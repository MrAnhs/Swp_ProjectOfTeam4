package com.diabetes.monitoring.admin.scheduling;

import com.diabetes.monitoring.appointment.AppointmentRepository;
import com.diabetes.monitoring.util.DatabaseConnection;

import static com.diabetes.monitoring.admin.common.AdminJdbcSupport.bindParams;
import static com.diabetes.monitoring.admin.common.AdminJdbcSupport.hasColumn;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Repository quản lý lịch trực bác sĩ, sức chứa và quota đặt lịch.
 */
public class AdminScheduleRepository {

    private static final Logger LOGGER =
            Logger.getLogger(AdminScheduleRepository.class.getName());

    static final int MAX_PATIENTS_HARD_CEILING = 50;
    static final int MAX_SHIFTS_PER_DOCTOR_PER_DAY = 2;

    private static final Set<String> ALLOWED_SCHEDULE_STATUS =
            new HashSet<>();

    private final ThreadLocal<String> scheduleValidationMessage =
            ThreadLocal.withInitial(() -> "");

    private final AppointmentRepository appointmentRepository =
            new AppointmentRepository();

    private final AdminRoomRepository roomRepository =
            new AdminRoomRepository();

    static {
        ALLOWED_SCHEDULE_STATUS.add("Available");
        ALLOWED_SCHEDULE_STATUS.add("Full");
        ALLOWED_SCHEDULE_STATUS.add("Cancelled");
        ALLOWED_SCHEDULE_STATUS.add("Expired");
    }

    public List<Map<String, Object>> getDoctorsForSchedule() {
        List<Map<String, Object>> doctors = new ArrayList<>();
        String sql = "SELECT d.doctor_id, d.full_name, d.department "
                + "FROM Doctor d "
                + "JOIN Account a ON a.account_id = d.account_id "
                + "WHERE LOWER(a.status) = 'active' "
                + "ORDER BY d.full_name";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> doctor = new HashMap<>();
                doctor.put("doctorId", rs.getInt("doctor_id"));
                doctor.put("fullName", rs.getString("full_name"));
                doctor.put("department", rs.getString("department"));
                doctors.add(doctor);
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load doctors for schedules", e);
        }

