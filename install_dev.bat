@echo off

set ERROR_RETURN=0

:: Installer paths
:: NOTE: %7 is an input in batch script, so using 'S' to indicate '7' in "7-Zip"
set SZ_INSTALLER=7z.msi
set ARIA2_INSTALLER=aria2.zip
set GIT_INSTALLER=GitSetup.exe
set MSVC_INSTALLER=vs_BuildTools.exe
set LLVM_INSTALLER=LLVM-win64.exe
set CMAKE_INSTALLER=cmake-windows.msi
set NINJA_INSTALLER=ninja-win.zip
set CCACHE_INSTALLER=ccache-x86_64.zip
set MAKE_INSTALLER=make.exe
set PYTHON_INSTALLER=python-amd64.exe
set NODEJS_INSTALLER=node-x64.msi
set VSCODE_INSTALLER=VSCodeSetup.exe
set MSYS2_INSTALLER=msys2.exe
set OVPN_INSTALLER=openvpn.msi

:: Common fullpaths
:: fresh installation with registry update will no be reflected in current cmd session
:: Rerunning this script will not have new PATH included
set SZ_FULLPATH=%ProgramFiles%\7-Zip
set ARIA2_FULLPATH=%ProgramFiles%\aria2
set PTTB_FULLPATH=%ProgramFiles%\pttb
:: Do not use 3.11, there is a module bug requiring MSVC, which should never be the case with Python modules
set PYTHON_PATH=Python310
set PYTHON_FULLPATH=%ProgramFiles%\%PYTHON_PATH%
set PIP_FULLPATH=%PYTHON_FULLPATH%\Scripts
set NODEJS_FULLPATH=%ProgramFiles%\nodejs
set SZ_EXE=%SZ_FULLPATH%\7z.exe
set ARIA2_EXE=%ARIA2_FULLPATH%\aria2c.exe
set PTTB_EXE=%PTTB_FULLPATH%\pttb.exe
set PYTHON_EXE=%PYTHON_FULLPATH%\python.exe
set PIP_EXE=%PIP_FULLPATH%\pip.exe
set CODE_EXE=%ProgramFiles%\Microsoft VS Code\bin\code

pushd %USERPROFILE%\Downloads
call:installAll
set ERROR_RETURN=%ERRORLEVEL%
if %ERROR_RETURN%==0 (
    call:displaySshKey
    call:deleteInstallers
)
popd
echo Exiting Installation Script...
exit /b %ERROR_RETURN%

:: ===================================================================
:: Start of main installation for all
:: ===================================================================
:installAll
call:checkAdmin
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

call:installConfig7z
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

call:installConfigAria2
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

call:installConfigPttb
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

call:installConfigMsvc
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

call:installConfigLlvm
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

call:installConfigCmake
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

call:installConfigNinja
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

call:installConfigCcache
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

call:installConfigMake
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

call:installConfigPkgconf
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

call:installConfigPthreads
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

call:installConfigZlib
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

call:installConfigPython
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

call:installConfigNodejs
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

call:installConfigMsys2
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

call:installConfigVscode
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

call:installConfigOvpn
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

exit /b %ERRORLEVEL%

:: ===================================================================
:: Start of 7-Zip Installation
:: ===================================================================
:installConfig7z
if not exist "%SZ_EXE%" call:install7z

:: Fail if installation fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:config7z
:: Add to PATH environment variable
call:appendPath %%%%ProgramFiles%%%%\7-Zip

exit /b %ERRORLEVEL%

:install7z
:: Download
echo Downloading 7-Zip . . .
call:download "https://www.7-zip.org/a/7z2201-x64.msi" %SZ_INSTALLER%

:: Fail if download fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Install
echo Installing 7-Zip . . .
start /wait MsiExec.exe /i %SZ_INSTALLER% /qn

exit /b %ERRORLEVEL%

:: ===================================================================
:: Start of aria2 Installation
:: ===================================================================
:installConfigAria2
if not exist "%ARIA2_EXE%" call:installAria2

:: Fail if installation fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:configAria2
:: Add to PATH environment variable
call:appendPath %%%%ProgramFiles%%%%\aria2

exit /b %ERRORLEVEL%

:installAria2

:: Download
echo Downloading aria2 . . .
call:download "https://github.com/aria2/aria2/releases/download/release-1.36.0/aria2-1.36.0-win-64bit-build1.zip" %ARIA2_INSTALLER%

