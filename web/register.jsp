<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Đăng ký - DiabetesCare</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css" />
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
            overflow: hidden;
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
        .custom-input-group .form-control, .custom-input-group .form-select {
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
        select.form-select option {
            background-color: #0F172A !important;
            color: #ffffff !important;
        }
    </style>
</head>
<body class="d-flex align-items-center justify-content-center">

    <div class="container py-5">
        <div class="row justify-content-center">
            <div class="col-xl-9 col-lg-10">
                
                <div class="card register-card border-0">
                    <div class="row g-0">
                        
                        <div class="col-md-4 p-4 text-white d-flex flex-column justify-content-center text-center text-md-start" style="background: linear-gradient(135deg, #2AB5A3, #208A7C);">
                            <div class="mb-3">
                                <i class="bi bi-heart-pulse-fill" style="font-size: 3rem;"></i>
                            </div>
                            <h3 class="fw-bold mb-3">Tạo tài khoản</h3>
                            <p class="small opacity-90 mb-0">Tham gia hệ thống DiabetesCare để đặt lịch khám và theo dõi hồ sơ sức khỏe.</p>
                        </div>
                        
                        <div class="col-md-8 p-4 p-md-5" style="background: rgba(15, 23, 42, 0.45);">
                            <c:if test="${not empty registerError}">
                                <div class="alert alert-danger border-0 text-white bg-danger bg-opacity-25" role="alert">
                                    ${registerError}
                                </div>
                            </c:if>
                            <form action="register" method="post" class="needs-validation" novalidate>
                                <div class="row g-3">
                                    
                                    <div class="col-md-6">
                                        <label class="form-label fw-bold text-uppercase tracking-wider" style="font-size: 11px; opacity: 0.65;" for="fullName">HỌ VÀ TÊN</label>
                                        <div class="input-group custom-input-group">
                                            <span class="input-group-text border-end-0"><i class="bi bi-person"></i></span>
                                            <input type="text" class="form-control border-start-0 ps-0 shadow-none" id="fullName" name="fullName" placeholder="Nguyễn Văn A" required>
                                            <div class="invalid-feedback ms-3">Vui lòng nhập họ và tên.</div>
                                        </div>
                                    </div>
                                    
                                    <div class="col-md-6">
                                        <label class="form-label fw-bold text-uppercase tracking-wider" style="font-size: 11px; opacity: 0.65;" for="email">EMAIL</label>
                                        <div class="input-group custom-input-group">
                                            <span class="input-group-text border-end-0"><i class="bi bi-envelope"></i></span>
                                            <input type="email" class="form-control border-start-0 ps-0 shadow-none" id="email" name="email" placeholder="example@gmail.com" required>
                                            <div class="invalid-feedback ms-3">Vui lòng nhập email hợp lệ.</div>
                                        </div>
                                    </div>
                                    
                                    <div class="col-md-6">
                                        <label class="form-label fw-bold text-uppercase tracking-wider" style="font-size: 11px; opacity: 0.65;" for="password">MẬT KHẨU</label>
                                        <div class="input-group custom-input-group">
                                            <span class="input-group-text border-end-0"><i class="bi bi-key"></i></span>
                                            <input type="password" class="form-control border-start-0 ps-0 shadow-none" id="password" name="password" placeholder="Tối thiểu 8 ký tự" required minlength="8">
                                            <div class="invalid-feedback ms-3">Mật khẩu phải có ít nhất 8 ký tự.</div>
                                        </div>
                                    </div>
                                    
                                    <div class="col-md-6">
                                        <label class="form-label fw-bold text-uppercase tracking-wider" style="font-size: 11px; opacity: 0.65;" for="confirmPassword">XÁC NHẬN MẬT KHẨU</label>
                                        <div class="input-group custom-input-group">
                                            <span class="input-group-text border-end-0"><i class="bi bi-shield-lock"></i></span>
                                            <input type="password" class="form-control border-start-0 ps-0 shadow-none" id="confirmPassword" name="confirmPassword" placeholder="Nhập lại mật khẩu" required>
                                            <div class="invalid-feedback ms-3" id="confirmFeedback">Vui lòng xác nhận mật khẩu.</div>
                                        </div>
                                    </div>
                                    
                                    <div class="col-md-6">
                                        <label class="form-label fw-bold text-uppercase tracking-wider" style="font-size: 11px; opacity: 0.65;" for="gender">GIỚI TÍNH</label>
                                        <div class="input-group custom-input-group">
                                            <span class="input-group-text border-end-0"><i class="bi bi-gender-ambiguous"></i></span>
                                            <select class="form-select border-start-0 ps-0 shadow-none" id="gender" name="gender" required>
                                                <option selected disabled value="">Chọn...</option>
                                                <option value="male">Nam</option>
                                                <option value="female">Nữ</option>
                                                <option value="other">Khác</option>
                                            </select>
                                            <div class="invalid-feedback ms-3">Vui lòng chọn giới tính.</div>
                                        </div>
                                    </div>
                                    
                                    <div class="col-md-6">
                                        <label class="form-label fw-bold text-uppercase tracking-wider" style="font-size: 11px; opacity: 0.65;" for="dob">NGÀY SINH</label>
                                        <div class="input-group custom-input-group">
                                            <span class="input-group-text border-end-0"><i class="bi bi-calendar-event"></i></span>
                                            <input type="date" class="form-control border-start-0 ps-0 shadow-none" id="dob" name="dob" min="1900-01-01" required>
                                            <div class="invalid-feedback ms-3" id="dobFeedback">Ngày sinh phải hợp lệ và không được vượt quá ngày hiện tại.</div>
                                        </div>
                                    </div>
                                    
                                    <div class="col-md-12">
                                        <label class="form-label fw-bold text-uppercase tracking-wider" style="font-size: 11px; opacity: 0.65;" for="phone">SỐ ĐIỆN THOẠI</label>
                                        <div class="input-group custom-input-group">
                                            <span class="input-group-text border-end-0"><i class="bi bi-telephone"></i></span>
                                            <input type="tel" class="form-control border-start-0 ps-0 shadow-none" id="phone" name="phone" placeholder="0912345678" inputmode="tel" pattern="(0(3[2-9]|5[2689]|7[06-9]|8[1-689]|9[0-46-9])[0-9]{7}|(\+?84)(3[2-9]|5[2689]|7[06-9]|8[1-689]|9[0-46-9])[0-9]{7})" maxlength="16" required>
                                            <div class="invalid-feedback ms-3">Vui lòng nhập số điện thoại Việt Nam hợp lệ, ví dụ 0912345678 hoặc +84912345678.</div>
                                        </div>
                                    </div>
                                    
                                    <div class="col-md-12">
                                        <label class="form-label fw-bold text-uppercase tracking-wider" style="font-size: 11px; opacity: 0.65;" for="address">ĐỊA CHỈ</label>
                                        <div class="input-group custom-input-group">
                                            <span class="input-group-text border-end-0"><i class="bi bi-house"></i></span>
                                            <input type="text" class="form-control border-start-0 ps-0 shadow-none" id="address" name="address" placeholder="Số nhà, phường/xã, quận/huyện, tỉnh/thành phố">
                                        </div>
                                    </div>
                                </div>
                                
                                <div class="mt-4 d-flex flex-column flex-sm-row justify-content-between align-items-center gap-3">
                                    <button type="submit" class="btn btn-vinmec text-white fw-bold px-4 shadow-sm order-sm-2 w-100 w-sm-auto">Tạo tài khoản</button>
                                    <a href="login.jsp" class="text-decoration-none text-dark-link order-sm-1">Đã có tài khoản?</a>
                                </div>
                            </form>
                        </div>
                        
                    </div>
                </div>
                
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/public/register.js?v=20260709-fontfix2"></script>
</body>
</html>
