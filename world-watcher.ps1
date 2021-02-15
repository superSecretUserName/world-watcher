#! /usr/bin/pwsh
# built off of https://powershell.one/tricks/filesystem/filesystemwatcher
[CmdletBinding()]
param(
  [Parameter(Position=0, mandatory)]
  [string] $fileToWatch,
  [int] $backupDays = 7,
  [string] $backupPath = "./backups"
  )

##
 # create backup folder if it doesn't exist
 ##
function createBackupFolderStructure() {
  If (!(test-path "./backups")) {
    Write-Warning "Backup Folders Not Found. Creating"
    New-Item -ItemType Directory -Force -Path $backupPath
  }

  # ensure that we have $backupDays number of backup folders
  for ($i = 0; $i -lt $backupDays; $i++) {
    If (!(test-path "./backups/$i-days-ago")) {
      New-Item -ItemType Directory -Force -Path "$backupPath/$i-days-ago"
    }
  }
}

##
 # Creates a backup with epoch timestamp in filename
 ##
function createBackups() {
  $epochTime = [int][double]::Parse((Get-Date -UFormat %s))
  $backupName = $ChangeInformation.Name + "-" + $epochTime
  Copy-Item $ChangeInformation.Name backups/$backupName
  Write-Host "Creating Backup File: $backupName" 
}


##
 # ensures no more than 1 backup per day if older than 24 hours
 ##
function clearOldBackups() {
  Write-Host "Clearing Old Backups"

  # get files in folder
  $files = Get-ChildItem -Path "./backups" | Foreach-Object {$_.LastWriteTime}

  Write-Host ($files | Format-List | Out-String)

  foreach ($filename in $files) {
    bucketByDay($filename)
  }
}

##
 # TODO: build this out to bucket 1 save file per day older than 24 hours
 ##
function bucketByDay([string] $lastWrite, [int] $daysOld)  {
  $timespan = new-timespan -days $daysOld
    if ($lastWrite -gt $timespan) {
    
    }
}




# specify the path to the folder you want to monitor:
$Path = Get-Location

createBackupFolderStructure




# specify which files you want to monitor
$FileFilter = $fileToWatch 

# specify whether you want to monitor subfolders as well:
$IncludeSubfolders = $true

# specify the file or folder properties you want to monitor:
$AttributeFilter = [IO.NotifyFilters]::FileName, [IO.NotifyFilters]::LastWrite 

# specify the type of changes you want to monitor:
$ChangeTypes = [System.IO.WatcherChangeTypes]::Changed 
# specify the maximum time (in milliseconds) you want to wait for changes:
$Timeout = 1000

# define a function that gets called for every change:
function Invoke-SomeAction
{
  param
  (
    [Parameter(Mandatory)]
    [System.IO.WaitForChangedResult]
    $ChangeInformation
  )
  # disable watcher to prevent repeat events from processing
  $watcher.EnableRaisingEvents = false

  # report the file change
  Write-Warning "Change detected " 
  $ChangeInformation | Out-String | Write-Host -ForegroundColor DarkYellow

  # since the server may be making multiple writes we'll give 
  # a very generous window of 10 seconds
  # TODO: add 10 second sleep here
  
  # re-enable watcher
  $watcher.EnableRaisingEvents = true

  # make back up file
  createBackups
  # remove old file
  clearOldBackups

}





# use a try...finally construct to release the
# filesystemwatcher once the loop is aborted
# by pressing CTRL+C
try
{
  Write-Warning "FileSystemWatcher is monitoring $Path"
  
  # create a filesystemwatcher object
  $watcher = New-Object -TypeName IO.FileSystemWatcher -ArgumentList $Path, $FileFilter -Property @{
    IncludeSubdirectories = $IncludeSubfolders
    NotifyFilter = $AttributeFilter
  }

  # start monitoring manually in a loop:
  do
  {
    # wait for changes for the specified timeout
    # IMPORTANT: while the watcher is active, PowerShell cannot be stopped
    # so it is recommended to use a timeout of 1000ms and repeat the
    # monitoring in a loop. This way, you have the chance to abort the
    # script every second.
    $result = $watcher.WaitForChanged($ChangeTypes, $Timeout)
    # if there was a timeout, continue monitoring:
    if ($result.TimedOut) { continue }
    
    Invoke-SomeAction -Change $result
    # the loop runs forever until you hit CTRL+C    
  } while ($true)
}
finally
{
  # release the watcher and free its memory:
  $watcher.Dispose()
  Write-Warning 'FileSystemWatcher removed.'
}

