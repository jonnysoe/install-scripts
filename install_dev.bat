@echo off

pushd %USERPROFILE%\Downloads

set ERROR_RETURN=0

:: Check if running as Administrator
:: https://stackoverflow.com/a/11995662/19336104
net session >nul 2>&1

:: Fail if not running as Administrator
if %ERRORLEVEL% neq 0 goto failAdmin

:: Installer paths
:: NOTE: %7 is an input in batch script, so using 'S' to indicate '7' in "7-Zip"
set SZ_INSTALLER=7z.msi
set ARIA2_INSTALLER=aria2.zip
set GIT_INSTALLER=GitSetup.exe
set MSVC_INSTALLER=vs_BuildTools.exe
set PYTHON_INSTALLER=python-amd64.exe
set NODEJS_INSTALLER=node-x64.msi
set VSCODE_INSTALLER=VSCodeSetup.exe
set MSYS2_INSTALLER=msys2.exe
set OVPN_INSTALLER=openvpn.msi

:: Common fullpaths
:: fresh installation with registry update will no be reflected in current cmd session
:: Rerunning this script will not have new PATH included
set SZ_FULLPATH=%PROGRAMFILES%\7-Zip
set ARIA2_FULLPATH=%PROGRAMFILES%\aria2
set PTTB_FULLPATH=%PROGRAMFILES%\pttb
:: Do not use 3.11, there is a module bug requiring MSVC, which should never be the case with Python modules
set PYTHON_PATH=Python310
set PYTHON_FULLPATH=%PROGRAMFILES%\%PYTHON_PATH%
set PIP_FULLPATH=%PYTHON_FULLPATH%\Scripts
set NODEJS_FULLPATH=%PROGRAMFILES%\nodejs
set SZ_EXE=%SZ_FULLPATH%\7z.exe
set ARIA2_EXE=%ARIA2_FULLPATH%\aria2c.exe
set PTTB_EXE=%PTTB_FULLPATH%\pttb.exe
set PYTHON_EXE=%PYTHON_FULLPATH%\python.exe
set PIP_EXE=%PIP_FULLPATH%\pip.exe
set CODE_EXE=C:\Program Files\Microsoft VS Code\bin\code

:: ===================================================================
:: Start of 7-Zip Installation
:: ===================================================================
:check7z

:: 7z fullpath exists, 7z has been installed, so skip
if exist "%SZ_EXE%" goto end7z

:: Skip to install if installer already exist
if exist %SZ_INSTALLER% goto install7z

:download7z
echo Downloading 7-Zip...
curl -L -o %SZ_INSTALLER% "https://www.7-zip.org/a/7z2201-x64.msi"

:: Fail if download fails
if %ERRORLEVEL% neq 0 goto failInstall

:install7z
start /wait MsiExec.exe /i %SZ_INSTALLER% /qn

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:: Add to PATH environment variable
setx /m PATH "%PATH%;%SZ_FULLPATH%"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:end7z

:: ===================================================================
:: Start of aria2 Installation
:: ===================================================================
:checkAria2

:: aria2 fullpath exists, aria2 has been installed, so skip
if exist "%ARIA2_EXE%" goto endAria2

:: Skip to install if installer already exist
if exist %ARIA2_INSTALLER% goto installAria2

:downloadAria2
echo Downloading aria2...
curl -L -o %ARIA2_INSTALLER% "https://github.com/aria2/aria2/releases/download/release-1.36.0/aria2-1.36.0-win-64bit-build1.zip"

:: Fail if download fails
if %ERRORLEVEL% neq 0 goto failInstall

:installAria2
start /wait MsiExec.exe /i %ARIA2_INSTALLER% /qn
call "%SZ_EXE%" e %ARIA2_INSTALLER% -o"%PROGRAMFILES%\aria2"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:: Add to PATH environment variable
setx /m PATH "%PATH%;%ARIA2_FULLPATH%"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:endAria2

:: ===================================================================
:: Start of Pin to TaskBar Installation
:: ===================================================================
:checkPttb

:: aria2 fullpath exists, aria2 has been installed, so skip
if exist "%PTTB_EXE%" goto endPttb

