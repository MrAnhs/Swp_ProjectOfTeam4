package com.diabetes.monitoring.admin.analytics;

import com.diabetes.monitoring.admin.common.AdminRepository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/**
 * Facade over dashboard and report persistence operations.
 */
public class AdminAnalyticsDAO {
    private final AdminDashboardDAO dashboardDAO = new AdminDashboardDAO();
    private final AdminReportDAO reportDAO = new AdminReportDAO();
    public void normalizeFutureCompletedAppointments() { dashboardDAO.normalizeFutureCompletedAppointments(); }
    public void autoAdvanceAppointmentWorkflowDemo() { dashboardDAO.autoAdvanceAppointmentWorkflowDemo(); }
    public int getCountTotalAccounts() { return dashboardDAO.getCountTotalAccounts(); }
    public int getCountActiveAccounts() { return dashboardDAO.getCountActiveAccounts(); }
    public int getCountLockedAccounts() { return dashboardDAO.getCountLockedAccounts(); }
    public int getCountTotalServices() { return dashboardDAO.getCountTotalServices(); }
    public BigDecimal getSumPaidRevenue() { return dashboardDAO.getSumPaidRevenue(); }
    public int getCountCompletedAppointments() { return dashboardDAO.getCountCompletedAppointments(); }
    public List<Map<String, Object>> getTodayClinicQueueStatus() { return dashboardDAO.getTodayClinicQueueStatus(); }
    public List<Map<String, Object>> getTodaySchedules() { return dashboardDAO.getTodaySchedules(); }
    public int getTodayTotalVisits() { return dashboardDAO.getTodayTotalVisits(); }
    public int getTodayWaitingPatients() { return dashboardDAO.getTodayWaitingPatients(); }
    public List<Map<String, Object>> getTodayPatientFlowByTimeSlot() { return dashboardDAO.getTodayPatientFlowByTimeSlot(); }
    public List<Map<String, Object>> getTodayRevenueByServiceType() { return dashboardDAO.getTodayRevenueByServiceType(); }
    public List<Map<String, Object>> getTodayAppointmentStatusDistribution() { return dashboardDAO.getTodayAppointmentStatusDistribution(); }
    public List<Map<String, Object>> getDashboardRevenueSeries(String granularity) { return dashboardDAO.getDashboardRevenueSeries(granularity); }
    public List<Map<String, Object>> getDashboardVisitSeries(String granularity) { return dashboardDAO.getDashboardVisitSeries(granularity); }
    public List<Map<String, Object>> getStaffAccountsQuick(String status, int limit) { return dashboardDAO.getStaffAccountsQuick(status, limit); }
    public List<Map<String, Object>> getRecentPaidInvoicesToday(int limit) { return dashboardDAO.getRecentPaidInvoicesToday(limit); }
    public List<Map<String, Object>> getMedicalServices(String keyword, String status, String department) { return dashboardDAO.getMedicalServices(keyword, status, department); }
    public List<Map<String, Object>> getCompletedAppointmentsTodayQuick(int limit) { return dashboardDAO.getCompletedAppointmentsTodayQuick(limit); }
    public List<Map<String, Object>> getRevenueReport(String granularity, Integer year, Integer month, Integer day, LocalDate startDate, LocalDate endDate) { return reportDAO.getRevenueReport(granularity, year, month, day, startDate, endDate); }
    public List<Map<String, Object>> getVisitReport(String granularity, Integer year, Integer month, Integer day, LocalDate startDate, LocalDate endDate) { return reportDAO.getVisitReport(granularity, year, month, day, startDate, endDate); }
    public Map<String, Object> getReportDetailByPeriod(String period) { return reportDAO.getReportDetailByPeriod(period); }
    public List<Map<String, Object>> getInvoiceItemsByInvoiceId(String invoiceId) { return reportDAO.getInvoiceItemsByInvoiceId(invoiceId); }
    public void markLateWaitingAppointmentsAsNoShow() { reportDAO.markLateWaitingAppointmentsAsNoShow(); }
}

