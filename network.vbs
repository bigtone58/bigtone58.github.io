Rem (c) 2007 Data Management & Warehousing
Rem 
Rem A script to print network information for BGInfo
Rem 
Rem The script takes advantage of the Windows Management Interface (WMI)
Rem to acquire the Network Configuration
Rem
Rem This script is overly commented to allow others as a learning aid.

On Error Resume Next

Rem Configuration

Rem Configuration Declarations

Rem Which computer ? - normally . for the localhost
Dim strComputer
Rem Display Adaptor Name ?
Dim blnShowCaption
Rem Display the IP address ?
Dim blnShowIPAddress
Rem Display IPv6 addresses ?
Dim blnShowIPv6
Rem Display whether the address is a DHCP Address ?
Dim blnShowDHCP
Rem Display DHCP Lease expiry ?
Dim blnShowDHCPExpire
Rem Display the Default Gateway
Dim blnShowGateway
Rem Display the Default Subnet
Dim blnShowSubnet
Rem Display the DNS Domain
Dim blnShowDNSDomain
Rem End of script message
Dim strMessage

Rem Configuration Values

strComputer = "."
blnShowCaption = False
blnShowIPAddress = True
blnShowIPv6 = False
blnShowDHCP = False
blnShowDHCPExpire = False
blnShowGateway = False
blnShowSubnet = False
blnShowDNSDomain = False

Rem Code Block

Rem Code Block Declarations

Rem Identity of the Windows Management Service
Dim objWMIService
Rem Items within the Windows Management Service
Dim colItems
Rem Objects within the Items
Rem Full list: http://msdn2.microsoft.com/en-us/library/aa394217.aspx
Dim objItem

Rem Current Record Values of objItems
Dim strIPAddress
Dim strCaption
Dim strDHCP
Dim strGateway

Rem Code Block Functionality

Rem Define source of information
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")

Rem Define query to get information - IPEnabled restricts the information to active Adaptors
Set colItems = objWMIService.ExecQuery("Select * from Win32_NetworkAdapterConfiguration Where IPEnabled = TRUE")

Rem Get each adaptor from the table
For Each objItem In colItems
    Rem Get each IP address for the adaptor
    For Each strIPAddress In objItem.IPAddress
       Rem check to see if it is an IPv6 address and whether we want it
       If InStr(strIPAddress, "::") = 0 Or blnShowIPv6 Then
          Rem Set up the correct adaptor name by stringing the first 12 characters and also the MAC address
          strCaption = fnSubstring(objItem.Caption, 12, 1024) & " (" & objItem.MACAddress & ")"
          Rem Format DHCP info if required
          If objItem.DHCPEnabled and blnShowDHCP Then
             strDHCP = " (DHCP"
             If blnShowDHCPExpire Then
                strDHCP = strDHCP & " - Expires: " & fnDisplayDate(objItem.DHCPLeaseExpires) & "; Server: " & objItem.DHCPServer
 	     End If
             strDHCP = strDHCP & ")"
          Else
             strDHCP = ""
          End If
          Rem Print information
          Rem Note that any other object from Win32_NetworkAdapterConfiguration can be added here
          REM Call fnDisplayValue(blnShowCaption,strCaption,"Adaptor",0)
          Call fnDisplayValue(blnShowIPAddress,strIPAddress + strDHCP,"",.5)
          REM Call fnDisplayValue(blnShowGateway,objItem.DefaultIPGateway,"Gateway",0)
          REM Call fnDisplayValue(blnShowSubnet,objItem.IPSubnet(0),"Subnet",0)
          REM Call fnDisplayValue(blnShowDNSDomain,objItem.DNSDomain,"Domain",0)
          REM Echo ""
       End If
    Next
Next

Rem print the end of script message
Echo strMessage

Rem End of Programme

Rem Procedures & Functions

Rem Display a passed value
Rem The parameters are:
Rem    p_valueLogical   - should this value be displayed ?
Rem    p_valueVar       - the value to display
Rem    p_valueDisplay   - the text to Display
Rem    p_valueTab       - the number of tabs needed to align it

Sub fnDisplayValue(p_valueLogical, p_valueVar, p_valueDisplay, p_valueTab)

   Dim strVar

   If p_valueLogical Then
      Rem if the value is an array the cycle through each value
      If IsArray(p_valueVar) Then
         For Each strVar In p_valueVar
            Rem if the value is a string then display it, otherwise ignore it 
            If VarType(strVar) = 8 Then
                Echo p_valueDisplay & "" & String(p_valueTab,"	") & strVar
            End If      
         Next
      Else
         strVar = p_valueVar
         Rem if the value is a string then display it, otherwise ignore it 
         If VarType(strVar) = 8 Then
            Echo p_valueDisplay & "" & String(p_valueTab," ") & strVar
         End If      
      End If
   End If 

End Sub

Rem Function to pull the a substring out from a string
 
Function fnSubstring(p_strData,p_intStart,p_intLength )

   Dim intLen
   intLen = Len(p_strdata)

   If p_intStart < 1 Or p_intStart > intLen Then
      fnSubstring = ""
   Else
      If p_intLength > intLen - p_intStart + 1 Then
         p_intLength = intLen - p_intStart + 1
      End If
      fnSubstring = Right(Left(p_strData, p_intStart + p_intLength - 1), p_intLength)
   End If 

End Function

Rem Function to convert a WMI date stamp into a usable date

Function fnDisplayDate(p_strDate)

   Dim strYear, strMonth, strDay, strHour, strMinute, strSecond  

   strYear =   fnSubstring(p_strDate,1,4)
   strMonth =  fnSubstring(p_strDate,5,2)
   strDay =    fnSubstring(p_strDate,7,2)
   strHour =   fnSubstring(p_strDate,9,2)
   strMinute = fnSubstring(p_strDate,11,2)
   strSecond = fnSubstring(p_strDate,13,2)
   fnDisplayDate = cdate(strMonth & "/" & strDay & "/" & strYear & " " & strHour & ":" & strMinute & ":" & strSecond)

End Function 

Rem End of file