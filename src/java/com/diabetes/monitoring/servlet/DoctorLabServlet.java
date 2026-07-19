package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.model.User;
import com.diabetes.monitoring.util.DatabaseConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class DoctorLabServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        User currentUser = session == null ? null : (User) session.getAttribute("currentUser");

        if (currentUser == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        if (!isDoctorLabRole(currentUser.getRole())) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Access Denied: Only lab doctors allowed.");
            return;
        }

        List<Map<String, String>> patients = new ArrayList<>();
        List<Map<String, String>> records = new ArrayList<>();
        List<Map<String, String>> waitingPatients = new ArrayList<>();
        int waitingCount = 0;
        int completedCount = 0;
        int totalPatients = 0;
        
        int bloodTestCount = 0;
        int kidneyTestCount = 0;
        int liverTestCount = 0;
        int urineTestCount = 0;

        java.util.Set<Integer> uniquePatientIds = new java.util.HashSet<>();
        java.util.Set<Integer> completedPatientIds = new java.util.HashSet<>();

        try (Connection conn = DatabaseConnection.getConnection()) {
            int currentLabId = 0;
            String sqlLab = "SELECT lab_id FROM Doctor_Lab WHERE account_id = ?";
            try (PreparedStatement stmt = conn.prepareStatement(sqlLab)) {
                stmt.setInt(1, currentUser.getId());
                try (ResultSet rs = stmt.executeQuery()) {
                    if (rs.next()) {
                        currentLabId = rs.getInt("lab_id");
                    }
                }
            }
            request.setAttribute("currentLabId", currentLabId);

            String sqlPatients = "WITH RecordCounts AS (" +
                    "    SELECT patient_id, COUNT(*) as cnt " +
                    "    FROM Healthy_Record " +
                    "    GROUP BY patient_id" +
                    ") " +
                    "SELECT p.patient_id, p.full_name, p.email, p.phone, p.date_of_birth, p.gender, p.address, " +
                    "       COALESCE(rc.cnt, 0) as record_count, " +
                    "       lo.status as waitlist_status, " +
                    "       lo.order_id as waiting_id, " +
                    "       COALESCE(ms.service_name, dl.lab_name, r.room_name) as lab_room, " +
                    "       lo.lab_id " +
                    "FROM Patient p " +
                    "LEFT JOIN Lab_Order lo ON p.patient_id = lo.patient_id " +
                    "LEFT JOIN Room r ON r.room_id = lo.room_id " +
                    "LEFT JOIN Doctor_Lab dl ON dl.lab_id = lo.lab_id " +
                    "LEFT JOIN Medical_Service ms ON ms.service_id = lo.service_id " +
                    "LEFT JOIN RecordCounts rc ON p.patient_id = rc.patient_id " +
                    "ORDER BY p.full_name, lo.created_at DESC";
            try (PreparedStatement stmt = conn.prepareStatement(sqlPatients);
                 ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, String> p = new HashMap<>();
                    int pId = rs.getInt("patient_id");
                    p.put("patientId", String.valueOf(pId));
                    p.put("fullName", rs.getString("full_name"));
                    p.put("email", rs.getString("email"));
                    p.put("phone", rs.getString("phone"));
                    p.put("dob", rs.getString("date_of_birth"));
                    String rawGender = rs.getString("gender");
                    String normGender = rawGender;
                    if (rawGender != null) {
                        String rgL = rawGender.trim().toLowerCase();
                        if (rgL.equals("male") || rgL.equals("m") || rgL.equals("nam")) {
                            normGender = "Nam";
                        } else if (rgL.equals("female") || rgL.equals("f") || rgL.equals("nữ") || rgL.equals("n?")) {
                            normGender = "Nữ";
                        }
                    }
                    p.put("gender", normGender);
                    p.put("address", rs.getString("address"));
                    
                    int recordCount = rs.getInt("record_count");
                    String waitlistStatus = rs.getString("waitlist_status");
                    String waitingId = rs.getString("waiting_id");
                    String rawRoom = rs.getString("lab_room");
                    String labRoom = normalizeRoomName(rawRoom);
                    int patientLabId = rs.getInt("lab_id");
                    
                    p.put("recordCount", String.valueOf(recordCount));
                    p.put("waitlistStatus", waitlistStatus != null ? waitlistStatus : "");
                    p.put("waitingId", waitingId != null ? waitingId : "");
                    p.put("labRoom", labRoom != null ? labRoom : "");
                    p.put("labId", rs.wasNull() ? "" : String.valueOf(patientLabId));
                    
                    boolean isAssignedToOther = patientLabId > 0 && patientLabId != currentLabId;
                    if (!isAssignedToOther) {
                        uniquePatientIds.add(pId);

                        boolean isCompleted = "completed".equals(waitlistStatus) || ((waitlistStatus == null || waitlistStatus.isEmpty()) && recordCount > 0);
                        if (isCompleted || recordCount > 0) {
                            completedPatientIds.add(pId);
                        }

                        if ("waiting".equals(waitlistStatus) || "testing".equals(waitlistStatus)) {
                            waitingCount++;
                            // Also populate waitingPatients list for backward compatibility if needed
                            Map<String, String> wp = new HashMap<>(p);
                            wp.put("waitingId", waitingId != null ? waitingId : "");
                            wp.put("createdAt", ""); // not strictly needed for merged but keep it clean
                            waitingPatients.add(wp);
                        }

                        if (labRoom != null) {
                            String rL = labRoom.toLowerCase();
                            if (rL.contains("máu")) {
                                bloodTestCount++;
                            } else if (rL.contains("thận")) {
                                kidneyTestCount++;
                            } else if (rL.contains("gan")) {
                                liverTestCount++;
                            } else if (rL.contains("nước tiểu")) {
                                urineTestCount++;
                            }
                        }
                        patients.add(p);
                    }
                }
                totalPatients = uniquePatientIds.size();
                completedCount = completedPatientIds.size();
            }

            String sqlRecords = "SELECT hr.health_record_id, hr.patient_id, p.full_name as patient_name, hr.urea, hr.cr, hr.hba1c, " +
                    "hr.chol, hr.tg, hr.hdl, hr.ldl, hr.vldl, hr.weight, hr.height, hr.bmi, hr.status, hr.created_at, hr.other_information " +
                    "FROM Healthy_Record hr " +
                    "INNER JOIN Patient p ON hr.patient_id = p.patient_id " +
                    "WHERE EXISTS (" +
                    "    SELECT 1 FROM Invoice_Detail id" +
                    "    WHERE id.health_record_id = hr.health_record_id" +
                    "      AND (id.lab_id = ? OR id.lab_id IS NULL)" +
                    ")" +
                    "ORDER BY hr.created_at DESC";
            try (PreparedStatement stmt = conn.prepareStatement(sqlRecords)) {
                stmt.setInt(1, currentLabId);
                try (ResultSet rs = stmt.executeQuery()) {
                    while (rs.next()) {
                        Map<String, String> r = new HashMap<>();
                        r.put("recordId", String.valueOf(rs.getInt("health_record_id")));
                        r.put("patientId", String.valueOf(rs.getInt("patient_id")));
                        r.put("patientName", rs.getString("patient_name"));
                        r.put("urea", formatDecimal(rs.getBigDecimal("urea")));
                        r.put("cr", formatDecimal(rs.getBigDecimal("cr")));
                        r.put("hba1c", formatDecimal(rs.getBigDecimal("hba1c")));
                        r.put("chol", formatDecimal(rs.getBigDecimal("chol")));
                        r.put("tg", formatDecimal(rs.getBigDecimal("tg")));
                        r.put("hdl", formatDecimal(rs.getBigDecimal("hdl")));
                        r.put("ldl", formatDecimal(rs.getBigDecimal("ldl")));
                        r.put("vldl", formatDecimal(rs.getBigDecimal("vldl")));
                        r.put("weight", formatDecimal(rs.getBigDecimal("weight")));
                        r.put("height", formatDecimal(rs.getBigDecimal("height")));
                        r.put("bmi", formatDecimal(rs.getBigDecimal("bmi")));
                        r.put("status", rs.getString("status"));
                        String rawCreatedAt = rs.getString("created_at");
                        if (rawCreatedAt != null && rawCreatedAt.length() >= 16) {
                            rawCreatedAt = rawCreatedAt.substring(0, 16);
                        }
                        r.put("createdAt", rawCreatedAt);
                        r.put("otherInfo", rs.getString("other_information"));
                        records.add(r);
                    }
                }
            }

            // Calculate HbA1c Glycemic Risks
            int highHbA1cCount = 0;
            int normalHbA1cCount = 0;
            for (Map<String, String> r : records) {
                try {
                    String hStr = r.get("hba1c");
                    if (hStr != null && !hStr.isEmpty()) {
                        double val = Double.parseDouble(hStr);
                        if (val >= 6.5) {
                            highHbA1cCount++;
                        } else {
                            normalHbA1cCount++;
                        }
                    }
                } catch (Exception e) {
                    // ignore
                }
            }

            int totalHb = highHbA1cCount + normalHbA1cCount;
            long highPct = totalHb > 0 ? Math.round((double) highHbA1cCount * 100.0 / totalHb) : 0;
            double dashArray = (double) highPct * 2.512;
            double dashOffset = 251.2 - dashArray;

            request.setAttribute("highPct", highPct);
            request.setAttribute("dashOffset", String.valueOf(dashOffset));

            request.setAttribute("waitingPatients", waitingPatients);
            request.setAttribute("waitingCount", waitingCount);
            request.setAttribute("totalPatients", totalPatients);
            request.setAttribute("completedCount", completedCount);
            request.setAttribute("bloodTestCount", bloodTestCount);
            request.setAttribute("kidneyTestCount", kidneyTestCount);
            request.setAttribute("liverTestCount", liverTestCount);
            request.setAttribute("urineTestCount", urineTestCount);
            request.setAttribute("highHbA1cCount", highHbA1cCount);
            request.setAttribute("normalHbA1cCount", normalHbA1cCount);
            request.setAttribute("totalRecords", records.size());
            
            com.diabetes.monitoring.doctor.dao.HealthRecordDAO recordDao = new com.diabetes.monitoring.doctor.dao.HealthRecordDAO();
            request.setAttribute("labSchedules", recordDao.getLabSchedulesByAccountId(currentUser.getId()));
        } catch (SQLException e) {
            e.printStackTrace();
        }

        request.setAttribute("patients", patients);
        request.setAttribute("records", records);
        request.getRequestDispatcher("/WEB-INF/views/doctor-lab/dashboard.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        User currentUser = session == null ? null : (User) session.getAttribute("currentUser");

        if (currentUser == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        if (!isDoctorLabRole(currentUser.getRole())) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Access Denied");
            return;
        }

        request.setCharacterEncoding("UTF-8");

        String action = request.getParameter("action");
        if ("invite".equals(action)) {
            String waitingIdStr = request.getParameter("waitingId");
            if (waitingIdStr == null || waitingIdStr.trim().isEmpty()) {
                session.setAttribute("errorMsg", "Mã hàng chờ không hợp lệ.");
                response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard");
                return;
            }
            try (Connection conn = DatabaseConnection.getConnection()) {
                String sqlInvite = "UPDATE Lab_Order SET status = 'testing' WHERE order_id = ?";
                try (PreparedStatement stmt = conn.prepareStatement(sqlInvite)) {
                    stmt.setString(1, waitingIdStr.trim());
                    stmt.executeUpdate();
                }
                session.setAttribute("successMsg", "Bệnh nhân đã được mời vào phòng xét nghiệm.");
            } catch (Exception e) {
                e.printStackTrace();
                session.setAttribute("errorMsg", "Lỗi khi cập nhật trạng thái mời: " + e.getMessage());
            }
            response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard");
            return;
        }

        if ("assign".equals(action)) {
            String patientIdStr = request.getParameter("patientId");
            String newRoom = request.getParameter("newRoom");
            if (patientIdStr == null || patientIdStr.trim().isEmpty() || newRoom == null || newRoom.trim().isEmpty()) {
                session.setAttribute("errorMsg", "Dữ liệu chỉ định không hợp lệ.");
                response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard");
                return;
            }
            try (Connection conn = DatabaseConnection.getConnection()) {
                int patientId = Integer.parseInt(patientIdStr.trim());
                
                Integer targetLabId = getLabIdFromRoomName(conn, newRoom);
                int serviceId = getServiceIdFromRoomName(conn, newRoom);
                
                String sqlCheckRoom = "SELECT COUNT(*) FROM Lab_Order WHERE patient_id = ? AND service_id = ? AND status = 'waiting'";
                try (PreparedStatement stmtCheck = conn.prepareStatement(sqlCheckRoom)) {
                    stmtCheck.setInt(1, patientId);
                    stmtCheck.setInt(2, serviceId);
                    try (ResultSet rsCheck = stmtCheck.executeQuery()) {
                        if (rsCheck.next() && rsCheck.getInt(1) > 0) {
                            session.setAttribute("errorMsg", "Xét nghiệm này đang trong danh sách chờ thực hiện.");
                            response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard");
                            return;
                        }
                    }
                }

                int appointmentId = 0;
                String selectApptSql = "SELECT TOP 1 appointment_id FROM Appointment WHERE patient_id = ? ORDER BY appointment_id DESC";
                try (PreparedStatement apptStmt = conn.prepareStatement(selectApptSql)) {
                    apptStmt.setInt(1, patientId);
                    try (ResultSet apptRs = apptStmt.executeQuery()) {
                        if (apptRs.next()) {
                            appointmentId = apptRs.getInt("appointment_id");
                        }
                    }
                }
                
                if (appointmentId == 0) {
                    session.setAttribute("errorMsg", "Không tìm thấy lịch hẹn cho bệnh nhân.");
                    response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard");
                    return;
                }

                String roomId = getRoomIdForLab(conn, targetLabId);
                String orderId = java.util.UUID.randomUUID().toString();
                String sqlInsertOrder = "INSERT INTO Lab_Order (order_id, appointment_id, patient_id, room_id, service_id, lab_id, status, created_at) " +
                                        "VALUES (?, ?, ?, ?, ?, ?, 'waiting', GETDATE())";
                try (PreparedStatement stmtOrder = conn.prepareStatement(sqlInsertOrder)) {
                    stmtOrder.setString(1, orderId);
                    stmtOrder.setInt(2, appointmentId);
                    stmtOrder.setInt(3, patientId);
                    stmtOrder.setString(4, roomId);
                    stmtOrder.setInt(5, serviceId);
                    if (targetLabId != null) {
                        stmtOrder.setInt(6, targetLabId);
                    } else {
                        stmtOrder.setNull(6, java.sql.Types.INTEGER);
                    }
                    stmtOrder.executeUpdate();
                }
                session.setAttribute("successMsg", "Đã chỉ định xét nghiệm mới: " + newRoom);
            } catch (Exception e) {
                e.printStackTrace();
                session.setAttribute("errorMsg", "Lỗi khi lưu chỉ định xét nghiệm: " + e.getMessage());
            }
            response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard");
            return;
        }

        String patientIdStr = request.getParameter("patientId");
        String waitingIdStr = request.getParameter("waitingId");
        String isRandomStr = request.getParameter("isRandom");

        if (patientIdStr == null || patientIdStr.isEmpty()) {
            session.setAttribute("errorMsg", "Vui lòng chọn bệnh nhân.");
            response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard");
            return;
        }

        try {
            int patientId = Integer.parseInt(patientIdStr);
            BigDecimal urea, cr, hba1c, chol, tg, hdl, ldl, vldl, weight, height, bmi;
            String otherInfo;

             String currentLabRoom = null;
             if (waitingIdStr != null && !waitingIdStr.trim().isEmpty()) {
                 try (Connection conn = DatabaseConnection.getConnection()) {
                     String sqlCheck = "SELECT lo.room_id, r.room_name, dl.lab_name, ms.service_name "
                             + "FROM Lab_Order lo "
                             + "LEFT JOIN Room r ON r.room_id = lo.room_id "
                             + "LEFT JOIN Doctor_Lab dl ON dl.lab_id = lo.lab_id "
                             + "LEFT JOIN Medical_Service ms ON ms.service_id = lo.service_id "
                             + "WHERE lo.order_id = ?";
                     try (PreparedStatement stmtCheck = conn.prepareStatement(sqlCheck)) {
                         stmtCheck.setString(1, waitingIdStr.trim());
                         try (ResultSet rsCheck = stmtCheck.executeQuery()) {
                             if (rsCheck.next()) {
                                 String svcName = rsCheck.getString("service_name");
                                 String labName = rsCheck.getString("lab_name");
                                 String roomName = rsCheck.getString("room_name");
                                 currentLabRoom = normalizeRoomName(svcName != null ? svcName : (labName != null ? labName : roomName));
                             }
                         }
                     }
                 } catch (Exception e) {
                     e.printStackTrace();
                 }
             }

             if ("true".equals(isRandomStr)) {
                 java.util.Map<String, BigDecimal> metrics;
                 if (currentLabRoom != null && (currentLabRoom.toLowerCase().contains("test") || currentLabRoom.toLowerCase().contains("đầy đủ"))) {
                     metrics = com.diabetes.monitoring.util.RandomTestGenerator.generateRandomMetrics();
                 } else if (currentLabRoom != null && (currentLabRoom.equals("phòng xét nghiệm máu - đường huyết") || currentLabRoom.equals("phòng xét nghiệm máu"))) {
                     metrics = com.diabetes.monitoring.util.RandomTestGenerator.generateBloodSugarMetrics();
                 } else if (currentLabRoom != null && currentLabRoom.equals("phòng xét nghiệm máu - chức năng gan")) {
                     metrics = com.diabetes.monitoring.util.RandomTestGenerator.generateLiverMetrics();
                 } else if (currentLabRoom != null && currentLabRoom.equals("phòng xét nghiệm máu - chức năng thận")) {
                     metrics = com.diabetes.monitoring.util.RandomTestGenerator.generateKidneyMetrics();
                 } else if (currentLabRoom != null && currentLabRoom.equals("phòng xét nghiệm máu - mỡ máu")) {
                     metrics = com.diabetes.monitoring.util.RandomTestGenerator.generateLipidsMetrics();
                 } else if (currentLabRoom != null && currentLabRoom.equals("phòng xét nghiệm nước tiểu")) {
                     metrics = com.diabetes.monitoring.util.RandomTestGenerator.generateUrineMetrics();
                 } else {
                     metrics = com.diabetes.monitoring.util.RandomTestGenerator.generateRandomMetrics();
                 }
                 
                 urea = metrics.get("urea");
                 cr = metrics.get("cr");
                 hba1c = metrics.get("hba1c");
                 chol = metrics.get("chol");
                 tg = metrics.get("tg");
                 hdl = metrics.get("hdl");
                 ldl = metrics.get("ldl");
                 vldl = metrics.get("vldl");
                 
                 BigDecimal existingWeight = null;
                 BigDecimal existingHeight = null;
                 try (Connection conn = DatabaseConnection.getConnection()) {
                     String sqlPrev = "SELECT TOP 1 weight, height FROM Healthy_Record WHERE patient_id = ? AND weight > 0 AND height > 0 ORDER BY created_at DESC";
                     try (PreparedStatement stmtPrev = conn.prepareStatement(sqlPrev)) {
                         stmtPrev.setInt(1, patientId);
                         try (ResultSet rsPrev = stmtPrev.executeQuery()) {
                             if (rsPrev.next()) {
                                 existingWeight = rsPrev.getBigDecimal("weight");
                                 existingHeight = rsPrev.getBigDecimal("height");
                             }
                         }
                     }
                 } catch (Exception e) {
                     e.printStackTrace();
                 }

                 if (existingWeight != null && existingHeight != null) {
                     weight = existingWeight;
                     height = existingHeight;
                     double w = weight.doubleValue();
                     double h = height.doubleValue();
                     if (h > 0) {
                         double hMeter = h / 100.0;
                         bmi = BigDecimal.valueOf(w / (hMeter * hMeter)).setScale(2, RoundingMode.HALF_UP);
                     } else {
                         bmi = BigDecimal.ZERO;
                     }
                 } else {
                     weight = metrics.get("weight");
                     height = metrics.get("height");
                     bmi = metrics.get("bmi");
                 }
                 
                 if (currentLabRoom != null) {
                     otherInfo = currentLabRoom;
                 } else {
                     otherInfo = "Chỉ số xét nghiệm được sinh ngẫu nhiên tự động.";
                 }
             } else {
                 String ureaStr = request.getParameter("urea");
                 String crStr = request.getParameter("cr");
                 String hba1cStr = request.getParameter("hba1c");
                 String cholStr = request.getParameter("chol");
                 String tgStr = request.getParameter("tg");
                 String hdlStr = request.getParameter("hdl");
                 String ldlStr = request.getParameter("ldl");
                 String vldlStr = request.getParameter("vldl");
                 String weightStr = request.getParameter("weight");
                 String heightStr = request.getParameter("height");
                 String otherInfoRaw = request.getParameter("otherInfo");

                 urea = parseDecimal(ureaStr);
                 cr = parseDecimal(crStr);
                 hba1c = parseDecimal(hba1cStr);
                 chol = parseDecimal(cholStr);
                 tg = parseDecimal(tgStr);
                 hdl = parseDecimal(hdlStr);
                 ldl = parseDecimal(ldlStr);
                 vldl = parseDecimal(vldlStr);
                 weight = parseDecimal(weightStr);
                 height = parseDecimal(heightStr);
                 bmi = calculateBMI(weight, height);
                 otherInfo = otherInfoRaw != null ? otherInfoRaw.trim() : "";
             }

            try (Connection conn = DatabaseConnection.getConnection()) {
                conn.setAutoCommit(false); // Begin transaction

                // 1. Check if patient is already tested in this visit
                boolean alreadyTested = false;
                currentLabRoom = null;
                int matchingServiceId = 0;
                if (waitingIdStr != null && !waitingIdStr.trim().isEmpty()) {
                    String sqlCheck = "SELECT lo.status, lo.room_id, lo.service_id, r.room_name, dl.lab_name, ms.service_name "
                            + "FROM Lab_Order lo "
                            + "LEFT JOIN Room r ON r.room_id = lo.room_id "
                            + "LEFT JOIN Doctor_Lab dl ON dl.lab_id = lo.lab_id "
                            + "LEFT JOIN Medical_Service ms ON ms.service_id = lo.service_id "
                            + "WHERE lo.order_id = ?";
                    try (PreparedStatement stmtCheck = conn.prepareStatement(sqlCheck)) {
                        stmtCheck.setString(1, waitingIdStr.trim());
                        try (ResultSet rsCheck = stmtCheck.executeQuery()) {
                            if (rsCheck.next()) {
                                String svcName = rsCheck.getString("service_name");
                                String labName = rsCheck.getString("lab_name");
                                String roomName = rsCheck.getString("room_name");
                                currentLabRoom = normalizeRoomName(svcName != null ? svcName : (labName != null ? labName : roomName));
                                matchingServiceId = rsCheck.getInt("service_id");
                                if ("completed".equals(rsCheck.getString("status"))) {
                                    alreadyTested = true;
                                }
                            }
                        }
                    }
                } else {
                    String sqlCheckLatest = "SELECT TOP 1 lo.status, lo.room_id, lo.service_id, r.room_name, dl.lab_name, ms.service_name "
                            + "FROM Lab_Order lo "
                            + "LEFT JOIN Room r ON r.room_id = lo.room_id "
                            + "LEFT JOIN Doctor_Lab dl ON dl.lab_id = lo.lab_id "
                            + "LEFT JOIN Medical_Service ms ON ms.service_id = lo.service_id "
                            + "WHERE lo.patient_id = ? ORDER BY lo.created_at DESC";
                    try (PreparedStatement stmtCheck = conn.prepareStatement(sqlCheckLatest)) {
                        stmtCheck.setInt(1, patientId);
                        try (ResultSet rsCheck = stmtCheck.executeQuery()) {
                            if (rsCheck.next()) {
                                String svcName = rsCheck.getString("service_name");
                                String labName = rsCheck.getString("lab_name");
                                String roomName = rsCheck.getString("room_name");
                                currentLabRoom = normalizeRoomName(svcName != null ? svcName : (labName != null ? labName : roomName));
                                matchingServiceId = rsCheck.getInt("service_id");
                                if ("completed".equals(rsCheck.getString("status"))) {
                                    alreadyTested = true;
                                }
                            }
                        }
                    }
                }

                if (alreadyTested) {
                    conn.rollback();
                    session.setAttribute("errorMsg", "Bệnh nhân này đã hoàn thành xét nghiệm cho lần khám hiện tại.");
                    response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard");
                    return;
                }



                // Retrieve logged in lab doctor's ID
                int loggedInLabId = 0;
                String sqlLabId = "SELECT lab_id FROM Doctor_Lab WHERE account_id = ?";
                try (PreparedStatement stmt = conn.prepareStatement(sqlLabId)) {
                    stmt.setInt(1, currentUser.getId());
                    try (ResultSet rs = stmt.executeQuery()) {
                        if (rs.next()) {
                            loggedInLabId = rs.getInt("lab_id");
                        }
                    }
                }

                // Find a pending Invoice_Detail request
                int matchingInvoiceDetailId = 0;
                int matchingHealthRecordId = 0;
                
                String findRequestSql;
                if (matchingServiceId > 0) {
                    findRequestSql = "SELECT TOP 1 id.invoice_detail_id, id.health_record_id "
                            + "FROM Invoice_Detail id "
                            + "JOIN Invoice i ON id.invoice_id = i.invoice_id "
                            + "WHERE i.patient_id = ? AND id.service_id = ? "
                            + "AND id.lab_status IN ('Waiting_Payment', 'Requested', 'Processing') "
                            + "AND (id.lab_id = ? OR id.lab_id IS NULL) "
                            + "ORDER BY id.requested_at ASC";
                } else {
                    findRequestSql = "SELECT TOP 1 id.invoice_detail_id, id.health_record_id "
                            + "FROM Invoice_Detail id "
                            + "JOIN Invoice i ON id.invoice_id = i.invoice_id "
                            + "WHERE i.patient_id = ? "
                            + "AND id.lab_status IN ('Waiting_Payment', 'Requested', 'Processing') "
                            + "AND (id.lab_id = ? OR id.lab_id IS NULL) "
                            + "ORDER BY id.requested_at ASC";
                }
                
                try (PreparedStatement stmtFind = conn.prepareStatement(findRequestSql)) {
                    if (matchingServiceId > 0) {
                        stmtFind.setInt(1, patientId);
                        stmtFind.setInt(2, matchingServiceId);
                        stmtFind.setInt(3, loggedInLabId);
                    } else {
                        stmtFind.setInt(1, patientId);
                        stmtFind.setInt(2, loggedInLabId);
                    }
                    try (ResultSet rsFind = stmtFind.executeQuery()) {
                        if (rsFind.next()) {
                            matchingInvoiceDetailId = rsFind.getInt("invoice_detail_id");
                            Object hrObj = rsFind.getObject("health_record_id");
                            matchingHealthRecordId = hrObj != null ? (Integer) hrObj : 0;
                        }
                    }
                }

                if (matchingHealthRecordId > 0) {
                    // Update existing Healthy_Record with the lab results
                    String sqlUpdateHR = "UPDATE Healthy_Record SET "
                            + "urea = COALESCE(?, urea), cr = COALESCE(?, cr), "
                            + "hba1c = COALESCE(?, hba1c), chol = COALESCE(?, chol), "
                            + "tg = COALESCE(?, tg), hdl = COALESCE(?, hdl), "
                            + "ldl = COALESCE(?, ldl), vldl = COALESCE(?, vldl), "
                            + "bmi = COALESCE(?, bmi), "
                            + "weight = CASE WHEN weight IS NULL OR weight = 0 THEN ? ELSE weight END, "
                            + "height = CASE WHEN height IS NULL OR height = 0 THEN ? ELSE height END, "
                            + "status = 'Accepted', synced_at = GETDATE(), "
                            + "other_information = CASE WHEN other_information IS NULL OR other_information = '' "
                            + "THEN ? ELSE other_information + '; ' + ? END "
                            + "WHERE health_record_id = ?";
                    try (PreparedStatement stmt = conn.prepareStatement(sqlUpdateHR)) {
                        stmt.setBigDecimal(1, urea);
                        stmt.setBigDecimal(2, cr);
                        stmt.setBigDecimal(3, hba1c);
                        stmt.setBigDecimal(4, chol);
                        stmt.setBigDecimal(5, tg);
                        stmt.setBigDecimal(6, hdl);
                        stmt.setBigDecimal(7, ldl);
                        stmt.setBigDecimal(8, vldl);
                        stmt.setBigDecimal(9, bmi);
                        stmt.setBigDecimal(10, weight);
                        stmt.setBigDecimal(11, height);
                        stmt.setString(12, otherInfo);
                        stmt.setString(13, otherInfo);
                        stmt.setInt(14, matchingHealthRecordId);
                        stmt.executeUpdate();
                    }

                    // Update Invoice_Detail to Completed
                    String sqlUpdateDetail = "UPDATE Invoice_Detail SET "
                            + "lab_status = 'Completed', "
                            + "lab_result = ?, "
                            + "completed_at = GETDATE() "
                            + "WHERE invoice_detail_id = ?";
                    try (PreparedStatement stmt = conn.prepareStatement(sqlUpdateDetail)) {
                        String resultSummary = String.format(
                            "HbA1c: %s, Urea: %s, CR: %s, Chol: %s, TG: %s, HDL: %s, LDL: %s",
                            hba1c != null ? hba1c.toString() : "0",
                            urea != null ? urea.toString() : "0",
                            cr != null ? cr.toString() : "0",
                            chol != null ? chol.toString() : "0",
                            tg != null ? tg.toString() : "0",
                            hdl != null ? hdl.toString() : "0",
                            ldl != null ? ldl.toString() : "0"
                        );
                        stmt.setString(1, resultSummary);
                        stmt.setInt(2, matchingInvoiceDetailId);
                        stmt.executeUpdate();
                    }
                } else {
                    // Fallback to inserting a new Healthy_Record
                    String sqlInsert = "INSERT INTO Healthy_Record (urea, cr, hba1c, chol, tg, hdl, ldl, vldl, bmi, patient_id, weight, height, other_information, status, created_at) " +
                            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Accepted', GETDATE())";
                    int newHRId = 0;
                    try (PreparedStatement stmt = conn.prepareStatement(sqlInsert, java.sql.Statement.RETURN_GENERATED_KEYS)) {
                        stmt.setBigDecimal(1, urea);
                        stmt.setBigDecimal(2, cr);
                        stmt.setBigDecimal(3, hba1c);
                        stmt.setBigDecimal(4, chol);
                        stmt.setBigDecimal(5, tg);
                        stmt.setBigDecimal(6, hdl);
                        stmt.setBigDecimal(7, ldl);
                        stmt.setBigDecimal(8, vldl);
                        stmt.setBigDecimal(9, bmi);
                        stmt.setInt(10, patientId);
                        stmt.setBigDecimal(11, weight);
                        stmt.setBigDecimal(12, height);
                        stmt.setString(13, otherInfo);
                        stmt.executeUpdate();
                        try (ResultSet rs = stmt.getGeneratedKeys()) {
                            if (rs.next()) {
                                newHRId = rs.getInt(1);
                            }
                        }
                    }

                    // Also update corresponding Invoice_Detail status to Completed and link health_record_id
                    if (matchingInvoiceDetailId > 0 && newHRId > 0) {
                        String sqlUpdateDetail = "UPDATE Invoice_Detail SET "
                                + "lab_status = 'Completed', "
                                + "health_record_id = ?, "
                                + "lab_result = ?, "
                                + "completed_at = GETDATE() "
                                + "WHERE invoice_detail_id = ?";
                        try (PreparedStatement stmt = conn.prepareStatement(sqlUpdateDetail)) {
                            String resultSummary = String.format(
                                "HbA1c: %s, Urea: %s, CR: %s, Chol: %s, TG: %s, HDL: %s, LDL: %s",
                                hba1c != null ? hba1c.toString() : "0",
                                urea != null ? urea.toString() : "0",
                                cr != null ? cr.toString() : "0",
                                chol != null ? chol.toString() : "0",
                                tg != null ? tg.toString() : "0",
                                hdl != null ? hdl.toString() : "0",
                                ldl != null ? ldl.toString() : "0"
                            );
                            stmt.setInt(1, newHRId);
                            stmt.setString(2, resultSummary);
                            stmt.setInt(3, matchingInvoiceDetailId);
                            stmt.executeUpdate();
                        }
                    }
                }

                // 3. Update waiting status if needed
                if (waitingIdStr != null && !waitingIdStr.trim().isEmpty()) {
                    String sqlUpdateWaiting = "UPDATE Lab_Order SET status = 'completed' WHERE order_id = ?";
                    try (PreparedStatement stmtUpdate = conn.prepareStatement(sqlUpdateWaiting)) {
                        stmtUpdate.setString(1, waitingIdStr.trim());
                        stmtUpdate.executeUpdate();
                    }
                }

                conn.commit(); // Commit transaction
                session.setAttribute("successMsg", "Nhập kết quả xét nghiệm thành công!");
            } catch (SQLException e) {
                e.printStackTrace();
                session.setAttribute("errorMsg", "Lỗi cơ sở dữ liệu khi lưu kết quả: " + e.getMessage());
            }

        } catch (NumberFormatException e) {
            session.setAttribute("errorMsg", "Lỗi định dạng dữ liệu số.");
        }

        response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard");
    }

    private boolean isRecordAbnormal(BigDecimal hba1c, BigDecimal urea, BigDecimal cr, BigDecimal chol, BigDecimal tg, BigDecimal hdl, BigDecimal ldl) {
        if (hba1c != null && hba1c.compareTo(BigDecimal.ZERO) > 0 && (hba1c.compareTo(new BigDecimal("4.0")) < 0 || hba1c.compareTo(new BigDecimal("5.6")) > 0)) return true;
        if (urea != null && urea.compareTo(BigDecimal.ZERO) > 0 && (urea.compareTo(new BigDecimal("2.5")) < 0 || urea.compareTo(new BigDecimal("7.5")) > 0)) return true;
        if (cr != null && cr.compareTo(BigDecimal.ZERO) > 0 && (cr.compareTo(new BigDecimal("45.0")) < 0 || cr.compareTo(new BigDecimal("110.0")) > 0)) return true;
        if (chol != null && chol.compareTo(BigDecimal.ZERO) > 0 && chol.compareTo(new BigDecimal("5.2")) >= 0) return true;
        if (tg != null && tg.compareTo(BigDecimal.ZERO) > 0 && tg.compareTo(new BigDecimal("1.7")) >= 0) return true;
        if (hdl != null && hdl.compareTo(BigDecimal.ZERO) > 0 && hdl.compareTo(new BigDecimal("1.0")) <= 0) return true;
        if (ldl != null && ldl.compareTo(BigDecimal.ZERO) > 0 && ldl.compareTo(new BigDecimal("3.4")) >= 0) return true;
        return false;
    }

    private BigDecimal parseDecimal(String val) {
        if (val == null || val.trim().isEmpty()) {
            return BigDecimal.ZERO;
        }
        try {
            return new BigDecimal(val.trim());
        } catch (NumberFormatException e) {
            return BigDecimal.ZERO;
        }
    }

    private BigDecimal calculateBMI(BigDecimal weight, BigDecimal height) {
        if (weight == null || height == null || weight.compareTo(BigDecimal.ZERO) <= 0 || height.compareTo(BigDecimal.ZERO) <= 0) {
            return BigDecimal.ZERO;
        }
        BigDecimal heightInMeters = height.divide(new BigDecimal("100"), 4, RoundingMode.HALF_UP);
        BigDecimal heightSquared = heightInMeters.multiply(heightInMeters);
        return weight.divide(heightSquared, 2, RoundingMode.HALF_UP);
    }

    private String formatDecimal(BigDecimal val) {
        if (val == null) return "0";
        return val.stripTrailingZeros().toPlainString();
    }

    private boolean isDoctorLabRole(String role) {
        if (role == null) {
            return false;
        }
        String normalized = role.trim().replace("-", "_").replace(" ", "_");
        return "doctor_lab".equalsIgnoreCase(normalized);
    }

    private String normalizeRoomName(String rawRoom) {
        if (rawRoom == null) return "";
        String rL = rawRoom.toLowerCase();
        if (rL.contains("gan")) {
            return "phòng xét nghiệm máu - chức năng gan";
        } else if (rL.contains("thận")) {
            return "phòng xét nghiệm máu - chức năng thận";
        } else if (rL.contains("mỡ máu") || rL.contains("cholesterol") || rL.contains("lipid")) {
            return "phòng xét nghiệm máu - mỡ máu";
        } else if (rL.contains("đường huyết") || rL.contains("hba1c") || rL.contains("glucose")) {
            return "phòng xét nghiệm máu - đường huyết";
        } else if (rL.contains("nước tiểu")) {
            return "phòng xét nghiệm nước tiểu";
        } else if (rL.contains("máu")) {
            return "phòng xét nghiệm máu";
        }
        return rawRoom;
    }

    private Integer getLabIdFromRoomName(Connection conn, String roomName) throws SQLException {
        String labName = null;
        if (roomName != null) {
            String rL = roomName.toLowerCase();
            if (rL.contains("gan")) {
                labName = "Phòng Xét nghiệm Chức năng Gan";
            } else if (rL.contains("thận")) {
                labName = "Phòng Xét nghiệm Chức năng Thận";
            } else if (rL.contains("nước tiểu")) {
                labName = "Phòng Xét nghiệm Nước tiểu";
            } else if (rL.contains("máu") || rL.contains("đường huyết") || rL.contains("mỡ máu")) {
                labName = "Phòng Xét nghiệm Máu";
            }
        }
        if (labName != null) {
            String sql = "SELECT lab_id FROM Doctor_Lab WHERE lab_name = ?";
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setString(1, labName);
                try (ResultSet rs = stmt.executeQuery()) {
                    if (rs.next()) {
                        return rs.getInt("lab_id");
                    }
                }
            }
        }
        return null;
    }

    private int getServiceIdFromRoomName(Connection conn, String roomName) throws SQLException {
        String query = "SELECT service_id, service_name FROM Medical_Service WHERE service_type = 'Lab_Test' AND status = 'Active'";
        List<Integer> ids = new ArrayList<>();
        List<String> names = new ArrayList<>();
        try (PreparedStatement stmt = conn.prepareStatement(query);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                ids.add(rs.getInt("service_id"));
                names.add(rs.getString("service_name").toLowerCase());
            }
        }
        if (roomName != null) {
            String rL = roomName.toLowerCase();
            if (rL.contains("gan")) {
                for (int i = 0; i < names.size(); i++) {
                    if (names.get(i).contains("gan")) return ids.get(i);
                }
            }
            if (rL.contains("thận")) {
                for (int i = 0; i < names.size(); i++) {
                    if (names.get(i).contains("thận")) return ids.get(i);
                }
            }
            if (rL.contains("nước tiểu")) {
                for (int i = 0; i < names.size(); i++) {
                    if (names.get(i).contains("nước tiểu")) return ids.get(i);
                }
            }
            if (rL.contains("mỡ máu")) {
                for (int i = 0; i < names.size(); i++) {
                    if (names.get(i).contains("mỡ máu") || names.get(i).contains("lipid")) return ids.get(i);
                }
            }
            if (rL.contains("máu") || rL.contains("đường huyết")) {
                for (int i = 0; i < names.size(); i++) {
                    if (names.get(i).contains("máu") || names.get(i).contains("hba1c") || names.get(i).contains("glucose")) return ids.get(i);
                }
            }
        }
        if (!ids.isEmpty()) {
            return ids.get(0);
        }
        return 2;
    }

    private String getRoomIdForLab(Connection conn, Integer labId) throws SQLException {
        if (labId != null && labId > 0) {
            String sql = "SELECT TOP 1 room_id FROM Lab_Schedule WHERE lab_id = ? AND work_date = CAST(GETDATE() AS date) AND LOWER(status) = 'scheduled' ORDER BY lab_sched_id DESC";
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setInt(1, labId);
                try (ResultSet rs = stmt.executeQuery()) {
                    if (rs.next()) {
                        String rId = rs.getString("room_id");
                        if (rId != null && !rId.trim().isEmpty()) {
                            return rId;
                        }
                    }
                }
            }
        }
        String fallbackSql = "SELECT TOP 1 room_id FROM Room ORDER BY room_id";
        try (PreparedStatement stmt = conn.prepareStatement(fallbackSql);
             ResultSet rs = stmt.executeQuery()) {
            if (rs.next()) {
                return rs.getString("room_id");
            }
        }
        return "R101";
    }
}
