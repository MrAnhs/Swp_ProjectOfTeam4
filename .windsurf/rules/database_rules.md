# Database Rules

## Quy tắc đặt tên

### Tables
- Tên bảng sử dụng **snake_case**, số nhiều
- Ví dụ: `users`, `order_items`, `product_categories`

### Columns
- Tên cột sử dụng **snake_case**
- Khóa chính: `id` (BIGINT AUTO_INCREMENT / SERIAL)
- Khóa ngoại: `[table_name]_id`
- Timestamp: `created_at`, `updated_at`, `deleted_at` (soft delete)

### Indexes
- Tên index: `idx_[table]_[column]`
- Unique index: `uniq_[table]_[column]`

## Quy tắc thiết kế

1. **Chuẩn hóa**: Tuân thủ 3NF (Third Normal Form)
2. **Soft Delete**: Sử dụng `deleted_at` thay vì xóa cứng
3. **Audit**: Mọi bảng cần có `created_at` và `updated_at`
4. **Foreign Keys**: Luôn định nghĩa ràng buộc khóa ngoại với `ON DELETE` và `ON UPDATE`

## Kiểu dữ liệu chuẩn

| Java/C# Type | Database Type | Ghi chú |
|-------------|---------------|---------|
| Long/Bigint | BIGINT | Khóa chính |
| String | VARCHAR(n) / TEXT | Tùy độ dài |
| Integer | INT | Số nguyên |
| BigDecimal | DECIMAL(p,s) | Tiền tệ |
| Boolean | BOOLEAN / BIT | True/False |
| LocalDateTime | TIMESTAMP / DATETIME | Thời gian |
| Enum | VARCHAR / ENUM | Hoặc bảng lookup |

## Query Guidelines

- Sử dụng **parameterized queries** (tránh SQL Injection)
- Viết `SELECT` rõ ràng cột, không dùng `SELECT *`
- Thêm `LIMIT` cho query có thể trả về nhiều dữ liệu
- Sử dụng `EXPLAIN` để kiểm tra query plan

## Migration

- Đặt tên file: `YYYYMMDD_[sequence]_[description].sql`
- Ví dụ: `20240602_001_create_users_table.sql`
- Mỗi migration phải có cả `UP` và `DOWN`

## Cấu trúc Database Project_SWP

### Database Info
- **Database Name**: Project_SWP
- **Server**: Microsoft SQL Server
- **User**: swp_user (db_datareader, db_datawriter)

### Tables Structure

#### Account
```sql
CREATE TABLE Account (
    account_id INT IDENTITY(1,1) PRIMARY KEY,
    full_name NVARCHAR(100) NULL,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(100) NULL,
    role VARCHAR(50) NULL,
    created_at DATETIME DEFAULT GETDATE(),
    status NVARCHAR(20) DEFAULT 'active'
);
```

#### Patient
```sql
CREATE TABLE Patient (
    patient_id INT IDENTITY(1,1) PRIMARY KEY,
    full_name NVARCHAR(100) NOT NULL,
    date_of_birth DATE NULL,
    gender NVARCHAR(10) NULL,
    phone VARCHAR(15) NULL,
    email VARCHAR(100) NULL,
    address NVARCHAR(255) NULL,
    account_id INT NULL FOREIGN KEY REFERENCES Account(account_id)
);
```

#### Doctor
```sql
CREATE TABLE Doctor (
    doctor_id INT IDENTITY(1,1) PRIMARY KEY,
    full_name NVARCHAR(100) NOT NULL,
    phone VARCHAR(15) NULL,
    email VARCHAR(100) NULL,
    department NVARCHAR(100) NULL,
    account_id INT NULL FOREIGN KEY REFERENCES Account(account_id)
);
```

#### Healthy_Record
```sql
CREATE TABLE Healthy_Record (
    health_record_id INT IDENTITY(1,1) PRIMARY KEY,
    urea DECIMAL(5,2) NULL,
    cr DECIMAL(5,2) NULL,
    hba1c DECIMAL(5,2) NULL,
    chol DECIMAL(5,2) NULL,
    tg DECIMAL(5,2) NULL,
    hdl DECIMAL(5,2) NULL,
    idl DECIMAL(5,2) NULL,
    vldl DECIMAL(5,2) NULL,
    bmi DECIMAL(5,2) NULL,
    patient_id INT NULL FOREIGN KEY REFERENCES Patient(patient_id),
    weight FLOAT NULL,
    height FLOAT NULL,
    other_information NVARCHAR(MAX) NULL,
    status NVARCHAR(20) NULL,
    created_at DATETIME DEFAULT GETDATE()
);
```

#### AI_Conversation
```sql
CREATE TABLE AI_Conversation (
    conversation_id INT IDENTITY(1,1) PRIMARY KEY,
    patient_id INT NOT NULL FOREIGN KEY REFERENCES Patient(patient_id) ON DELETE CASCADE,
    chat_history NVARCHAR(MAX) NULL,
    health_record_id INT NULL FOREIGN KEY REFERENCES Healthy_Record(health_record_id),
    ai_summary NVARCHAR(MAX) NULL,
    created_at DATETIME DEFAULT GETDATE()
);
```

#### Doctor_AI
```sql
CREATE TABLE Doctor_AI (
    doctor_ai_id INT IDENTITY(1,1) PRIMARY KEY,
    health_record_id INT NULL FOREIGN KEY REFERENCES Healthy_Record(health_record_id),
    diabetes_probability FLOAT NULL,
    pre_diabetes_probability FLOAT NULL,
    normal_probability FLOAT NULL,
    doctor_id INT NULL FOREIGN KEY REFERENCES Doctor(doctor_id)
);
```

#### Medical_record
```sql
CREATE TABLE Medical_record (
    record_id INT IDENTITY(1,1) PRIMARY KEY,
    patient_id INT NOT NULL FOREIGN KEY REFERENCES Patient(patient_id) ON DELETE CASCADE,
    doctor_id INT NOT NULL FOREIGN KEY REFERENCES Doctor(doctor_id) ON DELETE CASCADE,
    final_diagnosis NVARCHAR(MAX) NULL,
    doctor_note NVARCHAR(MAX) NULL,
    health_record_id INT NULL FOREIGN KEY REFERENCES Healthy_Record(health_record_id),
    result_visibility BIT NULL,
    processed_at DATETIME NULL
);
```

### Relationships
- **Account** 1-1 **Patient**
- **Account** 1-1 **Doctor**
- **Patient** 1-N **Healthy_Record**
- **Patient** 1-N **AI_Conversation**
- **Patient** 1-N **Medical_record**
- **Doctor** 1-N **Medical_record**
- **Doctor** 1-N **Doctor_AI**
- **Healthy_Record** 1-N **AI_Conversation**
- **Healthy_Record** 1-N **Doctor_AI**
- **Healthy_Record** 1-N **Medical_record**
