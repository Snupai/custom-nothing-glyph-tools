@echo off
title Create Custom Glyph
setlocal
set "refreshedEnv=false"

:start
REM check if python is installed
@(
    (
        python --version >nul 2>&1
    ) || (
        call :PrintWarning "Python is not installed."
        if "%refreshedEnv%"=="false" (
            call :PrintInfo "Trying to refresh Environment first."
            call :tryRefreshEnv
            set "refreshedEnv=true"
            goto :start
        )
        else (
            call :PrintInfo "Consider running the Install-Dependencies.bat."
            echo.
            goto :runInstallDependencies
        )
    )
)

REM check if ffmpeg is installed
@(
    (
        ffmpeg -version >nul 2>&1
    ) || (
        echo.
        call :PrintWarning "ffmpeg is not installed."
        if "%refreshedEnv%"=="false" (
            call :PrintInfo "Trying to refresh Environment first."
            call :tryRefreshEnv
            set "refreshedEnv=true"
            goto :start
        )
        else (
            call :PrintInfo "Consider running the Install-Dependencies.bat first."
            echo.
            goto :runInstallDependencies
        )
    )
)

goto :checkIfToolsDirectoryExists

REM create a goto label for the case that either python or ffmpeg is not installed and the user wants to run the Install-Dependencies.bat
:runInstallDependencies
REM try to refresh the environment variables before trying to call the Install-Dependencies.bat
setlocal EnableDelayedExpansion
if "%refreshedEnv%"=="false" (
    call :tryRefreshEnv
    set "refreshedEnv=true"
    goto :start
)

:askForInstallDependencies
REM ask if the user wants to run the Install-Dependencies.bat now
set /p runInstallDependencies="Do you want to run the Install-Dependencies.bat now? [y/n]: "
if /i "%runInstallDependencies%"=="y" (
    echo.
    call :PrintInfo "Running the Install-Dependencies.bat."
    echo.
    powershell Start-Process -FilePath './Install-Dependencies.bat'
    set "refreshedEnv=false"
    echo Press any key when the Install-Dependencies.bat has finished.
    pause >nul
    goto :start
) 
if /i "%runInstallDependencies%"=="n" (
    echo.
    call :PrintWarning "Python is not installed. Please install it manually."
    echo.
    echo Press any key to continue.
    pause >nul
    goto :eof
)
else goto :askForInstallDependencies
endlocal

:checkIfToolsDirectoryExists
REM check if the GlyphTranslator.py and GlyphModder.py files exist
if not exist GlyphTranslator.py (
    echo.
    call :PrintWarning "The file GlyphTranslator.py does not exist."
    echo.
    echo Press any key to continue.
    pause >nul
    goto :eof
)

if not exist GlyphModder.py (
    echo.
    call :PrintWarning "The file GlyphModder.py does not exist."
    echo.
    echo Press any key to continue.
    pause >nul
    goto :eof
)

REM get current directory and save it to a variable
set "toolsDirectory=%cd%"

REM ask for a name for the new glyph
echo.
:askForGlyphName
set /p glyphName="Enter a title for the new glyph: "
if "%glyphName%"=="" goto :askForGlyphName
:: check if the glyphname is too long and if it is ask for a new one
if "%glyphName:~0,32%" neq "%glyphName%" (
    echo.
    call :PrintWarning "The title ""%glyphName%""" is too long. Please enter a title with a maximum of 32 characters.
    echo.
    echo Press any key to continue.
    pause >nul
    goto :askForGlyphName
)
:: check if the glyphName contains any of the following characters: \ / : * ? " < > | and if it does replace them with _ and save the new name to a variable called folderName
setlocal enabledelayedexpansion
set "replace=_"
set "folderName=#!glyphName!"
:replaceLoop
for /F "tokens=1 delims=*" %%A in ("!folderName!") do (
  set "prefix=%%A"
  set "rest=!folderName:*%%A=!"
  if defined rest (
    set "rest=!replace!!rest:~1!"
    set Again=1
  ) else set "Again="
  set "folderName=%%A!rest!"
)
if defined again goto :replaceLoop
set "folderName=!folderName:~1!"
set folderName=!folderName:^|=^_!
set folderName=!folderName:^<=^_!
set folderName=!folderName:^>=^_!
set folderName=!folderName:/=_!
set folderName=!folderName:\=_!
set folderName=!folderName::=_!
set folderName=!folderName:?=_!


if "%glyphName%" neq "!folderName!" (
    echo.
    call :PrintWarning "The title ""%glyphName%""" contains one or more invalid characters. The title will be kept and the folder name will be ""!folderName!"".
    echo.
    echo Press any key to continue.
    pause >nul
)


