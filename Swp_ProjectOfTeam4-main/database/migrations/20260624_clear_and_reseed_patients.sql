SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;

-- 1. Delete dependent data
DELETE FROM Healthy_Record;
DELETE FROM Lab_Waiting_List;
DELETE FROM Medical_record;
DELETE FROM Invoice;
DELETE FROM Appointment;

-- 2. Delete all patients
DELETE FROM Patient;

-- 3. Delete accounts with role = 'patient'
DELETE FROM Account WHERE role = 'patient';

-- 4. Seed new patients & accounts
-- Password hash: 'd4587ea9ead060c13fd994f21ecfa7926272a78854a2c20136b10a3c9e53e71e' (patient123)

-- Patient 1: Phạm Hải Đăng
INSERT INTO Account (full_name, password_hash, email, role, created_at, status)
VALUES (N'Phạm Hải Đăng', 'd4587ea9ead060c13fd994f21ecfa7926272a78854a2c20136b10a3c9e53e71e', 'dang@gmail.com', 'patient', GETDATE(), 'active');
DECLARE @AccId1 INT = SCOPE_IDENTITY();
INSERT INTO Patient (full_name, date_of_birth, gender, phone, email, address, account_id)
VALUES (N'Phạm Hải Đăng', '1990-03-15', N'Nam', '0905112233', 'dang@gmail.com', N'12 Đường Hoa Hồng, Hải Phòng', @AccId1);
DECLARE @PatId1 INT = SCOPE_IDENTITY();

-- Patient 2: Lê Mỹ Linh
INSERT INTO Account (full_name, password_hash, email, role, created_at, status)
VALUES (N'Lê Mỹ Linh', 'd4587ea9ead060c13fd994f21ecfa7926272a78854a2c20136b10a3c9e53e71e', 'linh@gmail.com', 'patient', GETDATE(), 'active');
DECLARE @AccId2 INT = SCOPE_IDENTITY();
INSERT INTO Patient (full_name, date_of_birth, gender, phone, email, address, account_id)
VALUES (N'Lê Mỹ Linh', '1995-07-20', N'Nữ', '0918445566', 'linh@gmail.com', N'34 Đường Mai Đào, Hà Nội', @AccId2);
DECLARE @PatId2 INT = SCOPE_IDENTITY();

-- Patient 3: Nguyễn Hoàng Nam
INSERT INTO Account (full_name, password_hash, email, role, created_at, status)
VALUES (N'Nguyễn Hoàng Nam', 'd4587ea9ead060c13fd994f21ecfa7926272a78854a2c20136b10a3c9e53e71e', 'nam@gmail.com', 'patient', GETDATE(), 'active');
DECLARE @AccId3 INT = SCOPE_IDENTITY();
INSERT INTO Patient (full_name, date_of_birth, gender, phone, email, address, account_id)
VALUES (N'Nguyễn Hoàng Nam', '1982-12-05', N'Nam', '0987334455', 'nam@gmail.com', N'56 Đường Huỳnh Thúc Kháng, TP. HCM', @AccId3);
DECLARE @PatId3 INT = SCOPE_IDENTITY();

-- Patient 4: Vũ Thu Thảo
INSERT INTO Account (full_name, password_hash, email, role, created_at, status)
VALUES (N'Vũ Thu Thảo', 'd4587ea9ead060c13fd994f21ecfa7926272a78854a2c20136b10a3c9e53e71e', 'thao@gmail.com', 'patient', GETDATE(), 'active');
DECLARE @AccId4 INT = SCOPE_IDENTITY();
INSERT INTO Patient (full_name, date_of_birth, gender, phone, email, address, account_id)
VALUES (N'Vũ Thu Thảo', '1978-05-18', N'Nữ', '0936778899', 'thao@gmail.com', N'78 Đường Lê Lai, Đà Nẵng', @AccId4);
DECLARE @PatId4 INT = SCOPE_IDENTITY();

-- Patient 5: Trần Văn Anh
INSERT INTO Account (full_name, password_hash, email, role, created_at, status)
VALUES (N'Trần Văn Anh', 'd4587ea9ead060c13fd994f21ecfa7926272a78854a2c20136b10a3c9e53e71e', 'tran@gmail.com', 'patient', GETDATE(), 'active');
DECLARE @AccId5 INT = SCOPE_IDENTITY();
INSERT INTO Patient (full_name, date_of_birth, gender, phone, email, address, account_id)
VALUES (N'Trần Văn Anh', '1985-08-10', N'Nam', '0976112233', 'tran@gmail.com', N'45 Đường Trần Hưng Đạo, Hà Nội', @AccId5);
DECLARE @PatId5 INT = SCOPE_IDENTITY();

