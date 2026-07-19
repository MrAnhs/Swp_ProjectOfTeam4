package com.diabetes.monitoring.admin.analytics;

import com.diabetes.monitoring.admin.common.AdminJsonUtil;
import com.diabetes.monitoring.admin.common.ReportSeriesDTO;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/**
 * Dispatches dashboard and report requests from the Admin servlet.
 */
public class AdminAnalyticsHandler {
    private final AdminDashboardHandler dashboardHandler = new AdminDashboardHandler();
    private final AdminReportHandler reportHandler = new AdminReportHandler();

    /**
     * Loads dashboard data for the Admin UI.
     */
    public void loadDashboard(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException { dashboardHandler.loadDashboard(request, response); }
    /**
     * Loads dashboard chart data for the Admin UI.
     */
    public void loadDashboardChartData(HttpServletRequest request, HttpServletResponse response) throws IOException { dashboardHandler.loadDashboardChartData(request, response); }
    /**
     * Loads quick accounts data for the Admin UI.
     */
    public void loadQuickAccountsData(HttpServletRequest request, HttpServletResponse response) throws IOException { dashboardHandler.loadQuickAccountsData(request, response); }
    /**
     * Loads quick revenue data for the Admin UI.
     */
    public void loadQuickRevenueData(HttpServletResponse response) throws IOException { dashboardHandler.loadQuickRevenueData(response); }
    /**
     * Loads quick services data for the Admin UI.
     */
    public void loadQuickServicesData(HttpServletResponse response) throws IOException { dashboardHandler.loadQuickServicesData(response); }
    /**
     * Loads quick appointments data for the Admin UI.
     */
    public void loadQuickAppointmentsData(HttpServletResponse response) throws IOException { dashboardHandler.loadQuickAppointmentsData(response); }
    /**
     * Loads dashboard modal details data via AJAX.
     */
    public void loadDashboardModalData(HttpServletRequest request, HttpServletResponse response) throws IOException { dashboardHandler.loadDashboardModalData(request, response); }
    /**
     * Loads reports data for the Admin UI.
     */
    public void loadReports(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException { reportHandler.loadReports(request, response); }
    /**
     * Loads report detail by period data for the Admin UI.
     */
    public void loadReportDetailByPeriod(HttpServletRequest request, HttpServletResponse response) throws IOException { reportHandler.loadReportDetailByPeriod(request, response); }
    /**
     * Loads invoice items data for the Admin UI.
     */
    public void loadInvoiceItems(HttpServletRequest request, HttpServletResponse response) throws IOException { reportHandler.loadInvoiceItems(request, response); }
}

/**
 * Prepares dashboard views and dashboard AJAX responses.
 */
class AdminDashboardHandler {
    private final AdminDashboardService dashboardService = new AdminDashboardService();

    /**
     * Loads dashboard data for the Admin UI.
     */
    public void loadDashboard(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        dashboardService.prepareDashboardData();

        int totalAccounts = dashboardService.getCountTotalAccounts();
        int activeAccounts = dashboardService.getCountActiveAccounts();
        int lockedAccounts = dashboardService.getCountLockedAccounts();
        int totalServices = dashboardService.getCountTotalServices();
        BigDecimal totalRevenuePaid = dashboardService.getSumPaidRevenue();
        int completedAppointments = dashboardService.getCountCompletedAppointments();
        List<Map<String, Object>> todayQueueStatus = dashboardService.getTodayClinicQueueStatus();
        List<Map<String, Object>> todayShiftsList = dashboardService.getTodaySchedules();
        int totalVisitsToday = dashboardService.getTodayTotalVisits();
        int waitingPatientsToday = dashboardService.getTodayWaitingPatients();
        int availableBedsToday = 15;
        List<Map<String, Object>> todayPatientFlow = dashboardService.getTodayPatientFlowByTimeSlot();
        List<Map<String, Object>> todayRevenueByService = dashboardService.getTodayRevenueByServiceType();
        List<Map<String, Object>> todayStatusDistribution = dashboardService.getTodayAppointmentStatusDistribution();

        int todayPatientsCount = dashboardService.getTodayPatientsCount();
        int todayAppointmentsCount = dashboardService.getTodayAppointmentsCount();
        BigDecimal sumRevenueToday = dashboardService.getSumRevenueToday();
        int completedAppointmentsToday = dashboardService.getCompletedAppointmentsToday();
        int patientsWaiting = dashboardService.getPatientsWaitingCount();
        int patientsInProgress = dashboardService.getPatientsInProgressCount();
        int activeRooms = dashboardService.getActiveRoomsCount();

        int totalWaitingToday = 0;
        for (Map<String, Object> row : todayQueueStatus) {
            totalWaitingToday += parseInt(String.valueOf(row.get("waitingCount")), 0);
        }

        request.setAttribute("totalAccounts", totalAccounts);
        request.setAttribute("activeAccounts", activeAccounts);
        request.setAttribute("lockedAccounts", lockedAccounts);
        request.setAttribute("totalServices", totalServices);
        request.setAttribute("sumPaidRevenue", totalRevenuePaid);
        request.setAttribute("completedAppointments", completedAppointments);
        request.setAttribute("todayPatientsCount", todayPatientsCount);
        request.setAttribute("todayAppointmentsCount", todayAppointmentsCount);
        request.setAttribute("sumRevenueToday", sumRevenueToday);
        request.setAttribute("completedAppointmentsToday", completedAppointmentsToday);

        request.setAttribute("patientsWaiting", patientsWaiting);
        request.setAttribute("patientsInProgress", patientsInProgress);
        request.setAttribute("activeRooms", activeRooms);

        request.setAttribute("appointmentStatusSummary", dashboardService.getAppointmentStatusSummary());
        request.setAttribute("roomQueueSummary", dashboardService.getRoomQueueSummary());

        request.setAttribute("activeAccounts",
                dashboardService.getCountActiveAccounts());
        request.setAttribute("lockedAccounts",
                dashboardService.getCountLockedAccounts());
        request.setAttribute("todayScheduleCounts",
                dashboardService.getTodayScheduleCounts());
        request.setAttribute("scheduleStatusSummary",
                dashboardService.getScheduleStatusSummary());
        request.setAttribute("recentAdminActivities",
                dashboardService.getRecentAdminActivities(10));
        request.getRequestDispatcher("/WEB-INF/views/admin/dashboard/dashboard.jsp")
                .forward(request, response);
    }

    /**
     * Loads dashboard chart data for the Admin UI.
     */
    public void loadDashboardChartData(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        try {
            String granularity = request.getParameter("granularity");
            if (granularity == null || granularity.isBlank()) {
                granularity = "month";
            }

            List<Map<String, Object>> revenueSeries = dashboardService.getDashboardRevenueSeries(granularity);
            List<Map<String, Object>> visitSeries = dashboardService.getDashboardVisitSeries(granularity);

            try (PrintWriter out = response.getWriter()) {
                out.print("{\"granularity\":\"");
                out.print(AdminJsonUtil.escapeJson(granularity.toLowerCase()));
                out.print("\",\"revenue\":");
                out.print(AdminJsonUtil.toJsonSeries(revenueSeries));
                out.print(",\"visits\":");
                out.print(AdminJsonUtil.toJsonSeries(visitSeries));
                out.print("}");
            }
        } catch (Exception ex) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"error\":\"true\",\"message\":\"Không thể tải dữ liệu biểu đồ.\"}");
            }
        }
    }

    /**
     * Loads quick accounts data for the Admin UI.
     */
    public void loadQuickAccountsData(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        try {
            String filter = request.getParameter("filter");
            List<Map<String, Object>> items = dashboardService.getQuickAccounts(filter);
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"filter\":\"");
                out.print(AdminJsonUtil.escapeJson(filter == null ? "all" : filter));
                out.print("\",\"summary\":{");
                out.print("\"totalAccounts\":");
                out.print(dashboardService.getCountTotalAccounts());
                out.print(",\"activeAccounts\":");
                out.print(dashboardService.getCountActiveAccounts());
                out.print(",\"lockedAccounts\":");
                out.print(dashboardService.getCountLockedAccounts());
                out.print("},\"items\":");
                out.print(AdminJsonUtil.toJsonSimpleRows(items));
                out.print("}");
            }
        } catch (Exception ex) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"error\":\"true\",\"message\":\"Không thể tải dữ liệu tài khoản.\"}");
            }
        }
    }

    /**
     * Loads quick revenue data for the Admin UI.
     */
    public void loadQuickRevenueData(HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        try {
            List<Map<String, Object>> items = dashboardService.getQuickRevenue();
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"items\":");
                out.print(AdminJsonUtil.toJsonSimpleRows(items));
                out.print("}");
            }
        } catch (Exception ex) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"error\":\"true\",\"message\":\"Không thể tải dữ liệu doanh thu.\"}");
            }
        }
    }

    /**
     * Loads quick services data for the Admin UI.
     */
    public void loadQuickServicesData(HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        try {
            List<Map<String, Object>> items = dashboardService.getQuickServices();
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"summary\":{\"activeServices\":");
                out.print(dashboardService.getCountTotalServices());
                out.print("},\"items\":");
                out.print(AdminJsonUtil.toJsonSimpleRows(items));
                out.print("}");
            }
        } catch (Exception ex) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"error\":\"true\",\"message\":\"Không thể tải dữ liệu dịch vụ.\"}");
            }
        }
    }

    /**
     * Loads quick appointments data for the Admin UI.
     */
    public void loadQuickAppointmentsData(HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        try {
            List<Map<String, Object>> items = dashboardService.getQuickAppointments();
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"items\":");
                out.print(AdminJsonUtil.toJsonSimpleRows(items));
                out.print("}");
            }
        } catch (Exception ex) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"error\":\"true\",\"message\":\"Không thể tải dữ liệu lượt khám.\"}");
            }
        }
    }

    /**
     * Loads dashboard modal details data for the Admin UI.
     */
    public void loadDashboardModalData(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        try {
            String type = request.getParameter("type");
            String id = request.getParameter("id");
            if (type == null || type.isBlank()) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                try (PrintWriter out = response.getWriter()) {
                    out.print("{\"error\":\"true\",\"message\":\"Thiếu tham số type.\"}");
                }
                return;
            }

            Map<String, Object> data = dashboardService.getModalDetails(type, id);
            try (PrintWriter out = response.getWriter()) {
                out.print(AdminJsonUtil.toJsonMap(data));
            }
        } catch (Exception ex) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"error\":\"true\",\"message\":\"Không thể tải dữ liệu chi tiết.\"}");
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

