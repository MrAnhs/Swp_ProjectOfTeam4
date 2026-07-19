package com.diabetes.monitoring.admin.analytics;

import com.diabetes.monitoring.admin.common.ReportSeriesDTO;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Provides analytics use cases for dashboard and reports.
 */
public class AdminAnalyticsService {
    private final AdminDashboardService dashboardService = new AdminDashboardService();
    private final AdminReportService reportService = new AdminReportService();
    public void prepareDashboardData() { dashboardService.prepareDashboardData(); }
    public int getCountTotalAccounts() { return dashboardService.getCountTotalAccounts(); }
    public int getCountActiveAccounts() { return dashboardService.getCountActiveAccounts(); }
    public int getCountLockedAccounts() { return dashboardService.getCountLockedAccounts(); }
    public int getCountTotalServices() { return dashboardService.getCountTotalServices(); }
    public BigDecimal getSumPaidRevenue() { return dashboardService.getSumPaidRevenue(); }
    public int getCountCompletedAppointments() { return dashboardService.getCountCompletedAppointments(); }
    public List<Map<String, Object>> getTodayClinicQueueStatus() { return dashboardService.getTodayClinicQueueStatus(); }
    public List<Map<String, Object>> getTodaySchedules() { return dashboardService.getTodaySchedules(); }
    public int getTodayTotalVisits() { return dashboardService.getTodayTotalVisits(); }
    public int getTodayWaitingPatients() { return dashboardService.getTodayWaitingPatients(); }
    public List<Map<String, Object>> getTodayPatientFlowByTimeSlot() { return dashboardService.getTodayPatientFlowByTimeSlot(); }
    public List<Map<String, Object>> getTodayRevenueByServiceType() { return dashboardService.getTodayRevenueByServiceType(); }
    public List<Map<String, Object>> getTodayAppointmentStatusDistribution() { return dashboardService.getTodayAppointmentStatusDistribution(); }
    public List<Map<String, Object>> getDashboardRevenueSeries(String granularity) { return dashboardService.getDashboardRevenueSeries(granularity); }
    public List<Map<String, Object>> getDashboardVisitSeries(String granularity) { return dashboardService.getDashboardVisitSeries(granularity); }
    public List<Map<String, Object>> getQuickAccounts(String filter) { return dashboardService.getQuickAccounts(filter); }
    public List<Map<String, Object>> getQuickRevenue() { return dashboardService.getQuickRevenue(); }
    public List<Map<String, Object>> getQuickServices() { return dashboardService.getQuickServices(); }
    public List<Map<String, Object>> getQuickAppointments() { return dashboardService.getQuickAppointments(); }
    public List<ReportSeriesDTO> getRevenueSeries(String granularity, Integer year, Integer month, Integer day, LocalDate startDate, LocalDate endDate) { return reportService.getRevenueSeries(granularity, year, month, day, startDate, endDate); }
    public List<ReportSeriesDTO> getVisitSeries(String granularity, Integer year, Integer month, Integer day, LocalDate startDate, LocalDate endDate) { return reportService.getVisitSeries(granularity, year, month, day, startDate, endDate); }
    public Map<String, Object> getReportDetailByPeriod(String period) { return reportService.getReportDetailByPeriod(period); }
    public List<Map<String, Object>> getInvoiceItemsByInvoiceId(String invoiceId) { return reportService.getInvoiceItemsByInvoiceId(invoiceId); }
    public void refreshReportReadModels() { reportService.refreshReportReadModels(); }
}

/**
 * Coordinates dashboard data preparation and summary metrics.
 */
