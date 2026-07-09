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
            int doctorId = getDoctorId(currentUser);

            dao.createLaboratoryRequest(
                    recordId, doctorId, serviceIds, requestNote);
            session.setAttribute("doctorMessage",
                    "Đã tạo hóa đơn cho " + serviceIds.length
                    + " loại xét nghiệm. Yêu cầu sẽ được gửi đến phòng xét nghiệm "
                    + "sau khi lễ tân xác nhận thanh toán.");
            response.sendRedirect(request.getContextPath()
                    + "/doctor/laboratory-requests");
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
        } catch (java.sql.SQLException e) {
            session.setAttribute("doctorMessage", e.getMessage());
            response.sendRedirect(request.getContextPath()
                    + "/doctor/general-examinations");
        } catch (Exception e) {
            throw new ServletException("Khong the tao yeu cau xet nghiem", e);
        }
    }
}
