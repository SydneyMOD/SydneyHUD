:: misc
@echo off
cd /d %~dp0
title SydneyHUD Installer v1.0

:: set zipball url
set SydneyHUD_url="https://raw.githubusercontent.com/SydneyMOD/SydneyHUD/SydneyHUD.zip"
set SydneyHUD-Assets_url="https://raw.githubusercontent.com/SydneyMOD/SydneyHUD-Assets/SydneyHUD-Assets.zip"

:: set PAYDAY2 mod dir
set mods_path="C:\Program Files (x86)\Steam\steamapps\common\PAYDAY 2\mods"
set mod_overrides_path="C:\Program Files (x86)\Steam\steamapps\common\PAYDAY 2\assets\mod_overrides"

:: download zipball
pget %SydneyHUD_url%
pget %SydneyHUD-Assets_url%

:: unzip to PAYDAY2 mod dir
::7za x ./SydneyHUD.zip %mods_path%
::7za x ./SydneyHUD-Assets.zip %mod_overrides_path%

:: echo completed message
echo "Install completed. Now, you can start up game with SydneyHUD!"
pause