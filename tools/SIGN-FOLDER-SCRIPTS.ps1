<#
.VERSION 1.0.1
#>
<#
sign-folder-scripts.ps1

Signs all .ps1 files under a selected folder.

Purpose:
- Recursively sign jumpbox scripts after edits
- Works across subfolders
- Prompts for root folder
- Uses an existing code-signing certificate or creates a local self-signed one
- Optionally trusts the self-signed certificate for the current user
- No exports
- No hardcoded paths

Important:
- Editing a signed script breaks the signature.
- Re-run this after script changes.
- A self-signed cert is trusted only where it is trusted/imported.
#>

param(
    [string]$RootPath,
    [string]$Thumbprint,
    [switch]$ForceResign
)

$ErrorActionPreference = "SilentlyContinue"

function OK($m)   { Write-Host "[OK]   $m" -ForegroundColor Green }
function INFO($m) { Write-Host "[INFO] $m" }
function WARN($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }
function FAIL($m) { Write-Host "[FAIL] $m" -ForegroundColor Red }

function Pause-End {
    Write-Host ''
    Write-Host 'SESSION COMPLETE'
    Write-Host ""
    Read-Host 'Press Enter to close session.' | Out-Null
}

function Section {
    param([string]$Title)

    Write-Host ""
    Write-Host "--------------------------------------" -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host "--------------------------------------" -ForegroundColor Cyan
}

function Confirm-Yes {
    param([string]$Prompt)

    $a = Read-Host "$Prompt [Y/N]"
    return ($a.Trim().ToUpper() -eq "Y")
}

function Get-CodeSigningCerts {
    return @(Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert -ErrorAction SilentlyContinue | Sort-Object NotAfter -Descending)
}

function Select-CodeSigningCert {
    param([string]$Thumbprint)

    if ($Thumbprint) {
        $cleanThumb = $Thumbprint.Replace(" ", "").ToUpper()
        $cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert -ErrorAction SilentlyContinue |
            Where-Object { $_.Thumbprint.ToUpper() -eq $cleanThumb } |
            Select-Object -First 1

        if ($cert) {
            return $cert
        }

        WARN "Certificate thumbprint not found in CurrentUser\My"
    }

    $certs = @(Get-CodeSigningCerts)

    if ($certs.Count -eq 0) {
        return $null
    }

    Write-Host ""
    Write-Host "Available code-signing certificates:"
    Write-Host ""

    for ($i = 0; $i -lt $certs.Count; $i++) {
        $c = $certs[$i]
        Write-Host ("[{0}] {1}" -f ($i + 1), $c.Subject)
        Write-Host "    Thumbprint: $($c.Thumbprint)"
        Write-Host "    Expires   : $($c.NotAfter)"
        Write-Host ""
    }

    $choice = Read-Host "Choose certificate number"

    try {
        $index = [int]$choice - 1

        if ($index -ge 0 -and $index -lt $certs.Count) {
            return $certs[$index]
        }
    } catch {}

    return $null
}

