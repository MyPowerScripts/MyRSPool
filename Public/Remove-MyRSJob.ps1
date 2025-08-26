
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
    $RemoveJobs = [System.Collections.Generic.List[MyRSJob]]::New()
    
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
