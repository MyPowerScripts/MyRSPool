
#region function Close-MyRSPool
function Close-MyRSPool()
{
  <#
    .SYNOPSIS
      Close RunspacePool and Stop all Running Jobs
    .DESCRIPTION
      Close RunspacePool and Stop all Running Jobs
    .PARAMETER RSPool
      RunspacePool to clsoe
    .PARAMETER PoolName
      Name of RSPool to close
    .PARAMETER PoolID
      PoolID of Job to close
    .PARAMETER State
      State of Jobs to close
    .EXAMPLE
      Close-MyRSPool
  
      Close the Default RSPool
    .EXAMPLE
      Close-MyRSPool -PoolName $PoolName
  
      Close-MyRSPool -PoolID $PoolID
  
      Close Specified RSPools
    .NOTES
      Original Script By Ken Sweet on 10/15/2017
      Updated Script By Ken Sweet on 02/04/2019
    .LINK
  #>
  [CmdletBinding(DefaultParameterSetName = "All")]
  param (
    [parameter(Mandatory = $True, ValueFromPipeline = $True, ParameterSetName = "RSPool")]
    [MyRSPool[]]$RSPool,
    [parameter(Mandatory = $True, ParameterSetName = "PoolName")]
    [String[]]$PoolName = "MyDefaultRSPool",
    [parameter(Mandatory = $True, ParameterSetName = "PoolID")]
    [Guid[]]$PoolID,
    [parameter(Mandatory = $False, ParameterSetName = "All")]
    [parameter(Mandatory = $False, ParameterSetName = "PoolName")]
    [parameter(Mandatory = $False, ParameterSetName = "PoolID")]
    [ValidateSet("BeforeOpen", "Opening", "Opened", "Closed", "Closing", "Broken", "Disconnecting", "Disconnected", "Connecting")]
    [String[]]$State
  )
  Process
  {
    Write-Verbose -Message "Enter Function Close-MyRSPool Process Block"
    
    If ($PSCmdlet.ParameterSetName -eq "RSPool")
    {
      $TempPools = $RSPool
    }
    else
    {
      $TempPools = [MyRSPool[]](Get-MyRSPool @PSBoundParameters)
    }
    
    # Close RunspacePools, This will Stop all Running Jobs
    ForEach ($TempPool in $TempPools)
    {
      if (-not [String]::IsNullOrEmpty($TempPool.Mutex))
      {
        $TempPool.Mutex.Close()
        $TempPool.Mutex.Dispose()
      }
      $TempPool.RunspacePool.Close()
      $TempPool.RunspacePool.Dispose()
      [Void]$Script:MyHiddenRSPool.Remove($TempPool.Name)
    }
    
    Write-Verbose -Message "Exit Function Close-MyRSPool Process Block"
  }
  End
  {
    Write-Verbose -Message "Enter Function Close-MyRSPool End Block"
    
    # Garbage Collect, Recover Resources
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    Write-Verbose -Message "Exit Function Close-MyRSPool End Block"
  }
}
#endregion
