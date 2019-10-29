#Программа для автоматизации отправки банковской отчетности

param (
	[ValidateSet('311p', 'nalog')]
	[string]$form = "none",
	#$form - какую форму будем автоматизировать
	[switch]$nobegin = $false
	#$nobegin - будем копировать сообщения автоматически в папку Work или это уже сделано вручную
)

[boolean]$debug = $true
[string]$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent
Set-Location $curDir
[string]$lib = "$curDir\lib"

. $curDir/variables.ps1
. $lib/PSMultiLog.ps1
. $lib/libs.ps1
. $lib/libsSKAD.ps1

#ClearUI
Clear-Host
Start-HostLog -LogLevel Information

Start-FileLog -LogLevel Information -FilePath $logName -Append

#проверяем существуют ли нужные пути и файлы
testDir(@($work, $gni, $util, $vdkeys, $311Dir, $311Archive))
testFiles(@($arj32, $spki, $recList, $311_cp, $fizik311_cp, $311jur_cp, $nalog_final1))

#меню для ввода с клавиатуры
if ($debug) {
	Remove-Item -Path "$work\*.*"
	Copy-Item -Path "$tmp\work1\RBS\*.*" -Destination "$311Dir\RBS"
	Copy-Item -Path "$tmp\work1\WAY4\*.*" -Destination "$311Dir\WAY4"

	$nobegin = $false
	$form = '311p'
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

$files3 = Get-ChildItem -Path $work -File *.*
if (($files3 | Measure-Object).count -gt 0) {
	Write-Log -EntryType Error -Message "Найдены файлы в каталоге $work"
	exit
}

#копируем файлы отчетности в каталого $work
if (!($nobegin)) {
	switch ($form) {
		'311p' { &$311_cp }
		'nalog' {
			$files2 = Get-ChildItem -Path $gni "*.xml"
			$date2 = Get-Date -UFormat "%Y%m%d"
			foreach ($f2 in $files2) {
				$sub1 = $f2.Name.Substring(17, 8)
				if ($sub1 -eq $date2) {
					Copy-Item -Path "$gni\$f2" -Destination $work
					Write-Log -EntryType Information -Message "Копируем файл $f2"
				}
			}
			&$311jur_cp
		}
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

#сохраняем текущею ключевую дискету
Write-Log -EntryType Information -Message "Сохраняем текущею ключевую дискету"
$tmp_keys = "$curDir\tmp_keys"
if (!(Test-Path $tmp_keys)) {
    New-Item -ItemType directory -Path $tmp_keys | out-Null
}
Copy_dirs -from 'a:' -to $tmp_keys
Remove-Item 'a:' -Recurse -ErrorAction "SilentlyContinue"

exit

#подписываем отчеты
Write-Host -ForegroundColor Green "Загружаем ключевую дискету $disk_sig"
Copy_dirs -from $disk_sig -to 'a:'

Verba_script($script_sig)

#шифруем отчеты
Write-Host -ForegroundColor Green "Загружаем ключевую дискету $disk_crypt"
Remove-Item 'a:' -Recurse -ErrorAction "SilentlyContinue"
Copy_dirs -from $disk_crypt -to 'a:'

Verba_script($script_sig_crypt)

#сжимаем файлы и переносим в архив
switch ($form) {
	'311p' {
		Set-Location $work
		$date1 = Get-Date -UFormat "%y%m%d"
		$fname = -join ("BN02803", $date1, "0001")
		Write-Host "Начинаем архивацию $fname ..." -ForegroundColor Cyan
		$AllArgs = @('m', $fname, '*.xml')
		&$arj32	$AllArgs | Out-Null
		Set-Location $curDir
	}
	'nalog' {
		Set-Location $work
		$date1 = Get-Date -UFormat "%y%m%d"
		$fname = -join ("AN02803", $date1, "0001")
		Write-Host "Начинаем архивацию $fname ..." -ForegroundColor Cyan
		$AllArgs = @('m', $fname, '*.xml')
		&$arj32 $AllArgs | Out-Null
		Set-Location $curDir
	}
	'fts' { }
	default {
		exit
	}
}

#подписываем архив, если он не в ФТС
if ($form -eq '311p' -or $form -eq 'nalog') {
	Write-Host -ForegroundColor Green "Загружаем ключевую дискету $disk_sig"
	Remove-Item 'a:' -Recurse -ErrorAction "SilentlyContinue"
	Copy_dirs -from $disk_sig -to 'a:'

	Verba_script($script_sig)
}

Write-Host -ForegroundColor Green "Загружаем исходную ключевую дискету"
Remove-Item 'a:' -Recurse -ErrorAction "SilentlyContinue"
Copy_dirs -from $tmp_keys -to 'a:'
Remove-Item $tmp_keys -Recurse

#копируем в архив
Write-Host "Помещаем в архив..." -ForegroundColor Cyan
switch ($form) {
	'311p' {
		&$fizik311_cp
	}
	'nalog' {
		&$nalog_final1
	}
	default {
		exit
	}
}
Write-Log -EntryType Information -Message "Конец работы скрипта!"

Stop-FileLog
Stop-HostLog