:: Skip to install if installer already exist
if exist %PTTB_INSTALLER% goto installPttb

:: Make directory if it doesn't exist
if exist "%PTTB_FULLPATH%" goto downloadPttb
mkdir "%PTTB_FULLPATH%"

:downloadPttb
echo Downloading Pin To Taskbar...
call "%ARIA2_EXE%" -d "%PTTB_FULLPATH%" "https://github.com/0x546F6D/pttb_-_Pin_To_TaskBar/raw/main/pttb.exe"

:: Fail if download fails
if %ERRORLEVEL% neq 0 goto failInstall

:: Add to PATH environment variable
setx /m PATH "%PATH%;%PTTB_FULLPATH%"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:endPttb

:: ===================================================================
:: Start of Git Installation
:: ===================================================================
:checkGit

:: Latest MSYS2 is having compatibility issue with Git for Windows
goto endGit

set GIT_EXE="C:\Program Files\Git\cmd\git.exe"

:: git fullpath exists, git has been installed, so skip
if exist %GIT_EXE% goto endGit

:: Skip to install if installer already exist
if exist %GIT_INSTALLER% goto installGit

:downloadGit
echo Downloading Git...
:: https://github.com/git-for-windows/git/releases/latest
call "%ARIA2_EXE%" -o %GIT_INSTALLER% "https://github.com/git-for-windows/git/releases/download/v2.38.1.windows.1/Git-2.38.1-64-bit.exe"

:: Fail if download fails
if %ERRORLEVEL% neq 0 goto failInstall

:installGit
echo Installing Git...
call %GIT_INSTALLER% /VERYSILENT /NORESTART

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:endGit

:: ===================================================================
:: Start of Microsoft C++ Build Tools Installation
:: ===================================================================
:checkMsvc
goto endMsvc

set MSVC_FULLPATH=%PROGRAMFILES%\Microsoft Visual Studio

:: MSVC fullpath exists, git has been installed, so skip
if exist %MSVC_FULLPATH% goto endMsvc

:: Skip to install if installer already exist
if exist %MSVC_INSTALLER% goto installMsvc

:downloadMsvc
echo Downloading Microsoft C++ Build Tools...
call "%ARIA2_EXE%" -o %MSVC_INSTALLER% "https://aka.ms/vs/17/release/vs_BuildTools.exe"

:: Fail if download fails
if %ERRORLEVEL% neq 0 goto failInstall

:installMsvc
:: https://dimitri.janczak.net/2018/10/22/visual-c-build-tools-silent-installation/
:: https://learn.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio?view=vs-2019
:: Let this run in the background, add "--wait" if there are MSVC dependencies in the future
%MSVC_INSTALLER% --layout .\vs_buildtools --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --includeOptional --quiet --norestart

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:endMsvc

:: ===================================================================
:: Start of Python Installation
:: ===================================================================
:checkPython

:: Python fullpath exists, git has been installed, so skip
if exist "%PYTHON_EXE%" goto configPython

:: Skip to install if installer already exist
if exist %PYTHON_INSTALLER% goto installPython

:downloadPython
echo Downloading Python...
:: https://www.python.org/downloads/windows/
call "%ARIA2_EXE%" -o %PYTHON_INSTALLER% "https://www.python.org/ftp/python/3.10.9/python-3.10.9-amd64.exe"

:: Fail if download fails
if %ERRORLEVEL% neq 0 goto failInstall

:installPython
echo Installing Python...
call %PYTHON_INSTALLER% /quiet InstallAllUsers=1 PrependPath=1 AssociateFiles=1

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:configPython
:: There is a bug in Python310 where PrependPath doesn't work
:: Always check for the PATH environment variable from registry for the latest values
:: https://social.technet.microsoft.com/Forums/en-US/fed3975d-e1cf-4633-a37b-4e0948ac8eae/source-locations-for-path-variable-entries
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v "Path" | findstr /i "Python" > nul

:: Append to PATH variable if missing
if %ERRORLEVEL% neq 0 setx /m PATH "%PATH%;%PYTHON_FULLPATH%;%PIP_FULLPATH%"

:: Fail if append fails
if %ERRORLEVEL% neq 0 goto failInstall

:endPython

