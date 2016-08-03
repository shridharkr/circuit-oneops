$letters = "E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z"
#Get the available disk latters to assign
$LogicalDisks = get-wmiobject Win32_LogicalDisk
$remove_letters = New-Object System.Collections.ArrayList
foreach($Disk in $LogicalDisks)
{
    [void] $remove_letters.Add($Disk.DeviceID.Substring(0,1))
}
$available_letters = New-Object System.Collections.ArrayList
foreach ($letter in $letters.Split(","))
{
    [void] $available_letters.Add($letter)
}

foreach ($remove in $remove_letters.Split(","))
{
    $available_letters.Remove($remove)
}


#Check for offline disks on server.
$offlinedisk = "list disk" | diskpart | where {$_ -match "offline"}

#If offline disk(s) exist
if($offlinedisk)
{

    Write-Output "Following Offline disk(s) found..Trying to bring Online."
    $offlinedisk
    
    #for all offline disk(s) found on the server
    foreach($offdisk in $offlinedisk)
    {

        $offdiskS = $offdisk.Substring(2,6)
        Write-Output "Enabling $offdiskS"
#Creating command parameters for selecting disk, making disk online and setting off the read-only flag.
$letter = $available_letters[0]
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
        $available_letters.RemoveAt(0)
        #Sending parameters to diskpart
        $noOut = $OnlineDisk | diskpart
        sleep 5

    }

    #If selfhealing failed throw the alert.
    if(($offlinedisk = "list disk" | diskpart | where {$_ -match "offline"} ))
    {
    
        Write-Output "Failed to bring the following disk(s) online"
        $offlinedisk

    }
    else
    {

        Write-Output "Disk(s) are now online."

    }

}

#If no offline disk(s) exist.
else
{

    #All disk(s) are online.
    Write-Host "All disk(s) are online!"

}

