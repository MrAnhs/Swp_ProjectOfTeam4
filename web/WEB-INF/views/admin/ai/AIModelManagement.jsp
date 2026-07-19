<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<% request.setAttribute("currentAction", "ai-management"); %>
<%@ include file="../common/admin-header.jspf" %>

<div class="admin-page-header mb-3 d-flex justify-content-between align-items-center">
    <div>
        <h3 class="mb-1 text-primary-clinic"><i class="fa-solid fa-brain me-2"></i>Quản lý AI</h3>
        <p class="text-secondary mb-0">Quản trị toàn diện mô hình AI chẩn đoán bệnh tiểu đường</p>
    </div>
</div>

<%-- Thông báo flash --%>
<c:if test="${not empty sessionScope.successMessage}">
    <div class="alert alert-success alert-dismissible fade show" role="alert">
        <i class="fa-solid fa-circle-check me-2"></i>${sessionScope.successMessage}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
    <% session.removeAttribute("successMessage"); %>
</c:if>
<c:if test="${not empty sessionScope.errorMessage}">
    <div class="alert alert-danger alert-dismissible fade show" role="alert">
        <i class="fa-solid fa-triangle-exclamation me-2"></i>${sessionScope.errorMessage}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
    <% session.removeAttribute("errorMessage"); %>
</c:if>

<%-- Điều hướng Tab --%>
<ul class="nav nav-tabs mb-3" id="aiTabs" role="tablist">
    <li class="nav-item" role="presentation">
        <a class="nav-link fw-semibold ${activeTab == 'overview' ? 'active' : ''}"
           href="${pageContext.request.contextPath}/admin?action=ai-management&tab=overview">
            <i class="fa-solid fa-chart-pie me-1"></i>Tổng quan
        </a>
    </li>
    <li class="nav-item" role="presentation">
        <a class="nav-link fw-semibold ${activeTab == 'dataset' ? 'active' : ''}"
           href="${pageContext.request.contextPath}/admin?action=ai-management&tab=dataset">
            <i class="fa-solid fa-database me-1"></i>Dữ liệu
        </a>
    </li>
    <li class="nav-item" role="presentation">
        <a class="nav-link fw-semibold ${activeTab == 'training' ? 'active' : ''}"
           href="${pageContext.request.contextPath}/admin?action=ai-management&tab=training">
            <i class="fa-solid fa-graduation-cap me-1"></i>Huấn luyện
        </a>
    </li>
</ul>

<%-- ====================== TAB: TỔNG QUAN ====================== --%>
<c:if test="${activeTab == 'overview'}">
    <div class="row g-3 mb-4">
        <%-- Mô hình AI đang hoạt động --%>
        <div class="col-md-6">
            <div class="card ai-glass-card h-100 p-3">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <h5 class="card-title mb-0 fw-bold text-secondary">Mô hình AI hiện tại</h5>
                    <span class="badge-active">ĐANG HOẠT ĐỘNG</span>
                </div>
                <c:choose>
                    <c:when test="${not empty activeModel}">
                        <h3 class="text-primary-clinic fw-extrabold mb-2">${activeModel.version}</h3>
                        <div class="row g-2 text-muted text-sm">
                            <div class="col-6"><i class="fa-solid fa-dna me-1"></i>ID đợt huấn luyện:</div>
                            <div class="col-6 fw-bold text-dark">${activeModel.trainingId}</div>
                            <div class="col-6"><i class="fa-solid fa-gears me-1"></i>Thuật toán:</div>
                            <div class="col-6 fw-bold text-dark">${activeModel.algorithm}</div>
                            <div class="col-6"><i class="fa-solid fa-bullseye me-1"></i>Accuracy:</div>
                            <div class="col-6 fw-bold text-dark">${activeModel.accuracy}%</div>
                            <c:if test="${not empty activeModel.f1Score}">
                                <div class="col-6"><i class="fa-solid fa-chart-line me-1"></i>F1 Score:</div>
                                <div class="col-6 fw-bold text-dark">${activeModel.f1Score}%</div>
                            </c:if>
                            <div class="col-6"><i class="fa-solid fa-calendar-day me-1"></i>Lần train gần nhất:</div>
                            <div class="col-6 text-dark"><fmt:formatDate value="${activeModel.trainedAt}" pattern="dd/MM/yyyy" /></div>
                        </div>
                    </c:when>
                    <c:otherwise>
                        <p class="text-muted mt-2">Chưa ghi nhận thông tin mô hình.</p>
                    </c:otherwise>
                </c:choose>
            </div>
        </div>

        <%-- Trạng thái Dữ liệu --%>
        <div class="col-md-6">
            <div class="card ai-glass-card h-100 p-3">
                <h5 class="card-title mb-3 fw-bold text-secondary">Trạng thái dữ liệu AI</h5>
                <div class="row text-center g-2 mb-3">
                    <div class="col-4">
                        <div class="p-2 border rounded bg-white">
                            <h4 class="fw-bold mb-0 text-dark">${totalDataset}</h4>
                            <small class="text-muted d-block mt-1">Tổng bệnh án</small>
                        </div>
                    </div>
                    <div class="col-4">
                        <div class="p-2 border rounded bg-white" style="border-left:3px solid #18906f !important;">
                            <h4 class="fw-bold mb-0 text-primary-clinic">${approvedDataset}</h4>
                            <small class="text-muted d-block mt-1">Đã duyệt</small>
                        </div>
                    </div>
                    <div class="col-4">
                        <div class="p-2 border rounded bg-white" style="border-left:3px solid #e0a800 !important;">
                            <h4 class="fw-bold mb-0 text-warning">${pendingDataset}</h4>
                            <small class="text-muted d-block mt-1">Chờ duyệt</small>
                        </div>
                    </div>
                </div>
                <div class="d-flex gap-2 justify-content-end mt-auto">
                    <a class="btn btn-outline-success btn-sm rounded-pill px-3"
                       href="${pageContext.request.contextPath}/admin?action=ai-management&tab=dataset">
                        <i class="fa-solid fa-list-check me-1"></i>Duyệt dữ liệu
                    </a>
                    <a class="btn btn-success bg-primary-clinic border-0 btn-sm rounded-pill px-3"
                       href="${pageContext.request.contextPath}/admin?action=ai-management&tab=training">
                        <i class="fa-solid fa-play me-1"></i>Huấn luyện mới
                    </a>
                </div>
            </div>
        </div>
    </div>

    <%-- Lịch sử Huấn luyện --%>
    <div class="card shadow-sm border-0 mb-4" style="border-radius:16px;">
        <div class="card-header bg-white py-3 fw-bold border-0 text-dark">
            <span><i class="fa-solid fa-clock-rotate-left me-2"></i>Lịch sử huấn luyện mô hình</span>
        </div>
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead class="table-light">
                <tr>
                    <th class="ps-3">ID Huấn luyện</th>
                    <th>Phiên bản dữ liệu</th>
                    <th>Số bản ghi</th>
                    <th>Ngày thực hiện</th>
                    <th>Mô hình tốt nhất</th>
                    <th>Trạng thái</th>
                </tr>
                </thead>
                <tbody>
                <c:choose>
                    <c:when test="${not empty trainingHistory}">
                        <c:forEach var="h" items="${trainingHistory}">
                            <tr>
                                <td class="ps-3 fw-bold text-secondary">${h.trainingId}</td>
                                <td>${h.datasetVersion}</td>
                                <td>${h.datasetRecords} bản ghi</td>
                                <td><fmt:formatDate value="${h.trainedAt}" pattern="dd/MM/yyyy HH:mm" /></td>
                                <td>
                                    <c:if test="${not empty h.bestModelVersion}">
                                        <span class="badge bg-success-subtle text-success border border-success-subtle rounded-pill px-2">${h.bestModelVersion}</span>
                                    </c:if>
                                    <c:if test="${empty h.bestModelVersion}"><span class="text-muted">-</span></c:if>
                                </td>
                                <td>
                                    <c:choose>
                                        <c:when test="${h.status == 'Completed'}"><span class="badge text-bg-success rounded-pill">Hoàn tất</span></c:when>
                                        <c:when test="${h.status == 'Running'}"><span class="badge text-bg-warning rounded-pill"><i class="fa-solid fa-spinner fa-spin me-1"></i>Đang chạy</span></c:when>
                                        <c:otherwise><span class="badge text-bg-danger rounded-pill">Thất bại</span></c:otherwise>
                                    </c:choose>
                                </td>
                            </tr>
                        </c:forEach>
                    </c:when>
                    <c:otherwise>
                        <tr><td colspan="6" class="text-center py-4 text-muted">Chưa có đợt huấn luyện nào được ghi nhận.</td></tr>
                    </c:otherwise>
                </c:choose>
                </tbody>
            </table>
        </div>
    </div>
