
#region function Start-MyRSJob
function Start-MyRSJob()
{
  <#
    .SYNOPSIS
      Creates or Updates a RunspacePool
    .DESCRIPTION
      Function to do something specific
    .PARAMETER RSPool
      RunspacePool to add new RunspacePool Jobs to
    .PARAMETER PoolName
      Name of RunspacePool
    .PARAMETER PoolID
      ID of RunspacePool
    .PARAMETER InputObject
      Object / Value to pass to the RunspacePool Job ScriptBlock
    .PARAMETER InputParam
      Paramter to pass the Object / Value as
    .PARAMETER JobName
      Name of RunspacePool Jobs
    .PARAMETER ScriptBlock
      RunspacePool Job ScriptBock to Execute
    .PARAMETER Parameters
      Common Paramaters to pass to the RunspacePool Job ScriptBlock
    .PARAMETER PassThru
      Return the New Jobs to the Pipeline
    .EXAMPLE
      Start-MyRSJob -ScriptBlock $ScriptBlock -JobName $JobName -InputObject $InputObject

      Add new RSJobs to the Default RSPool
    .EXAMPLE
      $InputObject | Start-MyRSJob -ScriptBlock $ScriptBlock -RSPool $RSPool -JobName $JobName
  
      $InputObject | Start-MyRSJob -ScriptBlock $ScriptBlock -PoolName $PoolName -JobName $JobName
  
      $InputObject | Start-MyRSJob -ScriptBlock $ScriptBlock -PoolID $PoolID -JobName $JobName

      Add new RSJobs to the Specified RSPool
    .NOTES
      Original Script By Ken Sweet on 10/15/2017
      Updated Script By Ken Sweet on 02/04/2019
    .LINK
  #>
  [CmdletBinding(DefaultParameterSetName = "PoolName")]
  param (
    [parameter(Mandatory = $True, ParameterSetName = "RSPool")]
    [MyRSPool]$RSPool,
    [parameter(Mandatory = $False, ParameterSetName = "PoolName")]
    [String]$PoolName = "MyDefaultRSPool",
    [parameter(Mandatory = $True, ParameterSetName = "PoolID")]
    [Guid]$PoolID,
    [parameter(Mandatory = $False, ValueFromPipeline = $True)]
    [Object[]]$InputObject,
    [String]$InputParam = "InputObject",
    [String]$JobName = "Job Name",
    [parameter(Mandatory = $True)]
    [ScriptBlock]$ScriptBlock,
    [Hashtable]$Parameters,
    [Switch]$PassThru
  )
  Begin
  {
    Write-Verbose -Message "Enter Function Start-MyRSJob Begin Block"
    
    Switch ($PSCmdlet.ParameterSetName)
    {
      "RSPool" {
        # Set Pool
        $TempPool = $RSPool
        Break;
      }
      "PoolName" {
        # Set Pool Name and Return Matching Pools
        $TempPool = [MyRSPool](Start-MyRSPool -PoolName $PoolName -PassThru)
        Break;
      }
      "PoolID" {
        # Set PoolID Return Matching Pools
        $TempPool = [MyRSPool](Get-MyRSPool -PoolID $PoolID)
        Break;
      }
    }
    
    # List for New Jobs
    #$NewJobs = [System.Collections.Generic.List[MyRSJob]]::New())
    $NewJobs = [System.Collections.Generic.List[MyRSJob]]::New()
    
    Write-Verbose -Message "Exit Function Start-MyRSJob Begin Block"
  }
  Process
  {
    Write-Verbose -Message "Enter Function Start-MyRSJob Process Block"
    
    if ($PSBoundParameters.ContainsKey("InputObject"))
    {
      ForEach ($Object in $InputObject)
      {
        # Create New PowerShell Instance with ScriptBlock
        $PowerShell = ([Management.Automation.PowerShell]::Create()).AddScript($ScriptBlock)
        # Set RunspacePool
        $PowerShell.RunspacePool = $TempPool.RunspacePool
        # Add Parameters
        [Void]$PowerShell.AddParameter($InputParam, $Object)
        if ($PSBoundParameters.ContainsKey("Parameters"))
        {
          [Void]$PowerShell.AddParameters($Parameters)
        }
        # set Job Name
        if (($Object -is [String]) -or ($Object -is [ValueType]))
        {
          $TempJobName = "$JobName - $($Object)"
        }
        else
        {
          $TempJobName = $($Object.$JobName)
        }
        [Void]$NewJobs.Add(([MyRSjob]::New($TempJobName, $PowerShell, $PowerShell.BeginInvoke(), $Object, $TempPool.Name, $TempPool.InstanceID)))
      }
    }
    else
    {
      # Create New PowerShell Instance with ScriptBlock
      $PowerShell = ([Management.Automation.PowerShell]::Create()).AddScript($ScriptBlock)
      # Set RunspacePool
      $PowerShell.RunspacePool = $TempPool.RunspacePool
      # Add Parameters
      if ($PSBoundParameters.ContainsKey("Parameters"))
      {
        [Void]$PowerShell.AddParameters($Parameters)
      }
      [Void]$NewJobs.Add(([MyRSjob]::New($JobName, $PowerShell, $PowerShell.BeginInvoke(), $Null, $TempPool.Name, $TempPool.InstanceID)))
    }
    
    Write-Verbose -Message "Exit Function Start-MyRSJob Process Block"
  }
  End
  {
    Write-Verbose -Message "Enter Function Start-MyRSJob End Block"
    
    if ($NewJobs.Count)
    {
      $TempPool.Jobs.AddRange($NewJobs)
      # Return Jobs only if New RunspacePool
      if ($PassThru.IsPresent)
      {
        $NewJobs
      }
      $NewJobs.Clear()
    }
    
    Write-Verbose -Message "Exit Function Start-MyRSJob End Block"
  }
}
#endregion
