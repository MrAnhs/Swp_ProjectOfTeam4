package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.dao.PatientAppointmentDAO;
import com.diabetes.monitoring.model.AppointmentBookingResult;
import com.diabetes.monitoring.model.AppointmentInfo;
import com.diabetes.monitoring.model.User;
import com.diabetes.monitoring.service.AppointmentBookingException;
import com.diabetes.monitoring.service.AppointmentService;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

public class PatientAppointmentServlet extends HttpServlet {
    private static final long BOOKING_INTERVAL_MILLIS = 60_000L;
    private static final String LAST_SUCCESSFUL_BOOKING =
            PatientAppointmentServlet.class.getName() + ".lastSuccessfulBooking";

    private final AppointmentService appointmentService = new AppointmentService();
    private final PatientAppointmentDAO appointmentDAO = new PatientAppointmentDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        User currentUser = (User) request.getSession().getAttribute("currentUser");
        if (currentUser == null) {
            writeError(response, HttpServletResponse.SC_UNAUTHORIZED, "Bạn chưa đăng nhập.");
            return;
        }

        try {
            String appointmentIdParameter = request.getParameter("id");
            if (appointmentIdParameter == null || appointmentIdParameter.isBlank()) {
                writeAppointmentList(response,
                        appointmentDAO.findByPatientAccountId(currentUser.getId()));
                return;
            }

            int appointmentId = parsePositiveInt(appointmentIdParameter);
            AppointmentInfo appointment = appointmentDAO.findByIdAndPatientAccountId(
                    appointmentId, currentUser.getId());
            if (appointment == null) {
                writeError(response, HttpServletResponse.SC_NOT_FOUND,
                        "Không tìm thấy lịch hẹn hoặc bạn không có quyền truy cập.");
                return;
            }
            response.getWriter().print("{\"appointment\":" + toJson(appointment) + "}");
        } catch (NumberFormatException e) {
            writeError(response, HttpServletResponse.SC_BAD_REQUEST, "Mã lịch hẹn không hợp lệ.");
        } catch (SQLException e) {
            e.printStackTrace();
            writeError(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Không thể tải lịch hẹn.");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession();
        User currentUser = (User) session.getAttribute("currentUser");
        if (currentUser == null) {
            writeError(response, HttpServletResponse.SC_UNAUTHORIZED, "Bạn chưa đăng nhập.");
            return;
        }

        synchronized (session) {
            Long lastSuccessfulBooking = (Long) session.getAttribute(LAST_SUCCESSFUL_BOOKING);
            if (lastSuccessfulBooking != null) {
                long elapsed = System.currentTimeMillis() - lastSuccessfulBooking;
                if (elapsed < BOOKING_INTERVAL_MILLIS) {
                    long seconds = (BOOKING_INTERVAL_MILLIS - elapsed + 999L) / 1000L;
                    writeError(response, 429,
                            "Bạn vừa đặt lịch thành công. Vui lòng thử lại sau "
                            + seconds + " giây.");
                    return;
                }
            }

        try {
            int doctorId = parsePositiveInt(request.getParameter("doctorId"));
            int scheduleId = parsePositiveInt(request.getParameter("scheduleId"));
            AppointmentBookingResult result = appointmentService.bookByDoctor(
                    currentUser.getId(), doctorId, scheduleId);
            session.setAttribute(LAST_SUCCESSFUL_BOOKING, System.currentTimeMillis());
            response.setStatus(HttpServletResponse.SC_CREATED);
            response.getWriter().print(toJson(result));
        } catch (IllegalArgumentException | NullPointerException e) {
            writeError(response, HttpServletResponse.SC_BAD_REQUEST,
                    "Thông tin đặt lịch không hợp lệ.");
        } catch (AppointmentBookingException e) {
            writeError(response, HttpServletResponse.SC_CONFLICT, e.getMessage());
        } catch (SQLException e) {
            e.printStackTrace();
            writeError(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Không thể tạo lịch hẹn. Vui lòng thử lại.");
        }
        }
    }

    private int parsePositiveInt(String value) {
        int number = Integer.parseInt(value);
        if (number <= 0) {
            throw new NumberFormatException("Value must be positive");
        }
        return number;
    }

    private String toJson(AppointmentBookingResult result) {
        return new StringBuilder("{\"success\":true,")
                .append("\"appointmentId\":").append(result.getAppointmentId()).append(',')
                .append("\"scheduleId\":").append(result.getScheduleId()).append(',')
                .append("\"queueNumber\":").append(result.getQueueNumber()).append(',')
                .append("\"appointmentTime\":\"").append(result.getAppointmentTime()).append("\",")
                .append("\"status\":\"").append(escapeJson(result.getStatus())).append("\",")
                .append("\"doctorName\":\"").append(escapeJson(result.getDoctorName())).append("\",")
                .append("\"department\":\"").append(escapeJson(result.getDepartment())).append("\",")
                .append("\"timeSlot\":\"").append(escapeJson(result.getTimeSlot())).append("\"}")
                .toString();
    }

    private void writeAppointmentList(HttpServletResponse response,
            List<AppointmentInfo> appointments) throws IOException {
        StringBuilder json = new StringBuilder("{\"appointments\":[");
        for (int index = 0; index < appointments.size(); index++) {
            if (index > 0) {
                json.append(',');
            }
            json.append(toJson(appointments.get(index)));
        }
        json.append("]}");
        response.getWriter().print(json);
    }

    private String toJson(AppointmentInfo appointment) {
        return new StringBuilder("{")
                .append("\"appointmentId\":").append(appointment.getAppointmentId()).append(',')
                .append("\"doctorId\":").append(appointment.getDoctorId()).append(',')
                .append("\"scheduleId\":").append(appointment.getScheduleId()).append(',')
                .append("\"conversationId\":")
                .append(appointment.getConversationId() == null
                        ? "null" : appointment.getConversationId()).append(',')
                .append("\"doctorName\":\"").append(escapeJson(appointment.getDoctorName())).append("\",")
                .append("\"department\":\"").append(escapeJson(appointment.getDepartment())).append("\",")
                .append("\"doctorPhone\":\"").append(escapeJson(appointment.getDoctorPhone())).append("\",")
                .append("\"doctorEmail\":\"").append(escapeJson(appointment.getDoctorEmail())).append("\",")
                .append("\"timeSlot\":\"").append(escapeJson(appointment.getTimeSlot())).append("\",")
                .append("\"appointmentTime\":\"").append(appointment.getAppointmentTime()).append("\",")
                .append("\"bookingType\":\"").append(escapeJson(appointment.getBookingType())).append("\",")
                .append("\"queueNumber\":").append(appointment.getQueueNumber()).append(',')
                .append("\"status\":\"").append(escapeJson(appointment.getStatus())).append("\",")
                .append("\"createdAt\":\"").append(appointment.getCreatedAt()).append("\"")
                .append('}')
                .toString();
    }

    private void writeError(HttpServletResponse response, int status, String message) throws IOException {
        response.setStatus(status);
        response.getWriter().print("{\"error\":\"" + escapeJson(message) + "\"}");
    }

    private String escapeJson(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "");
    }
}