:: Fail if download fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Install
echo Installing aria2 . . .
call "%SZ_EXE%" x %ARIA2_INSTALLER% -o"%ARIA2_FULLPATH%"

exit /b %ERRORLEVEL%

:: ===================================================================
:: Start of Pin to TaskBar Installation
:: ===================================================================
:installConfigPttb
if not exist "%PTTB_EXE%" call:installPttb

:: Fail if installation fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:configPttb
:: Add to PATH environment variable
call:appendPath %%%%ProgramFiles%%%%\pttb

exit /b %ERRORLEVEL%

:installPttb

:: Make directory if it doesn't exist
if not exist "%PTTB_FULLPATH%" mkdir "%PTTB_FULLPATH%"

:: Download
echo Downloading Pin To Taskbar . . .
call:download "https://github.com/0x546F6D/pttb_-_Pin_To_TaskBar/raw/main/pttb.exe" pttb.exe -d "%PTTB_FULLPATH%"

exit /b %ERRORLEVEL%

:: ===================================================================
:: Start of Git Installation
:: ===================================================================
:installConfigGit

set GIT_EXE=%ProgramFiles%\Git\cmd\git.exe

if not exist "%GIT_EXE%" call:installGit

:: Fail if installation fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:configGit
:: Add to PATH environment variable
call:appendPath %%%%ProgramFiles%%%%\Git\cmd

exit /b %ERRORLEVEL%

:installGit
:: Download
:: https://github.com/git-for-windows/git/releases/latest
echo Downloading Git . . .
call:download "https://github.com/git-for-windows/git/releases/download/v2.38.1.windows.1/Git-2.38.1-64-bit.exe" %GIT_INSTALLER%

:: Fail if download fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:installGit
echo Installing Git . . .
call %GIT_INSTALLER% /VERYSILENT /NORESTART

exit /b %ERRORLEVEL%

:: ===================================================================
:: Start of Microsoft C++ Build Tools Installation
:: ===================================================================
:installConfigMsvc

set MSVC_FULLPATH=%ProgramFiles(x86)%\Microsoft Visual Studio

if not exist "%MSVC_FULLPATH%" call:installMsvc

:configMsvc
:: Nothing to configure for now

exit /b %ERRORLEVEL%

:installMsvc

:: Download if not installed
echo Downloading Microsoft C++ Build Tools...
call:download "https://aka.ms/vs/17/release/vs_BuildTools.exe" %MSVC_INSTALLER%

:: Fail if download fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Install
:: https://dimitri.janczak.net/2018/10/22/visual-c-build-tools-silent-installation/
:: https://learn.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio?view=vs-2019
:: MSVC and Windows SDK is required for LLVM
echo Installing Microsoft C++ Build Tools...
call %MSVC_INSTALLER% --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --includeOptional --passive --norestart --wait

exit /b %ERRORLEVEL%

:: ===================================================================
:: Start of LLVM Installation
:: ===================================================================
:installConfigLlvm

set LLVM_FULLPATH=%ProgramFiles%\LLVM\bin

if not exist "%LLVM_FULLPATH%\clang++.exe" call:installLlvm

:: Fail if installation fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:configLlvm
:: Add to PATH environment variable
call:appendPath %%%%ProgramFiles%%%%\LLVM\bin

exit /b %ERRORLEVEL%

:installLlvm

:: Download
:: https://github.com/llvm/llvm-project/releases/latest
echo Downloading LLVM . . .
call:download "https://github.com/llvm/llvm-project/releases/download/llvmorg-15.0.6/LLVM-15.0.6-win64.exe" %LLVM_INSTALLER%

:: Fail if download fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Install
:: https://silentinstallhq.com/llvm-silent-install-how-to-guide/
echo Installing LLVM . . .
call %LLVM_INSTALLER% /S

exit /b %ERRORLEVEL%

:: ===================================================================
:: Start of CMake Installation
:: ===================================================================
:installConfigCmake

set CMAKE_FULLPATH=%ProgramFiles%\CMake\bin

if not exist "%CMAKE_FULLPATH%\cmake.exe" call:installCmake

:: Fail if installation fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:configCmake
:: Add to PATH environment variable
call:appendPath %%%%ProgramFiles%%%%\CMake\bin

exit /b %ERRORLEVEL%

:installCmake

