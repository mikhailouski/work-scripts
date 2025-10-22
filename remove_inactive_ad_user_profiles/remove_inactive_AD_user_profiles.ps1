param(
    [switch]$NoConfirm  # Parameter for deleting without confirmation
)

# === Settings ===
$logPath = "C:\Logs\DisabledDomainUsers_MatchProfiles.log"
$disabledUsersPath = "C:\Logs\DisabledDomainUsers.txt"
$matchedProfilesPath = "C:\Logs\MatchedProfiles.txt"

# Ensure the log directory exists
New-Item -Path (Split-Path $logPath) -ItemType Directory -Force | Out-Null

# Get disabled domain users
Write-Output "[$(Get-Date)] Retrieving disabled domain users..." | Tee-Object -FilePath $logPath -Append

Import-Module ActiveDirectory
$disabledUsers = Get-ADUser -Filter 'Enabled -eq $false' -Properties SamAccountName |
    Select-Object -ExpandProperty SamAccountName

# Save list of disabled users
$disabledUsers | Sort-Object | Out-File -FilePath $disabledUsersPath -Encoding UTF8
Write-Output "[$(Get-Date)] Disabled user accounts found: $($disabledUsers.Count)" | Tee-Object -FilePath $logPath -Append

# Convert to lowercase for comparison
$disabledUsersLower = $disabledUsers | ForEach-Object { $_.ToLower() }

# Get local user profiles
$profiles = Get-CimInstance -ClassName Win32_UserProfile | Where-Object {
    -not $_.Special -and $_.LocalPath -like "C:\Users\*"
}

# Check and optionally delete matching profiles
$matchedProfiles = @()

foreach ($profile in $profiles) {
    $sid = $profile.SID

    try {
        $account = (New-Object System.Security.Principal.SecurityIdentifier($sid)).Translate([System.Security.Principal.NTAccount]).Value
        $username = $account.Split('\')[1].ToLower()
    } catch {
        Write-Warning "Failed to translate SID $sid"
        continue
    }

    if ($disabledUsersLower -contains $username) {
        $info = "$username`t$($profile.LocalPath)"
        $matchedProfiles += $info
        Write-Output "[$(Get-Date)] Found local profile of disabled user: $info" | Tee-Object -FilePath $logPath -Append

        # If NoConfirm flag is set, remove profile without asking
        if ($NoConfirm) {
            try {
                $profile | Remove-CimInstance
                Write-Output "[$(Get-Date)] Profile for '$username' removed successfully." | Tee-Object -FilePath $logPath -Append
            } catch {
                Write-Output "[$(Get-Date)] ERROR: Failed to remove profile for '$username' - $_" | Tee-Object -FilePath $logPath -Append
            }
        } else {
            # Prompt for confirmation if NoConfirm is not set
            $confirm = Read-Host "Delete profile for '$username' at path '$($profile.LocalPath)'? (y/n)"
            if ($confirm -eq 'y') {
                try {
                    $profile | Remove-CimInstance
                    Write-Output "[$(Get-Date)] Profile for '$username' removed successfully." | Tee-Object -FilePath $logPath -Append
                } catch {
                    Write-Output "[$(Get-Date)] ERROR: Failed to remove profile for '$username' - $_" | Tee-Object -FilePath $logPath -Append
                }
            } else {
                Write-Output "[$(Get-Date)] Skipped profile for '$username'" | Tee-Object -FilePath $logPath -Append
            }
        }
    }
}

# Save matched profiles list
$matchedProfiles | Sort-Object | Out-File -FilePath $matchedProfilesPath -Encoding UTF8
Write-Output "[$(Get-Date)] Total matched profiles: $($matchedProfiles.Count)" | Tee-Object -FilePath $logPath -Append