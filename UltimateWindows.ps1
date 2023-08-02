##########################################################################################################################
##################################### Table d'application à installer#####################################################
##########################################################################################################################
##########################################################################################################################

$apps = @(
#    "9NZVDKPMR9RD"                                   #firefox
    "7zip.7zip"			                             #7zip
#    "RARLab.WinRAR"                                  #winrar
#    "XP8BT8DW290MPQ"	                             #teams
#    "Microsoft.Office"                               #Microsoft 365 Apps for enterprise
#    "9WZDNCRD29V9"                                   #microsoft 365 (office)
#    "XPDP273C0XHQH2"                                 #Adobe Acrobat Reader DC
    "XPFFBJ2C6B1JGR"                                 #Xmind
    "XPDF9VL4D5XR9W"                                 #PDF-XChange Editor 
#    "Splashtop.SplashtopBusiness"                    #Splashtop Business
#    "9WZDNCRDH6MC"                                   #FortiClient
#    "XP9KF40VGV9PWM"                                 #ESET NOD32 Antivirus
#    "XPFM2WPGW7NLVB"                                 #ESET Internet security
);

##########################################################################################################################
##########################################################################################################################
##########################################################################################################################
##########################################################################################################################

$PackageNuGet = Get-AppxPackage -Name 'NuGet' | Select Name, Version
$PackageManager = Get-AppxPackage -Name 'Microsoft.Winget.Source' | Select Name, Version
$PackageVCLibs = Get-AppxPackage -Name 'Microsoft.VCLibs.140.00.UWPDesktop' | Select Name, Version
$PackageXAML = Get-AppxPackage -Name 'Microsoft.UI.Xaml.2.7*' | Select Name, Version
$PackageAppInstaller = Get-AppxPackage -Name 'Microsoft.DesktopAppInstaller' | Select Name, Version
$DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
$errorlog = "$DesktopPath\winget_error.log"

$NameApps = @{
    "9NZVDKPMR9RD" = "firefox"
    "7zip.7zip" = "7zip"
    "RARLab.WinRAR" = "winrar"
    "XP8BT8DW290MPQ" = "teams"
    "Microsoft.Office" = "Microsoft 365 Apps for enterprise"
    "9WZDNCRD29V9" = "microsoft 365 (office)"
    "XPDP273C0XHQH2" = "Adobe Acrobat Reader DC"
    "XPFFBJ2C6B1JGR" = "Xmind"
    "XPDF9VL4D5XR9W" = "PDF-XChange Editor" 
    "Splashtop.SplashtopBusiness" = "Splashtop Business"
    "9WZDNCRDH6MC" = "FortiClient"
    "XP9KF40VGV9PWM" = "ESET NOD32 Antivirus"
    "XPFM2WPGW7NLVB" = "ESET Internet security"
}

function CopyScript {
    Get-ChildItem $PSScriptRoot | Copy-Item -Destination $env:USERPROFILE
    }

function InstallWinget {
    Write-Host -ForegroundColor Yellow "Verification de Winget"
    if (!$PackageManager) {
        if (!$PackageNuGet){
            Install-PackageProvider -Name NuGet -Force
        }

        if ($PackageVCLibs.Version -lt "14.0.30035.0") {
            Write-Host -ForegroundColor Yellow "Installation des dependences VCLibs ..."
            Add-AppxPackage -Path "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx" #-Confirm
            Write-Host -ForegroundColor Green "Dependence VCLibs correctement installer."
        }

        else {
            Write-Host -ForegroundColor Green "VCLibs est deja installer"
        }

        if ($PackageXAML.Version -lt "7.2203.17001.0") {
            Write-Host -ForegroundColor Yellow "Installation des depedences XAML ..."
            NuGet\Install-Package Microsoft.UI.Xaml
            Write-Host -ForegroundColor Green "Dependences XAML correctement installer."
        }

        else {
            Write-Host -ForegroundColor Green "XAML est deja installer"
        }

        if ($PackageAppInstaller.Version -lt "1.16.12653.0") {
            Write-Host -ForegroundColor Yellow "Installation de WinGet..."
	        $releases_url = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
 		    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls13
   		    $releases = Invoke-RestMethod -Uri "$($releases_url)"
   		    $latestRelease = $releases.assets | Where-Object { $_.browser_download_url.EndsWith("msixbundle") } | Select-Object -First 1
   		    Add-AppxPackage -Path $latestRelease.browser_download_url
            Write-Host -ForegroundColor Green "WinGet correctement installer."
        }
    }

    else {
        Write-Host -ForegroundColor Green "WinGet est deja installer"
        Write-Host ""
        }
}

