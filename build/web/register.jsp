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
</head>
<body class="bg-light d-flex align-items-center justify-content-center" style="min-height: 100vh; background: linear-gradient(135deg, #f4fbf9 0%, #e8f7f4 100%);">

    <div class="container py-5">
        <div class="row justify-content-center">
            <div class="col-xl-9 col-lg-10">
                
                <div class="card border-0 shadow-lg overflow-hidden" style="border-radius: 20px;">
                    <div class="row g-0">
                        
                        <div class="col-md-4 p-4 text-white d-flex flex-column justify-content-center text-center text-md-start" style="background-color: #2dbbbc;">
                            <div class="mb-3">
                                <i class="bi bi-heart-pulse-fill" style="font-size: 3rem;"></i>
                            </div>
                            <h3 class="fw-bold mb-3">Tạo tài khoản</h3>
                            <p class="small opacity-90 mb-0">Tham gia hệ thống DiabetesCare để đặt lịch khám và theo dõi hồ sơ sức khỏe.</p>
                        </div>
                        
                        <div class="col-md-8 p-4 p-md-5 bg-white">
                            <c:if test="${not empty registerError}">
                                <div class="alert alert-danger" role="alert">
                                    ${registerError}
                                </div>
                            </c:if>
                            <form action="register" method="post" class="needs-validation" novalidate>
                                <div class="row g-3">
                                    
                                    <div class="col-md-6">
                                        <label class="form-label text-secondary fw-semibold small" for="fullName">Họ và tên</label>
                                        <div class="input-group custom-input-group">
                                            <span class="input-group-text bg-white border-end-0 text-secondary"><i class="bi bi-person-fill"></i></span>
                                            <input type="text" class="form-control border-start-0 ps-0 shadow-none" id="fullName" name="fullName" placeholder="Nguyễn Văn A" required>
                                            <div class="invalid-feedback ms-3">Vui lòng nhập họ và tên.</div>
                                        </div>
                                    </div>
                                    
                                    <div class="col-md-6">
                                        <label class="form-label text-secondary fw-semibold small" for="email">Email</label>
                                        <div class="input-group custom-input-group">
                                            <span class="input-group-text bg-white border-end-0 text-secondary"><i class="bi bi-envelope-fill"></i></span>
                                            <input type="email" class="form-control border-start-0 ps-0 shadow-none" id="email" name="email" placeholder="example@gmail.com" required>
                                            <div class="invalid-feedback ms-3">Vui lòng nhập email hợp lệ.</div>
                                        </div>
                                    </div>
                                    
                                    <div class="col-md-6">
                                        <label class="form-label text-secondary fw-semibold small" for="password">Mật khẩu</label>
                                        <div class="input-group custom-input-group">
                                            <span class="input-group-text bg-white border-end-0 text-secondary"><i class="bi bi-key-fill"></i></span>
                                            <input type="password" class="form-control border-start-0 ps-0 shadow-none" id="password" name="password" placeholder="Tối thiểu 8 ký tự" required minlength="8">
                                            <div class="invalid-feedback ms-3">Mật khẩu phải có ít nhất 8 ký tự.</div>
                                        </div>
                                    </div>
                                    
                                    <div class="col-md-6">
                                        <label class="form-label text-secondary fw-semibold small" for="confirmPassword">Xác nhận mật khẩu</label>
                                        <div class="input-group custom-input-group">
                                            <span class="input-group-text bg-white border-end-0 text-secondary"><i class="bi bi-shield-lock-fill"></i></span>
                                            <input type="password" class="form-control border-start-0 ps-0 shadow-none" id="confirmPassword" name="confirmPassword" placeholder="Nhập lại mật khẩu" required>
                                            <div class="invalid-feedback ms-3" id="confirmFeedback">Vui lòng xác nhận mật khẩu.</div>
                                        </div>
                                    </div>
                                    
                                    <div class="col-md-6">
                                        <label class="form-label text-secondary fw-semibold small" for="gender">Giới tính</label>
                                        <div class="input-group custom-input-group">
                                            <span class="input-group-text bg-white border-end-0 text-secondary"><i class="bi bi-gender-ambiguous"></i></span>
                                            <select class="form-select border-start-0 ps-0 shadow-none text-secondary" id="gender" name="gender" required>
                                                <option selected disabled value="">Chọn...</option>
                                                <option value="male">Nam</option>
                                                <option value="female">Nữ</option>
                                                <option value="other">Khác</option>
                                            </select>
                                            <div class="invalid-feedback ms-3">Vui lòng chọn giới tính.</div>
                                        </div>
                                    </div>
                                    
                                    <div class="col-md-6">
                                        <label class="form-label text-secondary fw-semibold small" for="dob">Ngày sinh</label>
                                        <div class="input-group custom-input-group">
                                            <span class="input-group-text bg-white border-end-0 text-secondary"><i class="bi bi-calendar-event-fill"></i></span>
                                            <input type="date" class="form-control border-start-0 ps-0 shadow-none text-secondary" id="dob" name="dob" min="1900-01-01" required>
                                            <div class="invalid-feedback ms-3" id="dobFeedback">Ngày sinh phải hợp lệ và không được vượt quá ngày hiện tại.</div>
                                        </div>
                                    </div>
                                    
                                    <div class="col-md-12">
                                        <label class="form-label text-secondary fw-semibold small" for="phone">Số điện thoại</label>
                                        <div class="input-group custom-input-group">
                                            <span class="input-group-text bg-white border-end-0 text-secondary"><i class="bi bi-telephone-fill"></i></span>
                                            <input type="tel" class="form-control border-start-0 ps-0 shadow-none" id="phone" name="phone" placeholder="0912345678" inputmode="tel" pattern="(0(3[2-9]|5[2689]|7[06-9]|8[1-689]|9[0-46-9])[0-9]{7}|(\+?84)(3[2-9]|5[2689]|7[06-9]|8[1-689]|9[0-46-9])[0-9]{7})" maxlength="16" required>
                                            <div class="invalid-feedback ms-3">Vui lòng nhập số điện thoại Việt Nam hợp lệ, ví dụ 0912345678 hoặc +84912345678.</div>
                                        </div>
                                    </div>
                                    
                                    <div class="col-md-12">
                                        <label class="form-label text-secondary fw-semibold small" for="address">Địa chỉ</label>
                                        <div class="input-group custom-input-group">
                                            <span class="input-group-text bg-white border-end-0 text-secondary"><i class="bi bi-house-fill"></i></span>
                                            <input type="text" class="form-control border-start-0 ps-0 shadow-none" id="address" name="address" placeholder="Số nhà, phường/xã, quận/huyện, tỉnh/thành phố">
                                        </div>
                                    </div>
                                </div>
                                
                                <div class="mt-4 d-flex flex-column flex-sm-row justify-content-between align-items-center gap-3">
                                    <button type="submit" class="btn btn-vinmec text-white fw-bold px-4 py-2-5 shadow-sm order-sm-2 w-100 w-sm-auto">Tạo tài khoản</button>
                                    <a href="login.jsp" class="text-decoration-none text-secondary small fw-medium order-sm-1 link-hover-vinmec">Đã có tài khoản?</a>
                                </div>
                            </form>
                        </div>
                        
                    </div>
                </div>
                
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script src="${pageContext.request.contextPath}/assets/js/pages/public/register.js"></script>
</body>
</html>