        return doctors;
    }

    public Map<String, Object> getDoctorScheduleById(int scheduleId) {
        boolean hasOnlineQuota = hasColumn("Doctor_Schedule", "online_quota");
        boolean hasRoomId = hasColumn("Doctor_Schedule", "room_id");
        String sql = "SELECT ds.schedule_id, ds.doctor_id, d.full_name, d.department, ds.work_date, ds.time_slot, ds.max_patients, "
                + (hasOnlineQuota ? "ds.online_quota" : "NULL")
                + " AS online_quota, ds.status, "
                + (hasRoomId ? "ds.room_id, r.room_id AS room_number, r.room_name " : "NULL AS room_id, NULL AS room_number, NULL AS room_name ")
                + "FROM Doctor_Schedule ds "
                + "JOIN Doctor d ON d.doctor_id = ds.doctor_id "
                + (hasRoomId ? "LEFT JOIN Room r ON r.room_id = ds.room_id " : "")
                + "WHERE ds.schedule_id = ?";
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, scheduleId);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                Map<String, Object> row = new HashMap<>();
                row.put("scheduleId", rs.getInt("schedule_id"));
                row.put("doctorId", rs.getInt("doctor_id"));
                row.put("doctorName", rs.getString("full_name"));
                row.put("department", rs.getString("department"));
                row.put("workDate", rs.getDate("work_date"));
                row.put("timeSlot", rs.getString("time_slot"));
                int maxPatients = rs.getInt("max_patients");
                row.put("maxPatients", maxPatients);
                int onlineQuota = getEffectiveOnlineQuota(rs.getObject("online_quota"), maxPatients);
                row.put("onlineQuota", onlineQuota);
                row.put("roomId", rs.getObject("room_id"));
                row.put("roomNumber", rs.getString("room_number"));
                row.put("roomName", rs.getString("room_name"));
                row.put("bookedCount", getBookedCountBySchedule(scheduleId));
                row.put("onlineBookedCount", getOnlineBookedCountBySchedule(scheduleId));
                row.put("status", rs.getString("status"));
                return row;
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load doctor schedule by id", e);
            return null;
        }
    }


    public boolean updateDoctorSchedule(int scheduleId, int doctorId, String timeSlot, int maxPatients, String status) {
        return updateDoctorSchedule(scheduleId, doctorId, timeSlot, maxPatients, null, status);
    }


    public boolean updateDoctorSchedule(int scheduleId, int doctorId, String timeSlot, int maxPatients, Integer onlineQuota, String status) {
        return updateDoctorSchedule(scheduleId, doctorId, timeSlot, maxPatients, onlineQuota, status, null);
    }

    public boolean updateDoctorSchedule(int scheduleId, int doctorId, String timeSlot, int maxPatients, Integer onlineQuota, String status, String roomId) {
        clearScheduleValidationMessage();
        if (scheduleId <= 0) {
            setScheduleValidationMessage("Schedule id khong hop le");
            return false;
        }
        if (doctorId <= 0) {
            setScheduleValidationMessage("Bac si khong hop le");
            return false;
        }
        if (maxPatients <= 0 || maxPatients > MAX_PATIENTS_HARD_CEILING) {
            setScheduleValidationMessage("So benh nhan toi da khong hop le");
            return false;
        }

        String normalizedStatus = normalizeScheduleStatus(status);
        if (normalizedStatus == null) {
            setScheduleValidationMessage("Trang thai ca khong hop le");
            return false;
        }

        int resolvedOnlineQuota = onlineQuota == null ? getDefaultOnlineQuota(maxPatients) : onlineQuota;
        if (resolvedOnlineQuota < 0 || resolvedOnlineQuota > maxPatients) {
            setScheduleValidationMessage("Slot online phai nam trong khoang tu 0 den so benh nhan toi da.");
            return false;
        }
        if (roomId == null || roomId.trim().isEmpty()) {
            setScheduleValidationMessage("Vui lòng chọn phòng trực.");
            return false;
        }

        boolean hasOnlineQuota = hasColumn("Doctor_Schedule", "online_quota");
        boolean hasRoomId = hasColumn("Doctor_Schedule", "room_id");
        if (!hasRoomId) {
            setScheduleValidationMessage("Database chưa có cột room_id trong Doctor_Schedule.");
            return false;
        }
        String sql = hasOnlineQuota
                ? "UPDATE Doctor_Schedule SET doctor_id = ?, time_slot = ?, max_patients = ?, online_quota = ?, status = ?, room_id = ? WHERE schedule_id = ?"
                : "UPDATE Doctor_Schedule SET doctor_id = ?, time_slot = ?, max_patients = ?, status = ?, room_id = ? WHERE schedule_id = ?";
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            Date workDate = getScheduleWorkDateById(connection, scheduleId);
            String validatedTimeSlot = normalizeTimeSlot(timeSlot);
            String validationError = validateScheduleConstraints(connection, doctorId, workDate, validatedTimeSlot, maxPatients, scheduleId);
            if (validationError != null) {
                setScheduleValidationMessage(validationError);
                return false;
            }
            String roomError = validateRoomConstraints(connection, roomId, workDate, validatedTimeSlot, scheduleId, null);
            if (roomError != null) {
                setScheduleValidationMessage(roomError);
                return false;
            }

            statement.setInt(1, doctorId);
            statement.setString(2, validatedTimeSlot);
            statement.setInt(3, maxPatients);
            if (hasOnlineQuota) {
                statement.setInt(4, resolvedOnlineQuota);
                statement.setString(5, normalizedStatus);
                statement.setString(6, roomId.trim());
                statement.setInt(7, scheduleId);
            } else {
                statement.setString(4, normalizedStatus);
                statement.setString(5, roomId.trim());
                statement.setInt(6, scheduleId);
            }
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to update doctor schedule id=" + scheduleId, e);
            setScheduleValidationMessage("Loi cap nhat DB: " + e.getMessage());
            return false;
        }
    }

    public boolean transferDoctorSchedule(int scheduleId, int targetDoctorId) {
        clearScheduleValidationMessage();
        if (scheduleId <= 0 || targetDoctorId <= 0) {
            setScheduleValidationMessage("Thiếu thông tin ca trực hoặc bác sĩ nhận ca.");
            return false;
        }

        String scheduleSql = "SELECT ds.doctor_id, ds.work_date, ds.time_slot, ds.max_patients, ds.status, d.department "
                + "FROM Doctor_Schedule ds "
                + "JOIN Doctor d ON d.doctor_id = ds.doctor_id "
                + "WHERE ds.schedule_id = ?";
        String targetSql = "SELECT d.doctor_id, d.department "
                + "FROM Doctor d "
                + "JOIN Account a ON a.account_id = d.account_id "
                + "WHERE d.doctor_id = ? AND LOWER(a.status) = 'active'";
        String updateSql = "UPDATE Doctor_Schedule SET doctor_id = ? WHERE schedule_id = ?";

        try (Connection connection = DatabaseConnection.getConnection()) {
            Integer sourceDoctorId = null;
            Date workDate = null;
            String timeSlot = null;
            int maxPatients = 0;

            try (PreparedStatement statement = connection.prepareStatement(scheduleSql)) {
                statement.setInt(1, scheduleId);
                try (ResultSet rs = statement.executeQuery()) {
                    if (!rs.next()) {
                        setScheduleValidationMessage("Không tìm thấy ca trực cần chuyển giao.");
                        return false;
                    }
                    sourceDoctorId = rs.getInt("doctor_id");
                    workDate = rs.getDate("work_date");
                    timeSlot = rs.getString("time_slot");
                    maxPatients = rs.getInt("max_patients");
                }
            }

            if (sourceDoctorId != null && sourceDoctorId == targetDoctorId) {
                setScheduleValidationMessage("Bác sĩ hiện tại đã là người phụ trách ca này.");
                return false;
            }

            try (PreparedStatement statement = connection.prepareStatement(targetSql)) {
                statement.setInt(1, targetDoctorId);
                try (ResultSet rs = statement.executeQuery()) {
                    if (!rs.next()) {
                        setScheduleValidationMessage("Bác sĩ nhận ca không khả dụng hoặc không tồn tại.");
                        return false;
                    }
                }
            }

            String validationError = validateScheduleConstraints(connection, targetDoctorId, workDate, timeSlot, maxPatients, scheduleId);
            if (validationError != null) {
                setScheduleValidationMessage(validationError);
                return false;
            }

            try (PreparedStatement statement = connection.prepareStatement(updateSql)) {
                statement.setInt(1, targetDoctorId);
                statement.setInt(2, scheduleId);
                return statement.executeUpdate() > 0;
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to transfer doctor schedule", e);
            setScheduleValidationMessage("Không thể chuyển giao ca trực do lỗi hệ thống.");
            return false;
        }
    }

    public List<Map<String, Object>> getTodaySchedules() {
        List<Map<String, Object>> rows = new ArrayList<>();

        appointmentRepository.markLateWaitingAppointmentsAsNoShow();
        refreshDoctorScheduleStatusFromAppointments();
        boolean hasBookingSource = hasColumn("Appointment", "booking_source");
        boolean hasBookingType = hasColumn("Appointment", "booking_type");
        boolean hasOnlineQuota = hasColumn("Doctor_Schedule", "online_quota");
        boolean hasRoomId = hasColumn("Doctor_Schedule", "room_id");
        String onlineSourceExpression = hasBookingSource
                ? "a.booking_source"
                : (hasBookingType ? "a.booking_type" : null);
        String onlineBookedExpression = onlineSourceExpression == null
                ? "0"
                : "SUM(CASE WHEN LOWER(LTRIM(RTRIM(COALESCE(" + onlineSourceExpression + ", '')))) = 'online' AND LOWER(LTRIM(RTRIM(COALESCE(a.status, '')))) IN ('waiting', 'checked_in', 'in_progress', 'completed') THEN 1 ELSE 0 END)";

        String sql = "SELECT ds.schedule_id, d.full_name, d.department, ds.time_slot, ds.max_patients, "
            + (hasOnlineQuota ? "ds.online_quota" : "NULL")
            + " AS online_quota, ds.status, "
            + "COALESCE(load_stats.booked_count, 0) AS booked_count, "
            + "COALESCE(load_stats.online_booked_count, 0) AS online_booked_count, "
            + "COALESCE(load_stats.active_count, 0) AS active_count "
                + "FROM Doctor_Schedule ds "
                + "JOIN Doctor d ON d.doctor_id = ds.doctor_id "
            + "LEFT JOIN ("
            + "   SELECT a.schedule_id, "
            + "      SUM(CASE WHEN LOWER(LTRIM(RTRIM(COALESCE(a.status, '')))) IN ('checked_in', 'in_progress') THEN 1 ELSE 0 END) AS active_count, "
            + "      SUM(CASE WHEN LOWER(LTRIM(RTRIM(COALESCE(a.status, '')))) IN ('waiting', 'checked_in', 'in_progress', 'completed') THEN 1 ELSE 0 END) AS booked_count, "
            + "      " + onlineBookedExpression + " AS online_booked_count "
            + "   FROM Appointment a "
            + "   WHERE a.schedule_id IS NOT NULL "
            + "   GROUP BY a.schedule_id "
            + ") load_stats ON load_stats.schedule_id = ds.schedule_id "
                + "WHERE ds.work_date = CAST(GETDATE() AS DATE) "
                + "ORDER BY d.department ASC, ds.time_slot ASC, d.full_name ASC, ds.schedule_id ASC";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("scheduleId", rs.getInt("schedule_id"));
                row.put("fullName", rs.getString("full_name"));
                row.put("department", rs.getString("department"));
                row.put("timeSlot", rs.getString("time_slot"));
                int maxPatients = rs.getInt("max_patients");
                int onlineQuota = getEffectiveOnlineQuota(rs.getObject("online_quota"), maxPatients);
                row.put("maxPatients", maxPatients);
                row.put("onlineQuota", onlineQuota);
                row.put("currentLoad", rs.getInt("booked_count"));
                row.put("bookedCount", rs.getInt("booked_count"));
                row.put("onlineBookedCount", rs.getInt("online_booked_count"));
                row.put("reservedSlots", Math.max(0, maxPatients - onlineQuota));
                row.put("activeCount", rs.getInt("active_count"));
                row.put("status", rs.getString("status"));
                rows.add(row);
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load today's doctor schedules", e);
        }

        return rows;
    }

    public List<String> getScheduleDepartments() {
        List<String> departments = new ArrayList<>();
        String sql = "SELECT DISTINCT d.department "
                + "FROM Doctor d "
                + "WHERE d.department IS NOT NULL AND LTRIM(RTRIM(d.department)) <> '' "
                + "ORDER BY d.department";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {
            while (rs.next()) {
                departments.add(rs.getString("department"));
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load schedule departments", e);
        }
        return departments;
    }

    public List<Map<String, Object>> getDoctorSchedules(String department, String doctorName, Date workDate) {
        List<Map<String, Object>> rows = new ArrayList<>();

        appointmentRepository.markLateWaitingAppointmentsAsNoShow();
        refreshDoctorScheduleStatusFromAppointments();
        boolean hasBookingSource = hasColumn("Appointment", "booking_source");
        boolean hasBookingType = hasColumn("Appointment", "booking_type");
        boolean hasOnlineQuota = hasColumn("Doctor_Schedule", "online_quota");
        boolean hasRoomId = hasColumn("Doctor_Schedule", "room_id");
        String onlineSourceColumn = hasBookingSource
                ? "booking_source"
                : (hasBookingType ? "booking_type" : null);
        String onlineBookingsJoin = onlineSourceColumn != null
                ? "LEFT JOIN ("
                + "   SELECT schedule_id, COUNT(*) AS online_booked_count "
                + "   FROM Appointment "
                + "   WHERE LOWER(LTRIM(RTRIM(COALESCE(" + onlineSourceColumn + ", '')))) = 'online' "
                + "   AND LOWER(LTRIM(RTRIM(COALESCE(status, '')))) IN ('waiting', 'checked_in', 'in_progress', 'completed') "
                + "   GROUP BY schedule_id"
                + ") online_bookings ON online_bookings.schedule_id = ds.schedule_id "
                : "OUTER APPLY (SELECT 0 AS online_booked_count) online_bookings ";

        StringBuilder sql = new StringBuilder(
                "SELECT ds.schedule_id, ds.doctor_id, "
                + "COALESCE(d.full_name, 'Không xác định') AS doctor_name, "
                + "COALESCE(d.department, 'General') AS department, "
                + "ds.work_date, "
                + "COALESCE(ds.time_slot, '00:00-00:00') AS time_slot, "
                + "ISNULL(ds.max_patients, 1) AS max_patients, "
                + (hasOnlineQuota
                ? "ISNULL(ds.online_quota, CASE WHEN ISNULL(ds.max_patients, 1) <= 1 THEN ISNULL(ds.max_patients, 1) WHEN CEILING(ISNULL(ds.max_patients, 1) * 0.6) >= ISNULL(ds.max_patients, 1) THEN ISNULL(ds.max_patients, 1) - 1 ELSE CAST(CEILING(ISNULL(ds.max_patients, 1) * 0.6) AS int) END)"
                : "CASE WHEN ISNULL(ds.max_patients, 1) <= 1 THEN ISNULL(ds.max_patients, 1) WHEN CEILING(ISNULL(ds.max_patients, 1) * 0.6) >= ISNULL(ds.max_patients, 1) THEN ISNULL(ds.max_patients, 1) - 1 ELSE CAST(CEILING(ISNULL(ds.max_patients, 1) * 0.6) AS int) END")
                + " AS online_quota, "
                + (hasRoomId ? "ds.room_id, r.room_id AS room_number, r.room_name, " : "NULL AS room_id, NULL AS room_number, NULL AS room_name, ")
                + "ds.status, "
            + "COALESCE(active_bookings.active_count, 0) AS active_count, "
            + "COALESCE(booked_bookings.booked_count, 0) AS booked_count, "
            + "COALESCE(online_bookings.online_booked_count, 0) AS online_booked_count "
                + "FROM Doctor_Schedule ds "
                + "JOIN Doctor d ON d.doctor_id = ds.doctor_id "
                + (hasRoomId ? "LEFT JOIN Room r ON r.room_id = ds.room_id " : "")
                + "LEFT JOIN ("
                + "   SELECT schedule_id, COUNT(*) AS active_count "
                + "   FROM Appointment "
                + "   WHERE LOWER(LTRIM(RTRIM(COALESCE(status, '')))) IN ('checked_in', 'in_progress') "
                + "   GROUP BY schedule_id"
                + ") active_bookings ON active_bookings.schedule_id = ds.schedule_id "
            + "LEFT JOIN ("
            + "   SELECT schedule_id, COUNT(*) AS booked_count "
            + "   FROM Appointment "
            + "   WHERE LOWER(LTRIM(RTRIM(COALESCE(status, '')))) IN ('waiting', 'checked_in', 'in_progress', 'completed') "
            + "   GROUP BY schedule_id"
            + ") booked_bookings ON booked_bookings.schedule_id = ds.schedule_id "
            + onlineBookingsJoin
                + "WHERE 1=1"
        );

        List<Object> params = new ArrayList<>();

        if (department != null && !department.trim().isEmpty()) {
            sql.append(" AND d.department = ?");
            params.add(department.trim());
        }

        if (doctorName != null && !doctorName.trim().isEmpty()) {
            sql.append(" AND d.full_name LIKE ?");
            params.add("%" + doctorName.trim() + "%");
        }

        if (workDate != null) {
            sql.append(" AND ds.work_date = ?");
            params.add(workDate);
        }

        sql.append(" ORDER BY ds.work_date DESC, ds.time_slot ASC");

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql.toString())) {

            bindParams(statement, params);

            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();

                    int maxPatients = rs.getInt("max_patients");
                    int activeCount = rs.getInt("active_count");
                    int bookedCount = rs.getInt("booked_count");
                    int onlineQuota = getEffectiveOnlineQuota(rs.getObject("online_quota"), maxPatients);
                    int onlineBookedCount = rs.getInt("online_booked_count");
                    String status = rs.getString("status");

                    row.put("scheduleId", rs.getInt("schedule_id"));
                    row.put("doctorId", rs.getInt("doctor_id"));
                    row.put("doctorName", rs.getString("doctor_name"));
                    row.put("department", rs.getString("department"));
                    row.put("workDate", rs.getDate("work_date"));
                    row.put("timeSlot", rs.getString("time_slot"));
                    row.put("maxPatients", maxPatients);
                    row.put("onlineQuota", onlineQuota);
                    row.put("roomId", rs.getObject("room_id"));
                    row.put("roomNumber", rs.getString("room_number"));
                    row.put("roomName", rs.getString("room_name"));

                    /*
                 * JSP của bạn đang dùng activeAppointments,
                 * nên phải truyền đúng key này.
                     */
                    row.put("activeAppointments", activeCount);

                    /*
                 * Giữ lại activeCount nếu chỗ khác trong code vẫn đang dùng.
                     */
                    row.put("activeCount", activeCount);
                    row.put("bookedAppointments", bookedCount);
                    row.put("bookedCount", bookedCount);
                    row.put("onlineBookedCount", onlineBookedCount);
                    row.put("reservedSlots", Math.max(0, maxPatients - onlineQuota));

                    /*
                 * status là trạng thái thật trong database.
                     */
                    row.put("status", status);

                    /*
                 * JSP của bạn đang dùng s.effectiveStatus,
                 * nên phải truyền effectiveStatus.
                 * Vì bạn muốn lưu luôn Expired vào DB,
                 * effectiveStatus có thể lấy bằng chính status.
                     */
                    row.put("effectiveStatus", status);

                    row.put("isFull", "Full".equalsIgnoreCase(status) || bookedCount >= maxPatients);
                    row.put("isExpired", "Expired".equalsIgnoreCase(status));
                    row.put("isCancelled", "Cancelled".equalsIgnoreCase(status));
                    row.put("isAvailable", "Available".equalsIgnoreCase(status));

                    rows.add(row);
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to get doctor schedules", e);
        }

        return rows;
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

        appointmentRepository.markLateWaitingAppointmentsAsNoShow();
        refreshDoctorScheduleStatusFromAppointments();
        pageSize = normalizePageSize(pageSize);
        page = Math.max(1, page);

        boolean hasBookingSource = hasColumn("Appointment", "booking_source");
        boolean hasBookingType = hasColumn("Appointment", "booking_type");
        boolean hasOnlineQuota = hasColumn("Doctor_Schedule", "online_quota");
        boolean hasRoomId = hasColumn("Doctor_Schedule", "room_id");
        String onlineSourceColumn = hasBookingSource ? "booking_source" : (hasBookingType ? "booking_type" : null);
        String onlineBookedExpression = onlineSourceColumn == null
                ? "0"
                : "(SELECT COUNT(*) FROM Appointment ao WHERE ao.schedule_id = ds.schedule_id "
                + "AND LOWER(LTRIM(RTRIM(COALESCE(ao." + onlineSourceColumn + ", '')))) = 'online' "
                + "AND LOWER(LTRIM(RTRIM(COALESCE(ao.status, '')))) IN ('waiting', 'checked_in', 'in_progress', 'completed'))";

        StringBuilder fromWhere = new StringBuilder(
                " FROM Doctor_Schedule ds "
                + "JOIN Doctor d ON d.doctor_id = ds.doctor_id "
                + (hasRoomId ? "LEFT JOIN Room r ON r.room_id = ds.room_id " : "")
                + "WHERE 1=1");
        List<Object> params = new ArrayList<>();
        appendDoctorScheduleFilters(fromWhere, params, department, doctorName, workDate, status, viewMode);

        int totalRecords = countRows("SELECT COUNT(*)" + fromWhere, params);
        int totalPages = Math.max(1, (int) Math.ceil(totalRecords / (double) pageSize));
        page = Math.min(page, totalPages);
        int offset = (page - 1) * pageSize;

        String startTimeExpression = "TRY_CONVERT(time, LEFT(LTRIM(RTRIM(ds.time_slot)), 5))";
        String endTimeExpression = "TRY_CONVERT(time, LEFT(LTRIM(RTRIM(SUBSTRING(ds.time_slot, CHARINDEX('-', ds.time_slot) + 1, 20))), 5))";
        
        String orderBy;
        if ("workDate".equalsIgnoreCase(sortBy)) {
            if ("desc".equalsIgnoreCase(sortDir)) {
                orderBy = " ORDER BY ds.work_date DESC, " + endTimeExpression + " DESC, ds.schedule_id DESC ";
            } else {
                orderBy = " ORDER BY ds.work_date ASC, " + startTimeExpression + " ASC, ds.schedule_id ASC ";
            }
        } else if ("fullName".equalsIgnoreCase(sortBy)) {
            if ("desc".equalsIgnoreCase(sortDir)) {
                orderBy = " ORDER BY d.full_name DESC, ds.work_date DESC, ds.schedule_id DESC ";
            } else {
                orderBy = " ORDER BY d.full_name ASC, ds.work_date ASC, ds.schedule_id ASC ";
            }
        } else {
            orderBy = "history".equalsIgnoreCase(normalizeViewMode(viewMode))
                    ? " ORDER BY ds.work_date DESC, " + endTimeExpression + " DESC, ds.schedule_id DESC "
                    : " ORDER BY ds.work_date ASC, " + startTimeExpression + " ASC, ds.schedule_id ASC ";
        }
        String sql = "SELECT ds.schedule_id, ds.doctor_id, "
                + "COALESCE(d.full_name, N'Không xác định') AS doctor_name, "
                + "COALESCE(d.department, 'General') AS department, "
                + "ds.work_date, COALESCE(ds.time_slot, '00:00-00:00') AS time_slot, "
                + "ISNULL(ds.max_patients, 1) AS max_patients, "
                + (hasOnlineQuota
                ? "ISNULL(ds.online_quota, CASE WHEN ISNULL(ds.max_patients, 1) <= 1 THEN ISNULL(ds.max_patients, 1) WHEN CEILING(ISNULL(ds.max_patients, 1) * 0.6) >= ISNULL(ds.max_patients, 1) THEN ISNULL(ds.max_patients, 1) - 1 ELSE CAST(CEILING(ISNULL(ds.max_patients, 1) * 0.6) AS int) END)"
                : "CASE WHEN ISNULL(ds.max_patients, 1) <= 1 THEN ISNULL(ds.max_patients, 1) WHEN CEILING(ISNULL(ds.max_patients, 1) * 0.6) >= ISNULL(ds.max_patients, 1) THEN ISNULL(ds.max_patients, 1) - 1 ELSE CAST(CEILING(ISNULL(ds.max_patients, 1) * 0.6) AS int) END")
                + " AS online_quota, "
                + (hasRoomId ? "ds.room_id, r.room_id AS room_number, r.room_name, " : "NULL AS room_id, NULL AS room_number, NULL AS room_name, ")
                + "ds.status, "
                + "(SELECT COUNT(*) FROM Appointment aa WHERE aa.schedule_id = ds.schedule_id "
                + "AND LOWER(LTRIM(RTRIM(COALESCE(aa.status, '')))) IN ('checked_in', 'in_progress')) AS active_count, "
                + "(SELECT COUNT(*) FROM Appointment ab WHERE ab.schedule_id = ds.schedule_id "
                + "AND LOWER(LTRIM(RTRIM(COALESCE(ab.status, '')))) IN ('waiting', 'checked_in', 'in_progress', 'completed')) AS booked_count, "
                + onlineBookedExpression + " AS online_booked_count "
                + fromWhere + orderBy
                + "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";

        List<Map<String, Object>> rows = new ArrayList<>();
        try (Connection connection = DatabaseConnection.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            List<Object> queryParams = new ArrayList<>(params);
            queryParams.add(offset);
            queryParams.add(pageSize);
            bindParams(statement, queryParams);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    rows.add(mapDoctorScheduleRow(rs));
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to get paged doctor schedules", e);
        }
        return new AdminSchedulePage(rows, page, pageSize, totalRecords);
    }

    private void appendDoctorScheduleFilters(StringBuilder sql,
            List<Object> params,
            String department,
            String doctorName,
            Date workDate,
            String status,
            String viewMode) {

        if (department != null && !department.trim().isEmpty()) {
            sql.append(" AND d.department = ?");
            params.add(department.trim());
        }
        if (doctorName != null && !doctorName.trim().isEmpty()) {
            sql.append(" AND LOWER(d.full_name) LIKE ?");
            params.add("%" + doctorName.trim().toLowerCase(Locale.ROOT) + "%");
        }
        if (workDate != null) {
            sql.append(" AND ds.work_date = ?");
            params.add(workDate);
        }
        if (status != null && !status.trim().isEmpty()) {
            sql.append(" AND LOWER(ds.status) = ?");
            params.add(status.trim().toLowerCase(Locale.ROOT));
        }
        String mode = normalizeViewMode(viewMode);
        if ("history".equals(mode)) {
            sql.append(" AND (ds.work_date < CAST(GETDATE() AS DATE) OR LOWER(ds.status) IN ('cancelled', 'expired', 'completed'))");
            if (workDate == null) {
                sql.append(" AND ds.work_date >= DATEADD(day, -30, CAST(GETDATE() AS DATE))");
            }
        } else {
            sql.append(" AND ds.work_date >= CAST(GETDATE() AS DATE) AND LOWER(ds.status) NOT IN ('cancelled', 'expired', 'completed')");
        }
    }

    private Map<String, Object> mapDoctorScheduleRow(ResultSet rs) throws SQLException {
        Map<String, Object> row = new HashMap<>();
        int maxPatients = rs.getInt("max_patients");
        int activeCount = rs.getInt("active_count");
        int bookedCount = rs.getInt("booked_count");
        int onlineQuota = getEffectiveOnlineQuota(rs.getObject("online_quota"), maxPatients);
        int onlineBookedCount = rs.getInt("online_booked_count");
        String status = rs.getString("status");
        row.put("scheduleId", rs.getInt("schedule_id"));
        row.put("doctorId", rs.getInt("doctor_id"));
        row.put("doctorName", rs.getString("doctor_name"));
        row.put("department", rs.getString("department"));
        row.put("workDate", rs.getDate("work_date"));
        row.put("timeSlot", rs.getString("time_slot"));
        row.put("maxPatients", maxPatients);
        row.put("onlineQuota", onlineQuota);
        row.put("roomId", rs.getObject("room_id"));
        row.put("roomNumber", rs.getString("room_number"));
        row.put("roomName", rs.getString("room_name"));
        row.put("activeAppointments", activeCount);
        row.put("activeCount", activeCount);
        row.put("bookedAppointments", bookedCount);
        row.put("bookedCount", bookedCount);
        row.put("onlineBookedCount", onlineBookedCount);
        row.put("reservedSlots", Math.max(0, maxPatients - onlineQuota));
        String effectiveStatus = resolveDoctorEffectiveStatus(rs.getDate("work_date"),
                rs.getString("time_slot"), status, bookedCount, maxPatients);
        row.put("status", status);
        row.put("effectiveStatus", effectiveStatus);
        row.put("isFull", "Full".equalsIgnoreCase(effectiveStatus));
        row.put("isExpired", "Expired".equalsIgnoreCase(effectiveStatus));
        row.put("isCancelled", "Cancelled".equalsIgnoreCase(effectiveStatus));
        row.put("isAvailable", "Available".equalsIgnoreCase(effectiveStatus)
                || "Upcoming".equalsIgnoreCase(effectiveStatus)
                || "Ongoing".equalsIgnoreCase(effectiveStatus));
        return row;
    }

    private String resolveDoctorEffectiveStatus(Date workDate,
            String timeSlot,
            String storedStatus,
            int bookedCount,
            int maxPatients) {

        if ("Cancelled".equalsIgnoreCase(storedStatus)) {
            return "Cancelled";
        }
        LocalTime[] range = parseTimeSlotRange(timeSlot);
        if (workDate == null || range == null) {
            return bookedCount >= maxPatients ? "Full" : "Upcoming";
        }
        LocalDate scheduleDate = workDate.toLocalDate();
        LocalDate today = LocalDate.now();
        if (scheduleDate.isBefore(today)) {
            return "Expired";
        }
        if (scheduleDate.isAfter(today)) {
            return bookedCount >= maxPatients ? "Full" : "Upcoming";
        }
        LocalTime now = LocalTime.now();
        if (now.isBefore(range[0])) {
            return bookedCount >= maxPatients ? "Full" : "Upcoming";
        }
        if (now.isBefore(range[1])) {
            return bookedCount >= maxPatients ? "Full" : "Ongoing";
        }
        return "Expired";
    }

    private int countRows(String sql, List<Object> params) {
        try (Connection connection = DatabaseConnection.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            bindParams(statement, params);
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to count paged schedules", e);
            return 0;
        }
    }

    private int normalizePageSize(int pageSize) {
        return pageSize == 20 || pageSize == 50 ? pageSize : 10;
    }

    private String normalizeViewMode(String viewMode) {
        return "history".equalsIgnoreCase(viewMode) ? "history" : "upcoming";
    }
    public boolean createDoctorSchedule(int doctorId, Date workDate, String timeSlot, int maxPatients, String status) {
        return createDoctorSchedule(doctorId, workDate, timeSlot, maxPatients, null, status);
    }

    public boolean createDoctorSchedule(int doctorId, Date workDate, String timeSlot, int maxPatients, Integer onlineQuota, String status) {
        return createDoctorSchedule(doctorId, workDate, timeSlot, maxPatients, onlineQuota, status, null);
    }

    public boolean createDoctorSchedule(int doctorId, Date workDate, String timeSlot, int maxPatients, Integer onlineQuota, String status, String roomId) {
        clearScheduleValidationMessage();

        if (!isAllowedScheduleStatus(status)) {
            setScheduleValidationMessage("Trạng thái ca trực không hợp lệ.");
            return false;
        }

        Integer resolvedOnlineQuota = onlineQuota == null ? getDefaultOnlineQuota(maxPatients) : onlineQuota;
        if (resolvedOnlineQuota < 0 || resolvedOnlineQuota > maxPatients) {
            setScheduleValidationMessage("Slot online phải nằm trong khoảng từ 0 đến số bệnh nhân tối đa.");
            return false;
        }
        if (roomId == null || roomId.trim().isEmpty()) {
            setScheduleValidationMessage("Vui lòng chọn phòng trực.");
            return false;
        }

        boolean hasOnlineQuota = hasColumn("Doctor_Schedule", "online_quota");
        boolean hasRoomId = hasColumn("Doctor_Schedule", "room_id");
        if (!hasRoomId) {
            setScheduleValidationMessage("Database chưa có cột room_id trong Doctor_Schedule.");
            return false;
        }
        String sql = hasOnlineQuota
                ? "INSERT INTO Doctor_Schedule (doctor_id, work_date, time_slot, max_patients, online_quota, status, room_id) VALUES (?, ?, ?, ?, ?, ?, ?)"
                : "INSERT INTO Doctor_Schedule (doctor_id, work_date, time_slot, max_patients, status, room_id) VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            String validatedTimeSlot = normalizeTimeSlot(timeSlot);
            String validationError = validateScheduleConstraints(connection, doctorId, workDate, validatedTimeSlot, maxPatients, null);
            if (validationError != null) {
                setScheduleValidationMessage(validationError);
                return false;
            }
            String roomError = validateRoomConstraints(connection, roomId, workDate, validatedTimeSlot, null, null);
            if (roomError != null) {
                setScheduleValidationMessage(roomError);
                return false;
            }

            statement.setInt(1, doctorId);
            statement.setDate(2, workDate);
            statement.setString(3, validatedTimeSlot);
            statement.setInt(4, maxPatients);
            if (hasOnlineQuota) {
                statement.setInt(5, resolvedOnlineQuota);
                statement.setString(6, normalizeScheduleStatus(status));
                statement.setString(7, roomId.trim());
            } else {
                statement.setString(5, normalizeScheduleStatus(status));
                statement.setString(6, roomId.trim());
            }
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to create doctor schedule", e);
            setScheduleValidationMessage("Không thể tạo ca trực do lỗi hệ thống.");
            return false;
        }
    }

    public boolean updateDoctorSchedule(int scheduleId, Date workDate, String timeSlot, int maxPatients, String status) {
        clearScheduleValidationMessage();

        if (!isAllowedScheduleStatus(status)) {
            setScheduleValidationMessage("Trạng thái ca trực không hợp lệ.");
            return false;
        }

        boolean hasOnlineQuota = hasColumn("Doctor_Schedule", "online_quota");
        String sql = hasOnlineQuota
                ? "UPDATE Doctor_Schedule SET work_date = ?, time_slot = ?, max_patients = ?, online_quota = ?, status = ? WHERE schedule_id = ?"
                : "UPDATE Doctor_Schedule SET work_date = ?, time_slot = ?, max_patients = ?, status = ? WHERE schedule_id = ?";
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            Integer doctorId = getDoctorIdByScheduleId(connection, scheduleId);
            if (doctorId == null) {
                setScheduleValidationMessage("Không tìm thấy ca trực cần cập nhật.");
                return false;
            }

            String validatedTimeSlot = normalizeTimeSlot(timeSlot);
            String validationError = validateScheduleConstraints(connection, doctorId, workDate, validatedTimeSlot, maxPatients, scheduleId);
            if (validationError != null) {
                setScheduleValidationMessage(validationError);
                return false;
            }

            statement.setDate(1, workDate);
            statement.setString(2, validatedTimeSlot);
            statement.setInt(3, maxPatients);
            if (hasOnlineQuota) {
                statement.setInt(4, getDefaultOnlineQuota(maxPatients));
                statement.setString(5, normalizeScheduleStatus(status));
                statement.setInt(6, scheduleId);
            } else {
                statement.setString(4, normalizeScheduleStatus(status));
                statement.setInt(5, scheduleId);
            }
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to update doctor schedule", e);
            setScheduleValidationMessage("Không thể cập nhật ca trực do lỗi hệ thống.");
            return false;
        }
    }

    public boolean deleteDoctorSchedule(int scheduleId) {
        String sql = "DELETE FROM Doctor_Schedule WHERE schedule_id = ?";
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, scheduleId);
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to delete doctor schedule", e);
            return false;
        }
    }

    public boolean cancelDoctorSchedule(int scheduleId) {
        clearScheduleValidationMessage();
        String sql = "UPDATE Doctor_Schedule SET status = 'Cancelled' "
                + "WHERE schedule_id = ? AND LOWER(status) NOT IN ('cancelled', 'expired')";
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, scheduleId);
            int updated = statement.executeUpdate();
            if (updated <= 0) {
                setScheduleValidationMessage("Không thể hủy ca trực đã hủy hoặc đã qua giờ.");
                return false;
            }
            return true;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to cancel doctor schedule", e);
            setScheduleValidationMessage("Không thể hủy ca trực do lỗi hệ thống.");
            return false;
        }
    }

    public int getBookedCountBySchedule(int scheduleId) {
        String sql = "SELECT COUNT(*) AS booked_count FROM Appointment "
                + "WHERE schedule_id = ? "
                + "AND LOWER(LTRIM(RTRIM(COALESCE(status, '')))) IN ('waiting', 'checked_in', 'in_progress', 'completed')";
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, scheduleId);
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("booked_count");
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to count booked appointments by scheduleId=" + scheduleId, e);
        }
        return 0;
    }

    public int getOnlineBookedCountBySchedule(int scheduleId) {
        boolean hasBookingSource = hasColumn("Appointment", "booking_source");
        boolean hasBookingType = hasColumn("Appointment", "booking_type");
        String onlineSourceColumn = hasBookingSource
                ? "booking_source"
                : (hasBookingType ? "booking_type" : null);
        if (onlineSourceColumn == null) {
            return 0;
        }
        String sql = "SELECT COUNT(*) AS booked_count FROM Appointment "
                + "WHERE schedule_id = ? "
                + "AND LOWER(LTRIM(RTRIM(COALESCE(" + onlineSourceColumn + ", '')))) = 'online' "
                + "AND LOWER(LTRIM(RTRIM(COALESCE(status, '')))) IN ('waiting', 'checked_in', 'in_progress', 'completed')";
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, scheduleId);
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("booked_count");
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to count online booked appointments by scheduleId=" + scheduleId, e);
        }
        return 0;
    }

    public boolean canBookOnline(int scheduleId) {
        return canBookBySource(scheduleId, true);
    }

    public boolean canBookByStaff(int scheduleId) {
        return canBookBySource(scheduleId, false);
    }

    public boolean updateOnlineQuota(int scheduleId, int onlineQuota) {
        clearScheduleValidationMessage();
        if (!hasColumn("Doctor_Schedule", "online_quota")) {
            setScheduleValidationMessage("Database chưa có cột online_quota trong Doctor_Schedule.");
            return false;
        }
        if (scheduleId <= 0) {
            setScheduleValidationMessage("Schedule id không hợp lệ");
            return false;
        }
        if (onlineQuota < 0) {
            setScheduleValidationMessage("Online quota không được nhỏ hơn 0");
            return false;
        }

        Integer maxPatients = null;
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement("SELECT max_patients FROM Doctor_Schedule WHERE schedule_id = ?")) {
            statement.setInt(1, scheduleId);
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    maxPatients = rs.getInt("max_patients");
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to read max_patients for scheduleId=" + scheduleId, e);
            setScheduleValidationMessage("Không thể kiểm tra giới hạn ca trực.");
            return false;
        }

        if (maxPatients == null) {
            setScheduleValidationMessage("Không tìm thấy ca trực cần cập nhật quota.");
            return false;
        }
        if (onlineQuota > maxPatients) {
            setScheduleValidationMessage("Slot online không được lớn hơn số bệnh nhân tối đa.");
            return false;
        }

        String sql = "UPDATE Doctor_Schedule SET online_quota = ? WHERE schedule_id = ?";
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, onlineQuota);
            statement.setInt(2, scheduleId);
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to update online quota for scheduleId=" + scheduleId, e);
            setScheduleValidationMessage("Không thể cập nhật online quota do lỗi hệ thống.");
            return false;
        }
    }

    private boolean canBookBySource(int scheduleId, boolean online) {
        boolean hasBookingSource = hasColumn("Appointment", "booking_source");
        boolean hasBookingType = hasColumn("Appointment", "booking_type");
        boolean hasOnlineQuota = hasColumn("Doctor_Schedule", "online_quota");
        String onlineSourceColumn = hasBookingSource
                ? "booking_source"
                : (hasBookingType ? "booking_type" : null);
        String onlineBookedJoin = onlineSourceColumn != null
                ? "LEFT JOIN ("
                + "   SELECT schedule_id, COUNT(*) AS online_booked_count "
                + "   FROM Appointment "
                + "   WHERE schedule_id = ? "
                + "   AND LOWER(LTRIM(RTRIM(COALESCE(" + onlineSourceColumn + ", '')))) = 'online' "
                + "   AND LOWER(LTRIM(RTRIM(COALESCE(status, '')))) IN ('waiting', 'checked_in', 'in_progress', 'completed') "
                + "   GROUP BY schedule_id"
                + ") online_booked ON online_booked.schedule_id = ds.schedule_id "
                : "OUTER APPLY (SELECT 0 AS online_booked_count) online_booked ";
        String sql = "SELECT ds.status, ds.max_patients, "
                + (hasOnlineQuota ? "ds.online_quota" : "NULL")
                + " AS online_quota, "
                + "COALESCE(booked.booked_count, 0) AS booked_count, "
                + "COALESCE(online_booked.online_booked_count, 0) AS online_booked_count "
                + "FROM Doctor_Schedule ds "
                + "LEFT JOIN ("
                + "   SELECT schedule_id, COUNT(*) AS booked_count "
                + "   FROM Appointment "
                + "   WHERE schedule_id = ? "
                + "   AND LOWER(LTRIM(RTRIM(COALESCE(status, '')))) IN ('waiting', 'checked_in', 'in_progress', 'completed') "
                + "   GROUP BY schedule_id"
                + ") booked ON booked.schedule_id = ds.schedule_id "
                + onlineBookedJoin
                + "WHERE ds.schedule_id = ?";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            int index = 1;
            statement.setInt(index++, scheduleId);
            if (onlineSourceColumn != null) {
                statement.setInt(index++, scheduleId);
            }
            statement.setInt(index, scheduleId);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    return false;
                }

                String status = rs.getString("status");
                if (status == null) {
                    return false;
                }
                String normalizedStatus = status.trim().toLowerCase(Locale.ROOT);
                if ("cancelled".equals(normalizedStatus) || "expired".equals(normalizedStatus) || "full".equals(normalizedStatus)) {
                    setScheduleValidationMessage("Ca này không còn nhận đặt lịch.");
                    return false;
                }

                int maxPatients = rs.getInt("max_patients");
                int bookedCount = rs.getInt("booked_count");
                if (bookedCount >= maxPatients) {
                    setScheduleValidationMessage("Ca này đã đầy. Vui lòng chọn ca khác.");
                    return false;
                }

                if (!online || onlineSourceColumn == null) {
                    return true;
                }

                int onlineQuota = getEffectiveOnlineQuota(rs.getObject("online_quota"), maxPatients);
                int onlineBookedCount = rs.getInt("online_booked_count");
                if (onlineBookedCount >= onlineQuota) {
                    setScheduleValidationMessage("Ca này đã hết slot đặt online. Vui lòng chọn ca khác hoặc liên hệ lễ tân để được hỗ trợ.");
                    return false;
                }
                return true;
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to evaluate booking availability for scheduleId=" + scheduleId, e);
            return false;
        }
    }

    public int refreshDoctorScheduleStatusFromAppointments() {
        appointmentRepository.markLateWaitingAppointmentsAsNoShow();
        boolean hasBookingSource = hasColumn("Appointment", "booking_source");
        boolean hasBookingType = hasColumn("Appointment", "booking_type");
        String onlineSourceExpression = hasBookingSource
                ? "ap.booking_source"
                : (hasBookingType ? "ap.booking_type" : null);
        String onlineBookedExpression = onlineSourceExpression == null
                ? "0"
                : "SUM(CASE WHEN LOWER(LTRIM(RTRIM(COALESCE(" + onlineSourceExpression + ", '')))) = 'online' AND LOWER(LTRIM(RTRIM(COALESCE(ap.status, '')))) IN ('waiting', 'checked_in', 'in_progress', 'completed') THEN 1 ELSE 0 END)";

        String sql = "UPDATE ds SET ds.status = CASE "
                + "WHEN LOWER(ds.status) = 'cancelled' THEN 'Cancelled' "
                + "WHEN LOWER(ds.status) = 'expired' THEN 'Expired' "
                + "WHEN ds.work_date < CAST(GETDATE() AS DATE) THEN 'Expired' "
                + "WHEN ds.work_date = CAST(GETDATE() AS DATE) "
                + "     AND TRY_CONVERT(time, LEFT(LTRIM(RTRIM(SUBSTRING(ds.time_slot, CHARINDEX('-', ds.time_slot) + 1, 20))), 5)) <= CAST(GETDATE() AS time) "
                + "THEN 'Expired' "
                + "WHEN counts.booked_appointments >= ds.max_patients THEN 'Full' "
                + "ELSE 'Available' END "
                + "FROM Doctor_Schedule ds "
                + "OUTER APPLY ("
                + "   SELECT "
                + "      SUM(CASE WHEN LOWER(LTRIM(RTRIM(COALESCE(ap.status, '')))) IN ('checked_in', 'in_progress') THEN 1 ELSE 0 END) AS active_appointments, "
                + "      SUM(CASE WHEN LOWER(LTRIM(RTRIM(COALESCE(ap.status, '')))) IN ('waiting', 'checked_in', 'in_progress', 'completed') THEN 1 ELSE 0 END) AS booked_appointments, "
                + "      " + onlineBookedExpression + " AS online_booked_appointments "
                + "   FROM Appointment ap "
                + "   WHERE ap.schedule_id = ds.schedule_id "
                + ") counts "
                + "WHERE LOWER(ds.status) <> 'cancelled'";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            return statement.executeUpdate();
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to refresh schedule status", e);
            return 0;
        }
    }

    public String consumeScheduleValidationMessage() {
        String message = scheduleValidationMessage.get();
        scheduleValidationMessage.remove();
        return message == null ? "" : message;
    }

    private void setScheduleValidationMessage(String message) {
        scheduleValidationMessage.set(message == null ? "" : message);
    }


    private void clearScheduleValidationMessage() {
        scheduleValidationMessage.remove();
    }

    private String normalizeScheduleStatus(String status) {
        if (status == null) {
            return null;
        }
        String value = status.trim();
        return ALLOWED_SCHEDULE_STATUS.contains(value) ? value : null;
    }

    private boolean isAllowedScheduleStatus(String status) {
        return normalizeScheduleStatus(status) != null;
    }

    int getDefaultOnlineQuota(int maxPatients) {
        if (maxPatients <= 1) {
            return Math.max(0, maxPatients);
        }
        int quota = (int) Math.ceil(maxPatients * 0.6);
        if (quota >= maxPatients) {
            quota = maxPatients - 1;
        }
        return Math.max(1, quota);
    }


    private int getEffectiveOnlineQuota(Object onlineQuotaValue, int maxPatients) {
        if (onlineQuotaValue instanceof Number) {
            int quota = ((Number) onlineQuotaValue).intValue();
            if (quota >= 0) {
                return Math.min(quota, Math.max(0, maxPatients));
            }
        }
        return getDefaultOnlineQuota(maxPatients);
    }

    private Integer getDoctorIdByScheduleId(Connection connection, int scheduleId) throws SQLException {
        String sql = "SELECT doctor_id FROM Doctor_Schedule WHERE schedule_id = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, scheduleId);
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("doctor_id");
                }
            }
        }
        return null;
    }


    private Date getScheduleWorkDateById(Connection connection, int scheduleId) throws SQLException {
        String sql = "SELECT work_date FROM Doctor_Schedule WHERE schedule_id = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, scheduleId);
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return rs.getDate("work_date");
                }
            }
        }
        return null;
    }

    String validateScheduleConstraints(Connection connection,
            int doctorId,
            Date workDate,
            String timeSlot,
            int maxPatients,
            Integer excludeScheduleId) throws SQLException {
        if (doctorId <= 0 || workDate == null) {
            return "Thiếu thông tin bác sĩ hoặc ngày trực.";
        }
        if (timeSlot == null) {
            return "Khung giờ ca trực không hợp lệ. Vui lòng dùng định dạng HH:mm-HH:mm.";
        }
        if (maxPatients <= 0) {
            return "Số bệnh nhân tối đa của ca trực phải lớn hơn 0.";
        }
        if (maxPatients > MAX_PATIENTS_HARD_CEILING) {
            return "Số bệnh nhân tối đa không được vượt quá 50 để đảm bảo chất lượng khám.";
        }
        if (hasScheduleOverlap(connection, doctorId, workDate, timeSlot, excludeScheduleId)) {
            return "Bác sĩ đã có ca trực trùng thời gian trong ngày.";
        }

        // Rule giới hạn 2 ca/ngày đã được loại bỏ theo yêu cầu
        // int shiftCount = countNonCancelledSchedulesInDay(connection, doctorId, workDate, excludeScheduleId);
        // if (shiftCount >= MAX_SHIFTS_PER_DOCTOR_PER_DAY) {
        //     return "Bác sĩ đã có 2 ca trực trong ngày này.";
        // }

        return null;
    }

    private String validateRoomConstraints(Connection connection,
            String roomId,
            Date workDate,
            String timeSlot,
            Integer excludeDoctorScheduleId,
            Integer excludeStaffScheduleId) throws SQLException {

        if (roomId == null || roomId.trim().isEmpty()) {
            return "Vui lòng chọn phòng trực.";
        }
        if (!roomRepository.isActiveRoom(connection, roomId)) {
            return "Phòng trực không tồn tại hoặc đang ngưng hoạt động.";
        }
        if (roomRepository.hasRoomOverlap(connection, roomId, workDate, timeSlot,
                excludeDoctorScheduleId, excludeStaffScheduleId)) {
            return "Phòng đã có lịch trực trùng thời gian.";
        }
        return null;
    }

    private int countNonCancelledSchedulesInDay(Connection connection,
            int doctorId,
            Date workDate,
            Integer excludeScheduleId) throws SQLException {
        String sql = "SELECT COUNT(*) AS total_count "
                + "FROM Doctor_Schedule "
                + "WHERE doctor_id = ? AND work_date = ? "
                + "AND LOWER(status) <> 'cancelled' "
                + "AND (? IS NULL OR schedule_id <> ?)";

        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, doctorId);
            statement.setDate(2, workDate);
            if (excludeScheduleId == null) {
                statement.setObject(3, null);
                statement.setObject(4, null);
            } else {
                statement.setInt(3, excludeScheduleId);
                statement.setInt(4, excludeScheduleId);
            }
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("total_count");
                }
            }
        }
        return 0;
    }

    private boolean hasScheduleOverlap(Connection connection,
            int doctorId,
            Date workDate,
            String timeSlot,
            Integer excludeScheduleId) throws SQLException {
        LocalTime[] range = parseTimeSlotRange(timeSlot);
        if (range == null) {
            return true;
        }

        String sql = "SELECT COUNT(*) AS overlap_count "
                + "FROM Doctor_Schedule ds "
                + "WHERE ds.doctor_id = ? "
                + "AND ds.work_date = ? "
                + "AND LOWER(ds.status) <> 'cancelled' "
                + "AND (? IS NULL OR ds.schedule_id <> ?) "
                + "AND TRY_CONVERT(time, LEFT(LTRIM(RTRIM(ds.time_slot)), 5)) IS NOT NULL "
                + "AND TRY_CONVERT(time, LEFT(LTRIM(RTRIM(SUBSTRING(ds.time_slot, CHARINDEX('-', ds.time_slot) + 1, 20))), 5)) IS NOT NULL "
                + "AND TRY_CONVERT(time, LEFT(LTRIM(RTRIM(ds.time_slot)), 5)) < ? "
                + "AND ? < TRY_CONVERT(time, LEFT(LTRIM(RTRIM(SUBSTRING(ds.time_slot, CHARINDEX('-', ds.time_slot) + 1, 20))), 5))";

        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, doctorId);
            statement.setDate(2, workDate);
            if (excludeScheduleId == null) {
                statement.setObject(3, null);
                statement.setObject(4, null);
            } else {
                statement.setInt(3, excludeScheduleId);
                statement.setInt(4, excludeScheduleId);
            }
            statement.setString(5, range[1].toString());
            statement.setString(6, range[0].toString());

            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("overlap_count") > 0;
                }
            }
        }
        return false;
    }

    String normalizeTimeSlot(String timeSlot) {
        if (timeSlot == null) {
            return null;
        }
        String compact = timeSlot.trim().replaceAll("\\s+", "");
        LocalTime[] range = parseTimeSlotRange(compact);
        return range == null ? null : compact;
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
}

