@echo off
SET "FILENAME=%~dp0\Vagrantfile"
bitsadmin.exe /transfer "Jarbas Environment Vagrantfile Downloader" https://raw.githubusercontent.com/gpcnifpb/jarbas/master-testing/environment/Vagrantfile "%FILENAME%"