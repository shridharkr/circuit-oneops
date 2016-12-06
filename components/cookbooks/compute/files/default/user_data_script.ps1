#ps1_sysnative

Function Set-Owner-Admin-Folder {

    [cmdletbinding(
        SupportsShouldProcess = $True
    )]
    Param (
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('FullName')]
        [string[]]$Path,
        [parameter()]
        [string]$Account = 'Builtin\Administrators',
        [parameter()]
        [switch]$Recurse
    )
    Begin {
        #Prevent Confirmation on each Write-Debug command when using -Debug
        If ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }
        Try {
            [void][TokenAdjuster]
        } Catch {
            $AdjustTokenPrivileges = @"
            using System;
            using System.Runtime.InteropServices;

             public class TokenAdjuster
             {
              [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
              internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,
              ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);
              [DllImport("kernel32.dll", ExactSpelling = true)]
              internal static extern IntPtr GetCurrentProcess();
              [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
              internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr
              phtok);
              [DllImport("advapi32.dll", SetLastError = true)]
              internal static extern bool LookupPrivilegeValue(string host, string name,
              ref long pluid);
              [StructLayout(LayoutKind.Sequential, Pack = 1)]
              internal struct TokPriv1Luid
              {
               public int Count;
               public long Luid;
               public int Attr;
              }
              internal const int SE_PRIVILEGE_DISABLED = 0x00000000;
              internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
              internal const int TOKEN_QUERY = 0x00000008;
              internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
              public static bool AddPrivilege(string privilege)
              {
               try
               {
                bool retVal;
                TokPriv1Luid tp;
                IntPtr hproc = GetCurrentProcess();
                IntPtr htok = IntPtr.Zero;
                retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
                tp.Count = 1;
                tp.Luid = 0;
                tp.Attr = SE_PRIVILEGE_ENABLED;
                retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
                retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
                return retVal;
               }
               catch (Exception ex)
               {
                throw ex;
               }
              }
              public static bool RemovePrivilege(string privilege)
              {
               try
               {
                bool retVal;
                TokPriv1Luid tp;
                IntPtr hproc = GetCurrentProcess();
                IntPtr htok = IntPtr.Zero;
                retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
                tp.Count = 1;
                tp.Luid = 0;
                tp.Attr = SE_PRIVILEGE_DISABLED;
                retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
                retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
                return retVal;
               }
               catch (Exception ex)
               {
                throw ex;
               }
              }
             }
"@
            Add-Type $AdjustTokenPrivileges
        }

        #Activate necessary admin privileges to make changes without NTFS perms
        [void][TokenAdjuster]::AddPrivilege("SeRestorePrivilege") #Necessary to set Owner Permissions
        [void][TokenAdjuster]::AddPrivilege("SeBackupPrivilege") #Necessary to bypass Traverse Checking
        [void][TokenAdjuster]::AddPrivilege("SeTakeOwnershipPrivilege") #Necessary to override FilePermissions
    }
    Process {
        ForEach ($Item in $Path) {
            Write-Verbose "FullName: $Item"
            #The ACL objects do not like being used more than once, so re-create them on the Process block
            $DirOwner = New-Object System.Security.AccessControl.DirectorySecurity
            $DirOwner.SetOwner([System.Security.Principal.NTAccount]$Account)
            $FileOwner = New-Object System.Security.AccessControl.FileSecurity
            $FileOwner.SetOwner([System.Security.Principal.NTAccount]$Account)
            $DirAdminAcl = New-Object System.Security.AccessControl.DirectorySecurity
            $FileAdminAcl = New-Object System.Security.AccessControl.DirectorySecurity
            $AdminACL = New-Object System.Security.AccessControl.FileSystemAccessRule('Builtin\Administrators','FullControl','ContainerInherit,ObjectInherit','InheritOnly','Allow')
            $FileAdminAcl.AddAccessRule($AdminACL)
            $DirAdminAcl.AddAccessRule($AdminACL)
            Try {
                $Item = Get-Item -LiteralPath $Item -Force -ErrorAction Stop
                If (-NOT $Item.PSIsContainer) {
                    If ($PSCmdlet.ShouldProcess($Item, 'Set File Owner')) {
                        Try {
                            $Item.SetAccessControl($FileOwner)
                        } Catch {
                            Write-Warning "Couldn't take ownership of $($Item.FullName)! Taking FullControl of $($Item.Directory.FullName)"
                            $Item.Directory.SetAccessControl($FileAdminAcl)
                            $Item.SetAccessControl($FileOwner)
                        }
                    }
                } Else {
                    If ($PSCmdlet.ShouldProcess($Item, 'Set Directory Owner')) {
                        Try {
                            $Item.SetAccessControl($DirOwner)
                        } Catch {
                            Write-Warning "Couldn't take ownership of $($Item.FullName)! Taking FullControl of $($Item.Parent.FullName)"
                            $Item.Parent.SetAccessControl($DirAdminAcl)
                            $Item.SetAccessControl($DirOwner)
                        }
                    }
                    If ($Recurse) {
                        [void]$PSBoundParameters.Remove('Path')
                        Get-ChildItem $Item -Force | Set-Owner-Admin-Folder @PSBoundParameters
                    }
                }
            } Catch {
                Write-Warning "$($Item): $($_.Exception.Message)"
            }
        }
    }
    End {
        #Remove priviledges that had been granted
        [void][TokenAdjuster]::RemovePrivilege("SeRestorePrivilege")
        [void][TokenAdjuster]::RemovePrivilege("SeBackupPrivilege")
        [void][TokenAdjuster]::RemovePrivilege("SeTakeOwnershipPrivilege")
    }
}