/**
 * Prepares revenue and visit report views and drill-down APIs.
 */
class AdminReportHandler {
    private final AdminReportService reportService = new AdminReportService();

    /**
     * Loads reports data for the Admin UI.
     */
    public void loadReports(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        reportService.refreshReportReadModels();

        String granularity = request.getParameter("granularity");
        if (granularity == null || granularity.isBlank()) {
            granularity = "month";
        }
        String reportStartDateParam = request.getParameter("reportStartDate");
        String reportEndDateParam = request.getParameter("reportEndDate");
        Integer year = nullableInt(request.getParameter("year"));
        Integer month = nullableInt(request.getParameter("month"));
        Integer day = nullableInt(request.getParameter("day"));

        LocalDate reportStartDate = null;
        LocalDate reportEndDate = null;

        if ("day".equalsIgnoreCase(granularity)) {
            try {
                if ((reportStartDateParam == null || reportStartDateParam.isBlank())
                        && (reportEndDateParam == null || reportEndDateParam.isBlank())) {
                    LocalDate now = LocalDate.now();
                    reportStartDate = now.withDayOfMonth(1);
                    reportEndDate = now.withDayOfMonth(now.lengthOfMonth());
                } else {
                    reportStartDate = (reportStartDateParam == null || reportStartDateParam.isBlank()) ? null : LocalDate.parse(reportStartDateParam.trim());
                    reportEndDate = (reportEndDateParam == null || reportEndDateParam.isBlank()) ? null : LocalDate.parse(reportEndDateParam.trim());

                    if (reportStartDate == null && reportEndDate != null) {
                        reportStartDate = reportEndDate;
                    } else if (reportStartDate != null && reportEndDate == null) {
                        reportEndDate = reportStartDate;
                    }

                    if (reportStartDate != null && reportEndDate != null && reportStartDate.isAfter(reportEndDate)) {
                        LocalDate temp = reportStartDate;
                        reportStartDate = reportEndDate;
                        reportEndDate = temp;
                    }
                }
            } catch (Exception ex) {
                request.setAttribute("errorMessage", "Khoảng ngày lọc không hợp lệ.");
                LocalDate now = LocalDate.now();
                reportStartDate = now.withDayOfMonth(1);
                reportEndDate = now.withDayOfMonth(now.lengthOfMonth());
            }
        }

        List<ReportSeriesDTO> revenueSeries = reportService.getRevenueSeries(granularity, year, month, day, reportStartDate, reportEndDate);
        List<ReportSeriesDTO> visitSeries = reportService.getVisitSeries(granularity, year, month, day, reportStartDate, reportEndDate);

        request.setAttribute("granularity", granularity);
        request.setAttribute("year", year);
        request.setAttribute("month", month);
        request.setAttribute("day", day);
        request.setAttribute("reportStartDate", reportStartDate == null ? "" : reportStartDate.toString());
        request.setAttribute("reportEndDate", reportEndDate == null ? "" : reportEndDate.toString());
        request.setAttribute("revenueSeries", revenueSeries);
        request.setAttribute("visitSeries", visitSeries);
        request.setAttribute("revenueJson", toJsonSeries(revenueSeries));
        request.setAttribute("visitJson", toJsonSeries(visitSeries));

        RequestDispatcher dispatcher = request.getRequestDispatcher("/WEB-INF/views/admin/reports.jsp");
        dispatcher.forward(request, response);
    }

