$credential = Get-Credential

#Connect to MS Online Service
try {
    Write-Host "Connecting to MS Online.." -ForegroundColor Yellow -BackgroundColor Black
    $connectMSOL = Connect-MsolService -Credential $credential -WarningAction Ignore -InformationAction Ignore -ErrorAction Stop
    Write-Host "Successfully Connected to MS Online" -ForegroundColor Yellow -BackgroundColor Black
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host "Failed to Connect to MS Online:" $ErrorMessage -ForegroundColor Red -BackgroundColor Black
    break
}

#Connect to Exchange Online
try {
    Write-Host "Connecting to Exchange Online.." -ForegroundColor Yellow -BackgroundColor Black
    $exchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $credential -Authentication "Basic" -AllowRedirection
    $connectEOL = Import-PSSession $exchangeSession -WarningAction SilentlyContinue -InformationAction Ignore -ErrorAction Stop
    Write-Host "Successfully Connected to MS Online" -ForegroundColor Yellow -BackgroundColor Black
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host "Failed to Connect to MS Online:" $ErrorMessage -ForegroundColor Red -BackgroundColor Black
    break
}


#Create custom SKU that only enables Exchange, Skype, Office, and Sharepoint
$O365StandardSku = New-MsolLicenseOptions -AccountSkuId craneww0:ENTERPRISEPACK -DisabledPlans FORMS_PLAN_E3,STREAM_O365_E3,Deskless,FLOW_O365_P2,POWERAPPS_O365_P2,TEAMS1,PROJECTWORKMANAGEMENT,SWAY,INTUNE_O365,YAMMER_ENTERPRISE,RMS_S_ENTERPRISE

#Import the userlist containing UPNs
$batch = Import-CSV C:\Support\O365\RemoteOnBoarding.csv

#Ask for a new batch name for the migration batch creation
$BatchName = Read-Host -Prompt 'Input your batch name >> '

#Must remove existing license and readd with correct disabled plans
foreach ($user in $batch) {
	Write-Host "Removing existing license options for $user.UserPrincipalName"
	Get-MsolUser -UserPrincipalName $user.UserPrincipalName | Set-MsolUserLicense -RemoveLicenses craneww0:ENTERPRISEPACK
	Write-Host "Adding new license options for $user.UserPrincipalName"
	Set-MsolUserLicense -UserPrincipalName $user.UserPrincipalName -AddLicenses craneww0:ENTERPRISEPACK -LicenseOptions $O365StandardSku
}

#Create a new migration batch and start the initial sync. Batch must be manually completed
$OnboardingBatch = New-MigrationBatch -Name $BatchName -SourceEndpoint CraneWorldWide -TargetDeliveryDomain craneww0.mail.onmicrosoft.com -BadItemLimit 10 -LargeItemLimit 10 -CSVData ([System.IO.File]::ReadAllBytes("C:\Support\O365\RemoteOnBoarding.csv")) -AllowUnknownColumnsInCsv $true
Start-MigrationBatch -Identity $OnboardingBatch.Identity

#Cleanup 
Get-PSSession | Remove-PSSession
