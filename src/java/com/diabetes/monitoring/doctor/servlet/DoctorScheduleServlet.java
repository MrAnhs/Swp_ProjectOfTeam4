package com.diabetes.monitoring.doctor.servlet;

import com.diabetes.monitoring.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

public class DoctorScheduleServlet extends DoctorServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            User currentUser = requireDoctor(request, response);
            if (currentUser == null) {
                return;
            }

            request.setAttribute("schedules", dao.getDoctorSchedulesByAccountId(currentUser.getId()));
            request.setAttribute("rooms", dao.getActiveRooms());
            request.getRequestDispatcher("/WEB-INF/views/doctor/schedule.jsp").forward(request, response);
        } catch (Exception e) {
            e.printStackTrace();
            throw new ServletException("Khong the tai lich truc bac si", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        try {
            User currentUser = requireDoctor(request, response);
            if (currentUser == null) {
                return;
            }

            int doctorId = getDoctorId(currentUser);
            String workDateStr = request.getParameter("workDate");
            String timeSlot = request.getParameter("timeSlot");
            if (timeSlot != null) {
                timeSlot = timeSlot.trim().replaceAll("\\s+", "");
            }
            String roomId = request.getParameter("roomId");
            String maxPatientsStr = request.getParameter("maxPatients");

            if (workDateStr == null || workDateStr.trim().isEmpty() ||
                timeSlot == null || timeSlot.trim().isEmpty() ||
                maxPatientsStr == null || maxPatientsStr.trim().isEmpty()) {
                request.getSession().setAttribute("errorMsg", "Vui lòng nhập đầy đủ thông tin đăng ký.");
                response.sendRedirect(request.getContextPath() + "/doctor/schedule");
                return;
            }

            java.sql.Date workDate = java.sql.Date.valueOf(workDateStr.trim());
            int maxPatients = Integer.parseInt(maxPatientsStr.trim());

            // Validate that workDate is in the future or today
            java.time.LocalDate today = java.time.LocalDate.now();
            if (workDate.toLocalDate().isBefore(today)) {
                request.getSession().setAttribute("errorMsg", "Không thể đăng ký lịch trực trong quá khứ.");
                response.sendRedirect(request.getContextPath() + "/doctor/schedule");
                return;
            }

            // Check overlap
            if (dao.isScheduleOverlapping(doctorId, workDate, timeSlot)) {
                request.getSession().setAttribute("errorMsg", "Lịch trực đã bị trùng ca làm việc.");
                response.sendRedirect(request.getContextPath() + "/doctor/schedule");
                return;
            }

            boolean success = dao.proposeDoctorSchedule(doctorId, workDate, timeSlot, maxPatients, roomId);
            if (success) {
                request.getSession().setAttribute("successMsg", "Gửi yêu cầu đăng ký lịch trực thành công. Vui lòng chờ Admin duyệt.");
            } else {
                request.getSession().setAttribute("errorMsg", "Có lỗi xảy ra khi gửi yêu cầu đăng ký.");
            }
            response.sendRedirect(request.getContextPath() + "/doctor/schedule");
        } catch (Exception e) {
            e.printStackTrace();
            request.getSession().setAttribute("errorMsg", "Lỗi xử lý: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/doctor/schedule");
        }
    }
}
