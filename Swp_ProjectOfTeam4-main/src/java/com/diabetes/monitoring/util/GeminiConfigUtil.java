package com.diabetes.monitoring.util;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Properties;
import java.util.Set;

public final class GeminiConfigUtil {
    private static final String DEFAULT_MODEL = "gemini-3.5-flash";
    private static final String FAST_FALLBACK_MODEL = "gemini-2.5-flash";
    private static final String LOCAL_CONFIG_RESOURCE = "gemini-local.properties";
    private static final Properties LOCAL_CONFIG = loadLocalConfig();

    private GeminiConfigUtil() {
    }

    public static String getRecommendationApiKey() {
        List<String> apiKeys = getRecommendationApiKeys();
        return apiKeys.isEmpty() ? null : apiKeys.get(0);
    }

    public static String getAntiFraudApiKey() {
        List<String> apiKeys = getAntiFraudApiKeys();
        return apiKeys.isEmpty() ? null : apiKeys.get(0);
    }

    public static List<String> getRecommendationApiKeys() {
        return collectApiKeys(
                System.getenv("RECOMMENDATION_GEMINI_API_KEYS"),
                System.getenv("RECOMMENDATION_GEMINI_API_KEY"),
                getLocalConfig("RECOMMENDATION_GEMINI_API_KEYS"),
                getLocalConfig("RECOMMENDATION_GEMINI_API_KEY"),
                System.getenv("GEMINI_API_KEYS"),
                System.getenv("GEMINI_API_KEY"),
                getLocalConfig("GEMINI_API_KEYS"),
                getLocalConfig("GEMINI_API_KEY"));
    }

    public static List<String> getAntiFraudApiKeys() {
        return collectApiKeys(
                System.getenv("ANTIFRAUD_GEMINI_API_KEYS"),
                System.getenv("ANTIFRAUD_GEMINI_API_KEY"),
                getLocalConfig("ANTIFRAUD_GEMINI_API_KEYS"),
                getLocalConfig("ANTIFRAUD_GEMINI_API_KEY"),
                System.getenv("GEMINI_API_KEYS"),
                System.getenv("GEMINI_API_KEY"),
                getLocalConfig("GEMINI_API_KEYS"),
                getLocalConfig("GEMINI_API_KEY"));
    }

    public static List<String> getSchedulingApiKeys() {
        return collectApiKeys(
                System.getenv("SCHEDULING_GEMINI_API_KEYS"),
                System.getenv("SCHEDULING_GEMINI_API_KEY"),
                getLocalConfig("SCHEDULING_GEMINI_API_KEYS"),
                getLocalConfig("SCHEDULING_GEMINI_API_KEY"),
                System.getenv("RECOMMENDATION_GEMINI_API_KEYS"),
                System.getenv("RECOMMENDATION_GEMINI_API_KEY"),
                getLocalConfig("RECOMMENDATION_GEMINI_API_KEYS"),
                getLocalConfig("RECOMMENDATION_GEMINI_API_KEY"),
                System.getenv("GEMINI_API_KEYS"),
                System.getenv("GEMINI_API_KEY"),
                getLocalConfig("GEMINI_API_KEYS"),
                getLocalConfig("GEMINI_API_KEY"));
    }

    public static String getRecommendationModel() {
        return normalizeModelName(firstNonBlank(
                System.getenv("RECOMMENDATION_GEMINI_MODEL"),
                getLocalConfig("RECOMMENDATION_GEMINI_MODEL"),
                System.getenv("GEMINI_MODEL"),
                getLocalConfig("GEMINI_MODEL"),
                DEFAULT_MODEL));
    }

    public static String getAntiFraudModel() {
        return normalizeModelName(firstNonBlank(
                System.getenv("ANTIFRAUD_GEMINI_MODEL"),
                getLocalConfig("ANTIFRAUD_GEMINI_MODEL"),
                System.getenv("GEMINI_MODEL"),
                getLocalConfig("GEMINI_MODEL"),
                DEFAULT_MODEL));
    }

    public static String getSchedulingModel() {
        return normalizeModelName(firstNonBlank(
                System.getenv("SCHEDULING_GEMINI_MODEL"),
                getLocalConfig("SCHEDULING_GEMINI_MODEL"),
                System.getenv("RECOMMENDATION_GEMINI_MODEL"),
                getLocalConfig("RECOMMENDATION_GEMINI_MODEL"),
                System.getenv("GEMINI_MODEL"),
                getLocalConfig("GEMINI_MODEL"),
                DEFAULT_MODEL));
    }

