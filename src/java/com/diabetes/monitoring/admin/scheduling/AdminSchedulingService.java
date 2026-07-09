package com.diabetes.monitoring.admin.scheduling;

import com.diabetes.monitoring.util.GeminiSchedulingService;
import com.diabetes.monitoring.util.GeminiSchedulingService.SchedulingResult;

import java.sql.Date;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Provides manual and AI scheduling use cases.
 */
public class AdminSchedulingService {
    private final AdminScheduleService scheduleService = new AdminScheduleService();
    private final AdminAiSchedulingService aiSchedulingService = new AdminAiSchedulingService();
    public void prepareScheduleViews() { scheduleService.prepareScheduleViews(); }
    public List<Map<String, Object>> getDoctorsForSchedule() { return scheduleService.getDoctorsForSchedule(); }
    public List<String> getScheduleDepartments() { return scheduleService.getScheduleDepartments(); }
    public List<Map<String, Object>> getDoctorSchedules(String department, String doctorName, Date workDate) { return scheduleService.getDoctorSchedules(department, doctorName, workDate); }
    public Map<String, Object> getDoctorScheduleById(int scheduleId) { return scheduleService.getDoctorScheduleById(scheduleId); }
    public List<Map<String, Object>> getAppointmentsBySchedule(int scheduleId) { return scheduleService.getAppointmentsBySchedule(scheduleId); }
    public boolean createSchedule(int doctorId, Date workDate, String timeSlot, int maxPatients, Integer onlineQuota) { return scheduleService.createSchedule(doctorId, workDate, timeSlot, maxPatients, onlineQuota); }
    public boolean updateSchedule(int scheduleId, int doctorId, String timeSlot, int maxPatients, Integer onlineQuota, String status) { return scheduleService.updateSchedule(scheduleId, doctorId, timeSlot, maxPatients, onlineQuota, status); }
    public boolean deleteSchedule(int scheduleId) { return scheduleService.deleteSchedule(scheduleId); }
    public boolean cancelSchedule(int scheduleId) { return scheduleService.cancelSchedule(scheduleId); }
    public boolean transferSchedule(int scheduleId, int targetDoctorId) { return scheduleService.transferSchedule(scheduleId, targetDoctorId); }
    public void autoAdvanceAppointmentWorkflowDemo() { scheduleService.autoAdvanceAppointmentWorkflowDemo(); }
    public String consumeValidationMessage() { return scheduleService.consumeValidationMessage(); }
    public List<Map<String, Object>> getAvailableDoctorsForEmergency(String department, Integer excludeDoctorId) { return scheduleService.getAvailableDoctorsForEmergency(department, excludeDoctorId); }
    public List<Map<String, Object>> getAllActiveDoctorsForEmergency(Integer excludeDoctorId) { return scheduleService.getAllActiveDoctorsForEmergency(excludeDoctorId); }
    public AdminAiSchedulingService.AiSchedulingResult createSchedules(AdminAiSchedulingService.AiSchedulingRequest request) { return aiSchedulingService.createSchedules(request); }
}

/**
 * Applies business rules for doctor schedule management.
 */
class AdminScheduleService {
    private final AdminScheduleDAO scheduleDAO = new AdminScheduleDAO();
    public void prepareScheduleViews() {
        scheduleDAO.markLateWaitingAppointmentsAsNoShow();
        scheduleDAO.refreshDoctorScheduleStatusFromAppointments();
    }
    public List<Map<String, Object>> getDoctorsForSchedule() {
        return scheduleDAO.getDoctorsForSchedule();
    }
    public List<String> getScheduleDepartments() {
        return scheduleDAO.getScheduleDepartments();
    }
    public List<Map<String, Object>> getDoctorSchedules(String department, String doctorName, Date workDate) {
        return scheduleDAO.getDoctorSchedules(department, doctorName, workDate);
    }
    public Map<String, Object> getDoctorScheduleById(int scheduleId) {
        return scheduleDAO.getDoctorScheduleById(scheduleId);
    }
    public List<Map<String, Object>> getAppointmentsBySchedule(int scheduleId) {
        return scheduleDAO.getAppointmentsBySchedule(scheduleId);
    }
    public boolean createSchedule(int doctorId, Date workDate, String timeSlot, int maxPatients, Integer onlineQuota) {
        return scheduleDAO.createDoctorSchedule(doctorId, workDate, timeSlot, maxPatients, onlineQuota, "Available");
    }
    public boolean updateSchedule(int scheduleId, int doctorId, String timeSlot, int maxPatients, Integer onlineQuota, String status) {
        return scheduleDAO.updateDoctorSchedule(scheduleId, doctorId, timeSlot, maxPatients, onlineQuota, status);
    }
    public boolean deleteSchedule(int scheduleId) {
        return scheduleDAO.deleteDoctorSchedule(scheduleId);
    }
    public boolean cancelSchedule(int scheduleId) {
        return scheduleDAO.cancelDoctorSchedule(scheduleId);
    }
    public boolean transferSchedule(int scheduleId, int targetDoctorId) {
        return scheduleDAO.transferDoctorSchedule(scheduleId, targetDoctorId);
    }
    public String consumeValidationMessage() {
        return scheduleDAO.consumeScheduleValidationMessage();
    }
    public List<Map<String, Object>> getAvailableDoctorsForEmergency(String department, Integer excludeDoctorId) {
        return scheduleDAO.getAvailableDoctorsForEmergency(department, excludeDoctorId);
    }
    public List<Map<String, Object>> getAllActiveDoctorsForEmergency(Integer excludeDoctorId) {
        return scheduleDAO.getAllActiveDoctorsForEmergency(excludeDoctorId);
    }
    public void normalizeFutureCompletedAppointments() {
        scheduleDAO.normalizeFutureCompletedAppointments();
    }
    public void autoAdvanceAppointmentWorkflowDemo() {
        scheduleDAO.autoAdvanceAppointmentWorkflowDemo();
    }
}

