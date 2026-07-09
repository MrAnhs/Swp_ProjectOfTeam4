# Test Accounts

These accounts are for local testing only.

## Accounts already visible in `database/project_SWP_dump.sql`

| Role | Email | Password | Note |
| --- | --- | --- | --- |
| Doctor | `bs.a@hospital.com` | `hash_123` | Seeded in the final dump |
| Doctor | `bs.b@hospital.com` | `hash_123` | Seeded in the final dump |

`hash_123` is the literal password for these two rows because it is not a SHA-256 value.

## Recommended accounts to seed

Run `database/seed_test_accounts.sql` to create/update these accounts:

| Role | Email | Password |
| --- | --- | --- |
| Admin | `admin.test@diabetes.local` | `Test123` |
| Receptionist | `reception.test@diabetes.local` | `Test123` |
| Doctor | `doctor.test@diabetes.local` | `Test123` |
| Patient | `patient.test@diabetes.local` | `Test123` |
| Laboratory | `lab.test@diabetes.local` | `Test123` |

After login, the app now redirects automatically from the role stored in `Account.role`.