:: Download if not installed
:: https://github.com/Kitware/CMake/releases/latest
echo Downloading CMake . . .
call:download "https://github.com/Kitware/CMake/releases/download/v3.25.1/cmake-3.25.1-windows-x86_64.msi" %CMAKE_INSTALLER%

:: Fail if download fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Install
:: https://silentinstallhq.com/cmake-silent-install-how-to-guide/
echo Installing CMake . . .
start /wait MsiExec.exe /i %CMAKE_INSTALLER% /qn

exit /b %ERRORLEVEL%

:: ===================================================================
:: Start of Ninja Installation
:: ===================================================================
:installConfigNinja

set NINJA_FULLPATH=%ProgramFiles%\Ninja

if not exist "%NINJA_FULLPATH%\ninja.exe" call:installNinja

:: Fail if installation fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:configNinja
:: Add to PATH environment variable
call:appendPath %%%%ProgramFiles%%%%\Ninja

exit /b %ERRORLEVEL%

:installNinja

:: Download
:: https://github.com/ninja-build/ninja/releases/latest
echo Downloading Ninja . . .
call:download "https://github.com/ninja-build/ninja/releases/download/v1.11.1/ninja-win.zip" %NINJA_INSTALLER%

:: Fail if download fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Install
echo Installing Ninja . . .
call "%SZ_EXE%" x %NINJA_INSTALLER% -o"%NINJA_FULLPATH%"

exit /b %ERRORLEVEL%

:: ===================================================================
:: Start of Ccache Installation
:: ===================================================================
:installConfigCcache

set CCACHE_FULLPATH=%ProgramFiles%\Ccache

if not exist "%CCACHE_FULLPATH%\ccache.exe" call:installCcache

:: Fail if installation fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:configCcache
:: Add to PATH environment variable
call:appendPath %%%%ProgramFiles%%%%\Ccache

exit /b %ERRORLEVEL%

:installCcache

:: Download
:: https://github.com/ccache/ccache/releases/latest
echo Downloading Ccache . . .
call:download "https://github.com/ccache/ccache/releases/download/v4.7.4/ccache-4.7.4-windows-x86_64.zip" %CCACHE_INSTALLER%

:: Fail if download fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Install
echo Installing Ccache . . .
call "%SZ_EXE%" x %CCACHE_INSTALLER% -o"%CCACHE_FULLPATH%"

exit /b %ERRORLEVEL%

:: ===================================================================
:: Start of GNU Make Installation
:: ===================================================================
:installConfigMake

set MAKE_FULLPATH=%ProgramFiles(x86)%\GnuWin32\bin

if not exist "%MAKE_FULLPATH%\make.exe" call:installMake

:: Fail if installation fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:configMake
:: Add to PATH environment variable
call:appendPath %%%%ProgramFiles(x86)%%%%\GnuWin32\bin

:: Somehow (x86) path is buggy - does not exist
set ERRORLEVEL=0
exit /b 0

:installMake
:: https://gnuwin32.sourceforge.net/packages/make.htm
echo Downloading GNU Make . . .
call:download "https://jaist.dl.sourceforge.net/project/gnuwin32/make/3.81/make-3.81.exe" %MAKE_INSTALLER%

:: Fail if download fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Install
:: https://gnuwin32.sourceforge.net/setup.html
echo Installing GNU Make . . .
call %MAKE_INSTALLER% /SP- /VERYSILENT /NORESTART /SUPPRESSMSGBOXES /MERGETASKS="fileassoc"

exit /b %ERRORLEVEL%

:: ===================================================================
:: Start of pthreads4w Installation
:: ===================================================================
:installConfigPthreads

set PTHREADS_FULLPATH=%ProgramFiles%\pthreads

if not exist "%PTHREADS_FULLPATH%" call:installPthreads

:: Fail if installation fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:configPthreads
:: Add to PATH environment variable
call:appendPath %%%%ProgramFiles%%%%\pthreads

exit /b %ERRORLEVEL%

:installPthreads
echo Downloading pthreads . . .
call:download "https://github.com/jonnysoe/pthreads4w/archive/refs/heads/main.zip" pthreads4w.zip

:: Fail if download fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Install
echo Installing pthreads . . .

:: Build pthreads
pushd pthreads4w\pthreads4w-main
call compile.bat all install
popd

:: Failed to build pthreads
if not exist pthreads4w\PTHREADS-BUILT exit /b 1

