function ClearUI {
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

#��������� ���������� �� ��������?
function testDir($dirList) {
	if ($dirList) {
		foreach ($curPath in $dirList) {
			#�������� ������������� �����
			if ($curPath) {
				if (!(Test-Path -Path $curPath)) {
					Write-Host -ForegroundColor Red "���� $curPath �� ������!!!"
					Write-Host -ForegroundColor Red "������� ����� ������� ��� �����������"
					Read-Host "������� Enter"
					Exit
				}
			}
		}
	}
}

#��������� ���������� �� �����?
function testFiles($filesList) {
	if ($filesList) {
		foreach ($curFile in $filesList) {
			#�������� ������������� ������
			if (!(Test-Path $curFile)) {
				Write-Host -ForegroundColor Red "���� $curFile �� ������!"
				Write-Host -ForegroundColor Red "������� ����� ������� ��� �����������"
				Read-Host "������� Enter"
				Exit
			}
		}
	}
}

#��������� ���������� �� ��������, ���� �� ����������, �� ������?
function createDir($dirList) {
	if ($dirList) {
		foreach ($curPath in $dirList) {
			#�������� ������������� �����
			if (!(Test-Path -Path $curPath)) {
				New-Item -ItemType directory -Path $curPath | out-Null
			}
		}
	}
}