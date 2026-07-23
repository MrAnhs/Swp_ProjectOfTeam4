package com.diabetes.monitoring.doctor.servlet;

import com.diabetes.monitoring.doctor.model.HealthRecord;
import com.diabetes.monitoring.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

public class MedicalHistoryServlet extends DoctorServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User currentUser = requireDoctor(request, response);
        if (currentUser == null) {
            return;
        }

        try {
            int recordId = getRecordId(request);
            int doctorId = getDoctorId(currentUser);
            HealthRecord record = dao.getHealthRecordByIdForDoctor(recordId, doctorId);
            if (record == null) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN);
                return;
            }

            request.setAttribute("record", record);
            request.setAttribute("patient", dao.getPatientById(record.getPatientId()));
            request.setAttribute("medicalHistory",
                    dao.getMedicalHistory(record.getPatientId(), doctorId));
            request.getRequestDispatcher("/WEB-INF/views/doctor/medicalHistory.jsp").forward(request, response);
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
        } catch (Exception e) {
            throw new ServletException("Khong the tai lich su benh an", e);
        }
    }
}