:: Copy and rename
xcopy pthreads4w\PTHREADS-BUILT "%PTHREADS_FULLPATH%" /E /C /I /Q /Y

exit /b %ERRORLEVEL%

:: ===================================================================
:: Start of Zlib Installation
:: ===================================================================
:installConfigZlib

set ZLIB_FULLPATH=%ProgramFiles%\zlib

if not exist "%ZLIB_FULLPATH%" call:installZlib

:: Fail if installation fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:configZlib
:: Add to PATH environment variable
call:appendPath %%%%ProgramFiles%%%%\zlib

exit /b %ERRORLEVEL%

:installZlib

:: Download
echo Downloading Zlib . . .
call:download "http://www.winimage.com/zLibDll/zlib123.zip" zlib123.zip

:: Fail if download fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

call:download "http://www.winimage.com/zLibDll/zlib123dllx64.zip" zlib123dllx64.zip

:: Fail if download fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Install
echo Installing Zlib . . .
mkdir "%ProgramFiles%\zlib" > nul 2>&1
mkdir "%ProgramFiles%\zlib\include" > nul 2>&1
call "%SZ_EXE%" x zlib123.zip -o"%ProgramFiles%\zlib\include"
call "%SZ_EXE%" x zlib123dllx64.zip -o"%ProgramFiles%\zlib"
pushd "%ProgramFiles%\zlib\"
rename static_x64 lib
rename dll_x64 bin
popd

exit /b %ERRORLEVEL%

:: ===================================================================
:: Start of Python Installation
:: ===================================================================
:installConfigPython

if not exist "%PYTHON_EXE%" call:installPython

:: Fail if installation fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:configPython
:: Add to PATH environment variable
call:prependPath %%%%ProgramFiles%%%%\%PYTHON_PATH%

:: Fail if append fails
if %ERRORLEVEL% neq 0 goto failInstall

:: Add to PATH environment variable
call:prependPath %%%%ProgramFiles%%%%\%PYTHON_PATH%\Scripts

:: Fail if append fails
if %ERRORLEVEL% neq 0 goto failInstall

exit /b %ERRORLEVEL%

:installPython
:: Download
echo Downloading Python . . .
call:download "https://www.python.org/ftp/python/3.10.9/python-3.10.9-amd64.exe" %PYTHON_INSTALLER%

:: Fail if download fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Install
echo Installing Python . . .
call %PYTHON_INSTALLER% /quiet InstallAllUsers=1 PrependPath=1 AssociateFiles=1

exit /b %ERRORLEVEL%

:: ===================================================================
:: Start of Nodejs Installation
:: ===================================================================
:installConfigNodejs

if not exist "%NODEJS_FULLPATH%" call:installNodejs

:: Fail if installation fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:configNodejs
echo Configuring Nodejs . . .

:: Allow script execution
PowerShell -Command "Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force"

:: Add to PATH environment variable
call:appendPath %%%%ProgramFiles%%%%\nodejs

:: Fail if append fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Install Global Node Modules (ignore errors)
:: NOTE:
:: - Need to add "call" as npm/npx will invoke another process, executing them without "call" will not return control
::   https://stackoverflow.com/a/42306073/19336104
:: - Do not add yo and generator-code as they will invoke another process which will call Node with outdated PATH
call npm install -g yarn npm@latest
call npx yarn global add @vscode/vsce

exit /b %ERRORLEVEL%

:installNodejs
:: Download
echo Downloading Nodejs . . .
call:download "https://nodejs.org/download/release/v16.18.1/node-v16.18.1-x64.msi" %NODEJS_INSTALLER%

:: Fail if download fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Install
:: https://silentinstallhq.com/node-js-silent-install-how-to-guide/
echo Installing Nodejs . . .
start /wait MsiExec.exe /i %NODEJS_INSTALLER% /qn

exit /b %ERRORLEVEL%

:: ===================================================================
:: Start of MSYS2 Installation
:: ===================================================================
:installConfigMsys2
set MSYS2_FULLPATH=C:\msys64

if not exist %MSYS2_FULLPATH% call:installMsys2

:: Fail if installation fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:configMsys2
echo Configuring MSYS2...

:: Add to PATH environment variable
call:appendPath %%MSYS2_FULLPATH%%\usr\bin

:: Fail if append fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Add to PATH environment variable
call:appendPath %%MSYS2_FULLPATH%%\mingw64\bin

