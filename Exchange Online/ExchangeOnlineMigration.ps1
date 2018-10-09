Param(
    [Parameter(Mandatory=$true)]
    [string]$BatchCsv,

    [Parameter(Mandatory=$true)]
    [string]$BatchName
)

$credential = Get-Credential 

$batchPath = Split-Path $BatchCsv
$batchAudited = "$batchPath\MigrationBatch-$(get-date -f MM-dd-yyyy-hhmm).csv" 

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
Write-Host "Creating Custom Sku..." -ForegroundColor Yellow -BackgroundColor Black
$O365StandardSku = New-MsolLicenseOptions -AccountSkuId craneww0:ENTERPRISEPACK -DisabledPlans FORMS_PLAN_E3,STREAM_O365_E3,Deskless,FLOW_O365_P2,POWERAPPS_O365_P2,TEAMS1,PROJECTWORKMANAGEMENT,SWAY,INTUNE_O365,YAMMER_ENTERPRISE,RMS_S_ENTERPRISE

#Import the userlist containing UPNs
Write-Host "Importing Batch Members..." -ForegroundColor Yellow -BackgroundColor Black
$preCheckBatch = Import-CSV $BatchCsv

#Check user list for existence of E3 license and output
Write-Host "Auditing Batch Members for E3 License Assignment..." -ForegroundColor Yellow -BackgroundColor Black 
foreach ($user in $preCheckBatch) {
    $licenseCheck = Get-MsolUser -UserPrincipalName $user.UserPrincipalName -ErrorAction SilentlyContinue
    if ($licenseCheck.Licenses.AccountSkuId -like "craneww0:ENTERPRISEPACK") {
        $user.hasLicense = $true
    }
    else {
        $user.hasLicense = $false
        Write-Host "User" $user.userPrincipalName "does not have an E3 license, removing from batch file." -ForegroundColor Red -BackgroundColor Black
    }
}

#Write users who have an E3 license into a new batch file.
try {
    Write-Host "Writing audited batch file to $batchAudited..." -ForegroundColor Yellow -BackgroundColor Black
    $preCheckBatch | Where-Object { $_.hasLicense -eq $true } | Export-CSV -Path $batchAudited -NoTypeInformation
    $batch = Import-CSV $batchAudited
}
catch {
    Write-Host "Error creating audited batch file. Aborting." -ForegroundColor Red -BackgroundColor Black
    break
}

#Must remove existing license and readd with correct plans
Write-Host "Attempting to fixup licensing.." -ForegroundColor Yellow -BackgroundColor Black
foreach ($user in $batch) {
    try {
        #Write-Host "Removing existing license options for" $user.UserPrincipalName
        Get-MsolUser -UserPrincipalName $user.UserPrincipalName | Set-MsolUserLicense -RemoveLicenses craneww0:ENTERPRISEPACK
    }
    catch {
        Write-Host "Error removing license for " $user.UserPrincipalName -ForegroundColor Red -BackgroundColor Black
    }

    try {
        #Write-Host "Adding new license options for" $user.UserPrincipalName
        Set-MsolUserLicense -UserPrincipalName $user.UserPrincipalName -AddLicenses craneww0:ENTERPRISEPACK -LicenseOptions $O365StandardSku
    }
    catch {
        Write-Host "Error re-adding license for " $user.UserPrincipalName -ForegroundColor Red -BackgroundColor Black
    }
}

#Create a new migration batch and start the initial sync. Batch must be manually completed
Write-Host "Creating new migration batch.." -ForegroundColor Yellow -BackgroundColor Black
$OnboardingBatch = New-MigrationBatch -Name $BatchName -SourceEndpoint CraneWorldWide -TargetDeliveryDomain craneww0.mail.onmicrosoft.com -BadItemLimit 10 -LargeItemLimit 10 -CSVData ([System.IO.File]::ReadAllBytes("$batchAudited")) -AllowUnknownColumnsInCsv $true

#Sleep 10 seconds to wait for Migration Batch 
Start-Sleep -Seconds 10

#Start migration batch
Write-Host "Starting migration batch.." -ForegroundColor Yellow -BackgroundColor Black
Start-MigrationBatch -Identity $OnboardingBatch.Identity

#Cleanup 
Write-Host "Cleaning up.." -ForegroundColor Yellow -BackgroundColor Black
Get-PSSession | Remove-PSSession
