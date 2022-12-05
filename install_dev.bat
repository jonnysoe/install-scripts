@echo off

set ERROR_RETURN=0

@REM ===================================================================
@REM Start of Git Installation
@REM ===================================================================
:checkGit
rem Check for Git installation
where git > nul 2>&1

rem No error, Git has been installed, so skip to install VS Code
if %ERRORLEVEL% equ 0 goto checkVscode

set GIT_INSTALLER=%USERPROFILE%\Downloads\GitSetup.exe

rem Skip to install if installer already exist
if exist %GIT_INSTALLER% goto installGit

:downloadGit
echo Downloading Git...
curl -L "https://github.com/git-for-windows/git/releases/download/v2.36.1.windows.1/Git-2.36.1-64-bit.exe" -o %GIT_INSTALLER%

rem Fail if download fails
if %ERRORLEVEL% neq 0 goto failInstall
if not exist %GIT_INSTALLER% goto failInstall

:installGit
echo Installing Git...
call %GIT_INSTALLER% /VERYSILENT /NORESTART

rem Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

@REM ===================================================================
@REM Start of VS Code Installation
@REM ===================================================================
:checkVscode
rem Check for VS Code installation
where code > nul 2>&1

rem No error, VS Code has been installed, so skip to install extention
if %ERRORLEVEL% equ 0 goto installExtension

set CODE_FULLPATH="C:\Program Files\Microsoft VS Code\bin\code"

rem code fullpath exists, VS Code has been installed, so skip to install extention
if exist %CODE_FULLPATH% equ 0 goto installExtension

set VSCODE_INSTALLER=%USERPROFILE%\Downloads\VSCodeSetup.exe

rem Skip to install if installer already exist
if exist %VSCODE_INSTALLER% goto installVscode

:downloadVscode
echo Downloading VS Code...

rem Detect OS architecture and download accordingly
rem https://docs.microsoft.com/en-us/windows/win32/winprog64/wow64-implementation-details
if /i %PROCESSOR_ARCHITECTURE%==AMD64 (
	curl -L "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64" -o %VSCODE_INSTALLER%
) else if /i %PROCESSOR_ARCHITECTURE%==x86 (
	curl -L "https://code.visualstudio.com/sha/download?build=stable&os=win32" -o %VSCODE_INSTALLER%
) else if /i %PROCESSOR_ARCHITECTURE%==ARM64 (
	curl -L "https://code.visualstudio.com/sha/download?build=stable&os=win32-arm64" -o %VSCODE_INSTALLER%
) else (
	rem unsupported architecture, eg. Intel Itanium
	goto failInstall
)

rem Fail if download fails
if %ERRORLEVEL% neq 0 goto failInstall
if not exist %VSCODE_INSTALLER% goto failInstall

:installVscode
echo Installing VS Code...
:: https://github.com/Microsoft/vscode/blob/main/build/win32/code.iss#L76-L97
:: runcode will be enabled by default, so disable it VS Code will pop out
:: addcontextmenufolders optionally added so that projects/folders can be easily opened
call %VSCODE_INSTALLER% /VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufolders

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:editSettings
set VSCODE_SETTINGS_DIR=%APPDATA%\Code\User
mkdir %VSCODE_SETTINGS_DIR% > nul 2>&1

set VSCODE_SETTINGS=%VSCODE_SETTINGS_DIR%\settings.json

