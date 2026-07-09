package com.diabetes.monitoring.admin.scheduling;

import com.diabetes.monitoring.admin.common.AdminRepository;

import java.sql.Date;
import java.util.List;
import java.util.Map;

/**
 * Facade over manual and AI scheduling persistence operations.
 */
public class AdminSchedulingDAO {
    private final AdminScheduleDAO scheduleDAO = new AdminScheduleDAO();
    private final AdminAiSchedulingDAO aiSchedulingDAO = new AdminAiSchedulingDAO();
    public List<Map<String, Object>> getDoctorsForSchedule() { return scheduleDAO.getDoctorsForSchedule(); }
    public List<String> getScheduleDepartments() { return scheduleDAO.getScheduleDepartments(); }
    public List<Map<String, Object>> getDoctorSchedules(String department, String doctorName, Date workDate) { return scheduleDAO.getDoctorSchedules(department, doctorName, workDate); }
    public Map<String, Object> getDoctorScheduleById(int scheduleId) { return scheduleDAO.getDoctorScheduleById(scheduleId); }
    public List<Map<String, Object>> getAppointmentsBySchedule(int scheduleId) { return scheduleDAO.getAppointmentsBySchedule(scheduleId); }
    public boolean createDoctorSchedule(int doctorId, Date workDate, String timeSlot, int maxPatients, Integer onlineQuota, String status) { return scheduleDAO.createDoctorSchedule(doctorId, workDate, timeSlot, maxPatients, onlineQuota, status); }
    public boolean updateDoctorSchedule(int scheduleId, int doctorId, String timeSlot, int maxPatients, Integer onlineQuota, String status) { return scheduleDAO.updateDoctorSchedule(scheduleId, doctorId, timeSlot, maxPatients, onlineQuota, status); }
    public boolean updateOnlineQuota(int scheduleId, int onlineQuota) { return scheduleDAO.updateOnlineQuota(scheduleId, onlineQuota); }
    public boolean deleteDoctorSchedule(int scheduleId) { return scheduleDAO.deleteDoctorSchedule(scheduleId); }
    public boolean cancelDoctorSchedule(int scheduleId) { return scheduleDAO.cancelDoctorSchedule(scheduleId); }
    public boolean transferDoctorSchedule(int scheduleId, int targetDoctorId) { return scheduleDAO.transferDoctorSchedule(scheduleId, targetDoctorId); }
    public int refreshDoctorScheduleStatusFromAppointments() { return scheduleDAO.refreshDoctorScheduleStatusFromAppointments(); }
    public void markLateWaitingAppointmentsAsNoShow() { scheduleDAO.markLateWaitingAppointmentsAsNoShow(); }
    public void normalizeFutureCompletedAppointments() { scheduleDAO.normalizeFutureCompletedAppointments(); }
    public void autoAdvanceAppointmentWorkflowDemo() { scheduleDAO.autoAdvanceAppointmentWorkflowDemo(); }
    public String consumeScheduleValidationMessage() { return scheduleDAO.consumeScheduleValidationMessage(); }
    public List<Map<String, Object>> getAvailableDoctorsForEmergency(String department, Integer excludeDoctorId) { return scheduleDAO.getAvailableDoctorsForEmergency(department, excludeDoctorId); }
    public List<Map<String, Object>> getAllActiveDoctorsForEmergency(Integer excludeDoctorId) { return scheduleDAO.getAllActiveDoctorsForEmergency(excludeDoctorId); }
    public List<Map<String, Object>> getDoctorsForAiScheduling(Date startDate, Date endDate) { return aiSchedulingDAO.getDoctorsForAiScheduling(startDate, endDate); }
    public List<Map<String, Object>> createGeminiSchedules(List<Map<String, Object>> assignments, int maxPatients, int maxSchedules) { return aiSchedulingDAO.createGeminiSchedules(assignments, maxPatients, maxSchedules); }
    public List<Map<String, Object>> createAiOptimizedSchedules(List<Date> targetDates, List<Map<String, String>> shiftsPerDay, String department, int maxPatients, int maxSchedules) { return aiSchedulingDAO.createAiOptimizedSchedules(targetDates, shiftsPerDay, department, maxPatients, maxSchedules); }
    public boolean createDoctorScheduleFromAi(int doctorId, Date workDate, String timeSlot, int maxPatients, Integer onlineQuota, String status) { return aiSchedulingDAO.createDoctorSchedule(doctorId, workDate, timeSlot, maxPatients, onlineQuota, status); }
}

