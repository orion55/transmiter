$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent

[string]$util = "$curDir\util"
[string]$tmp = "$curDir\temp"

#рабочий каталог, где будут подписываться и шифроваться файлы
[string]$work = "$tmp\work"
#маска поиска отчетов
[string]$mask = "*.xml"

[string]$arj32 ="$curDir\util\arj32.exe"
[string]$spki = "C:\Program Files\MDPREI\spki\spki1utl.exe"
[string]$vdkeys = "c:\SKAD\Floppy\DISKET2019-skad-test\test1"
[string]$profile = "OT_TestFOIV"
[string]$recList = "$curDir\util\Reclist.conf"

#первоначальное копирование отчетности в папку work
[string]$311_cp = "$lib\311_cp.ps1"

#копирование архива 311 формы на отправку
[string]$fizik311_cp = "$lib\fizik311_cp.ps1"
#копирование файлов для налоговой в архив
[string]$311jur_cp = "$lib\311jur_cp.ps1"
#копирование архива для налоговой на отправку
[string]$nalog_final1 = "$lib\nalog_final1.ps1"

#каталог на московском сервере, с отчетами для налоговой
[string]$gni = "$tmp\GNI"

$311Dir = "$tmp\311pMsk"
$311Archive = "$tmp\311p\Arhive"

$curDate = Get-Date -Format "ddMMyyyy"
[string]$logName = $curDir + "\log\" + $curDate + "_trans.log"
[string]$logSpki = $curDir + "\log\" + $curDate + "_spki_tr.log"




#скрипты для подписи и шифрования
$scripts = "$curDir\scripts"
$script_sig = "$scripts\send440Sign.scr"
$script_sig_crypt = "$scripts\send440Cript.scr"

#дискеты для подписи и шифрования
$disk_sig = "c:\DISKET2018-1\Disk\DISK2"
$disk_crypt = "c:\DISKET2019\Disk\disk21"

#путь до программы шифрования и архиватор
$verba = "c:\Program Files\MDPREI\РМП Верба-OW\FColseOW.exe"

#$311Dir = "\\191.168.7.14\RBS\TMN\311p"
#$311Archive = "\\tmn-ts-01\311p\Arhive"