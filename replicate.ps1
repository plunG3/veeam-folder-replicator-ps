param(
  [string] $Source = "C:\Source",
  [string] $Replica = "D:\Replica",
  [string] $LogPath = "D:\Replica\replication-log.txt"
)

Write-Output "Both Source and Replica paths were not provided, would you like to use the assumed defaults?"
Write-Output "Source: [$Source]"
Write-Output "Replica: [$Replica]"
Write-Output "Logfile: $LogPath"
$Continue = Read-Host -Prompt "[Y]/n ?"

if (($Continue -eq "") -or ($Continue.ToLower() -eq "y")) {
    Write-Output "Source: $Source"
    Write-Output "Replica: $Replica"
    Write-Output "Logfile: $LogPath"
    } else {
    Write-Output "Exiting.."
    Exit 0
    }


if (-not (Test-Path -Path $Replica)) {
    Write-Output "No Replica detected, copying Source entirely.."
    Copy-Item -Recurse $Source $Replica
    Exit 0
    } else {
    Write-Output "Replica found, doing diff.."

    # Get Source file list
    $SourceFiles = Get-ChildItem -File -Recurse $Source

    # Get Replica file list
    $ReplicaFiles = Get-ChildItem -File -Recurse $Replica


    # Check for new files ADDED in Source
    $diffList = @()
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

    if ($diffList.Count -gt 0) {
        Write-Host "Adding files to Replica:"
        $diffList | ForEach-Object { Write-Host $_.FullName }
        $diffList | ForEach-Object { Copy-Item $_.FullName $_.FullName.Replace($Source, $Replica) }

        # Update Replica file list
        $ReplicaFiles = Get-ChildItem -File -Recurse $Replica
    } else {
        Write-Output "No new files found."
    }


    # Check for existing files REMOVED from Source
    $diffList = @()
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

    if ($diffList.Count -gt 0) {
        Write-Host "Removing files from Replica:"
        $diffList | ForEach-Object { Write-Host $_.FullName }
        $diffList | ForEach-Object { Remove-Item $_.FullName }

        # Update Replica file list
        $ReplicaFiles = Get-ChildItem -File -Recurse $Replica
        } else {
        Write-Output "No files removed."
        }

    # Check for file updates
    Write-Output "Looking for updates."
    $SourceFiles | ForEach-Object {
        $SourceFilePath = $_.FullName
        $SourceFileUpdated = $_.LastWriteTime
        $ReplicaFiles | ForEach-Object {
            if ($_.FullName.Replace($Replica, "") -eq $SourceFilePath.Replace($Source, "")) {
                $ReplicaFilePath = $_.FullName
                $ReplicaFileUpdated = $_.LastWriteTime
                if ($SourceFileUpdated -ne $ReplicaFileUpdated) {
                    Write-Output "Updating file: $SourceFilePath"
                    Copy-Item $SourceFilePath $SourceFilePath.Replace($Source, $Replica)
                    }
                }
            }
        }

    Exit 0
}


$Hold = Read-Host -Prompt "waiting to exit.."
