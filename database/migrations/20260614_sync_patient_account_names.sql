UPDATE a
SET a.full_name = p.full_name
FROM dbo.Account a
INNER JOIN dbo.Patient p ON p.account_id = a.account_id
WHERE a.role = 'patient'
  AND (a.full_name IS NULL OR a.full_name <> p.full_name);
