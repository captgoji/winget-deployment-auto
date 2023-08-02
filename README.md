# winget-deployment-auto
The UltimateInstaller script is a tool that automates the installation of multiple applications on a Windows system. It uses the package manager "winget" to install applications from the Microsoft Store or other sources. Just run the script, and it takes care of everything for you.

UltimateInstaller - Automated Software Installation Script for Windows and Windows Update
Description:
The UltimateInstaller script is a tool that automates the installation of multiple applications on a Windows system. It uses the package manager "winget" to install applications from the Microsoft Store or other sources.

Prerequisites:
Ensure that you have an active internet connection to download the applications.

If the script is executed without an internet connection in PowerShell, run the following commands:
Start-Process "reg.exe" -ArgumentList 'ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 1 /f' -Verb RunAs
Unregister-ScheduledTask -TaskName "UltimateInstaller" -Confirm:$false
Remove-Item "$env:USERPROFILE\UltimateWindows.ps1"

Usage:
Customizing Applications
To personalize the applications to be installed, modify the variable $apps in the "UltimateWindows.ps1" script. You can add or remove lines to include the applications of your choice.
Use the command "Winget search <application name>" to find the ID to add to the $apps variable.

You can add other applications following the same syntax.

Important Notes:
Options 3 and 4 require an active internet connection to download the applications.
Options 1, 3, and 4 require a computer restart to apply certain changes. The script will automatically restart the computer after performing necessary operations.
The script temporarily disables User Account Control (UAC) to install some applications. It will automatically reactivate UAC at the end of the process.

Warning:
This script uses functionalities that can modify system settings and install applications. Use it with caution, and ensure to back up your important data before executing it.
