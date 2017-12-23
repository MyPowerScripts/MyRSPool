
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







