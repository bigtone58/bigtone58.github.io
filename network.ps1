# (c) 2007 Data Management & Warehousing
# Script to print network information for BGInfo
# Using CIM/WMI to acquire Network Configuration

# Configuration Declarations

# Which computer ? - normally . for the localhost
$strComputer = "."
# Display Adaptor Name ?
$ShowCaption = $false
# Display the IP address ?
$ShowIPAddress = $true
# Display IPv6 addresses ?
$ShowIPv6 = $false
# Display whether the address is a DHCP Address ?
$ShowDHCP = $false
# Display DHCP Lease expiry ?
$ShowDHCPExpire = $false
# Display the Default Gateway
$ShowGateway = $false
# Display the Default Subnet
$ShowSubnet = $false
# Display the DNS Domain
$ShowDNSDomain = $false
# End of script message
$strMessage = ""

# Configuration Values

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