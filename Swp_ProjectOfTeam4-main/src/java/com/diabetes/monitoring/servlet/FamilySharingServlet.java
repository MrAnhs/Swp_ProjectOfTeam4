package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.dao.RecordSharingDAO;
import com.diabetes.monitoring.model.RecordSharing;
import com.diabetes.monitoring.model.User;
import com.diabetes.monitoring.notification.NotificationDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

public class FamilySharingServlet extends HttpServlet {
    private final RecordSharingDAO sharingDAO = new RecordSharingDAO();
    private final NotificationDAO notificationDAO = new NotificationDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json;charset=UTF-8");
        User user = getCurrentUser(request, response);
        if (user == null) return;

        try {
            List<RecordSharing> following = sharingDAO.findByViewerAccountId(user.getId());
            List<RecordSharing> followers = sharingDAO.findByOwnerAccountId(user.getId());

            StringBuilder json = new StringBuilder();
            json.append("{\"success\":true,\"currentUserId\":").append(user.getId());
            json.append(",\"following\":").append(listToJson(following));
            json.append(",\"followers\":").append(listToJson(followers));
            json.append("}");

            response.getWriter().print(json.toString());
        } catch (SQLException e) {
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().print("{\"success\":false,\"message\":\"Lỗi hệ thống khi tải danh sách chia sẻ.\"}");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json;charset=UTF-8");
        User user = getCurrentUser(request, response);
        if (user == null) return;

        String action = request.getParameter("action");
        if (action == null) {
            writeError(response, "Hành động không hợp lệ.");
            return;
        }

        try {
            switch (action) {
                case "request_follow":
                    handleRequestFollow(request, response, user);
                    break;
                case "invite_follow":
                    handleInviteFollow(request, response, user);
                    break;
                case "accept":
                    handleAccept(request, response, user);
                    break;
                case "reject":
                    handleReject(request, response, user);
                    break;
                case "delete":
                    handleDelete(request, response, user);
                    break;
                default:
                    writeError(response, "Hành động không được hỗ trợ.");
                    break;
            }
        } catch (SQLException e) {
            e.printStackTrace();
            writeError(response, "Lỗi cơ sở dữ liệu: " + e.getMessage());
        }
    }

    private void handleRequestFollow(HttpServletRequest request, HttpServletResponse response, User user)
            throws SQLException, IOException {
        String email = request.getParameter("email");
        if (email == null || email.trim().isEmpty()) {
            writeError(response, "Vui lòng nhập Email người muốn theo dõi.");
            return;
        }
        email = email.trim();

        if (email.equalsIgnoreCase(user.getEmail())) {
            writeError(response, "Không thể tự chia sẻ hoặc theo dõi chính mình.");
            return;
        }

        Map<String, Object> targetAcc = sharingDAO.findAccountByEmail(email);
        if (targetAcc == null || !"Patient".equalsIgnoreCase((String) targetAcc.get("role"))) {
            writeError(response, "Đối tượng không tồn tại.");
            return;
        }

        int targetAccountId = (int) targetAcc.get("accountId");
        if (sharingDAO.existsSharing(targetAccountId, user.getId())) {
            writeError(response, "Yêu cầu liên kết giữa 2 tài khoản đã tồn tại.");
            return;
        }

        boolean created = sharingDAO.createSharing(targetAccountId, user.getId(), user.getId(), false, false, false);
        if (created) {
            notificationDAO.sendNotification(targetAccountId,
                    "Yêu cầu theo dõi hồ sơ",
                    "Tài khoản " + user.getEmail() + " đã gửi yêu cầu muốn theo dõi hồ sơ y tế gia đình của bạn.",
                    "SYSTEM",
                    "/patient/family-sharing");
            notificationDAO.sendNotification(user.getId(),
                    "Đã tạo yêu cầu theo dõi",
                    "Bạn đã gửi yêu cầu xin phép theo dõi hồ sơ y tế gia đình của tài khoản " + email + ".",
                    "SYSTEM",
                    "/patient/family-sharing");
            writeSuccess(response, "Đã gửi yêu cầu xin phép theo dõi thành công!");
        } else {
            writeError(response, "Không thể gửi yêu cầu.");
        }
    }

