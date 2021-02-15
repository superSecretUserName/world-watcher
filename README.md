World Watcher V0.1 WIP
======================

Overview
========

*Note: This will create backups but does not handle archiving*

This is a simple powershell script designed to automate backups for 
dedicated servers world saves for games such as Terraria and Valheim.

The end goal is to have a simple file watcher that will automatically 
backup upon server save and automatically archive old saves,
saving only file per day for any files older than 24 hours.


Usage
=====
`./world-watcher.ps1 [fileToWatch]`