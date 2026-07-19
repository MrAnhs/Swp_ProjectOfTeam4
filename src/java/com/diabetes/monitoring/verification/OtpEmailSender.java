package com.diabetes.monitoring.verification;

public interface OtpEmailSender {
    void send(String targetEmail, String purpose, String otp, int expiryMinutes)
            throws Exception;
}
