/* Run once on the Project database. */
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH('dbo.Notification', 'TargetUrl') IS NULL
BEGIN
    ALTER TABLE dbo.Notification ADD TargetUrl NVARCHAR(500) NULL;
END;
GO

IF COL_LENGTH('dbo.Notification', 'EventKey') IS NULL
BEGIN
    ALTER TABLE dbo.Notification ADD EventKey NVARCHAR(150) NULL;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Notification_Account_Read_Created'
      AND object_id = OBJECT_ID('dbo.Notification')
)
BEGIN
    CREATE INDEX IX_Notification_Account_Read_Created
        ON dbo.Notification (AccountID, IsRead, CreatedAt DESC, NotificationID DESC);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'UX_Notification_Account_EventKey'
      AND object_id = OBJECT_ID('dbo.Notification')
)
BEGIN
    CREATE UNIQUE INDEX UX_Notification_Account_EventKey
        ON dbo.Notification (AccountID, EventKey)
        WHERE EventKey IS NOT NULL;
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Room WHERE room_id = 'LAB01')
BEGIN
    INSERT INTO dbo.Room (room_id, room_name, location, status)
    VALUES ('LAB01', N'Ph' + NCHAR(242) + N'ng x' + NCHAR(233) + N't nghi' + NCHAR(7879) + N'm 1',
            N'T' + NCHAR(7847) + N'ng 2 - Khu x' + NCHAR(233) + N't nghi' + NCHAR(7879) + N'm', 'Active');
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Room WHERE room_id = 'LAB02')
BEGIN
    INSERT INTO dbo.Room (room_id, room_name, location, status)
    VALUES ('LAB02', N'Ph' + NCHAR(242) + N'ng x' + NCHAR(233) + N't nghi' + NCHAR(7879) + N'm 2',
            N'T' + NCHAR(7847) + N'ng 2 - Khu x' + NCHAR(233) + N't nghi' + NCHAR(7879) + N'm', 'Active');
END;
GO

UPDATE dbo.Room SET
    room_name = N'Ph' + NCHAR(242) + N'ng x' + NCHAR(233) + N't nghi' + NCHAR(7879) + N'm '
        + RIGHT(room_id, 1),
    location = N'T' + NCHAR(7847) + N'ng 2 - Khu x' + NCHAR(233) + N't nghi' + NCHAR(7879) + N'm'
WHERE room_id IN ('LAB01', 'LAB02');
GO

UPDATE id SET id.lab_status = 'Requested',
    id.requested_at = COALESCE(id.requested_at, GETDATE())
FROM dbo.Invoice_Detail id
JOIN dbo.Invoice i ON i.invoice_id = id.invoice_id
JOIN dbo.Medical_Service ms ON ms.service_id = id.service_id
WHERE i.status = 'Paid'
  AND ms.service_type = 'Lab_Test'
  AND (id.lab_status IS NULL OR id.lab_status = 'Waiting_Payment');
GO

INSERT INTO dbo.Lab_Order
    (order_id, appointment_id, patient_id, room_id, service_id, lab_id, status, created_at)
SELECT CONCAT('LAB-', id.invoice_detail_id), id.appointment_id, i.patient_id,
    (SELECT TOP 1 r.room_id
     FROM dbo.Room r
     WHERE r.status = 'Active'
       AND (r.room_id LIKE 'LAB%' OR r.room_name LIKE N'%xét nghiệm%')
     ORDER BY r.room_id),
    id.service_id, NULL,
    CASE WHEN id.lab_status = 'Completed' THEN 'Completed'
         WHEN id.lab_status = 'Processing' THEN 'Processing'
         ELSE 'Requested' END,
    COALESCE(id.requested_at, GETDATE())
FROM dbo.Invoice_Detail id
JOIN dbo.Invoice i ON i.invoice_id = id.invoice_id
JOIN dbo.Medical_Service ms ON ms.service_id = id.service_id
WHERE i.status = 'Paid'
  AND ms.service_type = 'Lab_Test'
  AND id.appointment_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM dbo.Lab_Order lo
      WHERE lo.order_id = CONCAT('LAB-', id.invoice_detail_id)
  );
GO
