# Duplicate Audit Before Final Merge

Pham vi doc/so sanh:

- `Swp_Project_Team4-main/src/java`
- `Role Doctor/src/java`
- `SWP_Project (1) (1)/src/java`
- `SWP_Project (4) (1) (1)/src/java`

Khong chon theo ten, thoi gian tao/sua, hoac thu tu source. Cac file duoc danh gia theo do day du logic, validation, exception handling, SQL/schema, noi duoc goi trong project final, va kha nang giu dung MVC + DAO hien tai.

## Nhom trung nhung noi dung giong nhau

Nhung file sau co noi dung trung hoac da duoc copy nguyen logic tot nhat vao project final. FINAL la file trong `Swp_Project_Team4-main`:

- `AcceptRecordServlet`, `AIConversation`, `AIConversationDAO`, `AISummaryServlet`
- `Appointment`, `AppointmentDAO`, `BillingDAO`, `CharacterEncodingFilter`
- `CompletedRecordsServlet`, `DoctorLabServlet`, `DoctorSchedule`, `DoctorServlet`, `DoctorSummary`
- `ExaminationDetailServlet`, `ExaminationListServlet`, `GeneralExaminationListServlet`
- `GetAISummaryServlet`, `GetDiagnosisServlet`, `HealthRecordAI`
- `Invoice`, `InvoiceDetail`, `LaboratoryListServlet`, `LaboratoryRequest`, `LaboratoryRequestServlet`
- `MedicalRecord`, `MedicalService`, `Patient`, `PatientSearchServlet`
- `RandomTestGenerator`, `SubmitHealthRecordServlet`, `TransferHistory`, `TransferRecordServlet`

Ly do: cac version khac khong co method/validation/exception/SQL bo sung can thiet hon, hoac da duoc merge vao final.

## Nhom can quyet dinh/merge

### `web.xml`

File A: `Swp_Project_Team4-main/web/WEB-INF/web.xml`

- Chuc nang co: auth/patient/admin/public mappings co ban.
- Chuc nang thieu: `CharacterEncodingFilter`, doctor-lab, doctor workflow, receptionist, patient health-record servlets.
- Diem manh: khop mot phan Team4 patient/admin.
- Diem yeu: thieu nhieu role, de loi deploy/404 do mapping khong du.

File B: `SWP_Project (1) (1)/web/WEB-INF/web.xml`

- Chuc nang co: patient health-record, AI summary, doctor-lab.
- Chuc nang thieu: admin/receptionist/appointment/invoice routes cua Team4, doctor workflow.
- Diem manh: day du luong health-record + lab.
- Diem yeu: khong bao toan cac role Team4.

File C: `Role Doctor/web/WEB-INF/web.xml`

- Chuc nang co: doctor workflow servlet mappings.
- Chuc nang thieu: admin/patient/receptionist/doctor-lab.
- Diem manh: khop JSP `/doctor/*`.
- Diem yeu: chi dung cho module doctor rieng.

Ket luan: lay file A lam BASE vi khop project final, merge them mappings/filter tu B va C, them receptionist mappings tu Team4 source.

### `PatientPageServlet`

File A: `Swp_Project_Team4-main/.../PatientPageServlet.java`

- Chuc nang co: route dashboard, ai-chat, appointments, invoices, visit history, profile.
- Chuc nang thieu: health-record pages va AI chat turn-count attribute.
- Diem manh: bao toan patient shell moi va module appointment/invoice/history.
- Diem yeu: neu dung mot minh se 404 `/patient/health-records*`.

File B: `SWP_Project (1) (1)/.../PatientPageServlet.java`

- Chuc nang co: route health-record pages, ai-chat turn-count.
- Chuc nang thieu: appointments, invoices, visit history cua Team4.
- Diem manh: phu hop luong health-record.
- Diem yeu: neu dung mot minh se mat cac page Team4.

Ket luan: File A lam BASE, merge route health-record va turn-count logic tu File B.

### `MedicalHistoryServlet`

File A: `SWP_Project (1) (1)/.../MedicalHistoryServlet.java`

- Chuc nang co: JSON API cho patient lay `Healthy_Record` theo `patient_id`.
- Chuc nang thieu: JSP view cho doctor.
- Diem manh: khop route `/medical-history` va patient JS.
- Diem yeu: chi phuc vu patient.

File B: `Role Doctor/.../MedicalHistoryServlet.java`

- Chuc nang co: doctor xem lich su benh an qua JSP, check role/ownership bang `DoctorServlet`.
- Chuc nang thieu: patient JSON API.
- Diem manh: logic phan quyen doctor dung nghiep vu.
- Diem yeu: trung ten class voi patient servlet.

