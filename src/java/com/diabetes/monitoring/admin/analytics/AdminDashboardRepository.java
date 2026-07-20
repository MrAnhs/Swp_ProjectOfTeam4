package com.diabetes.monitoring.admin.analytics;

import com.diabetes.monitoring.util.DatabaseConnection;

import static com.diabetes.monitoring.admin.common.AdminJdbcSupport.hasColumn;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Repository cung cấp KPI, biểu đồ và thông tin quản trị cho Admin Dashboard.
 */
public class AdminDashboardRepository {

    private static final Logger LOGGER =
            Logger.getLogger(AdminDashboardRepository.class.getName());
    private static final Map<String, Boolean> TABLE_CACHE =
            new ConcurrentHashMap<>();

    public BigDecimal getSumPaidRevenue() {
        return executeBigDecimal(
                "SELECT ISNULL(SUM(final_amount), 0) "
                + "FROM Invoice "
                + "WHERE LOWER(status) = 'paid' "
                + "AND CAST(created_at AS DATE) <= CAST(GETDATE() AS DATE)");
    }

    public int getCountCompletedAppointments() {
        return executeCount(
                "SELECT COUNT(*) FROM Appointment "
                + "WHERE LOWER(status) = 'completed'");
    }

    public BigDecimal getSumRevenueToday() {
        return executeBigDecimal(
                "SELECT ISNULL(SUM(final_amount), 0) "
                + "FROM Invoice "
                + "WHERE LOWER(status) = 'paid' "
                + "AND CAST(created_at AS DATE) = CAST(GETDATE() AS DATE)");
    }

    public int getCompletedAppointmentsToday() {
        return executeCount(
                "SELECT COUNT(*) FROM Appointment "
                + "WHERE LOWER(status) = 'completed' "
                + "AND CAST(appointment_time AS DATE) = CAST(GETDATE() AS DATE)");
    }

    public int getTodayPatientsCount() {
        return executeCount(
                "SELECT COUNT(DISTINCT patient_id) FROM Appointment "
                + "WHERE CAST(appointment_time AS DATE) = CAST(GETDATE() AS DATE)");
    }

    public int getTodayAppointmentsCount() {
        return executeCount(
                "SELECT COUNT(*) FROM Appointment "
                + "WHERE CAST(appointment_time AS DATE) = CAST(GETDATE() AS DATE)");
    }

    public int getPatientsWaitingCount() {
        return executeCount(
                "SELECT COUNT(*) FROM Appointment "
                + "WHERE LOWER(status) = 'waiting' "
                + "AND CAST(appointment_time AS DATE) = CAST(GETDATE() AS DATE)");
    }

    public int getPatientsInProgressCount() {
        return executeCount(
                "SELECT COUNT(*) FROM Appointment "
                + "WHERE LOWER(status) = 'in_progress' "
                + "AND CAST(appointment_time AS DATE) = CAST(GETDATE() AS DATE)");
    }

    public int getActiveRoomsCount() {
        return executeCount(
                "SELECT COUNT(*) FROM Room "
                + "WHERE LOWER(status) = 'active'");
    }

