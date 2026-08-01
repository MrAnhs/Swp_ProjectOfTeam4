package com.diabetes.monitoring.admin;

import com.diabetes.monitoring.admin.analytics.AdminAnalyticsHandler;
import com.diabetes.monitoring.admin.management.AdminManagementHandler;
import com.diabetes.monitoring.admin.patientflow.AdminPatientFlowHandler;
import com.diabetes.monitoring.admin.scheduling.AdminSchedulingHandler;

import com.diabetes.monitoring.model.User;
import com.diabetes.monitoring.util.CsrfUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

/**
 * Front controller for the Admin area.
 * Delegates dashboard, management, scheduling, and patient-flow actions.
 */
public class AdminServlet extends HttpServlet {
    private final AdminAnalyticsHandler analyticsHandler = new AdminAnalyticsHandler();
    private final AdminManagementHandler managementHandler = new AdminManagementHandler();
    private final AdminSchedulingHandler schedulingHandler = new AdminSchedulingHandler();
    private final AdminPatientFlowHandler patientFlowHandler = new AdminPatientFlowHandler();


    /**
     * Handles read-only Admin requests and forwards them to matching handlers.
     *
     * @param request  current HTTP request
     * @param response current HTTP response
     * @throws ServletException when a JSP forward or servlet operation fails
     * @throws IOException      when writing or redirecting the response fails
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!ensureAdminAccess(request, response)) {
            return;
        }
        CsrfUtil.getOrCreateToken(request.getSession());

        String action = request.getParameter("action");
        if (action == null || action.isBlank() || "dashboard".equals(action)) {
            analyticsHandler.loadDashboard(request, response);
            return;
        }

        if ("reports".equals(action)) {
            analyticsHandler.loadReports(request, response);
            return;
        }
        if ("getReportDetail".equals(action) || "getInvoiceItems".equals(action)) {
            response.setContentType("application/json;charset=UTF-8");
            try (java.io.PrintWriter out = response.getWriter()) {
                out.print(
                        "{\"success\":false,\"message\":\"Chức năng báo cáo cũ đã được tích hợp vào Dashboard mới.\"}");
            }
            return;
        }



        if ("listUsers".equals(action)) {
            managementHandler.loadAccounts(request, response);
            return;
        }

        if ("getAccountProfile".equals(action)) {
            managementHandler.loadAccountProfile(request, response);
            return;
        }

        if ("manageServices".equals(action)) {
            managementHandler.loadServices(request, response);
            return;
        }

        if ("manageRooms".equals(action)) {
            managementHandler.loadRooms(request, response);
            return;
        }

        if ("dashboardChartData".equals(action)) {
            analyticsHandler.loadDashboardChartData(request, response);
            return;
        }

        if ("dashboardModalData".equals(action)) {
            analyticsHandler.loadDashboardModalData(request, response);
            return;
        }

        if ("quickAccountsData".equals(action)) {
            analyticsHandler.loadQuickAccountsData(request, response);
            return;
        }

        if ("quickRevenueData".equals(action)) {
            analyticsHandler.loadQuickRevenueData(response);
            return;
        }

        if ("quickServicesData".equals(action)) {
            analyticsHandler.loadQuickServicesData(response);
            return;
        }

        if ("quickAppointmentsData".equals(action)) {
            analyticsHandler.loadQuickAppointmentsData(response);
            return;
        }

        if ("schedule".equals(action) || "manageSchedules".equals(action)) {
            schedulingHandler.loadSchedules(request, response);
            return;
        }

        if ("getCalendarSchedule".equals(action)) {
            schedulingHandler.getCalendarSchedule(request, response);
            return;
        }

        if ("getShiftDetail".equals(action) || "getStaffSchedule".equals(action)) {
            schedulingHandler.getShiftDetail(request, response);
            return;
        }

        if ("confirmAISchedule".equals(action)) {
            schedulingHandler.confirmAISchedule(request, response);
            return;
        }

        if ("getSchedule".equals(action)) {
            schedulingHandler.loadScheduleDetail(request, response);
            return;
        }

        if ("getTransferCandidates".equals(action)) {
            schedulingHandler.loadTransferCandidates(request, response);
            return;
        }

        if ("exception".equals(action) || "viewHealthRecords".equals(action)) {
            patientFlowHandler.loadExceptionRouting(request, response);
            return;
        }

        if ("getDoctorQueueDetail".equals(action)) {
            patientFlowHandler.loadDoctorQueueDetail(request, response);
            return;
        }
        if ("getTodayAppointments".equals(action)) {
            patientFlowHandler.loadTodayAppointments(response);
            return;
        }
        if ("getTodayWaiting".equals(action)) {
            patientFlowHandler.loadTodayWaiting(response);
            return;
        }
        if ("scheduleAppointments".equals(action)) {
            patientFlowHandler.loadScheduleAppointments(request, response);
            return;
        }

        if ("aiCreateSchedules".equals(action)) {
            schedulingHandler.aiCreateSchedules(request, response);
            return;
        }

        analyticsHandler.loadDashboard(request, response);
    }

    /**
     * Handles mutating Admin requests after validating Admin access and CSRF token.
     *
     * @param request  current HTTP request
     * @param response current HTTP response
     * @throws ServletException when a downstream servlet operation fails
     * @throws IOException      when writing or redirecting the response fails
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!ensureAdminAccess(request, response)) {
            return;
        }
        if (!CsrfUtil.isValid(request)) {
            handleInvalidCsrf(request, response);
            return;
        }

        String action = request.getParameter("action");

        if ("getTransferCandidates".equals(action)) {
            schedulingHandler.loadTransferCandidates(request, response);
            return;
        }



        if ("createAccount".equals(action)) {
            managementHandler.createAccount(request, response);
            return;
        }
        if ("updateAccountRole".equals(action)) {
            managementHandler.updateAccountRole(request, response);
            return;
        }
        if ("lockAccount".equals(action)) {
            managementHandler.updateAccountStatus(request, response, "locked");
            return;
        }
        if ("reactivateAccount".equals(action)) {
            managementHandler.updateAccountStatus(request, response, "active");
            return;
        }
        if ("deleteAccount".equals(action)) {
            managementHandler.deleteAccount(request, response);
            return;
        }
        if ("updateAccountProfile".equals(action)) {
            managementHandler.updateAccountProfile(request, response);
            return;
        }
        if ("updateAccountPassword".equals(action)) {
            managementHandler.updateAccountPassword(request, response);
            return;
        }
        if ("ajaxToggleAccountStatus".equals(action)) {
            managementHandler.ajaxToggleAccountStatus(request, response);
            return;
        }

        if ("createService".equals(action)) {
            managementHandler.createService(request, response);
            return;
        }
        if ("updateService".equals(action)) {
            managementHandler.updateService(request, response);
            return;
        }
        if ("updateServiceStatus".equals(action) || "ajaxToggleServiceStatus".equals(action)) {
            managementHandler.updateServiceStatus(request, response);
            return;
        }
        if ("deleteService".equals(action)) {
            managementHandler.deleteService(request, response);
            return;
        }

        if ("createRoom".equals(action)) {
            managementHandler.createRoom(request, response);
            return;
        }
        if ("updateRoom".equals(action)) {
            managementHandler.updateRoom(request, response);
            return;
        }
        if ("deleteRoom".equals(action)) {
            managementHandler.deleteRoom(request, response);
            return;
        }

        if ("createSchedule".equals(action)) {
            schedulingHandler.createSchedule(request, response);
            return;
        }
        if ("updateSchedule".equals(action)) {
            schedulingHandler.updateSchedule(request, response);
            return;
        }
        if ("deleteSchedule".equals(action)) {
            schedulingHandler.deleteSchedule(request, response);
            return;
        }
        if ("approveSchedule".equals(action)) {
            schedulingHandler.approveSchedule(request, response);
            return;
        }
        if ("cancelSchedule".equals(action)) {
            schedulingHandler.cancelSchedule(request, response);
            return;
        }
        if ("transferSchedule".equals(action)) {
            schedulingHandler.transferSchedule(request, response);
            return;
        }

        if ("create-staff-schedule".equals(action)) {
            schedulingHandler.createStaffSchedule(request, response);
            return;
        }
        if ("update-staff-schedule".equals(action)) {
            schedulingHandler.updateStaffSchedule(request, response);
            return;
        }
        if ("cancel-staff-schedule".equals(action)) {
            schedulingHandler.cancelStaffSchedule(request, response);
            return;
        }
        if ("delete-staff-schedule".equals(action)) {
            schedulingHandler.deleteStaffSchedule(request, response);
            return;
        }

        if ("resolveScheduleConflict".equals(action)) {
            schedulingHandler.resolveScheduleConflict(request, response);
            return;
        }
        if ("autoResolveAllConflicts".equals(action)) {
            schedulingHandler.autoResolveAllConflicts(request, response);
            return;
        }

        if ("aiCreateSchedules".equals(action)) {
            schedulingHandler.aiCreateSchedules(request, response);
            return;
        }

        if ("emergencyReassign".equals(action)) {
            patientFlowHandler.emergencyReassign(request, response);
            return;
        }

        if ("checkInAppointment".equals(action)) {
            patientFlowHandler.updateAppointmentWorkflowStatus(request, response, "checkIn");
            return;
        }
        if ("startAppointment".equals(action)) {
            patientFlowHandler.updateAppointmentWorkflowStatus(request, response, "start");
            return;
        }
        if ("completeAppointment".equals(action)) {
            patientFlowHandler.updateAppointmentWorkflowStatus(request, response, "complete");
            return;
        }

        if ("aiSaveProposedSchedules".equals(action)) {
            schedulingHandler.aiSaveProposedSchedules(request, response);
            return;
        }

        if ("ai-staff-schedule".equals(action)) {
            schedulingHandler.aiStaffSchedule(request, response);
            return;
        }

        request.getSession().setAttribute("errorMessage", "Hành động không hợp lệ");
        response.sendRedirect(request.getContextPath() + "/admin");
    }

    /**
     * Verifies that the current session belongs to an Admin user.
     *
     * @param request  current HTTP request
     * @param response current HTTP response
     * @return {@code true} when the current user is allowed to access Admin pages
     * @throws IOException when sending a redirect or JSON error response fails
     */
    private boolean ensureAdminAccess(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        User currentUser = session == null ? null : (User) session.getAttribute("currentUser");
        if (currentUser != null && "Admin".equalsIgnoreCase(currentUser.getRole())) {
            return true;
        }

        if (isJsonRequest(request)) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"success\":false,\"message\":\"Bạn không có quyền truy cập khu vực Admin\"}");
            return false;
        }

        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return false;
    }

    /**
     * Sends a consistent error response for invalid CSRF tokens.
     *
     * @param request  current HTTP request
     * @param response current HTTP response
     * @throws IOException when writing or redirecting the response fails
     */
    private void handleInvalidCsrf(HttpServletRequest request, HttpServletResponse response) throws IOException {
        if (isJsonRequest(request)) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"success\":false,\"message\":\"CSRF token không hợp lệ\"}");
            return;
        }

        request.getSession().setAttribute("errorMessage", "Phiên bảo mật không hợp lệ, vui lòng thử lại.");
        response.sendRedirect(request.getContextPath() + "/admin");
    }

    /**
     * Detects AJAX or JSON-oriented requests so the servlet can return JSON errors.
     *
     * @param request current HTTP request
     * @return {@code true} when the client expects a JSON response
     */
    private boolean isJsonRequest(HttpServletRequest request) {
        String requestedWith = request.getHeader("X-Requested-With");
        String accept = request.getHeader("Accept");
        String contentType = request.getContentType();
        return "XMLHttpRequest".equalsIgnoreCase(requestedWith)
                || (accept != null && accept.toLowerCase().contains("application/json"))
                || (contentType != null && contentType.toLowerCase().contains("application/json"));
    }
}

