param([string]$Root=(Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference='Stop';$cases=0
$reference=Get-Content -LiteralPath (Join-Path $Root 'tools/license-names/microsoft-products.json') -Raw|ConvertFrom-Json
foreach($file in @('INVOKE-ASSIGN-LICENSES.ps1','INVOKE-REMOVE-LICENSES.ps1')){
    $errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $Root ('published-source/identity/'+$file)),[ref]$null,[ref]$errors)
    if($errors.Count){throw ('Source parse failed: '+$file)}
    $function=$ast.Find({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Get-LicenseProductName'},$true)
    if(-not $function){throw 'Resolver missing.'};. ([scriptblock]::Create($function.Extent.Text))
    $script:LicenseNamesById=$null;$script:LicenseNamesByPart=$null
    foreach($row in $reference.products){
        $resolved=Get-LicenseProductName -SkuId ([string]$row[0]) -SkuPartNumber ([string]$row[1])
        $known=@($reference.products|Where-Object {$_[0] -eq $row[0]}|ForEach-Object {$_[2]})
        if($resolved -notin $known){throw ('GUID/name mismatch: '+$row[1])};$cases++
    }
    foreach($test in @(
        @('STANDARDPACK','Office 365 E1'),@('SPE_E5','Microsoft 365 E5'),@('ENTERPRISEPACK','Office 365 E3'),
        @('OFFICESUBSCRIPTION','Microsoft 365 Apps for Enterprise'),@('POWER_BI_STANDARD','Microsoft Fabric (Free)'),
        @('AAD_PREMIUM_P2','Microsoft Entra ID P2'),@('PROJECTPROFESSIONAL','Planner and Project Plan 3')
    )){if((Get-LicenseProductName -SkuPartNumber $test[0]) -cne $test[1]){throw ('Part/name mismatch: '+$test[0])};$cases++}
    if((Get-LicenseProductName -SkuId '18181A46-0D4E-45CD-891E-60AABD171B4E' -SkuPartNumber 'WRONG_CODE') -cne 'Office 365 E1'){throw 'Exact GUID did not take precedence.'};$cases++
    if((Get-LicenseProductName -SkuPartNumber 'UNKNOWN_PRODUCT') -cne 'Name unavailable: UNKNOWN_PRODUCT'){throw 'Unknown product was guessed.'};$cases++
    if((Get-LicenseProductName -SkuPartNumber 'MCOPSTN5') -cne 'Name unavailable: MCOPSTN5'){throw 'Ambiguous product was guessed.'};$cases++
}
Write-Host ('PASS: '+$cases+' license name checks across both standalone scripts.')
