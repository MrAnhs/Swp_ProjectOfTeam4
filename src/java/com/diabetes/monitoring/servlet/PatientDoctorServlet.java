package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.dao.DoctorDAO;
import com.diabetes.monitoring.model.DoctorInfo;
import com.diabetes.monitoring.model.DoctorScheduleInfo;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.List;

public class PatientDoctorServlet extends HttpServlet {
    private final DoctorDAO doctorDAO = new DoctorDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String doctorIdParameter = request.getParameter("id");
        try {
            if (doctorIdParameter == null || doctorIdParameter.isBlank()) {
                LocalDate workDate = parseWorkDate(request.getParameter("date"));
                String session = parseSession(request.getParameter("session"));
                String doctorName = normalizeDoctorName(request.getParameter("name"));
                writeDoctorList(response, workDate, session,
                        doctorDAO.findAvailableDoctors(workDate, session, doctorName));
                return;
            }

            int doctorId = parsePositiveId(doctorIdParameter);
            DoctorInfo doctor = doctorDAO.findActiveDoctorById(doctorId);
            if (doctor == null) {
                writeError(response, HttpServletResponse.SC_NOT_FOUND, "Không tìm thấy bác sĩ đang hoạt động.");
                return;
            }

            String dateParameter = request.getParameter("date");
            String session = parseSession(request.getParameter("session"));
            List<DoctorScheduleInfo> schedules = dateParameter == null || dateParameter.isBlank()
                    ? doctorDAO.findAvailableSchedules(doctorId)
                    : doctorDAO.findAvailableSchedules(
                            doctorId, parseWorkDate(dateParameter), session);
            response.getWriter().print(toDoctorDetailJson(doctor, schedules));
        } catch (DateTimeParseException | IllegalArgumentException e) {
            writeError(response, HttpServletResponse.SC_BAD_REQUEST,
                    "Thông tin lọc lịch khám không hợp lệ.");
        } catch (SQLException e) {
            e.printStackTrace();
            writeError(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Không thể tải thông tin bác sĩ.");
        }
    }

    private int parsePositiveId(String value) {
        int id = Integer.parseInt(value);
        if (id <= 0) {
            throw new NumberFormatException("ID must be positive");
        }
        return id;
    }

    private LocalDate parseWorkDate(String value) {
        LocalDate workDate = value == null || value.isBlank()
                ? LocalDate.now() : LocalDate.parse(value);
        if (workDate.isBefore(LocalDate.now())) {
            throw new IllegalArgumentException("Past dates are not allowed");
        }
        return workDate;
    }

    private String parseSession(String value) {
        String session = value == null || value.isBlank() ? "all" : value.trim().toLowerCase();
        if (!"all".equals(session) && !"morning".equals(session)
                && !"afternoon".equals(session)) {
            throw new IllegalArgumentException("Unsupported session");
        }
        return session;
    }

    private String normalizeDoctorName(String value) {
        return value == null ? "" : value.trim();
    }

    private void writeDoctorList(HttpServletResponse response, LocalDate workDate,
            String session, List<DoctorInfo> doctors) throws IOException, SQLException {
        StringBuilder json = new StringBuilder("{\"date\":\"")
                .append(workDate)
                .append("\",\"session\":\"")
                .append(session)
                .append("\",\"doctorCount\":")
                .append(doctors.size())
                .append(",\"doctors\":[");
        for (int index = 0; index < doctors.size(); index++) {
            if (index > 0) {
                json.append(',');
            }
            DoctorInfo doctor = doctors.get(index);
            List<DoctorScheduleInfo> schedules = doctorDAO.findAvailableSchedules(
                    doctor.getDoctorId(), workDate, session);
            json.append(toDoctorJson(doctor, schedules));
        }
        json.append("]}");
        response.getWriter().print(json);
    }

    private String toDoctorJson(DoctorInfo doctor, List<DoctorScheduleInfo> schedules) {
        StringBuilder json = new StringBuilder(toDoctorJson(doctor));
        json.deleteCharAt(json.length() - 1);
        json.append(",\"schedules\":[");
        appendSchedules(json, schedules);
        json.append("]}");
        return json.toString();
    }

    private String toDoctorDetailJson(DoctorInfo doctor, List<DoctorScheduleInfo> schedules) {
        StringBuilder json = new StringBuilder("{\"doctor\":");
        json.append(toDoctorJson(doctor));
        json.append(",\"schedules\":[");
        appendSchedules(json, schedules);
        json.append("]}");
        return json.toString();
    }

    private void appendSchedules(StringBuilder json, List<DoctorScheduleInfo> schedules) {
        for (int index = 0; index < schedules.size(); index++) {
            if (index > 0) {
                json.append(',');
            }
            DoctorScheduleInfo schedule = schedules.get(index);
            json.append('{')
                    .append("\"scheduleId\":").append(schedule.getScheduleId()).append(',')
                    .append("\"workDate\":\"").append(schedule.getWorkDate()).append("\",")
                    .append("\"timeSlot\":\"").append(escapeJson(schedule.getTimeSlot())).append("\",")
                    .append("\"maxPatients\":").append(schedule.getMaxPatients()).append(',')
                    .append("\"bookedPatients\":").append(schedule.getBookedPatients()).append(',')
                    .append("\"availableSlots\":").append(schedule.getAvailableSlots()).append(',')
                    .append("\"status\":\"").append(escapeJson(schedule.getStatus())).append("\"")
                    .append('}');
        }
    }

    private String toDoctorJson(DoctorInfo doctor) {
        return new StringBuilder("{")
                .append("\"doctorId\":").append(doctor.getDoctorId()).append(',')
                .append("\"fullName\":\"").append(escapeJson(doctor.getFullName())).append("\",")
                .append("\"phone\":\"").append(escapeJson(doctor.getPhone())).append("\",")
                .append("\"email\":\"").append(escapeJson(doctor.getEmail())).append("\",")
                .append("\"department\":\"").append(escapeJson(doctor.getDepartment())).append("\"")
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