    private void handleInviteFollow(HttpServletRequest request, HttpServletResponse response, User user)
            throws SQLException, IOException {
        String email = request.getParameter("email");
        if (email == null || email.trim().isEmpty()) {
            writeError(response, "Vui lòng nhập Email người mời.");
            return;
        }
        email = email.trim();

        if (email.equalsIgnoreCase(user.getEmail())) {
            writeError(response, "Không thể tự chia sẻ hoặc theo dõi chính mình.");
            return;
        }

        Map<String, Object> targetAcc = sharingDAO.findAccountByEmail(email);
        if (targetAcc == null || !"Patient".equalsIgnoreCase((String) targetAcc.get("role"))) {
            writeError(response, "Đối tượng không tồn tại.");
            return;
        }

        int targetAccountId = (int) targetAcc.get("accountId");
        if (sharingDAO.existsSharing(user.getId(), targetAccountId)) {
            writeError(response, "Yêu cầu liên kết giữa 2 tài khoản đã tồn tại.");
            return;
        }

        boolean appts = "true".equalsIgnoreCase(request.getParameter("canViewAppointments")) || "on".equalsIgnoreCase(request.getParameter("canViewAppointments"));
        boolean invoices = "true".equalsIgnoreCase(request.getParameter("canViewInvoices")) || "on".equalsIgnoreCase(request.getParameter("canViewInvoices"));
        boolean records = "true".equalsIgnoreCase(request.getParameter("canViewRecords")) || "on".equalsIgnoreCase(request.getParameter("canViewRecords"));

        boolean created = sharingDAO.createSharing(user.getId(), targetAccountId, user.getId(), appts, invoices, records);
        if (created) {
            notificationDAO.sendNotification(targetAccountId,
                    "Lời mời chia sẻ hồ sơ",
                    "Tài khoản " + user.getEmail() + " đã mời bạn xem hồ sơ y tế gia đình.",
                    "SYSTEM",
                    "/patient/family-sharing");
            notificationDAO.sendNotification(user.getId(),
                    "Đã tạo lời mời chia sẻ",
                    "Bạn đã gửi lời mời xem hồ sơ y tế gia đình của bạn cho tài khoản " + email + ".",
                    "SYSTEM",
                    "/patient/family-sharing");
            writeSuccess(response, "Đã gửi lời mời theo dõi thành công!");
        } else {
            writeError(response, "Không thể gửi lời mời.");
        }
    }

    private void handleAccept(HttpServletRequest request, HttpServletResponse response, User user)
            throws SQLException, IOException {
        int sharingId = Integer.parseInt(request.getParameter("sharingId"));
        RecordSharing sharing = sharingDAO.getSharingById(sharingId);
        if (sharing == null) {
            writeError(response, "Không tìm thấy thông tin chia sẻ.");
            return;
        }

        boolean updated;
        if (user.getId() == sharing.getOwnerAccountId()) {
            // Owner is accepting a request from Viewer -> Update permissions
            boolean appts = "true".equalsIgnoreCase(request.getParameter("canViewAppointments")) || "on".equalsIgnoreCase(request.getParameter("canViewAppointments"));
            boolean invoices = "true".equalsIgnoreCase(request.getParameter("canViewInvoices")) || "on".equalsIgnoreCase(request.getParameter("canViewInvoices"));
            boolean records = "true".equalsIgnoreCase(request.getParameter("canViewRecords")) || "on".equalsIgnoreCase(request.getParameter("canViewRecords"));
            updated = sharingDAO.updatePermissionsAndAccept(sharingId, appts, invoices, records, user.getId());
        } else {
            // Viewer is accepting an invite from Owner
            updated = sharingDAO.updateStatus(sharingId, "ACCEPTED", user.getId());
        }

        if (updated) {
            int targetUserId = (user.getId() == sharing.getOwnerAccountId()) ? sharing.getViewerAccountId() : sharing.getOwnerAccountId();
            notificationDAO.sendNotification(targetUserId,
                    "Chấp nhận chia sẻ hồ sơ",
                    "Yêu cầu liên kết hồ sơ y tế gia đình của bạn với tài khoản " + user.getEmail() + " đã được chấp nhận.",
                    "SYSTEM",
                    "/patient/family-sharing");
            writeSuccess(response, "Đã đồng ý chấp nhận liên kết hồ sơ!");
        } else {
            writeError(response, "Không thể cập nhật trạng thái.");
        }
    }