if not exist %VSCODE_SETTINGS% (
    rem file doesn't exist, touch file
    rem type nul > %VSCODE_SETTINGS%
    echo {
    echo     "vsintellicode.modify.editor.suggestSelection": "automaticallyOverrodeDefaultValue",
    echo     "tabnine.experimentalAutoImports": true,
    echo     "C_Cpp.default.includePath": [
    echo         "${default}",
    echo         "${workspaceFolder}/**",
    echo         "${workspaceFolder}/node_modules/**"
    echo     ],
    echo     "window.restoreWindows": "none",
    echo     "editor.rulers": [72,120],
    echo     "files.trimTrailingWhitespace": true,
    echo     "window.restoreWindows": "none",
    echo     "editor.renderWhitespace": "all",
    echo     "terminal.integrated.defaultProfile.windows": "Git Bash",
    echo     "files.associations": {
    echo         "CmakeLists.txt": "cmake",
    echo         "*.inc": "cpp"
    echo     },
    echo     "editor.suggestSelection": "first",
    echo     "search.exclude": {
    echo         "**/*jar-classes.txt": true,
    echo         "**/*.examples.json": true,
    echo         "**/node_modules": false
    echo     },
    echo     "search.useIgnoreFiles": false,
    echo     "gradle.reuseTerminals": "all",
    echo     "editor.detectIndentation": false,
    echo     "editor.unusualLineTerminators": "auto",
    echo     "diffEditor.wordWrap": "off",
    echo     "explorer.confirmDelete": false,
    echo     "cmake.configureOnOpen": false,
    echo     "git.autofetch": true,
    echo     "git.pruneOnFetch": true,
    echo     "diffEditor.ignoreTrimWhitespace": false,
    echo     "prettier.tabWidth": 4,
    echo     "prettier.useTabs": false,
    echo     "C_Cpp.autoAddFileAssociations": false,
    echo     "explorer.confirmDragAndDrop": false,
    echo }
) > %VSCODE_SETTINGS%

rem ///@todo temporarily skip individual settings for now
goto installExtension

>nul findstr /C:"workbench.editorAssociations" %VSCODE_SETTINGS% || (
    rem ///@todo use jq to update settings.json
)

>nul findstr /C:"editor.rules" %VSCODE_SETTINGS% || (
    rem ///@todo use jq to update settings.json
)

:installExtension
rem No error exit, nothing is fatal here

:: GitLens for Git convenience
call %CODE_FULLPATH% --force --install-extension eamodio.gitlens

:: Git Graph for Git tree view
call %CODE_FULLPATH%  --force --install-extension mhutchie.git-graph

:: MS C/C++ Language support
call %CODE_FULLPATH% --force --install-extension ms-vscode.cpptools-extension-pack
call %CODE_FULLPATH% --force --install-extension VisualStudioExptTeam.vscodeintellicode

:: CMake Language support
:: call %CODE_FULLPATH% --force --install-extension twxs.cmake

:: CMake Tool for Build and Run
:: call %CODE_FULLPATH% --force --install-extension ms-vscode.cmake-tools

:: LLDB support
call %CODE_FULLPATH% --force --install-extension vadimcn.vscode-lldb

:: Google proto3 support
call %CODE_FULLPATH% --force --install-extension zxh404.vscode-proto3

:: Python Language support
call %CODE_FULLPATH% --force --install-extension ms-toolsai.jupyter
call %CODE_FULLPATH% --force --install-extension ms-python.python

:: Tasks to run user tasks conveniently in the blue Status bar at the bottom
call %CODE_FULLPATH% --force --install-extension actboy168.tasks

:: Hex Editor support
call %CODE_FULLPATH% --force --install-extension ms-vscode.hexeditor

:: Optional: TabNine AI auto completion similar to IntelliSense
call %CODE_FULLPATH% --force --install-extension TabNine.tabnine-vscode

:: node.js support
call %CODE_FULLPATH% --force --install-extension waderyan.nodejs-extension-pack

:: Verilog support
:: Reference: https://github.com/mshr-h/vscode-verilog-hdl-support
call %CODE_FULLPATH% --force --install-extension mshr-h.veriloghdl

:: HTML
call %CODE_FULLPATH% --force --install-extension formulahendry.auto-complete-tag

:: ES6 - JavaScript/TypeScript
call %CODE_FULLPATH% --force --install-extension Tobermory.es6-string-html

:endInstall
:: Delete VS Code Installer and ignore error
del %VSCODE_INSTALLER% > nul 2>&1

echo Exiting Installation Script...
exit /b %ERROR_RETURN%

:failInstall
set ERROR_RETURN=1
goto endInstall