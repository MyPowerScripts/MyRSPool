
$ErrorActionPreference = "Stop"

#region ********* Custom Objects MyRSPool / MyRSJob *********

$MyCustom = @"
using System;
using System.Collections.Generic;
using System.Management.Automation;
using System.Threading;

public class MyRSJob
{
  private System.String _Name;
  private System.String _PoolName;
  private System.Guid _PoolID;
  private System.Management.Automation.PowerShell _PowerShell;
  private System.IAsyncResult _PowerShellAsyncResult;
  private System.Object _InputObject = null;

  public MyRSJob(System.String Name, System.Management.Automation.PowerShell PowerShell, System.IAsyncResult PowerShellAsyncResult, System.Object InputObject, System.String PoolName, System.Guid PoolID)
  {
    _Name = Name;
    _PoolName = PoolName;
    _PoolID = PoolID;
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

  public System.String PoolName
  {
    get
    {
      return _PoolName;
    }
  }

  public System.Guid PoolID
  {
    get
    {
      return _PoolID;
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
  private System.Collections.Hashtable _SyncedHash;
  private System.Threading.Mutex _Mutex;  

  public MyRSPool(System.String Name, System.Management.Automation.Runspaces.RunspacePool RunspacePool, System.Collections.Hashtable SyncedHash) 
  {
    _Name = Name;
    _RunspacePool = RunspacePool;
    _SyncedHash = SyncedHash;
  }

  public MyRSPool(System.String Name, System.Management.Automation.Runspaces.RunspacePool RunspacePool, System.Collections.Hashtable SyncedHash, System.String Mutex) 
  {
    _Name = Name;
    _RunspacePool = RunspacePool;
    _SyncedHash = SyncedHash;
    _Mutex = new System.Threading.Mutex(false, Mutex);
  }

  public System.Collections.Hashtable SyncedHash
  {
    get
    {
      return _SyncedHash;
    }
  }

  public System.Threading.Mutex Mutex
  {
    get
    {
      return _Mutex;
    }
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
Add-Type -TypeDefinition $MyCustom -Debug:$False

$Script:MyHiddenRSPool = New-Object -TypeName "System.Collections.Generic.Dictionary[[String], [MyRSPool]]"

#endregion

#region function Start-MyRSPool
function Start-MyRSPool()
{
  <#
    .SYNOPSIS
      Creates or Updates a RunspacePool
    .DESCRIPTION
      Function to do something specific
    .PARAMETER PoolName
      Name of RunspacePool
    .PARAMETER Functions
      Functions to include in the initial Session State
    .PARAMETER Variables
      Variables to include in the initial Session State
    .PARAMETER Modules
      Modules to load in the initial Session State
    .PARAMETER PSSnapins
      PSSnapins to load in the initial Session State
    .PARAMETER Hashtable
      Synced Hasttable to pass values between threads
    .PARAMETER Mutex
      Protects access to a shared resource
    .PARAMETER MaxJobs
      Maximum Number of Jobs
    .PARAMETER PassThru
      Return the New RSPool to the Pipeline
    .EXAMPLE
      Start-MyRSPool

      Create the Default RunspacePool
    .EXAMPLE
      $MyRSPool = Start-MyRSPool -PoolName $PoolName -MaxJobs $MaxJobs -PassThru

      Create a New RunspacePool and Return the RSPool to the Pipeline
    .NOTES
      Original Script By Ken Sweet on 10/15/2017
      Updated Script By Ken Sweet on 02/04/2019
    .LINK
  #>
  [CmdletBinding()]
  param (
    [String]$PoolName = "MyDefaultRSPool",
    [Hashtable]$Functions,
    [Hashtable]$Variables,
    [String[]]$Modules,
    [String[]]$PSSnapins,
    [Hashtable]$Hashtable = @{ "Enabled" = $True },
    [String]$Mutex,
    [ValidateRange(1, 64)]
    [Int]$MaxJobs = 8,
    [Switch]$PassThru
  )
  Write-Verbose -Message "Enter Function Start-MyRSPool"
  
  # check if Runspace Pool already exists
  if ($Script:MyHiddenRSPool.ContainsKey($PoolName))
  {
    # Return Existing Runspace Pool
    [MyRSPool]($Script:MyHiddenRSPool[$PoolName])
  }
  else
  {
    # Create Default Session State
    $InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    
    # Import Modules
    if ($PSBoundParameters.ContainsKey("Modules"))
    {
      [Void]$InitialSessionState.ImportPSModule($Modules)
    }
    
    # Import PSSnapins
    if ($PSBoundParameters.ContainsKey("PSSnapins"))
    {
      [Void]$InitialSessionState.ImportPSSnapIn($PSSnapins, [Ref]$Null)
    }
    
    # Add Common Functions
    if ($PSBoundParameters.ContainsKey("Functions"))
    {
      ForEach ($Key in $Functions.Keys)
      {
        #$InitialSessionState.Commands.Add(([System.Management.Automation.Runspaces.SessionStateFunctionEntry]::New($Key, $Functions[$Key])))
        $InitialSessionState.Commands.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList $Key, $Functions[$Key]))
      }
    }
    
    # Add Default Variables
    if ($PSBoundParameters.ContainsKey("Variables"))
    {
      ForEach ($Key in $Variables.Keys)
      {
        #$InitialSessionState.Variables.Add(([System.Management.Automation.Runspaces.SessionStateVariableEntry]::New($Key, $Variables[$Key], "$Key = $($Variables[$Key])", ([System.Management.Automation.ScopedItemOptions]::AllScope))))
        $InitialSessionState.Variables.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList $Key, $Variables[$Key], "$Key = $($Variables[$Key])", ([System.Management.Automation.ScopedItemOptions]::AllScope)))
      }
    }
    
    # Create and Open RunSpacePool
    $SyncedHash = [Hashtable]::Synchronized($Hashtable)
    #$InitialSessionState.Variables.Add(([System.Management.Automation.Runspaces.SessionStateVariableEntry]::New("SyncedHash", $SyncedHash, "SyncedHash = Synced Hashtable", ([System.Management.Automation.ScopedItemOptions]::AllScope))))
    $InitialSessionState.Variables.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList "SyncedHash", $SyncedHash, "SyncedHash = Synced Hashtable", ([System.Management.Automation.ScopedItemOptions]::AllScope)))
    if ($PSBoundParameters.ContainsKey("Mutex"))
    {
      #$InitialSessionState.Variables.Add(([System.Management.Automation.Runspaces.SessionStateVariableEntry]::New("Mutex", $Mutex, "Mutex = $Mutex", ([System.Management.Automation.ScopedItemOptions]::AllScope))))
      $InitialSessionState.Variables.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList "Mutex", $Mutex, "Mutex = $Mutex", ([System.Management.Automation.ScopedItemOptions]::AllScope)))
      $CreateRunspacePool = [Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $MaxJobs, $InitialSessionState, $Host)
      #$RSPool = [MyRSPool]::New($PoolName, $CreateRunspacePool, $SyncedHash, $Mutex)
      $RSPool = New-Object -TypeName "MyRSPool" -ArgumentList $PoolName, $CreateRunspacePool, $SyncedHash, $Mutex
    }
    else
    {
      $CreateRunspacePool = [Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $MaxJobs, $InitialSessionState, $Host)
      #$RSPool = [MyRSPool]::New($PoolName, $CreateRunspacePool, $SyncedHash)
      $RSPool = New-Object -TypeName "MyRSPool" -ArgumentList $PoolName, $CreateRunspacePool, $SyncedHash
    }
    
    $RSPool.RunspacePool.ApartmentState = "STA"
    #$RSPool.RunspacePool.ApartmentState = "MTA"
    $RSPool.RunspacePool.CleanupInterval = [TimeSpan]::FromMinutes(2)
    $RSPool.RunspacePool.Open()
    
    $Script:MyHiddenRSPool.Add($PoolName, $RSPool)
    
    if ($PassThru.IsPresent)
    {
      $RSPool
    }
  }
  
  Write-Verbose -Message "Exit Function Start-MyRSPool"
}
#endregion

