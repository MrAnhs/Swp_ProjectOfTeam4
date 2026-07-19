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
    public void aiSaveProposedSchedules(HttpServletRequest request, HttpServletResponse response) throws IOException { aiSchedulingHandler.aiSaveProposedSchedules(request, response); }
    public void aiSuggestTime(HttpServletRequest request, HttpServletResponse response) throws IOException { aiSchedulingHandler.aiSuggestTime(request, response); }
    public void loadStaffForSchedule(HttpServletRequest request, HttpServletResponse response) throws IOException { staffScheduleHandler.loadStaffForSchedule(request, response); }
    public void createStaffSchedule(HttpServletRequest request, HttpServletResponse response) throws IOException { staffScheduleHandler.createStaffSchedule(request, response); }
    public void updateStaffSchedule(HttpServletRequest request, HttpServletResponse response) throws IOException { staffScheduleHandler.updateStaffSchedule(request, response); }
    public void cancelStaffSchedule(HttpServletRequest request, HttpServletResponse response) throws IOException { staffScheduleHandler.cancelStaffSchedule(request, response); }
    public void deleteStaffSchedule(HttpServletRequest request, HttpServletResponse response) throws IOException { staffScheduleHandler.deleteStaffSchedule(request, response); }
    public void aiStaffSchedule(HttpServletRequest request, HttpServletResponse response) throws IOException { staffScheduleHandler.aiStaffSchedule(request, response); }
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
        request.getRequestDispatcher("/WEB-INF/views/admin/scheduling/schedule-management.jsp").forward(request, response);
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
class AdminStaffScheduleHandler {
    private final AdminStaffScheduleService staffScheduleService = new AdminStaffScheduleService();
    private final AdminSchedulingService schedulingService = new AdminSchedulingService();

    public void loadStaffForSchedule(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        List<Map<String, Object>> staff = staffScheduleService.getStaffForSchedule(request.getParameter("staffType"));
        try (PrintWriter out = response.getWriter()) {
            out.print("{\"items\":");
            out.print(AdminJsonUtil.toJsonSimpleRows(staff));
            out.print("}");
        }
    }