:: ===================================================================
:: Start of Nodejs Installation
:: ===================================================================
:checkNodejs

:: Nodejs fullpath exists, Nodejs has been installed, so skip
if exist "%NODEJS_FULLPATH%" goto configNodejs

:: Skip to install if installer already exist
if exist %NODEJS_INSTALLER% goto installNodejs

:downloadNodejs
echo Downloading Nodejs...
call "%ARIA2_EXE%" -o %NODEJS_INSTALLER% "https://nodejs.org/download/release/v16.18.1/node-v16.18.1-x64.msi"

:: Fail if download fails
if %ERRORLEVEL% neq 0 goto failInstall

:installNodejs
:: https://silentinstallhq.com/node-js-silent-install-how-to-guide/
start /wait MsiExec.exe /i %NODEJS_INSTALLER% /qn

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:configNodejs
echo Configuring Nodejs...

:: Allow script execution
PowerShell -Command "Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force"

:: Install Global Node Modules (ignore errors)
:: NOTE:
:: - Need to add "call" as npm/npx will invoke another process, executing them without "call" will not return control
::   https://stackoverflow.com/a/42306073/19336104
:: - Do not add yo and generator-code as they will invoke another process which will call Node with outdated PATH
set PATH=%PATH%;%NODEJS_FULLPATH%
call npm install -g yarn npm@latest
call npx yarn global add @vscode/vsce

:endNodejs

:: ===================================================================
:: Start of MSYS2 Installation
:: ===================================================================
:checkMsys2
set MSYS2_FULLPATH="C:\msys64"

:: MSYS2 fullpath exists, MSYS2 has been installed, so skip
if exist %MSYS2_FULLPATH% goto configMsys2

:: Skip to install if installer already exist
if exist %MSYS2_INSTALLER% goto installMsys2

:downloadMsys2
echo Downloading MSYS2...
call "%ARIA2_EXE%" -o %MSYS2_INSTALLER% "https://github.com/msys2/msys2-installer/releases/download/2022-10-28/msys2-x86_64-20221028.exe"

:: Fail if download fails
if %ERRORLEVEL% neq 0 goto failInstall

:installMsys2
:: https://silentinstallhq.com/msys2-silent-install-how-to-guide/
call %MSYS2_INSTALLER% install --root %MSYS2_FULLPATH% --confirm-command

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:: Add to PATH environment variable
:: NOTE: the bin paths contain the necessary DLLs to be loaded at runtime
setx /m PATH "%PATH%;%MSYS2_FULLPATH%\usr\bin;%MSYS2_FULLPATH%\mingw64\bin"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:configMsys2
echo Configuring MSYS2...

:: Install MinGW and dependencies for MSYS2
set MSYSTEM=MSYS
%MSYS2_FULLPATH%\usr\bin\bash --login -c "pacman -S --noconfirm --needed mingw-w64-x86_64-ccache mingw-w64-x86_64-cmake mingw-w64-x86_64-dlfcn mingw-w64-x86_64-eigen3 mingw-w64-x86_64-gcc mingw-w64-x86_64-make mingw-w64-x86_64-ninja mingw-w64-x86_64-zlib msys2-runtime-devel bison flex git make pkgconf unzip"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:: Add /mingw64/bin to PATH variable
%MSYS2_FULLPATH%\usr\bin\bash --login -c "[[ -n \"`grep mingw64 ~/.bashrc`\" ]] || echo \"export PATH=\$PATH:/mingw64/bin\" >> ~/.bashrc"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:: Symlink librt.a
%MSYS2_FULLPATH%\usr\bin\bash --login -c "[[ -f /mingw64/lib/librt.a ]] || ln -s /usr/lib/librt.a /mingw64/lib"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:: Symlink Py.exe
%MSYS2_FULLPATH%\usr\bin\bash --login -c "[[ -f /usr/bin/python ]] || ln -s /c/Windows/py.exe /usr/bin/python"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:: Symlink Py.exe
%MSYS2_FULLPATH%\usr\bin\bash --login -c "[[ -f /usr/bin/python3 ]] || ln -s /c/Windows/py.exe /usr/bin/python3"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:: Symlink pip.exe
%MSYS2_FULLPATH%\usr\bin\bash --login -c "[[ -f /usr/bin/pip ]] || ln -s /c/Program\ Files/Python310/Scripts/pip.exe /usr/bin/pip"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:: Generate SSH Key
%MSYS2_FULLPATH%\usr\bin\bash --login -c "[[ -f ~/.ssh/id_rsa.pub ]] || ssh-keygen -q -t rsa -N '' <<< \"\"$'\n'\"y\" 2>&1 >/dev/null"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:: Symlink directories in MSYS2 to Windows' (Git Bash) user directory to share directories
:: NOTE: This needs to be Windows' symlink to be visible in Windows
mklink /D "%USERPROFILE%\.ssh" "%MSYS2_FULLPATH%\home\%USERNAME%\.ssh" > nul 2>&1
mkdir "%MSYS2_FULLPATH%\home\%USERNAME%\_dev" > nul 2>&1
mklink /D "%USERPROFILE%\_dev" "%MSYS2_FULLPATH%\home\%USERNAME%\_dev" > nul 2>&1

