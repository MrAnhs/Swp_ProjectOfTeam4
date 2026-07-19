# Cấu hình email OTP

Chức năng đổi email và quên mật khẩu đọc cấu hình từ **biến môi trường** hoặc **JVM system properties**. Không lưu mật khẩu email thật trong source code.

## Cấu hình bắt buộc

```text
DIABETESCARE_SMTP_HOST=smtp.gmail.com
DIABETESCARE_SMTP_PORT=587
DIABETESCARE_SMTP_USERNAME=your-email@gmail.com
DIABETESCARE_SMTP_PASSWORD=your-google-app-password
DIABETESCARE_SMTP_FROM=your-email@gmail.com
DIABETESCARE_OTP_SECRET=a-random-secret-with-at-least-32-characters
```

Với Gmail, `DIABETESCARE_SMTP_PASSWORD` phải là **App Password**, không phải mật khẩu đăng nhập Gmail thông thường. Khởi động lại Tomcat sau khi thay đổi biến môi trường.

Trong NetBeans cũng có thể truyền các giá trị dưới dạng JVM option, ví dụ:

```text
-DDIABETESCARE_SMTP_USERNAME=your-email@gmail.com
-DDIABETESCARE_SMTP_PASSWORD=your-google-app-password
-DDIABETESCARE_SMTP_FROM=your-email@gmail.com
-DDIABETESCARE_OTP_SECRET=a-random-secret-with-at-least-32-characters
```

## Chế độ phát triển

Khi chưa cấu hình SMTP, có thể bật tạm trên máy phát triển:

```text
DIABETESCARE_OTP_DEV_MODE=true
```

Mã OTP sẽ được ghi vào log Tomcat. Không bật chế độ này ở môi trường thật.

## Database

Migration có thể chạy lại an toàn:

```powershell
sqlcmd -S localhost -E -d Project -C -b -i database\email_verification_migration.sql
```

Luồng bảo mật hiện tại:

- OTP gồm 6 chữ số, chỉ lưu HMAC-SHA256 trong database.
- OTP hết hạn sau 5 phút và chỉ dùng được một lần.
- Sai tối đa 5 lần; mã cũ bị vô hiệu khi gửi mã mới.
- Mỗi email/tài khoản chỉ gửi lại sau 60 giây, tối đa 5 lần trong một giờ.
- Quyền đặt lại mật khẩu sau khi xác thực OTP tồn tại trong session 10 phút.

## Kiểm tra cấu hình đang hoạt động

Sau khi cấu hình, phải dừng Tomcat và đóng hoàn toàn NetBeans rồi mở lại. Các biến
môi trường được thêm sau khi NetBeans đã chạy sẽ không tự xuất hiện trong tiến trình
Tomcat hiện tại.

Kiểm tra Tomcat đã nhận cấu hình hay chưa mà không in giá trị bí mật:

```powershell
$java = Get-CimInstance Win32_Process |
    Where-Object { $_.Name -match '^java(w)?\.exe$' -and $_.CommandLine -match 'catalina|tomcat' }

$java | ForEach-Object {
    [pscustomobject]@{
        SmtpUsername = $_.CommandLine -match 'DIABETESCARE_SMTP_USERNAME='
        SmtpPassword = $_.CommandLine -match 'DIABETESCARE_SMTP_PASSWORD='
        SmtpFrom     = $_.CommandLine -match 'DIABETESCARE_SMTP_FROM='
        OtpSecret    = $_.CommandLine -match 'DIABETESCARE_OTP_SECRET='
    }
}
```

Nếu cấu hình bằng biến môi trường Windows thay vì JVM option, kiểm tra ở phạm vi
người dùng:

```powershell
'DIABETESCARE_SMTP_USERNAME',
'DIABETESCARE_SMTP_PASSWORD',
'DIABETESCARE_SMTP_FROM',
'DIABETESCARE_OTP_SECRET' | ForEach-Object {
    [pscustomobject]@{
        Name = $_
        Configured = ![string]::IsNullOrWhiteSpace(
            [Environment]::GetEnvironmentVariable($_, 'User'))
    }
}
```

Kiểm tra máy có kết nối được SMTP Gmail:

```powershell
Test-NetConnection smtp.gmail.com -Port 587
```

Sau khi yêu cầu mã bằng một email có thật trong bảng `Account`, kiểm tra database:

```sql
SELECT TOP 10 verification_id, account_id, purpose, target_email,
       expires_at, failed_attempts, consumed_at, created_at
FROM dbo.Email_Verification
ORDER BY created_at DESC;
```

Nếu không có bản ghi, xem log mới nhất tại:

```text
C:\Program Files\Apache Software Foundation\Tomcat 10.1\logs\localhost.YYYY-MM-DD.log
```

Thông báo `Missing SMTP configuration` nghĩa là tiến trình Tomcat chưa nhận biến
cấu hình. Lỗi `AuthenticationFailedException` hoặc mã SMTP `535` thường nghĩa là
email/App Password không đúng hoặc tài khoản Gmail chưa bật xác minh hai bước.
