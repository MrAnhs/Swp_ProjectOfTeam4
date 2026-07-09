package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.model.Patient;
import com.diabetes.monitoring.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Collections;

public class PatientSearchServlet extends DoctorServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        User currentUser = requireDoctor(request, response);
        if (currentUser == null) {
            return;
        }

        String searchType = request.getParameter("searchType");
        String keyword = request.getParameter("keyword");

        if (searchType == null || searchType.trim().isEmpty()) {
            searchType = "patient";
        }
        if ((keyword == null || keyword.trim().isEmpty())
                && request.getParameter("patientId") != null) {
            keyword = request.getParameter("patientId");
            searchType = "patient";
        }

        request.setAttribute("searchType", searchType);
        request.setAttribute("keyword", keyword);

        if (keyword != null && !keyword.trim().isEmpty()) {
            try {
                int searchId = Integer.parseInt(keyword.trim());
                int doctorId = getDoctorId(currentUser);
                request.setAttribute("doctorId", doctorId);

                if ("record".equalsIgnoreCase(searchType)) {
                    searchByHealthRecordId(request, searchId, doctorId);
                } else {
                    searchByPatientId(request, searchId, doctorId);
                }
            } catch (NumberFormatException e) {
                request.setAttribute("message", "Mã tra cứu không hợp lệ.");
            } catch (Exception e) {
                throw new ServletException("Khong the tra cuu thong tin y te", e);
            }
        }

        request.getRequestDispatcher("/doctor/searchPatient.jsp")
                .forward(request, response);
    }

    private void searchByPatientId(HttpServletRequest request, int patientId, int doctorId)
            throws Exception {
        Patient patient = dao.getPatientById(patientId);

        if (patient != null) {
            request.setAttribute("patient", patient);
            request.setAttribute(
                    "records",
                    dao.getRecordsByPatientIdAndDoctorId(patientId, doctorId)
            );
        } else {
            request.setAttribute("message",
                    "Không tìm thấy bệnh nhân có mã: " + patientId);
        }
    }

    private void searchByHealthRecordId(HttpServletRequest request, int recordId, int doctorId)
            throws Exception {
        com.diabetes.monitoring.model.HealthRecord record =
                dao.getHealthRecordByIdForDoctor(recordId, doctorId);

        if (record != null) {
            request.setAttribute("patient", dao.getPatientById(record.getPatientId()));
            request.setAttribute("records", Collections.singletonList(record));
        } else {
            request.setAttribute("message",
                    "Không tìm thấy hồ sơ được phân công có mã: " + recordId);
        }
    }
}
