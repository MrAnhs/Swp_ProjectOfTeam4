<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Lịch sử bệnh án</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/css/doctor-module.css" rel="stylesheet">
</head>
<body class="doctor-app">
<aside class="doctor-sidebar">
    <div class="doctor-brand"><span class="doctor-brand-icon"><i class="bi bi-heart-pulse"></i></span> Cổng bác sĩ</div>
    <nav class="doctor-nav">
        <a href="${pageContext.request.contextPath}/DashboardServlet"><i class="bi bi-grid"></i> Tiếp nhận hồ sơ</a>
        <a href="${pageContext.request.contextPath}/GeneralExaminationListServlet"><i class="bi bi-person-vcard"></i> Khám tổng quát</a>
        <a href="${pageContext.request.contextPath}/LaboratoryListServlet"><i class="bi bi-eyedropper"></i> Xét nghiệm</a>
        <a href="${pageContext.request.contextPath}/ExaminationListServlet"><i class="bi bi-clipboard2-pulse-fill"></i> Khám chi tiết</a>
        <a href="${pageContext.request.contextPath}/CompletedRecordsServlet"><i class="bi bi-archive"></i> Đã hoàn thành</a>
        <a href="${pageContext.request.contextPath}/PatientSearchServlet"><i class="bi bi-search"></i> Tra cứu</a>
    </nav>
</aside>
<main class="doctor-main">
    <section class="doctor-topbar mb-4">
        <div class="d-flex justify-content-between align-items-center gap-3">
            <div>
                <div class="doctor-muted small">ELECTRONIC MEDICAL RECORD</div>
                <h1 class="doctor-title h3 mb-1">Lịch sử bệnh án</h1>
                <p class="doctor-muted mb-0">${patient.fullName} · Bệnh nhân #${patient.patientId} · Chế độ chỉ đọc</p>
            </div>
            <a class="btn btn-doctor" href="${pageContext.request.contextPath}/DetailServlet?record_id=${record.healthRecordId}">
                <i class="bi bi-arrow-left"></i> Quay lại hồ sơ
            </a>
        </div>
    </section>
    <div class="row g-3 mb-4">
        <div class="col-md-3"><div class="doctor-stat"><div class="doctor-muted small">Tuổi</div><div class="h4 fw-bold mb-0">${patient.age}</div></div></div>
        <div class="col-md-3"><div class="doctor-stat"><div class="doctor-muted small">Giới tính</div><div class="h4 fw-bold mb-0">${patient.gender}</div></div></div>
        <div class="col-md-3"><div class="doctor-stat"><div class="doctor-muted small">Nhóm máu</div><div class="h4 fw-bold mb-0">${empty patient.bloodType ? 'N/A' : patient.bloodType}</div></div></div>
        <div class="col-md-3"><div class="doctor-stat"><div class="doctor-muted small">Số lần khám</div><div class="h4 fw-bold mb-0">${medicalHistory.size()}</div></div></div>
    </div>
    <section class="doctor-card">
        <c:choose>
            <c:when test="${empty medicalHistory}">
                <div class="doctor-empty"><i class="bi bi-journal-medical fs-1 d-block mb-2"></i>Chưa có bệnh án trước đây.</div>
            </c:when>
            <c:otherwise>
                <div class="table-responsive">
                    <table class="table doctor-table align-middle mb-0">
                        <thead><tr><th>Ngày khám</th><th>Bác sĩ</th><th>Chẩn đoán</th><th>Ghi chú</th><th>Kết quả xét nghiệm</th></tr></thead>
                        <tbody>
                        <c:forEach var="item" items="${medicalHistory}">
                            <tr>
                                <td class="text-nowrap"><fmt:formatDate value="${item.processedAt}" pattern="dd/MM/yyyy HH:mm"/></td>
                                <td>${item.doctorName}</td>
                                <td><span class="doctor-badge badge-completed">${item.finalDiagnosis}</span></td>
                                <td>${empty item.doctorNote ? 'Không có ghi chú' : item.doctorNote}</td>
                                <td class="small">
                                    Đường huyết <strong>${item.hba1c}</strong> · Urea ${item.urea} · CR ${item.cr}<br>
                                    Chol ${item.chol} · TG ${item.tg} · HDL ${item.hdl} · LDL ${item.ldl} · BMI ${item.bmi}
                                </td>
                            </tr>
                        </c:forEach>
                        </tbody>
                    </table>
                </div>
            </c:otherwise>
        </c:choose>
    </section>
</main>
</body>
</html>
