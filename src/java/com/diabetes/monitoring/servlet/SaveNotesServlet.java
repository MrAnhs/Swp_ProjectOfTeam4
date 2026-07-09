package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.dao.HealthRecordDAO;
import com.diabetes.monitoring.model.User;
import com.google.gson.Gson;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

public class SaveNotesServlet extends HttpServlet {

    private final HealthRecordDAO dao = new HealthRecordDAO();
    private final Gson gson = new Gson();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json;charset=UTF-8");

        try {
            HttpSession session = request.getSession(false);
            if (session == null || !(session.getAttribute("currentUser") instanceof User)) {
                sendJson(response, HttpServletResponse.SC_UNAUTHORIZED, false,
                        "Phien dang nhap da het han");
                return;
            }

            User currentUser = (User) session.getAttribute("currentUser");
            if (!"doctor".equalsIgnoreCase(currentUser.getRole())) {
                sendJson(response, HttpServletResponse.SC_FORBIDDEN, false,
                        "Khong co quyen luu ho so");
                return;
            }

            int recordId = Integer.parseInt(request.getParameter("record_id"));
            String notes = request.getParameter("notes");
            String diagnosis = request.getParameter("diagnosis");
            boolean canView = Boolean.parseBoolean(request.getParameter("can_view"));

            if (recordId <= 0 || diagnosis == null || diagnosis.trim().isEmpty()) {
                sendJson(response, HttpServletResponse.SC_BAD_REQUEST, false,
                        "Du lieu ho so khong hop le");
                return;
            }

            int doctorId = dao.getOrCreateDoctorIdByAccountId(currentUser.getId());
            if (!dao.isRecordAssignedToDoctor(recordId, doctorId)) {
                sendJson(response, HttpServletResponse.SC_FORBIDDEN, false,
                        "Ban khong co quyen luu ho so nay");
                return;
            }

            if (!dao.canModifyDiagnosis(recordId, doctorId)) {
                sendJson(response, HttpServletResponse.SC_FORBIDDEN, false,
                        "This record cannot be modified.");
                return;
            }

            if (!dao.updateHealthMetricsForDoctor(
                    recordId,
                    doctorId,
                    parseNullableDouble(request.getParameter("urea")),
                    parseNullableDouble(request.getParameter("cr")),
                    parseNullableDouble(request.getParameter("hba1c")),
                    parseNullableDouble(request.getParameter("chol")),
                    parseNullableDouble(request.getParameter("tg")),
                    parseNullableDouble(request.getParameter("hdl")),
                    parseNullableDouble(request.getParameter("idl")),
                    parseNullableDouble(request.getParameter("vldl")),
                    parseNullableDouble(request.getParameter("bmi")))) {
                sendJson(response, HttpServletResponse.SC_FORBIDDEN, false,
                        "Khong the cap nhat chi so xet nghiem.");
                return;
            }

            dao.saveMedicalRecordAndCompleteForDoctor(
                    recordId,
                    doctorId,
                    notes,
                    diagnosis.trim(),
                    canView
            );

            sendJson(response, HttpServletResponse.SC_OK, true, "Luu ho so thanh cong");
        } catch (NumberFormatException e) {
            sendJson(response, HttpServletResponse.SC_BAD_REQUEST, false,
                    "Ma ho so khong hop le");
        } catch (Exception e) {
            e.printStackTrace();
            sendJson(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, false,
                    e.getMessage() == null ? "Khong the luu ho so" : e.getMessage());
        }
    }

    private Double parseNullableDouble(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        return Double.valueOf(value.trim());
    }

    private void sendJson(
            HttpServletResponse response,
            int status,
            boolean success,
            String message) throws IOException {
        response.setStatus(status);
        Map<String, Object> result = new HashMap<>();
        result.put("success", success);
        result.put("message", message);
        response.getWriter().write(gson.toJson(result));
    }
}
