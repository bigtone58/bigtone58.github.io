<#
.SYNOPSIS
    App Execution Alias Manager - A GUI tool for managing Windows application execution aliases.

.DESCRIPTION
    This PowerShell script provides a graphical user interface for viewing, managing, and creating
    Windows application execution aliases. It displays both Windows Store App Execution Aliases
    (from WindowsApps folder) and custom registry-based App Paths aliases in a three-column format
    showing alias names, full paths, and file sizes.

    The application automatically loads alias information on startup and provides functionality to:
    - List all registered app execution aliases
    - Remove custom registry aliases (Windows Store aliases require app uninstallation)
    - Create new custom aliases via registry App Paths
    - Display file sizes with automatic KB/MB formatting
    - Maintain window size and position across sessions

.PARAMETER None
    This script does not accept any parameters.

.EXAMPLE
    .\AppExecutionAliasManager_GUI.ps1

    Launches the App Execution Alias Manager GUI application.

.EXAMPLE
    Get-Help .\AppExecutionAliasManager_GUI.ps1 -Full

    Displays complete help information for this script.

.NOTES
    File Name      : AppExecutionAliasManager_GUI.ps1
    Author         : Tony Walsh - Generated with Augment AI and VSCode
    Copyright      : © 2025 Tony Walsh. All rights reserved.
    License        : GPL-3.0
    Prerequisite   : PowerShell 5.1 or later, Windows Forms

    Window Settings: Automatically saved to %LOCALAPPDATA%\AppExecutionAliasManager\config.json

    Alias Types Supported:
    - Windows Store App Execution Aliases (read-only, located in WindowsApps)
    - Registry App Paths aliases (can be created/removed)

    File Size Display:
    - Files ≤999KB: Displayed as whole numbers in KB (rounded up)
    - Files >999KB: Displayed in MB with 1 decimal place (rounded up to nearest tenth)

.LINK
    https://docs.microsoft.com/en-us/windows/win32/shell/app-registration

.LINK
    https://docs.microsoft.com/en-us/windows/uwp/launch-resume/launch-default-app

.FUNCTIONALITY
    GUI, Alias Management, Registry Management, File System
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'foundAliases')]
param()

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic

# Script-level variables
$script:listView = $null
$script:btnListAliases = $null

# Functions for saving/loading window settings
function Save-WindowSettings {
    param($Form)
    $configPath = "$env:LOCALAPPDATA\AppExecutionAliasManager\config.json"
    $configDir = Split-Path $configPath -Parent

    # Create directory if it doesn't exist
    if (-not (Test-Path $configDir)) {
        New-Item -Path $configDir -ItemType Directory -Force | Out-Null
    }

    $settings = @{
        WindowX = $Form.Location.X
        WindowY = $Form.Location.Y
        WindowWidth = $Form.Size.Width
        WindowHeight = $Form.Size.Height
        WindowState = $Form.WindowState.ToString()
    }

    $settings | ConvertTo-Json | Set-Content -Path $configPath
}

function Get-WindowSettings {
    param($Form)
    $configPath = "$env:LOCALAPPDATA\AppExecutionAliasManager\config.json"

    if (Test-Path $configPath) {
        try {
            $settings = Get-Content -Path $configPath | ConvertFrom-Json

            if ($settings.WindowX -and $settings.WindowY) {
                $Form.Location = New-Object System.Drawing.Point($settings.WindowX, $settings.WindowY)
            }

            if ($settings.WindowWidth -and $settings.WindowHeight) {
                $Form.Size = New-Object System.Drawing.Size($settings.WindowWidth, $settings.WindowHeight)
            }

            if ($settings.WindowState) {
                $Form.WindowState = [System.Windows.Forms.FormWindowState]::($settings.WindowState)
            }
        } catch {
            # If any error loading settings, use defaults (current settings remain)
        }
    }
}

