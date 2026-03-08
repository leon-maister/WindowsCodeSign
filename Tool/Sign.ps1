# ============================================
# Master Automation Script — perfect sync between console & log
# Uses Transcript (captures Write-Host) BUT strips ONLY the transcript header/footer
# by cutting:
#   - everything from "Windows PowerShell transcript start" through
#     "SerializationVersion: 1.1.0.1"
#   - everything from "Windows PowerShell transcript end" and below
# ============================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# ----- CONFIG -----
$loggerName = "SetupAutomation"
$basePath   = "C:\Data\Signer\Tool"
$logFile    = Join-Path $basePath "SetupAutomation.log"

# Scripts to execute in order
$scripts = @(
    "Step_00_Setup_Env_Variable.ps1",
    "Step_01_Prerequisite_Verification.ps1",
    "Step_04_Helper_Configuration_Verification.ps1",
    "Step_05_Bring_Cert.ps1",
    "Step_06_Thumbprint_Calculation.ps1",
    "Step_07_SignTheFile.ps1",
    "Step_08_Verify_Signature.ps1"
)

# Clean old log if exists
if (Test-Path $logFile) { Remove-Item $logFile -Force }

# Function for console + log output
function Log {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [string]$Color = "White"
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $formatted = "[$timestamp] [$loggerName] $Message"
    Write-Host $formatted -ForegroundColor $Color
    Add-Content -Path $logFile -Value $formatted
}

# Extract ONLY transcript BODY (no transcript header/footer)
function Get-TranscriptBody {
    param([Parameter(Mandatory=$true)][string]$TranscriptPath)

    $lines = Get-Content -Path $TranscriptPath

    # End of transcript header: "SerializationVersion: 1.1.0.1"
    $headerEndIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^SerializationVersion:\s*1\.1\.0\.1\s*$') {
            $headerEndIdx = $i
            break
        }
    }

    # Start of transcript footer: "Windows PowerShell transcript end"
    $footerStartIdx = $lines.Count
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*Windows PowerShell transcript end\s*$') {
            $footerStartIdx = $i
            break
        }
    }

    # Body = everything AFTER header and BEFORE footer
    $startIdx = if ($headerEndIdx -ge 0) { $headerEndIdx + 1 } else { 0 }
    $endIdx   = $footerStartIdx - 1

    if ($endIdx -lt $startIdx) { return @() }

    return $lines[$startIdx..$endIdx]
}

# Wrapper to capture Write-Host output too (via Transcript)
function Run-WithLogging {
    param([Parameter(Mandatory=$true)][string]$ScriptPath)

    $tempTranscript = [System.IO.Path]::GetTempFileName()
    Start-Transcript -Path $tempTranscript -Append | Out-Null

    try {
        & $ScriptPath
    }
    catch {
        Log "ERROR: $($_.Exception.Message)" "Red"
    }
    finally {
        Stop-Transcript | Out-Null
    }

    # Append ONLY body (no header/footer)
    $body = Get-TranscriptBody -TranscriptPath $tempTranscript
    if ($body.Count -gt 0) {
        Add-Content -Path $logFile -Value $body
    }

    Remove-Item $tempTranscript -Force
}

# ============================================
# MAIN EXECUTION
# ============================================

Log "Starting full setup automation..." "Cyan"
Log "BasePath: $basePath" "DarkGray"
Log "LogFile : $logFile" "DarkGray"

foreach ($script in $scripts) {
    $scriptPath = Join-Path $basePath $script

    Log "==================================================" "DarkGray"
    Log "Executing: $scriptPath ..." "Yellow"

    if (Test-Path $scriptPath) {
        Run-WithLogging $scriptPath
        Log "Finished: $script" "Green"
    }
    else {
        Log "[Skipped] Script not found: $scriptPath" "DarkGray"
    }

    Log "==================================================" "DarkGray"
    Start-Sleep -Seconds 1
}

Log "Automation completed. Log saved to $logFile" "Cyan"
