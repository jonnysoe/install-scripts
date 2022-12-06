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
set CHROME_INSTALLER=ChromeSetup.exe
set GIT_INSTALLER=GitSetup.exe
set VSCODE_INSTALLER=VSCodeSetup.exe
set MSYS2_INSTALLER=msys2.exe

:: Common fullpaths
:: fresh installation with registry update will no be reflected in current cmd session
:: Rerunning this script will not have new PATH included
set SZ_FULLPATH=%PROGRAMFILES%\7-Zip
set ARIA2_FULLPATH=%PROGRAMFILES%\aria2
set SZ_EXE=%SZ_FULLPATH%\7z.exe
set ARIA2_EXE=%ARIA2_FULLPATH%\aria2c.exe

:: ===================================================================
:: Start of 7-Zip Installation
:: ===================================================================
:check7z

:: 7z fullpath exists, 7z has been installed, so skip
if exist %SZ_EXE% goto checkAria2

:: Skip to install if installer already exist
if exist %SZ_INSTALLER% goto install7z

:download7z
echo Downloading 7-Zip...
curl -L -o %SZ_INSTALLER% "https://www.7-zip.org/a/7z2201-x64.msi"

:install7z
MsiExec.exe /i %SZ_INSTALLER% /qn

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:: Add to PATH environment variable
setx /m PATH "%PATH%;%SZ_FULLPATH%"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:: ===================================================================
:: Start of aria2 Installation
:: ===================================================================
:checkAria2

:: aria2 fullpath exists, aria2 has been installed, so skip
if exist "%ARIA2_EXE%" goto checkChrome

:: Skip to install if installer already exist
if exist %ARIA2_INSTALLER% goto installAria2

:downloadAria2
echo Downloading aria2...
curl -L -o %ARIA2_INSTALLER% "https://github.com/aria2/aria2/releases/download/release-1.36.0/aria2-1.36.0-win-64bit-build1.zip"

:installAria2
MsiExec.exe /i %ARIA2_INSTALLER% /qn
call "%SZ_EXE%" e %ARIA2_INSTALLER% -o"%PROGRAMFILES%\aria2"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:: Add to PATH environment variable
setx /m PATH "%PATH%;%ARIA2_FULLPATH%"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:: ===================================================================
:: Start of Chrome Installation
:: ===================================================================
:checkChrome

set CHROME_EXE=%PROGRAMFILES%\Google\Chrome\Application\chrome.exe

:: aria2 fullpath exists, aria2 has been installed, so skip
if exist "%CHROME_EXE%" goto checkGit

:: Skip to install if installer already exist
if exist %CHROME_INSTALLER% goto installChrome

:downloadChrome
echo Downloading Google Chrome...
call "%ARIA2_EXE%" -o %CHROME_INSTALLER% "https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7B52B94939-B32C-7286-0CE9-69EEDAE2F130%7D%26lang%3Den%26browser%3D3%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dprefers%26ap%3Dx64-stable-statsdef_1%26installdataindex%3Dempty/chrome/install/ChromeStandaloneSetup64.exe"

:installChrome
:: https://silentinstallhq.com/google-chrome-exe-silent-install-how-to-guide/
call %CHROME_INSTALLER% /silent /install

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:: Chrome will install in the background, do not babysit it, move on

:: ===================================================================
:: Start of Git Installation
:: ===================================================================
:checkGit
:: Check for Git installation
where git > nul 2>&1

:: No error, Git has been installed, so skip
if %ERRORLEVEL% equ 0 goto checkMsys2

set GIT_FULLPATH="C:\Program Files\Git\cmd\git.exe"

:: git fullpath exists, git has been installed, so skip
if exist %GIT_FULLPATH% goto checkMsys2

:: Skip to install if installer already exist
if exist %GIT_INSTALLER% goto installGit

