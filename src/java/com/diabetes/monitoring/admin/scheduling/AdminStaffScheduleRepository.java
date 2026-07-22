package com.diabetes.monitoring.admin.scheduling;

import com.diabetes.monitoring.util.DatabaseConnection;
import static com.diabetes.monitoring.admin.common.AdminJdbcSupport.bindParams;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Tinh gọn Repository cho Staff_Schedule. Chỉ chứa các phương thức CRUD chính.
 * Đã cấu hình lại để truy vấn trực tiếp vào Lab_Schedule và Reception_Schedule thay cho Staff_Schedule.
 */
public class AdminStaffScheduleRepository {
    private static final Logger LOGGER = Logger.getLogger(AdminStaffScheduleRepository.class.getName());

    private int getLabIdByAccountId(Connection conn, int accountId) throws SQLException {
        String sql = "SELECT lab_id FROM Doctor_Lab WHERE account_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt("lab_id") : 0;
            }
        }
    }

    private int getReceptionIdByAccountId(Connection conn, int accountId) throws SQLException {
        String sql = "SELECT reception_id FROM Reception WHERE account_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt("reception_id") : 0;
            }
        }
    }

    public List<Map<String, Object>> findStaff(String role) {
        List<Map<String, Object>> rows = new ArrayList<>();
        if (role == null) {
            return rows;
        }
        String sql = "SELECT account_id, full_name, email, role "
                + "FROM Account "
                + "WHERE LOWER(LTRIM(RTRIM(status))) = 'active' "
                + "AND LOWER(REPLACE(REPLACE(LTRIM(RTRIM(role)), '-', '_'), ' ', '_')) = ? "
                + "ORDER BY full_name";
        try (Connection connection = DatabaseConnection.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, role.toLowerCase());
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("accountId", rs.getInt("account_id"));
                    row.put("fullName", rs.getString("full_name"));
                    row.put("email", rs.getString("email"));
                    row.put("role", rs.getString("role"));
                    rows.add(row);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to find staff", e);
        }
        return rows;
    }

    private String getSubqueryForStaffType(String staffType) {
        if ("doctor_lab".equalsIgnoreCase(staffType)) {
            return "(SELECT 'doctor_lab' AS staff_type, ls.lab_sched_id AS staff_schedule_id, dl.account_id, "
                 + "ls.work_date, ls.time_slot, N'Xét nghiệm' AS department, NULL AS work_area, 50 AS max_workload, "
                 + "ls.status, 'AI' AS schedule_source, ls.room_id, CAST(NULL AS datetime) AS created_at "
                 + "FROM Lab_Schedule ls JOIN Doctor_Lab dl ON dl.lab_id = ls.lab_id) ss";
        } else if ("receptionist".equalsIgnoreCase(staffType)) {
            return "(SELECT 'receptionist' AS staff_type, rs.reception_sched_id + 1000000 AS staff_schedule_id, rec.account_id, "
                 + "rs.work_date, rs.time_slot, N'Tiếp nhận' AS department, NULL AS work_area, 50 AS max_workload, "
                 + "rs.status, 'AI' AS schedule_source, NULL AS room_id, CAST(NULL AS datetime) AS created_at "
                 + "FROM Reception_Schedule rs JOIN Reception rec ON rec.reception_id = rs.reception_id) ss";
        } else {
            return "(SELECT 'doctor_lab' AS staff_type, ls.lab_sched_id AS staff_schedule_id, dl.account_id, "
                 + "ls.work_date, ls.time_slot, N'Xét nghiệm' AS department, NULL AS work_area, 50 AS max_workload, "
                 + "ls.status, 'AI' AS schedule_source, ls.room_id, CAST(NULL AS datetime) AS created_at "
                 + "FROM Lab_Schedule ls JOIN Doctor_Lab dl ON dl.lab_id = ls.lab_id "
                 + "UNION ALL "
                 + "SELECT 'receptionist' AS staff_type, rs.reception_sched_id + 1000000 AS staff_schedule_id, rec.account_id, "
                 + "rs.work_date, rs.time_slot, N'Tiếp nhận' AS department, NULL AS work_area, 50 AS max_workload, "
                 + "rs.status, 'AI' AS schedule_source, NULL AS room_id, CAST(NULL AS datetime) AS created_at "
                 + "FROM Reception_Schedule rs JOIN Reception rec ON rec.reception_id = rs.reception_id) ss";
        }
    }

    public AdminSchedulePage findSchedules(String staffType,
            String staffName,
            String department,
            Date workDate,
            String status,
            String viewMode,
            String sortBy,
            String sortDir,
            int page,
            int pageSize) {

        int finalPageSize = (pageSize == 20 || pageSize == 50) ? pageSize : 10;
        int finalPage = Math.max(1, page);

        String subquery = getSubqueryForStaffType(staffType);

        StringBuilder fromWhere = new StringBuilder(
                " FROM " + subquery + " "
                + "JOIN Account a ON a.account_id = ss.account_id "
                + "LEFT JOIN Room r ON r.room_id = ss.room_id "
                + "WHERE 1=1");
        List<Object> params = new ArrayList<>();
        appendFilters(fromWhere, params, staffType, staffName, department, workDate, status, viewMode);

        int totalRecords = countRows("SELECT COUNT(*)" + fromWhere, params);
        int totalPages = Math.max(1, (int) Math.ceil(totalRecords / (double) finalPageSize));
        finalPage = Math.min(finalPage, totalPages);
        int offset = (finalPage - 1) * finalPageSize;

        String startTimeExpression = "TRY_CONVERT(time, LEFT(LTRIM(RTRIM(ss.time_slot)), 5))";
        String endTimeExpression = "TRY_CONVERT(time, LEFT(LTRIM(RTRIM(SUBSTRING(ss.time_slot, CHARINDEX('-', ss.time_slot) + 1, 20))), 5))";
        
        String orderBy;
        if ("workDate".equalsIgnoreCase(sortBy)) {
            if ("desc".equalsIgnoreCase(sortDir)) {
                orderBy = " ORDER BY ss.work_date DESC, " + endTimeExpression + " DESC, ss.staff_schedule_id DESC ";
            } else {
                orderBy = " ORDER BY ss.work_date ASC, " + startTimeExpression + " ASC, ss.staff_schedule_id ASC ";
            }
        } else if ("fullName".equalsIgnoreCase(sortBy)) {
            if ("desc".equalsIgnoreCase(sortDir)) {
                orderBy = " ORDER BY a.full_name DESC, ss.work_date DESC, ss.staff_schedule_id DESC ";
            } else {
                orderBy = " ORDER BY a.full_name ASC, ss.work_date ASC, ss.staff_schedule_id ASC ";
            }
        } else {
            orderBy = "history".equalsIgnoreCase(viewMode)
                    ? " ORDER BY ss.work_date DESC, " + endTimeExpression + " DESC, ss.staff_schedule_id DESC "
                    : " ORDER BY ss.work_date ASC, " + startTimeExpression + " ASC, ss.staff_schedule_id ASC ";
        }
        String sql = "SELECT ss.staff_schedule_id, ss.account_id, a.full_name, a.email, "
                + "ss.staff_type, ss.work_date, ss.time_slot, ss.department, ss.work_area, "
                + "ss.max_workload, ss.status, ss.schedule_source, ss.created_at, "
                + "ss.room_id, r.room_id AS room_number, r.room_name "
                + fromWhere
                + orderBy
                + "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";

        List<Map<String, Object>> rows = new ArrayList<>();
        try (Connection connection = DatabaseConnection.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            List<Object> queryParams = new ArrayList<>(params);
            queryParams.add(offset);
            queryParams.add(finalPageSize);
            bindParams(statement, queryParams);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    rows.add(mapStaffSchedule(rs));
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to find paged staff schedules", e);
        }
        return new AdminSchedulePage(rows, finalPage, finalPageSize, totalRecords);
    }

    public List<Map<String, Object>> findSchedules(String staffType,
            String staffName,
            String department,
            Date workDate) {

        List<Map<String, Object>> rows = new ArrayList<>();
        String subquery = getSubqueryForStaffType(staffType);

        StringBuilder sql = new StringBuilder(
                "SELECT ss.staff_schedule_id, ss.account_id, a.full_name, a.email, "
                + "ss.staff_type, ss.work_date, ss.time_slot, ss.department, ss.work_area, "
                + "ss.max_workload, ss.status, ss.schedule_source, ss.created_at, "
                + "ss.room_id, r.room_id AS room_number, r.room_name "
                + "FROM " + subquery + " "
                + "JOIN Account a ON a.account_id = ss.account_id "
                + "LEFT JOIN Room r ON r.room_id = ss.room_id "
                + "WHERE 1=1");
        List<Object> params = new ArrayList<>();

        if (staffType != null && !staffType.trim().isEmpty()) {
            sql.append(" AND ss.staff_type = ?");
            params.add(staffType);
        }
        if (staffName != null && !staffName.trim().isEmpty()) {
            sql.append(" AND LOWER(a.full_name) LIKE ?");
            params.add("%" + staffName.trim().toLowerCase() + "%");
        }
        if (department != null && !department.trim().isEmpty()) {
            sql.append(" AND (ss.department = ? OR ss.work_area = ?)");
            params.add(department.trim());
            params.add(department.trim());
        }
        if (workDate != null) {
            sql.append(" AND ss.work_date = ?");
            params.add(workDate);
        }
        sql.append(" ORDER BY ss.work_date DESC, ss.time_slot ASC, ss.staff_type ASC, a.full_name ASC");

        try (Connection connection = DatabaseConnection.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            bindParams(statement, params);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    rows.add(mapStaffSchedule(rs));
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to find staff schedules", e);
        }
        return rows;
    }

    public Map<String, Object> findById(int staffScheduleId) {
        String sql;
        if (staffScheduleId > 1000000) {
            sql = "SELECT rs.reception_sched_id + 1000000 AS staff_schedule_id, rec.account_id, a.full_name, a.email, "
                + "'receptionist' AS staff_type, rs.work_date, rs.time_slot, N'Tiếp nhận' AS department, NULL AS work_area, "
                + "50 AS max_workload, rs.status, 'AI' AS schedule_source, CAST(NULL AS datetime) AS created_at, "
                + "NULL AS room_id, NULL AS room_number, NULL AS room_name "
                + "FROM Reception_Schedule rs "
                + "JOIN Reception rec ON rec.reception_id = rs.reception_id "
                + "JOIN Account a ON a.account_id = rec.account_id "
                + "WHERE rs.reception_sched_id = ?";
        } else {
            sql = "SELECT ls.lab_sched_id AS staff_schedule_id, dl.account_id, a.full_name, a.email, "
                + "'doctor_lab' AS staff_type, ls.work_date, ls.time_slot, N'Xét nghiệm' AS department, NULL AS work_area, "
                + "50 AS max_workload, ls.status, 'AI' AS schedule_source, CAST(NULL AS datetime) AS created_at, "
                + "ls.room_id, r.room_id AS room_number, r.room_name "
                + "FROM Lab_Schedule ls "
                + "JOIN Doctor_Lab dl ON dl.lab_id = ls.lab_id "
                + "JOIN Account a ON a.account_id = dl.account_id "
                + "LEFT JOIN Room r ON r.room_id = ls.room_id "
                + "WHERE ls.lab_sched_id = ?";
        }
        try (Connection connection = DatabaseConnection.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, staffScheduleId > 1000000 ? staffScheduleId - 1000000 : staffScheduleId);
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next() ? mapStaffSchedule(rs) : null;
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to find staff schedule by id", e);
            return null;
        }
    }

    public boolean insert(int accountId,
            String staffType,
            Date workDate,
            String timeSlot,
            String department,
            String workArea,
            Integer maxWorkload,
            String status,
            String scheduleSource,
            String roomId) throws SQLException {
        try (Connection connection = DatabaseConnection.getConnection()) {
            return insert(connection, accountId, staffType, workDate, timeSlot, department, workArea, maxWorkload, status, scheduleSource, roomId) > 0;
        }
    }

    public int insert(Connection connection,
            int accountId,
            String staffType,
            Date workDate,
            String timeSlot,
            String department,
            String workArea,
            Integer maxWorkload,
            String status,
            String scheduleSource,
            String roomId) throws SQLException {

        if ("doctor_lab".equalsIgnoreCase(staffType)) {
            int labId = getLabIdByAccountId(connection, accountId);
            if (labId <= 0) {
                throw new SQLException("Không tìm thấy thông tin Bác sĩ xét nghiệm cho account_id = " + accountId);
            }
            String sql = "INSERT INTO Lab_Schedule (lab_id, work_date, time_slot, room_id, status) VALUES (?, ?, ?, ?, ?)";
            try (PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
                statement.setInt(1, labId);
                statement.setDate(2, workDate);
                statement.setString(3, timeSlot);
                if (roomId == null || roomId.trim().isEmpty()) {
                    statement.setNull(4, java.sql.Types.VARCHAR);
                } else {
                    statement.setString(4, roomId.trim());
                }
                statement.setString(5, status != null ? status : "Scheduled");
                statement.executeUpdate();
                try (ResultSet keys = statement.getGeneratedKeys()) {
                    return keys.next() ? keys.getInt(1) : 0;
                }
            }
        } else if ("receptionist".equalsIgnoreCase(staffType)) {
            int receptionId = getReceptionIdByAccountId(connection, accountId);
            if (receptionId <= 0) {
                throw new SQLException("Không tìm thấy thông tin Lễ tân cho account_id = " + accountId);
            }
            String sql = "INSERT INTO Reception_Schedule (reception_id, work_date, time_slot, status) VALUES (?, ?, ?, ?)";
            try (PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
                statement.setInt(1, receptionId);
                statement.setDate(2, workDate);
                statement.setString(3, timeSlot);
                statement.setString(4, status != null ? status : "Scheduled");
                statement.executeUpdate();
                try (ResultSet keys = statement.getGeneratedKeys()) {
                    return keys.next() ? (keys.getInt(1) + 1000000) : 0;
                }
            }
        } else {
            throw new SQLException("Vai trò nhân sự không được hỗ trợ lập lịch: " + staffType);
        }
    }

    public boolean update(int staffScheduleId,
            int accountId,
            String staffType,
            Date workDate,
            String timeSlot,
            String department,
            String workArea,
            Integer maxWorkload,
            String status,
            String roomId) throws SQLException {

        try (Connection connection = DatabaseConnection.getConnection()) {
            if (staffScheduleId > 1000000) {
                int receptionId = getReceptionIdByAccountId(connection, accountId);
                if (receptionId <= 0) {
                    throw new SQLException("Không tìm thấy thông tin Lễ tân cho account_id = " + accountId);
                }
                String sql = "UPDATE Reception_Schedule SET reception_id = ?, work_date = ?, time_slot = ?, status = ? "
                           + "WHERE reception_sched_id = ?";
                try (PreparedStatement statement = connection.prepareStatement(sql)) {
                    statement.setInt(1, receptionId);
                    statement.setDate(2, workDate);
                    statement.setString(3, timeSlot);
                    statement.setString(4, status);
                    statement.setInt(5, staffScheduleId - 1000000);
                    return statement.executeUpdate() > 0;
                }
            } else {
                int labId = getLabIdByAccountId(connection, accountId);
                if (labId <= 0) {
                    throw new SQLException("Không tìm thấy thông tin Bác sĩ xét nghiệm cho account_id = " + accountId);
                }
                String sql = "UPDATE Lab_Schedule SET lab_id = ?, work_date = ?, time_slot = ?, room_id = ?, status = ? "
                           + "WHERE lab_sched_id = ?";
                try (PreparedStatement statement = connection.prepareStatement(sql)) {
                    statement.setInt(1, labId);
                    statement.setDate(2, workDate);
                    statement.setString(3, timeSlot);
                    if (roomId == null || roomId.trim().isEmpty()) {
                        statement.setNull(4, java.sql.Types.VARCHAR);
                    } else {
                        statement.setString(4, roomId.trim());
                    }
                    statement.setString(5, status);
                    statement.setInt(6, staffScheduleId);
                    return statement.executeUpdate() > 0;
                }
            }
        }
    }

    public boolean cancel(int staffScheduleId) throws SQLException {
        String sql;
        if (staffScheduleId > 1000000) {
            sql = "UPDATE Reception_Schedule SET status = 'Cancelled' "
                + "WHERE reception_sched_id = ? AND LOWER(status) NOT IN ('cancelled', 'expired', 'completed')";
        } else {
            sql = "UPDATE Lab_Schedule SET status = 'Cancelled' "
                + "WHERE lab_sched_id = ? AND LOWER(status) NOT IN ('cancelled', 'expired', 'completed')";
        }
        try (Connection connection = DatabaseConnection.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, staffScheduleId > 1000000 ? staffScheduleId - 1000000 : staffScheduleId);
            return statement.executeUpdate() > 0;
        }
    }

    public boolean delete(int staffScheduleId) throws SQLException {
        String sql;
        if (staffScheduleId > 1000000) {
            sql = "DELETE FROM Reception_Schedule WHERE reception_sched_id = ?";
        } else {
            sql = "DELETE FROM Lab_Schedule WHERE lab_sched_id = ?";
        }
        try (Connection connection = DatabaseConnection.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, staffScheduleId > 1000000 ? staffScheduleId - 1000000 : staffScheduleId);
            return statement.executeUpdate() > 0;
        }
    }

    public int refreshStaffScheduleStatus() {
        String sqlLab = "UPDATE Lab_Schedule SET status = CASE "
                + "WHEN LOWER(status) = 'cancelled' THEN 'Cancelled' "
                + "WHEN LOWER(status) = 'completed' THEN 'Completed' "
                + "WHEN work_date < CAST(GETDATE() AS DATE) THEN 'Expired' "
                + "WHEN work_date = CAST(GETDATE() AS DATE) "
                + "AND TRY_CONVERT(time, LEFT(LTRIM(RTRIM(SUBSTRING(time_slot, CHARINDEX('-', time_slot) + 1, 20))), 5)) <= CAST(GETDATE() AS time) "
                + "THEN 'Expired' "
                + "ELSE 'Scheduled' END "
                + "WHERE LOWER(status) NOT IN ('cancelled', 'completed')";
        String sqlRec = "UPDATE Reception_Schedule SET status = CASE "
                + "WHEN LOWER(status) = 'cancelled' THEN 'Cancelled' "
                + "WHEN LOWER(status) = 'completed' THEN 'Completed' "
                + "WHEN work_date < CAST(GETDATE() AS DATE) THEN 'Expired' "
                + "WHEN work_date = CAST(GETDATE() AS DATE) "
                + "AND TRY_CONVERT(time, LEFT(LTRIM(RTRIM(SUBSTRING(time_slot, CHARINDEX('-', time_slot) + 1, 20))), 5)) <= CAST(GETDATE() AS time) "
                + "THEN 'Expired' "
                + "ELSE 'Scheduled' END "
                + "WHERE LOWER(status) NOT IN ('cancelled', 'completed')";
        int count = 0;
        try (Connection connection = DatabaseConnection.getConnection()) {
            try (PreparedStatement psLab = connection.prepareStatement(sqlLab)) {
                count += psLab.executeUpdate();
            }
            try (PreparedStatement psRec = connection.prepareStatement(sqlRec)) {
                count += psRec.executeUpdate();
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to refresh staff schedule status", e);
        }
        return count;
    }

    public String getStaffScheduleStatus(int staffScheduleId) throws SQLException {
        String sql;
        if (staffScheduleId > 1000000) {
            sql = "SELECT status FROM Reception_Schedule WHERE reception_sched_id = ?";
        } else {
            sql = "SELECT status FROM Lab_Schedule WHERE lab_sched_id = ?";
        }
        try (Connection connection = DatabaseConnection.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, staffScheduleId > 1000000 ? staffScheduleId - 1000000 : staffScheduleId);
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next() ? rs.getString("status") : null;
            }
        }
    }

    private void appendFilters(StringBuilder sql,
            List<Object> params,
            String staffType,
            String staffName,
            String department,
            Date workDate,
            String status,
            String viewMode) {

        if (staffType != null && !staffType.trim().isEmpty()) {
            sql.append(" AND ss.staff_type = ?");
            params.add(staffType);
        }
        if (staffName != null && !staffName.trim().isEmpty()) {
            sql.append(" AND LOWER(a.full_name) LIKE ?");
            params.add("%" + staffName.trim().toLowerCase() + "%");
        }
        if (department != null && !department.trim().isEmpty()) {
            sql.append(" AND (ss.department = ? OR ss.work_area = ? OR r.room_name = ? OR r.room_id = ?)");
            params.add(department.trim());
            params.add(department.trim());
            params.add(department.trim());
            params.add(department.trim());
        }
        if (workDate != null) {
            sql.append(" AND ss.work_date = ?");
            params.add(workDate);
        }
        if (status != null && !status.trim().isEmpty()) {
            sql.append(" AND LOWER(ss.status) = ?");
            params.add(status.trim().toLowerCase());
        }

        if ("history".equalsIgnoreCase(viewMode)) {
            sql.append(" AND (ss.work_date < CAST(GETDATE() AS DATE) "
                    + "OR LOWER(ss.status) IN ('cancelled', 'expired', 'completed'))");
            if (workDate == null) {
                sql.append(" AND ss.work_date >= DATEADD(day, -30, CAST(GETDATE() AS DATE))");
            }
        } else {
            sql.append(" AND ss.work_date >= CAST(GETDATE() AS DATE) "
                    + "AND LOWER(ss.status) NOT IN ('cancelled', 'expired', 'completed')");
        }
    }

    private int countRows(String sql, List<Object> params) {
        try (Connection connection = DatabaseConnection.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            bindParams(statement, params);
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to count staff schedules", e);
            return 0;
        }
    }

    private Map<String, Object> mapStaffSchedule(ResultSet rs) throws SQLException {
        Map<String, Object> row = new HashMap<>();
        row.put("staffScheduleId", rs.getInt("staff_schedule_id"));
        row.put("accountId", rs.getInt("account_id"));
        row.put("staffName", rs.getString("full_name"));
        row.put("fullName", rs.getString("full_name"));
        row.put("email", rs.getString("email"));
        row.put("staffType", rs.getString("staff_type"));
        row.put("workDate", rs.getDate("work_date"));
        row.put("timeSlot", rs.getString("time_slot"));
        row.put("department", rs.getString("department"));
        row.put("workArea", rs.getString("work_area"));
        int maxWorkload = rs.getInt("max_workload");
        row.put("maxWorkload", rs.wasNull() ? null : maxWorkload);
        String status = rs.getString("status");
        String effectiveStatus = AdminScheduleStatusUtil.getEffectiveStatus(rs.getDate("work_date"),
                rs.getString("time_slot"), status);
        row.put("status", status);
        row.put("effectiveStatus", effectiveStatus);
        row.put("isExpired", "Expired".equalsIgnoreCase(effectiveStatus));
        row.put("isCancelled", "Cancelled".equalsIgnoreCase(effectiveStatus));
        row.put("isCompleted", "Completed".equalsIgnoreCase(effectiveStatus));
        row.put("isEditable", !row.get("isExpired").equals(Boolean.TRUE)
                && !row.get("isCancelled").equals(Boolean.TRUE)
                && !row.get("isCompleted").equals(Boolean.TRUE));
        row.put("scheduleSource", rs.getString("schedule_source"));
        row.put("roomId", rs.getObject("room_id"));
        row.put("roomNumber", rs.getString("room_number"));
        row.put("roomName", rs.getString("room_name"));
        Timestamp createdAt = rs.getTimestamp("created_at");
        row.put("createdAt", createdAt);
        return row;
    }
