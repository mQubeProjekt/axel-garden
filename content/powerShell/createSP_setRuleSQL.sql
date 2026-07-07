USE [enviDataRulesDB_V2]
GO

/****** Objekt:  StoredProcedure [dbo].[setRuleSQL]    Skriptdatum: 07.07.2026 15:35:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[setRuleSQL] @myRuleID INT, @myRuleSQL NVARCHAR(MAX) AS
	BEGIN
		UPDATE dbo.rules
		SET ruleSQL = @myRuleSQL
		WHERE RuleID = @myRuleID
	END
GO


