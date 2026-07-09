SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

DECLARE @password_hash VARCHAR(64) = 'd9b5f58f0b38198293971865a14074f59eba3e82595becbe86ae51f1d9f1f65e'; -- Test123
DECLARE @adminAccountId INT;
DECLARE @receptionAccountId INT;
DECLARE @doctorAccountId INT;
DECLARE @patientAccountId INT;
DECLARE @labAccountId INT;
DECLARE @doctorId INT;
DECLARE @patientId INT;
DECLARE @scheduleId INT;

IF EXISTS (SELECT 1 FROM dbo.Account WHERE LOWER(email) = 'admin.test@diabetes.local')
BEGIN
    UPDATE dbo.Account
    SET full_name = N'Admin Test',
        password_hash = @password_hash,
        role = 'Admin',
        status = 'Active'
    WHERE LOWER(email) = 'admin.test@diabetes.local';
END
ELSE
BEGIN
    INSERT INTO dbo.Account (full_name, password_hash, email, role, status, created_at)
    VALUES (N'Admin Test', @password_hash, 'admin.test@diabetes.local', 'Admin', 'Active', GETDATE());
END;

IF EXISTS (SELECT 1 FROM dbo.Account WHERE LOWER(email) = 'reception.test@diabetes.local')
BEGIN
    UPDATE dbo.Account
    SET full_name = N'Receptionist Test',
        password_hash = @password_hash,
        role = 'Receptionist',
        status = 'Active'
    WHERE LOWER(email) = 'reception.test@diabetes.local';
END
ELSE
BEGIN
    INSERT INTO dbo.Account (full_name, password_hash, email, role, status, created_at)
    VALUES (N'Receptionist Test', @password_hash, 'reception.test@diabetes.local', 'Receptionist', 'Active', GETDATE());
END;

IF EXISTS (SELECT 1 FROM dbo.Account WHERE LOWER(email) = 'doctor.test@diabetes.local')
BEGIN
    UPDATE dbo.Account
    SET full_name = N'Doctor Test',
        password_hash = @password_hash,
        role = 'Doctor',
        status = 'Active'
    WHERE LOWER(email) = 'doctor.test@diabetes.local';
END
ELSE
BEGIN
    INSERT INTO dbo.Account (full_name, password_hash, email, role, status, created_at)
    VALUES (N'Doctor Test', @password_hash, 'doctor.test@diabetes.local', 'Doctor', 'Active', GETDATE());
END;

SELECT @doctorAccountId = account_id
FROM dbo.Account
WHERE LOWER(email) = 'doctor.test@diabetes.local';

IF NOT EXISTS (SELECT 1 FROM dbo.Doctor WHERE account_id = @doctorAccountId)
BEGIN
    INSERT INTO dbo.Doctor (full_name, phone, email, department, account_id)
    VALUES (N'Doctor Test', '0901000003', 'doctor.test@diabetes.local', N'Khoa Nội tổng hợp', @doctorAccountId);
END
ELSE
BEGIN
    UPDATE dbo.Doctor
    SET full_name = N'Doctor Test',
        phone = '0901000003',
        email = 'doctor.test@diabetes.local',
        department = N'Khoa Nội tổng hợp'
    WHERE account_id = @doctorAccountId;
END;

SELECT @doctorId = doctor_id
FROM dbo.Doctor
WHERE account_id = @doctorAccountId;

IF EXISTS (SELECT 1 FROM dbo.Account WHERE LOWER(email) = 'patient.test@diabetes.local')
BEGIN
    UPDATE dbo.Account
    SET full_name = N'Patient Test',
        password_hash = @password_hash,
        role = 'Patient',
        status = 'Active'
    WHERE LOWER(email) = 'patient.test@diabetes.local';
END
ELSE
BEGIN
    INSERT INTO dbo.Account (full_name, password_hash, email, role, status, created_at)
    VALUES (N'Patient Test', @password_hash, 'patient.test@diabetes.local', 'Patient', 'Active', GETDATE());
END;

SELECT @patientAccountId = account_id
FROM dbo.Account
WHERE LOWER(email) = 'patient.test@diabetes.local';

IF NOT EXISTS (SELECT 1 FROM dbo.Patient WHERE account_id = @patientAccountId)
BEGIN
    INSERT INTO dbo.Patient (full_name, date_of_birth, gender, phone, email, address, account_id)
    VALUES (N'Patient Test', '1995-01-01', N'Nam', '0911000003', 'patient.test@diabetes.local', N'Địa chỉ test', @patientAccountId);
END
ELSE
BEGIN
    UPDATE dbo.Patient
    SET full_name = N'Patient Test',
        date_of_birth = '1995-01-01',
        gender = N'Nam',
        phone = '0911000003',
        email = 'patient.test@diabetes.local',
        address = N'Địa chỉ test'
    WHERE account_id = @patientAccountId;
END;

SELECT @patientId = patient_id
FROM dbo.Patient
WHERE account_id = @patientAccountId;

IF EXISTS (SELECT 1 FROM dbo.Account WHERE LOWER(email) = 'lab.test@diabetes.local')
BEGIN
    UPDATE dbo.Account
    SET full_name = N'Laboratory Test',
        password_hash = @password_hash,
        role = 'Laboratory',
        status = 'Active'
    WHERE LOWER(email) = 'lab.test@diabetes.local';
END
ELSE
BEGIN
    INSERT INTO dbo.Account (full_name, password_hash, email, role, status, created_at)
    VALUES (N'Laboratory Test', @password_hash, 'lab.test@diabetes.local', 'Laboratory', 'Active', GETDATE());
END;

IF @doctorId IS NOT NULL AND @patientId IS NOT NULL
BEGIN
    SELECT TOP 1 @scheduleId = schedule_id
    FROM dbo.Doctor_Schedule
    WHERE doctor_id = @doctorId
      AND work_date = CAST(GETDATE() AS date)
      AND time_slot = '08:00-11:30'
    ORDER BY schedule_id DESC;

    IF @scheduleId IS NULL
    BEGIN
        INSERT INTO dbo.Doctor_Schedule (doctor_id, work_date, time_slot, max_patients, status)
        VALUES (@doctorId, CAST(GETDATE() AS date), '08:00-11:30', 12, 'Available');

        SET @scheduleId = SCOPE_IDENTITY();
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.Appointment
        WHERE patient_id = @patientId
          AND doctor_id = @doctorId
          AND schedule_id = @scheduleId
          AND status IN ('Waiting', 'Checked_In', 'In_Progress')
    )
    BEGIN
        INSERT INTO dbo.Appointment
            (patient_id, doctor_id, schedule_id, appointment_time, booking_type, queue_number, status, created_at)
        VALUES
            (@patientId, @doctorId, @scheduleId,
             DATEADD(HOUR, 8, CAST(CAST(GETDATE() AS date) AS datetime)),
             'At_Counter', 1, 'Waiting', GETDATE());
    END;
END;

COMMIT TRANSACTION;
