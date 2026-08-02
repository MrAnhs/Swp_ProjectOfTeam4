package com.diabetes.monitoring.util;

import jakarta.mail.*;
import jakarta.mail.internet.*;
import java.io.InputStream;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

public class EmailUtil {
    private static final Logger LOGGER = Logger.getLogger(EmailUtil.class.getName());
    private static final Properties PROPS = new Properties();

    static {
        try (InputStream in = EmailUtil.class.getClassLoader().getResourceAsStream("application.properties")) {
            if (in != null) {
                PROPS.load(in);
            } else {
                LOGGER.log(Level.SEVERE, "application.properties not found in classpath!");
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to load application.properties", e);
        }
    }

    public static void sendAccountDetails(String toEmail, String fullName, String password) throws MessagingException {
        String envUsername = System.getenv("DIABETESCARE_SMTP_USERNAME");
        String envPassword = System.getenv("DIABETESCARE_SMTP_PASSWORD");
        String envFrom = System.getenv("DIABETESCARE_SMTP_FROM");

        String host = PROPS.getProperty("mail.smtp.host", "smtp.gmail.com");
        String port = PROPS.getProperty("mail.smtp.port", "587");
        
        final String username = (envUsername != null && !envUsername.trim().isEmpty()) 
                ? envUsername.trim() 
                : PROPS.getProperty("DIABETESCARE_SMTP_USERNAME", "diabetescare.system.swp@gmail.com");
                
        final String passwordAuth = (envPassword != null && !envPassword.trim().isEmpty()) 
                ? envPassword.trim() 
                : PROPS.getProperty("DIABETESCARE_SMTP_PASSWORD", "xuyoblvebidpeqmr");
                
        final String fromEmail = (envFrom != null && !envFrom.trim().isEmpty())
                ? envFrom.trim()
                : (PROPS.getProperty("DIABETESCARE_SMTP_FROM") != null ? PROPS.getProperty("DIABETESCARE_SMTP_FROM") : username);

        if (username == null || username.trim().isEmpty() || username.contains("your_email")) {
            LOGGER.log(Level.WARNING, "SMTP Username not configured. Skipping email sending.");
            return;
        }

        Properties mailProps = new Properties();
        mailProps.put("mail.smtp.auth", "true");
        mailProps.put("mail.smtp.starttls.enable", "true");
        mailProps.put("mail.smtp.starttls.required", "true");
        mailProps.put("mail.smtp.host", host);
        mailProps.put("mail.smtp.port", port);
        mailProps.put("mail.smtp.ssl.protocols", "TLSv1.2");
        mailProps.put("mail.smtp.connectiontimeout", "10000");
        mailProps.put("mail.smtp.timeout", "10000");
        mailProps.put("mail.smtp.writetimeout", "10000");

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
