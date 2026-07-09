SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;

-- Fix encoding errors in database records

UPDATE Account SET full_name = N'Bác sĩ Nguyễn Văn A' WHERE account_id = 2;
UPDATE Doctor SET full_name = N'Bác sĩ Nguyễn Văn A', department = N'Khoa Nội tiết' WHERE doctor_id = 1;

UPDATE Account SET full_name = N'Bác sĩ Xét nghiệm B' WHERE account_id = 4;
UPDATE Doctor_Lab SET full_name = N'Bác sĩ Xét nghiệm B', lab_name = N'Phòng Xét nghiệm Hóa sinh' WHERE lab_id = 2;