function New-Form {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "App Execution Alias Manager"
    $form.Size = New-Object System.Drawing.Size(1024, 768)
    $form.MinimumSize = New-Object System.Drawing.Size(500, 400)
    $form.StartPosition = "CenterScreen"

    # Load saved window settings
    Get-WindowSettings -Form $form

    $script:listView = New-Object System.Windows.Forms.ListView
    $script:listView.Location = New-Object System.Drawing.Point(20, 10)
    $script:listView.Size = New-Object System.Drawing.Size(984, 680)
    $script:listView.Anchor = "Top,Left,Right,Bottom"
    $script:listView.View = "Details"
    $script:listView.FullRowSelect = $true
    $script:listView.GridLines = $true


    # Add columns with specified widths (20%, 70%, 9% = 99% total)
    $null = $script:listView.Columns.Add("=== Alias Name ===", 197)  # 20% of 984
    $null = $script:listView.Columns.Add("=== Full Path ===", 689)   # 70% of 984
    $sizeColumn = $script:listView.Columns.Add("=== Size ===", 89)   # 9% of 984
    $sizeColumn.TextAlign = "Right"



    $form.Controls.Add($script:listView)

    $buttonPanel = New-Object System.Windows.Forms.FlowLayoutPanel
    $buttonPanel.Dock = "Bottom"
    $buttonPanel.FlowDirection = "LeftToRight"
    $buttonPanel.AutoSize = $true
    $buttonPanel.AutoSizeMode = "GrowAndShrink"
    $buttonPanel.Padding = New-Object System.Windows.Forms.Padding(5, 3, 5, 3)
    $buttonPanel.Margin = New-Object System.Windows.Forms.Padding(0)
    $form.Controls.Add($buttonPanel)

    $script:btnListAliases = New-Object System.Windows.Forms.Button
    $script:btnListAliases.Text = "List Aliases"
    $script:btnListAliases.Size = New-Object System.Drawing.Size(120, 30)
    $script:btnListAliases.AutoSize = $false
    $script:btnListAliases.Margin = New-Object System.Windows.Forms.Padding(3, 3, 3, 3)
    $script:btnListAliases.Add_Click({
        $script:listView.Items.Clear()

        # Check WindowsApps folder for App Execution Aliases
        $windowsAppsPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps"
        $foundAliases = $false

        if (Test-Path $windowsAppsPath) {
            # Add header row
            $headerItem = New-Object System.Windows.Forms.ListViewItem("=== WindowsApps Aliases ===")
            $headerItem.SubItems.Add("")
            $headerItem.SubItems.Add("")
            $headerItem.ForeColor = [System.Drawing.Color]::Blue
            $headerItem.Font = New-Object System.Drawing.Font($script:listView.Font, [System.Drawing.FontStyle]::Bold)
            $script:listView.Items.Add($headerItem)

            Get-ChildItem "$windowsAppsPath\*.exe" -ErrorAction SilentlyContinue | ForEach-Object {
                $aliasName = $_.Name
                $target = $_.Target
                if ($target) {
                    $item = New-Object System.Windows.Forms.ListViewItem($aliasName)
                    $item.SubItems.Add($target)
                    $item.SubItems.Add("")
                } else {
                    # For App Execution Aliases, show file path and size
                    $fullPath = $_.FullName
                    $sizeKB = [math]::Ceiling($_.Length / 1KB)
                    if ($sizeKB -gt 999) {
                        $sizeMB = [math]::Ceiling(($_.Length / 1MB) * 10) / 10
                        $sizeText = "${sizeMB}MB"
                    } else {
                        $sizeText = "${sizeKB}KB"
                    }
                    $item = New-Object System.Windows.Forms.ListViewItem($aliasName)
                    $item.SubItems.Add($fullPath)
                    $item.SubItems.Add($sizeText)
                }
                $script:listView.Items.Add($item)
                $foundAliases = $true
            }
        }
        
        # Check App Paths registry
        $appPathsRoot = "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths"
        if (Test-Path $appPathsRoot) {
            # Add empty row and header
            $emptyItem = New-Object System.Windows.Forms.ListViewItem("")
            $emptyItem.SubItems.Add("")
            $emptyItem.SubItems.Add("")
            $script:listView.Items.Add($emptyItem)

            $headerItem = New-Object System.Windows.Forms.ListViewItem("=== Registry App Paths ===")
            $headerItem.SubItems.Add("")
            $headerItem.SubItems.Add("")
            $headerItem.ForeColor = [System.Drawing.Color]::Blue
            $headerItem.Font = New-Object System.Drawing.Font($script:listView.Font, [System.Drawing.FontStyle]::Bold)
            $script:listView.Items.Add($headerItem)

            Get-ChildItem $appPathsRoot -ErrorAction SilentlyContinue | ForEach-Object {
                $alias = $_.PSChildName
                try {
                    $props = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
                    $defaultValue = $props.'(default)'
                    $sizeText = ""

                    if ($defaultValue) {
                        # Check if target file exists and get size info
                        if (Test-Path $defaultValue -ErrorAction SilentlyContinue) {
                            $fileInfo = Get-Item $defaultValue -ErrorAction SilentlyContinue
                            if ($fileInfo) {
                                $sizeKB = [math]::Ceiling($fileInfo.Length / 1KB)
                                if ($sizeKB -gt 999) {
                                    $sizeMB = [math]::Ceiling(($fileInfo.Length / 1MB) * 10) / 10
                                    $sizeText = "${sizeMB}MB"
                                } else {
                                    $sizeText = "${sizeKB}KB"
                                }
                            }
                        } else {
                            # Only show "Target not found" if it looks like a file path or executable
                            if ($defaultValue -match '^[A-Za-z]:\\' -or $defaultValue.Contains('\') -or $defaultValue -match '\.[a-zA-Z]{2,4}$') {
                                $sizeText = "[Not found]"
                            }
                        }
                        $item = New-Object System.Windows.Forms.ListViewItem($alias)
                        $item.SubItems.Add($defaultValue)
                        $item.SubItems.Add($sizeText)
                    } else {
                        $item = New-Object System.Windows.Forms.ListViewItem($alias)
                        $item.SubItems.Add("[No target specified]")
                        $item.SubItems.Add("")
                    }

                    $script:listView.Items.Add($item)
                    $foundAliases = $true
                } catch {
                    $item = New-Object System.Windows.Forms.ListViewItem($alias)
                    $item.SubItems.Add("[Error reading registry]")
                    $item.SubItems.Add("")
                    $script:listView.Items.Add($item)
                }
            }
        }

        if (-not $foundAliases) {
            $item = New-Object System.Windows.Forms.ListViewItem("No aliases found.")
            $item.SubItems.Add("")
            $item.SubItems.Add("")
            $script:listView.Items.Add($item)
        }
    })
    $buttonPanel.Controls.Add($script:btnListAliases)

    $btnRemoveAlias = New-Object System.Windows.Forms.Button
    $btnRemoveAlias.Text = "Remove Alias"
    $btnRemoveAlias.Size = New-Object System.Drawing.Size(120, 30)
    $btnRemoveAlias.AutoSize = $false
    $btnRemoveAlias.Margin = New-Object System.Windows.Forms.Padding(3, 3, 3, 3)
    $btnRemoveAlias.Add_Click({
        if ($script:listView.SelectedItems.Count -gt 0) {
            $selectedItem = $script:listView.SelectedItems[0]
            $selectedAlias = $selectedItem.Text

            # Skip header lines
            if ($selectedAlias.StartsWith("===") -or $selectedAlias -eq "" -or $selectedAlias -eq "No aliases found.") {
                [System.Windows.Forms.MessageBox]::Show("Please select an alias to remove, not a header.")
                return
            }

            $selected = $selectedAlias
            $removed = $false
            
            # Try to remove from WindowsApps (App Execution Aliases)
            $windowsAppsPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps\$selected"
            if (Test-Path $windowsAppsPath) {
                try {
                    # App Execution Aliases are managed by Windows Store apps
                    # They cannot be directly deleted - inform user
                    [System.Windows.Forms.MessageBox]::Show("'$selected' is a Windows Store App Execution Alias.`nTo remove it, uninstall the associated app from Windows Settings > Apps.")
                    return
                } catch {
                    [System.Windows.Forms.MessageBox]::Show("Error: $($_.Exception.Message)")
                    return
                }
            }
            
            # Try to remove from App Paths registry
            $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\$selected"
            if (Test-Path $regPath) {
                try {
                    Remove-Item -Path $regPath -Recurse -Force
                    [System.Windows.Forms.MessageBox]::Show("Registry alias '$selected' removed.")
                    $removed = $true
                } catch {
                    [System.Windows.Forms.MessageBox]::Show("Error removing registry alias: $($_.Exception.Message)")
                }
            }
            
            # Check custom bin folder
            $customBinPath = "$env:USERPROFILE\bin\$selected"
            if (Test-Path $customBinPath) {
                try {
                    Remove-Item -Path $customBinPath -Force
                    [System.Windows.Forms.MessageBox]::Show("Custom alias '$selected' removed from ~/bin.")
                    $removed = $true
                } catch {
                    [System.Windows.Forms.MessageBox]::Show("Error removing custom alias: $($_.Exception.Message)")
                }
            }
            
            if (-not $removed) {
                [System.Windows.Forms.MessageBox]::Show("Alias '$selected' not found or cannot be removed.")
            } else {
                $script:btnListAliases.PerformClick()
            }
        } else {
            [System.Windows.Forms.MessageBox]::Show("Please select an alias to remove.")
        }
    })
    $buttonPanel.Controls.Add($btnRemoveAlias)

    $btnCreateAlias = New-Object System.Windows.Forms.Button
    $btnCreateAlias.Text = "Create Custom Alias"
    $btnCreateAlias.Size = New-Object System.Drawing.Size(150, 30)
    $btnCreateAlias.AutoSize = $false
    $btnCreateAlias.Margin = New-Object System.Windows.Forms.Padding(3, 3, 3, 3)
    $btnCreateAlias.Add_Click({
        $targetApp = [System.Windows.Forms.OpenFileDialog]::new()
        $targetApp.Title = "Select Target Application"
        $targetApp.Filter = "Executable files (*.exe)|*.exe|All files (*.*)|*.*"
        if ($targetApp.ShowDialog() -eq "OK") {
            $defaultName = Split-Path -Leaf $($targetApp.FileName)
            $aliasName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter alias name (include .exe extension):`n`nAlias will point to:`n$($targetApp.FileName)", "Create Custom Alias", $defaultName)
            if ($aliasName -and $aliasName.Trim() -ne "") {
                # Ensure .exe extension
                if (-not $aliasName.EndsWith(".exe")) {
                    $aliasName += ".exe"
                }
                
                # Create registry entry in App Paths
                $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\$aliasName"
                try {
                    if (-not (Test-Path $regPath)) {
                        New-Item -Path $regPath -Force | Out-Null
                    }
                    Set-ItemProperty -Path $regPath -Name "(default)" -Value $targetApp.FileName
                    Set-ItemProperty -Path $regPath -Name "Path" -Value (Split-Path $targetApp.FileName)
                    
                    [System.Windows.Forms.MessageBox]::Show("Registry alias '$aliasName' created successfully!`nYou can now run '$aliasName' from any command prompt.")
                    $script:btnListAliases.PerformClick()
                } catch {
                    [System.Windows.Forms.MessageBox]::Show("Error creating registry alias: $($_.Exception.Message)")
                }
            }
        }
    })
    $buttonPanel.Controls.Add($btnCreateAlias)

    # Add resize event to maintain equal left/right margins only
    $form.Add_Resize({
        $script:listView.Width = $form.ClientSize.Width - 40
        # Update column widths proportionally (99% total)
        $script:listView.Columns[0].Width = [int](($form.ClientSize.Width - 40) * 0.20)  # 20%
        $script:listView.Columns[1].Width = [int](($form.ClientSize.Width - 40) * 0.70)  # 70%
        $script:listView.Columns[2].Width = [int](($form.ClientSize.Width - 40) * 0.09)  # 9%
    })

    # Set initial width correctly based on actual client size
    $script:listView.Width = $form.ClientSize.Width - 40
    # Update initial column widths (99% total)
    $script:listView.Columns[0].Width = [int](($form.ClientSize.Width - 40) * 0.20)
    $script:listView.Columns[1].Width = [int](($form.ClientSize.Width - 40) * 0.70)
    $script:listView.Columns[2].Width = [int](($form.ClientSize.Width - 40) * 0.09)

    # Add form load event to auto-populate aliases
    $form.Add_Load({
        $script:btnListAliases.PerformClick()
    })

    # Add form closing event to save window settings
    $form.Add_FormClosing({
        Save-WindowSettings -Form $form
    })

    return $form
}

$form = New-Form
[void]$form.ShowDialog()