    public void loadStaffScheduleDetail(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        int staffScheduleId = parseInt(request.getParameter("staffScheduleId"), -1);
        try (PrintWriter out = response.getWriter()) {
            if (staffScheduleId <= 0) {
                out.print("{\"schedule\":null,\"staff\":[],\"rooms\":[]}");
                return;
            }

            Map<String, Object> schedule = staffScheduleService.getStaffScheduleById(staffScheduleId);
            if (schedule == null) {
                out.print("{\"schedule\":null,\"staff\":[],\"rooms\":[]}");
                return;
            }

            String staffType = String.valueOf(schedule.getOrDefault("staffType", ""));
            List<Map<String, Object>> staff = staffScheduleService.getStaffForSchedule(staffType);
            List<Map<String, Object>> rooms = "doctor_lab".equalsIgnoreCase(staffType)
                    ? schedulingService.getLabRoomsForSchedule()
                    : schedulingService.getRoomsForSchedule();

            out.print('{');
            out.print("\"schedule\":{");
            out.print("\"staffScheduleId\":");
            out.print(schedule.getOrDefault("staffScheduleId", 0));
            out.print(",\"accountId\":");
            out.print(schedule.getOrDefault("accountId", 0));
            out.print(",\"staffName\":\"");
            out.print(AdminJsonUtil.escapeJson(String.valueOf(schedule.getOrDefault("staffName", ""))));
            out.print("\",\"staffType\":\"");
            out.print(AdminJsonUtil.escapeJson(staffType));
            out.print("\",\"workDate\":\"");
            out.print(AdminJsonUtil.escapeJson(String.valueOf(schedule.getOrDefault("workDate", ""))));
            out.print("\",\"timeSlot\":\"");
            out.print(AdminJsonUtil.escapeJson(String.valueOf(schedule.getOrDefault("timeSlot", ""))));
            out.print("\",\"department\":\"");
            out.print(AdminJsonUtil.escapeJson(String.valueOf(schedule.getOrDefault("department", ""))));
            out.print("\",\"workArea\":\"");
            out.print(AdminJsonUtil.escapeJson(String.valueOf(schedule.getOrDefault("workArea", ""))));
            out.print("\",\"maxWorkload\":");
            Object maxWorkload = schedule.get("maxWorkload");
            out.print(maxWorkload == null ? "null" : maxWorkload);
            out.print(",\"status\":\"");
            out.print(AdminJsonUtil.escapeJson(String.valueOf(schedule.getOrDefault("status", ""))));
            out.print("\",\"scheduleSource\":\"");
            out.print(AdminJsonUtil.escapeJson(String.valueOf(schedule.getOrDefault("scheduleSource", ""))));
            out.print("\",\"roomId\":\"");
            out.print(AdminJsonUtil.escapeJson(String.valueOf(schedule.getOrDefault("roomId", ""))));
            out.print("\",\"roomNumber\":\"");
            out.print(AdminJsonUtil.escapeJson(String.valueOf(schedule.getOrDefault("roomNumber", ""))));
            out.print("\",\"roomName\":\"");
            out.print(AdminJsonUtil.escapeJson(String.valueOf(schedule.getOrDefault("roomName", ""))));
            out.print("\"}");
            out.print(",\"staff\":");
            out.print(AdminJsonUtil.toJsonSimpleRows(staff));
            out.print(",\"rooms\":");
            out.print(AdminJsonUtil.toJsonSimpleRows(rooms));
            out.print("}");
        } catch (Exception ex) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"schedule\":null,\"staff\":[],\"rooms\":[]}");
            }
        }
    }

    public void createStaffSchedule(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int accountId = parseInt(request.getParameter("accountId"), -1);
        String staffType = request.getParameter("staffType");
        Date workDate = nullableDate(request.getParameter("workDate"));
        String timeSlot = request.getParameter("timeSlot");
        String department = request.getParameter("department");
        String workArea = request.getParameter("workArea");
        Integer maxWorkload = nullableInt(request.getParameter("maxWorkload"));
        String roomId = cleanText(request.getParameter("roomId"));

        boolean ok = accountId > 0 && workDate != null
                && staffScheduleService.createStaffSchedule(accountId, staffType, workDate,
                        timeSlot, department, workArea, maxWorkload, roomId);
        setStaffFlash(request, ok, "Đã tạo lịch trực nhân sự", "Không thể tạo lịch trực nhân sự");
        response.sendRedirect(staffRedirect(request, staffType));
    }

    public void updateStaffSchedule(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int staffScheduleId = parseInt(request.getParameter("staffScheduleId"), -1);
        int accountId = parseInt(request.getParameter("accountId"), -1);
        String staffType = request.getParameter("staffType");
        Date workDate = nullableDate(request.getParameter("workDate"));
        String timeSlot = request.getParameter("timeSlot");
        String department = request.getParameter("department");
        String workArea = request.getParameter("workArea");
        Integer maxWorkload = nullableInt(request.getParameter("maxWorkload"));
        String status = request.getParameter("status");
        String roomId = cleanText(request.getParameter("roomId"));

        boolean ok = staffScheduleId > 0 && accountId > 0 && workDate != null
                && staffScheduleService.updateStaffSchedule(staffScheduleId, accountId,
                        staffType, workDate, timeSlot, department, workArea, maxWorkload, status, roomId);
        setStaffFlash(request, ok, "Đã cập nhật lịch trực nhân sự", "Không thể cập nhật lịch trực nhân sự");
        response.sendRedirect(staffRedirect(request, staffType));
    }

    public void cancelStaffSchedule(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int staffScheduleId = parseInt(request.getParameter("staffScheduleId"), -1);
        String staffType = request.getParameter("staffType");
        boolean ok = staffScheduleId > 0 && staffScheduleService.cancelStaffSchedule(staffScheduleId);
        setStaffFlash(request, ok, "Đã hủy lịch trực nhân sự", "Không thể hủy lịch trực nhân sự");
        response.sendRedirect(staffRedirect(request, staffType));
    }

    public void deleteStaffSchedule(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int staffScheduleId = parseInt(request.getParameter("staffScheduleId"), -1);
        String staffType = request.getParameter("staffType");
        boolean ok = staffScheduleId > 0 && staffScheduleService.deleteStaffSchedule(staffScheduleId);
        setStaffFlash(request, ok, "Đã xóa lịch trực nhân sự", "Không thể xóa lịch trực nhân sự");
        response.sendRedirect(staffRedirect(request, staffType));
    }

    private String determineLabRoomDepartment(java.sql.Connection connection, String roomId) {
        if (roomId == null || roomId.trim().isEmpty()) {
            return "Máu";
        }
        try {
            String sql = "SELECT room_name FROM Room WHERE room_id = ?";
            java.util.Map<String, Object> r = com.diabetes.monitoring.admin.common.AdminJdbcSupport.queryForMap(connection, sql, java.util.Arrays.asList(roomId.trim()));
            if (r != null && r.get("room_name") != null) {
                String roomName = String.valueOf(r.get("room_name"));
                String normalized = java.text.Normalizer.normalize(roomName, java.text.Normalizer.Form.NFD)
                        .replaceAll("\\p{M}", "")
                        .replace('đ', 'd')
                        .replace('Đ', 'D')
                        .toLowerCase();
                if (normalized.contains("nuoc tieu") || normalized.contains("urine")) {
                    return "Nước tiểu";
                }
            }
        } catch (Exception e) {
            // Ignore
        }
        return "Máu";
    }

    public void aiStaffSchedule(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String staffType = request.getParameter("staffType");
        if ("doctor_lab".equals(staffType)) {
            String[] roomIds = request.getParameterValues("roomIds");
            if (roomIds == null || roomIds.length == 0) {
                if (isJsonRequest(request)) {
                    response.setContentType("application/json;charset=UTF-8");
                    try (PrintWriter out = response.getWriter()) {
                        out.print("{\"success\":false,\"message\":\"Vui lòng chọn ít nhất một phòng xét nghiệm.\",\"items\":[]}");
                    }
                } else {
                    request.getSession().setAttribute("errorMessage", "Vui lòng chọn ít nhất một phòng xét nghiệm.");
                    response.sendRedirect(staffRedirect(request, staffType));
                }
                return;
            }

            Date startDate = nullableDate(request.getParameter("startDate"));
            Date endDate = nullableDate(request.getParameter("endDate"));
            int staffPerShift = parseInt(request.getParameter("staffPerShift"), 1);
            Integer maxWorkload = nullableInt(request.getParameter("maxWorkload"));
            String conflictHandling = cleanText(request.getParameter("conflictHandling"));
            String rawTemplates = request.getParameter("shiftTemplates");

            boolean allSuccess = true;
            StringBuilder combinedMessage = new StringBuilder();
            List<Map<String, Object>> allCreatedItems = new ArrayList<>();

            try (java.sql.Connection conn = com.diabetes.monitoring.util.DatabaseConnection.getConnection()) {
                for (String roomId : roomIds) {
                    String dept = determineLabRoomDepartment(conn, roomId);
                    
                    AiStaffSchedulingRequest aiRequest = new AiStaffSchedulingRequest();
                    aiRequest.staffType = staffType;
                    aiRequest.startDate = startDate;
                    aiRequest.endDate = endDate;
                    aiRequest.department = dept;
                    aiRequest.workArea = "";
                    aiRequest.staffPerShift = staffPerShift;
                    aiRequest.maxWorkload = maxWorkload;
                    aiRequest.roomId = roomId;
                    aiRequest.conflictHandling = conflictHandling;
                    aiRequest.shiftsPerDay = parseShiftTemplates(rawTemplates, dept, "");

                    AiStaffSchedulingResult result = staffScheduleService.createStaffSchedules(aiRequest);
                    if (!result.success) {
                        allSuccess = false;
                        if (combinedMessage.length() > 0) combinedMessage.append(" | ");
                        combinedMessage.append(result.message);
                    } else {
                        allCreatedItems.addAll(result.items);
                    }
                }
            } catch (java.sql.SQLException e) {
                allSuccess = false;
                combinedMessage.append("Lỗi cơ sở dữ liệu: ").append(e.getMessage());
            }

            if (combinedMessage.length() == 0) {
                combinedMessage.append("Lập lịch AI thành công cho ").append(roomIds.length).append(" phòng xét nghiệm.");
            }

            if (isJsonRequest(request)) {
                response.setContentType("application/json;charset=UTF-8");
                try (PrintWriter out = response.getWriter()) {
                    out.print("{\"success\":");
                    out.print(allSuccess);
                    out.print(",\"message\":\"");
                    out.print(AdminJsonUtil.escapeJson(combinedMessage.toString()));
                    out.print("\",\"items\":");
                    out.print(AdminJsonUtil.toJsonSimpleRows(allCreatedItems));
                    out.print("}");
                }
            } else {
                request.getSession().setAttribute(allSuccess ? "successMessage" : "errorMessage", combinedMessage.toString());
                response.sendRedirect(staffRedirect(request, staffType));
            }
            return;
        }

        AiStaffSchedulingRequest aiRequest = new AiStaffSchedulingRequest();
        aiRequest.staffType = staffType;
        aiRequest.startDate = nullableDate(request.getParameter("startDate"));
        aiRequest.endDate = nullableDate(request.getParameter("endDate"));
        aiRequest.shiftsPerDay = parseShiftTemplates(request.getParameter("shiftTemplates"),
                request.getParameter("department"), request.getParameter("workArea"));
        aiRequest.department = request.getParameter("department");
        aiRequest.workArea = request.getParameter("workArea");
        aiRequest.staffPerShift = parseInt(request.getParameter("staffPerShift"), 1);
        aiRequest.maxWorkload = nullableInt(request.getParameter("maxWorkload"));
        aiRequest.roomId = cleanText(request.getParameter("roomId"));
        aiRequest.conflictHandling = cleanText(request.getParameter("conflictHandling"));

        AiStaffSchedulingResult result = staffScheduleService.createStaffSchedules(aiRequest);
        if (isJsonRequest(request)) {
            response.setContentType("application/json;charset=UTF-8");
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"success\":");
                out.print(result.success);
                out.print(",\"message\":\"");
                out.print(AdminJsonUtil.escapeJson(result.message));
                out.print("\",\"items\":");
                out.print(AdminJsonUtil.toJsonSimpleRows(result.items));
                out.print("}");
            }
        } else {
            request.getSession().setAttribute(result.success ? "successMessage" : "errorMessage",
                    result.message);
            response.sendRedirect(staffRedirect(request, aiRequest.staffType));
        }
    }

    private List<Map<String, String>> parseShiftTemplates(String rawTemplates,
            String defaultDepartment,
            String defaultWorkArea) {

        List<Map<String, String>> shifts = new ArrayList<>();
        if (rawTemplates == null || rawTemplates.isBlank()) {
            return shifts;
        }
        String[] lines = rawTemplates.split("\\r?\\n");
        for (String line : lines) {
            if (line == null || line.trim().isEmpty()) {
                continue;
            }
            String[] parts = line.split("\\|");
            String timeSlot = parts[0].trim();
            if (!timeSlot.matches("\\d{2}:\\d{2}-\\d{2}:\\d{2}")) {
                continue;
            }
            Map<String, String> shift = new java.util.HashMap<>();
            shift.put("timeSlot", timeSlot);
            shift.put("department", parts.length > 1 ? parts[1].trim() : defaultDepartment);
            shift.put("workArea", parts.length > 2 ? parts[2].trim() : defaultWorkArea);
            shifts.add(shift);
        }
        return shifts;
    }

    private void setStaffFlash(HttpServletRequest request, boolean ok, String success, String failure) {
        String daoMessage = staffScheduleService.consumeValidationMessage();
        request.getSession().setAttribute(ok ? "successMessage" : "errorMessage",
                ok ? success : (daoMessage == null || daoMessage.isBlank() ? failure : daoMessage));
    }

    private String staffRedirect(HttpServletRequest request, String staffType) {
        String suffix = staffType == null || staffType.isBlank()
                ? ""
                : "&staffType=" + urlEncode(staffType);
        String anchor = "doctor_lab".equalsIgnoreCase(String.valueOf(staffType))
                ? "#labRolePane"
                : "#receptionistRolePane";
        return request.getContextPath() + "/admin?action=schedule" + suffix + anchor;
    }

    private boolean isJsonRequest(HttpServletRequest request) {
        String requestedWith = request.getHeader("X-Requested-With");
        String accept = request.getHeader("Accept");
        return "XMLHttpRequest".equalsIgnoreCase(requestedWith)
                || (accept != null && accept.toLowerCase().contains("application/json"));
    }

    private String urlEncode(String value) {
        try {
            return java.net.URLEncoder.encode(value, java.nio.charset.StandardCharsets.UTF_8.name());
        } catch (Exception ex) {
            return "";
        }
    }

    private Integer nullableInt(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        int value = parseInt(raw, Integer.MIN_VALUE);
        return value == Integer.MIN_VALUE ? null : value;
    }

    private String cleanText(String raw) {
        return raw == null || raw.trim().isEmpty() ? null : raw.trim();
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
}

