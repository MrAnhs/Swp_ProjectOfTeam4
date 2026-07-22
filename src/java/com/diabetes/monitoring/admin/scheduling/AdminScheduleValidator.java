package com.diabetes.monitoring.admin.scheduling;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;

/**
 * Validates doctor and non-doctor staff schedule constraints.
 */
public class AdminScheduleValidator {
    public static final int MAX_PATIENTS_HARD_CEILING = 50;
    public static final int MAX_SHIFTS_PER_STAFF_PER_DAY = 2;
    public static final int LAB_MAX_WORKLOAD = 500;
    
    private static final DateTimeFormatter TIME_FORMATTER =
            DateTimeFormatter.ofPattern("HH:mm");
            
    private static final AdminRoomRepository roomRepository = new AdminRoomRepository();

    public static String validateMaxPatients(int maxPatients) {
        if (maxPatients <= 0) {
            return "max_patients phải lớn hơn 0.";
        }
        if (maxPatients > MAX_PATIENTS_HARD_CEILING) {
            return "max_patients vượt quá giới hạn cho phép.";
        }
        return null;
    }

    public static String validateOnlineQuota(Integer onlineQuota,
            int maxPatients) {

        if (onlineQuota == null) {
            return null;
        }
        if (onlineQuota < 0) {
            return "online_quota không được âm.";
        }
        if (onlineQuota > maxPatients) {
            return "online_quota không được vượt quá max_patients.";
        }
        return null;
    }

    public static String validateTimeSlot(String timeSlot) {
        return normalizeDoctorTimeSlot(timeSlot) == null
                ? "time_slot không hợp lệ."
                : null;
    }

    public static String normalizeDoctorTimeSlot(String timeSlot) {
        if (timeSlot == null || timeSlot.isBlank()) {
            return null;
        }
        String normalized = timeSlot.trim();
        if (!normalized.matches("\\d{2}:\\d{2}-\\d{2}:\\d{2}")) {
            return null;
        }
        try {
            String[] parts = normalized.split("-");
            LocalTime start = LocalTime.parse(parts[0], TIME_FORMATTER);
            LocalTime end = LocalTime.parse(parts[1], TIME_FORMATTER);
            if (!start.isBefore(end)) {
                return null;
            }
            return start.format(TIME_FORMATTER) + "-" + end.format(TIME_FORMATTER);
        } catch (RuntimeException ex) {
            return null;
        }
    }

    public static String validateDoctorDailyLimit(int scheduleCountForDay) {
        return scheduleCountForDay >= 2
                ? "Bác sĩ không thể có quá 2 ca trong một ngày."
                : null;
    }

    public static String validateNoDuplicateSchedule(boolean duplicateExists) {
        return duplicateExists
                ? "Bác sĩ đã có lịch trực cùng ngày và cùng ca."
                : null;
    }

    public static String validateNoOverlap(boolean overlapExists) {
        return overlapExists
                ? "Bác sĩ đã có ca trực trùng thời gian trong ngày."
                : null;
    }

    public static String validateScheduleInput(int maxPatients,
            Integer onlineQuota,
            String timeSlot) {

        String message = validateMaxPatients(maxPatients);
        if (message != null) {
            return message;
        }
        message = validateOnlineQuota(onlineQuota, maxPatients);
        if (message != null) {
            return message;
        }
        return validateTimeSlot(timeSlot);
    }

    public static String validateStaffWorkload(String staffType, Integer maxWorkload) {
        String normalized = normalizeStaffTypeStatic(staffType);
        if ("doctor_lab".equals(normalized)) {
            if (maxWorkload == null || maxWorkload < 1) {
                return "Số mẫu tối đa/ca phải lớn hơn 0.";
            }
            if (maxWorkload > LAB_MAX_WORKLOAD) {
                return "Số mẫu tối đa/ca không được vượt quá " + LAB_MAX_WORKLOAD + ".";
            }
            return null;
        }
        if (maxWorkload != null && maxWorkload < 0) {
            return "Tải công việc tối đa không được nhỏ hơn 0.";
        }
        return null;
    }

    public static String validateRoom(Connection connection,
            String roomId,
            Date workDate,
            String timeSlot,
            Integer excludeStaffScheduleId) throws SQLException {

        if (!roomRepository.isActiveLabRoom(connection, roomId)) {
            return "Vui lòng chọn phòng xét nghiệm đang hoạt động.";
        }
        if (roomRepository.hasRoomOverlap(connection, roomId, workDate, timeSlot,
                null, excludeStaffScheduleId)) {
            return "Phòng đã có lịch trực trùng thời gian.";
        }
        return null;
    }

    public static boolean requiresRoom(String staffType) {
        return "doctor_lab".equals(normalizeStaffTypeStatic(staffType));
    }

