package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

// Servlet xử lý việc hiển thị các trang giao diện (JSP) cho phân hệ Lễ tân
public class ReceptionistPageServlet extends HttpServlet {

    private static final String VIEW_ROOT = "/WEB-INF/views/receptionist/";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        User currentUser = session == null ? null : (User) session.getAttribute("currentUser");

        // 1. Kiểm tra đăng nhập: Nếu chưa đăng nhập, chuyển hướng về trang login
        if (currentUser == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        // 2. Kiểm tra phân quyền: Chỉ cho phép người dùng có vai trò là "Receptionist" (Lễ tân) truy cập
        if (!"Receptionist".equalsIgnoreCase(currentUser.getRole())) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN); // Trả về lỗi 403 Forbidden nếu không đủ quyền
            return;
        }

        // 3. Phân tích đường dẫn servletPath để tìm file JSP tương ứng
        String view = resolveView(request.getServletPath());
        if (view == null) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND); // Trả về lỗi 404 nếu đường dẫn không khớp trang nào
            return;
        }

        // 4. Chuyển tiếp yêu cầu (forward) sang file JSP tương ứng để render giao diện HTML
        request.getRequestDispatcher(VIEW_ROOT + view).forward(request, response);
    }

    // Ánh xạ (Map) từ Servlet Path sang file JSP tương ứng trong thư mục /WEB-INF/views/receptionist/
    private String resolveView(String servletPath) {
        if ("/receptionist/dashboard".equals(servletPath)) {
            return "dashboard.jsp"; // Trang tổng quan
        }
        if ("/receptionist/patients/search".equals(servletPath)) {
            return "patient-search.jsp"; // Tra cứu hồ sơ & lịch hẹn bệnh nhân
        }
        if ("/receptionist/patients/register".equals(servletPath)) {
            return "patient-registration.jsp"; // Tạo tài khoản bệnh nhân tại quầy
        }
        if ("/receptionist/appointments/new".equals(servletPath)) {
            return "appointment-registration.jsp"; // Đăng ký ca khám
        }
        if ("/receptionist/queue".equals(servletPath)) {
            return "queue-management.jsp"; // Hàng đợi khám & Check-in
        }
        if ("/receptionist/billing".equals(servletPath)) {
            return "billing-management.jsp"; // Quản lý và thu phí hóa đơn
        }
        if ("/receptionist/schedule".equals(servletPath)) {
            return "schedule.jsp"; // Lịch trực tuần của Lễ tân
        }
        return null;
    }
}
