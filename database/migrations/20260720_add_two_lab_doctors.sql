SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;

-- Migration: Thêm 2 tài khoản bác sĩ phòng lab chung (không chia theo phòng phụ trách)
-- Mật khẩu mặc định cho cả 2 tài khoản là: 12345678
-- (Chuỗi Hash SHA-256: ef797c8118f02dfb649607dd5d3f8c7623048c9c063d532cc95c5ed7a898a64f)

-- 1. Bác sĩ Xét nghiệm 2
IF NOT EXISTS (SELECT 1 FROM Account WHERE email = 'lab2@diabetescare.com')
BEGIN
    INSERT INTO Account (full_name, password_hash, email, role, created_at, status)
    VALUES (N'Bác sĩ Xét nghiệm 2', 'ef797c8118f02dfb649607dd5d3f8c7623048c9c063d532cc95c5ed7a898a64f', 'lab2@diabetescare.com', 'doctor_lab', GETDATE(), 'active');

    DECLARE @AccId1 INT = SCOPE_IDENTITY();
    INSERT INTO Doctor_Lab (full_name, phone, email, lab_name, account_id)
    VALUES (N'Bác sĩ Xét nghiệm 2', '0981234567', 'lab2@diabetescare.com', N'Phòng xét nghiệm', @AccId1);
END;
GO

-- 2. Bác sĩ Xét nghiệm 3
IF NOT EXISTS (SELECT 1 FROM Account WHERE email = 'lab3@diabetescare.com')
BEGIN
    INSERT INTO Account (full_name, password_hash, email, role, created_at, status)
    VALUES (N'Bác sĩ Xét nghiệm 3', 'ef797c8118f02dfb649607dd5d3f8c7623048c9c063d532cc95c5ed7a898a64f', 'lab3@diabetescare.com', 'doctor_lab', GETDATE(), 'active');

    DECLARE @AccId2 INT = SCOPE_IDENTITY();
    INSERT INTO Doctor_Lab (full_name, phone, email, lab_name, account_id)
    VALUES (N'Bác sĩ Xét nghiệm 3', '0987654322', 'lab3@diabetescare.com', N'Phòng xét nghiệm', @AccId2);
END;
GO
