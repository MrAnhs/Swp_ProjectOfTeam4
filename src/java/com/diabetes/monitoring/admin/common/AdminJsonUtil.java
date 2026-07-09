package com.diabetes.monitoring.admin.common;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * Utility methods for lightweight JSON parsing and serialization in Admin APIs.
 */
public final class AdminJsonUtil {
    /**
     * Prevents instantiation of the AdminJsonUtil utility class.
     */
    private AdminJsonUtil() {
    }

    /**
     * Parses a small flat JSON payload used by Admin AJAX actions.
     */
    public static Map<String, String> parseSimpleJsonToMap(String json) {
        java.util.Map<String, String> result = new java.util.HashMap<>();
        if (json == null || json.isBlank()) {
            return result;
        }
        String body = json.trim();
        if (body.startsWith("{")) {
            body = body.substring(1);
        }
        if (body.endsWith("}")) {
            body = body.substring(0, body.length() - 1);
        }
        if (body.isBlank()) {
            return result;
        }

        String[] pairs = body.split(",(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)");
        for (String pair : pairs) {
            String[] kv = pair.split(":", 2);
            if (kv.length != 2) {
                continue;
            }
            String key = unquote(kv[0].trim());
            String value = unquote(kv[1].trim());
            result.put(key, value);
        }
        return result;
    }

    public static String toJsonSeries(List<Map<String, Object>> series) {
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < series.size(); i++) {
            if (i > 0) {
                sb.append(",");
            }
            Map<String, Object> item = series.get(i);
            sb.append("{\"period\":\"")
                    .append(escapeJson(String.valueOf(item.get("period"))))
                    .append("\",\"value\":")
                    .append(toBigDecimal(item.get("value")).toPlainString())
                    .append("}");
        }
        sb.append("]");
        return sb.toString();
    }

    public static String toJsonInvoices(List<Map<String, Object>> invoices) {
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < invoices.size(); i++) {
            if (i > 0) {
                sb.append(",");
            }
            Map<String, Object> inv = invoices.get(i);
            sb.append("{")
                    .append("\"invoiceId\":\"").append(escapeJson(String.valueOf(inv.get("invoiceId")))).append("\",")
                    .append("\"patientName\":\"").append(escapeJson(String.valueOf(inv.get("patientName")))).append("\",")
                    .append("\"totalAmount\":").append(toBigDecimal(inv.get("totalAmount")).toPlainString()).append(",")
                    .append("\"bhytDeduction\":").append(toBigDecimal(inv.get("bhytDeduction")).toPlainString()).append(",")
                    .append("\"finalAmount\":").append(toBigDecimal(inv.get("finalAmount")).toPlainString()).append(",")
                    .append("\"paymentDate\":\"").append(escapeJson(String.valueOf(inv.get("paymentDate")))).append("\"")
                    .append("}");
        }
        sb.append("]");
        return sb.toString();
    }

    public static String toJsonAppointments(List<Map<String, Object>> appointments) {
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < appointments.size(); i++) {
            if (i > 0) {
                sb.append(",");
            }
            Map<String, Object> apt = appointments.get(i);
            sb.append("{")
                    .append("\"appointmentId\":\"").append(escapeJson(String.valueOf(apt.get("appointmentId")))).append("\",")
                    .append("\"patientName\":\"").append(escapeJson(String.valueOf(apt.get("patientName")))).append("\",")
                    .append("\"doctorName\":\"").append(escapeJson(String.valueOf(apt.get("doctorName")))).append("\",")
                    .append("\"timeSlot\":\"").append(escapeJson(String.valueOf(apt.get("timeSlot")))).append("\",")
                    .append("\"bookingSource\":\"").append(escapeJson(String.valueOf(apt.get("bookingSource")))).append("\",")
                    .append("\"status\":\"").append(escapeJson(String.valueOf(apt.get("status")))).append("\",")
                    .append("\"appointmentDate\":\"").append(escapeJson(String.valueOf(apt.get("appointmentDate")))).append("\"")
                    .append("}");
        }
        sb.append("]");
        return sb.toString();
    }

    public static String toJsonInvoiceItems(List<Map<String, Object>> items) {
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < items.size(); i++) {
            if (i > 0) {
                sb.append(",");
            }
            Map<String, Object> item = items.get(i);
            sb.append("{")
                    .append("\"invoiceDetailId\":").append(parseInt(String.valueOf(item.get("invoiceDetailId")), 0)).append(",")
                    .append("\"invoiceId\":\"").append(escapeJson(String.valueOf(item.get("invoiceId")))).append("\",")
                    .append("\"serviceId\":").append(parseInt(String.valueOf(item.get("serviceId")), 0)).append(",")
                    .append("\"serviceName\":\"").append(escapeJson(String.valueOf(item.get("serviceName")))).append("\",")
                    .append("\"quantity\":").append(parseInt(String.valueOf(item.get("quantity")), 0)).append(",")
                    .append("\"unitPrice\":").append(toBigDecimal(item.get("unitPrice")).toPlainString()).append(",")
                    .append("\"lineTotal\":").append(toBigDecimal(item.get("lineTotal")).toPlainString())
                    .append("}");
        }
        sb.append("]");
        return sb.toString();
    }

    public static String toJsonSimpleRows(List<Map<String, Object>> rows) {
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < rows.size(); i++) {
            if (i > 0) {
                sb.append(",");
            }
            Map<String, Object> row = rows.get(i);
            sb.append("{");
            int fieldIndex = 0;
            for (Map.Entry<String, Object> entry : row.entrySet()) {
                if (fieldIndex++ > 0) {
                    sb.append(",");
                }
                sb.append("\"").append(escapeJson(entry.getKey())).append("\":");
                Object value = entry.getValue();
                if (value == null) {
                    sb.append("null");
                } else if (value instanceof Number || value instanceof Boolean) {
                    sb.append(String.valueOf(value));
                } else {
                    sb.append("\"").append(escapeJson(String.valueOf(value))).append("\"");
                }
            }
            sb.append("}");
        }
        sb.append("]");
        return sb.toString();
    }

    public static int parseInt(String raw, int fallback) {
        try {
            return Integer.parseInt(raw);
        } catch (Exception ex) {
            return fallback;
        }
    }

    public static BigDecimal toBigDecimal(Object value) {
        if (value == null) {
            return BigDecimal.ZERO;
        }
        if (value instanceof BigDecimal) {
            return (BigDecimal) value;
        }
        try {
            return new BigDecimal(String.valueOf(value));
        } catch (Exception ex) {
            return BigDecimal.ZERO;
        }
    }

    /**
     * Escapes text before embedding it in JSON responses.
     */
    public static String escapeJson(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "");
    }

    private static String unquote(String value) {
        String text = value == null ? "" : value.trim();
        if (text.startsWith("\"") && text.endsWith("\"") && text.length() >= 2) {
            text = text.substring(1, text.length() - 1);
        }
        return text.replace("\\\"", "\"")
                .replace("\\n", "\n")
                .replace("\\r", "\r")
                .replace("\\\\", "\\");
    }
}
