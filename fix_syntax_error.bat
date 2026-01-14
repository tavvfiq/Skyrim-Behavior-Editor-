@echo off
setlocal

:: --- CONFIGURATION ---
:: Define which file extensions to scan
set "extensions=*.cpp, *.h, *.hpp, *.c"

echo ========================================================
echo  Auto-Converter: Ternary to If-Else
echo ========================================================
echo  Scanning directory: %CD%
echo  Targeting: %extensions%
echo.
echo  WARNING: This will overwrite files in place.
echo  Press Ctrl+C to cancel, or any key to start...
pause >nul

:: --- POWERSHELL EXECUTION ---
:: We use PowerShell to iterate recursively and handle the regex replacement.
:: The regex logic:
:: 1. ^(\s*)       -> Capture indentation (Group 1)
:: 2. \((.+?)\)    -> Capture condition inside parens (Group 2)
:: 3. \?           -> Literal ?
:: 4. \s*(.+?)\s* -> Capture True action (Group 3)
:: 5. :            -> Literal :
:: 6. \s*(.+?)\s* -> Capture False action (Group 4)
:: 7. (?:,|;)      -> Stop capturing at the first comma OR semicolon
:: 8. .*$          -> Ignore everything else (like ", NULL;")

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$files = Get-ChildItem -Path . -Recurse -Include %extensions%;" ^
    "foreach ($file in $files) {" ^
    "    $content = Get-Content -LiteralPath $file.FullName;" ^
    "    $modified = $false;" ^
    "    $newContent = $content | ForEach-Object {" ^
    "        if ($_ -match '^(\s*)\((.+?)\)\s*\?\s*(.+?)\s*:\s*(.+?)\s*(?:,|;).*$') {" ^
    "            $modified = $true;" ^
    "            $indent = $matches[1];" ^
    "            $cond   = $matches[2];" ^
    "            $trueOp = $matches[3];" ^
    "            $falseOp= $matches[4];" ^
    "            $indent + 'if (' + $cond + ') {' + [Environment]::NewLine + " ^
    "            $indent + '    ' + $trueOp + ';' + [Environment]::NewLine + " ^
    "            $indent + '} else {' + [Environment]::NewLine + " ^
    "            $indent + '    ' + $falseOp + ';' + [Environment]::NewLine + " ^
    "            $indent + '}'" ^
    "        } else {" ^
    "            $_" ^
    "        }" ^
    "    };" ^
    "    if ($modified) {" ^
    "        Set-Content -LiteralPath $file.FullName -Value $newContent;" ^
    "        Write-Host 'Modified: ' $file.Name -ForegroundColor Green" ^
    "    }" ^
    "}"

echo.
echo ========================================================
echo  Done.
echo ========================================================
pause