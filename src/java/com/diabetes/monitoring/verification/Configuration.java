package com.diabetes.monitoring.verification;

import java.io.InputStream;
import java.util.Properties;

public final class Configuration {
    private static final Properties PROPS = new Properties();

    static {
        try (InputStream in = Configuration.class.getClassLoader().getResourceAsStream("application.properties")) {
            if (in != null) {
                PROPS.load(in);
            }
        } catch (Exception ignored) { }
    }

    private Configuration() { }

    public static String value(String name) {
        String systemValue = System.getProperty(name);
        if (systemValue != null && !systemValue.isBlank()) return systemValue.trim();
        String environmentValue = System.getenv(name);
        if (environmentValue != null && !environmentValue.isBlank()) return environmentValue.trim();
        String propValue = PROPS.getProperty(name);
        return propValue == null || propValue.isBlank() ? null : propValue.trim();
    }

    public static String value(String name, String defaultValue) {
        String value = value(name);
        return value == null ? defaultValue : value;
    }

    public static boolean booleanValue(String name) {
        return Boolean.parseBoolean(value(name, "false"));
    }
}