:: Fail if append fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Install MinGW and dependencies for MSYS2
set MSYSTEM=MSYS
%MSYS2_FULLPATH%\usr\bin\bash --login -c "pacman -S --noconfirm --needed mingw-w64-x86_64-ccache mingw-w64-x86_64-cmake mingw-w64-x86_64-dlfcn mingw-w64-x86_64-eigen3 mingw-w64-x86_64-gcc mingw-w64-x86_64-make mingw-w64-x86_64-ninja mingw-w64-x86_64-zlib msys2-runtime-devel bison flex git make pkgconf unzip"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Add /mingw64/bin to PATH variable
%MSYS2_FULLPATH%\usr\bin\bash --login -c "[[ -n \"`grep mingw64 ~/.bashrc`\" ]] || echo \"export PATH=\$PATH:/mingw64/bin\" >> ~/.bashrc"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Symlink librt.a
%MSYS2_FULLPATH%\usr\bin\bash --login -c "[[ -f /mingw64/lib/librt.a ]] || ln -s /usr/lib/librt.a /mingw64/lib"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Symlink Py.exe
%MSYS2_FULLPATH%\usr\bin\bash --login -c "[[ -f /usr/bin/python ]] || ln -s /c/Windows/py.exe /usr/bin/python"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Symlink Py.exe
%MSYS2_FULLPATH%\usr\bin\bash --login -c "[[ -f /usr/bin/python3 ]] || ln -s /c/Windows/py.exe /usr/bin/python3"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Symlink pip.exe
%MSYS2_FULLPATH%\usr\bin\bash --login -c "[[ -f /usr/bin/pip ]] || ln -s /c/Program\ Files/Python310/Scripts/pip.exe /usr/bin/pip"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Generate SSH Key
%MSYS2_FULLPATH%\usr\bin\bash --login -c "[[ -f ~/.ssh/id_rsa.pub ]] || ssh-keygen -q -t rsa -N '' <<< \"\"$'\n'\"y\" 2>&1 >/dev/null"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Add Github.com as known host
%MSYS2_FULLPATH%\usr\bin\bash --login -c "[[ -n \"`grep -m1 github.com ~/.ssh/known_hosts`\" ]] || ssh-keyscan github.com >> ~/.ssh/known_hosts"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Add Gitlab.com as known host
%MSYS2_FULLPATH%\usr\bin\bash --login -c "[[ -n \"`grep -m1 gitlab.com ~/.ssh/known_hosts`\" ]] || ssh-keyscan gitlab.com >> ~/.ssh/known_hosts"

:: Fail if installation fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Symlink directories in MSYS2 to Windows' (Git Bash) user directory to share directories
:: NOTE: This needs to be Windows' symlink to be visible in Windows
mklink /D "%USERPROFILE%\.ssh" "%MSYS2_FULLPATH%\home\%USERNAME%\.ssh" > nul 2>&1
mkdir "%MSYS2_FULLPATH%\home\%USERNAME%\_dev" > nul 2>&1
mklink /D "%USERPROFILE%\_dev" "%MSYS2_FULLPATH%\home\%USERNAME%\_dev" > nul 2>&1

exit /b %ERRORLEVEL%

:installMsys2
:: Download if not installed
echo Downloading MSYS2 . . .
call:download "https://github.com/msys2/msys2-installer/releases/download/2022-10-28/msys2-x86_64-20221028.exe" %MSYS2_INSTALLER%

:: Fail if download fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Install
:: https://silentinstallhq.com/msys2-silent-install-how-to-guide/
echo Installing MSYS2 . . .
call %MSYS2_INSTALLER% install --root %MSYS2_FULLPATH% --confirm-command

exit /b %ERRORLEVEL%

:: ===================================================================
:: Start of VS Code Installation
:: ===================================================================
:installConfigVscode

if not exist "%CODE_EXE%" call:installVscode

:: Fail if installation fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:configVscode
echo Configuring VS Code . . .
:: Add to PATH environment variable
call:appendPath %%%%ProgramFiles%%%%\Microsoft VS Code

set VSCODE_SETTINGS_DIR=%APPDATA%\Code\User
mkdir %VSCODE_SETTINGS_DIR% > nul 2>&1

:: @todo use jq to update settings.json
set VSCODE_SETTINGS=%VSCODE_SETTINGS_DIR%\settings.json

