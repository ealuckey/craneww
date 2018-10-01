$UserCredential = Get-Credential

$OnPremSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://cwl-dc01-exh01.cranewwl.internal/PowerShell/ -Authentication Kerberos -Credential $UserCredential
#$EOLSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

Import-PSSession $OnPremSession -DisableNameChecking

Function Add-NewDDL {

    [CmdletBinding()]
    param(
	    [Parameter( Mandatory=$false)]
	    [string]$Country,

	    [Parameter( Mandatory=$false)]
	    [string]$CountryCode
	)

    Write-Host "Attempting to create new Dynamic Distribution List for" $Country
}



Add-NewDDL -Country Italy