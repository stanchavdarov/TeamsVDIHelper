#powershell teams audit - Stan Chavdarov - Jul 2022

#init variables for alter
$isteamsoptimized = 0
$teamsinstalltype=""

#set reg path for Teams optimization on VDI
$teamsregpath="HKCU:\Software\Citrix\HDXMediaStream"


#Create the notification object
$notification = New-Object System.Windows.Forms.NotifyIcon 

#Define the icon for the system tray
$notification.Icon = [System.Drawing.SystemIcons]::Information

#Display title of balloon window
$notification.BalloonTipTitle = “Teams Optimization for Citrix Status”

$notification.BalloonTipIcon = “Warning”
$title = “Teams in Citrix is NOT Optimized. Click here to restart Teams.”

#wait for teams to start
function Wait-ForProcess
{
    param
    (
        $Name = 'Teams',

        [Switch]
        $IgnoreAlreadyRunningProcesses
    )

    if ($IgnoreAlreadyRunningProcesses)
    {
        $NumberOfProcesses = (Get-Process -Name $Name -ErrorAction SilentlyContinue).Count
    }
    else
    {
        $NumberOfProcesses = 0
    }


    #Write-Host "Waiting for $Name" -NoNewline
    while ( (Get-Process -Name $Name -ErrorAction SilentlyContinue).Count -eq $NumberOfProcesses )
    {
        #Write-Host '.' -NoNewline
        Start-Sleep -Milliseconds 1000
    }

    Write-Host ''
}

#wait for teams to be started and then 3secs more to start up completely
Wait-ForProcess
Start-Sleep -Milliseconds 3000

#Check Teams install
if ((Test-path "C:\Users\stanc\AppData\Local\Microsoft\Teams\current\Teams.exe") -eq $true) {#write-host "Single User Teams"
$teamsinstalltype="SingleUser"
}

#Check Teams install
if ((Test-path "C:\program files (x86)\Microsoft\Teams\Current\teams.exe") -eq $true) {#write-host "Multi-User Teams"
$teamsinstalltype="MultiUser"
}


#check for teams optimized key
$isteamsoptimized=Get-ItemPropertyValue -path $teamsregpath -Name MSTeamsRedirSupport
if ($isteamsoptimized -eq 0 ) {write-host "Teams is not optimized for VDI"
}
if ($isteamsoptimized -eq 1 ) {write-host "Teams is optimized for VDI"}

#Check for WebSocketAgent process
$processes=Get-Process | ? {$_.SI -eq (Get-Process -PID $PID).SessionId}
if (($processes.ProcessName -ieq "WebSocketAgent") -and ($isteamsoptimized -eq 1)) {write-host "WebSocketAgent Process is running"
$teamsisoptmized=1}

if ($processes.ProcessName -ine "WebSocketAgent") {write-host "WebSocketAgent Process is NOT running"}

#Load the required assemblies
[void] [System.Reflection.Assembly]::LoadWithPartialName(“System.Windows.Forms”)

#Remove any registered events related to notifications
Remove-Event BalloonClicked_event -ea SilentlyContinue
Unregister-Event -SourceIdentifier BalloonClicked_event -ea silentlycontinue
Remove-Event BalloonClosed_event -ea SilentlyContinue
Unregister-Event -SourceIdentifier BalloonClosed_event -ea silentlycontinue



#Type of balloon icon
if ($teamsisoptmized -eq 1) {
$notification.BalloonTipIcon = “Info”
$title = “Teams in Citrix is Optimized.”
}

#Notification message
$notification.BalloonTipText = $title

#Make balloon tip visible when called
$notification.Visible = $True

## Register a click event with action to take based on event
#Balloon message clicked
register-objectevent $notification BalloonTipClicked BalloonClicked_event `
-Action {[System.Windows.Forms.MessageBox]::Show(“Teams will be restarted now - click OK”,”Information”);$notification.Visible = $False

#Check for WebSocketAgent process
$processes=Get-Process | ? {$_.SI -eq (Get-Process -PID $PID).SessionId}
#If teams is running kill it
if ($processes.ProcessName -ieq "Teams") {stop-process -name "Teams"}
#wait till it stops
wait-process -name "Teams"
#then start it from either location/single/multi user install
if ((Test-path "C:\Users\stanc\AppData\Local\Microsoft\Teams\current\Teams.exe") -eq $true) {Start-Process "C:\Users\stanc\AppData\Local\Microsoft\Teams\current\Teams.exe"}
if ((Test-path "C:\program files (x86)\Microsoft\Teams\Current\teams.exe") -eq $true) {start-process C:\program files (x86)\Microsoft\Teams\Current\teams.exe}

} | Out-Null

#Balloon message closed
#register-objectevent $notification BalloonTipClosed BalloonClosed_event `
#-Action {[System.Windows.Forms.MessageBox]::Show(“Balloon message closed”,”Information”);$notification.Visible = $False} | Out-Null

#Call the balloon notification
$notification.ShowBalloonTip(2000)