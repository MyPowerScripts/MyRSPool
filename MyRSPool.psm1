<#
  .SYNOPSIS
    PowerShell RunspacePool Functions
  .DESCRIPTION
    PowerShell RunspacePool Functions
  .EXAMPLE
    Import-Module -Name "MyRSPool"
  .EXAMPLE
    Import-Module -Name "D:\MyTest\MyRSPool\MyRSPool.psm1"
  .NOTES
    Original Script By Ken Sweet on 10/15/2017 at 06:53 AM
  .LINK
#>

$PSModule = $ExecutionContext.SessionState.Module
$PSModuleRoot = $PSModule.ModuleBase

Write-Verbose -Message "Loading Module = $($PSModule.Name)"
Write-Verbose -Message "Module Base = $($PSModule.ModuleBase)"
Write-Verbose -Message ""

$Params = @{ }

#region ******** Add Custom MyRSPool / MyRSJob Types ********
$MyTypeData = @"
using System;
using System.Collections.Generic;
using System.Management.Automation;

public class MyRSJob
{
  private System.String _Name;
  private System.Management.Automation.PowerShell _PowerShell;
  private System.IAsyncResult _PowerShellAsyncResult;
  private System.Object _InputObject = null;

  public MyRSJob(System.String Name, System.Management.Automation.PowerShell PowerShell, System.IAsyncResult PowerShellAsyncResult, System.Object InputObject)
  {
    _Name = Name;
    _PowerShell = PowerShell;
    _PowerShellAsyncResult = PowerShellAsyncResult;
    _InputObject = InputObject;
  }

  public System.String Name
  {
    get
    {
      return _Name;
    }
  }

  public System.Guid InstanceID
  {
    get
    {
      return _PowerShell.InstanceId;
    }
  }

  public System.Management.Automation.PowerShell PowerShell
  {
    get
    {
      return _PowerShell;
    }
  }

  public System.Management.Automation.PSInvocationState State
  {
    get
    {
      return _PowerShell.InvocationStateInfo.State;
    }
  }

  public System.Exception Reason
  {
    get
    {
      return _PowerShell.InvocationStateInfo.Reason;
    }
  }

  public bool HadErrors
  {
    get
    {
      return _PowerShell.HadErrors;
    }
  }

  public System.String Command
  {
    get
    {
      return _PowerShell.Commands.Commands[0].ToString();
    }
  }

  public System.Management.Automation.Runspaces.RunspacePool RunspacePool
  {
    get
    {
      return _PowerShell.RunspacePool;
    }
  }

  public System.IAsyncResult PowerShellAsyncResult
  {
    get
    {
      return _PowerShellAsyncResult;
    }
  }

  public bool IsCompleted
  {
    get
    {
      return _PowerShellAsyncResult.IsCompleted;
    }
  }

  public System.Object InputObject
  {
    get
    {
      return _InputObject;
    }
  }

  public System.Management.Automation.PSDataCollection<System.Management.Automation.DebugRecord> Debug
  {
    get
    {
      return _PowerShell.Streams.Debug;
    }
  }

  public System.Management.Automation.PSDataCollection<System.Management.Automation.ErrorRecord> Error
  {
    get
    {
      return _PowerShell.Streams.Error;
    }
  }

  public System.Management.Automation.PSDataCollection<System.Management.Automation.ProgressRecord> Progress
  {
    get
    {
      return _PowerShell.Streams.Progress;
    }
  }

  public System.Management.Automation.PSDataCollection<System.Management.Automation.VerboseRecord> Verbose
  {
    get
    {
      return _PowerShell.Streams.Verbose;
    }
  }

  public System.Management.Automation.PSDataCollection<System.Management.Automation.WarningRecord> Warning
  {
    get
    {
      return _PowerShell.Streams.Warning;
    }
  }
}

public class MyRSPool
{
  private System.String _Name;  
  private System.Management.Automation.Runspaces.RunspacePool _RunspacePool;
  public System.Collections.Generic.List<MyRSJob> Jobs = new System.Collections.Generic.List<MyRSJob>();

  public MyRSPool(System.String Name, System.Management.Automation.Runspaces.RunspacePool RunspacePool)
  {
    _Name = Name;
    _RunspacePool = RunspacePool;
  }

  public System.String Name
  {
    get
    {
      return _Name;
    }
  }

  public System.Guid InstanceID
  {
    get
    {
      return _RunspacePool.InstanceId;
    }
  }

  public System.Management.Automation.Runspaces.RunspacePool RunspacePool
  {
    get
    {
      return _RunspacePool;
    }
  }

  public System.Management.Automation.Runspaces.RunspacePoolState State
  {
    get
    {
      return _RunspacePool.RunspacePoolStateInfo.State;
    }
  }
}
"@
Add-Type -TypeDefinition $MyTypeData -Debug:$False
#endregion

#region ******** Update Format & Type Data ********
if ([System.IO.Directory]::Exists("$PSModuleRoot\TypeData"))
{
  Write-Verbose -Message "Updating Format and Type Data"
  # Update Format Data
  ForEach ($FormatData in [System.IO.Directory]::EnumerateFiles("$PSModuleRoot\TypeData", "*.Format.ps1xml"))
  {
    Write-Verbose -Message $FormatData
    Update-FormatData -AppendPath $FormatData -ErrorAction "SilentlyContinue"
  }
  
  # Update Type Data
  ForEach ($TypeData in [System.IO.Directory]::EnumerateFiles("$PSModuleRoot\TypeData", "*.Types.ps1xml"))
  {
    Write-Verbose -Message $TypeData
    Update-TypeData -AppendPath $TypeData -ErrorAction "SilentlyContinue"
  }
  Write-Verbose -Message ""
}
#endregion

#region ******** Load Private Commands ********
if ([System.IO.Directory]::Exists("$PSModuleRoot\Private"))
{
  Write-Verbose -Message "Loading Private Functions"
  ForEach ($Command in [System.IO.Directory]::EnumerateFiles("$PSModuleRoot\Private", "*.ps1"))
  {
    Write-Verbose -Message $Command
    . $Command
  }
  Write-Verbose -Message ""
}
#endregion

#region ******** Load Public Commands ********
$Functions = @()
if ([System.IO.Directory]::Exists("$PSModuleRoot\Public"))
{
  Write-Verbose -Message "Loading Public Functions"
  ForEach ($Command in [System.IO.Directory]::EnumerateFiles("$PSModuleRoot\Public", "*.ps1"))
  {
    Write-Verbose -Message $Command
    $Functions += [System.IO.Path]::GetFileNameWithoutExtension($Command)
    . $Command
  }
  Write-Verbose -Message ""
}
if ($Functions.Count)
{
  $Params.Function = $Functions
}
#endregion

#region ******** Load Public Variables ********
Write-Verbose -Message "Loading Public Variables"
$Variables = @()
Write-Verbose -Message ""
if ($Variables.Count)
{
  $Params.Variable = $Variables
}
#endregion

Export-ModuleMember @Params

Write-Verbose -Message ""
Write-Verbose -Message "Finished Loading Module = $($PSModule.Name)"
Write-Verbose -Message ""
