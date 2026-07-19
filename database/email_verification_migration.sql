SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('dbo.Email_Verification', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Email_Verification (
        verification_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        account_id INT NULL,
        purpose VARCHAR(30) NOT NULL,
        target_email VARCHAR(255) NOT NULL,
        otp_hash VARCHAR(255) NOT NULL,
        expires_at DATETIME2 NOT NULL,
        failed_attempts INT NOT NULL CONSTRAINT DF_EmailVerification_FailedAttempts DEFAULT 0,
        consumed_at DATETIME2 NULL,
        created_at DATETIME2 NOT NULL CONSTRAINT DF_EmailVerification_CreatedAt DEFAULT GETDATE(),
        CONSTRAINT FK_EmailVerification_Account FOREIGN KEY (account_id)
            REFERENCES dbo.Account(account_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = 'CK_EmailVerification_Purpose'
      AND parent_object_id = OBJECT_ID('dbo.Email_Verification')
)
BEGIN
    ALTER TABLE dbo.Email_Verification ADD CONSTRAINT CK_EmailVerification_Purpose
        CHECK (purpose IN ('CHANGE_EMAIL', 'RESET_PASSWORD'));
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_EmailVerification_Target_Purpose_Created'
      AND object_id = OBJECT_ID('dbo.Email_Verification')
)
BEGIN
    CREATE INDEX IX_EmailVerification_Target_Purpose_Created
        ON dbo.Email_Verification (target_email, purpose, created_at DESC)
        INCLUDE (account_id, otp_hash, expires_at, failed_attempts, consumed_at);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_EmailVerification_Account_Purpose_Created'
      AND object_id = OBJECT_ID('dbo.Email_Verification')
)
BEGIN
    CREATE INDEX IX_EmailVerification_Account_Purpose_Created
        ON dbo.Email_Verification (account_id, purpose, created_at DESC);
END;
GO
