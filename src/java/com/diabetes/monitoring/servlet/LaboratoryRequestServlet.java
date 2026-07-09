package com.diabetes.monitoring.servlet;

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
        int recordId = -1;
        try {
            recordId = getRecordId(request);
            String[] serviceValues = request.getParameterValues("service_id");
            if (serviceValues == null || serviceValues.length == 0) {
                throw new java.sql.SQLException(
                        "Vui lòng chọn ít nhất một loại xét nghiệm.");
            }

            int[] serviceIds = new int[serviceValues.length];
            for (int i = 0; i < serviceValues.length; i++) {
                serviceIds[i] = Integer.parseInt(serviceValues[i]);
            }

            int doctorId = getDoctorId(currentUser);
            dao.createLaboratoryRequest(
                    recordId, doctorId, serviceIds,
                    request.getParameter("request_note"));

            session.setAttribute("doctorMessage",
                    "Đã tạo hóa đơn cho " + serviceIds.length
                    + " loại xét nghiệm. Sau khi lễ tân xác nhận thanh toán, "
                    + "yêu cầu sẽ chuyển sang phòng xét nghiệm.");
            response.sendRedirect(request.getContextPath()
                    + "/DetailServlet?record_id=" + recordId + "#laboratoryOrder");
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
        } catch (java.sql.SQLException e) {
            session.setAttribute("doctorMessage", e.getMessage());
            if (recordId > 0) {
                response.sendRedirect(request.getContextPath()
                        + "/DetailServlet?record_id=" + recordId + "#laboratoryOrder");
            } else {
                response.sendRedirect(request.getContextPath() + "/DashboardServlet");
            }
        } catch (Exception e) {
            throw new ServletException("Không thể tạo yêu cầu xét nghiệm", e);
        }
    }
}
