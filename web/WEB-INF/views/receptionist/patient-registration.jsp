<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<c:set var="currentPage" value="patient-register" />
<!DOCTYPE html>
<html lang="vi">
<head>
    <title>Đăng ký bệnh nhân</title>
    <%@ include file="/WEB-INF/views/components/shared/master-head.jspf" %>
    <link href="${pageContext.request.contextPath}/assets/css/pages/receptionist/receptionist.css?v=20260725-balanced" rel="stylesheet">
    <%-- Phong cách nút bấm tùy chỉnh riêng cho giao diện Lễ tân để tạo sự nhất quán --%>
    <style>
        .btn-receptionist-submit {
            background: linear-gradient(135deg, #2AB5A3, #208A7C) !important;
            border: none !important;
            border-radius: 50px !important;
            padding: 0.8rem 2.5rem !important;
            color: #ffffff !important;
            font-weight: 700 !important;
            box-shadow: 0 8px 25px rgba(42, 181, 163, 0.3) !important;
            transition: all 0.3s ease !important;
            font-size: 0.95rem !important;
        }
        .btn-receptionist-submit:hover {
            transform: translateY(-2px) !important;
            box-shadow: 0 12px 30px rgba(42, 181, 163, 0.45) !important;
        }
        .btn-receptionist-reset {
            border: 1px solid rgba(255, 255, 255, 0.2) !important;
            border-radius: 50px !important;
            padding: 0.8rem 2rem !important;
            color: rgba(255, 255, 255, 0.85) !important;
            background: transparent !important;
            font-weight: 600 !important;
            transition: all 0.3s ease !important;
            font-size: 0.95rem !important;
        }
        .btn-receptionist-reset:hover {
            background: rgba(255, 255, 255, 0.08) !important;
            border-color: rgba(255, 255, 255, 0.4) !important;
            color: #ffffff !important;
            transform: translateY(-2px) !important;
        }
    </style>
</head>
<body class="receptionist-page">
<div class="receptionist-shell">
    <%@ include file="/WEB-INF/views/components/receptionist/sidebar.jspf" %>
    <main class="receptionist-main">
        <div class="page-kicker">Tạo hồ sơ</div>
        <h1 class="page-title">Đăng ký bệnh nhân</h1>
        <p class="page-subtitle">Tạo hồ sơ bệnh nhân mới, sau đó chuyển thẳng sang đăng ký khám.</p>

        <%-- Form tạo hồ sơ bệnh nhân mới --%>
        <section class="panel-card mt-4">
            <form id="patientRegistrationForm" class="needs-validation" novalidate>
                <%-- Tắt chế độ Tự đăng ký trực tuyến (isSelfRegistration = false) để hiển thị form tại quầy lễ tân --%>
                <c:set var="isSelfRegistration" value="false" scope="request" />
                <%@ include file="/WEB-INF/views/components/shared/patient-registration-form.jspf" %>

                <%-- Các nút hành động gửi dữ liệu form hoặc làm mới --%>
                <div class="mt-4 d-flex gap-3 justify-content-end align-items-center">
                    <button class="btn btn-receptionist-reset" id="resetPatientRegistrationBtn" type="button">Làm mới</button>
                    <button class="btn btn-receptionist-submit" type="submit">
                        <i class="bi bi-person-plus me-1"></i>Tạo hồ sơ bệnh nhân
                    </button>
                </div>
            </form>
        </section>

        <%-- Khung kết quả hiển thị thông báo thành công cùng thông tin mật khẩu tạm thời --%>
        <section id="patientRegistrationResult" class="result-card mt-4 d-none"></section>
    </main>
</div>
<script>
    window.ReceptionistConfig = {
        contextPath: '${pageContext.request.contextPath}',
        apiBase: '${pageContext.request.contextPath}/receptionist/api'
    };
</script>
<script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/receptionist/receptionist-utils.js?v=20260709-fontfix2"></script>
<script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/receptionist/patient-registration.js?v=20260710-encodingfix"></script>
</body>
</html>