    private void handleReject(HttpServletRequest request, HttpServletResponse response, User user)
            throws SQLException, IOException {
        int sharingId = Integer.parseInt(request.getParameter("sharingId"));
        RecordSharing sharing = sharingDAO.getSharingById(sharingId);
        if (sharing == null) {
            writeError(response, "Không tìm thấy thông tin chia sẻ.");
            return;
        }

        boolean updated = sharingDAO.updateStatus(sharingId, "REJECTED", user.getId());
        if (updated) {
            // Notify the initiator that their request was rejected
            notificationDAO.sendNotification(sharing.getInitiatorAccountId(),
                    "Từ chối chia sẻ hồ sơ",
                    "Yêu cầu chia sẻ/theo dõi hồ sơ y tế với tài khoản " + user.getEmail() + " đã bị từ chối.",
                    "SYSTEM",
                    "/patient/family-sharing");
            writeSuccess(response, "Đã từ chối yêu cầu thành công!");
        } else {
            writeError(response, "Không thể cập nhật trạng thái.");
        }
    }

    private void handleDelete(HttpServletRequest request, HttpServletResponse response, User user)
            throws SQLException, IOException {
        int sharingId = Integer.parseInt(request.getParameter("sharingId"));
        boolean deleted = sharingDAO.deleteSharing(sharingId, user.getId());
        if (deleted) {
            writeSuccess(response, "Đã xóa bản ghi lịch sử chia sẻ!");
        } else {
            writeError(response, "Không thể xóa bản ghi.");
        }
    }

    private User getCurrentUser(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        User user = session == null ? null : (User) session.getAttribute("currentUser");
        if (user == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().print("{\"success\":false,\"message\":\"Phiên đăng nhập đã hết hạn.\"}");
        }
        return user;
    }

    private void writeError(HttpServletResponse response, String message) throws IOException {
        response.getWriter().print("{\"success\":false,\"message\":\"" + escapeJson(message) + "\"}");
    }

    private void writeSuccess(HttpServletResponse response, String message) throws IOException {
        response.getWriter().print("{\"success\":true,\"message\":\"" + escapeJson(message) + "\"}");
    }

    private String listToJson(List<RecordSharing> list) {
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < list.size(); i++) {
            RecordSharing r = list.get(i);
            if (i > 0) sb.append(",");
            sb.append("{");
            sb.append("\"sharingId\":").append(r.getSharingId()).append(",");
            sb.append("\"ownerAccountId\":").append(r.getOwnerAccountId()).append(",");
            sb.append("\"viewerAccountId\":").append(r.getViewerAccountId()).append(",");
            sb.append("\"initiatorAccountId\":").append(r.getInitiatorAccountId()).append(",");
            sb.append("\"canViewAppointments\":").append(r.isCanViewAppointments()).append(",");
            sb.append("\"canViewInvoices\":").append(r.isCanViewInvoices()).append(",");
            sb.append("\"canViewRecords\":").append(r.isCanViewRecords()).append(",");
            sb.append("\"status\":\"").append(escapeJson(r.getStatus())).append("\",");
            sb.append("\"createdAt\":\"").append(r.getCreatedAt() != null ? r.getCreatedAt().toString() : "").append("\",");
            sb.append("\"ownerName\":\"").append(escapeJson(r.getOwnerName())).append("\",");
            sb.append("\"ownerEmail\":\"").append(escapeJson(r.getOwnerEmail())).append("\",");
            sb.append("\"viewerName\":\"").append(escapeJson(r.getViewerName())).append("\",");
            sb.append("\"viewerEmail\":\"").append(escapeJson(r.getViewerEmail())).append("\",");
            sb.append("\"initiatorName\":\"").append(escapeJson(r.getInitiatorName())).append("\",");
            sb.append("\"initiatorEmail\":\"").append(escapeJson(r.getInitiatorEmail())).append("\",");
            sb.append("\"ownerPatientId\":").append(r.getOwnerPatientId() != null ? r.getOwnerPatientId() : "null");
            sb.append("}");
        }
        sb.append("]");
        return sb.toString();
    }

    private String escapeJson(String str) {
        if (str == null) return "";
        return str.replace("\\", "\\\\")
                  .replace("\"", "\\\"")
                  .replace("\b", "\\b")
                  .replace("\f", "\\f")
                  .replace("\n", "\\n")
                  .replace("\r", "\\r")
                  .replace("\t", "\\t");
    }
}