#################################################
Write-Host "Adding oneops user to windows"

$Computername = $env:COMPUTERNAME
$ADSIComp = [adsi]"WinNT://$Computername"
$OoUsername = 'oneops'
$NewUser = $ADSIComp.Create('User',$OoUsername)
$NewUser

#Create password
$Password = "0penStack16#" | ConvertTo-SecureString -AsPlainText -Force
$BSTR = [system.runtime.interopservices.marshal]::SecureStringToBSTR($Password)
$_password = [system.runtime.interopservices.marshal]::PtrToStringAuto($BSTR)
#Set password on account
$NewUser.SetPassword(($_password))

$NewUser.SetInfo()

$group = [ADSI]("WinNT://"+$env:COMPUTERNAME+"/administrators,group")
$group.add("WinNT://$env:USERDOMAIN/oneops,user")

#################################################

Write-Host "Adding oneops user to cygwin"
#C:\cygwin64\bin\mkpasswd.exe -u oneops -l

$ooUserDir = "C:\cygwin64\home\$OoUsername"
$ooSshDir = Join-Path $ooUserDir ".ssh"
$ooKeyFile = Join-Path $ooSshDir "authorized_keys"

New-Item $ooSshDir -ItemType directory
Copy-Item C:\Users\admin\.ssh\authorized_keys $ooKeyFile

$domain = hostname
$user_account = "$domain\$OoUsername"

Write-Host $user_account

Set-Owner-Admin-Folder -Path $ooUserDir -Recurse -Account $user_account

## TODO: Cleanup

################################################
Write-Host "Adding nagios user to windows"

$Computername = $env:COMPUTERNAME
$ADSIComp = [adsi]"WinNT://$Computername"
$Username = 'nagios'
$NewUser = $ADSIComp.Create('User',$Username)
$NewUser

#Create password
$Password = "0penStack16#" | ConvertTo-SecureString -AsPlainText -Force
$BSTR = [system.runtime.interopservices.marshal]::SecureStringToBSTR($Password)
$_password = [system.runtime.interopservices.marshal]::PtrToStringAuto($BSTR)
#Set password on account
$NewUser.SetPassword(($_password))

$NewUser.SetInfo()

$group = [ADSI]("WinNT://"+$env:COMPUTERNAME+"/administrators,group")
$group.add("WinNT://$env:USERDOMAIN/nagios,user")
#################################################
Write-Host "Adding nagios user to cygwin"
#C:\cygwin64\bin\mkpasswd.exe -u nagios -l
#C:\cygwin64\bin\mkgroup.exe -g nagios -l

New-Item C:\cygwin64\home\nagios\ -ItemType directory
Copy-Item C:\Users\admin\.ssh\authorized_keys C:\cygwin64\home\nagios\.ssh\authorized_keys

#$user_account = whoami

$domain = hostname
$user_account = "$domain\nagios"

Write-Host $user_account

Set-Owner-Admin-Folder -Path C:\cygwin64\home\nagios -Recurse -Account $user_account
