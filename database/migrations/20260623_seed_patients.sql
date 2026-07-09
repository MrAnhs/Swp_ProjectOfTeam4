SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;

-- Seed Patient 1 (if doesn't exist)
IF NOT EXISTS (SELECT 1 FROM Account WHERE email = 'binh@gmail.com')
BEGIN
    INSERT INTO Account (full_name, password_hash, email, role, created_at, status)
    VALUES (N'Nguyễn Thị Bình', 'd4587ea9ead060c13fd994f21ecfa7926272a78854a2c20136b10a3c9e53e71e', 'binh@gmail.com', 'patient', GETDATE(), 'active');
    
    DECLARE @AccId1 INT = SCOPE_IDENTITY();
    INSERT INTO Patient (full_name, date_of_birth, gender, phone, email, address, account_id)
    VALUES (N'Nguyễn Thị Bình', '1985-05-12', N'Nữ', '0903123456', 'binh@gmail.com', N'123 Đường Lê Lợi, TP. HCM', @AccId1);
END;

-- Seed Patient 2
IF NOT EXISTS (SELECT 1 FROM Account WHERE email = 'cuong@gmail.com')
BEGIN
    INSERT INTO Account (full_name, password_hash, email, role, created_at, status)
    VALUES (N'Trần Văn Cường', 'd4587ea9ead060c13fd994f21ecfa7926272a78854a2c20136b10a3c9e53e71e', 'cuong@gmail.com', 'patient', GETDATE(), 'active');
    
    DECLARE @AccId2 INT = SCOPE_IDENTITY();
    INSERT INTO Patient (full_name, date_of_birth, gender, phone, email, address, account_id)
    VALUES (N'Trần Văn Cường', '1972-11-23', N'Nam', '0914987654', 'cuong@gmail.com', N'456 Đường Nguyễn Trãi, Hà Nội', @AccId2);
END;

-- Seed Patient 3
IF NOT EXISTS (SELECT 1 FROM Account WHERE email = 'duc@gmail.com')
BEGIN
    INSERT INTO Account (full_name, password_hash, email, role, created_at, status)
    VALUES (N'Phạm Minh Đức', 'd4587ea9ead060c13fd994f21ecfa7926272a78854a2c20136b10a3c9e53e71e', 'duc@gmail.com', 'patient', GETDATE(), 'active');
    
    DECLARE @AccId3 INT = SCOPE_IDENTITY();
    INSERT INTO Patient (full_name, date_of_birth, gender, phone, email, address, account_id)
    VALUES (N'Phạm Minh Đức', '1998-02-05', N'Nam', '0985223344', 'duc@gmail.com', N'789 Đường Hùng Vương, Đà Nẵng', @AccId3);
END;

-- Seed Patient 4
IF NOT EXISTS (SELECT 1 FROM Account WHERE email = 'huong@gmail.com')
BEGIN
    INSERT INTO Account (full_name, password_hash, email, role, created_at, status)
    VALUES (N'Lê Thanh Hương', 'd4587ea9ead060c13fd994f21ecfa7926272a78854a2c20136b10a3c9e53e71e', 'huong@gmail.com', 'patient', GETDATE(), 'active');
    
    DECLARE @AccId4 INT = SCOPE_IDENTITY();
    INSERT INTO Patient (full_name, date_of_birth, gender, phone, email, address, account_id)
    VALUES (N'Lê Thanh Hương', '1965-09-30', N'Nữ', '0938445566', 'huong@gmail.com', N'101 Đường Trần Hưng Đạo, Cần Thơ', @AccId4);
END;
