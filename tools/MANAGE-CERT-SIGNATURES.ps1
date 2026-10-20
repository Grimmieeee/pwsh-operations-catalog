<#
.VERSION 1.0.0
#>
<#
manage-code-signing-cert.ps1

Code-signing certificate helper for jumpbox PowerShell tooling.

Companion utility for:
  sign-folder-scripts.ps1

Purpose:
- Create a local code-signing certificate
- List available code-signing certificates
- Export a public .cer trust file
- Trust a public .cer on the current jumpbox/user
- Export a private .pfx if you intentionally want signing available elsewhere
- Import a private .pfx on another jumpbox

Recommended model:
1. Create one signing cert on a primary/admin jumpbox.
2. Sign scripts from that box with sign-folder-scripts.ps1.
3. Export the public .cer.
4. Trust the public .cer on other jumpboxes.
5. Deploy signed scripts.

Safer default:
- Do not move the private key around unless you really need to sign scripts from multiple jumpboxes.

No automatic exports.
No hardcoded paths.
PowerShell 5.1 friendly.
#>

param(
    [string]$CertName = "Local Script Signing",
    [string]$Path
)

$ErrorActionPreference = "SilentlyContinue"

function OK($m)   { Write-Host "[OK]   $m" -ForegroundColor Green }
function INFO($m) { Write-Host "[INFO] $m" }
function WARN($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }
function FAIL($m) { Write-Host "[FAIL] $m" -ForegroundColor Red }

