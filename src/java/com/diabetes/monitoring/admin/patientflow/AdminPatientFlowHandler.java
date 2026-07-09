package com.diabetes.monitoring.admin.patientflow;

import com.diabetes.monitoring.admin.common.AdminJsonUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Dispatches appointment workflow and emergency routing requests.
 */
public class AdminPatientFlowHandler {
    private final AdminAppointmentHandler appointmentHandler = new AdminAppointmentHandler();
    private final AdminEmergencyRoutingHandler emergencyRoutingHandler = new AdminEmergencyRoutingHandler();

    /**
     * Loads doctor queue detail data for the Admin UI.
     */
    public void loadDoctorQueueDetail(HttpServletRequest request, HttpServletResponse response) throws IOException { appointmentHandler.loadDoctorQueueDetail(request, response); }
    /**
     * Loads today appointments data for the Admin UI.
     */
    public void loadTodayAppointments(HttpServletResponse response) throws IOException { appointmentHandler.loadTodayAppointments(response); }
    /**
     * Loads today waiting data for the Admin UI.
     */
    public void loadTodayWaiting(HttpServletResponse response) throws IOException { appointmentHandler.loadTodayWaiting(response); }
    /**
     * Loads schedule appointments data for the Admin UI.
     */
    public void loadScheduleAppointments(HttpServletRequest request, HttpServletResponse response) throws IOException { appointmentHandler.loadScheduleAppointments(request, response); }
    public void updateAppointmentWorkflowStatus(HttpServletRequest request, HttpServletResponse response, String workflowStep) throws IOException { appointmentHandler.updateAppointmentWorkflowStatus(request, response, workflowStep); }
    /**
     * Loads exception routing data for the Admin UI.
     */
    public void loadExceptionRouting(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException { emergencyRoutingHandler.loadExceptionRouting(request, response); }
    public void emergencyReassign(HttpServletRequest request, HttpServletResponse response) throws IOException { emergencyRoutingHandler.emergencyReassign(request, response); }
}

/**
 * Handles appointment workflow actions for Admin.
 */
class AdminAppointmentHandler {
    private final AdminAppointmentWorkflowService appointmentService = new AdminAppointmentWorkflowService();

    /**
     * Loads doctor queue detail data for the Admin UI.
     */
    public void loadDoctorQueueDetail(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        try {
            appointmentService.refreshWaitingStates();
            int doctorId = parseInt(request.getParameter("doctorId"), -1);
            List<Map<String, Object>> items = doctorId > 0
                    ? appointmentService.getDoctorQueueDetailToday(doctorId)
                    : java.util.Collections.emptyList();
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"items\":");
                out.print(AdminJsonUtil.toJsonSimpleRows(items));
                out.print("}");
            }
        } catch (Exception ex) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"error\":\"true\",\"message\":\"Không thể tải chi tiết hàng đợi.\"}");
            }
        }
    }

    /**
     * Loads today appointments data for the Admin UI.
     */
    public void loadTodayAppointments(HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        try {
            appointmentService.refreshWaitingStates();
            List<Map<String, Object>> items = appointmentService.getTodayAppointments();
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"items\":");
                out.print(AdminJsonUtil.toJsonSimpleRows(items));
                out.print("}");
            }
        } catch (Exception ex) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"error\":\"true\",\"message\":\"Không thể tải lịch hẹn hôm nay.\"}");
            }
        }
    }

    /**
     * Loads today waiting data for the Admin UI.
     */
    public void loadTodayWaiting(HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        try {
            appointmentService.refreshWaitingStates();
            List<Map<String, Object>> items = appointmentService.getTodayWaitingDetails();
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"items\":");
                out.print(AdminJsonUtil.toJsonSimpleRows(items));
                out.print("}");
            }
        } catch (Exception ex) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"error\":\"true\",\"message\":\"Không thể tải danh sách chờ.\"}");
            }
        }
    }

    /**
     * Loads schedule appointments data for the Admin UI.
     */
    public void loadScheduleAppointments(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int scheduleId = parseInt(request.getParameter("scheduleId"), -1);
        response.setContentType("application/json;charset=UTF-8");
        try (PrintWriter out = response.getWriter()) {
            List<Map<String, Object>> items = scheduleId > 0
                    ? appointmentService.getAppointmentsBySchedule(scheduleId)
                    : java.util.Collections.emptyList();
            out.print("{\"scheduleId\":");
            out.print(scheduleId);
            out.print(",\"items\":");
            out.print(AdminJsonUtil.toJsonSimpleRows(items));
            out.print("}");
        } catch (Exception ex) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"error\":\"true\",\"message\":\"Không thể tải danh sách bệnh nhân của ca trực.\"}");
            }
        }
    }

    public void updateAppointmentWorkflowStatus(HttpServletRequest request, HttpServletResponse response, String workflowStep) throws IOException {
        int appointmentId = parseInt(request.getParameter("appointmentId"), -1);
        boolean success = false;
        String message;

        if (appointmentId <= 0) {
            message = "Mã lịch hẹn không hợp lệ";
        } else if ("checkIn".equals(workflowStep)) {
            success = appointmentService.checkIn(appointmentId);
            message = success ? "Đã check-in lịch hẹn" : "Không thể check-in lịch hẹn";
        } else if ("start".equals(workflowStep)) {
            success = appointmentService.start(appointmentId);
            message = success ? "Đã chuyển lịch hẹn sang đang khám" : "Không thể bắt đầu lượt khám";
        } else if ("complete".equals(workflowStep)) {
            success = appointmentService.complete(appointmentId);
            message = success ? "Đã hoàn tất lượt khám" : "Không thể hoàn tất lượt khám";
        } else {
            message = "Hành động không hợp lệ";
        }

        if (isJsonRequest(request)) {
            response.setContentType("application/json;charset=UTF-8");
            response.setStatus(success ? HttpServletResponse.SC_OK : HttpServletResponse.SC_BAD_REQUEST);
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"success\":" + success + ",\"message\":\"" + AdminJsonUtil.escapeJson(message) + "\"}");
            }
            return;
        }

        request.getSession().setAttribute(success ? "successMessage" : "errorMessage", message);
        response.sendRedirect(request.getContextPath() + "/admin");
    }

    private boolean isJsonRequest(HttpServletRequest request) {
        String ct = request.getContentType();
        String xrw = request.getHeader("X-Requested-With");
        return (ct != null && ct.toLowerCase().contains("application/json"))
                || (xrw != null && "XMLHttpRequest".equalsIgnoreCase(xrw))
                || (request.getHeader("Accept") != null && request.getHeader("Accept").toLowerCase().contains("application/json"));
    }

    private int parseInt(String raw, int fallback) {
        try {
            return Integer.parseInt(raw);
        } catch (Exception ex) {
            return fallback;
        }
    }
}

