function Test-Endpoint {
    param($Method, $Url, $Body = $null)
    Write-Host "Testing $Method $Url..." -ForegroundColor Cyan
    try {
        $params = @{
            Method      = $Method
            Uri         = $Url
            ContentType = "application/json"
        }
        if ($Body) { $params.Body = $Body }
        
        $response = Invoke-RestMethod @params
        Write-Host "  ✅ Success" -ForegroundColor Green
        return $response
    }
    catch {
        Write-Host "  ❌ Failed: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            Write-Host "  Response: $($reader.ReadToEnd())" -ForegroundColor Yellow
        }
        return $null
    }
}

$ProjectDir = $PSScriptRoot
$ExePath = Join-Path $ProjectDir "WebTUUIDBindingExample.exe"
$Port = 8080
$BaseUrl = "http://localhost:$Port"

Write-Host "--- Testing WebTUUIDBindingExample ---" -ForegroundColor White -BackgroundColor Blue

# 1. Compile
Write-Host "Compiling project..."
$SourcesRoot = "C:\dev\Dext\DextRepository\Sources"
# Recursively find all directories containing .pas files under Sources
$SourceDirs = Get-ChildItem -Path $SourcesRoot -Recurse -Directory | Where-Object { 
    (Get-ChildItem -Path $_.FullName -Filter *.pas).Count -gt 0 
} | Select-Object -ExpandProperty FullName

$SearchPaths = @("$ProjectDir", "$SourcesRoot") + $SourceDirs
$SearchPathStr = $SearchPaths -join ";"

& dcc32 -Q -B "-U$SearchPathStr" "-I$SearchPathStr" WebTUUIDBindingExample.dpr
if ($LastExitCode -ne 0) {
    Write-Host "❌ Compilation failed!" -ForegroundColor Red
    exit $LastExitCode
}

# 2. Start Server
Write-Host "Starting server..."
$Process = Start-Process -FilePath $ExePath -ArgumentList "--no-wait" -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 2 # Wait for server to bind

try {
    # 3. Test Generate V7
    $genResponse = Test-Endpoint "POST" "$BaseUrl/api/products/generate-v7"
    if ($genResponse) {
        $uuid = $genResponse.id
        Write-Host "  Generated UUID: $uuid"
        
        # 4. Test Get by ID
        Test-Endpoint "GET" "$BaseUrl/api/products/$uuid"
        
        # 5. Test JSON formats
        Test-Endpoint "GET" "$BaseUrl/api/uuid/formats/$uuid"
        
        # 6. Test POST (Create)
        $newProduct = @{
            id    = $uuid
            name  = "PowerShell Test Product"
            price = 123.45
        } | ConvertTo-Json
        Test-Endpoint "POST" "$BaseUrl/api/products" $newProduct
    }
}
finally {
    # 4. Stop Server
    Write-Host "Stopping server..."
    if ($Process) {
        Stop-Process -Id $Process.Id -Force
    }
}

Write-Host "--- Tests Completed ---" -ForegroundColor White -BackgroundColor Blue
