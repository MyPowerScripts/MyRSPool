
#region function Wait-MyRSJob
function Wait-MyRSJob()
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
    .PARAMETER ScriptBlock
      ScriptBlock to invoke while waiting

      For windows Forms scripts add the DoEvents method in to the Wait ScritpBlock

      [System.Windows.Forms.Application]::DoEvents()
      [System.Threading.Thread]::Sleep(250)
    .PARAMETER Wait
      TimeSpace to wait
    .PARAMETER NoWait
      No Wait, Return when any Job states changes to Stopped, Completed, or Failed
    .EXAMPLE
      $MyRSJobs = Wait-MyRSJob -RSPool $MyRSPool
    .EXAMPLE
      $MyRSJobs = Wait-MyRSJob -RSPool $MyRSPool -Name $JobName -State "Running"
    .EXAMPLE
      $MyRSJobs = Wait-MyRSJob -RSPool $MyRSPool -InstanceId $InstanceId
    .EXAMPLE
      $MyRSJobs = Wait-MyRSJob -RSPool $MyRSPool $RSJob $MyRSJobs
    .EXAMPLE
      $MyRSJobs = Wait-MyRSJob -RSPool $MyRSPool -RSJob $MyRSJobs
    .EXAMPLE
      $MyRSJobs = $MyRSJobs | Wait-MyRSJob -RSPool $MyRSPool
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
    [ScriptBlock]$SciptBlock = { [System.Windows.Forms.Application]::DoEvents() },
    [ValidateRange("0:00:00", "8:00:00")]
    [TimeSpan]$Wait = "0:05:00",
    [Switch]$NoWait
  )
  Begin
  {
    Write-Verbose -Message "Enter Function Wait-MyRSJob Begin Block"
    
    # Remove Invalid Get-MyRSJob Parameters
    if ($PSCmdlet.ParameterSetName -ne "Job")
    {
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
    # Create new ArrayList to Move Wait Code to End block
    $Jobs = New-Object -TypeName System.Collections.ArrayList
    
    Write-Verbose -Message "Exit Function Wait-MyRSJob Begin Block"
  }
  Process
  {
    Write-Verbose -Message "Enter Function Wait-MyRSJob Process Block"
    
    # Add Passed RSJobs to $Jobs
    if ($PSCmdlet.ParameterSetName -eq "Job")
    {
      $Jobs.AddRange(@($RSJob))
    }
    else
    {
      $Jobs.AddRange(@(Get-MyRSJob @PSBoundParameters))
    }

    Write-Verbose -Message "Exit Function Wait-MyRSJob Process Block"
  }
  End
  {
    Write-Verbose -Message "Enter Function Wait-MyRSJob End Block"
    
    # Wait for Jobs to be Finshed
    if ($NoWait.IsPresent)
    {
      While (@(($Jobs | Where-Object -FilterScript { $PSItem.State -notmatch "Stopped|Completed|Failed" })).Count -eq $Jobs.Count)
      {
        $SciptBlock.Invoke()
      }
    }
    else
    {
      $WaitJobs = $Jobs.Clone()
      $Start = [DateTime]::Now
      While (@(($WaitJobs = $WaitJobs | Where-Object -FilterScript { $PSItem.State -notmatch "Stopped|Completed|Failed" })).Count -and ((([DateTime]::Now - $Start) -le $Wait) -or ($Wait.Ticks -eq 0)))
      {
        $SciptBlock.Invoke()
      }
    }
    
    # Return Completed Jobs
    @($Jobs | Where-Object -FilterScript { $PSItem.State -match "Stopped|Completed|Failed" })
    
    Write-Verbose -Message "Exit Function Wait-MyRSJob End Block"
  }
}
#endregion






