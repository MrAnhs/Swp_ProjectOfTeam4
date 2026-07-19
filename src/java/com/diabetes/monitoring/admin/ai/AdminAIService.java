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

        // Start background thread to run Python AI training process actually
        new Thread(() -> {
            try {
                // 1. Determine directories and path to Python script
                java.io.File workingDir = new java.io.File("../Diabetes-Prediction-System/Diabetes-Prediction-System");
                if (!workingDir.exists()) {
                    workingDir = new java.io.File("D:/ky5/Github_SWP391/Diabetes-Prediction-System/Diabetes-Prediction-System");
                }

                // 2. Select python executable path
                java.io.File pythonExe = new java.io.File(workingDir, ".venv/Scripts/python.exe");
                if (!pythonExe.exists()) {
                    pythonExe = new java.io.File(workingDir, "venv/Scripts/python.exe");
                }
                
                String pythonCmd = pythonExe.exists() ? pythonExe.getAbsolutePath() : "python";

                // 3. Build Process to run retraining
                ProcessBuilder pb = new ProcessBuilder(pythonCmd, "retrain_auto.py");
                pb.directory(workingDir);
                pb.redirectErrorStream(true);

                // Set WANDB_API_KEY to login and bypass interactive prompt automatically
                pb.environment().put("WANDB_API_KEY", "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");

                Process process = pb.start();

                // 4. Read script output logs to console
                try (java.io.BufferedReader reader = new java.io.BufferedReader(
                        new java.io.InputStreamReader(process.getInputStream(), java.nio.charset.StandardCharsets.UTF_8))) {
                    String line;
                    while ((line = reader.readLine()) != null) {
                        System.out.println("[Python AI Training Process]: " + line);
                    }
                }

                int exitCode = process.waitFor();
                if (exitCode == 0) {
                    // 5. Parse latest metrics from auto_training_history.csv
                    java.io.File csvFile = new java.io.File(workingDir, "Results/auto_training_history.csv");
                    Map<String, Map<String, Object>> metrics = parseLatestMetricsFromCsv(csvFile);

                    double accXGB = 0.0;
                    double accRF = 0.0;
                    double accLR = 0.0;
                    
                    double f1XGB = 0.0;
                    double f1RF = 0.0;
                    double f1LR = 0.0;

                    if (metrics.containsKey("XGBoost")) {
                        accXGB = (double) metrics.get("XGBoost").get("Accuracy");
                        f1XGB = (double) metrics.get("XGBoost").get("F1");
                    }
                    if (metrics.containsKey("Random Forest")) {
                        accRF = (double) metrics.get("Random Forest").get("Accuracy");
                        f1RF = (double) metrics.get("Random Forest").get("F1");
                    }
                    if (metrics.containsKey("Logistic Regression")) {
                        accLR = (double) metrics.get("Logistic Regression").get("Accuracy");
                        f1LR = (double) metrics.get("Logistic Regression").get("F1");
                    }

                    String bestModel = "XGBoost";
                    String bestAlgorithm = "XGBoost";
                    double bestAcc = accXGB;
                    double bestF1 = f1XGB;

                    if (accRF > bestAcc) {
                        bestModel = "Random Forest";
                        bestAlgorithm = "Random Forest";
                        bestAcc = accRF;
                        bestF1 = f1RF;
                    }
                    if (accLR > bestAcc) {
                        bestModel = "Logistic Regression";
                        bestAlgorithm = "Logistic Regression";
                        bestAcc = accLR;
                        bestF1 = f1LR;
                    }

                    // 6. Read latest W&B url
                    String wandbUrl = "https://wandb.ai/";
                    java.io.File wandbUrlFile = new java.io.File(workingDir, "Results/latest_wandb_url.txt");
                    if (wandbUrlFile.exists()) {
                        try (java.io.BufferedReader br = new java.io.BufferedReader(new java.io.FileReader(wandbUrlFile))) {
                            String urlLine = br.readLine();
                            if (urlLine != null && !urlLine.trim().isEmpty()) {
                                wandbUrl = urlLine.trim();
                            }
                        } catch (Exception ignored) {}
                    }

                    String json = "{" +
                        "\"XGBoost\":{\"Algorithm\":\"XGBoost\",\"Accuracy\":" + accXGB + ",\"F1\":" + f1XGB + "}," +
                        "\"Random Forest\":{\"Algorithm\":\"Random Forest\",\"Accuracy\":" + accRF + ",\"F1\":" + f1RF + "}," +
                        "\"Logistic Regression\":{\"Algorithm\":\"Logistic Regression\",\"Accuracy\":" + accLR + ",\"F1\":" + f1LR + "}" +
                        "}";

                    // Update database history record
                    trainingRepository.updateTrainingStatus(trainingId, "Completed", bestModel, json);

                    // Update memory state
                    progressState.put("status", "Completed");
                    progressState.put("bestModel", bestModel);
                    progressState.put("bestModelVersion", trainingId);
                    progressState.put("bestAlgorithm", bestAlgorithm);
                    progressState.put("bestAccuracy", bestAcc);
                    progressState.put("bestF1", bestF1);
                    progressState.put("metricsJson", json);
                    progressState.put("wandbUrl", wandbUrl);
                } else {
                    trainingRepository.updateTrainingStatus(trainingId, "Failed", null, "{\"error\":\"Exit code " + exitCode + "\"}");
                    progressState.put("status", "Failed");
                }
            } catch (Exception ex) {
                ex.printStackTrace();
                trainingRepository.updateTrainingStatus(trainingId, "Failed", null, "{\"error\":\"" + ex.getMessage() + "\"}");
                progressState.put("status", "Failed");
            }
        }).start();

        return trainingId;
    }

    private Map<String, Map<String, Object>> parseLatestMetricsFromCsv(java.io.File csvFile) {
        Map<String, Map<String, Object>> metrics = new HashMap<>();
        if (!csvFile.exists()) return metrics;
        
        try (java.io.BufferedReader br = new java.io.BufferedReader(new java.io.FileReader(csvFile))) {
            String headerLine = br.readLine(); // read header
            String line;
            List<String[]> rows = new ArrayList<>();
            while ((line = br.readLine()) != null) {
                String[] cols = line.split(",");
                if (cols.length >= 4) {
                    rows.add(cols);
                }
            }
            
            // The last 3 rows are the latest training session
            int startIdx = Math.max(0, rows.size() - 3);
            for (int i = startIdx; i < rows.size(); i++) {
                String[] cols = rows.get(i);
                if (cols.length < 3) continue;
                String modelName = cols[1].trim(); // e.g. XGBoost
                double cvAcc = Double.parseDouble(cols[2]) * 100.0; // convert to %
                
                double f1Val = cvAcc; // fallback
                if (cols.length >= 13 && cols[12] != null && !cols[12].trim().isEmpty()) {
                    try {
                        f1Val = Double.parseDouble(cols[12]) * 100.0;
                    } catch (Exception ignored) {}
                } else if (cols.length >= 5 && cols[4] != null && !cols[4].trim().isEmpty()) {
                    try {
                        f1Val = Double.parseDouble(cols[4]) * 100.0;
                    } catch (Exception ignored) {}
                }
                
                Map<String, Object> m = new HashMap<>();
                m.put("Algorithm", modelName);
                m.put("Accuracy", Math.round(cvAcc * 100.0) / 100.0);
                m.put("F1", Math.round(f1Val * 100.0) / 100.0);
                metrics.put(modelName, m);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return metrics;
    }

    public Map<String, Object> getTrainingProgress(String trainingId) {
        return activeTrainings.get(trainingId);
    }
}
