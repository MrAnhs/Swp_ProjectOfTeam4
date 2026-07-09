package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.util.DatabaseConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;

public class ReceptionistServlet extends HttpServlet {

    private static final DateTimeFormatter ISO_DATE = DateTimeFormatter.ISO_LOCAL_DATE;
    private static final DateTimeFormatter TIME_FORMAT = DateTimeFormatter.ofPattern("HH:mm");
    private static final SimpleDateFormat DISPLAY_FORMAT = new SimpleDateFormat("dd/MM/yyyy HH:mm");
    private static final String[] DEFAULT_TIME_SLOTS = {
        "08:00-09:00",
        "09:00-10:00",
        "10:00-11:00",
        "13:30-14:30",
        "14:30-15:30",
        "15:30-16:30"
    };

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json;charset=UTF-8");
        String action = request.getParameter("action");

        if ("getDoctors".equalsIgnoreCase(action)) {
            handleGetDoctors(request, response);
            return;
        }

        if ("getScheduleSlots".equalsIgnoreCase(action)) {
            handleGetScheduleSlots(request, response);
            return;
        }

        if ("getInvoiceStats".equalsIgnoreCase(action)) {
            handleGetInvoiceStats(request, response);
            return;
        }

        if ("getInvoicesByStatus".equalsIgnoreCase(action)) {
            handleGetInvoicesByStatus(request, response);
            return;
        }

        handleSearchPatient(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json;charset=UTF-8");
        String action = request.getParameter("action");

        if ("register".equalsIgnoreCase(action)) {
            handleRegisterAppointment(request, response);
            return;
        }

        if ("payInvoice".equalsIgnoreCase(action)) {
            handlePayInvoice(request, response);
            return;
        }

        sendJsonResponse(response, "{\"success\": false, \"error\": \"Action không hợp lệ.\"}");
    }

    private void handleSearchPatient(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String phone = request.getParameter("phone");

        if (phone == null || phone.trim().isEmpty()) {
            sendJsonResponse(response, "{\"success\": false, \"error\": \"Vui lòng nhập số điện thoại để tra cứu.\"}");
            return;
        }

        try (Connection connection = DatabaseConnection.getConnection()) {
            String patientSql = "SELECT patient_id, full_name, phone, email, address, date_of_birth, gender FROM Patient WHERE phone = ?";
            Integer patientId = null;
            String fullName = null;
            String patientPhone = null;
            String email = null;
            String address = null;
            Date dateOfBirth = null;
            String gender = null;

            try (PreparedStatement patientStmt = connection.prepareStatement(patientSql)) {
                patientStmt.setString(1, phone);
                try (ResultSet rs = patientStmt.executeQuery()) {
                    if (rs.next()) {
                        patientId = rs.getInt("patient_id");
                        fullName = rs.getString("full_name");
                        patientPhone = rs.getString("phone");
                        email = rs.getString("email");
                        address = rs.getString("address");
                        dateOfBirth = rs.getDate("date_of_birth");
                        gender = rs.getString("gender");
                    }
                }
            }

            if (patientId == null) {
                sendJsonResponse(response, "{\"success\": false, \"error\": \"Không tìm thấy bệnh nhân với số điện thoại này.\"}");
                return;
            }

            String countSql = "SELECT COUNT(*) AS total FROM Appointment WHERE patient_id = ?";
            int historyCount = 0;
            try (PreparedStatement countStmt = connection.prepareStatement(countSql)) {
                countStmt.setInt(1, patientId);
                try (ResultSet rs = countStmt.executeQuery()) {
                    if (rs.next()) {
                        historyCount = rs.getInt("total");
                    }
                }
            }

            String appointmentSql = "SELECT TOP 1 a.appointment_time, a.booking_type, a.status, a.queue_number, d.full_name AS doctor_name "
                    + "FROM Appointment a LEFT JOIN Doctor d ON a.doctor_id = d.doctor_id "
                    + "WHERE a.patient_id = ? ORDER BY a.appointment_time DESC";
            String appointmentTime = null;
            String bookingType = null;
            String status = null;
            String queueNumber = null;
            String doctorName = null;

            try (PreparedStatement appointmentStmt = connection.prepareStatement(appointmentSql)) {
                appointmentStmt.setInt(1, patientId);
                try (ResultSet rs = appointmentStmt.executeQuery()) {
                    if (rs.next()) {
                        Timestamp ts = rs.getTimestamp("appointment_time");
                        appointmentTime = ts != null ? formatTimestamp(ts) : null;
                        bookingType = rs.getString("booking_type");
                        status = rs.getString("status");
                        queueNumber = rs.getString("queue_number");
                        doctorName = rs.getString("doctor_name");
                    }
                }
            }

            StringBuilder json = new StringBuilder();
            json.append("{\"success\": true, \"patient\": {");
            json.append("\"fullName\": \"").append(escapeJson(fullName)).append("\", ");
            json.append("\"phone\": \"").append(escapeJson(patientPhone)).append("\", ");
            json.append("\"email\": \"").append(escapeJson(email)).append("\", ");
            json.append("\"address\": \"").append(escapeJson(address)).append("\", ");
            json.append("\"dateOfBirth\": \"").append(dateOfBirth != null ? escapeJson(dateOfBirth.toString()) : "").append("\", ");
            json.append("\"gender\": \"").append(escapeJson(gender)).append("\"}, ");
            json.append("\"historyCount\": ").append(historyCount).append(", ");
            if (appointmentTime != null) {
                json.append("\"nextAppointment\": {");
                json.append("\"appointmentTime\": \"").append(escapeJson(appointmentTime)).append("\", ");
                json.append("\"bookingType\": \"").append(escapeJson(nullToEmpty(bookingType))).append("\", ");
                json.append("\"status\": \"").append(escapeJson(nullToEmpty(status))).append("\", ");
                json.append("\"queueNumber\": \"").append(escapeJson(nullToEmpty(queueNumber))).append("\", ");
                json.append("\"doctorName\": \"").append(escapeJson(nullToEmpty(doctorName))).append("\"}");
            } else {
                json.append("\"nextAppointment\": null");
            }
            json.append("}");

            sendJsonResponse(response, json.toString());
        } catch (SQLException e) {
            e.printStackTrace();
            sendJsonResponse(response, "{\"success\": false, \"error\": \"Lỗi database: " + escapeJson(e.getMessage()) + "\"}");
        }
    }

