# test_web_features.ps1
$BaseUrl = "http://localhost:8080"
$ErrorActionPreference = "Stop"

function Test-Endpoint {
    param($Name, $Url, $Method="GET", $Headers=@{})
    Write-Host "Testing $Name..." -NoNewline
    try {
        $Response = Invoke-RestMethod -Uri $Url -Method $Method -Headers $Headers -ErrorAction Stop
        Write-Host " OK" -ForegroundColor Green
        # Convert PSCustomObject to JSON strictly for display
        $Json = $Response | ConvertTo-Json -Depth 2 -Compress
        Write-Host "  Response: $Json" -ForegroundColor Gray
    }
    catch {
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
        if ($_.Exception.Response) {
             $Stream = $_.Exception.Response.GetResponseStream()
             $Reader = New-Object System.IO.StreamReader($Stream)
             Write-Host "  Body: $($Reader.ReadToEnd())" -ForegroundColor Red
        }
    }
}

Write-Host "🚀 Testing Dext Web Features" -ForegroundColor Cyan
Write-Host "--------------------------------"

# 0. Authentication
Write-Host "Authenticating..." -NoNewline
try {
    $LoginBody = @{ username = "admin"; password = "admin" } | ConvertTo-Json
    $LoginResponse = Invoke-RestMethod -Uri "$BaseUrl/api/auth/login" -Method Post -Body $LoginBody -ContentType "application/json"
    $Token = $LoginResponse.token
    Write-Host " OK" -ForegroundColor Green
}
catch {
    Write-Host " FAILED to Login" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
    exit
}

$GlobalHeaders = @{ "Authorization" = "Bearer $Token" }

# 1. Content Negotiation
Test-Endpoint "Content Negotiation (JSON Default)" "$BaseUrl/api/greet/negotiated" -Headers $GlobalHeaders
# Merging headers for explicit Content Type
$JsonHeaders = $GlobalHeaders.Clone()
$JsonHeaders["Accept"] = "application/json"
Test-Endpoint "Content Negotiation (Explicit JSON)" "$BaseUrl/api/greet/negotiated" -Headers $JsonHeaders

# 2. API Versioning - Query String (These are anonymous in dpr, but adding auth header doesn't hurt)
Test-Endpoint "Versioning V1 (Query)" "$BaseUrl/api/versioned?api-version=1.0" -Headers $GlobalHeaders
Test-Endpoint "Versioning V2 (Query)" "$BaseUrl/api/versioned?api-version=2.0" -Headers $GlobalHeaders

# 3. API Versioning - Header
# Merging headers
$V1Headers = $GlobalHeaders.Clone()
$V1Headers["X-Version"] = "1.0"
Test-Endpoint "Versioning V1 (Header)" "$BaseUrl/api/versioned" -Headers $V1Headers

$V2Headers = $GlobalHeaders.Clone()
$V2Headers["X-Version"] = "2.0"
Test-Endpoint "Versioning V2 (Header)" "$BaseUrl/api/versioned" -Headers $V2Headers

# 4. Error Cases
Write-Host "Testing 404 Case (No matching version)..." -NoNewline
try {
    Invoke-RestMethod -Uri "$BaseUrl/api/versioned?api-version=9.0" -Headers $GlobalHeaders -ErrorAction Stop | Out-Null
    Write-Host " FAILED (Expected 404)" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 404) {
        Write-Host " OK (Got 404)" -ForegroundColor Green
    } else {
        Write-Host " FAILED (Got $($_.Exception.Response.StatusCode))" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Done."
