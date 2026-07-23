-- ============================================
-- Migration: Xoa AI_Conversation, tao AI_Summary
-- ============================================

-- 1. Xoa rang buoc khoa ngoai tren Appointment neu co
IF EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
    WHERE TABLE_NAME = 'Appointment' AND CONSTRAINT_NAME LIKE '%conversation%'
)
BEGIN
    DECLARE @constraintName NVARCHAR(256);
    SELECT @constraintName = CONSTRAINT_NAME 
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
    WHERE TABLE_NAME = 'Appointment' AND CONSTRAINT_NAME LIKE '%conversation%';
    EXEC('ALTER TABLE Appointment DROP CONSTRAINT [' + @constraintName + ']');
    PRINT 'Dropped FK constraint on Appointment.conversation_id';
END;

-- 2. Xoa cot conversation_id tren Appointment neu co
IF COL_LENGTH('dbo.Appointment', 'conversation_id') IS NOT NULL
BEGIN
    ALTER TABLE Appointment DROP COLUMN conversation_id;
    PRINT 'Dropped column Appointment.conversation_id';
END;

-- 3. Xoa bang AI_Conversation cu neu ton tai
IF OBJECT_ID('dbo.AI_Conversation', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.AI_Conversation;
    PRINT 'Dropped table AI_Conversation';
END;

-- 4. Tao bang AI_Summary neu chua ton tai
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='AI_Summary' AND xtype='U')
BEGIN
    CREATE TABLE AI_Summary (
        summary_id    INT IDENTITY(1,1) PRIMARY KEY,
        patient_id    INT NOT NULL,
        appointment_id INT NULL,
        symptoms      NVARCHAR(MAX) NULL,
        chat_history  NVARCHAR(MAX) NULL,
        ai_summary    NVARCHAR(MAX) NULL,
        created_at    DATETIME DEFAULT GETDATE(),
        CONSTRAINT FK_AISummary_Patient FOREIGN KEY (patient_id)
            REFERENCES Patient(patient_id) ON DELETE CASCADE
    );
    PRINT 'Created table AI_Summary';
END
ELSE
BEGIN
    -- Them cot symptoms neu chua co
    IF COL_LENGTH('dbo.AI_Summary', 'symptoms') IS NULL
    BEGIN
        ALTER TABLE AI_Summary ADD symptoms NVARCHAR(MAX) NULL;
        PRINT 'Added column symptoms to AI_Summary';
    END;
    -- Them cot appointment_id neu chua co
    IF COL_LENGTH('dbo.AI_Summary', 'appointment_id') IS NULL
    BEGIN
        ALTER TABLE AI_Summary ADD appointment_id INT NULL;
        PRINT 'Added column appointment_id to AI_Summary';
    END;
    PRINT 'Table AI_Summary already exists - updated schema';
END;
GO

SELECT 'Done! AI_Summary table is ready.' AS Result;