#region function Get-MyRSPool
function Get-MyRSPool()
{
  <#
    .SYNOPSIS
      Get RunspacePools that match specified criteria
    .DESCRIPTION
      Get RunspacePools that match specified criteria
    .PARAMETER PoolName
      Name of RSPool to search for
    .PARAMETER PoolID
      PoolID of Job to search for
    .PARAMETER State
      State of Jobs to search for
    .EXAMPLE
      $MyRSPools = Get-MyRSPool
  
      Get all RSPools
    .EXAMPLE
      $MyRSPools = Get-MyRSPool -PoolName $PoolName
  
      $MyRSPools = Get-MyRSPool -PoolID $PoolID
  
      Get Specified RSPools
    .NOTES
      Original Script By Ken Sweet on 10/15/2017
      Updated Script By Ken Sweet on 02/04/2019
    .LINK
  #>
  [CmdletBinding(DefaultParameterSetName = "All")]
  param (
    [parameter(Mandatory = $True, ParameterSetName = "PoolName")]
    [String[]]$PoolName = "MyDefaultRSPool",
    [parameter(Mandatory = $True, ValueFromPipeline = $True, ParameterSetName = "PoolID")]
    [Guid[]]$PoolID,
    [parameter(Mandatory = $False, ParameterSetName = "All")]
    [parameter(Mandatory = $False, ParameterSetName = "PoolName")]
    [parameter(Mandatory = $False, ParameterSetName = "PoolID")]
    [ValidateSet("BeforeOpen", "Opening", "Opened", "Closed", "Closing", "Broken", "Disconnecting", "Disconnected", "Connecting")]
    [String[]]$State
  )
  Begin
  {
    Write-Verbose -Message "Enter Function Get-MyRSPool Begin Block"
    
    # Set Job State RegEx Pattern
    if ($PSBoundParameters.ContainsKey("State"))
    {
      $StatePattern = $State -join "|"
    }
    else
    {
      $StatePattern = ".*"
    }
    
    Write-Verbose -Message "Exit Function Get-MyRSPool Begin Block"
  }
  Process
  {
    Write-Verbose -Message "Enter Function Get-MyRSPool Process Block"
    
    switch ($PSCmdlet.ParameterSetName)
    {
      "All"
      {
        # Return Matching Pools
        [MyRSPool[]](($Script:MyHiddenRSPool.Values | Where-Object -FilterScript { $PSItem.State -match $StatePattern }))
        Break;
      }
      "PoolName" {
        # Set Pool Name and Return Matching Pools
        $NamePattern = $PoolName -join "|"
        [MyRSPool[]]($Script:MyHiddenRSPool.Values | Where-Object -FilterScript { $PSItem.State -match $StatePattern -and $PSItem.Name -match $NamePattern})
        Break;
      }
      "PoolID" {
        # Set PoolID and Return Matching Pools
        $IDPattern = $PoolID -join "|"
        [MyRSPool[]]($Script:MyHiddenRSPool.Values | Where-Object -FilterScript { $PSItem.State -match $StatePattern -and $PSItem.InstanceId -match $IDPattern })
        Break;
      }
    }
    
    Write-Verbose -Message "Exit Function Get-MyRSPool Process Block"
  }
}
#endregion