    public Map<String, Integer> getAppointmentStatusSummary() {
        Map<String, Integer> stats = new HashMap<>();
        stats.put("waiting", 0);
        stats.put("confirmed", 0);
        stats.put("in_progress", 0);
        stats.put("completed", 0);
        stats.put("cancelled", 0);

        String sql = "SELECT status, COUNT(*) FROM Appointment "
                + "WHERE CAST(appointment_time AS DATE) = CAST(GETDATE() AS DATE) "
                + "GROUP BY status";
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet rs = statement.executeQuery()) {
            while (rs.next()) {
                String status = rs.getString(1);
                int count = rs.getInt(2);
                if (status != null) {
                    String key = status.trim().toLowerCase().replace(" ", "_");
                    stats.put(key, count);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to get appointment status summary", e);
        }
        return stats;
    }

    public List<Map<String, Object>> getRoomQueueSummary() {
        List<Map<String, Object>> queue = new ArrayList<>();
        String sql = "SELECT r.room_id, r.room_name, COUNT(ap.appointment_id) AS queue_count "
                + "FROM Room r "
                + "LEFT JOIN Doctor_Schedule ds ON ds.room_id = r.room_id AND ds.work_date = CAST(GETDATE() AS DATE) "
                + "LEFT JOIN Appointment ap ON ap.schedule_id = ds.schedule_id AND ap.status IN ('waiting', 'confirmed', 'in progress') "
                + "WHERE LOWER(r.status) = 'active' "
                + "GROUP BY r.room_id, r.room_name "
                + "ORDER BY r.room_id";
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet rs = statement.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> item = new HashMap<>();
                item.put("roomId", rs.getString("room_id"));
                item.put("roomName", rs.getString("room_name"));
                item.put("queueCount", rs.getInt("queue_count"));
                queue.add(item);
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to get room queue summary", e);
        }
        return queue;
    }

    public Map<String, Object> getTodayScheduleCounts() {
        Map<String, Object> summary = new HashMap<>();
        int doctorCount = countIfTableExists(
                "Doctor_Schedule",
                "SELECT COUNT(*) FROM Doctor_Schedule "
                + "WHERE work_date = CAST(GETDATE() AS DATE)");
        int receptionistCount = executeCount(
                "SELECT COUNT(*) FROM Reception_Schedule "
                + "WHERE work_date = CAST(GETDATE() AS DATE)");
        int labCount = executeCount(
                "SELECT COUNT(*) FROM Lab_Schedule "
                + "WHERE work_date = CAST(GETDATE() AS DATE)");

        summary.put("doctor", doctorCount);
        summary.put("receptionist", receptionistCount);
        summary.put("lab", labCount);
        summary.put("total", doctorCount + receptionistCount + labCount);
        return summary;
    }

    public Map<String, Object> getScheduleStatusSummary() {
        Map<String, Object> summary = new HashMap<>();
        int available = countIfTableExists(
                "Doctor_Schedule",
                "SELECT COUNT(*) FROM Doctor_Schedule "
                + "WHERE LOWER(status) = 'available'");
        int full = countIfTableExists(
                "Doctor_Schedule",
                "SELECT COUNT(*) FROM Doctor_Schedule "
                + "WHERE LOWER(status) = 'full'");
        int inactive = countIfTableExists(
                "Doctor_Schedule",
                "SELECT COUNT(*) FROM Doctor_Schedule "
                + "WHERE LOWER(status) IN ('cancelled', 'expired')");

        available += executeCount(
                "SELECT COUNT(*) FROM Reception_Schedule "
                + "WHERE LOWER(status) IN ('active', 'available', 'scheduled')");
        available += executeCount(
                "SELECT COUNT(*) FROM Lab_Schedule "
                + "WHERE LOWER(status) IN ('active', 'available', 'scheduled')");
        inactive += executeCount(
                "SELECT COUNT(*) FROM Reception_Schedule "
                + "WHERE LOWER(status) IN ('cancelled', 'expired', 'inactive')");
        inactive += executeCount(
                "SELECT COUNT(*) FROM Lab_Schedule "
                + "WHERE LOWER(status) IN ('cancelled', 'expired', 'inactive')");

        summary.put("available", available);
        summary.put("full", full);
        summary.put("inactive", inactive);
        return summary;
    }