    public static List<String> getRecommendationModelCandidates() {
        return collectModelCandidates(
                System.getenv("RECOMMENDATION_GEMINI_MODEL"),
                getLocalConfig("RECOMMENDATION_GEMINI_MODEL"),
                System.getenv("GEMINI_MODEL"),
                getLocalConfig("GEMINI_MODEL"));
    }

    public static List<String> getAntiFraudModelCandidates() {
        return collectModelCandidates(
                System.getenv("ANTIFRAUD_GEMINI_MODEL"),
                getLocalConfig("ANTIFRAUD_GEMINI_MODEL"),
                System.getenv("GEMINI_MODEL"),
                getLocalConfig("GEMINI_MODEL"));
    }

    public static List<String> getSchedulingModelCandidates() {
        return collectModelCandidates(
                System.getenv("SCHEDULING_GEMINI_MODEL"),
                getLocalConfig("SCHEDULING_GEMINI_MODEL"),
                System.getenv("RECOMMENDATION_GEMINI_MODEL"),
                getLocalConfig("RECOMMENDATION_GEMINI_MODEL"),
                System.getenv("GEMINI_MODEL"),
                getLocalConfig("GEMINI_MODEL"));
    }

    public static GeminiStatus checkService(String serviceName, List<String> apiKeys, String model) {
        GeminiStatus status = new GeminiStatus();
        status.serviceName = serviceName;
        status.model = firstNonBlank(model, DEFAULT_MODEL);
        status.configuredKeys = apiKeys == null ? new ArrayList<>() : new ArrayList<>(apiKeys);
        status.keyCount = status.configuredKeys.size();
        status.keyConfigured = !status.configuredKeys.isEmpty();

        if (!status.keyConfigured) {
            status.available = false;
            status.statusCode = 0;
            status.message = "Chưa cấu hình API key";
            return status;
        }

        for (int index = 0; index < status.configuredKeys.size(); index++) {
            String apiKey = status.configuredKeys.get(index);
            HttpURLConnection conn = null;
            try {
                URL url = new URL("https://generativelanguage.googleapis.com/v1/models/"
                        + status.model + "?key=" + apiKey);
                conn = (HttpURLConnection) url.openConnection();
                conn.setRequestMethod("GET");
                conn.setRequestProperty("Accept", "application/json");
                conn.setConnectTimeout(5000);
                conn.setReadTimeout(8000);

                int responseCode = conn.getResponseCode();
                String responseBody = readResponseBody(conn, responseCode >= 200 && responseCode < 300);
                String message = buildStatusMessage(status.model, responseCode, responseBody);

                status.attemptedKeyCount++;
                status.keyResults.add(new GeminiKeyResult(index + 1, apiKey, responseCode, responseCode == 200, message));
                status.statusCode = responseCode;

                if (responseCode == 200) {
                    status.available = true;
                    status.activeKeyIndex = index + 1;
                    status.message = "Kết nối Gemini thành công với key #" + (index + 1) + "/" + status.keyCount;
                    return status;
                }
                status.message = message;
            } catch (IOException e) {
                status.available = false;
                status.statusCode = -1;
                status.attemptedKeyCount++;
                String message = "Không thể kết nối Gemini: " + compact(e.getMessage());
                status.keyResults.add(new GeminiKeyResult(index + 1, apiKey, -1, false, message));
                status.message = message;
            } finally {
                if (conn != null) {
                    conn.disconnect();
                }
            }
        }

        if (!status.keyResults.isEmpty()) {
            GeminiKeyResult lastResult = status.keyResults.get(status.keyResults.size() - 1);
            status.statusCode = lastResult.statusCode;
            status.message = "Đã thử " + status.keyResults.size() + "/" + status.keyCount
                    + " key nhưng chưa kết nối thành công. Lỗi cuối: " + lastResult.message;
        }
        return status;
    }

