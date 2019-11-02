[string]$currentDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent

. $currentDir/../variables.ps1
. $curDir/lib/libs.ps1
. $curDir/lib/PSMultiLog.ps1

Set-Location $curDir

Start-HostLog -LogLevel Information
Start-FileLog -LogLevel Information -FilePath $logName -Append

testDir(@($311JurArchive, $work, $gni))

$archiveDir = "$311JurArchive\$curDate"
if (!(Test-Path -Path $archiveDir )) {
    New-Item -ItemType directory $archiveDir -Force | out-null
}
$workXml = Get-ChildItem -Path $work "*.xml"
$countWork = ($workXml | Measure-Object).count
if ($countWork -eq 0) {
    $gniFiles = Get-ChildItem -Path $gni "*.xml"
    $gniCount = ($gniFiles | Measure-Object).count
    if ($gniCount -gt 0) {
        try {
            $msg = Copy-Item -Path "$gni\*.xml" -Destination $work -Verbose -Force *>&1
            Write-Log -EntryType Information -Message ($msg | Out-String)
        }
        catch {
            Write-Log -EntryType Error -Message "Ошибка копирования файла(ов) в $work"
            exit
        }
    }
    else {
        Write-Log -EntryType Error -Message "Не найдены файлы в $gni"
        exit
    }
}
else {
    try {
        Write-Log -EntryType Information -Message "Резервное копирование файлов в $archiveDir"
        $msg = Copy-Item "$work\*.xml" -Destination $archiveDir -ErrorAction Stop -Verbose -Force *>&1
        Write-Log -EntryType Information -Message ($msg | Out-String)
        Write-Log -EntryType Information -Message "Файл(ы) скопирован(ы) в $archiveDir"
    }
    catch {
        Write-Log -EntryType Error -Message "Ошибка копирования файла(ов) в $archiveDir"
        exit
    }
}