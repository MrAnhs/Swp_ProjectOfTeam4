package com.diabetes.monitoring.verification;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.HexFormat;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

public class OtpSecurity {
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final byte[] PROCESS_FALLBACK_SECRET = createFallbackSecret();
    private final byte[] secret;

    public OtpSecurity() {
        String configuredSecret = Configuration.value("DIABETESCARE_OTP_SECRET");
        if (configuredSecret == null || configuredSecret.length() < 32) {
            this.secret = PROCESS_FALLBACK_SECRET;
        } else {
            this.secret = configuredSecret.getBytes(StandardCharsets.UTF_8);
        }
    }

    public String generateOtp() {
        return String.format("%06d", RANDOM.nextInt(1_000_000));
    }

    public String hash(String purpose, String email, String otp) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret, "HmacSHA256"));
            byte[] value = (purpose + "\n" + email.toLowerCase() + "\n" + otp)
                    .getBytes(StandardCharsets.UTF_8);
            return HexFormat.of().formatHex(mac.doFinal(value));
        } catch (Exception e) {
            throw new IllegalStateException("Unable to hash OTP", e);
        }
    }

    public boolean matches(String expectedHash, String purpose, String email, String otp) {
        if (expectedHash == null || otp == null) return false;
        byte[] expected = expectedHash.getBytes(StandardCharsets.US_ASCII);
        byte[] actual = hash(purpose, email, otp).getBytes(StandardCharsets.US_ASCII);
        return MessageDigest.isEqual(expected, actual);
    }

    private static byte[] createFallbackSecret() {
        byte[] generated = new byte[32];
        RANDOM.nextBytes(generated);
        return generated;
    }
}