/**
 * Handles emergency reassignment screens and actions.
 */
class AdminEmergencyRoutingHandler {
    private final AdminEmergencyRoutingService emergencyRoutingService = new AdminEmergencyRoutingService();

    /**
     * Loads exception routing data for the Admin UI.
     */
    public void loadExceptionRouting(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        Integer doctorId = nullableInt(request.getParameter("doctorId"));
        List<Map<String, Object>> queueItems = emergencyRoutingService.loadExceptionQueue(doctorId);

        Integer selectedAppointmentId = nullableInt(request.getParameter("appointmentId"));
        List<Map<String, Object>> candidateDoctors = new ArrayList<>();
        if (selectedAppointmentId != null) {
            for (Map<String, Object> item : queueItems) {
                Integer aid = nullableInt(String.valueOf(item.get("appointmentId")));
                if (aid != null && aid.equals(selectedAppointmentId)) {
                    Integer currentDoctorId = nullableInt(String.valueOf(item.get("currentDoctorId")));
                    candidateDoctors = emergencyRoutingService.getEmergencyCandidateDoctorsForAppointment(selectedAppointmentId, currentDoctorId);
                    request.setAttribute("selectedQueueItem", item);
                    break;
                }
            }
        }

        request.setAttribute("queueItems", queueItems);
        request.setAttribute("selectedAppointmentId", selectedAppointmentId);
        request.setAttribute("candidateDoctors", candidateDoctors);
        request.getRequestDispatcher("/WEB-INF/views/admin/exception-routing.jsp").forward(request, response);
    }

    public void emergencyReassign(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int appointmentId = parseInt(request.getParameter("appointmentId"), -1);
        String[] targetDoctorIds = request.getParameterValues("targetDoctorId");

        if (appointmentId <= 0 || targetDoctorIds == null || targetDoctorIds.length == 0) {
            request.getSession().setAttribute("errorMessage", "Vui lòng chọn ít nhất một bác sĩ tái điều phối");
            response.sendRedirect(request.getContextPath() + "/admin?action=exception");
            return;
        }

        int primaryDoctorId = parseInt(targetDoctorIds[0], -1);
        boolean ok = primaryDoctorId > 0 && emergencyRoutingService.reassignAppointmentToDoctor(appointmentId, primaryDoctorId);

        request.getSession().setAttribute(ok ? "successMessage" : "errorMessage",
                ok ? "Đã tái điều phối khẩn cấp cho " + targetDoctorIds[0] + " và ghi nhận " + (targetDoctorIds.length - 1) + " bác sĩ dự phòng"
                        : "Không thể tái điều phối khẩn cấp");
        response.sendRedirect(request.getContextPath() + "/admin?action=exception");
    }

    private Integer nullableInt(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        try {
            return Integer.parseInt(raw);
        } catch (Exception ex) {
            return null;
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
