SET NOCOUNT ON;

/*
    Admin module merge migration.

    Purpose:
    - Add schema pieces used by the Admin module imported from s-coms.
    - Keep the SWP_Project convention for missed appointments: Absent.
    - Keep the script idempotent so it can be rerun safely.
*/

IF COL_LENGTH('dbo.Doctor_Schedule', 'online_quota') IS NULL
BEGIN
    ALTER TABLE dbo.Doctor_Schedule ADD online_quota INT NULL;
END;

EXEC sp_executesql N'
UPDATE dbo.Doctor_Schedule
SET online_quota =
    CASE
        WHEN max_patients <= 1 THEN max_patients
        WHEN CEILING(max_patients * 0.6) >= max_patients THEN max_patients - 1
        ELSE CAST(CEILING(max_patients * 0.6) AS INT)
    END
;
';

IF COL_LENGTH('dbo.Appointment', 'booking_source') IS NULL
BEGIN
    ALTER TABLE dbo.Appointment ADD booking_source NVARCHAR(30) NULL;
END;

EXEC sp_executesql N'
UPDATE dbo.Appointment
SET booking_source =
    CASE
        WHEN booking_type = ''Online'' THEN ''Online''
        WHEN booking_type = ''At_Counter'' THEN ''Counter''
        ELSE ''Online''
    END
WHERE booking_source IS NULL;
';

IF COL_LENGTH('dbo.Appointment', 'consultation_start_time') IS NULL
BEGIN
    ALTER TABLE dbo.Appointment ADD consultation_start_time DATETIME2 NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_Appointment_ConsultationStartTime'
      AND object_id = OBJECT_ID('dbo.Appointment')
)
BEGIN
    EXEC sp_executesql N'CREATE INDEX IX_Appointment_ConsultationStartTime
    ON dbo.Appointment (consultation_start_time);';
END;

DECLARE @appointmentTableId INT = OBJECT_ID(N'dbo.Appointment');
IF @appointmentTableId IS NOT NULL
BEGIN
    DECLARE @dropAppointmentStatusSql NVARCHAR(MAX) = N'';

    SELECT @dropAppointmentStatusSql = @dropAppointmentStatusSql
        + N'ALTER TABLE dbo.Appointment DROP CONSTRAINT [' + cc.name + N'];' + CHAR(10)
    FROM sys.check_constraints cc
    WHERE cc.parent_object_id = @appointmentTableId
      AND LOWER(cc.definition) LIKE '%status%';

    IF @dropAppointmentStatusSql <> N''
    BEGIN
        EXEC sp_executesql @dropAppointmentStatusSql;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM sys.check_constraints
        WHERE parent_object_id = @appointmentTableId
          AND name = N'CK_Appointment_Status'
    )
    BEGIN
        ALTER TABLE dbo.Appointment WITH CHECK
        ADD CONSTRAINT CK_Appointment_Status
        CHECK ([status] IN ('Waiting', 'Checked_In', 'In_Progress', 'Completed', 'Absent', 'Cancelled'));
    END;
END;

DECLARE @doctorScheduleTableId INT = OBJECT_ID(N'dbo.Doctor_Schedule');
IF @doctorScheduleTableId IS NOT NULL
BEGIN
    DECLARE @dropScheduleStatusSql NVARCHAR(MAX) = N'';

    SELECT @dropScheduleStatusSql = @dropScheduleStatusSql
        + N'ALTER TABLE dbo.Doctor_Schedule DROP CONSTRAINT [' + cc.name + N'];' + CHAR(10)
    FROM sys.check_constraints cc
    WHERE cc.parent_object_id = @doctorScheduleTableId
      AND LOWER(cc.definition) LIKE '%status%';

    IF @dropScheduleStatusSql <> N''
    BEGIN
        EXEC sp_executesql @dropScheduleStatusSql;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM sys.check_constraints
        WHERE parent_object_id = @doctorScheduleTableId
          AND name = N'CK_DoctorSchedule_Status'
    )
    BEGIN
        ALTER TABLE dbo.Doctor_Schedule WITH CHECK
        ADD CONSTRAINT CK_DoctorSchedule_Status
        CHECK ([status] IN ('Available', 'Full', 'Cancelled', 'Expired'));
    END;
END;

