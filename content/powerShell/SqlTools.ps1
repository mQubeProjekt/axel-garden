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

function Set-CustomerRemarks
{
    param(
        [int]$RuleID,
        [string]$FileName
    )

    $ruleSQL = Get-Content $FileName -Raw

    Invoke-Sqlcmd `
        -ServerInstance $SqlConfig.Server `
        -Database $SqlConfig.Database `
        -TrustServerCertificate `
        -Query "EXEC dbo.setRuleSQL @RuleID = $CustomerID, @Remarks = N'$($ruleSQL.Replace("'", "''"))'"
}