    /**
     * Loads report detail by period data for the Admin UI.
     */
    public void loadReportDetailByPeriod(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        try {
            String period = request.getParameter("period");
            if (period == null || period.isBlank()) {
                try (PrintWriter out = response.getWriter()) {
                    out.print("{\"invoices\":[],\"appointments\":[]}");
                }
                return;
            }

            Map<String, Object> result = reportService.getReportDetailByPeriod(period);
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"invoices\":");
                out.print(AdminJsonUtil.toJsonInvoices(castList(result.get("invoices"))));
                out.print(",\"appointments\":");
                out.print(AdminJsonUtil.toJsonAppointments(castList(result.get("appointments"))));
                out.print("}");
            }
        } catch (Exception ex) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"error\":\"true\",\"message\":\"Không thể tải chi tiết báo cáo.\"}");
            }
        }
    }

    /**
     * Loads invoice items data for the Admin UI.
     */
    public void loadInvoiceItems(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        try {
            String invoiceId = request.getParameter("invoiceId");
            List<Map<String, Object>> items = reportService.getInvoiceItemsByInvoiceId(invoiceId);
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"invoiceId\":\"");
                out.print(AdminJsonUtil.escapeJson(invoiceId == null ? "" : invoiceId));
                out.print("\",\"items\":");
                out.print(AdminJsonUtil.toJsonInvoiceItems(items));
                out.print("}");
            }
        } catch (Exception ex) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"error\":\"true\",\"message\":\"Không thể tải hóa đơn.\"}");
            }
        }
    }

    private String toJsonSeries(List<ReportSeriesDTO> series) {
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < series.size(); i++) {
            if (i > 0) {
                sb.append(",");
            }
            ReportSeriesDTO item = series.get(i);
            sb.append("{\"period\":\"")
                    .append(AdminJsonUtil.escapeJson(item.getPeriod()))
                    .append("\",\"value\":")
                    .append(item.getValue().toPlainString())
                    .append("}");
        }
        sb.append("]");
        return sb.toString();
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

    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> castList(Object value) {
        if (value instanceof List<?>) {
            return (List<Map<String, Object>>) value;
        }
        return java.util.Collections.emptyList();
    }
}
