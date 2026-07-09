# Diabetes Prediction and Early Warning System Merge Report

## Nguyen tac danh gia sau khi ra soat lai

Lan ra soat nay khong chon file theo ten, timestamp hay thu tu source. Moi file trung chuc nang duoc danh gia theo:

- Do day du logic nghiep vu.
- Do khop voi schema hien tai.
- Do khop voi noi dang goi: Model -> DAO -> Servlet -> JSP -> Database -> AI API.
- Kha nang giu nguyen cac role ma khong lam vo module khac.
- Compile/deploy descriptor khong loi.

## Project chinh

Project final duoc gop vao:

`Swp_Project_Team4-main`

Ly do chon lam base ve mat noi dung:

- Co module Admin tach thanh handler/service/DAO rieng, it phu thuoc vao servlet lon cu.
- Patient appointment/invoice/history co day du DAO, servlet API, JS page va JSP tuong ung.
- Receptionist co DAO/service/page/API rieng, phu hop pattern MVC + service.
- Co filter phan quyen theo role va cau truc view theo `WEB-INF/views`.
- Khop tot hon voi database dump/migrations hien tai cua project final.

Khong merge truc tiep tu `build/`, `dist/`, `.class`, `.war`, `.venv`, vi day la output/generated dependency cache, khong phai source chinh.

## Kien truc folder final

```text
Swp_Project_Team4-main/
  ai_service/                         # Flask API /predict cho Java doctor AI
  database/
    project_SWP_dump.sql
    migrations/
  lib/                                # JDBC, JSTL, Gson
  src/
    java/com/diabetes/monitoring/
      admin/                          # Admin MVC handlers/DAO/service
      dao/                            # Shared DAO + doctor DAO merged
      filter/                         # Authentication + role authorization
      model/                          # Entity/DTO
      receptionist/                   # Receptionist DAO/service
      service/                        # Appointment service
      servlet/                        # Public/patient/doctor/lab servlets
      util/                           # DB, validation, Gemini, random lab data
  web/
    WEB-INF/views/
      admin/
      components/
      doctor-lab/
      patient/
      receptionist/
    doctor/                           # Doctor JSP module from Role Doctor
    assets/
    css/
    WEB-INF/web.xml
```

## File/version decisions theo noi dung code

### Base Team4 kept

Kept from `Swp_Project_Team4-main`:

- `UserDAO`, `AuthServlet`, `RegisterServlet`, `UpdateProfileServlet`, `LogoutServlet`
- `AIChatServlet`, `AIConversationServlet`
- Patient appointment/availability/doctor/invoice/visit DAO + servlet
- Admin module under `com.diabetes.monitoring.admin`
- Receptionist module under `com.diabetes.monitoring.receptionist`
- Filters: authentication, admin/patient/receptionist authorization
- Shared models already used by Team4 pages

Reason: cac file nay khop voi route/JSP/JS cua project final va tach nghiep vu tot hon. Cac phien ban cu trong `SWP_Project (4)` thuong gom nhieu logic vao servlet lon, de gay xung dot khi merge voi admin/receptionist/patient moi.

### Duplicate decisions chi tiet

