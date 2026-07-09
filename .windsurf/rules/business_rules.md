# Business Rules

## Domain chính

### 1. Patient Management (Quản lý bệnh nhân)

#### Quy tắc 1.1: Đăng ký tài khoản
- **Mô tả**: Bệnh nhân có thể đăng ký tài khoản mới với thông tin cá nhân
- **Ví dụ**: Nguyễn Văn A, email: a@gmail.com, phone: 0912345678
- **Validation**: 
  - Email phải unique và đúng định dạng
  - Số điện thoại phải đúng định dạng Việt Nam
  - Mật khẩu tối thiểu 8 ký tự, có chữ hoa, số và ký tự đặc biệt

#### Quy tắc 1.2: Cập nhật thông tin cá nhân
- **Mô tả**: Bệnh nhân có thể cập nhật thông tin cá nhân (trừ account_id)
- **Ví dụ**: Thay đổi địa chỉ, số điện thoại, email
- **Validation**: Email mới không được trùng với email đã tồn tại

### 2. Health Records (Hồ sơ sức khỏe)

#### Quy tắc 2.1: Nhập chỉ số sức khỏe
- **Mô tả**: Bệnh nhân nhập các chỉ số sức khỏe liên quan đến tiểu đường
- **Ví dụ**: HbA1c = 6.5%, BMI = 24.5, Cholesterol = 180 mg/dL
- **Validation**:
  - HbA1c: 3.0% - 15.0%
  - BMI: 10.0 - 50.0
  - Cholesterol: 100 - 400 mg/dL
  - Urea, Creatinine theo giới hạn y tế

#### Quy tắc 2.2: Tính toán chỉ số tự động
- **Mô tả**: Hệ thống tự động tính toán BMI từ weight và height
- **Ví dụ**: Weight = 70kg, Height = 1.70m → BMI = 24.2
- **Validation**: Height > 0, Weight > 0

### 3. AI Analysis (Phân tích AI)

#### Quy tắc 3.1: Phân tích nguy cơ tiểu đường
- **Mô tả**: AI phân tích các chỉ số và đưa ra xác suất nguy cơ
- **Ví dụ**: Diabetes: 75%, Pre-diabetes: 20%, Normal: 5%
- **Validation**: Tổng xác suất = 100%, mỗi giá trị 0-100%

#### Quy tắc 3.2: Tư vấn sức khỏe
- **Mô tả**: AI đưa ra lời khuyên dựa trên kết quả phân tích
- **Ví dụ**: "Bạn nên giảm cân và tập thể dục đều đặn"
- **Validation**: Nội dung phù hợp với mức độ nguy cơ

### 4. Medical Records (Bệnh án)

#### Quy tắc 4.1: Bác sĩ tạo bệnh án
- **Mô tả**: Bác sĩ tạo bệnh án dựa trên kết quả AI và khám
- **Ví dụ**: Chẩn đoán: Tiểu đường type 2, Ghi chú: Cần theo dõi chế độ ăn
- **Validation**: Chỉ bác sĩ mới có quyền tạo bệnh án

#### Quy tắc 4.2: Hiển thị kết quả
- **Mô tả**: Bệnh nhân có thể xem kết quả khi bác sĩ cho phép
- **Ví dụ**: result_visibility = true/1
- **Validation**: Mặc định là false cho đến khi bác sĩ duyệt

## Luồng nghiệp vụ chính

### Luồng 1: Đăng ký và sử dụng hệ thống

1. Bệnh nhân đăng ký tài khoản
2. Xác thực email và kích hoạt tài khoản
3. Đăng nhập vào hệ thống
4. Cập nhật thông tin cá nhân
5. Nhập chỉ số sức khỏe đầu tiên
6. AI phân tích và đưa ra kết quả
7. Bệnh nhân xem kết quả và nhận tư vấn

### Luồng 2: Quản lý của bác sĩ

1. Bác sĩ đăng nhập vào hệ thống
2. Xem danh sách bệnh nhân được phân công
3. Xem hồ sơ sức khỏe của bệnh nhân
4. Xem kết quả phân tích AI
5. Tạo bệnh án và chẩn đoán
6. Phê duyệt hiển thị kết quả cho bệnh nhân

### Luồng 3: Tư vấn AI

1. Bệnh nhân bắt đầu cuộc trò chuyện với AI
2. AI hỏi về triệu chứng và chỉ số
3. Bệnh nhân cung cấp thông tin
4. AI phân tích và đưa ra tư vấn
5. Lưu lịch sử trò chuyện
6. Tạo tóm tắt cho bác sĩ

## Ràng buộc nghiệp vụ

| STT | Ràng buộc | Mức độ | Mô tả |
|-----|-----------|--------|-------|
| 1 | Email uniqueness | Bắt buộc | Mỗi email chỉ đăng ký một tài khoản |
| 2 | Password strength | Bắt buộc | Mật khẩu phải có độ phức tạp tối thiểu |
| 3 | Health record validation | Bắt buộc | Chỉ số phải trong giới hạn y tế |
| 4 | Doctor authorization | Bắt buộc | Chỉ bác sĩ mới có quyền tạo bệnh án |
| 5 | AI probability sum | Bắt buộc | Tổng xác suất phải bằng 100% |
| 6 | Patient age | Tùy chọn | Bệnh nhân phải từ 18 tuổi trở lên |
| 7 | Data privacy | Bắt buộc | Bảo mật thông tin bệnh án |

## Trạng thái và chuyển đổi

### Account States

```
INACTIVE --[verify_email]--> ACTIVE --[deactivate]--> INACTIVE
   |                                              |
   |----[admin_ban]------------------------------->|
```

| Từ trạng thái | Sự kiện | Đến trạng thái | Điều kiện |
|---------------|---------|----------------|-----------|
| INACTIVE | verify_email | ACTIVE | Email xác thực thành công |
| ACTIVE | deactivate | INACTIVE | User yêu cầu hoặc admin khóa |
| ACTIVE | admin_ban | INACTIVE | Vi phạm điều khoản sử dụng |

### Medical Record States

```
PENDING --[doctor_approve]--> APPROVED --[patient_view]--> VIEWED
    |                              |
    |----[doctor_reject]----------> REJECTED
```

| Từ trạng thái | Sự kiện | Đến trạng thái | Điều kiện |
|---------------|---------|----------------|-----------|
| PENDING | doctor_approve | APPROVED | Bác sĩ duyệt bệnh án |
| PENDING | doctor_reject | REJECTED | Bác sĩ từ chối bệnh án |
| APPROVED | patient_view | VIEWED | Bệnh nhân đã xem kết quả |

## Ghi chú đặc biệt

- **Edge Cases**: Bệnh nhân có chỉ số bất thường cao cần cảnh báo khẩn cấp
- **Integration**: Cần tích hợp với hệ thống bệnh viện để đồng bộ dữ liệu
- **Security**: Mọi dữ liệu bệnh án phải được mã hóa
- **Compliance**: Tuân thủ quy định bảo mật thông tin y tế HIPAA
- **AI Limitations**: AI chỉ hỗ trợ tư vấn, không thay thế chẩn đoán bác sĩ
- **Data Retention**: Lưu trữ dữ liệu tối thiểu 10 năm theo quy định
