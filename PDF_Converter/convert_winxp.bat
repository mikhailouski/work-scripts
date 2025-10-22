@echo off
setlocal ENABLEDELAYEDEXPANSION

:: === Configuration ===
set "INPUT_DIR=.\input"
set "OUTPUT_DIR=.\output"
set "LOG_DIR=.\logs"
set "GS=C:\Program Files\gs\gs9.26\bin\gswin32c.exe"

if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

:: === Log file setup ===
for /f "tokens=2-4 delims=/. " %%a in ('date /t') do set DATESTAMP=%%c%%b%%a
for /f "tokens=1-2 delims=: " %%a in ("%time%") do set TIMESTAMP=%%a%%b
set "LOG_FILE=%LOG_DIR%\conversion_log_%DATESTAMP%_%TIMESTAMP%.txt"

echo === START TIME: %DATE% %TIME% === > "%LOG_FILE%"

:: === Initialize Counters ===
set processed=0
set success_count=0
set error_count=0
set skipped_count=0

:: === Count total files ===
set total_files=0
for %%F in ("%INPUT_DIR%\*.pdf") do (
    set /a total_files+=1
)

echo Total files detected: %total_files% >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

:: === Loop through files ===
for %%F in ("%INPUT_DIR%\*.pdf") do (
    set /a processed+=1
    set "FILENAME=%%~nxF"
    set "BASENAME=%%~nF"
    set "INPUT_FILE=%%F"
    set "OUTPUT_FILE=%OUTPUT_DIR%\!BASENAME!_PDFA.pdf"

    echo
    echo [!TIME!] PROCESSING  ^| !FILENAME!
    if exist "!OUTPUT_FILE!" (
        set /a skipped_count+=1
        echo [!TIME!] SKIPPED  ^| !FILENAME! ^| Already exists in output
        echo [!TIME!] SKIPPED  ^| !FILENAME! ^| Already exists in output >> "%LOG_FILE%"
    ) else (
        "%GS%" -sDEVICE=pdfwrite -dPDFA=1 -dPDFACompatibilityPolicy=1 -dNOPAUSE -dBATCH -dQUIET -sOutputFile="!OUTPUT_FILE!" "!INPUT_FILE!"
        if errorlevel 1 (
            set /a error_count+=1
            echo [!TIME!] ERROR   ^| !FILENAME! ^| Conversion failed
            echo [!TIME!] ERROR   ^| !FILENAME! ^| Conversion failed >> "%LOG_FILE%"
        ) else (
            set /a success_count+=1
            echo [!TIME!] SUCCESS ^| !FILENAME! ^| Converted successfully
            echo [!TIME!] SUCCESS ^| !FILENAME! ^| Converted successfully >> "%LOG_FILE%"
        )
    )
)

:: === Summary ===
echo. >> "%LOG_FILE%"
echo === CONVERSION SUMMARY === >> "%LOG_FILE%"
echo New files processed: %success_count% >> "%LOG_FILE%"
echo Files skipped (existing): %skipped_count% >> "%LOG_FILE%"
echo Errors encountered: %error_count% >> "%LOG_FILE%"
echo === COMPLETED: %DATE% %TIME% === >> "%LOG_FILE%"

:: === Completion output ===
echo.
echo Conversion completed.
echo ---------------------
echo New files processed: %success_count%
echo Files skipped:       %skipped_count%
echo Errors:              %error_count%
echo Log file saved to:   %LOG_FILE%

endlocal
pause