    private void handleGetDoctors(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        try (Connection connection = DatabaseConnection.getConnection()) {
            String sql = "SELECT d.doctor_id, d.full_name, d.department "
                    + "FROM Doctor d "
                    + "ORDER BY d.full_name";
            StringBuilder json = new StringBuilder();
            json.append("{\"success\": true, \"doctors\": [");

            try (PreparedStatement stmt = connection.prepareStatement(sql);
                 ResultSet rs = stmt.executeQuery()) {
                boolean first = true;
                while (rs.next()) {
                    if (!first) {
                        json.append(",");
                    }
                    first = false;
                    json.append("{");
                    json.append("\"doctorId\": ").append(rs.getInt("doctor_id")).append(", ");
                    json.append("\"fullName\": \"").append(escapeJson(rs.getString("full_name"))).append("\"");
                    String department = rs.getString("department");
                    if (department != null) {
                        json.append(", \"department\": \"").append(escapeJson(department)).append("\"");
                    }
                    json.append("}");
                }
            }

            json.append("]}");
            sendJsonResponse(response, json.toString());
        } catch (SQLException e) {
            e.printStackTrace();
            sendJsonResponse(response, "{\"success\": false, \"error\": \"Lỗi khi tải danh sách bác sĩ: " + escapeJson(e.getMessage()) + "\"}");
        }
    }

