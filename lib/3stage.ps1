#Программа перемещения arj-архива на отправку и в общий архив файлов
#(c) Гребенёв О.Е. 29.12.2019
param (
    [ValidateSet('311p', 'nalog')]
    [string]$form = "none"
    #$form - какую форму будем автоматизировать
)

[string]$currentDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent

. $currentDir/../variables.ps1
. $curDir/lib/libs.ps1
. $curDir/lib/PSMultiLog.ps1
. $curDir/lib/libsSKAD.ps1

Set-Location $curDir

Start-HostLog -LogLevel Information
Start-FileLog -LogLevel Information -FilePath $logName -Append

testDir(@($work))

$workXml = Get-ChildItem -Path $work "*.arj"
if (($workXml | Measure-Object).count -eq 0) {
    Write-Log -EntryType Error -Message "Не найдены arj-файлы в $work"
    exit
}

if ($form -eq "none") {
    $title = "Отправка отчетности"
    $message = "Выберите формы для отправки отчетности:"
    $311p_1 = New-Object System.Management.Automation.Host.ChoiceDescription "311-форма для физ. лиц - &0", "311p"
    $nalog_1 = New-Object System.Management.Automation.Host.ChoiceDescription "311-форма для юр. лиц - &1", "nalog"
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($311p_1, $nalog_1)
    $choice = $host.ui.PromptForChoice($title, $message, $options, 0)
    switch ($choice) {
        0 { $form = "311p" }
        1 { $form = "nalog" }
    }
    Write-Log -EntryType Information -Message "Обработка отчетности - $form"
}

$arhivePath = getArchivePath -form $form

$arjFiles = Get-ChildItem "$work\*.arj"
$xmlCount = 0
ForEach ($file in $arjFiles) {
    $AllArgs = @('l', $($file.FullName))
    $lastLog = &$arj32 $AllArgs
    $lastLog = $lastLog | Select-Object -Last 1

    $regex = "^\s+(\d+)\sfiles"
    $match = [regex]::Match($lastLog, $regex)
    if ($match.Success) {
        $xmlCount += [int]$match.Captures.groups[1].value
    }
}

$msg = Copy-Item "$work\*.arj" -Destination $arhivePath -Force -Verbose *>&1
Write-Log -EntryType Information -Message ($msg | Out-String)
$msg = Copy-Item "$work\*.arj" -Destination $outcoming_post -Force -Verbose *>&1
Write-Log -EntryType Information -Message ($msg | Out-String)
$msg = Remove-Item "$work\*.arj" -Verbose *>&1
Write-Log -EntryType Information -Message ($msg | Out-String)

$body = "Файлы отправлены, $xmlCount шт."
Write-Log -EntryType Information -Message "Отправка почтового сообщения"
if (Test-Connection $mailServer -Quiet -Count 2) {
    if ($form -eq '311p') {
        $mailAddr = $mailAddrFiz
    }
    elseif ($form -eq 'nalog') {
        $mailAddr = $mailAddrJur
    }
    $title = "Отправка в $curDate ИФНС"
    $encoding = [System.Text.Encoding]::UTF8
    Send-MailMessage -To $mailAddr -Body $body -Encoding $encoding -From $mailFrom -Subject $title -SmtpServer $mailServer
}
else {
    Write-Log -EntryType Error -Message "Не удалось соединиться с почтовым сервером $mailServer"
}
Write-Log -EntryType Information -Message $body