
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
