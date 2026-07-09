IF EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE name = 'CK_Appointment_Status'
      AND parent_object_id = OBJECT_ID('dbo.Appointment')
)
BEGIN
    ALTER TABLE [dbo].[Appointment] DROP CONSTRAINT [CK_Appointment_Status];
END
GO

ALTER TABLE [dbo].[Appointment] WITH CHECK ADD CONSTRAINT [CK_Appointment_Status]
CHECK (([status]='Absent' OR [status]='Cancelled' OR [status]='Completed'
    OR [status]='In_Progress' OR [status]='Waiting'));
GO

ALTER TABLE [dbo].[Appointment] CHECK CONSTRAINT [CK_Appointment_Status];
GO