:: file doesn't exist, touch file
if not exist %VSCODE_SETTINGS% (
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
    echo     "terminal.integrated.scrollback": 1000000,
    echo     "bookmarks.navigateThroughAllFiles": true,
    echo     "bookmarks.saveBookmarksInProject": true,
    echo     "bookmarks.wrapNavigation": true,
    echo }
) > %VSCODE_SETTINGS%

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

:: Bookmarks
call "%CODE_EXE%" --force --install-extension alefragnani.Bookmarks

exit /b 0

:installVscode

:: Detect OS architecture and download accordingly
:: https://docs.microsoft.com/en-us/windows/win32/winprog64/wow64-implementation-details
if /i %PROCESSOR_ARCHITECTURE%==AMD64 (
    set INSTALLER_LINK="https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"
) else if /i %PROCESSOR_ARCHITECTURE%==x86 (
    set INSTALLER_LINK="https://code.visualstudio.com/sha/download?build=stable&os=win32"
) else if /i %PROCESSOR_ARCHITECTURE%==ARM64 (
    set INSTALLER_LINK="https://code.visualstudio.com/sha/download?build=stable&os=win32-arm64"
) else (
    echo unsupported architecture for VS Code, eg. Intel Itanium
    exit /b 1
)

:: Download
echo Downloading VS Code . . .
call:download %VSCODE_INSTALLER% %INSTALLER_LINK%

:: Fail if download fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Install
:: https://github.com/Microsoft/vscode/blob/main/build/win32/code.iss#L76-L97
:: runcode will be enabled by default, so disable it VS Code will pop out
:: addcontextmenufolders optionally added so that projects/folders can be easily opened
echo Installing VS Code . . .
call %VSCODE_INSTALLER% /VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufolders

:: Fail if installation fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Pin vscode to Taskbar and Quick Launch
"%PTTB_EXE%" "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Visual Studio Code\Visual Studio Code.lnk"
copy "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Visual Studio Code\Visual Studio Code.lnk" "%AppData%\Microsoft\Internet Explorer\Quick Launch\"

exit /b %ERRORLEVEL%

:: ===================================================================
:: Start of OpenVPN Installation
:: ===================================================================
:installConfigOvpn

set OVPN_EXE="%ProgramFiles%\OpenVPN\bin\openvpn-gui.exe"

if not exist %OVPN_EXE% call:installOvpn

:configOvpn
:: Nothing to configure for now

exit /b %ERRORLEVEL%

:installOvpn
echo Downloading OpenVPN . . .
call:download "https://swupdate.openvpn.org/community/releases/OpenVPN-2.5.8-I604-amd64.msi" %OVPN_INSTALLER%

:: Fail if download fails
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Install
echo Installing OpenVPN . . .
call MsiExec.exe /i %OVPN_INSTALLER% /qn

exit /b %ERRORLEVEL%

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

exit /b 0

:: ===================================================================
:: End of Installation
:: ===================================================================
:deleteInstallers
:: Delete Installers and ignore error
del %SZ_INSTALLER% > nul 2>&1
del %ARIA2_INSTALLER% > nul 2>&1
del %GIT_INSTALLER% > nul 2>&1
del %VSCODE_INSTALLER% > nul 2>&1
del %MSYS2_INSTALLER% > nul 2>&1
del %OVPN_INSTALLER% > nul 2>&1

exit /b 0

:: ===================================================================
:: Start of helper subroutines
:: ===================================================================
:checkAdmin
:: Check if running as Administrator
:: https://stackoverflow.com/a/11995662/19336104
net session >nul 2>&1

set ERROR_RETURN=%ERRORLEVEL%

:: Fail if not running as Administrator
if %ERROR_RETURN% neq 0 echo Not running as Administrator

exit /b %ERROR_RETURN%

:download
set INSTALL_LINK=%1
shift
:: @todo generate INSTALL_FILE from INSTALL_LINK if not provided
set INSTALL_FILE=%1
shift

:downloadAppendArg
set EXTRA_ARGS=%1
shift
if "%1" neq "" goto downloadAppendArg

:: Skip download if already exist
if exist %INSTALL_FILE% exit /b 0

:: Try with aria2 first
if exist "%ARIA2_EXE%" call "%ARIA2_EXE%" -o %INSTALL_FILE% %INSTALL_LINK% %EXTRA_ARGS%

