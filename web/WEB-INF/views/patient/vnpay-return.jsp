<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="app-context-path" content="${pageContext.request.contextPath}">
    <title>Kết quả thanh toán - DiabetesCare</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/layouts/patient-shell.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/patient/patient-pages.css">
    <style>
        .result-card {
            max-width: 600px;
            margin: 40px auto;
            border-radius: 16px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.05);
            background: var(--card-bg, #ffffff);
            border: 1px solid var(--border-color, #eef2f5);
            overflow: hidden;
            animation: slideUp 0.5s ease-out;
        }
        @keyframes slideUp {
            from { transform: translateY(20px); opacity: 0; }
            to { transform: translateY(0); opacity: 1; }
        }
        .result-header {
            padding: 40px 30px;
            text-align: center;
            color: #ffffff;
        }
        .result-header.success {
            background: linear-gradient(135deg, #2ecc71, #27ae60);
        }
        .result-header.error {
            background: linear-gradient(135deg, #e74c3c, #c0392b);
        }
        .result-icon {
            font-size: 4rem;
            margin-bottom: 15px;
            animation: scaleIn 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275) 0.2s both;
        }
        @keyframes scaleIn {
            from { transform: scale(0); }
            to { transform: scale(1); }
        }
        .result-body {
            padding: 30px;
        }
        .detail-row {
            display: flex;
            justify-content: space-between;
            padding: 12px 0;
            border-bottom: 1px dashed #f1f4f6;
        }
        .detail-row:last-child {
            border-bottom: none;
        }
        .detail-label {
            color: #7f8c8d;
            font-weight: 500;
        }
        .detail-value {
            font-weight: 600;
            color: #2c3e50;
        }
        .result-actions {
            padding: 20px 30px 40px;
            text-align: center;
        }
        .btn-action-primary {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 12px 24px;
            border-radius: 8px;
            font-weight: 600;
            text-decoration: none;
            transition: all 0.2s;
            background-color: var(--primary-color, #3498db);
            color: #ffffff;
            border: none;
        }
        .btn-action-primary:hover {
            opacity: 0.9;
            transform: translateY(-1px);
            color: #ffffff;
        }
        .btn-action-secondary {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 12px 24px;
            border-radius: 8px;
            font-weight: 600;
            text-decoration: none;
            transition: all 0.2s;
            background-color: #f1f4f6;
            color: #34495e;
            border: none;
            margin-left: 10px;
        }
        .btn-action-secondary:hover {
            background-color: #e2e7eb;
            color: #2c3e50;
        }
    </style>
</head>
<body>
    <c:set var="activePatientPage" value="invoices" />
    <%@ include file="/WEB-INF/views/components/patient/sidebar.jspf" %>
    <main class="main-content-dash">
        <header class="page-header">
            <div>
                <p class="page-eyebrow">Thanh toán hóa đơn</p>
                <h1>Kết quả giao dịch</h1>
            </div>
        </header>
        
        <div class="result-card">
            <c:choose>
                <c:when test="${isSuccess}">
                    <div class="result-header success">
                        <div class="result-icon"><i class="bi bi-check-circle-fill"></i></div>
                        <h2>Thanh toán thành công!</h2>
                        <p>Hóa đơn của bạn đã được thanh toán trực tuyến qua cổng VNPay.</p>
                    </div>
                </c:when>
                <c:otherwise>
                    <div class="result-header error">
                        <div class="result-icon"><i class="bi bi-x-circle-fill"></i></div>
                        <h2>Thanh toán thất bại</h2>
                        <p>
                            <c:choose>
                                <c:when test="${not isSignatureValid}">
                                    Chữ ký dữ liệu không hợp lệ (Checksum Error).
                                </c:when>
                                <c:otherwise>
                                    Giao dịch không thành công hoặc bị hủy bỏ.
                                </c:otherwise>
                            </c:choose>
                        </p>
                    </div>
                </c:otherwise>
            </c:choose>
            
            <div class="result-body">
                <div class="detail-row">
                    <span class="detail-label">Mã hóa đơn:</span>
                    <span class="detail-value">#${invoiceId}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Số tiền:</span>
                    <span class="detail-value text-success">
                        <c:set var="vndAmount" value="${amount / 100}" />
                        <fmt:setLocale value="vi_VN"/>
                        <fmt:formatNumber value="${vndAmount}" type="currency"/>
                    </span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Ngân hàng thanh toán:</span>
                    <span class="detail-value">${bankCode}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Mã giao dịch VNPay:</span>
                    <span class="detail-value">${transactionNo}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Nội dung thanh toán:</span>
                    <span class="detail-value">${orderInfo}</span>
                </div>
                <c:if test="${not isSuccess && isSignatureValid}">
                    <div class="detail-row">
                        <span class="detail-label">Mã lỗi phản hồi:</span>
                        <span class="detail-value text-danger">${responseCode}</span>
                    </div>
                </c:if>
            </div>
            
            <div class="result-actions">
                <c:if test="${invoiceId > 0}">
                    <a href="${pageContext.request.contextPath}/patient/invoices/detail?id=${invoiceId}" class="btn-action-primary">
                        <i class="bi bi-receipt"></i> Xem chi tiết hóa đơn
                    </a>
                </c:if>
                <a href="${pageContext.request.contextPath}/patient/invoices" class="btn-action-secondary">
                    <i class="bi bi-list-task"></i> Danh sách hóa đơn
                </a>
            </div>
        </div>
    </main>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/app-config.js?v=20260710-patient-fontfix-all2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/api-client.js?v=20260710-patient-fontfix-all2"></script>
</body>
</html>
