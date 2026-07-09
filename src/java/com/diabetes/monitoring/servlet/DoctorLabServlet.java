package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.dao.LaboratoryDAO;
import com.diabetes.monitoring.model.LaboratoryRequest;
import com.diabetes.monitoring.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

public class DoctorLabServlet extends HttpServlet {
    private final LaboratoryDAO laboratoryDAO = new LaboratoryDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User currentUser = requireLaboratoryUser(request, response);
        if (currentUser == null) {
            return;
        }

        String status = request.getParameter("status");
        if (status == null || status.isBlank()) {
            status = "All";
        }

        HttpSession session = request.getSession(false);
        if (session != null) {
            request.setAttribute("successMsg", session.getAttribute("successMsg"));
            request.setAttribute("errorMsg", session.getAttribute("errorMsg"));
            session.removeAttribute("successMsg");
            session.removeAttribute("errorMsg");
        }

        List<LaboratoryRequest> requests = laboratoryDAO.getRequests(status);
        request.setAttribute("requests", requests);
        request.setAttribute("selectedStatus", status);
        request.setAttribute("requestedCount", countStatus(requests, "Requested"));
        request.setAttribute("processingCount", countStatus(requests, "Processing"));
        request.setAttribute("completedCount", countStatus(requests, "Completed"));
        request.getRequestDispatcher("/WEB-INF/views/doctor-lab/dashboard.jsp")
                .forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User currentUser = requireLaboratoryUser(request, response);
        if (currentUser == null) {
            return;
        }

        request.setCharacterEncoding("UTF-8");
        HttpSession session = request.getSession();
        String action = request.getParameter("action");
        int requestId = parseInt(request.getParameter("laboratoryRequestId"));

        try {
            if (requestId <= 0) {
                throw new SQLException("Chỉ định xét nghiệm không hợp lệ.");
            }

            if ("start".equals(action)) {
                if (laboratoryDAO.startProcessing(requestId)) {
                    session.setAttribute("successMsg", "Đã nhận xử lý chỉ định xét nghiệm.");
                } else {
                    session.setAttribute("errorMsg", "Không thể nhận xử lý chỉ định này.");
                }
            } else if ("complete".equals(action)) {
                LaboratoryRequest result = buildResult(request, requestId);
                laboratoryDAO.startProcessing(requestId);
                laboratoryDAO.completeRequest(result);
                session.setAttribute("successMsg", "Đã lưu kết quả xét nghiệm.");
            } else {
                session.setAttribute("errorMsg", "Thao tác không hợp lệ.");
            }
        } catch (SQLException e) {
            e.printStackTrace();
            session.setAttribute("errorMsg", e.getMessage());
        }

        response.sendRedirect(request.getContextPath()
                + "/doctor-lab/dashboard?status="
                + encodeStatus(request.getParameter("status")));
    }

    private User requireLaboratoryUser(HttpServletRequest request,
            HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        User currentUser = session == null ? null
                : (User) session.getAttribute("currentUser");

        if (currentUser == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return null;
        }

        if (!isLaboratoryRole(currentUser.getRole())) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN,
                    "Bạn không có quyền truy cập khu vực phòng xét nghiệm.");
            return null;
        }
        return currentUser;
    }

    private boolean isLaboratoryRole(String role) {
        return "doctor_lab".equalsIgnoreCase(role)
                || "Laboratory".equalsIgnoreCase(role);
    }

    private LaboratoryRequest buildResult(HttpServletRequest request, int requestId) {
        LaboratoryRequest result = new LaboratoryRequest();
        result.setLaboratoryRequestId(requestId);
        result.setUrea(parseDouble(request.getParameter("urea")));
        result.setCr(parseDouble(request.getParameter("cr")));
        result.setHba1c(parseDouble(request.getParameter("hba1c")));
        result.setChol(parseDouble(request.getParameter("chol")));
        result.setTg(parseDouble(request.getParameter("tg")));
        result.setHdl(parseDouble(request.getParameter("hdl")));
        result.setIdl(parseDouble(request.getParameter("ldl")));
        result.setVldl(parseDouble(request.getParameter("vldl")));
        result.setWeight(parseDouble(request.getParameter("weight")));
        result.setHeight(parseDouble(request.getParameter("height")));
        result.setBmi(parseDouble(request.getParameter("bmi")));
        result.setResult(request.getParameter("result"));
        return result;
    }

    private int countStatus(List<LaboratoryRequest> requests, String status) {
        int count = 0;
        for (LaboratoryRequest request : requests) {
            if (status.equalsIgnoreCase(request.getStatus())) {
                count++;
            }
        }
        return count;
    }

    private int parseInt(String value) {
        try {
            return Integer.parseInt(value == null ? "" : value.trim());
        } catch (NumberFormatException e) {
            return -1;
        }
    }

    private Double parseDouble(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        try {
            return Double.valueOf(value.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private String encodeStatus(String status) {
        if (status == null || status.isBlank()) {
            return "All";
        }
        return status.replaceAll("[^A-Za-z_]", "");
    }
}