:endMsys2

:: ===================================================================
:: Start of VS Code Installation
:: ===================================================================
:checkVscode

:: code fullpath exists, VS Code has been installed, so skip to install extention
if exist "%CODE_EXE%" goto installExtension

:: Skip to install if installer already exist
if exist %VSCODE_INSTALLER% goto installVscode

:downloadVscode
echo Downloading VS Code...

:: Detect OS architecture and download accordingly
:: https://docs.microsoft.com/en-us/windows/win32/winprog64/wow64-implementation-details
if /i %PROCESSOR_ARCHITECTURE%==AMD64 (
    call "%ARIA2_EXE%" -o %VSCODE_INSTALLER% "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"
) else if /i %PROCESSOR_ARCHITECTURE%==x86 (
    call "%ARIA2_EXE%" -o %VSCODE_INSTALLER% "https://code.visualstudio.com/sha/download?build=stable&os=win32"
) else if /i %PROCESSOR_ARCHITECTURE%==ARM64 (
    call "%ARIA2_EXE%" -o %VSCODE_INSTALLER% "https://code.visualstudio.com/sha/download?build=stable&os=win32-arm64"
) else (
    echo unsupported architecture for VS Code, eg. Intel Itanium
    goto failInstall
)

:: Fail if download fails
if %ERRORLEVEL% neq 0 goto failInstall

:installVscode
echo Installing VS Code...
:: https://github.com/Microsoft/vscode/blob/main/build/win32/code.iss#L76-L97
:: runcode will be enabled by default, so disable it VS Code will pop out
:: addcontextmenufolders optionally added so that projects/folders can be easily opened
call %VSCODE_INSTALLER% /VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufolders

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:: Pin vscode to Taskbar and Quick Launch
"%PTTB_EXE%" "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Visual Studio Code\Visual Studio Code.lnk"
copy "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Visual Studio Code\Visual Studio Code.lnk" "%AppData%\Microsoft\Internet Explorer\Quick Launch\"

:editSettings
set VSCODE_SETTINGS_DIR=%APPDATA%\Code\User
mkdir %VSCODE_SETTINGS_DIR% > nul 2>&1

set VSCODE_SETTINGS=%VSCODE_SETTINGS_DIR%\settings.json

