# Run with:
# powershell -ExecutionPolicy Unrestricted -File install_rust.ps1

function Make-Directory {
    param (
        $Path
    )

    # Create directory
    # -Force - similar to "mkdir --parents" to create nested directories
    #    https://stackoverflow.com/a/20983885
    # -ErrorAction SilentlyContinue - parents will also not error out if directory already exist
    #    https://serverfault.com/a/336139
    New-Item -Path "$Path" -Type directory -Force -ErrorAction SilentlyContinue > $null
}

function Update-Path {
    $env:Path = ((Get-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment").GetValue("Path", "") + ";" + (Get-Item -Path "HKCU:\Environment").GetValue("Path", "")).Replace(";;", ",")
}

function Add-Path {
    param (
        $Destination,
        [bool]$Prepend
    )

    $expanded = cmd /c "echo $Destination"

    Update-Path
    if ((Test-Path $expanded) -And ! ($env:Path.Contains($expanded))) {

        # https://superuser.com/a/1341040
        $reg = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
        if ("$expanded".Contains($env:USERPROFILE)) {
            $reg = "HKCU:\Environment"
        }

        $path = (Get-Item -Path $reg).GetValue("Path", "", "DoNotExpandEnvironmentNames")
        $collapsed = $Destination.
            Replace("$env:APPDATA", "%APPDATA%").
            Replace("$env:LOCALAPPDATA", "%LOCALAPPDATA%").
            Replace("$env:USERPROFILE", "%USERPROFILE%").
            Replace("$env:PUBLIC", "%PUBLIC%").
            Replace("$env:ProgramData", "%ProgramData%").
            Replace("$env:CommonProgramFiles", "%CommonProgramFiles%").
            Replace("${env:CommonProgramFiles(x86)}", "%CommonProgramFiles(x86)%").
            Replace("$env:ProgramFiles", "%ProgramFiles%").
            Replace("${env:ProgramFiles(x86)}", "%ProgramFiles(x86)%").
            Replace("$env:DriverData", "%DriverData%").
            Replace("$env:SystemRoot", "%SystemRoot%").
            Replace("$env:SystemDrive", "%SystemDrive%")

        if (! $Prepend) {
            $path = ($path + ";" + $collapsed).Replace(";;", ";")
            "Appending Path Environment variable: $collapsed" | Out-Host
        } else {
            $path = ($collapsed + ";" + $path).Replace(";;", ";")
            "Prepending Path Environment variable: $collapsed" | Out-Host
        }

        # Use PS's New-ItemProperty because older PS errors out on RegistryKey.SetValue's overload with RegistryValueKind.ExpandString
        New-ItemProperty -Path "$reg" -Name "Path" -Value "$path" -PropertyType ExpandString -Force > $null

        Update-Path
    }
}

function Install-Msvc {
    # Visual Studio does not add to PATH as the IDE will load vcvarsall.bat or Launch-VsDevShell.ps1
    # Look for both ${env:ProgramFiles(x86)} and ${env:ProgramFiles}
    # because MS BuildTools is in ${env:ProgramFiles(x86)} while the rest is in ${env:ProgramFiles}
    # @todo fix the security exception for invalid path
    [string[]] $vswhere = (Get-ChildItem -Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio" -Filter "vswhere.exe" -Recurse).FullName
    if (! $vswhere) {
        $vswhere = (Get-ChildItem -Path "${env:ProgramFiles}\Microsoft Visual Studio" -Filter "vswhere.exe" -Recurse).FullName
    }
    if (! $vswhere) {
        $file = "vs_BuildTools.exe"
        if (! (Test-Path $file)) {
            "Downloading MSVC..." | Out-Host
            Invoke-WebRequest -Uri "https://aka.ms/vs/stable/vs_BuildTools.exe" -OutFile $file -UseBasicParsing 2> $null
        }
        if (Test-Path $file) {
            "Installing MSVC..." | Out-Host
            Start-Process $file -ArgumentList @(
                "--add Microsoft.VisualStudio.Workload.VCTools",
                "--includeRecommended",
                "--includeOptional",
                "--passive",
                "--norestart",
                "--wait"
            ) -Wait -NoNewWindow -PassThru > $null
        }
    }
}

function Install-Rustup {
    if (! (Get-Command cargo -ErrorAction SilentlyContinue)) {
        $file = "rustup-init.exe"
        if (! (Test-Path $file)) {
            "Downloading rustup..." | Out-Host
            # https://www.rust-lang.org/tools/install
            Invoke-WebRequest -Uri "https://win.rustup.rs/x86_64" -OutFile $file -UseBasicParsing 2> $null
        }
        if (Test-Path $file) {
            "Installing rustup..." | Out-Host
            Start-Process $file -ArgumentList "-y" -Wait -NoNewWindow -PassThru > $null

            Add-Path "$env:USERPROFILE\.cargo\bin" $true
        }
    }
}

function Main {
    Update-Path
    Install-Msvc
    Install-Rustup
}

Make-Directory $env:USERPROFILE\Downloads
Push-Location $env:USERPROFILE\Downloads

# https://serverfault.com/a/95464
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # @todo only Install-Msvc needs admin privilege, try to limit administrator scope...
    $ret = Main

    # The built-in `Pause` function is ugly, use the cmd version instead
    # https://stackoverflow.com/a/20886446
    cmd /c pause
} else {
    Write-Host -ForegroundColor red "This script ($PSCommandPath) needs to run as Administrator!"

    # Relaunching as Administrator, -Verb runAs is not compatible with -NoNewWindow -PassThru,
    # so a new console will pop up
    # Nothing could be captured either, especially the exit code, the workaround is to write-then-read a temp file
    Start-Process powershell -ArgumentList "-ExecutionPolicy Unrestricted -File $PSCommandPath" -Verb runAs -Wait
}

Pop-Location

return $ret
