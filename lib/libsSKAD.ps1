<#function Verba_script($scrpt_name) {
    $tmp = "$curDir\tmp"

    do {
        $ht = @()
        Get-ChildItem "$work\$mask" | % { $ht += , ($_.Name, $_.Length) }

        Write-Host -ForegroundColor White "Начинаем преобразование..."
        Start-Process "$verba" "/@$scrpt_name" -NoNewWindow -Wait
        Start-Sleep -Seconds 3

        #проверяем действительно или все файлы подписаны\шафированы. Верба иногда вылетает с ошибкой.
        $ff = Get-ChildItem "$work\$mask"
        Write-Host -ForegroundColor White "Сравниваем до и после преобразования..."
        foreach ($f1 in $ff) {
            $ht | % { $i = 0 } { if ($_ -eq $f1.Name) { $ht[$i] += $f1.Length }; $i++ } { }
        }
        $not_diff = @()
        foreach ($h1 in $ht) {
            if ($h1[1] -eq $h1[2]) {
                $not_diff += [string]$h1[0]
            }
        }
        #если не все преобразованы, повторяем процесс
        $count = ($not_diff | Measure-Object).count
        if ($count -ne 0) {

            Write-Host -ForegroundColor Red "Часть файлов не были преобразованы!"

            if (!(Test-Path $tmp)) {
                New-Item -ItemType directory -Path $tmp | out-Null
            }
            $files1 = Get-ChildItem "$work\$mask" | Select-Object Name | ? { $not_diff -notcontains $_.Name } | % { $_.Name }
            foreach ($ff2 in $files1) {
                Move-Item -Path "$work\$ff2" -Destination $tmp
            }

        }
    } until ($count -eq 0)

    if (Test-Path $tmp) {
        Move-Item -Path "$tmp\*.*" -Destination $work
        Remove-Item -Recurse $tmp
    }
    Start-Sleep -Seconds 5
}#>

<#function Verba_script($scrpt_name){
	Write-Host -ForegroundColor White "Начинаем преобразование..."
	Start-Process "$verba" "/@$scrpt_name" -NoNewWindow -Wait
	Start-Sleep -Seconds 3
}#>


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
        [string]$maskFiles = "*.*")

    Write-Log -EntryType Information -Message "Начинаем преобразование..."
    $mask = Get-ChildItem -path $work $maskFiles

    foreach ($file in $mask) {
        $tmpFile = $file.FullName + '.test'

        $arguments = ''
        if ($encrypt) {
            $arguments = "-sign -encrypt -profile $profile -registry -algorithm 1.2.643.7.1.1.2.2 -in $($file.FullName) -out $tmpFile -reclist $recList -silent $logSpki"
        }
        else {
            $arguments = "-sign -profile $profile -registry -algorithm 1.2.643.7.1.1.2.2 -data $($file.FullName) -out $tmpFile -reclist $recList -silent $logSpki"
        }

        Write-Log -EntryType Information -Message "Обрабатываем файл $($file.Name)"
        Start-Process $spki $arguments -NoNewWindow -Wait
    }

    $testFiles = Get-ChildItem "$work\*.test"
    if (($testFiles | Measure-Object).count -gt 0) {
        $msg = $mask | Remove-Item -Verbose -Force *>&1
        Write-Log -EntryType Information -Message ($msg | Out-String)
        if ($debug) {
            $msg = Get-ChildItem -path $work '*.test' | Rename-Item -NewName { $_.Name -replace '.test$', '.tst' } -Verbose *>&1
        }
        else {
            $msg = Get-ChildItem -path $work '*.test' | Rename-Item -NewName { $_.Name -replace '.test$', '' } -Verbose *>&1
        }
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

    Write-Log -EntryType Information -Message "Начинаем преобразование..."
    $mask = Get-ChildItem -path $work $maskFiles

    foreach ($file in $mask) {
        $tmpFile = $file.FullName + '.test'

        $arguments = ''
        if ($decrypt) {
            $arguments = "-decrypt -verify -delete -1 -profile $profile -registry -in $($file.FullName) -out $tmpFile -silent $logSpki"
        }
        else {
            $arguments = "-verify -delete -1 -profile $profile -registry -in $($file.FullName) -out $tmpFile -silent $logSpki"
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