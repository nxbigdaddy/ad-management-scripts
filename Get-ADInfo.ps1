#requires -Version 5.1
<#
.SYNOPSIS
    Connect to Windows AD Server and retrieve user info, OU list, etc.
.DESCRIPTION
    This script connects to a specified Windows AD server and retrieves user lists, OU lists, computer lists, etc.
.PARAMETER Server
    AD server IP address or hostname
.PARAMETER Credential
    Credentials for connecting to AD
.PARAMETER Domain
    Domain name (e.g., demo)
.EXAMPLE
    .\Get-ADInfo.ps1 -Server "203.0.113.10" -Domain "demo" -Credential (Get-Credential)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Server = "203.0.113.10",
    
    [Parameter(Mandatory = $false)]
    [string]$Server2 = "203.0.113.10",
    
    [Parameter(Mandatory = $false)]
    [string]$Domain = "demo",
    
    [Parameter(Mandatory = $false)]
    [System.Management.Automation.PSCredential]$Credential,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\ADReports"
)

# Set error handling
$ErrorActionPreference = "Stop"

# Create output directory
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    Write-Host "Created output directory: $OutputPath" -ForegroundColor Green
}

# Prompt for credentials if not provided
if (-not $Credential) {
    Write-Host "Please enter AD administrator credentials (e.g., demo\administrator)" -ForegroundColor Yellow
    $Credential = Get-Credential -Message "Please enter AD administrator credentials"
}

# Build domain controller list
$servers = @($Server)
if ($Server2) {
    $servers += $Server2
}

# Try to connect to AD server
$connectedServer = $null
foreach ($srv in $servers) {
    try {
        Write-Host "Trying to connect to AD server: $srv ..." -ForegroundColor Cyan
        
        # Test connection
        $testConnection = Test-Connection -ComputerName $srv -Count 1 -Quiet -ErrorAction SilentlyContinue
        if (-not $testConnection) {
            Write-Warning "Cannot ping server: $srv"
            continue
        }
        
        # Try to get AD domain info
        $domainInfo = Get-ADDomain -Server $srv -Credential $Credential -ErrorAction Stop
        $connectedServer = $srv
        Write-Host "Successfully connected to AD server: $srv" -ForegroundColor Green
        Write-Host "Domain info: $($domainInfo.DNSRoot)" -ForegroundColor Green
        break
    }
    catch {
        Write-Warning "Failed to connect to server $srv : $_"
    }
}

if (-not $connectedServer) {
    throw "Unable to connect to any AD server"
}

# Set AD server for subsequent operations
$ADServer = $connectedServer

