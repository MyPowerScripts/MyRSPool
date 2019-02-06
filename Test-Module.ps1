<#
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

Get-Command -Module MyRSPool

$VerbosePreference = "SilentlyContinue"

#region function Test-Function
Function Test-Function
{
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
  [CmdletBinding(DefaultParameterSetName = "Default")]
  param (
    [parameter(Mandatory = $False, HelpMessage = "Enter Value", ParameterSetName = "Default")]
    [Object[]]$Value = "Default Value"
  )
  Write-Verbose -Message "Enter Function Test-Function"
  
  Start-Sleep -Milliseconds (1000 * 5)
  ForEach ($Item in $Value)
  {
    "Return Value: `$Item = $Item"
  }
  
  Write-Verbose -Message "Exit Function Test-Function"
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
      Original Script By Ken Sweet on 10/15/2017
      Updated Script By Ken Sweet on 02/04/2019
  
      Thread Script Variables
        [String]$Mutex - Exist only if -Mutex was specified on the Start-MyRSPool command line
        [HashTable]$SyncedHash - Always Exists, Default values $SyncedHash.Enabled = $True
  
    .LINK
  #>
  [CmdletBinding(DefaultParameterSetName = "ByValue")]
  Param (
    [parameter(Mandatory = $False, ParameterSetName = "ByValue")]
    [Object[]]$InputObject
  )
  
  # Generate Error Message to show in Error Buffer
  $ErrorActionPreference = "Continue"
  GenerateErrorMessage
  $ErrorActionPreference = "Stop"
  
  # Enable Verbose logging
  $VerbosePreference = "Continue"
  
  # Check is Thread is Enabled to Run
  if ($SyncedHash.Enabled)
  {
    # Call Imported Test Function
    Test-Function -Value $InputObject
    
    # Check if a Mutex exist
    if ([String]::IsNullOrEmpty($Mutex))
    {
      $HasMutex = $False
    }
    else
    {
      # Open and wait for Mutex
      $MyMutex = [System.Threading.Mutex]::OpenExisting($Mutex)
      [Void]($MyMutex.WaitOne())
      $HasMutex = $True
    }
    
    # Write Data to the Screen
    For ($Count = 0; $Count -le 8; $Count++)
    {
      Write-Host -Object "`$InputObject = $InputObject"
    }
    
    # Release the Mutex if it Exists
    if ($HasMutex)
    {
      $MyMutex.ReleaseMutex()
    }
  }
  else
  {
    "Return Value: RSJob was Canceled"
  }
}
#endregion

#region $WaitScript
$WaitScript = {
  Write-Host -Object "Completed $(@(Get-MyRSJob | Where-Object -FilterScript { $PSItem.State -eq 'Completed' }).Count) Jobs"
  Start-Sleep -Milliseconds 1000
}
#endregion

$TestFunction = @{}
$TestFunction.Add("Test-Function", (Get-Command -Type Function -Name Test-Function).ScriptBlock)

# Start and Get RSPool
$RSPool = Start-MyRSPool -MaxJobs 8 -Functions $TestFunction -PassThru #-Mutex "TestMutex"

# Create new RunspacePool and start 5 Jobs
1..10 | Start-MyRSJob -ScriptBlock $ScriptBlock -PassThru | Out-String

# Add 5 new Jobs to an existing RunspacePool
11..20 | Start-MyRSJob -ScriptBlock $ScriptBlock -PassThru | Out-String

# Disable Thread Script
#$RSPool.SyncedHash.Enabled = $False

# Wait for all Jobs to Complete or Fail
Get-MyRSJob | Wait-MyRSJob -SciptBlock $WaitScript -PassThru | Out-String

# Receive Completed Jobs and Remove them
Get-MyRSJob | Receive-MyRSJob -AutoRemove

# Close RunspacePool
Close-MyRSPool

$Host.EnterNestedPrompt()