REM create a new folder for the custom glyph and change to it
set "glyphFolder=%~dp0!folderName!"
if not exist "%glyphFolder%" (
    @(
        (
            md "%glyphFolder%"
        ) || (
            echo.
            call :PrintError "Could not create folder ""%~dp0%glyphName%"
            echo.
            echo Press any key to continue.
            pause >nul
            exit /b 0
        )
    )
    cd /d "%glyphFolder%"
    call :PrintInfo "created new Directory ""%~dp0%glyphName%""". Please add the files for the new glyph to this folder."
    goto :openGlyphFolder
)


echo.
REM ask if the user wants to continue if the folder already exists
call :PrintWarning "The folder ""%glyphFolder%""" already exists."
echo.
:askForContinue
set /p continue="Do you want to continue? [y/n]: "
if /i "%continue%"=="n" goto :eof
if /i "%continue%" neq "y" goto :askForContinue
cd /d "%glyphFolder%"
call :PrintInfo "opened Directory ""%cd%""". Please add the files for the new glyph to this folder."

:openGlyphFolder
REM open the new folder in the file explorer
explorer "%glyphFolder%"
echo.
echo Press any key to continue.
pause >nul

REM check if the folder is empty
:checkFolderEmpty
set "folderEmpty=true"
for /f "delims=" %%i in ('dir /b /a-d') do set "folderEmpty=false"
if "%folderEmpty%"=="true" (
    echo.
    call :PrintWarning "The folder ""%cd%""" is empty. Please add the files."
    echo.
    echo Press any key to continue.
    pause >nul
    goto :checkFolderEmpty
)

call :tmpExists

:checkFolderContainsLabelTxtFile
findstr /e /n /r /m /c:".END" *.txt > "%~dp0/.tmp/labelFileName.txt"

REM get the first line of the file and save it to a variable
set /p labelFileName=<"%~dp0/.tmp/labelFileName.txt"
rd /s /q "%~dp0/.tmp"
if not defined labelFileName (
  call :PrintInfo "The folder ""%cd%""" does not seem to contain a valid label file."
  echo.
  echo Press any key to retry.
  pause >nul
  goto :checkFolderContainsLabelTxtFile
)
call :PrintInfo "The label file ""%labelFileName%""" was found."

call :CleanUp

:checkFolderContainsAnotherTxtFile
set "watermarkFileName="
REM search for another .txt file thats not labelFileName
for /f "delims=" %%i in ('dir /b /a-d *.txt ^| findstr /v /i /c:%labelFileName%') do (
  REM if another .txt file is found, set watermarkFileName to the filename
  if not defined watermarkFileName (
    set "watermarkFileName=%%i"
    break
  )
)
if defined watermarkFileName (
    call :PrintInfo "The watermark file ""%watermarkFileName%""" was found."
) else (
    call :PrintInfo "No watermark file was found. Continueing without one."
)

REM ask if the user wants to disable compatibility mode
echo.
:askForDisableCompatibilityMode
set /p disableCompatibilityMode="Do you want to disable compatibility mode? [y/n]: "
if /i "%disableCompatibilityMode%"=="y" (
    echo.
    call :PrintInfo "Compatibility mode disabled."
    echo.
    echo Press any key to continue.
    pause >nul
    set "disableCompatibilityMode=--disableCompatibility"
    goto :runGlyphTranslator
) 
if /i "%disableCompatibilityMode%"=="n" (
    set "disableCompatibilityMode="
    goto :runGlyphTranslator
)
goto :askForDisableCompatibilityMode

:runGlyphTranslator
REM take the filename of the .txt file and use it as parameter for GlyphTranslator
REM if watermark.txt exists, use it as parameter for GlyphTranslator with --watermark watermark.txt
if "%watermarkFileName%"=="" (
    echo.
    call :PrintInfo "Running GlyphTranslator with the file ""%labelFileName%"" as parameter."
    echo.
    @(
        (
            python %toolsDirectory%/GlyphTranslator.py "%labelFileName%" %disableCompatibilityMode%
        ) || (
            echo.
            call :PrintError "The file ""%labelFileName%""" does not seem to be a valid labels file. Please add a valid labels file."
            echo.
            echo Press any key to continue.
            pause >nul
            goto :checkFolderContainsOneTxtFile
        )
    )
) else (
    echo.
    call :PrintInfo "Running GlyphTranslator with the file ""%labelFileName%""" and """%watermarkFileName%""" as parameter."
    echo.
    @(
        (
            python %toolsDirectory%/GlyphTranslator.py --watermark "%watermarkFileName%" "%labelFileName%" %disableCompatibilityMode%
        ) || (
            echo.
            call :PrintError "At least one of the files ""%labelFileName%""" """%watermarkFileName%""" does not seem to be valid file. Please check the files."
            echo.
            echo Press any key to continue.
            pause >nul
            goto :checkFolderContainsOneTxtFile
        )
    )
)


timeout /t 3

