
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
    .PARAMETER PoolName
      Name of Pool to Get Jobs From
    .PARAMETER PoolID
      ID of Pool to Get Jobs From
    .PARAMETER JobName
      Name of Jobs to Get
    .PARAMETER JobID
      ID of Jobs to Get
    .PARAMETER RSJob
      Jobs to Process
    .PARAMETER AutoRemove
      Remove Jobs after Receiving Output
    .EXAMPLE
      $MyResults = Receive-MyRSJob -AutoRemove
  
      Receive Results from RSJobs in the Default RSPool
    .EXAMPLE
      $MyResults = Receive-MyRSJob -RSPool $RSPool -AutoRemove
  
      $MyResults = Receive-MyRSJob -PoolName $PoolName -AutoRemove
  
      $MyResults = Receive-MyRSJob -PoolID $PoolID -AutoRemove
  
      Receive Results from RSJobs in the Specified RSPool
    .NOTES
      Original Script By Ken Sweet on 10/15/2017
      Updated Script By Ken Sweet on 02/04/2019
    .LINK
  #>
  [CmdletBinding(DefaultParameterSetName = "JobNamePoolName")]
  param (
    [parameter(Mandatory = $True, ParameterSetName = "JobIDPool")]
    [parameter(Mandatory = $True, ParameterSetName = "JobNamePool")]
    [MyRSPool]$RSPool,
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
    [parameter(Mandatory = $True, ValueFromPipeline = $True, ParameterSetName = "RSJob")]
    [MyRSJob[]]$RSJob,
    [Switch]$AutoRemove,
    [Switch]$Force
  )
  Begin
  {
    Write-Verbose -Message "Enter Function Receive-MyRSJob Begin Block"
    
    # Remove Invalid Get-MyRSJob Parameters
    if ($PSCmdlet.ParameterSetName -ne "RSJob")
    {
      if ($PSBoundParameters.ContainsKey("AutoRemove"))
      {
        [Void]$PSBoundParameters.Remove("AutoRemove")
      }
    }
    
    # List for Remove Jobs
    #$RemoveJobs = [System.Collections.Generic.List[MyRSJob]]::New())
    $RemoveJobs = New-Object -TypeName "System.Collections.Generic.List[MyRSJob]"
    
    Write-Verbose -Message "Exit Function Receive-MyRSJob Begin Block"
  }
  Process
  {
    Write-Verbose -Message "Enter Function Receive-MyRSJob Process Block"
    
    # Add Passed RSJobs to $Jobs
    if ($PSCmdlet.ParameterSetName -eq "RSJob")
    {
      $TempJobs = $RSJob
    }
    else
    {
      [Void]$PSBoundParameters.Add("State", "Completed")
      $TempJobs = @(Get-MyRSJob @PSBoundParameters)
    }
    
    # Receive all Complted Jobs, Remove Job if Required
    ForEach ($TempJob in $TempJobs)
    {
      if ($TempJob.IsCompleted)
      {
        Try
        {
          $TempJob.PowerShell.EndInvoke($TempJob.PowerShellAsyncResult)
          # Add Job to Remove List
          [Void]$RemoveJobs.Add($TempJob)
        }
        Catch
        {
        }
      }
    }
    
    Write-Verbose -Message "Exit Function Receive-MyRSJob Process Block"
  }
  End
  {
    Write-Verbose -Message "Enter Function Receive-MyRSJob End Block"
    
    if ($AutoRemove.IsPresent)
    {
      # Remove RSJobs
      foreach ($RemoveJob in $RemoveJobs)
      {
        $RemoveJob.PowerShell.Dispose()
        [Void]$Script:MyHiddenRSPool[$RemoveJob.PoolName].Jobs.Remove($RemoveJob)
      }
      $RemoveJobs.Clear()
    }
    
    # Garbage Collect, Recover Resources
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    Write-Verbose -Message "Exit Function Receive-MyRSJob End Block"
  }
}
#endregion







