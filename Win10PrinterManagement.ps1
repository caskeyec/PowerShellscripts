param([string]$mode)

$Location = "location" #pwd
set-location $Location 
$ScriptName = "Win10PrinterManagement.ps1"
$recipients = "email address"
$PRINTSERVER = "fqdn print server"
$DC = "domain controller"
import-module ActiveDirectory

function listprintergroups ([switch]$add) {

$FileServer      = "where do you want the logs"
$Logfile = "\\$FileServer\" + $env:username + "_" + $env:computername + "_Printers.txt"
#if (test-path $Logfile) {remove-item $logfile}

"`r`n----------------------------------------------------------`r`n" >> $logfile

write-output "Retrieving printer groups for $Env:username"

$Printergroups = (Get-ADPrincipalGroupMembership -identity $env:username -server $DC | ? {$_.Name -match "prt"} | sort).name

$CurrentPrinters = (get-printer | ? {$_.Type -eq "connection"}).name 

#"Current Printers" >> $Logfile
#$CurrentPrinters   >> $Logfile

#"`r`nCurrent Printer Groups on $DC " >> $Logfile
#$Printergroups >> $Logfile

if ($add)
    {
    
    $error.clear()
    $OverallStartTime = get-date 
    
    "`r`nUpdating Printers : " >> $Logfile
    
    foreach ($PrinterGroup in $Printergroups)
        {
        $FullPrinterName = ("\\$PRINTSERVER\" + $Printergroup).trim() 
        if     ($CurrentPrinters -notcontains $Fullprintername ) {AddNetworkPrinter $PRINTSERVER $PrinterGroup}
        else 
            {
            $Result = "$FullPrinterName skipped - already connected"
            $result
            $result >> $logfile
            }
        }
    foreach ($printer in $CurrentPrinters)
        {
        $PrinterName = $Printer -replace ("\\\\$PRINTSERVER\\","")
        if ($Printergroups -notcontains $PrinterName) 
            {
            $Result = "$Env:username is not in $PrinterName group - printer will be removed"
            $result
            $result >> $logfile
            RemoveNetworkPrinter $Printer
            }
        }

    $OverallEndTime = get-date
    $OverallSecondsEllapsed = ($OverallEndtime - $OverallstartTime).Seconds
    $OverallMinutesEllapsed = ($OverallEndtime - $OverallstartTime).Minutes

    $OverallMessage = "`r`nPrinters updated in $OverallMinutesEllapsed minutes $OverallSecondsEllapsed seconds."
    write-host $OverallMessage 
    $OverallMessage >> $logfile

    if ($mode -eq "interactive") 
        {
        $response = read-host "`r`nPress Enter to exit"
        if ($response -eq "M") {cls;menu}
        }
    }
else {
$PrinterGroups
    if ($mode -eq "interactive") 
        {
        $response = read-host "`r`nPress Enter to exit"
        if ($response -eq "M") {cls;menu}
        }

}

}

function AddPrinters () {
listprintergroups -add
}

function AddNetworkPrinter ($Printserver,$Printer) {
                
    write-host "Adding \\$Printserver\$Printer" -ForegroundColor green -NoNewline
    #"Trying \\$Printserver\$Printer" >> $logfile
    
    $error.clear()
    $StartTime = get-date 
    add-printer -connectionname \\$printserver\$printer -Verbose
    $EndTime = get-date
    $SecondsEllapsed = [math]::round(($Endtime - $startTime).TotalSeconds,0)

    if ($error) 
        {
            $body = $error[0] | out-string  
            $error.clear()
            $details = get-printer -ComputerName $Printserver -name $printer |select Name,DriverName,PrintProcessor,PortName 
            if (!$error)
                { 
                $IP = "http:`/`/" + $details.PortName
                $details = $details |fl | out-string
                $body = $details.trim() + " $IP" + "`r`n`r`n" + $body.trim()
                $details.trim()
                }
            else 
                {
                $body = "Cannot retrieve printer detail: `r`n`r`n" + $error[0] |Out-String
                }
            $Subject = ("Error adding $printserver $printer for $Env:username on $Env:computername ($SecondsEllapsed seconds)" |out-string ).trim()
            $Subject >> $Logfile
            $Body    >> $Logfile
            Send-MailMessage -to $recipients -from "scanner@title365.com" -SmtpServer "smtpscanner.corp.title365.com" -body $body -Subject $Subject}
    else 
        {
        write-host " $Printer added in $SecondsEllapsed seconds" -NoNewline
        $details = get-printer -name "\\$PrintServer\$printer" |select Name,DriverName,PrintProcessor,PortName
        $line = $details.DriverName + " " + $details.PortName + " " + $details.PrintProcessor
        write-host " - $line"
        " $Printer added in $SecondsEllapsed seconds - $Line" >> $logfile
        }
}

function RemoveNetworkPrinter ($Printer) {
    write-host "Removing $Printer " -ForegroundColor red -NoNewline
    "Removing $Printer " >> $logfile
    $error.clear()
    $StartTime = get-date 
    remove-printer -name $Printer #-Verbose
    $EndTime = get-date
    $SecondsEllapsed = ($Endtime - $startTime).seconds
    
    if ($error) 
        {
            $body = $error[0] | out-string  
            $error.clear()
            <#
            $details = get-printer -ComputerName $Printserver -name $printer |select Name,DriverName,PrintProcessor,PortName 
            if (!$error)
                { 
                $IP = "http:`/`/" + $details.PortName
                $details = $details |fl | out-string
                $body = $details.trim() + " $IP" + "`r`n`r`n" + $body.trim()
                $details.trim()
                }
            else 
                {
                $body = "Cannot retrieve printer detail: `r`n`r`n" + $error[0] |Out-String
                }
            #>
            $Subject = ("Error Removing $printer for $Env:username on $Env:computername ($SecondsEllapsed seconds)"|out-string).trim()
            $Subject >> $Logfile
            $body    >> $Logfile
            Send-MailMessage -to $recipients -from "scanner@title365.com" -SmtpServer "smtpscanner.corp.title365.com" -body $body -Subject $Subject }
    else 
        {
        $result = " $Printer removed in $SecondsEllapsed seconds"
        write-host $result
        $result >> $Logfile
        }
}

function RemovePrinters () {

get-printer | ? { $_.Type -eq "Connection"} | Remove-Printer
if ($mode -eq "interactive") {read-host "`r`nPress Enter to go back to the main menu"; menu}
}

function Check-GroupMembership {
[Cmdletbinding()]
Param (
        [Parameter(Mandatory)]$Username, 
        [Parameter(Mandatory)]$Group
        )
$AllDC = (Get-ADDomainController -filter *).Name
foreach ($DC in $AllDC) 
    {
    "Checking $DC"
    get-adprincipalgroupmembership -identity $username -server $DC | ? {$_.Name -eq $Group} | ft -autosize }
}

function menu() {
cls
switch (Read-Host "
[g] list AD printer groups for $env:username

[l] List printers on $Env:computername for $env:username

[u] Update printers based on AD groups

[d] Delete all printers for $Env:username

[x] Exit

") {

g {cls;listprintergroups}
l {cls;get-printer;if ($mode -eq "interactive") {read-host "`r`nPress Enter to go back to the main menu"; menu}}
u {cls;addprinters}
d {cls;removeprinters}
cg{cls;Check-GroupMembership -Username $env:username; read-host "`r`nPress Enter to go back to the main menu"; menu}

x {exit}
default {&$Location\$ScriptName}

}

&$Location\$ScriptName
}

if ($mode -eq "interactive") {addprinters}
#if ($mode -eq "auto") {addprinters}