/**
 * Builds AI scheduling requests and persists generated schedules.
 */
class AdminAiSchedulingService {
    private final AdminAiSchedulingDAO aiSchedulingDAO = new AdminAiSchedulingDAO();
    private final GeminiSchedulingService geminiSchedulingService = new GeminiSchedulingService();
    public AiSchedulingResult createSchedules(AiSchedulingRequest request) {
        AiSchedulingResult result = new AiSchedulingResult();
        Date startDate = request.startDate;
        Date endDate = request.endDate;
        String startTime = request.startTime;
        String endTime = request.endTime;
        int slotMinutes = request.slotMinutes;
        int maxPatients = request.maxPatients;
        int maxSchedules = request.maxSchedules;
        int doctorsPerShift = request.doctorsPerShift;
        String department = request.department;
        List<Map<String, String>> shiftsPerDay = new ArrayList<>(request.shiftsPerDay);
        List<Integer> selectedWeekdays = new ArrayList<>(request.selectedWeekdays);
        List<Date> targetDates = buildSelectedTargetDates(startDate, endDate, selectedWeekdays);

        if (shiftsPerDay.isEmpty()) {
            shiftsPerDay = buildDefaultShiftTemplates(startTime, endTime, slotMinutes, department);
        }
        doctorsPerShift = Math.min(4, Math.max(1, doctorsPerShift));
        int expectedScheduleCount = targetDates.size() * shiftsPerDay.size() * doctorsPerShift;
        shiftsPerDay = expandShiftsForDoctorsPerSlot(shiftsPerDay, doctorsPerShift);

        if (startDate == null || endDate == null || startDate.after(endDate)) {
            result.message = "Khoảng ngày lập lịch không hợp lệ.";
            return result;
        }
        if (selectedWeekdays.isEmpty()) {
            result.message = "Vui lòng chọn ít nhất một ngày áp dụng trong tuần.";
            return result;
        }
        if (targetDates.isEmpty()) {
            result.message = "Khoảng thời gian không chứa ngày nào khớp với các thứ đã chọn.";
            return result;
        }
        if (shiftsPerDay.isEmpty()) {
            result.message = "Khung mẫu ca trực không hợp lệ. Mỗi dòng phải có dạng HH:mm-HH:mm|Chuyên khoa.";
            return result;
        }
        if (maxPatients <= 0 || maxSchedules <= 0) {
            result.message = "Số bệnh nhân tối đa hoặc số slot bác sĩ cần tạo không hợp lệ.";
            return result;
        }
        if (maxPatients > 50) {
            result.message = "Số bệnh nhân tối đa không được vượt quá 50 để đảm bảo chất lượng khám.";
            return result;
        }

        maxSchedules = expectedScheduleCount;
        List<Map<String, Object>> doctors = aiSchedulingDAO.getDoctorsForAiScheduling(startDate, endDate);
        GeminiSchedulingService.SchedulingResult geminiResult =
                geminiSchedulingService.generate(targetDates, shiftsPerDay, doctors);

        List<Map<String, Object>> created = new ArrayList<>();
        if (geminiResult.success) {
            created = aiSchedulingDAO.createGeminiSchedules(geminiResult.assignments, maxPatients, maxSchedules);
        }
        if (created.size() != maxSchedules) {
            created = aiSchedulingDAO.createAiOptimizedSchedules(targetDates, shiftsPerDay, department, maxPatients, maxSchedules);
        }

        result.success = created.size() == maxSchedules;
        result.items = created;
        if (result.success) {
            boolean usedGemini = created.stream().anyMatch(row -> "Gemini AI".equals(String.valueOf(row.get("source"))));
            result.message = usedGemini
                    ? "Gemini AI đã tạo đúng " + created.size() + " slot lịch trực theo target_dates x shifts_per_day x bác sĩ/ca."
                    : "Đã tạo đúng " + created.size() + " slot bằng bộ cân bằng tải dự phòng vì Gemini chưa trả lịch hợp lệ.";
        } else {
            String daoMessage = aiSchedulingDAO.consumeScheduleValidationMessage();
            result.message = (daoMessage != null && !daoMessage.isBlank())
                    ? daoMessage
                    : "Không thể tạo đủ " + maxSchedules + " slot. Hệ thống đã hủy toàn bộ batch để tránh lịch thiếu hoặc sai chuyên khoa.";
        }
        return result;
    }
    private List<Map<String, String>> buildDefaultShiftTemplates(String rawStartTime, String rawEndTime, int slotMinutes, String department) {
        List<Map<String, String>> shifts = new ArrayList<>();
        String resolvedDepartment = (department == null || department.isBlank()) ? "Endocrinology" : department;
        for (String timeSlot : buildScheduleTimeSlots(rawStartTime, rawEndTime, slotMinutes)) {
            Map<String, String> shift = new java.util.HashMap<>();
            shift.put("timeSlot", timeSlot);
            shift.put("department", resolvedDepartment);
            shifts.add(shift);
        }
        return shifts;
    }
    private List<Map<String, String>> expandShiftsForDoctorsPerSlot(List<Map<String, String>> baseShifts, int doctorsPerShift) {
        List<Map<String, String>> expanded = new ArrayList<>();
        int multiplier = Math.min(4, Math.max(1, doctorsPerShift));
        for (Map<String, String> shift : baseShifts) {
            for (int i = 0; i < multiplier; i++) {
                Map<String, String> copy = new java.util.HashMap<>();
                copy.put("timeSlot", shift.get("timeSlot"));
                copy.put("department", shift.get("department"));
                expanded.add(copy);
            }
        }
        return expanded;
    }
    private List<String> buildScheduleTimeSlots(String rawStartTime, String rawEndTime, int slotMinutes) {
        List<String> slots = new ArrayList<>();
        if (slotMinutes < 30 || slotMinutes > 480) {
            return slots;
        }
        try {
            java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("HH:mm");
            java.time.LocalTime start = java.time.LocalTime.parse(rawStartTime, formatter);
            java.time.LocalTime end = java.time.LocalTime.parse(rawEndTime, formatter);
            if (!start.isBefore(end)) {
                return slots;
            }
            java.time.LocalTime cursor = start;
            while (cursor.plusMinutes(slotMinutes).compareTo(end) <= 0) {
                java.time.LocalTime slotEnd = cursor.plusMinutes(slotMinutes);
                slots.add(cursor.format(formatter) + "-" + slotEnd.format(formatter));
                cursor = slotEnd;
            }
        } catch (Exception ex) {
            return new ArrayList<>();
        }
        return slots;
    }
    private List<Date> buildSelectedTargetDates(Date startDate, Date endDate, List<Integer> selectedWeekdays) {
        List<Date> dates = new ArrayList<>();
        if (startDate == null || endDate == null || startDate.after(endDate) || selectedWeekdays == null || selectedWeekdays.isEmpty()) {
            return dates;
        }
        LocalDate cursor = startDate.toLocalDate();
        while (!cursor.isAfter(endDate.toLocalDate())) {
            if (selectedWeekdays.contains(cursor.getDayOfWeek().getValue())) {
                dates.add(Date.valueOf(cursor));
            }
            cursor = cursor.plusDays(1);
        }
        return dates;
    }

    public static class AiSchedulingRequest {
        public Date startDate;
        public Date endDate;
        public String startTime;
        public String endTime;
        public int slotMinutes;
        public int maxPatients;
        public int maxSchedules;
        public int doctorsPerShift;
        public String department;
        public List<Map<String, String>> shiftsPerDay;
        public List<Integer> selectedWeekdays;
    }

    public static class AiSchedulingResult {
        public boolean success;
        public String message = "";
        public List<Map<String, Object>> items = new ArrayList<>();
    }
}

