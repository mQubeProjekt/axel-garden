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