    public List<Map<String, Object>> getRecentAdminActivities(int limit) {
        int safeLimit = Math.max(1, limit);
        List<Map<String, Object>> rows = new ArrayList<>();

        addRecentAccounts(rows, safeLimit);
        addRecentMedicalServices(rows, safeLimit);
        addRecentDoctorSchedules(rows, safeLimit);
        addRecentStaffSchedules(rows, safeLimit);

        rows.sort((left, right) -> {
            Timestamp leftTime = (Timestamp) left.get("time");
            Timestamp rightTime = (Timestamp) right.get("time");
            if (leftTime == null && rightTime == null) {
                return 0;
            }
            if (leftTime == null) {
                return 1;
            }
            if (rightTime == null) {
                return -1;
            }
            return rightTime.compareTo(leftTime);
        });

        if (rows.size() <= safeLimit) {
            return rows;
        }
        return new ArrayList<>(rows.subList(0, safeLimit));
    }

    public List<Map<String, Object>> getDashboardRevenueSeries(
            String granularity) {

        return getDashboardSeries("Invoice", "created_at", "final_amount",
                "status", "Paid", true, granularity);
    }

    public List<Map<String, Object>> getDashboardVisitSeries(
            String granularity) {

        String timeColumn = hasColumn("Appointment", "created_at")
                ? "created_at"
                : "appointment_time";
        return getDashboardSeries("Appointment", timeColumn, "appointment_id",
                "status", "Completed", false, granularity);
    }

