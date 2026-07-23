package com.diabetes.monitoring.util;

import jakarta.mail.*;
import jakarta.mail.internet.*;
import java.io.InputStream;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

public class EmailUtil {
    private static final Logger LOGGER = Logger.getLogger(EmailUtil.class.getName());

    public static void sendAccountDetails(String toEmail, String fullName, String password) throws MessagingException {
        Properties props = new Properties();
        try (InputStream in = EmailUtil.class.getClassLoader().getResourceAsStream("application.properties")) {
            if (in != null) {
                props.load(in);
            } else {
                throw new MessagingException("Không tìm thấy tệp application.properties trong classpath của máy chủ.");
            }
        } catch (Exception e) {
            throw new MessagingException("Lỗi khi đọc tệp cấu hình application.properties: " + e.getMessage(), e);
        }

        String envUsername = System.getenv("DIABETESCARE_SMTP_USERNAME");
        String envPassword = System.getenv("DIABETESCARE_SMTP_PASSWORD");
        String envFrom = System.getenv("DIABETESCARE_SMTP_FROM");

        String host = props.getProperty("mail.smtp.host", "smtp.gmail.com");
        String port = props.getProperty("mail.smtp.port", "587");
        
        final String username = (envUsername != null && !envUsername.trim().isEmpty()) 
                ? envUsername.trim() 
                : props.getProperty("DIABETESCARE_SMTP_USERNAME");
                
        final String passwordAuth = (envPassword != null && !envPassword.trim().isEmpty()) 
                ? envPassword.trim() 
                : props.getProperty("DIABETESCARE_SMTP_PASSWORD");
                
        final String fromEmail = (envFrom != null && !envFrom.trim().isEmpty())
                ? envFrom.trim()
                : (props.getProperty("DIABETESCARE_SMTP_FROM") != null ? props.getProperty("DIABETESCARE_SMTP_FROM") : username);

        if (username == null || username.trim().isEmpty() || username.contains("your_email")) {
            throw new MessagingException("Tài khoản gửi email (SMTP Username) chưa được cấu hình.");
        }
        if (passwordAuth == null || passwordAuth.trim().isEmpty()) {
            throw new MessagingException("Mật khẩu tài khoản gửi email (SMTP Password) chưa được cấu hình.");
        }

        Properties mailProps = new Properties();
        mailProps.put("mail.smtp.auth", "true");
        mailProps.put("mail.smtp.starttls.enable", "true");
        mailProps.put("mail.smtp.host", host);
        mailProps.put("mail.smtp.port", port);
        mailProps.put("mail.smtp.ssl.protocols", "TLSv1.2");

        Session session = Session.getInstance(mailProps, new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(username, passwordAuth);
            }
        });

        try {
            MimeMessage message = new MimeMessage(session);
            message.setFrom(new InternetAddress(fromEmail));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail));
            message.setSubject("Tài khoản truy cập hệ thống DiabetesCare", "UTF-8");

            String htmlContent = "<h3>Kính gửi " + fullName + ",</h3>"
                    + "<p>Tài khoản của bạn đã được tạo thành công trên hệ thống <b>DiabetesCare</b>.</p>"
                    + "<p>Thông tin đăng nhập của bạn:</p>"
                    + "<ul>"
                    + "<li><b>Tên đăng nhập (Email):</b> " + toEmail + "</li>"
                    + "<li><b>Mật khẩu tạm thời:</b> " + password + "</li>"
                    + "</ul>"
                    + "<p>Vui lòng đăng nhập và đổi mật khẩu sớm nhất có thể.</p>"
                    + "<br/>"
                    + "<p>Trân trọng,<br/>Đội ngũ DiabetesCare</p>";

            message.setContent(htmlContent, "text/html; charset=UTF-8");
            Transport.send(message);
            LOGGER.log(Level.INFO, "Email sent successfully to " + toEmail);
        } catch (MessagingException e) {
            LOGGER.log(Level.SEVERE, "Failed to send email to " + toEmail, e);
            throw e;
        }
    }
}
