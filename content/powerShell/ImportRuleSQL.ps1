. ".\config.ps1"
. ".\SqlTools.ps1"

$result = Set-RuleSQL -RuleID 99 -FileName "C:\axel\BASF\dbs\99_create_testTable.sql"

Read-Host "Enter drücken"