</c:if>

<%-- ====================== TAB: DỮ LIỆU ====================== --%>
<c:if test="${activeTab == 'dataset'}">
    <%-- Bộ lọc tìm kiếm --%>
    <div class="card shadow-sm border-0 mb-4" style="border-radius:12px;">
        <div class="card-body p-3">
            <form class="row g-2 align-items-end" method="get" action="${pageContext.request.contextPath}/admin">
                <input type="hidden" name="action" value="ai-management">
                <input type="hidden" name="tab" value="dataset">
                <div class="col-md-3">
                    <label class="form-label mb-1 fw-bold text-secondary text-xs">Mã bệnh nhân</label>
                    <input type="text" class="form-control" name="patientId" value="${patientId}" placeholder="Tìm theo mã bệnh nhân...">
                </div>
                <div class="col-md-3">
                    <label class="form-label mb-1 fw-bold text-secondary text-xs">Bác sĩ chẩn đoán</label>
                    <select class="form-select" name="doctor">
                        <option value="" ${empty doctor ? 'selected' : ''}>Tất cả bác sĩ</option>
                        <c:forEach var="doc" items="${doctors}">
                            <option value="${doc.accountId}" ${doctor == doc.accountId ? 'selected' : ''}>${doc.fullName}</option>
                        </c:forEach>
                    </select>
                </div>
                <div class="col-md-3">
                    <label class="form-label mb-1 fw-bold text-secondary text-xs">Trạng thái</label>
                    <select class="form-select" name="status">
                        <option value="" ${empty status ? 'selected' : ''}>Tất cả</option>
                        <option value="Pending" ${status == 'Pending' ? 'selected' : ''}>Chờ duyệt</option>
                        <option value="Approved" ${status == 'Approved' ? 'selected' : ''}>Đã duyệt</option>
                        <option value="Exported" ${status == 'Exported' ? 'selected' : ''}>Đã duyệt (Đã gửi sang AI)</option>
                        <option value="Rejected" ${status == 'Rejected' ? 'selected' : ''}>Đã từ chối</option>
                    </select>
                </div>
                <div class="col-md-3">
                    <label class="form-label mb-1 fw-bold text-secondary text-xs">Chất lượng dữ liệu</label>
                    <select class="form-select" name="quality">
                        <option value="" ${empty quality ? 'selected' : ''}>Tất cả</option>
                        <option value="valid" ${quality == 'valid' ? 'selected' : ''}>Đủ điều kiện</option>
                        <option value="invalid" ${quality == 'invalid' ? 'selected' : ''}>Thiếu chỉ số</option>
                    </select>
                </div>
                <div class="col-12 text-end mt-2">
                    <a class="btn btn-outline-secondary rounded-pill px-3 me-2"
                       href="${pageContext.request.contextPath}/admin?action=ai-management&tab=dataset">
                        <i class="fa-solid fa-filter-circle-xmark me-1"></i>Xóa bộ lọc
                    </a>
                    <button class="btn btn-success bg-primary-clinic border-0 rounded-pill px-4" type="submit">
                        <i class="fa-solid fa-magnifying-glass me-1"></i>Tìm kiếm
                    </button>
                </div>
            </form>
        </div>
    </div>

    <%-- Bảng dữ liệu --%>
    <div class="card shadow-sm border-0 mb-4" style="border-radius:16px;">
        <div class="card-header bg-white py-3 fw-bold border-0 d-flex justify-content-between align-items-center flex-wrap gap-2">
            <span class="text-dark"><i class="fa-solid fa-list me-2"></i>Danh sách hồ sơ lâm sàng</span>
            <div class="d-flex align-items-center gap-2 flex-wrap">
                <!-- Global Actions -->
                <button type="button" id="btnApproveAllGlobal" class="btn btn-xs btn-success bg-primary-clinic border-0 rounded-pill px-3 py-1.5 fw-bold text-xs">
                    <i class="fa-solid fa-check-double me-1"></i>Duyệt tất cả hồ sơ
                </button>
                <button type="button" id="btnApproveQuantityGlobal" class="btn btn-xs btn-outline-success rounded-pill px-3 py-1.5 fw-bold text-xs">
                    <i class="fa-solid fa-sliders me-1"></i>Duyệt theo số lượng
                </button>
                
                <!-- Individual selection toolbar -->
                <span id="bulkSelectionStatus" class="text-secondary text-sm ms-2 me-1">Chọn hồ sơ để thao tác</span>
                <button type="button" id="btnBulkApprove" class="btn btn-xs btn-success rounded-pill px-2.5 py-1 d-none text-xs">
                    <i class="fa-solid fa-circle-check me-1"></i>Duyệt mục đã chọn
                </button>
                <button type="button" id="btnBulkReject" class="btn btn-xs btn-danger rounded-pill px-2.5 py-1 d-none text-xs">
                    <i class="fa-solid fa-circle-xmark me-1"></i>Từ chối
                </button>
                
                <span class="badge bg-light text-dark border rounded px-2 text-xs">Tìm thấy ${totalRecords} kết quả</span>
            </div>
        </div>
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead class="table-light">
                <tr>
                    <th class="ps-3" style="width: 40px;">
                        <!-- Checkbox chọn lẻ từng dòng -->
                    </th>
                    <th>ID Bệnh án</th>
                    <th>Bệnh nhân</th>
                    <th>Bác sĩ</th>
                    <th>Chất lượng</th>
                    <th>Chẩn đoán</th>
                    <th>Ngày chẩn đoán</th>
                    <th>Trạng thái AI</th>
                    <th class="pe-3 text-end">Thao tác</th>
                </tr>
                </thead>
                <tbody>
                <c:choose>
                    <c:when test="${not empty items}">
                        <c:forEach var="item" items="${items}">
                            <tr id="row-${item.recordId}">
                                <td class="ps-3">
                                    <input type="checkbox" class="form-check-input record-checkbox" 
                                           value="${item.recordId}" 
                                           data-is-valid="${item.isValid}"
                                           data-patient="${item.patientName}"
                                           data-hba1c="${item.hba1c}"
                                           data-bmi="${item.bmi}"
                                           data-age="${item.age}">
                                </td>
                                <td class="fw-bold text-secondary">#${item.recordId}</td>
                                <td>${item.patientName}</td>
                                <td>${item.doctorName}</td>
                                <td>
                                    <c:choose>
                                        <c:when test="${item.isValid}">
                                            <span class="badge text-bg-success rounded-pill" style="font-size: 11px;"><i class="fa-solid fa-circle-check me-1"></i>Đủ điều kiện</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="badge text-bg-secondary rounded-pill" style="font-size: 11px;" title="Thiếu thông tin tuổi hoặc chỉ số lâm sàng (BMI, HbA1c, Cholesterol, LDL, HDL)"><i class="fa-solid fa-triangle-exclamation me-1"></i>Thiếu chỉ số</span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                                <td>${item.finalDiagnosis}</td>
                                <td><fmt:formatDate value="${item.processedAt}" pattern="dd/MM/yyyy" /></td>
                                <td class="status-cell">
                                    <c:choose>
                                        <c:when test="${item.decisionStatus == 'Approved'}"><span class="badge text-bg-success rounded-pill">Đã duyệt</span></c:when>
                                        <c:when test="${item.decisionStatus == 'Exported'}"><span class="badge text-bg-success rounded-pill">Đã duyệt</span></c:when>
                                        <c:when test="${item.decisionStatus == 'Rejected'}"><span class="badge text-bg-danger rounded-pill">Đã từ chối</span></c:when>
                                        <c:otherwise><span class="badge text-bg-warning rounded-pill">Chờ duyệt</span></c:otherwise>
                                    </c:choose>
                                </td>
                                <td class="pe-3 text-end">
                                    <button type="button" class="btn btn-sm btn-outline-primary-clinic rounded-pill px-3"
                                            onclick="openDetailModal('${item.recordId}')">
                                        <i class="fa-solid fa-eye me-1"></i>Xem
                                    </button>
                                </td>
                            </tr>
                        </c:forEach>
                    </c:when>
                    <c:otherwise>
                        <tr><td colspan="9" class="text-center py-4 text-muted">Không tìm thấy dữ liệu phù hợp.</td></tr>
                    </c:otherwise>
                </c:choose>
                </tbody>
            </table>
        </div>
        <%-- Phân trang --%>
        <c:if test="${totalPages > 1}">
            <div class="card-footer bg-white border-0 py-3 d-flex justify-content-between align-items-center">
                <span class="text-muted text-sm fw-semibold">Trang ${currentPage} / ${totalPages}</span>
                <nav>
                    <ul class="pagination pagination-sm mb-0">
                        <li class="page-item ${currentPage == 1 ? 'disabled' : ''}">
                            <a class="page-link page-link-clinic"
                               href="${pageContext.request.contextPath}/admin?action=ai-management&tab=dataset&patientId=${patientId}&doctor=${doctor}&status=${status}&quality=${quality}&page=${currentPage - 1}">
                                <i class="fa-solid fa-chevron-left"></i>
                            </a>
                        </li>
                        <c:forEach var="p" begin="1" end="${totalPages}">
                            <li class="page-item ${p == currentPage ? 'active' : ''}">
                                <a class="page-link page-link-clinic"
                                   href="${pageContext.request.contextPath}/admin?action=ai-management&tab=dataset&patientId=${patientId}&doctor=${doctor}&status=${status}&quality=${quality}&page=${p}">${p}</a>
                            </li>
                        </c:forEach>
                        <li class="page-item ${currentPage == totalPages ? 'disabled' : ''}">
                            <a class="page-link page-link-clinic"
                               href="${pageContext.request.contextPath}/admin?action=ai-management&tab=dataset&patientId=${patientId}&doctor=${doctor}&status=${status}&quality=${quality}&page=${currentPage + 1}">
                                <i class="fa-solid fa-chevron-right"></i>
                            </a>
                        </li>
                    </ul>
                </nav>
            </div>
        </c:if>
    </div>

    <%-- Modal chi tiết bệnh án --%>
    <div class="modal fade" id="datasetModal" tabindex="-1" aria-labelledby="datasetModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-lg modal-dialog-centered">
            <div class="modal-content" style="border-radius:16px;">
                <div class="modal-header border-bottom-0 py-3">
                    <h5 class="modal-title fw-bold text-primary-clinic" id="datasetModalLabel">
                        <i class="fa-solid fa-notes-medical me-2"></i>Duyệt dữ liệu lâm sàng
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body py-1">
                    <div class="row g-3">
                        <div class="col-md-7">
                            <div class="p-3 bg-light rounded-3 border">
                                <h6 class="fw-bold text-dark mb-3">
                                    <i class="fa-solid fa-circle-info me-1"></i>Chi tiết bệnh án <span id="mdRecordId" class="text-secondary"></span>
                                </h6>
                                <div class="row g-2 mb-3 text-sm">
                                    <div class="col-4 text-muted">Bệnh nhân:</div>
                                    <div class="col-8 fw-bold text-dark" id="mdPatientName"></div>
                                    <div class="col-4 text-muted">Tuổi:</div>
                                    <div class="col-8 text-dark" id="mdPatientAge"></div>
                                    <div class="col-4 text-muted">Bác sĩ:</div>
                                    <div class="col-8 text-dark" id="mdDoctorName"></div>
                                </div>
                                <h6 class="fw-bold mb-1 text-primary-clinic">Chẩn đoán y khoa</h6>
                                <div class="clinical-badge mb-3">
                                    <strong id="mdDiagnosis"></strong>
                                    <div id="mdNote" class="text-xs text-secondary mt-1"></div>
                                </div>
                                <h6 class="fw-bold mb-2 text-secondary">Chỉ số sinh hóa</h6>
                                <table class="table table-bordered table-sm text-center mb-0 text-xs">
                                    <thead class="table-light">
                                    <tr><th>Chỉ số</th><th>Giá trị</th><th>Đơn vị</th></tr>
                                    </thead>
                                    <tbody>
                                    <tr><td>BMI</td><td class="fw-bold" id="mdBmi"></td><td>kg/m²</td></tr>
                                    <tr><td>HbA1c</td><td class="fw-bold" id="mdHba1c"></td><td>%</td></tr>
                                    <tr><td>Cholesterol</td><td class="fw-bold" id="mdChol"></td><td>mg/dL</td></tr>
                                    <tr><td>LDL</td><td class="fw-bold" id="mdLdl"></td><td>mg/dL</td></tr>
                                    <tr><td>HDL</td><td class="fw-bold" id="mdHdl"></td><td>mg/dL</td></tr>
                                    </tbody>
                                </table>
                                
                                <div class="p-3 bg-white rounded border mt-3 mb-1">
                                    <h6 class="fw-bold mb-2 text-dark" style="font-size: 13px;">
                                        <i class="fa-solid fa-square-check text-primary-clinic me-1"></i>Điều kiện huấn luyện AI
                                    </h6>
                                    <ul class="list-unstyled mb-0 text-xs">
                                        <li class="mb-1 d-flex justify-content-between">
                                            <span class="text-secondary">✓ HbA1c:</span>
                                            <span class="fw-bold" id="chkHba1cVal"></span>
                                        </li>
                                        <li class="mb-1 d-flex justify-content-between">
                                            <span class="text-secondary">✓ BMI:</span>
                                            <span class="fw-bold" id="chkBmiVal"></span>
                                        </li>
                                        <li class="mb-1 d-flex justify-content-between">
                                            <span class="text-secondary">✓ Nhóm tuổi:</span>
                                            <span class="fw-bold" id="chkAgeVal"></span>
                                        </li>
                                    </ul>
                                    <div class="mt-2 text-xs fw-bold text-center p-1.5 rounded" id="chkStatusText"></div>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-5">
                            <div class="p-3 bg-light rounded-3 border h-100" style="border-top:3px solid #18906f !important;">
                                <h6 class="fw-bold text-dark mb-3"><i class="fa-solid fa-gavel me-1"></i>Quyết định duyệt</h6>
                                <form id="decisionForm">
                                    <input type="hidden" name="action" value="ai-dataset-confirm">
                                    <input type="hidden" id="recordIdInput" name="recordId" value="">
                                    <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                                    <div class="mb-3">
                                        <label class="form-label fw-bold text-secondary text-xs">Trạng thái quyết định</label>
                                        <div class="d-flex gap-3 mt-1">
                                            <div class="form-check">
                                                <input class="form-check-input" type="radio" name="decisionStatus" id="approveRadio" value="Approved">
                                                <label class="form-check-label fw-semibold text-success text-sm" for="approveRadio">Phê duyệt</label>
                                            </div>
                                            <div class="form-check">
                                                <input class="form-check-input" type="radio" name="decisionStatus" id="rejectRadio" value="Rejected">
                                                <label class="form-check-label fw-semibold text-danger text-sm" for="rejectRadio">Từ chối</label>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="mb-4">
                                        <label class="form-label fw-bold text-secondary text-xs" for="decisionReason">Lý do (nếu có)</label>
                                        <textarea class="form-control text-sm" id="decisionReason" name="decisionReason" rows="4" placeholder="Nhập ghi chú hoặc lý do từ chối..."></textarea>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="modal-footer border-top-0 py-3">
                    <button type="button" class="btn btn-outline-secondary rounded-pill px-4 text-sm" data-bs-dismiss="modal">Đóng</button>
                    <button type="button" id="btnConfirm" class="btn btn-success bg-primary-clinic border-0 rounded-pill px-4 fw-bold text-sm">Xác nhận</button>
                </div>
            </div>
        </div>
    </div>

    <%-- Modal duyệt hàng loạt --%>
    <div class="modal fade" id="bulkApproveModal" tabindex="-1" aria-labelledby="bulkApproveModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content" style="border-radius:16px;">
                <div class="modal-header border-bottom-0 py-3">
                    <h5 class="modal-title fw-bold text-success" id="bulkApproveModalLabel">
                        <i class="fa-solid fa-square-poll-vertical me-2"></i>Quyết định duyệt hàng loạt
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body py-2">
                    <form id="bulkApproveForm">
                        <input type="hidden" name="action" value="ai-dataset-confirm-bulk">
                        <input type="hidden" id="bulkApproveRecordIds" name="recordIds" value="">
                        <input type="hidden" name="decisionStatus" value="Approved">
                        <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                        
                        <div class="p-3 bg-light rounded-3 border mb-3 text-sm">
                            <div class="mb-2 fw-semibold text-dark">Đã chọn: <span id="approveTotalCount">0</span> hồ sơ</div>
                            <div class="mb-3 text-sm">
                                <div class="mb-1 d-flex align-items-center">
                                    <span class="text-success me-2">🟢 Hợp lệ:</span> <strong id="approveValidCount">0</strong>
                                </div>
                                <div class="d-flex align-items-center">
                                    <span class="text-danger me-2">🔴 Lỗi dữ liệu:</span> <strong id="approveInvalidCount">0</strong>
                                </div>
                            </div>
                            
                            <!-- Warning text: show only when error count > 0 -->
                            <div id="invalidWarningText" class="alert alert-warning text-xs py-1.5 px-3 mb-2 rounded border border-warning d-none">
                                <i class="fa-solid fa-triangle-exclamation me-1"></i>Có hồ sơ chưa đủ điều kiện
                            </div>
                            
                            <!-- Trigger link for error list popup -->
                            <div id="invalidDetailsSection" class="mb-3 d-none">
                                <a href="javascript:void(0);" id="btnViewErrorRecords" class="text-xs text-danger fw-bold text-decoration-none">
                                    [ Xem chi tiết hồ sơ lỗi ]
                                </a>
                            </div>
                            
                            <div class="text-xs text-secondary border-top pt-2">
                                <strong id="approveValidDatasetCountText" class="text-success">0</strong> hồ sơ hợp lệ sẽ được đưa vào Dataset để huấn luyện AI
                            </div>
                        </div>

                        <div class="mb-3">
                            <label class="form-label fw-bold text-secondary text-xs" for="bulkApproveReason">Ghi chú duyệt hàng loạt (nếu có)</label>
                            <textarea class="form-control text-sm" id="bulkApproveReason" name="decisionReason" rows="2" placeholder="Nhập lý do hoặc ghi chú cho đợt duyệt này..."></textarea>
                        </div>
                    </form>
                </div>
                <div class="modal-footer border-top-0 py-3">
                    <button type="button" class="btn btn-outline-secondary rounded-pill px-4 text-sm" data-bs-dismiss="modal">Hủy</button>
                    <button type="button" id="btnConfirmApproveBulk" class="btn btn-success bg-primary-clinic border-0 rounded-pill px-4 fw-bold text-sm">✓ Duyệt 0 hồ sơ</button>
                </div>
            </div>
        </div>
    </div>

    <%-- Modal từ chối hàng loạt --%>
    <div class="modal fade" id="bulkRejectModal" tabindex="-1" aria-labelledby="bulkRejectModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content" style="border-radius:16px;">
                <div class="modal-header border-bottom-0 py-3">
                    <h5 class="modal-title fw-bold text-danger" id="bulkRejectModalLabel">
                        <i class="fa-solid fa-circle-xmark me-2"></i>Quyết định từ chối hàng loạt
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body py-2">
                    <form id="bulkRejectForm">
                        <input type="hidden" name="action" value="ai-dataset-confirm-bulk">
                        <input type="hidden" id="bulkRejectRecordIds" name="recordIds" value="">
                        <input type="hidden" name="decisionStatus" value="Rejected">
                        <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                        
                        <div class="alert alert-danger rounded-3 text-sm py-2 px-3 mb-3">
                            Bạn đã chọn <strong id="rejectTotalCount">0</strong> hồ sơ để <strong>TỪ CHỐI</strong>.
                            <div class="text-xs text-secondary mt-1 max-vh-10" style="overflow-y: auto; max-height: 80px;" id="bulkRejectIdsDisplay"></div>
                        </div>

                        <div class="mb-3">
                            <label class="form-label fw-bold text-secondary text-xs" for="bulkRejectReason">Lý do từ chối (bắt buộc)</label>
                            <textarea class="form-control text-sm" id="bulkRejectReason" name="decisionReason" rows="3" placeholder="Nhập lý do từ chối..." required></textarea>
                        </div>
                    </form>
                </div>
                <div class="modal-footer border-top-0 py-3">
                    <button type="button" class="btn btn-outline-secondary rounded-pill px-4 text-sm" data-bs-dismiss="modal">Hủy</button>
                    <button type="button" id="btnConfirmRejectBulk" class="btn btn-danger border-0 rounded-pill px-4 fw-bold text-sm">Từ chối 0 hồ sơ</button>
                </div>
            </div>
        </div>
    </div>

    <%-- Modal danh sách hồ sơ lỗi --%>
    <div class="modal fade" id="bulkErrorListModal" tabindex="-1" aria-labelledby="bulkErrorListModalLabel" aria-hidden="true" style="z-index: 1056;">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content" style="border-radius:16px; border: 1px solid #dc3545;">
                <div class="modal-header border-bottom-0 py-3">
                    <h5 class="modal-title fw-bold text-danger" id="bulkErrorListModalLabel">
                        <i class="fa-solid fa-triangle-exclamation me-2"></i>Danh sách hồ sơ lỗi
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body py-2">
                    <div class="table-responsive" style="max-height: 200px; overflow-y: auto;">
                        <table class="table table-sm table-hover align-middle text-sm mb-0">
                            <thead class="table-light sticky-top">
                                <tr>
                                    <th>ID</th>
                                    <th>Bệnh nhân</th>
                                    <th>Lỗi chỉ số</th>
                                    <th style="width: 80px;" class="text-end">Chi tiết</th>
                                </tr>
                            </thead>
                            <tbody id="bulkErrorListTableBody">
                                <!-- Populated dynamically -->
                            </tbody>
                        </table>
                    </div>
                </div>
                <div class="modal-footer border-top-0 py-2">
                    <button type="button" class="btn btn-secondary rounded-pill px-4 text-xs" data-bs-dismiss="modal">Đóng</button>
                </div>
            </div>
        </div>
    </div>

    <%-- Modal chi tiết lỗi của hồ sơ cụ thể --%>
    <div class="modal fade" id="bulkPatientErrorDetailModal" tabindex="-1" aria-labelledby="bulkPatientErrorDetailModalLabel" aria-hidden="true" style="z-index: 1058;">
        <div class="modal-dialog modal-dialog-centered modal-sm">
            <div class="modal-content" style="border-radius:16px;">
                <div class="modal-header border-bottom-0 py-2.5">
                    <h6 class="modal-title fw-bold text-dark" id="bulkPatientErrorDetailModalLabel">
                        Chi tiết hồ sơ <span id="errDetailRecordId" class="text-secondary"></span>
                    </h6>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body py-2 text-sm">
                    <div class="mb-2">
                        <span class="text-muted text-xs">Bệnh nhân:</span>
                        <div class="fw-semibold text-dark" id="errDetailPatientName"></div>
                    </div>
                    <div class="mb-2">
                        <span class="text-muted text-xs">Bác sĩ:</span>
                        <div class="text-dark" id="errDetailDoctorName"></div>
                    </div>
                    <div class="mb-3">
                        <span class="text-muted text-xs">Chẩn đoán:</span>
                        <div class="text-dark fw-semibold" id="errDetailDiagnosis"></div>
                    </div>
                    
                    <div class="p-2.5 bg-light rounded border mb-2">
                        <div class="fw-bold text-xs text-secondary mb-1.5"><i class="fa-solid fa-chart-simple me-1"></i>Chỉ số AI:</div>
                        <div class="d-flex justify-content-between text-xs mb-1">
                            <span class="text-muted">Tuổi:</span>
                            <span class="fw-bold text-dark" id="errDetailAge"></span>
                        </div>
                        <div class="d-flex justify-content-between text-xs mb-1">
                            <span class="text-muted">BMI:</span>
                            <span class="fw-bold text-dark" id="errDetailBmi"></span>
                        </div>
                        <div class="d-flex justify-content-between text-xs">
                            <span class="text-muted">HbA1c:</span>
                            <span class="fw-bold text-dark" id="errDetailHba1c"></span>
                        </div>
                    </div>
                    
                    <div class="text-xs text-danger fw-bold"><i class="fa-solid fa-triangle-exclamation me-1"></i>Chất lượng: Thiếu dữ liệu</div>
                </div>
                <div class="modal-footer border-top-0 py-2">
                    <button type="button" class="btn btn-outline-secondary rounded-pill px-4 text-xs w-100" data-bs-dismiss="modal">Đóng</button>
                </div>
            </div>
        </div>
    </div>

    <%-- Modal duyệt toàn bộ hệ thống --%>
    <div class="modal fade" id="globalApproveModal" tabindex="-1" aria-labelledby="globalApproveModalLabel" aria-hidden="true" style="z-index: 1056;">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content" style="border-radius:16px;">
                <div class="modal-header border-bottom-0 py-3">
                    <h5 class="modal-title fw-bold text-success" id="globalApproveModalLabel">
                        <i class="fa-solid fa-check-double me-2"></i>Quyết định duyệt toàn bộ
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body py-2">
                    <div class="p-3 bg-light rounded-3 border mb-3 text-sm">
                        <div class="mb-2 fw-semibold text-dark">Tìm thấy: <span id="globalPendingCount">0</span> hồ sơ đang chờ duyệt</div>
                        <div class="mb-3 text-sm">
                            <div class="mb-1 d-flex align-items-center">
                                <span class="text-success me-2">🟢 Đủ điều kiện:</span> <strong id="globalValidCount">0</strong>
                            </div>
                            <div class="d-flex align-items-center">
                                <span class="text-danger me-2">🔴 Thiếu dữ liệu:</span> <strong id="globalInvalidCount">0</strong>
                            </div>
                        </div>
                        <div class="text-xs text-secondary border-top pt-2">
                            <strong id="globalValidDatasetCountText" class="text-success">0</strong> hồ sơ hợp lệ sẽ được thêm vào Dataset để huấn luyện AI
                        </div>
                    </div>
                    <div class="text-xs text-muted mb-2">
                        * Thao tác này sẽ tự động duyệt toàn bộ các hồ sơ hợp lệ mà không cần tick chọn thủ công.
                    </div>
                </div>
                <div class="modal-footer border-top-0 py-3">
                    <button type="button" class="btn btn-outline-secondary rounded-pill px-4 text-sm" data-bs-dismiss="modal">Hủy</button>
                    <button type="button" id="btnConfirmGlobalApprove" class="btn btn-success bg-primary-clinic border-0 rounded-pill px-4 fw-bold text-sm">✓ Duyệt 0 hồ sơ</button>
                </div>
            </div>
        </div>
    </div>

    <%-- Modal duyệt theo số lượng --%>
    <div class="modal fade" id="quantityApproveModal" tabindex="-1" aria-labelledby="quantityApproveModalLabel" aria-hidden="true" style="z-index: 1056;">
        <div class="modal-dialog modal-dialog-centered modal-sm">
            <div class="modal-content" style="border-radius:16px;">
                <div class="modal-header border-bottom-0 py-3">
                    <h5 class="modal-title fw-bold text-primary-clinic" id="quantityApproveModalLabel">
                        <i class="fa-solid fa-sliders me-2"></i>Duyệt theo số lượng
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body py-2 text-sm">
                    <div class="p-3 bg-light rounded border mb-3">
                        <div class="text-xs text-secondary mb-1">Số hồ sơ hợp lệ đang chờ:</div>
                        <div class="fw-bold text-success text-base" id="quantityAvailableValid">0</div>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-bold text-secondary text-xs" for="approveQuantityInput">Số lượng hồ sơ muốn duyệt</label>
                        <input type="number" id="approveQuantityInput" class="form-control text-sm" min="1" value="20">
                        <div class="text-xs text-muted mt-1">Lấy từ mới nhất (ORDER BY ID DESC)</div>
                    </div>
                </div>
                <div class="modal-footer border-top-0 py-2">
                    <button type="button" class="btn btn-outline-secondary rounded-pill px-3 text-xs" data-bs-dismiss="modal">Hủy</button>
                    <button type="button" id="btnConfirmQuantityApprove" class="btn btn-success bg-primary-clinic border-0 rounded-pill px-3 fw-bold text-xs">Tiếp tục</button>
                </div>
            </div>
        </div>
    </div>

    <%-- Toast thông báo --%>
    <div class="toast-container position-fixed top-0 end-0 p-3" style="z-index:1060;">
        <div id="resultToast" class="toast align-items-center text-white border-0" role="alert" aria-live="assertive" aria-atomic="true">
            <div class="d-flex">
                <div class="toast-body" id="toastMessage"></div>
                <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
            </div>
        </div>
    </div>

    <script>
        let myModal = null;
        let bulkModal = null;
        let currentRecordEligible = false;

        function showToast(message, isSuccess) {
            const toastEl = document.getElementById('resultToast');
            if (toastEl) {
                document.getElementById('toastMessage').innerText = message;
                toastEl.classList.toggle('bg-success', isSuccess);
                toastEl.classList.toggle('bg-danger', !isSuccess);
                new bootstrap.Toast(toastEl).show();
            }
        }

        function openDetailModal(recordId) {
            if (!myModal) myModal = new bootstrap.Modal(document.getElementById('datasetModal'));
            fetch('${pageContext.request.contextPath}/admin?action=ai-dataset-detail-json&recordId=' + recordId)
            .then(r => r.json()).then(data => {
                if (!data.success) { alert('Không thể tải chi tiết: ' + data.message); return; }
                document.getElementById('mdRecordId').innerText = '#' + data.recordId;
                document.getElementById('mdPatientName').innerText = data.patientName;
                document.getElementById('mdPatientAge').innerText = data.age;
                document.getElementById('mdDoctorName').innerText = data.doctorName;
                document.getElementById('mdDiagnosis').innerText = data.finalDiagnosis;
                document.getElementById('mdNote').innerText = data.doctorNote || '';
                document.getElementById('mdBmi').innerText  = data.bmi  || 'Chưa đo';
                document.getElementById('mdHba1c').innerText = data.hba1c || 'Chưa đo';
                document.getElementById('mdChol').innerText = data.cholesterol || 'Chưa đo';
                document.getElementById('mdLdl').innerText  = data.ldl  || 'Chưa đo';
                document.getElementById('mdHdl').innerText  = data.hdl  || 'Chưa đo';
                document.getElementById('recordIdInput').value = data.recordId;
                document.getElementById('decisionReason').value = data.decisionReason || '';
                if (data.decisionStatus === 'Approved') document.getElementById('approveRadio').checked = true;
                else if (data.decisionStatus === 'Rejected') document.getElementById('rejectRadio').checked = true;
                else { document.getElementById('approveRadio').checked = false; document.getElementById('rejectRadio').checked = false; }
                
                // Update training indicators checklist
                const hasHba1c = (data.hba1c && parseFloat(data.hba1c) > 0);
                const hasBmi = (data.bmi && parseFloat(data.bmi) > 0);
                const hasAge = (data.age && data.age !== 'Chưa rõ');

                document.getElementById('chkHba1cVal').innerHTML = hasHba1c 
                    ? `<span class="text-success"><i class="fa-solid fa-check me-1"></i>${data.hba1c}%</span>`
                    : `<span class="text-danger"><i class="fa-solid fa-xmark me-1"></i>Không có dữ liệu</span>`;

                document.getElementById('chkBmiVal').innerHTML = hasBmi 
                    ? `<span class="text-success"><i class="fa-solid fa-check me-1"></i>${data.bmi}</span>`
                    : `<span class="text-danger"><i class="fa-solid fa-xmark me-1"></i>Không có dữ liệu</span>`;

                document.getElementById('chkAgeVal').innerHTML = hasAge 
                    ? `<span class="text-success"><i class="fa-solid fa-check me-1"></i>${data.age} tuổi</span>`
                    : `<span class="text-danger"><i class="fa-solid fa-xmark me-1"></i>Không có dữ liệu</span>`;

                const isEligible = hasHba1c && hasBmi && hasAge;
                currentRecordEligible = isEligible;
                const statusBox = document.getElementById('chkStatusText');
                if (isEligible) {
                    statusBox.innerText = 'ĐỦ ĐIỀU KIỆN HUẤN LUYỆN';
                    statusBox.className = 'mt-2 text-xs fw-bold text-center p-1.5 rounded bg-success-subtle text-success border border-success';
                } else {
                    statusBox.innerText = 'KHÔNG ĐỦ ĐIỀU KIỆN TRAINING';
                    statusBox.className = 'mt-2 text-xs fw-bold text-center p-1.5 rounded bg-danger-subtle text-danger border border-danger';
                }
                
                myModal.show();
            }).catch(err => { console.error(err); alert('Lỗi kết nối máy chủ.'); });
        }

        document.getElementById('btnConfirm').addEventListener('click', function() {
            const form = document.getElementById('decisionForm');
            const selectedStatus = form.querySelector('input[name="decisionStatus"]:checked');
            if (!selectedStatus) { alert('Vui lòng chọn Phê duyệt hoặc Từ chối.'); return; }
            if (selectedStatus.value === 'Approved' && !currentRecordEligible) {
                showToast('Không thể phê duyệt hồ sơ thiếu chỉ số lâm sàng thiết yếu (HbA1c, BMI, Tuổi).', false);
                return;
            }
            const params = new URLSearchParams(new FormData(form));
            fetch('${pageContext.request.contextPath}/admin', {
                method: 'POST', body: params,
                headers: {'Content-Type': 'application/x-www-form-urlencoded'}
            }).then(r => r.json()).then(data => {
                showToast(data.message, data.success);
                if (data.success) {
                    myModal.hide();
                    const recordId = document.getElementById('recordIdInput').value;
                    const statusCell = document.querySelector('#row-' + recordId + ' .status-cell');
                    if (statusCell) {
                        const val = selectedStatus.value;
                        statusCell.innerHTML = val === 'Approved'
                            ? '<span class="badge text-bg-success rounded-pill">Đã duyệt</span>'
                            : '<span class="badge text-bg-danger rounded-pill">Đã từ chối</span>';
                    }
                }
            }).catch(err => { console.error(err); alert('Lỗi kết nối máy chủ.'); });
        });

        // ================= BULK ACTIONS CONTROL =================
        const checkAll = document.getElementById('checkAllRecords');
        const checkboxes = document.querySelectorAll('.record-checkbox');
        const btnBulkApprove = document.getElementById('btnBulkApprove');
        const btnBulkReject = document.getElementById('btnBulkReject');

        if (checkAll) {
            checkAll.addEventListener('change', function() {
                checkboxes.forEach(cb => {
                    cb.checked = checkAll.checked;
                });
                toggleBulkButtons();
            });
        }

        checkboxes.forEach(cb => {
            cb.addEventListener('change', function() {
                if (!this.checked) {
                    if (checkAll) checkAll.checked = false;
                } else {
                    const allChecked = Array.from(checkboxes).every(c => c.checked);
                    if (checkAll) checkAll.checked = allChecked;
                }
                toggleBulkButtons();
            });
        });

        function toggleBulkButtons() {
            const checkedCount = document.querySelectorAll('.record-checkbox:checked').length;
            const statusSpan = document.getElementById('bulkSelectionStatus');
            if (checkedCount > 0) {
                statusSpan.innerHTML = 'Đã chọn <strong class="text-primary">' + checkedCount + '</strong> hồ sơ';
                if (btnBulkApprove) btnBulkApprove.classList.remove('d-none');
                if (btnBulkReject) btnBulkReject.classList.remove('d-none');
            } else {
                statusSpan.innerText = 'Chọn hồ sơ để thao tác';
                if (btnBulkApprove) btnBulkApprove.classList.add('d-none');
                if (btnBulkReject) btnBulkReject.classList.add('d-none');
            }
        }

        let bulkApproveModalObj = null;
        let bulkRejectModalObj = null;
        let bulkErrorListModalObj = null;
        let errorDetailModalObj = null;

        function openErrorDetail(recordId) {
            fetch('${pageContext.request.contextPath}/admin?action=ai-dataset-detail-json&recordId=' + recordId)
            .then(r => r.json()).then(data => {
                if (!data.success) { alert('Không thể tải chi tiết: ' + data.message); return; }
                document.getElementById('errDetailRecordId').innerText = '#' + data.recordId;
                document.getElementById('errDetailPatientName').innerText = data.patientName;
                document.getElementById('errDetailDoctorName').innerText = data.doctorName;
                document.getElementById('errDetailDiagnosis').innerText = data.finalDiagnosis;
                
                const hasHba1c = (data.hba1c && parseFloat(data.hba1c) > 0);
                const hasBmi = (data.bmi && parseFloat(data.bmi) > 0);
                const hasAge = (data.age && data.age !== 'Chưa rõ');

                document.getElementById('errDetailAge').innerHTML = hasAge ? (data.age + ' tuổi') : '❌ Chưa có';
                document.getElementById('errDetailBmi').innerHTML = hasBmi ? data.bmi : '❌ Chưa có';
                document.getElementById('errDetailHba1c').innerHTML = hasHba1c ? (data.hba1c + '%') : '❌ Chưa có';

                if (!errorDetailModalObj) {
                    errorDetailModalObj = new bootstrap.Modal(document.getElementById('bulkPatientErrorDetailModal'));
                }
                errorDetailModalObj.show();
            }).catch(err => { console.error(err); alert('Lỗi kết nối máy chủ.'); });
        }

        if (btnBulkApprove) {
            btnBulkApprove.addEventListener('click', function() {
                const selected = Array.from(document.querySelectorAll('.record-checkbox:checked'));
                const totalCount = selected.length;
                const validRecords = selected.filter(cb => cb.getAttribute('data-is-valid') === 'true');
                const invalidRecords = selected.filter(cb => cb.getAttribute('data-is-valid') === 'false');
                const validCount = validRecords.length;
                const invalidCount = invalidRecords.length;

                if (validCount === 0) {
                    showToast('Không có hồ sơ nào đủ điều kiện (HbA1c, BMI, Tuổi) để duyệt!', false);
                    return;
                }

                const validIds = validRecords.map(cb => cb.value);
                document.getElementById('bulkApproveRecordIds').value = validIds.join(',');
                document.getElementById('approveTotalCount').innerText = totalCount;
                document.getElementById('approveValidCount').innerText = validCount;
                document.getElementById('approveInvalidCount').innerText = invalidCount;
                document.getElementById('approveValidDatasetCountText').innerText = validCount;

                const confirmBtn = document.getElementById('btnConfirmApproveBulk');
                confirmBtn.innerText = '✓ Duyệt ' + validCount + ' hồ sơ';

                // Handle warning alert & action link
                const warningText = document.getElementById('invalidWarningText');
                const detailsSection = document.getElementById('invalidDetailsSection');
                
                if (invalidCount > 0) {
                    warningText.classList.remove('d-none');
                    detailsSection.classList.remove('d-none');
                    
                    // Render error table rows
                    let listHtml = '';
                    invalidRecords.forEach(cb => {
                        const id = cb.value;
                        const patient = cb.getAttribute('data-patient');
                        const hba1c = cb.getAttribute('data-hba1c');
                        const bmi = cb.getAttribute('data-bmi');
                        const age = cb.getAttribute('data-age');
                        
                        let missing = [];
                        if (!hba1c || parseFloat(hba1c) <= 0) missing.push('Thiếu HbA1c');
                        if (!bmi || parseFloat(bmi) <= 0) missing.push('Thiếu BMI');
                        if (!age || age === 'Chưa rõ') missing.push('Thiếu Tuổi');
                        
                        listHtml += '<tr style="cursor: pointer;" onclick="openErrorDetail(' + id + ')">' +
                            '<td>#' + id + '</td>' +
                            '<td class="fw-semibold">' + patient + '</td>' +
                            '<td class="text-danger">' + missing.join(', ') + '</td>' +
                            '<td class="text-end">' +
                                '<a href="javascript:void(0);" class="btn btn-xs btn-outline-danger py-0 px-2 rounded-pill" style="font-size: 10px;">Chi tiết</a>' +
                            '</td>' +
                        '</tr>';
                    });
                    document.getElementById('bulkErrorListTableBody').innerHTML = listHtml;
                } else {
                    warningText.classList.add('d-none');
                    detailsSection.classList.add('d-none');
                }
                if (!bulkApproveModalObj) {
                    bulkApproveModalObj = new bootstrap.Modal(document.getElementById('bulkApproveModal'));
                    
                    // Setup click listener for error list popup
                    document.getElementById('btnViewErrorRecords').addEventListener('click', function() {
                        if (!bulkErrorListModalObj) {
                            bulkErrorListModalObj = new bootstrap.Modal(document.getElementById('bulkErrorListModal'));
                        }
                        bulkErrorListModalObj.show();
                    });
                }
                document.getElementById('bulkApproveReason').value = '';
                bulkApproveModalObj.show();
            });
        }

        if (btnBulkReject) {
            btnBulkReject.addEventListener('click', function() {
                const selected = Array.from(document.querySelectorAll('.record-checkbox:checked'));
                const totalCount = selected.length;
                const allIds = selected.map(cb => cb.value);

                document.getElementById('bulkRejectRecordIds').value = allIds.join(',');
                document.getElementById('rejectTotalCount').innerText = totalCount;
                document.getElementById('bulkRejectIdsDisplay').innerText = 'Danh sách bệnh án: #' + allIds.join(', #');

                const confirmBtn = document.getElementById('btnConfirmRejectBulk');
                confirmBtn.innerText = 'Từ chối ' + totalCount + ' hồ sơ';

                if (!bulkRejectModalObj) {
                    bulkRejectModalObj = new bootstrap.Modal(document.getElementById('bulkRejectModal'));
                }
                document.getElementById('bulkRejectReason').value = '';
                bulkRejectModalObj.show();
            });
        }

        // Handle AJAX submit for Approve
        const btnConfirmApproveBulk = document.getElementById('btnConfirmApproveBulk');
        if (btnConfirmApproveBulk) {
            btnConfirmApproveBulk.addEventListener('click', function() {
                const form = document.getElementById('bulkApproveForm');
                const params = new URLSearchParams(new FormData(form));

                btnConfirmApproveBulk.disabled = true;
                btnConfirmApproveBulk.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span>Đang xử lý...';

                fetch('${pageContext.request.contextPath}/admin', {
                    method: 'POST',
                    body: params,
                    headers: {'Content-Type': 'application/x-www-form-urlencoded'}
                })
                .then(r => r.json()).then(data => {
                    btnConfirmApproveBulk.disabled = false;
                    btnConfirmApproveBulk.innerText = 'Xác nhận';
                    if (data.success) {
                        if (bulkApproveModalObj) bulkApproveModalObj.hide();
                        showToast(data.message, true);
                        setTimeout(() => window.location.reload(), 1000);
                    } else {
                        showToast('Lỗi: ' + data.message, false);
                    }
                }).catch(err => {
                    btnConfirmApproveBulk.disabled = false;
                    btnConfirmApproveBulk.innerText = 'Xác nhận';
                    console.error(err);
                    showToast('Lỗi kết nối máy chủ.', false);
                });
            });
        }

        // Handle AJAX submit for Reject
        const btnConfirmRejectBulk = document.getElementById('btnConfirmRejectBulk');
        if (btnConfirmRejectBulk) {
            btnConfirmRejectBulk.addEventListener('click', function() {
                const form = document.getElementById('bulkRejectForm');
                const reason = document.getElementById('bulkRejectReason').value;
                if (!reason || reason.trim() === '') {
                    alert('Vui lòng nhập lý do từ chối.');
                    return;
                }
                
                const params = new URLSearchParams(new FormData(form));
                btnConfirmRejectBulk.disabled = true;
                btnConfirmRejectBulk.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span>Đang xử lý...';

                fetch('${pageContext.request.contextPath}/admin', {
                    method: 'POST',
                    body: params,
                    headers: {'Content-Type': 'application/x-www-form-urlencoded'}
                })
                .then(r => r.json()).then(data => {
                    btnConfirmRejectBulk.disabled = false;
                    btnConfirmRejectBulk.innerText = 'Xác nhận';
                    if (data.success) {
                        if (bulkRejectModalObj) bulkRejectModalObj.hide();
                        showToast(data.message, true);
                        setTimeout(() => window.location.reload(), 1000);
                    } else {
                        showToast('Lỗi: ' + data.message, false);
                    }
                }).catch(err => {
                    btnConfirmRejectBulk.disabled = false;
                    btnConfirmRejectBulk.innerText = 'Xác nhận';
                    console.error(err);
                    showToast('Lỗi kết nối máy chủ.', false);
                });
            });
        }

        // ================= GLOBAL BULK ACTIONS CONTROL =================
        const btnApproveAllGlobal = document.getElementById('btnApproveAllGlobal');
        const btnApproveQuantityGlobal = document.getElementById('btnApproveQuantityGlobal');
        
        let globalApproveModalObj = null;
        let quantityApproveModalObj = null;

        function loadGlobalPendingCounts(callback) {
            fetch('${pageContext.request.contextPath}/admin?action=ai-dataset-global-info-json')
            .then(r => r.json()).then(data => {
                if (data.success) {
                    callback(data);
                } else {
                    showToast('Không thể lấy thông tin thống kê duyệt hệ thống.', false);
                }
            }).catch(err => {
                console.error(err);
                showToast('Lỗi kết nối máy chủ khi lấy dữ liệu toàn cục.', false);
            });
        }

        if (btnApproveAllGlobal) {
            btnApproveAllGlobal.addEventListener('click', function() {
                loadGlobalPendingCounts(function(data) {
                    if (data.validPending === 0) {
                        showToast('Không có hồ sơ nào đủ điều kiện (HbA1c, BMI, Tuổi) đang chờ duyệt!', false);
                        return;
                    }
                    document.getElementById('globalPendingCount').innerText = data.totalPending;
                    document.getElementById('globalValidCount').innerText = data.validPending;
                    document.getElementById('globalInvalidCount').innerText = data.invalidPending;
                    document.getElementById('globalValidDatasetCountText').innerText = data.validPending;
                    document.getElementById('btnConfirmGlobalApprove').innerText = '✓ Duyệt ' + data.validPending + ' hồ sơ';
                    
                    if (!globalApproveModalObj) {
                        globalApproveModalObj = new bootstrap.Modal(document.getElementById('globalApproveModal'));
                    }
                    globalApproveModalObj.show();
                });
            });
        }

        if (btnApproveQuantityGlobal) {
            btnApproveQuantityGlobal.addEventListener('click', function() {
                loadGlobalPendingCounts(function(data) {
                    document.getElementById('quantityAvailableValid').innerText = data.validPending;
                    
                    if (!quantityApproveModalObj) {
                        quantityApproveModalObj = new bootstrap.Modal(document.getElementById('quantityApproveModal'));
                    }
                    quantityApproveModalObj.show();
                });
            });
        }

        // Action submit: Approve All Global
        const btnConfirmGlobalApprove = document.getElementById('btnConfirmGlobalApprove');
        if (btnConfirmGlobalApprove) {
            btnConfirmGlobalApprove.addEventListener('click', function() {
                btnConfirmGlobalApprove.disabled = true;
                btnConfirmGlobalApprove.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span>Đang xử lý...';

                const params = new URLSearchParams();
                params.append('action', 'ai-dataset-confirm-global');
                params.append('limit', '-1');
                params.append('csrfToken', '${sessionScope.csrfToken}');

                fetch('${pageContext.request.contextPath}/admin', {
                    method: 'POST',
                    body: params,
                    headers: {'Content-Type': 'application/x-www-form-urlencoded'}
                })
                .then(r => r.json()).then(data => {
                    btnConfirmGlobalApprove.disabled = false;
                    btnConfirmGlobalApprove.innerText = 'Xác nhận';
                    if (data.success) {
                        if (globalApproveModalObj) globalApproveModalObj.hide();
                        showToast(data.message, true);
                        setTimeout(() => window.location.reload(), 1000);
                    } else {
                        showToast('Lỗi: ' + data.message, false);
                    }
                }).catch(err => {
                    btnConfirmGlobalApprove.disabled = false;
                    btnConfirmGlobalApprove.innerText = 'Xác nhận';
                    console.error(err);
                    showToast('Lỗi kết nối máy chủ.', false);
                });
            });
        }

        // Action submit: Approve Quantity Global
        const btnConfirmQuantityApprove = document.getElementById('btnConfirmQuantityApprove');
        if (btnConfirmQuantityApprove) {
            btnConfirmQuantityApprove.addEventListener('click', function() {
                const quantityInput = document.getElementById('approveQuantityInput').value;
                const quantity = parseInt(quantityInput);
                const availableValid = parseInt(document.getElementById('quantityAvailableValid').innerText);

                if (isNaN(quantity) || quantity <= 0) {
                    alert('Vui lòng nhập số lượng hợp lệ lớn hơn 0.');
                    return;
                }
                if (availableValid === 0) {
                    alert('Không có hồ sơ hợp lệ nào để duyệt.');
                    return;
                }

                btnConfirmQuantityApprove.disabled = true;
                btnConfirmQuantityApprove.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span>Đang xử lý...';

                const params = new URLSearchParams();
                params.append('action', 'ai-dataset-confirm-global');
                params.append('limit', quantity.toString());
                params.append('csrfToken', '${sessionScope.csrfToken}');

                fetch('${pageContext.request.contextPath}/admin', {
                    method: 'POST',
                    body: params,
                    headers: {'Content-Type': 'application/x-www-form-urlencoded'}
                })
                .then(r => r.json()).then(data => {
                    btnConfirmQuantityApprove.disabled = false;
                    btnConfirmQuantityApprove.innerText = 'Tiếp tục';
                    if (data.success) {
                        if (quantityApproveModalObj) quantityApproveModalObj.hide();
                        showToast(data.message, true);
                        setTimeout(() => window.location.reload(), 1000);
                    } else {
                        showToast('Lỗi: ' + data.message, false);
                    }
                }).catch(err => {
                    btnConfirmQuantityApprove.disabled = false;
                    btnConfirmQuantityApprove.innerText = 'Tiếp tục';
                    console.error(err);
                    showToast('Lỗi kết nối máy chủ.', false);
                });
            });
        }
    </script>
