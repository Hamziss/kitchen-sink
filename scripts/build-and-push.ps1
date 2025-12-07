# =============================================================================
# BUILD AND PUSH IMAGES SCRIPT (PowerShell)
# =============================================================================
# Usage:
#   .\scripts\build-and-push.ps1                    # Build all with 'latest' tag
#   .\scripts\build-and-push.ps1 -Service api-main -Tag v1.0.0
#   .\scripts\build-and-push.ps1 -Service all -Tag v1.0.0
# =============================================================================

param(
    [string]$Service = "all",
    [string]$Tag = "latest"
)

# Configuration
$HARBOR_REGISTRY = "harbor.hamziss.com"
$HARBOR_PROJECT = "production"
$DOMAIN = "hamziss.com"

Write-Host "==============================================" -ForegroundColor Green
Write-Host "Build and Push Docker Images to Harbor"
Write-Host "==============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Registry: $HARBOR_REGISTRY"
Write-Host "Project: $HARBOR_PROJECT"
Write-Host "Tag: $Tag"
Write-Host ""

function Build-And-Push {
    param(
        [string]$ServiceName,
        [string]$Context,
        [string]$BuildArgs = ""
    )

    Write-Host "Building $ServiceName..." -ForegroundColor Yellow
    
    $image = "$HARBOR_REGISTRY/$HARBOR_PROJECT/${ServiceName}:$Tag"
    
    if ($BuildArgs) {
        $cmd = "docker build $BuildArgs -t `"$image`" `"$Context`""
    } else {
        $cmd = "docker build -t `"$image`" `"$Context`""
    }
    
    Write-Host "Running: $cmd" -ForegroundColor Gray
    Invoke-Expression $cmd
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to build $ServiceName" -ForegroundColor Red
        return $false
    }
    
    Write-Host "Pushing $ServiceName..." -ForegroundColor Yellow
    docker push $image
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to push $ServiceName" -ForegroundColor Red
        return $false
    }
    
    Write-Host "SUCCESS: $ServiceName pushed!" -ForegroundColor Green
    Write-Host ""
    return $true
}

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

Push-Location $ProjectRoot

try {
    switch ($Service) {
        "api-main" {
            Build-And-Push -ServiceName "api-main" -Context "./api-main"
        }
        "api-second" {
            Build-And-Push -ServiceName "api-second" -Context "./api-second"
        }
        "front" {
            $buildArgs = "--build-arg VITE_API_MAIN_URL=https://api.$DOMAIN --build-arg VITE_API_SECOND_URL=https://api2.$DOMAIN"
            Build-And-Push -ServiceName "front" -Context "./front" -BuildArgs $buildArgs
        }
        "all" {
            Build-And-Push -ServiceName "api-main" -Context "./api-main"
            Build-And-Push -ServiceName "api-second" -Context "./api-second"
            
            $buildArgs = "--build-arg VITE_API_MAIN_URL=https://api.$DOMAIN --build-arg VITE_API_SECOND_URL=https://api2.$DOMAIN"
            Build-And-Push -ServiceName "front" -Context "./front" -BuildArgs $buildArgs
        }
        default {
            Write-Host "Usage: .\build-and-push.ps1 -Service [api-main|api-second|front|all] -Tag [version]" -ForegroundColor Yellow
            exit 1
        }
    }
} finally {
    Pop-Location
}

Write-Host "==============================================" -ForegroundColor Green
Write-Host "Build complete!"
Write-Host "==============================================" -ForegroundColor Green
