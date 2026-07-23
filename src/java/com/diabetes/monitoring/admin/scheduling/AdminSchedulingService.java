package com.diabetes.monitoring.admin.scheduling;

import com.diabetes.monitoring.appointment.AppointmentRepository;
import com.diabetes.monitoring.receptionist.EmergencyRoutingRepository;
import com.diabetes.monitoring.util.GeminiSchedulingService;

import java.sql.Date;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Provides manual and AI scheduling use cases.
 */
public class AdminSchedulingService {
    private final AdminScheduleService scheduleService = new AdminScheduleService();
    private final AdminAiSchedulingService aiSchedulingService = new AdminAiSchedulingService();
    private final AdminStaffScheduleService staffScheduleService = new AdminStaffScheduleService();

    public void prepareScheduleViews() {
        scheduleService.prepareScheduleViews();
        staffScheduleService.refreshStaffScheduleStatus();
    }

    public List<Map<String, Object>> getDoctorsForSchedule() {
        return scheduleService.getDoctorsForSchedule();
    }

    public List<String> getScheduleDepartments() {
        return scheduleService.getScheduleDepartments();
    }

    public List<Map<String, Object>> getRoomsForSchedule() {
        return scheduleService.getRoomsForSchedule();
    }

    public List<Map<String, Object>> getLabRoomsForSchedule() {
        return scheduleService.getLabRoomsForSchedule();
    }

    public List<Map<String, Object>> getDoctorSchedules(String department,
            String doctorName,
            Date workDate) {

        return scheduleService.getDoctorSchedules(department, doctorName,
                workDate);
    }

    public AdminSchedulePage getDoctorSchedulesPage(String department,
            String doctorName,
            Date workDate,
            String status,
            String viewMode,
            String sortBy,
            String sortDir,
            int page,
            int pageSize) {

        return scheduleService.getDoctorSchedulesPage(department, doctorName,
                workDate, status, viewMode, sortBy, sortDir, page, pageSize);
    }

    public Map<String, Object> getDoctorScheduleById(int scheduleId) {
        return scheduleService.getDoctorScheduleById(scheduleId);
    }

    public List<Map<String, Object>> getAppointmentsBySchedule(int scheduleId) {
        return scheduleService.getAppointmentsBySchedule(scheduleId);
    }

    public boolean createSchedule(int doctorId,
            Date workDate,
            String timeSlot,
            int maxPatients,
            Integer onlineQuota,
            String roomId) {

        return scheduleService.createSchedule(doctorId, workDate, timeSlot,
                maxPatients, onlineQuota, roomId);
    }

    public boolean updateSchedule(int scheduleId,
            int doctorId,
            String timeSlot,
            int maxPatients,
            Integer onlineQuota,
            String status,
            String roomId) {

        return scheduleService.updateSchedule(scheduleId, doctorId, timeSlot,
                maxPatients, onlineQuota, status, roomId);
    }

    public boolean deleteSchedule(int scheduleId) {
        return scheduleService.deleteSchedule(scheduleId);
    }

    public boolean approveSchedule(int scheduleId) {
        return scheduleService.approveSchedule(scheduleId);
    }

    public boolean cancelSchedule(int scheduleId) {
        return scheduleService.cancelSchedule(scheduleId);
    }

    public boolean transferSchedule(int scheduleId, int targetDoctorId) {
        return scheduleService.transferSchedule(scheduleId, targetDoctorId);
    }

    public String consumeValidationMessage() {
        return scheduleService.consumeValidationMessage();
    }

    public List<Map<String, Object>> getAvailableDoctorsForEmergency(
            String department,
            Integer excludeDoctorId) {

        return scheduleService.getAvailableDoctorsForEmergency(department,
                excludeDoctorId);
    }

    public List<Map<String, Object>> getAllActiveDoctorsForEmergency(
            Integer excludeDoctorId) {

        return scheduleService.getAllActiveDoctorsForEmergency(excludeDoctorId);
    }

