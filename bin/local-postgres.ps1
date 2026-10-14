param([ValidateSet('start','stop')][string]$Action = 'start')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$pgBin = 'C:\Program Files\PostgreSQL\17\bin'
$cluster = Join-Path $projectRoot '.local\postgres'
if ($Action -eq 'stop') {
  & (Join-Path $pgBin 'pg_ctl.exe') -D $cluster -m fast -w stop
  exit $LASTEXITCODE
}
if (!(Test-Path (Join-Path $cluster 'PG_VERSION'))) {
  & (Join-Path $pgBin 'initdb.exe') -D $cluster -U leadcurrent -A trust --encoding=UTF8 --locale=C
  if ($LASTEXITCODE -ne 0) { throw 'PostgreSQL initialization failed' }
}
& (Join-Path $pgBin 'pg_ctl.exe') -D $cluster status *> $null
if ($LASTEXITCODE -ne 0) {
  & (Join-Path $pgBin 'pg_ctl.exe') -D $cluster -l (Join-Path $projectRoot '.local\postgres.log') -o '-h 127.0.0.1 -p 55432' -w start
  if ($LASTEXITCODE -ne 0) { throw 'PostgreSQL startup failed' }
}
# Create only this application's independent development/test databases.
foreach ($dbName in @('leadcurrent_development','leadcurrent_test')) {
  $found = & (Join-Path $pgBin 'psql.exe') -h 127.0.0.1 -p 55432 -U leadcurrent -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$dbName'"
  if ($found -ne '1') {
    & (Join-Path $pgBin 'createdb.exe') -h 127.0.0.1 -p 55432 -U leadcurrent $dbName
    if ($LASTEXITCODE -ne 0) { throw 'Application database creation failed' }
  }
}
Write-Output 'LeadCurrent local PostgreSQL ready at 127.0.0.1:55432 (development only).'
