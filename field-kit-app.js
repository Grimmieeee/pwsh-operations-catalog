(() => {
  "use strict";

  const RAW = Array.isArray(window.CATALOG_DATA) ? window.CATALOG_DATA : [];

  const AREAS = [
    "Full Library",
    "Single User",
    "Multi User",
    "Tenant Wide",
    "Incident Response",
    "Utility",
    "Standalone",
    "Tools",
    "Toys",
    "About"
  ];

  const INCIDENT_SOURCES = ["PowerShell"];

  const STANDALONE_GROUPS = [
    "Exchange",
    "Graph",
    "Active Directory",
    "Windows CLI",
    "Network CLI",
    "WinGet",
    "Terminal"
  ];

  const EXTRA_STANDALONE = [
    {
      name:"Add Calendar Permission",
      platform:"Exchange Online",
      access:"Change",
      requires:"Connect: Connect-ExchangeOnline",
      code:'$AccessRights = "Reviewer" # Reviewer or Editor\nAdd-MailboxFolderPermission -Identity "owner@domain.com:\\Calendar" -User "user@domain.com" -AccessRights $AccessRights',
      options:{label:"ACCESS LEVEL",values:["Reviewer","Editor"]},
      keywords:"calendar permissions mailbox folder editor reviewer"
    },
    {
      name:"Remove Calendar Permission",
      platform:"Exchange Online",
      access:"Change",
      requires:"Connect: Connect-ExchangeOnline",
      code:'Remove-MailboxFolderPermission -Identity "owner@domain.com:\\Calendar" -User "user@domain.com" -Confirm:$true',
      keywords:"calendar permissions mailbox folder remove access"
    },
    {
      name:"Show Calendar Permissions",
      platform:"Exchange Online",
      access:"Read-only",
      requires:"Connect: Connect-ExchangeOnline",
      code:'Get-MailboxFolderPermission -Identity "user@domain.com:\\Calendar"',
      keywords:"calendar permissions mailbox folder access"
    },
    {
      name:"Show Contacts Permissions",
      platform:"Exchange Online",
      access:"Read-only",
      requires:"Connect: Connect-ExchangeOnline",
      code:'Get-MailboxFolderPermission -Identity "user@domain.com:\\Contacts"',
      keywords:"contacts permissions mailbox folder access"
    },
    {
      name:"Add Contacts Permission",
      platform:"Exchange Online",
      access:"Change",
      requires:"Connect: Connect-ExchangeOnline",
      code:'$AccessRights = "Reviewer" # Reviewer or Editor\nAdd-MailboxFolderPermission -Identity "owner@domain.com:\\Contacts" -User "user@domain.com" -AccessRights $AccessRights',
      options:{label:"ACCESS LEVEL",values:["Reviewer","Editor"]},
      keywords:"contacts permissions mailbox folder editor reviewer"
    },
    {
      name:"Show Send-To Restrictions / authOrig",
      platform:"Active Directory",
      access:"Read-only",
      requires:"Connect: Import-Module ActiveDirectory",
      code:"Get-ADGroup 'GroupName' -Properties authOrig | Select-Object -ExpandProperty authOrig",
      keywords:"distro distribution list sender restriction authorig allowed senders"
    },
    {
      name:"Show Account Enabled",
      platform:"Active Directory",
      access:"Read-only",
      requires:"Connect: Import-Module ActiveDirectory",
      code:'Get-ADUser "username" -Properties Enabled | Select-Object SamAccountName,Enabled',
      keywords:"account enabled disabled ad user status"
    },
    {
      name:"Show User Principal Name",
      platform:"Active Directory",
      access:"Read-only",
      requires:"Connect: Import-Module ActiveDirectory",
      code:'Get-ADUser -Identity "username" -Properties UserPrincipalName | Select-Object UserPrincipalName',
      keywords:"upn principal name ad user"
    },
    {
      name:"Show Password Last Set",
      platform:"Active Directory",
      access:"Read-only",
      requires:"Connect: Import-Module ActiveDirectory",
      code:'Get-ADUser -Identity "username" -Properties PasswordLastSet | Select-Object Name,PasswordLastSet',
      keywords:"password last set age changed ad"
    },
    {
      name:"Show Distinguished Name",
      platform:"Active Directory",
      access:"Read-only",
      requires:"Connect: Import-Module ActiveDirectory",
      code:'Get-ADUser -Identity "username" | Select-Object DistinguishedName',
      keywords:"dn distinguished name ad user"
    },
    {
      name:"Show Default Domain Password Policy",
      platform:"Active Directory",
      access:"Read-only",
      requires:"Connect: Import-Module ActiveDirectory",
      code:"Get-ADDefaultDomainPasswordPolicy",
      keywords:"password policy domain age complexity lockout"
    },
    {
      name:"Force Group Policy Update",
      platform:"Local Windows",
      access:"Change",
      code:"gpupdate /force",
      keywords:"gpo group policy refresh update"
    },
    {
      name:"Show Group Policy Result",
      platform:"Local Windows",
      access:"Read-only",
      code:"gpresult /r",
      keywords:"gpo group policy applied result"
    },
    {
      name:"Disable Hibernation",
      platform:"Local Windows",
      access:"Change",
      code:"powercfg.exe /hibernate off",
      keywords:"hibernate hibernation disk storage cleanup"
    },
    {
      name:"Show Domain Account Details",
      platform:"Local Windows",
      access:"Read-only",
      code:"net user username /domain",
      keywords:"domain user account details net user"
    },
    {
      name:"Create Local User",
      platform:"Local Windows",
      access:"Change",
      code:"net user username /add",
      keywords:"new local user create account"
    },
    {
      name:"Delete Local User",
      platform:"Local Windows",
      access:"Destructive",
      code:"& {\n    $Target = (Read-Host 'Exact local account name; blank cancels').Trim()\n    if (-not $Target) { return }\n    $User = Get-LocalUser -Name $Target -ErrorAction Stop\n    $User | Format-List Name,SID,Enabled | Out-Host\n    if ((Read-Host \"Type DELETE $($User.Name) to approve\").Trim() -cne \"DELETE $($User.Name)\") { Write-Host 'Cancelled; no changes.'; return }\n    Remove-LocalUser -SID $User.SID -ErrorAction Stop\n    Write-Host 'Deletion request completed; independently verify the local account is absent.'\n}",
      keywords:"delete local user remove account"
    },
    {
      name:"Set Local User Password",
      platform:"Local Windows",
      access:"Change",
      code:'net user "username" "temporary password"',
      keywords:"local password reset account"
    },
    {
      name:"Enable Local Account",
      platform:"Local Windows",
      access:"Change",
      code:'net user "username" /active:yes',
      keywords:"unlock enable local account"
    },
    {
      name:"Open Local Users and Groups",
      platform:"Local Windows",
      access:"Read-only",
      code:"lusrmgr.msc",
      keywords:"local users groups gui"
    },
    {
      name:"Show Logged-On Users",
      platform:"Local Windows",
      access:"Read-only",
      code:"quser",
      keywords:"logged in logged on sessions users"
    },
    {
      name:"Disable Network Adapter",
      platform:"Local Windows",
      access:"Change",
      code:"& {\n    Write-Warning \"May interrupt connectivity, active work, protection or installed applications. Review the command and arrange recovery before approving.\"\n    if ((Read-Host \"Type APPLY to approve: Disable Network Adapter\").Trim() -cne 'APPLY') { Write-Host 'Cancelled; no changes.'; return }\n    netsh interface set interface \"Wi-Fi\" admin=disabled\n}",
      keywords:"network adapter disable wifi isolate"
    },
    {
      name:"Restart Network Adapter",
      platform:"Local Windows",
      access:"Change",
      code:"& {\n    Write-Warning \"May interrupt connectivity, active work, protection or installed applications. Review the command and arrange recovery before approving.\"\n    if ((Read-Host \"Type APPLY to approve: Restart Network Adapter\").Trim() -cne 'APPLY') { Write-Host 'Cancelled; no changes.'; return }\n    Restart-NetAdapter -Name \"Wi-Fi\"\n}",
      keywords:"network adapter restart nic"
    },
    {
      name:"Isolate Device - Disable Enabled Adapters",
      platform:"Local Windows",
      access:"Change",
      code:"& {\n    Write-Warning \"May interrupt connectivity, active work, protection or installed applications. Review the command and arrange recovery before approving.\"\n    if ((Read-Host \"Type APPLY to approve: Isolate Device - Disable Enabled Adapters\").Trim() -cne 'APPLY') { Write-Host 'Cancelled; no changes.'; return }\n    Get-NetAdapter | Where-Object Status -eq \"Up\" | Disable-NetAdapter -Confirm:$true\n}",
      keywords:"isolate device network adapters disable incident response"
    },
    {
      name:"Reboot Computer",
      platform:"Local Windows",
      access:"Change",
      code:"& {\n    Write-Warning \"May interrupt connectivity, active work, protection or installed applications. Review the command and arrange recovery before approving.\"\n    if ((Read-Host \"Type APPLY to approve: Reboot Computer\").Trim() -cne 'APPLY') { Write-Host 'Cancelled; no changes.'; return }\n    Restart-Computer -Force\n}",
      keywords:"restart reboot computer workstation"
    },
    {
      name:"Resync Windows Time",
      platform:"Local Windows",
      access:"Change",
      code:"w32tm /resync /force",
      keywords:"time sync clock w32tm"
    },
    {
      name:"Open Windows Update",
      platform:"Local Windows",
      access:"Read-only",
      code:"start ms-settings:windowsupdate-action",
      keywords:"windows update settings patches"
    },
    {
      name:"Show Wi-Fi Interface",
      platform:"Local Windows",
      access:"Read-only",
      code:"netsh wlan show interfaces",
      keywords:"wifi wireless wlan interface ssid"
    },
    {
      name:"Delete Wi-Fi Profile",
      platform:"Local Windows",
      access:"Change",
      code:'netsh wlan delete profile name="ProfileName"',
      keywords:"wifi wireless wlan profile forget"
    },
    {
      name:"DISM Analyze Component Store",
      platform:"Local Windows",
      access:"Read-only",
      code:"DISM /Online /Cleanup-Image /AnalyzeComponentStore",
      keywords:"dism component store cleanup storage health"
    },
    {
      name:"DISM Component Store Cleanup",
      platform:"Local Windows",
      access:"Change",
      code:"DISM /Online /Cleanup-Image /StartComponentCleanup",
      keywords:"dism component store cleanup storage"
    },
    {
      name:"DISM Restore Health",
      platform:"Local Windows",
      access:"Change",
      code:"DISM /Online /Cleanup-Image /RestoreHealth",
      keywords:"dism repair image health windows"
    },
    {
      name:"Launch Disk Cleanup",
      platform:"Local Windows",
      access:"Change",
      code:"cleanmgr.exe",
      keywords:"disk cleanup storage temp files"
    },
    {
      name:"Defragment Volume",
      platform:"Local Windows",
      access:"Change",
      code:"Optimize-Volume -DriveLetter C -Defrag -Verbose",
      keywords:"defrag optimize volume disk"
    },
    {
      name:"Show Available WinGet Updates",
      platform:"WinGet",
      access:"Read-only",
      code:"winget upgrade --accept-source-agreements",
      keywords:"winget available updates packages software"
    },
    {
      name:"Update All Eligible WinGet Packages",
      platform:"WinGet",
      access:"Change",
      code:"& {\n    Write-Warning \"May interrupt connectivity, active work, protection or installed applications. Review the command and arrange recovery before approving.\"\n    if ((Read-Host \"Type APPLY to approve: Update All Eligible WinGet Packages\").Trim() -cne 'APPLY') { Write-Host 'Cancelled; no changes.'; return }\n    winget upgrade --all --silent --accept-source-agreements --accept-package-agreements --disable-interactivity\n}",
      keywords:"winget update all packages software"
    },
    {
      name:"Show WinGet Package Information",
      platform:"WinGet",
      access:"Read-only",
      input:'Exact package ID from winget search. Replace "Package.Id" before running.',
      code:'$PackageId = "Package.Id"\nwinget show --id $PackageId --exact',
      keywords:"winget package info version"
    },
    {
      name:"Update Specific WinGet Package",
      platform:"WinGet",
      access:"Change",
      input:'Exact package ID from winget search. Replace "Package.Id" before running.',
      code:'$PackageId = "Package.Id"\nwinget upgrade --id $PackageId --exact --accept-source-agreements --accept-package-agreements',
      keywords:"winget update specific package"
    },
    {
      name:"Update WinGet Sources",
      platform:"WinGet",
      access:"Change",
      code:"winget source update",
      keywords:"winget source refresh update"
    },
    {
      name:"Show PowerShell Version",
      platform:"PowerShell",
      access:"Read-only",
      code:"$PSVersionTable.PSVersion",
      keywords:"powershell version ps7 terminal health"
    },
    {
      name:"Show Execution Policies",
      platform:"PowerShell",
      access:"Read-only",
      code:"Get-ExecutionPolicy -List",
      keywords:"execution policy powershell terminal health"
    },
    {
      name:"Set Current User Execution Policy - RemoteSigned",
      platform:"PowerShell",
      access:"Change",
      code:"Set-ExecutionPolicy RemoteSigned -Scope CurrentUser",
      keywords:"execution policy remotesigned powershell"
    },
    {
      name:"Show Installed Microsoft Graph Module Version",
      platform:"PowerShell",
      access:"Read-only",
      code:'Get-Module Microsoft.Graph.Authentication -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1 Name,Version,Path',
      keywords:"graph module installed version terminal health"
    },
    {
      name:"Show Installed ExchangeOnlineManagement Version",
      platform:"PowerShell",
      access:"Read-only",
      code:'Get-Module ExchangeOnlineManagement -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1 Name,Version,Path',
      keywords:"exchange exo module installed version terminal health"
    },
    {
      name:"Show Graph Context",
      platform:"Microsoft Graph",
      access:"Read-only",
      code:"Get-MgContext",
      keywords:"graph session context scopes tenant account auth"
    },
    {
      name:"Show Exchange Connection",
      platform:"Exchange Online",
      access:"Read-only",
      code:"Get-ConnectionInformation",
      keywords:"exchange exo connection session auth"
    },
    {
      name:"Disconnect Microsoft Graph",
      platform:"Microsoft Graph",
      access:"Change",
      code:"Disconnect-MgGraph",
      keywords:"graph disconnect session reset auth"
    },
    {
      name:"Disconnect Exchange Online",
      platform:"Exchange Online",
      access:"Change",
      code:"Disconnect-ExchangeOnline -Confirm:$false",
      keywords:"exchange exo disconnect session reset auth"
    },
    {
      name:"Show Activity From One IP",
      platform:"Microsoft Graph",
      access:"Read-only",
      requires:'Connect: Connect-MgGraph -Scopes "AuditLog.Read.All","User.Read.All"',
      code:'$Ip = "1.2.3.4"\nGet-MgAuditLogSignIn -Filter "ipAddress eq \'$Ip\'" -Top 100 |\n  Select-Object CreatedDateTime,UserPrincipalName,AppDisplayName,IPAddress,ClientAppUsed,\n    @{N="Status";E={if($_.Status.ErrorCode -eq 0){"Success"}else{"Failed"}}}',
      keywords:"graph sign in signin ip address activity audit login"
    },
    {
      name:"Look Up ISP And Location",
      platform:"Local Windows",
      access:"Read-only",
      code:'$Ip = "8.8.8.8"\nInvoke-RestMethod "https://ipinfo.io/$Ip/json" |\n  Select-Object ip,city,region,country,org',
      notes:"Uses the external ipinfo.io lookup service.",
      keywords:"ip isp geolocation location network lookup internet"
    },
    {
      name:"AD Group Memberships",
      platform:"Active Directory",
      access:"Read-only",
      code:'Get-ADPrincipalGroupMembership -Identity "username" | Select-Object Name',
      useFor:"See which Active Directory groups a user belongs to.",
      keywords:"ad active directory groups membership user memberof"
    },
    {
      name:"AD Group Members",
      platform:"Active Directory",
      access:"Read-only",
      code:'Get-ADGroupMember -Identity "GroupName" | Select-Object Name,SamAccountName,ObjectClass',
      useFor:"See who or what is a member of an Active Directory group.",
      keywords:"ad active directory group members membership"
    },
    {
      name:"Connect Exchange Online",
      platform:"Exchange Online",
      access:"Read-only",
      code:"Connect-ExchangeOnline",
      useFor:"Start an Exchange Online PowerShell session.",
      keywords:"exchange exo connect session"
    },
    {
      name:"Install Exchange Online Module",
      platform:"PowerShell",
      access:"Change",
      code:"Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber",
      useFor:"Install or refresh the Exchange Online PowerShell module for the current user.",
      keywords:"exchange exo install module setup powershell"
    },
    {
      name:"Install Microsoft Graph Module",
      platform:"PowerShell",
      access:"Change",
      code:"Install-Module -Name Microsoft.Graph -Scope CurrentUser -Force -AllowClobber",
      useFor:"Install or refresh the Microsoft Graph PowerShell module for the current user.",
      keywords:"graph install module setup powershell"
    },
    {
      name:"Show Hidden Inbox Rules",
      platform:"Exchange Online",
      access:"Read-only",
      code:'Get-InboxRule -Mailbox "user@domain.com" -IncludeHidden',
      useFor:"Check visible and hidden inbox rules when mail is being moved, deleted, forwarded, or redirected unexpectedly.",
      keywords:"exchange inbox rules hidden forwarding mailbox suspicious email"
    },
    {
      name:"Delete All Inbox Rules",
      platform:"Exchange Online",
      access:"Destructive",
      code:"& {\n    $Mailbox = (Read-Host 'Exact mailbox UPN; blank cancels').Trim()\n    if (-not $Mailbox) { return }\n    $Rules = @(Get-InboxRule -Mailbox $Mailbox -IncludeHidden -ErrorAction Stop)\n    $Rules | Format-Table Name,Identity,Enabled -AutoSize | Out-Host\n    if (-not $Rules.Count) { Write-Host 'No rules found; no changes.'; return }\n    Write-Warning \"Deletes ALL $($Rules.Count) visible and hidden rules from $Mailbox. Legitimate rules are included.\"\n    if ((Read-Host \"Type DELETE $Mailbox to approve\").Trim() -cne \"DELETE $Mailbox\") { Write-Host 'Cancelled; no changes.'; return }\n    foreach ($Rule in $Rules) {\n        Remove-InboxRule -Mailbox $Mailbox -Identity $Rule.Identity -Confirm:$false -ErrorAction Stop\n    }\n    $Remaining = @(Get-InboxRule -Mailbox $Mailbox -IncludeHidden -ErrorAction Stop)\n    if ($Remaining.Count) { throw \"$($Remaining.Count) rules remain; review partial results.\" }\n    Write-Host \"Verified: no inbox rules remain in $Mailbox.\"\n}",
      useFor:"Remove all visible and hidden inbox rules after reviewing the target mailbox.",
      keywords:"exchange inbox rules hidden delete remove cleanup mailbox"
    },
    {
      name:"IP Configuration (ipconfig)",
      platform:"Local Windows",
      access:"Read-only",
      code:"ipconfig /all",
      useFor:"Check IP address, gateway, DHCP, DNS, and adapter configuration.",
      keywords:"windows cli cmd ipconfig ip gateway dhcp dns adapter network"
    },
    {
      name:"Flush DNS",
      platform:"Local Windows",
      access:"Change",
      code:"ipconfig /flushdns",
      useFor:"Clear the local DNS resolver cache after a DNS change or bad/stale resolution.",
      keywords:"windows cli cmd ipconfig flushdns dns cache network"
    },
    {
      name:"DNS Lookup",
      platform:"Local Windows",
      access:"Read-only",
      code:"nslookup example.com",
      useFor:"Verify DNS resolution and see which resolver is answering.",
      keywords:"windows cli cmd nslookup dns resolve hostname network"
    },
    {
      name:"Continuous Ping",
      platform:"Local Windows",
      access:"Read-only",
      code:"ping -t example.com",
      useFor:"Watch reachability and latency continuously while reproducing an intermittent issue.",
      keywords:"windows cli cmd ping continuous latency packet loss network"
    },
    {
      name:"Traceroute",
      platform:"Local Windows",
      access:"Read-only",
      code:"tracert example.com",
      useFor:"See where traffic stops or latency increases between the workstation and a destination.",
      keywords:"windows cli cmd tracert traceroute path hops latency network"
    },
    {
      name:"Path Ping",
      platform:"Local Windows",
      access:"Read-only",
      code:"pathping example.com",
      useFor:"Measure packet loss and latency across the route to a destination.",
      keywords:"windows cli cmd pathping packet loss latency route network"
    },
    {
      name:"Routing Table (route print)",
      platform:"Local Windows",
      access:"Read-only",
      code:"route print",
      useFor:"Check gateways and routes when multiple adapters, VPNs, or wrong-path issues are suspected.",
      keywords:"windows cli cmd route print routing gateway vpn network"
    },
    {
      name:"ARP Cache",
      platform:"Local Windows",
      access:"Read-only",
      code:"arp -a",
      useFor:"Check local IP-to-MAC mappings when troubleshooting duplicate IPs or LAN reachability.",
      keywords:"windows cli cmd arp mac duplicate ip lan network"
    },
    {
      name:"TCP Connections (netstat)",
      platform:"Local Windows",
      access:"Read-only",
      code:"netstat -ano",
      useFor:"See listening and active TCP connections with owning process IDs.",
      keywords:"windows cli cmd netstat tcp ports sockets pid connections network"
    },
    {
      name:"Port 443 Connections",
      platform:"Local Windows",
      access:"Read-only",
      code:"netstat -ano | findstr :443",
      useFor:"Quickly isolate HTTPS connections and listeners using TCP 443.",
      keywords:"windows cli cmd netstat findstr 443 https port tcp network"
    },
    {
      name:"Local Account Details",
      platform:"Local Windows",
      access:"Read-only",
      code:"net user username",
      useFor:"Check local account status, password age, group context, and logon details.",
      keywords:"windows cli cmd net user local account details"
    },
    {
      name:"Windows Time Status",
      platform:"Local Windows",
      access:"Read-only",
      code:"w32tm /query /status",
      useFor:"Check current Windows Time synchronization state and source details.",
      keywords:"windows cli cmd w32tm time sync clock ntp"
    },
    {
      name:"Windows Time Source",
      platform:"Local Windows",
      access:"Read-only",
      code:"w32tm /query /source",
      useFor:"Confirm which time source the workstation is using.",
      keywords:"windows cli cmd w32tm time source ntp domain"
    },
    {
      name:"WinHTTP Proxy",
      platform:"Local Windows",
      access:"Read-only",
      code:"netsh winhttp show proxy",
      useFor:"Check system-level proxy settings when browsers work but applications or services cannot reach the internet.",
      keywords:"windows cli cmd netsh winhttp proxy internet app connectivity"
    },
    {
      name:"Domain Trust Check",
      platform:"Local Windows",
      access:"Read-only",
      code:"Test-ComputerSecureChannel -Verbose",
      useFor:"Verify the workstation secure channel to the Active Directory domain.",
      keywords:"windows powershell domain trust secure channel active directory"
    },
    {
      name:"Printer Check",
      platform:"Local Windows",
      access:"Read-only",
      code:"Get-Printer | Select-Object Name,DriverName,PortName,PrinterStatus",
      useFor:"Review installed printers, drivers, ports, and current printer status.",
      keywords:"windows powershell printer print driver port queue"
    },
    {
      name:"Open Storage Settings",
      platform:"Local Windows",
      access:"Read-only",
      code:"start ms-settings:storagesense",
      useFor:"Open Windows Storage settings for disk cleanup and storage review.",
      keywords:"windows cli storage cleanup disk settings temp files"
    },
    {
      name:"Clear Delivery Optimization Cache",
      platform:"Local Windows",
      access:"Change",
      code:"Delete-DeliveryOptimizationCache -Force",
      useFor:"Clear the Windows Delivery Optimization cache after storage review.",
      keywords:"windows delivery optimization cache cleanup delete storage disk update cache"
    },
    {
      name:"Identity and Privileges",
      platform:"Local Windows",
      access:"Read-only",
      code:"whoami /all",
      useFor:"Show the current user, SID, group memberships, token privileges, and elevation context.",
      keywords:"windows cli whoami identity groups privileges sid admin elevation token"
    },
    {
      name:"Entra Join Status",
      platform:"Local Windows",
      access:"Read-only",
      code:"dsregcmd /status",
      useFor:"Check Entra join, domain join, device registration, PRT, and SSO state.",
      keywords:"windows cli dsregcmd entra azure ad join prt sso device registration hybrid join"
    },
    {
      name:"Mapped Drives",
      platform:"Local Windows",
      access:"Read-only",
      code:"net use",
      useFor:"Review mapped drives and active SMB connections for the current user.",
      keywords:"windows cli net use mapped drive smb share network drive"
    },
    {
      name:"Network Profile",
      platform:"Local Windows",
      access:"Read-only",
      code:"Get-NetConnectionProfile",
      useFor:"Check whether Windows sees the current network as Domain, Private, or Public.",
      keywords:"windows powershell network profile domain private public firewall connection"
    },
    {
      name:"Defender Status",
      platform:"Local Windows",
      access:"Read-only",
      code:"Get-MpComputerStatus | Select-Object AMServiceEnabled,AntivirusEnabled,RealTimeProtectionEnabled,AntivirusSignatureLastUpdated,QuickScanEndTime,FullScanEndTime",
      useFor:"Quickly verify Microsoft Defender service, real-time protection, signatures, and recent scan state.",
      keywords:"windows powershell defender antivirus real time protection signature scan security endpoint"
    },
    {
      name:"Print Jobs",
      platform:"Local Windows",
      access:"Read-only",
      code:'Get-Printer | ForEach-Object { Get-PrintJob -PrinterName $_.Name -ErrorAction SilentlyContinue }',
      useFor:"Find queued or stuck print jobs across installed printers.",
      keywords:"windows powershell printer print jobs queue stuck printing"
    },
    {
      name:"Spooler Status",
      platform:"Local Windows",
      access:"Read-only",
      code:"Get-Service Spooler",
      useFor:"Check whether the Windows Print Spooler service is running.",
      keywords:"windows powershell printer spooler service printing"
    },
    {
      name:"Connect Microsoft Graph",
      platform:"Microsoft Graph",
      access:"Read-only",
      input:"Delegated scopes required by your task. User.Read below is a basic signed-in-user example; use each task card's scopes for other operations.",
      requires:"Microsoft.Graph.Authentication; consent to the selected delegated scopes.",
      code:'Connect-MgGraph -Scopes "User.Read" -ContextScope Process',
      useFor:"Start a Microsoft Graph session with explicitly selected delegated permissions.",
      keywords:"graph connect session authentication microsoft graph powershell"
    },
    {
      name:"Show Code-Signing Certificates",
      platform:"PowerShell",
      access:"Read-only",
      code:"Get-ChildItem Cert:\\CurrentUser\\My -CodeSigningCert | Select-Object Subject,Thumbprint,NotAfter",
      keywords:"code signing certificate signature terminal health"
    }
  ].map((x, i) => ({
    ...x,
    type:"Quick Command",
    area:"Standalone",
    subarea:"",
    status:"Ready",
    source:"Standalone",
    input:x.input || "",
    output:"",
    file:"",
    related:[],
    notes:x.notes || "",
    useFor:x.useFor || "",
    url:"",
    _order:10000 + i
  }));

  const EXTRA_TOOLS = [
    {
      name:"Connection Patterns",
      type:"Documentation",
      area:"Tools",
      subarea:"Reference",
      platform:"Markdown",
      access:"Read-only",
      status:"Ready",
      source:"FIELD // KIT",
      file:"connection-patterns.md",
      publishedPath:"tools/connection-patterns.md",
      notes:"Reusable Graph, Exchange Online, and hybrid connection guidance without environment-specific identifiers.",
      keywords:"tools docs markdown connection graph exchange exo hybrid authentication reference",
      toolFacts:["Session reuse","Tenant validation","Least-privilege connections","Hybrid source-of-truth guidance"]
    },
    {
      name:"Operating Standards",
      type:"Documentation",
      area:"Tools",
      subarea:"Standards",
      platform:"Markdown",
      access:"Read-only",
      status:"Ready",
      source:"FIELD // KIT",
      file:"OPERATING-STANDARDS.md",
      publishedPath:"OPERATING-STANDARDS.md",
      notes:"Top-level project decision contract for canonical sources, 1-to-N input, safety, authentication, QA, release, and handoff/rebuild decisions.",
      keywords:"tools docs markdown operating standards canonical one-to-many safety authentication qa release handoff rebuild",
      toolFacts:["Canonical source model","1-to-N input standard","Hybrid authority rules","Safety and confirmation gates","Authentication / module rules","Static and runtime QA","Release workflow","Handoff / rebuild checklist"]
    },
    {
      name:"FIELD // KIT Build Standard",
      type:"Documentation",
      area:"Tools",
      subarea:"Standards",
      platform:"Markdown",
      access:"Read-only",
      status:"Ready",
      source:"FIELD // KIT",
      file:"field-kit-build-standard.md",
      publishedPath:"tools/field-kit-build-standard.md",
      notes:"Locked baseline for FIELD // KIT visual design, navigation, sorting, card behavior, source publication, and release validation.",
      keywords:"tools docs markdown field kit build standard design framework locked baseline",
      toolFacts:["Visual system","Navigation","Sorting","Card contract","Source behavior","Release checklist"]
    },
    {
      name:"Lessons Learned",
      type:"Documentation",
      area:"Tools",
      subarea:"Reference",
      platform:"Markdown",
      access:"Read-only",
      status:"Ready",
      source:"FIELD // KIT",
      file:"lessons-learned.md",
      publishedPath:"tools/lessons-learned.md",
      notes:"Small reusable rules captured from recurring PowerShell, authentication, hybrid, output, and publishing failures.",
      keywords:"tools docs markdown lessons gotchas failures reference",
      toolFacts:["PowerShell gotchas","Authentication lessons","Hybrid identity lessons","Publishing hygiene"]
    },
    {
      name:"PowerShell Standards",
      type:"Documentation",
      area:"Tools",
      subarea:"Standards",
      platform:"Markdown",
      access:"Read-only",
      status:"Ready",
      source:"FIELD // KIT",
      file:"powershell-standards.md",
      publishedPath:"tools/powershell-standards.md",
      notes:"Script implementation baseline for interactive FIELD // KIT PowerShell tools.",
      keywords:"tools docs markdown powershell standards build alignment coding style",
      toolFacts:["Compatibility","Authentication","Change safety","Output","Security","Validation"]
    },
    {
      name:"Publishing Checklist",
      type:"Documentation",
      area:"Tools",
      subarea:"Standards",
      platform:"Markdown",
      access:"Read-only",
      status:"Ready",
      source:"FIELD // KIT",
      file:"publishing-checklist.md",
      publishedPath:"tools/publishing-checklist.md",
      notes:"Final public-release gate for source, secrets, proprietary context, operational behavior, and catalog metadata.",
      keywords:"tools docs markdown publishing checklist secrets proprietary public release",
      toolFacts:["Secret scan","Environment scan","Operational review","Catalog review"]
    },
    {
      name:"Script Review Checklist",
      type:"Documentation",
      area:"Tools",
      subarea:"Standards",
      platform:"Markdown",
      access:"Read-only",
      status:"Ready",
      source:"FIELD // KIT",
      file:"script-review-checklist.md",
      publishedPath:"tools/script-review-checklist.md",
      notes:"Reusable pre-approval review covering syntax, structure, authentication, data handling, safety, output, and publication.",
      keywords:"tools docs markdown script review checklist validation parser",
      toolFacts:["Syntax","Structure","Authentication","Data handling","Changes","Security"]
    },
    {
      name:"Reusable Skills",
      type:"Documentation",
      area:"Tools",
      subarea:"Templates",
      platform:"Markdown",
      access:"Read-only",
      status:"Ready",
      source:"FIELD // KIT",
      file:"skills.md",
      publishedPath:"tools/skills.md",
      notes:"Repeatable workflows for building, reviewing, aligning, troubleshooting, publishing, and handing off FIELD // KIT work.",
      keywords:"tools docs markdown skills workflow reusable build review troubleshoot",
      toolFacts:["Build","Review","Align","Troubleshoot","Publish","Handoff"]
    },
    {
      name:"Script Template Guide",
      type:"Documentation",
      area:"Tools",
      subarea:"Templates",
      platform:"Markdown",
      access:"Read-only",
      status:"Ready",
      source:"FIELD // KIT",
      file:"script-template-guide.md",
      publishedPath:"tools/script-template-guide.md",
      notes:"Structural guide for single-objective tools, multi-section reviews, and connected workflows.",
      keywords:"tools docs markdown script template guide scaffold structure",
      toolFacts:["Recommended order","Three interaction levels","Prompting rules","Reuse guidance"]
    },
    {
      name:"NATO Phonetic Alphabet",
      type:"Documentation",
      area:"Tools",
      subarea:"Reference",
      platform:"Markdown",
      access:"Read-only",
      status:"Ready",
      source:"FIELD // KIT",
      file:"nato-phonetic-alphabet.md",
      publishedPath:"tools/nato-phonetic-alphabet.md",
      notes:"A-to-Z NATO spelling alphabet reference for clear verbal communication.",
      keywords:"alphabet phonetic alphabet nato spelling alphabet radio alphabet alpha bravo charlie x-ray whiskey reference",
      toolFacts:["A-Z spelling reference","Alpha through Zulu","Searchable by alphabet / phonetic / NATO"]
    },
    {
      name:"Update Project Artifact",
      type:"Tool",
      area:"Tools",
      subarea:"Repository",
      platform:"PowerShell + Git",
      access:"Change",
      status:"Ready",
      source:"FIELD // KIT",
      file:"git-handoff.ps1",
      version:"1.0.0",
      verification:{"version": "1.0.0", "sha256": "886a5782009fc8abf4825f997ccab38c0c1679a32b6653596089e038cf3ba22c", "operatorTested": true, "ownerAccepted": true, "testMode": "Offline scoped local/setup checks", "scope": "Metadata redaction and object-ID validation only; no repository reads or handoff writes.", "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"},
      publishedPath:"tools/git-handoff.ps1",
      notes:"Generates a repeatable context-state artifact from the Git repository containing the selected path. Captures branch, HEAD, upstream state, working-tree changes, stashes, recent commits, changes since the previous snapshot, and common project-document presence with readable names and best-effort sensitive-value redaction. Creates a local snapshot and local Git exclusion; does not stage, commit, fetch, or push. Review output before sharing. Run from a terminal; Windows validation pending.",
      keywords:"tools powershell git handoff snapshot context state artifact continuity repo repository session next conversation chatgpt",
      toolFacts:["Auto-detects repository root","Uses previous snapshot as the work boundary","Preserves readable names and summaries with targeted redaction","Writes .handoff/HANDOFF-SNAPSHOT.md and a local Git exclusion","Designed for ChatGPT project handoff"]
    },
    {
      name:"Project Handoff",
      type:"Documentation",
      area:"Tools",
      subarea:"Templates",
      platform:"Markdown",
      access:"Read-only",
      status:"Ready",
      source:"FIELD // KIT",
      file:"PROJECT-HANDOFF.md",
      publishedPath:"tools/PROJECT-HANDOFF.md",
      notes:"Canonical project handoff template for source of truth, local/remote state, locked decisions, validation status, limitations, and next-session startup.",
      keywords:"tools docs markdown project handoff template continuity source of truth commit branch runtime qa next session",
      toolFacts:["Source of truth","Local / remote state","Locked decisions","Static / runtime validation","Known limitations","Next session start"]
    }
  ].map((x, i) => ({
    ...x,
    requires:"",
    input:"",
    output:"",
    code:"",
    related:[],
    url:"",
    _order:30000 + i
  }));

  const EXTRA_RMM = [
    {
      name:"RMM BEC Risk Exposure Snapshot",
      type:"Tool",
      area:"Incident Response",
      subarea:"RMM",
      platform:"Datto RMM + Microsoft 365",
      access:"Read-only",
      status:"Ready",
      source:"RMM",
      file:"BEC-IR-M365-RISK-EXPOSURE-SNAPSHOT-v0.32-CHR.ps1",
      keywords:"rmm datto bec risk exposure security incident response"
    },
    {
      name:"RMM BEC Revoke Active Sessions",
      type:"Tool",
      area:"Incident Response",
      subarea:"RMM",
      platform:"Datto RMM + Microsoft 365",
      access:"Change",
      status:"Ready",
      source:"RMM",
      file:"BEC-IR-REVOKE-ACTIVE-SESSIONS-v2.0-CHR.ps1",
      keywords:"rmm datto bec active sessions revoke security incident response"
    }
  ].map((x, i) => ({
    ...x,
    requires:"",
    input:"",
    output:"",
    code:"",
    related:[],
    notes:"",
    url:"",
    _order:20000 + i
  }));

  const SPLIT_COMMAND_ARTIFACTS = new Set([
    "Show Activity From One Ip",
    "Show Sign-ins from One IP",
    '$Ip = "1.2.3.4"',
    "Look Up Isp And Location",
    '$Ip = "8.8.8.8"'
  ]);

  const rawItems = RAW.filter(item =>
    item &&
    item.status !== "Candidate" &&
    item.status !== "External Reference" &&
    item.status !== "Private" &&
    item.type !== "Runbook" &&
    item.type !== "Reference" &&
    !SPLIT_COMMAND_ARTIFACTS.has(String(item.name || "")) &&
    !isRmm(item)
  );

  const EXTRA_PUBLIC_TOOLS = [
  {
  "name": "Git Repository Tools",
  "area": "Tools",
  "subarea": "Repository",
  "platform": "PowerShell + Git",
  "access": "Change",
  "file": "git-repo.ps1",
  "publishedPath": "tools/git-repo.ps1",
  "notes": "Standalone Git check, push and pull using the current repository or -Path. Default: -Action Check; add -Details for file names. -Action Push previews changes and requires typed approval before staging, committing and pushing. -Action Pull refuses a dirty tree and only fast-forwards. Run in a terminal; no profile dependency. File-name checks are not a secret scanner.",
  "keywords": "git check details send it grab it push pull repository status commit standalone",
  "toolFacts": [
    "Check: local status and known upstream counts; no fetch",
    "Push: preview and typed approval; no force push",
    "Pull: clean working tree and fast-forward only",
    "One standalone file; Windows Git required"
  ],
  "type": "Tool",
  "status": "Ready",
  "source": "FIELD // KIT",
  "requires": "",
  "input": "",
  "output": "",
  "code": "",
  "related": [],
  "url": "",
  "_order": 32000,
  "version": "1.0.0",
  "verification": {
    "version": "1.0.0",
    "sha256": "cd0c87313d27c17cd79a82f470991aad016583781066f856841cc251f245afdd",
    "operatorTested": true,
    "ownerAccepted": true,
    "testMode": "Offline scoped local/setup checks",
    "scope": "Changed-filename risk screening with synthetic Git status; no real Git commands, commit, push or pull.",
    "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
  }
},
  {
    "name": "GitHub Security Check",
    "area": "Tools",
    "subarea": "Repository",
    "platform": "PowerShell + GitHub",
    "access": "Change",
    "file": "git-security.ps1",
    "publishedPath": "tools/git-security.ps1",
    "notes": "Run .\\git-security.ps1 -Account your-github-handle. Export JSON from GitHub, then press Enter for the newest matching download. Shows actionable unreviewed access/security events. Complete reviews without flags update a local checkpoint; flagged exports require explicit acknowledgement. Changes local history only, never GitHub settings. ALL CLEAR means no rule matches, not proof of no compromise.",
    "keywords": "git security github audit log export json gzip zip baseline checkpoint permissions recovery",
    "toolFacts": [
      "Reads JSON, JSON.GZ and ZIP locally",
      "Date, affected app/repository and next action",
      "Remembers exact reviewed records, not trusted identities",
      "No API token; manual GitHub export"
    ],
    "type": "Tool",
    "status": "Ready",
    "source": "FIELD // KIT",
    "requires": "",
    "input": "",
    "output": "",
    "code": "",
    "related": [],
    "url": "",
    "_order": 32001
  },
  {
  "name": "Script Setup",
  "area": "Tools",
  "subarea": "Setup",
  "platform": "PowerShell",
  "access": "Change",
  "file": "set-execution.ps1",
  "publishedPath": "tools/set-execution.ps1",
  "notes": "Explicit local setup utility. Checks effective execution policy, sets CurrentUser RemoteSigned only when needed and not managed, and unblocks adjacent .ps1 files. Run only in a folder of scripts you have reviewed. Does not sign files or install modules. Colored result; Enter to exit.",
  "keywords": "set execution policy remotesigned unblock scripts local setup signing preparation",
  "toolFacts": [
    "Checks effective policy before changing it",
    "Respects managed execution policy",
    "Unblocks .ps1 files beside this script",
    "No module installs or digital signing"
  ],
  "type": "Tool",
  "status": "Ready",
  "source": "FIELD // KIT",
  "requires": "",
  "input": "",
  "output": "",
  "code": "",
  "related": [],
  "url": "",
  "_order": 32002,
  "version": "1.0.0",
  "verification": {
    "version": "1.0.0",
    "sha256": "90464f2b844266bdf88c5956fc44dd34939cf7c8664ac19c90f4be4defec2bc4",
    "operatorTested": true,
    "ownerAccepted": true,
    "testMode": "Offline scoped behavioral checks; no live-service claim",
    "scope": "Simulated execution-policy/unblock workflow; managed policy preserved; no real policy/unblock changes.",
    "evidence": "docs/qa/BATCH-4-1.0.0-VERIFICATION.md"
  }
},
  {
    "name": "Git Tools Quick Start",
    "area": "Tools",
    "subarea": "Reference",
    "platform": "Markdown",
    "access": "Read-only",
    "file": "git-tools.md",
    "publishedPath": "tools/git-tools.md",
    "type": "Documentation",
    "notes": "Commands and operating boundaries for the standalone repository, security, handoff and execution-setup helpers.",
    "keywords": "git tools documentation check push pull security handoff setup",
    "toolFacts": [
      "Standalone commands",
      "Checkpoint acknowledgement",
      "Public-source safety boundaries"
    ],
    "status": "Ready",
    "source": "FIELD // KIT",
    "requires": "",
    "input": "",
    "output": "",
    "code": "",
    "related": [],
    "url": "",
    "_order": 32003
  },
  {
    "name": "Attractor",
    "area": "Toys",
    "subarea": "Animations",
    "platform": "PowerShell 7 + Windows Terminal",
    "access": "Read-only",
    "file": "attractor.ps1",
      version:"1.0.0",
      verification:{"version": "1.0.0", "sha256": "62820d67085b65d230bb28c4954259bd32bffd29f30aee8a6f9a2cdfcdfdc5aa", "operatorTested": true, "ownerAccepted": true, "testMode": "Native separate-window operator review", "scope": "Native separate-window preview; theme profile redirected; operator-reviewed appearance.", "evidence": "docs/qa/NATIVE-1.0.0-VERIFICATION.md"},
    "publishedPath": "toys/attractor.ps1",
    "notes": "Slowly evolving Clifford attractor with floating branding and a 24-hour clock. Run in an interactive terminal, ideally 60 columns by 22 rows or larger. Ctrl+C stops it. Cosmetic terminal effects only; no network access or file writes. Not a screen lock.",
    "keywords": "toys screensaver terminal animation attractor",
    "toolFacts": [
      "Terminal-only animation",
      "Cyan / magenta / dim palette",
      "24-hour clock",
      "Ctrl+C to stop"
    ],
    "type": "Tool",
    "status": "Ready",
    "source": "FIELD // KIT",
    "requires": "",
    "input": "",
    "output": "",
    "code": "",
    "related": [],
    "url": "",
    "_order": 32004
  },
  {
    "name": "Rain",
    "area": "Toys",
    "subarea": "Animations",
    "platform": "PowerShell 7 + Windows Terminal",
    "access": "Read-only",
    "file": "rain.ps1",
      version:"1.0.0",
      verification:{"version": "1.0.0", "sha256": "67ff5ccad0eb69510576920fd8b36accfb606a2b1cd3ddeb1ae75f021fda9bc9", "operatorTested": true, "ownerAccepted": true, "testMode": "Native separate-window operator review", "scope": "Native separate-window preview; theme profile redirected; operator-reviewed appearance.", "evidence": "docs/qa/NATIVE-1.0.0-VERIFICATION.md"},
    "publishedPath": "toys/rain.ps1",
    "notes": "Dense neon character rain, intermittent signal effects and a 24-hour clock. Run in an interactive terminal, ideally 60 columns by 22 rows or larger. Ctrl+C stops it. Cosmetic terminal effects only; no network access or file writes. Not a screen lock.",
    "keywords": "toys screensaver terminal animation rain",
    "toolFacts": [
      "Terminal-only animation",
      "Cyan / magenta / dim palette",
      "24-hour clock",
      "Ctrl+C to stop"
    ],
    "type": "Tool",
    "status": "Ready",
    "source": "FIELD // KIT",
    "requires": "",
    "input": "",
    "output": "",
    "code": "",
    "related": [],
    "url": "",
    "_order": 32005
  },
  {
    "name": "Static",
    "area": "Toys",
    "subarea": "Animations",
    "platform": "PowerShell 7 + Windows Terminal",
    "access": "Read-only",
    "file": "static.ps1",
      version:"1.0.0",
      verification:{"version": "1.0.0", "sha256": "75f06611710a84f21522226fffebb3bf2e6a6b5d58383baf507ba6c69ddf19ca", "operatorTested": true, "ownerAccepted": true, "testMode": "Native separate-window operator review", "scope": "Native separate-window preview; theme profile redirected; operator-reviewed appearance.", "evidence": "docs/qa/NATIVE-1.0.0-VERIFICATION.md"},
    "publishedPath": "toys/static.ps1",
    "notes": "Sparse pulsing dots, subtle static and drifting branding with a 24-hour clock. Run in an interactive terminal, ideally 60 columns by 22 rows or larger. Ctrl+C stops it. Cosmetic terminal effects only; no network access or file writes. Not a screen lock.",
    "keywords": "toys screensaver terminal animation static",
    "toolFacts": [
      "Terminal-only animation",
      "Cyan / magenta / dim palette",
      "24-hour clock",
      "Ctrl+C to stop"
    ],
    "type": "Tool",
    "status": "Ready",
    "source": "FIELD // KIT",
    "requires": "",
    "input": "",
    "output": "",
    "code": "",
    "related": [],
    "url": "",
    "_order": 32006
  }
];

  const UPLOADED_TOOLS = [
  {
    "name": "Digital Signature",
    "file": "SIGN-FOLDER-SCRIPTS.ps1",
      version:"1.0.0",
      verification:{"version": "1.0.0", "sha256": "9b2d82c75017899485b76d227e323deca66c6660534e83c1238938f058d454a1", "operatorTested": true, "ownerAccepted": true, "testMode": "Native separate-window operator review", "scope": "Operator-selected certificate/signing wizard steps; dummy signing folder; native approvals preserved.", "evidence": "docs/qa/NATIVE-1.0.0-VERIFICATION.md"},
    "publishedPath": "tools/SIGN-FOLDER-SCRIPTS.ps1",
    "area": "Tools",
    "subarea": "Setup",
    "objective": "Sign reviewed PowerShell scripts with a certificate you choose.",
    "notes": "Uses an existing certificate or creates a local self-signed certificate. Optional trust adds it to the current-user TrustedPublisher and Root stores. Shows files and asks before signing; -ForceResign replaces existing signatures.",
    "requires": "Windows PowerShell 5.1+ or PowerShell 7",
    "toolFacts": [
      "Includes subfolders",
      "Skips valid signatures from the selected certificate unless forced",
      "Checks each signing result"
    ],
    "access": "Change",
    "type": "Tool",
    "status": "Ready",
    "source": "FIELD // KIT",
    "keywords": "Digital Signature tools/SIGN-FOLDER-SCRIPTS.ps1",
    "input": "Folder + signing certificate",
    "output": "",
    "code": "",
    "related": [],
    "url": ""
  },
  {
  "name": "Terminal Readiness",
  "file": "GET-TERMINAL-READINESS-CHECK.ps1",
  "publishedPath": "tools/GET-TERMINAL-READINESS-CHECK.ps1",
  "area": "Tools",
  "subarea": "Setup",
  "objective": "Check the shell, modules, signing certificates, and expected toolkit files.",
  "notes": "This checks a fixed toolkit layout, not just PowerShell. Review $ExpectedFolders and $ExpectedFiles for your installation. Missing layout files are reported as failures. Root defaults to C:\\Field-Kit and can be changed at the prompt.",
  "requires": "Windows PowerShell 5.1+ or PowerShell 7",
  "toolFacts": [],
  "access": "Read-only",
  "type": "Tool",
  "status": "Ready",
  "source": "FIELD // KIT",
  "keywords": "Terminal Readiness tools/GET-TERMINAL-READINESS-CHECK.ps1",
  "input": "",
  "output": "",
  "code": "",
  "related": [],
  "url": "",
  "version": "1.0.0",
  "verification": {
    "version": "1.0.0",
    "sha256": "fcb2a3383b43915e88dc3e819ba6f573dafb2dc256b008d1d896535bb7dae991",
    "operatorTested": true,
    "ownerAccepted": true,
    "testMode": "Offline scoped local/setup checks",
    "scope": "Relative-path presentation only; no installed-module, signature or certificate readiness claim.",
    "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
  }
},
  {
    "name": "File Inventory",
    "file": "INVOKE-FILE-INVENTORY.ps1",
    "publishedPath": "tools/INVOKE-FILE-INVENTORY.ps1",
    "area": "Tools",
    "subarea": "Repository",
    "objective": "Find duplicate scripts, signature problems, and leftover working copies.",
    "notes": "Groups files into Active, Testing, and Archive; compares duplicate filenames by SHA256. Optional CSV export includes local paths and signer details. Root defaults to C:\\Field-Kit; keep reports private.",
    "requires": "Windows PowerShell 5.1+ or PowerShell 7",
    "toolFacts": [
      "Compares duplicate filenames and hashes",
      "Checks active-script signatures",
      "Exports CSV only when requested"
    ],
    "access": "Read-only",
    "type": "Tool",
    "status": "Ready",
    "source": "FIELD // KIT",
    "keywords": "File Inventory tools/INVOKE-FILE-INVENTORY.ps1",
    "input": "",
    "output": "",
    "code": "",
    "related": [],
    "url": "",
    "version": "1.0.0",
    "verification": {
      "version": "1.0.0",
      "sha256": "acb04fd3968ef3a29356ef52583229a72926f7a6ed319b4b36bd01e56de28445",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Synthetic local fixture / host read-only check",
      "evidence": "docs/qa/BATCH-2-1.0.0-VERIFICATION.md"
    }
  },
  {
  "name": "Folder Map",
  "file": "INVOKE-MAP-KIT.ps1",
  "publishedPath": "tools/INVOKE-MAP-KIT.ps1",
  "area": "Tools",
  "subarea": "Repository",
  "objective": "Show a folder tree, script counts, signatures, and file warnings.",
  "notes": "Uses root detection or -RootPath; confirms the selected folder. Reports naming and file-extension warnings, not a full secret scan. Does not enforce a fixed layout or export files.",
  "requires": "Windows PowerShell 5.1+ or PowerShell 7",
  "toolFacts": [],
  "access": "Read-only",
  "type": "Tool",
  "status": "Ready",
  "source": "FIELD // KIT",
  "keywords": "Folder Map tools/INVOKE-MAP-KIT.ps1",
  "input": "",
  "output": "",
  "code": "",
  "related": [],
  "url": "",
  "version": "1.0.0",
  "verification": {
    "version": "1.0.0",
    "sha256": "330fb1fc8cc144b3f9cd23a0e3399a2f69d168b31b6a9fe27c255e0c77ffdf2b",
    "operatorTested": true,
    "ownerAccepted": true,
    "testMode": "Offline scoped behavioral checks; no live-service claim",
    "scope": "Actual map workflow against a tiny disposable folder, including missing path; signatures skipped.",
    "evidence": "docs/qa/BATCH-4-1.0.0-VERIFICATION.md"
  }
},
  {
  "name": "Session Reset",
  "file": "INVOKE-SESSION-RESET.ps1",
  "publishedPath": "tools/INVOKE-SESSION-RESET.ps1",
  "area": "Tools",
  "subarea": "Setup",
  "objective": "Disconnect local Graph and Exchange sessions and clear session errors.",
  "notes": "Run in the terminal you want to reset. Asks before cleanup; can clear the optional JumpboxSessionPassword profile variable and open a fresh PowerShell 7 window. Does not change tenant settings.",
  "requires": "Windows PowerShell 5.1+ or PowerShell 7",
  "toolFacts": [],
  "access": "Change",
  "type": "Tool",
  "status": "Ready",
  "source": "FIELD // KIT",
  "keywords": "Session Reset tools/INVOKE-SESSION-RESET.ps1",
  "input": "",
  "output": "",
  "code": "",
  "related": [],
  "url": "",
  "version": "1.0.0",
  "verification": {
    "version": "1.0.0",
    "sha256": "4de135e684e778e091292f7fe56610ddee47739c15d34dda5367cbe3112a15bc",
    "operatorTested": true,
    "ownerAccepted": true,
    "testMode": "Offline scoped behavioral checks; no live-service claim",
    "scope": "Simulated jumpbox reset workflow; no password variable removal, disconnections or new windows.",
    "evidence": "docs/qa/BATCH-4-1.0.0-VERIFICATION.md"
  }
},
  {
    "name": "Basic",
    "file": "SET-THEME-BASIC.ps1",
      version:"1.0.0",
      verification:{"version": "1.0.0", "sha256": "82ddf2ed63914b6a1eb40664f486783e59690799b8df19bf9f00fbd3dc142756", "operatorTested": true, "ownerAccepted": true, "testMode": "Native separate-window operator review", "scope": "Native separate-window preview; theme profile redirected; operator-reviewed appearance.", "evidence": "docs/qa/NATIVE-1.0.0-VERIFICATION.md"},
    "publishedPath": "toys/SET-THEME-BASIC.ps1",
    "area": "Toys",
    "subarea": "Themes",
    "objective": "Preview plain terminal output and reusable message helpers.",
    "notes": "Prints example messages and waits for Enter. No persistent theme changes. Example output is demonstration data.",
    "requires": "Windows PowerShell 5.1+ or PowerShell 7",
    "toolFacts": [],
    "access": "Read-only",
    "type": "Tool",
    "status": "Ready",
    "source": "FIELD // KIT",
    "keywords": "Basic toys/SET-THEME-BASIC.ps1",
    "input": "",
    "output": "",
    "code": "",
    "related": [],
    "url": ""
  },
  {
    "name": "Cobalt",
    "file": "SET-THEME-COBALT.ps1",
      version:"1.0.0",
      verification:{"version": "1.0.0", "sha256": "3d0dbac577cce716e5427a9b2635ee6cefe29a45955bc632cb8b4f2dd48fe343", "operatorTested": true, "ownerAccepted": true, "testMode": "Native separate-window operator review", "scope": "Native separate-window preview; theme profile redirected; operator-reviewed appearance.", "evidence": "docs/qa/NATIVE-1.0.0-VERIFICATION.md"},
    "publishedPath": "toys/SET-THEME-COBALT.ps1",
    "area": "Toys",
    "subarea": "Themes",
    "objective": "Preview the Cobalt color palette and message styles.",
    "notes": "Changes this terminal’s appearance and sets Process execution policy to Bypass. Prints a palette reference; does not install a persistent theme. Requires an ANSI-capable terminal.",
    "requires": "Windows PowerShell 5.1+ or PowerShell 7",
    "toolFacts": [],
    "access": "Change",
    "type": "Tool",
    "status": "Ready",
    "source": "FIELD // KIT",
    "keywords": "Cobalt toys/SET-THEME-COBALT.ps1",
    "input": "",
    "output": "",
    "code": "",
    "related": [],
    "url": ""
  },
  {
    "name": "Sea Glass",
    "file": "SET-THEME-SEAGLASS.ps1",
      version:"1.0.0",
      verification:{"version": "1.0.0", "sha256": "16153f1c1989834f659ec7c08546c454dd95bdc51abebb2f7afb684b70964fdf", "operatorTested": true, "ownerAccepted": true, "testMode": "Native separate-window operator review", "scope": "Native separate-window preview; theme profile redirected; operator-reviewed appearance.", "evidence": "docs/qa/NATIVE-1.0.0-VERIFICATION.md"},
    "publishedPath": "toys/SET-THEME-SEAGLASS.ps1",
    "area": "Toys",
    "subarea": "Themes",
    "objective": "Apply Sea Glass colors now and when PowerShell starts.",
    "notes": "Writes CurrentUserAllHosts profile and replaces recognized theme blocks. Also sets Process execution policy to Bypass. Review your profile before running; remove the SEA GLASS THEME block to undo persistence.",
    "requires": "Windows PowerShell 5.1+ or PowerShell 7",
    "toolFacts": [],
    "access": "Change",
    "type": "Tool",
    "status": "Ready",
    "source": "FIELD // KIT",
    "keywords": "Sea Glass toys/SET-THEME-SEAGLASS.ps1",
    "input": "",
    "output": "",
    "code": "",
    "related": [],
    "url": ""
  },
  {
    "name": "Silicon Valley",
    "file": "SET-THEME-SILICON-VALLEY.ps1",
      version:"1.0.0",
      verification:{"version": "1.0.0", "sha256": "1c732aa6c82182265dc02019c9805a7ac9faec56e7b3312e8d7b00c7d66dd60d", "operatorTested": true, "ownerAccepted": true, "testMode": "Native separate-window operator review", "scope": "Native separate-window preview; theme profile redirected; operator-reviewed appearance.", "evidence": "docs/qa/NATIVE-1.0.0-VERIFICATION.md"},
    "publishedPath": "toys/SET-THEME-SILICON-VALLEY.ps1",
    "area": "Toys",
    "subarea": "Themes",
    "objective": "Apply Silicon Valley colors, keyboard shortcuts, and a startup banner.",
    "notes": "Rewrites recognized theme blocks in CurrentUserAllHosts profile. Also installs and displays a date-seeded daily password generator. Its output is predictable: do not use it as a password. Remove the SILICON VALLEY THEME block to undo persistence.",
    "requires": "Windows PowerShell 5.1+ or PowerShell 7",
    "toolFacts": [],
    "access": "Change",
    "type": "Tool",
    "status": "Ready",
    "source": "FIELD // KIT",
    "keywords": "Silicon Valley toys/SET-THEME-SILICON-VALLEY.ps1",
    "input": "",
    "output": "",
    "code": "",
    "related": [],
    "url": ""
  },
  {
    "name": "Signing Certificates",
    "file": "MANAGE-CERT-SIGNATURES.ps1",
      version:"1.0.0",
      verification:{"version": "1.0.0", "sha256": "11544fc1bdedfe8e1e7ff69c1abb084cd5001132c40178782bd21281150c2cb8", "operatorTested": true, "ownerAccepted": true, "testMode": "Native separate-window operator review", "scope": "Operator-selected certificate/signing wizard steps; dummy signing folder; native approvals preserved.", "evidence": "docs/qa/NATIVE-1.0.0-VERIFICATION.md"},
    "publishedPath": "tools/MANAGE-CERT-SIGNATURES.ps1",
    "area": "Tools",
    "subarea": "Setup",
    "type": "Tool",
    "access": "Change",
    "status": "Ready",
    "objective": "Create and manage certificates used to sign PowerShell scripts.",
    "toolFacts": [
      "Create a self-signed certificate",
      "Check and configure current-user trust",
      "Import or export certificates when requested"
    ],
    "requires": "Windows PowerShell 5.1 or later",
    "input": "Choose a certificate action",
    "notes": "Public .cer files share trust. Private .pfx files include the signing key and require explicit confirmation and a password. Lists certificates installed for the current user; select your own signing identity.",
    "keywords": "signing certificate trust import export digital signature",
    "code": "",
    "url": "",
    "related": []
  }
];

  const allSource = [...rawItems, ...EXTRA_RMM, ...EXTRA_STANDALONE, ...EXTRA_TOOLS, ...EXTRA_PUBLIC_TOOLS, ...UPLOADED_TOOLS];

  const esc = value => String(value ?? "")
    .replace(/&/g,"&amp;")
    .replace(/</g,"&lt;")
    .replace(/>/g,"&gt;")
    .replace(/"/g,"&quot;")
    .replace(/'/g,"&#039;");

  const norm = value => String(value ?? "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g," ")
    .trim();

  const words = value => norm(value).split(/\s+/).filter(Boolean);

  function isRmm(item){
    return /\brmm\b|datto/i.test([
      item.name,item.subarea,item.platform,item.source,item.file
    ].join(" "));
  }

  function logicalArea(item){
    if (item.area === "Tools") return "Tools";
    if (item.area === "Toys") return "Toys";
    if (/user profile backup/i.test(item.name || "")) return "Identity";
    if (item.type === "Quick Command" && item.name !== "Revoke Active Sessions") return "Standalone";
    if (/security\s*\/\s*ir|incident/i.test(item.area || "")) return "Incident Response";
    if (isRmm(item)) return "RMM";
    if (item.type === "Quick Command" || item.area === "Standalone") return "Standalone";
    if (/mailbox/i.test(item.area || "")) return "Mailbox";
    if (/identity|groups|reporting\s*\/\s*audit/i.test(item.area || "")) return "Identity";
    if (/utilities|endpoint|network/i.test(item.area || "")) return "Utility";
    return "Utility";
  }

  function displayName(item){
    const approved = window.FIELD_KIT_OPERATOR_CARDS?.[item.file];
    if (approved) return approved.name;
    let name = String(item.name || item.file || "Untitled").trim();
    name = name.replace(/^1[-_ ]+/i,"").replace(/^2[-_ ]+/i,"");
    name = name.replace(/-CHR\b/ig,"").replace(/\s{2,}/g," ").trim();

    if (/^Show Password Last Changed And Age$/i.test(name)) return "Show Password Age";
    if (/^Show All Authentication Methods For One User$/i.test(name)) return "Show MFA Methods";
    if (/^BEC \/ Account Compromise Discovery$/i.test(name)) return "BEC: Assess User Risk";
    if (/^BEC \/ Account Compromise Execution$/i.test(name)) return "BEC: Contain and Clean Up";
    if (/^Revoke Active Sessions$/i.test(name)) return "Incident Response: Revoke Sessions";
    if (/^Kit Preflight$/i.test(name)) return "PowerShell Readiness Check";
    if (/^Map Service Desk Kit$/i.test(name)) return "Folder Inventory";
    if (/^Reset PowerShell Sessions$/i.test(name)) return "M365 Session Reset";
    if (/^Winget Updates$/i.test(name)) return "Windows App Updates";
    if (/^Show Inbox Rules$/i.test(name) && /IncludeHidden/i.test(item.code || "")) return "Show Inbox Rules - Hidden";
    if (/Mailitemsaccessed/i.test(name)) return name.replace(/Mailitemsaccessed/ig,"Mail Items Accessed");

    return name.replace(/^IR:\s*/i,"Incident Response: ");
  }

  function groupFor(item, area){
    const name = displayName(item);
    const file = item.file || "";
    const combined = [name,file,item.subarea,item.platform,item.code].join(" ");

    if (area === "Tools" || area === "Toys"){
      return item.subarea || "Reference";
    }

    if (area === "Standalone"){
      if (/winget/i.test(combined)) return "WinGet";
      if (/PowerShell|execution policy|code-signing|terminal/i.test(combined) &&
          !/Microsoft Graph|Exchange Online/i.test(item.platform || "")) return "Terminal";
      if (/Exchange Online/i.test(item.platform || "")) return "Exchange";
      if (/Microsoft Graph/i.test(item.platform || "")) return "Graph";
      if (/Active Directory/i.test(item.platform || "")) return "Active Directory";
      if (/network|dns|tcp|ping|tracert|pathping|route|wifi|wlan|netadapter|winsock|ipconfig|nslookup|netstat|\barp\b|firewall|proxy/i.test(combined)) return "Network CLI";
      return "Windows CLI";
    }

    if (area === "Identity"){
      if (/^1[-_]/i.test(file) || /^1[-_]/i.test(item.name || "")) return "Single User";
      if (/^2[-_]/i.test(file) || /^2[-_]/i.test(item.name || "")) return "Multi User";
      if (/tenant/i.test(combined)) return "Tenant";
      return "General";
    }

    if (area === "Mailbox"){
      if (/^1[-_]/i.test(file) || /^1[-_]/i.test(item.name || "")) return "Single User";
      if (/^2[-_]/i.test(file) || /^2[-_]/i.test(item.name || "")) return "Multi User";
      return "General";
    }

    if (area === "Incident Response"){
      if (/^IR:|risk exposure|account compromise|bec|revoke active sessions/i.test(name)) return "Account Response";
      if (/investigat|timeline|token|threat|trace|exfil|email search/i.test(combined)) return "Investigation";
      if (/recover|response|eradicate/i.test(name)) return "Response";
      return "General";
    }

    if (area === "RMM"){
      if (/onboard|offboard/i.test(combined)) return "On / Offboarding";
      if (/group|membership|license|access/i.test(combined)) return "Access";
      if (/bec|incident|risk|security/i.test(combined)) return "Security";
      if (/audit|review|report/i.test(combined)) return "Audit";
      if (/mailbox|forward|inbox/i.test(combined)) return "Mailbox";
      return "Identity";
    }

    if (area === "Utility"){
      if (/sensitive data|sanit|publish/i.test(combined)) return "Publishing";
      if (/m365|microsoft 365|graph|exchange|session/i.test(combined)) return "Microsoft 365";
      if (/folder inventory|repository|repo|tree|file map/i.test(combined)) return "Repository";
      if (/readiness|workstation|terminal|powershell/i.test(combined)) return "Device";
      if (/winget|windows app updates/i.test(combined)) return "WinGet";
      return "General";
    }

    if (/winget/i.test(combined)) return "WinGet";
    if (/profile|field-kit|jumpbox|session|powershell/i.test(combined)) return "Terminal / Field-Kit";
    return "General";
  }


  const CURATED = [
    {
      match:/tenant-device-code-exposure|Device Code Exposure Audit/i,
      connect:['Connect-MgGraph -Scopes "Policy.Read.ConditionalAccess","AuditLog.Read.All","Directory.Read.All"'],
      label:"CHECKS",
      facts:["Conditional Access device-code blocking","Recent device-code sign-ins","Device-code exposure indicators"]
    },
    {
      match:/tenant-app-registrations|App Registration Audit/i,
      connect:['Connect-MgGraph -Scopes "Application.Read.All","Directory.Read.All"'],
      label:"CHECKS",
      facts:["App registrations","Expired / expiring secrets","Expired / expiring certificates","Risky application permissions","Application owners"]
    },
    {
      match:/tenant-cap-gaps|Conditional Access Gaps/i,
      connect:['Connect-MgGraph -Scopes "Policy.Read.ConditionalAccess","Directory.Read.All","User.Read.All"'],
      label:"CHECKS",
      facts:["Disabled policies","Report-only policies","User / group exclusions","Device-code gaps","Location conditions","Weak coverage indicators"]
    },
    {
      match:/tenant-mfa-security|MFA Security Audit/i,
      connect:['Connect-MgGraph -Scopes "User.Read.All","Directory.Read.All","Reports.Read.All","UserAuthenticationMethod.Read.All"'],
      label:"CHECKS",
      facts:["MFA registration","MFA capability","Registered methods","Phishing-resistant methods","No-MFA users","Weak-only MFA","Conditional Access coverage when requested"]
    },
    {
      match:/tenant-secure-score|Secure Score Snapshot/i,
      connect:['Connect-MgGraph -Scopes "SecurityEvents.Read.All","SecurityActions.Read.All","Directory.Read.All"'],
      label:"CHECKS",
      facts:["Current Secure Score","Maximum score","Enabled control scores","Previous snapshot comparison when supplied"]
    },
    {
      match:/tenant-signin-anomalies|Sign-in Anomalies Audit/i,
      connect:['Connect-MgGraph -Scopes "AuditLog.Read.All","User.Read.All","Directory.Read.All"'],
      label:"CHECKS",
      facts:["Recent sign-ins","Foreign successful sign-ins","Country changes","Device-code activity","New-IP non-interactive success"]
    },
    {
      match:/tenant-service-principal-owners|Service Principal Owners Audit/i,
      connect:['Connect-MgGraph -Scopes "Application.Read.All","Directory.Read.All","User.Read.All"'],
      label:"CHECKS",
      facts:["Service principals","Service-principal owners","User-owned service principals","Service principals with no owners"]
    },
    {
      match:/shared-mailbox-signin|Shared Mailbox Sign-in Audit/i,
      connect:['Connect-ExchangeOnline','Connect-MgGraph -Scopes "AuditLog.Read.All","User.Read.All","Directory.Read.All"'],
      label:"CHECKS",
      facts:["Shared mailboxes","Recent shared-mailbox sign-ins","Successful direct sign-ins"]
    },
    {
      match:/transport-rules|Transport Rules Audit/i,
      connect:['Connect-ExchangeOnline'],
      label:"CHECKS",
      facts:["Tenant transport rules","BCC actions","Redirect actions","Forwarding actions","Delete / quarantine actions","External-recipient actions"]
    },
    {
      match:/GET-USER-MAILBOX-SNAPSHOT|Mailbox Security Snapshot/i,
      connect:['Connect-ExchangeOnline'],
      label:"CHECKS",
      facts:[
        "Forwarding status",
        "Inbox rules",
        "Mailbox permissions",
        "Delegated access",
        "Send As / Send on Behalf",
        "Exposure indicators"
      ],
      note:"Reviews the selected user's mailbox state and surfaces the details that change the next decision without burying the operator in metadata."
    },
    {
      match:/GET-MAILBOX-PERMISSIONS|Mailbox Permissions Review|Mailbox Forwarding and Permission Audit/i,
      connect:['Connect-ExchangeOnline'],
      label:"CHECKS",
      facts:["One mailbox or TXT / CSV input","Forwarding","Mailbox delegates","Inbox rules","Full Access","Send As","Query failures remain visible"]
    },
    {
      match:/GET-MAILBOX-FORWARDING|Mailbox Forwarding Check/i,
      connect:['Connect-ExchangeOnline'],
      label:"CHECKS",
      facts:["One mailbox or TXT / CSV input","Mailbox-level forwarding","Deliver-to-mailbox-and-forward state","Visible and hidden inbox-rule forwarding","Redirect and forward-as-attachment actions","Query failures","Verified CSV when requested"]
    },
    {
      match:/INVOKE-ENFORCE-PER-USER-MFA_DEFAULT|Enforce Per-user MFA/i,
      label:"DOES",
      facts:[
        "Targets one user",
        "Enforces per-user MFA",
        "Uses the preferred authentication flow",
        "Requires appropriate tenant admin rights"
      ]
    },
    {
      match:/UPDATE-WINDOWS-APPS|Windows App Updates/i,
      label:"DOES",
      facts:["Shows available WinGet upgrades","Supports review-only mode","Confirms before changes","Updates normally eligible packages","Shows remaining upgrades"]
    },
    {
      match:/TEST-POWERSHELL-READINESS|PowerShell Readiness Check/i,
      label:"CHECKS",
      facts:["PowerShell version","Execution policy","Elevation state","Git and WinGet","PowerShellGet / PSGallery","Graph and Exchange modules","Optional Active Directory module","Active M365 sessions"]
    },
    {
      match:/RESET-M365-SESSION|M365 Session Reset/i,
      label:"DOES",
      facts:["Disconnects Exchange Online","Disconnects Microsoft Graph","Removes legacy Exchange PSSessions","Clears the local PowerShell error buffer","Optionally launches a fresh PowerShell 7 window"]
    },
    {
      match:/GET-FOLDER-INVENTORY|Folder Inventory/i,
      label:"CHECKS",
      facts:["Folder tree","File map","Per-folder counts","PowerShell script types","Authenticode signature state","Git branch and working-tree status"]
    },
    {
      match:/INSTALL-M365-MODULES|M365 Module Setup/i,
      label:"DOES",
      facts:["Installs Microsoft Graph","Installs ExchangeOnlineManagement","Supports Graph / Exchange / Both selection","Uses CurrentUser scope","Does not connect to a tenant"]
    },
    {
      match:/TEST-SENSITIVE-DATA|Sensitive Data Check/i,
      label:"CHECKS",
      facts:["Secret-like literals","Private-key / token material","Tenant or app GUIDs","Email addresses / UPNs","URLs and local paths","UNC paths","Authenticode blocks","Optional custom terms"]
    },
    {
      match:/INVOKE-ASSIGN-LICENSES|Assign User Licenses/i,
      connect:['Connect-MgGraph -Scopes "User.ReadWrite.All","Directory.Read.All","Organization.Read.All"'],
      label:"GUARDS",
      facts:["One user or TXT / CSV input","Tenant SKU inventory","UsageLocation handling when approved","Full preview before changes","Typed ASSIGN confirmation","Per-user post-change SKU verification","Verified CSV when requested"]
    },
    {
      match:/INVOKE-REMOVE-LICENSES|Remove User Licenses/i,
      connect:['Connect-MgGraph -Scopes "User.ReadWrite.All","Directory.Read.All","Organization.Read.All"'],
      label:"GUARDS",
      facts:["One user or TXT / CSV input","Current-license review","Numbered license selection or ALL","Full plan before changes","Typed REMOVE confirmation","Per-user post-change SKU verification","Verified CSV when requested"]
    },
    {
      match:/INVOKE-CREATE-DYNAMIC-LICENSE-GROUP|Create Dynamic License Group/i,
      connect:['Connect-MgGraph -Scopes "Group.ReadWrite.All","Directory.Read.All"'],
      label:"GUARDS",
      facts:["Single group creation","Dynamic security group","Enabled licensed-user rule","Previewed membership rule","Typed CREATE confirmation","Post-create group configuration verification"]
    },
    {
      match:/INVOKE-ENFORCE-PER-USER-MFA|Enforce Per-user MFA/i,
      connect:['Connect-MgGraph -Scopes "Policy.ReadWrite.AuthenticationMethod","UserAuthenticationMethod.Read.All","User.Read.All"'],
      label:"GUARDS",
      facts:["One user or TXT / CSV input","Per-user MFA state preview","Separate from Conditional Access","Typed ENFORCE confirmation","Post-change state validation","Registered authentication methods","Verified CSV when requested"]
    },
    {
      match:/GET-ACCOUNT-STATUS|Account Status Review/i,
      connect:['Connect-MgGraph -Scopes "User.Read.All","Directory.Read.All","AuditLog.Read.All"'],
      label:"CHECKS",
      facts:["One user or TXT / CSV input","Enabled / disabled state","Recorded Entra sign-in activity","Missing sign-in data kept separate","Query failures remain visible","Tenant-target validation","Verified CSV when requested"]
    },
    {
      match:/INVOKE-DISABLE-ACCOUNTS|Disable User Accounts/i,
      connect:['Connect-MgGraph -TenantId <tenant-domain> -Scopes "User.ReadWrite.All","Directory.Read.All"'],
      label:"DOES",
      facts:["Separates synced and cloud-only authority","Uses Active Directory for synced users","Uses Entra ID for cloud-only users","Shows the full disable preview","Requires typed DISABLE confirmation","Validates post-change state","Optionally revokes sessions","Optionally requests Entra Connect delta sync","Exports verified results when requested"]
    },
    {
      match:/GET-GROUP-MEMBERS|^Group Members$/i,
      connect:['Connect-ExchangeOnline','Connect-MgGraph -Scopes "Group.Read.All","User.Read.All"','Import-Module ActiveDirectory'],
      label:"CHECKS",
      facts:["One group or TXT / CSV input","Exchange distribution groups first","Entra groups second","Active Directory groups third","Direct members only","Verified member CSV when requested"]
    },
    {
      match:/GET-USER-GROUPS|User Group Memberships/i,
      connect:['Connect-MgGraph -Scopes "User.Read.All","Group.Read.All"','Import-Module ActiveDirectory'],
      label:"CHECKS",
      facts:["One user or TXT / CSV input","Active Directory memberships","Entra ID memberships","Synced Entra groups remain visible","Cloud / synced / dynamic markers","Independent AD and Entra coverage","Verified CSV when requested"]
    },
    {
      match:/INVOKE-DELETE-ACCOUNTS|Delete User Accounts/i,
      connect:['Connect-MgGraph -Scopes "User.ReadWrite.All","Organization.Read.All"','Import-Module ActiveDirectory'],
      label:"GUARDS",
      facts:["One user or TXT / CSV input","Exact UPN resolution","AD authority for synced users","Entra authority for cloud-only and guest users","Full deletion plan before action","Typed DELETE confirmation","Same-source post-delete validation","CSV / TXT evidence"]
    },
    {
      match:/INVOKE-REMOVE-USER-GROUPS|Remove User Group Memberships/i,
      connect:['Connect-MgGraph -Scopes "User.Read.All","Group.Read.All","GroupMember.ReadWrite.All"','Import-Module ActiveDirectory'],
      label:"GUARDS",
      facts:["One user or TXT / CSV input","AD and Entra memberships shown independently","Synced Entra observations remain visible","Synced memberships changed in AD","Dynamic and role-assignable groups skipped","Exchange-managed mail groups skipped","Typed REMOVE GROUPS confirmation","Post-removal validation"]
    },
    {
      match:/INVOKE-LITIGATION-HOLD|Enforce Litigation Hold/i,
      connect:['Connect-ExchangeOnline'],
      label:"GUARDS",
      facts:["One mailbox or TXT / CSV input","Pre-change hold-state review","Changes only noncompliant mailboxes","Full preview before changes","Typed HOLD confirmation","Unlimited duration target","Post-change mailbox re-read","Optional CSV evidence"]
    },
    {
      match:/RESOLVE-NAMES-TO-UPNS|Resolve Names to UPNs/i,
      connect:['Connect-MgGraph -TenantId <tenant-domain> -Scopes "User.Read.All"'],
      label:"DOES",
      facts:["Targets the requested tenant before searching","Classifies exact, likely, multiple, and no-match results","Shows account-enabled and hybrid context","Optionally exports a verified full review CSV","Optionally exports a verified exact-match UPN TXT"]
    },
    {
      match:/GET-USER-SECURITY-SNAPSHOT|User Security Snapshot/i,
      connect:['Connect-MgGraph -Scopes "User.Read.All","UserAuthenticationMethod.Read.All","Directory.Read.All","AuditLog.Read.All"'],
      label:"CHECKS",
      facts:["Account state and hybrid source","Password state","Authentication methods","Privileged roles","Direct group memberships","License state","Recent sign-ins","Explicit data gaps"]
    },
    {
      match:/GET-STALE-SIGNIN-REVIEW|Stale Entra Sign-in Review/i,
      connect:['Connect-MgGraph -Scopes "User.Read.All","Directory.Read.All","AuditLog.Read.All"'],
      label:"CHECKS",
      facts:["Enabled Entra member accounts","Configurable inactivity threshold","Recorded last sign-in age","Missing sign-in activity kept separate","Guests and disabled users excluded","Verified CSV when requested"]
    },
    {
      match:/GET-TENANT-GROUP-OWNERS|Tenant Group Owners Review/i,
      connect:['Connect-MgGraph -Scopes "Group.Read.All","User.Read.All"','Connect-ExchangeOnline'],
      label:"CHECKS",
      facts:["Microsoft Teams","Microsoft 365 groups","Security groups","Mail-enabled groups","Distribution groups","Ownerless groups","Owner lookup failures"]
    },
    {
      match:/GET-TRANSPORT-RULES-AUDIT|Transport Rules Audit/i,
      connect:['Connect-ExchangeOnline'],
      label:"CHECKS",
      facts:["Tenant-wide transport rules","BCC actions","Redirect actions","Delete / reject actions","Quarantine / moderation actions","Disabled rules","Verified CSV when requested"]
    },
    {
      match:/GET-CONDITIONAL-ACCESS-GAPS|Conditional Access Gaps/i,
      connect:['Connect-MgGraph -Scopes "Policy.Read.All","Directory.Read.All"'],
      label:"CHECKS",
      facts:["Disabled and report-only policies","User and group exclusions","Device-code coverage","Location conditions","Weak coverage indicators","Optional reviewed export"]
    },
    {
      match:/GET-TENANT-DRIFT-REVIEW|Tenant Drift Review/i,
      connect:['Connect-MgGraph -Scopes "Directory.Read.All","Application.Read.All","Policy.Read.All","RoleAssignmentSchedule.Read.Directory","RoleEligibilitySchedule.Read.Directory"'],
      label:"CHECKS",
      facts:["Active privileged role assignments","Eligible privileged role assignments","Conditional Access policy fingerprints","App registration credentials","Delegated OAuth consent grants","Tenant-ID bound local baseline","Verified baseline writes only after approval"]
    },
    {
      match:/GET-TENANT-SECURITY-SNAPSHOT|Tenant Security Snapshot/i,
      connect:['Connect-MgGraph -Scopes "Organization.Read.All","User.Read.All","AuditLog.Read.All","Directory.Read.All","RoleManagement.Read.Directory","Policy.Read.ConditionalAccess","DelegatedPermissionGrant.Read.All"'],
      label:"CHECKS",
      facts:["Tenant and user counts","Stale enabled accounts","Conditional Access policy state","Active admin role counts","Delegated OAuth grants"]
    },
    {
      match:/GET-ROOM-RESOURCE-ACCESS|Room & Resource Access Review/i,
      connect:['Connect-ExchangeOnline'],
      label:"CHECKS",
      facts:["Room / equipment mailbox type","Full Access delegates","In-policy booking principals","Resource delegates"]
    },
    {
      match:/GET-TENANT-MAILBOX-ACCESS-AUDIT|Tenant Mailbox Access Audit/i,
      connect:['Connect-ExchangeOnline'],
      label:"CHECKS",
      facts:["User and shared mailboxes","Forwarding","Full Access","Send As","Send on Behalf","Query failures"]
    },
    {
      match:/CLEANUP-DISABLED-USER-MAILBOX-ACCESS|Disabled User Mailbox Access Cleanup/i,
      connect:['Connect-MgGraph -Scopes "User.Read.All"','Connect-ExchangeOnline'],
      label:"DOES",
      facts:["Validates disabled state at the authoritative identity source","Scans Exchange recipients for Full Access","Scans Send As","Scans Send on Behalf","Shows the complete removal plan","Requires typed confirmation tied to the target UPN","Verifies each requested removal"]
    }
  ];

  function curatedMeta(item){
    const key = [displayName(item),item.file,item.name].join(" ");
    return CURATED.find(entry => entry.match.test(key)) || null;
  }

  function connectCommands(item){
    if (Array.isArray(item.connectFirst)) return [...item.connectFirst];
    if (/^Connect Microsoft Graph$/i.test(displayName(item))) return [];
    if (item.type === "Quick Command" && Object.hasOwn(QUICK_GRAPH_SCOPES,item.name)){
      const scopes = QUICK_GRAPH_SCOPES[item.name];
      return scopes.length ? ['Connect-MgGraph -Scopes '+scopes.map(scope=>JSON.stringify(scope)).join(',')+' -ContextScope Process'] : [];
    }
    if (/^Connect Exchange Online$/i.test(displayName(item))) return [];

    const curated = curatedMeta(item);
    if (curated?.connect?.length) return [...curated.connect];

    const req = String(item.requires || "");
    const found = [];

    for (const match of req.matchAll(/Connect:\s*([^|]+)/gi)){
      const value = match[1].trim();
      if (value && !found.includes(value)) found.push(value);
    }

    const platform = String(item.platform || "");
    const code = String(item.code || "");

    if (!found.length){
      if (/Microsoft Graph/i.test(platform) || /\bMg[A-Z]/.test(code)) found.push("Connect-MgGraph");
      if (/Exchange Online/i.test(platform) || /Get-Mailbox|Set-Mailbox|Get-InboxRule|MailboxFolderPermission/.test(code)) found.push("Connect-ExchangeOnline");
      if (/Active Directory/i.test(platform) || /\b(?:Get|Set|Enable|Disable|Remove|Add)-AD/.test(code)) found.push("Import-Module ActiveDirectory");
    }

    return [...new Set(found)];
  }

  const RISK_CHECKS = [
    "Account status",
    "Account source",
    "Password age",
    "MFA methods",
    "Interactive sign-in",
    "Non-interactive sign-in",
    "Recent sign-ins",
    "Failed sign-ins",
    "Privileged roles",
    "Conditional Access",
    "Visible inbox rules",
    "Hidden inbox rules",
    "Forwarding",
    "Full Access",
    "Send As",
    "Send on Behalf",
    "OAuth grants",
    "POP / IMAP / SMTP AUTH"
  ];

  function factBlockFor(item){
    if (Array.isArray(item.toolFacts) && item.toolFacts.length){
      return {label:"INCLUDES",items:[...item.toolFacts]};
    }

    const curated = curatedMeta(item);
    if (curated?.facts?.length){
      return {label:curated.label || "CHECKS",items:[...curated.facts]};
    }

    const title = displayName(item);
    if (/Identity Risk Assessment|M365 User Security Review|M365 Risk Exposure Snapshot|BEC Risk Exposure Snapshot|Identity Exposure Snapshot/i.test(title)){
      return {label:"CHECKS",items:[...RISK_CHECKS]};
    }

    if (/M365 User Quick View/i.test(title)){
      return {label:"CHECKS",items:["Account state","Password age","MFA","Groups","Mailbox state"]};
    }

    return null;
  }

  function workflowFor(item, area){
    if (area !== "Incident Response") return null;

    const current = IR_STEPS.find(step=>step.file===item.file);
    if (!current) return null;
    return {current:current.n,steps:IR_STEPS,note:"Review findings before choosing the next action. Change steps require authorization."};
  }

  function changeNote(item){
    // Specific consequences come from source.changeNote. Access badges already
    // communicate change/destructive state; generic action restatements add noise.
    return "";
  }

  const CARD_UPDATES = {"git-repo.ps1": {"objective": "Check repository changes, push reviewed work, or pull updates.", "requires": "Git for Windows; run from an existing terminal"}, "git-security.ps1": {"objective": "Review a GitHub security-log export for new access and security flags.", "requires": "Run with -Account your-github-handle"}, "set-execution.ps1": {"objective": "Prepare reviewed scripts to run under your current-user execution policy."}, "git-handoff.ps1": {"objective": "Save the current Git project state for your next session.", "changeNote": "Writes a local handoff file and Git exclusion; does not commit or push."}, "TEST-POWERSHELL-READINESS.ps1": {"area": "Tools", "subarea": "Setup", "name": "PowerShell Readiness"}, "GET-FOLDER-INVENTORY.ps1": {"area": "Tools", "subarea": "Repository", "name": "Repository Inventory", "objective": "Review a folder\u2019s contents, script signatures, and Git status."}, "RESET-M365-SESSION.ps1": {"area": "Tools", "subarea": "Setup"}, "INSTALL-M365-MODULES.ps1": {"area": "Tools", "subarea": "Setup"}, "attractor.ps1": {"objective": "Run a slowly evolving fractal animation with a floating label and clock."}, "rain.ps1": {"objective": "Run colorful terminal rain with a floating label and clock."}, "static.ps1": {"objective": "Run drifting dots and static with a floating label and clock."}};

  const IR_STEPS = [
    {file:"ir-risk-assessment.ps1",operationalSha256:"75bf88444949d04fb4b4e8b32d661ea082e8eb084bc24fa8740249ea332c2a80",acceptedSha256:"07f70bea99adcc4fcfc1115288ec4377f295f6b98ecfb6d16667da1d4f14383b",name:"BEC: Assess User Risk",n:"1"},
    {file:"ir-contain-eradicate.ps1",operationalSha256:"a51b84573ab23050cf3e5352680c36b069ae0529eb75f81e215f914809823198",acceptedSha256:"e9c4eff8a9637416bb4b51f6de4f7f21838f01c0c80adcb9170ae98778b958fb",name:"BEC: Contain and Clean Up",n:"2"},
    {file:"ir-recover-validate.ps1",operationalSha256:"141be9986ae42e052f08c0768c107a6f6542c8085836cd01e530847dbe386a6f",acceptedSha256:"c8651f2ab0d3c0e3f50ee65bb80cda9e984bc6fe52ce268831b9a7cf501f9b04",name:"BEC: Restore and Validate",n:"3"}
  ];
  const IR_RENAMES = {
    "_STEP1-ir-discovery-summary.ps1": IR_STEPS[0],
    "_STEP2-ir-execution-v2.ps1": IR_STEPS[1]
  };

  function isDocument(item){
    return /documentation|reference|runbook/i.test(item.type || "") || /\.(md|pdf|txt)$/i.test(item.file || "");
  }
  function documentLabel(item){
    return /guide|runbook|checklist|standard|handoff|how to/i.test([item.name,item.file].join(" ")) ? "GUIDE" : "REFERENCE";
  }
  const PENDING_NEXT_STEPS = {
  "invoke-user-offboard.ps1": [
    "GET-USER-PREDELETE-CHECK.ps1",
    "INVOKE-DISABLE-ACCOUNTS.ps1",
    "INVOKE-REMOVE-LICENSES.ps1"
  ],
  "invoke-user-onboard.ps1": [
    "RESOLVE-NAMES-TO-UPNS.ps1",
    "GET-ACCOUNT-STATUS.ps1",
    "INVOKE-ASSIGN-LICENSES.ps1"
  ],
  "get-inactive-group-debt.ps1": [
    "GET-QUARTERLY-CLEANUP-REVIEW.ps1",
    "GET-USER-GROUPS.ps1",
    "GET-ACCOUNT-STATUS.ps1"
  ],
  "get-inactive-mailbox-debt.ps1": [
    "GET-QUARTERLY-CLEANUP-REVIEW.ps1",
    "GET-MAILBOX-PERMISSIONS.ps1",
    "GET-ACCOUNT-STATUS.ps1"
  ],
  "find-accounts-by-name-clean.ps1": [
    "RESOLVE-NAMES-TO-UPNS.ps1",
    "GET-ACCOUNT-STATUS.ps1",
    "GET-USER-PREDELETE-CHECK.ps1"
  ],
  "shared-mailbox-members.ps1": [
    "GET-MAILBOX-PERMISSIONS.ps1",
    "GET-TENANT-MAILBOX-ACCESS-AUDIT.ps1",
    "GET-MAILBOX-SECURITY-SNAPSHOT.ps1"
  ],
  "distro-group-members.ps1": [
    "GET-DISTRIBUTION-GROUP-MEMBERS.ps1",
    "GET-GROUP-MEMBERS.ps1",
    "GET-TENANT-GROUP-OWNERS.ps1"
  ],
  "get-graph-session-user-check.ps1": [
    "TEST-POWERSHELL-READINESS.ps1",
    "GET-ACCOUNT-STATUS.ps1",
    "RESET-M365-SESSION.ps1"
  ],
  "tenant-security-hardening-guided.ps1": [
    "GET-TENANT-SECURITY-SNAPSHOT.ps1",
    "GET-CONDITIONAL-ACCESS-GAPS.ps1",
    "GET-MFA-SECURITY-AUDIT.ps1"
  ]
};

  function relatedItems(item){
    const cards=window.FIELD_KIT_OPERATOR_CARDS || {};
    const spec=cards[item.file];
    const candidates=ITEMS.filter(other=>other!==item && (!item.file || other.file!==item.file) && other.status!=="Source pending");
    const commandReview=window.FIELD_KIT_COMMAND_GUIDANCE?.[item.name];
    const reviewedLinks=item.type==='Quick Command' ? (commandReview?.code===item.code ? commandReview.related : []) : spec?.related;
    if(reviewedLinks)return reviewedLinks.map(key=>key.startsWith('command:')
      ? candidates.find(other=>other.type==='Quick Command' && other.name===key.slice(8))
      : candidates.find(other=>other.file===key)).filter(Boolean);
    let ranked=[];
    if(item.name==='Revoke Active Sessions')return ['ir-risk-assessment.ps1','ir-contain-eradicate.ps1','ir-recover-validate.ps1'].map(file=>candidates.find(x=>x.file===file)).filter(Boolean);
    if(item.name==='Show Whether Remote Desktop Is Enabled')return ['Show Windows Firewall Profiles','Show Windows Firewall Rules by Name','Show Listening Tcp Ports'].map(name=>candidates.find(x=>x.name===name)).filter(Boolean);
    // Atomic commands relate within their actual platform and task group.
    ranked=candidates.filter(other=>other.type===item.type && other.platform===item.platform && other.group===item.group)
      .sort((a,b)=>{
        const words=new Set(norm([item.displayName,item.subarea].join(' ')).split(' ').filter(x=>x.length>3));
        const relevance=x=>norm([x.displayName,x.subarea].join(' ')).split(' ').filter(x=>words.has(x)).length;
        return relevance(b)-relevance(a)||a.displayName.localeCompare(b.displayName);
      });
    if(isDocument(item))ranked=candidates.filter(isDocument).filter(other=>other.logicalArea===item.logicalArea);
    return ranked.slice(0,3);
  }
  function relatedMarkup(item){
    const links=relatedItems(item);
    if(!links.length)return '';
    return '<section class="related-block"><div class="section-label">RELATED ITEMS</div><div class="related-list">'+links.map(other=>`<button type="button" class="related-item" data-related-file="${esc(other.file)}" ${other.type==='Quick Command'?`data-related-name="${esc(other.name)}"`:''}><span>${esc(other.displayName)}</span>${accessMarkup(other).replaceAll('<div','<span').replaceAll('</div>','</span>')}</button>`).join('')+'</div></section>';
  }

  // Delegated preparation for these atomic commands; roles and consent remain
  // prerequisites. Diagnostic/disconnect commands deliberately need no sign-in.
  const QUICK_GRAPH_SCOPES = {
    "Show Password Last Changed And Age":["User.Read.All"],
    "Show Sync Source":["User.Read.All"],
    "Delete Cloud User":["User.ReadWrite.All"],
    "Disable Sign-In":["User.EnableDisableAccount.All","User.Read.All"],
    "Enable Sign-In":["User.EnableDisableAccount.All","User.Read.All"],
    "Revoke Active Sessions":["User.RevokeSessions.All"],
    "Remove Specific Authenticator Method":["UserAuthenticationMethod.ReadWrite.All"],
    "Remove Specific Phone Method":["UserAuthenticationMethod.ReadWrite.All"],
    "Remove Specific Delegated Grant":["DelegatedPermissionGrant.ReadWrite.All"],
    "Add User to Entra Group":["User.Read.All","GroupMember.ReadWrite.All"],
    "Remove User from Entra Group":["User.Read.All","GroupMember.ReadWrite.All"],
    "Show Entra Sign-ins - Last 48 Hours":["AuditLog.Read.All"],
    "Show Legacy / Other-client Sign-ins":["AuditLog.Read.All"],
    "Show Successful Sign-Ins":["AuditLog.Read.All"],
    "Show Graph Context":[],
    "Disconnect Microsoft Graph":[]
  };

  function buildItem(source){
    source = {...source, ...(CARD_UPDATES[source.file] || {})};
    const review = window.FIELD_KIT_CARD_GUIDANCE?.[source.file];
    if (review && review.sourceSha256 === window.FIELD_KIT_SOURCE_INTEGRITY?.[source.publishedPath]) source = {...source, ...review};
    if (source.name === "Revoke Active Sessions") source = {...source,area:"Security / IR",subarea:"Account Compromise"};
    if (IR_RENAMES[source.file]) {
      const legacy = source.file;
      source = {...source,...IR_RENAMES[legacy],status:"Source pending",keywords:[source.keywords,legacy,"ir identity risk assessment incident response"].join(" "),notes:source.notes+" Interactive source pending; download is not yet available."};
    }
    if (/SET-THEME-(SEAGLASS|SILICON-VALLEY)/.test(source.file || "")) source.changeNote = source.notes;
    if (/SET-THEME-COBALT/.test(source.file || "")) source.changeNote = "Changes this terminal and sets Process execution policy to Bypass; no profile installation.";
    if (source.area === "Tools" && source.type === "Documentation") source.subarea = "Reference";
    if (source.type === "Quick Command" && Object.hasOwn(QUICK_GRAPH_SCOPES,source.name)){
      const scopes = QUICK_GRAPH_SCOPES[source.name];
      source.requires = scopes.length
        ? 'Microsoft.Graph modules for this command; delegated scopes: '+scopes.join(', ')+'. Consent and a supported Entra role for the target are required.'+(scopes.includes('AuditLog.Read.All') ? ' Sign-in logs also require tenant licensing and log-read access.' : '')
        : 'Microsoft.Graph.Authentication; uses or inspects only the current session. No new sign-in required.';
    }
    const commandReview = window.FIELD_KIT_COMMAND_GUIDANCE?.[source.name];
    if (source.type === "Quick Command" && commandReview?.code === source.code) {
      const {code: reviewedCode, ...copy} = commandReview;
      source = {...source, ...copy};
    }
    if (source.type === "Quick Command" && /\bRemove-(?:ADUser|MgUser|LocalUser)\b|\bNew-ComplianceSearchAction\b[^\n]*\bHardDelete\b/i.test(source.code || "")) source.access = "Destructive";
    if (source.type !== "Quick Command" && !source.publishedPath && !String(source.code || "").trim()) source.status = "Source pending";
    if (source.status === "Source pending") {
      source = {...source, objective:"Planned tool: " + (source.objective || source.notes || source.name),
        checks:[], guards:["Source is not published; this tool cannot be run from the catalog yet."],
        input:"Final inputs and requirements will be confirmed when the source is published.", requires:"", notes:""};
    }
    const operatorCard=window.FIELD_KIT_OPERATOR_CARDS?.[source.file];
    if (operatorCard && operatorCard.sourceSha256 === window.FIELD_KIT_SOURCE_INTEGRITY?.[source.publishedPath]) {
      source.operatorCard=operatorCard;
      source.input=operatorCard.input;
      if(operatorCard.presentationRevision || operatorCard.operationalRevision){source.version=operatorCard.releaseVersion;delete source.verification;}
    }
    const area = logicalArea(source);
    return {
      ...source,
      logicalArea:area,
      group:groupFor(source, area),
      displayName:displayName(source),
      connect:connectCommands(source),
      facts:factBlockFor(source),
      workflow:workflowFor(source, area),
      changeNote:source.changeNote || changeNote(source)
    };
  }

  function scoreQuality(item){
    let score = 0;
    if (item.file) score += 3;
    if (item.code) score += 2;
    if (item.notes) score += 1;
    if (item.requires) score += 1;
    return score;
  }

  const byKey = new Map();
  for (const source of allSource){
    if (isRmm(source)) continue;
    const item = buildItem(source);
    const key = norm(item.logicalArea + " " + item.displayName);
    const existing = byKey.get(key);
    if (!existing || scoreQuality(item) > scoreQuality(existing)) byKey.set(key,item);
  }

  const PLANNED_ITEMS = [...byKey.values()].filter(item=>item.status==="Source pending");
  const ITEMS = [...byKey.values()].filter(item=>item.status!=="Source pending");

  const state = {
    area:"Full Library",
    incidentSource:"",
    incidentOpen:false,
    standaloneGroup:"",
    standaloneOpen:false,
    query:"",
    selected:null
  };

  const areaNav = document.getElementById("areaNav");
  const crumb = document.getElementById("crumb");
  const entryCount = document.getElementById("entryCount");
  const verificationKey = document.getElementById("verificationKey");
  const search = document.getElementById("search");
  const searchWrap = document.querySelector(".search-wrap");
  const clearSearch = document.getElementById("clearSearch");
  const contextBar = document.getElementById("contextBar");
  const jumpBar = document.getElementById("jumpBar");
  const results = document.getElementById("results");
  const empty = document.getElementById("empty");
  const drawer = document.getElementById("drawer");
  const drawerBody = document.getElementById("drawerBody");
  const closeDrawer = document.getElementById("closeDrawer");
  const drawerOverlay = document.getElementById("drawerOverlay");
  const menuBtn = document.getElementById("menuBtn");
  const navOverlay = document.getElementById("navOverlay");
  let lastFocusedElement = null;
  const shell = document.querySelector('.shell');
  const sourceCache = new Map();

  function areaLabel(area){
    if (area === "Standalone") return "Quick Commands";
    if (area === "Utility") return "Utilities";
    return area;
  }

  function countArea(area){
    if (area === "Full Library") return ITEMS.length;
    if (area === "About" || area === "Start Here") return "";
    return ITEMS.filter(x => itemBuckets(x).includes(area)).length;
  }

  function countStandaloneGroup(group){
    return ITEMS.filter(item => primaryBucket(item) === "Standalone" && (item.group || "General") === group).length;
  }

  function incidentSource(item){
    return isRmm(item) ? "RMM" : "PowerShell";
  }

  function countIncidentSource(source){
    return ITEMS.filter(item => primaryBucket(item) === "Incident Response" && incidentSource(item) === source).length;
  }

  function navButton(area){
    const active = state.area === area;
    const isStandalone = area === "Standalone";
    const isIncident = area === "Incident Response";
    const expandable = isStandalone;
    const expanded = isStandalone
      ? (active && state.standaloneOpen)
      : isIncident
        ? (active && state.incidentOpen)
        : false;
    const label = areaLabel(area);

    const parent = `
      <button class="area-button ${area === "About" ? "about-nav" : ""} ${active ? "active" : ""} ${expandable ? "area-parent" : ""}" data-area="${esc(area)}" type="button" aria-expanded="${expandable ? String(expanded) : "false"}">
        <span class="area-label">${esc(label)}${expandable ? '<span class="nav-caret">▾</span>' : ""}</span>
        ${area === "Full Library" || area === "Start Here" ? "" : `<span class="area-count">${countArea(area)}</span>`}
      </button>
    `;

    if (!expanded) return parent;

    if (isIncident){
      const sources = INCIDENT_SOURCES
        .map(source => ({source,count:countIncidentSource(source)}))
        .filter(entry => entry.count > 0);

      const allActive = !state.incidentSource;
      const children = [
        `<button class="area-sub-button ${allActive ? "active" : ""}" data-incident-source="" type="button">
            <span>All Incident Response</span><span class="area-count">${countArea("Incident Response")}</span>
          </button>`,
        ...sources.map(({source,count}) => `
          <button class="area-sub-button ${state.incidentSource === source ? "active" : ""}" data-incident-source="${esc(source)}" type="button">
            <span>${esc(source)}</span><span class="area-count">${count}</span>
          </button>
        `)
      ].join("");

      return parent + `<div class="area-subnav">${children}</div>`;
    }

    const groups = STANDALONE_GROUPS
      .map(group => ({group,count:countStandaloneGroup(group)}))
      .filter(entry => entry.count > 0);

    const allActive = !state.standaloneGroup;
    const children = [
      `<button class="area-sub-button ${allActive ? "active" : ""}" data-standalone-group="" type="button">
          <span>All Commands</span><span class="area-count">${countArea("Standalone")}</span>
        </button>`,
      ...groups.map(({group,count}) => `
        <button class="area-sub-button ${state.standaloneGroup === group ? "active" : ""}" data-standalone-group="${esc(group)}" type="button">
          <span>${esc(group)}</span><span class="area-count">${count}</span>
        </button>
      `)
    ].join("");

    return parent + `<div class="area-subnav">${children}</div>`;
  }

  function navSection(label, areas){
    return `
      <div class="nav-section-label">${esc(label)}</div>
      ${areas.map(navButton).join("")}
    `;
  }

  function renderNav(){
    areaNav.innerHTML = [
      '<div class="nav-primary">' + navButton("Start Here") + navButton("Full Library") + '</div>',
      navSection("Scope", ["Single User","Multi User","Tenant Wide"]),
      navSection("Operations", ["Incident Response","Utility","Standalone"]),
      navSection("Reference", ["Tools"]),
      navSection("Extras", ["Toys"]),
      '<div class="nav-bottom">' + navButton("About") + '</div>'
    ].join("");
  }

  function searchConcepts(item){
    const text = [item.displayName,item.operatorCard?.objective || item.objective,item.useFor].join(" ");

    const tags = [];
    const families = [
      [/computer|endpoint|workstation|device|hostname|bitlocker/i,"device computer endpoint workstation"],
      [/permission|delegat|full access|send as/i,"permission permissions access delegation"],
      [/license|licensing|sku/i,"license licenses licensing"],
      [/group|membership/i,"group groups membership"],
      [/terminal|powershell|theme|readiness|execution policy/i,"terminal powershell"],
      [/investigat|triage|risk assessment|incident|\bbec\b/i,"security investigation incident response ir bec"],
      [/\bgit\b|github|repository/i,"git repository github"],
      [/mailbox|inbox|forwarding|exchange/i,"mailbox email exchange"],
      [/connect|authentication|session/i,"connect connection authentication"],
      [/check|review|audit|assessment/i,"check review"]
    ];
    for (const [pattern,aliases] of families) if (pattern.test(text)) tags.push(aliases);
    if (isDocument(item)) tags.push("documentation document guide reference");

    if (/\bmfa\b|\b2fa\b|multi[- ]?factor|authenticator|authentication methods?|registration status/i.test(text)){
      tags.push("mfa","2fa","multifactor");
    }
    if (/password|\bpwd\b|credential/i.test(text)){
      tags.push("password","pwd");
    }
    if (/wi[- ]?fi|\bwlan\b|wireless/i.test(text)){
      tags.push("wifi","wireless","wlan");
    }
    if (/inbox rule|mailbox rule/i.test(text)){
      tags.push("inbox","rules");
    }
    if (/forwarding|forward address|redirect/i.test(text)){
      tags.push("forwarding","forward","redirect");
    }
    if (/permission|delegate|delegation|full access|send as|send on behalf/i.test(text)){
      tags.push("permissions","permission","delegate","delegation");
    }
    if (/sign[- ]?in|logon|login/i.test(text)){
      tags.push("login","logon","signin");
    }
    if (/entra|azure ad|\baad\b/i.test(text)){
      tags.push("entra","azuread","aad");
    }
    if (/exchange online|\bexo\b|mailbox/i.test(text)){
      tags.push("exchange","exo");
    }
    if (/microsoft graph|connect-mggraph|invoke-mggraph|\bmg[a-z]+/i.test(text)){
      tags.push("graph");
    }
    if (/bitlocker|manage-bde|encryption/i.test(text)){
      tags.push("bitlocker","encryption");
    }
    if (/defender|antivirus|microsoft defender|\bmde\b/i.test(text)){
      tags.push("defender","antivirus");
    }
    if (/printer|printing|spooler|print job/i.test(text)){
      tags.push("printer","printing");
    }
    if (/proxy|winhttp/i.test(text)){
      tags.push("proxy");
    }
    if (/\bdns\b|nslookup|resolver|resolution/i.test(text)){
      tags.push("dns");
    }
    if (/network|ipconfig|ping|tracert|pathping|route print|arp -a|netstat|netadapter|tcp/i.test(text)){
      tags.push("network");
    }

    return [...new Set(tags)].join(" ");
  }

  function searchScore(item, query){
    if (!query) return 1;
    const intent = norm(query);
    const offboardingIntent = /^(?:offboarding|offboard(?: user| employee)?|employee left|(?:employee|user) (?:leaving|departed)|departing (?:employee|user)|leaver)$/.test(intent);
    if (offboardingIntent) {
      if (item.file === 'GET-USER-PREDELETE-CHECK.ps1') return 1000;
      if (item.file === 'INVOKE-REMOVE-LICENSES.ps1') return 800;
      return 0;
    }
    const assessmentIntent = /^(?:(?:suspicious|unfamiliar|unusual|unexpected) (?:login|logon|sign in|signin|mfa prompts?)|(?:hacked|compromised) (?:account|mailbox)|(?:account|mailbox) (?:hacked|compromised)|possible account compromise|bec|phishing)$/.test(intent);
    if (assessmentIntent && item.file === 'ir-risk-assessment.ps1') return 1000;
    const q = words(query);
    if (!q.length) return 1;

    const facts = factBlockFor(item)?.items || [];
    const connect = Array.isArray(item.connect) ? item.connect : [];
    const optionValues = Array.isArray(item.options?.values) ? item.options.values : [];

    const strong = words([
      item.displayName,
      item.file,
      item.group,
      item.logicalArea,
      searchConcepts(item)
    ].join(" "));

    const task = words([item.displayName,item.operatorCard?.objective || item.objective,item.useFor,searchConcepts(item)].join(" "));
    if(!q.every(token=>task.some(w=>w===token || w.startsWith(token))))return 0;
    const weak = words([
      item.platform,
      item.objective,
      item.notes,
      item.output,
      item.input,
      item.requires,
      item.subarea,
      item.useFor,
      item.code,
      item.changeNote,
      connect.join(" "),
      optionValues.join(" "),
      facts.join(" ")
    ].join(" "));

    let score = 0;
    for (const token of q){
      let matched = false;

      if (strong.some(w => w === token)) { score += 7; matched = true; }
      else if (strong.some(w => w.startsWith(token))) { score += 5; matched = true; }
      else if (weak.some(w => w === token)) { score += 3; matched = true; }
      else if (weak.some(w => w.startsWith(token))) { score += 1; matched = true; }

      // Multi-word searches narrow results: every term must match.
      if (!matched) return 0;
    }

    // Prefer a tool whose actual title matches the task over incidental mentions.
    const titleWords=words(item.displayName);
    if(q.every(token=>titleWords.some(w=>w===token || w.startsWith(token)))) score+=40;
    if(norm(item.displayName)===intent) score+=100;
    if(item.operatorCard) score+=12;
    if(item.status==='Source pending') score-=2;
    return score;
  }

  function scopeSubgroup(item){
    const area = String(item.area || "");
    const text = [item.displayName,item.name,item.file,item.subarea].join(" ");

    if (/onboard|offboard|pre[- ]?delete|disable(?:\s+user)?\s+accounts|delete(?:\s+user)?\s+accounts/i.test(text)) return "On / Offboarding";
    if (/shared mailbox sign-in|\bIR[-_ ]|incident response|mfa|conditional access|oauth|secure score|sign[- ]?in anomalies|device code|service principal|app registration|guest app consent|guest consent|security hardening|user security snapshot|tenant security snapshot/i.test(text)) return "Security";
    if (/mailbox|room|equipment|resource access|inbox|forward|transport rule|send as|full access|calendar|contacts|litigation hold/i.test(text)) return "Mailbox";
    if (/license|licensing/i.test(text)) return "Licenses";
    if (/permission|role|access/i.test(text) && !/conditional access/i.test(text)) return "Permissions";
    if (/group|membership|owner/i.test(text)) return "Groups";
    if (/reporting\s*\/\s*audit/i.test(area) || /audit|review|report|stale|cleanup|tenant snapshot/i.test(text)) return "Audit";
    return "User";
  }

  const SCOPE_OVERRIDES = [
    {scope:"Tenant Wide", match:/Quarterly Account Cleanup|Inactive User Review|Disabled User Group Debt|Disabled User Mailbox Debt|Distribution Group Inventory|Teams and M365 Group Owners|Transport Rules Audit|Shared Mailbox Sign-in Audit/i},
    {scope:"Multi User", match:/Create Dynamic License Group|Distribution Group Members|^Group Members$|Mailbox Permissions Review/i}
  ];

  function itemBuckets(item){
    const declared = Array.isArray(item.scopes)
      ? item.scopes.filter(scope => ["Single User","Multi User","Tenant Wide"].includes(scope))
      : [];

    if (declared.length) return [...new Set(declared)];
    return [primaryBucket(item)];
  }

  function primaryBucket(item){
    if (item.logicalArea === "Incident Response") return "Incident Response";
    if (item.type === "Quick Command" || item.logicalArea === "Standalone") return "Standalone";
    if (item.logicalArea === "Utility") return "Utility";
    if (item.logicalArea === "Tools") return "Tools";
    if (item.logicalArea === "Toys") return "Toys";

    const combined = [item.displayName,item.name,item.file,item.notes,item.keywords].join(" ");
    const override = SCOPE_OVERRIDES.find(x => x.match.test(item.displayName || item.name || ""));
    if (override) return override.scope;

    if (/^\s*tenant\b/i.test(String(item.input || ""))) return "Tenant Wide";
    if (/^tenant[-_ ]/i.test(String(item.file || item.name || "")) || /^tenant\b/i.test(String(item.displayName || ""))) return "Tenant Wide";

    if (item.group === "Tenant") return "Tenant Wide";
    if (item.group === "Multi User") return "Multi User";
    if (item.group === "Single User") return "Single User";

    if (/\bbulk\b|\bmulti[- ]?user\b|one or more|multiple users|all users/i.test(combined)) return "Multi User";
    if (item.logicalArea === "Identity" || item.logicalArea === "Mailbox") return "Single User";
    return "Utility";
  }

  function bucketRank(bucket){
    const order = ["Single User","Multi User","Tenant Wide","Incident Response","RMM","Utility","Standalone","Tools","Toys"];
    const idx = order.indexOf(bucket);
    return idx === -1 ? 99 : idx;
  }

  function bucketId(bucket){
    return "section-" + norm(bucket).replace(/\s+/g,"-");
  }

  function irRank(item){
    const name = displayName(item);
    const step = IR_STEPS.find(step=>step.file===item.file);
    if (step) return Number(step.n);
    if (/User Security Review|Risk Exposure Snapshot|Discovery/i.test(name)) return 1;
    if (/Eradicate|Execution/i.test(name)) return 2;
    if (/Recover/i.test(name)) return 3;
    if (/Revoke (?:Active )?Sessions/i.test(name)) return 4;
    return 50;
  }

  const TOPIC_FAMILIES = [
    /\baccount\b|\buser\b|identity|profile|manager/i,
    /password|credential/i,
    /\bmfa\b|2fa|authenticator|authentication method|registration status/i,
    /sign[- ]?in|login|logon|session|token|kerberos/i,
    /license|licensing|sku/i,
    /distribution group|\bgroup\b|membership|member|owner/i,
    /role|permission grant|oauth|consent|app registration|service principal/i,
    /mailbox summary|mailbox protocol|smtp auth|\bpop\b|\bimap\b/i,
    /mailbox permission|full access|send as|send on behalf|delegate|\broom\b|equipment|resource access/i,
    /mailbox forwarding|forwarding|forward address/i,
    /inbox rule|mailbox rule/i,
    /transport rule|mail flow rule/i,
    /message trace/i,
    /calendar/i,
    /contacts/i,
    /litigation hold|retention|hold/i,
    /shared mailbox/i,
    /bitlocker|encryption|recovery protector/i,
    /printer|print job|spooler/i,
    /windows update|hotfix|winget|package update/i,
    /disk|storage|free space|volume/i,
    /process|cpu|memory consumer/i,
    /service status|startup type|\bservice\b/i,
    /scheduled task/i,
    /hostname|computer model|serial|uptime|os build|system info/i,
    /dns|nslookup|resolver/i,
    /ping|traceroute|tracert|pathping|reachability|latency|packet loss/i,
    /route|routing|gateway|arp/i,
    /adapter|ip configuration|ipconfig|tcp|netstat|port/i,
    /wi[- ]?fi|wireless|wlan/i,
    /vpn|proxy|winhttp/i,
    /firewall/i,
    /powershell|execution policy|module|terminal/i
  ];

  function topicRank(item){
    const text = [
      item.displayName,
      item.name,
      item.subarea,
      item.file
    ].join(" ");

    const index = TOPIC_FAMILIES.findIndex(pattern => pattern.test(text));
    return index === -1 ? 999 : index;
  }

  function actionRank(item){
    const access = String(item.access || "").toLowerCase();
    if (access.includes("destructive")) return 3;
    if (access.includes("change") || access.includes("mixed")) return 2;
    if (access.includes("read-only") || access.includes("read only") || access.includes("readonly")) return 1;
    return 4;
  }

  function setupRank(item){
    return item.group === "Setup" || item.group === "Terminal" || /^(M365 Module Setup|PowerShell Readiness|Terminal Readiness|Script Setup)$/.test(item.displayName) ? 0 : 1;
  }

  function semanticCompare(a,b){
    return setupRank(a) - setupRank(b) ||
      topicRank(a) - topicRank(b) ||
      actionRank(a) - actionRank(b) ||
      a.displayName.localeCompare(b.displayName) ||
      (a._order || 0) - (b._order || 0);
  }

  function filteredItems(){
    const q = state.query.trim();

    // Search is global. The selected navigation area controls browsing only;
    // once a query is entered, every catalog section participates.
    let list;
    if (q){
      list = ITEMS.slice();
    } else {
      list = ITEMS.filter(item => state.area === "Full Library" || itemBuckets(item).includes(state.area));

      if (state.area === "Incident Response" && state.incidentSource){
        list = list.filter(item => incidentSource(item) === state.incidentSource);
      }

      if (state.area === "Standalone" && state.standaloneGroup){
        list = list.filter(item => (item.group || "General") === state.standaloneGroup);
      }
    }

    if (q){
      list = list
        .map(item => ({item,score:searchScore(item,q)}))
        .filter(x => x.score > 0)
        .sort((a,b) => b.score - a.score || a.item.displayName.localeCompare(b.item.displayName))
        .map(x => x.item);
    } else if (state.area === "Full Library") {
      const purposeOrder = ["User","Groups","Permissions","Licenses","Mailbox","Security","On / Offboarding","Audit"];
      list.sort((a,b) => {
        const bucketDiff = bucketRank(primaryBucket(a)) - bucketRank(primaryBucket(b));
        if (bucketDiff) return bucketDiff;

        const bucket = primaryBucket(a);
        if (["Single User","Multi User","Tenant Wide"].includes(bucket)){
          const purposeDiff = purposeOrder.indexOf(scopeSubgroup(a)) - purposeOrder.indexOf(scopeSubgroup(b));
          if (purposeDiff) return purposeDiff;
        }

        if (bucket === "Incident Response") return irRank(a) - irRank(b) || semanticCompare(a,b);
        return semanticCompare(a,b);
      });
    } else if (["Single User","Multi User","Tenant Wide"].includes(state.area)) {
      const order = ["User","Groups","Permissions","Licenses","Mailbox","Security","On / Offboarding","Audit"];
      list.sort((a,b) =>
        order.indexOf(scopeSubgroup(a)) - order.indexOf(scopeSubgroup(b)) ||
        semanticCompare(a,b)
      );
    } else if (state.area === "Incident Response") {
      list.sort((a,b) =>
        groupRank(a.logicalArea,a.group) - groupRank(b.logicalArea,b.group) ||
        irRank(a) - irRank(b) ||
        semanticCompare(a,b)
      );
    } else {
      list.sort((a,b) =>
        groupRank(a.logicalArea,a.group) - groupRank(b.logicalArea,b.group) ||
        semanticCompare(a,b)
      );
    }

    return list;
  }

  function areaRank(area){
    const order = ["Identity","Mailbox","Incident Response","Utility","Standalone","Tools","Toys"];
    const idx = order.indexOf(area);
    return idx === -1 ? 99 : idx;
  }

  function groupRank(area, group){
    const orders = {
      "Identity":["Single User","Multi User","Tenant","General"],
      "Mailbox":["Single User","Multi User","General"],
      "Incident Response":["Account Response","Investigation","Response","General"],
      "Utility":["Device","Microsoft 365","Repository","Publishing","WinGet","General"],
      "Standalone":["Terminal","Active Directory","Exchange","Graph","Network CLI","Windows CLI","WinGet"],
      "Tools":["Setup","Repository","Reference"],
      "Toys":["Animations","Themes"]
    };
    const list = orders[area] || [];
    const idx = list.indexOf(group);
    return idx === -1 ? 99 : idx;
  }

  function accessTag(item){
    if (isDocument(item)) return `<span class="result-tag result-document">${documentLabel(item)}</span>`;
    const access = String(item.access || "").toLowerCase();

    if (access.includes("destructive")){
      return '<span class="result-tag result-change">MAKES CHANGES</span>' +
        '<span class="result-tag result-danger">DESTRUCTIVE</span>';
    }

    if (access.includes("change") || access.includes("mixed")){
      return '<span class="result-tag result-change">MAKES CHANGES</span>';
    }

    if (access.includes("read-only") || access.includes("read only") || access.includes("readonly")){
      return '<span class="result-tag result-read">READ ONLY</span>';
    }

    return '<span class="result-tag result-change">REVIEW ACCESS</span>';
  }

  function moduleLabel(item){
    const platform = String(item.platform || "");
    const connect = Array.isArray(item.connect) ? item.connect.join(" ") : "";
    const requires = String(item.requires || "");
    const code = String(item.code || "");
    const text = [platform,connect,requires,code].join(" ");

    const hasGraph = /Microsoft Graph|Connect-MgGraph|Microsoft\.Graph|\b(?:Get|Set|New|Remove|Update)-Mg[A-Z]/i.test(text);
    const hasExchange = /Exchange Online|Connect-ExchangeOnline|ExchangeOnlineManagement|\b(?:Get|Set|Add|Remove|New)-(?:Mailbox|Recipient|DistributionGroup|InboxRule|TransportRule)|MailboxFolderPermission/i.test(text);
    const hasAD = /Active Directory|Import-Module ActiveDirectory|\b(?:Get|Set|Add|Remove|Enable|Disable|Unlock)-AD[A-Z]/i.test(text);

    if (hasGraph && hasExchange && hasAD) return "GRAPH + EXO + AD";
    if (hasGraph && hasExchange) return "GRAPH + EXO";
    if (hasGraph && hasAD) return "GRAPH + AD";
    if (hasExchange && hasAD) return "EXO + AD";
    if (hasGraph) return "GRAPH";
    if (hasExchange) return "EXCHANGE";
    if (hasAD) return "ACTIVE DIRECTORY";
    if (/WinGet/i.test(text)) return "WINGET";
    if (/PowerShell/i.test(platform)) return "POWERSHELL";
    if (/Local Windows|Windows/i.test(platform)) return "WINDOWS";
    if (/Datto|RMM/i.test(text) || item.logicalArea === "RMM") return "RMM";
    if (/Markdown|Documentation/i.test([platform,item.type].join(" "))) return "DOCS";
    if (/Microsoft 365\s*\/\s*Entra/i.test(platform)) return "M365 / ENTRA";
    if (/Microsoft 365/i.test(platform)) return "M365";
    if (/Entra/i.test(platform)) return "ENTRA";
    return "";
  }

  function scopeTag(item){
    // Scope is already obvious while browsing grouped sections.
    // Only show it when global search mixes scopes together.
    if (!state.query.trim()) return "";

    if(item.operatorCard)return '<span class="result-tag result-scope">'+esc(item.operatorCard.scope)+'</span>';
    const labels = {
      "Single User":"SINGLE USER",
      "Multi User":"MULTI USER",
      "Tenant Wide":"TENANT WIDE"
    };
    return itemBuckets(item)
      .map(bucket => labels[bucket])
      .filter(Boolean)
      .map(label => '<span class="result-tag result-scope">' + label + '</span>')
      .join("");
  }

  function isVerifiedRelease(item){
    const record = item.verification;
    return !!(record && record.operatorTested === true && item.version === record.version &&
      /^[0-9a-f]{64}$/.test(record.sha256 || "") && item.publishedPath &&
      window.FIELD_KIT_SOURCE_INTEGRITY?.[item.publishedPath] === record.sha256);
  }

  function releaseTag(item){
    return isVerifiedRelease(item) ? '<button class="verification-check title-verification" type="button" data-verification-about aria-label="Operator verified; read About">✓</button>' : "";
  }

  // Package review is separate from the exact-source operator-tested badge.
  // Only the coupled BEC trio can carry this source-bound package review.
  function isReviewedWorkflowPackage(item){
    const spec=item.operatorCard, review=spec?.workflowReview, baseline=review?.baselineVerification;
    const accepted=IR_STEPS.find(step=>step.file===item.file);
    return !!(accepted && item.workflow &&
      (item.file==='ir-risk-assessment.ps1' ? review?.kind==='uri-boundary-fix' && review.evidence==='docs/qa/BEC-APP-LOOKUP-FIX.md' : review?.kind==='presentation-only') && baseline?.operatorTested===true &&
      baseline.version==='1.0.0' && baseline.evidence==='docs/qa/IR-1.0.0-VERIFICATION.md' && baseline.sha256===accepted.acceptedSha256 &&
      /^[0-9a-f]{64}$/.test(baseline.sha256 || '') && review.nonPresentationSha256===accepted.operationalSha256 &&
      review.version===item.version && review.sourceSha256===spec.sourceSha256 &&
      review.sourceSha256===window.FIELD_KIT_SOURCE_INTEGRITY?.[item.publishedPath]);
  }

  function rowTags(item){
    return scopeTag(item) + accessTag(item) + (item.status === "Source pending" ? '<span class="result-tag">SOURCE PENDING</span>' : "");
  }

  function groupTitleMarkup(group){
    const value = String(group || "").trim();
    const scoped = /^(Single User|Multi User|Tenant Wide)$/i.test(value);
    if (scoped){
      const parts = value.split(/\s+/);
      const first = parts.shift() || "";
      const rest = parts.join(" ");
      return '<span class="group-title-accent">' + esc(first.toUpperCase()) + '</span>' +
        (rest ? '<span class="group-title-muted">' + esc(rest.toUpperCase()) + '</span>' : "");
    }
    return '<span class="group-title-accent">' + esc(value.toUpperCase()) + '</span>';
  }

  function itemTitleMarkup(value){
    const parts = String(value || "").trim().split(/\s+/).filter(Boolean);
    if (!parts.length) return "";
    if (parts.length === 1) return '<strong class="item-title-accent">' + esc(parts[0]) + '</strong>';
    const accent = parts.pop();
    return '<span class="item-title-main">' + esc(parts.join(" ")) + '</span> ' +
      '<strong class="item-title-accent">' + esc(accent) + '</strong>';
  }

  function resultMarkup(item, index){
    return `
      <button class="result${isVerifiedRelease(item) ? ' result-operator-verified' : ''}" type="button" data-open-index="${index}"${isVerifiedRelease(item) ? ' aria-description="Operator verified. Download integrity checked. Applies to this release only." title="Operator verified. Download integrity checked. Applies to this release only."' : ''}>
        <span class="result-identity">
          <span class="result-name">${esc(item.displayName)}</span>
          <span class="result-description">${esc(item.operatorCard?.objective || item.objective || item.useFor || item.notes || "")}</span>
        </span>
        <span class="result-flags"><span class="result-risk-flags">${rowTags(item)}</span></span>
        ${isVerifiedRelease(item) ? '<span class="result-check verification-check" aria-hidden="true">✓</span>' : '<span class="result-arrow" aria-hidden="true">›</span>'}
      </button>
    `;
  }

  function renderFirstRun(){
    results.innerHTML = `<section class="about-block first-run-guide">
      <div class="about-kicker">FIRST TIME USING FIELD // KIT?</div>
      <h2 class="item-title">Start Here</h2>
      <p class="about-lede">Prepare the support computer. Choose one tool. Run one job.</p>
      <section class="note-block"><h3>1. Confirm the customer and computer</h3>
        <p>Connect to the customer’s approved Windows support computer. Confirm the customer, computer and approved Windows account. Keep the ticket open to record who ran the job and when.</p>
      </section>
      <section class="note-block"><h3>2. Prepare PowerShell</h3>
        <p>Download the setup package, transfer it to that computer if needed, and extract it. Right-click <strong>PREPARE-FIELD-KIT.ps1</strong> and select <strong>Run with PowerShell</strong>.</p>
        <p>Choose Microsoft Graph, Exchange Online, or both. Setup checks first, offers to install missing components, then rechecks them. Read the plan before typing INSTALL. Wait for <strong>RESULT: READY</strong>, then press Enter to close setup.</p>
        <p>Run setup under the same Windows account and PowerShell edition you will use for jobs. Setup prepares that account and edition.</p>
        <div class="actions"><button id="downloadSetupPackage" class="action primary" type="button">Download Setup Package</button><button class="action" type="button" data-first-run-file="PREPARE-FIELD-KIT.ps1">View Setup Tool</button></div>
        <p id="setupPackageStatus" class="source-note" role="status"></p>
        <p>Setup changes local prerequisites after approval. It does not sign into a customer or grant access. Local AD jobs also need approved AD tools and a domain connection.</p>
      </section>
      <section class="note-block"><h3>3. Choose and run one job</h3>
        <p>Read the card’s purpose, scope and impact. Download its current file and transfer it to the support computer. Right-click and select <strong>Run with PowerShell</strong>. Follow any card-specific launch instructions.</p>
        <p>Confirm the account, customer environment and targets when the tool asks. Sign in with the approved customer account. Setup readiness does not prove you have permission to run a job.</p>
        <p>The BEC package is one sequential workflow: keep its files together and use the same window through its handoffs.</p>
        <div class="actions"><button id="browseAfterSetup" class="action" type="button">Choose a Tool</button></div>
      </section>
      <section class="note-block"><h3>4. Review, finish and close</h3>
        <p>Review completed, failed, skipped and unresolved results. Record the outcome in the ticket. Press Enter to close the dedicated session when complete. Start the next unrelated job in a fresh window.</p>
        <details class="operator-details"><summary>SESSION BOUNDARIES</summary><p>A separate window contains a job; it is not a security sandbox. Closing it ends that PowerShell process, but customer access, Windows rights and browser sign-in caches may remain. A fresh window does not guarantee another password or MFA prompt.</p><p>If reusing an existing window, run Reset M365 Session in that same window first. Running cleanup in a different window cannot clean up the original. Follow your approved sign-out process on the shared computer when finished.</p></details>
      </section>
      <div class="actions"><button class="action" type="button" data-first-run-file="START-HERE.md">Full Setup Guide</button><button class="action" type="button" data-first-run-file="TEST-POWERSHELL-READINESS.ps1">Check Readiness Only</button></div>
    </section>`;
    results.querySelectorAll('[data-first-run-file]').forEach(button=>button.addEventListener('click',()=>{
      const item=ITEMS.find(candidate=>candidate.file===button.dataset.firstRunFile);
      if(item)openItem(item);
    }));
    document.getElementById('browseAfterSetup')?.addEventListener('click',()=>{
      state.area='Full Library';state.query='';search.value='';renderNav();renderResults();
    });
    document.getElementById('downloadSetupPackage')?.addEventListener('click',async event=>{
      const button=event.currentTarget,status=document.getElementById('setupPackageStatus');
      button.disabled=true;status.textContent='Checking setup and guide before packaging…';
      try { saveBlob(await buildSetupBundle(),'field-kit-first-run.zip');status.textContent='Setup script and guide verified. Package downloaded. Extract it on the approved support computer.'; }
      catch(error){status.textContent=error.message || 'Setup package unavailable. No partial package downloaded.';}
      finally {button.disabled=false;}
    });
  }

  function renderResults(){
    const queryActive = Boolean(state.query.trim());
    searchWrap?.classList.toggle("hidden", state.area === "About" || state.area === "Start Here");
    verificationKey.classList.add("hidden");

    if(state.area==='Start Here'){
      crumb.textContent='START HERE';entryCount.textContent='';entryCount.classList.add('hidden');
      clearSearch.classList.add('hidden');contextBar.classList.add('hidden');jumpBar.innerHTML='';jumpBar.classList.add('hidden');empty.classList.add('hidden');
      renderFirstRun();return;
    }

    if (state.area === "About"){
      crumb.textContent = "ABOUT";
      entryCount.textContent = "";
      entryCount.classList.add("hidden");
      clearSearch.classList.toggle("hidden", !state.query);
      contextBar.textContent = "";
      contextBar.classList.add("hidden");
      jumpBar.innerHTML = "";
      jumpBar.classList.add("hidden");
      empty.classList.add("hidden");
      results.innerHTML = `
        <section class="about-block">
          <div class="about-kicker">ABOUT</div>

          <h2 class="about-title">
            <span class="about-field">F I E L D</span>
            <span class="about-slash">//</span>
            <span class="about-kit">K I T</span>
          </h2>

          <div class="about-rule"></div>

          <p class="about-lede">FIELD // KIT helps you choose the right tool and understand its impact before you begin.</p>
          <p>Each entry explains what you’ll need, what it does, who may be affected, and what a finished run should look like. Clear directions guide you through the work. If something gets in the way, you’ll know what happened and where to go next.</p>
          <p>Choose a section or search the whole catalog. Setup tools come first where useful; other items are A–Z. Follow the numbered order for incident-response steps.</p>
          <p>Open an item to see what it does and what it changes. Download the script, view its code, or copy it. Read it before running it.</p>
          <p><strong>Tools</strong> contains setup, Git helpers, and references. <strong>Toys</strong> contains terminal animations and themes.</p>

          <details class="operator-details"><summary>PLANNED TOOLS (${PLANNED_ITEMS.length})</summary><p>These tools are planned and have no published script. They are excluded from library search and tool counts.</p><ul>${PLANNED_ITEMS.map(item=>`<li><strong>${esc(item.displayName)}</strong> — ${esc(item.objective.replace(/^Planned tool: /,''))}</li>`).join('')}</ul></details>
          <section class="about-library">
            <div class="section-label">VERIFICATION</div>
            <p><span class="verification-check" aria-hidden="true">✓</span> Operator-tested release accepted by the owner. The mark is tied to this version and its published checksum. Testing may be sampled, simulated, or limited to specific functions; release evidence records its scope and limits. The mark does not imply full live-service validation. A changed script needs testing and acceptance before retaining the mark.</p>
          </section>

          <section class="about-library">
            <div class="section-label">LIBRARY</div>
            <div class="about-library-total">${ITEMS.length} catalog entries</div>
            <div class="about-library-detail">Scripts, quick commands, and guides.</div>
          </section>

          <div class="about-key">
            <span class="access-read">READ ONLY</span><span>reviews information</span>
            <span class="access-change">MAKES CHANGES</span><span>modifies configuration or access</span>
            <span class="access-danger">DESTRUCTIVE</span><span>can remove data, access, or objects; shown with MAKES CHANGES</span>
          </div>

          <details class="security-note about-security">
            <summary>Security checks &amp; responsible use</summary>
            <p>Publishing is protected by pull requests, required integrity checks, code scanning, and secret scanning. Catalog downloads are verified against published checksums.</p>
            <p>These controls reduce risk; they do not guarantee that every script is safe or suitable for your environment. Review the code and required permissions, and test before running. <a href="https://github.com/Grimmieeee/pwsh-operations-catalog/blob/main/SECURITY.md">Security details</a>.</p>
          </details>
          <p class="about-foot">Review the selected item before execution.</p>
        </section>
      `;
      return;
    }

    const list = filteredItems();

    crumb.textContent = areaLabel(state.area).toUpperCase();
    const showCount = queryActive || state.area !== "Full Library";
    entryCount.textContent = showCount ? `(${list.length})` : "";
    entryCount.classList.toggle("hidden", !showCount);
    entryCount.setAttribute("aria-label", `${list.length} matching catalog entries`);
    clearSearch.classList.toggle("hidden", !state.query);
    contextBar.textContent = "";
    contextBar.classList.add("hidden");
    jumpBar.innerHTML = "";
    jumpBar.classList.add("hidden");

    if (!list.length){
      results.innerHTML = "";
      empty.classList.remove("hidden");
      return;
    }

    empty.classList.add("hidden");

    if (queryActive){
      results.innerHTML = '<div class="group">' + list.map((item,i) => resultMarkup(item,i)).join("") + "</div>";
    } else {
      const grouped = new Map();
      for (const item of list){
        const key = state.area === "Full Library"
          ? primaryBucket(item)
          : (["Single User","Multi User","Tenant Wide"].includes(state.area)
              ? scopeSubgroup(item)
              : (item.group || "General"));
        if (!grouped.has(key)) grouped.set(key,[]);
        grouped.get(key).push(item);
      }

      results.innerHTML = [...grouped.entries()].map(([group,items]) => `
        <section class="group" id="${esc(bucketId(group))}">
          <div class="group-title">${groupTitleMarkup(state.area === "Full Library" ? areaLabel(group) : group)}</div>
          ${items.map(item => resultMarkup(item, list.indexOf(item))).join("")}
        </section>
      `).join("");
    }

    const visible = list;
    results.querySelectorAll("[data-open-index]").forEach((btn, idx) => {
      btn.addEventListener("click", () => openItem(visible[idx]));
    });

    jumpBar.querySelectorAll("[data-jump]").forEach(btn => {
      btn.addEventListener("click", () => {
        const target = document.getElementById(btn.getAttribute("data-jump"));
        target?.scrollIntoView({behavior:"smooth",block:"start"});
      });
    });
  }

  function connectMarkup(item){
    if (!item.connect.length) return "";
    return `
      <div class="run-connect">
        ${item.connect.map(cmd => `
          <div class="connect-line">
            ${cmd.length > 80 ? `<details class="connect-command"><summary>${esc(cmd.trim().split(/\s+/)[0])} <span class="connect-expand">Show command</span></summary><code>${esc(cmd)}</code></details>` : `<code>${esc(cmd)}</code>`}
            <button class="copy-mini" type="button" data-copy="${esc(cmd)}">COPY</button>
          </div>
        `).join("")}
      </div>
    `;
  }

  function workflowMarkup(workflow){
    if (!workflow) return "";
    const note = workflow.current === '1' ? 'Start here. Continue to containment only if needed and approved.' : workflow.current === '2' ? 'After containment, review recovery readiness before restoring access.' : 'Restore only approved access, then verify the user can sign in with MFA.';
    return `<section class="workflow-block"><div class="section-label">STEP ${esc(workflow.current)} OF 3</div><div class="workflow-note">${esc(note)}</div><div class="sequence">${workflow.steps.map(step=>`<button type="button" class="sequence-row workflow-link ${step.n===workflow.current ? "sequence-current" : ""}" data-related-file="${esc(step.file)}" ${step.n===workflow.current ? 'aria-current="step"' : ''}><span class="sequence-number">${esc(step.n)}</span><span>${esc(step.name.replace(/^(?:BEC|Incident Response): /,""))}</span></button>`).join("")}</div></section>`;
  }

  function startMarkup(item){
    if (!item.publishedPath?.endsWith('.ps1')) return '';
    if (!window.FIELD_KIT_START) return '<section class="guided-start"><div class="section-label">STEPS</div><p>Start guidance could not load. Reload the site before proceeding. Individual source controls remain below.</p></section>';
    const ir=Boolean(window.FIELD_KIT_START.stages[item.file]);
    const terminal=/^terminal(?:-admin)?$/.test(item.startMode || '');
    const code=window.FIELD_KIT_START.launch(item.file)+(item.file==='git-repo.ps1' ? ' -Path (Read-Host "Full path to the target Git repository") -Action (Read-Host "Action: Check, Pull, or Push")' : item.launchArgs || '');
    if(!ir && !terminal)return '<section class="guided-start operator-steps"><div class="section-label">STEPS</div><p>Download file.<br>Right-click the downloaded file.<br>Select <strong>Run with PowerShell.</strong><br>Press Enter to close session when complete.</p></section>';
    return `<section class="guided-start operator-steps"><div class="section-label">STEPS</div>
      ${ir ? '<p>Download the workflow. Extract all three scripts into one folder on your approved Windows support computer.</p><button id="downloadIRWorkflow" class="action primary" type="button">DOWNLOAD BEC WORKFLOW</button><div id="workflowStatus" class="source-note" role="status"></div>' : '<p>Download file.</p>'}
      <p>${ir ? 'Keep the workflow in the same PowerShell window.' : item.startMode==='terminal-admin' ? 'Open PowerShell as administrator.' : 'Use the PowerShell window where this tool should run.'}</p>
      <div class="connect-line"><details class="connect-command"><summary>Launch command <span class="connect-expand">Show command</span></summary><code>${esc(code)}</code></details><button class="copy-mini" type="button" data-copy="${esc(code)}">COPY</button></div>
      <p>Copy the command into that window. Select <strong>Copy as path</strong> for the downloaded file and paste the path when asked.</p>
      ${ir ? '<p>Use the script handoff to continue. Keep the workflow window open.</p>' : '<p>Use the tool’s own finish controls; the existing PowerShell window stays open.</p>'}
      ${ir ? `<details class="workflow-guide"><summary>Workflow preparation</summary>${window.FIELD_KIT_START.preparation.map(text=>`<p>${esc(text)}</p>`).join('')}</details>` : ''}
    </section>`;
  }
  function scopeMarkup(item){
    if(item.operatorCard)return `<div class="operator-scope">${esc(item.operatorCard.scope)}<span>${esc(item.operatorCard.input)}</span></div>`;
    if(item.type==='Quick Command')return '<div class="operator-scope">QUICK COMMAND</div>';
    if(isDocument(item))return '';
    return `<div class="operator-scope">${esc(primaryBucket(item).toUpperCase())}</div>`;
  }
  function operatorDetailsMarkup(item){
    const spec=item.operatorCard;
    if(!spec)return shortNote(item);
    const notes=[...connectionInfo(item),...(spec.preparation || []),...spec.details];
    if(item.reviewNote)notes.push(item.reviewNote);
    if(item.changeNote && !spec.notice && !notes.includes(item.changeNote))notes.push(item.changeNote);
    if(item.workflow){const step=completionInfo(item);if(step)notes.push(step.result,step.next,step.blocked);}
    const sample=spec.inputExample;
    const example=sample ? `<div class="input-example"><p>${sample.header==='Group' ? 'Use group names or email addresses.' : 'Use the full sign-in address (UPN).'} Replace these examples with your targets.</p><p>Multiple entries: separate with commas when typing into the script.</p><pre>${esc(sample.values.join(','))}</pre><p>CSV: use a ${esc(sample.header)} column.</p><pre>${esc([sample.header,...sample.values].join('\n'))}</pre><p>Enter the saved file’s full path when prompted. CSV/TXT selects targets; it does not approve changes.</p></div>` : '';
    return notes.length?`<details class="operator-details"><summary>DETAILS</summary><ul>${[...new Set(notes)].map(text=>`<li>${esc(text)}</li>`).join('')}</ul>${example}</details>`:'';
  }

  function connectionInfo(item){
    const record=window.FIELD_KIT_CONNECTION_GUIDANCE?.[item.publishedPath];
    if(!record || record.sha256!==window.FIELD_KIT_SOURCE_INTEGRITY?.[item.publishedPath])return [];
    const services=record.services || [];
    const labels={GRAPH:'Microsoft Graph',EXO:'Exchange Online',AD:'local Active Directory'};
    if(services.length)return ['Connection: '+services.map(service=>labels[service] || service).join(' + ')+'.',services.includes('GRAPH') || services.includes('EXO') ? 'Sign-in: use the approved customer account when the workflow requests it.' : 'Sign-in: uses the Windows account running this job.'];
    if(item.file==='IR-GET-THREAT-INTEL-ACTIVITY.ps1')return ['Connection: external IP reputation services.','Sign-in: provider API keys supplied for this run.'];
    if(item.file==='git-repo.ps1')return ['Connection: the repository remote when pulling or pushing.','Sign-in: the Git credentials configured for that remote.'];
    if(item.file==='UPDATE-WINDOWS-APPS.ps1')return ['Connection: configured WinGet package sources.','Sign-in: uses the Windows account; individual installers may request approval.'];
    if(['RESET-M365-SESSION.ps1','INVOKE-SESSION-RESET.ps1'].includes(item.file))return ['Connection: existing sessions in this PowerShell window.','Sign-in: no new customer sign-in.'];
    if(['PREPARE-FIELD-KIT.ps1','INSTALL-M365-MODULES.ps1'].includes(item.file))return ['Connection: official PowerShell Gallery for approved installations.','Sign-in: the current Windows account; no customer tenant sign-in.'];
    return ['Connection: this computer or supplied files.','Sign-in: uses the approved Windows account; no new customer tenant sign-in.'];
  }

  function completionInfo(item){
    return window.FIELD_KIT_START?.stages[item.file] || item.completion || null;
  }

  function finishMarkup(item){
    const step=completionInfo(item);
    if(!step)return '';
    if (!item.workflow) return `<details class="workflow-guide completion-guide"><summary>WHEN FINISHED</summary><p>${esc(step.result)}</p><p>${esc(step.next)}</p><details class="workflow-guide"><summary>If blocked or cancelled</summary><p>${esc(step.blocked)}</p></details></details>`;
    return `<section class="guided-finish"><div class="section-label">EXPECTED RESULT</div><p>${esc(step.result)}</p><div class="section-label">NEXT</div><p>${esc(step.next)}</p><details class="workflow-guide"><summary>If blocked or cancelled</summary><p>${esc(step.blocked)}</p></details></section>`;
  }

  function comparableAction(value){
    return norm(value)
      .split(" ")
      .map(word => {
        if (/^(?:shows|checks|finds|moves|builds|reviews|removes|adds|updates|installs|disconnects|enforces|targets)$/.test(word)){
          return word.replace(/(?:es|s)$/,"");
        }
        return word;
      })
      .join(" ");
  }

  function displayFacts(item){
    const facts = Array.isArray(item.facts?.items) ? item.facts.items : [];
    const bucket = primaryBucket(item);
    const title = comparableAction(item.displayName);

    return facts.filter(value => {
      const text = String(value || "").trim();
      const normalized = norm(text);
      if (!normalized) return false;

      // Scope is already shown in the card context.
      if (bucket === "Single User" && /^(?:targets?\s+)?(?:one|single)\s+user\b/i.test(text)) return false;
      if (bucket === "Multi User" && /^(?:targets?\s+)?(?:multiple|many)\s+users?\b/i.test(text)) return false;
      if (bucket === "Tenant Wide" && /^(?:targets?\s+)?tenant(?:[- ]wide)?\b/i.test(text)) return false;

      // Don't repeat the card title as a DOES/CHECKS line.
      if (title && comparableAction(text) === title) return false;
      if (comparableAction(item.objective || "").includes(comparableAction(text))) return false;
      if (/^(?:summary|csv|export)\s*:?\s*(?:yes|ready)$/i.test(text)) return false;

      return true;
    });
  }

  function factsMarkup(item){
    const facts = displayFacts(item);
    // Classify by meaning, never by list position or the old mixed-list label.
    const guardFacts = new Set([
      "Configurable inactivity threshold", "Guests and disabled users excluded",
      "Separates synced and cloud-only authority", "Uses Active Directory for synced users",
      "Uses Entra ID for cloud-only users", "Shows the full disable preview",
      "Exact UPN resolution", "AD authority for synced users",
      "Entra authority for cloud-only and guest users", "Full deletion plan before action",
      "UsageLocation handling when approved", "Full preview before changes",
      "Numbered license selection or ALL", "Full plan before changes",
      "Targets the requested tenant before searching", "Tenant-target validation",
      "Direct members only", "Single group creation", "Previewed membership rule",
      "Changes only noncompliant mailboxes", "Uses CurrentUser scope",
      "Does not connect to a tenant", "Supports review-only mode", "Confirms before changes",
      "Uses the preferred authentication flow", "Validates disabled state at the authoritative identity source",
      "Shows the complete removal plan", "Tenant-ID bound local baseline",
      "Verified baseline writes only after approval", "Synced memberships changed in AD",
      "Dynamic and role-assignable groups skipped", "Exchange-managed mail groups skipped",
      "Separate from Conditional Access", "Uses previous snapshot as the work boundary",
      "Remembers exact reviewed records, not trusted identities", "No API token; manual GitHub export",
      "Respects managed execution policy", "No module installs or digital signing",
      "Public-source safety boundaries", "Skips valid signatures from the selected certificate unless forced"
    ]);
    const isGuard = text => guardFacts.has(text) ||
      /^(?:requires?\b|typed\b|one .+ input$|supports .+ selection$|push:|pull:)/i.test(text);
    const checks = item.checks || facts.filter(text => !isGuard(text));
    const inputFacts = facts.filter(text => /^one .+ input$/i.test(text));
    const inputs = inputInfo(item) ? [inputInfo(item)] : inputFacts;
    const guards = item.guards || facts.filter(isGuard).filter(text => !inputFacts.includes(text));
    const requires = requirementInfo(item);
    const list = values => `<div class="check-list">${values.map(text => `<div class="check-item">${esc(window.FIELD_KIT_PLAIN_PHRASES?.[text] || text)}</div>`).join("")}</div>`;
    const input = inputs.length ? `<section class="check-block"><div class="section-label">INPUT</div><div class="check-list">${inputs.map(text => `<div class="input-item">${esc(text)}</div>`).join("")}</div></section>` : "";
    const review = `${checks.length ? `<details class="card-disclosure"><summary>CHECKS</summary>${list(checks)}</details>` : ""}
      ${guards.length ? `<details class="card-disclosure"><summary>GUARDS</summary>${list(guards)}</details>` : ""}
      ${requires ? `<details class="requirements"><summary title="${esc(requires)}">REQUIRES</summary><div class="requirements-copy">${esc(requires)}</div></details>` : ""}`;
    return input + review;
  }

  function accessMarkup(item){
    if (isDocument(item)) return `<div class="access-state"><span class="access-tag result-document">${documentLabel(item)}</span></div>`;
    const access = String(item.access || "").toLowerCase();

    if (access.includes("destructive")) {
      return '<div class="access-state">' +
        '<span class="access-tag access-change">MAKES CHANGES</span>' +
        '<span class="access-tag access-danger">DESTRUCTIVE</span>' +
        '</div>';
    }

    if (access.includes("change") || access.includes("mixed")) {
      return '<div class="access-state"><span class="access-tag access-change">MAKES CHANGES</span></div>';
    }

    if (access.includes("read-only") || access.includes("read only") || access.includes("readonly")) {
      return '<div class="access-state"><span class="access-tag access-read">READ ONLY</span></div>';
    }

    return '<div class="access-state"><span class="access-tag access-change">REVIEW ACCESS</span></div>';
  }

  function optionMarkup(item){
    if (!item.options || !Array.isArray(item.options.values) || !item.options.values.length) return "";
    return `
      <div class="option-line">
        <span class="option-label">${esc(item.options.label || "OPTIONS")}</span>
        <span class="option-values">${item.options.values.map(esc).join(" / ")}</span>
      </div>
    `;
  }

  function useForMarkup(item){
    if (item.type !== "Quick Command") return "";
    const value = String(item.useFor || "").trim();
    if (!value) return "";
    return `
      <section class="note-block">
        <div class="section-label">USE FOR</div>
        <div>${esc(value)}</div>
      </section>
    `;
  }

  function objectiveMarkup(item){
    if (item.type === "Quick Command") return "";
    const objective = String(item.objective || item.notes || "").trim().split(/(?<=[.!?])\s+/)[0];
    if (!objective) return "";

    return `
      <section class="objective-block">
        <div class="section-label">USE FOR</div>
        <div class="objective-copy">${esc(objective)}</div>
      </section>
    `;
  }

  function shortNote(item){
    const reviewNote = item.reviewNote ? `<p class="source-note">${esc(item.reviewNote)}</p>` : "";
    // Reviewed summaries only: remove known duplication without guessing whether
    // an unfamiliar caveat is safe to hide.
    const concise = {
      "GET-QUARTERLY-CLEANUP-REVIEW.ps1":"",
      "GET-STALE-SIGNIN-REVIEW.ps1":"Missing sign-in activity is never classified as inactivity.",
      "get-inactive-group-debt.ps1":"", "get-inactive-mailbox-debt.ps1":"",
      "invoke-user-onboard.ps1":"", "invoke-user-offboard.ps1":"",
      "INVOKE-DISABLE-ACCOUNTS.ps1":"", "INVOKE-DELETE-ACCOUNTS.ps1":"",
      "INVOKE-ASSIGN-LICENSES.ps1":"", "INVOKE-REMOVE-LICENSES.ps1":"",
      "RESOLVE-NAMES-TO-UPNS.ps1":"", "GET-ACCOUNT-STATUS.ps1":"Missing sign-in data is never treated as inactivity.",
      "GET-GROUP-MEMBERS.ps1":"", "GET-USER-GROUPS.ps1":"",
      "INVOKE-REMOVE-USER-GROUPS.ps1":"", "INVOKE-CREATE-DYNAMIC-LICENSE-GROUP.ps1":"",
      "GET-TENANT-GROUP-OWNERS.ps1":"", "GET-MAILBOX-PERMISSIONS.ps1":"",
      "GET-MAILBOX-FORWARDING.ps1":"", "INVOKE-LITIGATION-HOLD.ps1":"",
      "GET-SHARED-MAILBOX-SIGNIN-AUDIT.ps1":"", "GET-APP-REGISTRATION-AUDIT.ps1":"",
      "GET-CONDITIONAL-ACCESS-GAPS.ps1":"", "TEST-POWERSHELL-READINESS.ps1":"",
      "INSTALL-M365-MODULES.ps1":"", "GET-FOLDER-INVENTORY.ps1":"Does not enforce a fixed folder structure."
    };
    const note = String(item.details ?? (Object.hasOwn(concise,item.file) ? concise[item.file] : (item.notes || ""))).trim();
    const verificationScope = isVerifiedRelease(item) && item.verification.scope ? `<p><strong>Tested scope:</strong> ${esc(item.verification.scope)}</p>` : "";
    const noteText = note && note !== item.objective && note !== item.changeNote && item.type !== "Quick Command" ? `<p>${esc(note)}</p>` : "";
    if (!noteText && !verificationScope) return reviewNote;
    return reviewNote + `<details class="more-details"><summary>Details</summary>${noteText}${verificationScope}</details>`;
  }

  function csvCapability(item){
    return /^YES$/i.test(String(item.csv || "").trim()) ? "YES" : "";
  }

  function summaryCapability(item){
    const explicit = String(item.summary || "").trim();
    return /^YES/i.test(explicit) ? "YES" : "";
  }

  function requirementInfo(item){
    const value = String(item.requires || "").replace(/\s*First sign-in requests[^.]*\./ig, "").trim();
    if (!value) return "";
    if (/^(?:none|n\/a|powerShell\s*5\.1\+?)$/i.test(value)) return "";
    if (/^optional\b/i.test(value)) return "";
    return value;
  }

  function inputInfo(item){
    const value = String(item.input || "").trim();
    if (item.type === "Quick Command") return value || commandInputInfo(item.code || "");
    if (!value) return "";

    const bucket = primaryBucket(item);
    if (bucket === "Single User" && /^user$/i.test(value)) return "";
    if (bucket === "Tenant Wide" && /^tenant$/i.test(value)) return "";

    return value;
  }

  function commandInputInfo(code){
    // Match the catalog's literal examples, not command/property names.
    const examples = [
      [/\busername\b|DOMAIN\\\\User/i, "target account name"],
      [/(?:user|owner|delegate|recipient|group)@domain\.com/i, "target user, mailbox or group address"],
      [/GroupName|Group Name|GROUP-OBJECT-ID/, "group name or object ID"],
      [/Jane Doe/, "exact display name"],
      [/APP-ID|AUTH-METHOD-ID|OAUTH-GRANT-ID|MESSAGE-TRACE-ID/, "record ID from a prior lookup"],
      [/THUMBPRINT/, "certificate thumbprint"],
      [/SEARCH-NAME|phishing subject|Rule Name|Task Name/, "target search, rule, task or subject"],
      [/1\.2\.3\.4|8\.8\.8\.8|example\.com|server01/, "target IP address, domain or host"],
      [/C:\\\\(?:Temp|Scripts)|C:\\(?:Temp|Scripts)/, "local file or folder path"],
      [/badguy@evil\.com/, "suspect sender address"],
      [/['"](?:Ethernet|Wi-Fi)['"]/, "network adapter name"],
      [/['"]UPN['"]/, "target user UPN"],
      [/['"]notepad['"]/, "process name"],
      [/['"]Spooler['"]/, "service name"],
      [/\*Remote Desktop\*/, "firewall rule display-name filter"],
      [/M365-AppAuth/, "certificate subject name"]
    ].filter(([pattern]) => pattern.test(code)).map(([,label]) => label);
    if (!examples.length) return "";
    return "Replace command examples with your " + [...new Set(examples)].join("; ") + ". Review all target values before running.";
  }

  function runInfoMarkup(item){
    if (isDocument(item)) return "";
    const recorded = window.FIELD_KIT_CONNECTION_GUIDANCE?.[item.publishedPath];
    const profile = recorded && recorded.sha256 === window.FIELD_KIT_SOURCE_INTEGRITY?.[item.publishedPath] ? recorded : null;
    const platform = profile?.services?.length ? profile.services.join(" + ") : moduleLabel(item);
    const badge = platform ? `<div><span class="platform-label">${esc(platform)}</span></div>` : "";
    if (profile?.mode === "auto"){
      const workflow = IR_STEPS.some(step => step.file === item.file);
      return `<section class="run-info-block">${badge}${workflow ? '<p class="connection-direction">Before starting: approved Windows jumpbox, Graph Authentication 2.x, Exchange Online module 3.2+, and authorized tenant access. Keep all three files together and use the same PowerShell window.</p><button type="button" class="copy-mini" data-related-file="TEST-POWERSHELL-READINESS.ps1">CHECK POWERSHELL READINESS</button>' : ''}</section>`;
    }
    if (profile?.mode === "local") return badge ? `<section class="run-info-block">${badge}</section>` : "";
    if (item.status === "Source pending") return "";
    if (item.publishedPath){
      return `<section class="run-info-block"><div class="run-info-subhead">CONNECTIONS</div>${badge}<p class="connection-direction">Connection setup needs review before running this script.</p></section>`;
    }
    // Quick commands are their own source. Do not duplicate connection commands
    // when the selected command already performs that connection.
    if (/^\s*(?:Connect-|Import-Module)/i.test(item.code || "")) return '<section class="run-info-block"><div class="run-info-subhead">START</div><p class="connection-direction">Open PowerShell on the target computer. Replace any example values, then paste the command below.</p></section>';
    if (!item.connect.length) return item.type === "Quick Command" ? `<section class="run-info-block"><div class="run-info-subhead">START</div><p class="connection-direction">Open PowerShell on the target computer. Replace any example values, then paste the command below.</p></section>` : "";
    return `<section class="run-info-block"><div class="run-info-subhead">CONNECT FIRST</div>${badge}<p class="connection-direction">Run these commands in the same PowerShell window before running the selected command.</p>${connectMarkup(item)}</section>`;
  }

  function sourceButton(item){
    if (item.type === "Quick Command") return "";
    if (!item.publishedPath && !item.code) return '<span class="source-note">Source pending. Download not available yet.</span>';
    const ext = /\.md$/i.test(item.file || "") ? ".MD" : ".PS1";
    const buttons = `<button id="downloadSource" class="action ${item.workflow ? '' : 'primary'}" type="button">Download</button><button id="showSource" class="action" type="button">View Code</button>`;
    return (item.workflow ? `<details class="individual-source"><summary>Individual script / source</summary><div class="actions">${buttons}</div></details>` : buttons)+'<span id="sourceStatus" role="status"></span>';
  }

  function referenceButtons(item){
    const name = String(item.name || "");
    const file = String(item.file || "");
    const type = String(item.type || "");
    const buttons = [];
    const reference = safeReferenceUrl(item.url);

    if (/runbook/i.test(type + " " + name + " " + file) && reference){
      buttons.push(`<a class="action" href="${esc(reference)}" target="_blank" rel="noopener noreferrer">RUNBOOK</a>`);
    }
    if (/readme/i.test(file) && reference){
      buttons.push(`<a class="action" href="${esc(reference)}" target="_blank" rel="noopener noreferrer">README</a>`);
    }
    return buttons.join("");
  }

  function standaloneCommandMarkup(item){
    if (item.type !== "Quick Command" || !item.code) return "";
    const platform = !item.connect.length || /^\s*(?:Connect-|Import-Module)/i.test(item.code) ? moduleLabel(item) : "";
    return `
      <section class="command-block">
        ${platform ? `<div><span class="platform-label">${esc(platform)}</span></div>` : ""}
        <div class="section-label">COMMAND</div>
        <div class="inline-code-box"><div class="source-heading"><button class="copy-mini" type="button" data-copy-source>COPY</button></div><pre class="command">${esc(item.code)}</pre></div>
      </section>
    `;
  }

  function openItem(item){
    closeNav();
    if (!document.body.classList.contains("drawer-open")){
      lastFocusedElement = document.activeElement instanceof HTMLElement
        ? document.activeElement
        : null;
    }
    state.selected = item;

    drawerBody.innerHTML = `
      <section class="item-head">
        <div class="item-context">${esc(item.operatorCard ? item.operatorCard.family==='ir-workflow' ? 'BEC' : item.operatorCard.family.startsWith('ir-') ? 'Incident Response' : item.operatorCard.family : primaryBucket(item))}</div>
        <h2 class="item-title">${itemTitleMarkup(item.displayName)}${releaseTag(item)}</h2>
        ${item.operatorCard ? `<p class="operator-purpose">${esc(item.operatorCard.objective)}</p>` : ''}
        <div class="operator-meta">${accessMarkup(item)}${item.operatorCard ? `<span class="operator-platform">${esc(moduleLabel(item).replace(/GRAPH/g,'Entra').replace(/EXO|EXCHANGE/g,'Exchange').replace(/ACTIVE DIRECTORY/g,'AD'))}</span>` : ''}</div>
        ${scopeMarkup(item)}
        ${item.status==='Source pending'?'<div class="source-note">SOURCE PENDING — download is not available.</div>':''}
      </section>
      ${item.operatorCard?.notice ? `<p class="change-note operator-notice">${esc(item.operatorCard.notice)}</p>` : ''}
      ${item.operatorCard ? '' : objectiveMarkup(item)}
      ${item.operatorCard ? '' : useForMarkup(item)}
      ${item.changeNote && !item.operatorCard ? `<div class="change-note">${esc(item.changeNote)}</div>` : ''}
      ${optionMarkup(item)}
      ${workflowMarkup(item.workflow)}
      ${item.operatorCard ? '' : factsMarkup(item)}
      ${item.operatorCard ? '' : runInfoMarkup(item)}
      ${startMarkup(item)}
      ${standaloneCommandMarkup(item)}
      <div class="actions operator-actions">${sourceButton(item)}${referenceButtons(item)}</div>
      <div id="sourceMount"></div>
      <div id="copyStatus" role="status" aria-live="polite"></div>
      ${operatorDetailsMarkup(item)}
      ${item.status==='Source pending' ? '<p class="source-note">'+(PENDING_NEXT_STEPS[item.file] ? 'The tools below cover individual tasks; they do not replace the complete planned workflow. Review each tool’s scope before continuing.' : 'No working replacement is published. Use your approved process for this task until this tool is available.')+'</p>' : ''}
      ${relatedMarkup(item)}
    `;

    bindDrawerActions(item);
    drawer.inert = false;
    if (shell) shell.inert = true;
    document.body.classList.add("drawer-open");
    drawer.setAttribute("aria-hidden","false");
    window.requestAnimationFrame(() => closeDrawer?.focus());
  }

  function bindDrawerActions(item){
    document.getElementById('downloadIRWorkflow')?.addEventListener('click',async e=>{
      const button=e.currentTarget,status=document.getElementById('workflowStatus');
      button.disabled=true;
      button.textContent='VERIFYING WORKFLOW';status.textContent='Checking all three scripts before building the package…';
      try { const blob=await buildIRBundle();saveBlob(blob,'field-kit-bec.zip');status.textContent='All three source checksums match the reviewed release. Workflow package downloaded.'; }
      catch(error){status.textContent=error.message||'Workflow package could not be built. No partial package was downloaded.';}
      finally{button.disabled=false;button.textContent='DOWNLOAD BEC WORKFLOW';}
    });
    drawerBody.querySelector("[data-verification-about]")?.addEventListener("click",()=>{
      closeItem();state.area="About";state.query="";search.value="";renderNav();renderResults();
    });
    drawerBody.querySelectorAll("[data-related-file]").forEach(button=>button.addEventListener("click",()=>{
      const target=button.dataset.relatedName ? ITEMS.find(other=>other.type==='Quick Command' && other.name===button.dataset.relatedName) : ITEMS.find(other=>other.file===button.dataset.relatedFile);
      if (target) {openItem(target);drawerBody.scrollTop=0;}
    }));
    for (const id of ["downloadSource"]){
      const button = document.getElementById(id);
      button?.addEventListener("click", async () => {
        button.disabled = true;
        const status = document.getElementById("sourceStatus");
        try {
          const source = await resolveSource(item);
          if (!source) throw new Error("Source is unavailable.");
          saveText(source,safeFilename(item.file));
          status.textContent = "Download verified.";
        } catch(error){ status.textContent = error.message || "Could not load source."; }
        finally { button.disabled = false; }
      });
    }

    drawerBody.querySelectorAll("[data-copy]").forEach(btn => {
      btn.addEventListener("click", async () => {
        await copyWithFeedback(btn, btn.getAttribute("data-copy") || "");
      });
    });

    const copySource = drawerBody.querySelector("[data-copy-source]");
    if (copySource){
      copySource.addEventListener("click", async () => {
        await copyWithFeedback(copySource, item.code || "");
      });
    }

    const showSource = document.getElementById("showSource");
    if (showSource){
      showSource.addEventListener("click", () => toggleSource(item,showSource));
    }
  }

  function safeReferenceUrl(value){
    if (!String(value || "").trim()) return "";
    try {
      const url = new URL(value, window.location.href);
      if (url.username || url.password) return "";
      if (url.protocol === "https:" || (url.origin === window.location.origin && url.protocol === "http:")) return url.href;
    } catch {}
    return "";
  }

  function approvedSourceUrl(path){
    const value = String(path || "");
    if (!/^(?:published-source\/|tools\/|toys\/|OPERATING-STANDARDS\.md$)/.test(value) ||
        !/^[a-z0-9._/-]+\.(?:ps1|md)$/i.test(value) ||
        value.split("/").some(part => !part || part === "." || part === "..")) {
      throw new Error("This source path is not approved.");
    }
    const expected = window.FIELD_KIT_SOURCE_INTEGRITY?.[value];
    if (!/^[a-f0-9]{64}$/.test(expected || "")) throw new Error("This source has no release checksum.");
    const base = new URL("./", window.location.href);
    const url = new URL(value, base);
    if (url.origin !== base.origin || !url.pathname.startsWith(base.pathname)) throw new Error("Source must stay within this catalog.");
    return {url:url.href,expected};
  }

  async function resolveSource(item){
    if (!item.publishedPath) return item.code || "";
    const approved = approvedSourceUrl(item.publishedPath);
    if (sourceCache.has(approved.url)) return sourceCache.get(approved.url);
    const controller = new AbortController();
    const timer = window.setTimeout(() => controller.abort(), 15000);
    try {
      const response = await fetch(approved.url, {
        cache:"no-store", credentials:"omit", redirect:"error", signal:controller.signal
      });
      if (!response.ok || response.redirected) throw new Error("Source could not be loaded.");
      if (/html|xml/i.test(response.headers.get("content-type") || "")) throw new Error("The server returned a page instead of source.");
      if (Number(response.headers.get("content-length")) > 2 * 1024 * 1024) throw new Error("Source exceeds the download limit.");
      const chunks = [];
      const reader = response.body.getReader();
      let length = 0;
      while (true){
        const {value,done} = await reader.read();
        if (done) break;
        length += value.byteLength;
        if (length > 2 * 1024 * 1024){ await reader.cancel(); throw new Error("Source exceeds the download limit."); }
        chunks.push(value);
      }
      if (!length) throw new Error("The source file is empty.");
      const bytes = new Uint8Array(length);
      let offset = 0;
      for (const chunk of chunks){ bytes.set(chunk,offset); offset += chunk.byteLength; }
      if (!window.crypto?.subtle) throw new Error("Use HTTPS or localhost to verify downloads.");
      const hash = Array.from(new Uint8Array(await window.crypto.subtle.digest("SHA-256",bytes)), byte => byte.toString(16).padStart(2,"0")).join("");
      if (hash !== approved.expected) throw new Error("Source checksum mismatch. Reload the page and try again.");
      // Keep an existing UTF-8 BOM and line endings so the saved file matches the reviewed bytes.
      const source = new TextDecoder("utf-8",{fatal:true,ignoreBOM:true}).decode(bytes);
      if (/^\s*(?:<!doctype\s+html|<html\b|<head\b|<body\b)/i.test(source)) throw new Error("The server returned a page instead of source.");
      sourceCache.set(approved.url,source);
      return source;
    } catch(error){
      if (error.name === "AbortError") throw new Error("Source request timed out. Try again.");
      throw error;
    } finally { window.clearTimeout(timer); }
  }

  async function toggleSource(item, button){
    const mount = document.getElementById("sourceMount");
    if (!mount) return;

    const isMarkdown = /\.md$/i.test(String(item.file || ""));
    const sourceLabel = isMarkdown ? "MARKDOWN" : "POWERSHELL";

    if (mount.dataset.open === "1"){
      mount.innerHTML = "";
      mount.dataset.open = "0";
      button.textContent = "VIEW CODE";
      return;
    }

    button.disabled = true;
    button.textContent = "LOADING";

    try{
      const source = await resolveSource(item);
      if (state.selected !== item || !mount.isConnected) return;
      if (!source){
        mount.innerHTML = `
          <section class="source-block">
            <div class="section-label">${sourceLabel}</div>
            <div class="source-note">
              The source file is not published in this preview yet. The UI is wired for same-origin source loading once an approved copy is added to the public catalog.
            </div>
          </section>
        `;
      } else {
        mount.innerHTML = `
          <section class="source-block">
            <div class="source-heading"><div class="section-label">${sourceLabel}</div><button id="copyScript" class="copy-mini" type="button">COPY</button></div>
            <pre class="command">${esc(source)}</pre>
          </section>
        `;

        document.getElementById("copyScript")?.addEventListener("click", async e => {
          const button = e.currentTarget;
          await copyWithFeedback(button,source);
        });

      }

      mount.dataset.open = "1";
      button.textContent = "HIDE CODE";
    } catch (error){
      if (state.selected !== item || !mount.isConnected) return;
      mount.innerHTML = `
        <section class="source-block">
          <div class="source-note">${esc(error.message || "Source could not be loaded.")}</div>
        </section>
      `;
      mount.dataset.open = "0";
      button.textContent = "VIEW CODE";
    } finally {
      button.disabled = false;
    }
  }

  function safeFilename(value){
    const base = String(value).split(/[\\/]/).pop() || "script.ps1";
    return base.replace(/[^a-z0-9._-]/gi,"-");
  }

  async function buildSetupBundle(){
    if(!window.FIELD_KIT_START)throw new Error('Package guidance could not load. Reload the site.');
    const names=['PREPARE-FIELD-KIT.ps1','START-HERE.md'];
    const files=await Promise.all(names.map(async name=>{
      const item=ITEMS.find(candidate=>candidate.file===name);
      const hash=item && window.FIELD_KIT_SOURCE_INTEGRITY?.[item.publishedPath];
      const review=window.FIELD_KIT_CARD_GUIDANCE?.[name];
      if(!item || !hash || review?.sourceSha256!==hash)throw new Error('Setup package needs source review. No package downloaded.');
      return {name,text:await resolveSource(item),hash};
    }));
    return window.FIELD_KIT_START.zip([...files,{name:'SHA256SUMS.txt',text:files.map(file=>file.hash+'  '+file.name).join('\n')+'\n'}]);
  }

  async function buildIRBundle(){
    if(!window.FIELD_KIT_START)throw new Error('Workflow guidance could not load. Reload the site.');
    const items=IR_STEPS.map(step=>ITEMS.find(candidate=>candidate.file===step.file));
    if(items.some(item=>!item || !(isVerifiedRelease(item) || isReviewedWorkflowPackage(item))))throw new Error('The workflow needs release review. No package downloaded.');
    if(new Set(items.map(item=>item.version)).size!==1)throw new Error('Workflow versions do not match. No package downloaded.');
    const files = await Promise.all(items.map(async item=>{
      return {name:item.file,text:await resolveSource(item),hash:window.FIELD_KIT_SOURCE_INTEGRITY[item.publishedPath],version:item.version};
    }));
    if(new Set(files.map(file=>file.version)).size!==1)throw new Error('Workflow versions do not match. No package downloaded.');
    return window.FIELD_KIT_START.zip([...files,{name:'IR-WORKFLOW-GUIDE.md',text:window.FIELD_KIT_START.guide()},{name:'SHA256SUMS.txt',text:files.map(file=>file.hash+'  '+file.name).join('\n')+'\n'}]);
  }

  function saveText(source, filename){
    saveBlob(new Blob([source],{type:"text/plain;charset=utf-8"}),filename);
  }
  function saveBlob(blob,filename){
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    a.remove();
    window.setTimeout(() => URL.revokeObjectURL(url),1000);
  }

  async function copyText(text){
    const value = String(text).replace(/^\uFEFF/,"");
    if (navigator.clipboard?.writeText){
      try { await navigator.clipboard.writeText(value); return; } catch {}
    }
    const active = document.activeElement;
    const ta = document.createElement("textarea");
    ta.value = value;
    ta.style.position = "fixed";
    ta.style.opacity = "0";
    // The fallback must stay inside the active dialog, outside the inert page.
    (document.body.classList.contains("drawer-open") ? drawerBody : document.body).appendChild(ta);
    try {
      ta.select();
      if (!document.execCommand("copy")) throw new Error("Copy failed. Select the code and copy it manually.");
    } finally { ta.remove(); active?.focus(); }
  }

  async function copyWithFeedback(button,text){
    const status = document.getElementById("copyStatus");
    try {
      await copyText(text);
      flashButton(button,"COPIED");
      if (status) status.textContent = "Copied.";
    } catch {
      if (status) status.textContent = "Copy failed. Select the code and copy it manually.";
    }
  }

  function flashButton(button,label){
    const old = button.textContent;
    button.textContent = label;
    window.setTimeout(() => { button.textContent = old; },900);
  }

  function closeItem(){
    const wasOpen = document.body.classList.contains("drawer-open");
    document.body.classList.remove("drawer-open");
    drawer.inert = true;
    if (shell) shell.inert = false;
    drawer.setAttribute("aria-hidden","true");
    state.selected = null;

    if (wasOpen && lastFocusedElement?.isConnected){
      const focusTarget = lastFocusedElement;
      window.requestAnimationFrame(() => focusTarget?.isConnected && focusTarget.focus());
    }
    lastFocusedElement = null;
  }

  function setNavOpen(open){
    document.body.classList.toggle("nav-open",open);
    menuBtn?.setAttribute("aria-expanded",String(open));
    menuBtn?.setAttribute("aria-label",open ? "Close navigation" : "Open navigation");
  }

  function closeNav(){
    setNavOpen(false);
  }

  function runFrameworkAudit(){
    const issues = [];
    const allowedBuckets = new Set(["Single User","Multi User","Tenant Wide","Incident Response","Utility","Standalone","Tools","Toys"]);
    const allowedPurpose = new Set(["User","Groups","Permissions","Licenses","Mailbox","Security","On / Offboarding","Audit"]);
    const seen = new Set();

    for (const item of ITEMS){
      const bucket = primaryBucket(item);
      const key = norm(bucket + " " + item.displayName);

      if (!item.displayName) issues.push("Missing display name.");
      if (!allowedBuckets.has(bucket)) issues.push("Unknown bucket: " + bucket + " / " + item.displayName);
      if (seen.has(key)) issues.push("Duplicate card: " + bucket + " / " + item.displayName);
      seen.add(key);

      if (["Single User","Multi User","Tenant Wide"].includes(bucket) && !allowedPurpose.has(scopeSubgroup(item))){
        issues.push("Unknown purpose: " + bucket + " / " + item.displayName);
      }

      if (item.type === "Quick Command" && !String(item.code || "").trim()){
        issues.push("Quick Command has no code: " + item.displayName);
      }

      if (item.publishedPath){
        try { approvedSourceUrl(item.publishedPath); }
        catch { issues.push("Unapproved source: " + item.displayName); }
      }
      if (item.url && !safeReferenceUrl(item.url)) issues.push("Unsafe reference URL: " + item.displayName);
    }

    const alphaCheck = (items, label) => {
      for (let i = 1; i < items.length; i++){
        if (items[i - 1].displayName.localeCompare(items[i].displayName) > 0){
          issues.push("A-Z order failed: " + label + " / " + items[i - 1].displayName + " > " + items[i].displayName);
          return;
        }
      }
    };

    for (const scope of ["Single User","Multi User","Tenant Wide"]){
      for (const purpose of ["User","Groups","Permissions","Licenses","Mailbox","Security","On / Offboarding","Audit"]){
        const subset = ITEMS
          .filter(item => primaryBucket(item) === scope && scopeSubgroup(item) === purpose)
          .slice()
          .sort((a,b) => a.displayName.localeCompare(b.displayName));
        alphaCheck(subset, scope + " / " + purpose);
      }
    }

    for (const area of ["Incident Response","Utility","Standalone","Tools","Toys"]){
      const groups = [...new Set(ITEMS.filter(item => primaryBucket(item) === area).map(item => item.group || "General"))];
      for (const group of groups){
        const subset = ITEMS
          .filter(item => primaryBucket(item) === area && (item.group || "General") === group)
          .slice()
          .sort((a,b) => a.displayName.localeCompare(b.displayName));
        alphaCheck(subset, area + " / " + group);
      }
    }

    const result = {
      ok: issues.length === 0,
      itemCount: ITEMS.length,
      issues
    };

    window.FIELD_KIT_AUDIT = result;
    if (result.ok) console.info("[FIELD // KIT] Framework audit passed:", result.itemCount, "items");
    else console.error("[FIELD // KIT] Framework audit failed:", issues);

    return result;
  }

  document.getElementById("showVerificationAbout")?.addEventListener("click",()=>{
    state.area="About";state.query="";search.value="";renderNav();renderResults();
  });

  areaNav.addEventListener("click", event => {
    const incidentSubgroup = event.target.closest("[data-incident-source]");
    if (incidentSubgroup){
      state.area = "Incident Response";
      state.incidentSource = incidentSubgroup.getAttribute("data-incident-source") || "";
      state.incidentOpen = true;
      state.standaloneGroup = "";
      state.standaloneOpen = false;
      renderNav();
      renderResults();
      closeNav();
      return;
    }

    const subgroup = event.target.closest("[data-standalone-group]");
    if (subgroup){
      state.area = "Standalone";
      state.standaloneGroup = subgroup.getAttribute("data-standalone-group") || "";
      state.standaloneOpen = true;
      state.incidentSource = "";
      state.incidentOpen = false;
      renderNav();
      renderResults();
      closeNav();
      return;
    }

    const btn = event.target.closest("[data-area]");
    if (!btn) return;

    const nextArea = btn.getAttribute("data-area") || "Full Library";

    if (nextArea === "Incident Response"){
      if (state.area === "Incident Response"){
        state.incidentOpen = !state.incidentOpen;
        renderNav();
        return;
      }

      state.area = "Incident Response";
      state.incidentSource = "";
      state.incidentOpen = true;
      state.standaloneGroup = "";
      state.standaloneOpen = false;
      renderNav();
      renderResults();
      closeNav();
      return;
    }

    if (nextArea === "Standalone"){
      if (state.area === "Standalone"){
        state.standaloneOpen = !state.standaloneOpen;
        renderNav();
        return;
      }

      state.area = "Standalone";
      state.standaloneGroup = "";
      state.standaloneOpen = true;
      state.incidentSource = "";
      state.incidentOpen = false;
      renderNav();
      renderResults();
      closeNav();
      return;
    }

    state.area = nextArea;
    state.incidentSource = "";
    state.incidentOpen = false;
    state.standaloneGroup = "";
    state.standaloneOpen = false;
    renderNav();
    renderResults();
    closeNav();
  });

  search.addEventListener("input", () => {
    state.query = search.value;
    renderResults();
  });

  clearSearch.addEventListener("click", () => {
    search.value = "";
    state.query = "";
    search.focus();
    renderResults();
  });

  closeDrawer.addEventListener("click",closeItem);
  drawerOverlay.addEventListener("click",closeItem);
  document.addEventListener("keydown",event => {
    if (event.key === "Tab" && document.body.classList.contains("drawer-open")){
      const focusable = [...drawer.querySelectorAll('button:not([disabled]),a[href],input:not([disabled]),textarea:not([disabled]),summary,[tabindex="0"]')]
        .filter(element => element.getClientRects().length);
      const first = focusable[0];
      const last = focusable[focusable.length - 1];
      if (first && event.shiftKey && (document.activeElement === first || !drawer.contains(document.activeElement))){ event.preventDefault(); last.focus(); }
      else if (last && !event.shiftKey && (document.activeElement === last || !drawer.contains(document.activeElement))){ event.preventDefault(); first.focus(); }
    }
    if (event.key === "Escape"){
      closeItem();
      closeNav();
    }
  });

  menuBtn?.addEventListener("click",() => {
    setNavOpen(!document.body.classList.contains("nav-open"));
  });
  navOverlay.addEventListener("click",closeNav);

  window.addEventListener("resize",() => {
    if (window.innerWidth > 760){
      closeNav();
    }
  },{passive:true});

  runFrameworkAudit();
  renderNav();
  renderResults();
})();
