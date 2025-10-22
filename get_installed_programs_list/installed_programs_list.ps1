$computerName = $env:COMPUTERNAME

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

$outputFile = Join-Path $scriptDir "${computerName}_Installed_Programs.txt"

# Get installed programs list
Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*, `
                  HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* `
| Where-Object { $_.DisplayName } `
| Select-Object DisplayName, Publisher, InstallDate, DisplayVersion `
| Sort-Object DisplayName `
| ForEach-Object {
    $installDate = $_.InstallDate
    if ($installDate -match '^\d{8}$') {
        $installDate = [datetime]::ParseExact($installDate, 'yyyyMMdd', $null).ToString('yyyy-MM-dd')
    }
    "{0} | Version: {1} | Publisher: {2} | Installed: {3}" -f $_.DisplayName, $_.DisplayVersion, $_.Publisher, $installDate
} > $outputFile