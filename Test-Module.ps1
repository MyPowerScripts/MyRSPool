﻿<#
  .SYNOPSIS
    Test Script for MyRSPool Module
  .DESCRIPTION
    Test Script for MyRSPool Module
  .EXAMPLE
    Test-Module.ps1
  .NOTES
    Original Script By Ken Sweet on 10/15/2017 at 06:53 AM
  .LINK
#>

$VerbosePreference = "Continue"

#Explicitly import the module for testing
Import-Module -Name "$PWD\MyRSPool.psm1" | Out-Null

$VerbosePreference = "SilentlyContinue"

#region function Test-Function
$TestFunction = @{
  "Test-Function" = {
  <#
    .SYNOPSIS
      Test Function for RunspacePool ScriptBlock
    .DESCRIPTION
      Test Function for RunspacePool ScriptBlock
    .PARAMETER Value
      Value Command Line Parameter
    .EXAMPLE
      Test-Function -Value "String"
    .NOTES
      Original Function By Ken Sweet
    .LINK
  #>
    [CmdletBinding(DefaultParameterSetName = "ByValue")]
    param (
      [parameter(Mandatory = $False, HelpMessage = "Enter Value", ParameterSetName = "ByValue")]
      [Object[]]$Value = "Default Value"
    )
    Write-Verbose -Message "Enter Function Test-Function"
    Try
    {
      ForEach ($Item in $Value)
      {
        [System.Threading.Thread]::Sleep(5000 * (($Item % 3) + 1))
        "`$Item = $Item"
      }
    }
    Catch
    {
      Write-Debug -Message "ErrMsg: $($Error[0].Exception.Message)"
      Write-Debug -Message "Line: $($Error[0].InvocationInfo.ScriptLineNumber)"
      Write-Debug -Message "Code: $(($Error[0].InvocationInfo.Line).Trim())"
    }
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    Write-Verbose -Message "Exit Function Test-Function"
  }
}
#endregion

#region Job $ScriptBlock
$ScriptBlock = {
  <#
    .SYNOPSIS
      Test RunspacePool ScriptBlock
    .DESCRIPTION
      Test RunspacePool ScriptBlock
    .PARAMETER InputObject
      InputObject passed to script
    .EXAMPLE
      Test-Script.ps1 -InputObject $InputObject
    .NOTES
      Original Script By Ken Sweet on 10/15/2017 at 06:53 AM
    .LINK
  #>
  [CmdletBinding(DefaultParameterSetName = "ByValue")]
  Param (
    [parameter(Mandatory = $False, ParameterSetName = "ByValue")]
    [Object[]]$inputObject
  )
  
  Test-Function -Value $inputObject
}
#endregion

#region $WaitScript
$WaitScript = {
  Write-Host -Object "Completed $(@($MyRSPool.Jobs | Where-Object -FilterScript {$PSItem.State -eq 'Completed'}).Count) Jobs"
  [System.Threading.Thread]::Sleep(2000)
}
#endregion

# Create new RunspacePool and start 5 Jobs
$MyRSPool = 1..5 | Start-MyRSJob -ScriptBlock $ScriptBlock -Functions $TestFunction -MaxJobs 4
$MyRSPool.Jobs | Out-String

# Add 5 new Jobs to an existing RunspacePool
6..10 | Start-MyRSJob -RSPool $MyRSPool -ScriptBlock $ScriptBlock
$MyRSPool.Jobs | Out-String

# Wait for all Jobs to Complete or Fail
$MyRSjobs = $MyRSPool.Jobs | Wait-MyRSJob -RSPool $MyRSPool -SciptBlock $WaitScript
$MyRSPool.Jobs | Out-String

# Receive Completed Jobs and Remove them
$MyRSjobs | Receive-MyRSJob -RSPool $MyRSPool -AutoRemove
# Close RunspacePool
Close-MyRSPool -RSPool $MyRSPool

$Host.EnterNestedPrompt()

