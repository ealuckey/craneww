#Get MSOL Credentials
$credential = Get-Credential

#Connect to AzureAD

try {
    Write-Host "Connecting to AzureAD.." -ForegroundColor Yellow -BackgroundColor Black
    $connectAAD = Connect-AzureAD -Credential $credential -WarningAction Ignore -InformationAction Ignore -ErrorAction Stop
    Write-Host "Successfully Connected to AzureAD" -ForegroundColor Yellow -BackgroundColor Black
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host "Failed to Connect to AzureAD:" $ErrorMessage -ForegroundColor Red -BackgroundColor Black
}


#Connect to MS Online Service
try {
    Write-Host "Connecting to MS Online.." -ForegroundColor Yellow -BackgroundColor Black
    $connectMSOL = Connect-MsolService -Credential $credential -WarningAction Ignore -InformationAction Ignore -ErrorAction Stop
    Write-Host "Successfully Connected to MS Online" -ForegroundColor Yellow -BackgroundColor Black
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host "Failed to Connect to MS Online:" $ErrorMessage -ForegroundColor Red -BackgroundColor Black
}



#Connect to Skype for Business Online, requires SkypeOnlineConnector downloadable at https://www.microsoft.com/en-us/download/details.aspx?id=39366
Import-Module SkypeOnlineConnector
try {
    Write-Host "Connecting to Skype for Business Online.." -ForegroundColor Yellow -BackgroundColor Black
    $sfboSession = New-CsOnlineSession -Credential $credential
    $connectSBOL = Import-PSSession $sfboSession -WarningAction Ignore -InformationAction Ignore -ErrorAction Stop
    Write-Host "Successfully Connected to Skype for Business Online" -ForegroundColor Yellow -BackgroundColor Black
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host "Failed to Connect to Skype for Business Online:" $ErrorMessage -ForegroundColor Red -BackgroundColor Black
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
}