    public AdminAiSchedulingService.AiSchedulingResult createSchedules(
            AdminAiSchedulingService.AiSchedulingRequest request) {

        return aiSchedulingService.createSchedules(request);
    }

    public List<Map<String, Object>> getStaffForSchedule(String staffType) {
        return staffScheduleService.getStaffForSchedule(staffType);
    }

    public List<Map<String, Object>> getStaffSchedules(String staffType,
            String staffName,
            String department,
            Date workDate) {

        return staffScheduleService.getStaffSchedules(staffType, staffName,
                department, workDate);
    }

    public AdminSchedulePage getStaffSchedulesPage(String staffType,
            String staffName,
            String department,
            Date workDate,
            String status,
            String viewMode,
            String sortBy,
            String sortDir,
            int page,
            int pageSize) {

        return staffScheduleService.getStaffSchedulesPage(staffType, staffName,
                department, workDate, status, viewMode, sortBy, sortDir, page, pageSize);
    }

    public Map<String, Object> getStaffScheduleById(int staffScheduleId) {
        return staffScheduleService.getStaffScheduleById(staffScheduleId);
    }

    public boolean createStaffSchedule(int accountId,
            String staffType,
            Date workDate,
            String timeSlot,
            String department,
            String workArea,
            Integer maxWorkload,
            String roomId) {

        return staffScheduleService.createStaffSchedule(accountId, staffType,
                workDate, timeSlot, department, workArea, maxWorkload, roomId);
    }

    public boolean updateStaffSchedule(int staffScheduleId,
            int accountId,
            String staffType,
            Date workDate,
            String timeSlot,
            String department,
            String workArea,
            Integer maxWorkload,
            String status,
            String roomId) {

        return staffScheduleService.updateStaffSchedule(staffScheduleId,
                accountId, staffType, workDate, timeSlot, department,
                workArea, maxWorkload, status, roomId);
    }

    public boolean cancelStaffSchedule(int staffScheduleId) {
        return staffScheduleService.cancelStaffSchedule(staffScheduleId);
    }

    public boolean deleteStaffSchedule(int staffScheduleId) {
        return staffScheduleService.deleteStaffSchedule(staffScheduleId);
    }

    public String consumeStaffValidationMessage() {
        return staffScheduleService.consumeValidationMessage();
    }

    public AdminStaffScheduleService.AiStaffSchedulingResult createStaffSchedules(
            AdminStaffScheduleService.AiStaffSchedulingRequest request) {

        return staffScheduleService.createStaffSchedules(request);
    }
}

/**
 * Applies business rules for doctor schedule management.
 */
class AdminScheduleService {
    private final AdminScheduleRepository scheduleRepository = new AdminScheduleRepository();
    private final AppointmentRepository appointmentRepository = new AppointmentRepository();
    private final EmergencyRoutingRepository emergencyRepository = new EmergencyRoutingRepository();
    private final AdminRoomRepository roomRepository = new AdminRoomRepository();

    public void prepareScheduleViews() {
        scheduleRepository.refreshDoctorScheduleStatusFromAppointments();
    }

    public List<Map<String, Object>> getDoctorsForSchedule() {
        return scheduleRepository.getDoctorsForSchedule();
    }

    public List<String> getScheduleDepartments() {
        return scheduleRepository.getScheduleDepartments();
    }

    public List<Map<String, Object>> getRoomsForSchedule() {
        return roomRepository.getActiveDoctorRooms();
    }

    public List<Map<String, Object>> getLabRoomsForSchedule() {
        return roomRepository.getActiveLabRooms();
    }

    public List<Map<String, Object>> getDoctorSchedules(String department,
            String doctorName,
            Date workDate) {

        return scheduleRepository.getDoctorSchedules(department, doctorName,
                workDate);
    }

    public AdminSchedulePage getDoctorSchedulesPage(String department,
            String doctorName,
            Date workDate,
            String status,
            String viewMode,
            String sortBy,
            String sortDir,
            int page,
            int pageSize) {

        return scheduleRepository.getDoctorSchedulesPage(department, doctorName,
                workDate, status, viewMode, sortBy, sortDir, page, pageSize);
    }

