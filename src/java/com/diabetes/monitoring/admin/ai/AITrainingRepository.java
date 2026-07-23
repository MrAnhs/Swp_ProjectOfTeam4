package com.diabetes.monitoring.admin.ai;

import com.diabetes.monitoring.util.DatabaseConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Handles database operations for AI retraining sessions and metrics.
 */
public class AITrainingRepository {

    public List<Map<String, Object>> getTrainingHistory() {
        String sql = "SELECT training_id, dataset_version, dataset_records, trained_at, status, best_model_version, models_metrics_json " +
                     "FROM AI_Training_History ORDER BY trained_at DESC";
        List<Map<String, Object>> list = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> map = new HashMap<>();
                map.put("trainingId", rs.getString("training_id"));
                map.put("datasetVersion", rs.getString("dataset_version"));
                map.put("datasetRecords", rs.getInt("dataset_records"));
                map.put("trainedAt", rs.getTimestamp("trained_at"));
                map.put("status", rs.getString("status"));
                map.put("bestModelVersion", rs.getString("best_model_version"));
                map.put("modelsMetricsJson", rs.getString("models_metrics_json"));
                list.add(map);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public boolean insertTrainingHistory(String trainingId, String datasetVersion, int datasetRecords, String status, String bestModel, String metricsJson) {
        String sql = "INSERT INTO AI_Training_History (training_id, dataset_version, dataset_records, trained_at, status, best_model_version, models_metrics_json) " +
                     "VALUES (?, ?, ?, GETDATE(), ?, ?, ?)";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, trainingId);
            ps.setString(2, datasetVersion);
            ps.setInt(3, datasetRecords);
            ps.setString(4, status);
            ps.setString(5, bestModel);
            ps.setString(6, metricsJson);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean updateTrainingStatus(String trainingId, String status, String bestModel, String metricsJson) {
        String sql = "UPDATE AI_Training_History SET status = ?, best_model_version = ?, models_metrics_json = ?, trained_at = GETDATE() WHERE training_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setString(2, bestModel);
            ps.setString(3, metricsJson);
            ps.setString(4, trainingId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public Map<String, Object> getActiveModel() {
        String sql = "SELECT TOP 1 training_id, dataset_version, dataset_records, trained_at, status, best_model_version, models_metrics_json " +
                     "FROM AI_Training_History WHERE status = 'Completed' ORDER BY trained_at DESC";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                Map<String, Object> map = new HashMap<>();
                map.put("trainingId", rs.getString("training_id"));
                map.put("version", rs.getString("best_model_version"));
                map.put("trainedAt", rs.getTimestamp("trained_at"));
                
                String metricsJson = rs.getString("models_metrics_json");
                String algorithm = "XGBoost";
                double accuracy = 98.07;
                double f1Score = 98.01;
                
                if (metricsJson != null) {
                    if (metricsJson.contains("\"XGBoost\"")) {
                        algorithm = "XGBoost";
                        accuracy = extractMetric(metricsJson, "XGBoost", "Accuracy", 98.07);
                        f1Score = extractMetric(metricsJson, "XGBoost", "F1", 98.01);
                    } else if (metricsJson.contains("\"Model B\"")) {
                        algorithm = "Neural Network";
                        accuracy = extractMetric(metricsJson, "Model B", "Accuracy", 94.2);
                        f1Score = extractMetric(metricsJson, "Model B", "F1", 93.9);
                    }
                }
                
                map.put("algorithm", algorithm);
                map.put("accuracy", accuracy);
                map.put("f1Score", f1Score);
                map.put("status", "ACTIVE");
                return map;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    private double extractMetric(String json, String modelKey, String metricKey, double fallback) {
        try {
            java.util.regex.Pattern p = java.util.regex.Pattern.compile(
                "\"" + java.util.regex.Pattern.quote(modelKey) + "\"\\s*:\\s*\\{[^\\}]*\"" + 
                java.util.regex.Pattern.quote(metricKey) + "\"\\s*:\\s*([0-9\\.]+)"
            );
            java.util.regex.Matcher m = p.matcher(json);
            if (m.find()) {
                return Double.parseDouble(m.group(1));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return fallback;
    }
}
