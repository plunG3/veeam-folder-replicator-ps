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
    [string] $Message,
    [string] $LogPath
    )
    # Output to terminal
    Write-Host $Message

    # Build Datetime string
    $Datetime = Get-Date
    $DateFormatted = $Datetime.ToString('yyyy-MM-dd HH:mm:ss')
    $LogMessage = "$DateFormatted`t`t$Message"
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
        try {
            Logging -LogPath $LogPath -Message "Error: The path [$Path] is invalid! Exiting."
            }
        catch {
            Write-Output "Error: LogPath is not valid, no logs written."
            }
    Exit 1
    }
}

# Validate input params are provided
if (-not ($Source) -or -not ($Replica) -or -not ($LogPath)) {
    Logging -LogPath $LogPath -Message "Error: A required command line arguement was not provided. Exiting.."
    Exit 1
    }

# Validate paths
ValidPath -Path $Source
ValidPath -Path $Replica.Substring(0, 3)

# Create log file if not already present
$logExists = Test-Path -Path $LogPath
if (-not $logExists) {
    try { 
        New-Item -Force -Path $LogPath -ItemType File | Out-Null
        } 
    catch { 
        Write-Output "Error: Unable to create log file [$LogPath]." 
        Exit 1
        }
    }

Logging -LogPath $LogPath -Message "Starting new execution of replication script!"
Write-Output ""

# Start replication flow
if (-not (Test-Path -Path $Replica)) {
    Logging -LogPath $LogPath -Message "No Replica detected, copying Source entirely."
    Copy-Item -Recurse $Source $Replica
    Logging -LogPath $LogPath -Message "Replication execution completed!"
    Exit 0
    } else {
    Logging -LogPath $LogPath -Message "Existing Replica found, running diffcheck."

    # Get Source file list
    $SourceFiles = Get-ChildItem -File -Recurse $Source

    # Get Replica file list
    $ReplicaFiles = Get-ChildItem -File -Recurse $Replica


    # Check for new files ADDED in Source
    Write-Output ""
    Logging -LogPath $LogPath -Message "Checking for new files in Source"
    Write-Output "------------------------------"
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
        Logging -LogPath $LogPath -Message "Adding files to Replica:"
        $diffList | ForEach-Object { Logging -LogPath $LogPath -Message $_.FullName }
        $diffList | ForEach-Object { Copy-Item $_.FullName $_.FullName.Replace($Source, $Replica) }

        # Update Replica file list
        $ReplicaFiles = Get-ChildItem -File -Recurse $Replica
    } else {
        Logging -LogPath $LogPath -Message "No new files found."
    }


    # Check for existing files REMOVED from Source
    Write-Output ""
    Logging -LogPath $LogPath -Message "Checking for files removed from Source"
    Write-Output "------------------------------------"
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
        Logging -LogPath $LogPath -Message "Removing files from Replica:"
        $diffList | ForEach-Object { Logging -LogPath $LogPath -Message $_.FullName }
        $diffList | ForEach-Object { Remove-Item $_.FullName }

        # Update Replica file list
        $ReplicaFiles = Get-ChildItem -File -Recurse $Replica
        } else {
        Logging -LogPath $LogPath -Message "No files removed."
        }

    # Check for file updates by comparing "LastWriteTime"
    Write-Output ""
    Logging -LogPath $LogPath -Message "Checking for file updates in Source"
    Write-Output "---------------------------------"
    $SourceFiles | ForEach-Object {
        $SourceFilePath = $_.FullName
        $SourceFileUpdated = $_.LastWriteTime
        $ReplicaFiles | ForEach-Object {
            if ($_.FullName.Replace($Replica, "") -eq $SourceFilePath.Replace($Source, "")) {
                $ReplicaFilePath = $_.FullName
                $ReplicaFileUpdated = $_.LastWriteTime
                if ($SourceFileUpdated -ne $ReplicaFileUpdated) {
                    Logging -LogPath $LogPath -Message "Updating file: $SourceFilePath"
                    Copy-Item $SourceFilePath $SourceFilePath.Replace($Source, $Replica)
                    }
                }
            }
        }

    Logging -LogPath $LogPath -Message "Replication execution completed!"
    Exit 0
}
