package com.diabetes.monitoring.admin.scheduling;

import com.diabetes.monitoring.admin.common.AdminJsonUtil;
import com.diabetes.monitoring.admin.scheduling.AdminAiSchedulingService.AiSchedulingRequest;
import com.diabetes.monitoring.admin.scheduling.AdminAiSchedulingService.AiSchedulingResult;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Date;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Dispatches manual and AI scheduling requests.
 */
public class AdminSchedulingHandler {
    private final AdminScheduleHandler scheduleHandler = new AdminScheduleHandler();
    private final AdminAiSchedulingHandler aiSchedulingHandler = new AdminAiSchedulingHandler();
    public void loadSchedules(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException { scheduleHandler.loadSchedules(request, response); }
    public void createSchedule(HttpServletRequest request, HttpServletResponse response) throws IOException { scheduleHandler.createSchedule(request, response); }
    public void updateSchedule(HttpServletRequest request, HttpServletResponse response) throws IOException { scheduleHandler.updateSchedule(request, response); }
    public void deleteSchedule(HttpServletRequest request, HttpServletResponse response) throws IOException { scheduleHandler.deleteSchedule(request, response); }
    public void cancelSchedule(HttpServletRequest request, HttpServletResponse response) throws IOException { scheduleHandler.cancelSchedule(request, response); }
    public void transferSchedule(HttpServletRequest request, HttpServletResponse response) throws IOException { scheduleHandler.transferSchedule(request, response); }
    public void loadTransferCandidates(HttpServletRequest request, HttpServletResponse response) throws IOException { scheduleHandler.loadTransferCandidates(request, response); }
    public void loadScheduleDetail(HttpServletRequest request, HttpServletResponse response) throws IOException { scheduleHandler.loadScheduleDetail(request, response); }
    public void aiCreateSchedules(HttpServletRequest request, HttpServletResponse response) throws IOException { aiSchedulingHandler.aiCreateSchedules(request, response); }
}

/**
 * Handles doctor schedule management screens and actions.
 */
class AdminScheduleHandler {
    private final AdminScheduleService scheduleService = new AdminScheduleService();
    public void loadSchedules(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        scheduleService.prepareScheduleViews();

        String department = request.getParameter("department");
        String doctorName = request.getParameter("doctorName");
        Date workDate = nullableDate(request.getParameter("workDate"));
        int transferScheduleId = parseInt(request.getParameter("transferScheduleId"), -1);

        request.setAttribute("doctors", scheduleService.getDoctorsForSchedule());
        request.setAttribute("departments", scheduleService.getScheduleDepartments());
        request.setAttribute("selectedDepartment", department == null ? "" : department);
        request.setAttribute("doctorNameFilter", doctorName == null ? "" : doctorName);
        request.setAttribute("selectedWorkDate", request.getParameter("workDate"));

        Map<String, Object> selectedSchedule = null;
        List<Map<String, Object>> transferCandidates = new ArrayList<>();
        if (transferScheduleId > 0) {
            selectedSchedule = scheduleService.getDoctorScheduleById(transferScheduleId);
            if (selectedSchedule != null) {
                Integer currentDoctorId = selectedSchedule.get("doctorId") instanceof Number
                        ? ((Number) selectedSchedule.get("doctorId")).intValue()
                        : null;
                String sourceDepartment = String.valueOf(selectedSchedule.get("department"));
                transferCandidates = scheduleService.getAvailableDoctorsForEmergency(sourceDepartment, currentDoctorId);
                if (transferCandidates.isEmpty()) {
                    transferCandidates = scheduleService.getAllActiveDoctorsForEmergency(currentDoctorId);
                }
            }
        }
        request.setAttribute("selectedSchedule", selectedSchedule);
        request.setAttribute("transferCandidates", transferCandidates);

        List<Map<String, Object>> rawSchedules = scheduleService.getDoctorSchedules(department, doctorName, workDate);
        for (Map<String, Object> row : rawSchedules) {
            if (!row.containsKey("activeAppointments")) {
                row.put("activeAppointments", row.get("activeCount"));
            }
            if (!row.containsKey("bookedAppointments")) {
                row.put("bookedAppointments", row.get("bookedCount"));
            }
            if (!row.containsKey("bookedCount")) {
                row.put("bookedCount", row.get("bookedAppointments"));
            }
            boolean isFull = Boolean.TRUE.equals(row.get("isFull"));
            String configured = String.valueOf(row.get("status"));
            if ("Expired".equalsIgnoreCase(configured) || "Cancelled".equalsIgnoreCase(configured)) {
                row.put("effectiveStatus", configured);
            } else {
                row.put("effectiveStatus", isFull ? "Full" : configured);
            }
        }
        request.setAttribute("schedules", rawSchedules);
        request.getRequestDispatcher("/WEB-INF/views/admin/schedule-management.jsp").forward(request, response);
    }
    public void createSchedule(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int doctorId = parseInt(request.getParameter("doctorId"), -1);
        Date workDate = nullableDate(request.getParameter("workDate"));
        String timeSlot = request.getParameter("timeSlot");
        int maxPatients = parseInt(request.getParameter("maxPatients"), 0);
        int onlineQuota = parseInt(request.getParameter("onlineQuota"), -1);

        boolean ok = doctorId > 0 && workDate != null
                && scheduleService.createSchedule(doctorId, workDate, timeSlot, maxPatients, onlineQuota >= 0 ? onlineQuota : null);
        String daoMessage = scheduleService.consumeValidationMessage();
        request.getSession().setAttribute(ok ? "successMessage" : "errorMessage",
                ok ? "Đã tạo ca trực bác sĩ"
                        : (daoMessage == null || daoMessage.isBlank() ? "Không thể tạo ca trực" : daoMessage));
        response.sendRedirect(request.getContextPath() + "/admin?action=schedule");
    }
    public void updateSchedule(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int scheduleId = parseInt(request.getParameter("scheduleId"), -1);
        int doctorId = parseInt(request.getParameter("doctorId"), -1);
        String timeSlot = request.getParameter("timeSlot");
        int maxPatients = parseInt(request.getParameter("maxPatients"), 0);
        int onlineQuota = parseInt(request.getParameter("onlineQuota"), -1);
        String status = request.getParameter("status");

        boolean ok = scheduleId > 0 && doctorId > 0
                && scheduleService.updateSchedule(scheduleId, doctorId, timeSlot, maxPatients, onlineQuota >= 0 ? onlineQuota : null, status);
        String daoMessage = scheduleService.consumeValidationMessage();
        request.getSession().setAttribute(ok ? "successMessage" : "errorMessage",
                ok ? "Đã cập nhật ca trực"
                        : (daoMessage == null || daoMessage.isBlank() ? "Không thể cập nhật ca trực" : daoMessage));
        response.sendRedirect(request.getContextPath() + "/admin?action=schedule");
    }
    public void deleteSchedule(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int scheduleId = parseInt(request.getParameter("scheduleId"), -1);
        boolean ok = scheduleId > 0 && scheduleService.deleteSchedule(scheduleId);
        request.getSession().setAttribute(ok ? "successMessage" : "errorMessage",
                ok ? "Đã xóa lịch trực" : "Không thể xóa lịch trực");
        response.sendRedirect(request.getContextPath() + "/admin?action=schedule");
    }
    public void cancelSchedule(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int scheduleId = parseInt(request.getParameter("scheduleId"), -1);
        boolean ok = scheduleId > 0 && scheduleService.cancelSchedule(scheduleId);
        String daoMessage = scheduleService.consumeValidationMessage();
        request.getSession().setAttribute(ok ? "successMessage" : "errorMessage",
                ok ? "Đã hủy ca trực"
                        : (daoMessage == null || daoMessage.isBlank() ? "Không thể hủy ca trực" : daoMessage));
        response.sendRedirect(request.getContextPath() + "/admin?action=schedule");
    }
    public void transferSchedule(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int scheduleId = parseInt(request.getParameter("scheduleId"), -1);
        int targetDoctorId = parseInt(request.getParameter("targetDoctorId"), -1);
        boolean ok = scheduleId > 0 && targetDoctorId > 0 && scheduleService.transferSchedule(scheduleId, targetDoctorId);
        String daoMessage = scheduleService.consumeValidationMessage();
        String xrw = request.getHeader("X-Requested-With");
        boolean isAjax = (xrw != null && "XMLHttpRequest".equalsIgnoreCase(xrw))
                || (request.getHeader("Accept") != null && request.getHeader("Accept").contains("application/json"));

        if (isAjax) {
            response.setContentType("application/json;charset=UTF-8");
            try (PrintWriter out = response.getWriter()) {
                out.print('{');
                out.print("\"success\":");
                out.print(ok);
                out.print(',');
                out.print("\"message\":\"");
                String msg = ok ? "Đã chuyển giao ca trực" : (daoMessage == null || daoMessage.isBlank() ? "Không thể chuyển giao ca trực" : daoMessage);
                out.print(escape(msg));
                out.print('\"');
                if (ok) {
                    Map<String, Object> profile = null;
                    String fullName = profile == null ? "" : String.valueOf(profile.getOrDefault("fullName", ""));
                    out.print(',');
                    out.print("\"targetDoctorId\":");
                    out.print(targetDoctorId);
                    out.print(',');
                    out.print("\"targetDoctorName\":\"");
                    out.print(escape(fullName));
                    out.print('\"');
                }
                out.print('}');
            }
            return;
        }

        request.getSession().setAttribute(ok ? "successMessage" : "errorMessage",
                ok ? "Đã chuyển giao ca trực"
                        : (daoMessage == null || daoMessage.isBlank() ? "Không thể chuyển giao ca trực" : daoMessage));
        response.sendRedirect(request.getContextPath() + "/admin?action=schedule");
    }
    public void loadTransferCandidates(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        int scheduleId = parseInt(request.getParameter("scheduleId"), -1);
        try (PrintWriter out = response.getWriter()) {
            if (scheduleId <= 0) {
                out.print("{\"currentDoctorId\":null,\"items\":[]}");
                return;
            }

            Map<String, Object> schedule = scheduleService.getDoctorScheduleById(scheduleId);
            if (schedule == null) {
                out.print("{\"currentDoctorId\":null,\"items\":[]}");
                return;
            }

            Integer currentDoctorId = schedule.get("doctorId") instanceof Number
                    ? ((Number) schedule.get("doctorId")).intValue()
                    : null;
            String department = String.valueOf(schedule.get("department"));
            List<Map<String, Object>> candidates = scheduleService.getAvailableDoctorsForEmergency(department, currentDoctorId);
            if (candidates == null || candidates.isEmpty()) {
                candidates = scheduleService.getAllActiveDoctorsForEmergency(currentDoctorId);
            }

            out.print("{\"currentDoctorId\":");
            out.print(currentDoctorId == null ? "null" : currentDoctorId);
            out.print(",\"items\":[");
            boolean first = true;
            for (Map<String, Object> candidate : candidates) {
                if (!first) {
                    out.print(',');
                }
                first = false;
                out.print('{');
                out.print("\"doctorId\":");
                out.print(candidate.getOrDefault("doctorId", 0));
                out.print(",\"fullName\":\"");
                out.print(escape(String.valueOf(candidate.getOrDefault("fullName", ""))));
                out.print("\",\"department\":\"");
                out.print(escape(String.valueOf(candidate.getOrDefault("department", ""))));
                out.print("\"}");
            }
            out.print("]}");
        } catch (Exception ex) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"currentDoctorId\":null,\"items\":[]}");
            }
        }
    }
    public void loadScheduleDetail(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        int scheduleId = parseInt(request.getParameter("scheduleId"), -1);
        try (PrintWriter out = response.getWriter()) {
            if (scheduleId <= 0) {
                out.print("{\"schedule\":null,\"doctors\":[]}");
                return;
            }

            Map<String, Object> schedule = scheduleService.getDoctorScheduleById(scheduleId);
            if (schedule == null) {
                out.print("{\"schedule\":null,\"doctors\":[]}");
                return;
            }

            List<Map<String, Object>> doctors = scheduleService.getDoctorsForSchedule();
            out.print('{');
            out.print("\"schedule\":{");
            out.print("\"scheduleId\":");
            out.print(schedule.getOrDefault("scheduleId", 0));
            out.print(",\"doctorId\":");
            out.print(schedule.getOrDefault("doctorId", 0));
            out.print(",\"doctorName\":\"");
            out.print(escape(String.valueOf(schedule.getOrDefault("doctorName", ""))));
            out.print("\",\"department\":\"");
            out.print(escape(String.valueOf(schedule.getOrDefault("department", ""))));
            out.print("\",\"workDate\":\"");
            out.print(escape(String.valueOf(schedule.getOrDefault("workDate", ""))));
            out.print("\",\"timeSlot\":\"");
            out.print(escape(String.valueOf(schedule.getOrDefault("timeSlot", ""))));
            out.print("\",\"maxPatients\":");
            out.print(schedule.getOrDefault("maxPatients", 1));
            out.print(",\"onlineQuota\":");
            out.print(schedule.getOrDefault("onlineQuota", 0));
            out.print(",\"bookedCount\":");
            out.print(schedule.getOrDefault("bookedCount", 0));
            out.print(",\"onlineBookedCount\":");
            out.print(schedule.getOrDefault("onlineBookedCount", 0));
            out.print(",\"status\":\"");
            out.print(escape(String.valueOf(schedule.getOrDefault("status", ""))));
            out.print("\"}");

            out.print(",\"doctors\":[");
            boolean first = true;
            for (Map<String, Object> doctor : doctors) {
                if (!first) {
                    out.print(',');
                }
                first = false;
                out.print('{');
                out.print("\"doctorId\":");
                out.print(doctor.getOrDefault("doctorId", 0));
                out.print(",\"fullName\":\"");
                out.print(escape(String.valueOf(doctor.getOrDefault("fullName", ""))));
                out.print("\",\"department\":\"");
                out.print(escape(String.valueOf(doctor.getOrDefault("department", ""))));
                out.print("\"}");
            }
            out.print("]}");
        } catch (Exception ex) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"schedule\":null,\"doctors\":[]}");
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
    private Date nullableDate(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        try {
            return Date.valueOf(LocalDate.parse(raw));
        } catch (Exception ex) {
            return null;
        }
    }
    private String escape(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}

