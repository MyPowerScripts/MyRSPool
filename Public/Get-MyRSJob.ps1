
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
