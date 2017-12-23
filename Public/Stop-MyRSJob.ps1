
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