| Class/chuc nang | Diem manh tung version | Thieu/rui ro | FINAL |
| --- | --- | --- | --- |
| `AuthServlet` | Team4 goi `UserDAO.validateLogin`, set `currentUser`, dieu huong theo role moi. Doctor/old versions chi phu hop module rieng. | Neu dung doctor version se mat dieu huong admin/patient/receptionist. | Giu Team4. |
| `UserDAO` | Team4 phu hop `Account`, `Patient`, `Doctor`, co validate password hash, duplicate email/phone. Doctor old rat lon va co nhieu admin/AI helper da duoc thay bang admin package + `HealthRecordDAO`. | Doctor `UserDAO` co nhieu method health-record nhung trung vai tro voi DAO moi; merge vao se tang coupling va rui ro schema `idl/ldl`. | Giu Team4, khong merge method khong con noi goi. |
| `AIChatServlet` | Team4 chat gan voi `AI_Conversation` va appointment. SWP (1) chat theo session + tao health record tu chat. | Chon mot file se mat mot luong. | Giu Team4 cho `/ai-chat`; merge them patient health-record flow qua `AISummaryServlet`, `SubmitHealthRecordServlet`, `GetAISummaryServlet`. |
| `MedicalHistoryServlet` | SWP (1) tra JSON lich su health record cho patient. Doctor version tra JSP lich su benh an cho bac si. | Trung package/class nhung la hai nghiep vu khac nhau. | Giu patient class ten cu; doi doctor class thanh `DoctorMedicalHistoryServlet`. |
| `PatientPageServlet` | Team4 co appointments/invoices/visit/profile. SWP (1) co health-record pages va AI-chat limit attributes. | Chon mot file se mat mot nhom page. | Giu Team4 lam nen, merge health-record routes va AI-chat turn-count attributes tu SWP (1). |
| `HealthRecordDAO` | Doctor version co workflow kham, accept, transfer, lab billing, AI result, complete record. SWP (4) ngan hon, it workflow. | Doctor version dung `idl`; project patient/Team4 dung `ldl`. | Chon doctor workflow lam nen, sua SQL sang `ldl`. |
| `MedicalRecordDAO` | Cac version gan nhu giong nhau, dung bang `patient_records`. | Project final khong goi DAO nay cho luong kham chinh; schema hien tai dung `Medical_record` + `Healthy_Record`. | Giu file final hien co de khong pha code cu, khong dua vao workflow moi. |
| `DatabaseConnection` | Team4 don gian, khop DB `Project`. Role Doctor co them thu ket noi. | Doi connection co the lam lech DB hien tai. | Giu Team4. |
| `RegisterServlet`/`UpdateProfileServlet` | Team4 co validation tieng Viet, CSRF/input util va khop `UserDAO` moi. | Old versions it khop appointment/invoice patient shell. | Giu Team4. |
| `ProcessAIServlet` | Doctor version validate role, quyen record, trang thai, data du truoc khi goi Flask, parse probabilities va luu `Doctor_AI`. | SWP (4) don gian hon, it guard hon. | Giu doctor version; them `gson` va Flask `/predict`. |

### Doctor module merged

Imported from `Role Doctor`:

- DAO: `AIConversationDAO`, `AppointmentDAO`, `BillingDAO`, `ClinicalWorkflowDAO`, `HealthRecordDAO`, `LaboratoryDAO`
- Models: `AIConversation`, `Appointment`, `DoctorSchedule`, `DoctorSummary`, `HealthRecord`, `HealthRecordAI`, `Invoice`, `InvoiceDetail`, `LaboratoryRequest`, `MedicalRecord`, `MedicalService`, `Patient`, `TransferHistory`
- Servlets: `DoctorServlet`, dashboard/detail/examination/lab/process/save/transfer/search/completed servlets
- Views/assets: `web/doctor/*`, `web/css/style.css`, `web/css/doctor-module.css`

Conflict resolved:

- Doctor `MedicalHistoryServlet` conflicted with patient JSON `MedicalHistoryServlet`.
- Kept patient servlet name for `/medical-history`.
- Renamed doctor version to `DoctorMedicalHistoryServlet` and mapped it to `/DoctorMedicalHistoryServlet`.

### Patient health-record and doctor-lab merged

Imported from `SWP_Project (1) (1)`:

- `CharacterEncodingFilter`
- `AISummaryServlet`, `GetAISummaryServlet`, `GetDiagnosisServlet`, `SubmitHealthRecordServlet`
- `MedicalHistoryServlet` for patient JSON history
- `DoctorLabServlet`
- `RandomTestGenerator`
- Patient health record JSP/JS: `health-record-form/list/detail`
- Doctor lab dashboard: `WEB-INF/views/doctor-lab/dashboard.jsp`

Conflict resolved:

- `PatientPageServlet` kept Team4 appointment/invoice/history routes and added health-record routes:
  - `/patient/health-records/new`
  - `/patient/health-records`
  - `/patient/health-records/detail`

### SQL/schema decision

The merged Java source is standardized on `Healthy_Record.ldl` for LDL cholesterol.

Reason:

- Team4 source and patient AI source use `ldl`.
- `SWP_Project (1) (1)/database/migrations/20260617_rename_idl_to_ldl.sql` indicates migration toward `ldl`.
- Doctor code imported from `Role Doctor` used `idl`; copied DAO SQL was normalized to `ldl` while keeping Java field names where they are only local parameter names.

