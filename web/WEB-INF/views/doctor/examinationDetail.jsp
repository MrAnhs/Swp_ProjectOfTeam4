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
        .exam-grid { display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:14px; }
        .exam-metric {
            padding:16px; border:1px solid rgba(255, 255, 255, 0.08) !important;
            border-radius:15px; background: rgba(15, 23, 42, 0.6) !important; color: #F8FAFC !important;
        }
        .exam-metric-label { color:#94A3B8 !important; font-size:.72rem; font-weight:700; text-transform:uppercase; }
        .exam-metric-value { margin-top:5px; font-size:1.28rem; font-weight:800; color: #FFFFFF !important; }
        .section-icon {
            display:grid; width:42px; height:42px; place-items:center;
            border-radius:13px; background: rgba(42, 181, 163, 0.15) !important; color:#2AB5A3 !important;
            border: 1px solid rgba(42, 181, 163, 0.2);
        }
        .ai-progress { height:22px; border-radius:999px; background: rgba(255, 255, 255, 0.1) !important; }
        .diagnosis-panel { position:sticky; top:20px; }
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
            .exam-grid, .patient-info-grid { grid-template-columns:1fr 1fr; }
            .patient-info-item.wide { grid-column:span 2; }
        }
    </style>
</head>
<body class="doctor-app">
<c:set var="canEditDiagnosis" value="${empty record.status or record.status != 'Cancelled'}"/>
<c:set var="canRunAI" value="${empty record.status or record.status != 'Cancelled'}"/>
<c:set var="hasAIResult" value="${record.status == 'AI_Processed' || record.status == 'Editing' || record.status == 'Completed'}"/>
<c:set var="isDetailedStage" value="${hasCompletedLaboratoryRequest || hasAIResult}"/>

<c:set var="activeDoctorPage" value="examinations" />
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
                <div class="small opacity-75">BƯỚC 4: KHÁM CHI TIẾT · HỒ SƠ #${record.healthRecordId}</div>
                <h1 class="h3 fw-bold mb-1">${record.patientName}</h1>
                <div class="doctor-muted">Bệnh nhân #${record.patientId} · ${patient.age} tuổi · ${patient.gender}</div>
            </div>
            <div class="d-flex flex-wrap gap-2">
                <a class="btn btn-light"
                   href="${pageContext.request.contextPath}/doctor/examinations">
                    <i class="bi bi-arrow-left"></i> Quay lại danh sách Khám chi tiết
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
        <a href="#historySection"><i class="bi bi-clock-history"></i> Lịch sử bệnh án</a>
        <c:if test="${hasCompletedLaboratoryRequest}">
            <a href="#examinationResult"><i class="bi bi-activity"></i> Kết quả khám & Chẩn đoán</a>
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

    <section id="historySection" class="doctor-card mb-4">
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
                    <div class="exam-metric"><div class="exam-metric-label">Urea</div><input id="metricUrea" class="form-control form-control-sm fw-bold" style="color: #34d399 !important;" type="text" value="${record.urea != null ? record.urea : 'Chưa có'}" readonly disabled></div>
                    <div class="exam-metric"><div class="exam-metric-label">Creatinine</div><input id="metricCr" class="form-control form-control-sm fw-bold" style="color: #34d399 !important;" type="text" value="${record.cr != null ? record.cr : 'Chưa có'}" readonly disabled></div>
                    <div class="exam-metric"><div class="exam-metric-label">Đường huyết (HbA1c)</div><input id="metricHba1c" class="form-control form-control-sm fw-bold" style="color: #34d399 !important;" type="text" value="${record.hba1c != null ? record.hba1c : 'Chưa có'}" readonly disabled></div>
                    <div class="exam-metric"><div class="exam-metric-label">Cholesterol</div><input id="metricChol" class="form-control form-control-sm fw-bold" style="color: #34d399 !important;" type="text" value="${record.chol != null ? record.chol : 'Chưa có'}" readonly disabled></div>
                    <div class="exam-metric"><div class="exam-metric-label">TG</div><input id="metricTg" class="form-control form-control-sm fw-bold" style="color: #34d399 !important;" type="text" value="${record.tg != null ? record.tg : 'Chưa có'}" readonly disabled></div>
                    <div class="exam-metric"><div class="exam-metric-label">HDL</div><input id="metricHdl" class="form-control form-control-sm fw-bold" style="color: #34d399 !important;" type="text" value="${record.hdl != null ? record.hdl : 'Chưa có'}" readonly disabled></div>
                    <div class="exam-metric"><div class="exam-metric-label">LDL</div><input id="metricIdl" class="form-control form-control-sm fw-bold" style="color: #34d399 !important;" type="text" value="${record.ldl != null ? record.ldl : 'Chưa có'}" readonly disabled></div>
                    <div class="exam-metric"><div class="exam-metric-label">VLDL</div><input id="metricVldl" class="form-control form-control-sm fw-bold" style="color: #34d399 !important;" type="text" value="${record.vldl != null ? record.vldl : 'Chưa có'}" readonly disabled></div>
                    <div class="exam-metric"><div class="exam-metric-label">BMI</div><input id="metricBmi" class="form-control form-control-sm fw-bold" style="color: #34d399 !important;" type="text" value="${record.bmi != null ? record.bmi : 'Chưa có'}" readonly disabled></div>
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
                        <option value="Tiểu đường Type 1" ${record.finalDiagnosis == 'Tiểu đường Type 1' or record.finalDiagnosis == 'Tiểu Đường Type 1' ? 'selected' : ''}>Tiểu Đường Type 1</option>
                        <option value="Tiểu đường Type 2" ${record.finalDiagnosis == 'Tiểu đường Type 2' or record.finalDiagnosis == 'Tiểu Đường Type 2' or record.finalDiagnosis == 'Tiểu đường' ? 'selected' : ''}>Tiểu Đường Type 2</option>
                        <option value="Tiểu đường Thai Kỳ" ${record.finalDiagnosis == 'Tiểu đường Thai Kỳ' or record.finalDiagnosis == 'Tiểu đường Thai kỳ' ? 'selected' : ''}>Tiểu Đường Thai Kỳ</option>
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
                    <button class="btn btn-doctor w-100" type="button" onclick="saveNotes('${record.healthRecordId}')">
                        <i class="bi bi-save me-1"></i> Lưu và hoàn thành
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
</body>
</html>
