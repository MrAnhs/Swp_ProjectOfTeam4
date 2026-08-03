package com.diabetes.monitoring.verification;

import jakarta.mail.Authenticator;
import jakarta.mail.Message;
import jakarta.mail.MessagingException;
import jakarta.mail.PasswordAuthentication;
import jakarta.mail.Session;
import jakarta.mail.Transport;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;
import java.util.Properties;
import java.util.logging.Logger;

public class SmtpOtpEmailSender implements OtpEmailSender {
    private static final Logger LOGGER = Logger.getLogger(SmtpOtpEmailSender.class.getName());

    @Override
    public void send(String targetEmail, String purpose, String otp, int expiryMinutes)
            throws Exception {
        if (Configuration.booleanValue("DIABETESCARE_OTP_DEV_MODE")) {
            LOGGER.warning("Development OTP for " + targetEmail + " (" + purpose + "): " + otp);
            return;
        }

        String host = Configuration.value("DIABETESCARE_SMTP_HOST", "smtp.gmail.com");
        String port = Configuration.value("DIABETESCARE_SMTP_PORT", "587");
        String username = Configuration.value("DIABETESCARE_SMTP_USERNAME", "diabetescare.system.swp@gmail.com");
        String password = Configuration.value("DIABETESCARE_SMTP_PASSWORD", "xuyoblvebidpeqmr");
        String from = Configuration.value("DIABETESCARE_SMTP_FROM", username);

        Properties properties = new Properties();
        properties.put("mail.smtp.auth", "true");
        properties.put("mail.smtp.starttls.enable", "true");
        properties.put("mail.smtp.starttls.required", "true");
        properties.put("mail.smtp.host", host);
        properties.put("mail.smtp.port", port);
        properties.put("mail.smtp.ssl.trust", "*");
        properties.put("mail.smtp.connectiontimeout", "10000");
        properties.put("mail.smtp.timeout", "10000");
        properties.put("mail.smtp.writetimeout", "10000");

        Session session = Session.getInstance(properties, new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(username, password);
            }
        });

        MimeMessage message = new MimeMessage(session);
        message.setFrom(new InternetAddress(from, "DiabetesCare", "UTF-8"));
        message.setRecipient(Message.RecipientType.TO, new InternetAddress(targetEmail));
        message.setSubject(subject(purpose), "UTF-8");
        message.setText(body(otp, expiryMinutes), "UTF-8");
        Transport.send(message);
    }

    private String required(String name) throws MessagingException {
        String value = Configuration.value(name);
        if (value == null) {
            throw new MessagingException("Missing SMTP configuration: " + name);
        }
        return value;
    }

    private String subject(String purpose) {
        if (EmailVerificationService.CHANGE_EMAIL.equals(purpose)) {
            return "M\u00E3 x\u00E1c th\u1EF1c thay \u0111\u00ED email - DiabetesCare";
        }
        if (EmailVerificationService.REGISTER.equals(purpose)) {
            return "M\u00E3 x\u00E1c th\u1EF1c \u0111\u0103ng k\u00FD t\u00E0i kho\u1EA3n - DiabetesCare";
        }
        return "M\u00E3 x\u00E1c th\u1EF1c \u0111\u1EB7t l\u1EA1i m\u1EADt kh\u1EA9u - DiabetesCare";
    }

    private String body(String otp, int expiryMinutes) {
        return "M\u00E3 x\u00E1c th\u1EF1c DiabetesCare c\u1EE7a b\u1EA1n l\u00E0: " + otp
                + "\n\nM\u00E3 c\u00F3 hi\u1EC7u l\u1EF1c trong " + expiryMinutes + " ph\u00FAt."
                + "\nKh\u00F4ng cung c\u1EA5p m\u00E3 n\u00E0y cho ng\u01B0\u1EDDi kh\u00E1c."
                + "\nN\u1EBFu b\u1EA1n kh\u00F4ng th\u1EF1c hi\u1EC7n y\u00EAu c\u1EA7u, h\u00E3y b\u1ECF qua email n\u00E0y.";
    }
}
