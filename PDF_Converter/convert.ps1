# Configuration
$input_dir  = ".\input"
$output_dir = ".\output"
$log_file   = ".\logs\conversion_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Initialization
$script_start = Get-Date
$all_input_files = Get-ChildItem -Path "$input_dir\*.pdf"
$total_files = $all_input_files.Count
$processed = 0
$success_count = 0
$error_count = 0
$skipped_count = 0

# Create directories if missing
if (-not (Test-Path $output_dir)) { New-Item -ItemType Directory -Path $output_dir -Force }

# Log header
Add-Content -Path $log_file -Value "=== START TIME: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="
Add-Content -Path $log_file -Value "Total files detected: $total_files"
Add-Content -Path $log_file -Value ""

# Function to check for existing output
function Test-OutputFile($inputFile) {
    $output_name = "$($inputFile.BaseName)_PDFA.pdf"
    $output_path = Join-Path -Path $output_dir -ChildPath $output_name
    return Test-Path -Path $output_path
}

# File processing loop
foreach ($input_file in $all_input_files) {
    $processed++
    $percent_complete = ($processed / $total_files) * 100
    
    # Progress bar
    Write-Progress -Activity "PDF Conversion in Progress" `
                   -Status "Processing file $processed of $total_files ($([math]::Round($percent_complete, 1))%)" `
                   -CurrentOperation $input_file.Name `
                   -PercentComplete $percent_complete

    # Skip if output exists
    if (Test-OutputFile -inputFile $input_file) {
        $skipped_count++
        Add-Content -Path $log_file -Value "[$(Get-Date -Format 'HH:mm:ss')] SKIPPED | $($input_file.Name) | Already exists in output"
        continue
    }

    # Conversion process
    $output_path = "$output_dir\$($input_file.BaseName)_PDFA.pdf"
    $file_start = Get-Date
    
    try {
        & "gswin64c" -sDEVICE=pdfwrite -dPDFA=1 -dPDFACompatibilityPolicy=1 `
                     -dNOPAUSE -dBATCH -dQUIET `
                     -sOutputFile="$output_path" "$($input_file.FullName)"
        
        $duration = (Get-Date) - $file_start
        $success_count++
        Add-Content -Path $log_file -Value "[$(Get-Date -Format 'HH:mm:ss')] SUCCESS | $($input_file.Name) | Processing time: $($duration.TotalSeconds.ToString('0.00')) sec."
    }
    catch {
        $error_count++
        Add-Content -Path $log_file -Value "[$(Get-Date -Format 'HH:mm:ss')] ERROR | $($input_file.Name) | $($_.Exception.Message)"
    }
}

# Final statistics
$total_time = (Get-Date) - $script_start
Add-Content -Path $log_file -Value ""
Add-Content -Path $log_file -Value "=== CONVERSION SUMMARY ==="
Add-Content -Path $log_file -Value "New files processed: $success_count"
Add-Content -Path $log_file -Value "Files skipped (existing): $skipped_count"
Add-Content -Path $log_file -Value "Errors encountered: $error_count"
Add-Content -Path $log_file -Value "Total execution time: $($total_time.TotalMinutes.ToString('0.00')) min."
Add-Content -Path $log_file -Value "=== COMPLETED: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="

# Completion message
Write-Progress -Activity "PDF Conversion" -Completed -Status "Done!"
Write-Host "Conversion results:"
Write-Host "  New files processed: $success_count"
Write-Host "  Files skipped: $skipped_count"
Write-Host "  Errors: $error_count"
Write-Host "Total execution time: $($total_time.TotalMinutes.ToString('0.00')) min."
Write-Host "Log file saved to: $log_file"