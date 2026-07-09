package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.dao.PatientVisitDAO;
import com.diabetes.monitoring.model.PatientVisit;
import com.diabetes.monitoring.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.List;

public class PatientVisitServlet extends HttpServlet {
    private final PatientVisitDAO visitDAO = new PatientVisitDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        User user = (User) request.getSession().getAttribute("currentUser");
        if (user == null) {
            error(response, 401, "Bạn chưa đăng nhập.");
            return;
        }

        try {
            String id = request.getParameter("appointmentId");
            if (id == null || id.isBlank()) {
                writeList(response, visitDAO.findByAccountId(user.getId()));
                return;
            }
            int appointmentId = Integer.parseInt(id);
            if (appointmentId <= 0) throw new NumberFormatException();
            PatientVisit visit = visitDAO.findByAppointmentId(appointmentId, user.getId());
            if (visit == null) {
                error(response, 404, "Không tìm thấy lần khám hoặc bạn không có quyền truy cập.");
                return;
            }
            response.getWriter().print("{\"visit\":" + json(visit) + "}");
        } catch (NumberFormatException e) {
            error(response, 400, "Mã lần khám không hợp lệ.");
        } catch (SQLException e) {
            e.printStackTrace();
            error(response, 500, "Không thể tải lịch sử khám.");
        }
    }

    private void writeList(HttpServletResponse response, List<PatientVisit> visits) throws IOException {
        StringBuilder json = new StringBuilder("{\"visits\":[");
        for (int index = 0; index < visits.size(); index++) {
            if (index > 0) json.append(',');
            json.append(json(visits.get(index)));
        }
        response.getWriter().print(json.append("]}"));
    }

    private String json(PatientVisit v) {
        StringBuilder json = new StringBuilder("{")
                .append("\"appointmentId\":").append(v.appointmentId).append(',')
                .append("\"doctorName\":\"").append(escape(v.doctorName)).append("\",")
                .append("\"department\":\"").append(escape(v.department)).append("\",")
                .append("\"appointmentTime\":\"").append(value(v.appointmentTime)).append("\",")
                .append("\"appointmentStatus\":\"").append(escape(v.appointmentStatus)).append("\",")
                .append("\"recordId\":").append(v.recordId == null ? "null" : v.recordId).append(',')
                .append("\"resultVisible\":").append(v.resultVisible).append(',')
                .append("\"processedAt\":\"").append(value(v.processedAt)).append("\",")
                .append("\"healthRecordId\":")
                .append(v.healthRecordId == null ? "null" : v.healthRecordId).append(',')
                .append("\"healthRecordStatus\":\"").append(escape(v.healthRecordStatus)).append("\"");

        if (v.resultVisible) {
            json.append(",\"finalDiagnosis\":\"").append(escape(v.finalDiagnosis)).append("\",")
                    .append("\"doctorNote\":\"").append(escape(v.doctorNote)).append("\",")
                    .append("\"metrics\":{")
                    .append("\"urea\":").append(number(v.urea)).append(',')
                    .append("\"cr\":").append(number(v.cr)).append(',')
                    .append("\"hba1c\":").append(number(v.hba1c)).append(',')
                    .append("\"chol\":").append(number(v.chol)).append(',')
                    .append("\"tg\":").append(number(v.tg)).append(',')
                    .append("\"hdl\":").append(number(v.hdl)).append(',')
                    .append("\"ldl\":").append(number(v.ldl)).append(',')
                    .append("\"vldl\":").append(number(v.vldl)).append(',')
                    .append("\"bmi\":").append(number(v.bmi)).append(',')
                    .append("\"weight\":").append(number(v.weight)).append(',')
                    .append("\"height\":").append(number(v.height))
                    .append("},\"otherInformation\":\"").append(escape(v.otherInformation)).append("\"");
        }
        return json.append('}').toString();
    }

    private String number(BigDecimal value) {
        return value == null ? "null" : value.toPlainString();
    }

    private String value(Object value) {
        return value == null ? "" : value.toString();
    }

    private void error(HttpServletResponse response, int status, String message) throws IOException {
        response.setStatus(status);
        response.getWriter().print("{\"error\":\"" + escape(message) + "\"}");
    }

    private String escape(String value) {
        if (value == null) return "";
        return value.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "");
    }
}
