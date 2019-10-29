$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent

[string]$util = "$curDir\util"
[string]$tmp = "$curDir\temp"

#рабочий каталог, где будут подписываться и шифроваться файлы
[string]$work = "$tmp\Work"
#маска поиска отчетов
[string]$mask = "*.xml"

$arj32 ="$curDir\util\arj32.exe"
[string]$spki = "C:\Program Files\MDPREI\spki\spki1utl.exe"
[string]$vdkeys = "c:\SKAD\Floppy\DISKET2019-skad-test\test1"
[string]$profile = "OT_TestFOIV"
[string]$recList = "$curDir\util\Reclist.conf"

#первоначальное копирование отчетности в папку work
[string]$311_cp = "$util\311_cp.ps1"

#копирование архива 311 формы на отправку
[string]$fizik311_cp = "$util\fizik311_cp.ps1"
#копирование файлов для налоговой в архив
[string]$311jur_cp = "$util\311jur_cp.ps1"
#копирование архива для налоговой на отправку
[string]$nalog_final1 = "$util\nalog_final1.ps1"

#каталог на московском сервере, с отчетами для налоговой
[string]$gni = "$tmp\GNI"




#скрипты для подписи и шифрования
$scripts = "$curDir\scripts"
$script_sig = "$scripts\send440Sign.scr"
$script_sig_crypt = "$scripts\send440Cript.scr"

#дискеты для подписи и шифрования
$disk_sig = "c:\DISKET2018-1\Disk\DISK2"
$disk_crypt = "c:\DISKET2019\Disk\disk21"

#путь до программы шифрования и архиватор
$verba = "c:\Program Files\MDPREI\РМП Верба-OW\FColseOW.exe"
