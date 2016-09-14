$Disk = $null
$searchLeter = "E"
$colDiskDrives = get-wmiobject -query "Select * From Win32_DiskDrive" 
Foreach ($drive in $colDiskDrives) 
{ 
    $a = $drive.DeviceID.Replace("\", "\\")
    $colPartitions = get-wmiobject -query "Associators of {Win32_DiskDrive.DeviceID=""$a""} WHERE AssocClass = Win32_DiskDriveToDiskPartition" 
    Foreach ($Partition in $colPartitions)
    {
        $b = $Partition.DeviceID 
        $colLogicalDisk = get-wmiobject -query "Associators of {Win32_DiskPartition.DeviceID=""$b""} WHERE AssocClass = Win32_LogicalDiskToPartition" 
        If ($colLogicalDisk.Caption -ne $null)
        { 
            if ($searchLeter + ":" -eq $colLogicalDisk.Caption)
            {
                $Disk = ($Partition.DeviceID -replace '\,|#','').Split(' ')[1]
                if($Disk -ne $null)
                {

                    break
                }
            }
        }
    }
    if($Disk -ne $null)
    {
        break
    }
}

if($Disk -ne $null)
{
    $volume = ("list volume" | diskpart | where {$_ -match " " + $searchLeter + " "}).Split(" ",[System.StringSplitOptions]::RemoveEmptyEntries)
    $command = @"
select volume $volume
delete volume
select disk $Disk
offline disk
"@
    $noOut = $command | diskpart
    sleep 5
    Write-Output "Drive deleted" 
}
else
{
   Write-Output "Drive not found"
}
