<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <title>Đăng ký - DiabetesCare</title>
    <%@ include file="/WEB-INF/views/components/shared/master-head.jspf" %>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/public/common.css" />
    <style>
        body {
            background: radial-gradient(circle at center, rgba(42, 181, 163, 0.15) 0%, #0B0F19 80%) !important;
            color: #E2E8F0 !important;
            font-family: 'Inter', sans-serif;
            min-height: 100vh;
        }
        .register-card {
            background: rgba(15, 23, 42, 0.6) !important;
            backdrop-filter: blur(24px) !important;
            -webkit-backdrop-filter: blur(24px) !important;
            border: 1px solid rgba(255, 255, 255, 0.08) !important;
            border-radius: 24px !important;
            box-shadow: 0 30px 80px rgba(0, 0, 0, 0.65) !important;
            max-width: 850px;
            width: 100%;
            margin: 2rem auto;
        }
        .btn-vinmec {
            background: linear-gradient(135deg, #2AB5A3, #208A7C) !important;
            border: none !important;
            border-radius: 50px !important;
            padding: 0.85rem 3.5rem !important;
            box-shadow: 0 8px 25px rgba(42, 181, 163, 0.3) !important;
            transition: all 0.3s ease !important;
            font-size: 1.05rem !important;
            letter-spacing: 0.2px !important;
        }
        .btn-vinmec:hover {
            transform: translateY(-2px) !important;
            box-shadow: 0 12px 30px rgba(42, 181, 163, 0.45) !important;
        }
        .text-dark-link {
            color: #2AB5A3 !important;
            font-weight: 700;
            font-size: 1.05rem;
            transition: color 0.2s ease;
        }
        .text-dark-link:hover {
            color: #34d399 !important;
            text-decoration: underline !important;
        }
        .back-to-home {
            color: rgba(255, 255, 255, 0.5) !important;
            font-size: 0.95rem;
            text-decoration: none;
            transition: color 0.2s ease;
        }
        .back-to-home:hover {
            color: #ffffff !important;
        }
    </style>
</head>
<body class="d-flex align-items-center justify-content-center py-4">

    <div class="container">
        <div class="row justify-content-center">
            <div class="col-12 d-flex justify-content-center">
                
                <div class="card register-card border-0 p-4 p-md-5">
                    <div class="card-body p-0">
                        <div class="mb-4 text-end">
                            <a href="${pageContext.request.contextPath}/index.jsp" class="back-to-home">
                                &larr; Về trang chủ
                            </a>
                        </div>
                        <c:if test="${not empty registerError}">
                            <div class="alert alert-danger border-0 text-white bg-danger bg-opacity-25" role="alert">
                                ${registerError}
                            </div>
                        </c:if>
                        <form action="register" method="post" class="needs-validation" novalidate>
                            <c:set var="isSelfRegistration" value="true" scope="request" />
                            <%@ include file="/WEB-INF/views/components/shared/patient-registration-form.jspf" %>
                            
                            <div class="mt-4 pt-2 d-flex flex-row justify-content-between align-items-center">
                                <a href="login.jsp" class="text-decoration-none text-dark-link">Đã có tài khoản?</a>
                                <button type="submit" class="btn btn-vinmec text-white fw-bold shadow-sm">Tạo tài khoản</button>
                            </div>
                        </form>
                    </div>
                </div>
                
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/public/register.js?v=20260709-fontfix2"></script>
</body>
</html>
