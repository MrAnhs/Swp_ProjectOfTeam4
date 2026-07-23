package com.diabetes.monitoring.admin.scheduling;

import com.diabetes.monitoring.admin.common.AdminJdbcSupport;
import com.diabetes.monitoring.util.DatabaseConnection;

import java.sql.Connection;
import java.sql.Date;
import java.sql.SQLException;
import java.text.Normalizer;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Loads rooms and validates room assignment for schedules.
 */
public class AdminRoomRepository {
    private static final Logger LOGGER =
            Logger.getLogger(AdminRoomRepository.class.getName());

    public List<Map<String, Object>> getActiveRooms() {
        String sql = "SELECT room_id, room_name, location, status "
                + "FROM Room "
                + "WHERE LOWER(LTRIM(RTRIM(COALESCE(status, 'Active')))) = 'active' "
                + "ORDER BY room_id";
        List<Map<String, Object>> rawRooms = AdminJdbcSupport.queryForList(sql, null);
        for (Map<String, Object> r : rawRooms) {
            String roomId = String.valueOf(r.get("room_id"));
            r.put("roomId", roomId);
            r.put("roomNumber", roomId);
            r.put("roomName", r.get("room_name"));
        }
        return rawRooms;
    }

    public List<Map<String, Object>> getActiveDoctorRooms() {
        List<Map<String, Object>> docRooms = new ArrayList<>();
        for (Map<String, Object> room : getActiveRooms()) {
            String id = String.valueOf(room.getOrDefault("roomId", ""));
            if (!"R101".equalsIgnoreCase(id) && !looksLikeLabRoom(room) && !looksLikeReceptionRoom(room)) {
                docRooms.add(room);
            }
        }
        return docRooms;
    }

    public List<Map<String, Object>> getActiveLabRooms() {
        List<Map<String, Object>> labRooms = new ArrayList<>();
        for (Map<String, Object> room : getActiveRooms()) {
            if (looksLikeLabRoom(room)) {
                labRooms.add(room);
            }
        }
        return labRooms;
    }

    public boolean isActiveRoom(Connection connection, String roomId) throws SQLException {
        if (roomId == null || roomId.trim().isEmpty()) {
            return false;
        }
        String sql = "SELECT 1 FROM Room WHERE room_id = ? "
                + "AND LOWER(LTRIM(RTRIM(COALESCE(status, 'Active')))) = 'active'";
        Map<String, Object> match = AdminJdbcSupport.queryForMap(connection, sql, Arrays.asList(roomId.trim()));
        return match != null;
    }

    public boolean isActiveLabRoom(Connection connection, String roomId) throws SQLException {
        if (roomId == null || roomId.trim().isEmpty()) {
            return false;
        }
        String sql = "SELECT room_id, room_name, location, status FROM Room WHERE room_id = ? "
                + "AND LOWER(LTRIM(RTRIM(COALESCE(status, 'Active')))) = 'active'";
        Map<String, Object> r = AdminJdbcSupport.queryForMap(connection, sql, Arrays.asList(roomId.trim()));
        if (r == null) {
            return false;
        }
        r.put("roomId", r.get("room_id"));
        r.put("roomNumber", r.get("room_id"));
        r.put("roomName", r.get("room_name"));
        return looksLikeLabRoom(r);
    }

    public boolean hasRoomOverlap(Connection connection,
            String roomId,
            Date workDate,
            String timeSlot,
            Integer excludeDoctorScheduleId,
            Integer excludeStaffScheduleId) throws SQLException {

        if (roomId == null || roomId.trim().isEmpty() || workDate == null || timeSlot == null) {
            return false;
        }
        LocalTime[] range = parseTimeSlotRange(timeSlot);
        if (range == null) {
            return true;
        }
        if (hasDoctorRoomOverlap(connection, roomId, workDate, range, excludeDoctorScheduleId)) {
            return true;
        }
        return hasStaffRoomOverlap(connection, roomId, workDate, range, excludeStaffScheduleId);
    }

