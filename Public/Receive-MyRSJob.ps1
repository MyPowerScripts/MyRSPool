
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







