package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.dao.PatientInvoiceDAO;
import com.diabetes.monitoring.model.InvoiceInfo;
import com.diabetes.monitoring.util.VnPayConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

public class VnPayIpnServlet extends HttpServlet {
    private final PatientInvoiceDAO invoiceDAO = new PatientInvoiceDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json; charset=UTF-8");
        response.setCharacterEncoding("UTF-8");

        // Lấy tất cả các tham số từ VNPay
        Map<String, String> fields = new HashMap<>();
        for (Map.Entry<String, String[]> entry : request.getParameterMap().entrySet()) {
            if (entry.getValue() != null && entry.getValue().length > 0) {
                fields.put(entry.getKey(), entry.getValue()[0]);
            }
        }

        String vnp_SecureHash = fields.get("vnp_SecureHash");
        fields.remove("vnp_SecureHash");
        fields.remove("vnp_SecureHashType");

        // 1. Kiểm tra chữ ký bảo mật (Checksum)
        String signValue = VnPayConfig.hashAllFields(fields);
        
        try {
            java.io.File logFile = new java.io.File("d:\\Ky5\\SWP391\\Swp_ProjectOfTeam4-main\\ipn_log.txt");
            try (java.io.PrintWriter pw = new java.io.PrintWriter(new java.io.FileWriter(logFile, true))) {
                pw.println("--- IPN RECEIVED AT " + new java.util.Date() + " ---");
                pw.println("Query String: " + request.getQueryString());
                pw.println("Parameters: " + fields);
                pw.println("vnp_SecureHash: " + vnp_SecureHash);
                pw.println("Calculated Hash: " + signValue);
                pw.println("Signature Valid: " + signValue.equalsIgnoreCase(vnp_SecureHash));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        if (!signValue.equalsIgnoreCase(vnp_SecureHash)) {
            System.out.println("VNPay IPN Warning: Invalid Checksum signature received.");
            writeJsonResponse(response, "97", "Invalid Checksum");
            return;
        }

        String txnRef = fields.get("vnp_TxnRef");
        int invoiceId = -1;
        if (txnRef != null && !txnRef.trim().isEmpty()) {
            try {
                invoiceId = Integer.parseInt(txnRef.split("_")[0]);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        // 2. Kiểm tra hóa đơn tồn tại trong hệ thống
        if (invoiceId <= 0) {
            writeJsonResponse(response, "01", "Order not found");
            return;
        }

        try {
            InvoiceInfo invoice = invoiceDAO.findById(invoiceId);
            if (invoice == null) {
                writeJsonResponse(response, "01", "Order not found");
                return;
            }

            // 3. Kiểm tra số tiền thanh toán (vnp_Amount chia 100 so với finalAmount của hóa đơn)
            long vnpAmountLong = Long.parseLong(fields.get("vnp_Amount"));
            long dbAmountLong = invoice.getFinalAmount().multiply(new BigDecimal(100)).longValue();
            if (vnpAmountLong != dbAmountLong) {
                writeJsonResponse(response, "04", "Invalid amount");
                return;
            }

            // 4. Kiểm tra trạng thái hóa đơn (Đơn hàng đã thanh toán trước đó chưa)
            if (!"Pending".equalsIgnoreCase(invoice.getStatus())) {
                writeJsonResponse(response, "02", "Order already confirmed");
                return;
            }

            // 5. Kiểm tra kết quả giao dịch và tiến hành cập nhật
            String responseCode = fields.get("vnp_ResponseCode");
            if ("00".equals(responseCode)) {
                // Thanh toán thành công -> Cập nhật sang trạng thái PAID
                boolean updateResult = invoiceDAO.payInvoiceOnline(invoiceId, "VNPay");
                if (updateResult) {
                    System.out.println("VNPay IPN Success: Invoice #" + invoiceId + " has been successfully paid online.");
                    writeJsonResponse(response, "00", "Confirm Success");
                } else {
                    writeJsonResponse(response, "99", "Database update failed");
                }
            } else {
                // Giao dịch không thành công trên VNPay (Bệnh nhân hủy hoặc lỗi thẻ)
                System.out.println("VNPay IPN Info: Transaction for Invoice #" + invoiceId + " failed with code " + responseCode);
                // Giữ nguyên trạng thái PENDING của hóa đơn để bệnh nhân có thể chọn thanh toán lại
                writeJsonResponse(response, "00", "Confirm Success");
            }

        } catch (NumberFormatException e) {
            writeJsonResponse(response, "04", "Invalid amount format");
        } catch (SQLException e) {
            e.printStackTrace();
            writeJsonResponse(response, "99", "Database connection error");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doGet(request, response);
    }

    private void writeJsonResponse(HttpServletResponse response, String rspCode, String message) throws IOException {
        response.getWriter().print("{\"RspCode\":\"" + rspCode + "\",\"Message\":\"" + message + "\"}");
    }
}