#region function Close-MyRSPool
function Close-MyRSPool()
{
  <#
    .SYNOPSIS
      Close RunspacePool and Stop all Running Jobs
    .DESCRIPTION
      Close RunspacePool and Stop all Running Jobs
    .PARAMETER RSPool
      RunspacePool to clsoe
    .PARAMETER PoolName
      Name of RSPool to close
    .PARAMETER PoolID
      PoolID of Job to close
    .PARAMETER State
      State of Jobs to close
    .EXAMPLE
      Close-MyRSPool
  
      Close the Default RSPool
    .EXAMPLE
      Close-MyRSPool -PoolName $PoolName
  
      Close-MyRSPool -PoolID $PoolID
  
      Close Specified RSPools
    .NOTES
      Original Script By Ken Sweet on 10/15/2017
      Updated Script By Ken Sweet on 02/04/2019
    .LINK
  #>
  [CmdletBinding(DefaultParameterSetName = "All")]
  param (
    [parameter(Mandatory = $True, ValueFromPipeline = $True, ParameterSetName = "RSPool")]
    [MyRSPool[]]$RSPool,
    [parameter(Mandatory = $True, ParameterSetName = "PoolName")]
    [String[]]$PoolName = "MyDefaultRSPool",
    [parameter(Mandatory = $True, ParameterSetName = "PoolID")]
    [Guid[]]$PoolID,
    [parameter(Mandatory = $False, ParameterSetName = "All")]
    [parameter(Mandatory = $False, ParameterSetName = "PoolName")]
    [parameter(Mandatory = $False, ParameterSetName = "PoolID")]
    [ValidateSet("BeforeOpen", "Opening", "Opened", "Closed", "Closing", "Broken", "Disconnecting", "Disconnected", "Connecting")]
    [String[]]$State
  )
  Process
  {
    Write-Verbose -Message "Enter Function Close-MyRSPool Process Block"
    
    If ($PSCmdlet.ParameterSetName -eq "RSPool")
    {
      $TempPools = $RSPool
    }
    else
    {
      $TempPools = [MyRSPool[]](Get-MyRSPool @PSBoundParameters)
    }
    
    # Close RunspacePools, This will Stop all Running Jobs
    ForEach ($TempPool in $TempPools)
    {
      if (-not [String]::IsNullOrEmpty($TempPool.Mutex))
      {
        $TempPool.Mutex.Close()
        $TempPool.Mutex.Dispose()
      }
      $TempPool.RunspacePool.Close()
      $TempPool.RunspacePool.Dispose()
      [Void]$Script:MyHiddenRSPool.Remove($TempPool.Name)
    }
    
    Write-Verbose -Message "Exit Function Close-MyRSPool Process Block"
  }
  End
  {
    Write-Verbose -Message "Enter Function Close-MyRSPool End Block"
    
    # Garbage Collect, Recover Resources
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    Write-Verbose -Message "Exit Function Close-MyRSPool End Block"
  }
}
#endregion

#region function Start-MyRSJob
function Start-MyRSJob()
{
  <#
    .SYNOPSIS
      Creates or Updates a RunspacePool
    .DESCRIPTION
      Function to do something specific
    .PARAMETER RSPool
      RunspacePool to add new RunspacePool Jobs to
    .PARAMETER PoolName
      Name of RunspacePool
    .PARAMETER PoolID
      ID of RunspacePool
    .PARAMETER InputObject
      Object / Value to pass to the RunspacePool Job ScriptBlock
    .PARAMETER InputParam
      Paramter to pass the Object / Value as
    .PARAMETER JobName
      Name of RunspacePool Jobs
    .PARAMETER ScriptBlock
      RunspacePool Job ScriptBock to Execute
    .PARAMETER Parameters
      Common Paramaters to pass to the RunspacePool Job ScriptBlock
    .PARAMETER PassThru
      Return the New Jobs to the Pipeline
    .EXAMPLE
      Start-MyRSJob -ScriptBlock $ScriptBlock -JobName $JobName -InputObject $InputObject

      Add new RSJobs to the Default RSPool
    .EXAMPLE
      $InputObject | Start-MyRSJob -ScriptBlock $ScriptBlock -RSPool $RSPool -JobName $JobName
  
      $InputObject | Start-MyRSJob -ScriptBlock $ScriptBlock -PoolName $PoolName -JobName $JobName
  
      $InputObject | Start-MyRSJob -ScriptBlock $ScriptBlock -PoolID $PoolID -JobName $JobName

      Add new RSJobs to the Specified RSPool
    .NOTES
      Original Script By Ken Sweet on 10/15/2017
      Updated Script By Ken Sweet on 02/04/2019
    .LINK
  #>
  [CmdletBinding(DefaultParameterSetName = "PoolName")]
  param (
    [parameter(Mandatory = $True, ParameterSetName = "RSPool")]
    [MyRSPool]$RSPool,
    [parameter(Mandatory = $False, ParameterSetName = "PoolName")]
    [String]$PoolName = "MyDefaultRSPool",
    [parameter(Mandatory = $True, ParameterSetName = "PoolID")]
    [Guid]$PoolID,
    [parameter(Mandatory = $False, ValueFromPipeline = $True)]
    [Object[]]$InputObject,
    [String]$InputParam = "InputObject",
    [String]$JobName = "Job Name",
    [parameter(Mandatory = $True)]
    [ScriptBlock]$ScriptBlock,
    [Hashtable]$Parameters,
    [Switch]$PassThru
  )
  Begin
  {
    Write-Verbose -Message "Enter Function Start-MyRSJob Begin Block"
    
    Switch ($PSCmdlet.ParameterSetName)
    {
      "RSPool" {
        # Set Pool
        $TempPool = $RSPool
        Break;
      }
      "PoolName" {
        # Set Pool Name and Return Matching Pools
        $TempPool = [MyRSPool](Start-MyRSPool -PoolName $PoolName -PassThru)
        Break;
      }
      "PoolID" {
        # Set PoolID Return Matching Pools
        $TempPool = [MyRSPool](Get-MyRSPool -PoolID $PoolID)
        Break;
      }
    }
    
    # List for New Jobs
    #$NewJobs = [System.Collections.Generic.List[MyRSJob]]::New())
    $NewJobs = New-Object -TypeName "System.Collections.Generic.List[MyRSJob]"
    
    Write-Verbose -Message "Exit Function Start-MyRSJob Begin Block"
  }
  Process
  {
    Write-Verbose -Message "Enter Function Start-MyRSJob Process Block"
    
    if ($PSBoundParameters.ContainsKey("InputObject"))
    {
      ForEach ($Object in $InputObject)
      {
        # Create New PowerShell Instance with ScriptBlock
        $PowerShell = ([Management.Automation.PowerShell]::Create()).AddScript($ScriptBlock)
        # Set RunspacePool
        $PowerShell.RunspacePool = $TempPool.RunspacePool
        # Add Parameters
        [Void]$PowerShell.AddParameter($InputParam, $Object)
        if ($PSBoundParameters.ContainsKey("Parameters"))
        {
          [Void]$PowerShell.AddParameters($Parameters)
        }
        # set Job Name
        if (($Object -is [String]) -or ($Object -is [ValueType]))
        {
          $TempJobName = "$JobName - $($Object)"
        }
        else
        {
          $TempJobName = $($Object.$JobName)
        }
        #[Void]$NewJobs.Add(([MyRSjob]::New($TempJobName, $PowerShell, $PowerShell.BeginInvoke(), $Object, $TempPool.Name, $TempPool.InstanceID)))
        [Void]$NewJobs.Add((New-Object -TypeName "MyRSjob" -ArgumentList $TempJobName, $PowerShell, $PowerShell.BeginInvoke(), $Object, $TempPool.Name, $TempPool.InstanceID))
      }
    }
    else
    {
      # Create New PowerShell Instance with ScriptBlock
      $PowerShell = ([Management.Automation.PowerShell]::Create()).AddScript($ScriptBlock)
      # Set RunspacePool
      $PowerShell.RunspacePool = $TempPool.RunspacePool
      # Add Parameters
      if ($PSBoundParameters.ContainsKey("Parameters"))
      {
        [Void]$PowerShell.AddParameters($Parameters)
      }
      #[Void]$NewJobs.Add(([MyRSjob]::New($JobName, $PowerShell, $PowerShell.BeginInvoke(), $Null, $TempPool.Name, $TempPool.InstanceID)))
      [Void]$NewJobs.Add((New-Object -TypeName "MyRSjob" -ArgumentList $JobName, $PowerShell, $PowerShell.BeginInvoke(), $Null, $TempPool.Name, $TempPool.InstanceID))
    }
    
    Write-Verbose -Message "Exit Function Start-MyRSJob Process Block"
  }
  End
  {
    Write-Verbose -Message "Enter Function Start-MyRSJob End Block"
    
    if ($NewJobs.Count)
    {
      $TempPool.Jobs.AddRange($NewJobs)
      # Return Jobs only if New RunspacePool
      if ($PassThru.IsPresent)
      {
        $NewJobs
      }
      $NewJobs.Clear()
    }
    
    Write-Verbose -Message "Exit Function Start-MyRSJob End Block"
  }
}
#endregion

