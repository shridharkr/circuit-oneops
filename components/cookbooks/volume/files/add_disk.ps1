param(
	[parameter(Mandatory=$true)]
	[string]$letter
) 

# Get the ID and security principal of the current user account
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
 
# Check to see if we are currently running "as Administrator"
if (!$myWindowsPrincipal.IsInRole($adminRole))
   {
        # We are not running "as Administrator" - so relaunch as administrator
        # Create a new process object that starts PowerShell
        $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
        # Specify the current script path and name as a parameter
        $newProcess.Arguments = $myInvocation.MyCommand.Definition + " " + $letter
        # Indicate that the process should be elevated
        $newProcess.Verb = "runas";
        # Start the new process
        [System.Diagnostics.Process]::Start($newProcess);
        exit
   }

Write-Host "Trying to enable" $letter "drive"
if (($letter.length -gt 1) -or !($letter -match '[e-z]')) {
    Write-Host $letter "is not a valid letter for a Windows Drive"
    return 1
}

$LogicalDisks = get-wmiobject Win32_LogicalDisk
foreach($Disk in $LogicalDisks)
{
    if ($letter -eq $Disk.DeviceID.Substring(0,1))
    {
        Write-Host $letter "is already in use"
        return 0
    }
}

#Check for offline disks on server.
$offlinedisk = "list disk" | diskpart | where {$_ -match "offline"}
if($offlinedisk)
{
    Write-Host "Following Offline disk found.."
    $offlinedisk
    foreach($offdisk in $offlinedisk)
    {
        Write-Host "Enabling $offdiskS with letter $letter"
        $offdiskS = $offdisk.Substring(2,6)

#Creating command parameters for selecting disk, making disk online and setting off the read-only flag.
$OnlineDisk = @"
select $offdiskS
online disk
attributes disk clear readonly
clean
create partition primary
select part 1
format fs=ntfs quick
assign letter $letter
"@

        #Sending parameters to diskpart
        $noOut = $OnlineDisk | diskpart
        sleep 6      
        break
    }

    #If selfhealing failed throw the alert.
    if(($offlinedisk = "list disk" | diskpart | where {$_ -match "offline"} ))
    {
        Write-Host "Failed to bring the disk online"
    }
    else
    {
        Write-Host "Disk $letter are now online."
        return 0
    }
}
else #If no offline disk exist.
{
    #All disk(s) are online.
    Write-Host "There is not a new disk to get online"
    return 1
}