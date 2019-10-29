if (Test-Connection $mail_server -Quiet -Count 2) {
		$title = "Отправлены сообщения по 440П SKAD Signatura"
		$encoding = [System.Text.Encoding]::UTF8
		Send-MailMessage -To $mail_addr -Body $body -Encoding $encoding -From $mail_from -Subject $title -SmtpServer $mail_server
	}
	else {
		Write-Log -EntryType Error -Message "Не удалось соединиться с почтовым сервером $mail_server"
	}
	

$afnCount = ($afnFiles | Measure-Object).count

$msg = Copy-Item -Path "$work\*.xml" -Destination $arhivePath -Verbose -Force *>&1
Write-Log -EntryType Information -Message ($msg | Out-String)