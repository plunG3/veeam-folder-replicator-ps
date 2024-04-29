# Simple script to replicate a source folder into a replica folder
# Expects "Source", "Replica" and "LogPath" paths to be specified via cmdline params
# Includes simple logging

# Written by Calvin Glass
# 2024-04-28

# command line params
param(
  [string] $Source,
  [string] $Replica,
  [string] $LogPath
)

# Generic logging function for terminal and log file
function Logging {
    param (
    [string] $Level,
    [string] $Message,
    [string] $LogPath
    )
    # Output to terminal
    Write-Host "$LEVEL`t$Message"

    # Build Datetime string
    $Datetime = Get-Date
    $DateFormatted = $Datetime.ToString('yyyy-MM-dd HH:mm:ss')
    $LogMessage = "$DateFormatted`t$Level`t$Message"
    # Append to log file
    Add-Content -Path $LogPath -Value $LogMessage
}

# Validate path
function ValidPath {
    param (
    [string] $Path
    )

    # Check path
    if (-not (Test-Path -Path $Path)) {
        try   { Logging -Level "ERROR" -LogPath $LogPath -Message "The path [$Path] is invalid! Exiting." }
        catch { Write-Output "ERROR`tLogPath is not valid, no logs written." }
        Exit 1
    }
}

# Ensure all error are caught by catch blocks
$ErrorActionPreference = "Stop"

# Validate input params are provided
if (-not ($Source) -or -not ($Replica) -or -not ($LogPath)) {
    Logging -Level "ERROR" -LogPath $LogPath -Message "A required command line arguement was not provided. Exiting.."
    Exit 1
    }

# Create log file if not already present
if (-not (Test-Path -Path $LogPath)) {
    try { 
        New-Item -Force -Path $LogPath -ItemType File | Out-Null 
    } catch { 
        Write-Output "ERROR`tUnable to create log file in [$LogPath]." 
        Exit 1
    }
}

# Validate Source
if (-not (Test-Path -Path $Source)) {
    Logging -Level "ERROR" -LogPath $LogPath -Message "Source path [$Source] is invalid! Exiting." 
    Exit 1
}

# Validate Replica
if (-not (Test-Path -Path $Replica)) {
    Logging -Level "WARN" -LogPath $LogPath -Message "Replica path [$Replica] not found, attempting to create.." 
    try { 
        New-Item -Force -Path "$Replica\TouchTest" -ItemType File | Out-Null
        Remove-Item "$Replica\TouchTest"
        Logging -Level "INFO" -LogPath $LogPath -Message "Successfully created and removed `"TouchTest`" in [$Replica]."
    } catch { 
        Logging -Level "ERROR" -LogPath $LogPath -Message "Replica path validation failed for [$Replica]." 
        Exit 1
    }
}

# Start replication flow
Logging -Level "INFO" -LogPath $LogPath -Message "Starting replication script!"
Write-Output ""

if (-not (Test-Path -Path $Replica)) {
    Logging -Level "INFO" -LogPath $LogPath -Message "No Replica detected, copying Source entirely."
    try { Copy-Item -Recurse $Source $Replica }
    catch { 
        Logging -Level "ERROR" -LogPath $LogPath -Message "Could not write to Replica path [$Replica]! Exiting."
        Exit 1
    }
    Logging -Level "INFO" -LogPath $LogPath -Message "Replication completed!"
    Exit 0
} else {
    Logging -Level "INFO" -LogPath $LogPath -Message "Existing Replica found, running diffcheck."

    # Get Source file list
    $SourceFiles = Get-ChildItem -File -Recurse $Source

    # Get Replica file list
    $ReplicaFiles = Get-ChildItem -File -Recurse $Replica


    # Check for new files ADDED in Source
    Write-Output ""
    Logging -Level "INFO" -LogPath $LogPath -Message "Checking for new files in Source.."
    $diffList = @()
    # Check each file in Source exists in Replica
    foreach ($Sourcefile in $SourceFiles) {
        $found = $false
        foreach ($ReplicaFile in $ReplicaFiles) {
            if ($Sourcefile.fullName.Replace($Source, "") -eq $ReplicaFile.fullName.Replace($Replica, "")) {
                $found = $true
                break
            }
        }
        if (!$found) {
            $diffList += $Sourcefile
        }
    }
    # Add files which didn't exist in Replica
    if ($diffList.Count -gt 0) {
        Logging -Level "INFO" -LogPath $LogPath -Message "Adding files to Replica:"
        $diffList | ForEach-Object { Logging -Level "INFO" -LogPath $LogPath -Message $_.FullName }
        $diffList | ForEach-Object { 
            try   { Copy-Item $_.FullName $_.FullName.Replace($Source, $Replica) }
            catch { Logging -Level "ERROR" -LogPath $LogPath -Message "Failed to write file to Replica!" }
        }

        # Update Replica file list
        $ReplicaFiles = Get-ChildItem -File -Recurse $Replica
    } else {
        Logging -Level "INFO" -LogPath $LogPath -Message "No new files found."
    }


    # Check for existing files REMOVED from Source
    Write-Output ""
    Logging -Level "INFO" -LogPath $LogPath -Message "Checking for files removed from Source.."
    $diffList = @()
    # Check each file in Replica exists in Source
    foreach ($ReplicaFile in $ReplicaFiles) {
      $found = $false
      foreach ($Sourcefile in $SourceFiles) {
        if ($ReplicaFile.FullName.Replace($Replica, "") -eq $Sourcefile.FullName.Replace($Source, "")) {
          $found = $true
          break
        }
      }
      if (!$found) {
        $diffList += $ReplicaFile
      }
    }
    # Remove files that only exist in Replica
    if ($diffList.Count -gt 0) {
        Logging -Level "WARN" -LogPath $LogPath -Message "Removing files from Replica:"
        $diffList | ForEach-Object { Logging -Level "WARN" -LogPath $LogPath -Message $_.FullName }
        $diffList | ForEach-Object { 
            try   { Remove-Item $_.FullName }
            catch { Logging -Level "ERROR" -LogPath $LogPath -Message "Failed to remove file from Replica!" }
        }

        # Update Replica file list
        $ReplicaFiles = Get-ChildItem -File -Recurse $Replica
        } else {
        Logging -Level "INFO" -LogPath $LogPath -Message "No files removed."
        }

    # Check for file updates by comparing "LastWriteTime"
    Write-Output ""
    Logging -Level "INFO" -LogPath $LogPath -Message "Checking for file updates in Source.."
    $SourceFiles | ForEach-Object {
        $SourceFilePath = $_.FullName
        $SourceFileUpdated = $_.LastWriteTime
        $ReplicaFiles | ForEach-Object {
            if ($_.FullName.Replace($Replica, "") -eq $SourceFilePath.Replace($Source, "")) {
                $ReplicaFilePath = $_.FullName
                $ReplicaFileUpdated = $_.LastWriteTime
                if ($SourceFileUpdated -ne $ReplicaFileUpdated) {
                    Logging -Level "INFO" -LogPath $LogPath -Message "Updating file: $SourceFilePath"
                    try   { Copy-Item $SourceFilePath $SourceFilePath.Replace($Source, $Replica) }
                    catch { Logging -Level "ERROR" -LogPath $LogPath -Message "Failed to update file in Replica!" }
                }
            }
        }
    }

    Logging -Level "INFO" -LogPath $LogPath -Message "Replication completed!"
    Exit 0
}