    private void addRecentAccounts(List<Map<String, Object>> rows, int limit) {
        String sql = "SELECT TOP (?) full_name, role, created_at "
                + "FROM Account "
                + "WHERE created_at IS NOT NULL "
                + "ORDER BY created_at DESC, account_id DESC";
        try (Connection connection = DatabaseConnection.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, limit);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("icon", "fa-user-plus");
                    row.put("title", "Tài khoản mới");
                    row.put("detail", rs.getString("full_name") + " - "
                            + displayRole(rs.getString("role")));
                    row.put("time", rs.getTimestamp("created_at"));
                    rows.add(row);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Failed to load recent accounts", e);
        }
    }

    private void addRecentMedicalServices(List<Map<String, Object>> rows,
            int limit) {

        String timeColumn = hasColumn("Medical_Service", "updated_at")
                ? "updated_at"
                : (hasColumn("Medical_Service", "created_at")
                        ? "created_at"
                        : null);
        if (timeColumn == null) {
            return;
        }

        String sql = "SELECT TOP (?) service_name, service_type, "
                + timeColumn + " AS activity_time "
                + "FROM Medical_Service "
                + "WHERE " + timeColumn + " IS NOT NULL "
                + "ORDER BY " + timeColumn + " DESC, service_id DESC";
        try (Connection connection = DatabaseConnection.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, limit);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("icon", "fa-stethoscope");
                    row.put("title", "Dịch vụ y tế cập nhật");
                    row.put("detail", safeText(rs.getString("service_name"))
                            + serviceTypeSuffix(rs.getString("service_type")));
                    row.put("time", rs.getTimestamp("activity_time"));
                    rows.add(row);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING,
                    "Failed to load recent medical services", e);
        }
    }

    private void addRecentDoctorSchedules(List<Map<String, Object>> rows,
            int limit) {

        if (!hasColumn("Doctor_Schedule", "created_at")) {
            return;
        }
        String sql = "SELECT TOP (?) a.full_name, ds.work_date, ds.time_slot, "
                + "ds.status, ds.created_at "
                + "FROM Doctor_Schedule ds "
                + "LEFT JOIN Doctor d ON ds.doctor_id = d.doctor_id "
                + "LEFT JOIN Account a ON d.account_id = a.account_id "
                + "WHERE ds.created_at IS NOT NULL "
                + "ORDER BY ds.created_at DESC, ds.schedule_id DESC";
        try (Connection connection = DatabaseConnection.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, limit);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    String status = rs.getString("status");
                    row.put("icon", isCancelled(status)
                            ? "fa-calendar-xmark"
                            : "fa-calendar-plus");
                    row.put("title", isCancelled(status)
                            ? "Lịch bác sĩ bị hủy"
                            : "Lịch bác sĩ mới");
                    row.put("detail", buildScheduleDetail(
                            rs.getString("full_name"),
                            rs.getDate("work_date"),
                            rs.getString("time_slot")));
                    row.put("time", rs.getTimestamp("created_at"));
                    rows.add(row);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING,
                    "Failed to load recent doctor schedules", e);
        }
    }

    private void addRecentStaffSchedules(List<Map<String, Object>> rows,
            int limit) {

        String sql = "SELECT TOP (?) * FROM ("
                + "  SELECT dl.full_name, 'doctor_lab' AS staff_type, ls.work_date, ls.time_slot, ls.status, ls.lab_sched_id AS id, CAST(NULL AS datetime) AS created_at "
                + "  FROM Lab_Schedule ls "
                + "  JOIN Doctor_Lab dl ON ls.lab_id = dl.lab_id "
                + "  UNION ALL "
                + "  SELECT rec.full_name, 'receptionist' AS staff_type, rs.work_date, rs.time_slot, rs.status, rs.reception_sched_id AS id, CAST(NULL AS datetime) AS created_at "
                + "  FROM Reception_Schedule rs "
                + "  JOIN Reception rec ON rs.reception_id = rec.reception_id"
                + ") combined "
                + "ORDER BY work_date DESC, id DESC";
        try (Connection connection = DatabaseConnection.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, limit);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    String staffType = rs.getString("staff_type");
                    String status = rs.getString("status");
                    boolean cancelled = isCancelled(status);
                    Map<String, Object> row = new HashMap<>();
                    row.put("icon", cancelled
                            ? "fa-calendar-xmark"
                            : "fa-calendar-plus");
                    row.put("title", cancelled
                            ? displayStaffType(staffType) + " bị hủy"
                            : "Lịch " + displayStaffType(staffType) + " mới");
                    row.put("detail", buildScheduleDetail(
                            rs.getString("full_name"),
                            rs.getDate("work_date"),
                            rs.getString("time_slot")));
                    row.put("time", rs.getTimestamp("created_at"));
                    rows.add(row);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING,
                    "Failed to load recent staff schedules", e);
        }
    }

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
                + "WHERE LOWER(" + statusColumn + ") = LOWER(?) "
                + "AND CAST(" + timeColumn + " AS DATE) <= CAST(GETDATE() AS DATE) "
                + "GROUP BY " + groupByExpr + " "
                + "ORDER BY " + orderByExpr;

        try (Connection connection = DatabaseConnection.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
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

    private String normalizeGranularity(String granularity) {
        String value = granularity == null
                ? "MONTH"
                : granularity.trim().toUpperCase(Locale.ROOT);
        if (!"DAY".equals(value) && !"MONTH".equals(value)
                && !"YEAR".equals(value)) {
            return "MONTH";
        }
        return value;
    }

    private int countIfTableExists(String tableName, String sql) {
        return hasTable(tableName) ? executeCount(sql) : 0;
    }

    private boolean hasTable(String tableName) {
        String cacheKey = tableName.toLowerCase(Locale.ROOT);
        Boolean cached = TABLE_CACHE.get(cacheKey);
        if (cached != null) {
            return cached;
        }

        String sql = "SELECT 1 FROM INFORMATION_SCHEMA.TABLES "
                + "WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = ?";
        boolean exists = false;
        try (Connection connection = DatabaseConnection.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, tableName);
            try (ResultSet rs = statement.executeQuery()) {
                exists = rs.next();
            }
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Failed to check table existence", e);
        }
        TABLE_CACHE.put(cacheKey, exists);
        return exists;
    }

    private int executeCount(String sql) {
        try (Connection connection = DatabaseConnection.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql);
                ResultSet rs = statement.executeQuery()) {
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to execute count query", e);
        }
        return 0;
    }

    private BigDecimal executeBigDecimal(String sql) {
        try (Connection connection = DatabaseConnection.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql);
                ResultSet rs = statement.executeQuery()) {
            if (rs.next()) {
                BigDecimal value = rs.getBigDecimal(1);
                return value == null ? BigDecimal.ZERO : value;
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to execute decimal query", e);
        }
        return BigDecimal.ZERO;
    }

    private String buildScheduleDetail(String name, java.sql.Date workDate,
            String timeSlot) {

        String displayName = safeText(name);
        String date = workDate == null ? "" : workDate.toString();
        String slot = timeSlot == null ? "" : timeSlot;
        String detail = (displayName + " - " + date + " " + slot).trim();
        return detail.endsWith("-") ? displayName : detail;
    }

    private String displayRole(String role) {
        String value = role == null ? "" : role.trim().toLowerCase(Locale.ROOT);
        switch (value) {
            case "admin":
                return "Quản trị viên";
            case "doctor":
                return "Bác sĩ khám";
            case "doctor_lab":
                return "Bác sĩ xét nghiệm";
            case "receptionist":
                return "Lễ tân";
            case "patient":
                return "Bệnh nhân";
            default:
                return safeText(role);
        }
    }

    private String displayStaffType(String staffType) {
        String value = staffType == null
                ? ""
                : staffType.trim().toLowerCase(Locale.ROOT).replace('-', '_');
        if ("receptionist".equals(value)) {
            return "lễ tân";
        }
        if ("doctor_lab".equals(value) || "doctorlab".equals(value)
                || "lab".equals(value)) {
            return "xét nghiệm";
        }
        return "nhân sự";
    }

    private String serviceTypeSuffix(String serviceType) {
        String text = safeText(serviceType);
        return text.isEmpty() ? "" : " - " + text;
    }

    private boolean isCancelled(String status) {
        return status != null && "cancelled".equals(
                status.trim().toLowerCase(Locale.ROOT));
    }

    private String safeText(String value) {
        return value == null ? "" : value.trim();
    }

    public Map<String, Object> getModalDetails(String type, String id) {
        Map<String, Object> result = new HashMap<>();
        List<Map<String, Object>> items = new ArrayList<>();
        result.put("type", type);
        result.put("items", items);

        Connection connection = null;
        PreparedStatement statement = null;
        ResultSet rs = null;

        try {
            connection = DatabaseConnection.getConnection();
            if ("todayPatients".equals(type)) {
                String sql = "SELECT DISTINCT a.account_id, a.full_name, a.email, "
                           + "ap.appointment_id, ds.time_slot "
                           + "FROM Appointment ap "
                           + "JOIN Account a ON a.account_id = ap.patient_id "
                           + "LEFT JOIN Doctor_Schedule ds ON ds.schedule_id = ap.schedule_id "
                           + "WHERE CAST(ap.appointment_time AS DATE) = CAST(GETDATE() AS DATE) "
                           + "ORDER BY ds.time_slot ASC, a.full_name ASC";
                statement = connection.prepareStatement(sql);
                rs = statement.executeQuery();
                while (rs.next()) {
                    Map<String, Object> m = new HashMap<>();
                    m.put("patientId", rs.getString("account_id"));
                    m.put("fullName", rs.getString("full_name"));
                    m.put("email", rs.getString("email"));
                    m.put("appointmentId", rs.getString("appointment_id"));
                    m.put("timeSlot", rs.getString("time_slot"));
                    items.add(m);
                }
            } else if ("todayAppointments".equals(type)) {
                String sql = "SELECT ap.appointment_id, pat.full_name AS patient_name, "
                           + "COALESCE(doc.full_name, 'Chua chi dinh') AS doctor_name, "
                           + "COALESCE(ds.time_slot, FORMAT(ap.appointment_time, 'HH:mm')) AS time_slot, "
                           + "ap.status "
                           + "FROM Appointment ap "
                           + "JOIN Patient p ON p.patient_id = ap.patient_id "
                           + "JOIN Account pat ON pat.account_id = p.account_id "
                           + "LEFT JOIN Doctor_Schedule ds ON ds.schedule_id = ap.schedule_id "
                           + "LEFT JOIN Doctor d ON d.doctor_id = ds.doctor_id "
                           + "LEFT JOIN Account doc ON doc.account_id = d.account_id "
                           + "WHERE CAST(ap.appointment_time AS DATE) = CAST(GETDATE() AS DATE) "
                           + "ORDER BY time_slot ASC";
                statement = connection.prepareStatement(sql);
                rs = statement.executeQuery();
                while (rs.next()) {
                    Map<String, Object> m = new HashMap<>();
                    m.put("appointmentId", rs.getString("appointment_id"));
                    m.put("patientName", rs.getString("patient_name"));
                    m.put("doctorName", rs.getString("doctor_name"));
                    m.put("timeSlot", rs.getString("time_slot"));
                    m.put("status", rs.getString("status"));
                    items.add(m);
                }
            } else if ("sumRevenueToday".equals(type)) {
                String sql = "SELECT iv.invoice_id, p.full_name AS patient_name, iv.final_amount, iv.created_at "
                           + "FROM Invoice iv "
                           + "JOIN Patient p ON p.patient_id = iv.patient_id "
                           + "WHERE LOWER(iv.status) = 'paid' "
                           + "AND CAST(iv.created_at AS DATE) = CAST(GETDATE() AS DATE) "
                           + "ORDER BY iv.created_at DESC";
                statement = connection.prepareStatement(sql);
                rs = statement.executeQuery();
                while (rs.next()) {
                    Map<String, Object> m = new HashMap<>();
                    m.put("invoiceId", rs.getString("invoice_id"));
                    m.put("patientName", rs.getString("patient_name"));
                    m.put("finalAmount", rs.getBigDecimal("final_amount"));
                    m.put("createdAt", rs.getTimestamp("created_at"));
                    items.add(m);
                }
            } else if ("completedAppointmentsToday".equals(type)) {
                String sql = "SELECT ap.appointment_id, pat.full_name AS patient_name, "
                           + "doc.full_name AS doctor_name, "
                           + "COALESCE(ds.time_slot, FORMAT(ap.appointment_time, 'HH:mm')) AS time_slot "
                           + "FROM Appointment ap "
                           + "JOIN Patient p ON p.patient_id = ap.patient_id "
                           + "JOIN Account pat ON pat.account_id = p.account_id "
                           + "LEFT JOIN Doctor_Schedule ds ON ds.schedule_id = ap.schedule_id "
                           + "LEFT JOIN Doctor d ON d.doctor_id = ds.doctor_id "
                           + "LEFT JOIN Account doc ON doc.account_id = d.account_id "
                           + "WHERE LOWER(ap.status) = 'completed' "
                           + "AND CAST(ap.appointment_time AS DATE) = CAST(GETDATE() AS DATE) "
                           + "ORDER BY time_slot ASC";
                statement = connection.prepareStatement(sql);
                rs = statement.executeQuery();
                while (rs.next()) {
                    Map<String, Object> m = new HashMap<>();
                    m.put("appointmentId", rs.getString("appointment_id"));
                    m.put("patientName", rs.getString("patient_name"));
                    m.put("doctorName", rs.getString("doctor_name"));
                    m.put("timeSlot", rs.getString("time_slot"));
                    items.add(m);
                }
            } else if ("waiting".equals(type) || "inProgress".equals(type)) {
                String statusVal = "waiting".equals(type) ? "waiting" : "in_progress";
                String sql = "SELECT ap.appointment_id, pat.full_name AS patient_name, "
                           + "doc.full_name AS doctor_name, r.room_name, "
                           + "COALESCE(ds.time_slot, FORMAT(ap.appointment_time, 'HH:mm')) AS time_slot "
                           + "FROM Appointment ap "
                           + "JOIN Patient p ON p.patient_id = ap.patient_id "
                           + "JOIN Account pat ON pat.account_id = p.account_id "
                           + "LEFT JOIN Doctor_Schedule ds ON ds.schedule_id = ap.schedule_id "
                           + "LEFT JOIN Doctor d ON d.doctor_id = ds.doctor_id "
                           + "LEFT JOIN Account doc ON doc.account_id = d.account_id "
                           + "LEFT JOIN Room r ON r.room_id = ds.room_id "
                           + "WHERE LOWER(ap.status) = ? "
                           + "AND CAST(ap.appointment_time AS DATE) = CAST(GETDATE() AS DATE) "
                           + "ORDER BY time_slot ASC";
                statement = connection.prepareStatement(sql);
                statement.setString(1, statusVal);
                rs = statement.executeQuery();
                while (rs.next()) {
                    Map<String, Object> m = new HashMap<>();
                    m.put("appointmentId", rs.getString("appointment_id"));
                    m.put("patientName", rs.getString("patient_name"));
                    m.put("doctorName", rs.getString("doctor_name"));
                    m.put("roomName", rs.getString("room_name"));
                    m.put("timeSlot", rs.getString("time_slot"));
                    items.add(m);
                }
            } else if ("doctorSchedule".equals(type)) {
                String sql = "SELECT ds.schedule_id, doc.full_name AS doctor_name, r.room_name, ds.time_slot, "
                           + "ds.max_patients, ds.status "
                           + "FROM Doctor_Schedule ds "
                           + "JOIN Doctor d ON d.doctor_id = ds.doctor_id "
                           + "JOIN Account doc ON doc.account_id = d.account_id "
                           + "LEFT JOIN Room r ON r.room_id = ds.room_id "
                           + "WHERE ds.work_date = CAST(GETDATE() AS DATE) "
                           + "ORDER BY ds.time_slot ASC";
                statement = connection.prepareStatement(sql);
                rs = statement.executeQuery();
                while (rs.next()) {
                    Map<String, Object> m = new HashMap<>();
                    m.put("scheduleId", rs.getString("schedule_id"));
                    m.put("doctorName", rs.getString("doctor_name"));
                    m.put("roomName", rs.getString("room_name"));
                    m.put("timeSlot", rs.getString("time_slot"));
                    m.put("maxPatients", rs.getInt("max_patients"));
                    m.put("status", rs.getString("status"));
                    items.add(m);
                }
            } else if ("activeRooms".equals(type)) {
                String sql = "SELECT room_id, room_name, location FROM Room WHERE LOWER(status) = 'active'";
                statement = connection.prepareStatement(sql);
                rs = statement.executeQuery();
                while (rs.next()) {
                    Map<String, Object> m = new HashMap<>();
                    m.put("roomId", rs.getString("room_id"));
                    m.put("roomName", rs.getString("room_name"));
                    m.put("location", rs.getString("location"));
                    items.add(m);
                }
            } else if ("receptionistSchedule".equals(type) || "labSchedule".equals(type)) {
                String roleVal = "receptionistSchedule".equals(type) ? "receptionist" : "doctor_lab";
                String sql;
                if ("receptionist".equals(roleVal)) {
                    sql = "SELECT rs.reception_sched_id AS schedule_id, rec.full_name AS staff_name, rs.time_slot, NULL AS room_name "
                        + "FROM Reception_Schedule rs "
                        + "JOIN Reception rec ON rec.reception_id = rs.reception_id "
                        + "WHERE rs.work_date = CAST(GETDATE() AS DATE) "
                        + "ORDER BY rs.time_slot ASC";
                } else {
                    sql = "SELECT ls.lab_sched_id AS schedule_id, dl.full_name AS staff_name, ls.time_slot, r.room_name "
                        + "FROM Lab_Schedule ls "
                        + "JOIN Doctor_Lab dl ON dl.lab_id = ls.lab_id "
                        + "LEFT JOIN Room r ON r.room_id = ls.room_id "
                        + "WHERE ls.work_date = CAST(GETDATE() AS DATE) "
                        + "ORDER BY ls.time_slot ASC";
                }
                statement = connection.prepareStatement(sql);
                rs = statement.executeQuery();
                while (rs.next()) {
                    Map<String, Object> m = new HashMap<>();
                    m.put("scheduleId", rs.getString("schedule_id"));
                    m.put("staffName", rs.getString("staff_name"));
                    m.put("timeSlot", rs.getString("time_slot"));
                    m.put("roomName", rs.getString("room_name"));
                    items.add(m);
                }
            } else if ("room".equals(type)) {
                // Get Room details
                String roomSql = "SELECT room_id, room_name, location, status FROM Room WHERE room_id = ?";
                statement = connection.prepareStatement(roomSql);
                statement.setString(1, id);
                rs = statement.executeQuery();
                if (rs.next()) {
                    result.put("roomId", rs.getString("room_id"));
                    result.put("roomName", rs.getString("room_name"));
                    result.put("location", rs.getString("location"));
                    result.put("status", rs.getString("status"));
                }
                rs.close();
                statement.close();

                // Get Doctor on duty today
                String docSql = "SELECT doc.full_name FROM Doctor_Schedule ds "
                              + "JOIN Account doc ON doc.account_id = ds.doctor_id "
                              + "WHERE ds.room_id = ? AND ds.work_date = CAST(GETDATE() AS DATE)";
                statement = connection.prepareStatement(docSql);
                statement.setString(1, id);
                rs = statement.executeQuery();
                if (rs.next()) {
                    result.put("doctorName", rs.getString("full_name"));
                } else {
                    result.put("doctorName", "Chua co bac si truc");
                }
                rs.close();
                statement.close();

                // Get patient queue today
                String queueSql = "SELECT ap.appointment_id, pat.full_name AS patient_name, "
                                + "ap.status, COALESCE(ds.time_slot, FORMAT(ap.appointment_time, 'HH:mm')) AS time_slot "
                                + "FROM Appointment ap "
                                + "JOIN Account pat ON pat.account_id = ap.patient_id "
                                + "JOIN Doctor_Schedule ds ON ds.schedule_id = ap.schedule_id "
                                + "WHERE ds.room_id = ? AND ds.work_date = CAST(GETDATE() AS DATE) "
                                + "AND ap.status IN ('waiting', 'confirmed', 'in progress') "
                                + "ORDER BY time_slot ASC";
                statement = connection.prepareStatement(queueSql);
                statement.setString(1, id);
                rs = statement.executeQuery();
                while (rs.next()) {
                    Map<String, Object> m = new HashMap<>();
                    m.put("appointmentId", rs.getString("appointment_id"));
                    m.put("patientName", rs.getString("patient_name"));
                    m.put("status", rs.getString("status"));
                    m.put("timeSlot", rs.getString("time_slot"));
                    items.add(m);
                }
            } else if ("activity".equals(type)) {
                List<Map<String, Object>> activities = getRecentAdminActivities(10);
                for (Map<String, Object> act : activities) {
                    Timestamp t = (Timestamp) act.get("time");
                    String timeStr = t == null ? "" : String.valueOf(t.getTime());
                    if (id != null && (id.equals(timeStr) || id.equals(act.get("detail")))) {
                        result.put("activityTitle", act.get("title"));
                        result.put("activityDetail", act.get("detail"));
                        result.put("activityTime", t);
                        break;
                    }
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to get modal details for type: " + type, e);
        } finally {
            if (rs != null) { try { rs.close(); } catch (SQLException ignore) {} }
            if (statement != null) { try { statement.close(); } catch (SQLException ignore) {} }
            if (connection != null) { try { connection.close(); } catch (SQLException ignore) {} }
        }

        return result;
    }
}



