Invoke-Sqlcmd -serverinstance "win3249627\QUAL" -Database "enviDataRulesDB_V2" -Query "SELECT TaskID, Task FROM dbo.tasks" -TrustServerCertificate
Read-Host "Zum Beenden Enter drücken"