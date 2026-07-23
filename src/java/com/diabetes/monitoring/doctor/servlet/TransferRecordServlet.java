package com.diabetes.monitoring.doctor.servlet;

import com.diabetes.monitoring.doctor.dao.HealthRecordDAO;
import com.diabetes.monitoring.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

public class TransferRecordServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);
        if (session == null || !(session.getAttribute("currentUser") instanceof User)) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        User currentUser = (User) session.getAttribute("currentUser");
        if (!"doctor".equalsIgnoreCase(currentUser.getRole())) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        try {
            int recordId = Integer.parseInt(request.getParameter("record_id"));
            int toDoctorId = Integer.parseInt(request.getParameter("to_doctor_id"));
            String reason = request.getParameter("reason");

            HealthRecordDAO dao = new HealthRecordDAO();
            int fromDoctorId = dao.getOrCreateDoctorIdByAccountId(currentUser.getId());

            if (fromDoctorId == toDoctorId) {
                request.getSession().setAttribute("doctorMessage",
                        "Khong the chuyen ho so cho chinh minh.");
            } else {
                dao.transferRecord(recordId, fromDoctorId, toDoctorId, reason);
                request.getSession().setAttribute("doctorMessage",
                        "Da chuyen ho so #" + recordId + " thanh cong.");
            }
        } catch (Exception e) {
            request.getSession().setAttribute("doctorMessage", "Loi chuyen ho so: " + e.getMessage());
        }

        response.sendRedirect(request.getContextPath() + "/doctor/dashboard");
    }
}