function New-LocalCodeSigningCert {
    $subject = Read-Host "Certificate name [default: Local Script Signing]"

    if (-not $subject) {
        $subject = "Local Script Signing"
    }

    if ($subject -notlike "CN=*") {
        $subject = "CN=$subject"
    }

    try {
        $cert = New-SelfSignedCertificate `
            -Type CodeSigningCert `
            -Subject $subject `
            -CertStoreLocation "Cert:\CurrentUser\My" `
            -KeyAlgorithm RSA `
            -KeyLength 2048 `
            -HashAlgorithm SHA256 `
            -KeyUsage DigitalSignature `
            -NotAfter (Get-Date).AddYears(5) `
            -ErrorAction Stop

        OK "Created local code-signing certificate"
        Write-Host "Thumbprint: $($cert.Thumbprint)"

        return $cert
    } catch {
        FAIL "Failed to create code-signing certificate"
        Write-Host $_.Exception.Message
        return $null
    }
}

function Trust-CertForCurrentUser {
    param([System.Security.Cryptography.X509Certificates.X509Certificate2]$Cert)

    if (-not $Cert) {
        return
    }

    try {
        $publisherStore = New-Object System.Security.Cryptography.X509Certificates.X509Store("TrustedPublisher", "CurrentUser")
        $publisherStore.Open("ReadWrite")
        $publisherStore.Add($Cert)
        $publisherStore.Close()

        $rootStore = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "CurrentUser")
        $rootStore.Open("ReadWrite")
        $rootStore.Add($Cert)
        $rootStore.Close()

        OK "Trusted certificate for current user"
    } catch {
        WARN "Could not trust certificate automatically"
        Write-Host $_.Exception.Message
    }
}

try {
    try {
        $host.UI.RawUI.WindowTitle = "Sign Folder Scripts"
    } catch {}

    Clear-Host
    Write-Host 'Sign Scripts'
    Write-Host 'Sign reviewed PowerShell scripts with a certificate you choose.'
    Write-Host ""

    if (-not $RootPath) {
        $RootPath = (Read-Host "Root folder to sign").Trim().Trim('"')
    }

    if (-not $RootPath) {
        FAIL "Root folder required"
        Pause-End
        exit 1
    }

    if (-not (Test-Path $RootPath)) {
        FAIL "Root folder not found: $RootPath"
        Pause-End
        exit 1
    }

    Section "CERTIFICATE"

    $cert = Select-CodeSigningCert -Thumbprint $Thumbprint

    if (-not $cert) {
        WARN "No code-signing certificate selected or found"
        Write-Host ""
        Write-Host "[1] Create local self-signed code-signing cert"
        Write-Host "[2] Enter thumbprint again"
        Write-Host "[3] Cancel"
        Write-Host ""
        $choice = Read-Host "Choose"

        if ($choice -eq "1") {
            $cert = New-LocalCodeSigningCert

            if ($cert -and (Confirm-Yes "Trust this certificate for the current user")) {
                Trust-CertForCurrentUser -Cert $cert
            }
        }
        elseif ($choice -eq "2") {
            $Thumbprint = Read-Host "Thumbprint"
            $cert = Select-CodeSigningCert -Thumbprint $Thumbprint
        }
        else {
            WARN "Cancelled"
            Pause-End
            exit 0
        }
    }

    if (-not $cert) {
        FAIL "No certificate available"
        Pause-End
        exit 1
    }

    OK "Using certificate: $($cert.Subject)"
    Write-Host "Thumbprint: $($cert.Thumbprint)"

    Section "SCAN"

    $scripts = @(Get-ChildItem -Path $RootPath -Filter "*.ps1" -Recurse -File -ErrorAction SilentlyContinue | Sort-Object FullName)

    if ($scripts.Count -eq 0) {
        WARN "No .ps1 files found"
        Pause-End
        exit 0
    }

    Write-Host "Root folder : $RootPath"
    Write-Host "Scripts     : $($scripts.Count)"
    Write-Host "Force resign: $ForceResign"
    Write-Host ""

    foreach ($s in $scripts) {
        Write-Host "- $($s.FullName)"
    }

    Write-Host ""
    if (-not (Confirm-Yes "Sign these scripts now")) {
        WARN "No files signed"
        Pause-End
        exit 0
    }

    Section "SIGNING"

    $signed = 0
    $skipped = 0
    $failed = 0

    foreach ($s in $scripts) {
        try {
            Unblock-File -Path $s.FullName -ErrorAction SilentlyContinue

            $sig = Get-AuthenticodeSignature -FilePath $s.FullName -ErrorAction SilentlyContinue

            if (-not $ForceResign -and $sig.Status -eq "Valid" -and $sig.SignerCertificate -and $sig.SignerCertificate.Thumbprint -eq $cert.Thumbprint) {
                $skipped++
                OK "Already signed: $($s.Name)"
                continue
            }

            $result = Set-AuthenticodeSignature `
                -FilePath $s.FullName `
                -Certificate $cert `
                -HashAlgorithm SHA256 `
                -ErrorAction Stop

            if ($result.Status -eq "Valid") {
                $signed++
                OK "Signed: $($s.Name)"
            }
            else {
                $failed++
                WARN "Signed but status is $($result.Status): $($s.Name)"
            }
        } catch {
            $failed++
            FAIL "Failed: $($s.Name)"
            Write-Host "       $($_.Exception.Message)"
        }
    }

    Section "SUMMARY"

    Write-Host "Root folder : $RootPath"
    Write-Host "Certificate : $($cert.Subject)"
    Write-Host "Thumbprint  : $($cert.Thumbprint)"
    Write-Host ""
    Write-Host "Signed      : $signed"
    Write-Host "Skipped     : $skipped"
    Write-Host "Failed      : $failed"
    Write-Host "Total       : $($scripts.Count)"
    Write-Host ""

    if ($failed -eq 0) {
        OK "Complete"
    } else {
        WARN "Complete with failures"
    }

    Write-Host ""
    Write-Host "Reminder:"
    Write-Host "- Re-run this after editing scripts"
    Write-Host "- Self-signed trust is local unless the cert is deployed to other machines"
    Write-Host "- If using AllSigned, the signing certificate must be trusted"

    Pause-End
}
catch {
    Write-Host ""
    FAIL "Unhandled script error"
    Write-Host $_.Exception.Message
    Pause-End
}
