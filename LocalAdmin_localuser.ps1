function log ($Message,$Log,[switch]$fileonly) {
$Message = ($Message |out-string).TrimEnd()
if (!$fileonly) {(get-date -format G) + " : " + "$Message"}
(get-date -format G) + " : " + "$Message" |out-file $Log -force -Append
}
 
Set-ExecutionPolicy remotesigned -Force
 
$error.Clear()
$ErrorActionPreference = "silentlycontinue"
 
$User = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty UserName 
$UserName   =     ($User -split("\\"))[1]
$DomainName =     ($User -split("\\"))[0]
 
$BasePublic               = "c:\users\public"
 
#-----------------------------------------------------------
# Local Admins
#-----------------------------------------------------------
 
$Logfile  = "$BasePublic\Autopilot_loggedonuser_LocalAdmin.txt"
$FlagFile = "$BasePublic\AutopilotLocalAdmin_loggedonuser.txt"
 
$UsersToAdd  = "CORP\ragan.faylor@xome.com"
 
if ($DomainName -eq "CORP" -and !(test-path $FlagFile))
    {
    $LocalGroup = "Administrators"
    foreach ($user in $UsersToAdd)
        {
        $error.Clear()
        log "Adding $User to $LocalGroup" $logfile
        $Result = Add-LocalGroupMember -Group $LocalGroup  -Member $User
        log $error $logfile
        }
    
    $LocalAdmins = net localgroup $Localgroup 
    log $LocalAdmins $logfile
    
    ($LocalAdmins |out-string) | set-content $FlagFile
    }
    pause