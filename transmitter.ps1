#Программа для автоматизации отправки банковской отчетности

param ( 
    [ValidateSet('311p','nalog')]
    [string]$form = "none",
	#$form - какую форму будем автоматизировать
	[switch]$nobegin = $false
	#$nobegin - будем копировать сообщения автоматически в папку Work или это уже сделано вручную
)
$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent

#рабочий каталог, где будут подписываться и шифроваться файлы
$Script:work = "c:\Work"
#$Script:work = "$dir1\Work"
#маска поиска отчетов
$Script:mask = "*.xml"

#скрипты для подписи и шифрования
$scripts = "$dir1\scripts"
$script_sig = "$scripts\send440Sign.scr"
$script_sig_crypt = "$scripts\send440Cript.scr"

#дискеты для подписи и шифрования
$disk_sig = "c:\DISKET2018-1\Disk\DISK2"
$disk_crypt = "c:\DISKET2019\Disk\disk21"

#путь до программы шифрования и архиватор
$verba = "c:\Program Files\MDPREI\РМП Верба-OW\FColseOW.exe"
$arj32 ="$dir1\arj32.exe"

#первоначальное копирование отчетности в папку work
#$311_cp = "d:\Ps1\311_cp\311_cp.ps1"
$311_cp = "$dir1\311_cp.ps1"
 
#копирование архива 311 формы на отправку
$fizik311_cp = "$dir1\fizik311_cp.ps1"
#копирование файлов для налоговой в архив
$311jur_cp = "$dir1\311jur_cp.ps1"
#копирование архива для налоговой на отправку
$nalog_final1 = "$dir1\nalog_final1.ps1"

#каталог на московском сервере, с отчетами для налоговой
#$gni = "$dir1\GNI"
$gni = "\\191.168.6.12\quorum\tmn\SENDDOC\365P\CB_OUT\GNI"

Set-Location $dir1

function ClearUI{
	$bckgrnd = "DarkBlue"
	$Host.UI.RawUI.BackgroundColor = $bckgrnd
	$Host.UI.RawUI.ForegroundColor = 'White'
	$Host.PrivateData.ErrorForegroundColor = 'Red'
	$Host.PrivateData.ErrorBackgroundColor = $bckgrnd
	$Host.PrivateData.WarningForegroundColor = 'Magenta'
	$Host.PrivateData.WarningBackgroundColor = $bckgrnd
	$Host.PrivateData.DebugForegroundColor = 'Yellow'
	$Host.PrivateData.DebugBackgroundColor = $bckgrnd
	$Host.PrivateData.VerboseForegroundColor = 'Green'
	$Host.PrivateData.VerboseBackgroundColor = $bckgrnd
	Clear-Host
}

function Test_dir($dirs1){		
	foreach ($d1 in $dirs1){
		#проверка существования путей
		if (!(Test-Path -Path $d1)){
			Write-Host "Путь $d1 не найден!" -ForegroundColor Red
			Write-Host "Нажмите любую клавишу для продолжения" 
			Read-Host "Нажмите Enter"			
			Exit
		}
	}
}

function Test_files($files){	
	foreach ($f1 in $files){
		#проверка существования файлов
		if (!(Test-Path $f1)){
			Write-Host "Файл $f1 не найден!" -ForegroundColor Red
			Write-Host "Нажмите любую клавишу для продолжения" 
			Read-Host "Нажмите Enter"			
			Exit
		}
	}
}

