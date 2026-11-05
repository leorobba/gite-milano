<#
  Aggiorna lo stato (aperta / chiusa / ...) delle ferrate leggendo le schede di ferrate365.it
  e scrive data/stato.js, che index.html rilegge da solo ogni 30 minuti.

  Esecuzione manuale:
    powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\aggiorna-stato.ps1"
  Sul sito pubblicato viene eseguito ogni giorno da GitHub Actions (.github/workflows/pages.yml);
  in locale può essere eseguito dall'attivita' pianificata "GiteMilano - stato ferrate"
  (vedi scripts\installa-aggiornamento.ps1).
  Funziona sia con Windows PowerShell 5.1 sia con PowerShell 7 su Linux.
#>
$ErrorActionPreference = 'Stop'
$root    = Split-Path -Parent $PSScriptRoot
$dataJs  = [IO.Path]::Combine($root, 'data', 'ferrate.js')     # percorsi validi su Windows e su Linux
$outJs   = [IO.Path]::Combine($root, 'data', 'stato.js')
$logFile = [IO.Path]::Combine($PSScriptRoot, 'aggiorna-stato.log')
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Log($msg) { $line = "{0}  {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg; Add-Content -Path $logFile -Value $line -Encoding UTF8; Write-Host $line }
function ReadUtf8($p) { [IO.File]::ReadAllText($p, [Text.Encoding]::UTF8) }
function JsonPart($text, $marker) {
  $i = $text.IndexOf($marker); if ($i -lt 0) { return $null }
  $s = $text.Substring($i + $marker.Length).Trim()
  if ($s.EndsWith(';')) { $s = $s.Substring(0, $s.Length - 1) }
  return $s
}

# tiene solo le ultime 300 righe di log
if (Test-Path $logFile) { $old = Get-Content $logFile -Encoding UTF8 -Tail 300; Set-Content $logFile $old -Encoding UTF8 }

$ferrate = (JsonPart (ReadUtf8 $dataJs) 'window.FERRATE = ') | ConvertFrom-Json
$targets = @($ferrate | Where-Object { $_.url -like 'https://www.ferrate365.it/*' })
Log "Avvio: $($targets.Count) schede ferrate365 da controllare"

# stato precedente (per conservare i valori in caso di errore e registrare i cambi)
$prevStati = @{}; $cambi = New-Object System.Collections.ArrayList
if (Test-Path $outJs) {
  try {
    $prev = (JsonPart (ReadUtf8 $outJs) 'window.STATO_FERRATE = ') | ConvertFrom-Json
    $prev.stati.PSObject.Properties | ForEach-Object { $prevStati[$_.Name] = $_.Value }
    foreach ($c in @($prev.cambi)) { if ($c) { [void]$cambi.Add($c) } }
  } catch { Log "Attenzione: stato.js precedente non leggibile ($($_.Exception.Message))" }
} else {
  foreach ($f in $targets) { $prevStati[$f.id] = $f.stato }   # primo avvio: confronta con il dataset
}

$MAP = @{ 'aperta'='aperta'; 'chiusa'='chiusa'; 'da verificare'='verificare'; 'in manutenzione'='manutenzione';
          'chiusura stagionale'='stagionale'; 'smantellata'='smantellata' }
$rx = [regex]'>Stato</[a-z0-9]+>\s*<[^>]+>\s*([^<]+?)\s*<'
$stati = [ordered]@{}; $ok = 0; $err = 0; $now = (Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz')

foreach ($f in $targets) {
  $val = $null
  for ($try = 1; $try -le 2 -and -not $val; $try++) {
    try {
      $r = Invoke-WebRequest -Uri $f.url -UseBasicParsing -TimeoutSec 40 -UserAgent 'GiteMilano-stato/1.0 (uso personale, 1 controllo al giorno)'
      $m = $rx.Match($r.Content)
      if ($m.Success) {
        $t = $m.Groups[1].Value.Trim().ToLower()
        if ($MAP.ContainsKey($t)) { $val = $MAP[$t] } else { $val = 'verificare'; Log "Stato sconosciuto '$t' per $($f.id)" }
      } else { throw "campo Stato non trovato" }
    } catch {
      if ($try -eq 2) { Log "Errore $($f.id): $($_.Exception.Message)" } else { Start-Sleep -Seconds 3 }
    }
  }
  if ($val) {
    $ok++
    $before = $prevStati[$f.id]
    if ($before -and $before -ne $val) {
      [void]$cambi.Insert(0, [ordered]@{ id = $f.id; nome = $f.nome; da = $before; a = $val; quando = $now })
      Log "CAMBIO $($f.nome): $before -> $val"
    }
    $stati[$f.id] = $val
  } else {
    $err++
    if ($prevStati[$f.id]) { $stati[$f.id] = $prevStati[$f.id] }   # mantiene l'ultimo valore noto
  }
  Start-Sleep -Milliseconds 600   # gentile con il sito
}

while ($cambi.Count -gt 60) { $cambi.RemoveAt($cambi.Count - 1) }
$obj = [ordered]@{ aggiornato = (Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz'); controllate = $ok; errori = $err; fonte = 'ferrate365.it'; stati = $stati; cambi = @($cambi) }
$json = $obj | ConvertTo-Json -Depth 5 -Compress
$js = "/* Generato da scripts/aggiorna-stato.ps1 - non modificare a mano */`nwindow.STATO_FERRATE = $json;`n"
$tmp = "$outJs.tmp"
[IO.File]::WriteAllText($tmp, $js, (New-Object Text.UTF8Encoding $false))
Move-Item -Force $tmp $outJs
Log "Fine: $ok controllate, $err errori, $(@($cambi).Count) cambi in archivio"
