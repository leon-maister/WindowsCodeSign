$uninstRoots = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

$app = Get-ChildItem $uninstRoots | ForEach-Object { Get-ItemProperty $_.PSPath } |
       Where-Object { $_.DisplayName -like "Akeyless KSP*" } | Select-Object -First 1

$app.DisplayName
$app.PSChildName   # This is the ProductCode GUID

msiexec /x $app.PSChildName /l*v "$env:logUninst"
$LASTEXITCODE