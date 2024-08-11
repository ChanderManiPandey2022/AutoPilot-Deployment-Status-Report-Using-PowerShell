Cls
<#Report_Name﻿ < AutoPilot Deployment Status Report / >
#DESCRIPTION  < This is generating a AutoPilot Deployment report from the last 30 days Using PowerShell />
 #INPUTS      < User Imput Section />
#NOTES
  Version:         1.0
  Author:          Chander Mani Pandey
  Creation Date:   10 Aug 2024
  Find Author on 
  Youtube:-        https://www.youtube.com/@chandermanipandey8763
  Twitter:-        https://twitter.com/Mani_CMPandey
  LinkedIn:-       https://www.linkedin.com/in/chandermanipandey
  
 #>

# ======================================= User Input ================================================================================

$WorkingFolder = "C:\TEMP\Autopilot_Deployment_Report"

# ===================================================================================================================================

$StartDate = Get-Date
Set-ExecutionPolicy -ExecutionPolicy Bypass 

# Function to check, install, and import a module
function Ensure-Module {
    param (
        [string]$ModuleName
    )

    $module = Get-Module -Name $ModuleName -ListAvailable
    Write-Host "Checking if '$ModuleName' is installed" -ForegroundColor Yellow

    if ($module -eq $null) {
        Write-Host "'$ModuleName' is not installed" -ForegroundColor Red
        Write-Host "Installing '$ModuleName'" -ForegroundColor Yellow
        Install-Module $ModuleName -Force
        Write-Host "'$ModuleName' has been installed successfully" -ForegroundColor Green
    }
    else {
        Write-Host "'$ModuleName' is already installed" -ForegroundColor Green
    }
    
    Write-Host "Importing '$ModuleName' module" -ForegroundColor Yellow
    Import-Module $ModuleName -Force
    Write-Host "'$ModuleName' module imported successfully" -ForegroundColor Green
}

# Ensure Microsoft.Graph.DeviceManagement.Enrollment is installed and imported
Ensure-Module -ModuleName "Microsoft.Graph.Beta.DeviceManagement.Enrollment"
Ensure-Module -ModuleName "Microsoft.Graph.Beta.DeviceManagement"

# Connect to Microsoft Graph
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
Connect-MgGraph 
Write-Host "Connected to Microsoft Graph successfully" -ForegroundColor Green

$date = Get-Date
$deploymentEndDateTimes = (Get-Date $date).AddDays($ReportDuration)

# =====================================AutoPilot Event Report==========================================================================
Write-Host "Fetching AutoPilot Event Report..." -ForegroundColor Yellow

$autopilotDevices = Get-MgBetaDeviceManagementAutopilotEvent 
$IntuneHardwareInfo = Get-MgBetaDeviceManagementManagedDevice | where {$_.OperatingSystem -eq 'Windows'} | Select-Object -Property Id, DeviceName, userId, userDisplayName, emailAddress, serialNumber
# | where {$_.enrollmentStartDateTime -gt $deploymentEndDateTimes }
Write-Host "Checking AutoPilot Deployment Report against: $($autopilotDevices.Count) Devices"
Write-Host "Fetching Device details..." -ForegroundColor Yellow

$Date = Get-Date -Format "MMMMMMMM dd, yyyy";

# Ensure the working directory exists
if (-not (Test-Path -Path $WorkingFolder)) {
    Write-Host "Directory $WorkingFolder does not exist. Creating now..." -ForegroundColor Yellow
    New-Item -Path $WorkingFolder -ItemType Directory -Force
    Write-Host "Directory $WorkingFolder created successfully." -ForegroundColor Green
}

$devices = @()

# Initialize counters
$totalCount = 0
$successCount = 0
$failedCount = 0
$progressCount = 0