/**
 * Loads dashboard data from the shared Admin repository.
 */
class AdminDashboardDAO {
    private final AdminRepository repository = new AdminRepository();
    public void normalizeFutureCompletedAppointments() {
        repository.normalizeFutureCompletedAppointments();
    }
    public void autoAdvanceAppointmentWorkflowDemo() {
        repository.autoAdvanceAppointmentWorkflowDemo();
    }
    public int getCountTotalAccounts() {
        return repository.getCountTotalAccounts();
    }
    public int getCountActiveAccounts() {
        return repository.getCountActiveAccounts();
    }
    public int getCountLockedAccounts() {
        return repository.getCountLockedAccounts();
    }
    public int getCountTotalServices() {
        return repository.getCountTotalServices();
    }
    public BigDecimal getSumPaidRevenue() {
        return repository.getSumPaidRevenue();
    }
    public int getCountCompletedAppointments() {
        return repository.getCountCompletedAppointments();
    }
    public List<Map<String, Object>> getTodayClinicQueueStatus() {
        return repository.getTodayClinicQueueStatus();
    }
    public List<Map<String, Object>> getTodaySchedules() {
        return repository.getTodaySchedules();
    }
    public int getTodayTotalVisits() {
        return repository.getTodayTotalVisits();
    }
    public int getTodayWaitingPatients() {
        return repository.getTodayWaitingPatients();
    }
    public List<Map<String, Object>> getTodayPatientFlowByTimeSlot() {
        return repository.getTodayPatientFlowByTimeSlot();
    }
    public List<Map<String, Object>> getTodayRevenueByServiceType() {
        return repository.getTodayRevenueByServiceType();
    }
    public List<Map<String, Object>> getTodayAppointmentStatusDistribution() {
        return repository.getTodayAppointmentStatusDistribution();
    }
    public List<Map<String, Object>> getDashboardRevenueSeries(String granularity) {
        return repository.getDashboardRevenueSeries(granularity);
    }
    public List<Map<String, Object>> getDashboardVisitSeries(String granularity) {
        return repository.getDashboardVisitSeries(granularity);
    }
    public List<Map<String, Object>> getStaffAccountsQuick(String status, int limit) {
        return repository.getStaffAccountsQuick(status, limit);
    }
    public List<Map<String, Object>> getRecentPaidInvoicesToday(int limit) {
        return repository.getRecentPaidInvoicesToday(limit);
    }
    public List<Map<String, Object>> getMedicalServices(String keyword, String status, String department) {
        return repository.getMedicalServices(keyword, status, department);
    }
    public List<Map<String, Object>> getCompletedAppointmentsTodayQuick(int limit) {
        return repository.getCompletedAppointmentsTodayQuick(limit);
    }
}

/**
 * Loads report data from the shared Admin repository.
 */
class AdminReportDAO {
    private final AdminRepository repository = new AdminRepository();
    public List<Map<String, Object>> getRevenueReport(String granularity, Integer year, Integer month, Integer day, LocalDate startDate, LocalDate endDate) {
        return repository.getRevenueReport(granularity, year, month, day, startDate, endDate);
    }
    public List<Map<String, Object>> getVisitReport(String granularity, Integer year, Integer month, Integer day, LocalDate startDate, LocalDate endDate) {
        return repository.getVisitReport(granularity, year, month, day, startDate, endDate);
    }
    public Map<String, Object> getReportDetailByPeriod(String period) {
        return repository.getReportDetailByPeriod(period);
    }
    public List<Map<String, Object>> getInvoiceItemsByInvoiceId(String invoiceId) {
        return repository.getInvoiceItemsByInvoiceId(invoiceId);
    }
    public void markLateWaitingAppointmentsAsNoShow() {
        repository.markLateWaitingAppointmentsAsNoShow();
    }
}