    public String validateStaffSchedule(Connection connection,
            int accountId,
            String staffType,
            Date workDate,
            String timeSlot,
            Integer excludeScheduleId) throws SQLException {

        String normalizedStaffType = normalizeStaffType(staffType);
        if (accountId <= 0 || normalizedStaffType == null) {
            return "Nhân sự hoặc loại nhân sự không hợp lệ.";
        }
        if (!isActiveStaffAccount(connection, accountId, normalizedStaffType)) {
            return "Tài khoản nhân sự không tồn tại, không hoạt động hoặc sai vai trò.";
        }
        if (workDate == null || workDate.toLocalDate().isBefore(LocalDate.now())) {
            return "Ngày trực phải từ hôm nay trở đi.";
        }
        String normalizedTimeSlot = normalizeTimeSlot(timeSlot);
        if (normalizedTimeSlot == null) {
            return "Khung giờ ca trực không hợp lệ. Vui lòng dùng định dạng HH:mm-HH:mm.";
        }
        if (hasStaffScheduleOverlap(connection, accountId, workDate,
                normalizedTimeSlot, excludeScheduleId)) {
            return "Nhân sự đã có ca trực trùng thời gian trong ngày.";
        }
        // Rule giới hạn 2 ca/ngày đã được loại bỏ theo yêu cầu
        // if (countStaffSchedulesInDay(connection, accountId, workDate,
        //         excludeScheduleId) >= MAX_SHIFTS_PER_STAFF_PER_DAY) {
        //     return "Nhân sự đã có 2 ca trực trong ngày này.";
        // }
        return null;
    }

    public String validate(Connection connection,
            int accountId,
            String staffType,
            Date workDate,
            String timeSlot,
            Integer excludeScheduleId) throws SQLException {

        return validateStaffSchedule(connection, accountId, staffType, workDate,
                timeSlot, excludeScheduleId);
    }