REM check if the folder contains 1 .glypha file and add the filename to a variable
:checkFolderContainsOneGlyphaFile
set "glyphaFileName="
for /f "delims=" %%i in ('dir /b /a-d *.glypha') do set "glyphaFileName=%%i"
if "%glyphaFileName%"=="" (
    echo.
    call :PrintWarning "The folder ""%cd%""" does not seem to contain a valid glypha file. Please add a valid glypha file."
    echo.
    echo Press any key to continue.
    pause >nul
    goto :checkFolderContainsOneGlyphaFile
)

REM check if the folder contains 1 .glyphc1 file and add the filename to a variable
:checkFolderContainsOneGlyphc1File
set "glyphc1FileName="
for /f "delims=" %%i in ('dir /b /a-d *.glyphc1') do set "glyphc1FileName=%%i"
if "%glyphc1FileName%"=="" (
    echo.
    call :PrintWarning "The folder ""%cd%""" does not seem to contain a valid glyphc1 file. Please add a valid glyphc1 file."
    echo.
    echo Press any key to continue.
    pause >nul
    goto :checkFolderContainsOneGlyphc1File
)

REM check if the folder contains 1 .ogg file and add the filename to a variable
:checkFolderContainsOneOggFile
set "oggFileName="
for /f "delims=" %%i in ('dir /b /a-d *.ogg') do set "oggFileName=%%i"
if "%oggFileName%"=="" (
    echo.
    call :PrintWarning "The folder ""%cd%""" does not seem to contain a valid sound file. Please add a valid sound file."
    echo.
    echo Press any key to continue.
    pause >nul
    goto :checkFolderContainsOneOggFile
)

echo.
REM run the GlyphModder with the filename of the .glypha, .glyphc1 and .ogg file as parameter the CustomTitle will be the folder name
@(
    (
        python %toolsDirectory%/GlyphModder.py -t "%glyphName%" -w "%glyphaFileName%" "%glyphc1FileName%" "%oggFileName%"
    ) || (
        echo.
        call :PrintError "At least one of these files (%glyphaFileName%, %glyphc1FileName%, %oggFileName%) does not seem to be a valid file."
        echo.
        echo Press any key to continue.
        pause >nul
        goto :checkFolderContainsOneGlyphaFile
    )
)
echo.
pause

REM ask if the user wants to delete the folder
call :PrintInfo "The glyph ""%glyphName%""" was created successfully."
echo.
:askForDeletion
set /p "continueRunning=Do you want to delete the folder "%glyphFolder%"? [y/n]: "
if /i "%continueRunning%" equ "n" goto :dontDeleteFolder
if /i "%continueRunning%" neq "y" goto :askForDeletion

echo.
call :PrintWarning "The folder ""%glyphFolder%""" will be deleted."
echo.
echo Press any key to continue.
pause >nul
cd /d %toolsDirectory%
rd /s /q "%glyphFolder%"
goto :eof

:dontDeleteFolder
echo.
call :PrintInfo "The folder ""%glyphFolder%""" will be kept."
echo.
echo Press any key to continue.
pause >nul
goto :eof

:PrintError
powershell Write-Host -ForegroundColor Red '[ERROR] %*'
exit /b 0

:PrintWarning
powershell Write-Host -ForegroundColor Yellow '[WARNING] %*'
exit /b 0

:PrintInfo
powershell Write-Host -ForegroundColor DarkCyan '[INFO] %*'
exit /b 0


REM Check if the folder ".tmp" exists and create it if it doesn't
:tmpExists
if exist "%~dp0/.tmp" (
    call :PrintInfo "The folder "".tmp""" exists - using it."
) else (
    REM Create the folder ".tmp" and hide it
    mkdir "%~dp0/.tmp"
    attrib +h "%~dp0/.tmp" /s /d
)
exit /b 0

:tryRefreshEnv
call :tmpExists
call :PrintInfo "Refreshing environment variables..."
@(
    (
        REM Download code from @badrelmers on GitHub to refresh environment variables.
        REM This downloaded code is part of badrelmers/RefrEnv (https://github.com/badrelmers/RefrEnv) which is released under the GPL-3.0 license.
        REM Go to https://github.com/badrelmers/RefrEnv/blob/main/LICENSE for full license details.
        powershell -Command "Invoke-WebRequest -Uri "https://raw.githubusercontent.com/badrelmers/RefrEnv/main/refrenv.bat" -OutFile "%~dp0/.tmp/refrenv.bat""
    ) && (
        call %~dp0/.tmp/refrenv.bat
        call :CleanUp
        echo.
        exit /b 0
    ) || (
        REM Download failed - inform the user
        call :PrintWarning "Could not refresh environment."
        pause
        call :CleanUp
        echo.
        exit /b 0
    )
)

:CleanUp
rd /S /Q "%~dp0/.tmp"
exit /b 0