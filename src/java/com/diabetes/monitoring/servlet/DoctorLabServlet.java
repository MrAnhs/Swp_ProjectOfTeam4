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
            String sqlPatients = "SELECT p.patient_id, p.full_name, p.email, p.phone, p.date_of_birth, p.gender, p.address, "
                    + "       CAST(id.invoice_detail_id AS VARCHAR(50)) AS waiting_id, "
                    + "       id.lab_status AS waitlist_status, "
                    + "       COALESCE(id.requested_at, i.created_at) AS requested_at, "
                    + "       ms.service_name AS lab_room, "
                    + "       COALESCE((SELECT COUNT(*) FROM Healthy_Record WHERE patient_id = p.patient_id), 0) as record_count "
                    + "FROM Invoice_Detail id "
                    + "JOIN Invoice i ON i.invoice_id = id.invoice_id "
                    + "JOIN Patient p ON p.patient_id = i.patient_id "
                    + "JOIN Medical_Service ms ON ms.service_id = id.service_id "
                    + "JOIN Doctor_Lab dl ON dl.account_id = ? "
                    + "WHERE (id.lab_id = dl.lab_id OR id.lab_id IS NULL) "
                    + "  AND id.lab_status IN ('Requested', 'Processing', 'Completed') "
                    + "UNION ALL "
                    + "SELECT p.patient_id, p.full_name, p.email, p.phone, p.date_of_birth, p.gender, p.address, "
                    + "       lo.order_id AS waiting_id, "
                    + "       lo.status AS waitlist_status, "
                    + "       lo.created_at AS requested_at, "
                    + "       ms.service_name AS lab_room, "
                    + "       COALESCE((SELECT COUNT(*) FROM Healthy_Record WHERE patient_id = p.patient_id), 0) as record_count "
                    + "FROM Lab_Order lo "
                    + "JOIN Patient p ON p.patient_id = lo.patient_id "
                    + "JOIN Medical_Service ms ON ms.service_id = lo.service_id "
                    + "JOIN Doctor_Lab dl ON dl.account_id = ? "
                    + "WHERE (lo.lab_id = dl.lab_id OR lo.lab_id IS NULL) "
                    + "  AND lo.status IN ('Requested', 'Processing', 'Completed') "
                    + "  AND NOT EXISTS ( "
                    + "      SELECT 1 FROM Invoice_Detail id2 "
                    + "      JOIN Invoice i2 ON i2.invoice_id = id2.invoice_id "
                    + "      WHERE i2.patient_id = lo.patient_id AND id2.service_id = lo.service_id "
                    + "        AND CONCAT('LAB-', id2.invoice_detail_id) = lo.order_id "
                    + "  ) "
                    + "ORDER BY requested_at DESC";
            try (PreparedStatement stmt = conn.prepareStatement(sqlPatients)) {
                stmt.setInt(1, currentUser.getId());
                stmt.setInt(2, currentUser.getId());
                try (ResultSet rs = stmt.executeQuery()) {

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
                        
                        java.sql.Timestamp reqAt = rs.getTimestamp("requested_at");
                        String reqAtStr = "";
                        if (reqAt != null) {
                            java.time.LocalDateTime ldt = reqAt.toLocalDateTime();
                            int hour = ldt.getHour();
                            String caStr = (hour >= 7 && hour < 12) ? "Ca 1 (7:30 - 12:00)" : ((hour >= 12 && hour <= 17) ? "Ca 2 (13:30 - 16:30)" : "Ngoại ca");
                            reqAtStr = ldt.format(java.time.format.DateTimeFormatter.ofPattern("HH:mm dd/MM/yyyy")) + " - " + caStr;
                        } else {
                            reqAtStr = "08:30 28/07/2026 - Ca 1 (7:30 - 12:00)";
                        }
                        p.put("requestedAt", reqAtStr);

                    
                    int recordCount = rs.getInt("record_count");
                    String waitlistStatus = rs.getString("waitlist_status");
                    String waitingId = rs.getString("waiting_id");
                    String labRoom = rs.getString("lab_room");
                    if ("Requested".equalsIgnoreCase(waitlistStatus) || "Waiting_Payment".equalsIgnoreCase(waitlistStatus) || "Waiting".equalsIgnoreCase(waitlistStatus) || "Pending".equalsIgnoreCase(waitlistStatus)) {
                        waitlistStatus = "waiting";
                    } else if ("Processing".equalsIgnoreCase(waitlistStatus) || "In_Progress".equalsIgnoreCase(waitlistStatus)) {
                        waitlistStatus = "testing";
                    } else if ("Completed".equalsIgnoreCase(waitlistStatus) || "Done".equalsIgnoreCase(waitlistStatus)) {
                        waitlistStatus = "completed";
                    } else {
                        waitlistStatus = "waiting";
                    }

                    if (labRoom != null) {
                        String lower = labRoom.toLowerCase();
                        if (lower.contains("đái tháo đường") || lower.contains("đường huyết") || lower.contains("hba1c") || lower.contains("glucose") || lower.contains("tiểu đường")) {
                            labRoom = "phòng xét nghiệm máu - đường huyết";
                        } else if (lower.contains("tổng phân tích") || lower.contains("nước tiểu") || lower.contains("microalbumin") || lower.contains("đạm niệu")) {
                            labRoom = "phòng xét nghiệm nước tiểu";
                        } else if (lower.contains("gan")) {
                            labRoom = "phòng xét nghiệm máu - chức năng gan";
                        } else if (lower.contains("thận")) {
                            labRoom = "phòng xét nghiệm máu - chức năng thận";
                        } else if (lower.contains("sinh hóa") || lower.contains("mỡ máu") || lower.contains("cholesterol") || lower.contains("triglycerid") || lower.contains("hdl") || lower.contains("ldl")) {
                            labRoom = "phòng xét nghiệm máu - mỡ máu";
                        } else if (lower.contains("huyết học") || lower.contains("tế bào") || lower.contains("máu")) {
                            labRoom = "phòng xét nghiệm máu";
                        } else {
                            labRoom = lower;
                        }
                    }

                    p.put("recordCount", String.valueOf(recordCount));
                    p.put("waitlistStatus", waitlistStatus);
                    p.put("waitingId", waitingId != null ? waitingId : "");
                    p.put("labRoom", labRoom != null ? labRoom : "");
                    
                    uniquePatientIds.add(pId);

                    boolean isCompleted = "completed".equals(waitlistStatus) || ((waitlistStatus == null || waitlistStatus.isEmpty()) && recordCount > 0);
                    if (isCompleted || recordCount > 0) {
                        completedPatientIds.add(pId);
                    }

                    if ("waiting".equals(waitlistStatus) || "testing".equals(waitlistStatus)) {
                        waitingCount++;
                        Map<String, String> wp = new HashMap<>(p);
                        wp.put("waitingId", waitingId != null ? waitingId : "");
                        wp.put("createdAt", "");
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

            // Retrieve lab doctor schedule from Lab_Schedule table
            List<Map<String, String>> registeredSchedules = new ArrayList<>();
            String sqlFetchSched = "SELECT CAST(ls.work_date AS DATE) AS work_date_clean, ls.time_slot, ls.room_id, ls.status, dl.full_name AS doctor_name, dl.account_id "
                    + "FROM Lab_Schedule ls "
                    + "LEFT JOIN Doctor_Lab dl ON ls.lab_id = dl.lab_id "
                    + "ORDER BY ls.work_date ASC, ls.time_slot ASC";
            try (PreparedStatement stmtSched = conn.prepareStatement(sqlFetchSched);
                 ResultSet rsSched = stmtSched.executeQuery()) {
                while (rsSched.next()) {
                    Map<String, String> item = new HashMap<>();
                    java.sql.Date d = rsSched.getDate("work_date_clean");
                    item.put("dateStr", d != null ? d.toString() : "");
                    item.put("slotKey", rsSched.getString("time_slot"));
                    item.put("roomId", rsSched.getString("room_id") != null ? rsSched.getString("room_id") : "Phòng xét nghiệm");
                    String dName = rsSched.getString("doctor_name");
                    item.put("doctorName", (dName != null && !dName.trim().isEmpty()) ? dName : "Bác sĩ Lab");
                    item.put("accountId", String.valueOf(rsSched.getInt("account_id")));
                    item.put("status", rsSched.getString("status") != null ? rsSched.getString("status") : "Active");
                    item.put("type", "blood");
                    registeredSchedules.add(item);
                }
            } catch (Exception ex) {
                ex.printStackTrace();
            }
            request.setAttribute("registeredSchedules", registeredSchedules);

            request.setAttribute("schedules", registeredSchedules);

            // Fetch logged-in doctor's profile info from Doctor_Lab table
            Map<String, String> doctorProfile = new HashMap<>();
            boolean isProfileComplete = true;
            String sqlDoctorProfile = "SELECT full_name, phone, email, lab_name, date_of_birth, gender, address FROM Doctor_Lab WHERE account_id = ?";
            try (PreparedStatement stmtDoc = conn.prepareStatement(sqlDoctorProfile)) {
                stmtDoc.setInt(1, currentUser.getId());
                try (ResultSet rsDoc = stmtDoc.executeQuery()) {
                    if (rsDoc.next()) {
                        String dName = rsDoc.getString("full_name");
                        String dPhone = rsDoc.getString("phone");
                        String dEmail = rsDoc.getString("email");
                        String dDob = rsDoc.getString("date_of_birth");
                        String dGender = rsDoc.getString("gender");
                        String dAddr = rsDoc.getString("address");

                        if (dDob != null && !dDob.trim().isEmpty()) {
                            dDob = dDob.trim();
                            if (dDob.length() >= 10) {
                                dDob = dDob.substring(0, 10);
                            }
                        } else {
                            dDob = "";
                        }

                        doctorProfile.put("fullName", (dName != null && !dName.trim().isEmpty()) ? dName.trim() : (currentUser.getFullName() != null ? currentUser.getFullName() : ""));
                        doctorProfile.put("phone", (dPhone != null && !dPhone.trim().isEmpty()) ? dPhone.trim() : (currentUser.getPhone() != null ? currentUser.getPhone() : ""));
                        doctorProfile.put("email", (dEmail != null && !dEmail.trim().isEmpty()) ? dEmail.trim() : (currentUser.getEmail() != null ? currentUser.getEmail() : ""));
                        doctorProfile.put("labName", "Phòng xét nghiệm");
                        doctorProfile.put("dob", !dDob.isEmpty() ? dDob : (currentUser.getDob() != null ? currentUser.getDob() : ""));
                        doctorProfile.put("gender", (dGender != null && !dGender.trim().isEmpty()) ? dGender.trim() : (currentUser.getGender() != null ? currentUser.getGender() : "Nam"));
                        doctorProfile.put("address", (dAddr != null && !dAddr.trim().isEmpty()) ? dAddr.trim() : (currentUser.getAddress() != null ? currentUser.getAddress() : ""));
                    } else {
                        String uDob = currentUser.getDob();
                        if (uDob != null && uDob.length() >= 10) uDob = uDob.substring(0, 10);
                        doctorProfile.put("fullName", currentUser.getFullName() != null ? currentUser.getFullName() : "");
                        doctorProfile.put("phone", currentUser.getPhone() != null ? currentUser.getPhone() : "");
                        doctorProfile.put("email", currentUser.getEmail() != null ? currentUser.getEmail() : "");
                        doctorProfile.put("labName", "Phòng xét nghiệm");
                        doctorProfile.put("dob", uDob != null ? uDob : "");
                        doctorProfile.put("gender", currentUser.getGender() != null ? currentUser.getGender() : "Nam");
                        doctorProfile.put("address", currentUser.getAddress() != null ? currentUser.getAddress() : "");
                    }
                }
            } catch (Exception ex) {
                ex.printStackTrace();
            }

            // Force isProfileComplete = true so modal closes and does not block doctor dashboard
            isProfileComplete = true;

            // Max allowed DOB for age >= 18
            String maxDobStr = java.time.LocalDate.now().minusYears(18).toString();
            request.setAttribute("maxDobStr", maxDobStr);

            request.setAttribute("doctorProfile", doctorProfile);
            request.setAttribute("isProfileComplete", isProfileComplete);

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

        if ("updateProfile".equals(action)) {

            String fullName = request.getParameter("fullName");
            String phone = request.getParameter("phone");
            String email = currentUser.getEmail(); // Keep existing email
            String labName = "Phòng xét nghiệm"; // Always fixed to Phòng xét nghiệm
            String dob = request.getParameter("dob");
            String gender = request.getParameter("gender");
            String address = request.getParameter("address");
            String newPassword = request.getParameter("newPassword");

            // 1. Check all required fields
            if (fullName == null || fullName.trim().isEmpty() ||
                phone == null || phone.trim().isEmpty() ||
                dob == null || dob.trim().isEmpty() ||
                gender == null || gender.trim().isEmpty() ||
                address == null || address.trim().isEmpty()) {
                session.setAttribute("errorMsg", "Vui lòng nhập đầy đủ các thông tin bắt buộc (Họ tên, SĐT, Ngày sinh, Giới tính, Địa chỉ).");
                response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard");
                return;
            }

            // 2. Validate phone format – Vietnam mobile numbers (2024 number plan)
            phone = phone.trim();
            // Accepted prefixes: 03x(Viettel), 05x(VM/Reddi/Gmobile), 07x(Mobifone),
            //                    08x(Vinaphone/Viettel/MBF), 09x(all carriers)
            String vnPhoneRegex = "^(03[2-9]|05[25689]|07[06-9]|08[1-9]|09[0-9])\\d{7}$";
            if (!phone.matches(vnPhoneRegex)) {
                session.setAttribute("errorMsg",
                    "Số điện thoại không hợp lệ! Vui lòng nhập số điện thoại Việt Nam đúng định dạng "
                    + "(10 số, bắt đầu bằng đầu số: 03x, 05x, 07x, 08x, 09x). "
                    + "Ví dụ: 0987654321 (Viettel), 0912345678 (Vinaphone).");
                response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard");
                return;
            }

            // 3. Check duplicate phone – reject if another doctor already uses this number
            try (Connection connCheck = DatabaseConnection.getConnection()) {
                String sqlCheckPhone = "SELECT account_id, full_name FROM Doctor_Lab WHERE phone = ? AND account_id <> ?";
                try (PreparedStatement stmtCheck = connCheck.prepareStatement(sqlCheckPhone)) {
                    stmtCheck.setString(1, phone);
                    stmtCheck.setInt(2, currentUser.getId());
                    try (java.sql.ResultSet rs = stmtCheck.executeQuery()) {
                        if (rs.next()) {
                            String existingName = rs.getString("full_name");
                            session.setAttribute("errorMsg",
                                "Số điện thoại " + phone + " đã được sử dụng bởi tài khoản khác"
                                + (existingName != null && !existingName.isEmpty() ? " (" + existingName + ")" : "")
                                + ". Vui lòng sử dụng số điện thoại khác.");
                            response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard");
                            return;
                        }
                    }
                }
            } catch (Exception exCheck) {
                exCheck.printStackTrace();
                session.setAttribute("errorMsg", "Lỗi kiểm tra số điện thoại: " + exCheck.getMessage());
                response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard");
                return;
            }

            // 3. Validate Date of Birth (At least 18 years old)
            try {
                java.time.LocalDate bDate = java.time.LocalDate.parse(dob.trim());
                java.time.LocalDate maxAllowedDob = java.time.LocalDate.now().minusYears(18);
                java.time.LocalDate minAllowedDob = java.time.LocalDate.now().minusYears(100);

                if (bDate.isAfter(maxAllowedDob)) {
                    session.setAttribute("errorMsg", "Ngày sinh không hợp lệ! Bác sĩ phải từ 18 tuổi trở lên.");
                    response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard");
                    return;
                }
                if (bDate.isBefore(minAllowedDob)) {
                    session.setAttribute("errorMsg", "Ngày sinh không hợp lệ! Vui lòng kiểm tra lại năm sinh.");
                    response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard");
                    return;
                }
            } catch (Exception ex) {
                session.setAttribute("errorMsg", "Định dạng ngày sinh không hợp lệ.");
                response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard");
                return;
            }

            try (Connection conn = DatabaseConnection.getConnection()) {
                // Update Doctor_Lab table
                String sqlUpdLab = "UPDATE Doctor_Lab SET full_name = ?, phone = ?, email = ?, lab_name = ?, date_of_birth = ?, gender = ?, address = ? WHERE account_id = ?";
                int rowsUpdated = 0;
                try (PreparedStatement stmtUpd = conn.prepareStatement(sqlUpdLab)) {
                    stmtUpd.setString(1, fullName.trim());
                    stmtUpd.setString(2, phone.trim());
                    stmtUpd.setString(3, email != null ? email.trim() : "");
                    stmtUpd.setString(4, labName);
                    if (dob != null && !dob.trim().isEmpty()) {
                        stmtUpd.setDate(5, java.sql.Date.valueOf(dob.trim()));
                    } else {
                        stmtUpd.setNull(5, java.sql.Types.DATE);
                    }
                    stmtUpd.setString(6, gender.trim());
                    stmtUpd.setString(7, address.trim());
                    stmtUpd.setInt(8, currentUser.getId());
                    rowsUpdated = stmtUpd.executeUpdate();
                }

                if (rowsUpdated == 0) {
                    String sqlInsLab = "INSERT INTO Doctor_Lab (full_name, phone, email, lab_name, date_of_birth, gender, address, account_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
                    try (PreparedStatement stmtIns = conn.prepareStatement(sqlInsLab)) {
                        stmtIns.setString(1, fullName.trim());
                        stmtIns.setString(2, phone.trim());
                        stmtIns.setString(3, email != null ? email.trim() : "");
                        stmtIns.setString(4, labName);
                        if (dob != null && !dob.trim().isEmpty()) {
                            stmtIns.setDate(5, java.sql.Date.valueOf(dob.trim()));
                        } else {
                            stmtIns.setNull(5, java.sql.Types.DATE);
                        }
                        stmtIns.setString(6, gender.trim());
                        stmtIns.setString(7, address.trim());
                        stmtIns.setInt(8, currentUser.getId());
                        stmtIns.executeUpdate();
                    }
                }

                // Update Account table
                String sqlUpdAcc = "UPDATE Account SET full_name = ?, email = ? WHERE account_id = ?";
                try (PreparedStatement stmtUpdAcc = conn.prepareStatement(sqlUpdAcc)) {
                    stmtUpdAcc.setString(1, fullName.trim());
                    stmtUpdAcc.setString(2, email != null ? email.trim() : "");
                    stmtUpdAcc.setInt(3, currentUser.getId());
                    stmtUpdAcc.executeUpdate();
                }

                // Update password if provided
                if (newPassword != null && !newPassword.trim().isEmpty()) {
                    String hashedPw = com.diabetes.monitoring.util.PasswordUtil.hashPassword(newPassword.trim());
                    String sqlPw = "UPDATE Account SET password_hash = ? WHERE account_id = ?";
                    try (PreparedStatement stmtPw = conn.prepareStatement(sqlPw)) {
                        stmtPw.setString(1, hashedPw);
                        stmtPw.setInt(2, currentUser.getId());
                        stmtPw.executeUpdate();
                    }
                }

                // Update current user session object
                currentUser.setFullName(fullName.trim());
                currentUser.setPhone(phone.trim());
                currentUser.setDob(dob.trim());
                currentUser.setGender(gender.trim());
                currentUser.setAddress(address.trim());
                if (email != null && !email.trim().isEmpty()) {
                    currentUser.setEmail(email.trim());
                }
                session.setAttribute("currentUser", currentUser);

                session.setAttribute("successMsg", "Cập nhật thông tin cá nhân thành công! Hồ sơ bác sĩ đã hoàn tất và kích hoạt đầy đủ.");
            } catch (Exception ex) {
                ex.printStackTrace();
                session.setAttribute("errorMsg", "Lỗi cập nhật hồ sơ: " + ex.getMessage());
            }
            response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard");
            return;
        }

        if ("registerSchedule".equals(action)) {
            String workDateStr = request.getParameter("workDate");
            String timeSlot = request.getParameter("timeSlot");
            String roomId = request.getParameter("roomId");

            if (workDateStr == null || workDateStr.trim().isEmpty()
                    || timeSlot == null || timeSlot.trim().isEmpty()
                    || roomId == null || roomId.trim().isEmpty()) {
                session.setAttribute("errorMsg", "Vui lòng nhập đầy đủ thông tin đăng ký lịch.");
                response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard#pill-register-schedule");
                return;
            }

            try {
                java.time.LocalDate selectedDate = java.time.LocalDate.parse(workDateStr.trim());
                java.time.LocalDate today = java.time.LocalDate.now();
                java.time.LocalDate currentMonday = today.with(java.time.DayOfWeek.MONDAY);
                java.time.LocalDate nextMonday = currentMonday.plusWeeks(1);

                if (selectedDate.isBefore(nextMonday)) {
                    String formattedMin = nextMonday.format(java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy"));
                    session.setAttribute("errorMsg", "Bác sĩ phải đăng ký lịch làm việc trước ít nhất 1 tuần. Hạn chót đăng ký cho tuần tới là 23:59 Chủ nhật tuần này (Ngày làm việc sớm nhất có thể đăng ký: " + formattedMin + ").");
                    response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard#pill-register-schedule");
                    return;
                }
            } catch (Exception ex) {
                session.setAttribute("errorMsg", "Định dạng ngày làm việc không hợp lệ.");
                response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard#pill-register-schedule");
                return;
            }

            try (Connection conn = DatabaseConnection.getConnection()) {
                // Find lab_id for currentUser
                int labId = 1;
                String sqlLabId = "SELECT lab_id FROM Doctor_Lab WHERE account_id = ?";
                try (PreparedStatement stmtLab = conn.prepareStatement(sqlLabId)) {
                    stmtLab.setInt(1, currentUser.getId());
                    try (ResultSet rsLab = stmtLab.executeQuery()) {
                        if (rsLab.next()) {
                            labId = rsLab.getInt("lab_id");
                        }
                    }
                }

                // Check 1: If ANY doctor has already registered this room for this date & time_slot
                String sqlCheckRoom = "SELECT ls.lab_sched_id, dl.full_name AS doctor_name " +
                        "FROM Lab_Schedule ls " +
                        "LEFT JOIN Doctor_Lab dl ON ls.lab_id = dl.lab_id " +
                        "WHERE ls.work_date = ? AND ls.time_slot = ? AND LOWER(ls.room_id) = LOWER(?) AND (ls.status = 'Active' OR ls.status = 'Registered')";
                try (PreparedStatement stmtCheck = conn.prepareStatement(sqlCheckRoom)) {
                    stmtCheck.setDate(1, java.sql.Date.valueOf(workDateStr.trim()));
                    stmtCheck.setString(2, timeSlot.trim());
                    stmtCheck.setString(3, roomId.trim());
                    try (ResultSet rsCheck = stmtCheck.executeQuery()) {
                        if (rsCheck.next()) {
                            String registeredDoctor = rsCheck.getString("doctor_name");
                            if (registeredDoctor == null || registeredDoctor.trim().isEmpty()) {
                                registeredDoctor = "bác sĩ khác";
                            }
                            java.time.LocalDate d = java.time.LocalDate.parse(workDateStr.trim());
                            String formattedDate = d.format(java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy"));
                            session.setAttribute("errorMsg", "Ca làm việc " + timeSlot.trim() + " tại '" + roomId.trim() + "' ngày " + formattedDate + " đã được " + registeredDoctor + " đăng ký! Không thể đăng ký thêm.");
                            response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard#pill-register-schedule");
                            return;
                        }
                    }
                }

                // Check 2: If THIS doctor already registered ANY room for this date & time_slot
                String sqlCheckDoc = "SELECT lab_sched_id FROM Lab_Schedule WHERE lab_id = ? AND work_date = ? AND time_slot = ? AND (status = 'Active' OR status = 'Registered')";
                try (PreparedStatement stmtCheckDoc = conn.prepareStatement(sqlCheckDoc)) {
                    stmtCheckDoc.setInt(1, labId);
                    stmtCheckDoc.setDate(2, java.sql.Date.valueOf(workDateStr.trim()));
                    stmtCheckDoc.setString(3, timeSlot.trim());
                    try (ResultSet rsCheckDoc = stmtCheckDoc.executeQuery()) {
                        if (rsCheckDoc.next()) {
                            java.time.LocalDate d = java.time.LocalDate.parse(workDateStr.trim());
                            String formattedDate = d.format(java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy"));
                            session.setAttribute("errorMsg", "Bạn đã đăng ký " + timeSlot.trim() + " vào ngày " + formattedDate + " rồi!");
                            response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard#pill-register-schedule");
                            return;
                        }
                    }
                }

                String sqlInsert = "INSERT INTO Lab_Schedule (lab_id, work_date, time_slot, room_id, status) VALUES (?, ?, ?, ?, 'Active')";
                try (PreparedStatement stmtInsert = conn.prepareStatement(sqlInsert)) {
                    stmtInsert.setInt(1, labId);
                    stmtInsert.setDate(2, java.sql.Date.valueOf(workDateStr.trim()));
                    stmtInsert.setString(3, timeSlot.trim());
                    stmtInsert.setString(4, roomId.trim());
                    stmtInsert.executeUpdate();
                }
                
                session.setAttribute("successMsg", "Đăng ký ca làm việc thành công!");
            } catch (Exception e) {
                e.printStackTrace();
                session.setAttribute("errorMsg", "Lỗi khi đăng ký lịch: " + e.getMessage());
            }
            response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard#pill-register-schedule");
            return;
        }

        if ("invite".equals(action)) {
            String waitingIdStr = request.getParameter("waitingId");
            if (waitingIdStr == null || waitingIdStr.trim().isEmpty()) {
                session.setAttribute("errorMsg", "Mã hàng chờ không hợp lệ.");
                response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard");
                return;
            }
            try (Connection conn = DatabaseConnection.getConnection()) {
                String cleanWaitingId = waitingIdStr.trim();
                if (cleanWaitingId.toUpperCase().startsWith("LAB-")) {
                    cleanWaitingId = cleanWaitingId.substring(4);
                }
                
                if (cleanWaitingId.matches("\\d+")) {
                    int waitingId = Integer.parseInt(cleanWaitingId);
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
                } else {
                    String sqlInvite = "UPDATE Lab_Order SET status = 'Processing' WHERE order_id = ?";
                    try (PreparedStatement stmt = conn.prepareStatement(sqlInvite)) {
                        stmt.setString(1, cleanWaitingId);
                        stmt.executeUpdate();
                    }
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
                
                // Map newRoom name to actual Medical_Service from database
                int serviceId = 10;
                BigDecimal price = new BigDecimal("150000.00");
                String roomLower = newRoom.toLowerCase();
                
                String sqlFindService = "SELECT TOP 1 service_id, price FROM Medical_Service WHERE status = 'Active' AND service_type = 'Lab_Test' AND " +
                                        "(LOWER(service_name) LIKE ? OR ? LIKE '%' + LOWER(service_name) + '%') ORDER BY service_id ASC";
                try (PreparedStatement stmtSvc = conn.prepareStatement(sqlFindService)) {
                    String keyword = "%";
                    if (roomLower.contains("nước tiểu") || roomLower.contains("tổng phân tích")) {
                        keyword = "%nước tiểu%";
                    } else if (roomLower.contains("mỡ máu") || roomLower.contains("sinh hóa")) {
                        keyword = "%mỡ máu%";
                    } else if (roomLower.contains("gan")) {
                        keyword = "%gan%";
                    } else if (roomLower.contains("thận")) {
                        keyword = "%thận%";
                    } else if (roomLower.contains("đường") || roomLower.contains("huyết")) {
                        keyword = "%đường%";
                    }
                    stmtSvc.setString(1, keyword);
                    stmtSvc.setString(2, roomLower);
                    try (ResultSet rsSvc = stmtSvc.executeQuery()) {
                        if (rsSvc.next()) {
                            serviceId = rsSvc.getInt("service_id");
                            price = rsSvc.getBigDecimal("price");
                        }
                    }
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

                // Check if they already have an active entry of this service in waiting/processing/unpaid
                String sqlCheckRoom = "SELECT COUNT(*) FROM Invoice_Detail id JOIN Invoice i ON i.invoice_id = id.invoice_id WHERE i.patient_id = ? AND id.service_id = ? AND id.lab_status IN ('Requested', 'Processing', 'Waiting_Payment')";
                try (PreparedStatement stmtCheck = conn.prepareStatement(sqlCheckRoom)) {
                    stmtCheck.setInt(1, patientId);
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
                String roomId = "LAB01";
                if (serviceId == 2) {
                    roomId = "LAB02";
                }

                // Create a NEW Invoice for this re-test
                int invoiceId = -1;
                String sqlInsertInvoice = "INSERT INTO Invoice (patient_id, receptionist_id, final_amount, payment_method, status, created_at) " +
                                          "VALUES (?, NULL, ?, NULL, 'Pending', GETDATE())";
                try (PreparedStatement stmtInv = conn.prepareStatement(sqlInsertInvoice, PreparedStatement.RETURN_GENERATED_KEYS)) {
                    stmtInv.setInt(1, patientId);
                    stmtInv.setBigDecimal(2, price);
                    stmtInv.executeUpdate();
                    try (ResultSet generatedKeys = stmtInv.getGeneratedKeys()) {
                        if (generatedKeys.next()) {
                            invoiceId = generatedKeys.getInt(1);
                        }
                    }
                }

                if (invoiceId == -1) {
                    session.setAttribute("errorMsg", "Không thể tạo hóa đơn mới cho chỉ định.");
                    response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard");
                    return;
                }

                // Insert into Invoice_Detail
                int invoiceDetailId = -1;
                String sqlInsertWaiting = "INSERT INTO Invoice_Detail (invoice_id, service_id, appointment_id, quantity, price, doctor_id, lab_status, requested_at) " +
                                          "VALUES (?, ?, ?, 1, ?, 5, 'Requested', GETDATE())";
                try (PreparedStatement stmtWait = conn.prepareStatement(sqlInsertWaiting, PreparedStatement.RETURN_GENERATED_KEYS)) {
                    stmtWait.setInt(1, invoiceId);
                    stmtWait.setInt(2, serviceId);
                    stmtWait.setInt(3, appointmentId);
                    stmtWait.setBigDecimal(4, price);
                    stmtWait.executeUpdate();
                    try (ResultSet generatedKeys = stmtWait.getGeneratedKeys()) {
                        if (generatedKeys.next()) {
                            invoiceDetailId = generatedKeys.getInt(1);
                        }
                    }
                }

                if (invoiceDetailId == -1) {
                    session.setAttribute("errorMsg", "Không thể tạo chi tiết hóa đơn.");
                    response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard");
                    return;
                }

                String orderId = "LAB-" + invoiceDetailId;

                // Insert into Lab_Order
                int currentLabId = 1;
                String sqlGetLabId = "SELECT lab_id FROM Doctor_Lab WHERE account_id = ?";
                try (PreparedStatement stmtLabId = conn.prepareStatement(sqlGetLabId)) {
                    stmtLabId.setInt(1, currentUser.getId());
                    try (ResultSet rsLabId = stmtLabId.executeQuery()) {
                        if (rsLabId.next()) {
                            currentLabId = rsLabId.getInt("lab_id");
                        }
                    }
                }
                String sqlInsertLab = "INSERT INTO Lab_Order (order_id, appointment_id, patient_id, room_id, service_id, lab_id, status, created_at) " +
                                      "VALUES (?, ?, ?, ?, ?, ?, 'Requested', GETDATE())";
                try (PreparedStatement stmtLab = conn.prepareStatement(sqlInsertLab)) {
                    stmtLab.setString(1, orderId);
                    stmtLab.setInt(2, appointmentId);
                    stmtLab.setInt(3, patientId);
                    stmtLab.setString(4, roomId);
                    stmtLab.setInt(5, serviceId);
                    stmtLab.setInt(6, currentLabId);
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
                 String cleanWaitingId = waitingIdStr.trim();
                 if (cleanWaitingId.toUpperCase().startsWith("LAB-")) {
                     cleanWaitingId = cleanWaitingId.substring(4);
                 }
                 if (cleanWaitingId.matches("\\d+")) {
                     int waitingId = Integer.parseInt(cleanWaitingId);
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
             }

             if ("true".equals(isRandomStr)) {
                 java.util.Map<String, BigDecimal> metrics;
                 String labRoomLow = currentLabRoom != null ? currentLabRoom.toLowerCase() : "";
                 if (currentLabRoom != null && (
                         labRoomLow.contains("mỡ máu") || labRoomLow.contains("cholesterol")
                         || labRoomLow.contains("triglycerid") || labRoomLow.contains("hdl") || labRoomLow.contains("ldl"))) {
                     metrics = com.diabetes.monitoring.util.RandomTestGenerator.generateLipidsMetrics();
                 } else if (currentLabRoom != null && (
                         labRoomLow.contains("nước tiểu") || labRoomLow.contains("microalbumin")
                         || labRoomLow.contains("đạm niệu"))) {
                     metrics = com.diabetes.monitoring.util.RandomTestGenerator.generateUrineMetrics();
                 } else if (currentLabRoom != null && (
                         labRoomLow.contains("glucose") || labRoomLow.contains("tiểu đường")
                         || labRoomLow.contains("đường huyết") || labRoomLow.contains("hba1c"))) {
                     metrics = com.diabetes.monitoring.util.RandomTestGenerator.generateBloodSugarMetrics();
                 } else if (currentLabRoom != null && (labRoomLow.contains("máu") || labRoomLow.contains("huyết học") || labRoomLow.contains("tế bào"))) {
                     metrics = com.diabetes.monitoring.util.RandomTestGenerator.generateRandomMetrics();
                 } else if (currentLabRoom != null && labRoomLow.contains("gan")) {
                     metrics = com.diabetes.monitoring.util.RandomTestGenerator.generateLiverMetrics();
                 } else if (currentLabRoom != null && labRoomLow.contains("thận")) {
                     metrics = com.diabetes.monitoring.util.RandomTestGenerator.generateKidneyMetrics();
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
                    String cleanWaitingId = waitingIdStr.trim();
                    if (cleanWaitingId.toUpperCase().startsWith("LAB-")) {
                        cleanWaitingId = cleanWaitingId.substring(4);
                    }
                    if (cleanWaitingId.matches("\\d+")) {
                        int waitingId = Integer.parseInt(cleanWaitingId);
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
                    // Kiểm tra keyword khớp với tên service thực trong Medical_Service
                    String labRoomLower = currentLabRoom != null ? currentLabRoom.toLowerCase() : "";
                    boolean isValidLabRoom = labRoomLower.contains("máu")          // ID2, ID5, Phòng Máu
                            || labRoomLower.contains("đường huyết")                // ID2
                            || labRoomLower.contains("hba1c")                      // ID2
                            || labRoomLower.contains("glucose")                    // ID4
                            || labRoomLower.contains("tiểu đường")                 // ID4
                            || labRoomLower.contains("nước tiểu")                  // ID3
                            || labRoomLower.contains("microalbumin")               // ID3
                            || labRoomLower.contains("đạm niệu")                   // ID3
                            || labRoomLower.contains("mỡ máu")                     // ID5
                            || labRoomLower.contains("cholesterol")                // ID5
                            || labRoomLower.contains("triglycerid")                // ID5
                            || labRoomLower.contains("gan")                        // Phòng Gan
                            || labRoomLower.contains("thận");                      // Phòng Thận
                    if (currentLabRoom == null || !isValidLabRoom) {
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
                    // Ánh xạ tên service/phòng → nhãn otherInfo lưu vào Healthy_Record
                    // Kiểm tra specific trước, generic sau để tránh match nhầm
                    if (lower.contains("mỡ máu") || lower.contains("cholesterol")
                            || lower.contains("triglycerid") || lower.contains("hdl") || lower.contains("ldl")) {
                        // ID5: Xét nghiệm bộ mỡ máu
                        otherInfo = "phòng xét nghiệm máu - mỡ máu";
                    } else if (lower.contains("nước tiểu") || lower.contains("microalbumin") || lower.contains("đạm niệu")) {
                        // ID3: Xét nghiệm nước tiểu
                        otherInfo = "phòng xét nghiệm nước tiểu";
                    } else if (lower.contains("glucose") || lower.contains("tiểu đường")
                            || lower.contains("đường huyết") || lower.contains("hba1c")) {
                        // ID4: Nghiệm pháp dung nạp Glucose / ID2: Đường huyết & HbA1c
                        otherInfo = "phòng xét nghiệm máu - đường huyết";
                    } else if (lower.contains("gan")) {
                        // Phòng Xét nghiệm Chức năng Gan
                        otherInfo = "phòng xét nghiệm máu - chức năng gan";
                    } else if (lower.contains("thận")) {
                        // Phòng Xét nghiệm Chức năng Thận
                        otherInfo = "phòng xét nghiệm máu - chức năng thận";
                    } else if (lower.contains("máu")) {
                        // ID2 / Phòng Xét nghiệm Máu chung
                        otherInfo = "phòng xét nghiệm máu - đường huyết";
                    } else {
                        otherInfo = currentLabRoom;
                    }
                }

                // 2. Fetch invoice_id and check if Healthy_Record already exists for this invoice
                int healthRecordId = -1;
                int invoiceId = -1;
                int invoiceDetailId = -1;
                int appointmentId = 0;

                if (waitingIdStr != null && !waitingIdStr.trim().isEmpty()) {
                    // Try to resolve appointment_id from Lab_Order
                    String sqlGetAppt = "SELECT appointment_id FROM Lab_Order WHERE order_id = ?";
                    try (PreparedStatement ps = conn.prepareStatement(sqlGetAppt)) {
                        ps.setString(1, waitingIdStr.trim());
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) {
                                appointmentId = rs.getInt("appointment_id");
                            }
                        }
                    }

                    String cleanWaitingId = waitingIdStr.trim();
                    if (cleanWaitingId.startsWith("LAB-")) {
                        cleanWaitingId = cleanWaitingId.substring(4);
                    }
                    if (cleanWaitingId.matches("\\d+")) {
                        invoiceDetailId = Integer.parseInt(cleanWaitingId);
                        String sqlGetInvoice = "SELECT invoice_id FROM Invoice_Detail WHERE invoice_detail_id = ?";
                        try (PreparedStatement ps = conn.prepareStatement(sqlGetInvoice)) {
                            ps.setInt(1, invoiceDetailId);
                            try (ResultSet rs = ps.executeQuery()) {
                                if (rs.next()) {
                                    invoiceId = rs.getInt("invoice_id");
                                }
                            }
                        }
                    }
                }

                // Step A: If we have a valid invoiceDetailId, check if Invoice_Detail already has health_record_id
                if (invoiceDetailId > 0) {
                    String sqlCheckDetail = "SELECT health_record_id FROM Invoice_Detail WHERE invoice_detail_id = ?";
                    try (PreparedStatement ps = conn.prepareStatement(sqlCheckDetail)) {
                        ps.setInt(1, invoiceDetailId);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) {
                                int hrId = rs.getInt("health_record_id");
                                if (!rs.wasNull() && hrId > 0) {
                                    healthRecordId = hrId;
                                }
                            }
                        }
                    }
                }

                // Step B: If not found, look up via Medical_record using appointmentId
                if (healthRecordId <= 0 && appointmentId > 0) {
                    String sqlGetHR = "SELECT health_record_id FROM Medical_record WHERE appointment_id = ?";
                    try (PreparedStatement ps = conn.prepareStatement(sqlGetHR)) {
                        ps.setInt(1, appointmentId);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) {
                                int hrId = rs.getInt("health_record_id");
                                if (!rs.wasNull() && hrId > 0) {
                                    healthRecordId = hrId;
                                }
                            }
                        }
                    }
                }

                // Step C: If not found, check Healthy_Record by invoiceId
                if (healthRecordId <= 0 && invoiceId > 0) {
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

                // Step D: Fallback to the latest active Healthy_Record for this patient
                if (healthRecordId <= 0) {
                    String sqlFindLatest = "SELECT TOP 1 health_record_id FROM Healthy_Record WHERE patient_id = ? AND status <> 'Completed' ORDER BY created_at DESC";
                    try (PreparedStatement ps = conn.prepareStatement(sqlFindLatest)) {
                        ps.setInt(1, patientId);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) {
                                healthRecordId = rs.getInt("health_record_id");
                            }
                        }
                    }
                }

                // Fetch the examining doctor's ID associated with this lab order
                int doctorId = 0;
                if (waitingIdStr != null && !waitingIdStr.trim().isEmpty()) {
                    String sqlGetDoctorId = "SELECT ds.doctor_id " +
                            "FROM Lab_Order lo " +
                            "JOIN Appointment a ON lo.appointment_id = a.appointment_id " +
                            "JOIN Doctor_Schedule ds ON a.schedule_id = ds.schedule_id " +
                            "WHERE lo.order_id = ?";
                    try (PreparedStatement ps = conn.prepareStatement(sqlGetDoctorId)) {
                        ps.setString(1, waitingIdStr.trim());
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) {
                                doctorId = rs.getInt("doctor_id");
                            }
                        }
                    }
                }
                if (doctorId == 0) {
                    String sqlGetLatestDoctor = "SELECT TOP 1 ds.doctor_id " +
                            "FROM Appointment a " +
                            "JOIN Doctor_Schedule ds ON a.schedule_id = ds.schedule_id " +
                            "WHERE a.patient_id = ? AND a.status <> 'Cancelled' " +
                            "ORDER BY a.created_at DESC";
                    try (PreparedStatement ps = conn.prepareStatement(sqlGetLatestDoctor)) {
                        ps.setInt(1, patientId);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) {
                                doctorId = rs.getInt("doctor_id");
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
                            "status = 'Accepted', " +
                            "doctor_id = COALESCE(doctor_id, ?), " +
                            "invoice_id = COALESCE(invoice_id, ?) " +
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
                        if (doctorId > 0) {
                            stmt.setInt(15, doctorId);
                        } else {
                            stmt.setNull(15, java.sql.Types.INTEGER);
                        }
                        if (invoiceId > 0) {
                            stmt.setInt(16, invoiceId);
                        } else {
                            stmt.setNull(16, java.sql.Types.INTEGER);
                        }
                        stmt.setInt(17, healthRecordId);
                        stmt.executeUpdate();
                    }
                } else {
                    // Insert a new Healthy_Record
                    String sqlInsert = "INSERT INTO Healthy_Record (urea, cr, hba1c, chol, tg, hdl, ldl, vldl, bmi, patient_id, weight, height, other_information, status, created_at, invoice_id, doctor_id) " +
                            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Accepted', GETDATE(), ?, ?)";
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
                        if (doctorId > 0) {
                            stmt.setInt(15, doctorId);
                        } else {
                            stmt.setNull(15, java.sql.Types.INTEGER);
                        }
                        stmt.executeUpdate();
                        try (ResultSet generatedKeys = stmt.getGeneratedKeys()) {
                            if (generatedKeys.next()) {
                                healthRecordId = generatedKeys.getInt(1);
                            }
                        }
                    }
                }

                // Step E: Ensure new/existing Healthy_Record is linked back to Medical_record
                if (appointmentId > 0 && healthRecordId > 0) {
                    String sqlLinkRecord = "UPDATE Medical_record SET health_record_id = ? WHERE appointment_id = ? AND health_record_id IS NULL";
                    try (PreparedStatement stmtLink = conn.prepareStatement(sqlLinkRecord)) {
                        stmtLink.setInt(1, healthRecordId);
                        stmtLink.setInt(2, appointmentId);
                        stmtLink.executeUpdate();
                    }
                }

                // 2.5 Update Invoice_Detail if this was ordered via an invoice
                if (waitingIdStr != null && !waitingIdStr.trim().isEmpty()) {
                    String cleanWaitingId = waitingIdStr.trim();
                    if (cleanWaitingId.startsWith("LAB-")) {
                        cleanWaitingId = cleanWaitingId.substring(4);
                    }
                    if (cleanWaitingId.matches("\\d+")) {
                        int invoiceDetailId_local = Integer.parseInt(cleanWaitingId);
                        String sqlUpdateInvoiceDetail = "UPDATE Invoice_Detail SET " +
                                "lab_status = 'Completed', " +
                                "completed_at = GETDATE(), " +
                                "lab_result = ?, " +
                                "health_record_id = ? " +
                                "WHERE invoice_detail_id = ?";
                        try (PreparedStatement stmtDetail = conn.prepareStatement(sqlUpdateInvoiceDetail)) {
                            stmtDetail.setString(1, "Hoàn thành xét nghiệm");
                            stmtDetail.setInt(2, healthRecordId);
                            stmtDetail.setInt(3, invoiceDetailId_local);
                            stmtDetail.executeUpdate();
                        }
                    }
                }

                // 3. Update waiting status if needed
                if (waitingIdStr != null && !waitingIdStr.trim().isEmpty()) {
                    String cleanWaitingId = waitingIdStr.trim();
                    if (cleanWaitingId.toUpperCase().startsWith("LAB-")) {
                        cleanWaitingId = cleanWaitingId.substring(4);
                    }
                    if (cleanWaitingId.matches("\\d+")) {
                        int waitingId = Integer.parseInt(cleanWaitingId);
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
                    } else {
                        String sqlUpdateLabOrder = "UPDATE Lab_Order SET status = 'Completed' WHERE order_id = ?";
                        try (PreparedStatement stmtLab = conn.prepareStatement(sqlUpdateLabOrder)) {
                            stmtLab.setString(1, cleanWaitingId);
                            stmtLab.executeUpdate();
                        }
                    }
                }

                conn.commit(); // Commit transaction
                session.setAttribute("successMsg", "Nhập kết quả xét nghiệm thành công!");
            } catch (SQLException e) {
                e.printStackTrace();
                session.setAttribute("errorMsg", "Lỗi cơ sở dữ liệu khi lưu kết quả: " + e.getMessage());
            }

        } catch (NumberFormatException e) {
            e.printStackTrace();
            session.setAttribute("errorMsg", "Lỗi định dạng dữ liệu số: " + e.getMessage());
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
            return null;
        }
        try {
            return new BigDecimal(val.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private BigDecimal calculateBMI(BigDecimal weight, BigDecimal height) {
        if (weight == null || height == null || weight.compareTo(BigDecimal.ZERO) <= 0 || height.compareTo(BigDecimal.ZERO) <= 0) {
            return null;
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
