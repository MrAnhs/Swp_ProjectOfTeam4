<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Tra cứu hồ sơ</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/assets/css/pages/doctor/doctor.css" rel="stylesheet">
</head>
<body class="doctor-app">
<aside class="doctor-sidebar">
    <div class="doctor-brand">
        <span class="doctor-brand-icon"><i class="bi bi-heart-pulse"></i></span>
        Cổng bác sĩ
    </div>
    <nav class="doctor-nav">
        <a href="${pageContext.request.contextPath}/doctor/dashboard"><i class="bi bi-calendar2-check"></i> Tiếp nhận bệnh nhân</a>
        <a href="${pageContext.request.contextPath}/doctor/general-examinations"><i class="bi bi-person-vcard"></i> Khám tổng quát</a>
        <a href="${pageContext.request.contextPath}/doctor/laboratory-requests"><i class="bi bi-eyedropper"></i> Xét nghiệm</a>
        <a href="${pageContext.request.contextPath}/doctor/examinations"><i class="bi bi-clipboard2-pulse-fill"></i> Khám chi tiết</a>
        <a href="${pageContext.request.contextPath}/doctor/completed-records"><i class="bi bi-archive"></i> Đã hoàn thành</a>
        <a class="active" href="${pageContext.request.contextPath}/doctor/patients/search"><i class="bi bi-search"></i> Tra cứu</a>
        <a href="${pageContext.request.contextPath}/doctor/schedule"><i class="bi bi-calendar3"></i> Lịch trực</a>
        <a href="${pageContext.request.contextPath}/settings"><i class="bi bi-gear"></i> Cài đặt</a>
        <a class="text-danger mt-lg-4" href="${pageContext.request.contextPath}/logout"><i class="bi bi-box-arrow-right"></i> Đăng xuất</a>
    </nav>
</aside>

