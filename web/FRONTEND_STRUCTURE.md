# Frontend structure

The frontend is organized by responsibility and role.

```text
web/
├── assets/
│   ├── css/
│   │   ├── base/
│   │   ├── components/
│   │   ├── layouts/
│   │   └── pages/{public,patient,doctor,admin,receptionist}/
│   └── js/
│       ├── core/
│       ├── components/
│       └── pages/{public,patient,doctor,admin,receptionist}/
└── WEB-INF/views/{components,patient,doctor,admin,receptionist,errors}/
```

## Rules

- JSP files contain markup and server-rendered values only.
- Page-specific CSS and JavaScript live under `assets/*/pages/<role>`.
- Reusable UI behavior lives under `assets/js/components`.
- HTTP requests use `ApiClient`; do not hard-code the deployed context path.
- Shared role components use JSP fragments under `WEB-INF/views/components`.
- All protected role pages must be placed under `WEB-INF/views` and reached through a servlet controller.
- Public URLs use role routes such as `/patient/dashboard`, `/doctor/dashboard`, `/receptionist/dashboard`, and `/admin/dashboard`; never link directly to role JSP files.

## Patient routes

- `/patient/dashboard`: summary and shortcuts only.
- `/patient/appointments/new`: filter available doctors by date, session, and name, then book an available slot.
- `/patient/appointments`: view the patient's appointments.
- `/patient/appointments/detail?id={id}`: view appointment details and start appointment chat.
- `/patient/invoices`: view invoices and payment status.
- `/patient/invoices/detail?id={id}`: view services and submit a payment method.
- `/patient/history`: browse examination history.
- `/patient/history/detail?id={appointmentId}`: view released diagnosis and test results.
- `/patient/ai-chat?appointmentId={id}`: chat in the context of an appointment.
- `/patient/profile`: update personal information.
- Dynamic text must use `textContent`; sanitize any content that must be rendered as HTML.

## Doctor routes

- `/doctor/dashboard`: overview dashboard, active queue metrics, shift handover history, and quick action shortcuts.
- `/doctor/general-examinations`: list of patients waiting for general physical examination and initial laboratory requisitions.
- `/doctor/records/general-detail?record_id={id}`: general examination workspace, vitals update, and lab service selection.
- `/doctor/examinations`: list of patients with completed lab results ready for AI risk analysis and final diagnosis.
- `/doctor/records/detail?record_id={id}`: detailed examination workspace, run AI risk analysis, enter final diagnosis and prescriptions.
- `/doctor/records/transfer`: POST endpoint for shift handover and transferring records to the next shift doctor.
- `/doctor/schedule`: view assigned work schedules and duty slots.
- `/doctor/lab/worklist`: lab worklist for laboratory technicians to view pending lab requests.
- `/doctor/lab/detail?id={invoiceDetailId}`: lab test detail page to enter lab metric values, approve, and publish results.

## Receptionist routes

- `/receptionist/dashboard`: receptionist dashboard and quick patient check-in counter.
- `/receptionist/patient-search`: search patients by name, phone, or identification number.
- `/receptionist/appointment-registration`: on-site patient registration and booking creation.
- `/receptionist/schedule`: view and manage room allocations and doctor availability schedules.
- `/receptionist/invoices`: list pending invoices and process in-person payments.

## Admin routes

- `/admin/dashboard`: system administration overview and performance analytics.
- `/admin/users`: manage user accounts, assign roles, and set account status.
- `/admin/services`: manage medical services, lab test packages, and pricing catalog.
- `/admin/scheduling`: configure doctor duty schedules, time slots, and clinic rooms.
- `/admin/reports`: view financial, appointment, and AI usage analytical reports.