function Pause-End {
    Write-Host ""
    Read-Host "Press Enter to close" | Out-Null
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

function Confirm-Type {
    param(
        [string]$Prompt,
        [string]$Required
    )

    Write-Host ""
    WARN $Prompt
    $a = Read-Host "Type $Required to continue"

    return ($a.Trim().ToUpper() -eq $Required.ToUpper())
}

function Normalize-Subject {
    param([string]$Name)

    if (-not $Name) {
        $Name = "Local Script Signing"
    }

    if ($Name -notlike "CN=*") {
        return "CN=$Name"
    }

    return $Name
}

function Get-CodeSigningCerts {
    $certs = @(Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert -ErrorAction SilentlyContinue | Sort-Object NotAfter -Descending)
    return $certs
}

function Show-CodeSigningCerts {
    Section "CODE-SIGNING CERTIFICATES"

    $certs = @(Get-CodeSigningCerts)

    if ($certs.Count -eq 0) {
        WARN "No code-signing certificates found in CurrentUser\My"
        return @()
    }

    for ($i = 0; $i -lt $certs.Count; $i++) {
        $c = $certs[$i]

        Write-Host ("[{0}] {1}" -f ($i + 1), $c.Subject)
        Write-Host "    Thumbprint : $($c.Thumbprint)"
        Write-Host "    Expires    : $($c.NotAfter)"
        Write-Host "    HasPrivate : $($c.HasPrivateKey)"
        Write-Host ""
    }

    return $certs
}

function Select-CodeSigningCert {
    $certs = @(Show-CodeSigningCerts)

    if ($certs.Count -eq 0) {
        return $null
    }

    $choice = Read-Host "Choose certificate number"

    try {
        $index = [int]$choice - 1

        if ($index -ge 0 -and $index -lt $certs.Count) {
            return $certs[$index]
        }
    } catch {}

    WARN "Invalid certificate selection"
    return $null
}

function New-LocalCodeSigningCert {
    Section "CREATE LOCAL CODE-SIGNING CERT"

    $name = Read-Host "Certificate name [default: $CertName]"

    if (-not $name) {
        $name = $CertName
    }

    $subject = Normalize-Subject $name

    Write-Host ""
    Write-Host "Subject : $subject"
    Write-Host "Store   : CurrentUser\My"
    Write-Host "Expires : 5 years"
    Write-Host ""

    if (-not (Confirm-Type "This will create a local self-signed code-signing certificate." "CREATE")) {
        WARN "Certificate creation cancelled"
        return $null
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
            -KeyExportPolicy Exportable `
            -NotAfter (Get-Date).AddYears(5) `
            -ErrorAction Stop

        OK "Created certificate"
        Write-Host "Thumbprint: $($cert.Thumbprint)"

        if (Confirm-Yes "Trust this certificate for the current user now") {
            Trust-CertificateObject -Cert $cert
        }

        return $cert
    }
    catch {
        FAIL "Certificate creation failed"
        Write-Host $_.Exception.Message
        return $null
    }
}

function Trust-CertificateObject {
    param([System.Security.Cryptography.X509Certificates.X509Certificate2]$Cert)

    if (-not $Cert) {
        FAIL "No certificate provided"
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
        Write-Host "TrustedPublisher: CurrentUser"
        Write-Host "Root            : CurrentUser"
    }
    catch {
        FAIL "Could not trust certificate"
        Write-Host $_.Exception.Message
    }
}

function Export-PublicCert {
    Section "EXPORT PUBLIC TRUST CERTIFICATE"

    $cert = Select-CodeSigningCert

    if (-not $cert) {
        return
    }

    $outPath = Read-Host "Output .cer path"

    if (-not $outPath) {
        FAIL "Output path required"
        return
    }

    $outPath = $outPath.Trim().Trim('"')

    if (-not $outPath.ToLower().EndsWith(".cer")) {
        $outPath = "$outPath.cer"
    }

    try {
        $parent = Split-Path -Parent $outPath

        if ($parent -and -not (Test-Path $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }

        Export-Certificate -Cert $cert -FilePath $outPath -Force -ErrorAction Stop | Out-Null

        OK "Exported public certificate"
        Write-Host $outPath
    }
    catch {
        FAIL "Public certificate export failed"
        Write-Host $_.Exception.Message
    }
}

function Trust-PublicCertFile {
    Section "TRUST PUBLIC CERTIFICATE"

    $certPath = $Path

    if (-not $certPath) {
        $certPath = Read-Host "Path to .cer file"
    }

    if (-not $certPath) {
        FAIL ".cer path required"
        return
    }

    $certPath = $certPath.Trim().Trim('"')

    if (-not (Test-Path $certPath)) {
        FAIL "File not found: $certPath"
        return
    }

    try {
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certPath)

        Write-Host ""
        Write-Host "Subject   : $($cert.Subject)"
        Write-Host "Thumbprint: $($cert.Thumbprint)"
        Write-Host ""

        if (-not (Confirm-Type "This will trust the certificate for the current user." "TRUST")) {
            WARN "Trust action cancelled"
            return
        }

        Trust-CertificateObject -Cert $cert
    }
    catch {
        FAIL "Could not load or trust certificate"
        Write-Host $_.Exception.Message
    }
}

function Export-PrivatePfx {
    Section "EXPORT PRIVATE PFX"

    $cert = Select-CodeSigningCert

    if (-not $cert) {
        return
    }

    if (-not $cert.HasPrivateKey) {
        FAIL "Selected certificate does not have a private key"
        return
    }

    WARN "PFX contains the private signing key."
    WARN "Only export this if you intentionally need signing available on another jumpbox."

    if (-not (Confirm-Type "This will export the private key." "EXPORT")) {
        WARN "PFX export cancelled"
        return
    }

    $outPath = Read-Host "Output .pfx path"

    if (-not $outPath) {
        FAIL "Output path required"
        return
    }

    $outPath = $outPath.Trim().Trim('"')

    if (-not $outPath.ToLower().EndsWith(".pfx")) {
        $outPath = "$outPath.pfx"
    }

    $password = Read-Host "PFX password" -AsSecureString

    if (-not $password) {
        FAIL "Password required"
        return
    }

    try {
        $parent = Split-Path -Parent $outPath

        if ($parent -and -not (Test-Path $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }

        Export-PfxCertificate -Cert $cert -FilePath $outPath -Password $password -Force -ErrorAction Stop | Out-Null

        OK "Exported private PFX"
        Write-Host $outPath
    }
    catch {
        FAIL "PFX export failed"
        Write-Host $_.Exception.Message
    }
}

function Import-PrivatePfx {
    Section "IMPORT PRIVATE PFX"

    $pfxPath = $Path

    if (-not $pfxPath) {
        $pfxPath = Read-Host "Path to .pfx file"
    }

    if (-not $pfxPath) {
        FAIL ".pfx path required"
        return
    }

    $pfxPath = $pfxPath.Trim().Trim('"')

    if (-not (Test-Path $pfxPath)) {
        FAIL "File not found: $pfxPath"
        return
    }

    WARN "This imports a private signing key into CurrentUser\My."

    if (-not (Confirm-Type "Import private code-signing key." "IMPORT")) {
        WARN "PFX import cancelled"
        return
    }

    $password = Read-Host "PFX password" -AsSecureString

    if (-not $password) {
        FAIL "Password required"
        return
    }

    try {
        $cert = Import-PfxCertificate -FilePath $pfxPath -CertStoreLocation Cert:\CurrentUser\My -Password $password -Exportable -ErrorAction Stop

        OK "Imported PFX"
        Write-Host "Subject   : $($cert.Subject)"
        Write-Host "Thumbprint: $($cert.Thumbprint)"

        if (Confirm-Yes "Trust this certificate for the current user now") {
            Trust-CertificateObject -Cert $cert
        }
    }
    catch {
        FAIL "PFX import failed"
        Write-Host $_.Exception.Message
    }
}

function Show-TrustStatus {
    Section "TRUST STATUS"

    $cert = Select-CodeSigningCert

    if (-not $cert) {
        return
    }

    $publisherMatch = $false
    $rootMatch = $false

    try {
        $publisher = @(Get-ChildItem Cert:\CurrentUser\TrustedPublisher -ErrorAction SilentlyContinue | Where-Object { $_.Thumbprint -eq $cert.Thumbprint })
        if ($publisher.Count -gt 0) { $publisherMatch = $true }
    } catch {}

    try {
        $root = @(Get-ChildItem Cert:\CurrentUser\Root -ErrorAction SilentlyContinue | Where-Object { $_.Thumbprint -eq $cert.Thumbprint })
        if ($root.Count -gt 0) { $rootMatch = $true }
    } catch {}

    Write-Host "Subject   : $($cert.Subject)"
    Write-Host "Thumbprint: $($cert.Thumbprint)"
    Write-Host "PrivateKey: $($cert.HasPrivateKey)"
    Write-Host ""
    Write-Host "TrustedPublisher CurrentUser: $publisherMatch"
    Write-Host "Root CurrentUser            : $rootMatch"

    if ($publisherMatch -and $rootMatch) {
        OK "Certificate is trusted for current user"
    }
    else {
        WARN "Certificate is not fully trusted for current user"

        if (Confirm-Yes "Trust this certificate now") {
            Trust-CertificateObject -Cert $cert
        }
    }
}

function Show-Menu {
    Section "CODE-SIGNING CERT MANAGER"

    Write-Host "[1] List code-signing certificates"
    Write-Host "[2] Create local self-signed code-signing cert"
    Write-Host "[3] Export public .cer trust file"
    Write-Host "[4] Trust public .cer for current user"
    Write-Host "[5] Export private .pfx"
    Write-Host "[6] Import private .pfx"
    Write-Host "[7] Check / fix trust status"
    Write-Host "[Q] Quit"
    Write-Host ""
}

try {
    try {
        $host.UI.RawUI.WindowTitle = "Manage Code-Signing Cert"
    }
    catch {}

    Clear-Host
    Write-Host "MANAGE CODE-SIGNING CERT"
    Write-Host ""

    do {
        Show-Menu
        $choice = (Read-Host "Choose").Trim().ToUpper()

        switch ($choice) {
            "1" { [void](Show-CodeSigningCerts) }
            "2" { [void](New-LocalCodeSigningCert) }
            "3" { Export-PublicCert }
            "4" { Trust-PublicCertFile }
            "5" { Export-PrivatePfx }
            "6" { Import-PrivatePfx }
            "7" { Show-TrustStatus }
            "Q" { break }
            default { WARN "Unknown option" }
        }
    } while ($choice -ne "Q")

    Write-Host ""
    OK "Closed"
    Pause-End
}
catch {
    Write-Host ""
    FAIL "Unhandled script error"
    Write-Host $_.Exception.Message
    Pause-End
}