function InstallApps {
    Foreach ($app in $apps) {
        $NameApp = $NameApps[$app]
        $listApp = winget list --exact --accept-source-agreements -q $app
        
        try { 
            if (![String]::Join("", $listApp).Contains($app)) {
                if ((winget search --exact -q $app) -match "msstore") {
                    Start-Process powershell.exe -ArgumentList "winget install --exact --accept-source-agreements --accept-package-agreements $app --source msstore" -Verb RunAs -Wait
                    Write-Host "$NameApp installer"
                }
                else {
                    Start-Process powershell.exe -ArgumentList "winget install --exact --scope machine --accept-source-agreements --accept-package-agreements $app" -Verb RunAs -Wait
                    Write-Host "$NameApp installer"
                }
        
            }
       } catch{Write-Host $_ }
    }
}

function AddTaskScheduled {
    $ScriptPath = "$env:USERPROFILE\UltimateWindows.ps1"
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`""
    $trigger = New-ScheduledTaskTrigger -AtLogOn -RandomDelay (New-TimeSpan -Minutes 1)
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -Compatibility Win8
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType ServiceAccount -RunLevel Highest

    Register-ScheduledTask -TaskName "UltimateInstaller" -Action $action -Trigger $trigger -Settings $settings -Principal $principal
    }

function DesactivateUAC {
    $UACStatus = reg.exe query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA

    if($UACStatus -match "0x1") {
        Start-Process "reg.exe" -ArgumentList 'ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f' -Verb RunAs
    }
}

function MajWin {
    $InstallNuget = Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Install-Module -Name PSWindowsUpdate -Force
    Install-WindowsUpdate -AcceptAll -AutoReboot

    $CheckUpdates = Get-WindowsUpdate 
    
    if ($CheckUpdates.Count -eq 0) {
        Restart-Computer
        }
    }

function ActivateUAC {
    $UACStatus = reg.exe query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA

    if($UACStatus -match "0x0") {
        Start-Process "reg.exe" -ArgumentList 'ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 1 /f' -Verb RunAs
    }
}

function DeleteTaskSCheduled {
    Unregister-ScheduledTask -TaskName "UltimateInstaller" -Confirm:$false
}

function Ajax {
    $Bureau = Get-ChildItem $env:USERPROFILE\Desktop 
    $Doc = Get-ChildItem $env:USERPROFILE\Documents
    $Download = Get-ChildItem $env:USERPROFILE\Downloads
    $Image = Get-ChildItem $env:USERPROFILE\Pictures
    $Musique = Get-ChildItem $env:USERPROFILE\Music
    $Video = Get-ChildItem $env:USERPROFILE\Videos
    $Extensions = ".exe", ".msi", ".appx", ".appxbundle"
    $dossAGarder = @("Desktop", "Documents", "Downloads", "Pictures", "Music", "videos")
    $AllVariable = @($Bureau, $Temp, $Doc, $Download, $Image, $Musique, $Video)

    Clear-RecycleBin -Confirm:$false

    foreach ($Variable in $AllVariable){
        foreach ($Items in $Variable) {
            if ($Items.Extension -notin $Extensions) {
                if ($Items.Name -notin $dossAGarder) {
                    if ($Items.PSIsContainer) {
                        Remove-Item -Path $Items.FullName -Recurse -Force -Confirm:$false
                    }
                    else {
                        Remove-Item -Path $Items.FullName -Force -Confirm:$false
                        }
                }
            }
        }
    }
    Clear-RecycleBin -Confirm:$false
}

function Finishim {
    $GetScheduledTask = Get-ScheduledTask -TaskName UltimateInstaller
    $Getps1 = Get-ChildItem "$env:USERPROFILE\UltimateWindows.ps1"
    
    if ($Getps1) {
        Remove-Item "$env:USERPROFILE\UltimateWindows.ps1"
        }
    if ($GetScheduledTask) {
        DeleteTaskSCheduled
        }
    ActivateUAC
    Set-ExecutionPolicy Default -Force -ErrorAction SilentlyContinue
    Restart-Computer -Delay 5
}

function CheckAdmin {
    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Warning "Le script doit etre lance en Administrateur, je le fait pour toi."
        $scriptPath = $PSScriptRoot + "\UltimateWindows.ps1"
        Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
        Break
    }
}

function CheckAppsExist {
    foreach ($app in $apps) {
        $result = winget list --exact --accept-source-agreements -q $app
        if (-not [String]::Join("", $result).Contains($app)) {
            return $false
        }
        else {
            return $true
        }
    }
}

function Menu {

    $UACStatus = reg.exe query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA

    if($UACStatus -match "0x1") {
        
        [string]$Title = 'UltimateInstaller Menu'
        Write-Host "======================================== $Title ========================================"
        Write-Host "########################################################################################"
        Write-Host "#######################################!ATTENTION!######################################"
        Write-Host
        Write-Host "les option 1, 2, 3, 4 redemarre l odrinateur pour qu il prenne en compte certaines modifications afin de travailler seul"
        Write-Host "ne relancer pas le script"
        Write-Host "pour les options 3 et 4 WIndows doit etre a jour si winget n'est pas installer sur le pc"
        Write-Host "ne pas oublier de se connecter a internet"
        Write-Host "si le script a ete lance sans internet il faut suivre les ete decrite dans le README que bien entendu... vous avez LU"
        Write-Host
        Write-Host "#######################################!ATTENTION!######################################"
        Write-Host "########################################################################################"
        Write-Host 
        Write-Host "1: La totale (MAJ Windows, installer le pool d'application personnalisé, désinstaller les bloatware)"
        Write-Host
        Write-Host "2: Mise à jour Windows"
        Write-Host
        Write-Host "3: Installer le pool d'application personnalisé)"
        Write-Host
        Write-Host "4: Désinstaller des application ou des bloatware (pas encore dispo)"
        Write-Host
        Write-Host "5: Voir la liste des applications installé"
        Write-Host
        Write-Host "6: Nettoyage complet(en cours de programmation)"
        Write-Host
        Write-Host "7: Nettoyage simple (Documents, Desktop, Image, Musique, Telechargements, Vidéos)"
        Write-Host
        Write-Host
        Write-Host
        Write-Host
        Write-Host
        Write-Host "0: Quitter"
        Write-Host

        $Action = "0"
        while ($Action -in 0..20) {
            $Action = Read-Host "Quelle option lancer ?"
        
            if ($Action -eq 0) {
                Finishim
                exit
                }
        
            if ($Action -eq 1) {
                CopyScript
                AddTaskScheduled
                DesactivateUAC
                MajWin
                }
        
            if ($Action -eq 2) {
                MajWin
                }

            if ($Action -eq 3) {
                InstallWinget
                AddTaskScheduled
                Finishim
                }

            if ($Action -eq 4) {
                RemoveBloatware
                }

            if ($Action -eq 5) {
                AppList
                }

            if ($Action -eq 7) {
                Ajax
                }
        }
    }
}

function CheckIfPossible {

    $UACStatus = reg.exe query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA
    $ScheduledTaskStatus = Get-ScheduledTask -TaskName "UltimateInstaller" -ErrorAction SilentlyContinue
    $AllAppsExist = CheckAppsExist

    if($UACStatus -match "0x0") {

        if ($ScheduledTaskStatus) {
            InstallWinget
            InstallApps

            if ($true) {
                $allAppsExist = CheckAppsExist

                if ($AllAppsExist) {
                    Finishim
                }
            }
        }
    }
}

CheckAdmin
CheckIfPossible
Menu