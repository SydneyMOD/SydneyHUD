@echo off
cd /d %~dp0

echo starting compress...
7za a SydneyHUD.zip loc/ lua/ menu/ scripts/ mod.txt SydneyHUD.lua LICENSE
echo compress finished.
pause