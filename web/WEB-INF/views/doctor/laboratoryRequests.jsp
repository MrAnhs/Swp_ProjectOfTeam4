<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Quản lý xét nghiệm</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/assets/css/pages/doctor/doctor.css?v=20260721-ui2" rel="stylesheet">
</head>
<body class="doctor-app">
<c:set var="activeDoctorPage" value="laboratory-requests" />
<%@ include file="/WEB-INF/views/components/doctor/sidebar.jspf" %>
<main class="doctor-main">
    <section class="doctor-topbar mb-4">
        <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 align-items-lg-center">
            <div>
                <div class="doctor-muted small mb-1">YÊU CẦU XÉT NGHIỆM</div>
                <h1 class="doctor-title h3 mb-1">Theo dõi yêu cầu xét nghiệm</h1>
                <p class="doctor-muted mb-0">Bác sĩ chỉ xem kết quả; trạng thái và kết quả do bộ phận xét nghiệm cập nhật.</p>
            </div>
            <form class="d-flex gap-2" method="get" action="${pageContext.request.contextPath}/doctor/laboratory-requests">
                <select class="form-select doctor-filter" name="status" onchange="this.form.submit()">
                    <option value="All" ${selectedStatus == 'All' ? 'selected' : ''}>Tất cả trạng thái</option>
                    <option value="Waiting_Payment" ${selectedStatus == 'Waiting_Payment' ? 'selected' : ''}>Chờ thanh toán</option>
                    <option value="Requested" ${selectedStatus == 'Requested' ? 'selected' : ''}>Đã yêu cầu</option>
                    <option value="Processing" ${selectedStatus == 'Processing' ? 'selected' : ''}>Đang xử lý</option>
                    <option value="Completed" ${selectedStatus == 'Completed' ? 'selected' : ''}>Đã hoàn thành</option>
                </select>
            </form>
        </div>
    </section>

    <section class="doctor-card">
        <c:choose>
            <c:when test="${empty laboratoryRequests}">
                <div class="doctor-empty">
                    <i class="bi bi-clipboard2-pulse fs-1 d-block mb-2"></i>
                    Không có yêu cầu xét nghiệm phù hợp.
                </div>
            </c:when>
            <c:otherwise>
                <div class="table-responsive">
                    <table class="table doctor-table align-middle mb-0">
                        <thead><tr><th>Hóa đơn</th><th>Hồ sơ</th><th>Loại xét nghiệm</th><th>Giá</th><th>Thanh toán</th><th>Ngày yêu cầu</th><th>Trạng thái</th><th>Kết quả</th><th></th></tr></thead>
                        <tbody>
                        <c:forEach var="lab" items="${laboratoryRequests}">
                            <tr>
                                <td class="fw-bold">#${lab.invoiceId}</td>
                                <td>#${lab.healthRecordId}</td>
                                <td>
                                    <strong>${lab.testTypeDisplay}</strong>
                                    <c:if test="${not empty lab.labDoctorName}">
                                        <br><small class="text-primary fw-semibold">BS thực hiện: ${lab.labDoctorName} (${lab.labName})</small>
                                    </c:if>
                                    <br><small class="doctor-muted">${lab.requestNote}</small>
                                </td>
                                <td class="fw-semibold"><fmt:formatNumber value="${lab.testPrice}" type="number" groupingUsed="true"/> VNĐ</td>
                                <td>
                                    <span class="doctor-badge ${lab.invoiceStatus == 'Paid' ? 'badge-completed' : 'badge-requested'}">
                                        ${lab.paymentStatusDisplay}
                                    </span>
                                </td>
                                <td><fmt:formatDate value="${lab.requestedAt}" pattern="dd/MM/yyyy HH:mm"/></td>
                                <td>
                                    <span class="doctor-badge ${lab.status == 'Completed' ? 'badge-completed' : (lab.status == 'Processing' ? 'badge-processing' : 'badge-requested')}">
                                        ${lab.statusDisplay}
                                    </span>
                                </td>
                                <td>
                                    <c:choose>
                                        <c:when test="${lab.status != 'Completed'}">
                                            <span class="doctor-muted">Phòng xét nghiệm chưa hoàn thành</span>
                                        </c:when>
                                        <c:when test="${empty lab.result && !lab.hasMeasurements}">
                                            <span class="doctor-muted">Chưa nhập kết quả</span>
                                        </c:when>
                                        <c:otherwise>
                                            <c:if test="${not empty lab.result}"><div class="mb-1">${lab.result}</div></c:if>
                                            <div class="small doctor-muted">
                                                <c:if test="${not empty lab.hba1c}">Đường huyết: <strong>${lab.hba1c}</strong> · </c:if>
                                                <c:if test="${not empty lab.urea}">Urea: <strong>${lab.urea}</strong> · </c:if>
                                                <c:if test="${not empty lab.cr}">Creatinine: <strong>${lab.cr}</strong> · </c:if>
                                                <c:if test="${not empty lab.chol}">Cholesterol: <strong>${lab.chol}</strong> · </c:if>
                                                <c:if test="${not empty lab.tg}">Triglyceride: <strong>${lab.tg}</strong> · </c:if>
                                                <c:if test="${not empty lab.hdl}">HDL: <strong>${lab.hdl}</strong> · </c:if>
                                                <c:if test="${not empty lab.ldl}">LDL: <strong>${lab.ldl}</strong> · </c:if>
                                                <c:if test="${not empty lab.vldl}">VLDL: <strong>${lab.vldl}</strong> · </c:if>
                                                <c:if test="${not empty lab.bmi}">BMI: <strong>${lab.bmi}</strong></c:if>
                                            </div>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                                <td class="text-end">
                                    <a class="btn btn-sm btn-outline-primary"
                                       href="${pageContext.request.contextPath}/doctor/records/detail?record_id=${lab.healthRecordId}">Mở hồ sơ</a>
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