/**
 * Handles AI-assisted schedule generation requests.
 */
class AdminAiSchedulingHandler {
    private final AdminAiSchedulingService aiSchedulingService = new AdminAiSchedulingService();
    public void aiCreateSchedules(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        try {
            AiSchedulingRequest aiRequest = new AiSchedulingRequest();
            aiRequest.startDate = nullableDate(request.getParameter("startDate"));
            aiRequest.endDate = nullableDate(request.getParameter("endDate"));
            aiRequest.startTime = request.getParameter("startTime");
            aiRequest.endTime = request.getParameter("endTime");
            aiRequest.slotMinutes = parseInt(request.getParameter("slotMinutes"), 120);
            aiRequest.maxPatients = parseInt(request.getParameter("maxPatients"), 20);
            aiRequest.maxSchedules = parseInt(request.getParameter("maxSchedules"), 12);
            aiRequest.doctorsPerShift = parseInt(request.getParameter("doctorsPerShift"), 1);
            aiRequest.department = request.getParameter("department");
            aiRequest.shiftsPerDay = parseShiftTemplates(request.getParameter("shiftTemplates"));
            aiRequest.selectedWeekdays = parseSelectedWeekdays(request.getParameterValues("selectedWeekdays"));

            AiSchedulingResult result = aiSchedulingService.createSchedules(aiRequest);
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"success\":");
                out.print(result.success);
                out.print(",\"message\":\"");
                out.print(AdminJsonUtil.escapeJson(result.message));
                out.print("\",\"items\":");
                out.print(AdminJsonUtil.toJsonSimpleRows(result.items));
                out.print("}");
            }
        } catch (StackOverflowError error) {
            writeAiScheduleError(response, "Dữ liệu Gemini quá lớn để xử lý. Hệ thống đã chặn lỗi và chưa ghi lịch vào database.");
        } catch (RuntimeException error) {
            writeAiScheduleError(response, "Không thể xử lý lịch AI: " + (error.getMessage() == null ? "Lỗi dữ liệu không xác định." : error.getMessage()));
        }
    }
    private void writeAiScheduleError(HttpServletResponse response, String message) throws IOException {
        response.setStatus(HttpServletResponse.SC_OK);
        try (PrintWriter out = response.getWriter()) {
            out.print("{\"success\":false,\"message\":\"");
            out.print(AdminJsonUtil.escapeJson(message));
            out.print("\",\"items\":[]}");
        }
    }
    private List<Map<String, String>> parseShiftTemplates(String rawTemplates) {
        List<Map<String, String>> shifts = new ArrayList<>();
        if (rawTemplates == null || rawTemplates.isBlank()) {
            return shifts;
        }
        String[] lines = rawTemplates.split("\\r?\\n");
        for (String line : lines) {
            if (line == null || line.trim().isEmpty()) {
                continue;
            }
            String[] parts = line.split("\\|", 2);
            if (parts.length < 2) {
                continue;
            }
            String timeSlot = parts[0].trim();
            String department = parts[1].trim();
            if (!timeSlot.matches("\\d{2}:\\d{2}-\\d{2}:\\d{2}") || department.isEmpty()) {
                continue;
            }
            Map<String, String> shift = new java.util.HashMap<>();
            shift.put("timeSlot", timeSlot);
            shift.put("department", department);
            shifts.add(shift);
        }
        return shifts;
    }
    private List<Integer> parseSelectedWeekdays(String[] values) {
        List<Integer> weekdays = new ArrayList<>();
        if (values == null) {
            return weekdays;
        }
        for (String value : values) {
            int day = parseInt(value, -1);
            if (day >= 1 && day <= 7 && !weekdays.contains(day)) {
                weekdays.add(day);
            }
        }
        return weekdays;
    }
    private int parseInt(String raw, int fallback) {
        try {
            return Integer.parseInt(raw);
        } catch (Exception ex) {
            return fallback;
        }
    }
    private Date nullableDate(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        try {
            return Date.valueOf(java.time.LocalDate.parse(raw));
        } catch (Exception ex) {
            return null;
        }
    }
}

