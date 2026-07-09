# Frontend structure

The frontend is organized by responsibility and role.

```text
web/
├── assets/
│   ├── css/
│   │   ├── base/
│   │   ├── components/
│   │   ├── layouts/
│   │   └── pages/{public,patient,doctor,admin}/
│   └── js/
│       ├── core/
│       ├── components/
│       └── pages/{public,patient,doctor,admin}/
└── WEB-INF/views/{components,patient,doctor,admin,errors}/
```

## Rules

- JSP files contain markup and server-rendered values only.
- Page-specific CSS and JavaScript live under `assets/*/pages/<role>`.
- Reusable UI behavior lives under `assets/js/components`.
- HTTP requests use `ApiClient`; do not hard-code the deployed context path.
- Shared role components use JSP fragments under `WEB-INF/views/components`.
- All protected role pages must be placed under `WEB-INF/views` and reached through a servlet controller.
- Public URLs use role routes such as `/patient/dashboard`, `/doctor/dashboard`, and `/admin/dashboard`; never link directly to role JSP files.

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
