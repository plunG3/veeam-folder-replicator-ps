
# PowerShell Script: ReplicateFolder

This PowerShell script replicates the contents of a source folder to a replica directory, logging the process to both the terminal and a specified log file.
## Features

    Replicates folders and subfolders.
    Writes detailed logs to the console and a specified log file.

## Usage
PowerShell

`.\ReplicateFolder.ps1 -Source <source_folder_path> -Replica <replica_folder_path> -LogPath <log_file_path>`

Use code with caution.

Arguments:

    -Source: Path to the source folder containing the files and subfolders to replicate.
    -Replica: Path to the destination folder where the replicated files will be placed.
    -LogPath: Path to the log file where all actions will be logged.

## Example
PowerShell

`.\ReplicateFolder.ps1 -Source "C:\MyDocuments\Important Files" -Replica "C:\Backups\Documents" -LogPath "C:\Logs\FolderReplication.log"`

Use code with caution.

This command will replicate the contents of the "C:\MyDocuments\Important Files" folder to the "C:\Backups\Documents" directory, logging all actions to the "C:\Logs\FolderReplication.log" file.
Requirements

    PowerShell 5.1 or later

## How it Works

    The script parses the command-line arguments for the source folder path, replica folder path, and log file path.
    It validates the existence of the source folder.
    It creates the replica folder if it doesn't exist.
    The script iterates through the files and subfolders within the source directory.
    For each file, it copies it to the corresponding location in the replica directory.
    All actions (source file path, destination file path, and timestamps) are logged to both the console and the specified log file.


## Author

Calvin Glass  
2024-04-28