    public Map<String, Object> getDoctorScheduleById(int scheduleId) {
        return scheduleRepository.getDoctorScheduleById(scheduleId);
    }

    public List<Map<String, Object>> getAppointmentsBySchedule(int scheduleId) {
        return appointmentRepository.getAppointmentsBySchedule(scheduleId);
    }

    public boolean createSchedule(int doctorId,
            Date workDate,
            String timeSlot,
            int maxPatients,
            Integer onlineQuota,
            String roomId) {

        return scheduleRepository.createDoctorSchedule(doctorId, workDate,
                timeSlot, maxPatients, onlineQuota, "Available", roomId);
    }

    public boolean createSchedule(int doctorId,
            Date workDate,
            String timeSlot,
            int maxPatients,
            Integer onlineQuota) {
        return createSchedule(doctorId, workDate, timeSlot, maxPatients, onlineQuota, null);
    }

    public boolean updateSchedule(int scheduleId,
            int doctorId,
            String timeSlot,
            int maxPatients,
            Integer onlineQuota,
            String status,
            String roomId) {

        return scheduleRepository.updateDoctorSchedule(scheduleId, doctorId,
                timeSlot, maxPatients, onlineQuota, status, roomId);
    }

    public boolean updateSchedule(int scheduleId,
            int doctorId,
            String timeSlot,
            int maxPatients,
            Integer onlineQuota,
            String status) {
        return updateSchedule(scheduleId, doctorId, timeSlot, maxPatients, onlineQuota, status, null);
    }

    public boolean deleteSchedule(int scheduleId) {
        return scheduleRepository.deleteDoctorSchedule(scheduleId);
    }

    public boolean approveSchedule(int scheduleId) {
        return scheduleRepository.approveDoctorSchedule(scheduleId);
    }

    public boolean cancelSchedule(int scheduleId) {
        return scheduleRepository.cancelDoctorSchedule(scheduleId);
    }

    public boolean transferSchedule(int scheduleId, int targetDoctorId) {
        return scheduleRepository.transferDoctorSchedule(scheduleId,
                targetDoctorId);
    }

    public String consumeValidationMessage() {
        return scheduleRepository.consumeScheduleValidationMessage();
    }

    public List<Map<String, Object>> getAvailableDoctorsForEmergency(
            String department,
            Integer excludeDoctorId) {

        return emergencyRepository.getAvailableDoctorsForEmergency(department,
                excludeDoctorId);
    }

    public List<Map<String, Object>> getAllActiveDoctorsForEmergency(
            Integer excludeDoctorId) {

        return emergencyRepository.getAllActiveDoctorsForEmergency(
                excludeDoctorId);
    }
}

/**
 * Applies business rules for receptionist and lab-doctor schedule management.
 */
class AdminStaffScheduleService {
    private final AdminStaffScheduleRepository staffRepository = new AdminStaffScheduleRepository();
    private final AdminAiSchedulingRepository aiSchedulingRepository = new AdminAiSchedulingRepository();
    private final AdminScheduleValidator validator = new AdminScheduleValidator();

    private final ThreadLocal<String> validationMessage = ThreadLocal.withInitial(() -> "");

    private void setValidationMessage(String msg) {
        validationMessage.set(msg != null ? msg : "");
    }

    public String consumeValidationMessage() {
        String msg = validationMessage.get();
        validationMessage.remove();
        return msg == null ? "" : msg;
    }

    public List<Map<String, Object>> getStaffForSchedule(String staffType) {
        String normalizedStaffType = validator.normalizeStaffType(staffType);
        String role = validator.roleForStaffType(normalizedStaffType);
        return staffRepository.findStaff(role);
    }

    public List<Map<String, Object>> getStaffSchedules(String staffType,
            String staffName,
            String department,
            Date workDate) {

        staffRepository.refreshStaffScheduleStatus();
        String normalizedStaffType = validator.normalizeStaffType(staffType);
        return staffRepository.findSchedules(normalizedStaffType, staffName,
                department, workDate);
    }