/**
>>>>>>> Stashed changes
 * Handles AI-assisted schedule generation requests.
 */
class AdminAiSchedulingHandler {
    private final AdminAiSchedulingService aiSchedulingService = new AdminAiSchedulingService();
    public void aiSuggestTime(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        try {
            int doctorId = parseInt(request.getParameter("doctorId"), 0);
            Date workDate = nullableDate(request.getParameter("workDate"));
            if (doctorId <= 0 || workDate == null) {
                response.getWriter().print("{\"success\":false,\"message\":\"Thiếu doctorId hoặc workDate.\"}");
                return;
            }
            
            String suggestedTime = aiSchedulingService.suggestTimeSlot(doctorId, workDate);
            try (PrintWriter out = response.getWriter()) {
                if (suggestedTime != null) {
                    out.print("{\"success\":true,\"suggestedTime\":\"" + AdminJsonUtil.escapeJson(suggestedTime) + "\"}");
                } else {
                    out.print("{\"success\":false,\"message\":\"Không tìm thấy ca rảnh phù hợp cho bác sĩ.\"}");
                }
            }
        } catch (Exception ex) {
            response.getWriter().print("{\"success\":false,\"message\":\"Lỗi gợi ý AI: " + AdminJsonUtil.escapeJson(ex.getMessage()) + "\"}");
        }
    }
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
            aiRequest.preview = "true".equalsIgnoreCase(request.getParameter("preview"));

