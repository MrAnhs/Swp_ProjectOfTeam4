package com.diabetes.monitoring.admin.patientflow;

import com.diabetes.monitoring.admin.common.AdminRepository;

import java.util.List;
import java.util.Map;

/**
 * Facade over appointment workflow and emergency routing persistence operations.
 */
public class AdminPatientFlowDAO {
    private final AdminAppointmentDAO appointmentDAO = new AdminAppointmentDAO();
    private final AdminEmergencyRoutingDAO emergencyDAO = new AdminEmergencyRoutingDAO();
    public int markLateWaitingAppointmentsAsNoShow() { return appointmentDAO.markLateWaitingAppointmentsAsNoShow(); }
    public boolean checkInAppointment(int appointmentId) { return appointmentDAO.checkInAppointment(appointmentId); }
    public boolean startAppointment(int appointmentId) { return appointmentDAO.startAppointment(appointmentId); }
    public boolean completeAppointment(int appointmentId) { return appointmentDAO.completeAppointment(appointmentId); }
    public List<Map<String, Object>> getDoctorQueueDetailToday(int doctorId) { return appointmentDAO.getDoctorQueueDetailToday(doctorId); }
    public List<Map<String, Object>> getTodayAppointments() { return appointmentDAO.getTodayAppointments(); }
    public List<Map<String, Object>> getTodayWaitingDetails() { return appointmentDAO.getTodayWaitingDetails(); }
    public List<Map<String, Object>> getAppointmentsBySchedule(int scheduleId) { return appointmentDAO.getAppointmentsBySchedule(scheduleId); }
    public List<Map<String, Object>> getTodayClinicQueueStatus() { return appointmentDAO.getTodayClinicQueueStatus(); }
    public List<Map<String, Object>> getExceptionQueue(Integer doctorId) { return emergencyDAO.getExceptionQueue(doctorId); }
    public List<Map<String, Object>> getEmergencyCandidateDoctorsForAppointment(int appointmentId, Integer excludeDoctorId) { return emergencyDAO.getEmergencyCandidateDoctorsForAppointment(appointmentId, excludeDoctorId); }
    public boolean reassignAppointmentToDoctor(int appointmentId, int targetDoctorId) { return emergencyDAO.reassignAppointmentToDoctor(appointmentId, targetDoctorId); }
    public void markLateWaitingAppointmentsAsNoShowForEmergency() { emergencyDAO.markLateWaitingAppointmentsAsNoShow(); }
}

/**
 * Loads and mutates appointment workflow data through the shared Admin repository.
 */
class AdminAppointmentDAO {
    private final AdminRepository repository = new AdminRepository();
    public int markLateWaitingAppointmentsAsNoShow() {
        return repository.markLateWaitingAppointmentsAsNoShow();
    }
    public boolean checkInAppointment(int appointmentId) {
        return repository.checkInAppointment(appointmentId);
    }
    public boolean startAppointment(int appointmentId) {
        return repository.startAppointment(appointmentId);
    }
    public boolean completeAppointment(int appointmentId) {
        return repository.completeAppointment(appointmentId);
    }
    public List<Map<String, Object>> getDoctorQueueDetailToday(int doctorId) {
        return repository.getDoctorQueueDetailToday(doctorId);
    }
    public List<Map<String, Object>> getTodayAppointments() {
        return repository.getTodayAppointments();
    }
    public List<Map<String, Object>> getTodayWaitingDetails() {
        return repository.getTodayWaitingDetails();
    }
    public List<Map<String, Object>> getAppointmentsBySchedule(int scheduleId) {
        return repository.getAppointmentsBySchedule(scheduleId);
    }
    public List<Map<String, Object>> getTodayClinicQueueStatus() {
        return repository.getTodayClinicQueueStatus();
    }
}

/**
 * Loads and mutates emergency routing data through the shared Admin repository.
 */
class AdminEmergencyRoutingDAO {
    private final AdminRepository repository = new AdminRepository();
    public List<Map<String, Object>> getExceptionQueue(Integer doctorId) {
        return repository.getExceptionQueue(doctorId);
    }
    public List<Map<String, Object>> getEmergencyCandidateDoctorsForAppointment(int appointmentId, Integer excludeDoctorId) {
        return repository.getEmergencyCandidateDoctorsForAppointment(appointmentId, excludeDoctorId);
    }
    public boolean reassignAppointmentToDoctor(int appointmentId, int targetDoctorId) {
        return repository.reassignAppointmentToDoctor(appointmentId, targetDoctorId);
    }
    public void markLateWaitingAppointmentsAsNoShow() {
        repository.markLateWaitingAppointmentsAsNoShow();
    }
}