:downloadGit
echo Downloading Git...
call "%ARIA2_EXE%" -o %GIT_INSTALLER% "https://github.com/git-for-windows/git/releases/download/v2.36.1.windows.1/Git-2.36.1-64-bit.exe"

:: Fail if download fails
if %ERRORLEVEL% neq 0 goto failInstall
if not exist %GIT_INSTALLER% goto failInstall

:installGit
echo Installing Git...
call %GIT_INSTALLER% /VERYSILENT /NORESTART

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:: ===================================================================
:: Start of MSYS2 Installation
:: ===================================================================
:checkMsys2
set MSYS2_FULLPATH="C:\msys64"

:: MSYS2 fullpath exists, MSYS2 has been installed, so skip
if exist %MSYS2_FULLPATH% goto checkVscode

:: Skip to install if installer already exist
if exist %MSYS2_INSTALLER% goto installMsys2

:downloadMsys2
echo Downloading MSYS2...
call "%ARIA2_EXE%" -o %MSYS2_INSTALLER% https://github.com/msys2/msys2-installer/releases/download/2022-10-28/msys2-x86_64-20221028.exe

:installMsys2
:: https://silentinstallhq.com/msys2-silent-install-how-to-guide/
call %MSYS2_INSTALLER% install --root %MSYS2_FULLPATH% --confirm-command

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:: Add to PATH environment variable
setx /m PATH "%PATH%;%MSYS2_FULLPATH%\usr\bin"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

:: Install MinGW and dependencies for MSYS2
set MSYSTEM=MSYS && C:\msys64\usr\bin\bash --login -c "pacman -S --noconfirm mingw-w64-x86_64-ccache mingw-w64-x86_64-cmake mingw-w64-x86_64-dlfcn mingw-w64-x86_64-eigen3 mingw-w64-x86_64-gcc mingw-w64-x86_64-make mingw-w64-x86_64-ninja mingw-w64-x86_64-zlib msys2-runtime-devel bison flex git pkgconf unzip"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

set MSYSTEM=MSYS && c:\msys64\usr\bin\bash --login -c "ln -s /usr/lib/librt.a /mingw64/lib"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

set MSYSTEM=MSYS && c:\msys64\usr\bin\bash --login -c "echo \"export PATH=\$PATH:/mingw64/bin\" >> ~/.bashrc"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

set MSYSTEM=MSYS && c:\msys64\usr\bin\bash --login -c "ssh-keygen -q -t rsa -N '' <<< \"\"$'\n'\"y\" 2>&1 >/dev/null"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall

echo Add SSH key, eg:
echo https://github.com/settings/ssh/new
echo https://gitlab.com/-/profile/keys
echo ================================================================================
set MSYSTEM=MSYS && c:\msys64\usr\bin\bash --login -c "cat ~/.ssh/id_rsa.pub"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 goto failInstall
echo ================================================================================

:: ===================================================================
:: Start of VS Code Installation
:: ===================================================================
:checkVscode
:: Check for VS Code installation
where code > nul 2>&1

:: No error, VS Code has been installed, so skip to install extention
if %ERRORLEVEL% equ 0 goto installExtension

set CODE_FULLPATH="C:\Program Files\Microsoft VS Code\bin\code"

:: code fullpath exists, VS Code has been installed, so skip to install extention
if exist %CODE_FULLPATH% goto installExtension

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
	rem unsupported architecture, eg. Intel Itanium
	goto failInstall
)

:: Fail if download fails
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

:: Copy vscode to Quick Launch
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

:: https://www.howtogeek.com/198815/use-this-secret-trick-to-close-and-restart-explorer.exe-in-windows/
echo Restarting Windows Explorer to reload new configurations...
taskkill /f /IM explorer.exe && start explorer

popd

echo Exiting Installation Script...
exit /b %ERROR_RETURN%

:failInstall
set ERROR_RETURN=1
goto endInstall

:failAdmin
echo Not running as administrator
set ERROR_RETURN=21
goto endInstall