:: file doesn't exist, touch file
if not exist %VSCODE_SETTINGS% (
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
    echo     "editor.renderWhitespace": "all",
    echo     "terminal.integrated.defaultProfile.windows": "Command Prompt",
    echo     "terminal.integrated.profiles.windows": {
    echo         "MSYS - MSYS2": {
    echo             "path": "C:/msys64/usr/bin/bash.exe",
    echo             "args": [
    echo                 "--login",
    echo                 "-i"
    echo             ],
    echo             "env": {
    echo                 "MSYSTEM": "MSYS",
    echo                 "CHERE_INVOKING": "1"
    echo             }
    echo         }
    echo     },
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

:: @todo temporarily skip individual settings for now
goto installExtension

>nul findstr /C:"workbench.editorAssociations" %VSCODE_SETTINGS% || (
    rem ///@todo use jq to update settings.json
)

>nul findstr /C:"editor.rules" %VSCODE_SETTINGS% || (
    rem ///@todo use jq to update settings.json
)

:installExtension
:: No error exit, nothing is fatal here

:: GitLens for Git convenience
call "%CODE_EXE%" --force --install-extension eamodio.gitlens

:: Git Graph for Git tree view
call "%CODE_EXE%"  --force --install-extension mhutchie.git-graph

:: MS C/C++ Language support
call "%CODE_EXE%" --force --install-extension ms-vscode.cpptools-extension-pack
call "%CODE_EXE%" --force --install-extension VisualStudioExptTeam.vscodeintellicode

:: CMake Language support
:: call "%CODE_EXE%" --force --install-extension twxs.cmake

:: CMake Tool for Build and Run
:: call "%CODE_EXE%" --force --install-extension ms-vscode.cmake-tools

:: LLDB support
call "%CODE_EXE%" --force --install-extension vadimcn.vscode-lldb

:: Google proto3 support
call "%CODE_EXE%" --force --install-extension zxh404.vscode-proto3

:: Python Language support
call "%CODE_EXE%" --force --install-extension ms-toolsai.jupyter
call "%CODE_EXE%" --force --install-extension ms-python.python

:: Tasks to run user tasks conveniently in the blue Status bar at the bottom
call "%CODE_EXE%" --force --install-extension actboy168.tasks

:: Hex Editor support
call "%CODE_EXE%" --force --install-extension ms-vscode.hexeditor

:: Optional: TabNine AI auto completion similar to IntelliSense
call "%CODE_EXE%" --force --install-extension TabNine.tabnine-vscode

:: node.js support
call "%CODE_EXE%" --force --install-extension waderyan.nodejs-extension-pack

:: Verilog support
:: Reference: https://github.com/mshr-h/vscode-verilog-hdl-support
call "%CODE_EXE%" --force --install-extension mshr-h.veriloghdl

:: HTML
call "%CODE_EXE%" --force --install-extension formulahendry.auto-complete-tag

:: ES6 - JavaScript/TypeScript
call "%CODE_EXE%" --force --install-extension Tobermory.es6-string-html

:: ===================================================================
:: Start of OpenVPN Installation
:: ===================================================================
:checkOvpn

set OVPN_EXE="%PROGRAMFILES%\OpenVPN\bin\openvpn-gui.exe"

:: git fullpath exists, git has been installed, so skip
if exist %OVPN_EXE% goto endOvpn

:: Skip to install if installer already exist
if exist %OVPN_INSTALLER% goto installOvpn

:downloadOvpn
echo Downloading OpenVPN...
:: https://openvpn.net/community-downloads/
call "%ARIA2_EXE%" -o %OVPN_INSTALLER% "https://swupdate.openvpn.org/community/releases/OpenVPN-2.5.8-I604-amd64.msi"

:: Fail if download fails
if %ERRORLEVEL% neq 0 goto failInstall

:installOvpn
echo Installing OpenVPN...
start /wait MsiExec.exe /i %OVPN_INSTALLER% /qn

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:endOvpn

:: ===================================================================
:: Display SSH key
:: ===================================================================
:displaySshKey
echo.
echo Add SSH key, eg:
echo https://github.com/settings/ssh/new
echo https://gitlab.com/-/profile/keys
echo ================================================================================
type %MSYS2_FULLPATH%\home\%USERNAME%\.ssh\id_rsa.pub
echo ================================================================================

:: ===================================================================
:: End of Installation
:: ===================================================================
:endInstall
:: Delete Installers and ignore error
del %SZ_INSTALLER% > nul 2>&1
del %ARIA2_INSTALLER% > nul 2>&1
del %GIT_INSTALLER% > nul 2>&1
del %VSCODE_INSTALLER% > nul 2>&1
del %MSYS2_INSTALLER% > nul 2>&1
del %OVPN_INSTALLER% > nul 2>&1

popd

echo Exiting Installation Script...
exit /b %ERROR_RETURN%

:failInstall
set ERROR_RETURN=1
goto endInstall

:failAdmin
echo Not running as administrator
set ERROR_RETURN=2
goto endInstall
