// Reviewed delegated preparation, not an instruction to grant tenant-wide admin roles.
const api=page=>'https://learn.microsoft.com/en-us/graph/api/'+page+'?view=graph-rest-1.0';
export const graphProfiles={};
function add(names,scopes,module,page,authority,note=''){
 for(const name of names)graphProfiles[name]={scopes:scopes.split(',').filter(Boolean),module:'Microsoft.Graph.'+module,documentation:api(page),authority,note};
}
const directory='Use an approved member account with directory-read access; tenant restrictions can require a supported reader/custom role.';
const authRead='Reading another user’s methods requires Global Reader, Authentication Administrator, or Privileged Authentication Administrator (or supported custom equivalent). Target-role restrictions apply; phone numbers may be masked.';
const authWrite='Authentication Administrator for supported nonprivileged targets; Privileged Authentication Administrator for privileged targets. Confirm the target-role restrictions before removal.';
const logs='Reports Reader or Security Reader (or another supported role). Tenant licensing, retention and log availability also apply; unavailable data is not a clean result.';
const groups='Use an authorized group owner/member or a supported directory-reader/custom role. Hidden memberships require separately approved Member.Read.Hidden access; do not add it by default. Non-user objects can return limited properties.';
add(['Find User By Exact Display Name','Get User By Upn','Show Password Last Changed And Age','Show Sync Source'],'User.Read.All','Users','user-get',directory);
add(['Show Manager'],'User.Read.All','Authentication','user-list-manager',directory);
add(['Show Assigned Licenses'],'LicenseAssignment.Read.All','Users','user-list-licensedetails','Directory Readers, License Administrator, or another supported role/custom equivalent.');
add(['Show All Authentication Methods For One User'],'UserAuthenticationMethod.Read.All','Identity.SignIns','authentication-list-methods',authRead);
add(['Show Microsoft Authenticator Methods'],'UserAuthMethod-MicrosoftAuthApp.Read.All','Identity.SignIns','microsoftauthenticatorauthenticationmethod-list',authRead);
add(['Show Phone Methods'],'UserAuthMethod-Phone.Read.All','Identity.SignIns','authentication-list-phonemethods',authRead);
add(['Show Registration Status For One User'],'AuditLog.Read.All','Reports','authenticationmethodsroot-list-userregistrationdetails',logs,'The registration report does not support disabled users.');
add(['Show Delegated Grants For One User','Show Potentially High-Impact Delegated Scopes'],'Directory.Read.All','Users','user-list-oauth2permissiongrants','Directory Readers or another supported reader/custom role.','Lists this user’s grants, not tenant-wide consent grants.');
add(['Find Exact Group'],'GroupMember.Read.All','Groups','group-list',directory);
add(['Show Entra Group Direct Members'],'GroupMember.Read.All,User.ReadBasic.All','Groups','group-list-members',groups,'GroupMember.Read.All is retained as a documented read-only permission; User.ReadBasic.All supplies user names and UPNs.');
add(['Show Entra Group Owners'],'GroupMember.Read.All,User.ReadBasic.All','Groups','group-list-owners',groups);
add(['Show Entra User Group Memberships'],'User.Read.All,GroupMember.Read.All','Users','user-list-memberof',groups,'Cloud-only lookup: the ActiveDirectory module is not required.');
add(['Show Risk Detections For One User'],'User.ReadBasic.All,IdentityRiskEvent.Read.All','Identity.SignIns + Microsoft.Graph.Users','riskdetection-list','Security Reader or another supported risk-reader/custom role. Identity Protection licensing and data availability apply.');
add(['Show Risky User State'],'IdentityRiskyUser.Read.All','Identity.SignIns','riskyuser-list','Security Reader or another supported risk-reader/custom role. Identity Protection licensing and data availability apply.');
add(['Show Failed Sign-Ins','Show Last 10 Entra Sign-Ins','Show Entra Sign-ins - Last 48 Hours','Show Legacy / Other-client Sign-ins','Show Successful Sign-Ins','Show Activity From One IP'],'AuditLog.Read.All','Reports','signin-list',logs);
add(['Delete Cloud User'],'User.ReadWrite.All','Users','user-delete','User Administrator or another supported role/custom equivalent; privileged target restrictions apply.','This preparation does not authorize privileged administrator deletion. That scenario additionally requires Directory.AccessAsUser.All and a higher supported operator role; do not add those rights by default.');
add(['Disable Sign-In','Enable Sign-In'],'User.EnableDisableAccount.All,User.Read.All','Users','user-update','User Administrator for supported targets; privileged target accounts require a higher supported role. Do not assume consent alone authorizes the target.');
add(['Revoke Active Sessions'],'User.RevokeSessions.All','Users.Actions','user-revokesigninsessions','Use a role permitted to revoke sessions for the target; privileged targets have additional role restrictions.');
add(['Remove Specific Authenticator Method'],'UserAuthenticationMethod.ReadWrite.All','Identity.SignIns','microsoftauthenticatorauthenticationmethod-delete',authWrite);
add(['Remove Specific Phone Method'],'UserAuthenticationMethod.ReadWrite.All','Identity.SignIns','phoneauthenticationmethod-delete',authWrite);
add(['Remove Specific Delegated Grant'],'DelegatedPermissionGrant.ReadWrite.All','Applications','oauth2permissiongrant-delete','Cloud Application Administrator, Application Administrator, or another supported role/custom equivalent.');
add(['Add User to Entra Group'],'User.ReadBasic.All,GroupMember.ReadWrite.All','Groups + Microsoft.Graph.Users','group-post-members','Authorized group owner or Groups Administrator (or supported custom equivalent).','Role-assignable groups additionally require RoleManagement.ReadWrite.Directory and Privileged Role Administrator; not requested by default. Dynamic membership cannot be managed as direct membership.');
add(['Remove User from Entra Group'],'User.ReadBasic.All,GroupMember.ReadWrite.All','Groups + Microsoft.Graph.Users','group-delete-members','Authorized group owner or Groups Administrator (or supported custom equivalent).','Role-assignable groups additionally require RoleManagement.ReadWrite.Directory and Privileged Role Administrator; not requested by default. Dynamic membership cannot be managed as direct membership.');
export const graphConsent='Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.';

// Explicit requested-scope declarations only: detection strings such as Mail.ReadWrite
// are findings, not requested permissions. Source hashes gate all other syntax changes.
export function requestedScopes(text,file){
 if(/^BEC-(RISK-ASSESSMENT|CONTAIN-ERADICATE|RECOVER-VALIDATE)\.ps1$/.test(file))text=text.match(/function Get-IRWorkflowScopes[\s\S]*?\n\}/)?.[0]||'';
 else {
  const arrays=[...text.matchAll(/(?:-(?:Required)?Scopes\s+|\$(?:required)?Scopes\s*=\s*|\bScopes\s*=\s*)@\(([\s\S]*?)\)/gi)].map(x=>x[1]);
  const optional=[...text.matchAll(/\$scopes\s*\+=\s*["']([^"']+)["']/gi)].map(x=>JSON.stringify(x[1]));
  text=[...arrays,...optional].join('\n');
 }
 return [...new Set([...text.matchAll(/["']([A-Za-z][\w.-]+\.[\w.-]+)["']/g)].map(x=>x[1]))];
}
