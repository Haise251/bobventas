# ============================================================
#  Firma el ejecutable de Windows de Bob Ventas
#  (firma de código con certificado propio o comprado)
#
#  Uso:
#    powershell -ExecutionPolicy Bypass -File .\firmar_windows.ps1
#        -ExePath "build\windows\x64\runner\Release\bob_ventas.exe"
#
#  Modos:
#    1) Certificado auto-firmado (gratis, para tu propio uso):
#       genera .pfx y firma. El PC mostrará "editor desconocido"
#       la primera vez; con "Propiedades → Desbloquear" o instalando
#       el certificado en "Entidades de raíz de confianza" desaparece.
#    2) Certificado comprado (Sectigo, DigiCert, Certum...):
#       pasa -PfxPath y -PfxPassword de tu certificado real.
# ============================================================
param(
    [Parameter(Mandatory = $true)][string]$ExePath,
    [string]$PfxPath = "",
    [string]$PfxPassword = "",
    [string]$CertName = "Bob Burguer",
    [string]$OutPfx = ".\bob-ventas-codigo.pfx"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ExePath)) {
    Write-Error "No existe el ejecutable: $ExePath"
    exit 1
}

# --- 1. Obtener certificado -------------------------------------------
if ([string]::IsNullOrWhiteSpace($PfxPath)) {
    Write-Host ">>> Creando certificado auto-firmado para '$CertName'..."
    $password = ConvertTo-SecureString -String $PfxPassword -Force -AsPlainText
    $cert = New-SelfSignedCertificate `
        -Type CodeSigningCert `
        -Subject "CN=$CertName" `
        -CertStoreLocation "Cert:\CurrentUser\My" `
        -KeyUsage DigitalSignature `
        -FriendlyName "$CertName - firma de codigo"
    Export-PfxCertificate -Cert $cert -FilePath $OutPfx -Password $password | Out-Null
    Write-Host ">>> Certificado exportado a: $OutPfx (guárdalo para firmas futuras)"
    $PfxPath = $OutPfx
    if ([string]::IsNullOrWhiteSpace($PfxPassword)) {
        Write-Error "Debes indicar -PfxPassword (contraseña del .pfx)."
        exit 1
    }
}

# --- 2. Localizar signtool --------------------------------------------
$signtool = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\bin" -Recurse `
    -Filter signtool.exe -ErrorAction SilentlyContinue |
    Sort-Object FullName -Descending | Select-Object -First 1

if (-not $signtool) {
    Write-Error "No se encontró signtool.exe. Instala el 'Windows SDK' (Windows 10/11 SDK)."
    exit 1
}

# --- 3. Firmar ---------------------------------------------------------
Write-Host ">>> Firmando: $ExePath"
& $signtool.FullName sign `
    /fd SHA256 `
    /f $PfxPath `
    /p $PfxPassword `
    /t http://timestamp.digicert.com `
    $ExePath

Write-Host ">>> Verificando firma:"
& $signtool.FullName verify /pa /v $ExePath

Write-Host ""
Write-Host "============================================================"
Write-Host " Listo. El .exe está firmado."
Write-Host " IMPORTANTE: firma también TODAS las DLL junto al exe si vas"
Write-Host " a distribuir la carpeta completa, repitiendo el comando por"
Write-Host " cada .dll, o usa un instalador (Inno Setup/MSIX)."
Write-Host "============================================================"