    private void handleGetScheduleSlots(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String doctorIdValue = request.getParameter("doctorId");
        if (doctorIdValue == null || doctorIdValue.trim().isEmpty()) {
            sendJsonResponse(response, "{\"success\": false, \"error\": \"Chưa chọn bác sĩ.\"}");
            return;
        }

        int doctorId;
        try {
            doctorId = Integer.parseInt(doctorIdValue);
        } catch (NumberFormatException e) {
            sendJsonResponse(response, "{\"success\": false, \"error\": \"Bác sĩ không hợp lệ.\"}");
            return;
        }

        try (Connection connection = DatabaseConnection.getConnection()) {
            ensureDefaultScheduleSlots(connection, doctorId);

            String sql = "SELECT ds.schedule_id, ds.work_date, ds.time_slot, ds.max_patients, ds.status, "
                    + "(SELECT COUNT(*) FROM Appointment a WHERE a.schedule_id = ds.schedule_id AND LOWER(ISNULL(a.status, '')) <> 'cancelled') AS booked "
                    + "FROM Doctor_Schedule ds "
                    + "WHERE ds.doctor_id = ? AND ds.work_date >= CAST(GETDATE() AS date) "
                    + "AND LOWER(ISNULL(ds.status, 'available')) <> 'full' "
                    + "ORDER BY ds.work_date, ds.time_slot";

            StringBuilder json = new StringBuilder();
            json.append("{\"success\": true, \"slots\": [");
            boolean first = true;

            try (PreparedStatement stmt = connection.prepareStatement(sql)) {
                stmt.setInt(1, doctorId);
                try (ResultSet rs = stmt.executeQuery()) {
                    while (rs.next()) {
                        int scheduleId = rs.getInt("schedule_id");
                        Date workDate = rs.getDate("work_date");
                        String timeSlot = rs.getString("time_slot");
                        int maxPatients = rs.getInt("max_patients");
                        int booked = rs.getInt("booked");
                        int available = Math.max(0, maxPatients - booked);
                        if (available <= 0) {
                            continue;
                        }

                        if (!first) {
                            json.append(",");
                        }
                        first = false;

                        String label = formatScheduleLabel(workDate, timeSlot);
                        json.append("{");
                        json.append("\"scheduleId\": ").append(scheduleId).append(", ");
                        json.append("\"label\": \"").append(escapeJson(label)).append("\", ");
                        json.append("\"workDate\": \"").append(workDate != null ? escapeJson(workDate.toString()) : "").append("\", ");
                        json.append("\"timeSlot\": \"").append(escapeJson(timeSlot)).append("\", ");
                        json.append("\"available\": ").append(available);
                        json.append("}");
                    }
                }
            }

            json.append("]}");
            sendJsonResponse(response, json.toString());
        } catch (SQLException e) {
            e.printStackTrace();
            sendJsonResponse(response, "{\"success\": false, \"error\": \"Lỗi khi tải khung giờ: " + escapeJson(e.getMessage()) + "\"}");
        }
    }

