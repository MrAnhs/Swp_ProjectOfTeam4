SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;

-- 1. Drop old table first to make sure it's gone
IF OBJECT_ID('dbo.Lab_Waiting_List', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Lab_Waiting_List;
END;
GO

-- 2. Create the new Lab_Waiting_List table with denormalized patient attributes in its own batch
CREATE TABLE dbo.Lab_Waiting_List (
    waiting_id INT IDENTITY(1,1) PRIMARY KEY,
    patient_id INT NOT NULL,
    full_name NVARCHAR(100),
    date_of_birth DATE,
    gender NVARCHAR(50),
    phone VARCHAR(20),
    email VARCHAR(100),
    address NVARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'waiting', -- 'waiting', 'completed'
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_LabWaitingList_Patient FOREIGN KEY (patient_id) REFERENCES dbo.Patient(patient_id) ON DELETE CASCADE
);
GO

-- 3. In the final batch, clean up and re-seed all records
DECLARE @BinhId INT, @CuongId INT, @DucId INT, @HuongId INT;

SELECT @BinhId = patient_id FROM Patient WHERE email = 'binh@gmail.com';
SELECT @CuongId = patient_id FROM Patient WHERE email = 'cuong@gmail.com';
SELECT @DucId = patient_id FROM Patient WHERE email = 'duc@gmail.com';
SELECT @HuongId = patient_id FROM Patient WHERE email = 'huong@gmail.com';

-- Delete dependent test data
IF @BinhId IS NOT NULL DELETE FROM Healthy_Record WHERE patient_id = @BinhId;
IF @CuongId IS NOT NULL DELETE FROM Healthy_Record WHERE patient_id = @CuongId;
IF @DucId IS NOT NULL DELETE FROM Healthy_Record WHERE patient_id = @DucId;
IF @HuongId IS NOT NULL DELETE FROM Healthy_Record WHERE patient_id = @HuongId;

IF @BinhId IS NOT NULL DELETE FROM Medical_record WHERE patient_id = @BinhId;
IF @CuongId IS NOT NULL DELETE FROM Medical_record WHERE patient_id = @CuongId;
IF @DucId IS NOT NULL DELETE FROM Medical_record WHERE patient_id = @DucId;
IF @HuongId IS NOT NULL DELETE FROM Medical_record WHERE patient_id = @HuongId;

IF @BinhId IS NOT NULL DELETE FROM Invoice WHERE patient_id = @BinhId;
IF @CuongId IS NOT NULL DELETE FROM Invoice WHERE patient_id = @CuongId;
IF @DucId IS NOT NULL DELETE FROM Invoice WHERE patient_id = @DucId;
IF @HuongId IS NOT NULL DELETE FROM Invoice WHERE patient_id = @HuongId;

IF @BinhId IS NOT NULL DELETE FROM Appointment WHERE patient_id = @BinhId;
IF @CuongId IS NOT NULL DELETE FROM Appointment WHERE patient_id = @CuongId;
IF @DucId IS NOT NULL DELETE FROM Appointment WHERE patient_id = @DucId;
IF @HuongId IS NOT NULL DELETE FROM Appointment WHERE patient_id = @HuongId;

-- Delete from Patient & Account
DELETE FROM Patient WHERE email IN ('binh@gmail.com', 'cuong@gmail.com', 'duc@gmail.com', 'huong@gmail.com');
DELETE FROM Account WHERE email IN ('binh@gmail.com', 'cuong@gmail.com', 'duc@gmail.com', 'huong@gmail.com');

-- Seed Patient 1: Nguyễn Thị Bình
INSERT INTO Account (full_name, password_hash, email, role, created_at, status)
VALUES (N'Nguyễn Thị Bình', 'd4587ea9ead060c13fd994f21ecfa7926272a78854a2c20136b10a3c9e53e71e', 'binh@gmail.com', 'patient', GETDATE(), 'active');
DECLARE @AccId1 INT = SCOPE_IDENTITY();
INSERT INTO Patient (full_name, date_of_birth, gender, phone, email, address, account_id)
VALUES (N'Nguyễn Thị Bình', '1985-05-12', N'Nữ', '0903123456', 'binh@gmail.com', N'123 Đường Lê Lợi, TP. HCM', @AccId1);
DECLARE @PatId1 INT = SCOPE_IDENTITY();

-- Seed Patient 2: Trần Văn Cường
INSERT INTO Account (full_name, password_hash, email, role, created_at, status)
VALUES (N'Trần Văn Cường', 'd4587ea9ead060c13fd994f21ecfa7926272a78854a2c20136b10a3c9e53e71e', 'cuong@gmail.com', 'patient', GETDATE(), 'active');
DECLARE @AccId2 INT = SCOPE_IDENTITY();
INSERT INTO Patient (full_name, date_of_birth, gender, phone, email, address, account_id)
VALUES (N'Trần Văn Cường', '1972-11-23', N'Nam', '0914987654', 'cuong@gmail.com', N'456 Đường Nguyễn Trãi, Hà Nội', @AccId2);
DECLARE @PatId2 INT = SCOPE_IDENTITY();

-- Seed Patient 3: Phạm Minh Đức
INSERT INTO Account (full_name, password_hash, email, role, created_at, status)
VALUES (N'Phạm Minh Đức', 'd4587ea9ead060c13fd994f21ecfa7926272a78854a2c20136b10a3c9e53e71e', 'duc@gmail.com', 'patient', GETDATE(), 'active');
DECLARE @AccId3 INT = SCOPE_IDENTITY();
INSERT INTO Patient (full_name, date_of_birth, gender, phone, email, address, account_id)
VALUES (N'Phạm Minh Đức', '1998-02-05', N'Nam', '0985223344', 'duc@gmail.com', N'789 Đường Hùng Vương, Đà Nẵng', @AccId3);
DECLARE @PatId3 INT = SCOPE_IDENTITY();

-- Seed Patient 4: Lê Thanh Hương
INSERT INTO Account (full_name, password_hash, email, role, created_at, status)
VALUES (N'Lê Thanh Hương', 'd4587ea9ead060c13fd994f21ecfa7926272a78854a2c20136b10a3c9e53e71e', 'huong@gmail.com', 'patient', GETDATE(), 'active');
DECLARE @AccId4 INT = SCOPE_IDENTITY();
INSERT INTO Patient (full_name, date_of_birth, gender, phone, email, address, account_id)
VALUES (N'Lê Thanh Hương', '1965-09-30', N'Nữ', '0938445566', 'huong@gmail.com', N'101 Đường Trần Hưng Đạo, Cần Thơ', @AccId4);
DECLARE @PatId4 INT = SCOPE_IDENTITY();

-- Seed waiting list with matching denormalized details
INSERT INTO dbo.Lab_Waiting_List (patient_id, full_name, date_of_birth, gender, phone, email, address, status, created_at)
VALUES 
(@PatId1, N'Nguyễn Thị Bình', '1985-05-12', N'Nữ', '0903123456', 'binh@gmail.com', N'123 Đường Lê Lợi, TP. HCM', 'waiting', DATEADD(MINUTE, -30, GETDATE())),
(@PatId2, N'Trần Văn Cường', '1972-11-23', N'Nam', '0914987654', 'cuong@gmail.com', N'456 Đường Nguyễn Trãi, Hà Nội', 'waiting', DATEADD(MINUTE, -15, GETDATE())),
(@PatId4, N'Lê Thanh Hương', '1965-09-30', N'Nữ', '0938445566', 'huong@gmail.com', N'101 Đường Trần Hưng Đạo, Cần Thơ', 'waiting', DATEADD(MINUTE, -5, GETDATE()));
GO
