package com.diabetes.monitoring.dao;

import com.diabetes.monitoring.model.AIConversation;
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
        String sql = "SELECT conversation_id, patient_id, chat_history, ai_summary, created_at "
                + "FROM AI_Conversation WHERE patient_id = ? ORDER BY created_at DESC";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, patientId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    AIConversation conversation = new AIConversation();
                    conversation.setConversationId(rs.getInt("conversation_id"));
                    conversation.setPatientId(rs.getInt("patient_id"));
                    conversation.setChatHistory(rs.getString("chat_history"));
                    conversation.setAiSummary(rs.getString("ai_summary"));
                    conversation.setCreatedAt(rs.getTimestamp("created_at"));
                    conversations.add(conversation);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return conversations;
    }

    public AIConversation getLatestConversationByPatient(int patientId) {
        String sql = "SELECT TOP 1 conversation_id, patient_id, chat_history, "
                + "ai_summary, created_at FROM AI_Conversation "
                + "WHERE patient_id = ? ORDER BY created_at DESC, conversation_id DESC";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, patientId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    AIConversation conversation = new AIConversation();
                    conversation.setConversationId(rs.getInt("conversation_id"));
                    conversation.setPatientId(rs.getInt("patient_id"));
                    conversation.setChatHistory(rs.getString("chat_history"));
                    conversation.setAiSummary(rs.getString("ai_summary"));
                    conversation.setCreatedAt(rs.getTimestamp("created_at"));
                    return conversation;
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
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
