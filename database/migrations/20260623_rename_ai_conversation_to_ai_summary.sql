-- Rename table AI_Conversation to AI_Summary if it exists
IF OBJECT_ID('dbo.AI_Conversation', 'U') IS NOT NULL AND OBJECT_ID('dbo.AI_Summary', 'U') IS NULL
BEGIN
    EXEC sp_rename 'dbo.AI_Conversation', 'AI_Summary';
END;

-- Rename column conversation_id to summary_id if it exists in AI_Summary table
IF COL_LENGTH('dbo.AI_Summary', 'conversation_id') IS NOT NULL AND COL_LENGTH('dbo.AI_Summary', 'summary_id') IS NULL
BEGIN
    EXEC sp_rename 'dbo.AI_Summary.conversation_id', 'summary_id', 'COLUMN';
END;