:: fallback to curl if aria2 does not exist
if not exist %INSTALL_FILE% call curl -L -o %INSTALL_FILE% %INSTALL_LINK% %EXTRA_ARGS%

:: Pass error code to caller
exit /b %ERRORLEVEL%

:appendPath
:: Do not add invalid Path
call:pathExist %*
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Always check for the PATH environment variable from registry for the latest values
:: https://social.technet.microsoft.com/Forums/en-US/fed3975d-e1cf-4633-a37b-4e0948ac8eae/source-locations-for-path-variable-entries
:: https://stackoverflow.com/a/6362922/19336104
for /f "tokens=2* USEBACKQ" %%a in (`reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v "Path"`) do set PATH_REG=%%b

:: Check if PATH is already added
:: NOTE: "findstr" on string have character limit - including "/g", so push to file then read into variable instead
::       Need to echo without line break to work
echo|set /p="%PATH_REG%" > temp.txt
echo temp.txt > search.txt
set FOUND_FILE=
for /f "tokens=* USEBACKQ" %%A in (`findstr /f:search.txt /c:"%*" /m`) do set FOUND_FILE=%%A
del temp.txt search.txt

:: Skip adding to PATH variable if its already added
if "%FOUND_FILE%" neq "" exit /b 0

:: Remove trailing ;
if "%PATH_REG:~-1%"==";" set PATH_REG=%PATH_REG:~0,-1%

:: Modify registry value
set PATH_REG=%PATH_REG%;%*

:: Update PATH registry - add overwrite
:: https://stackoverflow.com/a/35248331/19336104
:: Do not use `setx /m` as it will demote the registry to REG_SZ which can no longer add variable-based PATH
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v "Path" /t REG_EXPAND_SZ /d "%PATH_REG%" /f > nul
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

echo Appended PATH: %*

:: Get User PATH
:: https://superuser.com/a/1017930
for /f "tokens=2* USEBACKQ" %%a in (`reg query "HKEY_CURRENT_USER\Environment" /v "Path"`) do set USER_PATH=%%b

:: Update PATH environment variable in current session after successfully added
call:setPath %PATH_REG%;%*;%USER_PATH%

exit /b %ERRORLEVEL%

:prependPath
:: Do not add invalid Path
call:pathExist %*
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Always check for the PATH environment variable from registry for the latest values
:: https://social.technet.microsoft.com/Forums/en-US/fed3975d-e1cf-4633-a37b-4e0948ac8eae/source-locations-for-path-variable-entries
:: https://stackoverflow.com/a/6362922/19336104
for /f "tokens=2* USEBACKQ" %%a in (`reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v "Path"`) do set PATH_REG=%%b

:: Check if PATH is already added
:: NOTE: "findstr" on string have character limit - including "/g", so push to file then read into variable instead
::       Need to echo without line break to work
echo|set /p="%PATH_REG%" > temp.txt
echo temp.txt > search.txt
set FOUND_FILE=
for /f "tokens=* USEBACKQ" %%A in (`findstr /f:search.txt /c:"%*" /m`) do set FOUND_FILE=%%A
del temp.txt search.txt

:: Skip adding to PATH variable if its already added
if "%FOUND_FILE%" neq "" exit /b 0

:: Remove trailing ;
if "%PATH_REG:~-1%"==";" set PATH_REG=%PATH_REG:~0,-1%

:: Modify registry value
set PATH_REG=%*;%PATH_REG%

:: Update PATH registry - add overwrite
:: https://stackoverflow.com/a/35248331/19336104
:: Do not use `setx /m` as it will demote the registry to REG_SZ which can no longer add variable-based PATH
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v "Path" /t REG_EXPAND_SZ /d "%PATH_REG%" /f > nul
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

echo Prepended PATH: %*

:: Get User PATH
:: https://superuser.com/a/1017930
for /f "tokens=2* USEBACKQ" %%a in (`reg query "HKEY_CURRENT_USER\Environment" /v "Path"`) do set USER_PATH=%%b

:: Update PATH environment variable in current session after successfully added
call:setPath %PATH_REG%;%*;%USER_PATH%

exit /b %ERRORLEVEL%

:: This will expand the string containing variable before checking its existence
:pathExist
if exist "%*" exit /b 0
exit /b 1

:: This will expand the string containing variable before setting PATH variable for current session
:setPath
set PATH=%*
