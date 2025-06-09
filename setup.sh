#!/bin/bash

# Update package lists
sudo apt-get update

# Install PowerShell
wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y powershell

# Install .NET SDK for C# development
sudo apt-get install -y dotnet-sdk-8.0

# Install Python and pip
sudo apt-get install -y python3 python3-pip python3-venv

# Install Git (should already be available but ensure it's installed)
sudo apt-get install -y git

# Add installed tools to PATH in user profile
echo 'export PATH="$PATH:/usr/bin"' >> $HOME/.profile

# Verify installations
echo "Setup completed successfully!"
echo "PowerShell version:"
pwsh --version
echo "Python version:"
python3 --version
echo "Dotnet version:"
dotnet --version
echo "Git version:"
git --version