# ============================================
# Function: Get User List
# ============================================
function Get-ADUsersList {
    param(
        [string]$Server,
        [System.Management.Automation.PSCredential]$Cred
    )
    
    Write-Host "`nRetrieving user list..." -ForegroundColor Cyan
    
    try {
        $users = Get-ADUser -Filter * -Server $Server -Credential $Cred -Properties `
            Name, DisplayName, SamAccountName, UserPrincipalName, EmailAddress, `
            Enabled, LastLogonDate, PasswordLastSet, Created, Modified, `
            DistinguishedName, Department, Title, Office, TelephoneNumber
        
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
            Modified,
            Department,
            Title,
            Office,
            TelephoneNumber,
            @{Name = 'OU'; Expression = { 
                ($_.DistinguishedName -split ',')[1..($_.DistinguishedName.Split(',').Length - 1)] -join ',' 
            }}
        
        # Export to CSV
        $csvPath = Join-Path $OutputPath "AD_Users_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $userList | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        
        # Export to JSON
        $jsonPath = Join-Path $OutputPath "AD_Users_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $userList | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonPath -Encoding UTF8
        
        Write-Host "User list saved:" -ForegroundColor Green
        Write-Host "  CSV: $csvPath" -ForegroundColor Gray
        Write-Host "  JSON: $jsonPath" -ForegroundColor Gray
        Write-Host "  Total: $($userList.Count) users" -ForegroundColor Yellow
        
        return $userList
    }
    catch {
        Write-Error "Failed to get user list: $_"
        return $null
    }
}

# ============================================
# Function: Get OU List
# ============================================
function Get-ADOrganizationalUnits {
    param(
        [string]$Server,
        [System.Management.Automation.PSCredential]$Cred
    )
    
    Write-Host "`nRetrieving OU list..." -ForegroundColor Cyan
    
    try {
        $ous = Get-ADOrganizationalUnit -Filter * -Server $Server -Credential $Cred -Properties `
            Name, DistinguishedName, Created, Modified, Description, ManagedBy
        
        $ouList = $ous | Select-Object `
            Name,
            DistinguishedName,
            Created,
            Modified,
            Description,
            ManagedBy,
            @{Name = 'ParentOU'; Expression = {
                $dn = $_.DistinguishedName
                if ($dn -match 'OU=([^,]+),(.+)') {
                    $matches[2]
                } else {
                    "Root"
                }
            }},
            @{Name = 'Level'; Expression = {
                ($_.DistinguishedName -split 'OU=').Count - 1
            }}
        
        # Sort by level
        $ouList = $ouList | Sort-Object Level, DistinguishedName
        
        # Export to CSV
        $csvPath = Join-Path $OutputPath "AD_OUs_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $ouList | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        
        # Export to JSON
        $jsonPath = Join-Path $OutputPath "AD_OUs_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $ouList | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonPath -Encoding UTF8
        
        # Create tree structure text
        $treePath = Join-Path $OutputPath "AD_OUs_Tree_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        $treeContent = @()
        $treeContent += "Active Directory Organizational Structure"
        $treeContent += "========================================"
        $treeContent += ""
        
        foreach ($ou in $ouList) {
            $indent = "  " * ($ou.Level - 1)
            $treeContent += "$indent[$($ou.Level)] $($ou.Name)"
        }
        
        $treeContent | Out-File -FilePath $treePath -Encoding UTF8
        
        Write-Host "OU list saved:" -ForegroundColor Green
        Write-Host "  CSV: $csvPath" -ForegroundColor Gray
        Write-Host "  JSON: $jsonPath" -ForegroundColor Gray
        Write-Host "  Tree: $treePath" -ForegroundColor Gray
        Write-Host "  Total: $($ouList.Count) OUs" -ForegroundColor Yellow
        
        return $ouList
    }
    catch {
        Write-Error "Failed to get OU list: $_"
        return $null
    }
}

# ============================================
# Function: Get Computer List
# ============================================
function Get-ADComputersList {
    param(
        [string]$Server,
        [System.Management.Automation.PSCredential]$Cred
    )
    
    Write-Host "`nRetrieving computer list..." -ForegroundColor Cyan
    
    try {
        $computers = Get-ADComputer -Filter * -Server $Server -Credential $Cred -Properties `
            Name, DNSHostName, Enabled, LastLogonDate, Created, Modified, `
            DistinguishedName, OperatingSystem, OperatingSystemVersion, IPv4Address
        
        $computerList = $computers | Select-Object `
            Name,
            DNSHostName,
            Enabled,
            LastLogonDate,
            Created,
            Modified,
            OperatingSystem,
            OperatingSystemVersion,
            IPv4Address,
            @{Name = 'OU'; Expression = { 
                ($_.DistinguishedName -split ',')[1..($_.DistinguishedName.Split(',').Length - 1)] -join ',' 
            }}
        
        # Export to CSV
        $csvPath = Join-Path $OutputPath "AD_Computers_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $computerList | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        
        # Export to JSON
        $jsonPath = Join-Path $OutputPath "AD_Computers_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $computerList | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonPath -Encoding UTF8
        
        Write-Host "Computer list saved:" -ForegroundColor Green
        Write-Host "  CSV: $csvPath" -ForegroundColor Gray
        Write-Host "  JSON: $jsonPath" -ForegroundColor Gray
        Write-Host "  Total: $($computerList.Count) computers" -ForegroundColor Yellow
        
        return $computerList
    }
    catch {
        Write-Error "Failed to get computer list: $_"
        return $null
    }
}

# ============================================
# Function: Get Group List
# ============================================
function Get-ADGroupsList {
    param(
        [string]$Server,
        [System.Management.Automation.PSCredential]$Cred
    )
    
    Write-Host "`nRetrieving group list..." -ForegroundColor Cyan
    
    try {
        $groups = Get-ADGroup -Filter * -Server $Server -Credential $Cred -Properties `
            Name, SamAccountName, GroupCategory, GroupScope, Description, Created, Modified, Members, DistinguishedName
        
        $groupList = $groups | Select-Object `
            Name,
            SamAccountName,
            GroupCategory,
            GroupScope,
            Description,
            Created,
            Modified,
            @{Name = 'MemberCount'; Expression = { 
                if ($_.Members) { ($_.Members).Count } else { 0 }
            }},
            @{Name = 'OU'; Expression = { 
                ($_.DistinguishedName -split ',')[1..($_.DistinguishedName.Split(',').Length - 1)] -join ',' 
            }}
        
        # Export to CSV
        $csvPath = Join-Path $OutputPath "AD_Groups_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $groupList | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        
        # Export to JSON
        $jsonPath = Join-Path $OutputPath "AD_Groups_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $groupList | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonPath -Encoding UTF8
        
        Write-Host "Group list saved:" -ForegroundColor Green
        Write-Host "  CSV: $csvPath" -ForegroundColor Gray
        Write-Host "  JSON: $jsonPath" -ForegroundColor Gray
        Write-Host "  Total: $($groupList.Count) groups" -ForegroundColor Yellow
        
        return $groupList
    }
    catch {
        Write-Error "Failed to get group list: $_"
        return $null
    }
}

# ============================================
# Function: Generate Summary Report
# ============================================
function New-ADSummaryReport {
    param(
        [array]$Users,
        [array]$OUs,
        [array]$Computers,
        [array]$Groups
    )
    
    Write-Host "`nGenerating summary report..." -ForegroundColor Cyan
    
    $report = @{
        GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Server = $ADServer
        Domain = $Domain
        Statistics = @{
            TotalUsers = if ($Users) { $Users.Count } else { 0 }
            EnabledUsers = if ($Users) { ($Users | Where-Object { $_.Enabled -eq $true }).Count } else { 0 }
            DisabledUsers = if ($Users) { ($Users | Where-Object { $_.Enabled -eq $false }).Count } else { 0 }
            TotalOUs = if ($OUs) { $OUs.Count } else { 0 }
            TotalComputers = if ($Computers) { $Computers.Count } else { 0 }
            EnabledComputers = if ($Computers) { ($Computers | Where-Object { $_.Enabled -eq $true }).Count } else { 0 }
            TotalGroups = if ($Groups) { $Groups.Count } else { 0 }
            SecurityGroups = if ($Groups) { ($Groups | Where-Object { $_.GroupCategory -eq "Security" }).Count } else { 0 }
            DistributionGroups = if ($Groups) { ($Groups | Where-Object { $_.GroupCategory -eq "Distribution" }).Count } else { 0 }
        }
    }
    
    # Export summary report
    $jsonPath = Join-Path $OutputPath "AD_Summary_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $report | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonPath -Encoding UTF8
    
    # Create text report
    $txtPath = Join-Path $OutputPath "AD_Summary_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $txtContent = @"
========================================
Active Directory Summary Report
========================================
Generated At: $($report.GeneratedAt)
AD Server: $($report.Server)
Domain: $($report.Domain)

Statistics:
----------------------------------------
User Statistics:
  - Total Users: $($report.Statistics.TotalUsers)
  - Enabled Users: $($report.Statistics.EnabledUsers)
  - Disabled Users: $($report.Statistics.DisabledUsers)

OU Statistics:
  - Total OUs: $($report.Statistics.TotalOUs)

Computer Statistics:
  - Total Computers: $($report.Statistics.TotalComputers)
  - Enabled Computers: $($report.Statistics.EnabledComputers)

Group Statistics:
  - Total Groups: $($report.Statistics.TotalGroups)
  - Security Groups: $($report.Statistics.SecurityGroups)
  - Distribution Groups: $($report.Statistics.DistributionGroups)
========================================
"@
    
    $txtContent | Out-File -FilePath $txtPath -Encoding UTF8
    
    Write-Host "Summary report saved:" -ForegroundColor Green
    Write-Host "  JSON: $jsonPath" -ForegroundColor Gray
    Write-Host "  TXT: $txtPath" -ForegroundColor Gray
    
    # Display statistics
    Write-Host "`n========== AD Statistics ==========" -ForegroundColor Cyan
    Write-Host "Total Users: $($report.Statistics.TotalUsers)" -ForegroundColor White
    Write-Host "  - Enabled: $($report.Statistics.EnabledUsers)" -ForegroundColor Green
    Write-Host "  - Disabled: $($report.Statistics.DisabledUsers)" -ForegroundColor Red
    Write-Host "Total OUs: $($report.Statistics.TotalOUs)" -ForegroundColor White
    Write-Host "Total Computers: $($report.Statistics.TotalComputers)" -ForegroundColor White
    Write-Host "Total Groups: $($report.Statistics.TotalGroups)" -ForegroundColor White
    Write-Host "===================================" -ForegroundColor Cyan
    
    return $report
}

# ============================================
# Main Execution Logic
# ============================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Active Directory Information Collection Tool" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Execute data collection
$users = Get-ADUsersList -Server $ADServer -Cred $Credential
$ous = Get-ADOrganizationalUnits -Server $ADServer -Cred $Credential
$computers = Get-ADComputersList -Server $ADServer -Cred $Credential
$groups = Get-ADGroupsList -Server $ADServer -Cred $Credential

# Generate summary report
$summary = New-ADSummaryReport -Users $users -OUs $ous -Computers $computers -Groups $groups

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Data collection completed!" -ForegroundColor Green
Write-Host "All files saved to: $((Resolve-Path $OutputPath).Path)" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
