<#
  Crea l'attivita' pianificata di Windows "GiteMilano - stato ferrate":
  esegue scripts\aggiorna-stato.ps1 ogni giorno alle 7:30 e all'accesso a Windows.
  Se il PC era spento all'orario previsto, viene eseguita appena possibile.
  Gira con il tuo utente, senza privilegi di amministratore, solo con la rete disponibile.

  Rimozione:  powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\rimuovi-aggiornamento.ps1"
#>
$ErrorActionPreference = 'Stop'
$script = Join-Path $PSScriptRoot 'aggiorna-stato.ps1'
$name   = 'GiteMilano - stato ferrate'

$action  = New-ScheduledTaskAction -Execute 'powershell.exe' `
             -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script`"" `
             -WorkingDirectory $PSScriptRoot
$daily   = New-ScheduledTaskTrigger -Daily -At '07:30'
$logon   = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
$logon.Delay = 'PT3M'   # 3 minuti dopo l'accesso, per dare tempo alla rete
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -RunOnlyIfNetworkAvailable `
             -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 30) `
             -MultipleInstances IgnoreNew
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited

Register-ScheduledTask -TaskName $name -Action $action -Trigger @($daily, $logon) -Settings $settings `
  -Principal $principal -Description "Aggiorna lo stato delle ferrate (ferrate365.it) per Gite Milano: scrive data\stato.js" -Force | Out-Null

Write-Host "Attivita' pianificata '$name' installata: ogni giorno alle 7:30 e all'accesso."
