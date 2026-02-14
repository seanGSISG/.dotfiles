# Utility Aliases
# General system and productivity shortcuts

# System utilities
function ports {                                    # listening ports
    try {
        Get-NetTCPConnection -State Listen -ErrorAction Stop | Format-Table -AutoSize
    } catch {
        Write-Warning "Failed to retrieve listening TCP connections. The 'Get-NetTCPConnection' cmdlet may be unavailable, or you may lack the required permissions."
        Write-Verbose ("Underlying error: " + $_.Exception.Message)
    }
}
function path { $env:Path -split ';' }              # display PATH entries
function myip { (Invoke-WebRequest -Uri "https://ifconfig.me" -TimeoutSec 5).Content.Trim() }     # public IP
function localip {                                   # local IP
    (Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object { $_.InterfaceAlias -notmatch 'Loopback' -and $_.IPAddress -ne '127.0.0.1' }
    ).IPAddress | Select-Object -First 1
}
function weather { (Invoke-WebRequest -Uri "https://wttr.in/?format=3" -TimeoutSec 5).Content.Trim() }
function cls { Clear-Host }                          # clear screen
function h { Get-History }                           # history
function hg {                                        # history grep
    param([Parameter(Mandatory)][string]$Pattern)
    Get-History | Where-Object CommandLine -match $Pattern
}

# Editor
function e { & $env:EDITOR @args }                  # launch editor

# Safe file operations (prompt before overwrite/delete)
$PSDefaultParameterValues['Remove-Item:Confirm'] = $true
$PSDefaultParameterValues['Move-Item:Confirm'] = $true
$PSDefaultParameterValues['Copy-Item:Confirm'] = $true

# List improvements (use eza if available, fallback to Get-ChildItem)
if (Get-Command eza -ErrorAction SilentlyContinue) {
    function ll { & eza -lah @args }                # long list with hidden
    function la { & eza -a @args }                  # list all
    function l { & eza -F @args }                   # list with indicators
} else {
    function ll { Get-ChildItem -Force @args }      # long list with hidden
    function la { Get-ChildItem -Force -Name @args }  # list all names
    function l { Get-ChildItem @args }              # basic list
}

# Disk usage
function df { Get-PSDrive -PSProvider FileSystem | Format-Table Name, @{N='Used(GB)';E={[math]::Round($_.Used/1GB,1)}}, @{N='Free(GB)';E={[math]::Round($_.Free/1GB,1)}}, Root -AutoSize }
function du {
    param([string]$Path = ".")
    $size = (Get-ChildItem $Path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    "{0:N1} MB" -f ($size / 1MB)
}

# Tail equivalent
function t {
    param([Parameter(Mandatory)][string]$Path)
    Get-Content $Path -Wait -Tail 20
}
