@Echo off

Set MyApp=Test-Module
::Set MyApp=MyRSjobs

"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy ByPass -File "%~dp0%MyApp%.ps1"

Pause


:: Start-MyRSJob

