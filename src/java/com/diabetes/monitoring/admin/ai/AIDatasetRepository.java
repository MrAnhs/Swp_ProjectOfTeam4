package com.diabetes.monitoring.admin.ai;

import com.diabetes.monitoring.util.DatabaseConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Handles database operations for patient diagnostic datasets used by AI.
 */
public class AIDatasetRepository {

    public int getPendingDatasetCount() {
        String sql = "SELECT COUNT(*) FROM Medical_record mr " +
                     "LEFT JOIN AI_Dataset ad ON mr.record_id = ad.record_id " +
                     "WHERE COALESCE(ad.decision_status, 'Pending') = 'Pending'";
        return executeCount(sql);
    }

    public int getApprovedDatasetCount() {
        String sql = "SELECT COUNT(*) FROM Medical_record mr " +
                     "INNER JOIN AI_Dataset ad ON mr.record_id = ad.record_id " +
                     "WHERE ad.decision_status IN ('Approved', 'Exported')";
        return executeCount(sql);
    }

    public int getTotalDatasetCount() {
        String sql = "SELECT COUNT(*) FROM Medical_record";
        return executeCount(sql);
    }

    private int executeCount(String sql) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    public int getDatasetRecordsCount(String patientIdSearch, String doctorFilter, String statusFilter, String qualityFilter) {
        StringBuilder sql = new StringBuilder(
            "SELECT COUNT(*) FROM Medical_record mr " +
            "JOIN Patient p ON mr.patient_id = p.patient_id " +
            "JOIN Doctor doc ON mr.doctor_id = doc.doctor_id " +
            "JOIN Account d ON doc.account_id = d.account_id " +
            "LEFT JOIN Healthy_Record hr ON mr.health_record_id = hr.health_record_id " +
            "LEFT JOIN AI_Dataset ad ON mr.record_id = ad.record_id WHERE 1=1 "
        );
        List<Object> params = new ArrayList<>();
        buildFilters(sql, params, patientIdSearch, doctorFilter, statusFilter, qualityFilter);

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    public List<Map<String, Object>> getDatasetRecords(String patientIdSearch, String doctorFilter, String statusFilter, String qualityFilter, int page, int pageSize) {
        StringBuilder sql = new StringBuilder(
            "SELECT mr.record_id, p.full_name as patient_name, d.full_name as doctor_name, " +
            "mr.final_diagnosis, COALESCE(ad.decision_status, 'Pending') as decision_status, mr.processed_at, " +
            "p.date_of_birth, hr.bmi, hr.hba1c, hr.chol, hr.ldl, hr.hdl " +
            "FROM Medical_record mr " +
            "JOIN Patient p ON mr.patient_id = p.patient_id " +
            "JOIN Doctor doc ON mr.doctor_id = doc.doctor_id " +
            "JOIN Account d ON doc.account_id = d.account_id " +
            "LEFT JOIN Healthy_Record hr ON mr.health_record_id = hr.health_record_id " +
            "LEFT JOIN AI_Dataset ad ON mr.record_id = ad.record_id WHERE 1=1 "
        );
        List<Object> params = new ArrayList<>();
        buildFilters(sql, params, patientIdSearch, doctorFilter, statusFilter, qualityFilter);

        sql.append(" ORDER BY mr.processed_at DESC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY");
        params.add((page - 1) * pageSize);
        params.add(pageSize);

        List<Map<String, Object>> list = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> map = new HashMap<>();
                    map.put("recordId", rs.getInt("record_id"));
                    map.put("patientName", rs.getString("patient_name"));
                    map.put("doctorName", rs.getString("doctor_name"));
                    map.put("finalDiagnosis", rs.getString("final_diagnosis"));
                    map.put("decisionStatus", rs.getString("decision_status"));
                    map.put("processedAt", rs.getTimestamp("processed_at"));
                    
                    // Validate data indicators (Only HbA1c, BMI, and Age/DOB are mandatory for training)
                    java.sql.Date dob = rs.getDate("date_of_birth");
                    java.math.BigDecimal bmi = rs.getBigDecimal("bmi");
                    java.math.BigDecimal hba1c = rs.getBigDecimal("hba1c");
                    
                    int age = -1;
                    if (dob != null) {
                        java.util.Calendar birth = java.util.Calendar.getInstance();
                        birth.setTime(dob);
                        java.util.Calendar today = java.util.Calendar.getInstance();
                        age = today.get(java.util.Calendar.YEAR) - birth.get(java.util.Calendar.YEAR);
                        if (today.get(java.util.Calendar.DAY_OF_YEAR) < birth.get(java.util.Calendar.DAY_OF_YEAR)) {
                            age--;
                        }
                    }
                    
                    boolean isValid = (dob != null) 
                            && (bmi != null && bmi.doubleValue() > 0)
                            && (hba1c != null && hba1c.doubleValue() > 0);
                            
                    map.put("isValid", isValid);
                    map.put("bmi", bmi);
                    map.put("hba1c", hba1c);
                    map.put("age", age >= 0 ? age : "Chưa rõ");
                    list.add(map);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    private void buildFilters(StringBuilder sql, List<Object> params, String patientIdSearch, String doctorFilter, String statusFilter, String qualityFilter) {
        if (patientIdSearch != null && !patientIdSearch.trim().isEmpty()) {
            sql.append(" AND CAST(mr.patient_id AS VARCHAR) LIKE ?");
            params.add("%" + patientIdSearch.trim() + "%");
        }
        if (doctorFilter != null && !doctorFilter.trim().isEmpty() && !"all".equalsIgnoreCase(doctorFilter)) {
            sql.append(" AND CAST(mr.doctor_id AS VARCHAR) = ?");
            params.add(doctorFilter.trim());
        }
        if (statusFilter != null && !statusFilter.trim().isEmpty() && !"all".equalsIgnoreCase(statusFilter)) {
            if ("Pending".equalsIgnoreCase(statusFilter)) {
                sql.append(" AND (ad.decision_status IS NULL OR ad.decision_status = 'Pending')");
            } else {
                sql.append(" AND ad.decision_status = ?");
                params.add(statusFilter.trim());
            }
        }
        if (qualityFilter != null && !qualityFilter.trim().isEmpty() && !"all".equalsIgnoreCase(qualityFilter)) {
            if ("valid".equalsIgnoreCase(qualityFilter)) {
                sql.append(" AND p.date_of_birth IS NOT NULL AND hr.bmi IS NOT NULL AND hr.bmi > 0 AND hr.hba1c IS NOT NULL AND hr.hba1c > 0");
            } else if ("invalid".equalsIgnoreCase(qualityFilter)) {
                sql.append(" AND (p.date_of_birth IS NULL OR hr.bmi IS NULL OR hr.bmi <= 0 OR hr.hba1c IS NULL OR hr.hba1c <= 0)");
            }
        }
    }

    public Map<String, Object> getDatasetRecordDetail(int recordId) {
        String sql = "SELECT mr.record_id, mr.patient_id, p.full_name as patient_name, p.date_of_birth, " +
                     "d.full_name as doctor_name, mr.final_diagnosis, mr.doctor_note, " +
                     "hr.bmi, hr.hba1c, hr.chol, hr.ldl, hr.hdl, " +
                     "ad.decision_status, ad.decision_reason " +
                     "FROM Medical_record mr " +
                     "JOIN Patient p ON mr.patient_id = p.patient_id " +
                     "JOIN Doctor doc ON mr.doctor_id = doc.doctor_id " +
                     "JOIN Account d ON doc.account_id = d.account_id " +
                     "LEFT JOIN Healthy_Record hr ON mr.health_record_id = hr.health_record_id " +
                     "LEFT JOIN AI_Dataset ad ON mr.record_id = ad.record_id " +
                     "WHERE mr.record_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, recordId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Map<String, Object> map = new HashMap<>();
                    map.put("recordId", rs.getInt("record_id"));
                    map.put("patientId", rs.getInt("patient_id"));
                    map.put("patientName", rs.getString("patient_name"));
                    map.put("dateOfBirth", rs.getDate("date_of_birth"));
                    map.put("doctorName", rs.getString("doctor_name"));
                    map.put("finalDiagnosis", rs.getString("final_diagnosis"));
                    map.put("doctorNote", rs.getString("doctor_note"));
                    map.put("bmi", rs.getBigDecimal("bmi"));
                    map.put("hba1c", rs.getBigDecimal("hba1c"));
                    map.put("cholesterol", rs.getBigDecimal("chol"));
                    map.put("ldl", rs.getBigDecimal("ldl"));
                    map.put("hdl", rs.getBigDecimal("hdl"));
                    map.put("decisionStatus", rs.getString("decision_status") == null ? "Pending" : rs.getString("decision_status"));
                    map.put("decisionReason", rs.getString("decision_reason"));
                    return map;
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public boolean updateDatasetDecision(int recordId, String status, String reason, int adminAccountId) {
        String checkSql = "SELECT dataset_id FROM AI_Dataset WHERE record_id = ?";
        try (Connection conn = DatabaseConnection.getConnection()) {
            boolean exists = false;
            try (PreparedStatement ps = conn.prepareStatement(checkSql)) {
                ps.setInt(1, recordId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        exists = true;
                    }
                }
            }

            if (exists) {
                String updateSql = "UPDATE AI_Dataset SET decision_status = ?, decision_reason = ?, decided_by = ?, decided_at = GETDATE(), source_file = 'doctor_feedback.csv', hba1c_valid = ?, bmi_valid = ?, age_valid = ? WHERE record_id = ?";
                try (PreparedStatement ps = conn.prepareStatement(updateSql)) {
                    ps.setString(1, status);
                    ps.setString(2, reason);
                    ps.setInt(3, adminAccountId);
                    setValidationFlags(conn, recordId, ps, 4);
                    ps.setInt(7, recordId);
                    boolean ok = ps.executeUpdate() > 0;
                    if (ok && "Approved".equalsIgnoreCase(status)) {
                        boolean exported = CSVExporter.exportToDoctorFeedback(conn, java.util.Arrays.asList(recordId));
                        if (exported) {
                            String exportSql = "UPDATE AI_Dataset SET decision_status = 'Exported' WHERE record_id = ?";
                            try (PreparedStatement exportPs = conn.prepareStatement(exportSql)) {
                                exportPs.setInt(1, recordId);
                                exportPs.executeUpdate();
                            }
                        }
                    }
                    return ok;
                }
            } else {
                String insertSql = "INSERT INTO AI_Dataset (record_id, decision_status, decision_reason, decided_by, decided_at, source_file, hba1c_valid, bmi_valid, age_valid) VALUES (?, ?, ?, ?, GETDATE(), 'doctor_feedback.csv', ?, ?, ?)";
                try (PreparedStatement ps = conn.prepareStatement(insertSql)) {
                    ps.setInt(1, recordId);
                    ps.setString(2, status);
                    ps.setString(3, reason);
                    ps.setInt(4, adminAccountId);
                    setValidationFlags(conn, recordId, ps, 5);
                    boolean ok = ps.executeUpdate() > 0;
                    if (ok && "Approved".equalsIgnoreCase(status)) {
                        boolean exported = CSVExporter.exportToDoctorFeedback(conn, java.util.Arrays.asList(recordId));
                        if (exported) {
                            String exportSql = "UPDATE AI_Dataset SET decision_status = 'Exported' WHERE record_id = ?";
                            try (PreparedStatement exportPs = conn.prepareStatement(exportSql)) {
                                exportPs.setInt(1, recordId);
                                exportPs.executeUpdate();
                            }
                        }
                    }
                    return ok;
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean updateDatasetDecisionsBulk(List<Integer> recordIds, String status, String reason, int adminAccountId) {
        if (recordIds == null || recordIds.isEmpty()) {
            return false;
        }
        
        String checkSql = "SELECT dataset_id FROM AI_Dataset WHERE record_id = ?";
        String updateSql = "UPDATE AI_Dataset SET decision_status = ?, decision_reason = ?, decided_by = ?, decided_at = GETDATE(), source_file = 'doctor_feedback.csv', hba1c_valid = ?, bmi_valid = ?, age_valid = ? WHERE record_id = ?";
        String insertSql = "INSERT INTO AI_Dataset (record_id, decision_status, decision_reason, decided_by, decided_at, source_file, hba1c_valid, bmi_valid, age_valid) VALUES (?, ?, ?, ?, GETDATE(), 'doctor_feedback.csv', ?, ?, ?)";
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            conn.setAutoCommit(false);
            try (PreparedStatement checkPs = conn.prepareStatement(checkSql);
                 PreparedStatement updatePs = conn.prepareStatement(updateSql);
                 PreparedStatement insertPs = conn.prepareStatement(insertSql)) {
                
                for (int recordId : recordIds) {
                    checkPs.setInt(1, recordId);
                    boolean exists = false;
                    try (ResultSet rs = checkPs.executeQuery()) {
                        if (rs.next()) {
                            exists = true;
                        }
                    }
                    
                    if (exists) {
                        updatePs.setString(1, status);
                        updatePs.setString(2, reason);
                        updatePs.setInt(3, adminAccountId);
                        setValidationFlags(conn, recordId, updatePs, 4);
                        updatePs.setInt(7, recordId);
                        updatePs.addBatch();
                    } else {
                        insertPs.setInt(1, recordId);
                        insertPs.setString(2, status);
                        insertPs.setString(3, reason);
                        insertPs.setInt(4, adminAccountId);
                        setValidationFlags(conn, recordId, insertPs, 5);
                        insertPs.addBatch();
                    }
                }
                
                updatePs.executeBatch();
                insertPs.executeBatch();
                conn.commit();
                if ("Approved".equalsIgnoreCase(status)) {
                    boolean exported = CSVExporter.exportToDoctorFeedback(conn, recordIds);
                    if (exported) {
                        String exportSql = "UPDATE AI_Dataset SET decision_status = 'Exported' WHERE record_id = ?";
                        try (PreparedStatement exportPs = conn.prepareStatement(exportSql)) {
                            for (int id : recordIds) {
                                exportPs.setInt(1, id);
                                exportPs.addBatch();
                            }
                            exportPs.executeBatch();
                            conn.commit();
                        }
                    }
                }
                return true;
            } catch (SQLException ex) {
                conn.rollback();
                throw ex;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    private void setValidationFlags(Connection conn, int recordId, PreparedStatement ps, int offset) throws SQLException {
        String sql = "SELECT p.date_of_birth, hr.bmi, hr.hba1c FROM Medical_record mr " +
                     "JOIN Patient p ON mr.patient_id = p.patient_id " +
                     "LEFT JOIN Healthy_Record hr ON mr.health_record_id = hr.health_record_id " +
                     "WHERE mr.record_id = ?";
        boolean hba1cValid = false;
        boolean bmiValid = false;
        boolean ageValid = false;
        try (PreparedStatement checkPs = conn.prepareStatement(sql)) {
            checkPs.setInt(1, recordId);
            try (ResultSet rs = checkPs.executeQuery()) {
                if (rs.next()) {
                    java.sql.Date dob = rs.getDate("date_of_birth");
                    java.math.BigDecimal bmi = rs.getBigDecimal("bmi");
                    java.math.BigDecimal hba1c = rs.getBigDecimal("hba1c");
                    
                    ageValid = (dob != null);
                    bmiValid = (bmi != null && bmi.doubleValue() > 0);
                    hba1cValid = (hba1c != null && hba1c.doubleValue() > 0);
                }
            }
        }
        ps.setBoolean(offset, hba1cValid);
        ps.setBoolean(offset + 1, bmiValid);
        ps.setBoolean(offset + 2, ageValid);
    }

    public Map<String, Integer> getGlobalPendingCounts() {
        Map<String, Integer> result = new HashMap<>();
        int totalPending = 0;
        int validPending = 0;
        
        String sql = "SELECT mr.record_id, p.date_of_birth, hr.bmi, hr.hba1c " +
                     "FROM Medical_record mr " +
                     "JOIN Patient p ON mr.patient_id = p.patient_id " +
                     "LEFT JOIN Healthy_Record hr ON mr.health_record_id = hr.health_record_id " +
                     "LEFT JOIN AI_Dataset ad ON mr.record_id = ad.record_id " +
                     "WHERE COALESCE(ad.decision_status, 'Pending') = 'Pending'";
                     
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
             while (rs.next()) {
                 totalPending++;
                 java.sql.Date dob = rs.getDate("date_of_birth");
                 java.math.BigDecimal bmi = rs.getBigDecimal("bmi");
                 java.math.BigDecimal hba1c = rs.getBigDecimal("hba1c");
                 boolean isValid = (dob != null) 
                         && (bmi != null && bmi.doubleValue() > 0)
                         && (hba1c != null && hba1c.doubleValue() > 0);
                 if (isValid) {
                     validPending++;
                 }
             }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        result.put("totalPending", totalPending);
        result.put("validPending", validPending);
        result.put("invalidPending", totalPending - validPending);
        return result;
     }

     public boolean approveAllDatasetGlobal(int limit, int adminAccountId) {
         List<Integer> validIds = new java.util.ArrayList<>();
         String sql = "SELECT mr.record_id " +
                      "FROM Medical_record mr " +
                      "JOIN Patient p ON mr.patient_id = p.patient_id " +
                      "LEFT JOIN Healthy_Record hr ON mr.health_record_id = hr.health_record_id " +
                      "LEFT JOIN AI_Dataset ad ON mr.record_id = ad.record_id " +
                      "WHERE COALESCE(ad.decision_status, 'Pending') = 'Pending' " +
                      "AND p.date_of_birth IS NOT NULL " +
                      "AND hr.bmi IS NOT NULL AND hr.bmi > 0 " +
                      "AND hr.hba1c IS NOT NULL AND hr.hba1c > 0 " +
                      "ORDER BY mr.record_id DESC";
         
         try (Connection conn = DatabaseConnection.getConnection()) {
             try (PreparedStatement ps = conn.prepareStatement(sql);
                  ResultSet rs = ps.executeQuery()) {
                  int count = 0;
                  while (rs.next()) {
                      validIds.add(rs.getInt("record_id"));
                      count++;
                      if (limit > 0 && count >= limit) {
                          break;
                      }
                  }
             }
             
             if (validIds.isEmpty()) {
                 return true;
             }
                          return updateDatasetDecisionsBulk(validIds, "Approved", "Duyệt tự động toàn bộ hệ thống", adminAccountId);
          } catch (SQLException e) {
              e.printStackTrace();
          }
          return false;
      }
}
