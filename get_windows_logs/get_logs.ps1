# $startNum = 10276
# $endNum = 10425
# $computers = foreach ($num in $startNum..$endNum) { "PC-$num" }
$computer = "PC-10459"
$logName = "Microsoft-Windows-Kernel-Power%4Thermal-Operational"

$destinationFolder = "C:\Logs\SystemEvents\"
$logFile = "$destinationFolder\CopyLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

if (!(Test-Path $destinationFolder)) { New-Item -ItemType Directory -Path $destinationFolder -Force }

function Write-Log {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $message"
    Write-Host $logEntry  
    Add-Content -Path $logFile -Value $logEntry  
}

Write-Log "=== Начало копирования файлов $logName.evtx ==="


    $sourcePath = "\\$computer\C$\Windows\System32\winevt\Logs\$logName.evtx"
    $destinationPath = "$destinationFolder\$computer`_$logName.evtx"
    
    if (Test-Connection -ComputerName $computer -Count 1 -Quiet) {
        try {
            Copy-Item -Path $sourcePath -Destination $destinationPath -ErrorAction Stop
            Write-Log "УСПЕХ: Файл скопирован с $computer"
        }
        catch {
            Write-Log "ОШИБКА: Не удалось скопировать с $computer ($_)"
        }
    }
    else {
        Write-Log "ОФФЛАЙН: $computer недоступен"
    }


Write-Log "=== Копирование завершено ==="
Write-Host "Лог сохранён в $logFile" -ForegroundColor Cyan