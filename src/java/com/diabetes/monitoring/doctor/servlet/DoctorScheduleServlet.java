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
            String startDateStr = request.getParameter("startDate");
            String endDateStr = request.getParameter("endDate");
            String[] timeSlots = request.getParameterValues("timeSlots");
            String roomId = request.getParameter("roomId");
            String maxPatientsStr = request.getParameter("maxPatients");

            if (startDateStr == null || startDateStr.trim().isEmpty() ||
                endDateStr == null || endDateStr.trim().isEmpty() ||
                timeSlots == null || timeSlots.length == 0 ||
                maxPatientsStr == null || maxPatientsStr.trim().isEmpty()) {
                request.getSession().setAttribute("errorMsg", "Vui lòng nhập đầy đủ thông tin đăng ký.");
                response.sendRedirect(request.getContextPath() + "/doctor/schedule");
                return;
            }

            java.sql.Date startDate = java.sql.Date.valueOf(startDateStr.trim());
            java.sql.Date endDate = java.sql.Date.valueOf(endDateStr.trim());
            int maxPatients = Integer.parseInt(maxPatientsStr.trim());

            if (endDate.before(startDate)) {
                request.getSession().setAttribute("errorMsg", "Ngày kết thúc không được nhỏ hơn ngày bắt đầu.");
                response.sendRedirect(request.getContextPath() + "/doctor/schedule");
                return;
            }

            java.time.LocalDate startLocalDate = startDate.toLocalDate();
            java.time.LocalDate endLocalDate = endDate.toLocalDate();
            java.time.LocalDate today = java.time.LocalDate.now();

            if (startLocalDate.isBefore(today)) {
                request.getSession().setAttribute("errorMsg", "Không thể đăng ký lịch trực trong quá khứ.");
                response.sendRedirect(request.getContextPath() + "/doctor/schedule");
                return;
            }

            int proposedCount = 0;
            int skippedCount = 0;

            for (java.time.LocalDate date = startLocalDate; !date.isAfter(endLocalDate); date = date.plusDays(1)) {
                java.sql.Date sqlDate = java.sql.Date.valueOf(date);
                for (String rawSlot : timeSlots) {
                    if (rawSlot == null || rawSlot.trim().isEmpty()) {
                        continue;
                    }
                    String timeSlot = rawSlot.trim().replaceAll("\\s+", "");
                    if (dao.isScheduleOverlapping(doctorId, sqlDate, timeSlot)) {
                        skippedCount++;
                        continue;
                    }
                    boolean success = dao.proposeDoctorSchedule(doctorId, sqlDate, timeSlot, maxPatients, roomId);
                    if (success) {
                        proposedCount++;
                    } else {
                        skippedCount++;
                    }
                }
            }

            if (proposedCount > 0) {
                String msg = "Gửi yêu cầu đăng ký thành công " + proposedCount + " ca trực.";
                if (skippedCount > 0) {
                    msg += " Bỏ qua " + skippedCount + " ca trùng/lỗi.";
                }
                request.getSession().setAttribute("successMsg", msg);
            } else {
                request.getSession().setAttribute("errorMsg", "Không thể đăng ký ca trực nào (tất cả ca chọn đều trùng hoặc lỗi).");
            }
            response.sendRedirect(request.getContextPath() + "/doctor/schedule");
        } catch (Exception e) {
            e.printStackTrace();
            request.getSession().setAttribute("errorMsg", "Lỗi xử lý: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/doctor/schedule");
        }
    }
}
