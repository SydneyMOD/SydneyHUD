@echo off
cd /d %~dp0

echo deleting old file...
del SydneyHUD.zip
echo delete completed.

echo starting compress...
7za a SydneyHUD.zip ../SydneyHUD/ -xr!.git/ -xr!.vscode/ -xr!readme.md -xr!.gitignore -xr!7za.exe -xr!compress.bat
echo compress finished.
pause
