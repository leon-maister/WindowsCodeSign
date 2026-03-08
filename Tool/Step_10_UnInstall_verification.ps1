certutil -csplist | findstr /i "Akeyless"   # No output

reg query "HKLM\SYSTEM\CurrentControlSet\Control\Cryptography\Providers\Akeyless KSP" /s   # Key not found
reg query "HKLM\SOFTWARE\Microsoft\Cryptography\Providers\Akeyless KSP" /s                 # Key not found

reg query "HKLM\SYSTEM\CurrentControlSet\Control\Cryptography\Configuration\Local\Default\00010001\KEY_STORAGE" /v Providers   # No Akeyless KSP

Test-Path "C:\Windows\System32\AkeylessKsp.dll"                     # False
Test-Path "C:\Program Files\Akeyless\Akeyless KSP\akeyless-ksp-cert-helper.exe"   # False