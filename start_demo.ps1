$ErrorActionPreference = "Stop"
$basePath = "c:\Users\Manita\Downloads\appdoctor\doctorappnew-main\doctor-app-system"

$services = @(
    "auth-service",
    "patient-service",
    "consultation-service",
    "prescription-service",
    "appointment-service",
    "api-gateway"
)

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "1. INSTALLATION DES DÉPENDANCES BACKEND (npm install)" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

foreach ($service in $services) {
    Write-Host "-> Installation pour $service..." -ForegroundColor Yellow
    Set-Location "$basePath\services\$service"
    npm install
}

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "2. DÉMARRAGE DES SERVICES BACKEND" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "Chaque service va s'ouvrir dans une nouvelle fenêtre." -ForegroundColor Yellow

foreach ($service in $services) {
    Write-Host "-> Démarrage de $service..." -ForegroundColor Green
    if ($service -eq "api-gateway") {
        Start-Process "node" -ArgumentList "server.js" -WorkingDirectory "$basePath\services\$service" -WindowStyle Normal -RedirectStandardOutput "$basePath\services\$service\gateway_stdout.txt" -RedirectStandardError "$basePath\services\$service\gateway_stderr.txt"
    } elseif ($service -eq "auth-service") {
        # SPECIFICALLY capture auth-service logs!
        Start-Process "npm.cmd" -ArgumentList "run dev" -WorkingDirectory "$basePath\services\$service" -WindowStyle Normal -RedirectStandardOutput "$basePath\services\$service\auth_stdout.txt" -RedirectStandardError "$basePath\services\$service\auth_stderr.txt"
    } else {
        Start-Process "npm.cmd" -ArgumentList "run dev" -WorkingDirectory "$basePath\services\$service" -WindowStyle Normal
    }
    # Attendre un peu que le service s'initialise avant de lancer le suivant
    Start-Sleep -Seconds 5
}

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "3. PRÉPARATION DU FRONTEND FLUTTER" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Set-Location "$basePath\frontend"
Write-Host "-> flutter pub get..." -ForegroundColor Yellow
flutter pub get

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "4. LANCEMENT DU FRONTEND" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "-> Démarrage sur Chrome..." -ForegroundColor Green
Start-Process "flutter.bat" -ArgumentList "run -d chrome --web-port 3000" -WorkingDirectory "$basePath\frontend" -WindowStyle Normal

Write-Host "`n✅ Terminé ! Gardez les fenêtres ouvertes." -ForegroundColor Green
Write-Host "Connectez-vous avec : mejriaziz917@gmail.com / admin123" -ForegroundColor Magenta
