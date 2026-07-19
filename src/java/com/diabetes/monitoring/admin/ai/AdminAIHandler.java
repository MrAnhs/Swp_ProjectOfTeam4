package com.diabetes.monitoring.admin.ai;

import com.diabetes.monitoring.model.User;
import com.diabetes.monitoring.admin.common.AdminJsonUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Dispatches AI Model Management requests.
 */
public class AdminAIHandler {

    private final AdminAIService aiService = new AdminAIService();

    /**
     * Unified entry point — loads all data needed for the single tabbed AI management page.
     * The 'tab' param selects which tab is active: overview (default), dataset, training, version.
     */
    public void loadManagementPage(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String tab = request.getParameter("tab");
        if (tab == null || tab.isBlank()) tab = "overview";
        request.setAttribute("activeTab", tab);

        // Always load overview stats (displayed on Overview tab summary cards)
        Map<String, Object> stats = aiService.getAiDashboardStats();
        for (Map.Entry<String, Object> entry : stats.entrySet()) {
            request.setAttribute(entry.getKey(), entry.getValue());
        }

        if ("dataset".equals(tab)) {
            // Load dataset records with filters
            String patientIdSearch = request.getParameter("patientId");
            String doctorFilter   = request.getParameter("doctor");
            String statusFilter   = request.getParameter("status");
            String qualityFilter  = request.getParameter("quality");
            int page     = parseInt(request.getParameter("page"), 1);
            int pageSize = parseInt(request.getParameter("pageSize"), 10);

            int totalRecords = aiService.getDatasetRecordsCount(patientIdSearch, doctorFilter, statusFilter, qualityFilter);
            int totalPages   = (int) Math.ceil((double) totalRecords / pageSize);
            if (totalPages <= 0) totalPages = 1;
            if (page > totalPages) page = totalPages;

            List<Map<String, Object>> items = aiService.getDatasetRecords(
                    patientIdSearch, doctorFilter, statusFilter, qualityFilter, page, pageSize);

            request.setAttribute("items", items);
            request.setAttribute("currentPage", page);
            request.setAttribute("pageSize", pageSize);
            request.setAttribute("totalPages", totalPages);
            request.setAttribute("totalRecords", totalRecords);
            request.setAttribute("patientId", patientIdSearch);
            request.setAttribute("doctor", doctorFilter);
            request.setAttribute("status", statusFilter);
            request.setAttribute("quality", qualityFilter);

            com.diabetes.monitoring.admin.scheduling.AdminStaffScheduleRepository staffRepo =
                    new com.diabetes.monitoring.admin.scheduling.AdminStaffScheduleRepository();
            request.setAttribute("doctors", staffRepo.findStaff("Doctor"));
        }
        // training tab: approvedDataset already loaded from stats above

        request.getRequestDispatcher("/WEB-INF/views/admin/ai/AIModelManagement.jsp").forward(request, response);
    }

    public void getDatasetDetailJson(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        int recordId = parseInt(request.getParameter("recordId"), -1);
        Map<String, Object> detail = recordId > 0 ? aiService.getDatasetRecordDetail(recordId) : null;
        
        try (PrintWriter out = response.getWriter()) {
            if (detail == null) {
                out.print("{\"success\":false,\"message\":\"Không tìm thấy hồ sơ bệnh án\"}");
                return;
            }

            // Calculate age
            java.sql.Date dob = (java.sql.Date) detail.get("dateOfBirth");
            if (dob != null) {
                java.time.LocalDate birth = dob.toLocalDate();
                java.time.LocalDate now = java.time.LocalDate.now();
                detail.put("age", java.time.Period.between(birth, now).getYears());
            } else {
                detail.put("age", "N/A");
            }
            detail.put("success", true);

            out.print(AdminJsonUtil.toJsonMap(detail));
        }
    }

