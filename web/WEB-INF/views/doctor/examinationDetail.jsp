<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>
<%@taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Khám chi tiết</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/assets/css/pages/doctor/doctor.css?v=20260721-ui2" rel="stylesheet">
    <style>
        .exam-hero {
            overflow: hidden;
            position: relative;
            color: #fff;
            background: linear-gradient(135deg, #087f8c, #0f766e);
        }
        .exam-hero::after {
    position: absolute;
    right: -55px;
    top: -85px;
    width: 230px;
    height: 230px;
    border-radius: 50%;
    content: "";
    background: rgba(255,255,255,.1);

    pointer-events: none;
    z-index: 0;
}

.exam-hero > .position-relative {
    position: relative;
    z-index: 2;
}        .exam-hero .doctor-muted { color: rgba(255,255,255,.78); }
        .exam-grid { display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:14px; }
        .exam-metric {
            padding:16px; border:1px solid var(--doctor-border);
            border-radius:15px; background:#f8fbfd;
        }
        .exam-metric-label { color:var(--doctor-muted); font-size:.72rem; font-weight:700; text-transform:uppercase; }
        .exam-metric-value { margin-top:5px; font-size:1.28rem; font-weight:800; }
        .section-icon {
            display:grid; width:42px; height:42px; place-items:center;
            border-radius:13px; background:#e6f6f5; color:var(--doctor-primary);
        }
        .ai-progress { height:22px; border-radius:999px; background:#e8eef3; }
        .form-control, .form-select { border-radius:12px; border-color:var(--doctor-border); }
        .diagnosis-panel { position:sticky; top:20px; }
        .exam-section-nav {
            display:flex; flex-wrap:wrap; gap:10px; margin-bottom:24px;
        }
        .exam-section-nav a {
            display:inline-flex; align-items:center; gap:8px; padding:10px 15px;
            border:1px solid var(--doctor-border); border-radius:999px;
            background:#fff; color:var(--doctor-text); font-weight:700;
            text-decoration:none;
        }
        .exam-section-nav a:hover { border-color:var(--doctor-primary); color:var(--doctor-primary); }
        .patient-info-grid {
            display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:12px;
        }
        .patient-info-item {
            min-height:88px; padding:15px; border:1px solid var(--doctor-border);
            border-radius:14px; background:#f8fbfd;
        }
        .patient-info-item.wide { grid-column:span 2; }
        .patient-info-label {
            margin-bottom:5px; color:var(--doctor-muted); font-size:.76rem;
            font-weight:800; letter-spacing:.04em; text-transform:uppercase;
        }
        .patient-info-value { font-size:1rem; font-weight:700; overflow-wrap:anywhere; }
        .lab-request-form {
            padding:20px; border:1px solid #cfe5e7; border-radius:16px;
            background:linear-gradient(135deg,#f7fcfc,#eef8f8);
        }
        .lab-request-form .form-label { margin-bottom:8px; font-size:.92rem; color:#29455d; }
        .lab-request-form .form-control,
        .lab-request-form .form-select { min-height:48px; font-size:1rem; }
        .lab-request-form .btn { min-height:48px; font-weight:800; }
        @media (max-width:767px) {
            .exam-grid, .patient-info-grid { grid-template-columns:1fr 1fr; }
            .patient-info-item.wide { grid-column:span 2; }
        }
    </style>
</head>
<body class="doctor-app">
<c:set var="canEditDiagnosis" value="${record.status == 'Accepted' || record.status == 'AI_Processed' || record.status == 'Editing' || record.status == 'Completed'}"/>
<c:set var="canRunAI" value="${record.status == 'Accepted' || record.status == 'AI_Processed' || record.status == 'Editing' || record.status == 'Completed'}"/>
<c:set var="hasAIResult" value="${record.status == 'AI_Processed' || record.status == 'Editing' || record.status == 'Completed'}"/>
<c:set var="isDetailedStage" value="${hasCompletedLaboratoryRequest || hasAIResult}"/>

<aside class="doctor-sidebar">
    <div class="doctor-brand"><span class="doctor-brand-icon"><i class="bi bi-heart-pulse"></i></span> Cổng bác sĩ</div>
    <div class="doctor-profile-card">
        <div class="doctor-avatar">
            <c:choose>
                <c:when test="${not empty sessionScope.currentUser.fullName}">
                    <c:out value="${sessionScope.currentUser.fullName.substring(0, 1)}" />
                </c:when>
                <c:otherwise>D</c:otherwise>
            </c:choose>
        </div>
        <div class="doctor-info">
            <div class="doctor-name" title="<c:out value='${sessionScope.currentUser.fullName}' />">
                <c:out value="${sessionScope.currentUser.fullName}" default="Bác sĩ" />
            </div>
            <div class="doctor-role-tag">Bác sĩ</div>
        </div>
        <a href="${pageContext.request.contextPath}/settings" class="doctor-edit-profile-btn" title="Chỉnh sửa hồ sơ">
            <i class="bi bi-pencil-square"></i>
        </a>
    </div>
    <nav class="doctor-nav">
        <a href="${pageContext.request.contextPath}/doctor/dashboard"><i class="bi bi-grid"></i> Tiếp nhận bệnh nhân</a>
        <a class="${!isDetailedStage ? 'active' : ''}" href="${pageContext.request.contextPath}/doctor/general-examinations"><i class="bi bi-person-vcard"></i> Khám tổng quát</a>
        <a href="${pageContext.request.contextPath}/doctor/laboratory-requests"><i class="bi bi-eyedropper"></i> Xét nghiệm</a>
        <a class="${isDetailedStage ? 'active' : ''}" href="${pageContext.request.contextPath}/doctor/examinations"><i class="bi bi-clipboard2-pulse-fill"></i> Khám chi tiết</a>
        <a href="${pageContext.request.contextPath}/doctor/completed-records"><i class="bi bi-archive"></i> Đã hoàn thành</a>
        <a href="${pageContext.request.contextPath}/doctor/patients/search"><i class="bi bi-search"></i> Tra cứu</a>
        <a href="${pageContext.request.contextPath}/doctor/schedule"><i class="bi bi-calendar3"></i> Lịch trực</a>
        <a class="text-danger mt-lg-4" href="${pageContext.request.contextPath}/logout"><i class="bi bi-box-arrow-right"></i> Đăng xuất</a>
    </nav>
</aside>

<main class="doctor-main">
    <c:if test="${not empty sessionScope.doctorMessage}">
        <div class="alert alert-info alert-dismissible fade show">
            ${sessionScope.doctorMessage}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <c:remove var="doctorMessage" scope="session"/>
    </c:if>

    <section class="doctor-card exam-hero mb-4">
        <div class="position-relative d-flex flex-column flex-lg-row justify-content-between gap-3 align-items-lg-center">
            <div>
                <div class="small opacity-75">HỒ SƠ KHÁM #${record.healthRecordId}</div>
                <h1 class="h3 fw-bold mb-1">${record.patientName}</h1>
                <div class="doctor-muted">Bệnh nhân #${record.patientId} · ${patient.age} tuổi · ${patient.gender}</div>
            </div>
            <div class="d-flex flex-wrap gap-2">
                <a class="btn btn-light"
                   href="${pageContext.request.contextPath}/doctor/general-examinations">
                    <i class="bi bi-arrow-left"></i> Quay lại danh sách
                </a>
                <c:if test="${canRunAI && hasCompletedLaboratoryRequest && hasRequiredAIData}">
                    <button class="btn btn-warning" data-bs-toggle="modal" data-bs-target="#aiModal">
                        <i class="bi bi-robot"></i> Chạy AI
                    </button>
                </c:if>
                <c:if test="${canRunAI && hasCompletedLaboratoryRequest && !hasRequiredAIData}">
                    <button class="btn btn-secondary" type="button" disabled
                            title="Cần nhập đủ kết quả xét nghiệm trước khi chạy AI">
                        <i class="bi bi-hourglass-split"></i> Chờ kết quả xét nghiệm
                    </button>
                </c:if>
            </div>
        </div>
    </section>

    <nav class="exam-section-nav" aria-label="Các phần của hồ sơ khám">
        <a href="#patientContext"><i class="bi bi-person-vcard"></i> Bệnh nhân và hội thoại</a>
        <a href="#vitalsSection"><i class="bi bi-heart-pulse"></i> Chỉ số thể chất</a>
        <a href="#laboratoryOrder"><i class="bi bi-clipboard2-plus"></i> Chỉ định xét nghiệm</a>
        <c:if test="${hasCompletedLaboratoryRequest}">
            <a href="#examinationResult"><i class="bi bi-activity"></i> Kết quả khám</a>
        </c:if>
    </nav>

    <section id="patientContext" class="doctor-card mb-4">
        <div class="d-flex flex-column flex-xl-row justify-content-between gap-3 mb-4">
            <div class="d-flex align-items-center gap-3">
                <span class="section-icon"><i class="bi bi-person-lines-fill"></i></span>
                <div>
                    <h2 class="doctor-section-title h5 mb-0">Thông tin bệnh nhân và lịch sử hội thoại</h2>
                    <div class="doctor-muted small">Thông tin hành chính và nội dung bệnh nhân đã trao đổi với trợ lý AI.</div>
                </div>
            </div>
            <a class="btn btn-outline-primary"
               href="${pageContext.request.contextPath}/doctor/records/history?record_id=${record.healthRecordId}">
                <i class="bi bi-clock-history"></i> Xem lịch sử bệnh án
            </a>
        </div>

        <div class="patient-info-grid mb-4">
            <div class="patient-info-item"><div class="patient-info-label">Mã bệnh nhân</div><div class="patient-info-value">#${patient.patientId}</div></div>
            <div class="patient-info-item"><div class="patient-info-label">Họ và tên</div><div class="patient-info-value">${patient.fullName}</div></div>
            <div class="patient-info-item"><div class="patient-info-label">Tuổi</div><div class="patient-info-value">${patient.age} tuổi</div></div>
            <div class="patient-info-item"><div class="patient-info-label">Giới tính</div><div class="patient-info-value">${patient.gender == 'M' ? 'Nam' : (patient.gender == 'F' ? 'Nữ' : patient.gender)}</div></div>
            <div class="patient-info-item wide"><div class="patient-info-label">Điện thoại</div><div class="patient-info-value">${empty patient.phone ? 'Chưa cập nhật' : patient.phone}</div></div>
            <div class="patient-info-item wide"><div class="patient-info-label">Email</div><div class="patient-info-value">${empty patient.email ? 'Chưa cập nhật' : patient.email}</div></div>
            <div class="patient-info-item wide"><div class="patient-info-label">Địa chỉ</div><div class="patient-info-value">${empty patient.address ? 'Chưa cập nhật' : patient.address}</div></div>
            <div class="patient-info-item wide"><div class="patient-info-label">Ngày sinh</div><div class="patient-info-value"><fmt:formatDate value="${patient.dateOfBirth}" pattern="dd/MM/yyyy"/></div></div>
        </div>

        <div class="row g-4">
            <div class="col-lg-12">
                <h3 class="h6 fw-bold mb-3"><i class="bi bi-stars text-warning"></i> Tóm tắt triệu chứng từ AI</h3>
                <c:choose>
                    <c:when test="${empty aiConversation || empty aiConversation.aiSummary}">
                        <div class="chat-summary doctor-muted">Chưa có nội dung triệu chứng được tổng hợp từ cuộc trò chuyện ban đầu.</div>
                    </c:when>
                    <c:otherwise>
                        <div class="chat-summary">${aiConversation.aiSummary}</div>
                        <div class="doctor-muted small mt-2">
                            Cập nhật: <fmt:formatDate value="${aiConversation.createdAt}" pattern="dd/MM/yyyy HH:mm"/>
                        </div>
                    </c:otherwise>
                </c:choose>
            </div>
        </div>
    </section>

    <section id="vitalsSection" class="doctor-card mb-4">
        <div class="d-flex align-items-center gap-3 mb-3">
            <span class="section-icon"><i class="bi bi-heart-pulse"></i></span>
            <div>
                <h2 class="doctor-section-title h5 mb-0">Chỉ số thể chất</h2>
                <div class="doctor-muted small">Cập nhật chiều cao, cân nặng và tự động tính chỉ số BMI của bệnh nhân.</div>
            </div>
        </div>
        
        <div class="row g-3 align-items-end">
            <div class="col-md-3">
                <label class="form-label fw-semibold">Chiều cao (cm)</label>
                <input id="vitalsHeight" type="number" step="0.1" min="30" max="300" class="form-control" 
                       value="${record.height > 0 ? record.height : ''}" 
                       placeholder="Nhập chiều cao (cm)" 
                       ${!canEditDiagnosis ? 'disabled' : ''}>
            </div>
            <div class="col-md-3">
                <label class="form-label fw-semibold">Cân nặng (kg)</label>
                <input id="vitalsWeight" type="number" step="0.1" min="2" max="500" class="form-control" 
                       value="${record.weight > 0 ? record.weight : ''}" 
                       placeholder="Nhập cân nặng (kg)" 
                       ${!canEditDiagnosis ? 'disabled' : ''}>
            </div>
            <div class="col-md-3">
                <label class="form-label fw-semibold">Chỉ số BMI</label>
                <input id="vitalsBmi" type="text" class="form-control bg-light fw-bold" 
                       value="${record.bmi > 0 ? record.bmi : 'Chưa tính'}" 
                       readonly disabled>
            </div>
            <c:if test="${canEditDiagnosis}">
                <div class="col-md-3">
                    <button class="btn btn-doctor w-100" type="button" onclick="saveVitals('${record.healthRecordId}')">
                        <i class="bi bi-save"></i> Lưu chỉ số
                    </button>
                </div>
            </c:if>
        </div>
    </section>

    <section class="doctor-card mb-4">
        <div class="d-flex align-items-center gap-3 mb-3">
            <span class="section-icon"><i class="bi bi-clock-history"></i></span>
            <div>
                <h2 class="doctor-section-title h5 mb-0">Lịch sử bệnh án</h2>
                <div class="doctor-muted small">Thông tin chỉ đọc từ những lần khám trước.</div>
            </div>
        </div>
        <c:choose>
            <c:when test="${empty medicalHistory}">
                <div class="doctor-empty py-3">Bệnh nhân chưa có bệnh án trước đó.</div>
            </c:when>
            <c:otherwise>
                <div class="table-responsive">
                    <table class="table doctor-table align-middle mb-0">
                        <thead><tr><th>Ngày khám</th><th>Chẩn đoán</th><th>Ghi chú bác sĩ</th><th>Kết quả xét nghiệm</th></tr></thead>
                        <tbody>
                         <c:forEach var="history" items="${medicalHistory}">
                             <tr>
                                 <td><fmt:formatDate value="${history.processedAt}" pattern="dd/MM/yyyy HH:mm"/></td>
                                 <td>${empty history.finalDiagnosis ? 'Chưa có' : history.finalDiagnosis}</td>
                                 <td>${empty history.doctorNote ? 'Chưa có' : history.doctorNote}</td>
                                 <td>
                                     Đường huyết ${history.hba1c} · Urea ${history.urea} · CR ${history.cr}
                                     <c:if test="${history.diabetesProbability > 0 || history.preDiabetesProbability > 0 || history.normalProbability > 0}">
                                         <br>
                                         <small class="text-secondary fw-semibold">
                                             AI Dự đoán: 
                                             Tiểu đường (<fmt:formatNumber value="${history.diabetesProbability}" type="percent"/>) · 
                                             Tiền tiểu đường (<fmt:formatNumber value="${history.preDiabetesProbability}" type="percent"/>) · 
                                             Bình thường (<fmt:formatNumber value="${history.normalProbability}" type="percent"/>)
                                         </small>
                                     </c:if>
                                 </td>
                             </tr>
                         </c:forEach>
                        </tbody>
                    </table>
                </div>
            </c:otherwise>
        </c:choose>
    </section>

    <section id="laboratoryOrder" class="doctor-card mb-4">
        <div class="d-flex align-items-center gap-3 mb-3">
            <span class="section-icon"><i class="bi bi-clipboard2-plus"></i></span>
            <div>
                <h2 class="doctor-section-title h5 mb-0">Tạo yêu cầu xét nghiệm</h2>
                <div class="doctor-muted small">Chọn loại xét nghiệm và xem giá trước khi gửi yêu cầu.</div>
            </div>
        </div>

        <c:set var="hasPendingPayment" value="false" />
        <c:forEach var="lab" items="${laboratoryRequests}">
            <c:if test="${lab.status == 'Waiting_Payment'}">
                <c:set var="hasPendingPayment" value="true" />
            </c:if>
        </c:forEach>
        <c:if test="${hasPendingPayment}">
            <div class="alert alert-warning d-flex align-items-center gap-2 mb-3 py-2 px-3 small border-0" style="background: rgba(255, 193, 7, 0.15); color: #ffc107; border-radius: 10px;">
                <i class="bi bi-exclamation-triangle-fill"></i>
                <div>
                    <strong>Lưu ý:</strong> Bệnh nhân có chỉ định xét nghiệm bổ sung đang chờ thanh toán. Yêu cầu sẽ được gửi đến phòng xét nghiệm sau khi bệnh nhân hoàn tất thanh toán hóa đơn.
                </div>
            </div>
        </c:if>

        <c:if test="${record.status == 'Accepted' || record.status == 'AI_Processed' || record.status == 'Editing'}">
            <form class="row g-3 mb-4 lab-request-form lab-multi-form" method="post"
                  action="${pageContext.request.contextPath}/doctor/laboratory-requests/create">
                <input type="hidden" name="record_id" value="${record.healthRecordId}">
                <div class="col-12">
                    <label class="form-label fw-semibold mb-3">Chọn loại xét nghiệm chỉ định</label>
                    <div class="row row-cols-1 row-cols-md-3 row-cols-xl-6 g-3">
                        <c:forEach var="service" items="${laboratoryServices}">
                            <div class="col">
                                <c:set var="iconClass" value="bi-clipboard-pulse" />
                                <c:set var="iconColor" value="text-secondary" />
                                <c:choose>
                                    <c:when test="${service.serviceName == 'Xét nghiệm máu'}">
                                        <c:set var="iconClass" value="bi-droplet-fill" />
                                        <c:set var="iconColor" value="text-danger" />
                                    </c:when>
                                    <c:when test="${service.serviceName == 'Chức năng gan'}">
                                        <c:set var="iconClass" value="bi-hospital" />
                                        <c:set var="iconColor" value="text-success" />
                                    </c:when>
                                    <c:when test="${service.serviceName == 'Chức năng thận'}">
                                        <c:set var="iconClass" value="bi-shield-shaded" />
                                        <c:set var="iconColor" value="text-info" />
                                    </c:when>
                                    <c:when test="${service.serviceName == 'Xét nghiệm đường huyết'}">
                                        <c:set var="iconClass" value="bi-activity" />
                                        <c:set var="iconColor" value="text-warning" />
                                    </c:when>
                                    <c:when test="${service.serviceName == 'Xét nghiệm nước tiểu'}">
                                        <c:set var="iconClass" value="bi-droplet" />
                                        <c:set var="iconColor" value="text-primary" />
                                    </c:when>
                                    <c:when test="${service.serviceName == 'Xét nghiệm mỡ máu'}">
                                        <c:set var="iconClass" value="bi-speedometer2" />
                                        <c:set var="iconColor" value="text-danger" />
                                    </c:when>
                                </c:choose>
                                <label class="lab-service-option mb-2 w-100 h-100">
                                    <input class="form-check-input" type="checkbox" name="service_id" value="${service.serviceId}">
                                    <i class="bi ${iconClass} ${iconColor} fs-4"></i>
                                    <span>
                                        <strong class="d-block text-white" style="font-size: 0.9rem;">${service.serviceName}</strong>
                                        <small class="text-secondary"><fmt:formatNumber value="${service.price}" type="number" groupingUsed="true"/> VNĐ</small>
                                    </span>
                                </label>
                            </div>
                        </c:forEach>
                    </div>
                </div>
                <div class="col-lg-4">
                    <label class="form-label fw-semibold">Ghi chú cho phòng xét nghiệm</label>
                    <input class="form-control" name="request_note" maxlength="1000"
                           placeholder="Nội dung cần lưu ý">
                </div>
                <div class="col-lg-5">
                    <label class="form-label fw-semibold">Bác sĩ phòng xét nghiệm</label>
                    <select class="form-select" name="lab_id" required>
                        <option value="" disabled selected>-- Chọn bác sĩ --</option>
                        <c:forEach var="doc" items="${labDoctors}">
                            <option value="${doc.labId}">${doc.fullName} (${fn:replace(doc.labName, 'Phòng Xét nghiệm ', '')}) - Chờ: ${doc.waitingPatients} BN</option>
                        </c:forEach>
                    </select>
                </div>
                <div class="col-lg-3 d-flex align-items-end">
                    <button class="btn btn-doctor w-100" type="submit">
                        <i class="bi bi-send"></i> Gửi yêu cầu
                    </button>
                </div>
            </form>
        </c:if>
        <c:choose>
            <c:when test="${empty laboratoryRequests}">
                <div class="doctor-empty py-3">Chưa có yêu cầu xét nghiệm cho hồ sơ này.</div>
            </c:when>
            <c:otherwise>
                <div class="table-responsive">
                    <table class="table doctor-table align-middle mb-0">
                        <thead>
                        <tr><th>Loại xét nghiệm</th><th>Giá</th><th>Bác sĩ thực hiện</th><th>Thanh toán</th><th>Ngày yêu cầu</th><th>Trạng thái</th></tr>
                        </thead>
                        <tbody>
                        <c:forEach var="lab" items="${laboratoryRequests}">
                            <tr>
                                <td><strong>${lab.testTypeDisplay}</strong><br><small class="doctor-muted">${lab.requestNote}</small></td>
                                <td class="fw-semibold">
                                    <fmt:formatNumber value="${lab.testPrice}" type="number" groupingUsed="true"/> VNĐ
                                </td>
                                <td>
                                    <c:choose>
                                        <c:when test="${not empty lab.labDoctorName}">
                                            ${lab.labDoctorName} <br><small class="doctor-muted">(${lab.labName})</small>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="text-muted">Chưa phân công</span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                                <td>${lab.paymentStatusDisplay}</td>
                                <td><fmt:formatDate value="${lab.requestedAt}" pattern="dd/MM/yyyy HH:mm"/></td>
                                <td><span class="doctor-badge ${lab.status == 'Completed' ? 'badge-completed' : (lab.status == 'Processing' ? 'badge-processing' : 'badge-requested')}">${lab.statusDisplay}</span></td>
                            </tr>
                        </c:forEach>
                        </tbody>
                    </table>
                </div>
            </c:otherwise>
        </c:choose>
    </section>

    <c:if test="${hasCompletedLaboratoryRequest}">
    <div id="examinationResult" class="row g-4 align-items-start">
        <div class="col-xl-7">
            <section class="doctor-card mb-4">
                <div class="d-flex align-items-center gap-3 mb-3">
                    <span class="section-icon"><i class="bi bi-activity"></i></span>
                    <div>
                        <h2 class="doctor-section-title h5 mb-0">Thông tin xét nghiệm</h2>
                        <div class="doctor-muted small">Các chỉ số mới nhất từ phòng xét nghiệm.</div>
                    </div>
                </div>
                <div class="exam-grid">
                    <div class="exam-metric"><div class="exam-metric-label">Urea</div><input id="metricUrea" class="form-control form-control-sm bg-light text-dark fw-bold" type="text" value="${record.urea != null ? record.urea : 'Chưa có'}" readonly disabled></div>
                    <div class="exam-metric"><div class="exam-metric-label">Creatinine</div><input id="metricCr" class="form-control form-control-sm bg-light text-dark fw-bold" type="text" value="${record.cr != null ? record.cr : 'Chưa có'}" readonly disabled></div>
                    <div class="exam-metric"><div class="exam-metric-label">Đường huyết (HbA1c)</div><input id="metricHba1c" class="form-control form-control-sm bg-light text-dark fw-bold" type="text" value="${record.hba1c != null ? record.hba1c : 'Chưa có'}" readonly disabled></div>
                    <div class="exam-metric"><div class="exam-metric-label">Cholesterol</div><input id="metricChol" class="form-control form-control-sm bg-light text-dark fw-bold" type="text" value="${record.chol != null ? record.chol : 'Chưa có'}" readonly disabled></div>
                    <div class="exam-metric"><div class="exam-metric-label">TG</div><input id="metricTg" class="form-control form-control-sm bg-light text-dark fw-bold" type="text" value="${record.tg != null ? record.tg : 'Chưa có'}" readonly disabled></div>
                    <div class="exam-metric"><div class="exam-metric-label">HDL</div><input id="metricHdl" class="form-control form-control-sm bg-light text-dark fw-bold" type="text" value="${record.hdl != null ? record.hdl : 'Chưa có'}" readonly disabled></div>
                    <div class="exam-metric"><div class="exam-metric-label">LDL</div><input id="metricIdl" class="form-control form-control-sm bg-light text-dark fw-bold" type="text" value="${record.ldl != null ? record.ldl : 'Chưa có'}" readonly disabled></div>
                    <div class="exam-metric"><div class="exam-metric-label">VLDL</div><input id="metricVldl" class="form-control form-control-sm bg-light text-dark fw-bold" type="text" value="${record.vldl != null ? record.vldl : 'Chưa có'}" readonly disabled></div>
                    <div class="exam-metric"><div class="exam-metric-label">BMI</div><input id="metricBmi" class="form-control form-control-sm bg-light text-dark fw-bold" type="text" value="${record.bmi != null ? record.bmi : 'Chưa có'}" readonly disabled></div>
                </div>
            </section>

            <c:if test="${hasAIResult}">
            <section class="doctor-card">
                <div class="d-flex justify-content-between align-items-start gap-3 mb-3">
                    <div class="d-flex align-items-center gap-3">
                        <span class="section-icon"><i class="bi bi-cpu"></i></span>
                        <div>
                            <h2 class="doctor-section-title h5 mb-0">Kết quả AI</h2>
                            <div class="doctor-muted small">Công cụ hỗ trợ đánh giá nguy cơ.</div>
                        </div>
                    </div>
                    <span class="doctor-badge badge-requested">Tham khảo</span>
                </div>
                <div class="alert alert-warning"><i class="bi bi-info-circle"></i> Chẩn đoán cuối cùng thuộc trách nhiệm của bác sĩ.</div>
                <div class="mb-3">
                    <div class="d-flex justify-content-between mb-1"><strong>Tiểu đường</strong><fmt:formatNumber value="${record.diabetes_probability}" type="percent"/></div>
                    <div class="progress ai-progress"><div class="progress-bar bg-danger" style="width:${record.diabetes_probability * 100}%"></div></div>
                </div>
                <div class="mb-3">
                    <div class="d-flex justify-content-between mb-1"><strong>Tiền tiểu đường</strong><fmt:formatNumber value="${record.pre_diabetes_probability}" type="percent"/></div>
                    <div class="progress ai-progress"><div class="progress-bar bg-warning" style="width:${record.pre_diabetes_probability * 100}%"></div></div>
                </div>
                <div>
                    <div class="d-flex justify-content-between mb-1"><strong>Bình thường</strong><fmt:formatNumber value="${record.normal_probability}" type="percent"/></div>
                    <div class="progress ai-progress"><div class="progress-bar bg-success" style="width:${record.normal_probability * 100}%"></div></div>
                </div>
            </section>
            </c:if>

            <c:if test="${!hasAIResult}">
                <section class="doctor-card">
                    <div class="d-flex align-items-center gap-3">
                        <span class="section-icon"><i class="bi bi-robot"></i></span>
                        <div>
                            <h2 class="doctor-section-title h5 mb-1">Chờ phân tích AI</h2>
                            <div class="doctor-muted">
                                Kết quả xét nghiệm đã có. Hãy chạy AI để mở phần kết luận của bác sĩ.
                            </div>
                        </div>
                    </div>
                </section>
            </c:if>
        </div>

        <c:if test="${hasCompletedLaboratoryRequest}">
        <div class="col-xl-5">
            <section class="doctor-card diagnosis-panel">
                <div class="d-flex align-items-center gap-3 mb-3">
                    <span class="section-icon"><i class="bi bi-journal-medical"></i></span>
                    <div>
                        <h2 class="doctor-section-title h5 mb-0">Kết quả của bác sĩ</h2>
                        <div class="doctor-muted small">${canEditDiagnosis ? 'Có thể cập nhật và hoàn thành hồ sơ.' : 'Hồ sơ đang ở chế độ chỉ đọc.'}</div>
                    </div>
                </div>
                <div class="mb-3">
                    <label class="form-label fw-bold">Ghi chú bác sĩ</label>
                    <textarea id="doctorNotes" class="form-control" rows="7" ${!canEditDiagnosis ? 'disabled' : ''}>${record.doctor_notes}</textarea>
                </div>
                <div class="mb-3">
                    <label class="form-label fw-bold">Chẩn đoán cuối cùng</label>
                    <select id="finalDiagnosis" class="form-select" ${!canEditDiagnosis ? 'disabled' : ''}>
                        <option value="Bình thường" ${record.finalDiagnosis == 'Bình thường' ? 'selected' : ''}>Bình thường</option>
                        <option value="Tiền tiểu đường" ${record.finalDiagnosis == 'Tiền tiểu đường' ? 'selected' : ''}>Tiền tiểu đường</option>
                        <option value="Tiểu đường" ${record.finalDiagnosis == 'Tiểu đường' ? 'selected' : ''}>Tiểu đường</option>
                    </select>
                </div>
                <div class="mb-3">
                    <label class="form-label fw-bold">Hẹn ngày tái khám (Không bắt buộc)</label>
                    <input id="revisitDate" type="date" class="form-control" ${!canEditDiagnosis ? 'disabled' : ''} value="${record.revisitDateFormatted}">
                </div>
                <div class="form-check mb-4">
                    <input id="canView" class="form-check-input" type="checkbox"
                           ${record.canPatientView ? 'checked' : ''} ${!canEditDiagnosis ? 'disabled' : ''}>
                    <label class="form-check-label" for="canView">Cho phép bệnh nhân xem kết quả</label>
                </div>
                <c:if test="${canEditDiagnosis}">
                    <c:if test="${hasPendingPayment}">
                        <div class="alert alert-danger py-2 px-3 small mb-3 border-0 d-flex align-items-center gap-2" style="background: rgba(220, 53, 69, 0.1); color: #dc3545; border-radius: 8px;">
                            <i class="bi bi-exclamation-circle-fill"></i>
                            <span>Bệnh nhân chưa thanh toán xét nghiệm bổ sung. Bạn không thể hoàn thành hồ sơ lúc này.</span>
                        </div>
                    </c:if>
                    <button class="btn btn-doctor w-100" onclick="saveNotes('${record.healthRecordId}')" ${hasPendingPayment ? 'disabled' : ''}>
                        <i class="bi bi-save"></i> Lưu và hoàn thành
                    </button>
                </c:if>
            </section>
        </div>
        </c:if>
    </div>
    </c:if>

</main>

<div class="modal fade" id="aiModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header"><h5 class="modal-title">Phân tích AI</h5><button class="btn-close" data-bs-dismiss="modal"></button></div>
            <div class="modal-body">Hệ thống sẽ gửi các chỉ số xét nghiệm hiện tại sang AI để phân tích.</div>
            <div class="modal-footer">
                <form action="${pageContext.request.contextPath}/doctor/ai/process" method="post">
                    <input type="hidden" name="record_id" value="${record.healthRecordId}">
                    <button class="btn btn-warning" type="submit">Xác nhận chạy AI</button>
                </form>
            </div>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
document.addEventListener("DOMContentLoaded", () => {
    const revisitInput = document.getElementById("revisitDate");
    if (revisitInput) {
        revisitInput.min = new Date().toISOString().split('T')[0];
    }

    // Live BMI calculation
    const hInput = document.getElementById("vitalsHeight");
    const wInput = document.getElementById("vitalsWeight");
    
    function calculateLiveBmi() {
        const heightVal = parseFloat(hInput.value);
        const weightVal = parseFloat(wInput.value);
        const bmiInput = document.getElementById("vitalsBmi");
        const metricBmiInput = document.getElementById("metricBmi");
        
        if (heightVal > 0 && weightVal > 0) {
            const heightInMeters = heightVal / 100;
            const bmi = weightVal / (heightInMeters * heightInMeters);
            const roundedBmi = bmi.toFixed(2);
            bmiInput.value = roundedBmi;
            if (metricBmiInput) {
                metricBmiInput.value = roundedBmi;
            }
        } else {
            bmiInput.value = "Chưa tính";
            if (metricBmiInput) {
                metricBmiInput.value = "Chưa có";
            }
        }
    }
    
    if (hInput && wInput) {
        hInput.addEventListener("input", calculateLiveBmi);
        wInput.addEventListener("input", calculateLiveBmi);
        // Run once on load to ensure sync if height and weight are pre-populated
        calculateLiveBmi();
    }
});

function saveVitals(recordId) {
    const heightVal = document.getElementById("vitalsHeight").value;
    const weightVal = document.getElementById("vitalsWeight").value;
    
    const height = parseFloat(heightVal);
    const weight = parseFloat(weightVal);
    
    if (!heightVal || isNaN(height) || height < 30 || height > 300) {
        alert("Chiều cao hợp lệ phải nằm trong khoảng từ 30 cm đến 300 cm.");
        return;
    }
    if (!weightVal || isNaN(weight) || weight < 2 || weight > 500) {
        alert("Cân nặng hợp lệ phải nằm trong khoảng từ 2 kg đến 500 kg.");
        return;
    }
    
    const body = new URLSearchParams({
        record_id: recordId,
        height: heightVal,
        weight: weightVal
    });
    
    fetch("${pageContext.request.contextPath}/doctor/records/save-vitals", {
        method: "POST",
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: body.toString()
    })
    .then(async response => {
        const data = await response.json();
        if (!response.ok || !data.success) throw new Error(data.message || "Không thể lưu chỉ số thể chất");
        alert(data.message);
        if (data.bmi > 0) {
            document.getElementById("vitalsBmi").value = data.bmi;
            const metricBmiInput = document.getElementById("metricBmi");
            if (metricBmiInput) {
                metricBmiInput.value = data.bmi;
            }
        }
    })
    .catch(error => alert(error.message));
}

function saveNotes(recordId) {
    const revisitDateVal = document.getElementById("revisitDate").value;
    if (revisitDateVal) {
        const selectedDate = new Date(revisitDateVal);
        selectedDate.setHours(0, 0, 0, 0);
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        if (selectedDate < today) {
            alert("Ngày tái khám không được là ngày trong quá khứ!");
            return;
        }
    }

    const body = new URLSearchParams({
        record_id: recordId,
        notes: document.getElementById("doctorNotes").value,
        diagnosis: document.getElementById("finalDiagnosis").value,
        can_view: document.getElementById("canView").checked,
        revisit_date: document.getElementById("revisitDate").value
    });
    fetch("${pageContext.request.contextPath}/doctor/records/save", {
        method: "POST",
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: body.toString()
    })
    .then(async response => {
        const data = await response.json();
        if (!response.ok || !data.success) throw new Error(data.message || "Không thể lưu hồ sơ");
    })
    .then(() => window.location.href = "${pageContext.request.contextPath}/doctor/completed-records")
    .catch(error => alert(error.message));
}

document.querySelectorAll(".lab-multi-form").forEach(form => {
    const options = form.querySelectorAll(".lab-service-option");
    const select = form.querySelector('select[name="lab_id"]');
    options.forEach(option => {
        const checkbox = option.querySelector('input[name="service_id"]');
        const updateSelectedState = () => {
            option.classList.toggle("is-selected", checkbox.checked);
            if (checkbox.checked && select) {
                const serviceText = option.querySelector('strong').textContent.toLowerCase();
                let targetKeyword = "";
                if (serviceText.includes("gan") || serviceText.includes("ast") || serviceText.includes("alt") || serviceText.includes("ggt") || serviceText.includes("bilirubin") || serviceText.includes("protein")) {
                    targetKeyword = "gan";
                } else if (serviceText.includes("th\u1eadn") || serviceText.includes("ure") || serviceText.includes("creatinine") || serviceText.includes("egfr")) {
                    targetKeyword = "th\u1eadn";
                } else if (serviceText.includes("n\u01b0\u1edbc ti\u1ec3u") || serviceText.includes("urine")) {
                    targetKeyword = "n\u01b0\u1edbc ti\u1ec3u";
                } else {
                    targetKeyword = "m\u00e1u";
                }
                if (targetKeyword) {
                    for (let i = 0; i < select.options.length; i++) {
                        const opt = select.options[i];
                        const optText = opt.textContent.toLowerCase();
                        if (optText.includes(targetKeyword)) {
                            select.value = opt.value;
                            break;
                        }
                    }
                }
            }
        };
        checkbox.addEventListener("change", updateSelectedState);
        updateSelectedState();
    });

    form.addEventListener("submit", event => {
        if (!form.querySelector('input[name="service_id"]:checked')) {
            event.preventDefault();
            alert("Vui lòng chọn ít nhất một loại xét nghiệm.");
        }
    });
});
</script>
</body>
</html>
