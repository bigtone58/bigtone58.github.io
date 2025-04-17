# (c) 2007 Data Management & Warehousing
# Script to print network information for BGInfo
# Using CIM/WMI to acquire Network Configuration

# Configuration
$ShowCaption = $false
$ShowIPAddress = $true
$ShowIPv6 = $false
$ShowDHCP = $false
$ShowDHCPExpire = $false
$ShowGateway = $false
$ShowSubnet = $false
$ShowDNSDomain = $false

# Get network adapters using CimInstance (modern replacement for WMI)
$networkAdapters = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | 
                   Where-Object { $_.IPEnabled -eq $true }

foreach ($adapter in $networkAdapters) {
    foreach ($ip in $adapter.IPAddress) {
        # Check if IPv6 and whether we want to show it
        if (-not $ip.Contains("::") -or $ShowIPv6) {
            # Format adapter caption with MAC
            $caption = "{0} ({1})" -f ($adapter.Caption.Substring(0, [Math]::Min(12, $adapter.Caption.Length))), 
                                    $adapter.MACAddress

            # Format DHCP info if required
            $dhcpInfo = ""
            if ($adapter.DHCPEnabled -and $ShowDHCP) {
                $dhcpInfo = " (DHCP"
                if ($ShowDHCPExpire) {
                    $expires = [Management.ManagementDateTimeConverter]::ToDateTime($adapter.DHCPLeaseExpires)
                    $dhcpInfo += " - Expires: $expires; Server: $($adapter.DHCPServer)"
                }
                $dhcpInfo += ")"
            }

            # Display information based on configuration
            if ($ShowCaption) { Write-Host "Adapter: $caption" }
            if ($ShowIPAddress) { Write-Host "$ip$dhcpInfo" }
            if ($ShowGateway -and $adapter.DefaultIPGateway) { 
                Write-Host "Gateway: $($adapter.DefaultIPGateway[0])" 
            }
            if ($ShowSubnet -and $adapter.IPSubnet) { 
                Write-Host "Subnet: $($adapter.IPSubnet[0])" 
            }
            if ($ShowDNSDomain) { 
                Write-Host "Domain: $($adapter.DNSDomain)" 
            }
        }
    }
}