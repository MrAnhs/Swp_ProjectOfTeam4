package com.diabetes.monitoring.admin.management;

import com.diabetes.monitoring.util.DatabaseConnection;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Repository for Admin medical service catalog operations.
 */
public class AdminMedicalServiceRepository {
    private static final Logger LOGGER = Logger.getLogger(AdminMedicalServiceRepository.class.getName());
    private static final Set<String> ALLOWED_SERVICE_TYPES = new HashSet<>();
    private static final Set<String> ALLOWED_SERVICE_STATUS = new HashSet<>();

    static {
        ALLOWED_SERVICE_TYPES.add("Examination");
        ALLOWED_SERVICE_TYPES.add("Lab_Test");

        ALLOWED_SERVICE_STATUS.add("Active");
        ALLOWED_SERVICE_STATUS.add("Inactive");
    }

    public int getCountTotalServices() {
        return executeCount("SELECT COUNT(*) FROM Medical_Service WHERE status = 'Active'");
    }

    public int getMedicalServicesCount(String search, String serviceType, String status) {
        StringBuilder sql = new StringBuilder("SELECT COUNT(*) FROM Medical_Service WHERE 1=1");
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

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            bindParams(statement, params);
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to count medical services", e);
        }
        return 0;
    }

    public List<Map<String, Object>> getMedicalServices(String search, String serviceType, String status, int page, int pageSize) {
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
        sql.append(" OFFSET ? ROWS FETCH NEXT ? ROWS ONLY");

        int offset = (Math.max(1, page) - 1) * pageSize;
        params.add(offset);
        params.add(pageSize);

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

    public boolean deleteMedicalService(int serviceId) {
        String sql = "UPDATE Medical_Service SET status = 'Inactive' WHERE service_id = ?";
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, serviceId);
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to delete medical service (soft delete)", e);
            return false;
        }
    }

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

    private int executeCount(String sql) {
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {
            return rs.next() ? rs.getInt(1) : 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to execute count query", e);
            return 0;
        }
    }

    private String normalizeServiceType(String serviceType) {
        if (serviceType == null) {
            return null;
        }
        String value = serviceType.trim();
        return ALLOWED_SERVICE_TYPES.contains(value) ? value : null;
    }

    private String normalizeServiceStatus(String status) {
        if (status == null) {
            return null;
        }
        String value = status.trim();
        return ALLOWED_SERVICE_STATUS.contains(value) ? value : null;
    }

    private boolean isAllowedServiceType(String serviceType) {
        return normalizeServiceType(serviceType) != null;
    }

    private boolean isAllowedServiceStatus(String status) {
        return normalizeServiceStatus(status) != null;
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