    private static String readResponseBody(HttpURLConnection conn, boolean success) throws IOException {
        if (conn == null) {
            return "";
        }
        InputStream stream = success ? conn.getInputStream() : conn.getErrorStream();
        if (stream == null) {
            return "";
        }
        try (BufferedReader br = new BufferedReader(
                new InputStreamReader(stream, StandardCharsets.UTF_8))) {
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = br.readLine()) != null) {
                sb.append(line);
            }
            return sb.toString();
        }
    }

    private static String firstNonBlank(String... values) {
        if (values == null) {
            return null;
        }
        for (String value : values) {
            if (value != null && !value.isBlank()) {
                return value;
            }
        }
        return null;
    }

    private static Properties loadLocalConfig() {
        Properties properties = new Properties();
        try (InputStream input = GeminiConfigUtil.class.getResourceAsStream(LOCAL_CONFIG_RESOURCE)) {
            if (input != null) {
                properties.load(input);
            }
        } catch (IOException ignored) {
            // Local config is optional.
        }
        return properties;
    }

    private static String getLocalConfig(String key) {
        if (LOCAL_CONFIG == null || key == null) {
            return null;
        }
        String value = LOCAL_CONFIG.getProperty(key);
        return value == null || value.isBlank() ? null : value.trim();
    }

    private static List<String> collectApiKeys(String... rawValues) {
        Set<String> deduplicated = new LinkedHashSet<>();
        if (rawValues != null) {
            for (String rawValue : rawValues) {
                if (rawValue == null || rawValue.isBlank()) {
                    continue;
                }
                String[] tokens = rawValue.split("[,;\\r\\n]+");
                for (String token : tokens) {
                    String trimmed = token == null ? "" : token.trim();
                    if (!trimmed.isEmpty() && !"YOUR_GEMINI_API_KEY".equals(trimmed)) {
                        deduplicated.add(trimmed);
                    }
                }
            }
        }
        return new ArrayList<>(deduplicated);
    }

    private static String compact(String input) {
        if (input == null) {
            return "";
        }
        String normalized = input.replaceAll("\\s+", " ").trim();
        if (normalized.length() > 220) {
            return normalized.substring(0, 217) + "...";
        }
        return normalized;
    }

    private static String buildStatusMessage(String model, int responseCode, String responseBody) {
        if (responseCode == 200) {
            return "Kết nối Gemini thành công";
        }
        if (responseCode == 429) {
            if (responseBody != null && responseBody.contains("limit: 0")) {
                return "Quota của project hiện bằng 0 cho model này. Cần bật billing hoặc chuyển sang project có quota.";
            }
            return "Gemini đang trả 429: " + compact(responseBody);
        }
        if (responseCode == 404 && isLegacyModel(model)) {
            return "Model " + model
                    + " không còn hỗ trợ trên Gemini API hiện tại. Hãy chuyển sang "
                    + DEFAULT_MODEL + " hoặc model mới hơn.";
        }
        return "Gemini trả HTTP " + responseCode + ": " + compact(responseBody);
    }

    private static String normalizeModelName(String model) {
        String resolved = firstNonBlank(model, DEFAULT_MODEL);
        if (resolved == null) {
            return DEFAULT_MODEL;
        }
        if (isLegacyModel(resolved)) {
            return DEFAULT_MODEL;
        }
        return resolved.trim();
    }

    private static List<String> collectModelCandidates(String... rawValues) {
        Set<String> models = new LinkedHashSet<>();
        if (rawValues != null) {
            for (String rawValue : rawValues) {
                String normalized = normalizeModelName(rawValue);
                if (normalized != null && !normalized.isBlank()) {
                    models.add(normalized);
                }
            }
        }
        models.add(FAST_FALLBACK_MODEL);
        models.add(DEFAULT_MODEL);
        return new ArrayList<>(models);
    }

    private static boolean isLegacyModel(String model) {
        if (model == null) {
            return false;
        }
        String normalized = model.trim().toLowerCase();
        return normalized.startsWith("gemini-1.5-flash")
                || normalized.startsWith("gemini-1.5-pro")
                || normalized.startsWith("gemini-2.0-flash");
    }

    public static final class GeminiStatus {
        public String serviceName;
        public String model;
        public boolean keyConfigured;
        public boolean available;
        public int statusCode;
        public String message;
        public int keyCount;
        public int attemptedKeyCount;
        public int activeKeyIndex;
        public List<String> configuredKeys = new ArrayList<>();
        public List<GeminiKeyResult> keyResults = new ArrayList<>();
    }

    public static final class GeminiKeyResult {
        public final int index;
        public final String apiKey;
        public final int statusCode;
        public final boolean available;
        public final String message;

        public GeminiKeyResult(int index, String apiKey, int statusCode, boolean available, String message) {
            this.index = index;
            this.apiKey = apiKey;
            this.statusCode = statusCode;
            this.available = available;
            this.message = message;
        }
    }
}