## web.xml integration

Da sua loi deploy tiem an:

- Viet lai `web.xml` theo dung thu tu schema Jakarta Servlet: `filter`, `filter-mapping`, `servlet`, `servlet-mapping`, `welcome-file-list`.
- Da doc va doi chieu 4 file `web.xml` theo role, khong chon theo ten/thoi gian:
  - `Swp_Project_Team4-main/web/WEB-INF/web.xml`: base tong hop Admin, Patient, Receptionist, Doctor-Lab.
  - `SWP_Project (1) (1)/web/WEB-INF/web.xml`: lay role Patient health-record va Doctor-Lab.
  - `Role Doctor/web/WEB-INF/web.xml`: lay role Doctor workflow day du.
  - `SWP_Project (4) (1) (1)/web/WEB-INF/web.xml`: lay them endpoint role Admin anti-fraud va legacy Receptionist search.
- Them mapping receptionist bi thieu: pages va `/receptionist/api/*`.
- Them mapping tu role thu 4 co source that:
  - `/admin-anti-fraud` -> `AntiFraudServlet`
  - `/receptionist-search` -> `ReceptionistServlet`
- Khong merge `/ai-recommendation` tu role thu 4 vi `AIRecommendationServlet.java` khong ton tai trong source; neu dua mapping nay vao se gay loi deploy/class not found.
- Kiem tra khong co duplicate servlet URL.

Added mappings for:

- Encoding filter on `/*`
- Patient health-record API servlets
- Doctor-lab `/doctor-lab/*`
- Doctor workflow servlets:
  - `/DashboardServlet`
  - `/AcceptRecordServlet`
  - `/TransferRecordServlet`
  - `/GeneralExaminationListServlet`
  - `/ExaminationListServlet`
  - `/ExaminationDetailServlet`
  - `/DetailServlet`
  - `/LaboratoryListServlet`
  - `/LaboratoryRequestServlet`
  - `/DoctorMedicalHistoryServlet`
  - `/PatientSearchServlet`
  - `/ProcessAIServlet`
  - `/SaveNotesServlet`
  - `/CompletedRecordsServlet`
- Receptionist:
  - `/receptionist/dashboard`
  - `/receptionist/patients/search`
  - `/receptionist/appointments/new`
  - `/receptionist/queue`
  - `/receptionist/billing`
  - `/receptionist/api/*`

## AI service integration

Added:

- `ai_service/app.py`
- `ai_service/requirements.txt`
- `ai_service/README.md`

Java `ProcessAIServlet` calls:

`http://127.0.0.1:5000/predict`

The Flask service accepts the `HealthRecord` JSON sent by Java and returns:

```json
{
  "status": "success",
  "modelVersion": "fallback-rules-v1",
  "probabilities": {
    "Normal": 0.0,
    "Pre-Diabetes": 0.0,
    "Diabetes": 0.0
  }
}
```

If `model.joblib` exists or `DIABETES_MODEL_PATH` is set, the Flask API loads the scikit-learn model and uses `predict_proba`. Otherwise it uses a conservative fallback rule set so the Java flow remains runnable.

## Verification

Executed:

```powershell
javac -encoding UTF-8 -cp "lib\gson-2.10.1.jar;lib\mssql-jdbc-13.2.0.jre11.jar;lib\mysql-connector-java-8.0.30.jar;C:\Users\LENOVO\.m2\repository\jakarta\servlet\jakarta.servlet-api\6.0.0\jakarta.servlet-api-6.0.0.jar" -d build\codex-classes <all src/java files>
py -3 -m py_compile ai_service\app.py
```

Result:

- Java compile OK.
- Flask app syntax compile OK.
- `web.xml` XML parse OK.
- Every servlet/filter class referenced by `web.xml` exists.
- Every servlet mapping references a declared servlet.
- No duplicate servlet `url-pattern`.
- No duplicate Java basename remains in final `src/java`.

Note: `ant` is not installed in PATH on this machine, so WAR packaging was not run from CLI. NetBeans/Ant can still use the updated `build.xml`/`nbproject` once Ant is available.