<<<<<<< Updated upstream
=======

    /**
     * Lấy danh sách ca làm việc dạng Weekly Calendar (Tất cả vai trò: Doctor, Lab, Reception)
     */
    public List<Map<String, Object>> getWeeklyCalendarSchedules(Date startDate, Date endDate, String roleFilter, String roomFilter) {
        List<Map<String, Object>> list = new ArrayList<>();
        String sql = "SELECT * FROM ("
                + "SELECT 'Doctor' AS staff_type, ds.schedule_id AS id, acc.account_id, acc.full_name AS staff, 'Doctor' AS role, "
                + "ISNULL(r.room_name, N'Chưa xếp') AS room, ds.room_id, ds.work_date AS date, "
                + "CASE WHEN LOWER(ds.time_slot) LIKE '%morning%' OR ds.time_slot = '08:00-12:00' OR CAST(LEFT(ds.time_slot, 2) AS INT) < 12 THEN '08:00' ELSE '13:00' END AS start_time, "
                + "CASE WHEN LOWER(ds.time_slot) LIKE '%morning%' OR ds.time_slot = '08:00-12:00' OR CAST(LEFT(ds.time_slot, 2) AS INT) < 12 THEN '12:00' ELSE '17:00' END AS end_time, "
                + "ds.time_slot, ds.status "
                + "FROM Doctor_Schedule ds "
                + "JOIN Doctor d ON d.doctor_id = ds.doctor_id "
                + "JOIN Account acc ON acc.account_id = d.account_id "
                + "LEFT JOIN Room r ON r.room_id = ds.room_id "
                + "WHERE ds.work_date >= ? AND ds.work_date <= ? "
                + "UNION ALL "
                + "SELECT 'Lab' AS staff_type, ls.lab_sched_id AS id, acc.account_id, acc.full_name AS staff, 'Lab' AS role, "
                + "ISNULL(r.room_name, N'Phòng Lab') AS room, ls.room_id, ls.work_date AS date, "
                + "CASE WHEN LOWER(ls.time_slot) LIKE '%morning%' OR ls.time_slot = '08:00-12:00' OR CAST(LEFT(ls.time_slot, 2) AS INT) < 12 THEN '08:00' ELSE '13:00' END AS start_time, "
                + "CASE WHEN LOWER(ls.time_slot) LIKE '%morning%' OR ls.time_slot = '08:00-12:00' OR CAST(LEFT(ls.time_slot, 2) AS INT) < 12 THEN '12:00' ELSE '17:00' END AS end_time, "
                + "ls.time_slot, ls.status "
                + "FROM Lab_Schedule ls "
                + "JOIN Doctor_Lab dl ON dl.lab_id = ls.lab_id "
                + "JOIN Account acc ON acc.account_id = dl.account_id "
                + "LEFT JOIN Room r ON r.room_id = ls.room_id "
                + "WHERE ls.work_date >= ? AND ls.work_date <= ? "
                + "UNION ALL "
                + "SELECT 'Reception' AS staff_type, rs.reception_sched_id AS id, acc.account_id, acc.full_name AS staff, 'Reception' AS role, "
                + "N'Quầy lễ tân' AS room, NULL AS room_id, rs.work_date AS date, "
                + "CASE WHEN LOWER(rs.time_slot) LIKE '%morning%' OR rs.time_slot = '08:00-12:00' OR CAST(LEFT(rs.time_slot, 2) AS INT) < 12 THEN '08:00' ELSE '13:00' END AS start_time, "
                + "CASE WHEN LOWER(rs.time_slot) LIKE '%morning%' OR rs.time_slot = '08:00-12:00' OR CAST(LEFT(rs.time_slot, 2) AS INT) < 12 THEN '12:00' ELSE '17:00' END AS end_time, "
                + "rs.time_slot, rs.status "
                + "FROM Reception_Schedule rs "
                + "JOIN Reception rec ON rec.reception_id = rs.reception_id "
                + "JOIN Account acc ON acc.account_id = rec.account_id "
                + "WHERE rs.work_date >= ? AND rs.work_date <= ? "
                + ") cal WHERE 1=1";

        List<Object> params = new ArrayList<>();
        params.add(startDate);
        params.add(endDate);
        params.add(startDate);
        params.add(endDate);
        params.add(startDate);
        params.add(endDate);

        if (roleFilter != null && !roleFilter.trim().isEmpty() && !"all".equalsIgnoreCase(roleFilter)) {
            String targetRole = roleFilter.trim().toLowerCase();
            if ("receptionist".equals(targetRole)) {
                targetRole = "reception";
            } else if ("doctor_lab".equals(targetRole)) {
                targetRole = "lab";
            }
            sql += " AND LOWER(cal.role) = ?";
            params.add(targetRole);
        }
        if (roomFilter != null && !roomFilter.trim().isEmpty() && !"all".equalsIgnoreCase(roomFilter)) {
            sql += " AND (CAST(cal.room_id AS VARCHAR) = ? OR cal.room LIKE ?)";
            params.add(roomFilter.trim());
            params.add("%" + roomFilter.trim() + "%");
        }

        sql += " ORDER BY cal.date ASC, cal.start_time ASC, cal.role ASC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            bindParams(ps, params);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> map = new HashMap<>();
                    map.put("id", rs.getInt("id"));
                    map.put("staffType", rs.getString("staff_type"));
                    map.put("accountId", rs.getInt("account_id"));
                    map.put("staff", rs.getString("staff"));
                    map.put("role", rs.getString("role"));
                    map.put("room", rs.getString("room"));
                    map.put("roomId", rs.getObject("room_id"));
                    map.put("date", rs.getDate("date").toString());
                    map.put("start", rs.getString("start_time"));
                    map.put("end", rs.getString("end_time"));
                    map.put("timeSlot", rs.getString("time_slot"));
                    map.put("status", rs.getString("status") != null ? rs.getString("status") : "Confirmed");
                    map.put("conflict", false);
                    map.put("conflictMessage", "");
                    list.add(map);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to get weekly calendar schedules", e);
        }

        // Phát hiện Conflict (Trùng lịch nhân sự hoặc Trùng phòng khám)
        detectConflicts(list);

        return list;
    }

    private void detectConflicts(List<Map<String, Object>> list) {
        Map<String, List<Map<String, Object>>> staffTimeMap = new HashMap<>();
        Map<String, List<Map<String, Object>>> roomTimeMap = new HashMap<>();

        for (Map<String, Object> item : list) {
            String date = (String) item.get("date");
            String timeSlot = (String) item.get("timeSlot");
            if (timeSlot == null || timeSlot.trim().isEmpty()) {
                timeSlot = (String) item.get("start");
            }
            Integer accountId = (Integer) item.get("accountId");
            Object roomId = item.get("roomId");

            if (accountId != null) {
                String key = date + "_" + timeSlot.trim() + "_ACC_" + accountId;
                staffTimeMap.computeIfAbsent(key, k -> new ArrayList<>()).add(item);
            }
            if (roomId != null && !String.valueOf(roomId).trim().isEmpty()) {
                String key = date + "_" + timeSlot.trim() + "_ROOM_" + roomId;
                roomTimeMap.computeIfAbsent(key, k -> new ArrayList<>()).add(item);
            }
        }

        for (List<Map<String, Object>> group : staffTimeMap.values()) {
            if (group.size() > 1) {
                for (Map<String, Object> item : group) {
                    item.put("conflict", true);
                    String msg = (String) item.get("conflictMessage");
                    msg = (msg == null || msg.isEmpty()) ? "⚠ Nhân viên " + item.get("staff") + " bị xếp trùng 2 ca cùng thời gian (" + item.get("date") + " " + item.get("timeSlot") + ")" : msg;
                    item.put("conflictMessage", msg);
                }
            }
        }

        for (List<Map<String, Object>> group : roomTimeMap.values()) {
            if (group.size() > 1) {
                for (Map<String, Object> item : group) {
                    item.put("conflict", true);
                    String msg = (String) item.get("conflictMessage");
                    msg = (msg == null || msg.isEmpty()) ? "⚠ Phòng " + item.get("room") + " bị xếp trùng 2 ca cùng lúc (" + item.get("date") + " " + item.get("timeSlot") + ")" : msg + " | ⚠ Trùng phòng khám";
                    item.put("conflictMessage", msg);
                }
            }
        }
    }

    public boolean deleteDoctorSchedule(int id) {
        String sql = "DELETE FROM Doctor_Schedule WHERE schedule_id = ?";
        try (Connection conn = DatabaseConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to delete doctor schedule", e);
            return false;
        }
    }

    public boolean deleteLabSchedule(int id) {
        String sql = "DELETE FROM Lab_Schedule WHERE lab_sched_id = ?";
        try (Connection conn = DatabaseConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to delete lab schedule", e);
            return false;
        }
    }

    public boolean deleteReceptionSchedule(int id) {
        String sql = "DELETE FROM Reception_Schedule WHERE reception_sched_id = ?";
        try (Connection conn = DatabaseConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to delete reception schedule", e);
            return false;
        }
    }

    public boolean autoReassignConflictRoom(int id, String staffType) {
        // Tự động tìm phòng rỗng trong cùng ca trực và cập nhật
        String table = "Doctor_Schedule";
        String idCol = "schedule_id";
        if ("Lab".equalsIgnoreCase(staffType)) {
            table = "Lab_Schedule";
            idCol = "lab_sched_id";
        }
        
        String selectSql = "SELECT work_date, time_slot FROM " + table + " WHERE " + idCol + " = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(selectSql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Date date = rs.getDate("work_date");
                    String slot = rs.getString("time_slot");
                    
                    // Tìm phòng rỗng
                    String findEmptyRoom = "SELECT TOP 1 room_id FROM Room WHERE is_active = 1 AND room_id NOT IN ("
                            + "SELECT room_id FROM Doctor_Schedule WHERE work_date = ? AND time_slot = ? AND room_id IS NOT NULL "
                            + "UNION ALL "
                            + "SELECT room_id FROM Lab_Schedule WHERE work_date = ? AND time_slot = ? AND room_id IS NOT NULL"
                            + ")";
                    try (PreparedStatement ps2 = conn.prepareStatement(findEmptyRoom)) {
                        ps2.setDate(1, date);
                        ps2.setString(2, slot);
                        ps2.setDate(3, date);
                        ps2.setString(4, slot);
                        try (ResultSet rs2 = ps2.executeQuery()) {
                            if (rs2.next()) {
                                String emptyRoomId = rs2.getString("room_id");
                                String updateSql = "UPDATE " + table + " SET room_id = ? WHERE " + idCol + " = ?";
                                try (PreparedStatement ps3 = conn.prepareStatement(updateSql)) {
                                    ps3.setString(1, emptyRoomId);
                                    ps3.setInt(2, id);
                                    return ps3.executeUpdate() > 0;
                                }
                            }
                        }
                    }
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to auto reassign conflict room", e);
        }
        return false;
    }

    public boolean autoResolveAllConflicts() {
        // Dọn dẹp tất cả ca trùng trùng doctor/time_slot
        String sqlDoctor = "DELETE FROM Doctor_Schedule WHERE schedule_id NOT IN ("
                + "  SELECT MIN(schedule_id) FROM Doctor_Schedule GROUP BY doctor_id, work_date, time_slot"
                + ")";
        String sqlReception = "DELETE FROM Reception_Schedule WHERE reception_sched_id NOT IN ("
                + "  SELECT MIN(reception_sched_id) FROM Reception_Schedule GROUP BY reception_id, work_date, time_slot"
                + ")";
        String sqlLab = "DELETE FROM Lab_Schedule WHERE lab_sched_id NOT IN ("
                + "  SELECT MIN(lab_sched_id) FROM Lab_Schedule GROUP BY lab_id, work_date, time_slot"
                + ")";

        try (Connection conn = DatabaseConnection.getConnection()) {
            try (PreparedStatement ps = conn.prepareStatement(sqlDoctor)) { ps.executeUpdate(); }
            try (PreparedStatement ps = conn.prepareStatement(sqlReception)) { ps.executeUpdate(); }
            try (PreparedStatement ps = conn.prepareStatement(sqlLab)) { ps.executeUpdate(); }
            return true;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to auto resolve all conflicts", e);
            return false;
        }
    }
>>>>>>> Stashed changes
}
