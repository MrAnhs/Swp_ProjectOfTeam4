-- Update CK_Account_Role constraint to allow 'doctor_lab' role
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Account_Role')
BEGIN
    ALTER TABLE Account DROP CONSTRAINT CK_Account_Role;
END;

ALTER TABLE Account ADD CONSTRAINT CK_Account_Role CHECK ([role]='Admin' OR [role]='Receptionist' OR [role]='Doctor' OR [role]='Patient' OR [role]='doctor_lab');

-- Create Doctor_Lab table if it doesn't exist
IF OBJECT_ID('dbo.Doctor_Lab', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Doctor_Lab (
        lab_id INT IDENTITY(1,1) PRIMARY KEY,
        full_name NVARCHAR(100) NOT NULL,
        phone VARCHAR(20),
        email VARCHAR(100),
        lab_name NVARCHAR(100),
        account_id INT NOT NULL,
        CONSTRAINT FK_DoctorLab_Account FOREIGN KEY (account_id) REFERENCES dbo.Account(account_id) ON DELETE CASCADE
    );
END;

-- Insert default laboratory doctor account if it doesn't exist
IF NOT EXISTS (SELECT 1 FROM Account WHERE email = 'lab@diabetescare.com')
BEGIN
    INSERT INTO Account (full_name, password_hash, email, role, created_at, status)
    VALUES (N'Bác sĩ Xét nghiệm B', '3705b578e8fcb1b82a94ad917881ec248bbd4111645e91aed3c19af12d82116f', 'lab@diabetescare.com', 'doctor_lab', GETDATE(), 'active');

    DECLARE @AccountId INT = SCOPE_IDENTITY();
    
    INSERT INTO Doctor_Lab (full_name, phone, email, lab_name, account_id)
    VALUES (N'Bác sĩ Xét nghiệm B', '0987654321', 'lab@diabetescare.com', N'Phòng Xét nghiệm Hóa sinh', @AccountId);
END;
