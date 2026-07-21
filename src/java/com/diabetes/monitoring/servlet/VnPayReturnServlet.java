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
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

public class VnPayReturnServlet extends HttpServlet {
    private final PatientInvoiceDAO invoiceDAO = new PatientInvoiceDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = (User) request.getSession().getAttribute("currentUser");
        if (user == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        // Lấy tất cả các tham số phản hồi từ VNPay
        Map<String, String> fields = new HashMap<>();
        for (Map.Entry<String, String[]> entry : request.getParameterMap().entrySet()) {
            if (entry.getValue() != null && entry.getValue().length > 0) {
                fields.put(entry.getKey(), entry.getValue()[0]);
            }
        }

        String vnp_SecureHash = fields.get("vnp_SecureHash");
        fields.remove("vnp_SecureHash");
        fields.remove("vnp_SecureHashType");

        // Xác minh chữ kýChecksum bảo mật
        String signValue = VnPayConfig.hashAllFields(fields);
        boolean isSignatureValid = signValue.equalsIgnoreCase(vnp_SecureHash);

        String responseCode = fields.get("vnp_ResponseCode");
        String txnRef = fields.get("vnp_TxnRef");
        int invoiceId = -1;
        if (txnRef != null && !txnRef.trim().isEmpty()) {
            try {
                invoiceId = Integer.parseInt(txnRef.split("_")[0]);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        boolean isSuccess = isSignatureValid && "00".equals(responseCode);

        if (isSuccess && invoiceId > 0) {
            try {
                // Cập nhật hóa đơn trong cơ sở dữ liệu làm dự phòng khi IPN không gọi tới được (nhất là ở môi trường test local)
                invoiceDAO.payInvoiceOnline(invoiceId, "VNPay");
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }

        // Đẩy thông tin giao dịch sang JSP
        request.setAttribute("isSignatureValid", isSignatureValid);
        request.setAttribute("isSuccess", isSuccess);
        request.setAttribute("responseCode", responseCode);
        request.setAttribute("invoiceId", invoiceId);
        request.setAttribute("amount", fields.get("vnp_Amount"));
        request.setAttribute("transactionNo", fields.get("vnp_TransactionNo"));
        request.setAttribute("bankCode", fields.get("vnp_BankCode"));
        request.setAttribute("payDate", fields.get("vnp_PayDate"));
        request.setAttribute("orderInfo", fields.get("vnp_OrderInfo"));

        request.getRequestDispatcher("/WEB-INF/views/patient/vnpay-return.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doGet(request, response);
    }
}
