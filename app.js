(() => {
  "use strict";

  const RAW = Array.isArray(window.CATALOG_DATA) ? window.CATALOG_DATA : [];

  const AREAS = [
    "Full Library",
    "Single User",
    "Multi User",
    "Tenant Wide",
    "Incident Response",
    "RMM",
    "Utility",
    "Standalone",
    "About"
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
      code:'Remove-MailboxFolderPermission -Identity "owner@domain.com:\\Calendar" -User "user@domain.com" -Confirm:$false',
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
      code:"net user username /delete",
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
      code:'netsh interface set interface "Wi-Fi" admin=disabled',
      keywords:"network adapter disable wifi isolate"
    },
    {
      name:"Restart Network Adapter",
      platform:"Local Windows",
      access:"Change",
      code:'Restart-NetAdapter -Name "Wi-Fi"',
      keywords:"network adapter restart nic"
    },
    {
      name:"Isolate Device - Disable Enabled Adapters",
      platform:"Local Windows",
      access:"Change",
      code:'Get-NetAdapter | Where-Object Status -eq "Up" | Disable-NetAdapter -Confirm:$false',
      keywords:"isolate device network adapters disable incident response"
    },
    {
      name:"Reboot Computer",
      platform:"Local Windows",
      access:"Change",
      code:"shutdown /r /t 0",
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
      code:"winget upgrade --all --silent --accept-source-agreements --accept-package-agreements --disable-interactivity",
      keywords:"winget update all packages software"
    },
    {
      name:"Show WinGet Package Information",
      platform:"WinGet",
      access:"Read-only",
      code:"winget show --id <Package.Id>",
      keywords:"winget package info version"
    },
    {
      name:"Update Specific WinGet Package",
      platform:"WinGet",
      access:"Change",
      code:"winget upgrade --id <Package.Id> --accept-source-agreements --accept-package-agreements",
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
    input:"",
    output:"",
    file:"",
    related:[],
    notes:"",
    url:"",
    _order:10000 + i
  }));

  const EXTRA_RMM = [
    {
      name:"M365 User Quick View",
      type:"Tool",
      area:"RMM",
      subarea:"Identity",
      platform:"Datto RMM + Microsoft 365",
      access:"Read-only",
      status:"Ready",
      source:"RMM",
      file:"M365-USER-QUICK-VIEW-v1.2-CHR.ps1",
      keywords:"rmm datto m365 user quick view identity mailbox mfa"
    },
    {
      name:"RMM Group Management",
      type:"Tool",
      area:"RMM",
      subarea:"Access",
      platform:"Datto RMM + Microsoft 365",
      access:"Change",
      status:"Ready",
      source:"RMM",
      file:"RMM-GROUP-MANAGEMENT-v0.5.ps1",
      keywords:"rmm datto access groups membership"
    },
    {
      name:"RMM User Group Review",
      type:"Tool",
      area:"RMM",
      subarea:"Access",
      platform:"Datto RMM + Microsoft 365",
      access:"Read-only",
      status:"Ready",
      source:"RMM",
      file:"RMM-USER-GROUP-REVIEW-v1.0.ps1",
      keywords:"rmm datto access groups membership review"
    },
    {
      name:"RMM User Onboarding Summary",
      type:"Automation",
      area:"RMM",
      subarea:"On / Offboarding",
      platform:"Datto RMM + Microsoft 365",
      access:"Read-only",
      status:"Ready",
      source:"RMM",
      file:"RMM-USER-ONBOARDING-SUMMARY-v1.1.ps1",
      keywords:"rmm datto onboarding user summary"
    },
    {
      name:"RMM User Offboarding Summary",
      type:"Automation",
      area:"RMM",
      subarea:"On / Offboarding",
      platform:"Datto RMM + Microsoft 365",
      access:"Read-only",
      status:"Ready",
      source:"RMM",
      file:"RMM-USER-OFFBOARDING-SUMMARY-v1.0.ps1",
      keywords:"rmm datto offboarding user summary"
    },
    {
      name:"RMM BEC Risk Exposure Snapshot",
      type:"Tool",
      area:"RMM",
      subarea:"Security",
      platform:"Datto RMM + Microsoft 365",
      access:"Read-only",
      status:"Ready",
      source:"RMM",
      file:"BEC-IR-M365-RISK-EXPOSURE-SNAPSHOT-v0.32-CHR.ps1",
      keywords:"rmm datto bec risk exposure security"
    },
    {
      name:"RMM BEC Revoke Active Sessions",
      type:"Tool",
      area:"RMM",
      subarea:"Security",
      platform:"Datto RMM + Microsoft 365",
      access:"Change",
      status:"Ready",
      source:"RMM",
      file:"BEC-IR-REVOKE-ACTIVE-SESSIONS-v2.0-CHR.ps1",
      keywords:"rmm datto bec active sessions security"
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

  const rawItems = RAW.filter(item =>
    item &&
    item.status !== "Candidate" &&
    item.status !== "External Reference" &&
    item.type !== "Runbook" &&
    item.type !== "Reference" &&
    !isRmm(item)
  );

  const allSource = [...rawItems, ...EXTRA_RMM, ...EXTRA_STANDALONE];

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
    if (/user profile backup/i.test(item.name || "")) return "Identity";
    if (isRmm(item)) return "RMM";
    if (item.type === "Quick Command" || item.area === "Standalone") return "Standalone";
    if (/security\s*\/\s*ir|incident/i.test(item.area || "")) return "Incident Response";
    if (/mailbox/i.test(item.area || "")) return "Mailbox";
    if (/identity|groups|reporting\s*\/\s*audit/i.test(item.area || "")) return "Identity";
    if (/utilities|endpoint|network/i.test(item.area || "")) return "Utility";
    return "Utility";
  }

  function displayName(item){
    let name = String(item.name || item.file || "Untitled").trim();
    name = name.replace(/^1[-_ ]+/i,"").replace(/^2[-_ ]+/i,"");
    name = name.replace(/-CHR\b/ig,"").replace(/\s{2,}/g," ").trim();

    if (/^Show Password Last Changed And Age$/i.test(name)) return "Show Password Age";
    if (/^Show All Authentication Methods For One User$/i.test(name)) return "Show MFA Methods";
    if (/^BEC \/ Account Compromise Discovery$/i.test(name)) return "BEC Risk Exposure Snapshot";
    if (/^BEC \/ Account Compromise Execution$/i.test(name)) return "BEC Eradicate";
    if (/^Show Inbox Rules$/i.test(name) && /IncludeHidden/i.test(item.code || "")) return "Show Inbox Rules - Hidden";
    if (/Mailitemsaccessed/i.test(name)) return name.replace(/Mailitemsaccessed/ig,"Mail Items Accessed");

    return name;
  }

  function groupFor(item, area){
    const name = displayName(item);
    const file = item.file || "";
    const combined = [name,file,item.subarea,item.platform,item.code].join(" ");

    if (area === "Standalone"){
      if (/winget/i.test(combined)) return "WinGet";
      if (/PowerShell|execution policy|code-signing|terminal/i.test(combined) &&
          !/Microsoft Graph|Exchange Online/i.test(item.platform || "")) return "Terminal";
      if (/Exchange Online/i.test(item.platform || "")) return "Exchange";
      if (/Microsoft Graph/i.test(item.platform || "")) return "Graph";
      if (/Active Directory/i.test(item.platform || "")) return "Active Directory";
      if (/network|dns|tcp|ping|tracert|route|wifi|wlan|netadapter|winsock|ipconfig|firewall/i.test(combined)) return "Network";
      return "Windows";
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
      if (/risk exposure|account compromise|bec|revoke active sessions/i.test(name)) return "Primary";
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
      facts:["Mailbox state","Inbox rules","Forwarding","Full Access","Send As"]
    },
    {
      match:/GET-MAILBOX-PERMISSIONS|Mailbox Permissions Review|Mailbox Forwarding and Permission Audit/i,
      connect:['Connect-ExchangeOnline'],
      label:"CHECKS",
      facts:["Forwarding","Mailbox delegates","Inbox rules","Full Access","Send As"]
    },
    {
      match:/GET-WINGET-UPDATES|Winget Updates/i,
      label:"DOES",
      facts:["Shows available upgrades","Confirms before changes","Updates normally eligible packages","Shows remaining upgrades"]
    },
    {
      match:/GET-TERMINAL-READINESS-CHECK|Terminal Readiness Check/i,
      label:"CHECKS",
      facts:["PowerShell version","Execution policy","Jumpbox folders","Code-signing certificate","Script signatures","Cloud modules","Graph / Exchange sessions","Core files"]
    },
    {
      match:/INVOKE-SESSION-RESET|Session Reset/i,
      label:"DOES",
      facts:["Disconnects Exchange Online","Disconnects Microsoft Graph","Removes Exchange-related PSSessions","Clears PowerShell error buffer","Optionally resets session password","Optionally launches PowerShell 7"]
    }
  ];

  function curatedMeta(item){
    const key = [displayName(item),item.file,item.name].join(" ");
    return CURATED.find(entry => entry.match.test(key)) || null;
  }

  function connectCommands(item){
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
    const curated = curatedMeta(item);
    if (curated?.facts?.length){
      return {label:curated.label || "CHECKS",items:[...curated.facts]};
    }

    const title = displayName(item);
    if (/M365 Risk Exposure Snapshot|BEC Risk Exposure Snapshot|Identity Exposure Snapshot/i.test(title)){
      return {label:"CHECKS",items:[...RISK_CHECKS]};
    }

    if (/M365 User Quick View/i.test(title)){
      return {label:"CHECKS",items:["Account state","Password age","MFA","Groups","Mailbox state"]};
    }

    return null;
  }

  function workflowFor(item, area){
    if (area !== "Incident Response") return null;

    const title = displayName(item);
    if (!/BEC|Account Compromise|Risk Exposure|Eradicate|Recover|Revoke Active Sessions/i.test(title)) return null;

    const steps = [
      {n:"1",name:"Risk Exposure Snapshot"},
      {n:"2",name:"Eradicate"},
      {n:"3",name:"Recover"},
      {n:"",name:"Revoke Active Sessions",standalone:true}
    ];

    let current = "";
    if (/Risk Exposure|Discovery/i.test(title)) current = "1";
    else if (/Eradicate|Execution/i.test(title)) current = "2";
    else if (/Recover/i.test(title)) current = "3";
    else if (/Revoke Active Sessions/i.test(title)) current = "standalone";

    return {
      note:"RUN IN ORDER — Complete each numbered step before moving to the next. Items marked STANDALONE may be run independently.",
      current,
      steps
    };
  }

  function changeNote(item){
    const access = String(item.access || "");
    if (!/change|destructive|mixed/i.test(access)) return "";

    const title = displayName(item);
    if (/Add Calendar Permission/i.test(title)) return "Changes calendar folder permissions.";
    if (/Remove Calendar Permission/i.test(title)) return "Removes calendar folder permissions.";
    if (/Revoke Active Sessions/i.test(title)) return "Revokes active Microsoft 365 sessions.";
    if (/Disable Sign-In/i.test(title)) return "Disables user sign-in.";
    if (/Enable Sign-In|Re-Enable/i.test(title)) return "Enables user sign-in.";
    if (/Reset Password/i.test(title)) return "Resets the user password.";
    if (/Delete/i.test(title)) return "Deletes or removes the selected object.";
    if (/Remove/i.test(title)) return "Removes the selected access or configuration.";
    if (/Add/i.test(title)) return "Adds or changes access.";
    if (/Update|Upgrade/i.test(title)) return "Installs or applies updates.";
    return "Makes changes.";
  }

  function buildItem(source){
    const area = logicalArea(source);
    return {
      ...source,
      logicalArea:area,
      group:groupFor(source, area),
      displayName:displayName(source),
      connect:connectCommands(source),
      facts:factBlockFor(source),
      workflow:workflowFor(source, area),
      changeNote:changeNote(source)
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
    const item = buildItem(source);
    const key = norm(item.logicalArea + " " + item.displayName);
    const existing = byKey.get(key);
    if (!existing || scoreQuality(item) > scoreQuality(existing)) byKey.set(key,item);
  }

  const ITEMS = [...byKey.values()];

  const state = {
    area:"Full Library",
    query:"",
    selected:null
  };

  const areaNav = document.getElementById("areaNav");
  const crumb = document.getElementById("crumb");
  const entryCount = document.getElementById("entryCount");
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

  function countArea(area){
    if (area === "Full Library") return ITEMS.length;
    if (area === "About") return "";
    return ITEMS.filter(x => primaryBucket(x) === area).length;
  }

  function renderNav(){
    areaNav.innerHTML = AREAS.map(area => `
      <button class="area-button ${area === "About" ? "about-nav" : ""} ${state.area === area ? "active" : ""}" data-area="${esc(area)}" type="button">
        <span>${esc(area)}</span>
        <span class="area-count">${countArea(area)}</span>
      </button>
    `).join("");
  }

  function searchScore(item, query){
    if (!query) return 1;
    const q = words(query);
    if (!q.length) return 1;

    const strong = words([
      item.displayName,
      item.file,
      item.group,
      item.logicalArea,
      item.keywords
    ].join(" "));

    const weak = words([
      item.platform,
      item.notes,
      item.output,
      item.subarea
    ].join(" "));

    let score = 0;
    for (const token of q){
      if (strong.some(w => w === token)) score += 7;
      else if (strong.some(w => w.startsWith(token))) score += 5;
      else if (weak.some(w => w === token)) score += 3;
      else if (weak.some(w => w.startsWith(token))) score += 1;
    }

    return score;
  }

  function scopeSubgroup(item){
    const area = String(item.area || "");
    const text = [item.displayName,item.name,item.file,item.subarea].join(" ");

    if (/onboard|offboard|pre[- ]?delete|disable(?:\s+user)?\s+accounts|delete(?:\s+user)?\s+accounts/i.test(text)) return "On / Offboarding";
    if (/shared mailbox sign-in|\bIR[-_ ]|incident response|mfa|conditional access|oauth|secure score|sign[- ]?in anomalies|device code|service principal|app registration|guest app consent|guest consent|security hardening/i.test(text)) return "Security";
    if (/mailbox|inbox|forward|transport rule|send as|full access|calendar|contacts|litigation hold/i.test(text)) return "Mailbox";
    if (/reporting\s*\/\s*audit/i.test(area) || /audit|review|report|stale|cleanup|tenant snapshot/i.test(text)) return "Audit";
    if (/license|group|membership|owner|role|permission/i.test(text) && !/conditional access/i.test(text)) return "Access";
    return "Identity";
  }

  const SCOPE_OVERRIDES = [
    {scope:"Tenant Wide", match:/Quarterly Account Cleanup|Inactive User Review|Disabled User Group Debt|Disabled User Mailbox Debt|Distribution Group Inventory|Teams and M365 Group Owners|Transport Rules Audit|Shared Mailbox Sign-in Audit/i},
    {scope:"Multi User", match:/Create Dynamic License Group|Distribution Group Members|^Group Members$/i}
  ];

  function primaryBucket(item){
    if (item.type === "Quick Command" || item.logicalArea === "Standalone") return "Standalone";
    if (item.logicalArea === "Incident Response") return "Incident Response";
    if (item.logicalArea === "RMM") return "RMM";
    if (item.logicalArea === "Utility") return "Utility";

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
    const order = ["Single User","Multi User","Tenant Wide","Incident Response","RMM","Utility","Standalone"];
    const idx = order.indexOf(bucket);
    return idx === -1 ? 99 : idx;
  }

  function bucketId(bucket){
    return "section-" + norm(bucket).replace(/\s+/g,"-");
  }

  function irRank(item){
    const name = displayName(item);
    if (/Risk Exposure Snapshot|Discovery/i.test(name)) return 1;
    if (/Eradicate|Execution/i.test(name)) return 2;
    if (/Recover/i.test(name)) return 3;
    if (/Revoke Active Sessions/i.test(name)) return 4;
    return 50;
  }

  function filteredItems(){
    let list = ITEMS.filter(item => state.area === "Full Library" || primaryBucket(item) === state.area);
    const q = state.query.trim();

    if (q){
      list = list
        .map(item => ({item,score:searchScore(item,q)}))
        .filter(x => x.score > 0)
        .sort((a,b) => b.score - a.score || a.item.displayName.localeCompare(b.item.displayName))
        .map(x => x.item);
    } else if (state.area === "Full Library") {
      list.sort((a,b) =>
        bucketRank(primaryBucket(a)) - bucketRank(primaryBucket(b)) ||
        a.displayName.localeCompare(b.displayName)
      );
    } else if (["Single User","Multi User","Tenant Wide"].includes(state.area)) {
      const order = ["Access","Audit","Identity","On / Offboarding","Mailbox","Security"];
      list.sort((a,b) =>
        order.indexOf(scopeSubgroup(a)) - order.indexOf(scopeSubgroup(b)) ||
        a.displayName.localeCompare(b.displayName)
      );
    } else if (state.area === "Incident Response") {
      list.sort((a,b) =>
        groupRank(a.logicalArea,a.group) - groupRank(b.logicalArea,b.group) ||
        irRank(a) - irRank(b) ||
        a.displayName.localeCompare(b.displayName)
      );
    } else {
      list.sort((a,b) =>
        groupRank(a.logicalArea,a.group) - groupRank(b.logicalArea,b.group) ||
        a.displayName.localeCompare(b.displayName)
      );
    }

    return list;
  }

  function areaRank(area){
    const order = ["Identity","Mailbox","Incident Response","RMM","Utility","Standalone"];
    const idx = order.indexOf(area);
    return idx === -1 ? 99 : idx;
  }

  function groupRank(area, group){
    const orders = {
      "Identity":["Single User","Multi User","Tenant","General"],
      "Mailbox":["Single User","Multi User","General"],
      "Incident Response":["Primary","Investigation","Response","General"],
      "RMM":["Access","Audit","Identity","On / Offboarding","Mailbox","Security"],
      "Utility":["WinGet","Terminal / Field-Kit","General"],
      "Standalone":["Exchange","Graph","Active Directory","Windows","Network","WinGet","Terminal"]
    };
    const list = orders[area] || [];
    const idx = list.indexOf(group);
    return idx === -1 ? 99 : idx;
  }

  function accessTag(item){
    const access = String(item.access || "").toLowerCase();
    if (access.includes("destructive")) return '<span class="result-tag result-danger">DESTRUCTIVE</span>';
    if (access.includes("change") || access.includes("mixed")) return '<span class="result-tag result-change">CHANGE</span>';
    return "";
  }

  function rowTags(item){
    return accessTag(item);
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
    const meta = item.type === "Quick Command"
      ? (item.group || "")
      : (item.file || item.group || "");
    return `
      <button class="result" type="button" data-open-index="${index}">
        <span class="result-name">${esc(item.displayName)}</span>
        <span class="result-meta">${esc(meta)}</span>
        <span class="result-flags">${rowTags(item)}</span>
        <span class="result-arrow">›</span>
      </button>
    `;
  }

  function renderResults(){
    const queryActive = Boolean(state.query.trim());
    searchWrap?.classList.toggle("hidden", state.area === "About");

    if (state.area === "About"){
      crumb.textContent = "ABOUT";
      entryCount.textContent = "";
      clearSearch.classList.toggle("hidden", !state.query);
      contextBar.textContent = "FIELD // KIT";
      jumpBar.innerHTML = "";
      jumpBar.classList.add("hidden");
      empty.classList.add("hidden");
      results.innerHTML = `
        <section class="about-block">
          <div class="about-kicker">ABOUT</div>
          <h2>FIELD // KIT</h2>
          <p>A searchable working catalog of PowerShell scripts, commands, and operational workflows.</p>
          <p>Start with scope: <strong>Single User</strong>, <strong>Multi User</strong>, or <strong>Tenant Wide</strong>. Then narrow by purpose: <strong>Access</strong>, <strong>Audit</strong>, <strong>Identity</strong>, <strong>On / Offboarding</strong>, <strong>Mailbox</strong>, or <strong>Security</strong>.</p>
          <p>Items are sorted A–Z within each section. Incident Response workflows stay in required execution order.</p>
          <div class="about-key">
            <span class="access-read">READ ONLY</span><span>reviews information</span>
            <span class="access-change">MAKES CHANGES</span><span>modifies configuration or access</span>
            <span class="access-danger">DESTRUCTIVE</span><span>can remove data, access, or objects</span>
          </div>
          <p>Review the selected item before execution.</p>

        </section>
      `;
      return;
    }

    const list = filteredItems();

    crumb.textContent = state.area.toUpperCase();
    entryCount.textContent = `${list.length} ${list.length === 1 ? "ITEM" : "ITEMS"}`;
    clearSearch.classList.toggle("hidden", !state.query);
    contextBar.classList.toggle("hidden", state.area === "Full Library" && !queryActive);
    contextBar.textContent = queryActive
      ? `SEARCH / ${state.area.toUpperCase()}`
      : state.area.toUpperCase();

    if (!queryActive && state.area === "Full Library"){
      const buckets = [...new Set(list.map(primaryBucket))];
      jumpBar.innerHTML = '<span class="jump-label">JUMP TO</span>' + buckets.map(bucket =>
        `<button class="jump-link" type="button" data-jump="${esc(bucketId(bucket))}">${esc(bucket.toUpperCase())}</button>`
      ).join("");
      jumpBar.classList.remove("hidden");
    } else if (!queryActive && ["Single User","Multi User","Tenant Wide"].includes(state.area)){
      const sections = [...new Set(list.map(scopeSubgroup))];
      jumpBar.innerHTML = '<span class="jump-label">JUMP TO</span>' + sections.map(section =>
        `<button class="jump-link" type="button" data-jump="${esc(bucketId(section))}">${esc(section.toUpperCase())}</button>`
      ).join("");
      jumpBar.classList.remove("hidden");
    } else {
      jumpBar.innerHTML = "";
      jumpBar.classList.add("hidden");
    }

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
        <section class="group" id="${(state.area === "Full Library" || ["Single User","Multi User","Tenant Wide"].includes(state.area)) ? esc(bucketId(group)) : ""}">
          <div class="group-title">${groupTitleMarkup(group)}</div>
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
      <section class="connect-block">
        <div class="section-label">CONNECT</div>
        ${item.connect.map(cmd => `
          <div class="connect-line">
            <code>${esc(cmd)}</code>
            <button class="copy-mini" type="button" data-copy="${esc(cmd)}">COPY</button>
          </div>
        `).join("")}
      </section>
    `;
  }

  function workflowMarkup(workflow){
    if (!workflow) return "";
    return `
      <section class="workflow-block">
        <div class="workflow-note">${esc(workflow.note)}</div>
        <div class="sequence">
          ${workflow.steps.map(step => {
            const isCurrent = workflow.current === step.n || (step.standalone && workflow.current === "standalone");
            return `
              <div class="sequence-row ${isCurrent ? "sequence-current" : ""}">
                <span class="sequence-number">${esc(step.n)}</span>
                <span>${esc(step.name)}</span>
                <span class="sequence-standalone">${step.standalone ? "STANDALONE" : ""}</span>
              </div>
            `;
          }).join("")}
        </div>
      </section>
    `;
  }

  function factsMarkup(item){
    if (!item.facts?.items?.length) return "";
    const label = item.facts.label || "CHECKS";
    const doesClass = label === "DOES" ? " does-list" : "";
    return `
      <section class="check-block">
        <div class="section-label">${esc(label)}</div>
        <div class="check-list${doesClass}">
          ${item.facts.items.map(x => `<div class="check-item">${esc(x)}</div>`).join("")}
        </div>
      </section>
    `;
  }

  function accessMarkup(item){
    const access = String(item.access || "").toLowerCase();
    if (access.includes("destructive")) {
      return '<div class="access-state access-danger">DESTRUCTIVE</div>';
    }
    if (access.includes("change") || access.includes("mixed")) {
      return '<div class="access-state access-change">MAKES CHANGES</div>';
    }
    return '<div class="access-state access-read">READ ONLY</div>';
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

  function shortNote(item){
    if (item.type === "Quick Command" || item.facts?.items?.length) return "";
    const note = String(item.notes || "").trim();
    if (!note) return "";
    return `<div class="note-block">${esc(note)}</div>`;
  }

  function sourceButton(item){
    if (item.type === "Quick Command") return "";
    if (!item.file && !item.code && !item.publishedPath) return "";
    return '<button id="showSource" class="action primary" type="button">POWERSHELL</button>';
  }

  function referenceButtons(item){
    const name = String(item.name || "");
    const file = String(item.file || "");
    const type = String(item.type || "");
    const buttons = [];

    if (/runbook/i.test(type + " " + name + " " + file) && item.url){
      buttons.push(`<a class="action" href="${esc(item.url)}" target="_blank" rel="noopener noreferrer">RUNBOOK</a>`);
    }
    if (/readme/i.test(file) && item.url){
      buttons.push(`<a class="action" href="${esc(item.url)}" target="_blank" rel="noopener noreferrer">README</a>`);
    }
    return buttons.join("");
  }

  function standaloneCommandMarkup(item){
    if (item.type !== "Quick Command" || !item.code) return "";
    return `
      <section class="command-block">
        <div class="section-label">COMMAND</div>
        <pre class="command">${esc(item.code)}</pre>
        <div class="source-actions">
          <button class="action primary" type="button" data-copy-source>COPY COMMAND</button>
        </div>
      </section>
    `;
  }

  function openItem(item){
    state.selected = item;

    drawerBody.innerHTML = `
      <section class="item-head">
        <div class="item-context">${esc(primaryBucket(item))} / ${esc(["Single User","Multi User","Tenant Wide"].includes(primaryBucket(item)) ? scopeSubgroup(item) : item.group)}</div>
        <h2 class="item-title">${itemTitleMarkup(item.displayName)}</h2>
        ${accessMarkup(item)}
      </section>

      ${connectMarkup(item)}
      ${item.changeNote ? `<div class="change-note ${/destructive/i.test(item.access || "") ? "danger" : ""}">${esc(item.changeNote)}</div>` : ""}
      ${optionMarkup(item)}
      ${workflowMarkup(item.workflow)}
      ${factsMarkup(item)}
      ${shortNote(item)}
      ${standaloneCommandMarkup(item)}

      <div class="actions">
        ${sourceButton(item)}
        ${referenceButtons(item)}
      </div>

      <div id="sourceMount"></div>
    `;

    bindDrawerActions(item);
    document.body.classList.add("drawer-open");
    drawer.setAttribute("aria-hidden","false");
  }

  function bindDrawerActions(item){
    drawerBody.querySelectorAll("[data-copy]").forEach(btn => {
      btn.addEventListener("click", async () => {
        await copyText(btn.getAttribute("data-copy") || "");
        flashButton(btn,"COPIED");
      });
    });

    const copySource = drawerBody.querySelector("[data-copy-source]");
    if (copySource){
      copySource.addEventListener("click", async () => {
        await copyText(item.code || "");
        flashButton(copySource,"COPIED");
      });
    }

    const showSource = document.getElementById("showSource");
    if (showSource){
      showSource.addEventListener("click", () => toggleSource(item,showSource));
    }
  }

  async function resolveSource(item){
    if (item.publishedPath){
      const response = await fetch(item.publishedPath,{cache:"no-store"});
      if (!response.ok) throw new Error("Source could not be loaded.");
      return await response.text();
    }
    if (item.code) return item.code;
    return "";
  }

  async function toggleSource(item, button){
    const mount = document.getElementById("sourceMount");
    if (!mount) return;

    if (mount.dataset.open === "1"){
      mount.innerHTML = "";
      mount.dataset.open = "0";
      button.textContent = "POWERSHELL";
      return;
    }

    button.disabled = true;
    button.textContent = "LOADING";

    try{
      const source = await resolveSource(item);
      if (!source){
        mount.innerHTML = `
          <section class="source-block">
            <div class="section-label">POWERSHELL</div>
            <div class="source-note">
              The source file is not published in this preview yet. The UI is wired for same-origin source loading once an approved copy is added to the public catalog.
            </div>
          </section>
        `;
      } else {
        mount.innerHTML = `
          <section class="source-block">
            <div class="section-label">POWERSHELL</div>
            <pre class="command">${esc(source)}</pre>
            <div class="source-actions">
              <button id="copyScript" class="action primary" type="button">COPY SCRIPT</button>
              ${item.file && /\.ps1$/i.test(item.file) ? '<button id="saveScript" class="action" type="button">SAVE .PS1</button>' : ""}
            </div>
          </section>
        `;

        document.getElementById("copyScript")?.addEventListener("click", async e => {
          await copyText(source);
          flashButton(e.currentTarget,"COPIED");
        });

        document.getElementById("saveScript")?.addEventListener("click", () => {
          saveText(source, safeFilename(item.file || item.displayName + ".ps1"));
        });
      }

      mount.dataset.open = "1";
      button.textContent = "HIDE POWERSHELL";
    } catch (error){
      mount.innerHTML = `
        <section class="source-block">
          <div class="source-note">${esc(error.message || "Source could not be loaded.")}</div>
        </section>
      `;
      mount.dataset.open = "1";
      button.textContent = "POWERSHELL";
    } finally {
      button.disabled = false;
    }
  }

  function safeFilename(value){
    const base = String(value).split(/[\\/]/).pop() || "script.ps1";
    return base.replace(/[^a-z0-9._-]/gi,"-");
  }

  function saveText(source, filename){
    const blob = new Blob([source],{type:"text/plain;charset=utf-8"});
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  }

  async function copyText(text){
    if (navigator.clipboard?.writeText){
      await navigator.clipboard.writeText(text);
      return;
    }
    const ta = document.createElement("textarea");
    ta.value = text;
    ta.style.position = "fixed";
    ta.style.opacity = "0";
    document.body.appendChild(ta);
    ta.select();
    document.execCommand("copy");
    ta.remove();
  }

  function flashButton(button,label){
    const old = button.textContent;
    button.textContent = label;
    window.setTimeout(() => { button.textContent = old; },900);
  }

  function closeItem(){
    document.body.classList.remove("drawer-open");
    drawer.setAttribute("aria-hidden","true");
    state.selected = null;
  }

  function closeNav(){
    document.body.classList.remove("nav-open");
  }

  areaNav.addEventListener("click", event => {
    const btn = event.target.closest("[data-area]");
    if (!btn) return;
    state.area = btn.getAttribute("data-area") || "Full Library";
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
    if (event.key === "Escape"){
      closeItem();
      closeNav();
    }
  });

  menuBtn?.addEventListener("click",() => document.body.classList.toggle("nav-open"));
  navOverlay.addEventListener("click",closeNav);

  renderNav();
  renderResults();
})();
