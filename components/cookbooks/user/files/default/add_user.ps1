param([string]$userName="", [array]$sshKeys=@())

Function Set-Owner {

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
                        Get-ChildItem $Item -Force | Set-Owner @PSBoundParameters
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

Function Remove-Inheritance {
  param([string]$Path)

  $Acl = (Get-Item $Path).GetAccessControl('Access')
  $Acl.SetAccessRuleProtection($True, $True)
  $Acl | Set-Acl $Path

  Get-ChildItem $Path -Recurse |
  Foreach-Object {
    $Acl = (Get-Item $_.FullName).GetAccessControl('Access')
    $Acl.SetAccessRuleProtection($True, $True)
    $Acl | Set-Acl $_.FullName
  }
}

#################################################

Function Remove-Permission {
  param([string]$Path, [string]$User)

  $Acl = (Get-Item $Path).GetAccessControl('Access')
  $Ar = New-Object  System.Security.AccessControl.FileSystemAccessRule($User, "Read" ,,,"Allow")
  $Acl.RemoveAccessRuleAll($Ar)
  $Acl | Set-Acl $Path

  Get-ChildItem $Path -Recurse |
  Foreach-Object {
    $Acl = (Get-Item $_.FullName).GetAccessControl('Access')
    $Ar = New-Object  System.Security.AccessControl.FileSystemAccessRule($User, "Read" ,,,"Allow")
    $Acl.RemoveAccessRuleAll($Ar)
    $Acl | Set-Acl $_.FullName
  }
}

#################################################

Function Set-Permission {
  param([string]$Path, [string]$User, [string]$Access)

  $Acl = (Get-Item $Path).GetAccessControl('Access')
  $Ar = New-Object  System.Security.AccessControl.FileSystemAccessRule($User, $Access, "Allow")
  $Acl.SetAccessRule($Ar)
  $Acl | Set-Acl $Path

  Get-ChildItem $Path -Recurse |
  Foreach-Object {
    $Acl = (Get-Item $_.FullName).GetAccessControl('Access')
    $Ar = New-Object  System.Security.AccessControl.FileSystemAccessRule($User, $Access, "Allow")
    $Acl.SetAccessRule($Ar)
    $Acl | Set-Acl $_.FullName
  }
}

#################################################

Function Add-SSH-Keys-To-File {
  param([string]$userName, [string]$file, [array]$keys)

  foreach ($key in $keys) {
    Add-Content $file "$key"
    Write-Host "Adding ssh key to ${userName}: $key"
  }
}

#################################################

Function User-Exists {
  param([string]$userName)

  $exists = $false

  net user | Foreach-Object {
    # These lines are useless in "net user" command
    if($_.Contains("User accounts for") -or $_.Contains("The command completed successfully.") -or $_.Contains("-------")) {
      Return
    }

    $_.Split(" ") | Foreach-Object {
      if($_ -eq $userName) {
          $exists = $true
      }
    }
  }

  return $exists
}

#################################################
# START OF SCRIPT
#################################################

if (User-Exists -userName $userName) {
  #  user exists
  Write-Host "User $userName already exists"
} else {
  #  user does not exist
  Write-Host "Adding $userName user to windows"

  $Computername = $env:COMPUTERNAME
  $ADSIComp = [adsi]"WinNT://$Computername"
  $NewUser = $ADSIComp.Create('User',$userName)
  $NewUser.SetInfo()

  $group = [ADSI]("WinNT://"+$env:COMPUTERNAME+"/administrators,group")
  $group.add("WinNT://$env:USERDOMAIN/$userName,user")
}

#################################################

$userDir = "C:\cygwin64\home\$userName"
$sshDir = Join-Path $userDir ".ssh"
$keyFile = Join-Path $sshDir "authorized_keys"

if (!(Test-Path $userDir)) {
  Write-Host "Adding $userName user to cygwin"
  New-Item $sshDir -ItemType directory

  Copy-Item C:\Users\admin\.ssh\authorized_keys $keyFile -Force
  Add-SSH-Keys-To-File -userName $userName -file $keyFile -keys $sshKeys

  $domain = hostname
  $user_account = "$domain\$userName"

  Remove-Inheritance -Path C:\cygwin64\home\$userName
  Remove-Permission -Path C:\cygwin64\home\$userName -User "$domain\oneops"
  Set-Permission -Path C:\cygwin64\home\$userName -User "BUILTIN\Administrators" -Access "FullControl"
  Set-Owner -Path C:\cygwin64\home\$userName -Recurse -Account $user_account
} else {
  Copy-Item C:\Users\admin\.ssh\authorized_keys $keyFile -Force
  Add-SSH-Keys-To-File -userName $userName -file $keyFile -keys $sshKeys
}

## TODO: Cleanup