    public void confirmDatasetDecision(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        int recordId = parseInt(request.getParameter("recordId"), -1);
        String status = request.getParameter("decisionStatus");
        String reason = request.getParameter("decisionReason");

        User currentUser = (User) request.getSession().getAttribute("currentUser");
        if (currentUser == null || !"Admin".equalsIgnoreCase(currentUser.getRole())) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"success\":false,\"message\":\"Quyền truy cập bị từ chối.\"}");
            }
            return;
        }

        boolean ok = recordId > 0 && aiService.updateDatasetDecision(recordId, status, reason, currentUser.getId());
        try (PrintWriter out = response.getWriter()) {
            if (ok) {
                out.print("{\"success\":true,\"message\":\"Đã ghi nhận quyết định duyệt dữ liệu thành công.\"}");
            } else {
                out.print("{\"success\":false,\"message\":\"Không thể lưu quyết định duyệt.\"}");
            }
        }
    }

    public void confirmDatasetDecisionBulk(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        String recordIdsStr = request.getParameter("recordIds");
        String status = request.getParameter("decisionStatus");
        String reason = request.getParameter("decisionReason");

        User currentUser = (User) request.getSession().getAttribute("currentUser");
        if (currentUser == null || !"Admin".equalsIgnoreCase(currentUser.getRole())) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"success\":false,\"message\":\"Quyền truy cập bị từ chối.\"}");
            }
            return;
        }

        if (recordIdsStr == null || recordIdsStr.isBlank()) {
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"success\":false,\"message\":\"Danh sách bệnh án không hợp lệ.\"}");
            }
            return;
        }

        List<Integer> recordIds = new ArrayList<>();
        try {
            for (String s : recordIdsStr.split(",")) {
                if (!s.isBlank()) {
                    recordIds.add(Integer.parseInt(s.trim()));
                }
            }
        } catch (NumberFormatException e) {
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"success\":false,\"message\":\"Định dạng ID bệnh án không hợp lệ.\"}");
            }
            return;
        }

        boolean ok = aiService.updateDatasetDecisionsBulk(recordIds, status, reason, currentUser.getId());
        try (PrintWriter out = response.getWriter()) {
            if (ok) {
                out.print("{\"success\":true,\"message\":\"Đã xử lý quyết định duyệt hàng loạt thành công.\"}");
            } else {
                out.print("{\"success\":false,\"message\":\"Không thể lưu quyết định duyệt hàng loạt.\"}");
            }
        }
    }

    public void getGlobalPendingCountsJson(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        Map<String, Integer> counts = aiService.getGlobalPendingCounts();
        
        try (PrintWriter out = response.getWriter()) {
            Map<String, Object> result = new HashMap<>();
            result.put("success", true);
            result.put("totalPending", counts.get("totalPending"));
            result.put("validPending", counts.get("validPending"));
            result.put("invalidPending", counts.get("invalidPending"));
            out.print(AdminJsonUtil.toJsonMap(result));
        }
    }

    public void confirmDatasetDecisionGlobal(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        int limit = parseInt(request.getParameter("limit"), -1);

        User currentUser = (User) request.getSession().getAttribute("currentUser");
        if (currentUser == null || !"Admin".equalsIgnoreCase(currentUser.getRole())) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"success\":false,\"message\":\"Quyền truy cập bị từ chối.\"}");
            }
            return;
        }

        boolean ok = aiService.approveAllDatasetGlobal(limit, currentUser.getId());
        try (PrintWriter out = response.getWriter()) {
            if (ok) {
                out.print("{\"success\":true,\"message\":\"Đã thực hiện duyệt tự động toàn bộ hệ thống thành công.\"}");
            } else {
                out.print("{\"success\":false,\"message\":\"Không thể hoàn tất duyệt toàn bộ.\"}");
            }
        }
    }

    public void startTraining(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        int totalRecords = parseInt(request.getParameter("totalRecords"), 0);
        if (totalRecords <= 0) {
            totalRecords = 150; // Fallback default for demo/retraining purposes
        }

        List<String> selectedModels = Arrays.asList("XGBoost", "Random Forest", "Logistic Regression");
        String trainingId = aiService.startRetraining(selectedModels, totalRecords);

        try (PrintWriter out = response.getWriter()) {
            out.print("{\"success\":true,\"trainingId\":\"" + trainingId + "\"}");
        }
    }

    public void getTrainingProgress(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        String trainingId = request.getParameter("trainingId");
        Map<String, Object> progress = trainingId != null ? aiService.getTrainingProgress(trainingId) : null;
        
        try (PrintWriter out = response.getWriter()) {
            if (progress == null) {
                out.print("{\"success\":false,\"message\":\"Không tìm thấy tiến trình đợt train này.\"}");
            } else {
                out.print(AdminJsonUtil.toJsonMap(progress));
            }
        }
    }

    private int parseInt(String raw, int fallback) {
        try {
            return Integer.parseInt(raw);
        } catch (Exception ex) {
            return fallback;
        }
    }
}