</c:if>

<%-- ====================== TAB: HUẤN LUYỆN ====================== --%>
<c:if test="${activeTab == 'training'}">
    <%-- Màn hình cấu hình --%>
    <div id="configSection" class="card shadow-sm border-0 mb-4 p-4" style="border-radius:14px;">
        <h5 class="fw-bold mb-3 text-dark"><i class="fa-solid fa-sliders me-2"></i>Huấn luyện mô hình AI mới</h5>
        <p class="text-secondary text-sm mb-4">Hệ thống sẽ thực hiện gửi tín hiệu kích hoạt huấn luyện các thuật toán chẩn đoán tự động trên tập dữ liệu lâm sàng đã duyệt.</p>
        
        <div class="row g-3 mb-4">
            <div class="col-md-6">
                <div class="p-3 bg-light rounded border h-100">
                    <h6 class="fw-bold text-secondary mb-2">Tập dữ liệu khả dụng</h6>
                    <div class="row g-2 text-sm">
                        <div class="col-7">Số bệnh án đã duyệt:</div>
                        <div class="col-5 fw-bold text-success">${approvedDataset}</div>
                        <div class="col-7">Trạng thái:</div>
                        <div class="col-5 text-dark fw-bold">Sẵn sàng</div>
                    </div>
                </div>
            </div>
            <div class="col-md-6">
                <div class="p-3 bg-light rounded border h-100">
                    <h6 class="fw-bold text-secondary mb-2">Thông tin thuật toán</h6>
                    <div class="text-xs text-muted">
                        Mô hình chẩn đoán kết hợp: XGBoost (Mô hình tối ưu), Random Forest, Logistic Regression.
                    </div>
                </div>
            </div>
        </div>

        <form id="trainingForm" class="text-center">
            <input type="hidden" name="action" value="ai-start-training">
            <input type="hidden" name="totalRecords" value="${approvedDataset}">
            <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
            <div class="d-flex justify-content-center gap-2">
                <button type="button" id="btnStartTrain" class="btn btn-success bg-primary-clinic border-0 rounded-pill px-5 py-2.5 fw-bold shadow-sm">
                    <i class="fa-solid fa-play me-2"></i>BẮT ĐẦU HUẤN LUYỆN
                </button>
                <a href="https://wandb.ai/nam30112k5-no/diabetes-prediction/workspace?nw=nwusernam30112k5" target="_blank" class="btn btn-outline-success rounded-pill px-4 py-2.5 fw-bold shadow-sm">
                    <i class="fa-solid fa-chart-line me-2"></i>XEM BÁO CÁO W&B
                </a>
            </div>
        </form>
    </div>

    <%-- Màn hình tiến trình (ẩn ban đầu) --%>
    <div id="progressSection" class="card shadow-sm border-0 mb-4 p-5 text-center d-none" style="border-radius:14px;">
        <div class="py-4">
            <div class="spinner-border text-primary-clinic" style="width: 3rem; height: 3rem;" role="status">
                <span class="visually-hidden">Loading...</span>
            </div>
            <h5 class="fw-bold mt-4 text-dark">Hệ thống đang gửi yêu cầu huấn luyện tới AI Service...</h5>
            <p class="text-secondary text-sm mb-0">Sau khi hoàn thành, hệ thống sẽ đánh giá và lựa chọn mô hình có hiệu suất tốt nhất.</p>
            <div class="text-xs text-muted mt-3">Vui lòng không đóng trình duyệt khi tiến trình đang diễn ra.</div>
        </div>
    </div>

    <%-- Màn hình kết quả (ẩn ban đầu) --%>
    <div id="resultSection" class="card shadow-sm border-0 mb-4 p-4 d-none" style="border-radius:14px;">
        <h5 class="fw-bold mb-3 text-success"><i class="fa-solid fa-circle-check me-2"></i>Huấn luyện hoàn tất!</h5>
        <div class="result-card p-3 mb-4 border bg-light rounded">
            <h6 class="fw-bold text-primary-clinic mb-3">
                <i class="fa-solid fa-award me-1"></i>Mô hình chẩn đoán tối ưu: Mô hình <span id="bestModelLabel" class="fw-extrabold text-success"></span>
            </h6>
            <div class="row g-3 text-sm mb-3">
                <div class="col-5 text-secondary">ID Đợt huấn luyện:</div>
                <div class="col-7 fw-bold text-dark" id="resTrainingId"></div>
                <div class="col-5 text-secondary">Số dữ liệu huấn luyện:</div>
                <div class="col-7 fw-bold text-dark" id="resRecords"></div>
                <div class="col-5 text-secondary">ID đợt huấn luyện (Training Run):</div>
                <div class="col-7 fw-bold text-success" id="resVersion"></div>
                <div class="col-5 text-secondary">Thuật toán tối ưu:</div>
                <div class="col-7 fw-bold text-dark" id="resAlgorithm"></div>
                <div class="col-5 text-secondary">Độ chính xác (Accuracy):</div>
                <div class="col-7 fw-bold text-dark"><span id="resAccuracy"></span>%</div>
                <div class="col-5 text-secondary">Điểm F1-Score:</div>
                <div class="col-7 fw-bold text-dark"><span id="resF1"></span>%</div>
            </div>
        </div>
        
        <h6 class="fw-bold mb-3 text-secondary">Chi tiết hiệu suất các mô hình so sánh</h6>
        <div class="table-responsive mb-4">
            <table class="table table-bordered text-center align-middle mb-0 text-sm bg-white">
                <thead class="table-light">
                <tr><th>Mô hình</th><th>Thuật toán</th><th>Độ chính xác (Accuracy)</th><th>F1-Score</th></tr>
                </thead>
                <tbody id="metricsTableBody"></tbody>
            </table>
        </div>
        
        <div class="text-center d-flex justify-content-center gap-2">
            <a href="${pageContext.request.contextPath}/admin?action=ai-management"
               class="btn btn-success bg-primary-clinic border-0 rounded-pill px-5 py-2 fw-bold">
                <i class="fa-solid fa-arrow-left me-2"></i>← Quay lại tổng quan
            </a>
            <a href="https://wandb.ai/" id="btnViewWandbReport" target="_blank"
               class="btn btn-outline-success rounded-pill px-5 py-2 fw-bold">
                <i class="fa-solid fa-chart-line me-2"></i>Xem báo cáo đợt train này
            </a>
        </div>
    </div>

    <script>
        let pollInterval = null;
        document.getElementById('btnStartTrain').addEventListener('click', function() {
            const form = document.getElementById('trainingForm');
            const params = new URLSearchParams(new FormData(form));
            document.getElementById('configSection').classList.add('d-none');
            document.getElementById('progressSection').classList.remove('d-none');
            
            fetch('${pageContext.request.contextPath}/admin', {
                method: 'POST', 
                body: params, 
                headers: {'Content-Type': 'application/x-www-form-urlencoded'}
            })
            .then(r => r.json()).then(data => {
                if (data.success) {
                    startPolling(data.trainingId);
                } else { 
                    alert('Lỗi khởi động: ' + data.message); 
                    document.getElementById('configSection').classList.remove('d-none'); 
                    document.getElementById('progressSection').classList.add('d-none'); 
                }
            }).catch(err => { 
                console.error(err); 
                alert('Lỗi kết nối máy chủ.'); 
                document.getElementById('configSection').classList.remove('d-none'); 
                document.getElementById('progressSection').classList.add('d-none'); 
            });
        });

        function startPolling(trainingId) {
            pollInterval = setInterval(() => {
                fetch('${pageContext.request.contextPath}/admin?action=ai-training-progress&trainingId=' + trainingId)
                .then(r => r.json()).then(data => {
                    if (data.status === 'Completed') {
                        clearInterval(pollInterval);
                        setTimeout(() => showResult(trainingId, data), 300);
                    } else if (data.status === 'Failed') { 
                        clearInterval(pollInterval); 
                        alert('Đợt huấn luyện AI thất bại. Vui lòng thử lại.'); 
                        window.location.reload(); 
                    }
                }).catch(err => console.error('Lỗi polling:', err));
            }, 800);
        }

        function showResult(trainingId, data) {
            document.getElementById('progressSection').classList.add('d-none');
            document.getElementById('resultSection').classList.remove('d-none');
            document.getElementById('resTrainingId').innerText = trainingId;
            
            const recCount = data.totalRecords || 150;
            document.getElementById('resRecords').innerText = recCount + ' records (Doctor feedback approved records)';
            document.getElementById('resVersion').innerText = data.bestModelVersion || trainingId;
            document.getElementById('bestModelLabel').innerText = data.bestModel;
            document.getElementById('resAlgorithm').innerText = data.bestAlgorithm;
            document.getElementById('resAccuracy').innerText = data.bestAccuracy;
            document.getElementById('resF1').innerText = data.bestF1;
            document.getElementById('btnViewWandbReport').href = data.wandbUrl || 'https://wandb.ai/';
            
            const tbody = document.getElementById('metricsTableBody'); 
            tbody.innerHTML = '';
            
            let metrics = data.metricsJson;
            if (typeof metrics === 'string') {
                metrics = JSON.parse(metrics);
            }
            
            for (const k in metrics) {
                const row = document.createElement('tr');
                if (k === data.bestModel) {
                    row.classList.add('table-success');
                }
                row.innerHTML = '<td class="fw-bold">' + k + '</td>' +
                                '<td>' + metrics[k].Algorithm + '</td>' +
                                '<td class="fw-bold">' + metrics[k].Accuracy + '%</td>' +
                                '<td>' + (metrics[k].F1 ? metrics[k].F1 + '%' : '-') + '</td>';
                tbody.appendChild(row);
            }
        }
    </script>
</c:if>

<%@ include file="../common/admin-footer.jspf" %>
