SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;

-- Create Lab_Waiting_List table if it doesn't exist
IF OBJECT_ID('dbo.Lab_Waiting_List', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Lab_Waiting_List (
        waiting_id INT IDENTITY(1,1) PRIMARY KEY,
        patient_id INT NOT NULL,
        status VARCHAR(20) NOT NULL DEFAULT 'waiting', -- 'waiting', 'completed'
        created_at DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_LabWaitingList_Patient FOREIGN KEY (patient_id) REFERENCES dbo.Patient(patient_id) ON DELETE CASCADE
    );
END;

-- Seed waiting patients if the table is empty
IF NOT EXISTS (SELECT 1 FROM dbo.Lab_Waiting_List WHERE status = 'waiting')
BEGIN
    INSERT INTO dbo.Lab_Waiting_List (patient_id, status, created_at)
    VALUES 
    (2, 'waiting', DATEADD(MINUTE, -30, GETDATE())), -- Nguyễn Thị Bình
    (3, 'waiting', DATEADD(MINUTE, -15, GETDATE())), -- Trần Văn Cường
    (5, 'waiting', DATEADD(MINUTE, -5, GETDATE()));   -- Lê Thanh Hương
END;