    private boolean hasDoctorRoomOverlap(Connection connection,
            String roomId,
            Date workDate,
            LocalTime[] range,
            Integer excludeScheduleId) throws SQLException {

        String sql = "SELECT COUNT(*) AS overlap_count "
                + "FROM Doctor_Schedule ds "
                + "WHERE ds.room_id = ? AND ds.work_date = ? "
                + "AND LOWER(ds.status) <> 'cancelled' "
                + "AND (? IS NULL OR ds.schedule_id <> ?) "
                + "AND TRY_CONVERT(time, LEFT(LTRIM(RTRIM(ds.time_slot)), 5)) < ? "
                + "AND ? < TRY_CONVERT(time, LEFT(LTRIM(RTRIM(SUBSTRING(ds.time_slot, CHARINDEX('-', ds.time_slot) + 1, 20))), 5))";
        
        List<Object> params = Arrays.asList(
                roomId.trim(),
                workDate,
                excludeScheduleId,
                excludeScheduleId,
                range[1].toString(),
                range[0].toString()
        );
        Map<String, Object> row = AdminJdbcSupport.queryForMap(connection, sql, params);
        if (row != null) {
            Object count = row.get("overlap_count");
            if (count instanceof Number) {
                return ((Number) count).intValue() > 0;
            }
        }
        return false;
    }

    private boolean hasStaffRoomOverlap(Connection connection,
            String roomId,
            Date workDate,
            LocalTime[] range,
            Integer excludeScheduleId) throws SQLException {

        int dbExcludeId = (excludeScheduleId != null && excludeScheduleId <= 1000000) ? excludeScheduleId : -1;
        String sql = "SELECT COUNT(*) AS overlap_count "
                + "FROM Lab_Schedule ss "
                + "WHERE ss.room_id = ? AND ss.work_date = ? "
                + "AND LOWER(ss.status) <> 'cancelled' "
                + "AND (? = -1 OR ss.lab_sched_id <> ?) "
                + "AND TRY_CONVERT(time, LEFT(LTRIM(RTRIM(ss.time_slot)), 5)) < ? "
                + "AND ? < TRY_CONVERT(time, LEFT(LTRIM(RTRIM(SUBSTRING(ss.time_slot, CHARINDEX('-', ss.time_slot) + 1, 20))), 5))";

        List<Object> params = Arrays.asList(
                roomId.trim(),
                workDate,
                dbExcludeId,
                dbExcludeId,
                range[1].toString(),
                range[0].toString()
        );
        Map<String, Object> row = AdminJdbcSupport.queryForMap(connection, sql, params);
        if (row != null) {
            Object count = row.get("overlap_count");
            if (count instanceof Number) {
                return ((Number) count).intValue() > 0;
            }
        }
        return false;
    }

    private boolean looksLikeLabRoom(Map<String, Object> room) {
        String text = String.valueOf(room.getOrDefault("roomId", ""))
                + " " + String.valueOf(room.getOrDefault("roomNumber", ""))
                + " " + String.valueOf(room.getOrDefault("roomName", ""))
                + " " + String.valueOf(room.getOrDefault("location", ""));
        String normalized = normalizeSearchText(text);
        return normalized.contains("xet nghiem")
                || normalized.contains("lab")
                || normalized.contains("laboratory")
                || normalized.contains("phong xn")
                || normalized.matches(".*\\bxn\\b.*");
    }

    private boolean looksLikeReceptionRoom(Map<String, Object> room) {
        String text = String.valueOf(room.getOrDefault("roomId", ""))
                + " " + String.valueOf(room.getOrDefault("roomNumber", ""))
                + " " + String.valueOf(room.getOrDefault("roomName", ""))
                + " " + String.valueOf(room.getOrDefault("location", ""));
        String normalized = normalizeSearchText(text);
        return normalized.contains("quay")
                || normalized.contains("reception")
                || "r101".equalsIgnoreCase(String.valueOf(room.getOrDefault("roomId", "")));
    }

