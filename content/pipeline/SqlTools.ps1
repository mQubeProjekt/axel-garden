function Invoke-Table
{
    param(
        [string]$TableName
    )

    Invoke-Sqlcmd `
        -ServerInstance $SqlConfig.Server `
        -Database $SqlConfig.Database `
        -Query "SELECT * FROM $TableName" `
        -TrustServerCertificate:$SqlConfig.TrustCert
}

function Get-RuleSQL
{
    param(
        [int]$RuleID
    )

    Invoke-Sqlcmd `
        -ServerInstance $SqlConfig.Server `
        -Database $SqlConfig.Database `
        -TrustServerCertificate `
        -Query "
            SELECT RuleSQL
            FROM dbo.rulesNew
            WHERE RuleID = $RuleID
        "
}

function Set-RuleSQL
{
    param(
        [int]$RuleID,
        [string]$RuleSQL
    )

    Invoke-Sqlcmd -ServerInstance $SqlConfig.Server -Database $SqlConfig.Database -TrustServerCertificate -Query "EXEC dbo.setRuleSQL @RuleID = $RuleID, @ruleSQL = N'$($RuleSQL.Replace("'", "''"))'"
}