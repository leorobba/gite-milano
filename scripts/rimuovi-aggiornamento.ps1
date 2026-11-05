# Rimuove l'attivita' pianificata creata da installa-aggiornamento.ps1
$name = 'GiteMilano - stato ferrate'
if (Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue) {
  Unregister-ScheduledTask -TaskName $name -Confirm:$false
  Write-Host "Attivita' '$name' rimossa. La pagina mostrera' l'ultimo stato salvato in data\stato.js."
} else { Write-Host "Nessuna attivita' '$name' trovata." }
