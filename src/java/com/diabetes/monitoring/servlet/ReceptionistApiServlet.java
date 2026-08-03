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

            // API 1: Tìm kiếm bệnh nhân theo từ khóa (họ tên hoặc số điện thoại)
            if ("/patients/search".equals(path)) {
                String keyword = request.getParameter("keyword");
                if (keyword == null || keyword.isBlank()) {
                    keyword = request.getParameter("phone");
                }
                write(response, successObject(service.searchPatient(keyword)));
                return;
            }

            // API 2: Lấy danh sách bệnh nhân tái khám trong ngày (upcoming revisits)
            if ("/patients/revisit".equals(path)) {
                String dateStr = request.getParameter("date");
                java.time.LocalDate date = java.time.LocalDate.now();
                if (dateStr != null && !dateStr.isBlank()) {
                    try {
                        date = java.time.LocalDate.parse(dateStr.trim());
                    } catch (java.time.format.DateTimeParseException e) {
                        // Giữ nguyên ngày mặc định nếu parse lỗi
                    }
                }
                List<Map<String, Object>> patients = service.getUpcomingRevisits(date);
                write(response, "{\"success\":true,\"patients\":" + toJson(patients) + "}");
                return;
            }

            // API 3: Lấy danh sách toàn bộ các Bác sĩ đang hoạt động
            if ("/doctors".equals(path)) {
                write(response, "{\"success\":true,\"doctors\":" + toJson(service.getDoctors()) + "}");
                return;
            }

            // API 4: Lấy lịch trực và các slot khám còn trống của một Bác sĩ cụ thể
            if ("/schedules".equals(path)) {
                int doctorId = parseInt(request.getParameter("doctorId"));
                write(response, "{\"success\":true,\"slots\":" + toJson(service.getSchedules(doctorId)) + "}");
                return;
            }

            // API 5: Thống kê số lượng hóa đơn (chờ thanh toán và đã thanh toán)
            if ("/invoices/stats".equals(path)) {
                write(response, successObject(service.getInvoiceStats()));
                return;
            }

            // API 6: Lấy danh sách hóa đơn theo bộ lọc trạng thái và từ khóa tìm kiếm
            if ("/invoices".equals(path)) {
                List<Map<String, Object>> invoices = service.getInvoices(request.getParameter("status"), request.getParameter("invoiceType"), request.getParameter("keyword"));
                write(response, "{\"success\":true,\"invoices\":" + toJson(invoices) + "}");
                return;
            }

            // API 7: Tải danh sách chi tiết các dịch vụ y tế đi kèm của một hóa đơn cụ thể
            if ("/invoices/details".equals(path)) {
                int invoiceId = parseInt(request.getParameter("invoiceId"));
                List<Map<String, Object>> details = service.getInvoiceDetails(invoiceId);
                write(response, "{\"success\":true,\"details\":" + toJson(details) + "}");
                return;
            }

            // API 8: Lấy danh sách hàng đợi khám bệnh hôm nay theo trạng thái
            if ("/queue".equals(path)) {
                List<Map<String, Object>> items = service.getTodayQueue(request.getParameter("status"));
                write(response, "{\"success\":true,\"items\":" + toJson(items) + "}");
                return;
            }

            // API 9: Xem trước thông tin lịch hẹn khám trước khi tiến hành check-in/hủy lịch
            if ("/appointments/preview".equals(path)) {
                write(response, successObject(service.getAppointmentPreview(request.getParameter("appointmentId"))));
                return;
            }

            // API 10: Tải lịch hẹn dạng lịch biểu (Calendar) theo tuần
            if ("/appointments/calendar".equals(path)) {
                write(response, "{\"success\":true,\"items\":" + toJson(service.getAppointmentCalendar(request.getParameter("fromDate"), request.getParameter("toDate"))) + "}");
                return;
            }

            // API 11: Lấy danh sách lịch trực tuần của chính Lễ tân đang đăng nhập
            if ("/my-schedule".equals(path)) {
                User currentUser = currentUser(request);
                write(response, "{\"success\":true,\"items\":" + toJson(service.getMySchedule(currentUser.getId(), request.getParameter("fromDate"), request.getParameter("toDate"))) + "}");
                return;
            }

            // API 12: Kiểm tra trạng thái ca trực hiện tại của Lễ tân (active hay không)
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

            // 1. Kiểm tra an toàn: Lễ tân bắt buộc phải đang trong Ca trực được phân công thì mới được sửa đổi dữ liệu (trừ API đăng ký ca trực)
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

            // API 13: Tạo mới hồ sơ bệnh nhân tại quầy
            if ("/patients".equals(path)) {
                write(response, "{\"success\":true,\"patient\":" + toJson(service.createPatient(params(request))) + "}");
                return;
            }

            // API 14: Gửi email chứa tài khoản và mật khẩu tạm thời cho bệnh nhân
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

            // API 15: Tạo lịch hẹn khám bệnh mới
            if ("/appointments".equals(path)) {
                write(response, successObject(service.registerAppointment(params(request))));
                return;
            }

            // API 16: Hủy lịch hẹn khám bệnh và thông báo lý do hủy cho bệnh nhân
            if ("/appointments/cancel".equals(path)) {
                User currentUser = currentUser(request);
                int appointmentId = parseInt(request.getParameter("appointmentId"));
                String reason = request.getParameter("reason");
                service.cancelAppointment(appointmentId, reason, currentUser.getId());
                write(response, "{\"success\":true,\"message\":\"Đã hủy lịch khám thành công và gửi thông báo tới bệnh nhân.\"}");
                return;
            }

            // API 17: Xác nhận thanh toán hóa đơn bằng Tiền mặt hoặc VNPay tại quầy
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

            // API 18: Xác nhận Check-in cho bệnh nhân khi họ đến phòng chờ khám
            if ("/queue/check-in".equals(path)) {
                service.checkInAppointment(request.getParameter("appointmentId"));
                write(response, "{\"success\":true,\"message\":\"Đã check-in bệnh nhân.\"}");
                return;
            }

            // API 19: Phân bổ lại lịch hẹn sang Bác sĩ khác hoặc Slot thời gian khác
            if ("/queue/reassign".equals(path)) {
                service.reassignAppointment(request.getParameter("appointmentId"), request.getParameter("doctorId"), request.getParameter("scheduleId"));
                write(response, "{\"success\":true,\"message\":\"Đã đổi bác sĩ/ca khám thành công.\"}");
                return;
            }

            // API 20: Hủy lịch trong hàng đợi khám
            if ("/queue/cancel".equals(path)) {
                service.cancelAppointment(request.getParameter("appointmentId"));
                write(response, "{\"success\":true,\"message\":\"Đã hủy lịch hẹn thành công.\"}");
                return;
            }

            // API 21: Đăng ký lịch làm việc (lịch trực tuần) của Lễ tân
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
