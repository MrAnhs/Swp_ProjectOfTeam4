package com.diabetes.monitoring.util;

import java.util.Locale;
import java.util.regex.Pattern;

public final class InputValidationUtil {
    private static final Pattern EMAIL_PATTERN = Pattern.compile(
            "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
    );

    // Vietnamese mobile numbers: 03x, 05x, 07x, 08x, 09x prefixes with 10 national digits.
    private static final Pattern VIETNAM_MOBILE_PATTERN = Pattern.compile(
            "^0(3[2-9]|5[2689]|7[06-9]|8[1-689]|9[0-46-9])\\d{7}$"
    );

    private InputValidationUtil() {
    }

    public static String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    public static String normalizeEmail(String email) {
        String normalized = trimToNull(email);
        return normalized == null ? null : normalized.toLowerCase(Locale.ROOT);
    }

    public static boolean isValidEmail(String email) {
        return email != null && EMAIL_PATTERN.matcher(email).matches();
    }

    public static String normalizeVietnamesePhone(String phone) {
        String normalized = trimToNull(phone);
        if (normalized == null) {
            return null;
        }

        normalized = normalized.replaceAll("[\\s.\\-()]", "");
        if (normalized.startsWith("+84")) {
            normalized = "0" + normalized.substring(3);
        } else if (normalized.startsWith("84") && normalized.length() == 11) {
            normalized = "0" + normalized.substring(2);
        }

        return normalized;
    }

    public static boolean isValidVietnameseMobilePhone(String phone) {
        String normalized = normalizeVietnamesePhone(phone);
        return normalized != null && VIETNAM_MOBILE_PATTERN.matcher(normalized).matches();
    }
}