#region function Get-MyRSJob
function Get-MyRSJob()
{
  <#
    .SYNOPSIS
      Get Jobs from RunspacePool that match specified criteria
    .DESCRIPTION
      Get Jobs from RunspacePool that match specified criteria
    .PARAMETER RSPool
      RunspacePool to search
    .PARAMETER PoolName
      Name of Pool to Get Jobs From
    .PARAMETER PoolID
      ID of Pool to Get Jobs From
    .PARAMETER JobName
      Name of Jobs to Get
    .PARAMETER JobID
      ID of Jobs to Get
    .PARAMETER State
      State of Jobs to search for
    .EXAMPLE
      $MyRSJobs = Get-MyRSJob
  
      Get RSJobs from the Default RSPool
    .EXAMPLE
      $MyRSJobs = Get-MyRSJob -RSPool $RSPool
  
      $MyRSJobs = Get-MyRSJob -PoolName $PoolName
  
      $MyRSJobs = Get-MyRSJob -PoolID $PoolID
  
      Get RSJobs from the Specified RSPool
    .NOTES
      Original Script By Ken Sweet on 10/15/2017
      Updated Script By Ken Sweet on 02/04/2019
    .LINK
  #>
  [CmdletBinding(DefaultParameterSetName = "JobNamePoolName")]
  param (
    [parameter(Mandatory = $True, ParameterSetName = "JobIDPool")]
    [parameter(Mandatory = $True, ParameterSetName = "JobNamePool")]
    [MyRSPool[]]$RSPool,
    [parameter(Mandatory = $False, ParameterSetName = "JobIDPoolName")]
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePoolName")]
    [String]$PoolName = "MyDefaultRSPool",
    [parameter(Mandatory = $True, ParameterSetName = "JobIDPoolID")]
    [parameter(Mandatory = $True, ParameterSetName = "JobNamePoolID")]
    [Guid]$PoolID,
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePool")]
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePoolName")]
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePoolID")]
    [String[]]$JobName = ".*",
    [parameter(Mandatory = $True, ValueFromPipeline = $True, ParameterSetName = "JobIDPool")]
    [parameter(Mandatory = $True, ValueFromPipeline = $True, ParameterSetName = "JobIDPoolName")]
    [parameter(Mandatory = $True, ValueFromPipeline = $True, ParameterSetName = "JobIDPoolID")]
    [Guid[]]$JobID,
    [ValidateSet("NotStarted", "Running", "Stopping", "Stopped", "Completed", "Failed", "Disconnected")]
    [String[]]$State
  )
  Begin
  {
    Write-Verbose -Message "Enter Function Get-MyRSJob Begin Block"
    
    # Set Job State RegEx Pattern
    if ($PSBoundParameters.ContainsKey("State"))
    {
      $StatePattern = $State -join "|"
    }
    else
    {
      $StatePattern = ".*"
    }
    
    Switch -regex ($PSCmdlet.ParameterSetName)
    {
      "Pool$" {
        # Set Pool
        $TempPools = $RSPool
        Break;
      }
      "PoolName$" {
        # Set Pool Name and Return Matching Pools
        $TempPools = [MyRSPool[]](Get-MyRSPool -PoolName $PoolName)
        Break;
      }
      "PoolID$" {
        # Set PoolID Return Matching Pools
        $TempPools = [MyRSPool[]](Get-MyRSPool -PoolID $PoolID)
        Break;
      }
    }
    
    Write-Verbose -Message "Exit Function Get-MyRSJob Begin Block"
  }
  Process
  {
    Write-Verbose -Message "Enter Function Get-MyRSJob Process Block"
    
    Switch -regex ($PSCmdlet.ParameterSetName)
    {
      "^JobName" {
        # Set Job Name RegEx Pattern and Return Matching Jobs
        $NamePattern = $JobName -join "|"
        [MyRSJob[]]($TempPools | ForEach-Object -Process { $PSItem.Jobs | Where-Object -FilterScript { $PSItem.State -match $StatePattern -and $PSItem.Name -match $NamePattern } })
        Break;
      }
      "^JobID" {
        # Set Job ID RegEx Pattern and Return Matching Jobs
        $IDPattern = $JobID -join "|"
        [MyRSJob[]]($TempPools | ForEach-Object -Process { $PSItem.Jobs | Where-Object -FilterScript { $PSItem.State -match $StatePattern -and $PSItem.InstanceId -match $IDPattern } })
        Break;
      }
    }
    
    Write-Verbose -Message "Exit Function Get-MyRSJob Process Block"
  }
}
#endregion

