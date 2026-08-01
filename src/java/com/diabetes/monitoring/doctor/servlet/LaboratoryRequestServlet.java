package com.diabetes.monitoring.doctor.servlet;

import com.diabetes.monitoring.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

public class LaboratoryRequestServlet extends DoctorServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        User currentUser = requireDoctor(request, response);
        if (currentUser == null) {
            return;
        }

        HttpSession session = request.getSession();
        try {
            int recordId = getRecordId(request);
            String[] serviceValues = request.getParameterValues("service_id");
            if (serviceValues == null || serviceValues.length == 0) {
                throw new java.sql.SQLException(
                        "Vui lòng chọn ít nhất một loại xét nghiệm");
            }
            int[] serviceIds = new int[serviceValues.length];
            for (int i = 0; i < serviceValues.length; i++) {
                serviceIds[i] = Integer.parseInt(serviceValues[i]);
            }
            String requestNote = request.getParameter("request_note");
            String labIdVal = request.getParameter("lab_id");
            if (labIdVal == null || labIdVal.trim().isEmpty()) {
                throw new java.sql.SQLException("Vui l\u00f2ng ch\u1ecdn b\u00e1c s\u0129 ph\u00f2ng x\u00e9t nghi\u1ec7m");
            }
            int labId = Integer.parseInt(labIdVal);
            int doctorId = getDoctorId(currentUser);

            dao.createLaboratoryRequest(
                    recordId, doctorId, serviceIds, requestNote, labId);
            session.setAttribute("doctorMessage",
                    "\u0110\u00e3 t\u1ea1o h\u00f3a \u0111\u01a1n cho " + serviceIds.length
                    + " lo\u1ea1i x\u00e9t nghi\u1ec7m. Y\u00eau c\u1ea7u s\u1ebd \u0111\u01b0\u1ee3c g\u1eedi \u0111\u1ebfn ph\u00f2ng x\u00e9t nghi\u1ec7m "
                    + "sau khi l\u1ec5 t\u00e2n x\u00e1c nh\u1eadn thanh to\u00e1n.");
            response.sendRedirect(request.getContextPath()
                    + "/doctor/laboratory-requests");
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
        } catch (java.sql.SQLException e) {
            e.printStackTrace();
            session.setAttribute("doctorMessage", "Lỗi CSDL: " + e.getMessage());
            int recordId = -1;
            try {
                recordId = Integer.parseInt(request.getParameter("record_id"));
            } catch (Exception ignored) {}
            if (recordId > 0) {
                response.sendRedirect(request.getContextPath()
                        + "/doctor/records/general-detail?record_id=" + recordId);
            } else {
                response.sendRedirect(request.getContextPath()
                        + "/doctor/general-examinations");
            }
        } catch (Exception e) {
            e.printStackTrace();
            session.setAttribute("doctorMessage", "Lỗi hệ thống: " + e.getMessage());
            int recordId = -1;
            try {
                recordId = Integer.parseInt(request.getParameter("record_id"));
            } catch (Exception ignored) {}
            if (recordId > 0) {
                response.sendRedirect(request.getContextPath()
                        + "/doctor/records/general-detail?record_id=" + recordId);
            } else {
                response.sendRedirect(request.getContextPath()
                        + "/doctor/general-examinations");
            }
        }
    }
}
