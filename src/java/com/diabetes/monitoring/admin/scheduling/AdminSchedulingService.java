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
    private final AdminStaffScheduleService staffScheduleService = new AdminStaffScheduleService();

    public void prepareScheduleViews() {
        scheduleService.prepareScheduleViews();
        staffScheduleService.refreshStaffScheduleStatus();
    }

    public List<Map<String, Object>> getStaffSchedules(String staffType, String staffName, Date workDate) {
        return staffScheduleService.getStaffSchedules(staffType, staffName, workDate);
    }

    public Map<String, Object> getStaffScheduleById(int staffScheduleId) {
        return staffScheduleService.getStaffScheduleById(staffScheduleId);
    }

    public boolean createStaffSchedule(String accountIdRaw, Date workDate, String timeSlot, String staffType, String department, String workArea, String roomId, int maxWorkload) {
        return staffScheduleService.createStaffSchedule(accountIdRaw, workDate, timeSlot, staffType, department, workArea, roomId, maxWorkload);
    }

    public boolean updateStaffSchedule(int staffScheduleId, String accountIdRaw, Date workDate, String timeSlot, String status, String department, String workArea, String roomId, int maxWorkload) {
        return staffScheduleService.updateStaffSchedule(staffScheduleId, accountIdRaw, workDate, timeSlot, status, department, workArea, roomId, maxWorkload);
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
        validationMessage.set("");
        return msg;
    }

    public void refreshStaffScheduleStatus() {
        staffRepository.refreshStaffScheduleStatus();
    }

    public List<Map<String, Object>> getStaffSchedules(String staffType, String staffName, Date workDate) {
        return staffRepository.getStaffSchedules(staffType, staffName, workDate);
    }

    public Map<String, Object> getStaffScheduleById(int staffScheduleId) {
        return staffRepository.getStaffScheduleById(staffScheduleId);
    }

    public List<Map<String, Object>> getStaffForSchedule(String staffType) {
        return staffRepository.getStaffForSchedule(staffType);
    }

    public boolean createStaffSchedule(String accountIdRaw, Date workDate, String timeSlot, String staffType, String department, String workArea, String roomId, int maxWorkload) {
        try {
            int accountId = Integer.parseInt(accountIdRaw);
            if (!validator.isValidWorkDate(workDate)) {
                setValidationMessage("Ngày trực không được ở quá khứ.");
                return false;
            }
            if (!validator.isValidTimeSlot(timeSlot)) {
                setValidationMessage("Khung giờ trực không hợp lệ (định dạng HH:mm-HH:mm).");
                return false;
            }
            if (staffRepository.hasOverlapSchedule(accountId, -1, workDate, timeSlot)) {
                setValidationMessage("Nhân sự này đã có lịch trực khác trùng khung giờ trong ngày.");
                return false;
            }
            return staffRepository.createStaffSchedule(accountId, workDate, timeSlot, staffType, department, workArea, roomId, maxWorkload);
        } catch (Exception ex) {
            setValidationMessage("Dữ liệu nhân sự không hợp lệ.");
            return false;
        }
    }

    public boolean updateStaffSchedule(int staffScheduleId, String accountIdRaw, Date workDate, String timeSlot, String status, String department, String workArea, String roomId, int maxWorkload) {
        try {
            int accountId = Integer.parseInt(accountIdRaw);
            Map<String, Object> current = staffRepository.getStaffScheduleById(staffScheduleId);
            if (current == null) {
                setValidationMessage("Lịch trực không tồn tại.");
                return false;
            }
            String currentStatus = String.valueOf(current.get("status"));
            if ("Expired".equalsIgnoreCase(currentStatus) || "Cancelled".equalsIgnoreCase(currentStatus) || "Completed".equalsIgnoreCase(currentStatus)) {
                setValidationMessage("Ca trực này đã qua, đã hủy hoặc hoàn tất, không thể chỉnh sửa.");
                return false;
            }
            if (!validator.isValidWorkDate(workDate)) {
                setValidationMessage("Ngày trực không được ở quá khứ.");
                return false;
            }
            if (!validator.isValidTimeSlot(timeSlot)) {
                setValidationMessage("Khung giờ trực không hợp lệ (định dạng HH:mm-HH:mm).");
                return false;
            }
            if (staffRepository.hasOverlapSchedule(accountId, staffScheduleId, workDate, timeSlot)) {
                setValidationMessage("Nhân sự này đã có lịch trực khác trùng khung giờ trong ngày.");
                return false;
            }
            return staffRepository.updateStaffSchedule(staffScheduleId, accountId, workDate, timeSlot, status, department, workArea, roomId, maxWorkload);
        } catch (Exception ex) {
            setValidationMessage("Dữ liệu cập nhật không hợp lệ.");
            return false;
        }
    }

    public boolean cancelStaffSchedule(int staffScheduleId) {
        Map<String, Object> current = staffRepository.getStaffScheduleById(staffScheduleId);
        if (current == null) {
            setValidationMessage("Lịch trực không tồn tại.");
            return false;
        }
        String currentStatus = String.valueOf(current.get("status"));
        if ("Expired".equalsIgnoreCase(currentStatus) || "Cancelled".equalsIgnoreCase(currentStatus) || "Completed".equalsIgnoreCase(currentStatus)) {
            setValidationMessage("Lịch trực này không ở trạng thái hoạt động để hủy.");
            return false;
        }
        return staffRepository.cancelStaffSchedule(staffScheduleId);
    }

    public boolean deleteStaffSchedule(int staffScheduleId) {
        return staffRepository.deleteStaffSchedule(staffScheduleId);
    }

    public AiStaffSchedulingResult createStaffSchedules(AiStaffSchedulingRequest request) {
        AiStaffSchedulingResult result = new AiStaffSchedulingResult();
        if (request.startDate == null || request.endDate == null || request.startDate.after(request.endDate)) {
            result.message = "Khoảng ngày lập lịch nhân viên không hợp lệ.";
            return result;
        }
        if (request.selectedWeekdays == null || request.selectedWeekdays.isEmpty()) {
            result.message = "Vui lòng chọn ít nhất một thứ áp dụng trong tuần.";
            return result;
        }
        List<Date> targetDates = new ArrayList<>();
        LocalDate cursor = request.startDate.toLocalDate();
        while (!cursor.isAfter(request.endDate.toLocalDate())) {
            if (request.selectedWeekdays.contains(cursor.getDayOfWeek().getValue())) {
                targetDates.add(Date.valueOf(cursor));
            }
            cursor = cursor.plusDays(1);
        }
        if (targetDates.isEmpty()) {
            result.message = "Khoảng ngày đã chọn không chứa thứ nào tương thích.";
            return result;
        }

        List<Map<String, Object>> staff = staffRepository.getStaffForSchedule(request.staffType);
        List<Map<String, Object>> created = aiSchedulingRepository.createStaffSchedulesBatch(
                targetDates, request.timeSlot, request.staffType, request.department, request.workArea,
                request.roomId, request.maxWorkload, staff, request.preview
        );

        result.success = !created.isEmpty();
        result.items = created;
        if (result.success) {
            result.message = "AI đã tự động lập thành công " + created.size() + " ca trực cho nhân sự!";
        } else {
            result.message = "Không có ca trực nào được tạo do trùng lịch hoặc thiếu nhân sự phù hợp.";
        }
        return result;
    }

    public static class AiStaffSchedulingRequest {
        public Date startDate;
        public Date endDate;
        public String timeSlot;
        public String staffType;
        public String department;
        public String workArea;
        public String roomId;
        public int maxWorkload = 50;
        public List<Integer> selectedWeekdays = new ArrayList<>();
        public boolean preview;
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
        List<Map<String, Object>> doctors = aiSchedulingRepository.getDoctorsForAiScheduling(startDate, endDate);
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

        result.success = created.size() == maxSchedules;
        result.items = created;
        if (result.success) {
            boolean usedGemini = created.stream()
                    .anyMatch(row -> "Gemini AI".equals(String.valueOf(row.get("source"))));
            result.message = usedGemini
                    ? "Gemini AI đã tạo đúng " + created.size()
                            + " slot lịch trực theo target_dates x shifts_per_day x bác sĩ/ca."
                    : "Đã tạo đúng " + created.size()
                            + " slot bằng bộ cân bằng tải dự phòng vì Gemini chưa trả lịch hợp lệ.";
        } else {
            String repoMessage = aiSchedulingRepository.consumeScheduleValidationMessage();
            result.message = (repoMessage != null && !repoMessage.isBlank())
                    ? repoMessage
                    : "Không thể tạo đủ " + maxSchedules
                            + " slot. Hệ thống đã hủy toàn bộ batch để tránh lịch thiếu hoặc sai chuyên khoa.";
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
            LocalTime start = LocalTime.parse(rawStartTime, formatter);
            LocalTime end = LocalTime.parse(rawEndTime, formatter);
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
        public boolean preview;
    }

    public static class AiSchedulingResult {
        public boolean success;
        public String message = "";
        public List<Map<String, Object>> items = new ArrayList<>();
    }
}