class AdminDashboardService {
    private final AdminDashboardDAO dashboardDAO = new AdminDashboardDAO();
    public void prepareDashboardData() {
        dashboardDAO.normalizeFutureCompletedAppointments();
    }
    public int getCountTotalAccounts() {
        return dashboardDAO.getCountTotalAccounts();
    }
    public int getCountActiveAccounts() {
        return dashboardDAO.getCountActiveAccounts();
    }
    public int getCountLockedAccounts() {
        return dashboardDAO.getCountLockedAccounts();
    }
    public int getCountTotalServices() {
        return dashboardDAO.getCountTotalServices();
    }
    public BigDecimal getSumPaidRevenue() {
        return dashboardDAO.getSumPaidRevenue();
    }
    public int getCountCompletedAppointments() {
        return dashboardDAO.getCountCompletedAppointments();
    }
    public List<Map<String, Object>> getTodayClinicQueueStatus() {
        return dashboardDAO.getTodayClinicQueueStatus();
    }
    public List<Map<String, Object>> getTodaySchedules() {
        return dashboardDAO.getTodaySchedules();
    }
    public int getTodayTotalVisits() {
        return dashboardDAO.getTodayTotalVisits();
    }
    public int getTodayWaitingPatients() {
        return dashboardDAO.getTodayWaitingPatients();
    }
    public List<Map<String, Object>> getTodayPatientFlowByTimeSlot() {
        return dashboardDAO.getTodayPatientFlowByTimeSlot();
    }
    public List<Map<String, Object>> getTodayRevenueByServiceType() {
        return dashboardDAO.getTodayRevenueByServiceType();
    }
    public List<Map<String, Object>> getTodayAppointmentStatusDistribution() {
        return dashboardDAO.getTodayAppointmentStatusDistribution();
    }
    public List<Map<String, Object>> getDashboardRevenueSeries(String granularity) {
        return dashboardDAO.getDashboardRevenueSeries(granularity);
    }
    public List<Map<String, Object>> getDashboardVisitSeries(String granularity) {
        return dashboardDAO.getDashboardVisitSeries(granularity);
    }
    public List<Map<String, Object>> getQuickAccounts(String filter) {
        String status = (filter == null || filter.isBlank() || "all".equalsIgnoreCase(filter)) ? null : filter;
        return dashboardDAO.getStaffAccountsQuick(status, 50);
    }
    public List<Map<String, Object>> getQuickRevenue() {
        return dashboardDAO.getRecentPaidInvoicesToday(10);
    }
    public List<Map<String, Object>> getQuickServices() {
        return dashboardDAO.getMedicalServices(null, null, null);
    }
    public List<Map<String, Object>> getQuickAppointments() {
        return dashboardDAO.getCompletedAppointmentsTodayQuick(50);
    }
}

/**
 * Builds report series and report detail models for Admin screens.
 */
class AdminReportService {
    private final AdminReportDAO reportDAO = new AdminReportDAO();
    public List<ReportSeriesDTO> getRevenueSeries(String granularity, Integer year, Integer month, Integer day, LocalDate startDate, LocalDate endDate) {
        return toSeries(reportDAO.getRevenueReport(granularity, year, month, day, startDate, endDate));
    }
    public List<ReportSeriesDTO> getVisitSeries(String granularity, Integer year, Integer month, Integer day, LocalDate startDate, LocalDate endDate) {
        return toSeries(reportDAO.getVisitReport(granularity, year, month, day, startDate, endDate));
    }
    public Map<String, Object> getReportDetailByPeriod(String period) {
        return reportDAO.getReportDetailByPeriod(period);
    }
    public List<Map<String, Object>> getInvoiceItemsByInvoiceId(String invoiceId) {
        return reportDAO.getInvoiceItemsByInvoiceId(invoiceId);
    }
    public void refreshReportReadModels() {
        reportDAO.markLateWaitingAppointmentsAsNoShow();
    }
    private List<ReportSeriesDTO> toSeries(List<Map<String, Object>> rows) {
        List<ReportSeriesDTO> result = new ArrayList<>();
        for (Map<String, Object> row : rows) {
            String period = row.get("periodLabel") == null ? "" : String.valueOf(row.get("periodLabel"));
            Object rawValue = row.get("metricValue");
            BigDecimal value = rawValue instanceof BigDecimal ? (BigDecimal) rawValue : new BigDecimal(String.valueOf(rawValue == null ? 0 : rawValue));
            result.add(new ReportSeriesDTO(period, value));
        }
        return result;
    }
}
