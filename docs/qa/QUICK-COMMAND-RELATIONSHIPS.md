# Quick-command relationship review

All 235 quick commands have three explicit, available destinations. Each record is bound to the reviewed command text; changing the command invalidates its relationship review. These are task choices, not output-to-input contracts.

| Command | Task | Related tools |
| --- | --- | --- |
| Get User | AD account review | Get User Account Status; Check User Before Deletion; Get User Groups |
| Show Password Expiry | AD account review | Get User Account Status; Check User Before Deletion; Get User |
| Delete User | AD account review | Get User Account Status; Check User Before Deletion; Get User |
| Disable User | AD account review | Get User Account Status; Check User Before Deletion; Get User |
| Enable User | AD account review | Get User Account Status; Check User Before Deletion; Get User |
| Force Password Change Next Logon | AD account review | Get User Account Status; Check User Before Deletion; Get User |
| Reset Password | AD account review | Get User Account Status; Check User Before Deletion; Get User |
| Unlock User | AD account review | Get User Account Status; Check User Before Deletion; Get User |
| Find User By Exact Display Name | Cloud account review | Get User Account Status; Check User Before Deletion; Get User Security |
| Get User By Upn | Cloud account review | Get User Account Status; Check User Before Deletion; Get User Security |
| Show Assigned Licenses | Cloud account review | Get User Account Status; Check User Before Deletion; Get User Security |
| Show Manager | Cloud account review | Get User Account Status; Check User Before Deletion; Get User Security |
| Show Password Age | Cloud account review | Get User Account Status; Check User Before Deletion; Get User Security |
| Show Sync Source | Cloud account review | Get User Account Status; Check User Before Deletion; Get User Security |
| Delete Cloud User | Cloud account review | Get User Account Status; Check User Before Deletion; Get User Security |
| Disable Sign-In | Sign-in investigation | BEC: Assess User Risk; Get User Security; Incident Response: Trace IP Activity |
| Enable Sign-In | Sign-in investigation | BEC: Assess User Risk; Get User Security; Incident Response: Trace IP Activity |
| Incident Response: Revoke Sessions | Sign-in investigation | BEC: Assess User Risk; Get User Security; Incident Response: Trace IP Activity |
| Show Cached Tickets | Windows sessions and shares | Show Logged-On Users; Show SMB Sessions; Show SMB Shares |
| Purge Cached Tickets | Windows sessions and shares | Show Logged-On Users; Show SMB Sessions; Show SMB Shares |
| Show Local Administrators | Local accounts | Show Local Users; Identity and Privileges; Local Account Details |
| Show Local Users | Local accounts | Show Local Administrators; Identity and Privileges; Local Account Details |
| Add User To Administrators | Local accounts | Show Local Users; Show Local Administrators; Identity and Privileges |
| Remove User From Administrators | Local accounts | Show Local Users; Show Local Administrators; Identity and Privileges |
| Show MFA Methods | MFA methods | Get User Security; Audit MFA Security; Show Registration Status For One User |
| Show Microsoft Authenticator Methods | MFA methods | Get User Security; Audit MFA Security; Show MFA Methods |
| Show Phone Methods | MFA methods | Get User Security; Audit MFA Security; Show MFA Methods |
| Show Registration Status For One User | MFA methods | Get User Security; Audit MFA Security; Show MFA Methods |
| Remove Specific Authenticator Method | MFA methods | Get User Security; Audit MFA Security; Show MFA Methods |
| Remove Specific Phone Method | MFA methods | Get User Security; Audit MFA Security; Show MFA Methods |
| Show Delegated Grants For One User | App access | Audit App Consent; Get Enterprise App Owners; Get User Security |
| Show Potentially High-Impact Delegated Scopes | App access | Audit App Consent; Get Enterprise App Owners; Get User Security |
| Remove Specific Delegated Grant | App access | Audit App Consent; Get Enterprise App Owners; Get User Security |
| Show Distribution Group Members | Distribution groups | Get Distribution Group Members; Get Group Owners; Show Distribution Group Owners |
| Show Distribution Group Owners | Distribution groups | Get Distribution Group Members; Get Group Owners; Get Group Members |
| Add Distribution Group Member | Distribution groups | Get Distribution Group Members; Get Group Owners; Show Distribution Group Owners |
| Remove Distribution Group Member | Distribution groups | Get Distribution Group Members; Get Group Owners; Show Distribution Group Owners |
| Show AD Group Members | AD groups | Get User Groups; Get Group Members; Show AD User Group Memberships |
| Show AD User Group Memberships | AD groups | Get User Groups; Get Group Members; Show AD Group Members |
| Add User to AD Group | AD groups | Get User Groups; Get Group Members; Show AD Group Members |
| Remove User from AD Group | AD groups | Get User Groups; Get Group Members; Show AD Group Members |
| Find Exact Group | Entra groups | Get Group Members; Get User Groups; Get Group Owners |
| Show Entra Group Direct Members | Entra groups | Get Group Members; Get User Groups; Get Group Owners |
| Show Entra Group Owners | Entra groups | Get Group Members; Get User Groups; Get Group Owners |
| Show Entra User Group Memberships | Entra groups | Get Group Members; Get User Groups; Get Group Owners |
| Add User to Entra Group | Entra groups | Get Group Members; Get User Groups; Get Group Owners |
| Remove User from Entra Group | Entra groups | Get Group Members; Get User Groups; Get Group Owners |
| Show Mailbox Protocol State | Mailbox protocols | Get Mailbox Security; Show Mailbox Summary; Get Mailbox Permissions |
| Show Mailbox Summary | Mailbox access and forwarding | Get Mailbox Permissions; Get Mailbox Forwarding; Get Mailbox Security |
| Disable Mailbox SMTP AUTH | Mailbox protocols | Show Mailbox Protocol State; Get Mailbox Security; Show Mailbox Summary |
| Disable Mailbox POP / IMAP | Mailbox protocols | Show Mailbox Protocol State; Get Mailbox Security; Show Mailbox Summary |
| Show Mailbox Full Access Delegates | Mailbox access and forwarding | Get Mailbox Permissions; Get Mailbox Forwarding; Get Mailbox Security |
| Show Mailbox Forwarding | Mailbox access and forwarding | Get Mailbox Permissions; Get Mailbox Forwarding; Get Mailbox Security |
| Show Mailbox Send As Delegates | Mailbox access and forwarding | Get Mailbox Permissions; Get Mailbox Forwarding; Get Mailbox Security |
| Show Mailbox Send on Behalf Delegates | Mailbox access and forwarding | Get Mailbox Permissions; Get Mailbox Forwarding; Get Mailbox Security |
| Remove Mailbox Full Access Delegate | Mailbox access and forwarding | Get Mailbox Permissions; Get Mailbox Forwarding; Get Mailbox Security |
| Remove Mailbox Forwarding | Mailbox access and forwarding | Get Mailbox Permissions; Get Mailbox Forwarding; Get Mailbox Security |
| Remove Mailbox Send As Delegate | Mailbox access and forwarding | Get Mailbox Permissions; Get Mailbox Forwarding; Get Mailbox Security |
| Remove Mailbox Send on Behalf Delegate | Mailbox access and forwarding | Get Mailbox Permissions; Get Mailbox Forwarding; Get Mailbox Security |
| Show Specific Transport Rule | Mail transport | Audit Mail Flow Rules; Audit Tenant Inbox Rules; Incident Response: Trace Email Delivery |
| Show Transport Rules | Mail transport | Audit Mail Flow Rules; Audit Tenant Inbox Rules; Incident Response: Trace Email Delivery |
| Show Inbox Rules - Including Hidden | Inbox rules | Audit Tenant Inbox Rules; Get Mailbox Security; Get Mailbox Forwarding |
| Show Suspicious Inbox Rules | Inbox rules | Audit Tenant Inbox Rules; Get Mailbox Security; Get Mailbox Forwarding |
| Remove All Inbox Rules | Inbox rules | Audit Tenant Inbox Rules; Get Mailbox Security; Get Mailbox Forwarding |
| Remove Specific Inbox Rule | Inbox rules | Audit Tenant Inbox Rules; Get Mailbox Security; Get Mailbox Forwarding |
| Show BitLocker Recovery Protectors | Endpoint protection | Show BitLocker Status; Show Physical Disk Health; Check Common Pending Reboot Flags |
| Show BitLocker Status | Endpoint protection | Show BitLocker Recovery Protectors; Show Physical Disk Health; Check Common Pending Reboot Flags |
| Resume Protection | Endpoint protection | Show BitLocker Status; Show BitLocker Recovery Protectors; Show Physical Disk Health |
| Suspend For One Reboot | Endpoint protection | Show BitLocker Status; Show BitLocker Recovery Protectors; Show Physical Disk Health |
| Find By Thumbprint | Signing and certificates | Manage Signing Certificates; Sign Scripts; Verify Script Signature |
| Show Expiring Certificates | Signing and certificates | Manage Signing Certificates; Sign Scripts; Verify Script Signature |
| Verify Script Signature | Signing and certificates | Manage Signing Certificates; Sign Scripts; Show Code-Signing Certificates |
| Create Self-Signed App-Auth Certificate | Signing and certificates | Manage Signing Certificates; Sign Scripts; Verify Script Signature |
| Export Pfx | Signing and certificates | Manage Signing Certificates; Sign Scripts; Verify Script Signature |
| Export Public Cer | Signing and certificates | Manage Signing Certificates; Sign Scripts; Verify Script Signature |
| Sign Script | Signing and certificates | Manage Signing Certificates; Sign Scripts; Verify Script Signature |
| Find Exchange Service Principal By Appid | App access | Audit App Consent; Get Enterprise App Owners; Get User Security |
| Calculate Sha256 Hash | Signing and certificates | Manage Signing Certificates; Sign Scripts; Verify Script Signature |
| Show Compliance Search Status | Content search | Show Exchange Connection; Incident Response: Trace Email Delivery; Show Message Trace Search Jobs |
| Create Phishing Search By Subject | Content search | Show Compliance Search Status; Show Exchange Connection; Incident Response: Trace Email Delivery |
| Hard-Delete Search Results | Content search | Show Compliance Search Status; Show Exchange Connection; Incident Response: Trace Email Delivery |
| Start Compliance Search | Content search | Show Compliance Search Status; Show Exchange Connection; Incident Response: Trace Email Delivery |
| Run Quick Scan | Antivirus | Defender Status; Show Recent Windows Update History; Show Service Status |
| Update Signatures | Antivirus | Defender Status; Show Recent Windows Update History; Show Service Status |
| Audit Inbox Rule Changes | Mail investigation | Incident Response: Trace Email Delivery; Get Mailbox Security; Incident Response: Build Incident Timeline |
| Mail Delete And Move Audit | Mail investigation | Incident Response: Trace Email Delivery; Get Mailbox Security; Incident Response: Build Incident Timeline |
| Mail Items Accessed Audit | Mail investigation | Incident Response: Trace Email Delivery; Get Mailbox Security; Incident Response: Build Incident Timeline |
| Parse Mail Audit Subject, Ip, And Destination Folder | Mail investigation | Incident Response: Trace Email Delivery; Get Mailbox Security; Incident Response: Build Incident Timeline |
| Search Query Audit | Mail investigation | Incident Response: Trace Email Delivery; Get Mailbox Security; Incident Response: Build Incident Timeline |
| Unified Audit Log For One User | Mail investigation | Incident Response: Trace Email Delivery; Get Mailbox Security; Incident Response: Build Incident Timeline |
| Show Risk Detections For One User | Sign-in investigation | BEC: Assess User Risk; Get User Security; Incident Response: Trace IP Activity |
| Show Risky User State | Sign-in investigation | BEC: Assess User Risk; Get User Security; Incident Response: Trace IP Activity |
| Recipient | Mail delivery | Incident Response: Trace Email Delivery; Show Message Trace Events; Show Message Trace Search Jobs |
| Sender | Mail delivery | Incident Response: Trace Email Delivery; Show Message Trace Events; Show Message Trace Search Jobs |
| Show Message Trace Events | Mail delivery | Incident Response: Trace Email Delivery; Show Message Trace Search Jobs; Who Received Mail From Suspicious Sender |
| Show Message Trace Search Jobs | Mail delivery | Incident Response: Trace Email Delivery; Show Message Trace Events; Who Received Mail From Suspicious Sender |
| Who Received Mail From Suspicious Sender | Mail delivery | Incident Response: Trace Email Delivery; Show Message Trace Events; Show Message Trace Search Jobs |
| Show Failed Sign-Ins | Sign-in investigation | BEC: Assess User Risk; Get User Security; Incident Response: Trace IP Activity |
| Show Last 10 Entra Sign-Ins | Sign-in investigation | BEC: Assess User Risk; Get User Security; Incident Response: Trace IP Activity |
| Show Entra Sign-ins - Last 48 Hours | Sign-in investigation | BEC: Assess User Risk; Get User Security; Incident Response: Trace IP Activity |
| Show Legacy / Other-client Sign-ins | Sign-in investigation | BEC: Assess User Risk; Get User Security; Incident Response: Trace IP Activity |
| Show Successful Sign-Ins | Sign-in investigation | BEC: Assess User Risk; Get User Security; Incident Response: Trace IP Activity |
| Recent Application Errors | Windows event review | Recent System Errors; Show Last Boot And Uptime; Show Service Status |
| Recent System Errors | Windows event review | Recent Application Errors; Show Last Boot And Uptime; Show Service Status |
| Resolve Name | DNS | Show Configured Dns Servers; DNS Lookup; Show Ip Configuration |
| Show Configured Dns Servers | DNS | DNS Lookup; Show Ip Configuration; Resolve Name |
| Flush Resolver Cache | DNS | Show Configured Dns Servers; DNS Lookup; Show Ip Configuration |
| Show Windows Firewall Profiles | Firewall and remote access | Show Windows Firewall Rules by Name; Show Listening Tcp Ports; Test Tcp Port |
| Show Windows Firewall Rules by Name | Firewall and remote access | Show Windows Firewall Profiles; Show Listening Tcp Ports; Test Tcp Port |
| Ping Host | Network paths | Show Ip Configuration; Show Routing Table; Test Tcp Port |
| Show Active Adapters | Network changes | Show Ip Configuration; Show Routing Table; Network Profile |
| Show Arp Neighbor Cache | Network paths | Show Ip Configuration; Show Routing Table; Test Tcp Port |
| Show Established Tcp Connections | Network paths | Show Ip Configuration; Show Routing Table; Test Tcp Port |
| Show Ip Configuration | Network paths | Show Routing Table; Test Tcp Port; Ping Host |
| Show Listening Tcp Ports | Network paths | Show Ip Configuration; Show Routing Table; Test Tcp Port |
| Show Routing Table | Network paths | Show Ip Configuration; Test Tcp Port; Ping Host |
| Test Tcp Port | Network paths | Show Ip Configuration; Show Routing Table; Ping Host |
| Trace Route | Network paths | Show Ip Configuration; Show Routing Table; Test Tcp Port |
| Release And Renew Dhcp | Network changes | Show Active Adapters; Show Ip Configuration; Show Routing Table |
| Reset Tcp/Ip Stack | Network changes | Show Active Adapters; Show Ip Configuration; Show Routing Table |
| Reset Winsock | Network changes | Show Active Adapters; Show Ip Configuration; Show Routing Table |
| Restart Adapter | Network changes | Show Active Adapters; Show Ip Configuration; Show Routing Table |
| Show Configured Windows Vpn Connections | Network paths | Show Ip Configuration; Show Routing Table; Test Tcp Port |
| Show Wi-Fi Connection | Wi-Fi | Show Wi-Fi Interface; Show Saved Wi-Fi Profiles; Network Profile |
| Show Saved Wi-Fi Profiles | Wi-Fi | Show Wi-Fi Connection; Show Wi-Fi Interface; Network Profile |
| Show Problem Devices | Computer information | Show Computer Model And Serial Number; Show Os And Build; Show Last Boot And Uptime |
| Show Free Space | Storage | Review Windows Storage; Show Physical Disk Health; Open Storage Settings |
| Show Physical Disk Health | Storage | Review Windows Storage; Show Free Space; Open Storage Settings |
| Find Files Modified In Last 24 Hours | Storage | Review Windows Storage; Show Free Space; Show Physical Disk Health |
| Show Computer Model And Serial Number | Computer information | Show Os And Build; Show Last Boot And Uptime; Show Problem Devices |
| Show Hostname And Current User | Computer information | Show Computer Model And Serial Number; Show Os And Build; Show Last Boot And Uptime |
| Show Last Boot And Uptime | Computer information | Show Computer Model And Serial Number; Show Os And Build; Show Problem Devices |
| Show Os And Build | Computer information | Show Computer Model And Serial Number; Show Last Boot And Uptime; Show Problem Devices |
| Show Top Cpu Consumers | Performance | Show Top Memory Consumers; Show Service Status; Recent Application Errors |
| Show Top Memory Consumers | Performance | Show Top Cpu Consumers; Show Service Status; Recent Application Errors |
| Stop Process By Name | Performance | Show Top Cpu Consumers; Show Top Memory Consumers; Show Service Status |
| Show Whether Remote Desktop Is Enabled | Firewall and remote access | Show Windows Firewall Profiles; Show Windows Firewall Rules by Name; Show Listening Tcp Ports |
| Chkdsk Online Scan | Windows repair | Dism Component Store Scan; DISM Analyze Component Store; Recent System Errors |
| Dism Component Store Scan | Windows repair | DISM Analyze Component Store; Recent System Errors; Show Physical Disk Health |
| Dism Restore Health | Windows repair | Dism Component Store Scan; DISM Analyze Component Store; Recent System Errors |
| System File Checker | Windows repair | Dism Component Store Scan; DISM Analyze Component Store; Recent System Errors |
| Reboot Computer | Apps and updates | Show Available WinGet Updates; Show Recent Windows Update History; Check Common Pending Reboot Flags |
| Show Service Status | Services and scheduled tasks | Show Scheduled Task; Show Scheduled Task Last Run Result; Recent System Errors |
| Restart Service | Services and scheduled tasks | Show Service Status; Show Scheduled Task; Show Scheduled Task Last Run Result |
| Set Startup Type | Services and scheduled tasks | Show Service Status; Show Scheduled Task; Show Scheduled Task Last Run Result |
| Show Locally Logged-On Users | Windows sessions and shares | Show Logged-On Users; Show SMB Sessions; Show SMB Shares |
| Show SMB Sessions | Windows sessions and shares | Show Logged-On Users; Show SMB Shares; Mapped Drives |
| Show SMB Shares | Windows sessions and shares | Show Logged-On Users; Show SMB Sessions; Mapped Drives |
| Show Scheduled Task | Services and scheduled tasks | Show Service Status; Show Scheduled Task Last Run Result; Recent System Errors |
| Show Scheduled Task Last Run Result | Services and scheduled tasks | Show Service Status; Show Scheduled Task; Recent System Errors |
| Check Common Pending Reboot Flags | Apps and updates | Show Available WinGet Updates; Show Recent Windows Update History; Show Installed Hotfixes |
| Show Installed Hotfixes | Apps and updates | Show Available WinGet Updates; Show Recent Windows Update History; Check Common Pending Reboot Flags |
| Show Recent Windows Update History | Apps and updates | Show Available WinGet Updates; Check Common Pending Reboot Flags; Show Installed Hotfixes |
| Add Calendar Permission | Calendar and contacts | Show Calendar Permissions; Show Contacts Permissions; Get Mailbox Permissions |
| Remove Calendar Permission | Calendar and contacts | Show Calendar Permissions; Show Contacts Permissions; Get Mailbox Permissions |
| Show Calendar Permissions | Calendar and contacts | Show Contacts Permissions; Get Mailbox Permissions; Get Resource Mailbox Access |
| Show Contacts Permissions | Calendar and contacts | Show Calendar Permissions; Get Mailbox Permissions; Get Resource Mailbox Access |
| Add Contacts Permission | Calendar and contacts | Show Calendar Permissions; Show Contacts Permissions; Get Mailbox Permissions |
| Show Send-To Restrictions / authOrig | AD groups | Get User Groups; Get Group Members; Show AD Group Members |
| Show Account Enabled | AD account review | Get User Account Status; Check User Before Deletion; Get User |
| Show User Principal Name | AD account review | Get User Account Status; Check User Before Deletion; Get User |
| Show Password Last Set | AD account review | Get User Account Status; Check User Before Deletion; Get User |
| Show Distinguished Name | AD account review | Get User Account Status; Check User Before Deletion; Get User |
| Show Default Domain Password Policy | AD account review | Get User Account Status; Check User Before Deletion; Get User |
| Force Group Policy Update | Domain and device identity | Domain Trust Check; Entra Join Status; Show Group Policy Result |
| Show Group Policy Result | Domain and device identity | Domain Trust Check; Entra Join Status; Show Configured Dns Servers |
| Disable Hibernation | Storage | Review Windows Storage; Show Free Space; Show Physical Disk Health |
| Show Domain Account Details | Domain and device identity | Domain Trust Check; Entra Join Status; Show Group Policy Result |
| Create Local User | Local accounts | Show Local Users; Show Local Administrators; Identity and Privileges |
| Delete Local User | Local accounts | Show Local Users; Show Local Administrators; Identity and Privileges |
| Set Local User Password | Local accounts | Show Local Users; Show Local Administrators; Identity and Privileges |
| Enable Local Account | Local accounts | Show Local Users; Show Local Administrators; Identity and Privileges |
| Open Local Users and Groups | Local accounts | Show Local Users; Show Local Administrators; Identity and Privileges |
| Show Logged-On Users | Windows sessions and shares | Show SMB Sessions; Show SMB Shares; Mapped Drives |
| Disable Network Adapter | Network changes | Show Active Adapters; Show Ip Configuration; Show Routing Table |
| Restart Network Adapter | Network changes | Show Active Adapters; Show Ip Configuration; Show Routing Table |
| Isolate Device - Disable Enabled Adapters | Network changes | Show Active Adapters; Show Ip Configuration; Show Routing Table |
| Resync Windows Time | Windows time | Windows Time Status; Windows Time Source; Show Last Boot And Uptime |
| Open Windows Update | Apps and updates | Show Available WinGet Updates; Show Recent Windows Update History; Check Common Pending Reboot Flags |
| Show Wi-Fi Interface | Wi-Fi | Show Wi-Fi Connection; Show Saved Wi-Fi Profiles; Network Profile |
| Delete Wi-Fi Profile | Wi-Fi | Show Wi-Fi Connection; Show Wi-Fi Interface; Show Saved Wi-Fi Profiles |
| DISM Analyze Component Store | Windows repair | Dism Component Store Scan; Recent System Errors; Show Physical Disk Health |
| DISM Component Store Cleanup | Windows repair | Dism Component Store Scan; DISM Analyze Component Store; Recent System Errors |
| Launch Disk Cleanup | Storage | Review Windows Storage; Show Free Space; Show Physical Disk Health |
| Defragment Volume | Storage | Review Windows Storage; Show Free Space; Show Physical Disk Health |
| Show Available WinGet Updates | Apps and updates | Show Recent Windows Update History; Check Common Pending Reboot Flags; Show Installed Hotfixes |
| Update All Eligible WinGet Packages | Apps and updates | Show Available WinGet Updates; Show Recent Windows Update History; Check Common Pending Reboot Flags |
| Show WinGet Package Information | Apps and updates | Show Available WinGet Updates; Show Recent Windows Update History; Check Common Pending Reboot Flags |
| Update Specific WinGet Package | Apps and updates | Show Available WinGet Updates; Show Recent Windows Update History; Check Common Pending Reboot Flags |
| Update WinGet Sources | Apps and updates | Show Available WinGet Updates; Show Recent Windows Update History; Check Common Pending Reboot Flags |
| Show PowerShell Version | PowerShell setup | Check M365 PowerShell Readiness; Install M365 Modules; Show Execution Policies |
| Show Execution Policies | PowerShell setup | Check M365 PowerShell Readiness; Install M365 Modules; Show PowerShell Version |
| Set Current User Execution Policy - RemoteSigned | PowerShell setup | Check M365 PowerShell Readiness; Install M365 Modules; Show Execution Policies |
| Show Installed Microsoft Graph Module Version | PowerShell setup | Check M365 PowerShell Readiness; Install M365 Modules; Show Execution Policies |
| Show Installed ExchangeOnlineManagement Version | PowerShell setup | Check M365 PowerShell Readiness; Install M365 Modules; Show Execution Policies |
| Show Graph Context | Graph connection | Check M365 PowerShell Readiness; Reset M365 Session; Get User By Upn |
| Show Exchange Connection | Exchange connection | Check M365 PowerShell Readiness; Reset M365 Session; Show Mailbox Summary |
| Disconnect Microsoft Graph | Graph connection | Check M365 PowerShell Readiness; Reset M365 Session; Show Graph Context |
| Disconnect Exchange Online | Exchange connection | Check M365 PowerShell Readiness; Reset M365 Session; Show Exchange Connection |
| Show Activity From One IP | Sign-in investigation | BEC: Assess User Risk; Get User Security; Incident Response: Trace IP Activity |
| Look Up ISP And Location | Network paths | Show Ip Configuration; Show Routing Table; Test Tcp Port |
| AD Group Memberships | AD groups | Get User Groups; Get Group Members; Show AD Group Members |
| AD Group Members | AD groups | Get User Groups; Get Group Members; Show AD Group Members |
| Connect Exchange Online | Exchange connection | Check M365 PowerShell Readiness; Reset M365 Session; Show Exchange Connection |
| Install Exchange Online Module | PowerShell setup | Check M365 PowerShell Readiness; Install M365 Modules; Show Execution Policies |
| Install Microsoft Graph Module | PowerShell setup | Check M365 PowerShell Readiness; Install M365 Modules; Show Execution Policies |
| Show Hidden Inbox Rules | Inbox rules | Audit Tenant Inbox Rules; Get Mailbox Security; Get Mailbox Forwarding |
| Delete All Inbox Rules | Inbox rules | Audit Tenant Inbox Rules; Get Mailbox Security; Get Mailbox Forwarding |
| IP Configuration (ipconfig) | Network paths | Show Ip Configuration; Show Routing Table; Test Tcp Port |
| Flush DNS | DNS | Show Configured Dns Servers; DNS Lookup; Show Ip Configuration |
| DNS Lookup | DNS | Show Configured Dns Servers; Show Ip Configuration; Resolve Name |
| Continuous Ping | Network paths | Show Ip Configuration; Show Routing Table; Test Tcp Port |
| Traceroute | Network paths | Show Ip Configuration; Show Routing Table; Test Tcp Port |
| Path Ping | Network paths | Show Ip Configuration; Show Routing Table; Test Tcp Port |
| Routing Table (route print) | Network paths | Show Ip Configuration; Show Routing Table; Test Tcp Port |
| ARP Cache | Network paths | Show Ip Configuration; Show Routing Table; Test Tcp Port |
| TCP Connections (netstat) | Network paths | Show Ip Configuration; Show Routing Table; Test Tcp Port |
| Port 443 Connections | Network paths | Show Ip Configuration; Show Routing Table; Test Tcp Port |
| Local Account Details | Local accounts | Show Local Users; Show Local Administrators; Identity and Privileges |
| Windows Time Status | Windows time | Windows Time Source; Show Last Boot And Uptime; Domain Trust Check |
| Windows Time Source | Windows time | Windows Time Status; Show Last Boot And Uptime; Domain Trust Check |
| WinHTTP Proxy | Network paths | Show Ip Configuration; Show Routing Table; Test Tcp Port |
| Domain Trust Check | Domain and device identity | Entra Join Status; Show Group Policy Result; Show Configured Dns Servers |
| Printer Check | Printing | Install Network Printer; Print Jobs; Spooler Status |
| Open Storage Settings | Storage | Review Windows Storage; Show Free Space; Show Physical Disk Health |
| Clear Delivery Optimization Cache | Storage | Review Windows Storage; Show Free Space; Show Physical Disk Health |
| Identity and Privileges | Local accounts | Show Local Users; Show Local Administrators; Local Account Details |
| Entra Join Status | Domain and device identity | Domain Trust Check; Show Group Policy Result; Show Configured Dns Servers |
| Mapped Drives | Windows sessions and shares | Show Logged-On Users; Show SMB Sessions; Show SMB Shares |
| Network Profile | Network paths | Show Ip Configuration; Show Routing Table; Test Tcp Port |
| Defender Status | Antivirus | Show Recent Windows Update History; Show Service Status; Show Problem Devices |
| Print Jobs | Printing | Install Network Printer; Printer Check; Spooler Status |
| Spooler Status | Printing | Install Network Printer; Printer Check; Print Jobs |
| Connect Microsoft Graph | Graph connection | Check M365 PowerShell Readiness; Reset M365 Session; Show Graph Context |
| Show Code-Signing Certificates | Signing and certificates | Manage Signing Certificates; Sign Scripts; Verify Script Signature |
