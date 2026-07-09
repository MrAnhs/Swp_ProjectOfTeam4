package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.dao.DoctorDAO;
import com.diabetes.monitoring.model.AvailabilitySlot;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

public class PatientAvailabilityServlet extends HttpServlet {
    private final DoctorDAO doctorDAO = new DoctorDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        try {
            List<AvailabilitySlot> slots = doctorDAO.findAvailableTimeSlots();
            StringBuilder json = new StringBuilder("{\"slots\":[");
            for (int index = 0; index < slots.size(); index++) {
                if (index > 0) {
                    json.append(',');
                }
                AvailabilitySlot slot = slots.get(index);
                json.append('{')
                        .append("\"workDate\":\"").append(slot.getWorkDate()).append("\",")
                        .append("\"timeSlot\":\"").append(escapeJson(slot.getTimeSlot())).append("\",")
                        .append("\"doctorCount\":").append(slot.getDoctorCount()).append(',')
                        .append("\"availableSlots\":").append(slot.getAvailableSlots())
                        .append('}');
            }
            json.append("]}");
            response.getWriter().print(json);
        } catch (SQLException e) {
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().print("{\"error\":\"Không thể tải các ca khám khả dụng.\"}");
        }
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
