package com.diabetes.monitoring.admin.scheduling;

import com.diabetes.monitoring.util.DatabaseConnection;

import static com.diabetes.monitoring.admin.common.AdminJdbcSupport.hasColumn;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Repository tạo lịch bằng Gemini và thuật toán fallback cục bộ.
 */
public class AdminAiSchedulingRepository {

    private static final Logger LOGGER =
            Logger.getLogger(AdminAiSchedulingRepository.class.getName());

    private static final int MAX_PATIENTS_HARD_CEILING = 50;
    private static final int MAX_SHIFTS_PER_DOCTOR_PER_DAY = 2;

    private final ThreadLocal<String> validationMessage =
            ThreadLocal.withInitial(() -> "");

    private final AdminScheduleRepository scheduleRepository =
            new AdminScheduleRepository();

    public List<Map<String, Object>> getDoctorSchedulesByDate(int doctorId, Date workDate) {
        String sql = "SELECT schedule_id, time_slot, status FROM Doctor_Schedule "
                + "WHERE doctor_id = ? AND work_date = ? AND LOWER(status) <> 'cancelled'";
        return com.diabetes.monitoring.admin.common.AdminJdbcSupport.queryForList(sql, java.util.Arrays.asList(doctorId, workDate));
    }

    public List<Map<String, Object>> getDoctorsForAiScheduling(Date startDate, Date endDate) {
        List<Map<String, Object>> doctors = new ArrayList<>();
        String sql = "SELECT d.doctor_id, d.full_name, d.department, LOWER(a.status) AS account_status, "
                + "COALESCE(active_load.active_count, 0) AS active_count, "
                + "COALESCE(capacity_load.total_capacity, 0) AS total_capacity "
                + "FROM Doctor d "
                + "JOIN Account a ON a.account_id = d.account_id "
                + "LEFT JOIN ("
                + " SELECT ds.doctor_id, COUNT(ap.appointment_id) AS active_count "
                + " FROM Doctor_Schedule ds "
                + " LEFT JOIN Appointment ap ON ap.schedule_id = ds.schedule_id "
                + "      AND ap.status IN ('Checked_In', 'In_Progress') "
                + " WHERE ds.work_date BETWEEN ? AND ? "
                + " GROUP BY ds.doctor_id"
                + ") active_load ON active_load.doctor_id = d.doctor_id "
                + "LEFT JOIN ("
                + " SELECT doctor_id, SUM(max_patients) AS total_capacity "
                + " FROM Doctor_Schedule "
                + " WHERE work_date BETWEEN ? AND ? AND status <> 'Cancelled' "
                + " GROUP BY doctor_id"
                + ") capacity_load ON capacity_load.doctor_id = d.doctor_id "
                + "WHERE LOWER(a.status) = 'active' "
                + "ORDER BY d.department, d.full_name";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setDate(1, startDate);
            statement.setDate(2, endDate);
            statement.setDate(3, startDate);
            statement.setDate(4, endDate);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    int activeCount = rs.getInt("active_count");
                    int totalCapacity = rs.getInt("total_capacity");
                    int currentLoad;
                    if (totalCapacity <= 0) {
                        currentLoad = 0;
                    } else {
                        currentLoad = (int) Math.round(activeCount * 100.0 / totalCapacity);
                    }
                    Map<String, Object> doctor = new HashMap<>();
                    doctor.put("doctorId", rs.getInt("doctor_id"));
                    doctor.put("doctorName", rs.getString("full_name"));
                    String rawDepartment = rs.getString("department");
                    String normalizedDepartment = normalizeDepartmentForAi(rawDepartment);
                    doctor.put("department", normalizedDepartment);
                    doctor.put("status", rs.getString("account_status"));
                    doctor.put("activeCount", activeCount);
                    doctor.put("totalCapacity", totalCapacity);
                    doctor.put("currentLoad", currentLoad);
                    doctors.add(doctor);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load doctors for Gemini scheduling", e);
        }
        return doctors;
    }

    private String normalizeDepartmentForAi(String rawDepartment) {
        if (rawDepartment == null) {
            return "General";
        }
        String trimmed = rawDepartment.trim();
        if (trimmed.isEmpty()) {
            return "General";
        }
        String lower = trimmed.toLowerCase();
        if (lower.contains("nội tiết") || lower.contains("tiểu đường") || lower.contains("endocrin")) {
            return "Endocrinology";
        }
        if (lower.contains("tim mạch") || lower.contains("cardio")) {
            return "Cardiology";
        }
        if (lower.contains("thận") || lower.contains("tiết niệu") || lower.contains("nephro")) {
            return "Nephrology";
        }
        if (lower.contains("tổng quát") || lower.contains("general") || lower.contains("mắt") || lower.contains("thần kinh")) {
            return "General";
        }
        return "General";
    }

    public List<Map<String, Object>> createGeminiSchedules(List<Map<String, Object>> assignments,
            int maxPatients,
            int expectedCount) {
        return createGeminiSchedules(assignments, maxPatients, expectedCount, false);
    }

    public List<Map<String, Object>> createGeminiSchedules(List<Map<String, Object>> assignments,
            int maxPatients,
            int expectedCount,
            boolean previewOnly) {
        List<Map<String, Object>> created = new ArrayList<>();
        clearValidationMessage();
        if (assignments == null || assignments.size() != expectedCount) {
            setValidationMessage("Dữ liệu phân bổ từ AI không hợp lệ hoặc không đủ số lượng.");
            return created;
        }
        if (maxPatients <= 0) {
            setValidationMessage("Số bệnh nhân tối đa của ca trực phải lớn hơn 0.");
            return created;
        }
        if (maxPatients > MAX_PATIENTS_HARD_CEILING) {
            setValidationMessage("Số bệnh nhân tối đa không được vượt quá 50 để đảm bảo chất lượng khám.");
            return created;
        }

        Date rangeStart = assignments.stream()
                .map(row -> Date.valueOf(String.valueOf(row.get("workDate"))))
                .min(Date::compareTo)
                .orElse(null);
        Date rangeEnd = assignments.stream()
                .map(row -> Date.valueOf(String.valueOf(row.get("workDate"))))
                .max(Date::compareTo)
                .orElse(null);
        String validateDoctorSql = "SELECT d.full_name, d.department, "
                + "COALESCE(active_load.active_count, 0) AS active_count, "
                + "COALESCE(capacity_load.total_capacity, 0) AS total_capacity "
                + "FROM Doctor d JOIN Account a ON a.account_id = d.account_id "
                + "OUTER APPLY ("
                + " SELECT COUNT(ap.appointment_id) AS active_count "
                + " FROM Doctor_Schedule ds "
                + " LEFT JOIN Appointment ap ON ap.schedule_id = ds.schedule_id "
                + "      AND ap.status IN ('Checked_In', 'In_Progress') "
                + " WHERE ds.doctor_id = d.doctor_id AND ds.work_date BETWEEN ? AND ?"
                + ") active_load "
                + "OUTER APPLY ("
                + " SELECT SUM(ds.max_patients) AS total_capacity "
                + " FROM Doctor_Schedule ds "
                + " WHERE ds.doctor_id = d.doctor_id AND ds.work_date BETWEEN ? AND ? "
                + "      AND ds.status <> 'Cancelled'"
                + ") capacity_load "
                + "WHERE d.doctor_id = ? AND LOWER(a.status) = 'active' "
                + "AND (COALESCE(capacity_load.total_capacity, 0) = 0 "
                + " OR COALESCE(active_load.active_count, 0) < COALESCE(capacity_load.total_capacity, 0) * 0.90)";
        String duplicateSql = "SELECT COUNT(*) FROM Doctor_Schedule "
                + "WHERE doctor_id = ? AND work_date = ? AND time_slot = ? AND status <> 'Cancelled'";
        boolean hasOnlineQuota = hasColumn("Doctor_Schedule", "online_quota");
        String insertSql = hasOnlineQuota
                ? "INSERT INTO Doctor_Schedule (doctor_id, work_date, time_slot, max_patients, online_quota, status) VALUES (?, ?, ?, ?, ?, 'Available')"
                : "INSERT INTO Doctor_Schedule (doctor_id, work_date, time_slot, max_patients, status) VALUES (?, ?, ?, ?, 'Available')";

        try (Connection connection = DatabaseConnection.getConnection()) {
            connection.setAutoCommit(false);
            try {
                Map<String, Integer> previousDoctorByDate = new HashMap<>();
                Map<String, Integer> dailyShiftCount = new HashMap<>();
                for (Map<String, Object> assignment : assignments) {
                    int doctorId = ((Number) assignment.get("doctorId")).intValue();
                    Date workDate = Date.valueOf(String.valueOf(assignment.get("workDate")));
                    String timeSlot = scheduleRepository.normalizeTimeSlot(String.valueOf(assignment.get("timeSlot")));
                    if (timeSlot == null) {
                        throw new SQLException("Khung giờ ca trực không hợp lệ. Vui lòng dùng định dạng HH:mm-HH:mm.");
                    }
                    Integer previousDoctor = previousDoctorByDate.put(workDate.toString(), doctorId);
                    if (previousDoctor != null && previousDoctor == doctorId) {
                        throw new SQLException("Gemini assigned consecutive shifts to doctor " + doctorId);
                    }
                    String dailyKey = workDate + "|" + doctorId;
                    int shiftsToday = dailyShiftCount.getOrDefault(dailyKey, 0);
                    if (shiftsToday >= MAX_SHIFTS_PER_DOCTOR_PER_DAY) {
                        throw new SQLException("Gemini assigned more than two daily shifts to doctor " + doctorId);
                    }
                    dailyShiftCount.put(dailyKey, shiftsToday + 1);

                    String validationError = scheduleRepository.validateScheduleConstraints(connection, doctorId, workDate, timeSlot, maxPatients, null);
                    if (validationError != null) {
                        throw new SQLException(validationError);
                    }

                    String doctorName;
                    String actualDepartment;
                    try (PreparedStatement validate = connection.prepareStatement(validateDoctorSql)) {
                        validate.setDate(1, rangeStart);
                        validate.setDate(2, rangeEnd);
                        validate.setDate(3, rangeStart);
                        validate.setDate(4, rangeEnd);
                        validate.setInt(5, doctorId);
                        try (ResultSet rs = validate.executeQuery()) {
                            if (!rs.next()) {
                                throw new SQLException("Invalid active doctor/department assignment: " + doctorId);
                            }
                            doctorName = rs.getString("full_name");
                            actualDepartment = rs.getString("department");
                        }
                    }

                    try (PreparedStatement duplicate = connection.prepareStatement(duplicateSql)) {
                        duplicate.setInt(1, doctorId);
                        duplicate.setDate(2, workDate);
                        duplicate.setString(3, timeSlot);
                        try (ResultSet rs = duplicate.executeQuery()) {
                            if (rs.next() && rs.getInt(1) > 0) {
                                throw new SQLException("Doctor already has this shift: " + doctorId + " / " + workDate + " / " + timeSlot);
                            }
                        }
                    }

                    try (PreparedStatement insert = connection.prepareStatement(
                            insertSql, java.sql.Statement.RETURN_GENERATED_KEYS)) {
                        insert.setInt(1, doctorId);
                        insert.setDate(2, workDate);
                        insert.setString(3, timeSlot);
                        insert.setInt(4, maxPatients);
                        if (hasOnlineQuota) {
                            insert.setInt(5, scheduleRepository.getDefaultOnlineQuota(maxPatients));
                        }
                        if (insert.executeUpdate() != 1) {
                            throw new SQLException("Could not insert Gemini schedule");
                        }
                        int scheduleId = 0;
                        try (ResultSet keys = insert.getGeneratedKeys()) {
                            if (keys.next()) {
                                scheduleId = keys.getInt(1);
                            }
                        }
                        Map<String, Object> row = new HashMap<>();
                        row.put("scheduleId", scheduleId);
                        row.put("doctorId", doctorId);
                        row.put("doctorName", doctorName);
                        row.put("department", actualDepartment);
                        row.put("workDate", workDate.toString());
                        row.put("timeSlot", timeSlot);
                        row.put("activeAppointments", 0);
                        row.put("maxPatients", maxPatients);
                        row.put("loadPct", 0);
                        row.put("effectiveStatus", "Available");
                        row.put("source", "Gemini AI");
                        row.put("reason", "Gemini tối ưu cân bằng tổng số ca, ưu tiên đúng khoa nhưng cho phép điều phối linh hoạt để chênh lệch mỗi bác sĩ không quá 1 ca.");
                        created.add(row);
                    }
                }
                if (created.size() != expectedCount) {
                    throw new SQLException("Gemini schedule count mismatch: " + created.size() + "/" + expectedCount);
                }
                if (!isBalancedScheduleBatch(connection, created)) {
                    throw new SQLException("Gemini schedule is not balanced across doctors");
                }
                if (previewOnly) {
                    connection.rollback();
                } else {
                    connection.commit();
                }
            } catch (SQLException | RuntimeException e) {
                connection.rollback();
                throw e;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (SQLException | RuntimeException e) {
            LOGGER.log(Level.SEVERE, "Failed to persist validated Gemini schedules", e);
            setValidationMessage(e.getMessage() == null ? "Không thể tạo lịch AI do vi phạm ràng buộc lịch trực." : e.getMessage());
            created.clear();
        }
        return created;
    }

    private boolean isBalancedScheduleBatch(Connection connection, List<Map<String, Object>> rows) throws SQLException {
        if (rows == null || rows.isEmpty()) {
            return true;
        }
        Map<Integer, Integer> counts = new HashMap<>();
        String activeDoctorsSql = "SELECT d.doctor_id FROM Doctor d "
                + "JOIN Account a ON a.account_id = d.account_id "
                + "WHERE LOWER(a.status) = 'active'";
        try (PreparedStatement statement = connection.prepareStatement(activeDoctorsSql); ResultSet rs = statement.executeQuery()) {
            while (rs.next()) {
                counts.put(rs.getInt("doctor_id"), 0);
            }
        }
        if (counts.isEmpty()) {
            return false;
        }
        for (Map<String, Object> row : rows) {
            Object value = row.get("doctorId");
            if (!(value instanceof Number)) {
                continue;
            }
            int doctorId = ((Number) value).intValue();
            counts.put(doctorId, counts.getOrDefault(doctorId, 0) + 1);
        }
        int min = Integer.MAX_VALUE;
        int max = Integer.MIN_VALUE;
        for (int count : counts.values()) {
            min = Math.min(min, count);
            max = Math.max(max, count);
        }
        return max - min <= 1;
    }

    public List<Map<String, Object>> createAiOptimizedSchedules(Date startDate,
            Date endDate,
            List<Map<String, String>> shiftsPerDay,
            String department,
            int maxPatients,
            int maxSchedules) {
        return createAiOptimizedSchedules(startDate, endDate, shiftsPerDay, department, maxPatients, maxSchedules, false);
    }

    public List<Map<String, Object>> createAiOptimizedSchedules(Date startDate,
            Date endDate,
            List<Map<String, String>> shiftsPerDay,
            String department,
            int maxPatients,
            int maxSchedules,
            boolean previewOnly) {
        List<Date> targetDates = new ArrayList<>();
        if (startDate != null && endDate != null && !startDate.after(endDate)) {
            java.time.LocalDate cursor = startDate.toLocalDate();
            while (!cursor.isAfter(endDate.toLocalDate())) {
                targetDates.add(Date.valueOf(cursor));
                cursor = cursor.plusDays(1);
            }
        }
        return createAiOptimizedSchedules(targetDates, shiftsPerDay, department, maxPatients, maxSchedules, previewOnly);
    }

    public List<Map<String, Object>> createAiOptimizedSchedules(List<Date> targetDates,
            List<Map<String, String>> shiftsPerDay,
            String department,
            int maxPatients,
            int maxSchedules) {
        return createAiOptimizedSchedules(targetDates, shiftsPerDay, department, maxPatients, maxSchedules, false);
    }

    public List<Map<String, Object>> createAiOptimizedSchedules(List<Date> targetDates,
            List<Map<String, String>> shiftsPerDay,
            String department,
            int maxPatients,
            int maxSchedules,
            boolean previewOnly) {
        List<Map<String, Object>> created = new ArrayList<>();
        clearValidationMessage();
        if (targetDates == null || targetDates.isEmpty() || shiftsPerDay == null || shiftsPerDay.isEmpty()
                || maxPatients <= 0 || maxSchedules <= 0) {
            setValidationMessage("Dữ liệu tạo lịch dự phòng không hợp lệ.");
            return created;
        }
        if (maxPatients > MAX_PATIENTS_HARD_CEILING) {
            setValidationMessage("Số bệnh nhân tối đa không được vượt quá 50 để đảm bảo chất lượng khám.");
            return created;
        }

        Date startDate = targetDates.stream().min(Date::compareTo).orElse(null);
        Date endDate = targetDates.stream().max(Date::compareTo).orElse(null);
        String normalizedDepartment = department == null || department.trim().isEmpty() ? null : department.trim();
        int totalDays = targetDates.size();
        int targetPerDay = Math.min(shiftsPerDay.size(), Math.max(1, maxSchedules / totalDays));
        String pickDoctorSql = "SELECT TOP 1 d.doctor_id, d.full_name, d.department, "
                + "COALESCE(active_load.active_count, 0) AS active_count, "
                + "COALESCE(capacity_load.total_capacity, 0) AS total_capacity, "
                + "COALESCE(schedule_load.schedule_count, 0) AS schedule_count "
                + "FROM Doctor d "
                + "JOIN Account a ON a.account_id = d.account_id "
                + "LEFT JOIN ("
                + "   SELECT ds.doctor_id, COUNT(ap.appointment_id) AS active_count "
                + "   FROM Doctor_Schedule ds "
                + "   LEFT JOIN Appointment ap ON ap.schedule_id = ds.schedule_id AND ap.status IN ('Checked_In', 'In_Progress') "
                + "   WHERE ds.work_date BETWEEN ? AND ? "
                + "   GROUP BY ds.doctor_id"
                + ") active_load ON active_load.doctor_id = d.doctor_id "
                + "LEFT JOIN ("
                + "   SELECT doctor_id, SUM(max_patients) AS total_capacity "
                + "   FROM Doctor_Schedule "
                + "   WHERE work_date BETWEEN ? AND ? AND status <> 'Cancelled' "
                + "   GROUP BY doctor_id"
                + ") capacity_load ON capacity_load.doctor_id = d.doctor_id "
                + "LEFT JOIN ("
                + "   SELECT doctor_id, COUNT(*) AS schedule_count "
                + "   FROM Doctor_Schedule "
                + "   WHERE work_date BETWEEN ? AND ? AND status <> 'Cancelled' "
                + "   GROUP BY doctor_id"
                + ") schedule_load ON schedule_load.doctor_id = d.doctor_id "
                + "WHERE LOWER(a.status) = 'active' "
                + "AND (? <= 0 OR d.doctor_id <> ?) "
                + "AND (COALESCE(capacity_load.total_capacity, 0) = 0 "
                + "     OR COALESCE(active_load.active_count, 0) < COALESCE(capacity_load.total_capacity, 0) * 0.90) "
                + "AND NOT EXISTS ("
                + "   SELECT 1 FROM Doctor_Schedule existing "
                + "   WHERE existing.doctor_id = d.doctor_id "
                + "   AND existing.work_date = ? "
                + "   AND existing.time_slot = ? "
                + "   AND existing.status <> 'Cancelled'"
                + ") "
                + "AND NOT EXISTS ("
                + "   SELECT 1 FROM Doctor_Schedule overlap "
                + "   WHERE overlap.doctor_id = d.doctor_id "
                + "   AND overlap.work_date = ? "
                + "   AND overlap.status <> 'Cancelled' "
                + "   AND TRY_CONVERT(time, LEFT(LTRIM(RTRIM(overlap.time_slot)), 5)) IS NOT NULL "
                + "   AND TRY_CONVERT(time, LEFT(LTRIM(RTRIM(SUBSTRING(overlap.time_slot, CHARINDEX('-', overlap.time_slot) + 1, 20))), 5)) IS NOT NULL "
                + "   AND TRY_CONVERT(time, LEFT(LTRIM(RTRIM(overlap.time_slot)), 5)) < ? "
                + "   AND ? < TRY_CONVERT(time, LEFT(LTRIM(RTRIM(SUBSTRING(overlap.time_slot, CHARINDEX('-', overlap.time_slot) + 1, 20))), 5))"
                + ") "
                + "AND ("
                + "   SELECT COUNT(*) FROM Doctor_Schedule existing_day "
                + "   WHERE existing_day.doctor_id = d.doctor_id "
                + "   AND existing_day.work_date = ? "
                + "   AND existing_day.status <> 'Cancelled'"
                + ") < 2 "
                + "ORDER BY CASE "
                + "           WHEN ? IS NULL OR LTRIM(RTRIM(?)) = '' THEN 0 "
                + "           WHEN LOWER(LTRIM(RTRIM(d.department))) = LOWER(LTRIM(RTRIM(?))) THEN 0 "
                + "           ELSE 1 "
                + "         END ASC, "
                + "CASE WHEN COALESCE(active_load.active_count, 0) = 0 THEN 0 ELSE 1 END ASC, "
                + "CASE WHEN COALESCE(capacity_load.total_capacity, 0) = 0 THEN 0 "
                + "     ELSE CAST(COALESCE(active_load.active_count, 0) AS FLOAT) / capacity_load.total_capacity END ASC, "
                + "COALESCE(schedule_load.schedule_count, 0) ASC, d.full_name ASC";
        boolean hasOnlineQuota = hasColumn("Doctor_Schedule", "online_quota");
        String insertSql = hasOnlineQuota
                ? "INSERT INTO Doctor_Schedule (doctor_id, work_date, time_slot, max_patients, online_quota, status) VALUES (?, ?, ?, ?, ?, 'Available')"
                : "INSERT INTO Doctor_Schedule (doctor_id, work_date, time_slot, max_patients, status) VALUES (?, ?, ?, ?, 'Available')";

        try (Connection connection = DatabaseConnection.getConnection()) {
            connection.setAutoCommit(false);
            try {
                for (Date sqlDate : targetDates) {
                    if (created.size() >= maxSchedules) {
                        break;
                    }
                    int createdToday = 0;
                    int lastDoctorId = -1;
                    int slotsForDay = Math.min(targetPerDay, shiftsPerDay.size());
                    for (int slotIndex = 0; slotIndex < slotsForDay && created.size() < maxSchedules; slotIndex++) {
                        Map<String, String> shift = shiftsPerDay.get(slotIndex);
                        String timeSlot = scheduleRepository.normalizeTimeSlot(shift.get("timeSlot"));
                        if (timeSlot == null) {
                            continue;
                        }
                        String targetDepartment = shift.get("department");
                        if (targetDepartment == null || targetDepartment.isBlank()) {
                            targetDepartment = normalizedDepartment;
                        }

                        Integer preferredDoctorId = getPreferredDoctorIdForFixedRotation(connection, sqlDate, timeSlot, targetDepartment);

                        Map<String, Object> doctor = null;
                        if (preferredDoctorId != null) {
                            String validationError = scheduleRepository.validateScheduleConstraints(connection, preferredDoctorId, sqlDate, timeSlot, maxPatients, null);
                            if (validationError == null) {
                                doctor = getDoctorSnapshotById(connection, preferredDoctorId);
                            }
                        }

                        if (doctor == null) {
                            doctor = pickScheduleDoctor(connection, pickDoctorSql, startDate, endDate,
                                    normalizedDepartment, targetDepartment, lastDoctorId, sqlDate, timeSlot);
                        }

                        if (doctor == null) {
                            continue;
                        }

                        int doctorId = (Integer) doctor.get("doctorId");
                        String validationError = scheduleRepository.validateScheduleConstraints(connection, doctorId, sqlDate, timeSlot, maxPatients, null);
                        if (validationError != null) {
                            LOGGER.log(Level.WARNING, "Skip invalid fallback shift: {0}", validationError);
                            continue;
                        }

                        try (PreparedStatement insert = connection.prepareStatement(insertSql, java.sql.Statement.RETURN_GENERATED_KEYS)) {
                            insert.setInt(1, doctorId);
                            insert.setDate(2, sqlDate);
                            insert.setString(3, timeSlot);
                            insert.setInt(4, maxPatients);
                            if (hasOnlineQuota) {
                            insert.setInt(5, scheduleRepository.getDefaultOnlineQuota(maxPatients));
                        }
                            if (insert.executeUpdate() > 0) {
                                int scheduleId = 0;
                                try (ResultSet keys = insert.getGeneratedKeys()) {
                                    if (keys.next()) {
                                        scheduleId = keys.getInt(1);
                                    }
                                }
                                String doctorDepartment = String.valueOf(doctor.get("department"));
                                lastDoctorId = doctorId;
                                createdToday++;

                                Map<String, Object> row = new HashMap<>();
                                row.put("scheduleId", scheduleId);
                                row.put("doctorId", doctorId);
                                row.put("doctorName", doctor.get("doctorName"));
                                row.put("department", doctorDepartment);
                                row.put("workDate", sqlDate.toString());
                                row.put("timeSlot", timeSlot);
                                row.put("activeAppointments", 0);
                                row.put("maxPatients", maxPatients);
                                row.put("loadPct", 0);
                                row.put("effectiveStatus", "Available");
                                row.put("source", "Local Fallback");
                                row.put("reason", "Thuật toán dự phòng cân bằng tổng số ca trên toàn bộ bác sĩ active, ưu tiên tải thấp và tránh hai ca liên tiếp; ca mới khởi tạo 0% tải.");
                                created.add(row);
                            }
                        }
                    }
                    if (createdToday < slotsForDay) {
                        LOGGER.log(Level.WARNING, "AI scheduling created only {0}/{1} slots for date {2}",
                                new Object[]{createdToday, slotsForDay, sqlDate});
                    }
                }
                if (created.size() < maxSchedules) {
                    throw new SQLException("AI scheduling could not create exact required slot count: " + created.size() + "/" + maxSchedules);
                }
                if (!isBalancedScheduleBatch(connection, created)) {
                    throw new SQLException("Fallback schedule is not balanced across doctors");
                }
                if (previewOnly) {
                    connection.rollback();
                } else {
                    connection.commit();
                }
            } catch (SQLException e) {
                connection.rollback();
                throw e;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to create AI optimized schedules", e);
            setValidationMessage(e.getMessage() == null ? "Không thể tạo lịch dự phòng do vi phạm ràng buộc lịch trực." : e.getMessage());
        }
        return created;
    }

    private Integer getPreferredDoctorIdForFixedRotation(Connection connection,
            Date workDate,
            String timeSlot,
            String targetDepartment) {
        return null;
    }

    private Map<String, Object> getDoctorSnapshotById(Connection connection, int doctorId) throws SQLException {
        String sql = "SELECT d.doctor_id, d.full_name, d.department "
                + "FROM Doctor d JOIN Account a ON a.account_id = d.account_id "
                + "WHERE d.doctor_id = ? AND LOWER(a.status) = 'active'";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, doctorId);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                Map<String, Object> doctor = new HashMap<>();
                doctor.put("doctorId", rs.getInt("doctor_id"));
                doctor.put("doctorName", rs.getString("full_name"));
                doctor.put("department", rs.getString("department"));
                doctor.put("activeCount", 0);
                doctor.put("scheduleCount", 0);
                return doctor;
            }
        }
    }

    private Map<String, Object> pickScheduleDoctor(Connection connection,
            String pickDoctorSql,
            Date startDate,
            Date endDate,
            String globalDepartment,
            String targetDepartment,
            int excludedDoctorId,
            Date workDate,
            String timeSlot) throws SQLException {
        try (PreparedStatement pick = connection.prepareStatement(pickDoctorSql)) {
            pick.setDate(1, startDate);
            pick.setDate(2, endDate);
            pick.setDate(3, startDate);
            pick.setDate(4, endDate);
            pick.setDate(5, startDate);
            pick.setDate(6, endDate);
            pick.setInt(7, excludedDoctorId);
            pick.setInt(8, excludedDoctorId);
            pick.setDate(9, workDate);
            pick.setString(10, timeSlot);
            LocalTime[] range = scheduleRepository.parseTimeSlotRange(timeSlot);
            String startTime = range == null ? "00:00" : range[0].toString();
            String endTime = range == null ? "23:59" : range[1].toString();
            pick.setDate(11, workDate);
            pick.setString(12, endTime);
            pick.setString(13, startTime);
            pick.setDate(14, workDate);
            pick.setString(15, targetDepartment);
            pick.setString(16, targetDepartment);
            pick.setString(17, targetDepartment);
            try (ResultSet rs = pick.executeQuery()) {
                if (rs.next()) {
                    Map<String, Object> doctor = new HashMap<>();
                    doctor.put("doctorId", rs.getInt("doctor_id"));
                    doctor.put("doctorName", rs.getString("full_name"));
                    doctor.put("department", rs.getString("department"));
                    doctor.put("activeCount", rs.getInt("active_count"));
                    doctor.put("scheduleCount", rs.getInt("schedule_count"));
                    return doctor;
                }
            }
        }
        return null;
    }


    public List<Map<String, Object>> createAiStaffSchedules(
            String staffType,
            Date startDate,
            Date endDate,
            List<Map<String, String>> shiftsPerDay,
            String department,
            String workArea,
            int staffPerShift,
            Integer maxWorkload,
            String roomId,
            String conflictHandling) {

        clearValidationMessage();
        List<Map<String, Object>> created = new ArrayList<>();
        AdminStaffScheduleRepository staffRepository =
                new AdminStaffScheduleRepository();
        AdminScheduleValidator validator = new AdminScheduleValidator();
        String normalizedStaffType = validator.normalizeStaffType(staffType);
        if (normalizedStaffType == null || startDate == null
                || endDate == null || startDate.after(endDate)) {
            setValidationMessage("Thông tin lập lịch AI cho nhân sự không hợp lệ.");
            return created;
        }
        if (shiftsPerDay == null || shiftsPerDay.isEmpty()) {
            setValidationMessage("Vui lòng cấu hình ít nhất một khung ca cho AI.");
            return created;
        }
        int resolvedStaffPerShift = Math.min(4, Math.max(1, staffPerShift));
        List<Map<String, Object>> candidates =
                staffRepository.findStaff(validator.roleForStaffType(normalizedStaffType));
        if (candidates.isEmpty()) {
            setValidationMessage("Không có nhân sự đang hoạt động phù hợp vai trò "
                     + normalizedStaffType + ".");
            return created;
        }
        if (AdminScheduleValidator.requiresRoom(normalizedStaffType)
                && (roomId == null || roomId.trim().isEmpty())) {
            setValidationMessage("Vui lòng chọn phòng xét nghiệm cho lịch bác sĩ xét nghiệm.");
            return created;
        }

        try (Connection connection = DatabaseConnection.getConnection()) {
            boolean previousAutoCommit = connection.getAutoCommit();
            connection.setAutoCommit(false);
            try {
                if ("overwrite".equalsIgnoreCase(conflictHandling)) {
                    if ("receptionist".equalsIgnoreCase(normalizedStaffType)) {
                        String deleteSql = "DELETE FROM Reception_Schedule WHERE work_date BETWEEN ? AND ?";
                        try (PreparedStatement deleteStmt = connection.prepareStatement(deleteSql)) {
                            deleteStmt.setDate(1, startDate);
                            deleteStmt.setDate(2, endDate);
                            deleteStmt.executeUpdate();
                        }
                    } else {
                        String deleteSql = "DELETE FROM Lab_Schedule WHERE room_id = ? AND work_date BETWEEN ? AND ?";
                        try (PreparedStatement deleteStmt = connection.prepareStatement(deleteSql)) {
                            deleteStmt.setString(1, roomId);
                            deleteStmt.setDate(2, startDate);
                            deleteStmt.setDate(3, endDate);
                            deleteStmt.executeUpdate();
                        }
                    }
                }

                Map<Integer, Integer> totalAssigned = new HashMap<>();
                Map<String, List<String>> dayAssignedSlots = new HashMap<>();

                LocalDate cursor = startDate.toLocalDate();
                while (!cursor.isAfter(endDate.toLocalDate())) {
                    Date workDate = Date.valueOf(cursor);
                    for (Map<String, String> shift : shiftsPerDay) {
                        String timeSlot =
                                validator.normalizeTimeSlot(shift.get("timeSlot"));
                        if (timeSlot == null) {
                            throw new SQLException("Khung ca AI không hợp lệ: "
                                    + shift.get("timeSlot"));
                        }
                        String shiftDepartment =
                                firstNotBlank(shift.get("department"), department);
                        String shiftWorkArea =
                                firstNotBlank(shift.get("workArea"), workArea);
                        for (int slot = 0; slot < resolvedStaffPerShift; slot++) {
                            Map<String, Object> candidate =
                                    chooseStaffCandidate(connection, candidates,
                                            totalAssigned, dayAssignedSlots,
                                            normalizedStaffType, workDate,
                                            timeSlot, staffRepository, validator);
                            if (candidate == null) {
                                if ("skip".equalsIgnoreCase(conflictHandling)) {
                                    continue;
                                }
                                throw new SQLException("Không đủ nhân sự khả dụng cho ngày "
                                        + workDate + " ca " + timeSlot + ".");
                            }
                            int accountId =
                                    ((Number) candidate.get("accountId")).intValue();
                            String error = validator.validate(connection,
                                    accountId, normalizedStaffType, workDate,
                                    timeSlot, null);
                            if (error != null) {
                                if ("skip".equalsIgnoreCase(conflictHandling)) {
                                    continue;
                                }
                                throw new SQLException(error);
                            }
                            int id = staffRepository.insert(connection,
                                    accountId, normalizedStaffType, workDate,
                                    timeSlot, shiftDepartment, shiftWorkArea,
                                    maxWorkload, "Scheduled", "AI",
                                    AdminScheduleValidator.requiresRoom(normalizedStaffType) ? roomId : null);
                            Map<String, Object> row = new HashMap<>();
                            row.put("staffScheduleId", id);
                            row.put("accountId", accountId);
                            row.put("staffName", candidate.get("fullName"));
                            row.put("staffType", normalizedStaffType);
                            row.put("workDate", workDate);
                            row.put("timeSlot", timeSlot);
                            row.put("department", shiftDepartment);
                            row.put("workArea", shiftWorkArea);
                            row.put("maxWorkload", maxWorkload);
                            row.put("status", "Scheduled");
                            row.put("scheduleSource", "AI");
                            row.put("roomId", AdminScheduleValidator.requiresRoom(normalizedStaffType) ? roomId : null);
                            created.add(row);
                            totalAssigned.put(accountId,
                                    totalAssigned.getOrDefault(accountId, 0) + 1);
                            dayAssignedSlots.computeIfAbsent(
                                    staffDayKey(accountId, workDate),
                                    key -> new ArrayList<>()).add(timeSlot);
                        }
                    }
                    cursor = cursor.plusDays(1);
                }
                connection.commit();
            } catch (Exception ex) {
                connection.rollback();
                created.clear();
                setValidationMessage(ex.getMessage());
            } finally {
                connection.setAutoCommit(previousAutoCommit);
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to create AI staff schedules", e);
            setValidationMessage("Không thể tạo lịch AI cho nhân sự: "
                    + e.getMessage());
            created.clear();
        }
        return created;
    }

    private Map<String, Object> chooseStaffCandidate(Connection connection,
            List<Map<String, Object>> candidates,
            Map<Integer, Integer> totalAssigned,
            Map<String, List<String>> dayAssignedSlots,
            String staffType,
            Date workDate,
            String timeSlot,
            AdminStaffScheduleRepository staffRepository,
            AdminScheduleValidator validator) {

        return candidates.stream()
                .filter(candidate -> canUseStaffCandidate(connection, candidate,
                        staffType, workDate, timeSlot, dayAssignedSlots,
                        staffRepository, validator))
                .sorted(Comparator
                        .comparing((Map<String, Object> candidate) ->
                                isConsecutiveStaffCandidate(candidate, workDate,
                                        timeSlot, dayAssignedSlots,
                                        staffRepository, validator))
                        .thenComparingInt(candidate ->
                                totalAssigned.getOrDefault(
                                        ((Number) candidate.get("accountId")).intValue(),
                                        0)))
                .findFirst()
                .orElse(null);
    }

    private boolean canUseStaffCandidate(Connection connection,
            Map<String, Object> candidate,
            String staffType,
            Date workDate,
            String timeSlot,
            Map<String, List<String>> dayAssignedSlots,
            AdminStaffScheduleRepository staffRepository,
            AdminScheduleValidator validator) {

        int accountId = ((Number) candidate.get("accountId")).intValue();
        List<String> assignedToday =
                dayAssignedSlots.get(staffDayKey(accountId, workDate));
        if (assignedToday != null
                && assignedToday.size()
                >= AdminScheduleValidator.MAX_SHIFTS_PER_STAFF_PER_DAY) {
            return false;
        }
        try {
            return validator.validate(connection, accountId,
                    staffType, workDate, timeSlot, null) == null;
        } catch (SQLException ex) {
            return false;
        }
    }

    private boolean isConsecutiveStaffCandidate(Map<String, Object> candidate,
            Date workDate,
            String timeSlot,
            Map<String, List<String>> dayAssignedSlots,
            AdminStaffScheduleRepository staffRepository,
            AdminScheduleValidator validator) {

        int accountId = ((Number) candidate.get("accountId")).intValue();
        List<String> assignedToday =
                dayAssignedSlots.get(staffDayKey(accountId, workDate));
        if (assignedToday == null || assignedToday.isEmpty()) {
            return false;
        }
        LocalTime[] target =
                validator.parseTimeSlotRange(timeSlot);
        if (target == null) {
            return true;
        }
        for (String existing : assignedToday) {
            LocalTime[] current =
                    validator.parseTimeSlotRange(existing);
            if (current != null
                    && (current[1].equals(target[0])
                    || target[1].equals(current[0]))) {
                return true;
            }
        }
        return false;
    }

    private String staffDayKey(int accountId, Date workDate) {
        return accountId + "|" + workDate;
    }

    private String firstNotBlank(String first, String second) {
        if (first != null && !first.trim().isEmpty()) {
            return first.trim();
        }
        return second == null || second.trim().isEmpty()
                ? null
                : second.trim();
    }
    public String consumeScheduleValidationMessage() {
        String message = validationMessage.get();
        validationMessage.remove();
        return message == null ? "" : message;
    }

    private void setValidationMessage(String message) {
        validationMessage.set(message == null ? "" : message);
    }

    private void clearValidationMessage() {
        validationMessage.remove();
    }

    public boolean saveSchedules(List<Map<String, Object>> list, String conflictHandling) throws SQLException {
        if (list == null || list.isEmpty()) {
            return true;
        }
        if (conflictHandling == null || conflictHandling.trim().isEmpty()) {
            conflictHandling = "overwrite";
        }
        boolean hasOnlineQuota = hasColumn("Doctor_Schedule", "online_quota");
        String insertSql = hasOnlineQuota
                ? "INSERT INTO Doctor_Schedule (doctor_id, work_date, time_slot, max_patients, online_quota, status) VALUES (?, ?, ?, ?, ?, 'Available')"
                : "INSERT INTO Doctor_Schedule (doctor_id, work_date, time_slot, max_patients, status) VALUES (?, ?, ?, ?, 'Available')";
        try (Connection connection = DatabaseConnection.getConnection()) {
            connection.setAutoCommit(false);
            try {
                for (Map<String, Object> item : list) {
                    int doctorId = ((Number) item.get("doctorId")).intValue();
                    Date workDate = Date.valueOf(String.valueOf(item.get("workDate")));
                    String timeSlot = String.valueOf(item.get("timeSlot"));
                    int maxPatients = ((Number) item.get("maxPatients")).intValue();
<<<<<<< Updated upstream
=======
                    String roomId = (String) item.get("roomId");

                    // 1. Kiểm tra ca trực cũ đã tồn tại chưa (chuẩn hóa khoảng trắng trong time_slot)
                    String checkExistSql = "SELECT schedule_id FROM Doctor_Schedule WHERE doctor_id = ? AND work_date = ? AND REPLACE(time_slot, ' ', '') = REPLACE(?, ' ', '') AND status <> 'Cancelled'";
                    Integer oldScheduleId = null;
                    try (PreparedStatement checkExist = connection.prepareStatement(checkExistSql)) {
                        checkExist.setInt(1, doctorId);
                        checkExist.setDate(2, workDate);
                        checkExist.setString(3, timeSlot);
                        try (ResultSet rs = checkExist.executeQuery()) {
                            if (rs.next()) {
                                oldScheduleId = rs.getInt("schedule_id");
                            }
                        }
                    }

                    if (oldScheduleId != null) {
                        if ("overwrite".equalsIgnoreCase(conflictHandling)) {
                            // Kiểm tra xem ca cũ đã có cuộc hẹn nào chưa
                            String checkApptSql = "SELECT COUNT(*) FROM Appointment WHERE schedule_id = ?";
                            int apptCount = 0;
                            try (PreparedStatement checkAppt = connection.prepareStatement(checkApptSql)) {
                                checkAppt.setInt(1, oldScheduleId);
                                try (ResultSet rs = checkAppt.executeQuery()) {
                                    if (rs.next()) {
                                        apptCount = rs.getInt(1);
                                    }
                                }
                            }
                            
                            if (apptCount == 0) {
                                // Không có cuộc hẹn -> Xóa ca cũ một cách an toàn
                                String deleteSql = "DELETE FROM Doctor_Schedule WHERE schedule_id = ?";
                                try (PreparedStatement delete = connection.prepareStatement(deleteSql)) {
                                    delete.setInt(1, oldScheduleId);
                                    delete.executeUpdate();
                                }
                            } else {
                                // Có cuộc hẹn -> Bỏ qua không chèn dòng mới để bảo toàn dữ liệu bệnh nhân
                                continue;
                            }
                        } else {
                            // conflictHandling là "skip" -> Bỏ qua
                            continue;
                        }
                    }

                    // 2. Chèn ca trực mới
>>>>>>> Stashed changes
                    try (PreparedStatement insert = connection.prepareStatement(insertSql)) {
                        insert.setInt(1, doctorId);
                        insert.setDate(2, workDate);
                        insert.setString(3, timeSlot);
                        insert.setInt(4, maxPatients);
                        if (hasOnlineQuota) {
                            insert.setInt(5, scheduleRepository.getDefaultOnlineQuota(maxPatients));
                        }
                        insert.executeUpdate();
                    }
                }
                connection.commit();
                return true;
            } catch (SQLException e) {
                connection.rollback();
                throw e;
            } finally {
                connection.setAutoCommit(true);
            }
        }
    }
<<<<<<< Updated upstream
=======

    private List<String> getActiveDoctorRooms(Connection conn) throws SQLException {
        List<String> rooms = new ArrayList<>();
        String sql = "SELECT room_id FROM Room "
                   + "WHERE LOWER(status) = 'active' "
                   + "  AND room_id NOT IN ('R101') "
                   + "  AND LOWER(room_name) NOT LIKE N'%xét nghiệm%' "
                   + "  AND LOWER(room_name) NOT LIKE N'%lab%' "
                   + "  AND LOWER(room_name) NOT LIKE N'%quầy%' "
                   + "ORDER BY room_id ASC";
        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                rooms.add(rs.getString("room_id"));
            }
        }
        if (rooms.isEmpty()) {
            rooms.add("R102");
            rooms.add("R103");
        }
        return rooms;
    }
>>>>>>> Stashed changes
}

