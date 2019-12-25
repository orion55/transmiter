#Программа для автоматизации отправки банковской отчетности по форме 311p SKAD Signature для физ. и юр. лиц
#(c) Гребенёв О.Е. 28.10.2019

param (
	[ValidateSet('311p', 'nalog')]
	[string]$form = "none",
	#$form - какую форму будем автоматизировать
	[switch]$nobegin = $false
	#$nobegin - будем копировать сообщения автоматически в папку Work или это уже сделано вручную
)

[string]$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent
Set-Location $curDir
[string]$lib = "$curDir\lib"

. $curDir/variables.ps1
. $lib/PSMultiLog.ps1
. $lib/libs.ps1
. $lib/libsSKAD.ps1

Clear-Host
Start-HostLog -LogLevel Information
Start-FileLog -LogLevel Information -FilePath $logName -Append

#проверяем существуют ли нужные пути и файлы
testDir(@($work, $gni, $util, $vdkeys, $311Dir, $311Archive))
testFiles(@($archiver, $spki, $fnsList, $fnsFssList, $311_cp, $311jur_cp))

Write-Log -EntryType Information -Message "Начало работы Transmiter SKAD Signature"

Set-Location $work

#меню для ввода с клавиатуры
if ($debug) {
	Remove-Item -Path "$work\*.*"
	Remove-Item -Path $311Dir -Recurse
	New-Item -ItemType directory -Path $311Dir | out-Null
	Copy-Item -Path "$tmp\work1\RBS" -Destination $311Dir -Recurse
	Copy-Item -Path "$tmp\work1\WAY4" -Destination $311Dir -Recurse

	$nobegin = $false
	$form = '311p'

	<#Remove-Item -Path "$work\*.*"
	Copy-Item -Path "$tmp\work1\*.*" -Destination $gni
	$nobegin = $false
	$form = 'nalog'#>
}
elseif ($form -eq "none") {
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

	$title = "Файлы отчетности скопированы в папку Work?"
	$message = "Выберите вариант:"
	$yes = New-Object System.Management.Automation.Host.ChoiceDescription "Да - &0", "Да"
	$no = New-Object System.Management.Automation.Host.ChoiceDescription "Нет - &1", "Нет"
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
	$choice = $host.ui.PromptForChoice($title, $message, $options, 1)
	switch ($choice) {
		0 { $nobegin = $true }
		1 { $nobegin = $false }
	}

	if ($nobegin) {
		$msg = "Файлы отчетности не будут скопированы в папку $work"
	}
	else {
		$msg = "Файлы отчетности будут скопированы в папку $work"
	}
	Write-Log -EntryType Information -Message $msg
}

if ($nobegin) {
	Write-Log -EntryType Information -Message "Автоматическое копирование в папку $work произведено не было!"
}

#копируем файлы отчетности в каталого $work
if (!($nobegin)) {
	switch ($form) {
		'311p' { &$311_cp }
		'nalog' { &$311jur_cp }
		default {
			exit
		}
	}
}
else {
	if ($form -eq 'nalog') {
		&$311jur_cp
	}
}

#есть ли xml-файлы в каталоге work?
$xml1 = Get-ChildItem "$work\*.xml"
$count = ($xml1 | Measure-Object).count
if ($count -eq 0) {
	Write-Log -EntryType Error -Message "Файлы в $work не обнаружены!"
	exit
}

#проверяем действительно ли файлы скопированы - московский сервер периодически может отваливаться
if (!$debug -and !($nobegin)) {
	$title = "Проверка копирования"
	$message = "Файлы отчетности корректно скопированы в папку Work?"
	$yes = New-Object System.Management.Automation.Host.ChoiceDescription "Да - &0", "Да"
	$no = New-Object System.Management.Automation.Host.ChoiceDescription "Нет - &1", "Нет"
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
	$choice = $host.ui.PromptForChoice($title, $message, $options, 0)
	switch ($choice) {
		1 { exit }
	}
}

#проверяем есть ли диск А
$disks = (Get-PSDrive -PSProvider FileSystem).Name
if ($disks -notcontains "a") {
	Write-Log -EntryType Error -Message "Диск А не найден!"
	exit
}

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

#сохраняем текущею ключевую дискету
Write-Log -EntryType Information -Message "Сохраняем текущею ключевую дискету"
$tmp_keys = "$curDir\tmp_keys"
if (!(Test-Path $tmp_keys)) {
	New-Item -ItemType directory -Path $tmp_keys | out-Null
}
Copy_dirs -from 'a:' -to $tmp_keys
Remove-Item 'a:' -Recurse -ErrorAction "SilentlyContinue"

Write-Log -EntryType Information -Message "Загружаем ключевую дискету $vdkeys"
Copy_dirs -from $vdkeys -to 'a:'

$xmlFiles = Get-ChildItem -Path $work "*.xml"
$countXML = ($xmlFiles | Measure-Object).count

#подписываем и шифруем отчеты
Write-Log -EntryType Information -Message "Подписываем файлы"
SKAD_Encrypt -encrypt $false -maskFiles "*.xml"

Write-Log -EntryType Information -Message "Архивируем файлы"
SKAD_archive -maskFiles "*.xml"

Write-Log -EntryType Information -Message "Шифруем файлы"
if ($form -eq '311p') {
	$archDir = $311Archive
	SKAD_Encrypt -encrypt $true -maskFiles "*.xml" -fss $false
}
elseif ($form -eq 'nalog') {
	$archDir = $311JurArchive
	SKAD_Encrypt -encrypt $true -maskFiles "*.xml" -fss $true
}

#сжимаем файлы и переносим в архив
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

SKAD_Encrypt -encrypt $false -maskFiles "*.$extArchiver"

Write-Log -EntryType Information -Message "Копируем файл архива $fname в $arhivePath"
Copy-Item "$work\$fname" -Destination $arhivePath -Force
Write-Log -EntryType Information -Message "Копируем файл архива $fname в $outcoming_post"
Copy-Item "$work\$fname" -Destination $outcoming_post -Force

$msg = Remove-Item "$work\$fname" -Verbose *>&1
Write-Log -EntryType Information -Message ($msg | Out-String)

$body = "Отправлено $countXML файлов"
Write-Log -EntryType Information -Message "Отправка почтового сообщения"
if (Test-Connection $mailServer -Quiet -Count 2) {
	if ($form -eq '311p') {
		$mailAddr = $mailAddrFiz
	}
	elseif ($form -eq 'nalog') {
		$mailAddr = $mailAddrJur
	}
	$title = "Отправка в $curDate ИФНС - SKAD"
	$encoding = [System.Text.Encoding]::UTF8
	Send-MailMessage -To $mailAddr -Body $body -Encoding $encoding -From $mailFrom -Subject $title -SmtpServer $mailServer
}
else {
	Write-Log -EntryType Error -Message "Не удалось соединиться с почтовым сервером $mailServer"
}
Write-Log -EntryType Information -Message $body

Write-Log -EntryType Information -Message "Загружаем исходную ключевую дискету"
Remove-Item 'a:' -Recurse -ErrorAction "SilentlyContinue"
Copy_dirs -from $tmp_keys -to 'a:'
Remove-Item $tmp_keys -Recurse -Force

Write-Log -EntryType Information -Message "Конец работы скрипта!"

Stop-FileLog
Stop-HostLog