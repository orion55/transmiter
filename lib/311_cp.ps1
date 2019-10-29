[string]$currentDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent
$post_fix = @("RBS", "WAY4")

. $currentDir/../variables.ps1
. $curDir/lib/libs.ps1
. $curDir/lib/PSMultiLog.ps1

Set-Location $curDir
#ClearUI
Clear-Host
Start-HostLog -LogLevel Information
Start-FileLog -LogLevel Information -FilePath $logName -Append

$rbsOrig = "$311Dir\RBS"
$way4Orig = "$311Dir\WAY4"

testDir(@($311Dir, $rbsOrig, $way4Orig, $311Archive, $work))

$arch_dir = "$311Archive\$curDate"
if (!(Test-Path -Path $arch_dir )){
	New-Item -ItemType directory $arch_dir -Force | out-null
}

foreach ($curPrefix in $post_fix){
	$curPrefixDir = "$arch_dir\$curPrefix"
	if (!(Test-Path -Path $curPrefixDir)){
		New-Item -ItemType directory $curPrefixDir -Force | out-null
	}
}

$rbsArchiv = "$arch_dir\RBS"
$subName = Get-ChildItem "BN*" -Path $rbsOrig -Name -Directory
$countSub = ($subName | Measure-Object).count
if ($countSub -ne 1){
    Write-Log -EntryType Error -Message "Количество вложенных папок в $rbsOrig не равно 1"
}

Write-Log -EntryType Information -Message "Начало копирования файлов..."

$rbsOrigFull = "$rbsOrig\$subName"
$rbsXml = Get-ChildItem -Path $rbsOrigFull "*.xml"
$countRBS = ($rbsXml | Measure-Object).count
if ($countRBS -eq 0){
    Write-Log -EntryType Error -Message "Не найдены файлы в $rbsOrigFull"
} else {
    try {
        $msg = Copy-Item "$rbsOrigFull\*.xml" -Destination $rbsArchiv -ErrorAction Stop -Verbose -Force *>&1
        Write-Log -EntryType Information -Message ($msg | Out-String)
        Write-Log -EntryType Information -Message "Файл(ы) скопирован(ы) в $rbsArchiv"
    }
    catch {
        Write-Log -EntryType Error -Message "Ошибка копирования файла(ов) в $rbsArchiv"
		Write-Host "Для выхода нажмите любую клавишу"
		$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | out-null
        exit
    }

    try {
        $msg = Copy-Item "$rbsOrigFull\*.xml" -Destination $work -ErrorAction Stop -Verbose -Force *>&1
        Write-Log -EntryType Information -Message ($msg | Out-String)
        Write-Log -EntryType Information -Message "Файл(ы) скопирован(ы) в $work"
    }
    catch {
        Write-Log -EntryType Error -Message "Ошибка копирования файла(ов) в $work"
		Write-Host "Для выхода нажмите любую клавишу"
		$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | out-null
        exit
    }

    try {
        $msg = Remove-Item $rbsOrigFull -ErrorAction Stop -Verbose -Recurse *>&1
        Write-Log -EntryType Information -Message ($msg | Out-String)
        Write-Log -EntryType Information -Message "Файл(ы) удален(ы) в $rbsOrigFull"
    }
    catch {
        Write-Log -EntryType Error -Message "Ошибка удаления файла(ов) в $rbsOrigFull"
		Write-Host "Для выхода нажмите любую клавишу"
		$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | out-null
        exit
    }
}

$way4Archiv = "$arch_dir\WAY4"
$way4Xml = Get-ChildItem -Path $way4Orig "*.xml"
$countWay4 = ($way4Xml | Measure-Object).count
if ($countWay4 -eq 0){
    Write-Log -EntryType Error -Message "Не найдены файлы в $way4Orig"
} else {
    try {
        $msg = Copy-Item "$way4Orig\*.*" -Destination $way4Archiv -ErrorAction Stop -Verbose -Force *>&1
        Write-Log -EntryType Information -Message ($msg | Out-String)
        Write-Log -EntryType Information -Message "Файл(ы) скопирован(ы) в $way4Archiv"
    }
    catch {
        Write-Log -EntryType Error -Message "Ошибка копирования файла(ов) в $way4Archiv"
		Write-Host "Для выхода нажмите любую клавишу"
		$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | out-null
        exit
    }

    try {
        $msg = Copy-Item "$way4Orig\*.xml" -Destination $work -ErrorAction Stop -Verbose -Force *>&1
        Write-Log -EntryType Information -Message ($msg | Out-String)
        Write-Log -EntryType Information -Message "Файл(ы) скопирован(ы) в $work"
    }
    catch {
        Write-Log -EntryType Error -Message "Ошибка копирования файла(ов) в $work"
		Write-Host "Для выхода нажмите любую клавишу"
		$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | out-null
        exit
    }

    try {
        $msg = Remove-Item "$way4Orig\*.*" -ErrorAction Stop -Verbose *>&1
        Write-Log -EntryType Information -Message ($msg | Out-String)
        Write-Log -EntryType Information -Message "Файл(ы) удален(ы) в $way4Orig"
    }
    catch {
        Write-Log -EntryType Error -Message "Ошибка удаления файла(ов) в $way4Orig"
		Write-Host "Для выхода нажмите любую клавишу"
		$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | out-null
        exit
    }
}

<#Stop-FileLog
Stop-HostLog#>