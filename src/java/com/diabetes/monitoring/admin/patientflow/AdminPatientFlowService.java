package com.diabetes.monitoring.admin.patientflow;

import java.util.List;
import java.util.Map;

/**
 * Provides appointment workflow and emergency routing use cases.
 */
public class AdminPatientFlowService {
    private final AdminAppointmentWorkflowService appointmentService = new AdminAppointmentWorkflowService();
    private final AdminEmergencyRoutingService emergencyService = new AdminEmergencyRoutingService();
    public boolean checkInAppointment(int appointmentId) { return appointmentService.checkIn(appointmentId); }
    public boolean startAppointment(int appointmentId) { return appointmentService.start(appointmentId); }
    public boolean completeAppointment(int appointmentId) { return appointmentService.complete(appointmentId); }
    public int markLateWaitingAppointmentsAsNoShow() { return appointmentService.refreshWaitingStates(); }
    public List<Map<String, Object>> getDoctorQueueDetailToday(int doctorId) { return appointmentService.getDoctorQueueDetailToday(doctorId); }
    public List<Map<String, Object>> getTodayAppointments() { return appointmentService.getTodayAppointments(); }
    public List<Map<String, Object>> getTodayWaitingDetails() { return appointmentService.getTodayWaitingDetails(); }
    public List<Map<String, Object>> getAppointmentsBySchedule(int scheduleId) { return appointmentService.getAppointmentsBySchedule(scheduleId); }
    public List<Map<String, Object>> getTodayClinicQueueStatus() { return appointmentService.getTodayClinicQueueStatus(); }
    public void prepareExceptionRouting() { emergencyService.loadExceptionQueue(null); }
    public List<Map<String, Object>> getExceptionQueue(Integer doctorId) { return emergencyService.loadExceptionQueue(doctorId); }
    public List<Map<String, Object>> getEmergencyCandidateDoctorsForAppointment(int appointmentId, Integer excludeDoctorId) { return emergencyService.getEmergencyCandidateDoctorsForAppointment(appointmentId, excludeDoctorId); }
    public boolean reassignAppointmentToDoctor(int appointmentId, int targetDoctorId) { return emergencyService.reassignAppointmentToDoctor(appointmentId, targetDoctorId); }
}

/**
 * Applies business rules for appointment state transitions.
 */
class AdminAppointmentWorkflowService {
    private final AdminAppointmentDAO appointmentDAO = new AdminAppointmentDAO();
    public int refreshWaitingStates() {
        return appointmentDAO.markLateWaitingAppointmentsAsNoShow();
    }
    public boolean checkIn(int appointmentId) {
        return appointmentDAO.checkInAppointment(appointmentId);
    }
    public boolean start(int appointmentId) {
        return appointmentDAO.startAppointment(appointmentId);
    }
    public boolean complete(int appointmentId) {
        return appointmentDAO.completeAppointment(appointmentId);
    }
    public List<Map<String, Object>> getDoctorQueueDetailToday(int doctorId) {
        return appointmentDAO.getDoctorQueueDetailToday(doctorId);
    }
    public List<Map<String, Object>> getTodayAppointments() {
        return appointmentDAO.getTodayAppointments();
    }
    public List<Map<String, Object>> getTodayWaitingDetails() {
        return appointmentDAO.getTodayWaitingDetails();
    }
    public List<Map<String, Object>> getAppointmentsBySchedule(int scheduleId) {
        return appointmentDAO.getAppointmentsBySchedule(scheduleId);
    }
    public List<Map<String, Object>> getTodayClinicQueueStatus() {
        return appointmentDAO.getTodayClinicQueueStatus();
    }
}

/**
 * Applies business rules for emergency doctor reassignment.
 */
class AdminEmergencyRoutingService {
    private final AdminEmergencyRoutingDAO emergencyRoutingDAO = new AdminEmergencyRoutingDAO();
    public List<Map<String, Object>> loadExceptionQueue(Integer doctorId) {
        emergencyRoutingDAO.markLateWaitingAppointmentsAsNoShow();
        return emergencyRoutingDAO.getExceptionQueue(doctorId);
    }
    public List<Map<String, Object>> getEmergencyCandidateDoctorsForAppointment(int appointmentId, Integer excludeDoctorId) {
        return emergencyRoutingDAO.getEmergencyCandidateDoctorsForAppointment(appointmentId, excludeDoctorId);
    }
    public boolean reassignAppointmentToDoctor(int appointmentId, int targetDoctorId) {
        return emergencyRoutingDAO.reassignAppointmentToDoctor(appointmentId, targetDoctorId);
    }
}
