@echo off
cd /d %~dp0

echo "%~1"

if "%~1"=="--edge" (
	echo deleting old file...
	del SydneyHUD_edge.zip

	echo starting compress...
	7za a SydneyHUD.zip ../SydneyHUD/ -xr!.git/ -xr!.vscode/ -xr!.idea/ -xr!installer/ -xr!readme.md -xr!.gitignore -xr!7za.exe -xr!build.bat -xr!modworkshop_desc.txt -xr!.editorconfig -xr!.travis.yml -xr!SydneyHUD_edge.zip

	echo renaming...
	ren SydneyHUD.zip SydneyHUD_edge.zip
) else (
	echo deleting old file...
	del SydneyHUD.zip

	echo starting compress...
	7za a SydneyHUD.zip ../SydneyHUD/ -xr!.git/ -xr!.vscode/ -xr!.idea/ -xr!installer/ -xr!readme.md -xr!.gitignore -xr!7za.exe -xr!build.bat -xr!modworkshop_desc.txt -xr!.editorconfig -xr!.travis.yml -xr!SydneyHUD_edge.zip
)