# Loop through devices and update progress
for ($i = 0; $i -lt $autopilotDevices.Count; $i++) {
    $autopilotDevice = $autopilotDevices[$i]

    # =================AutopilotDevice Information========================================================================================================================================

    $APdeviceId = $autopilotDevice.id
    $deviceName = $autopilotDevice.ManagedDeviceName
    $SerialNumber = $autopilotDevice.deviceSerialNumber
    $OSversion = $autopilotDevice.osVersion
    $UserName = $autopilotDevice.userPrincipalName
    $windowsAutopilotDeploymentProfileDisplayName = $autopilotDevice.windowsAutopilotDeploymentProfileDisplayName
    $deploymentState = $autopilotDevice.deploymentState
    $deploymentStartDateTime = $autopilotDevice.deploymentStartDateTime
    $deploymentEndDateTime = $autopilotDevice.deploymentEndDateTime
    $DeploymentDuration = New-TimeSpan –Start $deploymentStartDateTime –End $deploymentEndDateTime 

    # Converting time in HH:MM:SS format
    [string]$Duration = ""
    $Duration  =  $DeploymentDuration.Hours
    $Duration  += ' Hr '
    $Duration  +=  $DeploymentDuration.Minutes
    $Duration  += ' Mins '
    $Duration  += $DeploymentDuration.Seconds
    $Duration  += ' Secs '

    $DevicePreparationDuration1 = $autopilotDevice.DevicePreparationDuration
    [String]$Inputstring = $DevicePreparationDuration1
    $DevicePreparationDuration = $Inputstring.replace("PT","") -replace "M"," Min " -replace "S"," Sec"

    $DeviceSetupDuration1  = $autopilotDevice.DeviceSetupDuration 
    [String]$Inputstring = $DeviceSetupDuration1
    $DeviceSetupDuration = $Inputstring.replace("PT","") -replace "M"," Min " -replace "S"," Sec"

    $TargetedAppCount = $autopilotDevice.TargetedAppCount
    $EnrollmentFailureDetails = $autopilotDevice.EnrollmentFailureDetails 
  
    $eventDateTime = $autopilotDevice.eventDateTime
    $deploymentDuration = $autopilotDevice.deploymentDuration
    $ESPName = $autopilotDevice.windows10EnrollmentCompletionPageConfigurationDisplayName
    $enrollmentType = $autopilotDevice.enrollmentType
    $deviceRegisteredDateTime = $autopilotDevice.deviceRegisteredDateTime

    $IntuneHW_Dump =  $IntuneHardwareInfo | Where-Object { $_.serialNumber -eq $SerialNumber  }
    
    if ($IntuneHW_Dump) {
        $IntuneHW_deviceName = $IntuneHW_Dump.DeviceName
        $IntuneHW_userName = $IntuneHW_Dump.userDisplayName
        $IntuneHW_UserEmailID = $IntuneHW_Dump.emailAddress
    } else {
        Write-Host "No matching Intune Hardware Info found for Device ID: $APdeviceId and Serial Number: $SerialNumber" -ForegroundColor Red
        $IntuneHW_deviceName = "N/A"
        $IntuneHW_userName = "N/A"
        $IntuneHW_UserEmailID = "N/A"
    }

    # ==================================================In-Console Status===============================================================================================================================

    Write-Host "`n"
    Write-Host "Autopilot Deployment Status:" -ForegroundColor Green
    Write-Host "Autopilot Device Name: $IntuneHW_deviceName"
    Write-Host "Autopilot Status is: $deploymentState"
    Write-Host "Autopilot User Name: $IntuneHW_userName"
    Write-Host "User Email ID: $IntuneHW_UserEmailID"
    Write-Host "Device Serial Number: $SerialNumber"
    Write-Host "Deployment Start Date Time: $deploymentStartDateTime"
    Write-Host "Deployment End Date Time: $deploymentEndDateTime"
    Write-Host "Deployment Duration (hh:mm:ss): $Duration"
    Write-Host "Autopilot Device Preparation Duration: $DevicePreparationDuration"
    Write-Host "Autopilot Device ESP Duration: $DeviceSetupDuration"
    Write-Host "Autopilot Deployment Profile Display Name: $windowsAutopilotDeploymentProfileDisplayName"
    Write-Host "Autopilot ESP Name: $ESPName"
    Write-Host "Autopilot Enrollment Type: $enrollmentType"
    Write-Host "Autopilot Targeted App Count: $TargetedAppCount"
    Write-Host "Autopilot Enrollment Failure Details (If Any): $EnrollmentFailureDetails"
    Write-Host "Autopilot Device Registered Date Time: $deviceRegisteredDateTime"
  
    Write-Host "================================================================================================="
    Write-Host "`n"

    # ======================================================Reporting=============================================================================================================================================

    $ReportProps = [ordered] @{ 
        DeviceName =  $IntuneHW_deviceName
        Status = $deploymentState
        UserName = $IntuneHW_userName
        UserEMailId = $IntuneHW_UserEmailID 
        Serial_Number = $SerialNumber 
        Deployment_StartDateTime = $deploymentStartDateTime 
        Deployment_EndDateTime = $deploymentEndDateTime 
        Deployment_Duration = $Duration
        Deployment_Profile_Display_Name = $windowsAutopilotDeploymentProfileDisplayName 
        ESP_Name = $ESPName
        Enrollment_Type = $enrollmentType
        Device_Registered_DateTime = $deviceRegisteredDateTime
        DevicePreparationDuration = $DevicePreparationDuration
        DeviceSetupDuration = $DeviceSetupDuration 
        TargetedAppCount = $TargetedAppCount 
        EnrollmentFailureDetails = $EnrollmentFailureDetails 
    }
    $ReportObject = New-Object -TypeName PSObject -Property $ReportProps
    Write-Host 'working.....'
    $devices += $ReportObject

    # Update counters
    $totalCount++
    if ($deploymentState -eq 'success') {
        $successCount++
    } elseif ($deploymentState -eq 'Failure') {
        $failedCount++
    } elseif ($deploymentState -eq 'progress') {
        $progressCount++
    }

    # Update progress
    $percentComplete = (($i + 1) / $autopilotDevices.Count) * 100
    #Write-Progress -PercentComplete $percentComplete -CurrentOperation "Processing device $($i + 1) of $($autopilotDevices.Count)" -Status "Processing Devices"
}

# Calculate percentage success
if ($totalCount -gt 0) {
    $successPercentage = ($successCount / $totalCount) * 100
} else {
    $successPercentage = 0
}

# =======================================================================Export Device Information==========================================================================================================

# Export report to CSV
Write-Host "Exporting report to CSV..." -ForegroundColor Yellow
$devices | Export-Csv -Path "$WorkingFolder\AutoPilotDeploymentReport.csv" -NoTypeInformation -Force
Write-Host "Report exported successfully to $WorkingFolder\AutoPilotDeploymentReport.csv" -ForegroundColor Green

# Display summary
Write-Host "`nSummary Report:" -ForegroundColor Green
Write-Host "Total Autopilot Device Count:                    $totalCount"  -ForegroundColor White
Write-Host "Total Successful Autopilot Device Count:         $successCount" -ForegroundColor Green
Write-Host "Total Failed Autopilot Device Count:             $failedCount"  -ForegroundColor Red
Write-Host "Total In Progress Autopilot Device Count:        $progressCount" -ForegroundColor Yellow
Write-Host "OverAll Autopilot Deployment Success Percentage: $([math]::Round($successPercentage, 2))%"  -ForegroundColor Green
 
# Disconnect from Microsoft Graph
Disconnect-MgGraph
