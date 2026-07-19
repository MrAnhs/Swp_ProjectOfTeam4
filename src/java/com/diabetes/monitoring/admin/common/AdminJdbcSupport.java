package com.diabetes.monitoring.admin.common;

import com.diabetes.monitoring.util.DatabaseConnection;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
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
 * Helper JDBC dùng chung cho các repository của Admin.
 */
public final class AdminJdbcSupport {

    private static final Logger LOGGER =
            Logger.getLogger(AdminJdbcSupport.class.getName());

    private static final Map<String, Boolean> COLUMN_CACHE =
            new ConcurrentHashMap<>();

    private AdminJdbcSupport() {
    }

    public static boolean hasColumn(String tableName, String columnName) {
        String cacheKey = (tableName + "." + columnName)
                .toLowerCase(Locale.ROOT);
        Boolean cached = COLUMN_CACHE.get(cacheKey);
        if (cached != null) {
            return cached;
        }

        String sql = "SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS "
                + "WHERE TABLE_NAME = ? AND COLUMN_NAME = ?";

        boolean exists = false;
        try (Connection connection = DatabaseConnection.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            exists = hasColumn(statement, tableName, columnName);
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Failed to check column existence", e);
        }
        COLUMN_CACHE.put(cacheKey, exists);
        return exists;
    }

    public static boolean hasColumn(
            Connection connection,
            String tableName,
            String columnName) {

        String sql = "SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS "
                + "WHERE TABLE_NAME = ? AND COLUMN_NAME = ?";

        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            return hasColumn(statement, tableName, columnName);
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Failed to check column existence", e);
            return false;
        }
    }

    private static boolean hasColumn(
            PreparedStatement statement,
            String tableName,
            String columnName) throws SQLException {

        statement.setString(1, tableName);
        statement.setString(2, columnName);

        try (ResultSet rs = statement.executeQuery()) {
            return rs.next();
        }
    }

    public static void bindParams(
            PreparedStatement statement,
            List<Object> params) throws SQLException {

        if (params == null) {
            return;
        }
        for (int i = 0; i < params.size(); i++) {
            Object param = params.get(i);
            int idx = i + 1;

            if (param == null) {
                statement.setNull(idx, java.sql.Types.VARCHAR);
            } else if (param instanceof Integer) {
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

    /**
     * Thực thi câu lệnh truy vấn trả về danh sách các bản ghi (mỗi bản ghi là 1 Map).
     */
    public static List<Map<String, Object>> queryForList(String sql, List<Object> params) {
        try (Connection connection = DatabaseConnection.getConnection()) {
            return queryForList(connection, sql, params);
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to get database connection for queryForList. SQL: " + sql, e);
            return new ArrayList<>();
        }
    }

    /**
     * Thực thi truy vấn với Connection có sẵn (thích hợp cho transaction).
     */
    public static List<Map<String, Object>> queryForList(Connection connection, String sql, List<Object> params) {
        List<Map<String, Object>> list = new ArrayList<>();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bindParams(statement, params);
            try (ResultSet rs = statement.executeQuery()) {
                ResultSetMetaData metaData = rs.getMetaData();
                int columnCount = metaData.getColumnCount();
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    for (int i = 1; i <= columnCount; i++) {
                        String columnName = metaData.getColumnLabel(i);
                        Object value = rs.getObject(i);
                        row.put(columnName, value);
                    }
                    list.add(row);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to execute queryForList. SQL: " + sql, e);
        }
        return list;
    }

    /**
     * Thực thi truy vấn trả về duy nhất 1 bản ghi đầu tiên, hoặc null nếu rỗng.
     */
    public static Map<String, Object> queryForMap(String sql, List<Object> params) {
        List<Map<String, Object>> list = queryForList(sql, params);
        return list.isEmpty() ? null : list.get(0);
    }

    public static Map<String, Object> queryForMap(Connection connection, String sql, List<Object> params) {
        List<Map<String, Object>> list = queryForList(connection, sql, params);
        return list.isEmpty() ? null : list.get(0);
    }

    /**
     * Thực thi các lệnh Cập nhật (INSERT, UPDATE, DELETE).
     * Trả về số dòng bị ảnh hưởng.
     */
    public static int update(String sql, List<Object> params) {
        try (Connection connection = DatabaseConnection.getConnection()) {
            return update(connection, sql, params);
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to get database connection for update. SQL: " + sql, e);
            return 0;
        }
    }

    /**
     * Thực thi cập nhật với Connection có sẵn (thích hợp cho transaction).
     */
    public static int update(Connection connection, String sql, List<Object> params) {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bindParams(statement, params);
            return statement.executeUpdate();
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to execute update. SQL: " + sql, e);
            return 0;
        }
    }
}
