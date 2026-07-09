IF COL_LENGTH('dbo.Healthy_Record', 'cr') IS NOT NULL
BEGIN
    ALTER TABLE dbo.Healthy_Record
        ALTER COLUMN cr DECIMAL(6, 2) NULL;
END;
