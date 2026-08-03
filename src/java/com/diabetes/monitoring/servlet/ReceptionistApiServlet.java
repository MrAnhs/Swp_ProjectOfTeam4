package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.model.User;
import com.diabetes.monitoring.receptionist.ReceptionistDAO.ReceptionistException;
import com.diabetes.monitoring.receptionist.ReceptionistService;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class ReceptionistApiServlet extends HttpServlet {
    private final ReceptionistService service = new ReceptionistService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        prepareJson(response);
        try {
            String path = apiPath(request);
            if ("/patients/search".equals(path)) {
                String keyword = request.getParameter("keyword");
                if (keyword == null || keyword.isBlank()) {
                    keyword = request.getParameter("phone");
                }
                write(response, successObject(service.searchPatient(keyword)));
                return;
            }
            if ("/patients/revisit".equals(path)) {
                String dateStr = request.getParameter("date");
                java.time.LocalDate date = java.time.LocalDate.now();
                if (dateStr != null && !dateStr.isBlank()) {
                    try {
                        date = java.time.LocalDate.parse(dateStr.trim());
                    } catch (java.time.format.DateTimeParseException e) {
                        // Keep fallback date
                    }
                }
                List<Map<String, Object>> patients = service.getUpcomingRevisits(date);
                write(response, "{\"success\":true,\"patients\":" + toJson(patients) + "}");
                return;
            }
            if ("/doctors".equals(path)) {
                write(response, "{\"success\":true,\"doctors\":" + toJson(service.getDoctors()) + "}");
                return;
            }
            if ("/schedules".equals(path)) {
                int doctorId = parseInt(request.getParameter("doctorId"));
                write(response, "{\"success\":true,\"slots\":" + toJson(service.getSchedules(doctorId)) + "}");
                return;
            }
            if ("/invoices/stats".equals(path)) {
                write(response, successObject(service.getInvoiceStats()));
                return;
            }
            if ("/invoices".equals(path)) {
                List<Map<String, Object>> invoices = service.getInvoices(request.getParameter("status"), request.getParameter("invoiceType"), request.getParameter("keyword"));
                write(response, "{\"success\":true,\"invoices\":" + toJson(invoices) + "}");
                return;
            }
            if ("/invoices/details".equals(path)) {
                int invoiceId = parseInt(request.getParameter("invoiceId"));
                List<Map<String, Object>> details = service.getInvoiceDetails(invoiceId);
                write(response, "{\"success\":true,\"details\":" + toJson(details) + "}");
                return;
            }
            if ("/queue".equals(path)) {
                List<Map<String, Object>> items = service.getTodayQueue(request.getParameter("status"));
                write(response, "{\"success\":true,\"items\":" + toJson(items) + "}");
                return;
            }
            if ("/appointments/preview".equals(path)) {
                write(response, successObject(service.getAppointmentPreview(request.getParameter("appointmentId"))));
                return;
            }
            if ("/appointments/calendar".equals(path)) {
                write(response, "{\"success\":true,\"items\":" + toJson(service.getAppointmentCalendar(request.getParameter("fromDate"), request.getParameter("toDate"))) + "}");
                return;
            }
            if ("/queue".equals(path)) {
                List<Map<String, Object>> items = service.getTodayQueue(request.getParameter("status"));
                write(response, "{\"success\":true,\"items\":" + toJson(items) + "}");
                return;
            }
            if ("/my-schedule".equals(path)) {
                User currentUser = currentUser(request);
                write(response, "{\"success\":true,\"items\":" + toJson(service.getMySchedule(currentUser.getId(), request.getParameter("fromDate"), request.getParameter("toDate"))) + "}");
                return;
            }
            if ("/shift-status".equals(path)) {
                User currentUser = currentUser(request);
                Map<String, Object> status = service.getCurrentShiftStatus(currentUser.getId());
                write(response, "{\"success\":true,\"shift\":" + toJson(status) + "}");
                return;
            }
            writeError(response, HttpServletResponse.SC_NOT_FOUND, "API không tồn tại.");
        } catch (NumberFormatException | ReceptionistException e) {
            writeError(response, HttpServletResponse.SC_BAD_REQUEST, e.getMessage());
        } catch (SQLException e) {
            e.printStackTrace();
            writeError(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Không thể xử lý dữ liệu lễ tân.");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        prepareJson(response);
        try {
            String path = apiPath(request);
            if (!"/my-schedule/register".equals(path)) {
                User currentUser = currentUser(request);
                Map<String, Object> shiftStatus = service.getCurrentShiftStatus(currentUser.getId());
                Boolean inShift = (Boolean) shiftStatus.get("inShift");
                if (inShift != null && !inShift) {
                    String msg = (String) shiftStatus.get("message");
                    writeError(response, HttpServletResponse.SC_FORBIDDEN, msg != null ? msg : "Bạn hiện không ở trong ca trực active. Không thể thực hiện thao tác!");
                    return;
                }
            }

            if ("/patients".equals(path)) {
                write(response, "{\"success\":true,\"patient\":" + toJson(service.createPatient(params(request))) + "}");
                return;
            }
            if ("/patients/send-email".equals(path)) {
                Map<String, String> parameters = params(request);
                String email = parameters.get("email");
                String fullName = parameters.get("fullName");
                String temporaryPassword = parameters.get("temporaryPassword");
                if (email == null || email.trim().isEmpty() || fullName == null || fullName.trim().isEmpty() || temporaryPassword == null || temporaryPassword.trim().isEmpty()) {
                    writeError(response, HttpServletResponse.SC_BAD_REQUEST, "Thiếu thông tin gửi email.");
                    return;
                }
                com.diabetes.monitoring.util.EmailUtil.sendAccountDetailsAsync(email, fullName, temporaryPassword);
                write(response, "{\"success\":true,\"message\":\"Yêu cầu gửi email đã được khởi chạy thành công.\"}");
                return;
            }
            if ("/appointments".equals(path)) {
                write(response, successObject(service.registerAppointment(params(request))));
                return;
            }
            if ("/appointments/cancel".equals(path)) {
                User currentUser = currentUser(request);
                int appointmentId = parseInt(request.getParameter("appointmentId"));
                String reason = request.getParameter("reason");
                service.cancelAppointment(appointmentId, reason, currentUser.getId());
                write(response, "{\"success\":true,\"message\":\"Đã hủy lịch khám thành công và gửi thông báo tới bệnh nhân.\"}");
                return;
            }
            if ("/invoices/pay".equals(path)) {
                User currentUser = currentUser(request);
                String invoiceIdStr = request.getParameter("invoiceId");
                int invoiceId;
                if (invoiceIdStr != null && !invoiceIdStr.trim().isEmpty()) {
                    invoiceId = service.payInvoiceById(parseInt(invoiceIdStr),
                            request.getParameter("paymentMethod"), currentUser.getId());
                } else {
                    invoiceId = service.payInvoice(request.getParameter("patientKeyword"),
                            request.getParameter("paymentMethod"), currentUser.getId());
                }
                write(response, "{\"success\":true,\"message\":\"Thanh toán thành công.\",\"invoiceId\":"
                        + invoiceId + "}");
                return;
            }
            if ("/queue/check-in".equals(path)) {
                service.checkInAppointment(request.getParameter("appointmentId"));
                write(response, "{\"success\":true,\"message\":\"Đã check-in bệnh nhân.\"}");
                return;
            }
            if ("/queue/reassign".equals(path)) {
                service.reassignAppointment(request.getParameter("appointmentId"), request.getParameter("doctorId"), request.getParameter("scheduleId"));
                write(response, "{\"success\":true,\"message\":\"Đã đổi bác sĩ/ca khám thành công.\"}");
                return;
            }
            if ("/queue/cancel".equals(path)) {
                service.cancelAppointment(request.getParameter("appointmentId"));
                write(response, "{\"success\":true,\"message\":\"Đã hủy lịch hẹn thành công.\"}");
                return;
            }
            if ("/my-schedule/register".equals(path)) {
                User currentUser = currentUser(request);
                String workDate = request.getParameter("workDate");
                String timeSlot = request.getParameter("timeSlot");
                service.registerMySchedule(currentUser.getId(), workDate, timeSlot);
                write(response, "{\"success\":true,\"message\":\"Đăng ký lịch trực thành công.\"}");
                return;
            }
            writeError(response, HttpServletResponse.SC_NOT_FOUND, "API không tồn tại.");
        } catch (NumberFormatException | ReceptionistException e) {
            writeError(response, HttpServletResponse.SC_BAD_REQUEST, e.getMessage());
        } catch (SQLException e) {
            e.printStackTrace();
            writeError(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Không thể xử lý dữ liệu lễ tân.");
        }
    }

    private String apiPath(HttpServletRequest request) {
        String servletPath = request.getServletPath();
        String requestUri = request.getRequestURI().substring(request.getContextPath().length());
        return requestUri.substring(servletPath.length());
    }

    private User currentUser(HttpServletRequest request) throws ReceptionistException {
        HttpSession session = request.getSession(false);
        User user = session == null ? null : (User) session.getAttribute("currentUser");
        if (user == null) {
            throw new ReceptionistException("Phiên đăng nhập đã hết hạn.");
        }
        return user;
    }

    private Map<String, String> params(HttpServletRequest request) {
        Map<String, String> result = new HashMap<>();
        request.getParameterMap().forEach((key, values) ->
                result.put(key, values != null && values.length > 0 ? values[0] : ""));
        return result;
    }

    private int parseInt(String value) {
        return Integer.parseInt(value == null ? "" : value.trim());
    }

    private void prepareJson(HttpServletResponse response) {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
    }

    private void write(HttpServletResponse response, String json) throws IOException {
        response.getWriter().print(json);
    }

    private void writeError(HttpServletResponse response, int status, String message) throws IOException {
        response.setStatus(status);
        write(response, "{\"success\":false,\"error\":\"" + escape(message) + "\"}");
    }

    private String successObject(Map<String, Object> values) {
        String json = toJson(values);
        return "{\"success\":true," + json.substring(1);
    }

    private String toJson(List<Map<String, Object>> items) {
        StringBuilder json = new StringBuilder("[");
        for (int index = 0; index < items.size(); index++) {
            if (index > 0) {
                json.append(',');
            }
            json.append(toJson(items.get(index)));
        }
        return json.append(']').toString();
    }

    @SuppressWarnings("unchecked")
    private String toJson(Map<String, Object> values) {
        StringBuilder json = new StringBuilder("{");
        boolean first = true;
        for (Map.Entry<String, Object> entry : values.entrySet()) {
            if (!first) {
                json.append(',');
            }
            first = false;
            json.append('"').append(escape(entry.getKey())).append('"').append(':');
            Object value = entry.getValue();
            if (value instanceof Map) {
                json.append(toJson((Map<String, Object>) value));
            } else if (value instanceof List) {
                json.append(toJson((List<Map<String, Object>>) value));
            } else if (value instanceof Number || value instanceof BigDecimal) {
                json.append(value);
            } else if (value instanceof Boolean) {
                json.append(value);
            } else if (value == null) {
                json.append("null");
            } else {
                json.append('"').append(escape(String.valueOf(value))).append('"');
            }
        }
        return json.append('}').toString();
    }

    private String escape(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "");
    }
}
