param([ValidateSet('start','stop','status')][string]$Action = 'start')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$pgBin = 'C:\Program Files\PostgreSQL\17\bin'
$cluster = Join-Path $projectRoot '.local\postgres'
$pgLog = Join-Path $projectRoot '.local\postgres.log'
foreach ($tool in @('pg_ctl.exe','psql.exe','pg_isready.exe','initdb.exe','createdb.exe')) {
  if (!(Test-Path -LiteralPath (Join-Path $pgBin $tool))) {
    throw "PostgreSQL 17 tool missing: $pgBin\$tool. No database files were changed."
  }
}
if ($Action -eq 'stop') {
  & (Join-Path $pgBin 'pg_ctl.exe') -D $cluster -m fast -w stop
  exit $LASTEXITCODE
}
if (!(Test-Path (Join-Path $cluster 'PG_VERSION'))) {
  if ($Action -ne 'start' -or ((Test-Path -LiteralPath $cluster) -and (Get-ChildItem -LiteralPath $cluster -Force | Select-Object -First 1))) {
    throw "No PG_VERSION in $cluster. Refusing to initialize an existing nonempty cluster; inspect it before recovery."
  }
  & (Join-Path $pgBin 'initdb.exe') -D $cluster -U leadcurrent -A trust --encoding=UTF8 --locale=C
  if ($LASTEXITCODE -ne 0) { throw 'PostgreSQL initialization failed' }
}
& (Join-Path $pgBin 'pg_ctl.exe') -D $cluster status *> $null
$clusterStatus = $LASTEXITCODE
if ($clusterStatus -eq 3) {
  if ($Action -eq 'status') { throw 'LeadCurrent PostgreSQL is stopped. Run bin/local-postgres.ps1 -Action start.' }
  $listener = Get-NetTCPConnection -State Listen -LocalPort 55432 -ErrorAction SilentlyContinue
  if ($listener) {
    throw "Port 55432 is occupied by PID(s) $($listener.OwningProcess -join ', '). The project cluster is stopped; no processes were terminated."
  }
  & (Join-Path $pgBin 'pg_ctl.exe') -D $cluster -l $pgLog -o '-h 127.0.0.1 -p 55432' -w start
  if ($LASTEXITCODE -ne 0) { throw "PostgreSQL startup failed. Inspect $pgLog. No PID or database files were deleted." }
} elseif ($clusterStatus -ne 0) {
  throw "Cannot inspect the project cluster (pg_ctl exit $clusterStatus). Check permissions and $pgLog."
} else {
  Write-Output 'LeadCurrent PostgreSQL is already running; verifying its endpoint.'
}
$pidInfo = Get-Content -LiteralPath (Join-Path $cluster 'postmaster.pid')
if ($pidInfo.Count -lt 4 -or $pidInfo[3].Trim() -ne '55432') {
  throw 'The project cluster is running on an unexpected port. Expected 55432; no configuration was changed.'
}
& (Join-Path $pgBin 'pg_isready.exe') -h 127.0.0.1 -p 55432 -U leadcurrent -d postgres -t 3
if ($LASTEXITCODE -ne 0) { throw "PostgreSQL is not ready on 127.0.0.1:55432. Inspect $pgLog." }
$actualCluster = & (Join-Path $pgBin 'psql.exe') -X -w -v ON_ERROR_STOP=1 -h 127.0.0.1 -p 55432 -U leadcurrent -d postgres -tAc 'SHOW data_directory'
if ($LASTEXITCODE -ne 0) { throw "Cannot connect as leadcurrent. Check local authentication and $pgLog." }
if ([IO.Path]::GetFullPath($actualCluster.Trim()) -ne [IO.Path]::GetFullPath($cluster)) {
  throw 'Port 55432 belongs to a different cluster. No application databases were created.'
}
# Create only this application's independent development/test databases.
foreach ($dbName in @('leadcurrent_development','leadcurrent_test')) {
  $found = & (Join-Path $pgBin 'psql.exe') -X -w -v ON_ERROR_STOP=1 -h 127.0.0.1 -p 55432 -U leadcurrent -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$dbName'"
  if ($LASTEXITCODE -ne 0) { throw "Cannot inspect application databases. Check $pgLog; no database was created." }
  if ($found -ne '1') {
    if ($Action -eq 'status') { throw "Expected database $dbName is missing. No database was created." }
    & (Join-Path $pgBin 'createdb.exe') -h 127.0.0.1 -p 55432 -U leadcurrent $dbName
    if ($LASTEXITCODE -ne 0) { throw 'Application database creation failed' }
  }
}
Write-Output 'LeadCurrent local PostgreSQL ready at 127.0.0.1:55432 (development only).'
