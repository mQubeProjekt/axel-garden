USE al_test
GO
CREATE TRIGGER dbo.trg_rules_upd
ON dbo.rules
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Beispiel: Protokolliere Änderungen in eine Historientabelle
    INSERT INTO dbo.log_rules ( ruleID, old_RuleSQL, new_RuleSQL, chgDTM)

    SELECT 
        i.RuleID,
        d.RuleSQL AS AlterWert,
        i.RuleSQL AS NeuerWert,
        GETDATE()
    FROM inserted i
    INNER JOIN deleted d ON i.ruleID = d.ruleID
    WHERE UPDATE(RuleSQL); -- Prüft, ob SpalteX geändert wurde
END;
GO

--SELECT USER_name()
--CREATE TABLE dbo.log_rules (logID INT identity(1,1), RuleID INT, old_RuleSQL NVARCHAR(MAX), new_RuleSQL NVARCHAR(MAX), chgDTM DATETIME)

--ALTER TABLE dbo.log_rules ADD CONSTRAINT pk_logID PRIMARY KEY(logID)