#region function Wait-MyRSJob
function Wait-MyRSJob()
{
  <#
    .SYNOPSIS
      Wait for RSJob to Finish
    .DESCRIPTION
      Wait for RSJob to Finish
    .PARAMETER RSPool
      RunspacePool to search
    .PARAMETER PoolName
      Name of Pool to Get Jobs From
    .PARAMETER PoolID
      ID of Pool to Get Jobs From
    .PARAMETER JobName
      Name of Jobs to Get
    .PARAMETER JobID
      ID of Jobs to Get
    .PARAMETER State
      State of Jobs to search for
    .PARAMETER ScriptBlock
      ScriptBlock to invoke while waiting

      For windows Forms scripts add the DoEvents method in to the Wait ScritpBlock

      [System.Windows.Forms.Application]::DoEvents()
      [System.Threading.Thread]::Sleep(250)
    .PARAMETER Wait
      TimeSpace to wait
    .PARAMETER NoWait
      No Wait, Return when any Job states changes to Stopped, Completed, or Failed
    .PARAMETER PassThru
      Return the New Jobs to the Pipeline
    .EXAMPLE
      $MyRSJobs = Wait-MyRSJob -PassThru
  
      Wait for and Get RSJobs from the Default RSPool
    .EXAMPLE
      $MyRSJobs = Wait-MyRSJob -RSPool $RSPool -PassThru
  
      $MyRSJobs = Wait-MyRSJob -PoolName $PoolName -PassThru
  
      $MyRSJobs = Wait-MyRSJob -PoolID $PoolID -PassThru
  
      Wait for and Get RSJobs from the Specified RSPool
    .NOTES
      Original Script By Ken Sweet on 10/15/2017
      Updated Script By Ken Sweet on 02/04/2019
    .LINK
  #>
  [CmdletBinding(DefaultParameterSetName = "JobNamePoolName")]
  param (
    [parameter(Mandatory = $True, ParameterSetName = "JobIDPool")]
    [parameter(Mandatory = $True, ParameterSetName = "JobNamePool")]
    [MyRSPool[]]$RSPool,
    [parameter(Mandatory = $False, ParameterSetName = "JobIDPoolName")]
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePoolName")]
    [String]$PoolName = "MyDefaultRSPool",
    [parameter(Mandatory = $True, ParameterSetName = "JobIDPoolID")]
    [parameter(Mandatory = $True, ParameterSetName = "JobNamePoolID")]
    [Guid]$PoolID,
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePool")]
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePoolName")]
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePoolID")]
    [String[]]$JobName = ".*",
    [parameter(Mandatory = $True, ParameterSetName = "JobIDPool")]
    [parameter(Mandatory = $True, ParameterSetName = "JobIDPoolName")]
    [parameter(Mandatory = $True, ParameterSetName = "JobIDPoolID")]
    [Guid[]]$JobID,
    [parameter(Mandatory = $True, ValueFromPipeline = $True, ParameterSetName = "RSJob")]
    [MyRSJob[]]$RSJob,
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePool")]
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePoolName")]
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePoolID")]
    [parameter(Mandatory = $False, ParameterSetName = "JobIDPool")]
    [parameter(Mandatory = $False, ParameterSetName = "JobIDPoolName")]
    [parameter(Mandatory = $False, ParameterSetName = "JobIDPoolID")]
    [ValidateSet("NotStarted", "Running", "Stopping", "Stopped", "Completed", "Failed", "Disconnected")]
    [String[]]$State,
    [ScriptBlock]$SciptBlock = { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 200 },
    [ValidateRange("0:00:00", "8:00:00")]
    [TimeSpan]$Wait = "0:05:00",
    [Switch]$NoWait,
    [Switch]$PassThru
  )
  Begin
  {
    Write-Verbose -Message "Enter Function Wait-MyRSJob Begin Block"
    
    # Remove Invalid Get-MyRSJob Parameters
    if ($PSCmdlet.ParameterSetName -ne "RSJob")
    {
      if ($PSBoundParameters.ContainsKey("PassThru"))
      {
        [Void]$PSBoundParameters.Remove("PassThru")
      }
      if ($PSBoundParameters.ContainsKey("Wait"))
      {
        [Void]$PSBoundParameters.Remove("Wait")
      }
      if ($PSBoundParameters.ContainsKey("NoWait"))
      {
        [Void]$PSBoundParameters.Remove("NoWait")
      }
      if ($PSBoundParameters.ContainsKey("ScriptBlock"))
      {
        [Void]$PSBoundParameters.Remove("ScriptBlock")
      }
    }
    
    # List for Wait Jobs
    #$WaitJobs = [System.Collections.Generic.List[MyRSJob]]::New())
    $WaitJobs = New-Object -TypeName "System.Collections.Generic.List[MyRSJob]"
    
    Write-Verbose -Message "Exit Function Wait-MyRSJob Begin Block"
  }
  Process
  {
    Write-Verbose -Message "Enter Function Wait-MyRSJob Process Block"
    
    # Add Passed RSJobs to $Jobs
    if ($PSCmdlet.ParameterSetName -eq "RSJob")
    {
      $WaitJobs.AddRange($RSJob)
    }
    else
    {
      $WaitJobs.AddRange([MyRSJob[]](Get-MyRSJob @PSBoundParameters))
    }
    
    Write-Verbose -Message "Exit Function Wait-MyRSJob Process Block"
  }
  End
  {
    Write-Verbose -Message "Enter Function Wait-MyRSJob End Block"
    
    # Wait for Jobs to be Finshed
    if ($NoWait.IsPresent)
    {
      While (@(($WaitJobs | Where-Object -FilterScript { $PSItem.State -notmatch "Stopped|Completed|Failed" })).Count -eq $WaitJobs.Count)
      {
        $SciptBlock.Invoke()
      }
    }
    else
    {
      [Object[]]$CheckJobs = $WaitJobs.ToArray()
      $Start = [DateTime]::Now
      While (@(($CheckJobs = $CheckJobs | Where-Object -FilterScript { $PSItem.State -notmatch "Stopped|Completed|Failed" })).Count -and ((([DateTime]::Now - $Start) -le $Wait) -or ($Wait.Ticks -eq 0)))
      {
        $SciptBlock.Invoke()
      }
    }
    
    if ($PassThru.IsPresent)
    {
      # Return Completed Jobs
      [MyRSJob[]]($WaitJobs | Where-Object -FilterScript { $PSItem.State -match "Stopped|Completed|Failed" })
    }
    $WaitJobs.Clear()
    
    Write-Verbose -Message "Exit Function Wait-MyRSJob End Block"
  }
}
#endregion