function Verba_script($scrpt_name){
	$tmp = "$dir1\tmp"
	
	do{
		$ht = @()
		Get-ChildItem "$work\$mask" | %{ $ht += ,($_.Name, $_.Length)}
		
		Write-Host -ForegroundColor White "Начинаем преобразование..."
		Start-Process "$verba" "/@$scrpt_name" -NoNewWindow -Wait
		Start-Sleep -Seconds 3		
			
		#проверяем действительно или все файлы подписаны\шафированы. Верба иногда вылетает с ошибкой.
		$ff = Get-ChildItem "$work\$mask"
		Write-Host -ForegroundColor White "Сравниваем до и после преобразования..."
		foreach ($f1 in $ff){	
			$ht |  % {$i = 0} { if ($_ -eq $f1.Name) {$ht[$i] += $f1.Length}; $i++} {}	
		}
		$not_diff = @()
		foreach ($h1 in $ht){
			if ($h1[1] -eq $h1[2]){
				$not_diff += [string]$h1[0]		
			}
		}
		#если не все преобразованы, повторяем процесс
		$count = ($not_diff | Measure-Object).count
		if ($count -ne 0){
			
			Write-Host -ForegroundColor Red "Часть файлов не были преобразованы!"
						
			if (!(Test-Path $tmp)){
				New-Item -ItemType directory -Path $tmp | out-Null
			}
			$files1 = Get-ChildItem "$work\$mask" |  Select-Object Name | ? {$not_diff -notcontains $_.Name} | % {$_.Name}
			foreach ($ff2 in $files1){
				Move-Item -Path "$work\$ff2" -Destination $tmp
			}
			
		}
	} until ($count -eq 0)
	
	if (Test-Path $tmp){
		Move-Item -Path "$tmp\*.*" -Destination $work
		Remove-Item -Recurse $tmp
	}
	Start-Sleep -Seconds 5
}

<#function Verba_script($scrpt_name){
	Write-Host -ForegroundColor White "Начинаем преобразование..."
	Start-Process "$verba" "/@$scrpt_name" -NoNewWindow -Wait
	Start-Sleep -Seconds 3		
}#>


#копируем каталоги рекурсивно на "волшебный" диск А: - туда и обратно
function Copy_dirs{
	Param( 
	[string]$from,
	[string]$to)
	
	Get-ChildItem -Path $from -Recurse  | 
    Copy-Item -Destination {
        if ($_.PSIsContainer) {
            Join-Path $to $_.Parent.FullName.Substring($from.length)
        } else {
            Join-Path $to $_.FullName.Substring($from.length)
        }
    } -Force
}

function willBe{
    param($result)

    if ($result) {
        return "Файлы отчетности не будут скопированы в папку $work"
    } else {
        return "Файлы отчетности будут скопированы в папку $work"
    }
}

ClearUI

#меню для ввода с клавиатуры
if ($form -eq "none"){
	$title = "Отправка отчетности"
	$message = "Выберите формы для отправки отчетности:"
	$311p_1 = New-Object System.Management.Automation.Host.ChoiceDescription "311-форма для физ. лиц - &0", "311p"
	$nalog_1 = New-Object System.Management.Automation.Host.ChoiceDescription "311-форма для юр. лиц - &1", "nalog"	
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($311p_1, $nalog_1)
	$choice = $host.ui.PromptForChoice($title, $message, $options, 0)
	switch ($choice){
		0  { $form = "311p"}
		1  { $form = "nalog"}		
	}
    Write-Host -ForegroundColor Magenta "Обработка отчетности - $form"	
	
    $title = "Автоматизация копирования"
	$message = "Файлы отчетности скопированы в папку Work?"
	$yes = New-Object System.Management.Automation.Host.ChoiceDescription "Да - &0", "Да"
	$no = New-Object System.Management.Automation.Host.ChoiceDescription "Нет - &1", "Нет"
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
	$choice = $host.ui.PromptForChoice($title, $message, $options, 1)
	switch ($choice){
		0  { $nobegin = $true}
		1  { $nobegin = $false}
	}
    
    $msgWillBe = willBe -result $nobegin
    Write-Host -ForegroundColor Magenta $msgWillBe
    
    $title = "Обработка отчетности - $form и $msgWillBe"
	$message = "Продолжить работу программы?"
	$yes = New-Object System.Management.Automation.Host.ChoiceDescription "Да - &0", "Да"
	$no = New-Object System.Management.Automation.Host.ChoiceDescription "Нет - &1", "Нет"
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
	$choice = $host.ui.PromptForChoice($title, $message, $options, 0)
	switch ($choice){
		0  {}
		1  { exit }
	}
    		
}


