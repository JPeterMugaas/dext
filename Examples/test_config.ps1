$ErrorActionPreference = "Stop"

Write-Host "Authenticating..." -NoNewline
try {
    $LoginBody = @{ username = "admin"; password = "admin" } | ConvertTo-Json
    $LoginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/login" -Method Post -Body $LoginBody -ContentType "application/json"
    $Token = $LoginResponse.token
    Write-Host " OK" -ForegroundColor Green
}
catch {
    Write-Host " FAILED to Login" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
    exit
}

Write-Host "Testing Configuration Endpoint..."
try {
  $Response = Invoke-RestMethod -Uri "http://localhost:8080/api/greet/config" -Headers @{ "Authorization" = "Bearer $Token" }
  Write-Host "Response: $($Response | ConvertTo-Json -Depth 2)"

  if ($Response.Greeting -eq "Hello from appsettings.json") {
      Write-Host "✅ Configuration Test Passed" -ForegroundColor Green
  } else {
      Write-Host "❌ Configuration Test Failed" -ForegroundColor Red
  }
} catch {
  Write-Host "Error: $_" -ForegroundColor Red
}
