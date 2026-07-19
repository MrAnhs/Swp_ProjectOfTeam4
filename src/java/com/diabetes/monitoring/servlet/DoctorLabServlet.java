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
            String sqlPatients = "SELECT p.patient_id, p.full_name, p.email, p.phone, p.date_of_birth, p.gender, p.address, " +
                    "       id.invoice_detail_id AS waiting_id, " +
                    "       id.lab_status AS waitlist_status, " +
                    "       ms.service_name AS lab_room, " +
                    "       COALESCE((SELECT COUNT(*) FROM Healthy_Record WHERE patient_id = p.patient_id), 0) as record_count " +
                    "FROM Patient p " +
                    "JOIN Invoice i ON p.patient_id = i.patient_id " +
                    "JOIN Invoice_Detail id ON i.invoice_id = id.invoice_id AND id.lab_status IS NOT NULL AND id.service_id IN (1, 2, 3, 4, 5) " +
                    "JOIN Medical_Service ms ON ms.service_id = id.service_id " +
                    "ORDER BY p.full_name ASC, id.invoice_detail_id DESC";
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
                    p.put("gender", rs.getString("gender"));
                    p.put("address", rs.getString("address"));
                    
                    int recordCount = rs.getInt("record_count");
                    String waitlistStatus = rs.getString("waitlist_status");
                    int waitingId = rs.getInt("waiting_id");
                    String labRoom = rs.getString("lab_room");
                    
                    if ("Requested".equalsIgnoreCase(waitlistStatus) || "Waiting_Payment".equalsIgnoreCase(waitlistStatus)) {
                        waitlistStatus = "waiting";
                    } else if ("Processing".equalsIgnoreCase(waitlistStatus)) {
                        waitlistStatus = "testing";
                    } else if ("Completed".equalsIgnoreCase(waitlistStatus)) {
                        waitlistStatus = "completed";
                    } else {
                        waitlistStatus = "";
                    }

                    if (labRoom != null) {
                        String lower = labRoom.toLowerCase();
                        if (lower.contains("đường huyết")) {
                            labRoom = "phòng xét nghiệm máu - đường huyết";
                        } else if (lower.contains("nước tiểu")) {
                            labRoom = "phòng xét nghiệm nước tiểu";
                        } else if (lower.contains("gan")) {
                            labRoom = "phòng xét nghiệm máu - chức năng gan";
                        } else if (lower.contains("thận")) {
                            labRoom = "phòng xét nghiệm máu - chức năng thận";
                        } else if (lower.contains("mỡ máu")) {
                            labRoom = "phòng xét nghiệm máu - mỡ máu";
                        } else {
                            labRoom = lower;
                        }
                    }

                    p.put("recordCount", String.valueOf(recordCount));
                    p.put("waitlistStatus", waitlistStatus);
                    p.put("waitingId", waitingId > 0 ? String.valueOf(waitingId) : "");
                    p.put("labRoom", labRoom != null ? labRoom : "");
                    
                    uniquePatientIds.add(pId);

                    boolean isCompleted = "completed".equals(waitlistStatus) || ((waitlistStatus == null || waitlistStatus.isEmpty()) && recordCount > 0);
                    if (isCompleted || recordCount > 0) {
                        completedPatientIds.add(pId);
                    }

                    if ("waiting".equals(waitlistStatus) || "testing".equals(waitlistStatus)) {
                        waitingCount++;
                        // Also populate waitingPatients list for backward compatibility if needed
                        Map<String, String> wp = new HashMap<>(p);
                        wp.put("waitingId", String.valueOf(waitingId));
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
                totalPatients = uniquePatientIds.size();
                completedCount = completedPatientIds.size();
            }

            String sqlRecords = "SELECT hr.health_record_id, hr.patient_id, p.full_name as patient_name, hr.urea, hr.cr, hr.hba1c, " +
                    "hr.chol, hr.tg, hr.hdl, hr.ldl, hr.vldl, hr.weight, hr.height, hr.bmi, hr.status, hr.created_at, hr.other_information " +
                    "FROM Healthy_Record hr " +
                    "INNER JOIN Patient p ON hr.patient_id = p.patient_id " +
                    "ORDER BY hr.created_at DESC";
            try (PreparedStatement stmt = conn.prepareStatement(sqlRecords);
                 ResultSet rs = stmt.executeQuery()) {
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

            // Retrieve lab doctor schedule (No longer query Lab_Schedule table from database)
            List<Map<String, String>> schedules = new ArrayList<>();
            request.setAttribute("schedules", schedules);
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
                int waitingId = Integer.parseInt(waitingIdStr.trim());
                String sqlInvite = "UPDATE Invoice_Detail SET lab_status = 'Processing' WHERE invoice_detail_id = ?";
                try (PreparedStatement stmt = conn.prepareStatement(sqlInvite)) {
                    stmt.setInt(1, waitingId);
                    stmt.executeUpdate();
                }
                
                // Also update corresponding Lab_Order status to 'Processing'
                String sqlUpdateLabOrder = "UPDATE lo " +
                        "SET lo.status = 'Processing' " +
                        "FROM Lab_Order lo " +
                        "JOIN Invoice_Detail id ON ( " +
                        "    (id.appointment_id IS NOT NULL AND lo.appointment_id = id.appointment_id AND lo.service_id = id.service_id) " +
                        "    OR " +
                        "    (id.appointment_id IS NULL AND lo.service_id = id.service_id AND lo.patient_id = (SELECT patient_id FROM Invoice WHERE invoice_id = id.invoice_id)) " +
                        ") " +
                        "WHERE id.invoice_detail_id = ?";
                try (PreparedStatement stmtLab = conn.prepareStatement(sqlUpdateLabOrder)) {
                    stmtLab.setInt(1, waitingId);
                    stmtLab.executeUpdate();
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
                
                // Map newRoom name to a standard service_id
                int serviceId = 1; // Default to Blood sugar test
                BigDecimal price = new BigDecimal("150000.00");
                if (newRoom.toLowerCase().contains("nước tiểu")) {
                    serviceId = 2;
                    price = new BigDecimal("80000.00");
                } else if (newRoom.toLowerCase().contains("mỡ máu")) {
                    serviceId = 3;
                    price = new BigDecimal("300000.00");
                } else if (newRoom.toLowerCase().contains("gan")) {
                    serviceId = 4;
                    price = new BigDecimal("150000.00");
                } else if (newRoom.toLowerCase().contains("thận")) {
                    serviceId = 5;
                    price = new BigDecimal("150000.00");
                }
                
                // Fetch latest paid or unpaid invoice
                int invoiceId = -1;
                String sqlInvoice = "SELECT TOP 1 invoice_id FROM Invoice WHERE patient_id = ? ORDER BY created_at DESC";
                try (PreparedStatement stmtInv = conn.prepareStatement(sqlInvoice)) {
                    stmtInv.setInt(1, patientId);
                    try (ResultSet rsInv = stmtInv.executeQuery()) {
                        if (rsInv.next()) {
                            invoiceId = rsInv.getInt("invoice_id");
                        }
                    }
                }
                
                if (invoiceId == -1) {
                    session.setAttribute("errorMsg", "Không tìm thấy hóa đơn nào của bệnh nhân để liên kết chỉ định.");
                    response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard");
                    return;
                }
                
                // Fetch latest appointment
                int appointmentId = 1;
                String sqlApp = "SELECT TOP 1 appointment_id FROM Appointment WHERE patient_id = ? ORDER BY appointment_time DESC";
                try (PreparedStatement stmtApp = conn.prepareStatement(sqlApp)) {
                    stmtApp.setInt(1, patientId);
                    try (ResultSet rsApp = stmtApp.executeQuery()) {
                        if (rsApp.next()) {
                            appointmentId = rsApp.getInt("appointment_id");
                        }
                    }
                }

                // Check if they already have an active entry of this service
                String sqlCheckRoom = "SELECT COUNT(*) FROM Invoice_Detail WHERE invoice_id = ? AND service_id = ? AND lab_status IN ('Requested', 'Processing')";
                try (PreparedStatement stmtCheck = conn.prepareStatement(sqlCheckRoom)) {
                    stmtCheck.setInt(1, invoiceId);
                    stmtCheck.setInt(2, serviceId);
                    try (ResultSet rsCheck = stmtCheck.executeQuery()) {
                        if (rsCheck.next() && rsCheck.getInt(1) > 0) {
                            session.setAttribute("errorMsg", "Xét nghiệm này đã được chỉ định hoặc đang chờ thực hiện.");
                            response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard");
                            return;
                        }
                    }
                }
                
                // Determine room_id
                String roomId = "R301";
                if (serviceId == 2) {
                    roomId = "R302";
                }

                // Generate new unique order_id (LOXXX)
                String orderId = "LO010";
                String sqlMaxOrder = "SELECT TOP 1 order_id FROM Lab_Order ORDER BY order_id DESC";
                try (PreparedStatement stmtMax = conn.prepareStatement(sqlMaxOrder);
                     ResultSet rsMax = stmtMax.executeQuery()) {
                    if (rsMax.next()) {
                        String maxId = rsMax.getString("order_id");
                        if (maxId != null && maxId.startsWith("LO")) {
                            try {
                                int num = Integer.parseInt(maxId.substring(2)) + 1;
                                orderId = String.format("LO%03d", num);
                            } catch (Exception e) {}
                        }
                    }
                }

                // Insert into Invoice_Detail
                String sqlInsertWaiting = "INSERT INTO Invoice_Detail (invoice_id, service_id, appointment_id, quantity, price, doctor_id, lab_status, requested_at) " +
                                          "VALUES (?, ?, ?, 1, ?, 5, 'Requested', GETDATE())";
                try (PreparedStatement stmtWait = conn.prepareStatement(sqlInsertWaiting)) {
                    stmtWait.setInt(1, invoiceId);
                    stmtWait.setInt(2, serviceId);
                    stmtWait.setInt(3, appointmentId);
                    stmtWait.setBigDecimal(4, price);
                    stmtWait.executeUpdate();
                }

                // Insert into Lab_Order
                String sqlInsertLab = "INSERT INTO Lab_Order (order_id, appointment_id, patient_id, room_id, service_id, lab_id, status, created_at) " +
                                      "VALUES (?, ?, ?, ?, ?, 1, 'Waiting', GETDATE())";
                try (PreparedStatement stmtLab = conn.prepareStatement(sqlInsertLab)) {
                    stmtLab.setString(1, orderId);
                    stmtLab.setInt(2, appointmentId);
                    stmtLab.setInt(3, patientId);
                    stmtLab.setString(4, roomId);
                    stmtLab.setInt(5, serviceId);
                    stmtLab.executeUpdate();
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

             String requestLabRoom = request.getParameter("labRoom");
             if (requestLabRoom != null && requestLabRoom.trim().isEmpty()) {
                 requestLabRoom = null;
             }
             String currentLabRoom = requestLabRoom;
             if (waitingIdStr != null && !waitingIdStr.trim().isEmpty()) {
                 int waitingId = Integer.parseInt(waitingIdStr.trim());
                 try (Connection conn = DatabaseConnection.getConnection()) {
                     String sqlCheck = "SELECT (SELECT service_name FROM Medical_Service WHERE service_id = id.service_id) as lab_room FROM Invoice_Detail id WHERE invoice_detail_id = ?";
                     try (PreparedStatement stmtCheck = conn.prepareStatement(sqlCheck)) {
                         stmtCheck.setInt(1, waitingId);
                         try (ResultSet rsCheck = stmtCheck.executeQuery()) {
                             if (rsCheck.next()) {
                                 currentLabRoom = rsCheck.getString("lab_room");
                             }
                         }
                     }
                 } catch (Exception e) {
                     e.printStackTrace();
                 }
             }

             if ("true".equals(isRandomStr)) {
                 java.util.Map<String, BigDecimal> metrics;
                 if (currentLabRoom != null && (currentLabRoom.toLowerCase().contains("máu") || currentLabRoom.toLowerCase().contains("đường huyết"))) {
                     metrics = com.diabetes.monitoring.util.RandomTestGenerator.generateBloodSugarMetrics();
                 } else if (currentLabRoom != null && currentLabRoom.toLowerCase().contains("gan")) {
                     metrics = com.diabetes.monitoring.util.RandomTestGenerator.generateLiverMetrics();
                 } else if (currentLabRoom != null && currentLabRoom.toLowerCase().contains("thận")) {
                     metrics = com.diabetes.monitoring.util.RandomTestGenerator.generateKidneyMetrics();
                 } else if (currentLabRoom != null && (currentLabRoom.toLowerCase().contains("mỡ máu") || currentLabRoom.toLowerCase().contains("cholesterol"))) {
                     metrics = com.diabetes.monitoring.util.RandomTestGenerator.generateLipidsMetrics();
                 } else if (currentLabRoom != null && (currentLabRoom.toLowerCase().contains("nước tiểu") || currentLabRoom.toLowerCase().contains("microalbumin"))) {
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
                String dbLabRoom = null;
                if (waitingIdStr != null && !waitingIdStr.trim().isEmpty()) {
                    int waitingId = Integer.parseInt(waitingIdStr.trim());
                    String sqlCheck = "SELECT id.lab_status, ms.service_name as lab_room FROM Invoice_Detail id JOIN Medical_Service ms ON ms.service_id = id.service_id WHERE id.invoice_detail_id = ?";
                    try (PreparedStatement stmtCheck = conn.prepareStatement(sqlCheck)) {
                        stmtCheck.setInt(1, waitingId);
                        try (ResultSet rsCheck = stmtCheck.executeQuery()) {
                            if (rsCheck.next()) {
                                dbLabRoom = rsCheck.getString("lab_room");
                                if ("Completed".equalsIgnoreCase(rsCheck.getString("lab_status"))) {
                                    alreadyTested = true;
                                }
                            }
                        }
                    }
                } else {
                    String sqlCheckLatest = "SELECT TOP 1 id.lab_status, ms.service_name as lab_room FROM Invoice_Detail id JOIN Invoice i ON i.invoice_id = id.invoice_id JOIN Medical_Service ms ON ms.service_id = id.service_id WHERE i.patient_id = ? ORDER BY id.invoice_detail_id DESC";
                    try (PreparedStatement stmtCheck = conn.prepareStatement(sqlCheckLatest)) {
                        stmtCheck.setInt(1, patientId);
                        try (ResultSet rsCheck = stmtCheck.executeQuery()) {
                            if (rsCheck.next()) {
                                dbLabRoom = rsCheck.getString("lab_room");
                                if ("Completed".equalsIgnoreCase(rsCheck.getString("lab_status"))) {
                                    alreadyTested = true;
                                }
                            }
                        }
                    }
                }

                if (dbLabRoom != null) {
                    currentLabRoom = dbLabRoom;
                }

                if (dbLabRoom == null) {
                    if (currentLabRoom == null || (!currentLabRoom.toLowerCase().contains("máu") 
                            && !currentLabRoom.toLowerCase().contains("nước tiểu") && !currentLabRoom.toLowerCase().contains("đường huyết"))) {
                        conn.rollback();
                        session.setAttribute("errorMsg", "Xét nghiệm này cần được bác sĩ chỉ định trước!");
                        response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard");
                        return;
                    }
                }

                if (alreadyTested) {
                    conn.rollback();
                    session.setAttribute("errorMsg", "Bệnh nhân này đã hoàn thành xét nghiệm cho lần khám hiện tại.");
                    response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard");
                    return;
                }

                if (currentLabRoom != null) {
                    String lower = currentLabRoom.toLowerCase();
                    if (lower.contains("đường huyết")) {
                        otherInfo = "phòng xét nghiệm máu - đường huyết";
                    } else if (lower.contains("nước tiểu")) {
                        otherInfo = "phòng xét nghiệm nước tiểu";
                    } else if (lower.contains("gan")) {
                        otherInfo = "phòng xét nghiệm máu - chức năng gan";
                    } else if (lower.contains("thận")) {
                        otherInfo = "phòng xét nghiệm máu - chức năng thận";
                    } else if (lower.contains("mỡ máu")) {
                        otherInfo = "phòng xét nghiệm máu - mỡ máu";
                    } else {
                        otherInfo = currentLabRoom;
                    }
                }

                // 2. Fetch invoice_id and check if Healthy_Record already exists for this invoice
                int healthRecordId = -1;
                int invoiceId = -1;
                if (waitingIdStr != null && !waitingIdStr.trim().isEmpty()) {
                    int waitingId = Integer.parseInt(waitingIdStr.trim());
                    String sqlGetInvoice = "SELECT invoice_id FROM Invoice_Detail WHERE invoice_detail_id = ?";
                    try (PreparedStatement ps = conn.prepareStatement(sqlGetInvoice)) {
                        ps.setInt(1, waitingId);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) {
                                invoiceId = rs.getInt("invoice_id");
                            }
                        }
                    }
                }

                if (invoiceId > 0) {
                    String sqlFindRecord = "SELECT health_record_id FROM Healthy_Record WHERE invoice_id = ?";
                    try (PreparedStatement ps = conn.prepareStatement(sqlFindRecord)) {
                        ps.setInt(1, invoiceId);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) {
                                healthRecordId = rs.getInt("health_record_id");
                            }
                        }
                    }
                }

                if (healthRecordId > 0) {
                    // Update existing Healthy_Record with non-null values
                    String sqlUpdate = "UPDATE Healthy_Record SET " +
                            "urea = COALESCE(?, urea), " +
                            "cr = COALESCE(?, cr), " +
                            "hba1c = COALESCE(?, hba1c), " +
                            "chol = COALESCE(?, chol), " +
                            "tg = COALESCE(?, tg), " +
                            "hdl = COALESCE(?, hdl), " +
                            "ldl = COALESCE(?, ldl), " +
                            "vldl = COALESCE(?, vldl), " +
                            "bmi = COALESCE(?, bmi), " +
                            "weight = COALESCE(?, weight), " +
                            "height = COALESCE(?, height), " +
                            "other_information = CASE WHEN ? IS NOT NULL AND LTRIM(RTRIM(?)) <> '' THEN ? ELSE other_information END, " +
                            "status = 'approved' " +
                            "WHERE health_record_id = ?";
                    try (PreparedStatement stmt = conn.prepareStatement(sqlUpdate)) {
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
                        stmt.setString(14, otherInfo);
                        stmt.setInt(15, healthRecordId);
                        stmt.executeUpdate();
                    }
                } else {
                    // Insert a new Healthy_Record
                    String sqlInsert = "INSERT INTO Healthy_Record (urea, cr, hba1c, chol, tg, hdl, ldl, vldl, bmi, patient_id, weight, height, other_information, status, created_at, invoice_id) " +
                            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'approved', GETDATE(), ?)";
                    try (PreparedStatement stmt = conn.prepareStatement(sqlInsert, PreparedStatement.RETURN_GENERATED_KEYS)) {
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
                        if (invoiceId > 0) {
                            stmt.setInt(14, invoiceId);
                        } else {
                            stmt.setNull(14, java.sql.Types.INTEGER);
                        }
                        stmt.executeUpdate();
                        try (ResultSet generatedKeys = stmt.getGeneratedKeys()) {
                            if (generatedKeys.next()) {
                                healthRecordId = generatedKeys.getInt(1);
                            }
                        }
                    }
                }

                // 3. Update waiting status if needed
                if (waitingIdStr != null && !waitingIdStr.trim().isEmpty()) {
                    int waitingId = Integer.parseInt(waitingIdStr.trim());
                    String sqlUpdateWaiting = "UPDATE Invoice_Detail SET lab_status = 'Completed', health_record_id = ?, completed_at = GETDATE() WHERE invoice_detail_id = ?";
                    try (PreparedStatement stmtUpdate = conn.prepareStatement(sqlUpdateWaiting)) {
                        stmtUpdate.setInt(1, healthRecordId);
                        stmtUpdate.setInt(2, waitingId);
                        stmtUpdate.executeUpdate();
                    }
                    
                    // Also update corresponding Lab_Order status to 'Completed'
                    String sqlUpdateLabOrder = "UPDATE lo " +
                            "SET lo.status = 'Completed' " +
                            "FROM Lab_Order lo " +
                            "JOIN Invoice_Detail id ON ( " +
                            "    (id.appointment_id IS NOT NULL AND lo.appointment_id = id.appointment_id AND lo.service_id = id.service_id) " +
                            "    OR " +
                            "    (id.appointment_id IS NULL AND lo.service_id = id.service_id AND lo.patient_id = (SELECT patient_id FROM Invoice WHERE invoice_id = id.invoice_id)) " +
                            ") " +
                            "WHERE id.invoice_detail_id = ?";
                    try (PreparedStatement stmtLab = conn.prepareStatement(sqlUpdateLabOrder)) {
                        stmtLab.setInt(1, waitingId);
                        stmtLab.executeUpdate();
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
}
