package com.diabetes.monitoring.admin.common;

import com.diabetes.monitoring.model.User;
import com.diabetes.monitoring.util.DatabaseConnection;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
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
 * Shared JDBC repository for Admin dashboard, management, scheduling, and reporting data.
 */
public class AdminRepository {

    private static final Logger LOGGER = Logger.getLogger(AdminRepository.class.getName());
    private static final int MAX_PATIENTS_HARD_CEILING = 50;
    private static final int MAX_SHIFTS_PER_DOCTOR_PER_DAY = 2;

    private static final Set<String> ALLOWED_ROLES = new HashSet<>();
    private static final Set<String> ALLOWED_ACCOUNT_STATUS = new HashSet<>();
    private static final Set<String> ALLOWED_SERVICE_TYPES = new HashSet<>();
    private static final Set<String> ALLOWED_SERVICE_STATUS = new HashSet<>();
    private static final Set<String> ALLOWED_SCHEDULE_STATUS = new HashSet<>();
    private static final Set<String> ALLOWED_BOOKING_SOURCES = new HashSet<>();
    private final ThreadLocal<String> scheduleValidationMessage = ThreadLocal.withInitial(() -> "");

    static {
        ALLOWED_ROLES.add("patient");
        ALLOWED_ROLES.add("doctor");
        ALLOWED_ROLES.add("doctor_lab");
        ALLOWED_ROLES.add("receptionist");
        ALLOWED_ROLES.add("admin");

        ALLOWED_ACCOUNT_STATUS.add("active");
        ALLOWED_ACCOUNT_STATUS.add("locked");

        ALLOWED_SERVICE_TYPES.add("Examination");
        ALLOWED_SERVICE_TYPES.add("Lab_Test");

        ALLOWED_SERVICE_STATUS.add("Active");
        ALLOWED_SERVICE_STATUS.add("Inactive");

        ALLOWED_SCHEDULE_STATUS.add("Available");
        ALLOWED_SCHEDULE_STATUS.add("Full");
        ALLOWED_SCHEDULE_STATUS.add("Cancelled");
        ALLOWED_SCHEDULE_STATUS.add("Expired");
        ALLOWED_SCHEDULE_STATUS.add("Pending");

        ALLOWED_BOOKING_SOURCES.add("Online");
        ALLOWED_BOOKING_SOURCES.add("Receptionist");
        ALLOWED_BOOKING_SOURCES.add("Admin");
        ALLOWED_BOOKING_SOURCES.add("Walk_In");
        ALLOWED_BOOKING_SOURCES.add("Emergency_Routing");
    }

    // =========================
    // KHU VỰC TỔNG QUAN DASHBOARD
    // =========================

    // Kiểm tra role có nằm trong danh sách vai trò hợp lệ của hệ thống hay không.
    public boolean isAllowedRole(String role) {
        return normalizeRole(role) != null;
    }

    // Kiểm tra trạng thái tài khoản có được phép dùng trong admin hay không.
    public boolean isAllowedAccountStatus(String status) {
        return normalizeAccountStatus(status) != null;
    }

    // Đếm tổng số tài khoản trong hệ thống.
    public int getCountTotalAccounts() {
        return executeCount("SELECT COUNT(*) FROM Account");
    }

    // Đếm số tài khoản đang hoạt động.
    public int getCountActiveAccounts() {
        return executeCount("SELECT COUNT(*) FROM Account WHERE LOWER(status) = 'active'");
    }

    // Đếm số tài khoản bị khóa.
    public int getCountLockedAccounts() {
        return executeCount("SELECT COUNT(*) FROM Account WHERE LOWER(status) = 'locked'");
    }

    // Đếm tổng số dịch vụ y tế đang tồn tại.
    public int getCountTotalServices() {
        return executeCount("SELECT COUNT(*) FROM Medical_Service WHERE status = 'Active'");
    }

    // Tính tổng doanh thu đã thanh toán.
    public BigDecimal getSumPaidRevenue() {
        // Lấy tổng doanh thu đã thanh toán từ đầu năm đến hôm nay (không tính tương lai)
        return executeBigDecimal("SELECT ISNULL(SUM(final_amount), 0) FROM Invoice WHERE status = 'Paid' AND CAST(created_at AS DATE) <= CAST(GETDATE() AS DATE)");
    }

    // Đếm tổng số lượt khám đã hoàn tất.
    public int getCountCompletedAppointments() {
        return executeCount("SELECT COUNT(*) FROM Appointment WHERE LOWER(status) = 'completed'");
    }

    // Lấy chuỗi dữ liệu doanh thu cho biểu đồ dashboard.
    public List<Map<String, Object>> getDashboardRevenueSeries(String granularity) {
        return getDashboardSeries("Invoice", "created_at", "final_amount", "status", "Paid", true, granularity);
    }

    // Lấy chuỗi dữ liệu lượt khám cho biểu đồ dashboard.
    public List<Map<String, Object>> getDashboardVisitSeries(String granularity) {
        String timeColumn = hasColumn("Appointment", "created_at") ? "created_at" : "appointment_time";
        return getDashboardSeries("Appointment", timeColumn, "appointment_id", "status", "Completed", false, granularity);
    }

    // Lấy số bệnh nhân đang chờ theo từng bác sĩ trong ngày hôm nay.
    public List<Map<String, Object>> getTodayClinicQueueStatus() {
        markLateWaitingAppointmentsAsNoShow();

        List<Map<String, Object>> rows = new ArrayList<>();
        String sql = "SELECT d.doctor_id, d.full_name AS doctor_name, d.department, "
                + "COUNT(a.appointment_id) AS waiting_count "
                + "FROM Doctor_Schedule ds "
                + "JOIN Doctor d ON d.doctor_id = ds.doctor_id "
            + "LEFT JOIN Appointment a ON a.schedule_id = ds.schedule_id AND LOWER(a.status) = 'checked_in' "
                + "WHERE ds.work_date = CAST(GETDATE() AS DATE) "
                + "AND LOWER(ds.status) <> 'cancelled' "
                + "GROUP BY d.doctor_id, d.full_name, d.department "
                + "ORDER BY waiting_count DESC, d.full_name ASC";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("doctorId", rs.getInt("doctor_id"));
                row.put("doctorName", rs.getString("doctor_name"));
                row.put("department", rs.getString("department"));
                row.put("waitingCount", rs.getInt("waiting_count"));
                rows.add(row);
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load today clinic queue status", e);
        }

