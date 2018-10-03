#Get MSOL Credentials
$credential = Get-Credential

#Connect to AzureAD
Connect-AzureAD -Credential $credential

#Connect to MS Online Service
Connect-MsolService -Credential $credential

#Connect to Skype for Business Online, requires SkypeOnlineConnector downloadable at https://www.microsoft.com/en-us/download/details.aspx?id=39366
Import-Module SkypeOnlineConnector
$sfboSession = New-CsOnlineSession -Credential $credential
Import-PSSession $sfboSession

#Connect to Exchange Online
$exchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $credential -Authentication "Basic" -AllowRedirection
Import-PSSession $exchangeSession