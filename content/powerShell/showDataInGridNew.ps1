$ErrorActionPreference = "Stop"

try {
    Import-Module SqlServer

    $result = Invoke-Sqlcmd `
        -ServerInstance "win3249627\QUAL" `
        -Database "enviDataRulesDB_V2" `
        -Query "SELECT TaskID, Task FROM dbo.tasks" `
        -TrustServerCertificate

    Write-Host "Zeilen gefunden:" $result.Count

    if ($result.Count -gt 0) {
        $result | Out-GridView -Title "SQL-Tabelle"
    } else {
        Write-Host "Die Abfrage hat keine Datensätze geliefert."
    }
}
catch {
    $_ | Format-List -Force
}

Read-Host "Enter drücken zum Beenden"