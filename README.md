# install-scripts
Automation scripts to help prepare development workstation environment with minimal user intervention.

## Notes
If there is a script that needs to be executed often, they can be added to the default executable directory

### Windows
```powershell
$env:LOCALAPPDATA\Microsoft\WindowsApps
```

### Linux
```shell
# These will only be added to path after re-login, a new remote ssh session will have this in PATH
$HOME/.local/bin
# Alternative path, however python will usually place executables in the '.local' path
$HOME/bin
```

# License
Refer to [LICENSE.md](./LICENSE.md), normally [0BSD](https://spdx.org/licenses/0BSD.html) by default as its not usually something to ship so its as permissive as possible, unless stated otherwise by individual files that was mirrored (modified) over.
