. ".\config.ps1"
. ".\SqlTools.ps1"

$result = Get-RuleSQL -RuleID 99


Write-Host "Zeilen gefunden: " $result.Count

$result | Out-GridView -Title "SQL-Tabelle"

Read-Host "Enter drücken"