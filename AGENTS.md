# AGENTS.md

Tài liệu này mô tả các agent và vai trò trong dự án SWP - Diabetes Monitoring & Early Warning System.

## Danh sách Agent

### 1. Patient Agent
- **Vai trò**: Đại diện cho bệnh nhân sử dụng hệ thống
- **Trách nhiệm**: 
  - Đăng ký và quản lý tài khoản cá nhân
  - Nhập và theo dõi chỉ số sức khỏe
  - Tương tác với AI để nhận tư vấn
  - Xem kết quả phân tích và lịch sử hồ sơ
- **Ngôn ngữ/Tech Stack**: Java Servlet, JSP, Bootstrap, JavaScript

### 2. Doctor Agent
- **Vai trò**: Đại diện cho bác sĩ quản lý và chẩn đoán
- **Trách nhiệm**: 
  - Quản lý danh sách bệnh nhân
  - Xem và phân tích kết quả AI
  - Tạo và quản lý bệnh án
  - Phê duyệt hiển thị kết quả cho bệnh nhân
- **Ngôn ngữ/Tech Stack**: Java Servlet, JSP, SQL Server

### 3. AI Analysis Agent
- **Vai trò**: Hệ thống AI phân tích và tư vấn sức khỏe
- **Trách nhiệm**: 
  - Phân tích các chỉ số sức khỏe
  - Tính toán xác suất nguy cơ tiểu đường
  - Đưa ra lời khuyên sức khỏe tự động
  - Tạo tóm tắt cuộc trò chuyện
- **Ngôn ngữ/Tech Stack**: Python/Machine Learning, REST API, JSON

### 4. Data Management Agent
- **Vai trò**: Quản lý lưu trữ và xử lý dữ liệu
- **Trách nhiệm**: 
  - Quản lý kết nối database SQL Server
  - Xử lý transaction và data integrity
  - Backup và restore dữ liệu
  - Optimize query performance
- **Ngôn ngữ/Tech Stack**: Java, JDBC, SQL Server, Connection Pooling

### 5. Security Agent
- **Vai trò**: Đảm bảo bảo mật và xác thực người dùng
- **Trách nhiệm**: 
  - Xác thực đăng nhập (Authentication)
  - Kiểm tra quyền truy cập (Authorization)
  - Bảo vệ khỏi SQL Injection và XSS
  - Quản lý session và token
- **Ngôn ngữ/Tech Stack**: Java, JWT, bcrypt, Security Filters

## Luồng giao tiếp giữa các Agent

```
Patient Agent --> Security Agent --> Data Management Agent
      |                    |                    |
      v                    v                    v
AI Analysis Agent <-- Doctor Agent <-- Data Management Agent
```

### Luồng chính:
1. **Patient Agent** gửi request → **Security Agent** xác thực → **Data Management Agent** xử lý dữ liệu
2. **Data Management Agent** cung cấp dữ liệu → **AI Analysis Agent** phân tích → **Doctor Agent** xem kết quả
3. **Doctor Agent** tạo bệnh án → **Data Management Agent** lưu trữ → **Patient Agent** xem kết quả

## Phân chia hệ thống theo Layer

### Presentation Layer
- **Patient Agent**: Giao diện bệnh án, nhập liệu, chat AI
- **Doctor Agent**: Giao diện quản lý, phân tích, tạo bệnh án

### Business Logic Layer
- **AI Analysis Agent**: Core business logic cho phân tích
- **Security Agent**: Business logic cho authentication/authorization

### Data Layer
- **Data Management Agent**: Tất cả operations với database

## Ghi chú

- **Scalability**: Mỗi agent có thể scale độc lập
- **Maintainability**: Tách biệt logic giúp dễ bảo trì
- **Testability**: Mỗi agent có unit test riêng
- **Integration**: Agents giao tiếp qua well-defined interfaces
- **Error Handling**: Mỗi agent có error handling riêng biệt
- **Logging**: Centralized logging system cho tất cả agents
