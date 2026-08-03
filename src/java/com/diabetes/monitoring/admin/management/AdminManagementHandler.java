package com.diabetes.monitoring.admin.management;

import com.diabetes.monitoring.model.User;
import com.diabetes.monitoring.util.PasswordUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.Map;

/**
 * Dispatches account and medical service management requests.
 */
public class AdminManagementHandler {
    private final AdminAccountHandler accountHandler = new AdminAccountHandler();
    private final AdminMedicalServiceHandler medicalServiceHandler = new AdminMedicalServiceHandler();
    private final AdminRoomHandler roomHandler = new AdminRoomHandler();

    public void loadAccounts(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException { accountHandler.loadAccounts(request, response); }
    public void createAccount(HttpServletRequest request, HttpServletResponse response) throws IOException { accountHandler.createAccount(request, response); }
    public void updateAccountRole(HttpServletRequest request, HttpServletResponse response) throws IOException { accountHandler.updateAccountRole(request, response); }
    public void updateAccountStatus(HttpServletRequest request, HttpServletResponse response, String targetStatus) throws IOException { accountHandler.updateAccountStatus(request, response, targetStatus); }
    public void deleteAccount(HttpServletRequest request, HttpServletResponse response) throws IOException { accountHandler.deleteAccount(request, response); }
    public void updateAccountProfile(HttpServletRequest request, HttpServletResponse response) throws IOException { accountHandler.updateAccountProfile(request, response); }
    public void updateAccountPassword(HttpServletRequest request, HttpServletResponse response) throws IOException { accountHandler.updateAccountPassword(request, response); }
    public void ajaxToggleAccountStatus(HttpServletRequest request, HttpServletResponse response) throws IOException { accountHandler.ajaxToggleAccountStatus(request, response); }
    public void loadAccountProfile(HttpServletRequest request, HttpServletResponse response) throws IOException { accountHandler.loadAccountProfile(request, response); }
    public void loadServices(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException { medicalServiceHandler.loadServices(request, response); }
    public void createService(HttpServletRequest request, HttpServletResponse response) throws IOException { medicalServiceHandler.createService(request, response); }
    public void updateService(HttpServletRequest request, HttpServletResponse response) throws IOException { medicalServiceHandler.updateService(request, response); }
    public void updateServiceStatus(HttpServletRequest request, HttpServletResponse response) throws IOException { medicalServiceHandler.updateServiceStatus(request, response); }
    public void deleteService(HttpServletRequest request, HttpServletResponse response) throws IOException { medicalServiceHandler.deleteService(request, response); }

    public void loadRooms(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException { roomHandler.loadRooms(request, response); }
    public void createRoom(HttpServletRequest request, HttpServletResponse response) throws IOException { roomHandler.createRoom(request, response); }
    public void updateRoom(HttpServletRequest request, HttpServletResponse response) throws IOException { roomHandler.updateRoom(request, response); }
    public void deleteRoom(HttpServletRequest request, HttpServletResponse response) throws IOException { roomHandler.deleteRoom(request, response); }
}

/**
 * Handles Admin account management screens and actions.
 */
class AdminAccountHandler {
    private final AdminManagementService accountService = new AdminManagementService();

    public void loadAccounts(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String search = request.getParameter("search");
        String role = request.getParameter("role");
        String status = request.getParameter("status");

        int page = parseInt(request.getParameter("page"), 1);
        int pageSize = parseInt(request.getParameter("pageSize"), 10);

        int totalRecords = accountService.getAccountsTotalCount(search, role, status);
        int totalPages = (int) Math.ceil((double) totalRecords / pageSize);
        if (totalPages <= 0) totalPages = 1;
        if (page > totalPages) page = totalPages;

        request.setAttribute("users", accountService.loadAccounts(search, role, status, page, pageSize));
        request.setAttribute("currentPage", page);
        request.setAttribute("pageSize", pageSize);
        request.setAttribute("totalPages", totalPages);
        request.setAttribute("totalRecords", totalRecords);
        request.setAttribute("search", search);
        request.setAttribute("role", role);
        request.setAttribute("status", status);

        request.getRequestDispatcher("/WEB-INF/views/admin/users/users.jsp").forward(request, response);
    }
    public void createAccount(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String fullName = request.getParameter("fullName");
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        String role = request.getParameter("role");
        String specialization = request.getParameter("specialization");
        String normalizedEmail = email == null ? "" : email.trim();

        if (fullName == null || fullName.isBlank() || normalizedEmail.isBlank() || password == null || password.isBlank()) {
            request.getSession().setAttribute("errorMessage", "Vui lòng nhập đầy đủ họ tên, email và mật khẩu");
            response.sendRedirect(request.getContextPath() + "/admin?action=listUsers");
            return;
        }

        if (password.length() < 6) {
            request.getSession().setAttribute("errorMessage", "Mật khẩu phải chứa ít nhất 6 ký tự.");
            response.sendRedirect(request.getContextPath() + "/admin?action=listUsers");
            return;
        }

        if (!isAllowedRole(role)) {
            request.getSession().setAttribute("errorMessage", "Vai trò không hợp lệ theo FR-ADM-02");
            response.sendRedirect(request.getContextPath() + "/admin?action=listUsers");
            return;
        }

        try {
            User currentUser = (User) request.getSession().getAttribute("currentUser");
            boolean created = accountService.createAccount(fullName, normalizedEmail, PasswordUtil.hashPassword(password), role, "active", specialization, currentUser);
            if (created) {
                com.diabetes.monitoring.util.EmailUtil.sendAccountDetailsAsync(normalizedEmail, fullName, password);
                request.getSession().setAttribute("successMessage", "Đã tạo tài khoản thành công! Hệ thống đang gửi email thông tin đăng nhập tới " + normalizedEmail);
            } else {
                request.getSession().setAttribute("errorMessage", "Không thể tạo tài khoản (Email đã tồn tại hoặc thông tin không hợp lệ)");
            }
        } catch (IllegalArgumentException | SecurityException ex) {
            request.getSession().setAttribute("errorMessage", ex.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/admin?action=listUsers");
    }
    public void updateAccountRole(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int accountId = parseInt(request.getParameter("accountId"), -1);
        String role = request.getParameter("role");
        try {
            User currentUser = (User) request.getSession().getAttribute("currentUser");
            boolean ok = accountId > 0 && accountService.updateAccountRole(accountId, role, currentUser);
            request.getSession().setAttribute(ok ? "successMessage" : "errorMessage",
                    ok ? "Đã cập nhật phân quyền tài khoản" : "Không thể cập nhật phân quyền");
        } catch (SecurityException ex) {
            request.getSession().setAttribute("errorMessage", ex.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/admin?action=listUsers");
    }
    public void updateAccountStatus(HttpServletRequest request, HttpServletResponse response, String targetStatus) throws IOException {
        int accountId = parseInt(request.getParameter("accountId"), -1);
        try {
            User currentUser = (User) request.getSession().getAttribute("currentUser");
            boolean ok = accountId > 0 && accountService.updateAccountStatus(accountId, targetStatus, currentUser);
            request.getSession().setAttribute(ok ? "successMessage" : "errorMessage",
                    ok ? ("locked".equals(targetStatus) ? "Đã khóa tài khoản" : "Đã kích hoạt lại tài khoản")
                            : "Không thể cập nhật trạng thái tài khoản");
        } catch (SecurityException ex) {
            request.getSession().setAttribute("errorMessage", ex.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/admin?action=listUsers");
    }
    public void deleteAccount(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int accountId = parseInt(request.getParameter("accountId"), -1);
        try {
            User currentUser = (User) request.getSession().getAttribute("currentUser");
            boolean ok = accountId > 0 && accountService.deleteAccount(accountId, currentUser);
            request.getSession().setAttribute(ok ? "successMessage" : "errorMessage",
                    ok ? "Đã khóa (xóa mềm) tài khoản thành công" : "Không thể xóa tài khoản");
        } catch (SecurityException ex) {
            request.getSession().setAttribute("errorMessage", ex.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/admin?action=listUsers");
    }
    public void updateAccountProfile(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int accountId = parseInt(request.getParameter("accountId"), -1);
        String fullName = request.getParameter("fullName");
        String email = request.getParameter("email");
        String phone = request.getParameter("phone");
        String address = request.getParameter("address");
        String department = request.getParameter("department");

        if (accountId <= 0 || fullName == null || fullName.isBlank() || email == null || email.isBlank()) {
            request.getSession().setAttribute("errorMessage", "Vui lòng nhập đầy đủ họ tên và email hợp lệ");
            response.sendRedirect(request.getContextPath() + "/admin?action=listUsers");
            return;
        }

        if (phone != null && !phone.isBlank()) {
            String cleanedPhone = phone.trim().replaceAll("[\\s.\\-()]", "");
            if (!cleanedPhone.matches("^(0|\\+84)(3|5|7|8|9)\\d{8}$")) {
                request.getSession().setAttribute("errorMessage", "Số điện thoại không hợp lệ. Vui lòng nhập số di động Việt Nam hợp lệ (ví dụ: 0912345678 hoặc +84912345678)");
                response.sendRedirect(request.getContextPath() + "/admin?action=listUsers");
                return;
            }
        }

        try {
            User currentUser = (User) request.getSession().getAttribute("currentUser");
            boolean ok = accountId > 0 && accountService.updateAccountProfileByRole(accountId, fullName, email, phone, address, department, currentUser);
            request.getSession().setAttribute(ok ? "successMessage" : "errorMessage",
                    ok ? "Đã cập nhật hồ sơ tài khoản" : "Không thể cập nhật hồ sơ tài khoản");
        } catch (IllegalArgumentException | SecurityException ex) {
            request.getSession().setAttribute("errorMessage", ex.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/admin?action=listUsers");
    }

    public void updateAccountPassword(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int accountId = parseInt(request.getParameter("accountId"), -1);
        String newPassword = request.getParameter("newPassword");

        if (accountId <= 0 || newPassword == null || newPassword.trim().isEmpty()) {
            request.getSession().setAttribute("errorMessage", "Vui lòng nhập mật khẩu mới hợp lệ");
            response.sendRedirect(request.getContextPath() + "/admin?action=listUsers");
            return;
        }

        try {
            User currentUser = (User) request.getSession().getAttribute("currentUser");
            boolean ok = accountService.updateAccountPassword(accountId, newPassword, currentUser);
            request.getSession().setAttribute(ok ? "successMessage" : "errorMessage",
                    ok ? "Đã thay đổi mật khẩu tài khoản thành công" : "Không thể thay đổi mật khẩu tài khoản");
        } catch (IllegalArgumentException | SecurityException ex) {
            request.getSession().setAttribute("errorMessage", ex.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/admin?action=listUsers");
    }
    public void ajaxToggleAccountStatus(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int accountId = parseInt(request.getParameter("accountId"), -1);
        String status = request.getParameter("status");
        boolean ok = false;
        try {
            User currentUser = (User) request.getSession().getAttribute("currentUser");
            ok = accountId > 0 && accountService.updateAccountStatus(accountId, status, currentUser);
        } catch (SecurityException ignored) {
        }

        response.setContentType("application/json;charset=UTF-8");
        try (java.io.PrintWriter out = response.getWriter()) {
            out.print("{\"success\":");
            out.print(ok);
            out.print(",\"activeAccounts\":");
            out.print(accountService.loadAccounts(null, null, "active", 1, 1000).size());
            out.print(",\"lockedAccounts\":");
            out.print(accountService.loadAccounts(null, null, "locked", 1, 1000).size());
            out.print("}");
        }
    }
    public void loadAccountProfile(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        int accountId = parseInt(request.getParameter("accountId"), -1);
        Map<String, Object> profile = accountId > 0 ? accountService.getAccountProfile(accountId) : null;
        try (java.io.PrintWriter out = response.getWriter()) {
            if (profile == null) {
                out.print("{\"success\":false,\"message\":\"Không tìm thấy tài khoản\"}");
                return;
            }
            out.print("{\"success\":true,\"item\":{");
            out.print("\"accountId\":" + profile.getOrDefault("accountId", 0));
            out.print(",\"fullName\":\"" + escape(String.valueOf(profile.getOrDefault("fullName", ""))) + "\"");
            out.print(",\"email\":\"" + escape(String.valueOf(profile.getOrDefault("email", ""))) + "\"");
            out.print(",\"role\":\"" + escape(String.valueOf(profile.getOrDefault("role", ""))) + "\"");
            out.print(",\"phone\":\"" + escape(String.valueOf(profile.getOrDefault("phone", ""))) + "\"");
            out.print(",\"address\":\"" + escape(String.valueOf(profile.getOrDefault("address", ""))) + "\"");
            out.print(",\"department\":\"" + escape(String.valueOf(profile.getOrDefault("department", ""))) + "\"");
            out.print(",\"status\":\"" + escape(String.valueOf(profile.getOrDefault("status", ""))) + "\"");
            out.print("}}");
        }
    }
    private boolean isAllowedRole(String role) {
        return role != null && ("admin".equalsIgnoreCase(role)
                || "receptionist".equalsIgnoreCase(role)
                || "doctor".equalsIgnoreCase(role)
                || "doctor_lab".equalsIgnoreCase(role));
    }
    private int parseInt(String raw, int fallback) {
        try {
            return Integer.parseInt(raw);
        } catch (Exception ex) {
            return fallback;
        }
    }
    private String escape(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n");
    }
}

/**
 * Handles medical service catalog screens and actions.
 */
class AdminMedicalServiceHandler {
    private final AdminManagementService medicalServiceService = new AdminManagementService();

    public void loadServices(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String search = request.getParameter("search");
        String serviceType = request.getParameter("serviceType");
        String status = request.getParameter("status");

        int page = parseInt(request.getParameter("page"), 1);
        int pageSize = parseInt(request.getParameter("pageSize"), 10);

        int totalRecords = medicalServiceService.getMedicalServicesCount(search, serviceType, status);
        int totalPages = (int) Math.ceil((double) totalRecords / pageSize);
        if (totalPages <= 0) totalPages = 1;
        if (page > totalPages) page = totalPages;

        request.setAttribute("services", medicalServiceService.loadServices(search, serviceType, status, page, pageSize));
        request.setAttribute("currentPage", page);
        request.setAttribute("pageSize", pageSize);
        request.setAttribute("totalPages", totalPages);
        request.setAttribute("totalRecords", totalRecords);
        request.setAttribute("search", search);
        request.setAttribute("serviceType", serviceType);
        request.setAttribute("status", status);

        request.getRequestDispatcher("/WEB-INF/views/admin/services/services.jsp").forward(request, response);
    }
    public void createService(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String serviceName = request.getParameter("serviceName");
        String serviceType = request.getParameter("serviceType");
        String status = request.getParameter("status");
        BigDecimal price = parseBigDecimal(request.getParameter("price"));

        if (serviceName == null || serviceName.isBlank() || price == null || price.compareTo(BigDecimal.ZERO) < 0) {
            request.getSession().setAttribute("errorMessage", "Tên dịch vụ không được trống và đơn giá phải >= 0");
            response.sendRedirect(request.getContextPath() + "/admin?action=manageServices");
            return;
        }

        try {
            User currentUser = (User) request.getSession().getAttribute("currentUser");
            boolean ok = medicalServiceService.createService(serviceName, price, serviceType, status, currentUser);
            request.getSession().setAttribute(ok ? "successMessage" : "errorMessage",
                    ok ? "Đã thêm dịch vụ y tế" : "Không thể thêm dịch vụ y tế");
        } catch (IllegalArgumentException | SecurityException ex) {
            request.getSession().setAttribute("errorMessage", ex.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/admin?action=manageServices");
    }
    public void updateService(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int serviceId = parseInt(request.getParameter("serviceId"), -1);
        String serviceName = request.getParameter("serviceName");
        String serviceType = request.getParameter("serviceType");
        String status = request.getParameter("status");
        BigDecimal price = parseBigDecimal(request.getParameter("price"));

        if (serviceId <= 0 || serviceName == null || serviceName.isBlank() || price == null || price.compareTo(BigDecimal.ZERO) < 0) {
            request.getSession().setAttribute("errorMessage", "Dữ liệu dịch vụ không hợp lệ");
            response.sendRedirect(request.getContextPath() + "/admin?action=manageServices");
            return;
        }

        try {
            User currentUser = (User) request.getSession().getAttribute("currentUser");
            boolean ok = serviceId > 0 && medicalServiceService.updateService(serviceId, serviceName, price, serviceType, status, currentUser);
            request.getSession().setAttribute(ok ? "successMessage" : "errorMessage",
                    ok ? "Đã cập nhật dịch vụ y tế" : "Không thể cập nhật dịch vụ y tế");
        } catch (IllegalArgumentException | SecurityException ex) {
            request.getSession().setAttribute("errorMessage", ex.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/admin?action=manageServices");
    }
    public void updateServiceStatus(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int serviceId = parseInt(request.getParameter("serviceId"), -1);
        String status = request.getParameter("status");
        try {
            User currentUser = (User) request.getSession().getAttribute("currentUser");
            boolean ok = serviceId > 0 && medicalServiceService.updateServiceStatus(serviceId, status, currentUser);
            request.getSession().setAttribute(ok ? "successMessage" : "errorMessage",
                    ok ? "Đã cập nhật trạng thái dịch vụ" : "Không thể cập nhật trạng thái dịch vụ");
        } catch (SecurityException ex) {
            request.getSession().setAttribute("errorMessage", ex.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/admin?action=manageServices");
    }
    public void deleteService(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int serviceId = parseInt(request.getParameter("serviceId"), -1);
        try {
            User currentUser = (User) request.getSession().getAttribute("currentUser");
            boolean ok = serviceId > 0 && medicalServiceService.deleteService(serviceId, currentUser);
            request.getSession().setAttribute(ok ? "successMessage" : "errorMessage",
                    ok ? "Đã xóa mềm dịch vụ y tế thành công" : "Không thể xóa dịch vụ y tế");
        } catch (SecurityException ex) {
            request.getSession().setAttribute("errorMessage", ex.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/admin?action=manageServices");
    }
    private int parseInt(String raw, int fallback) {
        try {
            return Integer.parseInt(raw);
        } catch (Exception ex) {
            return fallback;
        }
    }
    private BigDecimal parseBigDecimal(String raw) {
        try {
            return raw == null || raw.isBlank() ? BigDecimal.ZERO : new BigDecimal(raw);
        } catch (Exception ex) {
            return BigDecimal.ZERO;
        }
    }
}


/**
 * Handles Admin Room CRUD screens and actions.
 */
class AdminRoomHandler {
    private final com.diabetes.monitoring.admin.scheduling.AdminRoomRepository roomRepository =
            new com.diabetes.monitoring.admin.scheduling.AdminRoomRepository();

    public void loadRooms(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String search = request.getParameter("search");
        String status = request.getParameter("status");
        request.setAttribute("rooms", roomRepository.getAllRooms(search, status));
        request.getRequestDispatcher("/WEB-INF/views/admin/rooms/rooms.jsp").forward(request, response);
    }

    public void createRoom(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String roomId = request.getParameter("roomId");
        String roomName = request.getParameter("roomName");
        String location = request.getParameter("location");
        String status = request.getParameter("status");

        if (roomId == null || roomId.isBlank() || roomName == null || roomName.isBlank()) {
            request.getSession().setAttribute("errorMessage", "Mã phòng và tên phòng không được trống");
            response.sendRedirect(request.getContextPath() + "/admin?action=manageRooms");
            return;
        }

        boolean ok = roomRepository.createRoom(roomId, roomName, location, status);
        request.getSession().setAttribute(ok ? "successMessage" : "errorMessage",
                ok ? "Đã thêm phòng khám thành công" : "Không thể thêm phòng khám");
        response.sendRedirect(request.getContextPath() + "/admin?action=manageRooms");
    }

    public void updateRoom(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String roomId = request.getParameter("roomId");
        String roomName = request.getParameter("roomName");
        String location = request.getParameter("location");
        String status = request.getParameter("status");

        if (roomId == null || roomId.isBlank() || roomName == null || roomName.isBlank()) {
            request.getSession().setAttribute("errorMessage", "Thông tin phòng không hợp lệ");
            response.sendRedirect(request.getContextPath() + "/admin?action=manageRooms");
            return;
        }

        boolean ok = roomRepository.updateRoom(roomId, roomName, location, status);
        request.getSession().setAttribute(ok ? "successMessage" : "errorMessage",
                ok ? "Đã cập nhật phòng khám thành công" : "Không thể cập nhật phòng khám");
        response.sendRedirect(request.getContextPath() + "/admin?action=manageRooms");
    }

    public void deleteRoom(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String roomId = request.getParameter("roomId");
        if (roomId == null || roomId.isBlank()) {
            request.getSession().setAttribute("errorMessage", "Mã phòng không hợp lệ");
            response.sendRedirect(request.getContextPath() + "/admin?action=manageRooms");
            return;
        }

        boolean ok = roomRepository.deleteRoom(roomId);
        request.getSession().setAttribute(ok ? "successMessage" : "errorMessage",
                ok ? "Đã xóa mềm phòng khám thành công" : "Không thể xóa phòng khám");
        response.sendRedirect(request.getContextPath() + "/admin?action=manageRooms");
    }
}
