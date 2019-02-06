
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
    $Script:MyHiddenRSPool[$PoolName]
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
