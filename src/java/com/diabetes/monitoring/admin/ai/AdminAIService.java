package com.diabetes.monitoring.admin.ai;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Orchestrates AI dataset review, model deployments, and retraining simulation.
 */
public class AdminAIService {

    private final AIDatasetRepository datasetRepository = new AIDatasetRepository();
    private final AITrainingRepository trainingRepository = new AITrainingRepository();

    // In-memory store for tracking active training session progress
    private static final Map<String, Map<String, Object>> activeTrainings = new ConcurrentHashMap<>();

    public Map<String, Object> getAiDashboardStats() {
        Map<String, Object> stats = new HashMap<>();
        
        // Active model info (Fetched from latest Completed training run)
        Map<String, Object> activeModel = trainingRepository.getActiveModel();
        stats.put("activeModel", activeModel);

        // Dataset overview counts
        int totalDataset = datasetRepository.getTotalDatasetCount();
        int approvedDataset = datasetRepository.getApprovedDatasetCount();
        int pendingDataset = datasetRepository.getPendingDatasetCount();
        stats.put("totalDataset", totalDataset);
        stats.put("approvedDataset", approvedDataset);
        stats.put("pendingDataset", pendingDataset);

        // Recent history
        List<Map<String, Object>> trainingHistory = trainingRepository.getTrainingHistory();
        stats.put("trainingHistory", trainingHistory.isEmpty() ? new ArrayList<>() : trainingHistory);

        return stats;
    }

    public List<Map<String, Object>> getDatasetRecords(String patientIdSearch, String doctorFilter, String statusFilter, String qualityFilter, int page, int pageSize) {
        return datasetRepository.getDatasetRecords(patientIdSearch, doctorFilter, statusFilter, qualityFilter, page, pageSize);
    }

    public int getDatasetRecordsCount(String patientIdSearch, String doctorFilter, String statusFilter, String qualityFilter) {
        return datasetRepository.getDatasetRecordsCount(patientIdSearch, doctorFilter, statusFilter, qualityFilter);
    }

    public Map<String, Object> getDatasetRecordDetail(int recordId) {
        return datasetRepository.getDatasetRecordDetail(recordId);
    }

    public boolean updateDatasetDecision(int recordId, String status, String reason, int adminAccountId) {
        return datasetRepository.updateDatasetDecision(recordId, status, reason, adminAccountId);
    }

    public boolean updateDatasetDecisionsBulk(List<Integer> recordIds, String status, String reason, int adminAccountId) {
        return datasetRepository.updateDatasetDecisionsBulk(recordIds, status, reason, adminAccountId);
    }

    public Map<String, Integer> getGlobalPendingCounts() {
        return datasetRepository.getGlobalPendingCounts();
    }

    public boolean approveAllDatasetGlobal(int limit, int adminAccountId) {
        return datasetRepository.approveAllDatasetGlobal(limit, adminAccountId);
    }

    public List<Map<String, Object>> getTrainingHistory() {
        return trainingRepository.getTrainingHistory();
    }

    public String startRetraining(List<String> selectedModels, int totalRecords) {
        String timestamp = new java.text.SimpleDateFormat("yyyyMMdd-HHmmss").format(new java.util.Date());
        String trainingId = "TR-" + timestamp;
        
        // Prepare initial progress state
        Map<String, Object> progressState = new ConcurrentHashMap<>();
        progressState.put("status", "Running");
        progressState.put("totalRecords", totalRecords);
        
        activeTrainings.put(trainingId, progressState);

        // Insert pending training record to DB (Dataset v1.5)
        trainingRepository.insertTrainingHistory(trainingId, "Dataset v1.5", totalRecords, "Running", null, null);

        // Start background thread to simulate training process quickly
        new Thread(() -> {
            try {
                // Short sleep to let the user see the loading state
                Thread.sleep(1500);

                // Fixed realistic Python AI metrics
                double accXGB = 98.07;
                double accRF = 97.05;
                double accLR = 89.20;
                
                double f1XGB = 98.01;
                double f1RF = 96.80;
                double f1LR = 88.50;

                String bestModel = "XGBoost";
                String bestAlgorithm = "XGBoost";
                double bestAcc = accXGB;
                double bestF1 = f1XGB;

                // JSON Metrics structure with exact Python outcomes
                String json = "{" +
                    "\"XGBoost\":{\"Algorithm\":\"XGBoost\",\"Accuracy\":" + accXGB + ",\"F1\":" + f1XGB + "}," +
                    "\"Random Forest\":{\"Algorithm\":\"Random Forest\",\"Accuracy\":" + accRF + ",\"F1\":" + f1RF + "}," +
                    "\"Logistic Regression\":{\"Algorithm\":\"Logistic Regression\",\"Accuracy\":" + accLR + ",\"F1\":" + f1LR + "}" +
                    "}";

                // Update Training History record in DB (Store "XGBoost" as the best model name)
                trainingRepository.updateTrainingStatus(trainingId, "Completed", bestModel, json);

                // Update in-memory state
                progressState.put("status", "Completed");
                progressState.put("bestModel", bestModel);
                progressState.put("bestModelVersion", trainingId); // Display training run ID as identifier
                progressState.put("bestAlgorithm", bestAlgorithm);
                progressState.put("bestAccuracy", bestAcc);
                progressState.put("bestF1", bestF1);
                progressState.put("metricsJson", json);

            } catch (Exception e) {
                e.printStackTrace();
                progressState.put("status", "Failed");
                trainingRepository.updateTrainingStatus(trainingId, "Failed", null, null);
            }
        }).start();

        return trainingId;
    }

    public Map<String, Object> getTrainingProgress(String trainingId) {
        return activeTrainings.get(trainingId);
    }
}