    public AdminSchedulePage getStaffSchedulesPage(String staffType,
            String staffName,
            String department,
            Date workDate,
            String status,
            String viewMode,
            String sortBy,
            String sortDir,
            int page,
            int pageSize) {

        staffRepository.refreshStaffScheduleStatus();
        String normalizedStaffType = validator.normalizeStaffType(staffType);
        return staffRepository.findSchedules(normalizedStaffType, staffName,
                department, workDate, status, viewMode, sortBy, sortDir, page, pageSize);
    }

    public Map<String, Object> getStaffScheduleById(int staffScheduleId) {
        return staffRepository.findById(staffScheduleId);
    }

    public boolean createStaffSchedule(int accountId,
            String staffType,
            Date workDate,
            String timeSlot,
            String department,
            String workArea,
            Integer maxWorkload,
            String roomId) {

        setValidationMessage("");
        String normalizedStaffType = validator.normalizeStaffType(staffType);
        String normalizedTimeSlot = validator.normalizeTimeSlot(timeSlot);
        if (normalizedStaffType == null) {
            setValidationMessage("Loại nhân sự không hợp lệ.");
            return false;
        }

        String workloadError = AdminScheduleValidator.validateStaffWorkload(normalizedStaffType, maxWorkload);
        if (workloadError != null) {
            setValidationMessage(workloadError);
            return false;
        }

        if (AdminScheduleValidator.requiresRoom(normalizedStaffType)
                && (roomId == null || roomId.trim().isEmpty())) {
            setValidationMessage("Vui lòng chọn phòng xét nghiệm.");
            return false;
        }

        try (java.sql.Connection connection = com.diabetes.monitoring.util.DatabaseConnection.getConnection()) {
            String error = validator.validate(connection, accountId, normalizedStaffType,
                    workDate, normalizedTimeSlot, null);
            if (error != null) {
                setValidationMessage(error);
                return false;
            }

            String roomError = AdminScheduleValidator.requiresRoom(normalizedStaffType)
                    ? AdminScheduleValidator.validateRoom(connection, roomId, workDate, normalizedTimeSlot, null)
                    : null;
            if (roomError != null) {
                setValidationMessage(roomError);
                return false;
            }

            return staffRepository.insert(accountId, normalizedStaffType, workDate,
                    normalizedTimeSlot, department, workArea, maxWorkload, "Scheduled", "Manual", roomId);
        } catch (java.sql.SQLException e) {
            setValidationMessage("Lỗi tạo lịch nhân sự: " + e.getMessage());
            return false;
        }
    }

    public boolean updateStaffSchedule(int staffScheduleId,
            int accountId,
            String staffType,
            Date workDate,
            String timeSlot,
            String department,
            String workArea,
            Integer maxWorkload,
            String status,
            String roomId) {

        setValidationMessage("");
        String normalizedStaffType = validator.normalizeStaffType(staffType);
        String normalizedTimeSlot = validator.normalizeTimeSlot(timeSlot);
        if (staffScheduleId <= 0 || normalizedStaffType == null) {
            setValidationMessage("Thông tin cập nhật lịch nhân sự không hợp lệ.");
            return false;
        }

        String workloadError = AdminScheduleValidator.validateStaffWorkload(normalizedStaffType, maxWorkload);
        if (workloadError != null) {
            setValidationMessage(workloadError);
            return false;
        }

        if (AdminScheduleValidator.requiresRoom(normalizedStaffType)
                && (roomId == null || roomId.trim().isEmpty())) {
            setValidationMessage("Vui lòng chọn phòng xét nghiệm.");
            return false;
        }

        try (java.sql.Connection connection = com.diabetes.monitoring.util.DatabaseConnection.getConnection()) {
            String currentStatus = staffRepository.getStaffScheduleStatus(staffScheduleId);
            if (currentStatus == null) {
                setValidationMessage("Không tìm thấy lịch trực nhân sự.");
                return false;
            }
            if ("cancelled".equalsIgnoreCase(currentStatus)
                    || "expired".equalsIgnoreCase(currentStatus)
                    || "completed".equalsIgnoreCase(currentStatus)) {
                setValidationMessage("Không thể chỉnh sửa lịch đã hủy, đã hoàn tất hoặc đã qua giờ.");
                return false;
            }

            String error = validator.validate(connection, accountId, normalizedStaffType,
                    workDate, normalizedTimeSlot, staffScheduleId);
            if (error != null) {
                setValidationMessage(error);
                return false;
            }

            String roomError = AdminScheduleValidator.requiresRoom(normalizedStaffType)
                    ? AdminScheduleValidator.validateRoom(connection, roomId, workDate, normalizedTimeSlot,
                            staffScheduleId)
                    : null;
            if (roomError != null) {
                setValidationMessage(roomError);
                return false;
            }

            return staffRepository.update(staffScheduleId, accountId, normalizedStaffType, workDate,
                    normalizedTimeSlot, department, workArea, maxWorkload, status, roomId);
        } catch (java.sql.SQLException e) {
            setValidationMessage("Lỗi cập nhật lịch nhân sự: " + e.getMessage());
            return false;
        }
    }