<main class="doctor-main">
    <section class="doctor-topbar mb-4">
        <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 align-items-lg-center">
            <div>
                <div class="doctor-muted small mb-1">TRA CỨU THÔNG TIN Y TẾ</div>
                <h1 class="doctor-title h3 mb-1">Tra cứu hồ sơ</h1>
                <p class="doctor-muted mb-0">
                    Tìm theo mã bệnh nhân hoặc mã hồ sơ. Chỉ hồ sơ thuộc bác sĩ hiện tại mới được mở.
                </p>
            </div>
            <div class="doctor-stat-icon bg-info-subtle text-info">
                <i class="bi bi-search"></i>
            </div>
        </div>
    </section>

    <section class="doctor-card mb-4">
        <form action="${pageContext.request.contextPath}/doctor/patients/search" method="get">
            <div class="row g-3 align-items-end">
                <div class="col-lg-3">
                    <label class="form-label fw-semibold">Tìm kiếm theo</label>
                    <select name="searchType" class="form-select doctor-filter">
                        <option value="patient" ${empty searchType || searchType == 'patient' ? 'selected' : ''}>
                            Mã bệnh nhân
                        </option>
                        <option value="record" ${searchType == 'record' ? 'selected' : ''}>
                            Mã hồ sơ sức khỏe
                        </option>
                    </select>
                </div>
                <div class="col-lg-7">
                    <label class="form-label fw-semibold">Mã cần tra cứu</label>
                    <div class="input-group">
                        <span class="input-group-text bg-white border-end-0">
                            <i class="bi bi-hash"></i>
                        </span>
                        <input type="number" name="keyword"
                               class="form-control doctor-filter border-start-0"
                               value="${not empty keyword ? keyword : param.patientId}"
                               placeholder="Nhập mã cần tìm" min="1" required>
                    </div>
                </div>
                <div class="col-lg-2">
                    <button type="submit" class="btn btn-doctor w-100">
                        <i class="bi bi-search"></i> Tìm kiếm
                    </button>
                </div>
            </div>
        </form>
    </section>

    <c:if test="${not empty message}">
        <div class="alert alert-warning border-0 shadow-sm">
            <i class="bi bi-exclamation-circle me-2"></i>${message}
        </div>
    </c:if>

    <c:if test="${empty patient && empty message && empty keyword}">
        <section class="doctor-card">
            <div class="doctor-empty">
                <i class="bi bi-person-search fs-1 d-block mb-2"></i>
                Nhập mã bệnh nhân hoặc mã hồ sơ để bắt đầu tra cứu.
            </div>
        </section>
    </c:if>

    <c:if test="${not empty patient}">
        <section class="doctor-card mb-4">
            <div class="d-flex flex-column flex-md-row justify-content-between gap-3 align-items-md-center mb-4">
                <div>
                    <h2 class="doctor-section-title h5 mb-1">Thông tin bệnh nhân</h2>
                    <div class="doctor-muted">Thông tin hành chính của bệnh nhân được tìm thấy.</div>
                </div>
                <span class="doctor-badge badge-accepted">
                    <i class="bi bi-person"></i> Bệnh nhân #${patient.patientId}
                </span>
            </div>

            <div class="row g-3">
                <div class="col-md-6 col-xl-4">
                    <div class="search-info-card">
                        <div class="search-info-icon"><i class="bi bi-person-badge"></i></div>
                        <div><div class="doctor-muted small">Họ và tên</div><div class="fw-bold">${patient.fullName}</div></div>
                    </div>
                </div>
                <div class="col-md-6 col-xl-4">
                    <div class="search-info-card">
                        <div class="search-info-icon"><i class="bi bi-gender-ambiguous"></i></div>
                        <div><div class="doctor-muted small">Giới tính</div><div class="fw-bold">${empty patient.gender ? 'Chưa cập nhật' : patient.gender}</div></div>
                    </div>
                </div>
                <div class="col-md-6 col-xl-4">
                    <div class="search-info-card">
                        <div class="search-info-icon"><i class="bi bi-telephone"></i></div>
                        <div><div class="doctor-muted small">Điện thoại</div><div class="fw-bold">${empty patient.phone ? 'Chưa cập nhật' : patient.phone}</div></div>
                    </div>
                </div>
                <div class="col-md-6">
                    <div class="search-info-card">
                        <div class="search-info-icon"><i class="bi bi-envelope"></i></div>
                        <div><div class="doctor-muted small">Email</div><div class="fw-bold text-break">${empty patient.email ? 'Chưa cập nhật' : patient.email}</div></div>
                    </div>
                </div>
                <div class="col-md-6">
                    <div class="search-info-card">
                        <div class="search-info-icon"><i class="bi bi-geo-alt"></i></div>
                        <div><div class="doctor-muted small">Địa chỉ</div><div class="fw-bold">${empty patient.address ? 'Chưa cập nhật' : patient.address}</div></div>
                    </div>
                </div>
            </div>
        </section>

        <section class="doctor-card">
            <div class="d-flex flex-column flex-md-row justify-content-between gap-3 align-items-md-center mb-3">
                <div>
                    <h2 class="doctor-section-title h5 mb-1">Hồ sơ bác sĩ phụ trách</h2>
                    <div class="doctor-muted">Danh sách hồ sơ được phân công cho tài khoản hiện tại.</div>
                </div>
                <span class="doctor-badge badge-assigned">${records.size()} hồ sơ</span>
            </div>

            <c:choose>
                <c:when test="${empty records}">
                    <div class="doctor-empty">
                        <i class="bi bi-folder-x fs-1 d-block mb-2"></i>
                        Không có hồ sơ nào của bệnh nhân được phân công cho bác sĩ hiện tại.
                    </div>
                </c:when>
                <c:otherwise>
                    <div class="table-responsive">
                        <table class="table doctor-table align-middle mb-0">
                            <thead>
                            <tr>
                                <th>Hồ sơ</th>
                                <th>Đường huyết</th>
                                <th>BMI</th>
                                <th>Ngày tạo</th>
                                <th>Trạng thái</th>
                                <th class="text-end">Thao tác</th>
                            </tr>
                            </thead>
                            <tbody>
                            <c:forEach var="record" items="${records}">
                                <tr>
                                    <td class="fw-bold">#${record.healthRecordId}</td>
                                    <td>${record.hba1c}</td>
                                    <td>${record.bmi}</td>
                                    <td><fmt:formatDate value="${record.createdAt}" pattern="dd/MM/yyyy HH:mm"/></td>
                                    <td>
                                        <span class="doctor-badge ${record.status == 'Completed' ? 'badge-completed' : (record.status == 'AI_Processed' ? 'badge-ai' : (record.status == 'Accepted' ? 'badge-accepted' : 'badge-assigned'))}">
                                            ${record.statusDisplayText}
                                        </span>
                                    </td>
                                    <td class="text-end">
                                        <a class="btn btn-sm btn-doctor"
                                           href="${pageContext.request.contextPath}/doctor/records/detail?record_id=${record.healthRecordId}">
                                            <i class="bi bi-folder2-open"></i> Mở hồ sơ
                                        </a>
                                    </td>
                                </tr>
                            </c:forEach>
                            </tbody>
                        </table>
                    </div>
                </c:otherwise>
            </c:choose>
        </section>
    </c:if>
</main>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