#region function Stop-MyRSJob
function Stop-MyRSJob()
{
  <#
    .SYNOPSIS
      Function to do something specific
    .DESCRIPTION
      Function to do something specific
    .PARAMETER RSPool
      RunspacePool to search
    .PARAMETER Name
      Name of Job to search for
    .PARAMETER InstanceId
      InstanceId of Job to search for
    .PARAMETER RSJob
      RunspacePool Jobs to Process
    .PARAMETER State
      State of Jobs to search for
    .EXAMPLE
      Stop-MyRSJob
  
      Stop all RSJobs in the Default RSPool
    .EXAMPLE
      Stop-MyRSJob -RSPool $RSPool
  
      Stop-MyRSJob -PoolName $PoolName
  
      Stop-MyRSJob -PoolID $PoolID
  
      Stop all RSJobs in the Specified RSPool
    .NOTES
      Original Script By Ken Sweet on 10/15/2017
      Updated Script By Ken Sweet on 02/04/2019
    .LINK
  #>
  [CmdletBinding(DefaultParameterSetName = "JobNamePoolName")]
  param (
    [parameter(Mandatory = $True, ParameterSetName = "JobIDPool")]
    [parameter(Mandatory = $True, ParameterSetName = "JobNamePool")]
    [MyRSPool[]]$RSPool,
    [parameter(Mandatory = $False, ParameterSetName = "JobIDPoolName")]
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePoolName")]
    [String]$PoolName = "MyDefaultRSPool",
    [parameter(Mandatory = $True, ParameterSetName = "JobIDPoolID")]
    [parameter(Mandatory = $True, ParameterSetName = "JobNamePoolID")]
    [Guid]$PoolID,
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePool")]
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePoolName")]
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePoolID")]
    [String[]]$JobName = ".*",
    [parameter(Mandatory = $True, ParameterSetName = "JobIDPool")]
    [parameter(Mandatory = $True, ParameterSetName = "JobIDPoolName")]
    [parameter(Mandatory = $True, ParameterSetName = "JobIDPoolID")]
    [Guid[]]$JobID,
    [parameter(Mandatory = $True, ValueFromPipeline = $True, ParameterSetName = "RSJob")]
    [MyRSJob[]]$RSJob,
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePool")]
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePoolName")]
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePoolID")]
    [parameter(Mandatory = $False, ParameterSetName = "JobIDPool")]
    [parameter(Mandatory = $False, ParameterSetName = "JobIDPoolName")]
    [parameter(Mandatory = $False, ParameterSetName = "JobIDPoolID")]
    [ValidateSet("NotStarted", "Running", "Stopping", "Stopped", "Completed", "Failed", "Disconnected")]
    [String[]]$State
  )
  Process
  {
    Write-Verbose -Message "Enter Function Stop-MyRSJob Process Block"
    
    # Add Passed RSJobs to $Jobs
    if ($PSCmdlet.ParameterSetName -eq "RSJob")
    {
      $TempJobs = $RSJob
    }
    else
    {
      $TempJobs = [MyRSJob[]](Get-MyRSJob @PSBoundParameters)
    }
    
    # Stop all Jobs that have not Finished
    ForEach ($TempJob in $TempJobs)
    {
      if ($TempJob.State -notmatch "Stopped|Completed|Failed")
      {
        $TempJob.PowerShell.Stop()
      }
    }
    
    Write-Verbose -Message "Exit Function Stop-MyRSJob Process Block"
  }
  End
  {
    Write-Verbose -Message "Enter Function Stop-MyRSJob End Block"
    
    # Garbage Collect, Recover Resources
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    Write-Verbose -Message "Exit Function Stop-MyRSJob End Block"
  }
}
#endregion

