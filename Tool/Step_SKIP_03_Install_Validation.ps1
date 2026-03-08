# ===========================================
# Akeyless KSP Ultimate Health Check Script
# Checks:
#   1. Akeyless KSP core files
#   2. Registry configuration
#   3. KSP registration (certutil)
#   4. Native NCryptOpenStorageProvider() access
# Outputs color-coded results
# ===========================================

Write-Host "`n=== Akeyless KSP Health Check ===`n" -ForegroundColor Cyan
Write-Host $env:AKEYLESS_SQLCRYPT_CONFIG_PATH -ForegroundColor Cyan

# ========================================================
# SECTION 1 - Check required Akeyless KSP files
# ========================================================

$files = @(
    "C:\Windows\System32\AkeylessKsp.dll",
    "C:\Program Files\Akeyless\Akeyless KSP\akeyless-ksp-cert-helper.exe"
)

$results = foreach ($file in $files) {
    $item = Get-Item $file -ErrorAction SilentlyContinue

    if ($item) {
        [PSCustomObject]@{
            Component      = "File"
            Name           = Split-Path $file -Leaf
            Location       = $item.FullName
            Size_KB        = [math]::Round($item.Length / 1KB, 1)
            LastWriteTime  = $item.LastWriteTime
            Status         = "Found"
        }
    } else {
        [PSCustomObject]@{
            Component      = "File"
            Name           = Split-Path $file -Leaf
            Location       = $file
            Size_KB        = "-"
            LastWriteTime  = "-"
            Status         = "Missing"
        }
    }
}

# ========================================================
# SECTION 2 - Check registry configuration for KSP
# ========================================================

$regKeys = @(
    "HKLM\SYSTEM\CurrentControlSet\Control\Cryptography\Providers\Akeyless KSP",
    "HKLM\SOFTWARE\Microsoft\Cryptography\Providers\Akeyless KSP",
    "HKLM\SYSTEM\CurrentControlSet\Control\Cryptography\Configuration\Local\Default\00010001\KEY_STORAGE"
)

foreach ($key in $regKeys) {
    try {
        if ($key -like "*KEY_STORAGE*") {
            $value = (reg query $key /v Providers 2>$null)
            if ($value -match "Akeyless KSP") {
                $results += [PSCustomObject]@{
                    Component = "Registry"
                    Name      = "KEY_STORAGE Providers"
                    Location  = $key
                    Size_KB   = "-"
                    LastWriteTime = "-"
                    Status    = "Found"
                }
            } else {
                $results += [PSCustomObject]@{
                    Component = "Registry"
                    Name      = "KEY_STORAGE Providers"
                    Location  = $key
                    Size_KB   = "-"
                    LastWriteTime = "-"
                    Status    = "Missing"
                }
            }
        } else {
            $exists = Test-Path "Registry::$key"
            $results += [PSCustomObject]@{
                Component = "Registry"
                Name      = Split-Path $key -Leaf
                Location  = $key
                Size_KB   = "-"
                LastWriteTime = "-"
                Status    = if ($exists) { "Found" } else { "Missing" }
            }
        }
    } catch {
        $results += [PSCustomObject]@{
            Component = "Registry"
            Name      = Split-Path $key -Leaf
            Location  = $key
            Size_KB   = "-"
            LastWriteTime = "-"
            Status    = "Error"
        }
    }
}

# ========================================================
# SECTION 3 - Check KSP registration in CryptoAPI (certutil)
# ========================================================

Write-Host "`nRunning certutil check..." -ForegroundColor Yellow
$certutilOutput = certutil -csplist 2>$null | findstr /i "Akeyless"

if ($certutilOutput) {
    $results += [PSCustomObject]@{
        Component      = "CryptoAPI"
        Name           = "Akeyless KSP Registration"
        Location       = "certutil -csplist"
        Size_KB        = "-"
        LastWriteTime  = "-"
        Status         = "Found"
    }
} else {
    $results += [PSCustomObject]@{
        Component      = "CryptoAPI"
        Name           = "Akeyless KSP Registration"
        Location       = "certutil -csplist"
        Size_KB        = "-"
        LastWriteTime  = "-"
        Status         = "Missing"
    }
}

# ========================================================
# SECTION 4 - Native NCryptOpenStorageProvider() test
# ========================================================

Write-Host "`nTesting NCryptOpenStorageProvider() access..." -ForegroundColor Yellow

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class NCryptNative {
  [DllImport("ncrypt.dll", CharSet=CharSet.Unicode)]
  public static extern int NCryptOpenStorageProvider(out IntPtr phProvider, string pszProviderName, int dwFlags);
  [DllImport("ncrypt.dll")]
  public static extern int NCryptFreeObject(IntPtr hObject);
}
"@

$prov = "Akeyless KSP"
$h = [IntPtr]::Zero
$rc = [NCryptNative]::NCryptOpenStorageProvider([ref]$h, $prov, 0)
$u = if ($rc -lt 0) { [uint32]([int64]$rc + 0x100000000) } else { [uint32]$rc }

if ($rc -eq 0) {
    $status = "Found"
    Write-Host ("Successfully opened KSP provider. RC=0x{0:X8}" -f $u) -ForegroundColor Green
} else {
    $status = "Missing"
    Write-Host ("Failed to open provider. RC=0x{0:X8}" -f $u) -ForegroundColor Red
}

if ($h -ne [IntPtr]::Zero) { [void][NCryptNative]::NCryptFreeObject($h) }

$results += [PSCustomObject]@{
    Component      = "CNG"
    Name           = "NCryptOpenStorageProvider()"
    Location       = "ncrypt.dll"
    Size_KB        = "-"
    LastWriteTime  = "-"
    Status         = $status
}

# ========================================================
# SECTION 5 - Display results
# ========================================================

Write-Host "`n=== Results Summary ===`n" -ForegroundColor Yellow

foreach ($r in $results) {
    $output = ("{0,-10} {1,-35} {2,-70} {3,-10}" -f $r.Component, $r.Name, $r.Location, $r.Status)
    switch ($r.Status) {
        "Found"   { Write-Host $output -ForegroundColor Green }
        "Missing" { Write-Host $output -ForegroundColor Red }
        default   { Write-Host $output -ForegroundColor Yellow }
    }
}
