package com.diabetes.monitoring.verification;

import java.time.LocalDateTime;

public class EmailVerification {
    private long verificationId;
    private Integer accountId;
    private String purpose;
    private String targetEmail;
    private String otpHash;
    private LocalDateTime expiresAt;
    private int failedAttempts;

    public long getVerificationId() { return verificationId; }
    public void setVerificationId(long verificationId) { this.verificationId = verificationId; }
    public Integer getAccountId() { return accountId; }
    public void setAccountId(Integer accountId) { this.accountId = accountId; }
    public String getPurpose() { return purpose; }
    public void setPurpose(String purpose) { this.purpose = purpose; }
    public String getTargetEmail() { return targetEmail; }
    public void setTargetEmail(String targetEmail) { this.targetEmail = targetEmail; }
    public String getOtpHash() { return otpHash; }
    public void setOtpHash(String otpHash) { this.otpHash = otpHash; }
    public LocalDateTime getExpiresAt() { return expiresAt; }
    public void setExpiresAt(LocalDateTime expiresAt) { this.expiresAt = expiresAt; }
    public int getFailedAttempts() { return failedAttempts; }
    public void setFailedAttempts(int failedAttempts) { this.failedAttempts = failedAttempts; }
}