#region function Receive-MyRSJob
function Receive-MyRSJob()
{
  <#
    .SYNOPSIS
      Receive Output from Completed Jobs
    .DESCRIPTION
      Receive Output from Completed Jobs
    .PARAMETER RSPool
      RunspacePool to search
    .PARAMETER PoolName
      Name of Pool to Get Jobs From
    .PARAMETER PoolID
      ID of Pool to Get Jobs From
    .PARAMETER JobName
      Name of Jobs to Get
    .PARAMETER JobID
      ID of Jobs to Get
    .PARAMETER RSJob
      Jobs to Process
    .PARAMETER AutoRemove
      Remove Jobs after Receiving Output
    .EXAMPLE
      $MyResults = Receive-MyRSJob -AutoRemove
  
      Receive Results from RSJobs in the Default RSPool
    .EXAMPLE
      $MyResults = Receive-MyRSJob -RSPool $RSPool -AutoRemove
  
      $MyResults = Receive-MyRSJob -PoolName $PoolName -AutoRemove
  
      $MyResults = Receive-MyRSJob -PoolID $PoolID -AutoRemove
  
      Receive Results from RSJobs in the Specified RSPool
    .NOTES
      Original Script By Ken Sweet on 10/15/2017
      Updated Script By Ken Sweet on 02/04/2019
    .LINK
  #>
  [CmdletBinding(DefaultParameterSetName = "JobNamePoolName")]
  param (
    [parameter(Mandatory = $True, ParameterSetName = "JobIDPool")]
    [parameter(Mandatory = $True, ParameterSetName = "JobNamePool")]
    [MyRSPool[]]$RSPool,
    [parameter(Mandatory = $False, ParameterSetName = "JobIDPoolName")]
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePoolName")]
    [String]$PoolName = "MyDefaultRSPool",
    [parameter(Mandatory = $True, ParameterSetName = "JobIDPoolID")]
    [parameter(Mandatory = $True, ParameterSetName = "JobNamePoolID")]
    [Guid]$PoolID,
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePool")]
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePoolName")]
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePoolID")]
    [String[]]$JobName = ".*",
    [parameter(Mandatory = $True, ValueFromPipeline = $True, ParameterSetName = "JobIDPool")]
    [parameter(Mandatory = $True, ValueFromPipeline = $True, ParameterSetName = "JobIDPoolName")]
    [parameter(Mandatory = $True, ValueFromPipeline = $True, ParameterSetName = "JobIDPoolID")]
    [Guid[]]$JobID,
    [parameter(Mandatory = $True, ValueFromPipeline = $True, ParameterSetName = "RSJob")]
    [MyRSJob[]]$RSJob,
    [Switch]$AutoRemove,
    [Switch]$Force
  )
  Begin
  {
    Write-Verbose -Message "Enter Function Receive-MyRSJob Begin Block"
    
    # Remove Invalid Get-MyRSJob Parameters
    if ($PSCmdlet.ParameterSetName -ne "RSJob")
    {
      if ($PSBoundParameters.ContainsKey("AutoRemove"))
      {
        [Void]$PSBoundParameters.Remove("AutoRemove")
      }
    }
    
    # List for Remove Jobs
    #$RemoveJobs = [System.Collections.Generic.List[MyRSJob]]::New())
    $RemoveJobs = New-Object -TypeName "System.Collections.Generic.List[MyRSJob]"
    
    Write-Verbose -Message "Exit Function Receive-MyRSJob Begin Block"
  }
  Process
  {
    Write-Verbose -Message "Enter Function Receive-MyRSJob Process Block"
    
    # Add Passed RSJobs to $Jobs
    if ($PSCmdlet.ParameterSetName -eq "RSJob")
    {
      $TempJobs = $RSJob
    }
    else
    {
      [Void]$PSBoundParameters.Add("State", "Completed")
      $TempJobs = [MyRSJob[]](Get-MyRSJob @PSBoundParameters)
    }
    
    # Receive all Complted Jobs, Remove Job if Required
    ForEach ($TempJob in $TempJobs)
    {
      if ($TempJob.IsCompleted)
      {
        Try
        {
          $TempJob.PowerShell.EndInvoke($TempJob.PowerShellAsyncResult)
          # Add Job to Remove List
          [Void]$RemoveJobs.Add($TempJob)
        }
        Catch
        {
        }
      }
    }
    
    Write-Verbose -Message "Exit Function Receive-MyRSJob Process Block"
  }
  End
  {
    Write-Verbose -Message "Enter Function Receive-MyRSJob End Block"
    
    if ($AutoRemove.IsPresent)
    {
      # Remove RSJobs
      foreach ($RemoveJob in $RemoveJobs)
      {
        $RemoveJob.PowerShell.Dispose()
        [Void]$Script:MyHiddenRSPool[$RemoveJob.PoolName].Jobs.Remove($RemoveJob)
      }
      $RemoveJobs.Clear()
    }
    
    # Garbage Collect, Recover Resources
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    Write-Verbose -Message "Exit Function Receive-MyRSJob End Block"
  }
}
#endregion

#region function Remove-MyRSJob
function Remove-MyRSJob()
{
  <#
    .SYNOPSIS
      Function to do something specific
    .DESCRIPTION
      Function to do something specific
    .PARAMETER RSPool
      RunspacePool to search
    .PARAMETER Name
      Name of Job to search for
    .PARAMETER InstanceId
      InstanceId of Job to search for
    .PARAMETER RSJob
      RunspacePool Jobs to Process
    .PARAMETER State
      State of Jobs to search for
    .PARAMETER Force
      Force the Job to stop
    .EXAMPLE
      Remove-MyRSJob
  
      Remove all RSJobs in the Default RSPool
    .EXAMPLE
      Remove-MyRSJob -RSPool $RSPool
  
      Remove-MyRSJob -PoolName $PoolName
  
      Remove-MyRSJob -PoolID $PoolID
  
      Remove all RSJobs in the Specified RSPool
    .NOTES
      Original Script By Ken Sweet on 10/15/2017 at 06:53 AM
      Updated Script By Ken Sweet on 02/04/2019 at 06:53 AM
    .LINK
  #>
  [CmdletBinding(DefaultParameterSetName = "JobNamePoolName")]
  param (
    [parameter(Mandatory = $True, ParameterSetName = "JobIDPool")]
    [parameter(Mandatory = $True, ParameterSetName = "JobNamePool")]
    [MyRSPool[]]$RSPool,
    [parameter(Mandatory = $False, ParameterSetName = "JobIDPoolName")]
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePoolName")]
    [String]$PoolName = "MyDefaultRSPool",
    [parameter(Mandatory = $True, ParameterSetName = "JobIDPoolID")]
    [parameter(Mandatory = $True, ParameterSetName = "JobNamePoolID")]
    [Guid]$PoolID,
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePool")]
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePoolName")]
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePoolID")]
    [String[]]$JobName = ".*",
    [parameter(Mandatory = $True, ParameterSetName = "JobIDPool")]
    [parameter(Mandatory = $True, ParameterSetName = "JobIDPoolName")]
    [parameter(Mandatory = $True, ParameterSetName = "JobIDPoolID")]
    [Guid[]]$JobID,
    [parameter(Mandatory = $True, ValueFromPipeline = $True, ParameterSetName = "RSJob")]
    [MyRSJob[]]$RSJob,
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePool")]
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePoolName")]
    [parameter(Mandatory = $False, ParameterSetName = "JobNamePoolID")]
    [parameter(Mandatory = $False, ParameterSetName = "JobIDPool")]
    [parameter(Mandatory = $False, ParameterSetName = "JobIDPoolName")]
    [parameter(Mandatory = $False, ParameterSetName = "JobIDPoolID")]
    [ValidateSet("NotStarted", "Running", "Stopping", "Stopped", "Completed", "Failed", "Disconnected")]
    [String[]]$State,
    [Switch]$Force
  )
  Begin
  {
    Write-Verbose -Message "Enter Function Remove-MyRSJob Begin Block"
    
    # Remove Invalid Get-MyRSJob Parameters
    if ($PSCmdlet.ParameterSetName -ne "RSJob")
    {
      if ($PSBoundParameters.ContainsKey("Force"))
      {
        [Void]$PSBoundParameters.Remove("Force")
      }
    }
    
    # List for Remove Jobs
    #$RemoveJobs = [System.Collections.Generic.List[MyRSJob]]::New())
    $RemoveJobs = New-Object -TypeName "System.Collections.Generic.List[MyRSJob]"
    
    Write-Verbose -Message "Exit Function Remove-MyRSJob Begin Block"
  }
  Process
  {
    Write-Verbose -Message "Enter Function Remove-MyRSJob Process Block"
    
    # Add Passed RSJobs to $Jobs
    if ($PSCmdlet.ParameterSetName -eq "RSJob")
    {
      $TempJobs = $RSJob
    }
    else
    {
      $TempJobs = [MyRSJob[]](Get-MyRSJob @PSBoundParameters)
    }
    
    # Remove all Jobs, Stop all Running if Forced
    ForEach ($TempJob in $TempJobs)
    {
      if ($Force -and $TempJob.State -notmatch "Stopped|Completed|Failed")
      {
        $TempJob.PowerShell.Stop()
      }
      if ($TempJob.State -match "Stopped|Completed|Failed")
      {
        # Add Job to Remove List
        [Void]$RemoveJobs.Add($TempJob)
      }
    }
    
    Write-Verbose -Message "Exit Function Remove-MyRSJob Process Block"
  }
  End
  {
    Write-Verbose -Message "Enter Function Remove-MyRSJob End Block"
    
    # Remove RSJobs
    foreach ($RemoveJob in $RemoveJobs)
    {
      $RemoveJob.PowerShell.Dispose()
      [Void]$Script:MyHiddenRSPool[$RemoveJob.PoolName].Jobs.Remove($RemoveJob)
    }
    $RemoveJobs.Clear()
    
    # Garbage Collect, Recover Resources
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    Write-Verbose -Message "Exit Function Remove-MyRSJob End Block"
  }
}
#endregion


