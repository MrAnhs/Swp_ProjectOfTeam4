package com.diabetes.monitoring.verification;

public final class Configuration {
    private Configuration() { }

    public static String value(String name) {
        String systemValue = System.getProperty(name);
        if (systemValue != null && !systemValue.isBlank()) return systemValue.trim();
        String environmentValue = System.getenv(name);
        return environmentValue == null || environmentValue.isBlank()
                ? null : environmentValue.trim();
    }

    public static String value(String name, String defaultValue) {
        String value = value(name);
        return value == null ? defaultValue : value;
    }

    public static boolean booleanValue(String name) {
        return Boolean.parseBoolean(value(name, "false"));
    }
}
