package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.dao.PatientInvoiceDAO;
import com.diabetes.monitoring.model.InvoiceInfo;
import com.diabetes.monitoring.model.InvoiceItem;
import com.diabetes.monitoring.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.List;

public class PatientInvoiceServlet extends HttpServlet {
    private final PatientInvoiceDAO invoiceDAO = new PatientInvoiceDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        prepare(response);
        User user = currentUser(request, response);
        if (user == null) return;

        try {
            String idParameter = request.getParameter("id");
            if (idParameter == null || idParameter.isBlank()) {
                writeList(response, invoiceDAO.findByPatientAccountId(
                        user.getId(), parseSearchDate(request.getParameter("searchDate"))));
                return;
            }
            int invoiceId = positiveId(idParameter);
            InvoiceInfo invoice = invoiceDAO.findById(invoiceId, user.getId());
            if (invoice == null) {
                writeError(response, 404, "Không tìm thấy hóa đơn hoặc bạn không có quyền truy cập.");
                return;
            }
            List<InvoiceItem> items = invoiceDAO.findItems(invoiceId, user.getId());
            response.getWriter().print("{\"invoice\":" + invoiceJson(invoice)
                    + ",\"items\":" + itemsJson(items) + "}");
        } catch (NumberFormatException e) {
            writeError(response, 400, "Mã hóa đơn không hợp lệ.");
        } catch (SQLException e) {
            e.printStackTrace();
            writeError(response, 500, "Không thể tải hóa đơn.");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        prepare(response);
        User user = currentUser(request, response);
        if (user == null) return;

        try {
            int invoiceId = positiveId(request.getParameter("invoiceId"));
            String paymentMethod = request.getParameter("paymentMethod");
            if (!invoiceDAO.requestPayment(invoiceId, user.getId(), paymentMethod)) {
                writeError(response, 409,
                        "Hóa đơn không tồn tại, đã thanh toán hoặc không thể cập nhật.");
                return;
            }
            response.getWriter().print("{\"success\":true,\"status\":\"Pending\","
                    + "\"message\":\"Đã ghi nhận phương thức thanh toán. "
                    + "Vui lòng chờ lễ tân xác nhận.\"}");
        } catch (IllegalArgumentException e) {
            writeError(response, 400, e.getMessage());
        } catch (SQLException e) {
            e.printStackTrace();
            writeError(response, 500, "Không thể gửi yêu cầu thanh toán.");
        }
    }

    private User currentUser(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        User user = (User) request.getSession().getAttribute("currentUser");
        if (user == null) writeError(response, 401, "Bạn chưa đăng nhập.");
        return user;
    }

    private int positiveId(String value) {
        int id = Integer.parseInt(value);
        if (id <= 0) throw new NumberFormatException();
        return id;
    }

    private LocalDate parseSearchDate(String value) throws IOException {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return LocalDate.parse(value);
        } catch (DateTimeParseException e) {
            throw new IOException("Ngày tìm kiếm không hợp lệ.", e);
        }
    }

    private void prepare(HttpServletResponse response) {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
    }

    private void writeList(HttpServletResponse response, List<InvoiceInfo> invoices)
            throws IOException {
        StringBuilder json = new StringBuilder("{\"invoices\":[");
        for (int index = 0; index < invoices.size(); index++) {
            if (index > 0) json.append(',');
            json.append(invoiceJson(invoices.get(index)));
        }
        json.append("]}");
        response.getWriter().print(json);
    }

    private String invoiceJson(InvoiceInfo invoice) {
        return new StringBuilder("{")
                .append("\"invoiceId\":").append(invoice.getInvoiceId()).append(',')
                .append("\"totalAmount\":").append(number(invoice.getTotalAmount())).append(',')
                .append("\"insuranceDeduction\":").append(number(invoice.getInsuranceDeduction())).append(',')
                .append("\"finalAmount\":").append(number(invoice.getFinalAmount())).append(',')
                .append("\"paymentMethod\":\"").append(escape(invoice.getPaymentMethod())).append("\",")
                .append("\"status\":\"").append(escape(invoice.getStatus())).append("\",")
                .append("\"createdAt\":\"").append(invoice.getCreatedAt()).append("\",")
                .append("\"exportedAt\":\"")
                .append(invoice.getExportedAt() == null ? "" : invoice.getExportedAt()).append("\",")
                .append("\"patientId\":").append(invoice.getPatientId()).append(',')
                .append("\"patientName\":\"").append(escape(invoice.getPatientName())).append("\",")
                .append("\"patientPhone\":\"").append(escape(invoice.getPatientPhone())).append("\",")
                .append("\"patientEmail\":\"").append(escape(invoice.getPatientEmail())).append("\",")
                .append("\"patientAddress\":\"").append(escape(invoice.getPatientAddress())).append("\"}")
                .toString();
    }

    private String itemsJson(List<InvoiceItem> items) {
        StringBuilder json = new StringBuilder("[");
        for (int index = 0; index < items.size(); index++) {
            if (index > 0) json.append(',');
            InvoiceItem item = items.get(index);
            json.append('{')
                    .append("\"invoiceDetailId\":").append(item.getInvoiceDetailId()).append(',')
                    .append("\"appointmentId\":").append(item.getAppointmentId()).append(',')
                    .append("\"serviceId\":").append(item.getServiceId()).append(',')
                    .append("\"serviceName\":\"").append(escape(item.getServiceName())).append("\",")
                    .append("\"serviceType\":\"").append(escape(item.getServiceType())).append("\",")
                    .append("\"quantity\":").append(item.getQuantity()).append(',')
                    .append("\"price\":").append(number(item.getPrice()))
                    .append('}');
        }
        return json.append(']').toString();
    }

    private String number(java.math.BigDecimal value) {
        return value == null ? "0" : value.toPlainString();
    }

    private void writeError(HttpServletResponse response, int status, String message)
            throws IOException {
        response.setStatus(status);
        response.getWriter().print("{\"error\":\"" + escape(message) + "\"}");
    }

    private String escape(String value) {
        if (value == null) return "";
        return value.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "");
    }
}
