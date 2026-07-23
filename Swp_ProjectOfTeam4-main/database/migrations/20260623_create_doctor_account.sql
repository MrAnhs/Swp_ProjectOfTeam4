-- Insert a new doctor account if it doesn't exist
IF NOT EXISTS (SELECT 1 FROM Account WHERE email = 'doctor@diabetescare.com')
BEGIN
    INSERT INTO Account (full_name, password_hash, email, role, created_at, status)
    VALUES (N'Bác sĩ Nguyễn Văn A', 'f348d5628621f3d8f59c8cabda0f8eb0aa7e0514a90be7571020b1336f26c113', 'doctor@diabetescare.com', 'doctor', GETDATE(), 'active');

    DECLARE @AccountId INT = SCOPE_IDENTITY();
    
    INSERT INTO Doctor (full_name, phone, email, department, account_id)
    VALUES (N'Bác sĩ Nguyễn Văn A', '0912345678', 'doctor@diabetescare.com', N'Khoa Nội tiết', @AccountId);
END;