    boolean isActiveStaffAccount(Connection connection, int accountId,
            String staffType) throws SQLException {

        String role = roleForStaffType(staffType);
        if (role == null) {
            return false;
        }
        String sql = "SELECT 1 FROM Account "
                + "WHERE account_id = ? "
                + "AND LOWER(LTRIM(RTRIM(status))) = 'active' "
                + "AND LOWER(REPLACE(REPLACE(LTRIM(RTRIM(role)), '-', '_'), ' ', '_')) = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, accountId);
            statement.setString(2, role.toLowerCase());
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next();
            }
        }
    }

    private String getAccountRole(Connection connection, int accountId) throws SQLException {
        String sql = "SELECT role FROM Account WHERE account_id = ?";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getString("role") : null;
            }
        }
    }

    int countStaffSchedulesInDay(Connection connection,
            int accountId,
            Date workDate,
            Integer excludeScheduleId) throws SQLException {

        String role = getAccountRole(connection, accountId);
        if (role == null) {
            return 0;
        }

        String sql;
        int dbExcludeId = -1;
        if ("receptionist".equalsIgnoreCase(role)) {
            dbExcludeId = (excludeScheduleId != null && excludeScheduleId > 1000000) ? excludeScheduleId - 1000000 : -1;
            sql = "SELECT COUNT(*) AS total_count "
                + "FROM Reception_Schedule rs "
                + "JOIN Reception r ON r.reception_id = rs.reception_id "
                + "WHERE r.account_id = ? AND rs.work_date = ? "
                + "AND LOWER(rs.status) <> 'cancelled' "
                + "AND (? = -1 OR rs.reception_sched_id <> ?)";
        } else if ("doctor_lab".equalsIgnoreCase(role)) {
            dbExcludeId = (excludeScheduleId != null && excludeScheduleId <= 1000000) ? excludeScheduleId : -1;
            sql = "SELECT COUNT(*) AS total_count "
                + "FROM Lab_Schedule ls "
                + "JOIN Doctor_Lab dl ON dl.lab_id = ls.lab_id "
                + "WHERE dl.account_id = ? AND ls.work_date = ? "
                + "AND LOWER(ls.status) <> 'cancelled' "
                + "AND (? = -1 OR ls.lab_sched_id <> ?)";
        } else {
            return 0;
        }

        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, accountId);
            statement.setDate(2, workDate);
            statement.setInt(3, dbExcludeId);
            statement.setInt(4, dbExcludeId);
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next() ? rs.getInt("total_count") : 0;
            }
        }
    }

    boolean hasStaffScheduleOverlap(Connection connection,
            int accountId,
            Date workDate,
            String timeSlot,
            Integer excludeScheduleId) throws SQLException {

        LocalTime[] range = parseTimeSlotRange(timeSlot);
        if (range == null) {
            return true;
        }

        String role = getAccountRole(connection, accountId);
        if (role == null) {
            return false;
        }

        String sql;
        int dbExcludeId = -1;
        if ("receptionist".equalsIgnoreCase(role)) {
            dbExcludeId = (excludeScheduleId != null && excludeScheduleId > 1000000) ? excludeScheduleId - 1000000 : -1;
            sql = "SELECT COUNT(*) AS overlap_count "
                + "FROM Reception_Schedule rs "
                + "JOIN Reception r ON r.reception_id = rs.reception_id "
                + "WHERE r.account_id = ? "
                + "AND rs.work_date = ? "
                + "AND LOWER(rs.status) <> 'cancelled' "
                + "AND (? = -1 OR rs.reception_sched_id <> ?) "
                + "AND TRY_CONVERT(time, LEFT(LTRIM(RTRIM(rs.time_slot)), 5)) IS NOT NULL "
                + "AND TRY_CONVERT(time, LEFT(LTRIM(RTRIM(SUBSTRING(rs.time_slot, CHARINDEX('-', rs.time_slot) + 1, 20))), 5)) IS NOT NULL "
                + "AND TRY_CONVERT(time, LEFT(LTRIM(RTRIM(rs.time_slot)), 5)) < ? "
                + "AND ? < TRY_CONVERT(time, LEFT(LTRIM(RTRIM(SUBSTRING(rs.time_slot, CHARINDEX('-', rs.time_slot) + 1, 20))), 5))";
        } else if ("doctor_lab".equalsIgnoreCase(role)) {
            dbExcludeId = (excludeScheduleId != null && excludeScheduleId <= 1000000) ? excludeScheduleId : -1;
            sql = "SELECT COUNT(*) AS overlap_count "
                + "FROM Lab_Schedule ls "
                + "JOIN Doctor_Lab dl ON dl.lab_id = ls.lab_id "
                + "WHERE dl.account_id = ? "
                + "AND ls.work_date = ? "
                + "AND LOWER(ls.status) <> 'cancelled' "
                + "AND (? = -1 OR ls.lab_sched_id <> ?) "
                + "AND TRY_CONVERT(time, LEFT(LTRIM(RTRIM(ls.time_slot)), 5)) IS NOT NULL "
                + "AND TRY_CONVERT(time, LEFT(LTRIM(RTRIM(SUBSTRING(ls.time_slot, CHARINDEX('-', ls.time_slot) + 1, 20))), 5)) IS NOT NULL "
                + "AND TRY_CONVERT(time, LEFT(LTRIM(RTRIM(ls.time_slot)), 5)) < ? "
                + "AND ? < TRY_CONVERT(time, LEFT(LTRIM(RTRIM(SUBSTRING(ls.time_slot, CHARINDEX('-', ls.time_slot) + 1, 20))), 5))";
        } else {
            return false;
        }

        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, accountId);
            statement.setDate(2, workDate);
            statement.setInt(3, dbExcludeId);
            statement.setInt(4, dbExcludeId);
            statement.setString(5, range[1].toString());
            statement.setString(6, range[0].toString());
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next() && rs.getInt("overlap_count") > 0;
            }
        }
    }

    public String normalizeTimeSlot(String timeSlot) {
        if (timeSlot == null) {
            return null;
        }
        String compact = timeSlot.trim().replaceAll("\\s+", "");
        return parseTimeSlotRange(compact) == null ? null : compact;
    }

    LocalTime[] parseTimeSlotRange(String timeSlot) {
        if (timeSlot == null) {
            return null;
        }
        String[] parts = timeSlot.split("-", 2);
        if (parts.length != 2) {
            return null;
        }
        try {
            LocalTime start = LocalTime.parse(parts[0]);
            LocalTime end = LocalTime.parse(parts[1]);
            if (!start.isBefore(end)) {
                return null;
            }
            return new LocalTime[]{start, end};
        } catch (RuntimeException ex) {
            return null;
        }
    }

    public String normalizeStaffType(String staffType) {
        return normalizeStaffTypeStatic(staffType);
    }

    private static String normalizeStaffTypeStatic(String staffType) {
        if (staffType == null) {
            return null;
        }
        String normalized = staffType.trim().replace("-", "_").replace(" ", "_");
        if ("receptionist".equalsIgnoreCase(normalized)) {
            return "Receptionist";
        }
        if ("doctor_lab".equalsIgnoreCase(normalized)
                || "doctorlab".equalsIgnoreCase(normalized)) {
            return "doctor_lab";
        }
        return null;
    }

    public String roleForStaffType(String staffType) {
        String normalized = normalizeStaffType(staffType);
        if ("Receptionist".equals(normalized)) {
            return "receptionist";
        }
        if ("doctor_lab".equals(normalized)) {
            return "doctor_lab";
        }
        return null;
    }
}
