<#
.SYNOPSIS
  Sets up the SQLite WASM backend that sqflite needs on the web.

.DESCRIPTION
  `sqflite` has no web implementation. The web build uses
  `sqflite_common_ffi_web`, which runs SQLite compiled to WebAssembly inside a
  web worker. That needs two files served alongside index.html:

    web/sqlite3.wasm    - the SQLite WASM binary
    web/sqflite_sw.js   - the generated worker that hosts it

  Neither ships inside the pub package - the WASM binary is compiled by the
  package's own setup tool. So rather than copying files out of the pub cache,
  this delegates to that tool:

    dart run sqflite_common_ffi_web:setup

  Run this after `flutter pub get`, and again after upgrading
  sqflite_common_ffi_web, because the assets are version-specific.

.PARAMETER Force
  Rebuild the binaries even if they already exist.
#>
[CmdletBinding()]
param([switch]$Force)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$webDir = Join-Path $projectRoot 'web'

if (-not (Test-Path $webDir)) {
  throw "web/ not found at $webDir"
}

Push-Location $projectRoot
try {
  $setupArgs = @('run', 'sqflite_common_ffi_web:setup')
  if ($Force) { $setupArgs += '--force' }

  Write-Host "==> dart $($setupArgs -join ' ')"
  & dart @setupArgs

  if ($LASTEXITCODE -ne 0) {
    throw "dart run sqflite_common_ffi_web:setup failed with exit code $LASTEXITCODE"
  }

  Write-Host ''
  foreach ($file in 'sqlite3.wasm', 'sqflite_sw.js') {
    $path = Join-Path $webDir $file
    if (Test-Path $path) {
      $kb = [math]::Round((Get-Item $path).Length / 1KB, 1)
      Write-Host ("  ok    web\{0,-16} {1} KB" -f $file, $kb)
    } else {
      Write-Warning "web\$file is still missing - the offline cache will not work on the web."
    }
  }
}
finally {
  Pop-Location
}

Write-Host ''
Write-Host 'Done. Verify with: flutter run -d chrome'
