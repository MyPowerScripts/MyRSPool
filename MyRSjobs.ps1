
$ErrorActionPreference = "Stop"

#region ********* MyRSPool / MyRSJob *********
$MyCustom = @"
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
Add-Type -TypeDefinition $MyCustom -Debug:$False
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
    .PARAMETER Functions
      Functions to include in the initial Session State
    .PARAMETER Variables
      Variables to include in the initial Session State
    .PARAMETER Modules
      Modules to load in the initial Session State
    .PARAMETER PSSnapins
      PSSnapins to load in the initial Session State
    .PARAMETER MaxJobs
      Maximum Number of Jobs
    .PARAMETER Hashtable
      Synced Hasttable to pass values between threads
    .PARAMETER Mutex
      Protects access to a shared resource
    .EXAMPLE
      $MyRSPool = Start-MyRSJob -ScriptBlock $ScriptBlock -PoolName $PoolName -JobName $JobName -MaxJobs $MaxJobs -InputObject $InputObject

      Create New RunspacePool and add new Jobs
    .EXAMPLE
      $MyRSPool = $InputObject | Start-MyRSJob -ScriptBlock $ScriptBlock -PoolName $PoolName -JobName $JobName -MaxJobs $MaxJobs

      Create New RunspacePool and add new Jobs
    .EXAMPLE
      Start-MyRSJob -RSPool $MyRSPool -ScriptBlock $ScriptBlock -JobName -InputObject $InputObject

      Update existing RunspacePool with new Jobs
    .EXAMPLE
      $InputObject | Start-MyRSJob -RSPool $MyRSPool -ScriptBlock $ScriptBlock -JobName

      Update existing RunspacePool with new Jobs
    .NOTES
      Original Function By Ken Sweet
    .LINK
  #>
  [CmdletBinding(DefaultParameterSetName = "New")]
  param (
    [parameter(Mandatory = $True, ParameterSetName = "Update")]
    [MyRSPool]$RSPool,
    [parameter(Mandatory = $False, ParameterSetName = "New")]
    [String]$PoolName = "RunspacePool",
    [parameter(Mandatory = $False, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
    [Object[]]$InputObject,
    [String]$InputParam = "InputObject",
    [String]$JobName = "Job Name",
    [parameter(Mandatory = $True)]
    [ScriptBlock]$ScriptBlock,
    [Hashtable]$Parameters,
    [parameter(Mandatory = $False, ParameterSetName = "New")]
    [Hashtable]$Functions,
    [parameter(Mandatory = $False, ParameterSetName = "New")]
    [Hashtable]$Variables,
    [parameter(Mandatory = $False, ParameterSetName = "New")]
    [String[]]$Modules,
    [parameter(Mandatory = $False, ParameterSetName = "New")]
    [String[]]$PSSnapins,
    [parameter(Mandatory = $False, ParameterSetName = "New")]
    [ValidateRange(1, 16)]
    [Int]$MaxJobs = 8,
    [parameter(Mandatory = $False, ParameterSetName = "New")]
    [Hashtable]$Hashtable = @{"Enabled" = $True},
    [parameter(Mandatory = $False, ParameterSetName = "New")]
    [String]$Mutex
  )
  Begin
  {
    Write-Verbose -Message "Enter Function Start-MyRSJob Begin Block"
    
    if ($PSCmdlet.ParameterSetName -eq "Update")
    {
      # Set Return if Updating Existing RSPool
      $Return = $RSPool
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
          #$InitialSessionState.Variables.Add(([System.Management.Automation.Runspaces.SessionStateVariableEntry]::New($Key, $Variables[$Key], "$Key = $($Variables[$Key])")))
          $InitialSessionState.Variables.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList $Key, $Variables[$Key], "$Key = $($Variables[$Key])", ([System.Management.Automation.ScopedItemOptions]::AllScope)))
        }
      }
      
      # Create and Open RunSpacePool
      $SyncedHash = [Hashtable]::Synchronized($Hashtable)
      #$InitialSessionState.Variables.Add(([System.Management.Automation.Runspaces.SessionStateVariableEntry]::New("Hashtable", $Hashtable, "Hashtable = Synced Hashtable")))
      $InitialSessionState.Variables.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList "SyncedHash", $SyncedHash, "SyncedHash = Synced Hashtable", ([System.Management.Automation.ScopedItemOptions]::AllScope)))
      if ($PSBoundParameters.ContainsKey("Mutex"))
      {
        #$InitialSessionState.Variables.Add(([System.Management.Automation.Runspaces.SessionStateVariableEntry]::New("Mutex", $Mutex, "Mutex = $Mutex")))
        $InitialSessionState.Variables.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList "Mutex", $Mutex, "Mutex = $Mutex", ([System.Management.Automation.ScopedItemOptions]::AllScope)))
        $CreateRunspacePool = [Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $MaxJobs, $InitialSessionState, $Host)
        #$Return = [MyRSPool]::New($PoolName, $CreateRunspacePool, $Hashtable, $Mutex)
        $Return = New-Object -TypeName "MyRSPool" -ArgumentList $PoolName, $CreateRunspacePool, $SyncedHash, $Mutex
      }
      else
      {
        #$Return = [MyRSPool]::New($PoolName, $CreateRunspacePool, $Hashtable)
        $CreateRunspacePool = [Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $MaxJobs, $InitialSessionState, $Host)
        $Return = New-Object -TypeName "MyRSPool" -ArgumentList $PoolName, $CreateRunspacePool, $SyncedHash
      }
      
      $Return.RunspacePool.ApartmentState = "STA"
      #$Return.RunspacePool.ApartmentState = "MTA"
      $Return.RunspacePool.CleanupInterval = [TimeSpan]::FromMinutes(2)
      $Return.RunspacePool.Open()
    }
    
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
        $PowerShell.RunspacePool = $Return.RunspacePool
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
        #[Void]$Return.Jobs.Add(([MyRSjob]::New($TempJobName, $PowerShell, $PowerShell.BeginInvoke(), $Object)))
        [Void]$Return.Jobs.Add((New-Object -TypeName "MyRSjob" -ArgumentList $TempJobName, $PowerShell, $PowerShell.BeginInvoke(), $Object))
      }
    }
    else
    {
      # Create New PowerShell Instance with ScriptBlock
      $PowerShell = ([Management.Automation.PowerShell]::Create()).AddScript($ScriptBlock)
      # Set RunspacePool
      $PowerShell.RunspacePool = $Return.RunspacePool
      # Add Parameters
      if ($PSBoundParameters.ContainsKey("Parameters"))
      {
        [Void]$PowerShell.AddParameters($Parameters)
      }
      #[Void]$Return.Jobs.Add(([MyRSjob]::New($JobName, $PowerShell, $PowerShell.BeginInvoke(), $Null)))
      [Void]$Return.Jobs.Add((New-Object -TypeName "MyRSjob" -ArgumentList $JobName, $PowerShell, $PowerShell.BeginInvoke(), $Null))
    }
    
    Write-Verbose -Message "Exit Function Start-MyRSJob Process Block"
  }
  End
  {
    Write-Verbose -Message "Enter Function Start-MyRSJob End Block"
    
    # Return Jobs only if New RunspacePool
    if ($PSCmdlet.ParameterSetName -eq "New")
    {
      $Return
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
    .PARAMETER Name
      Name of Job to search for
    .PARAMETER InstanceId
      InstanceId of Job to search for
    .PARAMETER State
      State of Jobs to search for
    .EXAMPLE
      $MyRSJobs = Get-MyRSJob -RSPool $MyRSPool -State "Complted"
    .EXAMPLE
      $MyRSJobs = Get-MyRSJob -RSPool $MyRSPool -Name $JobName
    .EXAMPLE
      $MyRSJobs = Get-MyRSJob -RSPool $MyRSPool -InstanceId $InstanceId
    .EXAMPLE
      $MyRSJobs = $InstanceId | Get-MyRSJob -RSPool $MyRSPool
    .EXAMPLE
      $MyRSJobs = Get-MyRSJob -RSPool $MyRSPool -Name $JobName -State "Complted"
    .EXAMPLE
      $MyRSJobs = Get-MyRSJob -RSPool $MyRSPool -InstanceId $InstanceId -State "Complted"
    .NOTES
      Original Function By Ken Sweet
    .LINK
  #>
  [CmdletBinding(DefaultParameterSetName = "All")]
  param (
    [parameter(Mandatory = $True)]
    [MyRSPool]$RSPool,
    [parameter(Mandatory = $True, ParameterSetName = "Name")]
    [String[]]$Name,
    [parameter(Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, ParameterSetName = "InstanceId")]
    [String[]]$InstanceId,
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
    
    Write-Verbose -Message "Exit Function Get-MyRSJob Begin Block"
  }
  Process
  {
    Write-Verbose -Message "Enter Function Get-MyRSJob Process Block"
    
    switch ($PSCmdlet.ParameterSetName)
    {
      "All" {
        # Return Matching Jobs
        @($RSPool.Jobs | Where-Object -FilterScript { $PSItem.State -match $StatePattern })
      }
      "Name" {
        # Set Job Name RegEx Pattern and Return Matching Jobs
        $NamePattern = $Name -join "|"
        @($RSPool.Jobs | Where-Object -FilterScript { $PSItem.State -match $StatePattern -and $PSItem.Name -match $NamePattern })
      }
      "InstanceID" {
        # Set Job InstanceId RegEx Pattern and Return Matching Jobs
        $InstanceIdPattern = $InstanceId -join "|"
        @($RSPool.Jobs | Where-Object -FilterScript { $PSItem.State -match $StatePattern -and $PSItem.InstanceId -match $InstanceIdPattern })
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
    .PARAMETER ScriptBlock
      ScriptBlock to invoke while waiting
      
      For windows Forms scripts add the DoEvents method in to the Wait ScritpBlock

      [System.Windows.Forms.Application]::DoEvents()
      [System.Threading.Thread]::Sleep(250)
    .PARAMETER Wait
      TimeSpace to wait
    .PARAMETER NoWait
      No Wait, Return when any Job states changes to Stopped, Completed, or Failed
    .EXAMPLE
      $MyRSJobs = Wait-MyRSJob -RSPool $MyRSPool
    .EXAMPLE
      $MyRSJobs = Wait-MyRSJob -RSPool $MyRSPool -Name $JobName -State "Running"
    .EXAMPLE
      $MyRSJobs = Wait-MyRSJob -RSPool $MyRSPool -InstanceId $InstanceId
    .EXAMPLE
      $MyRSJobs = Wait-MyRSJob -RSPool $MyRSPool $RSJob $MyRSJobs
    .EXAMPLE
      $MyRSJobs = Wait-MyRSJob -RSPool $MyRSPool -RSJob $MyRSJobs
    .EXAMPLE
      $MyRSJobs = $MyRSJobs | Wait-MyRSJob -RSPool $MyRSPool
    .NOTES
      Original Function By Ken Sweet
    .LINK
  #>
  [CmdletBinding(DefaultParameterSetName = "All")]
  param (
    [parameter(Mandatory = $True)]
    [MyRSPool]$RSPool,
    [parameter(Mandatory = $True, ParameterSetName = "Name")]
    [String[]]$Name,
    [parameter(Mandatory = $True, ParameterSetName = "InstanceId")]
    [String[]]$InstanceId,
    [parameter(Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, ParameterSetName = "Job")]
    [MyRSJob[]]$RSJob,
    [parameter(Mandatory = $False, ParameterSetName = "All")]
    [parameter(Mandatory = $False, ParameterSetName = "Name")]
    [parameter(Mandatory = $False, ParameterSetName = "InstanceId")]
    [ValidateSet("NotStarted", "Running", "Stopping", "Stopped", "Completed", "Failed", "Disconnected")]
    [String[]]$State,
    [ScriptBlock]$SciptBlock = { [System.Threading.Thread]::Sleep(250) },
    [ValidateRange("0:00:00", "8:00:00")]
    [TimeSpan]$Wait = "0:05:00",
    [Switch]$NoWait
  )
  Begin
  {
    Write-Verbose -Message "Enter Function Wait-MyRSJob Begin Block"
    
    # Remove Invalid Get-MyRSJob Parameters
    if ($PSCmdlet.ParameterSetName -ne "Job")
    {
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
    # Create new ArrayList to Move Wait Code to End block
    $Jobs = New-Object -TypeName System.Collections.ArrayList
    
    Write-Verbose -Message "Exit Function Wait-MyRSJob Begin Block"
  }
  Process
  {
    Write-Verbose -Message "Enter Function Wait-MyRSJob Process Block"
    
    # Add Passed RSJobs to $Jobs
    if ($PSCmdlet.ParameterSetName -eq "Job")
    {
      $Jobs.AddRange(@($RSJob))
    }
    else
    {
      $Jobs.AddRange(@(Get-MyRSJob @PSBoundParameters))
    }
    
    Write-Verbose -Message "Exit Function Wait-MyRSJob Process Block"
  }
  End
  {
    Write-Verbose -Message "Enter Function Wait-MyRSJob End Block"
    
    # Wait for Jobs to be Finshed
    if ($NoWait)
    {
      While (@(($Jobs | Where-Object -FilterScript { $PSItem.State -notmatch "Stopped|Completed|Failed" })).Count -eq $Jobs.Count)
      {
        $SciptBlock.Invoke()
      }
    }
    else
    {
      $WaitJobs = $Jobs.Clone()
      $Start = [DateTime]::Now
      While (@(($WaitJobs = $WaitJobs | Where-Object -FilterScript { $PSItem.State -notmatch "Stopped|Completed|Failed" })).Count -and (([DateTime]::Now - $Start) -le $Wait))
      {
        $SciptBlock.Invoke()
      }
    }
    
    # Return Completed Jobs
    @($Jobs | Where-Object -FilterScript { $PSItem.State -match "Stopped|Completed|Failed" })
    
    Write-Verbose -Message "Exit Function Wait-MyRSJob End Block"
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
    .PARAMETER Name
      Name of Job to search for
    .PARAMETER InstanceId
      InstanceId of Job to search for
    .PARAMETER RSJob
      RunspacePool Jobs to Process
    .PARAMETER AutoRemove
      Remove Jobs after Receiving Output
    .EXAMPLE
      $MyResults = Receive-MyRSJob -RSPool $MyRSPool
    .EXAMPLE
      $MyResults = Receive-MyRSJob -RSPool $MyRSPool -Name $JobName
    .EXAMPLE
      $MyResults = Receive-MyRSJob -RSPool $MyRSPool -InstanceId $InstanceId
    .EXAMPLE
      $MyResults = Receive-MyRSJob -RSPool $MyRSPool -RSJob $MyRSJobs
    .EXAMPLE
      $MyResults = $MyRSJobs | Receive-MyRSJob -RSPool $MyRSPool -AutoRemove
    .EXAMPLE
      $MyResults = $MyRSPool.Jobs.ToArray() | Receive-MyRSJob -RSPool $MyRSPool -AutoRemove
    .NOTES
      Original Function By Ken Sweet
    .LINK
  #>
  [CmdletBinding(DefaultParameterSetName = "All")]
  param (
    [parameter(Mandatory = $True)]
    [MyRSPool]$RSPool,
    [parameter(Mandatory = $True, ParameterSetName = "Name")]
    [String[]]$Name,
    [parameter(Mandatory = $True, ParameterSetName = "InstanceId")]
    [String[]]$InstanceId,
    [parameter(Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, ParameterSetName = "Job")]
    [MyRSJob[]]$RSJob,
    [Switch]$AutoRemove
  )
  Begin
  {
    Write-Verbose -Message "Enter Function Receive-MyRSJob Begin Block"
    
    # Remove Invalid Get-MyRSJob Parameters
    if ($PSCmdlet.ParameterSetName -ne "Job")
    {
      if ($PSBoundParameters.ContainsKey("AutoRemove"))
      {
        [Void]$PSBoundParameters.Remove("AutoRemove")
      }
    }
    
    Write-Verbose -Message "Exit Function Receive-MyRSJob Begin Block"
  }
  Process
  {
    Write-Verbose -Message "Enter Function Receive-MyRSJob Process Block"
    
    # Add Passed RSJobs to $Jobs
    if ($PSCmdlet.ParameterSetName -eq "Job")
    {
      $Jobs = $RSJob
    }
    else
    {
      [Void]$PSBoundParameters.Add("State", "Completed")
      $Jobs = @(Get-MyRSJob @PSBoundParameters)
    }
    
    # Receive all Complted Jobs, Remove Job if Required
    ForEach ($Job in $Jobs)
    {
      if ($Job.IsCompleted)
      {
        Try
        {
          $Job.PowerShell.EndInvoke($Job.PowerShellAsyncResult)
        }
        Catch
        {
        }
        if ($AutoRemove)
        {
          $Job.PowerShell.Dispose()
          [Void]$RSPool.Jobs.Remove($Job)
        }
      }
    }
    
    Write-Verbose -Message "Exit Function Receive-MyRSJob Process Block"
  }
  End
  {
    Write-Verbose -Message "Enter Function Receive-MyRSJob End Block"
    
    # Garbage Collect, Recover Resources
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    Write-Verbose -Message "Exit Function Receive-MyRSJob End Block"
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
      Stop-MyRSJob -RSPool $MyRSPool
    .EXAMPLE
      Stop-MyRSJob -RSPool $MyRSPool -Name $JobName
    .EXAMPLE
      Stop-MyRSJob -RSPool $MyRSPool -InstanceId $InstanceId
    .EXAMPLE
      Stop-MyRSJob -RSPool $MyRSPool -RSJob $MyRSJobs
    .EXAMPLE
      $MyRSJobs | Stop-MyRSJob -RSPool $MyRSPool -State "Running"
    .EXAMPLE
      $MyRSPool.Jobs.ToArray() | Stop-MyRSJob -RSPool $MyRSPool -State "Running"
    .NOTES
      Original Function By Ken Sweet
    .LINK
  #>
  [CmdletBinding(DefaultParameterSetName = "All")]
  param (
    [parameter(Mandatory = $True)]
    [MyRSPool]$RSPool,
    [parameter(Mandatory = $True, ParameterSetName = "Name")]
    [String[]]$Name,
    [parameter(Mandatory = $True, ParameterSetName = "InstanceId")]
    [String[]]$InstanceId,
    [parameter(Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, ParameterSetName = "Job")]
    [MyRSJob[]]$RSJob,
    [parameter(Mandatory = $False, ParameterSetName = "All")]
    [parameter(Mandatory = $False, ParameterSetName = "Name")]
    [parameter(Mandatory = $False, ParameterSetName = "InstanceId")]
    [ValidateSet("NotStarted", "Running", "Stopping", "Stopped", "Completed", "Failed", "Disconnected")]
    [String[]]$State
  )
  Process
  {
    Write-Verbose -Message "Enter Function Stop-MyRSJob Process Block"
    
    # Add Passed RSJobs to $Jobs
    if ($PSCmdlet.ParameterSetName -eq "Job")
    {
      $Jobs = $RSJob
    }
    else
    {
      $Jobs = @(Get-MyRSJob @PSBoundParameters)
    }
    
    # Stop all Jobs that have not Finished
    ForEach ($Job in $Jobs)
    {
      if ($Job.State -notmatch "Stopped|Completed|Failed")
      {
        $Job.PowerShell.Stop()
      }
    }
    
    Write-Verbose -Message "Exit Function Stop-MyRSJob Process Block"
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
      Remove-MyRSJob -RSPool $MyRSPool
    .EXAMPLE
      Remove-MyRSJob -RSPool $MyRSPool -Name $JobName
    .EXAMPLE
      Remove-MyRSJob -RSPool $MyRSPool -InstanceId $InstanceId -State "Failed"
    .EXAMPLE
      Remove-MyRSJob -RSPool $MyRSPool -RSJob $MyRSJobs -Force
    .EXAMPLE
      $MyRSJobs | Remove-MyRSJob -RSPool $MyRSPool -Force
    .EXAMPLE
      $MyRSPool.Jobs.ToArray() | Remove-MyRSJob -RSPool $MyRSPool -Force
    .NOTES
      Original Function By Ken Sweet
    .LINK
  #>
  [CmdletBinding(DefaultParameterSetName = "All")]
  param (
    [parameter(Mandatory = $True)]
    [MyRSPool]$RSPool,
    [parameter(Mandatory = $True, ParameterSetName = "Name")]
    [String[]]$Name,
    [parameter(Mandatory = $True, ParameterSetName = "InstanceId")]
    [String[]]$InstanceId,
    [parameter(Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, ParameterSetName = "Job")]
    [MyRSJob[]]$RSJob,
    [parameter(Mandatory = $False, ParameterSetName = "All")]
    [parameter(Mandatory = $False, ParameterSetName = "Name")]
    [parameter(Mandatory = $False, ParameterSetName = "InstanceId")]
    [ValidateSet("NotStarted", "Running", "Stopping", "Stopped", "Completed", "Failed", "Disconnected")]
    [String[]]$State,
    [Switch]$Force
  )
  Begin
  {
    Write-Verbose -Message "Enter Function Remove-MyRSJob Begin Block"
    
    # Remove Invalid Get-MyRSJob Parameters
    if ($PSCmdlet.ParameterSetName -ne "Job")
    {
      if ($PSBoundParameters.ContainsKey("Force"))
      {
        [Void]$PSBoundParameters.Remove("Force")
      }
    }
    
    Write-Verbose -Message "Exit Function Remove-MyRSJob Begin Block"
  }
  Process
  {
    Write-Verbose -Message "Enter Function Remove-MyRSJob Process Block"
    
    # Add Passed RSJobs to $Jobs
    if ($PSCmdlet.ParameterSetName -eq "Job")
    {
      $Jobs = $RSJob
    }
    else
    {
      $Jobs = @(Get-MyRSJob @PSBoundParameters)
    }
    
    # Remove all Jobs, Stop all Running if Forced
    ForEach ($Job in $Jobs)
    {
      if ($Force -and $Job.State -notmatch "Stopped|Completed|Failed")
      {
        $Job.PowerShell.Stop()
      }
      if ($Job.State -match "Stopped|Completed|Failed")
      {
        $Job.PowerShell.Dispose()
        [Void]$RSPool.Jobs.Remove($Job)
      }
    }
    
    Write-Verbose -Message "Exit Function Remove-MyRSJob Process Block"
  }
  End
  {
    Write-Verbose -Message "Enter Function Remove-MyRSJob End Block"
    
    # Garbage Collect, Recover Resources
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    Write-Verbose -Message "Exit Function Remove-MyRSJob End Block"
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
    .EXAMPLE
      Close-MyRSPool -RSPool $MyRSPool
    .EXAMPLE
      $MyRSPool | Close-MyRSPool
    .NOTES
      Original Function By Ken Sweet
    .LINK
  #>
  [CmdletBinding()]
  param (
    [parameter(Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
    [MyRSPool[]]$RSPool
  )
  Process
  {
    Write-Verbose -Message "Enter Function Close-MyRSPool Process Block"
    
    # Close RunspacePools, This will Stop all Running Jobs
    ForEach ($Pool in $RSPool)
    {
      $Pool.RunspacePool.Close()
      $Pool.RunspacePool.Dispose()
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


#region ******** Sample Code ********

#region function Test-Function
$TestFunction = @{"Test-Function" = {
  <#
    .SYNOPSIS
      Function to test something specific
    .DESCRIPTION
      Function to test something specific
    .PARAMETER Value
      Value Command Line Parameter
    .EXAMPLE
      Test-Function -Value "String"
    .NOTES
      Original Function By Ken Sweet
    .LINK
  #>
    [CmdletBinding(DefaultParameterSetName = "ByValue")]
    param (
      [parameter(Mandatory = $False, HelpMessage = "Enter Value", ParameterSetName = "ByValue")]
      [Object[]]$Value = "Default Value"
    )
    Write-Verbose -Message "Enter Function Test-Function"
    Try
    {
      ForEach ($Item in $Value)
      {
        [System.Threading.Thread]::Sleep(5000 * (($Item % 3) + 1))
        "`$Item = $Item"
      }
    }
    Catch
    {
      Write-Debug -Message "ErrMsg: $($Error[0].Exception.Message)"
      Write-Debug -Message "Line: $($Error[0].InvocationInfo.ScriptLineNumber)"
      Write-Debug -Message "Code: $(($Error[0].InvocationInfo.Line).Trim())"
    }
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    Write-Verbose -Message "Exit Function Test-Function"
  }
}
#endregion

#region Job $ScriptBlock
$ScriptBlock = {
  <#
    .SYNOPSIS
      Script to test something specific
    .DESCRIPTION
      Script to test something specific
    .PARAMETER InputObject
      InputObject passed to script
    .EXAMPLE
      Test-Script.ps1 -InputObject $InputObject
    .NOTES
      Original Script By Ken Sweet on 10/15/2017 at 06:53 AM
    .LINK
  #>
  [CmdletBinding(DefaultParameterSetName = "ByValue")]
  Param (
    [parameter(Mandatory = $False, ParameterSetName = "ByValue")]
    [Object[]]$inputObject
  )
  
  Test-Function -Value $inputObject
}
#endregion

#region $WaitScript
$WaitScript = {
  Write-Host -Object "Completed $(@($MyRSPool.Jobs | Where-Object -FilterScript { $PSItem.State -eq 'Completed' }).Count) Jobs"
  [System.Threading.Thread]::Sleep(2000)
}
#endregion

# Create new RunspacePool and start 5 Jobs
$MyRSPool = 1..5 | Start-MyRSJob -ScriptBlock $ScriptBlock -Functions $TestFunction -MaxJobs 4
$MyRSPool.Jobs | Out-String

# Add 5 new Jobs to an existing RunspacePool
6..10 | Start-MyRSJob -RSPool $MyRSPool -ScriptBlock $ScriptBlock
$MyRSPool.Jobs | Out-String

# Wait for all Jobs to Complete or Fail
$MyRSjobs = $MyRSPool.Jobs | Wait-MyRSJob -RSPool $MyRSPool -SciptBlock $WaitScript
$MyRSPool.Jobs | Out-String

# Receive Completed Jobs and Remove them
$MyRSjobs | Receive-MyRSJob -RSPool $MyRSPool -AutoRemove
# Close RunspacePool
Close-MyRSPool -RSPool $MyRSPool

#endregion