    private String normalizeSearchText(String value) {
        String normalized = Normalizer.normalize(value == null ? "" : value,
                Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .replace('đ', 'd')
                .replace('Đ', 'D')
                .toLowerCase();
        return normalized.replaceAll("[^a-z0-9]+", " ").trim();
    }

    private LocalTime[] parseTimeSlotRange(String timeSlot) {
        String[] parts = timeSlot.split("-", 2);
        if (parts.length != 2) {
            return null;
        }
        try {
            LocalTime start = LocalTime.parse(parts[0]);
            LocalTime end = LocalTime.parse(parts[1]);
            return start.isBefore(end) ? new LocalTime[]{start, end} : null;
        } catch (RuntimeException ex) {
            return null;
        }
    }

    public List<Map<String, Object>> getAllRooms(String search, String status) {
        StringBuilder sql = new StringBuilder("SELECT room_id, room_name, location, status FROM Room WHERE 1=1");
        List<Object> params = new ArrayList<>();

        if (search != null && !search.trim().isEmpty()) {
            sql.append(" AND (room_id LIKE ? OR room_name LIKE ? OR location LIKE ?)");
            String like = "%" + search.trim() + "%";
            params.add(like);
            params.add(like);
            params.add(like);
        }

        if (status != null && !status.trim().isEmpty()) {
            sql.append(" AND LOWER(status) = LOWER(?)");
            params.add(status.trim());
        }

        sql.append(" ORDER BY room_id");

        List<Map<String, Object>> rawRooms = AdminJdbcSupport.queryForList(sql.toString(), params);
        for (Map<String, Object> r : rawRooms) {
            String roomId = String.valueOf(r.get("room_id"));
            r.put("roomId", roomId);
            r.put("roomNumber", roomId);
            r.put("roomName", r.get("room_name"));
        }
        return rawRooms;
    }

    public Map<String, Object> getRoomById(String roomId) {
        if (roomId == null || roomId.trim().isEmpty()) {
            return null;
        }
        String sql = "SELECT room_id, room_name, location, status FROM Room WHERE room_id = ?";
        Map<String, Object> r = AdminJdbcSupport.queryForMap(sql, Arrays.asList(roomId.trim()));
        if (r != null) {
            String id = String.valueOf(r.get("room_id"));
            r.put("roomId", id);
            r.put("roomNumber", id);
            r.put("roomName", r.get("room_name"));
        }
        return r;
    }

    public boolean createRoom(String roomId, String roomName, String location, String status) {
        if (roomId == null || roomId.trim().isEmpty() || roomName == null || roomName.isBlank()) {
            return false;
        }
        String sql = "INSERT INTO Room (room_id, room_name, location, status) VALUES (?, ?, ?, ?)";
        return AdminJdbcSupport.update(sql, Arrays.asList(
                roomId.trim(),
                roomName.trim(),
                location != null ? location.trim() : "",
                status != null ? status.trim() : "Active"
        )) > 0;
    }

    public boolean updateRoom(String roomId, String roomName, String location, String status) {
        if (roomId == null || roomId.trim().isEmpty() || roomName == null || roomName.isBlank()) {
            return false;
        }
        String sql = "UPDATE Room SET room_name = ?, location = ?, status = ? WHERE room_id = ?";
        return AdminJdbcSupport.update(sql, Arrays.asList(
                roomName.trim(),
                location != null ? location.trim() : "",
                status != null ? status.trim() : "Active",
                roomId.trim()
        )) > 0;
    }

    public boolean deleteRoom(String roomId) {
        if (roomId == null || roomId.trim().isEmpty()) {
            return false;
        }
        String softDeleteSql = "UPDATE Room SET status = 'Inactive' WHERE room_id = ?";
        return AdminJdbcSupport.update(softDeleteSql, Arrays.asList(roomId.trim())) > 0;
    }
}
