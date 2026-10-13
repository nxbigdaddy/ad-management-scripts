#requires -Version 5.1
<#
.SYNOPSIS
    Add a user to an AD group
.DESCRIPTION
    This script adds a specified user to an AD group
.PARAMETER UserName
    The username (SamAccountName) of the user to add
.PARAMETER GroupName
    The name of the group to add the user to
.PARAMETER Server
    AD server IP address
.PARAMETER Credential
    AD credentials
.EXAMPLE
    .\Add-UserToGroup.ps1 -UserName "lidd" -GroupName "SCMD-Read"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$UserName,
    
    [Parameter(Mandatory = $true)]
    [string]$GroupName,
    
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
Write-Host "Adding user to group" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

try {
    # Verify the user exists
    Write-Host "`nSearching for user: $UserName" -ForegroundColor Yellow
    $user = Get-ADUser -Filter "SamAccountName -eq '$UserName' -or Name -eq '$UserName'" -Server $Server -Credential $Credential -Properties Name, SamAccountName, DistinguishedName, Enabled
    
    if (-not $user) {
        Write-Warning "User '$UserName' not found!"
        
        # Try to search in 审计部 OU
        Write-Host "`nSearching in 审计部 OU..." -ForegroundColor Yellow
        $ou = Get-ADOrganizationalUnit -Filter "Name -eq '审计部'" -Server $Server -Credential $Credential
        if ($ou) {
            $user = Get-ADUser -Filter "Name -like '*$UserName*'" -SearchBase $ou.DistinguishedName -Server $Server -Credential $Credential -Properties Name, SamAccountName, DistinguishedName, Enabled
        }
        
        if (-not $user) {
            Write-Error "User '$UserName' could not be found in AD!"
            exit
        }
    }
    
    Write-Host "`nUser found:" -ForegroundColor Green
    Write-Host "  Name: $($user.Name)" -ForegroundColor White
    Write-Host "  SamAccountName: $($user.SamAccountName)" -ForegroundColor White
    Write-Host "  DistinguishedName: $($user.DistinguishedName)" -ForegroundColor White
    Write-Host "  Enabled: $($user.Enabled)" -ForegroundColor White
    
    # Verify the group exists
    Write-Host "`nSearching for group: $GroupName" -ForegroundColor Yellow
    $group = Get-ADGroup -Filter "Name -eq '$GroupName'" -Server $Server -Credential $Credential
    
    if (-not $group) {
        Write-Error "Group '$GroupName' not found!"
        exit
    }
    
    Write-Host "`nGroup found:" -ForegroundColor Green
    Write-Host "  Name: $($group.Name)" -ForegroundColor White
    Write-Host "  SamAccountName: $($group.SamAccountName)" -ForegroundColor White
    Write-Host "  DistinguishedName: $($group.DistinguishedName)" -ForegroundColor White
    
    # Check if user is already a member
    $members = Get-ADGroupMember -Identity $group.DistinguishedName -Server $Server -Credential $Credential | Select-Object -ExpandProperty SamAccountName
    
    if ($members -contains $user.SamAccountName) {
        Write-Host "`nUser '$($user.Name)' is already a member of group '$GroupName'!" -ForegroundColor Yellow
        exit
    }
    
    # Add user to group
    Write-Host "`nAdding user '$($user.Name)' to group '$GroupName'..." -ForegroundColor Yellow
    Add-ADGroupMember -Identity $group.DistinguishedName -Members $user.DistinguishedName -Server $Server -Credential $Credential
    
    Write-Host "`n✓ Successfully added user '$($user.Name)' to group '$GroupName'!" -ForegroundColor Green
    
    # Verify the addition
    $updatedMembers = Get-ADGroupMember -Identity $group.DistinguishedName -Server $Server -Credential $Credential | Select-Object -ExpandProperty SamAccountName
    
    if ($updatedMembers -contains $user.SamAccountName) {
        Write-Host "`nVerification: User is now a member of the group." -ForegroundColor Green
        Write-Host "Current member count: $($updatedMembers.Count)" -ForegroundColor White
    }
}
catch {
    Write-Error "Error adding user to group: $_"
}