    public boolean cancelStaffSchedule(int staffScheduleId) {
        setValidationMessage("");
        try {
            String currentStatus = staffRepository.getStaffScheduleStatus(staffScheduleId);
            if (currentStatus == null) {
                setValidationMessage("Không tìm thấy lịch trực nhân sự.");
                return false;
            }
            if ("cancelled".equalsIgnoreCase(currentStatus)
                    || "expired".equalsIgnoreCase(currentStatus)
                    || "completed".equalsIgnoreCase(currentStatus)) {
                setValidationMessage("Không thể hủy lịch đã hủy, đã hoàn tất hoặc đã qua giờ.");
                return false;
            }
            return staffRepository.cancel(staffScheduleId);
        } catch (java.sql.SQLException e) {
            setValidationMessage("Không thể hủy lịch nhân sự do lỗi hệ thống.");
            return false;
        }
    }

    public boolean deleteStaffSchedule(int id, String staffType) {
        if ("Doctor".equalsIgnoreCase(staffType)) {
            return staffRepository.deleteDoctorSchedule(id);
        } else if ("Lab".equalsIgnoreCase(staffType)) {
            return staffRepository.deleteLabSchedule(id);
        } else if ("Reception".equalsIgnoreCase(staffType) || "Receptionist".equalsIgnoreCase(staffType)) {
            return staffRepository.deleteReceptionSchedule(id);
        }
        try {
            return staffRepository.delete(id);
        } catch (java.sql.SQLException e) {
            return false;
        }
    }

    public boolean autoReassignConflictRoom(int id, String staffType) {
        return staffRepository.autoReassignConflictRoom(id, staffType);
    }

    public boolean autoResolveAllConflicts() {
        return staffRepository.autoResolveAllConflicts();
    }

    public boolean deleteStaffSchedule(int staffScheduleId) {
        setValidationMessage("");
        try {
            return staffRepository.delete(staffScheduleId);
        } catch (java.sql.SQLException e) {
            setValidationMessage("Không thể xóa lịch nhân sự do lỗi hệ thống.");
            return false;
        }
    }

    public int refreshStaffScheduleStatus() {
        return staffRepository.refreshStaffScheduleStatus();
    }

