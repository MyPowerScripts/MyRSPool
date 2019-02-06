
#region function Wait-MyRSJob
function Wait-MyRSJob()
{
  <#
    .SYNOPSIS
      Wait for RSJob to Finish
    .DESCRIPTION
      Wait for RSJob to Finish
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
    .PARAMETER ScriptBlock
      ScriptBlock to invoke while waiting

      For windows Forms scripts add the DoEvents method in to the Wait ScritpBlock

      [System.Windows.Forms.Application]::DoEvents()
      [System.Threading.Thread]::Sleep(250)
    .PARAMETER Wait
      TimeSpace to wait
    .PARAMETER NoWait
      No Wait, Return when any Job states changes to Stopped, Completed, or Failed
    .PARAMETER PassThru
      Return the New Jobs to the Pipeline
    .EXAMPLE
      $MyRSJobs = Wait-MyRSJob -PassThru
  
      Wait for and Get RSJobs from the Default RSPool
    .EXAMPLE
      $MyRSJobs = Wait-MyRSJob -RSPool $RSPool -PassThru
  
      $MyRSJobs = Wait-MyRSJob -PoolName $PoolName -PassThru
  
      $MyRSJobs = Wait-MyRSJob -PoolID $PoolID -PassThru
  
      Wait for and Get RSJobs from the Specified RSPool
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
    [String[]]$State,
    [ScriptBlock]$SciptBlock = { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 200 },
    [ValidateRange("0:00:00", "8:00:00")]
    [TimeSpan]$Wait = "0:05:00",
    [Switch]$NoWait,
    [Switch]$PassThru
  )
  Begin
  {
    Write-Verbose -Message "Enter Function Wait-MyRSJob Begin Block"
    
    # Remove Invalid Get-MyRSJob Parameters
    if ($PSCmdlet.ParameterSetName -ne "RSJob")
    {
      if ($PSBoundParameters.ContainsKey("PassThru"))
      {
        [Void]$PSBoundParameters.Remove("PassThru")
      }
      if ($PSBoundParameters.ContainsKey("Wait"))
      {
        [Void]$PSBoundParameters.Remove("Wait")
      }
      if ($PSBoundParameters.ContainsKey("NoWait"))
      {
        [Void]$PSBoundParameters.Remove("NoWait")
      }
      if ($PSBoundParameters.ContainsKey("ScriptBlock"))
      {
        [Void]$PSBoundParameters.Remove("ScriptBlock")
      }
    }
    
    # List for Wait Jobs
    #$WaitJobs = [System.Collections.Generic.List[MyRSJob]]::New())
    $WaitJobs = New-Object -TypeName "System.Collections.Generic.List[MyRSJob]"
    
    Write-Verbose -Message "Exit Function Wait-MyRSJob Begin Block"
  }
  Process
  {
    Write-Verbose -Message "Enter Function Wait-MyRSJob Process Block"
    
    # Add Passed RSJobs to $Jobs
    if ($PSCmdlet.ParameterSetName -eq "RSJob")
    {
      $WaitJobs.AddRange(@($RSJob))
    }
    else
    {
      $WaitJobs.AddRange(@(Get-MyRSJob @PSBoundParameters))
    }

    Write-Verbose -Message "Exit Function Wait-MyRSJob Process Block"
  }
  End
  {
    Write-Verbose -Message "Enter Function Wait-MyRSJob End Block"
    
    # Wait for Jobs to be Finshed
    if ($NoWait.IsPresent)
    {
      While (@(($WaitJobs | Where-Object -FilterScript { $PSItem.State -notmatch "Stopped|Completed|Failed" })).Count -eq $WaitJobs.Count)
      {
        $SciptBlock.Invoke()
      }
    }
    else
    {
      [Object[]]$CheckJobs = $WaitJobs.ToArray()
      $Start = [DateTime]::Now
      While (@(($CheckJobs = $CheckJobs | Where-Object -FilterScript { $PSItem.State -notmatch "Stopped|Completed|Failed" })).Count -and ((([DateTime]::Now - $Start) -le $Wait) -or ($Wait.Ticks -eq 0)))
      {
        $SciptBlock.Invoke()
      }
    }
    
    if ($PassThru.IsPresent)
    {
      # Return Completed Jobs
      $WaitJobs | Where-Object -FilterScript { $PSItem.State -match "Stopped|Completed|Failed" }
    }
    $WaitJobs.Clear()
    
    Write-Verbose -Message "Exit Function Wait-MyRSJob End Block"
  }
}
#endregion






