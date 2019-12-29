#копируем каталоги рекурсивно на "волшебный" диск А: - туда и обратно
function Copy_dirs {
    Param(
        [string]$from,
        [string]$to)

    Get-ChildItem -Path $from -Recurse |
    Copy-Item -Destination {
        if ($_.PSIsContainer) {
            Join-Path $to $_.Parent.FullName.Substring($from.length)
        }
        else {
            Join-Path $to $_.FullName.Substring($from.length)
        }
    } -Force
}
function SKAD_Encrypt {
    Param(
        $encrypt = $false,
        [string]$maskFiles = "*.*",
        $fss = $false
    )


    $mask = Get-ChildItem -path $work $maskFiles

    Set-Location "$curDir\util"

    foreach ($file in $mask) {
        $tmpFile = $file.FullName + '.test'

        $arguments = ''
        if ($encrypt) {
            if ($fss) {
                #$arguments = "-sign -encrypt -profile $profile -registry -algorithm 1.2.643.7.1.1.2.2 -in $($file.FullName) -out $tmpFile -reclist $recList -silent $logSpki"
                $arguments = "-sign -encrypt -profile $profile -algorithm 1.2.643.7.1.1.2.2 -in $($file.FullName) -out $tmpFile -reclist $fnsFssList -silent $logSpki"
                Write-Log -EntryType Information -Message "Шифруем файлы ключами ФНС и ФСС"
            }
            else {
                $arguments = "-sign -encrypt -profile $profile -algorithm 1.2.643.7.1.1.2.2 -in $($file.FullName) -out $tmpFile -reclist $fnsList -silent $logSpki"
                Write-Log -EntryType Information -Message "Шифруем файлы ключём ФНС"
            }
        }
        else {
            #$arguments = "-sign -profile $profile -registry -algorithm 1.2.643.7.1.1.2.2 -data $($file.FullName) -out $tmpFile -reclist $recList -silent $logSpki"
            $arguments = "-sign -profile $profile -algorithm 1.2.643.7.1.1.2.2 -data $($file.FullName) -out $tmpFile -silent $logSpki"
            #$arguments = "-sign -algorithm 1.2.643.7.1.1.2.2 -data $($file.FullName) -out $tmpFile"
            Write-Log -EntryType Information -Message "Подписываем файлы"
        }

        Write-Log -EntryType Information -Message "Обрабатываем файл $($file.Name)"
        Start-Process $spki $arguments -NoNewWindow -Wait
    }

    Set-Location $curDir

    $testFiles = Get-ChildItem "$work\*.test"
    if (($testFiles | Measure-Object).count -gt 0) {
        $msg = $mask | Remove-Item -Verbose -Force *>&1
        Write-Log -EntryType Information -Message ($msg | Out-String)
        $msg = Get-ChildItem -path $work '*.test' | Rename-Item -NewName { $_.Name -replace '.test$', '' } -Verbose *>&1
        Write-Log -EntryType Information -Message ($msg | Out-String)
    }
    else {
        Write-Log -EntryType Error -Message "Ошибка при работе программы $spki"
        exit
    }
}
function SKAD_Decrypt {
    Param(
        $decrypt = $false,
        [string]$maskFiles = "*.*")

    $mask = Get-ChildItem -path $work $maskFiles

    foreach ($file in $mask) {
        $tmpFile = $file.FullName + '.test'

        $arguments = ''
        if ($decrypt) {
            $arguments = "-decrypt -verify -delete -1 -profile $profile -in $($file.FullName) -out $tmpFile -silent $logSpki"
            Write-Log -EntryType Information -Message "Дешифруем файлы"
        }
        else {
            $arguments = "-verify -delete -1 -profile $profile -in $($file.FullName) -out $tmpFile -silent $logSpki"
            Write-Log -EntryType Information -Message "Снимаем подпись с файлов"
        }

        Write-Log -EntryType Information -Message "Обрабатываем файл $($file.Name)"
        Start-Process $spki $arguments -NoNewWindow -Wait
    }

    $testFiles = Get-ChildItem "$work\*.test"
    if (($testFiles | Measure-Object).count -gt 0) {
        $msg = $mask | Remove-Item -Verbose -Force *>&1
        Write-Log -EntryType Information -Message ($msg | Out-String)
        $msg = Get-ChildItem -path $work '*.test' | Rename-Item -NewName { $_.Name -replace '.test$', '' } -Verbose *>&1
        Write-Log -EntryType Information -Message ($msg | Out-String)
    }
    else {
        Write-Log -EntryType Error -Message "Ошибка при работе программы $spki"
        exit
    }

}

function SKAD_archive {
    Param([string]$maskFiles = "*.*")

    $arguments = "-f -k $work\$maskFiles"
    Start-Process $archiver $arguments -NoNewWindow -Wait

    $gzFiles = Get-ChildItem "$work\*.gz"
    if (($gzFiles | Measure-Object).count -gt 0) {
        $msg = "$work\$maskFiles" | Remove-Item -Verbose -Force -Exclude "$work\*.gz" *>&1
        Write-Log -EntryType Information -Message ($msg | Out-String)
        $msg = Get-ChildItem -path $work '*.gz' | Rename-Item -NewName { $_.Name -replace '.gz$', '' } -Verbose *>&1
        Write-Log -EntryType Information -Message ($msg | Out-String)
    }
    else {
        Write-Log -EntryType Error -Message "Ошибка при работе программы $archiver"
        exit
    }
}

function getArchivePath {
    param (
        [ValidateSet('311p', 'nalog')]
        [string]$form = "none"
    )
    [string]$archDir = ''
    if ($form -eq '311p') {
        $archDir = $311Archive
    }
    elseif ($form -eq 'nalog') {
        $archDir = $311JurArchive
    }

    $arhivePath = $archDir + '\' + $curDate
    if (!(Test-Path $arhivePath)) {
        New-Item -ItemType directory -Path $arhivePath | out-Null
    }

    return $arhivePath
}