    public AiStaffSchedulingResult createStaffSchedules(
            AiStaffSchedulingRequest request) {

        AiStaffSchedulingResult result = new AiStaffSchedulingResult();
        if (request == null || request.startDate == null
                || request.endDate == null
                || request.startDate.after(request.endDate)) {
            result.message = "Khoảng ngày lập lịch nhân sự không hợp lệ.";
            return result;
        }
        if (request.shiftsPerDay == null || request.shiftsPerDay.isEmpty()) {
            result.message = "Vui lòng nhập ít nhất một khung ca nhân sự.";
            return result;
        }

        List<Map<String, Object>> created = aiSchedulingRepository.createAiStaffSchedules(
                request.staffType,
                request.startDate,
                request.endDate,
                request.shiftsPerDay,
                request.department,
                request.workArea,
                request.staffPerShift,
                request.maxWorkload,
                request.roomId,
                request.conflictHandling);

        int expected = countDays(request.startDate, request.endDate)
                * request.shiftsPerDay.size()
                * Math.min(4, Math.max(1, request.staffPerShift));

        String repoMessage = aiSchedulingRepository.consumeScheduleValidationMessage();
        boolean hasError = repoMessage != null && !repoMessage.isBlank();

        result.success = !hasError && (created.size() == expected || "skip".equalsIgnoreCase(request.conflictHandling)
                || "overwrite".equalsIgnoreCase(request.conflictHandling));
        result.items = created;
        if (result.success) {
            result.message = "AI đã tạo " + created.size()
                    + " ca trực nhân sự trong Staff_Schedule.";
        } else {
            result.message = repoMessage == null || repoMessage.isBlank()
                    ? "Không thể tạo đủ lịch nhân sự. Batch đã rollback để tránh dữ liệu thiếu."
                    : repoMessage;
        }
        return result;
    }

    private int countDays(Date startDate, Date endDate) {
        int days = 0;
        LocalDate cursor = startDate.toLocalDate();
        while (!cursor.isAfter(endDate.toLocalDate())) {
            days++;
            cursor = cursor.plusDays(1);
        }
        return days;
    }

    public static class AiStaffSchedulingRequest {
        public String staffType;
        public Date startDate;
        public Date endDate;
        public List<Map<String, String>> shiftsPerDay;
        public String department;
        public String workArea;
        public int staffPerShift;
        public Integer maxWorkload;
        public String roomId;
        public String conflictHandling;
    }

    public static class AiStaffSchedulingResult {
        public boolean success;
        public String message = "";
        public List<Map<String, Object>> items = new ArrayList<>();
    }
}

/**
 * Builds AI scheduling requests and persists generated schedules.
 */
class AdminAiSchedulingService {
    private final AdminAiSchedulingRepository aiSchedulingRepository = new AdminAiSchedulingRepository();
    private final GeminiSchedulingService geminiSchedulingService = new GeminiSchedulingService();

    public String suggestTimeSlot(int doctorId, Date workDate) {
        try {
            List<Map<String, Object>> existingSchedules = aiSchedulingRepository.getDoctorSchedulesByDate(doctorId,
                    workDate);
            if (existingSchedules.isEmpty()) {
                return "08:00-12:00";
            } else if (existingSchedules.size() == 1) {
                String slot = String.valueOf(existingSchedules.get(0).get("time_slot"));
                if (slot.contains("08:00") || slot.contains("09:00") || slot.contains("10:00")
                        || slot.contains("11:00")) {
                    return "13:30-17:30";
                } else {
                    return "08:00-12:00";
                }
            }
        } catch (Exception ex) {
            System.err.println("Failed to suggest time slot using Heuristics: " + ex.getMessage());
        }
        return null;
    }

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
        List<Date> targetDates = buildSelectedTargetDates(startDate, endDate,
                selectedWeekdays);

        if (shiftsPerDay.isEmpty()) {
            shiftsPerDay = buildDefaultShiftTemplates(startTime, endTime,
                    slotMinutes, department);
        }
        doctorsPerShift = Math.min(4, Math.max(1, doctorsPerShift));
        int expectedScheduleCount = targetDates.size() * shiftsPerDay.size()
                * doctorsPerShift;
        shiftsPerDay = expandShiftsForDoctorsPerSlot(shiftsPerDay,
                doctorsPerShift);

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
        List<Map<String, Object>> doctors = aiSchedulingRepository.getDoctorsForAiScheduling(startDate,
                endDate, request.selectedDepartments);
        GeminiSchedulingService.SchedulingResult geminiResult = geminiSchedulingService.generate(targetDates,
                shiftsPerDay,
                doctors);

