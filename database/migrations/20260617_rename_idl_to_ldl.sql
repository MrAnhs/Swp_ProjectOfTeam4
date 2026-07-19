IF COL_LENGTH('Healthy_Record', 'idl') IS NOT NULL
   AND COL_LENGTH('Healthy_Record', 'ldl') IS NULL
BEGIN
    EXEC sp_rename 'Healthy_Record.idl', 'ldl', 'COLUMN';
END;
