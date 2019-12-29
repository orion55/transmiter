#Программа создания arj-архива и удаления файлов входящих в этот архив
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

$workXml = Get-ChildItem -Path $work "*.xml"
if (($workXml | Measure-Object).count -eq 0) {
    Write-Log -EntryType Error -Message "Не найдены файлы в $work"
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

[string]$maskArch = ''

if ($form -eq '311p') {
    $maskArch = "BN02803"
}
elseif ($form -eq 'nalog') {
    $maskArch = "AN02803"
}

$date1 = Get-Date -UFormat "%y%m%d"

$afnFiles = Get-ChildItem "$arhivePath\$maskArch$date1*.$extArchiver"
$afnCount = ($afnFiles | Measure-Object).count
$afnCount++
$afnCountStr = $afnCount.ToString("0000")

$fname = $maskArch + $date1 + $afnCountStr + "." + $extArchiver

Write-Log -EntryType Information -Message "Начинаем архивацию $fname ..."

$AllArgs = @('a', '-e', "$work\$fname", "$work\*.xml")
&$arj32	$AllArgs | Out-Null

Set-Location $curDir

#удаляем все файлы, кроме файла архива
$msg = Remove-Item "$work\*.*" -Exclude $fname -Verbose *>&1
Write-Log -EntryType Information -Message ($msg | Out-String)
