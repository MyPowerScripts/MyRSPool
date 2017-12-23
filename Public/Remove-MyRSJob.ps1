
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







