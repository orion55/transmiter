$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent

[string]$util = "$curDir\util"
[string]$tmp = "$curDir\temp"
[boolean]$debug = $true

#рабочий каталог, где будут подписываться и шифроваться файлы
[string]$work = "$tmp\work"
#маска поиска отчетов
[string]$mask = "*.xml"

[string]$arj32 ="$curDir\util\arj32.exe"
[string]$archiver = "$curDir\util\gzip.exe"
[string]$extArchiver = "arj"
#[string]$extArchiver = "zip"

[string]$spki = "C:\Program Files\MDPREI\spki\spki1utl.exe"
[string]$vdkeys = "d:\SKAD\Floppy\foiv"
[string]$profile = "r2880_2"
[string]$fnsList = "$curDir\util\FNS_Key.conf"
[string]$fnsFssList = "$curDir\util\FNS_FSS_Key.conf"

#первоначальное копирование отчетности в папку work
[string]$311_cp = "$lib\311_cp.ps1"

#копирование файлов для налоговой в архив
[string]$311jur_cp = "$lib\311jur_cp.ps1"

#каталог на московском сервере, с отчетами для налоговой
[string]$gni = "$tmp\GNI"

$311Dir = "$tmp\311pMsk"
$311Archive = "$tmp\311p\Arhive"
$311JurArchive = "$tmp\311jur\Arhive"

$curDate = Get-Date -Format "ddMMyyyy"
[string]$logName = $curDir + "\log\" + $curDate + "_trans.log"
[string]$logSpki = $curDir + "\log\" + $curDate + "_spki_tr.log"
[string]$outcoming_post = "$tmp\Post"

#настройка почты
#[string]$mail_addr = "tmn-f365@tmn.apkbank.apk"
[string]$mailAddrFiz = "tmn-goe@tmn.apkbank.ru"
#[string[]]$mailAddrJur = "<tmn-lov@tmn.apkbank.ru>", "<tmn_oit@tmn.apkbank.apk>"
$mailAddrJur = "tmn-goe <tmn-goe@tmn.apkbank.ru>", "lma <lma@tmn.apkbank.ru>"
[string]$mailServer = "191.168.6.50"
[string]$mailFrom = "robot311@tmn.apkbank.apk"