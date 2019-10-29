$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent

#рабочий каталог, где будут подписываться и шифроваться файлы
$Script:work = "c:\Work"
#$Script:work = "$curDir\Work"
#маска поиска отчетов
$Script:mask = "*.xml"

#скрипты для подписи и шифрования
$scripts = "$curDir\scripts"
$script_sig = "$scripts\send440Sign.scr"
$script_sig_crypt = "$scripts\send440Cript.scr"

#дискеты для подписи и шифрования
$disk_sig = "c:\DISKET2018-1\Disk\DISK2"
$disk_crypt = "c:\DISKET2019\Disk\disk21"

#путь до программы шифрования и архиватор
$verba = "c:\Program Files\MDPREI\РМП Верба-OW\FColseOW.exe"
$arj32 ="$curDir\arj32.exe"

#первоначальное копирование отчетности в папку work
#$311_cp = "d:\Ps1\311_cp\311_cp.ps1"
$311_cp = "$curDir\311_cp.ps1"

#копирование архива 311 формы на отправку
$fizik311_cp = "$curDir\fizik311_cp.ps1"
#копирование файлов для налоговой в архив
$311jur_cp = "$curDir\311jur_cp.ps1"
#копирование архива для налоговой на отправку
$nalog_final1 = "$curDir\nalog_final1.ps1"

#каталог на московском сервере, с отчетами для налоговой
#$gni = "$curDir\GNI"
$gni = "\\191.168.6.12\quorum\tmn\SENDDOC\365P\CB_OUT\GNI"