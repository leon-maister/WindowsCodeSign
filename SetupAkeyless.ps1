# ==============================================
# setupAkeyless.ps1 — perfect sync between console & log
# Transcript captures Write-Host, but we strip ONLY transcript header/footer
# (cuts everything through "SerializationVersion: 1.1.0.1" and everything from
#  "Windows PowerShell transcript end" and below)
# ==============================================

$loggerName = "setupAkeyless"
$logFile = "C:\Data\Signer\log-setupAkeyless.log"

# Clean old log if exists
if (Test-Path $logFile) { Remove-Item $logFile -Force }

# Script order
$scripts = @(
    "C:\Data\Signer\Step_0_Set_Env_Variables.ps1",
    "C:\Data\Signer\Step_2_Akeyless_CleanUp.ps1",
    "C:\Data\Signer\Step_1_Init_Akeyless_environment.ps1",
    "C:\Data\Signer\Step_3_Bring_Root_Certificate.ps1"
)

# Function for console + log output
function Log {
    param([string]$Message, [string]$Color = "White")
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

# Wrapper to capture Write-Host output too
function Run-WithLogging {
    param([string]$ScriptPath)

    # Use a temporary transcript to capture Write-Host output
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

    # Append ONLY transcript body (no header/footer)
    $body = Get-TranscriptBody -TranscriptPath $tempTranscript
    if ($body.Count -gt 0) {
        Add-Content -Path $logFile -Value $body
    }

    Remove-Item $tempTranscript -Force
}

# ==============================================
# MAIN EXECUTION
# ==============================================

Log "Starting setup process..." "Cyan"

foreach ($script in $scripts) {
    Log "==================================================" "DarkGray"
    Log "Executing: $script ..." "Yellow"

    Run-WithLogging $script

    Log "Finished: $script" "Green"
    Log "==================================================" "DarkGray"
}

Log "Setup completed. Log saved to $logFile" "Cyan"
