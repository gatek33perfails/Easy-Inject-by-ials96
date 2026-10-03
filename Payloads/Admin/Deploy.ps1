$ErrorActionPreference = 'Stop'

$consoleIp = '192.168.1.31'
$ftpPort = 1337
$nexusPort = 2567
$remoteRoot = '/data/DeadOps/t6_mp'
$loader = 'C:\Users\dffgd\Desktop\modbo2bo1\Nexus-BO-Loader.exe'
$sourceRoot = Join-Path $PSScriptRoot 'source'

$files = Get-ChildItem -LiteralPath (Join-Path $sourceRoot 'maps') -Recurse -File -Filter '*.gsc'
if (-not $files -or $files.Count -ne 4) {
    throw 'The verified Admin menu payload is incomplete.'
}

foreach ($file in $files) {
    $relative = $file.FullName.Substring($sourceRoot.Length + 1).Replace('\', '/')
    $remoteUrl = "ftp://${consoleIp}:${ftpPort}${remoteRoot}/${relative}"
    & curl.exe --fail --silent --show-error --user 'anonymous:' --ftp-create-dirs --upload-file $file.FullName $remoteUrl
    if ($LASTEXITCODE -ne 0) { throw "Upload failed: $relative" }
}

$processes = Invoke-RestMethod -Uri "http://${consoleIp}:${nexusPort}/get_proc_list" -TimeoutSec 8
$bo2 = $processes.RESPONSE.LIST | Where-Object { $_.TID -eq 'CUSA57548' -and $_.EXEC -eq 'codmp.elf' } | Select-Object -First 1
if (-not $bo2) { throw 'Black Ops 2 Multiplayer is not running.' }
if (-not (Test-Path -LiteralPath $loader)) { throw 'Nexus BO loader was not found.' }

& $loader
if ($LASTEXITCODE -ne 0) { throw "Nexus loader failed with exit code $LASTEXITCODE." }

Write-Output 'DONE'
