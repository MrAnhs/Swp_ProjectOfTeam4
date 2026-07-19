# Coding Workflow

## Quy trình làm việc

### 1. Trước khi code

- [ ] Đọc `project_context.md` để hiểu context
- [ ] Đọc `business_rules.md` liên quan đến feature
- [ ] Đọc `database_rules.md` nếu có thay đổi DB
- [ ] Xác nhận yêu cầu và acceptance criteria

### 2. Trong khi code

#### Style Guide
- Tuân thủ **Java Naming Convention**:
  - Class: PascalCase (PatientDAO, HealthRecordServlet)
  - Method: camelCase (getPatientById, validateHealthData)
  - Variable: camelCase (patientId, healthRecord)
  - Constant: UPPER_SNAKE_CASE (MAX_BMI_VALUE, DEFAULT_PAGE_SIZE)
- Sử dụng **JSTL** trong JSP, tránh Java code trong template
- Chạy **Checkstyle** hoặc **SonarLint** trước khi commit

#### Code Quality
- **DRY**: Don't Repeat Yourself
- **KISS**: Keep It Simple, Stupid
- **Single Responsibility**: Mỗi class/method làm 1 việc
- **Comment**: Giải thích "tại sao" hơn là "cái gì"
- **Exception Handling**: Sử dụng try-catch-finally, log lỗi đầy đủ

#### Testing
- Viết **JUnit** cho business logic trong DAO và Service layers
- **Integration test** cho Servlet endpoints
- Đảm bảo coverage > 70% cho business logic
- Sử dụng **Mockito** cho mock dependencies

### 3. Sau khi code

- [ ] Chạy toàn bộ test suite
- [ ] Self-review code
- [ ] Update documentation nếu cần
- [ ] Commit với message rõ ràng

## Git Workflow

### Branch naming
```
feature/[ticket-id]-[short-desc]
bugfix/[ticket-id]-[short-desc]
hotfix/[short-desc]
refactor/[short-desc]
```

### Commit message format
```
[type]: [subject]

[body - optional]

[footer - optional]
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

**Example**:
```
feat: add user authentication

- Implement JWT token generation
- Add login/logout endpoints
- Add password encryption

Closes #123
```

## Code Review Checklist

- [ ] Logic đúng theo business rules
- [ ] Không có hardcode (sử dụng constants)
- [ ] Xử lý lỗi đầy đủ (try-catch, logging)
- [ ] Không có security issues (SQL injection, XSS, CSRF)
- [ ] Performance tốt (connection pooling, prepared statements)
- [ ] Test coverage đủ (>70% business logic)
- [ ] Documentation cập nhật (JavaDoc, comments)
- [ ] JSP không chứa Java code (chỉ JSTL/EL)
- [ ] Database connections được đóng đúng cách
- [ ] Session management được thực hiện đúng

## Java/JSP Specific Guidelines

### Servlet Development
- **Đăng ký servlet** trong `web.xml` hoặc dùng `@WebServlet`
- **HTTP Methods**: Implement đúng GET, POST, PUT, DELETE
- **Request/Response**: Sử dụng proper encoding (UTF-8)
- **Session Management**: Set appropriate timeout and attributes

### JSP Best Practices
- **JSTL优先**: Sử dụng JSTL tags thay vì Java code
- **Expression Language**: Dùng `${expression}` thay vì `<%= %>`
- **Custom Tags**: Tạo custom tags cho logic phức tạp
- **CSS/JS**: Externalize, không inline trong JSP

### Database Access
- **Connection Pool**: Sử dụng connection pool (HikariCP, DBCP)
- **Prepared Statements**: Luôn dùng để tránh SQL injection
- **Transaction Management**: Xử lý transaction đúng cách
- **Resource Cleanup**: Luôn close ResultSet, Statement, Connection

### Security
- **Input Validation**: Validate tất cả user input
- **Output Encoding**: Encode output để tránh XSS
- **Authentication**: Implement proper login/logout
- **Authorization**: Check user roles trước khi cho phép truy cập
- **Password Security**: Hash passwords với bcrypt/scrypt

### Error Handling
- **Custom Exception**: Tạo custom exceptions cho business logic
- **Error Pages**: Tạo custom error pages (404, 500)
- **Logging**: Sử dụng SLF4J/Log4J với proper log levels
- **User Messages**: Hiển thị friendly error messages

## Definition of Done

1. Code hoàn thiện và pass review
2. Test viết đầy đủ và pass (JUnit + Integration)
3. Documentation cập nhật (JavaDoc, comments)
4. Manual test trên Tomcat thành công
5. Security check passed (no SQL injection, XSS)
6. Performance test passed (response time < 2s)
7. Code deploy lên staging và QA approve
