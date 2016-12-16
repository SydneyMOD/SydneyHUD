@echo off
cd /d %~dp0

echo deleting old file...
del SydneyHUD.zip
echo delete completed.

echo starting compress...
7za a SydneyHUD.zip ../SydneyHUD/ -xr!.git/ -xr!.vscode/ -xr!installer/ -xr!readme.md -xr!.gitignore -xr!7za.exe -xr!build.bat
