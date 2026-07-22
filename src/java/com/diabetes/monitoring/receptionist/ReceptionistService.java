package com.diabetes.monitoring.receptionist;

import com.diabetes.monitoring.receptionist.ReceptionistDAO.ReceptionistException;
import com.diabetes.monitoring.receptionist.ReceptionistDAO.ReceptionistRegistrationRequest;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class ReceptionistService {
    private static final Set<String> PAYMENT_METHODS = Set.of("Cash", "Momo", "VNPay", "Bank_Transfer");
    private static final Set<String> QUEUE_STATUSES = Set.of("Waiting", "Checked_In", "In_Progress");
    private final ReceptionistDAO dao = new ReceptionistDAO();

    public Map<String, Object> searchPatient(String keyword)
            throws SQLException, ReceptionistException {
        String normalizedKeyword = trim(keyword);
        if (!normalizedKeyword.matches("^(0|\\+84)[35789]\\d{8}$")) {
            Map<String, Object> patientByName = dao.findPatientByName(normalizedKeyword);
            if (patientByName == null) {
                throw new ReceptionistException("Khong tim thay benh nhan phu hop.");
            }
            return patientByName;
        }
        String normalizedPhone = normalizePhone(normalizedKeyword);
        if (!isVietnamesePhone(normalizedPhone)) {
            throw new ReceptionistException("Số điện thoại Việt Nam không hợp lệ.");
        }
        Map<String, Object> result = dao.findPatientByPhone(normalizedPhone);
        if (result == null) {
            throw new ReceptionistException("Không tìm thấy bệnh nhân với số điện thoại này.");
        }
        return result;
    }

    public List<Map<String, Object>> getDoctors() throws SQLException {
        return dao.findActiveDoctors();
    }

    public List<Map<String, Object>> getSchedules(int doctorId)
            throws SQLException, ReceptionistException {
        if (doctorId <= 0) {
            throw new ReceptionistException("Bác sĩ không hợp lệ.");
        }
        return dao.findAvailableSchedules(doctorId);
    }

    public Map<String, Object> createPatient(Map<String, String> params)
            throws SQLException, ReceptionistException {
        ReceptionistRegistrationRequest request = new ReceptionistRegistrationRequest();
        request.patientName = require(params, "patientName", "Vui lòng nhập họ tên bệnh nhân.");
        request.phone = normalizePhone(require(params, "patientPhone", "Vui lòng nhập số điện thoại."));
        if (!isVietnamesePhone(request.phone)) {
            throw new ReceptionistException("Số điện thoại Việt Nam không hợp lệ.");
        }
        request.email = require(params, "patientEmail", "Email is required to create a patient account.");
        if (!request.email.isEmpty() && !request.email.matches("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")) {
            throw new ReceptionistException("Email không hợp lệ.");
        }
        request.dateOfBirth = parseDate(require(params, "patientDob", "Vui lòng nhập ngày sinh."));
        if (request.dateOfBirth.isAfter(LocalDate.now()) || request.dateOfBirth.getYear() < 1900) {
            throw new ReceptionistException("Ngày sinh phải nằm trong khoảng từ năm 1900 đến hiện tại.");
        }
        request.gender = normalizeGender(params.get("patientGender"));
        request.address = trim(params.get("patientAddress"));
        Map<String, Object> patient = dao.createPatient(request);
        return patient;
    }

    public Map<String, Object> registerAppointment(Map<String, String> params)
            throws SQLException, ReceptionistException {
        ReceptionistRegistrationRequest request = new ReceptionistRegistrationRequest();
        request.patientName = require(params, "patientName", "Vui lòng nhập họ tên bệnh nhân.");
        request.phone = normalizePhone(require(params, "patientPhone", "Vui lòng nhập số điện thoại."));
        if (!isVietnamesePhone(request.phone)) {
            throw new ReceptionistException("Số điện thoại Việt Nam không hợp lệ.");
        }
        request.email = trim(params.get("patientEmail"));
        if (!request.email.isEmpty() && !request.email.matches("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")) {
            throw new ReceptionistException("Email không hợp lệ.");
        }
        request.dateOfBirth = parseDate(require(params, "patientDob", "Vui lòng nhập ngày sinh."));
        if (request.dateOfBirth.isAfter(LocalDate.now()) || request.dateOfBirth.getYear() < 1900) {
            throw new ReceptionistException("Ngày sinh phải nằm trong khoảng từ năm 1900 đến hiện tại.");
        }
        request.gender = normalizeGender(params.get("patientGender"));
        request.address = trim(params.get("patientAddress"));
        request.doctorId = parsePositiveInt(params.get("doctorId"), "Bác sĩ không hợp lệ.");
        request.scheduleId = parsePositiveInt(params.get("scheduleId"), "Ca khám không hợp lệ.");
        request.revisitAppointmentId = parseOptionalPositiveInt(params.get("revisitAppointmentId"));
        request.note = trim(params.get("note"));
        return dao.registerAppointment(request);
    }

    public Map<String, Object> getInvoiceStats() throws SQLException {
        return dao.getInvoiceStats();
    }

    public List<Map<String, Object>> getInvoices(String status, String invoiceType)
            throws SQLException, ReceptionistException {
        String normalized = "Paid".equalsIgnoreCase(status) ? "Paid" : "Pending";
        return dao.findInvoicesByStatus(normalized, invoiceType);
    }

    public List<Map<String, Object>> getInvoiceDetails(int invoiceId) throws SQLException {
        return dao.findInvoiceDetails(invoiceId);
    }

    public int payInvoice(String keyword, String paymentMethod, int receptionistAccountId)
            throws SQLException, ReceptionistException {
        if (!PAYMENT_METHODS.contains(paymentMethod)) {
            throw new ReceptionistException("Phương thức thanh toán không hợp lệ.");
        }
        return dao.payPendingInvoice(trim(keyword), paymentMethod, receptionistAccountId);
    }

    public List<Map<String, Object>> getTodayQueue(String status)
            throws SQLException, ReceptionistException {
        String normalized = trim(status);
        if (!normalized.isEmpty() && !QUEUE_STATUSES.contains(normalized)) {
            throw new ReceptionistException("Trạng thái hàng đợi không hợp lệ.");
        }
        return dao.findTodayQueue(normalized);
    }

    public void checkInAppointment(String appointmentId)
            throws SQLException, ReceptionistException {
        int parsedId = parsePositiveInt(appointmentId, "Lịch hẹn không hợp lệ.");
        if (!dao.checkInAppointment(parsedId)) {
            throw new ReceptionistException("Không thể check-in. Lịch hẹn không tồn tại, không phải hôm nay hoặc không còn ở trạng thái chờ khám.");
        }
    }

    public Map<String, Object> getAppointmentPreview(String appointmentId)
            throws SQLException, ReceptionistException {
        int parsedId = parsePositiveInt(appointmentId, "Lịch hẹn không hợp lệ.");
        Map<String, Object> preview = dao.findAppointmentPreview(parsedId);
        if (preview == null) {
            throw new ReceptionistException("Không tìm thấy lịch hẹn.");
        }
        return preview;
    }

    public List<Map<String, Object>> getAppointmentCalendar(String fromDate, String toDate)
            throws SQLException, ReceptionistException {
        LocalDate start = parseDate(fromDate);
        LocalDate end = parseDate(toDate);
        if (end.isBefore(start)) {
            throw new ReceptionistException("Khoảng thời gian không hợp lệ.");
        }
        return dao.findAppointmentsForCalendar(start, end);
    }

    public void reassignAppointment(String appointmentId, String doctorId, String scheduleId)
            throws SQLException, ReceptionistException {
        int parsedAppointmentId = parsePositiveInt(appointmentId, "Lịch hẹn không hợp lệ.");
        int parsedDoctorId = parsePositiveInt(doctorId, "Bác sĩ không hợp lệ.");
        int parsedScheduleId = parsePositiveInt(scheduleId, "Ca khám không hợp lệ.");
        if (!dao.reassignAppointment(parsedAppointmentId, parsedDoctorId, parsedScheduleId)) {
            throw new ReceptionistException("Không thể đổi bác sĩ/ca cho lịch hẹn này.");
        }
    }

    public void cancelAppointment(String appointmentId)
            throws SQLException, ReceptionistException {
        int parsedId = parsePositiveInt(appointmentId, "Lịch hẹn không hợp lệ.");
        if (!dao.cancelAppointment(parsedId)) {
            throw new ReceptionistException("Không thể hủy lịch hẹn này.");
        }
    }

    public List<Map<String, Object>> getMySchedule(int accountId, String fromDate, String toDate)
            throws SQLException, ReceptionistException {
        LocalDate start = parseDate(fromDate);
        LocalDate end = parseDate(toDate);
        if (end.isBefore(start)) {
            throw new ReceptionistException("Khoảng thời gian không hợp lệ.");
        }
        return dao.findMySchedule(accountId, start, end);
    }

    public void registerMySchedule(int accountId, String dateStr, String timeSlot) throws SQLException, ReceptionistException {
        if (dateStr == null || dateStr.isBlank()) {
            throw new ReceptionistException("Vui lòng chọn ngày trực.");
        }
        LocalDate workDate;
        try {
            workDate = LocalDate.parse(dateStr.trim());
        } catch (DateTimeParseException e) {
            throw new ReceptionistException("Ngày trực không đúng định dạng YYYY-MM-DD.");
        }
        if (workDate.isBefore(LocalDate.now())) {
            throw new ReceptionistException("Không thể đăng ký lịch trực trong quá khứ.");
        }
        String slot = trim(timeSlot);
        if (slot.isEmpty()) {
            throw new ReceptionistException("Vui lòng chọn ca trực.");
        }
        dao.registerMySchedule(accountId, workDate, slot);
    }

    private String require(Map<String, String> params, String key, String message)
            throws ReceptionistException {
        String value = trim(params.get(key));
        if (value.isEmpty()) {
            throw new ReceptionistException(message);
        }
        return value;
    }

    private int parsePositiveInt(String value, String message) throws ReceptionistException {
        try {
            int parsed = Integer.parseInt(trim(value));
            if (parsed > 0) {
                return parsed;
            }
        } catch (NumberFormatException ignored) {
        }
        throw new ReceptionistException(message);
    }

    public List<Map<String, Object>> getUpcomingRevisits(LocalDate date) throws SQLException {
        return dao.findUpcomingRevisits(date);
    }

    private int parseOptionalPositiveInt(String value) {
        try {
            int parsed = Integer.parseInt(trim(value));
            return parsed > 0 ? parsed : 0;
        } catch (NumberFormatException ignored) {
            return 0;
        }
    }

    private LocalDate parseDate(String value) throws ReceptionistException {
        try {
            return LocalDate.parse(value);
        } catch (DateTimeParseException e) {
            throw new ReceptionistException("Ngày sinh không hợp lệ.");
        }
    }

    private String normalizeGender(String value) {
        String normalized = trim(value);
        if ("Female".equalsIgnoreCase(normalized)) {
            return "Female";
        }
        if ("Other".equalsIgnoreCase(normalized)) {
            return "Other";
        }
        return "Male";
    }

    private String normalizePhone(String phone) {
        String normalized = trim(phone).replace(" ", "");
        if (normalized.startsWith("+84")) {
            return "0" + normalized.substring(3);
        }
        return normalized;
    }

    private boolean isVietnamesePhone(String phone) {
        return phone != null && phone.matches("^0(3|5|7|8|9)\\d{8}$");
    }

    private String trim(String value) {
        return value == null ? "" : value.trim();
    }
}