Ket luan: giu File A lam `MedicalHistoryServlet`; doi File B thanh `DoctorMedicalHistoryServlet` de bao toan ca hai luong.

### `AIChatServlet`

File A: `Swp_Project_Team4-main/.../AIChatServlet.java`

- Chuc nang co: `AI_Conversation`, lien ket appointment, summary khi finish.
- Chuc nang thieu: session health-data extraction/10-turn warning cua health-record form.
- Diem manh: khop module appointment + doctor conversation moi.
- Diem yeu: khong tu tao health-record tu chat.

File B: `SWP_Project (1) (1)/.../AIChatServlet.java`

- Chuc nang co: health-data extraction, abnormal value confirmation, session chat limit.
- Chuc nang thieu: appointment conversation integration cua Team4.
- Diem manh: tot cho luong health-record.
- Diem yeu: thay the truc tiep se lam mat luong appointment chat.

Ket luan: khong thay FINAL bang B. Giu A cho `/ai-chat`; merge luong health-record bang `AISummaryServlet`, `GetAISummaryServlet`, `SubmitHealthRecordServlet`, va `PatientPageServlet` turn-count.

### `HealthRecordDAO`

File A: `Role Doctor/.../HealthRecordDAO.java`

- Chuc nang co: accept, transfer, lab request, AI result, complete medical record, doctor workflow.
- Chuc nang thieu: can chuan hoa schema `idl` -> `ldl`.
- Diem manh: logic nghiep vu doctor day du nhat.
- Diem yeu: SQL cu dung `idl`.

File B: `SWP_Project (4)/.../HealthRecordDAO.java`

- Chuc nang co: mot phan health record/AI.
- Chuc nang thieu: doctor workflow moi, billing/lab workflow.
- Diem manh: gon hon.
- Diem yeu: khong du cho role doctor final.

Ket luan: File A lam BASE, sua SQL sang `ldl` de khop schema/project final.

### `UserDAO`

File A: `Swp_Project_Team4-main/.../UserDAO.java`

- Chuc nang co: register patient, login Account, load patient/doctor details, duplicate email/phone.
- Chuc nang thieu: mot so helper admin/AI cu.
- Diem manh: khop `AuthServlet`, `RegisterServlet`, `UpdateProfileServlet`, Account/Patient schema cua Team4.
- Diem yeu: khong gom tat ca helper cu trong mot DAO.

File B: `Role Doctor/.../UserDAO.java` va `SWP_Project (4)/.../UserDAO.java`

- Chuc nang co: rat nhieu helper admin/health-record/AI.
- Chuc nang thieu: mot so validation/input util cua Team4.
- Diem manh: nhieu method.
- Diem yeu: nhieu method da duoc thay bang `admin/*` va `HealthRecordDAO`; merge nguyen file se tang coupling va de xung dot schema.

Ket luan: File A lam BASE. Khong merge helper khong con caller; doctor/admin logic da nam o DAO/service rieng.

### `RegisterServlet` va `UpdateProfileServlet`

File A: Team4 final.

- Chuc nang co: validation, duplicate checks, khop UI public/patient.
- Chuc nang thieu: khong co mot so helper cu khong con route.
- Diem manh: khop `UserDAO` final va frontend Team4.
- Diem yeu: can giu dependency `InputValidationUtil`.

File B/C: SWP cu.

- Chuc nang co: dang ky/cap nhat co ban.
- Chuc nang thieu: it validation/tich hop hon.
- Diem manh: gon.
- Diem yeu: khong du cho UI final.

Ket luan: giu Team4 final.

### `ProcessAIServlet`

File A: Role Doctor.

- Chuc nang co: check role doctor, check ownership record, check status, check du data, call Flask, parse probabilities, save `Doctor_AI`.
- Chuc nang thieu: can dependency Gson va Flask service.
- Diem manh: nghiep vu day du va an toan hon.
- Diem yeu: can service `/predict`.

File B: SWP (4).

- Chuc nang co: call Flask co ban.
- Chuc nang thieu: guard role/record/status it hon.
- Diem manh: ngan.
- Diem yeu: de chay sai record.

Ket luan: File A lam BASE, them `gson` va `ai_service/app.py`.

## Viec can lam thanh FINAL

1. Viet lai `web.xml` final tu BASE Team4 + mappings con thieu.
2. Merge `PatientPageServlet` tu Team4 + health-record routes.
3. Giu `MedicalHistoryServlet` patient va `DoctorMedicalHistoryServlet` doctor.
4. Kiem tra compile + parse XML + duplicate URL.
