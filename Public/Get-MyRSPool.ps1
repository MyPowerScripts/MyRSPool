
#region function Get-MyRSPool
function Get-MyRSPool()
{
  <#
    .SYNOPSIS
      Get RunspacePools that match specified criteria
    .DESCRIPTION
      Get RunspacePools that match specified criteria
    .PARAMETER PoolName
      Name of RSPool to search for
    .PARAMETER PoolID
      PoolID of Job to search for
    .PARAMETER State
      State of Jobs to search for
    .EXAMPLE
      $MyRSPools = Get-MyRSPool
  
      Get all RSPools
    .EXAMPLE
      $MyRSPools = Get-MyRSPool -PoolName $PoolName
  
      $MyRSPools = Get-MyRSPool -PoolID $PoolID
  
      Get Specified RSPools
    .NOTES
      Original Script By Ken Sweet on 10/15/2017
      Updated Script By Ken Sweet on 02/04/2019
    .LINK
  #>
  [CmdletBinding(DefaultParameterSetName = "All")]
  param (
    [parameter(Mandatory = $True, ParameterSetName = "PoolName")]
    [String[]]$PoolName = "MyDefaultRSPool",
    [parameter(Mandatory = $True, ValueFromPipeline = $True, ParameterSetName = "PoolID")]
    [Guid[]]$PoolID,
    [parameter(Mandatory = $False, ParameterSetName = "All")]
    [parameter(Mandatory = $False, ParameterSetName = "PoolName")]
    [parameter(Mandatory = $False, ParameterSetName = "PoolID")]
    [ValidateSet("BeforeOpen", "Opening", "Opened", "Closed", "Closing", "Broken", "Disconnecting", "Disconnected", "Connecting")]
    [String[]]$State
  )
  Begin
  {
    Write-Verbose -Message "Enter Function Get-MyRSPool Begin Block"
    
    # Set Job State RegEx Pattern
    if ($PSBoundParameters.ContainsKey("State"))
    {
      $StatePattern = $State -join "|"
    }
    else
    {
      $StatePattern = ".*"
    }
    
    Write-Verbose -Message "Exit Function Get-MyRSPool Begin Block"
  }
  Process
  {
    Write-Verbose -Message "Enter Function Get-MyRSPool Process Block"
    
    switch ($PSCmdlet.ParameterSetName)
    {
      "All" {
        # Return Matching Pools
        @($Script:MyHiddenRSPool.Values | Where-Object -FilterScript { $PSItem.State -match $StatePattern })
        Break;
      }
      "PoolName" {
        # Set Pool Name and Return Matching Pools
        $NamePattern = $PoolName -join "|"
        @($Script:MyHiddenRSPool.Values | Where-Object -FilterScript { $PSItem.State -match $StatePattern -and $PSItem.Name -match $NamePattern })
        Break;
      }
      "PoolID" {
        # Set PoolID and Return Matching Pools
        $IDPattern = $PoolID -join "|"
        @($Script:MyHiddenRSPool.Values | Where-Object -FilterScript { $PSItem.State -match $StatePattern -and $PSItem.InstanceId -match $IDPattern })
        Break;
      }
    }
    
    Write-Verbose -Message "Exit Function Get-MyRSPool Process Block"
  }
}
#endregion







