SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;

-- 1. Add lab_room column to Lab_Waiting_List if it doesn't exist
IF COL_LENGTH('dbo.Lab_Waiting_List', 'lab_room') IS NULL
BEGIN
    ALTER TABLE dbo.Lab_Waiting_List ADD lab_room NVARCHAR(100) NULL;
END;
GO

-- 2. Update existing waitlist records to assign to specific rooms
UPDATE dbo.Lab_Waiting_List SET lab_room = N'phòng xét nghiệm máu' WHERE patient_id = (SELECT patient_id FROM Patient WHERE email = 'binh@gmail.com');
UPDATE dbo.Lab_Waiting_List SET lab_room = N'phòng xét nghiệm chức năng thận' WHERE patient_id = (SELECT patient_id FROM Patient WHERE email = 'cuong@gmail.com');
UPDATE dbo.Lab_Waiting_List SET lab_room = N'phòng xét nghiệm nước tiểu' WHERE patient_id = (SELECT patient_id FROM Patient WHERE email = 'huong@gmail.com');

-- 3. Add a patient to waitlist for Liver test (Gan) if not already exists
DECLARE @PatId3 INT;
SELECT @PatId3 = patient_id FROM Patient WHERE email = 'duc@gmail.com';
IF @PatId3 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Lab_Waiting_List WHERE patient_id = @PatId3 AND status = 'waiting')
BEGIN
    INSERT INTO dbo.Lab_Waiting_List (patient_id, full_name, date_of_birth, gender, phone, email, address, status, created_at, lab_room)
    VALUES (@PatId3, N'Phạm Minh Đức', '1998-02-05', N'Nam', '0985223344', 'duc@gmail.com', N'789 Đường Hùng Vương, Hà Nội', 'waiting', DATEADD(MINUTE, -10, GETDATE()), N'phòng xét nghiệm chức năng gan');
END;
GO

-- 4. Seed account for Blood Lab Doctor
IF NOT EXISTS (SELECT 1 FROM Account WHERE email = 'lab_mau@diabetescare.com')
BEGIN
    INSERT INTO Account (full_name, password_hash, email, role, created_at, status)
    VALUES (N'Bác sĩ Xét nghiệm Máu', '3705b578e8fcb1b82a94ad917881ec248bbd4111645e91aed3c19af12d82116f', 'lab_mau@diabetescare.com', 'doctor_lab', GETDATE(), 'active');

    DECLARE @AccId1 INT = SCOPE_IDENTITY();
    INSERT INTO Doctor_Lab (full_name, phone, email, lab_name, account_id)
    VALUES (N'Bác sĩ Xét nghiệm Máu', '0987654321', 'lab_mau@diabetescare.com', N'Phòng Xét nghiệm Máu', @AccId1);
END;
GO

-- 5. Seed account for Kidney Lab Doctor
IF NOT EXISTS (SELECT 1 FROM Account WHERE email = 'lab_than@diabetescare.com')
BEGIN
    INSERT INTO Account (full_name, password_hash, email, role, created_at, status)
    VALUES (N'Bác sĩ Xét nghiệm Thận', '3705b578e8fcb1b82a94ad917881ec248bbd4111645e91aed3c19af12d82116f', 'lab_than@diabetescare.com', 'doctor_lab', GETDATE(), 'active');

    DECLARE @AccId2 INT = SCOPE_IDENTITY();
    INSERT INTO Doctor_Lab (full_name, phone, email, lab_name, account_id)
    VALUES (N'Bác sĩ Xét nghiệm Thận', '0987654321', 'lab_than@diabetescare.com', N'Phòng Xét nghiệm Chức năng Thận', @AccId2);
END;
GO

-- 6. Seed account for Liver Lab Doctor
IF NOT EXISTS (SELECT 1 FROM Account WHERE email = 'lab_gan@diabetescare.com')
BEGIN
    INSERT INTO Account (full_name, password_hash, email, role, created_at, status)
    VALUES (N'Bác sĩ Xét nghiệm Gan', '3705b578e8fcb1b82a94ad917881ec248bbd4111645e91aed3c19af12d82116f', 'lab_gan@diabetescare.com', 'doctor_lab', GETDATE(), 'active');

    DECLARE @AccId3 INT = SCOPE_IDENTITY();
    INSERT INTO Doctor_Lab (full_name, phone, email, lab_name, account_id)
    VALUES (N'Bác sĩ Xét nghiệm Gan', '0987654321', 'lab_gan@diabetescare.com', N'Phòng Xét nghiệm Chức năng Gan', @AccId3);
END;
GO

-- 7. Seed account for Urine Lab Doctor
IF NOT EXISTS (SELECT 1 FROM Account WHERE email = 'lab_nuoctieu@diabetescare.com')
BEGIN
    INSERT INTO Account (full_name, password_hash, email, role, created_at, status)
    VALUES (N'Bác sĩ Xét nghiệm Nước tiểu', '3705b578e8fcb1b82a94ad917881ec248bbd4111645e91aed3c19af12d82116f', 'lab_nuoctieu@diabetescare.com', 'doctor_lab', GETDATE(), 'active');

    DECLARE @AccId4 INT = SCOPE_IDENTITY();
    INSERT INTO Doctor_Lab (full_name, phone, email, lab_name, account_id)
    VALUES (N'Bác sĩ Xét nghiệm Nước tiểu', '0987654321', 'lab_nuoctieu@diabetescare.com', N'Phòng Xét nghiệm Nước tiểu', @AccId4);
END;
GO
