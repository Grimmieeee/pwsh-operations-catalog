# FIELD // KIT — Start Here

Prepare the client-side support computer, then run one tool for one goal.

## 1. Confirm where you are working

Connect to the customer's approved Windows support computer. Confirm the customer, computer and approved Windows account before continuing. Use the ticket to identify the operator and job; a shared Windows account alone does not identify the technician.

Download the current setup package from FIELD // KIT. If downloaded elsewhere, transfer it to that support computer using your approved remote file transfer. Extract it into an approved toolkit folder. Setup installs modules for the Windows account and PowerShell edition running it, so run it in the same context you will use for later jobs.

If Windows blocks a downloaded script, use the approved signing and execution-policy process. Do not disable a managed policy or unblock an entire Downloads folder to get past it.

## 2. Prepare this computer

Right-click `PREPARE-FIELD-KIT.ps1` and select **Run with PowerShell**. Choose Microsoft Graph, Exchange Online, or both. Setup checks first, shows missing prerequisites, and asks you to type INSTALL before making changes.

Compatible modules are kept. Missing selected modules are installed from the official PowerShell Gallery for the current Windows account. Setup may register the default repository and install its NuGet provider after approval; it does not change repository trust, execution policy, customer permissions or tenant configuration. It does not sign into a customer tenant or create an app registration.

Wait for **RESULT: READY**. NOT READY means a dependency, version, import or host check still needs attention. CANCELLED means the installation was not approved. Read the result before pressing Enter to close the setup session.

READY applies only to local prerequisites for the selected profile. It does not prove customer access, MFA, licenses, tenant permissions, or end-to-end job success. AD jobs also need local Active Directory tools, a domain connection and the appropriate access; use `-IncludeADTools` to check these dependencies. Setup does not install RSAT or join a domain.

Supported baseline: Windows PowerShell 5.1, or supported PowerShell 7.4 or later. Exchange on Windows PowerShell also requires .NET Framework 4.7.2 or later. Graph setup uses the compatible 2.x module family. Run setup again in each PowerShell edition/account you intend to use.

## 3. Choose one job

Choose the card that matches the goal. Confirm its brief purpose, scope, and READ ONLY / MAKES CHANGES label. Details explains the connection and sign-in requirements. Download the current `.ps1` from the card, transfer it to the approved support computer if needed, and right-click → Run with PowerShell.

Confirm the customer environment and target sign-in address inside the workflow. Sign in with the approved customer account when requested. Installing modules does not grant access. Browser or Windows single sign-on may select an account automatically; check the account and environment rather than assuming a fresh credential prompt means the right customer.

The BEC workflow is one sequential job: download its complete package, keep the three files together, and follow its launch instructions in one PowerShell window. Keep that window open through the approved handoffs. Tools with administrator or existing-terminal instructions retain those explicit exceptions.

## 4. Review, finish and close

Read the completed, failed, skipped and unresolved results. Record the outcome in the ticket. Press Enter to close the dedicated session when complete. Start a separate window for the next unrelated job; do not turn a finished workflow into a general-purpose admin terminal.

Closing a PowerShell process ends that process. It does not make the workflow a sandbox, revoke all tokens, remove the Windows account's rights, or guarantee another MFA prompt. Graph and Exchange connection/cache behavior differs between existing tools. If reusing an existing window, use **Reset M365 Session in that same window** before the next job. Opening the reset tool in a separate window cannot clean up the first window. Broker/browser sign-in may still persist; use your approved operator-session sign-out process when finished on the shared computer.
