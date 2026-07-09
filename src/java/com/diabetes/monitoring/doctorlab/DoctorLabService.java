package com.diabetes.monitoring.doctorlab;

import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

public class DoctorLabService {
    private final DoctorLabDAO dao = new DoctorLabDAO();

    public List<LabRequest> getRequests(String status) {
        return dao.findRequests(status);
    }

    public Map<String, Integer> getStatusCounts() {
        return dao.getStatusCounts();
    }

    public boolean startProcessing(int invoiceDetailId) {
        return dao.startProcessing(invoiceDetailId);
    }

    public LabRequest getRequest(int invoiceDetailId) {
        return dao.findByInvoiceDetailId(invoiceDetailId);
    }

    public void completeManual(LabRequest request) throws SQLException {
        request.setLabResult(buildResultSummary(request));
        dao.completeRequest(request);
    }

    public void completeRandom(int invoiceDetailId) throws SQLException {
        LabRequest existing = dao.findByInvoiceDetailId(invoiceDetailId);
        if (existing == null) {
            throw new SQLException("Không tìm thấy yêu cầu xét nghiệm.");
        }
        Map<String, BigDecimal> metrics =
                RandomTestGenerator.generateForService(existing.getServiceName());
        existing.setUrea(toDouble(metrics.get("urea")));
        existing.setCr(toDouble(metrics.get("cr")));
        existing.setHba1c(toDouble(metrics.get("hba1c")));
        existing.setChol(toDouble(metrics.get("chol")));
        existing.setTg(toDouble(metrics.get("tg")));
        existing.setHdl(toDouble(metrics.get("hdl")));
        existing.setLdl(toDouble(metrics.get("ldl")));
        existing.setVldl(toDouble(metrics.get("vldl")));
        existing.setWeight(toDouble(metrics.get("weight")));
        existing.setHeight(toDouble(metrics.get("height")));
        existing.setBmi(toDouble(metrics.get("bmi")));
        existing.setLabResult(buildResultSummary(existing));
        dao.completeRequest(existing);
    }

    private Double toDouble(BigDecimal value) {
        return value == null ? null : value.doubleValue();
    }

    private String buildResultSummary(LabRequest request) {
        StringBuilder result = new StringBuilder();
        appendMetric(result, "Urea", request.getUrea());
        appendMetric(result, "Creatinine", request.getCr());
        appendMetric(result, "HbA1c", request.getHba1c());
        appendMetric(result, "Cholesterol", request.getChol());
        appendMetric(result, "Triglycerides", request.getTg());
        appendMetric(result, "HDL", request.getHdl());
        appendMetric(result, "LDL", request.getLdl());
        appendMetric(result, "VLDL", request.getVldl());
        appendMetric(result, "Cân nặng", request.getWeight());
        appendMetric(result, "Chiều cao", request.getHeight());
        appendMetric(result, "BMI", request.getBmi());
        return result.length() == 0
                ? "Đã hoàn thành xét nghiệm."
                : result.toString();
    }

    private void appendMetric(StringBuilder result, String label, Double value) {
        if (value == null) {
            return;
        }
        if (result.length() > 0) {
            result.append("; ");
        }
        result.append(label).append(": ").append(value);
    }
}
