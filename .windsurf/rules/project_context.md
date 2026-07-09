# Project Context

## Tổng quan dự án

- **Tên dự án**: SWP_Project - Diabetes Monitoring & Early Warning System
- **Mô tả**: Hệ thống theo dõi và cảnh báo sớm bệnh tiểu đường sử dụng AI để phân tích chỉ số sức khỏe
- **Ngôn ngữ chính**: Java
- **Framework**: Java Servlet + JSP
- **Database**: Microsoft SQL Server (Project_SWP)
- **Build Tool**: Apache Ant

## Mục tiêu dự án

1. Theo dõi các chỉ số sức khỏe liên quan đến tiểu đường
2. Phân tích và dự báo nguy cơ tiểu đường bằng AI
3. Quản lý hồ sơ bệnh án và lịch sử trò chuyện với AI
4. Cung cấp giao diện cho bệnh nhân và bác sĩ
5. Hỗ trợ chẩn đoán sớm và tư vấn sức khỏe

## Cấu trúc thư mục

```
SWP_Project/
├── src/
│   └── java/
│       └── com/diabetes/monitoring/
│           ├── dao/          # Data Access Objects
│           ├── model/        # Entity classes
│           ├── servlet/      # Controllers
│           └── util/         # Utility classes
├── web/                     # Web resources
│   ├── css/                 # Stylesheets
│   ├── js/                  # JavaScript files
│   ├── patient/             # Patient pages
│   ├── index.jsp            # Home page
│   ├── login.jsp            # Login page
│   └── register.jsp         # Registration page
├── lib/                     # External libraries
├── build/                   # Build output
├── dist/                    # Distribution
└── test/                    # Test files
```

## Tech Stack

- **Backend**: Java 8+, Servlet API, JSP, JSTL
- **Frontend**: HTML5, CSS3, JavaScript, Bootstrap 5.3.0
- **Database**: Microsoft SQL Server
- **Build**: Apache Ant
- **Container**: Apache Tomcat
- **Other**: JWT (Authentication), Bootstrap Icons

## Domain Model

### Core Entities
- **Account**: Xác thực người dùng (Patient/Doctor)
- **Patient**: Thông tin bệnh nhân
- **Doctor**: Thông tin bác sĩ
- **Healthy_Record**: Chỉ số sức khỏe (urea, cr, hba1c, chol, tg, hdl, idl, vldl, bmi)
- **AI_Conversation**: Lịch sử trò chuyện với AI
- **Doctor_AI**: Kết quả phân tích AI của bác sĩ
- **Medical_record**: Hồ sơ bệnh án

## Features

### Patient Features
- Đăng ký/Đăng nhập tài khoản
- Nhập chỉ số sức khỏe
- Trò chuyện với AI tư vấn
- Xem kết quả phân tích
- Xem lịch sử hồ sơ

### Doctor Features
- Quản lý bệnh nhân
- Xem và phân tích kết quả AI
- Tạo bệnh án
- Theo dõi tiến trình bệnh nhân

### AI Features
- Phân tích nguy cơ tiểu đường
- Tư vấn sức khỏe tự động
- Tóm tắt cuộc trò chuyện
- Hỗ trợ chẩn đoán

## Liên kết quan trọng

- **Database**: Project_SWP (SQL Server)
- **Package**: com.diabetes.monitoring
- **Context Path**: /SWP_Project
- **Default Port**: 8080 (Tomcat)