-- Patient 6: Nguyễn Thị Bình
INSERT INTO Account (full_name, password_hash, email, role, created_at, status)
VALUES (N'Nguyễn Thị Bình', 'd4587ea9ead060c13fd994f21ecfa7926272a78854a2c20136b10a3c9e53e71e', 'binh@gmail.com', 'patient', GETDATE(), 'active');
DECLARE @AccId6 INT = SCOPE_IDENTITY();
INSERT INTO Patient (full_name, date_of_birth, gender, phone, email, address, account_id)
VALUES (N'Nguyễn Thị Bình', '1992-04-25', N'Nữ', '0945223344', 'binh@gmail.com', N'78 Đường Lý Tự Trọng, TP. HCM', @AccId6);
DECLARE @PatId6 INT = SCOPE_IDENTITY();

-- Patient 7: Hoàng Quốc Cường
INSERT INTO Account (full_name, password_hash, email, role, created_at, status)
VALUES (N'Hoàng Quốc Cường', 'd4587ea9ead060c13fd994f21ecfa7926272a78854a2c20136b10a3c9e53e71e', 'cuong@gmail.com', 'patient', GETDATE(), 'active');
DECLARE @AccId7 INT = SCOPE_IDENTITY();
INSERT INTO Patient (full_name, date_of_birth, gender, phone, email, address, account_id)
VALUES (N'Hoàng Quốc Cường', '1970-11-30', N'Nam', '0912334455', 'cuong@gmail.com', N'12 Đường Hùng Vương, Huế', @AccId7);
DECLARE @PatId7 INT = SCOPE_IDENTITY();

-- Patient 8: Đỗ Thu Hương
INSERT INTO Account (full_name, password_hash, email, role, created_at, status)
VALUES (N'Đỗ Thu Hương', 'd4587ea9ead060c13fd994f21ecfa7926272a78854a2c20136b10a3c9e53e71e', 'huong@gmail.com', 'patient', GETDATE(), 'active');
DECLARE @AccId8 INT = SCOPE_IDENTITY();
INSERT INTO Patient (full_name, date_of_birth, gender, phone, email, address, account_id)
VALUES (N'Đỗ Thu Hương', '1988-09-05', N'Nữ', '0988445566', 'huong@gmail.com', N'89 Đường Lê Lợi, Nha Trang', @AccId8);
DECLARE @PatId8 INT = SCOPE_IDENTITY();

-- 5. Seed waitlist with active 'waiting' entries for these new patients
INSERT INTO dbo.Lab_Waiting_List (patient_id, full_name, date_of_birth, gender, phone, email, address, status, created_at, lab_room)
VALUES 
(@PatId1, N'Phạm Hải Đăng', '1990-03-15', N'Nam', '0905112233', 'dang@gmail.com', N'12 Đường Hoa Hồng, Hải Phòng', 'waiting', DATEADD(MINUTE, -30, GETDATE()), N'phòng xét nghiệm máu'),
(@PatId2, N'Lê Mỹ Linh', '1995-07-20', N'Nữ', '0918445566', 'linh@gmail.com', N'34 Đường Mai Đào, Hà Nội', 'waiting', DATEADD(MINUTE, -20, GETDATE()), N'phòng xét nghiệm nước tiểu'),
(@PatId3, N'Nguyễn Hoàng Nam', '1982-12-05', N'Nam', '0987334455', 'nam@gmail.com', N'56 Đường Huỳnh Thúc Kháng, TP. HCM', 'waiting', DATEADD(MINUTE, -10, GETDATE()), N'phòng xét nghiệm máu'),
(@PatId4, N'Vũ Thu Thảo', '1978-05-18', N'Nữ', '0936778899', 'thao@gmail.com', N'78 Đường Lê Lai, Đà Nẵng', 'waiting', DATEADD(MINUTE, -5, GETDATE()), N'phòng xét nghiệm máu'),
(@PatId5, N'Trần Văn Anh', '1985-08-10', N'Nam', '0976112233', 'tran@gmail.com', N'45 Đường Trần Hưng Đạo, Hà Nội', 'waiting', DATEADD(MINUTE, -25, GETDATE()), N'phòng xét nghiệm máu'),
(@PatId6, N'Nguyễn Thị Bình', '1992-04-25', N'Nữ', '0945223344', 'binh@gmail.com', N'78 Đường Lý Tự Trọng, TP. HCM', 'waiting', DATEADD(MINUTE, -15, GETDATE()), N'phòng xét nghiệm máu'),
(@PatId7, N'Hoàng Quốc Cường', '1970-11-30', N'Nam', '0912334455', 'cuong@gmail.com', N'12 Đường Hùng Vương, Huế', 'waiting', DATEADD(MINUTE, -8, GETDATE()), N'phòng xét nghiệm máu'),
(@PatId8, N'Đỗ Thu Hương', '1988-09-05', N'Nữ', '0988445566', 'huong@gmail.com', N'89 Đường Lê Lợi, Nha Trang', 'waiting', DATEADD(MINUTE, -3, GETDATE()), N'phòng xét nghiệm nước tiểu');