        return rows;
    }

    // Lấy chi tiết hàng đợi hôm nay của một bác sĩ cụ thể.
    public List<Map<String, Object>> getDoctorQueueDetailToday(int doctorId) {
        markLateWaitingAppointmentsAsNoShow();

        List<Map<String, Object>> rows = new ArrayList<>();
        String sql = "SELECT a.appointment_id, p.full_name, "
                + "FORMAT(a.appointment_time, 'HH:mm') AS appointment_time, a.status "
                + "FROM Appointment a "
                + "JOIN Patient p ON a.patient_id = p.patient_id "
                + "WHERE a.doctor_id = ? "
            + "AND LOWER(a.status) IN ('checked_in', 'in_progress', 'in-progress') "
                + "AND CAST(a.appointment_time AS DATE) = CAST(GETDATE() AS DATE) "
                + "ORDER BY a.appointment_time ASC, a.appointment_id ASC";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, doctorId);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("appointmentId", rs.getInt("appointment_id"));
                    row.put("patientName", rs.getString("full_name"));
                    row.put("appointmentTime", rs.getString("appointment_time"));
                    row.put("status", rs.getString("status"));
                    rows.add(row);
                }
            }
            return rows;
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Primary queue-detail query failed; fallback to Account join", e);
        }

        String fallbackSql = "SELECT a.appointment_id, acc.full_name, "
                + "FORMAT(a.appointment_time, 'HH:mm') AS appointment_time, a.status "
                + "FROM Appointment a "
                + "JOIN Account acc ON a.patient_id = acc.account_id "
                + "WHERE a.doctor_id = ? "
            + "AND LOWER(a.status) IN ('checked_in', 'in_progress', 'in-progress') "
                + "AND CAST(a.appointment_time AS DATE) = CAST(GETDATE() AS DATE) "
                + "ORDER BY a.appointment_time ASC, a.appointment_id ASC";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(fallbackSql)) {
            statement.setInt(1, doctorId);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("appointmentId", rs.getInt("appointment_id"));
                    row.put("patientName", rs.getString("full_name"));
                    row.put("appointmentTime", rs.getString("appointment_time"));
                    row.put("status", rs.getString("status"));
                    rows.add(row);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load queue detail for doctorId=" + doctorId, e);
        }

        return rows;
    }

    // Đếm số lượt khám thực sự đã diễn ra trong hôm nay.
    public int getTodayTotalVisits() {
        return executeCount("SELECT COUNT(*) FROM Appointment WHERE LOWER(status) = 'completed' AND CAST(appointment_time AS DATE) = CAST(GETDATE() AS DATE) AND appointment_time <= GETDATE()");
    }

    // Chuẩn hóa dữ liệu cũ: nếu lịch hẹn ở tương lai nhưng status completed thì kéo về Waiting.
    public int normalizeFutureCompletedAppointments() {
        String sql = "UPDATE Appointment "
                + "SET status = 'Waiting' "
                + "WHERE LOWER(status) = 'completed' "
                + "AND appointment_time > GETDATE()";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            int updated = statement.executeUpdate();
            if (updated > 0) {
                LOGGER.log(Level.INFO, "Normalized future completed appointments to Waiting: {0}", updated);
            }
            return updated;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to normalize future completed appointments", e);
            return 0;
        }
    }

    /**
     * Marks late Waiting appointments as Absent after the schedule cutoff time.
     */
    public int markLateWaitingAppointmentsAsNoShow() {
        String sql = "UPDATE a SET a.status = 'Absent' "
            + "FROM Appointment a "
            + "INNER JOIN Doctor_Schedule ds ON ds.schedule_id = a.schedule_id "
            + "WHERE LOWER(a.status) = 'waiting' "
            + "AND DATEADD(SECOND, DATEDIFF(SECOND, CAST('00:00:00' AS time), "
            + "TRY_CONVERT(time, RIGHT(REPLACE(ds.time_slot, ' ', ''), 5))), "
            + "CAST(CAST(a.appointment_time AS date) AS datetime)) < GETDATE()";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            int updated = statement.executeUpdate();
            if (updated > 0) {
                LOGGER.log(Level.INFO, "Auto-marked late waiting appointments as Absent: {0}", updated);
            }
            return updated;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to mark late waiting appointments as Absent", e);
            return 0;
        }
    }

    // Demo: tự động đẩy workflow Appointment theo mốc thời gian để mô phỏng lễ tân/bác sĩ.
    public int autoAdvanceAppointmentWorkflowDemo() {
        int totalUpdated = 0;

        try (Connection connection = DatabaseConnection.getConnection()) {
            // Step 0: Chuẩn hóa dữ liệu cũ từ In-Progress -> In_Progress để đồng bộ dashboard
            String normalizeSql = "UPDATE Appointment "
                    + "SET status = 'In_Progress' "
                    + "WHERE LOWER(status) = 'in-progress'";
            try (PreparedStatement normalizeStmt = connection.prepareStatement(normalizeSql)) {
                int normalized = normalizeStmt.executeUpdate();
                totalUpdated += normalized;
                if (normalized > 0) {
                    LOGGER.log(Level.INFO, "[DEMO] Normalized in-progress -> In_Progress: {0} appointments", normalized);
                }
            }

                // Step 1: Waiting -> Checked_In khi đến giờ hẹn.
            String waitingToCheckedInSql = "UPDATE Appointment "
                    + "SET status = 'Checked_In' "
                    + "WHERE LOWER(status) = 'waiting' "
                    + "AND appointment_time <= GETDATE()";
            try (PreparedStatement stmt = connection.prepareStatement(waitingToCheckedInSql)) {
                int updated = stmt.executeUpdate();
                totalUpdated += updated;
                if (updated > 0) {
                    LOGGER.log(Level.INFO, "[DEMO] Auto-transitioned Waiting -> Checked_In: {0} appointments", updated);
                }
            }

                // Step 2: Checked_In -> In_Progress sau 30 phút.
            String checkedInToInProgressSql = "UPDATE Appointment "
                    + "SET status = 'In_Progress' "
                    + "WHERE LOWER(status) = 'checked_in' "
                    + "AND DATEADD(MINUTE, 30, appointment_time) <= GETDATE()";
            try (PreparedStatement stmt = connection.prepareStatement(checkedInToInProgressSql)) {
                int updated = stmt.executeUpdate();
                totalUpdated += updated;
                if (updated > 0) {
                    LOGGER.log(Level.INFO, "[DEMO] Auto-transitioned Checked_In -> In_Progress: {0} appointments", updated);
                }
            }

                // Step 3: In_Progress -> Completed sau 1 giờ.
            String inProgressToCompletedSql = "UPDATE Appointment "
                    + "SET status = 'Completed' "
                    + "WHERE LOWER(status) = 'in_progress' "
                    + "AND DATEADD(HOUR, 1, appointment_time) <= GETDATE()";
            try (PreparedStatement stmt = connection.prepareStatement(inProgressToCompletedSql)) {
                int updated = stmt.executeUpdate();
                totalUpdated += updated;
                if (updated > 0) {
                    LOGGER.log(Level.INFO, "[DEMO] Auto-transitioned In_Progress -> Completed: {0} appointments", updated);
                }
            }

            if (totalUpdated > 0) {
                LOGGER.log(Level.INFO, "[DEMO] Total auto-transitioned appointments: {0}", totalUpdated);
            }
            return totalUpdated;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "[DEMO] Failed to auto-transition appointment statuses", e);
            return 0;
        }
    }

    // Wrapper tương thích với các chỗ gọi cũ.
    public int autoTransitionAppointmentStatuses() {
        return autoAdvanceAppointmentWorkflowDemo();
    }

    /**
     * Moves an appointment from Waiting to Checked_In.
     */
    public boolean checkInAppointment(int appointmentId) {
        return updateAppointmentStatus(appointmentId, "Checked_In", "Waiting");
    }

    /**
     * Moves an appointment from Checked_In to In_Progress.
     */
    public boolean startAppointment(int appointmentId) {
        return updateAppointmentStatus(appointmentId, "In_Progress", "Checked_In");
    }

    /**
     * Moves an appointment from In_Progress to Completed.
     */
    public boolean completeAppointment(int appointmentId) {
        return updateAppointmentStatus(appointmentId, "Completed", "In_Progress", "In-Progress");
    }

    // Cập nhật trạng thái lịch hẹn với ràng buộc trạng thái đầu vào cho phép.
    private boolean updateAppointmentStatus(int appointmentId, String newStatus, String... allowedCurrentStatuses) {
        if (appointmentId <= 0 || newStatus == null || newStatus.trim().isEmpty()) {
            return false;
        }

        StringBuilder sql = new StringBuilder("UPDATE Appointment SET status = ? WHERE appointment_id = ?");
        if (allowedCurrentStatuses != null && allowedCurrentStatuses.length > 0) {
            sql.append(" AND LOWER(status) IN (");
            for (int i = 0; i < allowedCurrentStatuses.length; i++) {
                if (i > 0) {
                    sql.append(", ");
                }
                sql.append("?");
            }
            sql.append(")");
        }

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            int index = 1;
            statement.setString(index++, newStatus);
            statement.setInt(index++, appointmentId);
            if (allowedCurrentStatuses != null && allowedCurrentStatuses.length > 0) {
                for (String allowedStatus : allowedCurrentStatuses) {
                    statement.setString(index++, allowedStatus == null ? null : allowedStatus.toLowerCase(Locale.ROOT).replace('-', '_'));
                }
            }
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to update appointment status for appointmentId=" + appointmentId + " to " + newStatus, e);
            return false;
        }
    }

    // Đếm số bệnh nhân đang chờ khám trong ngày hôm nay.
    public int getTodayWaitingPatients() {
        markLateWaitingAppointmentsAsNoShow();
        return executeCount("SELECT COUNT(*) FROM Appointment WHERE LOWER(status) = 'checked_in' AND CAST(appointment_time AS DATE) = CAST(GETDATE() AS DATE)");
    }

    // Lấy danh sách các lượt khám đã hoàn tất trong ngày hôm nay.
    public List<Map<String, Object>> getTodayAppointments() {
        markLateWaitingAppointmentsAsNoShow();

        List<Map<String, Object>> rows = new ArrayList<>();
        String sql = "SELECT a.appointment_id, "
                + "COALESCE(p.full_name, acc.full_name, N'Chưa xác định') AS patient_name, "
                + "COALESCE(d.full_name, N'Chưa phân công') AS doctor_name, "
                + "FORMAT(a.appointment_time, 'dd/MM/yyyy') AS appointment_date, "
                + "FORMAT(a.appointment_time, 'HH:mm') AS appointment_time, "
                + "a.status "
                + "FROM Appointment a "
                + "LEFT JOIN Patient p ON p.patient_id = a.patient_id "
                + "LEFT JOIN Account acc ON acc.account_id = a.patient_id "
                + "LEFT JOIN Doctor d ON d.doctor_id = a.doctor_id "
                + "WHERE CAST(a.appointment_time AS DATE) = CAST(GETDATE() AS DATE) "
                + "AND LOWER(a.status) = 'completed' "
                + "AND a.appointment_time <= GETDATE() "
                + "ORDER BY a.appointment_time ASC, a.appointment_id ASC";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("appointmentId", rs.getInt("appointment_id"));
                row.put("patientName", rs.getString("patient_name"));
                row.put("doctorName", rs.getString("doctor_name"));
                row.put("appointmentDate", rs.getString("appointment_date"));
                row.put("appointmentTime", rs.getString("appointment_time"));
                row.put("status", rs.getString("status"));
                rows.add(row);
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load today appointments", e);
        }

        return rows;
    }

    // Lấy chi tiết danh sách bệnh nhân đang chờ để hiển thị ở modal dashboard.
    public List<Map<String, Object>> getTodayWaitingDetails() {
        markLateWaitingAppointmentsAsNoShow();

        List<Map<String, Object>> rows = new ArrayList<>();
        String sql = "SELECT a.appointment_id, "
                + "COALESCE(p.full_name, acc.full_name, N'Chưa xác định') AS patient_name, "
                + "COALESCE(d.department, dsd.department, N'Chưa xác định') AS department, "
                + "FORMAT(a.appointment_time, 'HH:mm') AS appointment_time, "
                + "a.status, "
                + "CASE WHEN DATEDIFF(MINUTE, a.appointment_time, GETDATE()) < 0 THEN 0 "
                + "ELSE DATEDIFF(MINUTE, a.appointment_time, GETDATE()) END AS waiting_minutes "
                + "FROM Appointment a "
                + "LEFT JOIN Patient p ON p.patient_id = a.patient_id "
                + "LEFT JOIN Account acc ON acc.account_id = a.patient_id "
                + "LEFT JOIN Doctor d ON d.doctor_id = a.doctor_id "
                + "LEFT JOIN Doctor_Schedule ds ON ds.schedule_id = a.schedule_id "
                + "LEFT JOIN Doctor dsd ON dsd.doctor_id = ds.doctor_id "
                + "WHERE LOWER(a.status) = 'checked_in' "
                + "AND CAST(a.appointment_time AS DATE) = CAST(GETDATE() AS DATE) "
                + "ORDER BY a.appointment_time ASC, a.appointment_id ASC";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("appointmentId", rs.getInt("appointment_id"));
                row.put("patientName", rs.getString("patient_name"));
                row.put("department", rs.getString("department"));
                row.put("appointmentTime", rs.getString("appointment_time"));
                row.put("status", rs.getString("status"));
                row.put("waitingMinutes", rs.getInt("waiting_minutes"));
                rows.add(row);
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load today waiting details", e);
        }

        return rows;
    }

    // Thống kê lượt khám theo từng khung giờ trong ngày.
    public List<Map<String, Object>> getTodayPatientFlowByTimeSlot() {
        List<Map<String, Object>> rows = new ArrayList<>();

        String sql = "WITH slot_template AS ("
            + "    SELECT CAST('07:00' AS time) AS slot_start, CAST('09:00' AS time) AS slot_end, '07:00-09:00' AS time_slot "
            + "    UNION ALL SELECT CAST('09:00' AS time), CAST('11:00' AS time), '09:00-11:00' "
            + "    UNION ALL SELECT CAST('11:00' AS time), CAST('13:00' AS time), '11:00-13:00' "
            + "    UNION ALL SELECT CAST('13:00' AS time), CAST('15:00' AS time), '13:00-15:00' "
            + "    UNION ALL SELECT CAST('15:00' AS time), CAST('17:00' AS time), '15:00-17:00' "
            + "    UNION ALL SELECT CAST('17:00' AS time), CAST('19:00' AS time), '17:00-19:00' "
            + "    UNION ALL SELECT CAST('19:00' AS time), CAST('21:00' AS time), '19:00-21:00' "
            + "    UNION ALL SELECT CAST('21:00' AS time), CAST('23:00' AS time), '21:00-23:00' "
            + ") "
            + "SELECT st.time_slot, COUNT(a.appointment_id) AS visit_count "
            + "FROM slot_template st "
            + "LEFT JOIN Doctor_Schedule ds "
            + "       ON ds.work_date = CAST(GETDATE() AS DATE) "
            + "      AND LOWER(ISNULL(ds.status, '')) <> 'cancelled' "
            + "      AND TRY_CAST(LEFT(REPLACE(ds.time_slot, ' ', ''), 5) AS time) >= st.slot_start "
            + "      AND TRY_CAST(LEFT(REPLACE(ds.time_slot, ' ', ''), 5) AS time) < st.slot_end "
            + "LEFT JOIN Appointment a "
            + "       ON a.schedule_id = ds.schedule_id "
            + "      AND LOWER(a.status) = 'completed' "
            + "      AND CAST(a.appointment_time AS DATE) = CAST(GETDATE() AS DATE) "
            + "      AND a.appointment_time <= GETDATE() "
            + "GROUP BY st.slot_start, st.time_slot "
            + "ORDER BY st.slot_start";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("timeSlot", rs.getString("time_slot"));
                row.put("visitCount", rs.getInt("visit_count"));
                rows.add(row);
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load today patient flow by hourly slot", e);
        }

        return rows;
    }

    // Thống kê doanh thu hôm nay theo loại dịch vụ khám/xét nghiệm.
    public List<Map<String, Object>> getTodayRevenueByServiceType() {
        List<Map<String, Object>> rows = new ArrayList<>();
        String sql = "SELECT "
                + "COALESCE(SUM(CASE WHEN ms.service_type = 'Examination' THEN id.quantity * id.price ELSE 0 END), 0) AS exam_revenue, "
                + "COALESCE(SUM(CASE WHEN ms.service_type = 'Lab_Test' THEN id.quantity * id.price ELSE 0 END), 0) AS lab_revenue "
                + "FROM Invoice i "
                + "JOIN Invoice_Detail id ON id.invoice_id = i.invoice_id "
                + "JOIN Medical_Service ms ON ms.service_id = id.service_id "
                + "WHERE LOWER(i.status) = 'paid' "
                + "AND CAST(i.created_at AS DATE) <= CAST(GETDATE() AS DATE)";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {
            if (rs.next()) {
                Map<String, Object> exam = new HashMap<>();
                exam.put("serviceType", "Examination");
                exam.put("totalRevenue", rs.getBigDecimal("exam_revenue"));
                rows.add(exam);

                Map<String, Object> lab = new HashMap<>();
                lab.put("serviceType", "Lab_Test");
                lab.put("totalRevenue", rs.getBigDecimal("lab_revenue"));
                rows.add(lab);
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load today revenue by service type", e);
        }

        return rows;
    }

    // Thống kê phân bố trạng thái ca khám hôm nay.
    public List<Map<String, Object>> getTodayAppointmentStatusDistribution() {
        markLateWaitingAppointmentsAsNoShow();

        List<Map<String, Object>> rows = new ArrayList<>();
        String sql = "SELECT CASE "
                + "WHEN LOWER(ap.status) = 'checked_in' THEN 'Checked_In' "
                + "WHEN LOWER(ap.status) IN ('in_progress', 'in-progress') THEN 'In_Progress' "
                + "WHEN LOWER(ap.status) = 'absent' THEN 'Absent' "
                + "WHEN LOWER(ap.status) = 'waiting' THEN 'Waiting' "
                + "WHEN LOWER(ap.status) = 'completed' THEN 'Completed' "
                + "WHEN LOWER(ap.status) IN ('cancelled', 'canceled') THEN 'Cancelled' "
                + "ELSE ap.status END AS status, "
                + "COUNT(ap.appointment_id) AS total_count "
                + "FROM Appointment ap "
                + "WHERE CAST(ap.appointment_time AS DATE) = CAST(GETDATE() AS DATE) "
                + "AND LOWER(ap.status) IN ('waiting', 'checked_in', 'in_progress', 'in-progress', 'completed', 'absent', 'cancelled', 'canceled') "
                + "GROUP BY CASE "
                + "WHEN LOWER(ap.status) = 'checked_in' THEN 'Checked_In' "
                + "WHEN LOWER(ap.status) IN ('in_progress', 'in-progress') THEN 'In_Progress' "
                + "WHEN LOWER(ap.status) = 'absent' THEN 'Absent' "
                + "WHEN LOWER(ap.status) = 'waiting' THEN 'Waiting' "
                + "WHEN LOWER(ap.status) = 'completed' THEN 'Completed' "
                + "WHEN LOWER(ap.status) IN ('cancelled', 'canceled') THEN 'Cancelled' "
                + "ELSE ap.status END";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("status", rs.getString("status"));
                row.put("totalCount", rs.getInt("total_count"));
                rows.add(row);
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load today appointment status distribution", e);
        }

        return rows;
    }

    // Lấy tổng hợp KPI cho dashboard admin.
    public Map<String, Object> getDashboardSummary() {
        Map<String, Object> summary = new HashMap<>();
        summary.put("totalAccounts", 0);
        summary.put("activeAccounts", 0);
        summary.put("lockedAccounts", 0);
        summary.put("totalServices", 0);
        summary.put("activeServices", 0);
        summary.put("totalSchedules", 0);
        summary.put("fullSchedules", 0);
        summary.put("totalRevenuePaid", BigDecimal.ZERO);
        summary.put("completedVisits", 0);

        String sql = "SELECT "
                + "(SELECT COUNT(*) FROM Account) AS total_accounts, "
                + "(SELECT COUNT(*) FROM Account WHERE LOWER(status) = 'active') AS active_accounts, "
                + "(SELECT COUNT(*) FROM Account WHERE LOWER(status) = 'locked') AS locked_accounts, "
                + "(SELECT COUNT(*) FROM Medical_Service) AS total_services, "
                + "(SELECT COUNT(*) FROM Medical_Service WHERE LOWER(status) = 'active') AS active_services, "
                + "(SELECT COUNT(*) FROM Doctor_Schedule) AS total_schedules, "
                + "(SELECT COUNT(*) FROM Doctor_Schedule WHERE LOWER(status) = 'full') AS full_schedules, "
                + "(SELECT COALESCE(SUM(final_amount), 0) FROM Invoice WHERE LOWER(status) = 'paid') AS total_revenue, "
                + "(SELECT COUNT(*) FROM Appointment WHERE LOWER(status) = 'completed') AS completed_visits";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {
            if (rs.next()) {
                summary.put("totalAccounts", rs.getInt("total_accounts"));
                summary.put("activeAccounts", rs.getInt("active_accounts"));
                summary.put("lockedAccounts", rs.getInt("locked_accounts"));
                summary.put("totalServices", rs.getInt("total_services"));
                summary.put("activeServices", rs.getInt("active_services"));
                summary.put("totalSchedules", rs.getInt("total_schedules"));
                summary.put("fullSchedules", rs.getInt("full_schedules"));
                summary.put("totalRevenuePaid", rs.getBigDecimal("total_revenue"));
                summary.put("completedVisits", rs.getInt("completed_visits"));
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load admin dashboard summary", e);
        }
        return summary;
    }

    // Lấy dữ liệu theo tháng để vẽ biểu đồ doanh thu và lượt khám.
    public List<Map<String, Object>> getMonthlyRevenueAndVisitsSeries(int monthBackInclusive) {
        List<Map<String, Object>> rows = new ArrayList<>();

        String sql = "WITH month_base AS ("
                + "    SELECT FORMAT(DATEADD(MONTH, -v.num, GETDATE()), 'yyyy-MM') AS month_key "
                + "    FROM (SELECT TOP (?) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS num FROM sys.all_objects) v"
                + "), revenue AS ("
                + "    SELECT FORMAT(created_at, 'yyyy-MM') AS month_key, SUM(final_amount) AS total_revenue "
                + "    FROM Invoice WHERE LOWER(status) = 'paid' AND CAST(created_at AS DATE) <= CAST(GETDATE() AS DATE) "
                + "    GROUP BY FORMAT(created_at, 'yyyy-MM')"
                + "), visits AS ("
                + "    SELECT FORMAT(appointment_time, 'yyyy-MM') AS month_key, COUNT(appointment_id) AS completed_visits "
                + "    FROM Appointment WHERE LOWER(status) = 'completed' AND CAST(appointment_time AS DATE) <= CAST(GETDATE() AS DATE) "
                + "    GROUP BY FORMAT(appointment_time, 'yyyy-MM')"
                + ") "
                + "SELECT mb.month_key, "
                + "       COALESCE(r.total_revenue, 0) AS total_revenue, "
                + "       COALESCE(v.completed_visits, 0) AS completed_visits "
                + "FROM month_base mb "
                + "LEFT JOIN revenue r ON r.month_key = mb.month_key "
                + "LEFT JOIN visits v ON v.month_key = mb.month_key "
                + "WHERE mb.month_key <= FORMAT(GETDATE(), 'yyyy-MM') "
                + "ORDER BY mb.month_key";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, Math.max(monthBackInclusive, 1));
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("month", rs.getString("month_key"));
                    row.put("revenue", rs.getBigDecimal("total_revenue"));
                    row.put("visits", rs.getInt("completed_visits"));
                    rows.add(row);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load monthly series", e);
        }

        return rows;
    }

    // =========================
    // KHU VỰC QUẢN LÝ TÀI KHOẢN
    // =========================

    // Lấy danh sách tài khoản theo bộ lọc tìm kiếm/role/status.
    public List<User> getAccounts(String search, String role, String status) {
        List<User> users = new ArrayList<>();
        StringBuilder sql = new StringBuilder("SELECT account_id, full_name, email, role, status, created_at FROM Account WHERE 1=1");
        List<Object> params = new ArrayList<>();

        if (search != null && !search.trim().isEmpty()) {
            sql.append(" AND (full_name LIKE ? OR email LIKE ?)");
            params.add("%" + search.trim() + "%");
            params.add("%" + search.trim() + "%");
        }

        String normalizedRole = normalizeRole(role);
        if (normalizedRole != null) {
            sql.append(" AND LOWER(role) = ?");
            params.add(normalizedRole.toLowerCase(Locale.ROOT));
        }

        String normalizedStatus = normalizeAccountStatus(status);
        if (normalizedStatus != null) {
            sql.append(" AND LOWER(status) = ?");
            params.add(normalizedStatus.toLowerCase(Locale.ROOT));
        }

        sql.append(" ORDER BY created_at DESC, account_id DESC");

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            bindParams(statement, params);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    User user = new User();
                    user.setId(rs.getInt("account_id"));
                    user.setFullName(rs.getString("full_name"));
                    user.setEmail(rs.getString("email"));
                    user.setRole(toTitleCase(rs.getString("role")));
                    user.setStatus(toTitleCase(rs.getString("status")));
                    user.setCreatedAt(rs.getTimestamp("created_at"));
                    users.add(user);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to get admin account list", e);
        }
        return users;
    }

    // =========================
    // KHU VỰC QUẢN LÝ DỊCH VỤ
    // =========================

    // Tạo tài khoản mới cho admin, receptionist, doctor hoặc patient.
    public boolean createAccount(String fullName, String email, String passwordHash, String role, String status) {
        String normalizedRole = normalizeRole(role);
        String normalizedStatus = normalizeAccountStatus(status);

        if (normalizedRole == null || normalizedStatus == null) {
            return false;
        }

        if (isAccountEmailExists(email)) {
            return false;
        }

        String sql = "INSERT INTO Account (full_name, email, password_hash, role, status) VALUES (?, ?, ?, ?, ?)";
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, fullName);
            statement.setString(2, email);
            statement.setString(3, passwordHash);
            statement.setString(4, normalizedRole);
            statement.setString(5, normalizedStatus);
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to create account", e);
            return false;
        }
    }

    // Kiểm tra email tài khoản đã tồn tại hay chưa (không phân biệt hoa thường).
    public boolean isAccountEmailExists(String email) {
        if (email == null || email.isBlank()) {
            return false;
        }

        String sql = "SELECT COUNT(*) FROM Account WHERE LOWER(email) = LOWER(?)";
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, email.trim());
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to check duplicate account email", e);
            return false;
        }
    }

    // Cập nhật role của tài khoản.
    public boolean updateAccountRole(int accountId, String role) {
        String normalizedRole = normalizeRole(role);
        if (normalizedRole == null) {
            return false;
        }

        String sql = "UPDATE Account SET role = ? WHERE account_id = ?";
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, normalizedRole);
            statement.setInt(2, accountId);
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to update account role", e);
            return false;
        }
    }

    // Khóa hoặc kích hoạt lại tài khoản.
    public boolean updateAccountStatus(int accountId, String status) {
        String normalizedStatus = normalizeAccountStatus(status);
        if (normalizedStatus == null) {
            return false;
        }

        String sql = "UPDATE Account SET status = ? WHERE account_id = ?";
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, normalizedStatus);
            statement.setInt(2, accountId);
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to update account status", e);
            return false;
        }
    }

    // Xóa tài khoản (không áp dụng cho bác sĩ); rollback nếu có ràng buộc dữ liệu.
    public boolean deleteAccountForAdmin(int accountId) {
        if (accountId <= 0) {
            return false;
        }

        String sqlGetRole = "SELECT role FROM Account WHERE account_id = ?";
        String sqlDeletePatient = "DELETE FROM Patient WHERE account_id = ? OR patient_id = ?";
        String sqlDeleteAccount = "DELETE FROM Account WHERE account_id = ?";

        try (Connection connection = DatabaseConnection.getConnection()) {
            connection.setAutoCommit(false);
            try {
                String role;
                try (PreparedStatement roleStmt = connection.prepareStatement(sqlGetRole)) {
                    roleStmt.setInt(1, accountId);
                    try (ResultSet rs = roleStmt.executeQuery()) {
                        if (!rs.next()) {
                            connection.rollback();
                            return false;
                        }
                        role = normalizeRole(rs.getString("role"));
                    }
                }

                if ("Doctor".equalsIgnoreCase(role)) {
                    connection.rollback();
                    return false;
                }

                if ("Patient".equalsIgnoreCase(role)) {
                    try (PreparedStatement patientStmt = connection.prepareStatement(sqlDeletePatient)) {
                        patientStmt.setInt(1, accountId);
                        patientStmt.setInt(2, accountId);
                        patientStmt.executeUpdate();
                    }
                }

                try (PreparedStatement accountStmt = connection.prepareStatement(sqlDeleteAccount)) {
                    accountStmt.setInt(1, accountId);
                    if (accountStmt.executeUpdate() <= 0) {
                        connection.rollback();
                        return false;
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
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to delete account", e);
            return false;
        }
    }

    // Lấy hồ sơ chi tiết tài khoản để admin chỉnh sửa theo vai trò.
    public Map<String, Object> getAccountProfileForAdminEdit(int accountId) {
        Map<String, Object> profile = new HashMap<>();
        String sqlAccount = "SELECT account_id, full_name, email, role FROM Account WHERE account_id = ?";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement accountStmt = connection.prepareStatement(sqlAccount)) {
            accountStmt.setInt(1, accountId);
            try (ResultSet accountRs = accountStmt.executeQuery()) {
                if (!accountRs.next()) {
                    return profile;
                }

                String role = toTitleCase(accountRs.getString("role"));
                profile.put("accountId", accountRs.getInt("account_id"));
                profile.put("fullName", accountRs.getString("full_name"));
                profile.put("email", accountRs.getString("email"));
                profile.put("role", role);
                profile.put("phone", "");
                profile.put("address", "");
                profile.put("department", "");

                if ("Patient".equals(role)) {
                    String sqlPatient = "SELECT TOP 1 phone, address FROM Patient WHERE account_id = ? OR patient_id = ?";
                    try (PreparedStatement patientStmt = connection.prepareStatement(sqlPatient)) {
                        patientStmt.setInt(1, accountId);
                        patientStmt.setInt(2, accountId);
                        try (ResultSet patientRs = patientStmt.executeQuery()) {
                            if (patientRs.next()) {
                                profile.put("phone", patientRs.getString("phone"));
                                profile.put("address", patientRs.getString("address"));
                            }
                        }
                    }
                } else if ("Doctor".equals(role)) {
                    String sqlDoctor = "SELECT TOP 1 phone, department FROM Doctor WHERE account_id = ? OR doctor_id = ?";
                    try (PreparedStatement doctorStmt = connection.prepareStatement(sqlDoctor)) {
                        doctorStmt.setInt(1, accountId);
                        doctorStmt.setInt(2, accountId);
                        try (ResultSet doctorRs = doctorStmt.executeQuery()) {
                            if (doctorRs.next()) {
                                profile.put("phone", doctorRs.getString("phone"));
                                profile.put("department", normalizeDepartmentForAi(doctorRs.getString("department")));
                            }
                        }
                    }
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load account profile for admin edit", e);
            profile.clear();
        }

        return profile;
    }

    // Cập nhật hồ sơ tài khoản theo vai trò: Account + Patient/Doctor nếu có.
    public boolean updateAccountProfileByRole(int accountId,
            String fullName,
            String email,
            String phone,
            String address,
            String department) {
        if (accountId <= 0 || fullName == null || fullName.isBlank() || email == null || email.isBlank()) {
            return false;
        }

        if (isAccountEmailExistsForOtherAccount(email, accountId)) {
            return false;
        }

        String sqlGetRole = "SELECT role FROM Account WHERE account_id = ?";
        String sqlUpdateAccount = "UPDATE Account SET full_name = ?, email = ? WHERE account_id = ?";
        String sqlUpdatePatientByAccount = "UPDATE Patient SET full_name = ?, email = ?, phone = ?, address = ? WHERE account_id = ?";
        String sqlUpdatePatientById = "UPDATE Patient SET full_name = ?, email = ?, phone = ?, address = ? WHERE patient_id = ?";
        String sqlUpdateDoctorByAccount = "UPDATE Doctor SET full_name = ?, email = ?, phone = ?, department = ? WHERE account_id = ?";
        String sqlUpdateDoctorById = "UPDATE Doctor SET full_name = ?, email = ?, phone = ?, department = ? WHERE doctor_id = ?";

        String cleanName = fullName.trim();
        String cleanEmail = email.trim();
        String cleanPhone = phone == null ? "" : phone.trim();
        String cleanAddress = address == null ? "" : address.trim();
        String normalizedDepartment = normalizeDepartmentForAi(department);

        try (Connection connection = DatabaseConnection.getConnection()) {
            connection.setAutoCommit(false);
            try {
                String role;
                try (PreparedStatement roleStmt = connection.prepareStatement(sqlGetRole)) {
                    roleStmt.setInt(1, accountId);
                    try (ResultSet rs = roleStmt.executeQuery()) {
                        if (!rs.next()) {
                            connection.rollback();
                            return false;
                        }
                        role = toTitleCase(rs.getString("role"));
                    }
                }

                try (PreparedStatement accountStmt = connection.prepareStatement(sqlUpdateAccount)) {
                    accountStmt.setString(1, cleanName);
                    accountStmt.setString(2, cleanEmail);
                    accountStmt.setInt(3, accountId);
                    if (accountStmt.executeUpdate() <= 0) {
                        connection.rollback();
                        return false;
                    }
                }

                if ("Patient".equals(role)) {
                    int updated;
                    try (PreparedStatement patientStmt = connection.prepareStatement(sqlUpdatePatientByAccount)) {
                        patientStmt.setString(1, cleanName);
                        patientStmt.setString(2, cleanEmail);
                        patientStmt.setString(3, cleanPhone);
                        patientStmt.setString(4, cleanAddress);
                        patientStmt.setInt(5, accountId);
                        updated = patientStmt.executeUpdate();
                    }
                    if (updated <= 0) {
                        try (PreparedStatement patientStmt = connection.prepareStatement(sqlUpdatePatientById)) {
                            patientStmt.setString(1, cleanName);
                            patientStmt.setString(2, cleanEmail);
                            patientStmt.setString(3, cleanPhone);
                            patientStmt.setString(4, cleanAddress);
                            patientStmt.setInt(5, accountId);
                            patientStmt.executeUpdate();
                        }
                    }
                } else if ("Doctor".equals(role)) {
                    int updated;
                    try (PreparedStatement doctorStmt = connection.prepareStatement(sqlUpdateDoctorByAccount)) {
                        doctorStmt.setString(1, cleanName);
                        doctorStmt.setString(2, cleanEmail);
                        doctorStmt.setString(3, cleanPhone);
                        doctorStmt.setString(4, normalizedDepartment);
                        doctorStmt.setInt(5, accountId);
                        updated = doctorStmt.executeUpdate();
                    }
                    if (updated <= 0) {
                        try (PreparedStatement doctorStmt = connection.prepareStatement(sqlUpdateDoctorById)) {
                            doctorStmt.setString(1, cleanName);
                            doctorStmt.setString(2, cleanEmail);
                            doctorStmt.setString(3, cleanPhone);
                            doctorStmt.setString(4, normalizedDepartment);
                            doctorStmt.setInt(5, accountId);
                            doctorStmt.executeUpdate();
                        }
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
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to update account profile by role", e);
            return false;
        }
    }

    // Lấy danh sách tài khoản dạng nhanh cho quick modal trên dashboard.
    public List<Map<String, Object>> getStaffAccountsQuick(String status, int limit) {
        List<Map<String, Object>> rows = new ArrayList<>();

        StringBuilder sql = new StringBuilder(
                "SELECT TOP (?) account_id, full_name, email, role, status, created_at "
                + "FROM Account "
                + "WHERE 1 = 1 "
        );

        String normalizedStatus = normalizeAccountStatus(status);

        if (normalizedStatus != null) {
            sql.append(" AND LOWER(status) = ? ");
        }

        sql.append(" ORDER BY created_at DESC, account_id DESC ");

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql.toString())) {

            int index = 1;
            statement.setInt(index++, Math.max(limit, 1));

            if (normalizedStatus != null) {
                statement.setString(index, normalizedStatus.toLowerCase(Locale.ROOT));
            }

            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("accountId", rs.getInt("account_id"));
                    row.put("fullName", rs.getString("full_name"));
                    row.put("email", rs.getString("email"));
                    row.put("role", rs.getString("role"));
                    row.put("status", rs.getString("status"));
                    row.put("createdAt", rs.getTimestamp("created_at"));
                    rows.add(row);
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load quick accounts", e);
        }

        return rows;
    }

    // Lấy các hóa đơn đã thanh toán gần nhất trong ngày để hiển thị nhanh.
    public List<Map<String, Object>> getRecentPaidInvoicesToday(int limit) {
        List<Map<String, Object>> rows = new ArrayList<>();
        String sql = "SELECT TOP (?) i.invoice_id, p.full_name AS patient_name, i.final_amount, "
                + "FORMAT(i.created_at, 'dd/MM/yyyy HH:mm') AS payment_time "
                + "FROM Invoice i "
                + "JOIN Patient p ON p.patient_id = i.patient_id "
                + "WHERE LOWER(i.status) = 'paid' AND CAST(i.created_at AS DATE) = CAST(GETDATE() AS DATE) "
                + "ORDER BY i.created_at DESC";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, Math.max(limit, 1));
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("invoiceId", rs.getString("invoice_id"));
                    row.put("patientName", rs.getString("patient_name"));
                    row.put("finalAmount", rs.getBigDecimal("final_amount"));
                    row.put("payment_time", rs.getString("payment_time"));
                    rows.add(row);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load recent paid invoices for today", e);
        }
        return rows;
    }

    // Lấy danh sách lượt khám completed hôm nay cho quick modal.
    public List<Map<String, Object>> getCompletedAppointmentsTodayQuick(int limit) {
        List<Map<String, Object>> rows = new ArrayList<>();

        String sql = "SELECT TOP (?) "
                + "ap.appointment_id, "
                + "p.full_name AS patient_name, "
                + "COALESCE(d_direct.full_name, d_schedule.full_name, N'Chưa phân công') AS doctor_name, "
                + "FORMAT(ap.appointment_time, 'HH:mm') AS appointment_time_label, "
                + "FORMAT(ap.appointment_time, 'yyyy-MM-dd') AS appointment_date "
                + "FROM Appointment ap "
                + "JOIN Patient p ON p.patient_id = ap.patient_id "
                + "LEFT JOIN Doctor d_direct ON d_direct.doctor_id = ap.doctor_id "
                + "LEFT JOIN Doctor_Schedule ds ON ds.schedule_id = ap.schedule_id "
                + "LEFT JOIN Doctor d_schedule ON d_schedule.doctor_id = ds.doctor_id "
                + "WHERE LOWER(ap.status) = 'completed' "
                + "AND ap.appointment_time <= GETDATE() "
                + "ORDER BY ap.appointment_time DESC, ap.appointment_id DESC";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, Math.max(limit, 1));

            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("appointmentId", rs.getString("appointment_id"));
                    row.put("patientName", rs.getString("patient_name"));
                    row.put("doctorName", rs.getString("doctor_name"));
                    row.put("appointmentTime", rs.getString("appointment_time_label"));
                    row.put("appointmentDate", rs.getString("appointment_date"));
                    rows.add(row);
                }
            }

            LOGGER.log(Level.INFO, "Loaded " + rows.size() + " completed appointments quick");

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load completed appointments quick", e);
        }

        return rows;
    }

    // Lấy danh sách dịch vụ y tế theo bộ lọc tìm kiếm/loại/trạng thái.
    public List<Map<String, Object>> getMedicalServices(String search, String serviceType, String status) {
        List<Map<String, Object>> rows = new ArrayList<>();
        StringBuilder sql = new StringBuilder("SELECT service_id, service_name, price, service_type, status FROM Medical_Service WHERE 1=1");
        List<Object> params = new ArrayList<>();

        if (search != null && !search.trim().isEmpty()) {
            sql.append(" AND service_name LIKE ?");
            params.add("%" + search.trim() + "%");
        }

        if (serviceType != null && !serviceType.trim().isEmpty()) {
            sql.append(" AND LOWER(service_type) = LOWER(?)");
            params.add(serviceType.trim());
        }

        if (status != null && !status.trim().isEmpty()) {
            sql.append(" AND LOWER(status) = LOWER(?)");
            params.add(status.trim());
        }

        sql.append(" ORDER BY service_type, service_name");

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            bindParams(statement, params);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("serviceId", rs.getInt("service_id"));
                    row.put("serviceName", rs.getString("service_name"));
                    row.put("price", rs.getBigDecimal("price"));
                    row.put("serviceType", rs.getString("service_type"));
                    row.put("status", rs.getString("status"));
                    rows.add(row);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to query medical services", e);
        }

        return rows;
    }

    // Tạo dịch vụ y tế mới.
    public boolean createMedicalService(String serviceName, BigDecimal price, String serviceType, String status) {
        if (serviceName == null || serviceName.isBlank() || price == null || price.compareTo(BigDecimal.ZERO) <= 0) {
            return false;
        }
        if (!isAllowedServiceType(serviceType) || !isAllowedServiceStatus(status)) {
            return false;
        }

        String sql = "INSERT INTO Medical_Service (service_name, price, service_type, status) VALUES (?, ?, ?, ?)";
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, serviceName);
            statement.setBigDecimal(2, price);
            statement.setString(3, normalizeServiceType(serviceType));
            statement.setString(4, normalizeServiceStatus(status));
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to create medical service", e);
            return false;
        }
    }

    // Cập nhật thông tin dịch vụ y tế.
    public boolean updateMedicalService(int serviceId, String serviceName, BigDecimal price, String serviceType, String status) {
        if (serviceId <= 0 || serviceName == null || serviceName.isBlank() || price == null || price.compareTo(BigDecimal.ZERO) <= 0) {
            return false;
        }
        if (!isAllowedServiceType(serviceType) || !isAllowedServiceStatus(status)) {
            return false;
        }

        String sql = "UPDATE Medical_Service SET service_name = ?, price = ?, service_type = ?, status = ? WHERE service_id = ?";
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, serviceName);
            statement.setBigDecimal(2, price);
            statement.setString(3, normalizeServiceType(serviceType));
            statement.setString(4, normalizeServiceStatus(status));
            statement.setInt(5, serviceId);
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to update medical service", e);
            return false;
        }
    }

    // Xóa một dịch vụ y tế khỏi hệ thống.
    public boolean deleteMedicalService(int serviceId) {
        String sql = "DELETE FROM Medical_Service WHERE service_id = ?";
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, serviceId);
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to delete medical service", e);
            return false;
        }
    }

    // Cập nhật trạng thái Active/Inactive của dịch vụ.
    public boolean updateMedicalServiceStatus(int serviceId, String status) {
        if (!isAllowedServiceStatus(status)) {
            return false;
        }
        String sql = "UPDATE Medical_Service SET status = ? WHERE service_id = ?";
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, normalizeServiceStatus(status));
            statement.setInt(2, serviceId);
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to update service status", e);
            return false;
        }
    }

    // =========================
    // KHU VỰC QUẢN LÝ LỊCH TRỰC
    // =========================

    // Lấy danh sách bác sĩ khả dụng để tạo lịch trực thủ công.
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

    // Lấy chi tiết một ca trực theo scheduleId để phục vụ chuyển giao hoặc chỉnh sửa.
    public Map<String, Object> getDoctorScheduleById(int scheduleId) {
        boolean hasOnlineQuota = hasColumn("Doctor_Schedule", "online_quota");
        String sql = "SELECT ds.schedule_id, ds.doctor_id, d.full_name, d.department, ds.work_date, ds.time_slot, ds.max_patients, "
                + (hasOnlineQuota ? "ds.online_quota" : "NULL")
                + " AS online_quota, ds.status "
                + "FROM Doctor_Schedule ds "
                + "JOIN Doctor d ON d.doctor_id = ds.doctor_id "
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

        boolean hasOnlineQuota = hasColumn("Doctor_Schedule", "online_quota");
        String sql = hasOnlineQuota
                ? "UPDATE Doctor_Schedule SET doctor_id = ?, time_slot = ?, max_patients = ?, online_quota = ?, status = ? WHERE schedule_id = ?"
                : "UPDATE Doctor_Schedule SET doctor_id = ?, time_slot = ?, max_patients = ?, status = ? WHERE schedule_id = ?";
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            Date workDate = getScheduleWorkDateById(connection, scheduleId);
            String validatedTimeSlot = normalizeTimeSlot(timeSlot);
            String validationError = validateScheduleConstraints(connection, doctorId, workDate, validatedTimeSlot, maxPatients, scheduleId);
            if (validationError != null) {
                setScheduleValidationMessage(validationError);
                return false;
            }

            statement.setInt(1, doctorId);
            statement.setString(2, validatedTimeSlot);
            statement.setInt(3, maxPatients);
            if (hasOnlineQuota) {
                statement.setInt(4, resolvedOnlineQuota);
                statement.setString(5, normalizedStatus);
                statement.setInt(6, scheduleId);
            } else {
                statement.setString(4, normalizedStatus);
                statement.setInt(5, scheduleId);
            }
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to update doctor schedule id=" + scheduleId, e);
            setScheduleValidationMessage("Loi cap nhat DB: " + e.getMessage());
            return false;
        }
    }
    // Chuyển giao một ca trực sang bác sĩ khác sau khi kiểm tra xung đột.
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

    // Lấy danh sách bệnh nhân thuộc một ca trực cụ thể.
    public List<Map<String, Object>> getAppointmentsBySchedule(int scheduleId) {
        List<Map<String, Object>> rows = new ArrayList<>();
        boolean hasBookingSource = hasColumn("Appointment", "booking_source");
        boolean hasBookingType = hasColumn("Appointment", "booking_type");
        String bookingSourceExpression = hasBookingSource
                ? "a.booking_source"
                : (hasBookingType ? "a.booking_type" : "'Online'");
        String sql = "SELECT a.appointment_id, p.full_name, "
                + "FORMAT(a.appointment_time, 'HH:mm') AS appointment_time, a.status, "
                + bookingSourceExpression + " AS booking_source "
                + "FROM Appointment a "
                + "JOIN Patient p ON a.patient_id = p.patient_id "
                + "WHERE a.schedule_id = ? "
                + "ORDER BY a.appointment_time ASC";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, scheduleId);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("appointmentId", rs.getInt("appointment_id"));
                    row.put("patientName", rs.getString("full_name"));
                    row.put("appointmentTime", rs.getString("appointment_time"));
                    row.put("status", rs.getString("status"));
                    row.put("bookingSource", rs.getString("booking_source"));
                    rows.add(row);
                }
            }
            return rows;
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Failed to load appointments for schedule " + scheduleId, e);
        }
        return rows;
    }

    // Lấy dữ liệu bác sĩ để AI scheduling cân bằng tải và đúng khoa.
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

    /**
     * Normalize department name để đảm bảo consistency trong AI scheduling.
     * Chuyển đổi các biến thể của khoa tiểu đường sang "Endocrinology" hoặc giữ
     * lại tên khoa Tổng quát để AI có thể phân bổ dự phòng.
     */
    // Chuẩn hóa tên khoa để AI scheduling dùng một chuẩn thống nhất.
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

    // Lấy danh sách ca trực hôm nay cho modal dashboard.
    public List<Map<String, Object>> getTodaySchedules() {
        List<Map<String, Object>> rows = new ArrayList<>();

        markLateWaitingAppointmentsAsNoShow();
        refreshDoctorScheduleStatusFromAppointments();
        boolean hasBookingSource = hasColumn("Appointment", "booking_source");
        boolean hasBookingType = hasColumn("Appointment", "booking_type");
        boolean hasOnlineQuota = hasColumn("Doctor_Schedule", "online_quota");
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

    // Lấy danh sách khoa đang có dữ liệu lịch trực.
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

    // Lấy danh sách lịch trực theo bộ lọc khoa/bác sĩ/ngày.
    public List<Map<String, Object>> getDoctorSchedules(String department, String doctorName, Date workDate) {
        List<Map<String, Object>> rows = new ArrayList<>();

        markLateWaitingAppointmentsAsNoShow();
        refreshDoctorScheduleStatusFromAppointments();
        boolean hasBookingSource = hasColumn("Appointment", "booking_source");
        boolean hasBookingType = hasColumn("Appointment", "booking_type");
        boolean hasOnlineQuota = hasColumn("Doctor_Schedule", "online_quota");
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
                + "ds.status, "
            + "COALESCE(active_bookings.active_count, 0) AS active_count, "
            + "COALESCE(booked_bookings.booked_count, 0) AS booked_count, "
            + "COALESCE(online_bookings.online_booked_count, 0) AS online_booked_count "
                + "FROM Doctor_Schedule ds "
                + "JOIN Doctor d ON d.doctor_id = ds.doctor_id "
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

    // Tạo ca trực thủ công, áp dụng đầy đủ constraint lịch trực.
    public boolean createDoctorSchedule(int doctorId, Date workDate, String timeSlot, int maxPatients, String status) {
        return createDoctorSchedule(doctorId, workDate, timeSlot, maxPatients, null, status);
    }

    // Tạo ca trực thủ công với online quota tùy chọn.
    public boolean createDoctorSchedule(int doctorId, Date workDate, String timeSlot, int maxPatients, Integer onlineQuota, String status) {
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

        boolean hasOnlineQuota = hasColumn("Doctor_Schedule", "online_quota");
        String sql = hasOnlineQuota
                ? "INSERT INTO Doctor_Schedule (doctor_id, work_date, time_slot, max_patients, online_quota, status) VALUES (?, ?, ?, ?, ?, ?)"
                : "INSERT INTO Doctor_Schedule (doctor_id, work_date, time_slot, max_patients, status) VALUES (?, ?, ?, ?, ?)";
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            String validatedTimeSlot = normalizeTimeSlot(timeSlot);
            String validationError = validateScheduleConstraints(connection, doctorId, workDate, validatedTimeSlot, maxPatients, null);
            if (validationError != null) {
                setScheduleValidationMessage(validationError);
                return false;
            }

            statement.setInt(1, doctorId);
            statement.setDate(2, workDate);
            statement.setString(3, validatedTimeSlot);
            statement.setInt(4, maxPatients);
            if (hasOnlineQuota) {
                statement.setInt(5, resolvedOnlineQuota);
                statement.setString(6, normalizeScheduleStatus(status));
            } else {
                statement.setString(5, normalizeScheduleStatus(status));
            }
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to create doctor schedule", e);
            setScheduleValidationMessage("Không thể tạo ca trực do lỗi hệ thống.");
            return false;
        }
    }

    // Persist batch lịch từ Gemini sau khi validate ràng buộc và rollback toàn bộ nếu có lỗi.
    // =========================
    // KHU VỰC AI SCHEDULING VÀ ĐIỀU PHỐI
    // =========================

    // Lưu batch lịch do Gemini trả về sau khi đã validate toàn bộ ràng buộc.
    public List<Map<String, Object>> createGeminiSchedules(List<Map<String, Object>> assignments,
            int maxPatients,
            int expectedCount) {
        List<Map<String, Object>> created = new ArrayList<>();
        clearScheduleValidationMessage();
        if (assignments == null || assignments.size() != expectedCount) {
            setScheduleValidationMessage("Dữ liệu phân bổ từ AI không hợp lệ hoặc không đủ số lượng.");
            return created;
        }
        if (maxPatients <= 0) {
            setScheduleValidationMessage("Số bệnh nhân tối đa của ca trực phải lớn hơn 0.");
            return created;
        }
        if (maxPatients > MAX_PATIENTS_HARD_CEILING) {
            setScheduleValidationMessage("Số bệnh nhân tối đa không được vượt quá 50 để đảm bảo chất lượng khám.");
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
                    String timeSlot = normalizeTimeSlot(String.valueOf(assignment.get("timeSlot")));
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

                    String validationError = validateScheduleConstraints(connection, doctorId, workDate, timeSlot, maxPatients, null);
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
                            insert.setInt(5, getDefaultOnlineQuota(maxPatients));
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
                connection.commit();
            } catch (SQLException | RuntimeException e) {
                connection.rollback();
                throw e;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (SQLException | RuntimeException e) {
            LOGGER.log(Level.SEVERE, "Failed to persist validated Gemini schedules", e);
            setScheduleValidationMessage(e.getMessage() == null ? "Không thể tạo lịch AI do vi phạm ràng buộc lịch trực." : e.getMessage());
            created.clear();
        }
        return created;
    }

    // Kiểm tra batch AI có cân bằng tải giữa các bác sĩ hay không.
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

    // Wrapper theo khoảng ngày cho thuật toán fallback cân bằng tải.
    // Wrapper chuyển khoảng ngày thành danh sách ngày trước khi chạy fallback AI.
    public List<Map<String, Object>> createAiOptimizedSchedules(Date startDate,
            Date endDate,
            List<Map<String, String>> shiftsPerDay,
            String department,
            int maxPatients,
            int maxSchedules) {
        List<Date> targetDates = new ArrayList<>();
        if (startDate != null && endDate != null && !startDate.after(endDate)) {
            java.time.LocalDate cursor = startDate.toLocalDate();
            while (!cursor.isAfter(endDate.toLocalDate())) {
                targetDates.add(Date.valueOf(cursor));
                cursor = cursor.plusDays(1);
            }
        }
        return createAiOptimizedSchedules(targetDates, shiftsPerDay, department, maxPatients, maxSchedules);
    }

    /**
     * Creates schedules with the local fallback optimizer when Gemini cannot provide a valid batch.
     */
    public List<Map<String, Object>> createAiOptimizedSchedules(List<Date> targetDates,
            List<Map<String, String>> shiftsPerDay,
            String department,
            int maxPatients,
            int maxSchedules) {
        List<Map<String, Object>> created = new ArrayList<>();
        clearScheduleValidationMessage();
        if (targetDates == null || targetDates.isEmpty() || shiftsPerDay == null || shiftsPerDay.isEmpty()
                || maxPatients <= 0 || maxSchedules <= 0) {
            setScheduleValidationMessage("Dữ liệu tạo lịch dự phòng không hợp lệ.");
            return created;
        }
        if (maxPatients > MAX_PATIENTS_HARD_CEILING) {
            setScheduleValidationMessage("Số bệnh nhân tối đa không được vượt quá 50 để đảm bảo chất lượng khám.");
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
                        String timeSlot = normalizeTimeSlot(shift.get("timeSlot"));
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
                            String validationError = validateScheduleConstraints(connection, preferredDoctorId, sqlDate, timeSlot, maxPatients, null);
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
                        String validationError = validateScheduleConstraints(connection, doctorId, sqlDate, timeSlot, maxPatients, null);
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
                            insert.setInt(5, getDefaultOnlineQuota(maxPatients));
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
                connection.commit();
            } catch (SQLException e) {
                connection.rollback();
                throw e;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to create AI optimized schedules", e);
            setScheduleValidationMessage(e.getMessage() == null ? "Không thể tạo lịch dự phòng do vi phạm ràng buộc lịch trực." : e.getMessage());
        }
        return created;
    }

    /**
     * Soft-constraint hook: fixed weekly rotation.
     * Return a preferred doctorId when a persistent pattern store is available.
     * Current implementation keeps AI behavior unchanged.
     */
    // Hook soft-constraint cho lịch cố định tuần (hiện để mở rộng, chưa kích hoạt dữ liệu).
    // Hook mở rộng cho lịch cố định theo tuần; hiện trả null để không ảnh hưởng AI hiện tại.
    private Integer getPreferredDoctorIdForFixedRotation(Connection connection,
            Date workDate,
            String timeSlot,
            String targetDepartment) {
        return null;
    }

    // Lấy thông tin cơ bản của bác sĩ để dùng lại khi ưu tiên fixed rotation.
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

    // Chọn bác sĩ phù hợp cho một slot theo tải, chuyên khoa và các ràng buộc.
    // Chọn bác sĩ phù hợp cho từng slot dựa trên tải, chuyên khoa và ràng buộc.
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
            LocalTime[] range = parseTimeSlotRange(timeSlot);
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

    // Cập nhật ca trực thủ công với cùng bộ constraint như khi tạo mới.
    // Cập nhật ca trực và validate lại overlap, số ca/ngày, giới hạn bệnh nhân.
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

    // Xóa hẳn lịch trực theo scheduleId.
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

    // Hủy ca trực; chặn hủy nếu ca đã Cancelled hoặc Expired.
    // Hủy lịch trực nhưng vẫn giữ bản ghi để truy vết lịch sử.
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

    // Lấy các ca đang chờ/đang khám để điều phối ngoại lệ.
    public List<Map<String, Object>> getExceptionQueue(Integer doctorId) {
        markLateWaitingAppointmentsAsNoShow();

        List<Map<String, Object>> rows = new ArrayList<>();
        StringBuilder sql = new StringBuilder(
                "SELECT a.appointment_id, a.status AS appointment_status, a.appointment_time, "
                + "a.schedule_id, ds.doctor_id AS current_doctor_id, d.full_name AS current_doctor_name, d.department, "
                + "p.patient_id, p.full_name AS patient_name "
                + "FROM Appointment a "
                + "LEFT JOIN Doctor_Schedule ds ON a.schedule_id = ds.schedule_id "
                + "LEFT JOIN Doctor d ON ds.doctor_id = d.doctor_id "
                + "LEFT JOIN Patient p ON a.patient_id = p.patient_id "
                + "WHERE a.status IN ('Checked_In', 'In_Progress') "
                + "AND CAST(a.appointment_time AS DATE) = CAST(GETDATE() AS DATE) "
                + "AND a.appointment_time <= GETDATE()"
        );
        List<Object> params = new ArrayList<>();
        if (doctorId != null) {
            sql.append(" AND ds.doctor_id = ?");
            params.add(doctorId);
        }
        sql.append(" ORDER BY a.appointment_time ASC, a.appointment_id ASC");

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            bindParams(statement, params);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("appointmentId", rs.getInt("appointment_id"));
                    row.put("appointmentStatus", rs.getString("appointment_status"));
                    row.put("appointmentTime", rs.getTimestamp("appointment_time"));
                    row.put("scheduleId", rs.getInt("schedule_id"));
                    row.put("currentDoctorId", rs.getInt("current_doctor_id"));
                    row.put("currentDoctorName", rs.getString("current_doctor_name"));
                    row.put("department", rs.getString("department"));
                    row.put("patientId", rs.getInt("patient_id"));
                    row.put("patientName", rs.getString("patient_name"));
                    rows.add(row);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load exception queue", e);
        }
        return rows;
    }

    /**
     * Counts appointments that still occupy schedule capacity.
     * Cancelled and Absent are excluded.
     */
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

    /**
     * Counts online appointments that still occupy the online quota.
     * Cancelled and Absent are excluded.
     */
    public int getOnlineBookedCountBySchedule(int scheduleId) {
        if (!hasColumn("Appointment", "booking_source")) {
            return 0;
        }
        String sql = "SELECT COUNT(*) AS booked_count FROM Appointment "
                + "WHERE schedule_id = ? "
                + "AND LOWER(LTRIM(RTRIM(COALESCE(booking_source, '')))) = 'online' "
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

    /**
     * Checks whether a patient can book this schedule online.
     */
    public boolean canBookOnline(int scheduleId) {
        return canBookBySource(scheduleId, true);
    }

    /**
     * Checks whether staff can book into the schedule capacity.
     * Staff booking can use reserved slots.
     */
    public boolean canBookByStaff(int scheduleId) {
        return canBookBySource(scheduleId, false);
    }

    // Cập nhật quota online riêng cho một ca trực.
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

    /**
     * Applies booking capacity rules for online and staff-created appointments.
     */
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

    // Lấy bác sĩ còn khả dụng để tái phân trong tình huống khẩn cấp.
    public List<Map<String, Object>> getAvailableDoctorsForEmergency(String department, Integer excludeDoctorId) {
        List<Map<String, Object>> doctors = new ArrayList<>();
        StringBuilder sql = new StringBuilder(
                "SELECT d.doctor_id, d.full_name, d.department "
                + "FROM Doctor d "
                + "JOIN Account a ON a.account_id = d.account_id "
                + "WHERE LOWER(a.status) = 'active'"
        );
        List<Object> params = new ArrayList<>();
        if (department != null && !department.trim().isEmpty()) {
            sql.append(" AND d.department = ?");
            params.add(department.trim());
        }
        if (excludeDoctorId != null) {
            sql.append(" AND d.doctor_id <> ?");
            params.add(excludeDoctorId);
        }
        sql.append(" ORDER BY d.full_name ASC");

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            bindParams(statement, params);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("doctorId", rs.getInt("doctor_id"));
                    row.put("fullName", rs.getString("full_name"));
                    row.put("department", rs.getString("department"));
                    doctors.add(row);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load available doctors for emergency", e);
        }
        return doctors;
    }

    // Lấy TẤT CẢ bác sĩ hoạt động để chọn tái điều phối (không lọc khoa).
    public List<Map<String, Object>> getAllActiveDoctorsForEmergency(Integer excludeDoctorId) {
        List<Map<String, Object>> doctors = new ArrayList<>();
        StringBuilder sql = new StringBuilder(
                "SELECT d.doctor_id, d.full_name, d.department "
                + "FROM Doctor d "
                + "JOIN Account a ON a.account_id = d.account_id "
                + "WHERE LOWER(a.status) = 'active'"
        );
        List<Object> params = new ArrayList<>();
        if (excludeDoctorId != null) {
            sql.append(" AND d.doctor_id <> ?");
            params.add(excludeDoctorId);
        }
        sql.append(" ORDER BY d.department, d.full_name ASC");

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            bindParams(statement, params);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("doctorId", rs.getInt("doctor_id"));
                    row.put("fullName", rs.getString("full_name"));
                    row.put("department", rs.getString("department"));
                    doctors.add(row);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load all active doctors for emergency", e);
        }
        return doctors;
    }

    // Lấy bác sĩ có lịch không hủy trong ngày của appointment cần điều phối.
    public List<Map<String, Object>> getEmergencyCandidateDoctorsForAppointment(int appointmentId, Integer excludeDoctorId) {
        List<Map<String, Object>> doctors = new ArrayList<>();
        StringBuilder sql = new StringBuilder(
                "SELECT DISTINCT d.doctor_id, d.full_name, d.department "
                + "FROM Appointment ap "
                + "JOIN Doctor_Schedule src_ds ON src_ds.schedule_id = ap.schedule_id "
                + "JOIN Doctor_Schedule ds ON ds.work_date = src_ds.work_date "
                + "JOIN Doctor d ON d.doctor_id = ds.doctor_id "
                + "JOIN Account a ON a.account_id = d.account_id "
                + "WHERE ap.appointment_id = ? "
                + "AND LOWER(a.status) = 'active' "
                + "AND LOWER(ds.status) <> 'cancelled'"
        );
        List<Object> params = new ArrayList<>();
        params.add(appointmentId);

        if (excludeDoctorId != null) {
            sql.append(" AND d.doctor_id <> ?");
            params.add(excludeDoctorId);
        }

        sql.append(" ORDER BY d.department, d.full_name ASC");

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            bindParams(statement, params);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("doctorId", rs.getInt("doctor_id"));
                    row.put("fullName", rs.getString("full_name"));
                    row.put("department", rs.getString("department"));
                    doctors.add(row);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load emergency candidate doctors for appointmentId=" + appointmentId, e);
        }

        return doctors;
    }

    // Tái gán lịch hẹn sang bác sĩ khác trong luồng điều phối khẩn.
    public boolean reassignAppointmentToDoctor(int appointmentId, int targetDoctorId) {
        String pickSameDayScheduleSql = "SELECT TOP 1 ds.schedule_id "
                + "FROM Appointment ap "
                + "JOIN Doctor_Schedule src_ds ON src_ds.schedule_id = ap.schedule_id "
                + "JOIN Doctor_Schedule ds ON ds.doctor_id = ? "
                + "WHERE ap.appointment_id = ? "
                + "AND ds.work_date = src_ds.work_date "
                + "AND LOWER(ds.status) <> 'cancelled' "
                + "ORDER BY TRY_CAST(LEFT(REPLACE(ds.time_slot, ' ', ''), 5) AS time) ASC";

        String pickFallbackScheduleSql = "SELECT TOP 1 ds.schedule_id "
                + "FROM Doctor_Schedule ds "
                + "WHERE ds.doctor_id = ? "
                + "AND LOWER(ds.status) <> 'cancelled' "
                + "AND ds.work_date >= CAST(GETDATE() AS DATE) "
                + "ORDER BY ds.work_date ASC, TRY_CAST(LEFT(REPLACE(ds.time_slot, ' ', ''), 5) AS time) ASC";

        String updateAppointmentSql = "UPDATE Appointment "
                + "SET schedule_id = ?, doctor_id = ? "
                + "WHERE appointment_id = ? AND LOWER(status) IN ('checked_in', 'in_progress', 'in-progress')";

        try (Connection connection = DatabaseConnection.getConnection()) {
            Integer targetScheduleId = null;

            try (PreparedStatement pick = connection.prepareStatement(pickSameDayScheduleSql)) {
                pick.setInt(1, targetDoctorId);
                pick.setInt(2, appointmentId);
                try (ResultSet rs = pick.executeQuery()) {
                    if (rs.next()) {
                        targetScheduleId = rs.getInt("schedule_id");
                    }
                }
            }

            if (targetScheduleId == null) {
                try (PreparedStatement pick = connection.prepareStatement(pickFallbackScheduleSql)) {
                    pick.setInt(1, targetDoctorId);
                    try (ResultSet rs = pick.executeQuery()) {
                        if (rs.next()) {
                            targetScheduleId = rs.getInt("schedule_id");
                        }
                    }
                }
            }

            if (targetScheduleId == null) {
                return false;
            }

            try (PreparedStatement update = connection.prepareStatement(updateAppointmentSql)) {
                update.setInt(1, targetScheduleId);
                update.setInt(2, targetDoctorId);
                update.setInt(3, appointmentId);
                return update.executeUpdate() > 0;
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to reassign appointment in emergency routing", e);
            return false;
        }
    }

    /**
     * Refreshes schedule status from time and occupied capacity.
     * Cancelled schedules stay Cancelled.
     */
    public int refreshDoctorScheduleStatusFromAppointments() {
        markLateWaitingAppointmentsAsNoShow();
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
                + "WHERE LOWER(ds.status) NOT IN ('cancelled', 'pending')";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            return statement.executeUpdate();
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to refresh schedule status", e);
            return 0;
        }
    }

    // Lấy báo cáo doanh thu theo granularity đã chọn.
    public List<Map<String, Object>> getRevenueReport(String granularity, Integer year, Integer month, Integer day) {
        return getRevenueReport(granularity, year, month, day, null, null);
    }

    // Lấy báo cáo lượt khám theo granularity đã chọn.
    public List<Map<String, Object>> getVisitReport(String granularity, Integer year, Integer month, Integer day) {
        return getVisitReport(granularity, year, month, day, null, null);
        }

        // Lấy báo cáo doanh thu theo khoảng ngày cụ thể.
        public List<Map<String, Object>> getRevenueReport(String granularity,
            Integer year,
            Integer month,
            Integer day,
            LocalDate startDate,
            LocalDate endDate) {
        return getTimeSeriesReport("Invoice", "created_at", "final_amount", "status", "Paid", "SUM", "revenue_value",
            granularity, year, month, day, startDate, endDate);
        }

        // Lấy báo cáo lượt khám theo khoảng ngày cụ thể.
        public List<Map<String, Object>> getVisitReport(String granularity,
            Integer year,
            Integer month,
            Integer day,
            LocalDate startDate,
            LocalDate endDate) {
        return getTimeSeriesReport("Appointment", "appointment_time", "appointment_id", "status", "Completed", "COUNT", "visit_value",
            granularity, year, month, day, startDate, endDate);
    }

    // Lấy chi tiết hóa đơn và lượt khám theo period để drill-down từ báo cáo.
    public Map<String, Object> getReportDetailByPeriod(String period) {
        Map<String, Object> result = new HashMap<>();
        List<Map<String, Object>> invoices = new ArrayList<>();
        List<Map<String, Object>> appointments = new ArrayList<>();

        if (period == null || period.isBlank()) {
            result.put("invoices", invoices);
            result.put("appointments", appointments);
            return result;
        }

        period = period.trim();
        LOGGER.log(Level.INFO, "getReportDetailByPeriod called with period: [" + period + "]");

        boolean isDay = period.matches("\\d{4}-\\d{2}-\\d{2}");

        String periodFilter = isDay
                ? "FORMAT(i.created_at, 'yyyy-MM-dd') = ?"
                : "FORMAT(i.created_at, 'yyyy-MM') = ?";

        boolean hasInsuranceDeduction = hasColumn("Invoice", "insurance_deduction");
        String bhytCol = hasInsuranceDeduction
                ? "i.insurance_deduction"
                : "CAST(0 AS DECIMAL(18,2))";

        String invoiceSql = "SELECT i.invoice_id, p.full_name AS patient_name, "
                + "i.total_amount, " + bhytCol + " AS bhyt_deduction, i.final_amount, "
                + "FORMAT(i.created_at, 'yyyy-MM-dd') AS payment_date "
                + "FROM Invoice i "
                + "JOIN Patient p ON p.patient_id = i.patient_id "
                + "WHERE LOWER(i.status) = 'paid' AND " + periodFilter + " "
                + "ORDER BY i.created_at DESC";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(invoiceSql)) {

            statement.setString(1, period);

            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("invoiceId", rs.getString("invoice_id"));
                    row.put("patientName", rs.getString("patient_name"));
                    row.put("totalAmount", rs.getBigDecimal("total_amount"));
                    row.put("bhytDeduction", rs.getBigDecimal("bhyt_deduction"));
                    row.put("finalAmount", rs.getBigDecimal("final_amount"));
                    row.put("paymentDate", rs.getString("payment_date"));
                    invoices.add(row);
                }
            }

            LOGGER.log(Level.INFO, "Loaded " + invoices.size()
                    + " invoices for period [" + period + "]");

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load invoice details by period ["
                    + period + "]: " + e.getMessage());
        }

        /*
     * Phần dưới sửa lại query chi tiết lượt khám.
     *
     * Lý do:
     * 1. Appointment.patient_id phải nối với Patient.patient_id.
     * 2. Một số Appointment không có schedule_id nên phải dùng LEFT JOIN.
     * 3. Nếu không có Doctor_Schedule thì vẫn lấy được giờ từ appointment_time.
     * 4. Nếu có doctor_id trực tiếp trong Appointment thì lấy bác sĩ từ đó.
     * 5. Nếu doctor_id trong Appointment null thì lấy bác sĩ thông qua Doctor_Schedule.
         */
        periodFilter = isDay
                ? "FORMAT(ap.appointment_time, 'yyyy-MM-dd') = ?"
                : "FORMAT(ap.appointment_time, 'yyyy-MM') = ?";

        String appointmentSql = "SELECT ap.appointment_id, "
                + "p.full_name AS patient_name, "
                + "COALESCE(d_direct.full_name, d_schedule.full_name, N'Chưa phân bác sĩ') AS doctor_name, "
                + "COALESCE(ds.time_slot, FORMAT(ap.appointment_time, 'HH:mm')) AS time_slot, "
                + "ap.status AS appointment_status, "
                + "FORMAT(ap.appointment_time, 'yyyy-MM-dd') AS appointment_date "
                + "FROM Appointment ap "
                + "JOIN Patient p ON p.patient_id = ap.patient_id "
                + "LEFT JOIN Doctor d_direct ON d_direct.doctor_id = ap.doctor_id "
                + "LEFT JOIN Doctor_Schedule ds ON ds.schedule_id = ap.schedule_id "
                + "LEFT JOIN Doctor d_schedule ON d_schedule.doctor_id = ds.doctor_id "
            + "WHERE LOWER(ap.status) IN ('completed', 'absent') AND " + periodFilter + " "
                + "ORDER BY ap.appointment_time DESC";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(appointmentSql)) {

            statement.setString(1, period);

            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("appointmentId", rs.getString("appointment_id"));
                    row.put("patientName", rs.getString("patient_name"));
                    row.put("doctorName", rs.getString("doctor_name"));
                    row.put("timeSlot", rs.getString("time_slot"));
                    row.put("status", rs.getString("appointment_status"));
                    row.put("appointmentDate", rs.getString("appointment_date"));
                    appointments.add(row);
                }
            }

            LOGGER.log(Level.INFO, "Loaded " + appointments.size()
                    + " appointments for period [" + period + "]");

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load appointment details by period ["
                    + period + "]: " + e.getMessage());
        }

        result.put("invoices", invoices);
        result.put("appointments", appointments);
        return result;
    }

    // =========================
    // KHU VỰC HELPER NỘI BỘ
    // =========================

    // Lấy chi tiết item của một hóa đơn theo invoiceId.
    public List<Map<String, Object>> getInvoiceItemsByInvoiceId(String invoiceId) {
        List<Map<String, Object>> items = new ArrayList<>();
        if (invoiceId == null || invoiceId.trim().isEmpty()) {
            return items;
        }

        String sql = "SELECT id.invoice_detail_id, id.invoice_id, id.service_id, "
                + "ms.service_name, id.quantity, id.price AS unit_price, "
                + "CAST(id.quantity * id.price AS DECIMAL(18,2)) AS line_total "
                + "FROM Invoice_Detail id "
                + "LEFT JOIN Medical_Service ms ON ms.service_id = id.service_id "
                + "WHERE id.invoice_id = ? "
                + "ORDER BY id.invoice_detail_id ASC";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, invoiceId.trim());
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> item = new HashMap<>();
                    item.put("invoiceDetailId", rs.getInt("invoice_detail_id"));
                    item.put("invoiceId", rs.getString("invoice_id"));
                    item.put("serviceId", rs.getInt("service_id"));
                    item.put("serviceName", rs.getString("service_name"));
                    item.put("quantity", rs.getInt("quantity"));
                    item.put("unitPrice", rs.getBigDecimal("unit_price"));
                    item.put("lineTotal", rs.getBigDecimal("line_total"));
                    items.add(item);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load invoice items for invoiceId=" + invoiceId, e);
        }

        return items;
    }

    // Truy vấn time-series dùng chung cho doanh thu/lượt khám.
    private List<Map<String, Object>> getTimeSeriesReport(String table,
            String timeColumn,
            String metricColumn,
            String statusColumn,
            String statusValue,
            String aggregateType,
            String metricAlias,
            String granularity,
            Integer year,
            Integer month,
            Integer day,
            LocalDate startDate,
            LocalDate endDate) {
        List<Map<String, Object>> rows = new ArrayList<>();
        String normalizedGranularity = normalizeGranularity(granularity);

        String periodExpr;
        if ("DAY".equals(normalizedGranularity)) {
            periodExpr = "FORMAT(" + timeColumn + ", 'yyyy-MM-dd')";
        } else if ("MONTH".equals(normalizedGranularity)) {
            periodExpr = "FORMAT(" + timeColumn + ", 'yyyy-MM')";
        } else {
            periodExpr = "FORMAT(" + timeColumn + ", 'yyyy')";
        }

        String metricExpr = "SUM".equals(aggregateType)
                ? "COALESCE(SUM(" + metricColumn + "), 0)"
                : "COUNT(" + metricColumn + ")";

        StringBuilder sql = new StringBuilder("SELECT " + periodExpr + " AS period_label, "
                + metricExpr + " AS " + metricAlias + " "
                + "FROM " + table + " "
                + "WHERE LOWER(" + statusColumn + ") = LOWER(?) "
                + "AND CAST(" + timeColumn + " AS DATE) <= CAST(GETDATE() AS DATE)");

        List<Object> params = new ArrayList<>();
        params.add(statusValue);

        if ("DAY".equals(normalizedGranularity)) {
            if (startDate != null) {
                sql.append(" AND CAST(").append(timeColumn).append(" AS DATE) >= ?");
                params.add(Date.valueOf(startDate));
            }
            if (endDate != null) {
                sql.append(" AND CAST(").append(timeColumn).append(" AS DATE) <= ?");
                params.add(Date.valueOf(endDate));
            }
        } else {
            if (year != null) {
                sql.append(" AND DATEPART(YEAR, ").append(timeColumn).append(") = ?");
                params.add(year);
            }
            if (month != null) {
                sql.append(" AND DATEPART(MONTH, ").append(timeColumn).append(") = ?");
                params.add(month);
            }
            if (day != null) {
                sql.append(" AND DATEPART(DAY, ").append(timeColumn).append(") = ?");
                params.add(day);
            }
        }

        sql.append(" GROUP BY ").append(periodExpr).append(" ORDER BY period_label ASC");

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            bindParams(statement, params);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("periodLabel", rs.getString("period_label"));
                    row.put("metricValue", rs.getBigDecimal(metricAlias));
                    rows.add(row);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to execute report query", e);
        }

        return rows;
    }

    // Chuẩn hóa granularity về DAY/MONTH/YEAR.
    private String normalizeGranularity(String granularity) {
        String value = granularity == null ? "MONTH" : granularity.trim().toUpperCase(Locale.ROOT);
        if (!"DAY".equals(value) && !"MONTH".equals(value) && !"YEAR".equals(value)) {
            return "MONTH";
        }
        return value;
    }

    // Chạy query count đơn giản và trả về số lượng.
    private int executeCount(String sql) {
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to execute count query", e);
        }
        return 0;
    }

    // Chạy query decimal đơn giản và trả về giá trị tiền tệ.
    private BigDecimal executeBigDecimal(String sql) {
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {
            if (rs.next()) {
                BigDecimal value = rs.getBigDecimal(1);
                return value == null ? BigDecimal.ZERO : value;
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to execute decimal query", e);
        }
        return BigDecimal.ZERO;
    }

    // Kiểm tra một cột có tồn tại trong database hay không.
    private boolean hasColumn(String tableName, String columnName) {
        String sql = "SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ? AND COLUMN_NAME = ?";
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            return hasColumn(statement, tableName, columnName);
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Failed to check column existence", e);
            return false;
        }
    }

    private boolean hasColumn(Connection connection, String tableName, String columnName) {
        String sql = "SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ? AND COLUMN_NAME = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            return hasColumn(statement, tableName, columnName);
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Failed to check column existence", e);
            return false;
        }
    }

    private boolean hasColumn(PreparedStatement statement, String tableName, String columnName) throws SQLException {
        statement.setString(1, tableName);
        statement.setString(2, columnName);
        try (ResultSet rs = statement.executeQuery()) {
            return rs.next();
        }
    }

    // Truy vấn dữ liệu dashboard series cho biểu đồ đa kỳ.
    private List<Map<String, Object>> getDashboardSeries(String table,
            String timeColumn,
            String metricColumn,
            String statusColumn,
            String statusValue,
            boolean isSum,
            String granularity) {
        List<Map<String, Object>> rows = new ArrayList<>();
        String normalizedGranularity = normalizeGranularity(granularity);

        String periodExpr;
        String groupByExpr;
        String orderByExpr;

        if ("DAY".equals(normalizedGranularity)) {
            periodExpr = "CONVERT(varchar(10), CAST(" + timeColumn + " AS DATE), 23)";
            groupByExpr = "CAST(" + timeColumn + " AS DATE)";
            orderByExpr = "CAST(" + timeColumn + " AS DATE)";
        } else if ("MONTH".equals(normalizedGranularity)) {
            periodExpr = "CONCAT(YEAR(" + timeColumn + "), '-', RIGHT('0' + CAST(MONTH(" + timeColumn + ") AS varchar(2)), 2))";
            groupByExpr = "YEAR(" + timeColumn + "), MONTH(" + timeColumn + ")";
            orderByExpr = "YEAR(" + timeColumn + "), MONTH(" + timeColumn + ")";
        } else {
            periodExpr = "CAST(YEAR(" + timeColumn + ") AS varchar(4))";
            groupByExpr = "YEAR(" + timeColumn + ")";
            orderByExpr = "YEAR(" + timeColumn + ")";
        }

        String metricExpr = isSum
                ? "ISNULL(SUM(" + metricColumn + "), 0)"
                : "COUNT(" + metricColumn + ")";

        String sql = "SELECT " + periodExpr + " AS period, "
                + metricExpr + " AS metric_value "
                + "FROM " + table + " "
                + "WHERE " + statusColumn + " = ? "
                + "AND CAST(" + timeColumn + " AS DATE) <= CAST(GETDATE() AS DATE) "
                + "GROUP BY " + groupByExpr + " "
                + "ORDER BY " + orderByExpr;

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, statusValue);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("period", rs.getString("period"));
                    BigDecimal metric = rs.getBigDecimal("metric_value");
                    row.put("value", metric == null ? BigDecimal.ZERO : metric);
                    rows.add(row);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load dashboard series", e);
        }

        return rows;
    }

    // Chuẩn hóa role về lowercase để so khớp danh sách hợp lệ.
    private String normalizeRole(String role) {
        if (role == null) {
            return null;
        }
        String value = role.trim().toLowerCase(Locale.ROOT);
        if (value.isEmpty() || !ALLOWED_ROLES.contains(value)) {
            return null;
        }
        switch (value) {
            case "patient":
                return "Patient";
            case "doctor":
                return "Doctor";
            case "doctor_lab":
                return "doctor_lab";
            case "receptionist":
                return "Receptionist";
            case "admin":
                return "Admin";
            default:
                return null;
        }
    }

    // Kiểm tra email có thuộc tài khoản khác hay không.
    private boolean isAccountEmailExistsForOtherAccount(String email, int accountId) {
        if (email == null || email.isBlank() || accountId <= 0) {
            return false;
        }

        String sql = "SELECT COUNT(*) FROM Account WHERE LOWER(email) = LOWER(?) AND account_id <> ?";
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, email.trim());
            statement.setInt(2, accountId);
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to check duplicate account email for profile edit", e);
            return true;
        }
    }

    // Chuẩn hóa trạng thái tài khoản về lowercase.
    private String normalizeAccountStatus(String status) {
        if (status == null) {
            return null;
        }
        String value = status.trim().toLowerCase(Locale.ROOT);
        if (value.isEmpty() || !ALLOWED_ACCOUNT_STATUS.contains(value)) {
            return null;
        }
        return "locked".equals(value) ? "Locked" : "Active";
    }

    // Chuẩn hóa loại dịch vụ y tế.
    private String normalizeServiceType(String serviceType) {
        if (serviceType == null) {
            return null;
        }
        String value = serviceType.trim();
        return ALLOWED_SERVICE_TYPES.contains(value) ? value : null;
    }

    // Chuẩn hóa trạng thái dịch vụ y tế.
    private String normalizeServiceStatus(String status) {
        if (status == null) {
            return null;
        }
        String value = status.trim();
        return ALLOWED_SERVICE_STATUS.contains(value) ? value : null;
    }

    // Chuẩn hóa trạng thái lịch trực theo danh sách cho phép.
    private String normalizeScheduleStatus(String status) {
        if (status == null) {
            return null;
        }
        String value = status.trim();
        return ALLOWED_SCHEDULE_STATUS.contains(value) ? value : null;
    }

    // Chuẩn hóa nguồn đặt lịch cho Appointment.booking_source.
    private String normalizeBookingSource(String bookingSource) {
        if (bookingSource == null) {
            return null;
        }
        String value = bookingSource.trim();
        return ALLOWED_BOOKING_SOURCES.contains(value) ? value : null;
    }

    // Kiểm tra loại dịch vụ có hợp lệ hay không.
    private boolean isAllowedServiceType(String serviceType) {
        return normalizeServiceType(serviceType) != null;
    }

    // Kiểm tra trạng thái dịch vụ có hợp lệ hay không.
    private boolean isAllowedServiceStatus(String status) {
        return normalizeServiceStatus(status) != null;
    }

    // Kiểm tra trạng thái lịch trực có hợp lệ hay không.
    private boolean isAllowedScheduleStatus(String status) {
        return normalizeScheduleStatus(status) != null;
    }

    /**
     * Calculates the default online quota as 60% of max patients.
     * Keeps reserved slots for receptionist and walk-in booking.
     */
    private int getDefaultOnlineQuota(int maxPatients) {
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

    private boolean isCountedAppointmentStatus(String status) {
        if (status == null) {
            return false;
        }
        String value = status.trim().toLowerCase(Locale.ROOT);
        return "waiting".equals(value)
                || "checked_in".equals(value)
                || "in_progress".equals(value)
                || "in-progress".equals(value)
                || "completed".equals(value);
    }

    private boolean isCountedOnlineAppointmentStatus(String status, String bookingSource) {
        return isCountedAppointmentStatus(status) && "online".equalsIgnoreCase(bookingSource == null ? null : bookingSource.trim());
    }

    // Lấy và xóa message lỗi validation gần nhất để servlet trả ra UI.
    // Lấy message validation gần nhất để servlet đẩy ra UI.
    public String consumeScheduleValidationMessage() {
        String message = scheduleValidationMessage.get();
        scheduleValidationMessage.remove();
        return message == null ? "" : message;
    }

    // TODO: integrate with Doctor workflow when complete action is wired.
    // Requires Appointment.consultation_start_time to enforce minimum consultation duration.
    // Chuẩn bị kiểm tra thời gian khám tối thiểu trước khi cho phép hoàn tất.
    public boolean canCompleteConsultationByMinimumTime(int appointmentId, int minMinutes) {
        if (appointmentId <= 0 || minMinutes <= 0) {
            return false;
        }
        if (!hasColumn("Appointment", "consultation_start_time")) {
            LOGGER.log(Level.INFO, "consultation_start_time does not exist; skip minimum consultation-time guard");
            return true;
        }

        String sql = "SELECT CASE "
                + "WHEN consultation_start_time IS NULL THEN 0 "
                + "WHEN DATEDIFF(MINUTE, consultation_start_time, GETDATE()) >= ? THEN 1 "
                + "ELSE 0 END AS can_complete "
                + "FROM Appointment WHERE appointment_id = ?";
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, minMinutes);
            statement.setInt(2, appointmentId);
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("can_complete") == 1;
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to evaluate minimum consultation time", e);
        }
        return false;
    }

    // Keep the last schedule validation message for the current request flow.
    private void setScheduleValidationMessage(String message) {
        scheduleValidationMessage.set(message == null ? "" : message);
    }

    private void clearScheduleValidationMessage() {
        scheduleValidationMessage.remove();
    }

    // Lấy doctor_id tương ứng với schedule_id để validate update.
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

    /**
     * Validates hard schedule constraints shared by manual and AI scheduling.
     */
    private String validateScheduleConstraints(Connection connection,
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

        int shiftCount = countNonCancelledSchedulesInDay(connection, doctorId, workDate, excludeScheduleId);
        if (shiftCount >= MAX_SHIFTS_PER_DOCTOR_PER_DAY) {
            return "Bác sĩ đã có 2 ca trực trong ngày này.";
        }

        return null;
    }

    // Đếm số ca trong ngày của bác sĩ (không tính Cancelled).
    // Đếm số ca trong ngày của bác sĩ, bỏ qua những ca đã hủy.
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

    // Kiểm tra overlap theo khoảng thời gian thực trong cùng ngày.
    // Kiểm tra ca mới có chồng lấp với bất kỳ ca nào khác trong cùng ngày không.
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

    // Chuẩn hóa chuỗi timeSlot về dạng HH:mm-HH:mm không có khoảng trắng thừa.
    private String normalizeTimeSlot(String timeSlot) {
        if (timeSlot == null) {
            return null;
        }
        String compact = timeSlot.trim().replaceAll("\\s+", "");
        LocalTime[] range = parseTimeSlotRange(compact);
        return range == null ? null : compact;
    }

    // Tách timeSlot thành giờ bắt đầu và kết thúc để so sánh overlap.
    private LocalTime[] parseTimeSlotRange(String timeSlot) {
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

    // Viết hoa chữ cái đầu, dùng cho một số nhãn hiển thị nội bộ.
    private String toTitleCase(String value) {
        if (value == null || value.isBlank()) {
            return "";
        }
        String lower = value.toLowerCase(Locale.ROOT);
        return Character.toUpperCase(lower.charAt(0)) + lower.substring(1);
    }

    private void bindParams(PreparedStatement statement, List<Object> params) throws SQLException {
        for (int i = 0; i < params.size(); i++) {
            Object param = params.get(i);
            int idx = i + 1;
            if (param instanceof Integer) {
                statement.setInt(idx, (Integer) param);
            } else if (param instanceof BigDecimal) {
                statement.setBigDecimal(idx, (BigDecimal) param);
            } else if (param instanceof Date) {
                statement.setDate(idx, (Date) param);
            } else if (param instanceof Timestamp) {
                statement.setTimestamp(idx, (Timestamp) param);
            } else {
                statement.setString(idx, String.valueOf(param));
            }
        }
    }
}








