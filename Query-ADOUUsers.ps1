#requires -Version 5.1
<#
.SYNOPSIS
    Query AD users in a specific OU
.DESCRIPTION
    This script queries users in a specific Organizational Unit
.PARAMETER OUName
    The name of the OU to query (e.g., "采购部")
.PARAMETER Server
    AD server IP address
.PARAMETER Credential
    AD credentials
.EXAMPLE
    .\Query-ADOUUsers.ps1 -OUName "采购部"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$OUName,
    
    [Parameter(Mandatory = $false)]
    [string]$Server = "203.0.113.10",
    
    [Parameter(Mandatory = $false)]
    [System.Management.Automation.PSCredential]$Credential
)

# Prompt for credentials if not provided
if (-not $Credential) {
    Write-Host "Please enter AD administrator credentials (e.g., demo\administrator)" -ForegroundColor Yellow
    $Credential = Get-Credential -Message "Please enter AD administrator credentials"
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Querying users in OU: $OUName" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

try {
    # Get the OU
    $ou = Get-ADOrganizationalUnit -Filter "Name -eq '$OUName'" -Server $Server -Credential $Credential
    
    if (-not $ou) {
        Write-Warning "OU '$OUName' not found!"
        exit
    }
    
    Write-Host "`nOU Details:" -ForegroundColor Green
    Write-Host "  Name: $($ou.Name)" -ForegroundColor White
    Write-Host "  DistinguishedName: $($ou.DistinguishedName)" -ForegroundColor White
    Write-Host "  Created: $($ou.Created)" -ForegroundColor White
    
    # Get users in this OU
    $users = Get-ADUser -Filter * -SearchBase $ou.DistinguishedName -Server $Server -Credential $Credential -Properties `
        Name, DisplayName, SamAccountName, UserPrincipalName, EmailAddress, `
        Enabled, LastLogonDate, PasswordLastSet, Created, Modified, `
        Department, Title, Office, TelephoneNumber, Description
    
    if ($users) {
        Write-Host "`nUsers in OU '$OUName':" -ForegroundColor Green
        Write-Host "Total: $($users.Count) users" -ForegroundColor Yellow
        Write-Host ""
        
        $userList = $users | Select-Object `
            Name,
            DisplayName,
            SamAccountName,
            UserPrincipalName,
            EmailAddress,
            Enabled,
            LastLogonDate,
            PasswordLastSet,
            Created,
            Department,
            Title,
            Office,
            TelephoneNumber,
            Description
        
        $userList | Format-Table -AutoSize
        
        # Export to CSV
        $csvPath = ".\${OUName}_Users_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $userList | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-Host "Results exported to: $csvPath" -ForegroundColor Green
    } else {
        Write-Host "`nNo users found in OU '$OUName'" -ForegroundColor Yellow
    }
    
    # Also check for computers in this OU
    $computers = Get-ADComputer -Filter * -SearchBase $ou.DistinguishedName -Server $Server -Credential $Credential -Properties `
        Name, DNSHostName, Enabled, LastLogonDate, OperatingSystem
    
    if ($computers) {
        Write-Host "`nComputers in OU '$OUName':" -ForegroundColor Green
        Write-Host "Total: $($computers.Count) computers" -ForegroundColor Yellow
        $computers | Select-Object Name, DNSHostName, Enabled, LastLogonDate, OperatingSystem | Format-Table -AutoSize
    } else {
        Write-Host "`nNo computers found in OU '$OUName'" -ForegroundColor Gray
    }
    
    # Check for groups in this OU
    $groups = Get-ADGroup -Filter * -SearchBase $ou.DistinguishedName -Server $Server -Credential $Credential -Properties `
        Name, SamAccountName, GroupCategory, GroupScope, Description
    
    if ($groups) {
        Write-Host "`nGroups in OU '$OUName':" -ForegroundColor Green
        Write-Host "Total: $($groups.Count) groups" -ForegroundColor Yellow
        $groups | Select-Object Name, SamAccountName, GroupCategory, GroupScope, Description | Format-Table -AutoSize
    } else {
        Write-Host "`nNo groups found in OU '$OUName'" -ForegroundColor Gray
    }
}
catch {
    Write-Error "Error querying OU: $_"
}
