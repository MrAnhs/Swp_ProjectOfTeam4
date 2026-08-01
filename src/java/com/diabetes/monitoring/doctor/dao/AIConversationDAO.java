package com.diabetes.monitoring.doctor.dao;

import com.diabetes.monitoring.doctor.model.AIConversation;
import com.diabetes.monitoring.util.DatabaseConnection;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class AIConversationDAO {

    public int createConversation(int patientId, String chatHistory, String aiSummary)
            throws SQLException {
        String sql = "INSERT INTO AI_Conversation "
                + "(patient_id, chat_history, ai_summary, created_at) "
                + "VALUES (?, ?, ?, GETDATE())";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, patientId);
            ps.setString(2, chatHistory == null ? "[]" : chatHistory);
            ps.setString(3, aiSummary);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }
        throw new SQLException("Khong the tao hoi thoai AI");
    }

    public boolean updateConversation(
            int conversationId,
            int patientId,
            String chatHistory,
            String aiSummary) {
        String sql = "UPDATE AI_Conversation SET chat_history = ?, ai_summary = ?, "
                + "created_at = GETDATE() "
                + "WHERE conversation_id = ? AND patient_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, chatHistory);
            ps.setString(2, aiSummary);
            ps.setInt(3, conversationId);
            ps.setInt(4, patientId);
            return ps.executeUpdate() == 1;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public List<AIConversation> getConversationsByPatient(int patientId) {
        List<AIConversation> conversations = new ArrayList<>();
        AIConversation latest = getLatestConversationByPatient(patientId);
        if (latest != null) {
            conversations.add(latest);
        }
        return conversations;
    }

    public AIConversation getLatestConversationByPatient(int patientId) {
        return getConversationByRecordOrPatient(0, patientId);
    }

    public AIConversation getConversationByRecordOrPatient(int recordId, int patientId) {
        try (Connection conn = DatabaseConnection.getConnection()) {
            AIConversation result = null;

            // 1. Try by health_record_id first across candidate queries
            if (recordId > 0) {
                result = tryQueries(conn, recordId, patientId, true);
                if (result != null) {
                    return result;
                }
            }

            // 2. Fallback to latest by patient_id across candidate queries
            result = tryQueries(conn, recordId, patientId, false);
            if (result != null) {
                return result;
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    private AIConversation tryQueries(Connection conn, int recordId, int patientId, boolean byRecordId) {
        String[][] queryTemplates = {
            // Table AI_Summary
            {"AI_Summary", "ai_summary", "health_record_id = ? AND patient_id = ?"},
            {"AI_Summary", "ai_summary", "patient_id = ?"},
            {"AI_Summary", "AI_Conversation", "health_record_id = ? AND patient_id = ?"},
            {"AI_Summary", "AI_Conversation", "patient_id = ?"},
            {"AI_Summary", "symptoms", "health_record_id = ? AND patient_id = ?"},
            {"AI_Summary", "symptoms", "patient_id = ?"},

            // Table AI_Conversation
            {"AI_Conversation", "ai_summary", "health_record_id = ? AND patient_id = ?"},
            {"AI_Conversation", "ai_summary", "patient_id = ?"},
            {"AI_Conversation", "AI_Conversation", "health_record_id = ? AND patient_id = ?"},
            {"AI_Conversation", "AI_Conversation", "patient_id = ?"},
            {"AI_Conversation", "symptoms", "health_record_id = ? AND patient_id = ?"},
            {"AI_Conversation", "symptoms", "patient_id = ?"},

            // Table Healthy_Record
            {"Healthy_Record", "other_information", "health_record_id = ?"},
            {"Healthy_Record", "other_information", "patient_id = ?"}
        };

        for (String[] q : queryTemplates) {
            String table = q[0];
            String col = q[1];
            String where = q[2];

            boolean isRecordWhere = where.contains("health_record_id");
            if (byRecordId != isRecordWhere) {
                continue;
            }

            String sql = "SELECT TOP 1 " + col + " AS summary_text, created_at FROM " + table
                    + " WHERE " + where + " AND " + col + " IS NOT NULL AND TRIM(" + col + ") <> '' ORDER BY created_at DESC";

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                if (where.contains("health_record_id = ? AND patient_id = ?")) {
                    ps.setInt(1, recordId);
                    ps.setInt(2, patientId);
                } else if (where.contains("health_record_id = ?")) {
                    ps.setInt(1, recordId);
                } else if (where.contains("patient_id = ?")) {
                    ps.setInt(1, patientId);
                }

                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        String text = rs.getString("summary_text");
                        if (text != null && !text.isBlank()) {
                            AIConversation conv = new AIConversation();
                            conv.setPatientId(patientId);
                            conv.setAiSummary(text.trim());
                            conv.setCreatedAt(rs.getTimestamp("created_at"));
                            return conv;
                        }
                    }
                }
            } catch (SQLException ignored) {
                // Table or column doesn't exist in this DB variation, try next template
            }
        }
        return null;
    }

    public boolean saveLatestConversation(
            int patientId, String chatHistory, String aiSummary) {
        AIConversation latest = getLatestConversationByPatient(patientId);
        if (latest != null) {
            return updateConversation(
                    latest.getConversationId(), patientId, chatHistory, aiSummary);
        }
        try {
            return createConversation(patientId, chatHistory, aiSummary) > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
}
