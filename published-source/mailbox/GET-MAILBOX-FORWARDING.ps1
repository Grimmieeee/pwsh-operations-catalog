#requires -Version 5.1

<#
.SYNOPSIS
Checks mailbox-level forwarding and inbox-rule forwarding for a single Microsoft 365 mailbox.

.REQUIREMENTS
ExchangeOnlineManagement module
Read-only
#>

$ErrorActionPreference = 'Stop'

function Pause-End {
    Write-Host ""
    Read-Host "Press ENTER to EXIT" | Out-Null
}

try {
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        throw "ExchangeOnlineManagement module is not installed."
    }

    $UPN = Read-Host "Enter UPN"

    if ([string]::IsNullOrWhiteSpace($UPN)) {
        throw "UPN is required."
    }

    Write-Host ""
    Write-Host "Connecting to Exchange Online..."
    Connect-ExchangeOnline -ShowBanner:$false

    $mailbox = Get-Mailbox -Identity $UPN

    Write-Host ""
    Write-Host "MAILBOX FORWARDING"
    Write-Host "------------------"

    $forwardingFound = $false

    if ($mailbox.ForwardingAddress) {
        $forwardingFound = $true

        $resolvedForwardingAddress = $mailbox.ForwardingAddress
        try {
            $recipient = Get-Recipient -Identity $mailbox.ForwardingAddress -ErrorAction Stop
            if ($recipient.PrimarySmtpAddress) {
                $resolvedForwardingAddress = $recipient.PrimarySmtpAddress.ToString()
            }
            elseif ($recipient.DisplayName) {
                $resolvedForwardingAddress = $recipient.DisplayName
            }
        }
        catch {}

        Write-Host "ForwardingAddress:          $resolvedForwardingAddress"
    }

    if ($mailbox.ForwardingSmtpAddress) {
        $forwardingFound = $true
        Write-Host "ForwardingSmtpAddress:      $($mailbox.ForwardingSmtpAddress)"
    }

    if ($forwardingFound) {
        Write-Host "DeliverToMailboxAndForward: $($mailbox.DeliverToMailboxAndForward)"
    }
    else {
        Write-Host "No mailbox-level forwarding configured."
    }

    Write-Host ""
    Write-Host "INBOX RULE FORWARDING"
    Write-Host "---------------------"

    $rules = Get-InboxRule -Mailbox $UPN -IncludeHidden |
        Where-Object {
            $_.ForwardTo -or
            $_.ForwardAsAttachmentTo -or
            $_.RedirectTo
        }

    if ($rules) {
        foreach ($rule in $rules) {
            Write-Host ""
            Write-Host "Rule:    $($rule.Name)"
            Write-Host "Enabled: $($rule.Enabled)"

            if ($rule.ForwardTo) {
                Write-Host "ForwardTo:"
                foreach ($target in $rule.ForwardTo) {
                    Write-Host "  - $target"
                }
            }

            if ($rule.ForwardAsAttachmentTo) {
                Write-Host "ForwardAsAttachmentTo:"
                foreach ($target in $rule.ForwardAsAttachmentTo) {
                    Write-Host "  - $target"
                }
            }

            if ($rule.RedirectTo) {
                Write-Host "RedirectTo:"
                foreach ($target in $rule.RedirectTo) {
                    Write-Host "  - $target"
                }
            }
        }
    }
    else {
        Write-Host "No forwarding inbox rules found."
    }
}
catch {
    Write-Host ""
    Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    try {
        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
    }
    catch {}

    Pause-End
}
