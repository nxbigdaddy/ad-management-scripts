#requires -Version 5.1
<#
.SYNOPSIS
    Get members of an AD group
.DESCRIPTION
    This script retrieves all members of a specified AD group
.PARAMETER GroupName
    The name of the group to query
.PARAMETER Server
    AD server IP address
.PARAMETER Credential
    AD credentials
.EXAMPLE
    .\Get-ADGroupMembers.ps1 -GroupName "SCMD-Read"
#>

[CmdletBinding()]
param(
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
Write-Host "Querying members of group: $GroupName" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

try {
    # Get the group
    $group = Get-ADGroup -Filter "Name -eq '$GroupName'" -Server $Server -Credential $Credential -Properties Description, Created, Modified
    
    if (-not $group) {
        Write-Warning "Group '$GroupName' not found!"
        exit
    }
    
    Write-Host "`nGroup Details:" -ForegroundColor Green
    Write-Host "  Name: $($group.Name)" -ForegroundColor White
    Write-Host "  SamAccountName: $($group.SamAccountName)" -ForegroundColor White
    Write-Host "  GroupCategory: $($group.GroupCategory)" -ForegroundColor White
    Write-Host "  GroupScope: $($group.GroupScope)" -ForegroundColor White
    Write-Host "  DistinguishedName: $($group.DistinguishedName)" -ForegroundColor White
    if ($group.Description) {
        Write-Host "  Description: $($group.Description)" -ForegroundColor White
    }
    
    # Get group members
    $members = Get-ADGroupMember -Identity $group.DistinguishedName -Server $Server -Credential $Credential -Recursive
    
    if ($members) {
        Write-Host "`nGroup Members:" -ForegroundColor Green
        Write-Host "Total: $($members.Count) members" -ForegroundColor Yellow
        Write-Host ""
        
        # Separate by object type
        $users = $members | Where-Object { $_.objectClass -eq 'user' }
        $groups = $members | Where-Object { $_.objectClass -eq 'group' }
        $computers = $members | Where-Object { $_.objectClass -eq 'computer' }
        
        if ($users) {
            Write-Host "Users ($($users.Count)):" -ForegroundColor Cyan
            $users | Select-Object Name, SamAccountName, objectClass | Format-Table -AutoSize
        }
        
        if ($groups) {
            Write-Host "Nested Groups ($($groups.Count)):" -ForegroundColor Cyan
            $groups | Select-Object Name, SamAccountName, objectClass | Format-Table -AutoSize
        }
        
        if ($computers) {
            Write-Host "Computers ($($computers.Count)):" -ForegroundColor Cyan
            $computers | Select-Object Name, SamAccountName, objectClass | Format-Table -AutoSize
        }
        
        # Export to CSV
        $csvPath = ".\${GroupName}_Members_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $members | Select-Object Name, SamAccountName, objectClass, distinguishedName | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-Host "Results exported to: $csvPath" -ForegroundColor Green
    } else {
        Write-Host "`nNo members found in group '$GroupName'" -ForegroundColor Yellow
    }
}
catch {
    Write-Error "Error querying group: $_"
}
