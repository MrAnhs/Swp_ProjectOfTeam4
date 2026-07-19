package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.dao.PatientInvoiceDAO;
import com.diabetes.monitoring.model.InvoiceInfo;
import com.diabetes.monitoring.model.User;
import com.diabetes.monitoring.util.VnPayConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;
import java.text.SimpleDateFormat;
import java.util.*;

public class VnPayController extends HttpServlet {
    private final PatientInvoiceDAO invoiceDAO = new PatientInvoiceDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = (User) request.getSession().getAttribute("currentUser");
        if (user == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Bạn chưa đăng nhập.");
            return;
        }

        String invoiceIdParam = request.getParameter("invoiceId");
        if (invoiceIdParam == null || invoiceIdParam.trim().isEmpty()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Mã hóa đơn không hợp lệ.");
            return;
        }

        try {
            int invoiceId = Integer.parseInt(invoiceIdParam);
            InvoiceInfo invoice = invoiceDAO.findById(invoiceId, user.getId());
            if (invoice == null) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Không tìm thấy hóa đơn hoặc bạn không có quyền truy cập.");
                return;
            }

            if (!"Pending".equalsIgnoreCase(invoice.getStatus())) {
                response.sendError(HttpServletResponse.SC_CONFLICT, "Hóa đơn này đã được thanh toán hoặc không ở trạng thái chờ.");
                return;
            }

            // Ghi nhận phương thức thanh toán là VNPay trong cơ sở dữ liệu trước khi chuyển hướng
            invoiceDAO.requestPayment(invoiceId, user.getId(), "VNPay");

            // Tính số tiền thanh toán (nhân với 100 và chuyển thành kiểu số nguyên dài theo chuẩn VNPay)
            long amount = invoice.getFinalAmount().multiply(new java.math.BigDecimal(100)).longValue();

            // Khởi tạo các tham số VNPay
            String vnp_TxnRef = invoiceId + "_" + System.currentTimeMillis(); // Mã giao dịch duy nhất
            
            // Xử lý địa chỉ IP người dùng
            String ipAddress = request.getHeader("X-FORWARDED-FOR");
            if (ipAddress == null) {
                ipAddress = request.getRemoteAddr();
            }
            if (ipAddress == null || ipAddress.equals("0:0:0:0:0:0:0:1") || ipAddress.equals("::1")) {
                ipAddress = "127.0.0.1";
            }

            // Tạo Return URL động dựa trên request hiện tại
            String scheme = request.getScheme();
            String serverName = request.getServerName();
            int serverPort = request.getServerPort();
            String contextPath = request.getContextPath();
            String baseUrl = scheme + "://" + serverName + ":" + serverPort + contextPath;
            String vnp_ReturnUrl = baseUrl + "/patient/vnpay-return";

            // Định dạng thời gian GMT+7
            SimpleDateFormat formatter = new SimpleDateFormat("yyyyMMddHHmmss");
            formatter.setTimeZone(TimeZone.getTimeZone("GMT+7"));
            String vnp_CreateDate = formatter.format(Calendar.getInstance(TimeZone.getTimeZone("GMT+7")).getTime());

            Map<String, String> vnp_Params = new HashMap<>();
            vnp_Params.put("vnp_Version", "2.1.0");
            vnp_Params.put("vnp_Command", "pay");
            vnp_Params.put("vnp_TmnCode", VnPayConfig.vnp_TmnCode);
            vnp_Params.put("vnp_Amount", String.valueOf(amount));
            vnp_Params.put("vnp_CurrCode", "VND");
            vnp_Params.put("vnp_TxnRef", vnp_TxnRef);
            vnp_Params.put("vnp_OrderInfo", "Thanh toan hoa don #" + invoiceId);
            vnp_Params.put("vnp_OrderType", "250000"); // 250000: Dịch vụ Y tế
            vnp_Params.put("vnp_Locale", "vn");
            vnp_Params.put("vnp_ReturnUrl", vnp_ReturnUrl);
            vnp_Params.put("vnp_IpAddr", ipAddress);
            vnp_Params.put("vnp_CreateDate", vnp_CreateDate);
            vnp_Params.put("vnp_BankCode", "NCB"); // Mặc định ngân hàng NCB test

            // Tạo chuỗi mã hóa và chữ ký bảo mật
            String secureHash = VnPayConfig.hashAllFields(vnp_Params);
            
            // Xây dựng URL chuyển hướng hoàn chỉnh
            StringBuilder query = new StringBuilder();
            List<String> fieldNames = new ArrayList<>(vnp_Params.keySet());
            Collections.sort(fieldNames);
            Iterator<String> itr = fieldNames.iterator();
            while (itr.hasNext()) {
                String fieldName = itr.next();
                String fieldValue = vnp_Params.get(fieldName);
                query.append(URLEncoder.encode(fieldName, StandardCharsets.UTF_8.toString()))
                     .append("=")
                     .append(URLEncoder.encode(fieldValue, StandardCharsets.UTF_8.toString()).replace("+", "%20"));
                if (itr.hasNext()) {
                    query.append("&");
                }
            }
            
            String redirectUrl = VnPayConfig.vnp_Url + "?" + query.toString() + "&vnp_SecureHash=" + secureHash;
            
            System.out.println("VNPay Payment Redirect URL: " + redirectUrl);
            response.sendRedirect(redirectUrl);

        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Mã hóa đơn phải là dạng số nguyên.");
        } catch (SQLException e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Lỗi kết nối cơ sở dữ liệu.");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doGet(request, response);
    }
}
