
function Show-Menu {
    Clear-Host
    Write-Host "=============================" -ForegroundColor Cyan
    Write-Host " App Execution Alias Manager " -ForegroundColor Yellow -BackgroundColor DarkBlue
    Write-Host "=============================" -ForegroundColor Cyan
    Write-Host "1. " -ForegroundColor White -NoNewline
    Write-Host "List Registered App Execution Aliases" -ForegroundColor Green
    Write-Host "2. " -ForegroundColor White -NoNewline
    Write-Host "List Stub Executables in WindowsApps" -ForegroundColor Green
    Write-Host "3. " -ForegroundColor White -NoNewline
    Write-Host "Check if a File is an Alias Stub" -ForegroundColor Green
    Write-Host "4. " -ForegroundColor White -NoNewline
    Write-Host "Remove an App Execution Alias" -ForegroundColor Red
    Write-Host "5. " -ForegroundColor White -NoNewline
    Write-Host "Create Custom Alias (Symlink)" -ForegroundColor Magenta
    Write-Host "0. " -ForegroundColor White -NoNewline
    Write-Host "Exit" -ForegroundColor Yellow
    Write-Host ""
}

function Get-Aliases {
    # Check WindowsApps folder for App Execution Aliases
    $windowsAppsPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps"
    if (Test-Path $windowsAppsPath) {
        Write-Host "=== WindowsApps Aliases ==="
        Get-ChildItem "$windowsAppsPath\*.exe" -ErrorAction SilentlyContinue | ForEach-Object {
            $aliasName = $_.Name
            [PSCustomObject]@{
                Alias = $aliasName
                Path  = $_.FullName
            }
        } | Format-Table -AutoSize
    }

    # Check App Paths registry
    $appPathsRoot = "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths"
    if (Test-Path $appPathsRoot) {
        Write-Host ""
        Write-Host "=== Registry App Paths ==="
        Get-ChildItem $appPathsRoot -ErrorAction SilentlyContinue | ForEach-Object {
            $alias = $_.PSChildName
            try {
                $props = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
                [PSCustomObject]@{
                    Alias = $alias
                    Path  = $props.'(default)'
                }
            } catch {
                Write-Host "$alias  →  [Error reading registry]"
            }
        } | Format-Table -AutoSize
    }

    Wait-ForInput
}

function Get-Stubs {
    $stubPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps"
    Get-ChildItem -Path $stubPath -Filter *.exe -File | Sort-Object Length | ForEach-Object {
        [PSCustomObject]@{
            Name = $_.Name
            SizeKB = "{0:N1}" -f ($_.Length / 1KB)
            FullPath = $_.FullName
        }
    } | Format-Table -AutoSize
    Wait-ForInput
}

function Test-Alias {
    $exe = Read-Host "Enter alias name (e.g., winget.exe)"
    $exePath = Join-Path "$env:LOCALAPPDATA\Microsoft\WindowsApps" $exe
    if (Test-Path $exePath) {
        $info = Get-Item $exePath | Select-Object Name, Length, VersionInfo
        $isStub = $info.Length -lt 25000 -and ($info.VersionInfo.FileDescription -eq "")
        Write-Host "Alias Name: $($info.Name)"
        Write-Host "Size: $($info.Length) bytes"
        Write-Host "Likely Stub: $isStub"
    } else {
        Write-Host "Executable not found."
    }
    Wait-ForInput
}

function Remove-Alias {
    $alias = Read-Host "Enter alias to remove (e.g., winget.exe)"
    
    # Try to remove from WindowsApps
    $windowsAppsPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps\$alias"
    if (Test-Path $windowsAppsPath) {
        Write-Host "'$alias' is a Windows Store App Execution Alias. `nTo remove it, uninstall the associated app from Windows Settings > Apps."
        return
    }

    # Try to remove from App Paths registry
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\$alias"
    if (Test-Path $regPath) {
        Remove-Item -Path $regPath -Recurse -Force
        Write-Host "Registry alias '$alias' removed."
    } else {
        Write-Host "Alias not found."
    }

    Wait-ForInput
}

function New-CustomAlias {
    $targetApp = Read-Host "Enter full path to target app (e.g., 'C:\Tools\MyApp.exe')"
    $aliasName = Read-Host "Enter alias name (include .exe) (e.g., 'myapp.exe')"

    # Create registry entry in App Paths
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\$aliasName"
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    Set-ItemProperty -Path $regPath -Name "(default)" -Value $targetApp
    Set-ItemProperty -Path $regPath -Name "Path" -Value (Split-Path $targetApp)

    Write-Host "Registry alias '$aliasName' created successfully! You can now run '$aliasName' from any command prompt."
    Wait-ForInput
}

function Wait-ForInput {
    Write-Host ""
    Read-Host "Press Enter to continue..."
}

do {
    Show-Menu
    $choice = Read-Host "Select an option"
    switch ($choice) {
        "1" { Get-Aliases }
        "2" { Get-Stubs }
        "3" { Test-Alias }
        "4" { Remove-Alias }
        "5" { New-CustomAlias }
        "0" { 
            Write-Host "Exiting!"
            return
        }
        default { Write-Host "Invalid selection. Try again."; Wait-ForInput }
    }
} while ($true)
