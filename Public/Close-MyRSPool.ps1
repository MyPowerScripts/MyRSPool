
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
    .EXAMPLE
      Close-MyRSPool -RSPool $MyRSPool
    .EXAMPLE
      $MyRSPool | Close-MyRSPool
    .NOTES
      Original Function By Ken Sweet
    .LINK
  #>
  [CmdletBinding()]
  param (
    [parameter(Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
    [MyRSPool[]]$RSPool
  )
  Process
  {
    Write-Verbose -Message "Enter Function Close-MyRSPool Process Block"
    
    # Close RunspacePools, This will Stop all Running Jobs
    ForEach ($Pool in $RSPool)
    {
      if (-not [String]::IsNullOrEmpty($Pool.Mutex))
      {
        $Pool.Mutex.Close()
        $Pool.Mutex.Dispose()
      }
      $Pool.RunspacePool.Close()
      $Pool.RunspacePool.Dispose()
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