        List<Map<String, Object>> created = new ArrayList<>();
        if (geminiResult.success) {
            created = aiSchedulingRepository.createGeminiSchedules(
                    geminiResult.assignments, maxPatients, maxSchedules, request.preview);
        }
        if (created.size() != maxSchedules) {
            created = aiSchedulingRepository.createAiOptimizedSchedules(
                    targetDates, shiftsPerDay, department, maxPatients,
                    maxSchedules, request.preview);
        }

        result.success = !created.isEmpty();
        result.items = created;
        if (result.success) {
            boolean usedGemini = created.stream()
                    .anyMatch(row -> "Gemini AI".equals(String.valueOf(row.get("source"))));
            if (created.size() == maxSchedules) {
                result.message = usedGemini
                        ? "Gemini AI đã tạo đúng " + created.size()
                                + " ca trực tối ưu."
                        : "Hệ thống AI đã tạo thành công " + created.size()
                                + " ca trực tối ưu theo cấu hình.";
            } else {
                result.message = "Đã phân bổ thành công " + created.size() + "/" + maxSchedules
                        + " ca trực còn thiếu (các ca còn lại đã có lịch sẵn).";
            }
        } else {
            String repoMessage = aiSchedulingRepository.consumeScheduleValidationMessage();
            result.message = (repoMessage != null && !repoMessage.isBlank())
                    ? repoMessage
                    : "Không có ca trực mới nào được tạo vì tất cả các ca đều đã có lịch hoặc không đủ phòng khả dụng.";
        }
        return result;
    }

    private List<Map<String, String>> buildDefaultShiftTemplates(
            String rawStartTime,
            String rawEndTime,
            int slotMinutes,
            String department) {

        List<Map<String, String>> shifts = new ArrayList<>();
        String resolvedDepartment = (department == null || department.isBlank())
                ? "Endocrinology"
                : department;
        for (String timeSlot : buildScheduleTimeSlots(rawStartTime, rawEndTime,
                slotMinutes)) {
            Map<String, String> shift = new java.util.HashMap<>();
            shift.put("timeSlot", timeSlot);
            shift.put("department", resolvedDepartment);
            shifts.add(shift);
        }
        return shifts;
    }

    private List<Map<String, String>> expandShiftsForDoctorsPerSlot(
            List<Map<String, String>> baseShifts,
            int doctorsPerShift) {

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

    private List<String> buildScheduleTimeSlots(String rawStartTime,
            String rawEndTime,
            int slotMinutes) {

        List<String> slots = new ArrayList<>();
        if (slotMinutes < 30 || slotMinutes > 480) {
            return slots;
        }
        try {
            java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("HH:mm");
            LocalTime start = LocalTime.parse(rawStartTime, formatter);
            LocalTime end = LocalTime.parse(rawEndTime, formatter);
            if (!start.isBefore(end)) {
                return slots;
            }
            LocalTime cursor = start;
            while (cursor.plusMinutes(slotMinutes).compareTo(end) <= 0) {
                LocalTime slotEnd = cursor.plusMinutes(slotMinutes);
                slots.add(cursor.format(formatter) + "-"
                        + slotEnd.format(formatter));
                cursor = slotEnd;
            }
        } catch (Exception ex) {
            return new ArrayList<>();
        }
        return slots;
    }

    private List<Date> buildSelectedTargetDates(Date startDate,
            Date endDate,
            List<Integer> selectedWeekdays) {

        List<Date> dates = new ArrayList<>();
        if (startDate == null || endDate == null || startDate.after(endDate)
                || selectedWeekdays == null || selectedWeekdays.isEmpty()) {
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
        public List<String> selectedDepartments = new ArrayList<>();
        public List<Map<String, String>> shiftsPerDay;
        public List<Integer> selectedWeekdays;
        public boolean preview;
    }

    public static class AiSchedulingResult {
        public boolean success;
        public String message = "";
        public List<Map<String, Object>> items = new ArrayList<>();
    }
}
