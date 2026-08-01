<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <title>Đăng nhập - DiabetesCare</title>
    <%@ include file="/WEB-INF/views/components/shared/master-head.jspf" %>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/public/common.css" />
    <style>
        body {
            background: radial-gradient(circle at center, rgba(42, 181, 163, 0.15) 0%, #0B0F19 80%) !important;
            color: #E2E8F0 !important;
            font-family: 'Inter', sans-serif;
            min-height: 100vh;
        }
        .login-card {
            background: rgba(15, 23, 42, 0.6) !important;
            backdrop-filter: blur(24px) !important;
            -webkit-backdrop-filter: blur(24px) !important;
            border: 1px solid rgba(255, 255, 255, 0.08) !important;
            border-radius: 24px !important;
            box-shadow: 0 30px 80px rgba(0, 0, 0, 0.65) !important;
            max-width: 480px;
            width: 100%;
        }
        .custom-input-group {
            background: rgba(255, 255, 255, 0.03) !important;
            border: 1px solid rgba(255, 255, 255, 0.08) !important;
            border-radius: 12px !important;
            overflow: hidden;
            transition: all 0.3s ease;
        }
        .custom-input-group:focus-within {
            border-color: rgba(42, 181, 163, 0.5) !important;
            box-shadow: 0 0 0 2px rgba(42, 181, 163, 0.15) !important;
        }
        .custom-input-group .input-group-text {
            background: transparent !important;
            border: none !important;
            color: #2AB5A3 !important;
            font-size: 1.1rem;
        }
        .custom-input-group .form-control {
            background: transparent !important;
            border: none !important;
            color: #ffffff !important;
            font-size: 0.95rem;
            padding: 0.75rem 1rem 0.75rem 0 !important;
        }
        .custom-input-group .form-control::placeholder {
            color: rgba(255, 255, 255, 0.3) !important;
        }
        .btn-vinmec {
            background: linear-gradient(135deg, #2AB5A3, #208A7C) !important;
            border: none !important;
            border-radius: 50px !important;
            padding: 0.8rem 1.5rem !important;
            box-shadow: 0 8px 25px rgba(42, 181, 163, 0.3) !important;
            transition: all 0.3s ease !important;
        }
        .btn-vinmec:hover {
            transform: translateY(-2px) !important;
            box-shadow: 0 12px 30px rgba(42, 181, 163, 0.45) !important;
        }
        .text-dark-link {
            color: #2AB5A3 !important;
            font-weight: 600;
        }
        .text-dark-link:hover {
            color: #00d2d3 !important;
        }
        .form-label {
            color: rgba(255, 255, 255, 0.7) !important;
            margin-bottom: 0.5rem;
        }
    </style>
</head>
<body class="d-flex align-items-center justify-content-center">

    <div class="container">
        <div class="row justify-content-center">
            <div class="col-12 d-flex justify-content-center">
                
                <div class="card login-card border-0 p-3">
                    <div class="card-body p-4 p-md-5">
                        <div class="mb-3">
                            <a href="${pageContext.request.contextPath}/index.jsp" class="text-decoration-none text-white-50 small hover-arrow d-inline-flex align-items-center gap-1" style="font-size: 0.85rem;">
                                <i class="bi bi-arrow-left"></i> Về trang chủ
                            </a>
                        </div>
                        <div class="text-center mb-4">
                            <div class="mb-3 d-inline-flex align-items-center justify-content-center" style="width: 48px; height: 48px; background: linear-gradient(135deg, #2AB5A3, #208A7C); border-radius: 12px;">
                                <i class="bi bi-heart-pulse-fill text-white fs-4"></i>
                            </div>
                            <h2 class="fw-bold text-white mb-2" style="font-size: 1.8rem;">Đăng nhập hệ thống</h2>
                            <p class="text-white-50 small" style="font-size: 0.85rem; line-height: 1.4;">Hệ thống sẽ tự nhận diện vai trò tài khoản và chuyển đến đúng khu vực làm việc.</p>
                        </div>
                        <c:if test="${not empty loginError}">
                            <div class="alert alert-danger border-0 text-white bg-danger bg-opacity-25" role="alert">
                                ${loginError}
                            </div>
                        </c:if>
                        
                        <form action="auth" method="post" class="needs-validation" novalidate>
                            
                            <div class="mb-3">
                                <label for="email" class="form-label fw-bold text-uppercase tracking-wider" style="font-size: 11px; opacity: 0.65;">EMAIL</label>
                                <div class="input-group custom-input-group">
                                    <span class="input-group-text border-end-0">
                                        <i class="bi bi-envelope"></i>
                                    </span>
                                    <input type="email" class="form-control border-start-0 ps-0 shadow-none" id="email" name="email" value="<c:out value='${not empty typedEmail ? typedEmail : param.email}'/>" placeholder="example@gmail.com" required>
                                    <div class="invalid-feedback ms-3">Vui lòng nhập email.</div>
                                </div>
                            </div>
                            
                            <div class="mb-3">
                                <label for="password" class="form-label fw-bold text-uppercase tracking-wider" style="font-size: 11px; opacity: 0.65;">MẬT KHẨU</label>
                                <div class="input-group custom-input-group">
                                    <span class="input-group-text border-end-0">
                                        <i class="bi bi-key"></i>
                                    </span>
                                    <input type="password" class="form-control border-start-0 ps-0 shadow-none" id="password" name="password" placeholder="**********" required>
                                    <div class="invalid-feedback ms-3">Vui lòng nhập mật khẩu.</div>
                                </div>
                            </div>
                            

                            <div class="d-flex justify-content-end align-items-center mb-4 pt-1">
                                <a href="${pageContext.request.contextPath}/forgot-password/" class="text-decoration-none text-white-50 small hover-arrow">Quên mật khẩu?</a>
                            </div>
                            
                            <button type="submit" class="btn btn-vinmec w-100 fw-bold text-white shadow-sm">Đăng nhập</button>
                        </form>
                        
                        <p class="text-center text-white-50 mt-4 mb-0 small">
                            Chưa có tài khoản? <a href="register.jsp" class="text-decoration-none text-dark-link">Đăng ký</a>
                        </p>
                    </div>
                </div>
                
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/public/login.js?v=20260709-fontfix2"></script>
</body>
</html>
