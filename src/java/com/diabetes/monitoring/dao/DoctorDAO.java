package com.diabetes.monitoring.dao;

import com.diabetes.monitoring.model.DoctorInfo;
import com.diabetes.monitoring.model.DoctorScheduleInfo;
import com.diabetes.monitoring.model.AvailabilitySlot;
import com.diabetes.monitoring.util.DatabaseConnection;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class DoctorDAO {

    public List<DoctorInfo> findActiveDoctors() throws SQLException {
        String sql = "SELECT d.doctor_id, d.full_name, d.phone, d.email, d.department "
                + "FROM Doctor d "
                + "INNER JOIN Account a ON a.account_id = d.account_id "
                + "WHERE a.role = 'Doctor' AND a.status = 'Active' "
                + "ORDER BY d.full_name";
        List<DoctorInfo> doctors = new ArrayList<>();

        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            while (resultSet.next()) {
                doctors.add(mapDoctor(resultSet));
            }
        }
        return doctors;
    }

    public List<DoctorInfo> findAvailableDoctors(LocalDate workDate, String session,
            String doctorName) throws SQLException {
        StringBuilder sql = new StringBuilder(
                "SELECT DISTINCT d.doctor_id, d.full_name, d.phone, d.email, d.department "
                + "FROM Doctor d "
                + "INNER JOIN Account acc ON acc.account_id = d.account_id "
                + "INNER JOIN Doctor_Schedule ds ON ds.doctor_id = d.doctor_id "
                + "CROSS APPLY (SELECT COUNT(*) AS booked_patients FROM Appointment ap "
                + "WHERE ap.schedule_id = ds.schedule_id AND ap.status <> 'Cancelled') booked "
                + "WHERE acc.role = 'Doctor' AND acc.status = 'Active' "
                + "AND ds.work_date = ? AND ds.status = 'Available' "
                + "AND booked.booked_patients < ds.max_patients "
                + "AND (ds.work_date > CAST(GETDATE() AS date) "
                + "OR TRY_CONVERT(time, LEFT(ds.time_slot, 5)) > CAST(GETDATE() AS time)) ");
        appendSessionFilter(sql, session);
        if (doctorName != null && !doctorName.isBlank()) {
            sql.append("AND d.full_name LIKE ? ");
        }
        sql.append("ORDER BY d.full_name");

        List<DoctorInfo> doctors = new ArrayList<>();
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            int parameterIndex = 1;
            statement.setDate(parameterIndex++, java.sql.Date.valueOf(workDate));
            if (doctorName != null && !doctorName.isBlank()) {
                statement.setString(parameterIndex, "%" + doctorName.trim() + "%");
            }
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    doctors.add(mapDoctor(resultSet));
                }
            }
        }
        return doctors;
    }

    public DoctorInfo findActiveDoctorById(int doctorId) throws SQLException {
        String sql = "SELECT d.doctor_id, d.full_name, d.phone, d.email, d.department "
                + "FROM Doctor d "
                + "INNER JOIN Account a ON a.account_id = d.account_id "
                + "WHERE d.doctor_id = ? AND a.role = 'Doctor' AND a.status = 'Active'";

        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, doctorId);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next() ? mapDoctor(resultSet) : null;
            }
        }
    }

    public List<DoctorScheduleInfo> findAvailableSchedules(int doctorId) throws SQLException {
        String sql = "SELECT ds.schedule_id, ds.work_date, ds.time_slot, ds.max_patients, ds.status, "
                + "SUM(CASE WHEN a.status IN ('Waiting', 'In_Progress') THEN 1 ELSE 0 END) AS booked_patients "
                + "FROM Doctor_Schedule ds "
                + "LEFT JOIN Appointment a ON a.schedule_id = ds.schedule_id "
                + "WHERE ds.doctor_id = ? AND ds.work_date >= CAST(GETDATE() AS date) "
                + "AND ds.status = 'Available' "
                + "GROUP BY ds.schedule_id, ds.work_date, ds.time_slot, ds.max_patients, ds.status "
                + "HAVING SUM(CASE WHEN a.status IN ('Waiting', 'In_Progress') THEN 1 ELSE 0 END) < ds.max_patients "
                + "ORDER BY ds.work_date, ds.time_slot";
        List<DoctorScheduleInfo> schedules = new ArrayList<>();

        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, doctorId);
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    DoctorScheduleInfo schedule = new DoctorScheduleInfo();
                    schedule.setScheduleId(resultSet.getInt("schedule_id"));
                    schedule.setWorkDate(resultSet.getDate("work_date").toLocalDate());
                    schedule.setTimeSlot(resultSet.getString("time_slot"));
                    schedule.setMaxPatients(resultSet.getInt("max_patients"));
                    schedule.setBookedPatients(resultSet.getInt("booked_patients"));
                    schedule.setStatus(resultSet.getString("status"));
                    schedules.add(schedule);
                }
            }
        }
        return schedules;
    }

    public List<DoctorScheduleInfo> findAvailableSchedules(int doctorId, LocalDate workDate,
            String session) throws SQLException {
        StringBuilder sql = new StringBuilder(
                "SELECT ds.schedule_id, ds.work_date, ds.time_slot, ds.max_patients, ds.status, "
                + "SUM(CASE WHEN ap.status <> 'Cancelled' THEN 1 ELSE 0 END) AS booked_patients "
                + "FROM Doctor_Schedule ds "
                + "LEFT JOIN Appointment ap ON ap.schedule_id = ds.schedule_id "
                + "WHERE ds.doctor_id = ? AND ds.work_date = ? AND ds.status = 'Available' "
                + "AND (ds.work_date > CAST(GETDATE() AS date) "
                + "OR TRY_CONVERT(time, LEFT(ds.time_slot, 5)) > CAST(GETDATE() AS time)) ");
        appendSessionFilter(sql, session);
        sql.append("GROUP BY ds.schedule_id, ds.work_date, ds.time_slot, "
                + "ds.max_patients, ds.status "
                + "HAVING SUM(CASE WHEN ap.status <> 'Cancelled' THEN 1 ELSE 0 END) < ds.max_patients "
                + "ORDER BY TRY_CONVERT(time, LEFT(ds.time_slot, 5))");

        List<DoctorScheduleInfo> schedules = new ArrayList<>();
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            statement.setInt(1, doctorId);
            statement.setDate(2, java.sql.Date.valueOf(workDate));
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    schedules.add(mapSchedule(resultSet));
                }
            }
        }
        return schedules;
    }

    public List<AvailabilitySlot> findAvailableTimeSlots() throws SQLException {
        String sql = "SELECT ds.work_date, ds.time_slot, COUNT(*) AS doctor_count, "
                + "SUM(ds.max_patients - booked.booked_patients) AS available_slots "
                + "FROM Doctor_Schedule ds "
                + "INNER JOIN Doctor d ON d.doctor_id = ds.doctor_id "
                + "INNER JOIN Account acc ON acc.account_id = d.account_id "
                + "CROSS APPLY (SELECT COUNT(*) AS booked_patients FROM Appointment a "
                + "WHERE a.schedule_id = ds.schedule_id AND a.status <> 'Cancelled') booked "
                + "WHERE ds.work_date >= CAST(GETDATE() AS date) "
                + "AND ds.status = 'Available' "
                + "AND acc.role = 'Doctor' AND acc.status = 'Active' "
                + "AND booked.booked_patients < ds.max_patients "
                + "GROUP BY ds.work_date, ds.time_slot "
                + "ORDER BY ds.work_date, ds.time_slot";
        List<AvailabilitySlot> slots = new ArrayList<>();

        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            while (resultSet.next()) {
                AvailabilitySlot slot = new AvailabilitySlot();
                slot.setWorkDate(resultSet.getDate("work_date").toLocalDate());
                slot.setTimeSlot(resultSet.getString("time_slot"));
                slot.setDoctorCount(resultSet.getInt("doctor_count"));
                slot.setAvailableSlots(resultSet.getInt("available_slots"));
                slots.add(slot);
            }
        }
        return slots;
    }

    private DoctorInfo mapDoctor(ResultSet resultSet) throws SQLException {
        DoctorInfo doctor = new DoctorInfo();
        doctor.setDoctorId(resultSet.getInt("doctor_id"));
        doctor.setFullName(resultSet.getString("full_name"));
        doctor.setPhone(resultSet.getString("phone"));
        doctor.setEmail(resultSet.getString("email"));
        doctor.setDepartment(resultSet.getString("department"));
        return doctor;
    }

    private DoctorScheduleInfo mapSchedule(ResultSet resultSet) throws SQLException {
        DoctorScheduleInfo schedule = new DoctorScheduleInfo();
        schedule.setScheduleId(resultSet.getInt("schedule_id"));
        schedule.setWorkDate(resultSet.getDate("work_date").toLocalDate());
        schedule.setTimeSlot(resultSet.getString("time_slot"));
        schedule.setMaxPatients(resultSet.getInt("max_patients"));
        schedule.setBookedPatients(resultSet.getInt("booked_patients"));
        schedule.setStatus(resultSet.getString("status"));
        return schedule;
    }

    private void appendSessionFilter(StringBuilder sql, String session) {
        if ("morning".equals(session)) {
            sql.append("AND TRY_CONVERT(time, LEFT(ds.time_slot, 5)) < CAST('12:00' AS time) ");
        } else if ("afternoon".equals(session)) {
            sql.append("AND TRY_CONVERT(time, LEFT(ds.time_slot, 5)) >= CAST('12:00' AS time) ");
        }
    }
}