            AiSchedulingResult result = aiSchedulingService.createSchedules(aiRequest);
            List<Map<String, Object>> doctors = aiSchedulingRepository.getDoctorsForAiScheduling(aiRequest.startDate, aiRequest.endDate);
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"success\":");
                out.print(result.success);
                out.print(",\"preview\":");
                out.print(aiRequest.preview);
                out.print(",\"message\":\"");
                out.print(AdminJsonUtil.escapeJson(result.message));
                out.print("\",\"items\":");
                out.print(AdminJsonUtil.toJsonSimpleRows(result.items));
                out.print(",\"doctors\":");
                out.print(AdminJsonUtil.toJsonSimpleRows(doctors));
                out.print("}");
            }
        } catch (StackOverflowError error) {
            writeAiScheduleError(response, "Dữ liệu Gemini quá lớn để xử lý. Hệ thống đã chặn lỗi và chưa ghi lịch vào database.");
        } catch (RuntimeException error) {
            writeAiScheduleError(response, "Không thể xử lý lịch AI: " + (error.getMessage() == null ? "Lỗi dữ liệu không xác định." : error.getMessage()));
        }
    }

    public void aiSaveProposedSchedules(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        try {
            String[] doctorIds = request.getParameterValues("doctorId");
            String[] workDates = request.getParameterValues("workDate");
            String[] timeSlots = request.getParameterValues("timeSlot");
            String[] maxPatientsArr = request.getParameterValues("maxPatients");

            if (doctorIds == null || workDates == null || timeSlots == null || maxPatientsArr == null
                    || doctorIds.length == 0 || workDates.length != doctorIds.length 
                    || timeSlots.length != doctorIds.length || maxPatientsArr.length != doctorIds.length) {
                response.getWriter().print("{\"success\":false,\"message\":\"Dữ liệu lịch trực đề xuất không đồng bộ hoặc trống.\"}");
                return;
            }

            List<Map<String, Object>> schedules = new ArrayList<>();
            for (int i = 0; i < doctorIds.length; i++) {
                Map<String, Object> item = new java.util.HashMap<>();
                item.put("doctorId", Integer.parseInt(doctorIds[i]));
                item.put("workDate", workDates[i]);
                item.put("timeSlot", timeSlots[i]);
                item.put("maxPatients", Integer.parseInt(maxPatientsArr[i]));
                schedules.add(item);
            }

            boolean ok = aiSchedulingRepository.saveSchedules(schedules);
            try (PrintWriter out = response.getWriter()) {
                if (ok) {
                    out.print("{\"success\":true,\"message\":\"Đã lưu thành công " + schedules.size() + " ca lịch trực bác sĩ khám đề xuất bằng AI!\"}");
                } else {
                    out.print("{\"success\":false,\"message\":\"Không thể lưu lịch trực đề xuất vào cơ sở dữ liệu.\"}");
                }
            }
        } catch (Exception ex) {
            response.getWriter().print("{\"success\":false,\"message\":\"Lỗi lưu lịch trực đề xuất: " + AdminJsonUtil.escapeJson(ex.getMessage()) + "\"}");
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

