<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>
<%@taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Khám tổng quát - Hồ sơ #${record.healthRecordId}</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/assets/css/pages/doctor/doctor.css?v=20260721-ui2" rel="stylesheet">
    <style>
        .exam-hero {
            overflow: hidden;
            position: relative;
            color: #fff;
            background: linear-gradient(135deg, rgba(42, 181, 163, 0.25), rgba(15, 23, 42, 0.95)) !important;
            border: 1px solid rgba(255, 255, 255, 0.1) !important;
            border-radius: 18px !important;
        }
        .exam-hero::after {
            position: absolute;
            right: -55px;
            top: -85px;
            width: 230px;
            height: 230px;
            border-radius: 50%;
            content: "";
            background: rgba(255,255,255,.05);
            pointer-events: none;
            z-index: 0;
        }
        .exam-hero > .position-relative {
            position: relative;
            z-index: 2;
        }
        .exam-hero .doctor-muted { color: #94A3B8 !important; }
        .section-icon {
            display:grid; width:42px; height:42px; place-items:center;
            border-radius:13px; background: rgba(42, 181, 163, 0.15) !important; color:#2AB5A3 !important;
            border: 1px solid rgba(42, 181, 163, 0.2);
        }
        .exam-section-nav {
            display:flex; flex-wrap:wrap; gap:10px; margin-bottom:24px;
        }
        .exam-section-nav a {
            display:inline-flex; align-items:center; gap:8px; padding:10px 15px;
            border:1px solid rgba(255, 255, 255, 0.12) !important; border-radius:999px;
            background: rgba(15, 23, 42, 0.75) !important; color:#94A3B8 !important; font-weight:700;
            text-decoration:none; transition: all 0.2s ease;
        }
        .exam-section-nav a:hover { border-color:#2AB5A3 !important; color:#2AB5A3 !important; background: rgba(42, 181, 163, 0.15) !important; }
        .patient-info-grid {
            display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:12px;
        }
        .patient-info-item {
            min-height:88px; padding:15px; border:1px solid rgba(255, 255, 255, 0.08) !important;
            border-radius:14px; background: rgba(15, 23, 42, 0.6) !important; color: #F8FAFC !important;
        }
        .patient-info-item.wide { grid-column:span 2; }
        .patient-info-label {
            margin-bottom:5px; color:#94A3B8 !important; font-size:.76rem;
            font-weight:800; letter-spacing:.04em; text-transform:uppercase;
        }
        .patient-info-value { font-size:1rem; font-weight:700; overflow-wrap:anywhere; color: #FFFFFF !important; }
        .lab-request-form {
            padding:20px; border:1px solid rgba(255, 255, 255, 0.08) !important; border-radius:16px;
            background: rgba(15, 23, 42, 0.6) !important;
        }
        .lab-request-form .form-label { margin-bottom:8px; font-size:.92rem; color:#94A3B8 !important; }
        .lab-request-form .form-control,
        .lab-request-form .form-select { min-height:48px; font-size:1rem; }
        .lab-request-form .btn { min-height:48px; font-weight:800; }
        @media (max-width:767px) {
            .patient-info-grid { grid-template-columns:1fr 1fr; }
            .patient-info-item.wide { grid-column:span 2; }
        }
    </style>
</head>
<body class="doctor-app">
<c:set var="canEditVitals" value="${record.status == 'Accepted' || record.status == 'AI_Processed' || record.status == 'Editing'}"/>

<c:set var="activeDoctorPage" value="general-examinations" />
<%@ include file="/WEB-INF/views/components/doctor/sidebar.jspf" %>

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
                <div class="small opacity-75">BƯỚC 2: KHÁM TỔNG QUÁT · HỒ SƠ #${record.healthRecordId}</div>
                <h1 class="h3 fw-bold mb-1">${record.patientName}</h1>
                <div class="doctor-muted">Bệnh nhân #${record.patientId} · ${patient.age} tuổi · ${patient.gender}</div>
            </div>
            <div class="d-flex flex-wrap gap-2">
                <a class="btn btn-light" href="${pageContext.request.contextPath}/doctor/general-examinations">
                    <i class="bi bi-arrow-left"></i> Quay lại danh sách Khám tổng quát
                </a>
            </div>
        </div>
    </section>

    <nav class="exam-section-nav" aria-label="Các phần của hồ sơ khám">
        <a href="#patientContext"><i class="bi bi-person-vcard"></i> Bệnh nhân và hội thoại AI</a>
        <a href="#vitalsSection"><i class="bi bi-heart-pulse"></i> Chỉ số thể chất</a>
        <a href="#historySection"><i class="bi bi-clock-history"></i> Lịch sử bệnh án</a>
        <a href="#laboratoryOrder"><i class="bi bi-clipboard2-plus"></i> Chỉ định xét nghiệm & Hóa đơn</a>
    </nav>

    <section id="patientContext" class="doctor-card mb-4">
        <div class="d-flex flex-column flex-xl-row justify-content-between gap-3 mb-4">
            <div class="d-flex align-items-center gap-3">
                <span class="section-icon"><i class="bi bi-person-lines-fill"></i></span>
                <div>
                    <h2 class="doctor-section-title h5 mb-0">Thông tin bệnh nhân và hội thoại ban đầu</h2>
                    <div class="doctor-muted small">Thông tin hành chính và nội dung bệnh nhân đã trao đổi với trợ lý AI.</div>
                </div>
            </div>
            <a class="btn btn-outline-primary" href="${pageContext.request.contextPath}/doctor/records/history?record_id=${record.healthRecordId}">
                <i class="bi bi-clock-history"></i> Xem chi tiết lịch sử bệnh án
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
                <h3 class="h6 fw-bold mb-3"><i class="bi bi-stars text-warning"></i> Tóm tắt triệu chứng từ AI ban đầu</h3>
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
                <h2 class="doctor-section-title h5 mb-0">Chỉ số thể chất ban đầu</h2>
                <div class="doctor-muted small">Cập nhật chiều cao, cân nặng và tự động tính chỉ số BMI của bệnh nhân.</div>
            </div>
        </div>
        
        <div class="row g-3 align-items-end">
            <div class="col-md-3">
                <label class="form-label fw-semibold">Chiều cao (cm)</label>
                <input id="vitalsHeight" type="number" step="0.1" min="30" max="300" class="form-control" 
                       value="${record.height > 0 ? record.height : ''}" 
                       placeholder="Nhập chiều cao (cm)" 
                       ${!canEditVitals ? 'disabled' : ''}>
            </div>
            <div class="col-md-3">
                <label class="form-label fw-semibold">Cân nặng (kg)</label>
                <input id="vitalsWeight" type="number" step="0.1" min="2" max="500" class="form-control" 
                       value="${record.weight > 0 ? record.weight : ''}" 
                       placeholder="Nhập cân nặng (kg)" 
                       ${!canEditVitals ? 'disabled' : ''}>
            </div>
            <div class="col-md-3">
                <label class="form-label fw-semibold">Chỉ số BMI</label>
                <input id="vitalsBmi" type="text" class="form-control fw-bold" style="color: #34d399 !important;" 
                       value="${record.bmi > 0 ? record.bmi : 'Chưa tính'}" 
                       readonly disabled>
            </div>
            <c:if test="${canEditVitals}">
                <div class="col-md-3">
                    <button class="btn btn-doctor w-100" type="button" onclick="saveVitals('${record.healthRecordId}')">
                        <i class="bi bi-save"></i> Lưu chỉ số thể chất
                    </button>
                </div>
            </c:if>
        </div>
    </section>

    <section id="historySection" class="doctor-card mb-4">
        <div class="d-flex align-items-center gap-3 mb-3">
            <span class="section-icon"><i class="bi bi-clock-history"></i></span>
            <div>
                <h2 class="doctor-section-title h5 mb-0">Lịch sử bệnh án cũ</h2>
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
                        <thead><tr><th>Ngày khám</th><th>Chẩn đoán</th><th>Ghi chú bác sĩ</th><th>Kết quả xét nghiệm cũ</th></tr></thead>
                        <tbody>
                         <c:forEach var="history" items="${medicalHistory}">
                             <tr>
                                 <td><fmt:formatDate value="${history.processedAt}" pattern="dd/MM/yyyy HH:mm"/></td>
                                 <td>${empty history.finalDiagnosis ? 'Chưa có' : history.finalDiagnosis}</td>
                                 <td>${empty history.doctorNote ? 'Chưa có' : history.doctorNote}</td>
                                 <td>
                                     Đường huyết ${history.hba1c} · Urea ${history.urea} · CR ${history.cr}
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
                <h2 class="doctor-section-title h5 mb-0">Chỉ định xét nghiệm & Tạo hóa đơn</h2>
                <div class="doctor-muted small">Phân loại các xét nghiệm cần thiết, chọn bác sĩ phòng Lab và gửi yêu cầu hóa đơn.</div>
            </div>
        </div>

        <c:set var="hasPendingPayment" value="false" />
        <c:forEach var="lab" items="${laboratoryRequests}">
            <c:if test="${lab.status == 'Waiting_Payment'}">
                <c:set var="hasPendingPayment" value="true" />
            </c:if>
        </c:forEach>
        <c:if test="${hasPendingPayment}">
            <div class="alert alert-warning d-flex align-items-center gap-2 mb-3 py-3 px-3 small border-0" style="background: rgba(255, 193, 7, 0.15); color: #ffc107; border-radius: 12px;">
                <i class="bi bi-exclamation-triangle-fill fs-5"></i>
                <div>
                    <strong>Yêu cầu đang chờ thanh toán:</strong> Đã tạo chỉ định xét nghiệm cho hồ sơ này. Vui lòng hướng dẫn bệnh nhân thực hiện thanh toán hóa đơn trực tuyến hoặc tại bàn Lễ tân. Sau khi thanh toán hoàn tất (trạng thái Paid), hồ sơ sẽ tự động gửi tới Bác sĩ phòng Lab.
                </div>
            </div>
        </c:if>

        <c:if test="${record.status == 'Accepted' || record.status == 'AI_Processed' || record.status == 'Editing'}">
            <form class="row g-3 mb-4 lab-request-form lab-multi-form" method="post"
                  action="${pageContext.request.contextPath}/doctor/laboratory-requests/create">
                <input type="hidden" name="record_id" value="${record.healthRecordId}">
                <div class="col-12">
                    <label class="form-label fw-semibold mb-3">Chọn danh mục xét nghiệm chỉ định</label>
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
                    <input class="form-control" name="request_note" maxlength="1000" placeholder="Nội dung cần lưu ý">
                </div>
                <div class="col-lg-5">
                    <label class="form-label fw-semibold">Bác sĩ phòng xét nghiệm</label>
                    <select class="form-select" name="lab_id" required>
                        <c:choose>
                            <c:when test="${empty labDoctors}">
                                <option value="" disabled selected>-- Chưa có bác sĩ xét nghiệm trực hôm nay --</option>
                            </c:when>
                            <c:otherwise>
                                <option value="" disabled selected>-- Chọn bác sĩ xét nghiệm --</option>
                                <c:forEach var="doc" items="${labDoctors}">
                                    <option value="${doc.labId}"><c:out value="${empty doc.displayLabel ? doc.fullName : doc.displayLabel}" /></option>
                                </c:forEach>
                            </c:otherwise>
                        </c:choose>
                    </select>
                </div>
                <div class="col-lg-3 d-flex align-items-end">
                    <button class="btn btn-doctor w-100" type="submit">
                        <i class="bi bi-send"></i> Gửi yêu cầu & Tạo hóa đơn
                    </button>
                </div>
            </form>
        </c:if>

        <h3 class="h6 fw-bold mb-3">Danh sách chỉ định xét nghiệm của hồ sơ này</h3>
        <c:choose>
            <c:when test="${empty laboratoryRequests}">
                <div class="doctor-empty py-3">Chưa có yêu cầu xét nghiệm cho hồ sơ này.</div>
            </c:when>
            <c:otherwise>
                <div class="table-responsive">
                    <table class="table doctor-table align-middle mb-0">
                        <thead>
                        <tr><th>Loại xét nghiệm</th><th>Giá</th><th>Bác sĩ thực hiện</th><th>Thanh toán</th><th>Ngày yêu cầu</th><th>Trạng thái Lab</th></tr>
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

    <section id="doctorDiagnosisSection" class="doctor-card mb-4">
        <div class="d-flex align-items-center gap-3 mb-3">
            <span class="section-icon"><i class="bi bi-journal-medical"></i></span>
            <div>
                <h2 class="doctor-section-title h5 mb-0">Kết quả & Chẩn đoán của bác sĩ</h2>
                <div class="doctor-muted small">Cập nhật ghi chú khám, chẩn đoán cuối cùng và hoàn thành hồ sơ khám.</div>
            </div>
        </div>
        <div class="row g-3">
            <div class="col-lg-8">
                <div class="mb-3">
                    <label class="form-label fw-bold">Ghi chú bác sĩ</label>
                    <textarea id="doctorNotes" class="form-control" rows="5" placeholder="Nhập ghi chú hoặc kết luận lâm sàng...">${record.doctor_notes}</textarea>
                </div>
            </div>
            <div class="col-lg-4">
                <div class="mb-3">
                    <label class="form-label fw-bold">Chẩn đoán cuối cùng</label>
                    <select id="finalDiagnosis" class="form-select">
                        <option value="Bình thường" ${record.finalDiagnosis == 'Bình thường' ? 'selected' : ''}>Bình thường</option>
                        <option value="Tiền tiểu đường" ${record.finalDiagnosis == 'Tiền tiểu đường' ? 'selected' : ''}>Tiền tiểu đường</option>
                        <option value="Tiểu đường Type 1" ${record.finalDiagnosis == 'Tiểu đường Type 1' or record.finalDiagnosis == 'Tiểu Đường Type 1' ? 'selected' : ''}>Tiểu Đường Type 1</option>
                        <option value="Tiểu đường Type 2" ${record.finalDiagnosis == 'Tiểu đường Type 2' or record.finalDiagnosis == 'Tiểu Đường Type 2' or record.finalDiagnosis == 'Tiểu đường' ? 'selected' : ''}>Tiểu Đường Type 2</option>
                        <option value="Tiểu đường Thai Kỳ" ${record.finalDiagnosis == 'Tiểu đường Thai Kỳ' or record.finalDiagnosis == 'Tiểu đường Thai kỳ' ? 'selected' : ''}>Tiểu Đường Thai Kỳ</option>
                    </select>
                </div>
                <div class="mb-3">
                    <label class="form-label fw-bold">Hẹn ngày tái khám (Không bắt buộc)</label>
                    <input id="revisitDate" type="date" class="form-control" value="${record.revisitDateFormatted}">
                </div>
                <div class="form-check mb-3">
                    <input id="canView" class="form-check-input" type="checkbox" ${record.canPatientView ? 'checked' : ''}>
                    <label class="form-check-label" for="canView">Cho phép bệnh nhân xem kết quả</label>
                </div>
                <button class="btn btn-doctor w-100" type="button" onclick="saveNotes('${record.healthRecordId}')">
                    <i class="bi bi-save me-1"></i> Lưu và hoàn thành
                </button>
            </div>
        </div>
    </section>
</main>

<script>
function openTransferModal() {
    const modalEl = document.getElementById("transferModal");
    if (!modalEl) return;
    try {
        if (typeof bootstrap !== 'undefined' && bootstrap.Modal) {
            const bsModal = bootstrap.Modal.getOrCreateInstance(modalEl);
            bsModal.show();
            return;
        }
    } catch (e) {
        console.warn("Bootstrap modal fallback", e);
    }
    modalEl.classList.add("show");
    modalEl.style.display = "block";
    document.body.classList.add("modal-open");
    if (!document.querySelector(".modal-backdrop")) {
        const backdrop = document.createElement("div");
        backdrop.className = "modal-backdrop fade show";
        backdrop.id = "transferBackdrop";
        document.body.appendChild(backdrop);
    }
}

function closeTransferModal() {
    const modalEl = document.getElementById("transferModal");
    if (!modalEl) return;
    try {
        if (typeof bootstrap !== 'undefined' && bootstrap.Modal) {
            const bsModal = bootstrap.Modal.getInstance(modalEl);
            if (bsModal) bsModal.hide();
        }
    } catch (e) {}
    modalEl.classList.remove("show");
    modalEl.style.display = "none";
    document.body.classList.remove("modal-open");
    const backdrop = document.getElementById("transferBackdrop");
    if (backdrop) backdrop.remove();
}

function saveVitals(recordId) {
    const hInput = document.getElementById("vitalsHeight");
    const wInput = document.getElementById("vitalsWeight");
    if (!hInput || !wInput) return;
    const height = hInput.value;
    const weight = wInput.value;
    if (!height || !weight) {
        alert("Vui lòng nhập đầy đủ chiều cao và cân nặng.");
        return;
    }
    fetch("${pageContext.request.contextPath}/doctor/records/save-vitals", {
        method: "POST",
        headers: { "Content-Type": "x-www-form-urlencoded" },
        body: "record_id=" + recordId + "&height=" + height + "&weight=" + weight
    }).then(r => r.json()).then(data => {
        if (data.success) {
            if (document.getElementById("vitalsBmi")) {
                document.getElementById("vitalsBmi").value = data.bmi || "";
            }
            alert("Đã lưu chỉ số thể chất thành công!");
        } else {
            alert("Lỗi: " + (data.message || "Không thể lưu chỉ số thể chất"));
        }
    }).catch(e => {
        alert("Lỗi kết nối khi lưu chỉ số thể chất.");
    });
}

document.querySelectorAll("#vitalsHeight, #vitalsWeight").forEach(input => {
    input.addEventListener("input", () => {
        const h = parseFloat(document.getElementById("vitalsHeight").value) / 100;
        const w = parseFloat(document.getElementById("vitalsWeight").value);
        if (h > 0 && w > 0) {
            const bmi = (w / (h * h)).toFixed(2);
            document.getElementById("vitalsBmi").value = bmi;
        }
    });
});

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
                } else if (serviceText.includes("thận") || serviceText.includes("ure") || serviceText.includes("creatinine") || serviceText.includes("egfr")) {
                    targetKeyword = "thận";
                } else if (serviceText.includes("nước tiểu") || serviceText.includes("urine")) {
                    targetKeyword = "nước tiểu";
                } else {
                    targetKeyword = "máu";
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

function saveNotes(recordId) {
    if (!recordId || recordId === "undefined" || recordId === "null" || recordId === "0") {
        alert("Không tìm thấy mã hồ sơ. Vui lòng tải lại trang.");
        return;
    }

    const revisitInput = document.getElementById("revisitDate");
    const notesInput = document.getElementById("doctorNotes");
    const diagnosisInput = document.getElementById("finalDiagnosis");
    const canViewInput = document.getElementById("canView");

    const revisitDateVal = (revisitInput && revisitInput.value) ? revisitInput.value : "";
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

    const notesVal = notesInput ? notesInput.value : "";
    const diagnosisVal = (diagnosisInput && diagnosisInput.value) ? diagnosisInput.value : "Bình thường";
    const canViewVal = canViewInput ? canViewInput.checked : false;

    const body = new URLSearchParams({
        record_id: recordId,
        notes: notesVal,
        diagnosis: diagnosisVal,
        can_view: canViewVal,
        revisit_date: revisitDateVal
    });

    const saveBtn = document.querySelector("button[onclick*='saveNotes']");
    if (saveBtn) {
        saveBtn.disabled = true;
        saveBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>Đang lưu...';
    }

    fetch("${pageContext.request.contextPath}/doctor/records/save", {
        method: "POST",
        headers: {
            "Content-Type": "application/x-www-form-urlencoded",
            "Accept": "application/json",
            "X-Requested-With": "XMLHttpRequest"
        },
        body: body.toString()
    })
    .then(async response => {
        const text = await response.text();
        let data = {};
        try {
            data = JSON.parse(text);
        } catch (e) {
            if (response.status === 401 || text.includes("login")) {
                throw new Error("Phiên làm việc đã hết hạn. Vui lòng đăng nhập lại.");
            }
            throw new Error("Không thể xử lý phản hồi từ máy chủ.");
        }
        if (!response.ok || !data.success) {
            throw new Error(data.message || data.error || "Không thể lưu hồ sơ");
        }
        return data;
    })
    .then(() => {
        window.location.href = "${pageContext.request.contextPath}/doctor/completed-records";
    })
    .catch(error => {
        if (saveBtn) {
            saveBtn.disabled = false;
            saveBtn.innerHTML = '<i class="bi bi-save me-1"></i> Lưu và hoàn thành';
        }
        alert(error.message);
    });
}
</script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