/**
 * Loads and mutates doctor schedule data through the shared Admin repository.
 */
class AdminScheduleDAO {
    private final AdminRepository repository = new AdminRepository();
    public List<Map<String, Object>> getDoctorsForSchedule() {
        return repository.getDoctorsForSchedule();
    }
    public List<String> getScheduleDepartments() {
        return repository.getScheduleDepartments();
    }
    public List<Map<String, Object>> getDoctorSchedules(String department, String doctorName, Date workDate) {
        return repository.getDoctorSchedules(department, doctorName, workDate);
    }
    public Map<String, Object> getDoctorScheduleById(int scheduleId) {
        return repository.getDoctorScheduleById(scheduleId);
    }
    public List<Map<String, Object>> getAppointmentsBySchedule(int scheduleId) {
        return repository.getAppointmentsBySchedule(scheduleId);
    }
    public boolean createDoctorSchedule(int doctorId, Date workDate, String timeSlot, int maxPatients, Integer onlineQuota, String status) {
        return repository.createDoctorSchedule(doctorId, workDate, timeSlot, maxPatients, onlineQuota, status);
    }
    public boolean updateDoctorSchedule(int scheduleId, int doctorId, String timeSlot, int maxPatients, Integer onlineQuota, String status) {
        return repository.updateDoctorSchedule(scheduleId, doctorId, timeSlot, maxPatients, onlineQuota, status);
    }
    public boolean updateOnlineQuota(int scheduleId, int onlineQuota) {
        return repository.updateOnlineQuota(scheduleId, onlineQuota);
    }
    public boolean deleteDoctorSchedule(int scheduleId) {
        return repository.deleteDoctorSchedule(scheduleId);
    }
    public boolean cancelDoctorSchedule(int scheduleId) {
        return repository.cancelDoctorSchedule(scheduleId);
    }
    public boolean transferDoctorSchedule(int scheduleId, int targetDoctorId) {
        return repository.transferDoctorSchedule(scheduleId, targetDoctorId);
    }
    public int refreshDoctorScheduleStatusFromAppointments() {
        return repository.refreshDoctorScheduleStatusFromAppointments();
    }
    public void markLateWaitingAppointmentsAsNoShow() {
        repository.markLateWaitingAppointmentsAsNoShow();
    }
    public void normalizeFutureCompletedAppointments() {
        repository.normalizeFutureCompletedAppointments();
    }
    public void autoAdvanceAppointmentWorkflowDemo() {
        repository.autoAdvanceAppointmentWorkflowDemo();
    }
    public String consumeScheduleValidationMessage() {
        return repository.consumeScheduleValidationMessage();
    }
    public List<Map<String, Object>> getAvailableDoctorsForEmergency(String department, Integer excludeDoctorId) {
        return repository.getAvailableDoctorsForEmergency(department, excludeDoctorId);
    }
    public List<Map<String, Object>> getAllActiveDoctorsForEmergency(Integer excludeDoctorId) {
        return repository.getAllActiveDoctorsForEmergency(excludeDoctorId);
    }
}

/**
 * Persists AI-generated schedule assignments.
 */
class AdminAiSchedulingDAO {
    private final AdminRepository repository = new AdminRepository();
    public List<Map<String, Object>> getDoctorsForAiScheduling(java.sql.Date startDate, java.sql.Date endDate) {
        return repository.getDoctorsForAiScheduling(startDate, endDate);
    }
    public List<Map<String, Object>> createGeminiSchedules(List<Map<String, Object>> assignments, int maxPatients, int maxSchedules) {
        return repository.createGeminiSchedules(assignments, maxPatients, maxSchedules);
    }
    public List<Map<String, Object>> createAiOptimizedSchedules(List<java.sql.Date> targetDates,
            List<Map<String, String>> shiftsPerDay,
            String department,
            int maxPatients,
            int maxSchedules) {
        return repository.createAiOptimizedSchedules(targetDates, shiftsPerDay, department, maxPatients, maxSchedules);
    }
    public boolean createDoctorSchedule(int doctorId, java.sql.Date workDate, String timeSlot, int maxPatients, Integer onlineQuota, String status) {
        return repository.createDoctorSchedule(doctorId, workDate, timeSlot, maxPatients, onlineQuota, status);
    }
    public String consumeScheduleValidationMessage() {
        return repository.consumeScheduleValidationMessage();
    }
}

