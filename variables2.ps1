$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent

[string]$util = "$curDir\util"
[string]$tmp = "$curDir\temp"
[boolean]$debug = $false

#рабочий каталог, где будут подписываться и шифроваться файлы
[string]$work = "c:\WORK"
#маска поиска отчетов
[string]$mask = "*.xml"

#[string]$arj32 ="$curDir\util\arj32.exe"
[string]$archiver = "$curDir\util\7z.exe"
#[string]$extArchiver = "arj"
[string]$extArchiver = "zip"

[string]$spki = "C:\Program Files\MDPREI\spki\spki1utl.exe"
[string]$vdkeys = "C:\DISKET2019-skad-2\foiv"
[string]$profile = "r2880_2"
[string]$recList = "$curDir\util\Reclist.conf"

#первоначальное копирование отчетности в папку work
[string]$311_cp = "$lib\311_cp.ps1"

#копирование файлов для налоговой в архив
[string]$311jur_cp = "$lib\311jur_cp.ps1"

#каталог на московском сервере, с отчетами для налоговой
[string]$gni = "\\191.168.6.12\quorum\tmn\SENDDOC\365P\CB_OUT\GNI"

$311Dir = "\\191.168.7.14\RBS\TMN\311p"
$311Archive = "\\tmn-ts-01\311p\Arhive"
$311JurArchive = "\\tmn-ts-01\311jur\Archive"

$curDate = Get-Date -Format "ddMMyyyy"
[string]$logName = $curDir + "\log\" + $curDate + "_trans.log"
[string]$logSpki = $curDir + "\log\" + $curDate + "_spki_tr.log"
[string]$outcoming_post = "$tmp\Post"

#настройка почты
[string]$mail_addr = "tmn-f365@tmn.apkbank.apk"
[string]$mail_server = "191.168.6.50"
[string]$mail_from = "robot311@tmn.apkbank.apk"