#region ******** Sample Code ********

$VerbosePreference = "SilentlyContinue"

#region function Test-Function
Function Test-Function
{
  <#
    .SYNOPSIS
      Test Function for RunspacePool ScriptBlock
    .DESCRIPTION
      Test Function for RunspacePool ScriptBlock
    .PARAMETER Value
      Value Command Line Parameter
    .EXAMPLE
      Test-Function -Value "String"
    .NOTES
      Original Function By Ken Sweet
    .LINK
  #>
  [CmdletBinding(DefaultParameterSetName = "Default")]
  param (
    [parameter(Mandatory = $False, HelpMessage = "Enter Value", ParameterSetName = "Default")]
    [Object[]]$Value = "Default Value"
  )
  Write-Verbose -Message "Enter Function Test-Function"
  
  Start-Sleep -Milliseconds (1000 * 5)
  ForEach ($Item in $Value)
  {
    "Return Value: `$Item = $Item"
  }
  
  Write-Verbose -Message "Exit Function Test-Function"
}
#endregion

#region Job $ScriptBlock
$ScriptBlock = {
  <#
    .SYNOPSIS
      Test RunspacePool ScriptBlock
    .DESCRIPTION
      Test RunspacePool ScriptBlock
    .PARAMETER InputObject
      InputObject passed to script
    .EXAMPLE
      Test-Script.ps1 -InputObject $InputObject
    .NOTES
      Original Script By Ken Sweet on 10/15/2017
      Updated Script By Ken Sweet on 02/04/2019
  
      Thread Script Variables
        [String]$Mutex - Exist only if -Mutex was specified on the Start-MyRSPool command line
        [HashTable]$SyncedHash - Always Exists, Default values $SyncedHash.Enabled = $True
  
    .LINK
  #>
  [CmdletBinding(DefaultParameterSetName = "ByValue")]
  Param (
    [parameter(Mandatory = $False, ParameterSetName = "ByValue")]
    [Object[]]$InputObject
  )
  
  # Generate Error Message to show in Error Buffer
  $ErrorActionPreference = "Continue"
  GenerateErrorMessage
  $ErrorActionPreference = "Stop"
  
  # Enable Verbose logging
  $VerbosePreference = "Continue"
  
  # Check is Thread is Enabled to Run
  if ($SyncedHash.Enabled)
  {
    # Call Imported Test Function
    Test-Function -Value $InputObject
    
    # Check if a Mutex exist
    if ([String]::IsNullOrEmpty($Mutex))
    {
      $HasMutex = $False
    }
    else
    {
      # Open and wait for Mutex
      $MyMutex = [System.Threading.Mutex]::OpenExisting($Mutex)
      [Void]($MyMutex.WaitOne())
      $HasMutex = $True
    }
    
    # Write Data to the Screen
    For ($Count = 0; $Count -le 8; $Count++)
    {
      Write-Host -Object "`$InputObject = $InputObject"
    }
    
    # Release the Mutex if it Exists
    if ($HasMutex)
    {
      $MyMutex.ReleaseMutex()
    }
  }
  else
  {
    "Return Value: RSJob was Canceled"
  }
}
#endregion

#region $WaitScript
$WaitScript = {
  Write-Host -Object "Completed $(@(Get-MyRSJob | Where-Object -FilterScript { $PSItem.State -eq 'Completed' }).Count) Jobs"
  Start-Sleep -Milliseconds 1000
}
#endregion

$TestFunction = @{}
$TestFunction.Add("Test-Function", (Get-Command -Type Function -Name Test-Function).ScriptBlock)

# Start and Get RSPool
$RSPool = Start-MyRSPool -MaxJobs 8 -Functions $TestFunction -PassThru #-Mutex "TestMutex"

# Create new RunspacePool and start 5 Jobs
1..10 | Start-MyRSJob -ScriptBlock $ScriptBlock -PassThru | Out-String

# Add 5 new Jobs to an existing RunspacePool
11..20 | Start-MyRSJob -ScriptBlock $ScriptBlock -PassThru | Out-String

# Disable Thread Script
#$RSPool.SyncedHash.Enabled = $False

# Wait for all Jobs to Complete or Fail
Get-MyRSJob | Wait-MyRSJob -SciptBlock $WaitScript -PassThru | Out-String

# Receive Completed Jobs and Remove them
Get-MyRSJob | Receive-MyRSJob -AutoRemove

# Close RunspacePool
Close-MyRSPool


#endregion

