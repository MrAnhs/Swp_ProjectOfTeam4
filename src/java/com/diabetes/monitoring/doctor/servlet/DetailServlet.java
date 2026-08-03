package com.diabetes.monitoring.doctor.servlet;

import com.diabetes.monitoring.doctor.dao.HealthRecordDAO;
import com.diabetes.monitoring.doctor.model.HealthRecord;
import com.diabetes.monitoring.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

public class DetailServlet extends DoctorServlet {

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
            HealthRecord record =
                    dao.getHealthRecordByIdForDoctor(recordId, doctorId);
            if (record == null) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN);
                return;
            }

            HealthRecordDAO.LaboratoryStage labStage =
                    dao.getLaboratoryStage(recordId, doctorId);
            boolean hasCompletedLab =
                    labStage == HealthRecordDAO.LaboratoryStage.COMPLETED;
            int patientId = record.getPatientId();

            request.setAttribute("record", record);
            request.setAttribute("patient", dao.getPatientById(patientId));
            request.setAttribute("aiConversation",
                    new com.diabetes.monitoring.doctor.dao.AIConversationDAO().getConversationByRecordOrPatient(recordId, patientId));
            request.setAttribute("medicalHistory",
                    dao.getMedicalHistory(patientId, doctorId));
            request.setAttribute("laboratoryRequests",
                    dao.getLaboratoryRequests(recordId, doctorId));
            request.setAttribute("laboratoryServices",
                    dao.getActiveLaboratoryServices());
            request.setAttribute("labDoctors",
                    dao.getScheduledLabDoctors());
            request.setAttribute("laboratoryStage", labStage.name());
            request.setAttribute("hasLaboratoryRequest",
                    labStage != HealthRecordDAO.LaboratoryStage.NONE);
            request.setAttribute("hasPaidLaboratoryRequest",
                    labStage == HealthRecordDAO.LaboratoryStage.LABORATORY
                    || hasCompletedLab);
            request.setAttribute("hasCompletedLaboratoryRequest",
                    hasCompletedLab);
            request.setAttribute("hasRequiredAIData",
                    dao.hasRequiredAIData(recordId, doctorId));
            request.setAttribute("availableDoctors",
                    dao.getAvailableDoctors(doctorId));
            request.getRequestDispatcher("/WEB-INF/views/doctor/examinationDetail.jsp")
                    .forward(request, response);
        } catch (NumberFormatException e) {
            response.sendRedirect(
                    request.getContextPath() + "/doctor/dashboard");
        } catch (Exception e) {
            throw new ServletException("Không thể tải hồ sơ khám", e);
        }
    }

}