    private void handleGetInvoiceStats(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String sql = "SELECT "
                + "SUM(CASE WHEN status = 'Pending' THEN 1 ELSE 0 END) AS pending_count, "
                + "SUM(CASE WHEN status = 'Paid' THEN 1 ELSE 0 END) AS paid_count "
                + "FROM Invoice";

        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement stmt = connection.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            int pendingCount = 0;
            int paidCount = 0;
            if (rs.next()) {
                pendingCount = rs.getInt("pending_count");
                paidCount = rs.getInt("paid_count");
            }

            sendJsonResponse(response, "{\"success\": true, \"pendingCount\": "
                    + pendingCount + ", \"paidCount\": " + paidCount + "}");
        } catch (SQLException e) {
            e.printStackTrace();
            sendJsonResponse(response, "{\"success\": false, \"error\": \"Lỗi khi tải thống kê hóa đơn: " + escapeJson(e.getMessage()) + "\"}");
        }
    }

    private void handleGetInvoicesByStatus(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String status = nullToEmpty(request.getParameter("status")).trim();
        if (!"Pending".equalsIgnoreCase(status) && !"Paid".equalsIgnoreCase(status)) {
            sendJsonResponse(response, "{\"success\": false, \"error\": \"Trạng thái hóa đơn không hợp lệ.\"}");
            return;
        }

        String normalizedStatus = "Paid".equalsIgnoreCase(status) ? "Paid" : "Pending";
        String sql = "SELECT TOP 20 i.invoice_id, i.patient_id, p.full_name, p.phone, "
                + "i.final_amount, i.status, i.created_at "
                + "FROM Invoice i "
                + "LEFT JOIN Patient p ON i.patient_id = p.patient_id "
                + "WHERE i.status = ? "
                + "ORDER BY i.created_at DESC, i.invoice_id DESC";

        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setString(1, normalizedStatus);
            try (ResultSet rs = stmt.executeQuery()) {
                StringBuilder json = new StringBuilder();
                json.append("{\"success\": true, \"status\": \"").append(normalizedStatus).append("\", \"invoices\": [");
                boolean first = true;
                while (rs.next()) {
                    if (!first) {
                        json.append(",");
                    }
                    first = false;
                    Timestamp createdAt = rs.getTimestamp("created_at");
                    json.append("{");
                    json.append("\"invoiceId\": ").append(rs.getInt("invoice_id")).append(", ");
                    json.append("\"patientId\": ").append(rs.getInt("patient_id")).append(", ");
                    json.append("\"patientName\": \"").append(escapeJson(nullToEmpty(rs.getString("full_name")))).append("\", ");
                    json.append("\"phone\": \"").append(escapeJson(nullToEmpty(rs.getString("phone")))).append("\", ");
                    json.append("\"finalAmount\": ").append(rs.getDouble("final_amount")).append(", ");
                    json.append("\"status\": \"").append(escapeJson(nullToEmpty(rs.getString("status")))).append("\", ");
                    json.append("\"createdAt\": \"").append(createdAt != null ? escapeJson(formatTimestamp(createdAt)) : "").append("\"");
                    json.append("}");
                }
                json.append("]}");
                sendJsonResponse(response, json.toString());
            }
        } catch (SQLException e) {
            e.printStackTrace();
            sendJsonResponse(response, "{\"success\": false, \"error\": \"Lỗi khi tải danh sách hóa đơn: " + escapeJson(e.getMessage()) + "\"}");
        }
    }

    private void handlePayInvoice(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String patientKeyword = nullToEmpty(request.getParameter("patientKeyword")).trim();
        String paymentMethod = nullToEmpty(request.getParameter("paymentMethod")).trim();

        try (Connection connection = DatabaseConnection.getConnection()) {
            Integer invoiceId = findPendingInvoiceId(connection, patientKeyword);
            if (invoiceId == null) {
                sendJsonResponse(response, "{\"success\": false, \"error\": \"Không tìm thấy hóa đơn Pending phù hợp.\"}");
                return;
            }

            String updateSql = "UPDATE Invoice SET status = 'Paid', payment_method = ?, exported_at = GETDATE() WHERE invoice_id = ?";
            try (PreparedStatement stmt = connection.prepareStatement(updateSql)) {
                stmt.setString(1, paymentMethod.isEmpty() ? "cash" : paymentMethod);
                stmt.setInt(2, invoiceId);
                stmt.executeUpdate();
            }

            sendJsonResponse(response, "{\"success\": true, \"message\": \"Thanh toán thành công.\", \"invoiceId\": "
                    + invoiceId + "}");
        } catch (SQLException e) {
            e.printStackTrace();
            sendJsonResponse(response, "{\"success\": false, \"error\": \"Lỗi khi cập nhật hóa đơn: " + escapeJson(e.getMessage()) + "\"}");
        }
    }

    private Integer findPendingInvoiceId(Connection connection, String patientKeyword) throws SQLException {
        String baseSql = "SELECT TOP 1 i.invoice_id "
                + "FROM Invoice i "
                + "LEFT JOIN Patient p ON i.patient_id = p.patient_id "
                + "WHERE i.status = 'Pending' ";
        boolean hasKeyword = !patientKeyword.isEmpty();
        String sql = baseSql
                + (hasKeyword ? "AND (p.phone = ? OR p.full_name LIKE ?) " : "")
                + "ORDER BY i.created_at DESC, i.invoice_id DESC";

        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            if (hasKeyword) {
                stmt.setString(1, patientKeyword);
                stmt.setString(2, "%" + patientKeyword + "%");
            }
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getInt("invoice_id") : null;
            }
        }
    }

    private void handleRegisterAppointment(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String fullName = request.getParameter("patientName");
        String phone = request.getParameter("patientPhone");
        String email = request.getParameter("patientEmail");
        String dobValue = request.getParameter("patientDob");
        String gender = request.getParameter("patientGender");
        String address = request.getParameter("patientAddress");
        String doctorIdValue = request.getParameter("doctorId");
        String scheduleIdValue = request.getParameter("scheduleId");
        String note = request.getParameter("note");

        if (isNullOrEmpty(fullName) || isNullOrEmpty(phone) || isNullOrEmpty(dobValue)
                || isNullOrEmpty(doctorIdValue) || isNullOrEmpty(scheduleIdValue)) {
            sendJsonResponse(response, "{\"success\": false, \"error\": \"Vui lòng điền đầy đủ thông tin bệnh nhân, bác sĩ và khung giờ.\"}");
            return;
        }

        int doctorId;
        int scheduleId;
        try {
            doctorId = Integer.parseInt(doctorIdValue);
            scheduleId = Integer.parseInt(scheduleIdValue);
        } catch (NumberFormatException e) {
            sendJsonResponse(response, "{\"success\": false, \"error\": \"Bác sĩ hoặc khung giờ không hợp lệ.\"}");
            return;
        }

        LocalDate dob;
        try {
            dob = LocalDate.parse(dobValue, ISO_DATE);
        } catch (DateTimeParseException e) {
            sendJsonResponse(response, "{\"success\": false, \"error\": \"Ngày sinh không đúng định dạng.\"}");
            return;
        }

        try (Connection connection = DatabaseConnection.getConnection()) {
            connection.setAutoCommit(false);
            Integer patientId = findPatientIdByPhone(connection, phone);

            if (patientId == null) {
                patientId = insertPatient(connection, fullName, dob, gender, phone, email, address);
            } else {
                updatePatientInfo(connection, patientId, fullName, dob, gender, email, address);
            }

            AppointmentSchedule schedule = loadSchedule(connection, scheduleId, doctorId);
            if (schedule == null) {
                connection.rollback();
                sendJsonResponse(response, "{\"success\": false, \"error\": \"Khung giờ khám không hợp lệ hoặc đã đầy.\"}");
                return;
            }

            int queueNumber = getNextQueueNumber(connection, doctorId, schedule.workDate);
            Timestamp appointmentTime = Timestamp.valueOf(LocalDateTime.of(schedule.workDate.toLocalDate(), schedule.startTime));

            String insertAppointment = "INSERT INTO Appointment (patient_id, doctor_id, schedule_id, appointment_time, booking_type, queue_number, status, created_at) "
                    + "VALUES (?, ?, ?, ?, ?, ?, ?, GETDATE())";
            try (PreparedStatement stmt = connection.prepareStatement(insertAppointment)) {
                stmt.setInt(1, patientId);
                stmt.setInt(2, doctorId);
                stmt.setInt(3, scheduleId);
                stmt.setTimestamp(4, appointmentTime);
                stmt.setString(5, "At_Counter");
                stmt.setInt(6, queueNumber);
                stmt.setString(7, "Waiting");
                stmt.executeUpdate();
            }

            if (schedule.booked + 1 >= schedule.maxPatients) {
                try (PreparedStatement updateSchedule = connection.prepareStatement(
                        "UPDATE Doctor_Schedule SET status = 'full' WHERE schedule_id = ?")) {
                    updateSchedule.setInt(1, scheduleId);
                    updateSchedule.executeUpdate();
                }
            }

            connection.commit();
            StringBuilder json = new StringBuilder();
            json.append("{\"success\": true, \"message\": \"Đã đăng ký khám thành công.\", ");
            json.append("\"patientId\": ").append(patientId).append(", ");
            json.append("\"appointmentTime\": \"").append(formatTimestamp(appointmentTime)).append("\", ");
            json.append("\"queueNumber\": ").append(queueNumber).append("}");
            sendJsonResponse(response, json.toString());
        } catch (SQLException e) {
            e.printStackTrace();
            sendJsonResponse(response, "{\"success\": false, \"error\": \"Lỗi ghi dữ liệu: " + escapeJson(e.getMessage()) + "\"}");
        }
    }

    private Integer findPatientIdByPhone(Connection connection, String phone) throws SQLException {
        String sql = "SELECT patient_id FROM Patient WHERE phone = ?";
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setString(1, phone);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getInt("patient_id") : null;
            }
        }
    }

    private int insertPatient(Connection connection, String fullName, LocalDate dob, String gender, String phone, String email, String address) throws SQLException {
        String sql = "INSERT INTO Patient (full_name, date_of_birth, gender, phone, email, address, account_id) VALUES (?, ?, ?, ?, ?, ?, NULL)";
        try (PreparedStatement stmt = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            stmt.setString(1, fullName);
            stmt.setDate(2, Date.valueOf(dob));
            stmt.setString(3, gender);
            stmt.setString(4, phone);
            stmt.setString(5, nullToEmpty(email).isEmpty() ? null : email);
            stmt.setString(6, address);
            stmt.executeUpdate();
            try (ResultSet rs = stmt.getGeneratedKeys()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }
        throw new SQLException("Không thể tạo bản ghi bệnh nhân mới.");
    }

    private void updatePatientInfo(Connection connection, int patientId, String fullName, LocalDate dob, String gender, String email, String address) throws SQLException {
        String sql = "UPDATE Patient SET full_name = ?, date_of_birth = ?, gender = ?, email = ?, address = ? WHERE patient_id = ?";
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setString(1, fullName);
            stmt.setDate(2, Date.valueOf(dob));
            stmt.setString(3, gender);
            stmt.setString(4, nullToEmpty(email).isEmpty() ? null : email);
            stmt.setString(5, address);
            stmt.setInt(6, patientId);
            stmt.executeUpdate();
        }
    }

    private AppointmentSchedule loadSchedule(Connection connection, int scheduleId, int doctorId) throws SQLException {
        String sql = "SELECT ds.work_date, ds.time_slot, ds.max_patients, "
                + "(SELECT COUNT(*) FROM Appointment a WHERE a.schedule_id = ds.schedule_id AND LOWER(ISNULL(a.status, '')) <> 'cancelled') AS booked "
                + "FROM Doctor_Schedule ds "
                + "WHERE ds.schedule_id = ? AND ds.doctor_id = ? "
                + "AND ds.work_date >= CAST(GETDATE() AS date) "
                + "AND LOWER(ISNULL(ds.status, 'available')) <> 'full'";
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, scheduleId);
            stmt.setInt(2, doctorId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                Date workDate = rs.getDate("work_date");
                String timeSlot = rs.getString("time_slot");
                int maxPatients = rs.getInt("max_patients");
                int booked = rs.getInt("booked");
                int available = maxPatients - booked;
                if (available <= 0) {
                    return null;
                }
                LocalTime startTime = parseStartTime(timeSlot);
                return new AppointmentSchedule(workDate, startTime, maxPatients, booked);
            }
        }
    }

    private void ensureDefaultScheduleSlots(Connection connection, int doctorId) throws SQLException {
        String countSql = "SELECT COUNT(*) AS total "
                + "FROM Doctor_Schedule "
                + "WHERE doctor_id = ? AND work_date >= CAST(GETDATE() AS date)";
        try (PreparedStatement countStmt = connection.prepareStatement(countSql)) {
            countStmt.setInt(1, doctorId);
            try (ResultSet rs = countStmt.executeQuery()) {
                if (rs.next() && rs.getInt("total") > 0) {
                    return;
                }
            }
        }

        String insertSql = "INSERT INTO Doctor_Schedule (doctor_id, work_date, time_slot, max_patients, status) "
                + "VALUES (?, DATEADD(day, ?, CAST(GETDATE() AS date)), ?, ?, ?)";
        try (PreparedStatement insertStmt = connection.prepareStatement(insertSql)) {
            for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
                for (String slot : DEFAULT_TIME_SLOTS) {
                    insertStmt.setInt(1, doctorId);
                    insertStmt.setInt(2, dayOffset);
                    insertStmt.setString(3, slot);
                    insertStmt.setInt(4, 4);
                    insertStmt.setString(5, "available");
                    insertStmt.addBatch();
                }
            }
            insertStmt.executeBatch();
        }
    }

    private int getNextQueueNumber(Connection connection, int doctorId, Date workDate) throws SQLException {
        String sql = "SELECT ISNULL(MAX(queue_number), 0) + 1 AS next_queue "
                + "FROM Appointment "
                + "WHERE doctor_id = ? AND CAST(appointment_time AS date) = ?";
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, doctorId);
            stmt.setDate(2, workDate);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("next_queue");
                }
            }
        }
        return 1;
    }

    private LocalTime parseStartTime(String timeSlot) {
        if (timeSlot == null || timeSlot.trim().isEmpty()) {
            return LocalTime.of(9, 0);
        }
        String[] parts = timeSlot.split("\\s*(?:-|–|—|to)\\s*");
        if (parts.length == 0) {
            return LocalTime.of(9, 0);
        }
        try {
            return LocalTime.parse(parts[0].trim(), TIME_FORMAT);
        } catch (DateTimeParseException e) {
            return LocalTime.of(9, 0);
        }
    }

    private String formatScheduleLabel(Date workDate, String timeSlot) {
        if (workDate == null) {
            return timeSlot != null ? timeSlot : "";
        }
        String dateLabel = new SimpleDateFormat("dd/MM/yyyy").format(workDate);
        return dateLabel + " " + (timeSlot != null ? timeSlot : "");
    }

    private void sendJsonResponse(HttpServletResponse response, String json) throws IOException {
        try (PrintWriter writer = response.getWriter()) {
            writer.write(json);
        }
    }

    private String escapeJson(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }

    private String nullToEmpty(String value) {
        return value == null ? "" : value;
    }

    private String formatTimestamp(Timestamp timestamp) {
        return DISPLAY_FORMAT.format(timestamp);
    }

    private boolean isNullOrEmpty(String value) {
        return value == null || value.trim().isEmpty();
    }

    private static class AppointmentSchedule {
        private final Date workDate;
        private final LocalTime startTime;
        private final int maxPatients;
        private final int booked;

        public AppointmentSchedule(Date workDate, LocalTime startTime, int maxPatients, int booked) {
            this.workDate = workDate;
            this.startTime = startTime;
            this.maxPatients = maxPatients;
            this.booked = booked;
        }
    }
}
