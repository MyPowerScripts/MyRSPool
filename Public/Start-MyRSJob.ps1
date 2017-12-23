
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
    [parameter(Mandatory = $False, ParameterSetName = "New")]
    [HashTable]$Parameters,
    [parameter(Mandatory = $False, ParameterSetName = "New")]
    [HashTable]$Functions,
    [parameter(Mandatory = $False, ParameterSetName = "New")]
    [HashTable]$Variables,
    [parameter(Mandatory = $False, ParameterSetName = "New")]
    [String[]]$Modules,
    [parameter(Mandatory = $False, ParameterSetName = "New")]
    [String[]]$PSSnapins,
    [parameter(Mandatory = $False, ParameterSetName = "New")]
    [ValidateRange(1, 16)]
    [Int]$MaxJobs = 8
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
          $InitialSessionState.Variables.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList $Key, $Variables[$Key], "$Key = $($Variables[$Key])"))
        }
      }
      
      # Create and Open RunSpacePool
      #$Return = [MyRSPool]::New($PoolName, ([Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $MaxJobs, $InitialSessionState, $Host)))
      $Return = New-Object -TypeName "MyRSPool" -ArgumentList $PoolName, ([Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $MaxJobs, $InitialSessionState, $Host))
      $Return.RunspacePool.ApartmentState = "STA"
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