if ($nobegin){
	Write-Host -ForegroundColor Yellow "`nАвтоматическое копирование в папку $work произведено не было!"
}

#копируем файлы отчетности в каталого $work
if (!($nobegin)){
	switch ($form){ 
	    '311p'  { &$311_cp } 
	    'nalog' {
			$files2 = Get-ChildItem -Path $gni "*.xml"
			$date2 = Get-Date -UFormat "%Y%m%d"
			foreach ($f2 in $files2){
				$sub1 = $f2.Name.Substring(17, 8)
				if ($sub1 -eq $date2){
					Copy-Item -Path "$gni\$f2" -Destination $work
					Write-Host -ForegroundColor White "Копируем файл $f2"
				}				
			}
			&$311jur_cp
		} 
	    default {
			exit
        }
	}
} else {
    if ($form -eq 'nalog'){        
        &$311jur_cp
    }
}

#есть ли xml-файлы в каталоге work?
$xml1 = Get-ChildItem "$work\*.xml"
$count = ($xml1|Measure-Object).count
if ($count -eq 0){
	Write-Host -ForegroundColor Red "Файлы в $work не обнаружены!"
	exit
}

#проверяем действительно ли файлы скопированы - московский сервер периодически может отваливаться
if (!($nobegin)){
	$title = "Проверка копирования"
	$message = "Файлы отчетности корректно скопированы в папку Work?"
	$yes = New-Object System.Management.Automation.Host.ChoiceDescription "Да - &0", "Да"
	$no = New-Object System.Management.Automation.Host.ChoiceDescription "Нет - &1", "Нет"
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
	$choice = $host.ui.PromptForChoice($title, $message, $options, 0)
	switch ($choice){		
		1  { exit}
	}
}

#проверяем существуют ли нужные пути и файлы
$dir_arr = @($work, $scripts, $disk_sig, $disk_crypt, $gni)
Test_dir($dir_arr)

$files_arr = @($script_sig, $script_sig_crypt, $verba, $arj32, $311_cp, $fizik311_cp, $nalog_final1, $311jur_cp)
Test_files($files_arr)

#проверяем есть ли диск А
$disks = (Get-PSDrive -PSProvider FileSystem).Name
if ($disks -notcontains "a"){
	Write-Host -ForegroundColor Red "Диск А не найден!"
	exit
}

#сохраняем текущею ключевую дискету
Write-Host -ForegroundColor Green "Сохраняем текущею ключевую дискету"
$tmp_keys = "$dir1\tmp_keys"
if (!(Test-Path $tmp_keys)){
	New-Item -ItemType directory -Path $tmp_keys | out-Null
}
Copy_dirs -from 'a:' -to $tmp_keys
Remove-Item 'a:' -Recurse -ErrorAction "SilentlyContinue"

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
switch ($form){ 
    '311p' {	
		Set-Location $work
		$date1 = Get-Date -UFormat "%y%m%d"
		$fname = -join ("BN02803",$date1, "0001")
		Write-Host "Начинаем архивацию $fname ..." -ForegroundColor Cyan
		$AllArgs = @('m', $fname, '*.xml')
		&$arj32	$AllArgs | Out-Null
		Set-Location $dir1
	} 
    'nalog' {
		Set-Location $work
		$date1 = Get-Date -UFormat "%y%m%d"
		$fname = -join ("AN02803",$date1, "0001")
		Write-Host "Начинаем архивацию $fname ..." -ForegroundColor Cyan
		$AllArgs = @('m', $fname, '*.xml')
		&$arj32 $AllArgs | Out-Null
		Set-Location $dir1	
	} 
    'fts' {} 
    default {
		exit
	}
}

#подписываем архив, если он не в ФТС
if ($form -eq '311p' -or $form -eq 'nalog'){
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
switch ($form){ 
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
Write-Host -ForegroundColor Cyan "Конец!"