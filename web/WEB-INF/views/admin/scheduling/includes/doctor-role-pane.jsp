<%@ page pageEncoding="UTF-8" %>
                <div class="schedule-role-pane is-visible" id="doctorRolePane" role="tabpanel" aria-labelledby="doctor-role-tab" tabindex="0">
            <div class="card mb-3">
                <div class="card-body">
                    <form method="get" action="${pageContext.request.contextPath}/admin" class="row g-3 align-items-end">
                        <input type="hidden" name="action" value="schedule">
                        
                        <!-- Row 1: Thông tin nhân sự & Thời gian -->
                        <div class="col-md-3">
                            <label class="form-label fw-semibold text-secondary">Tên bác sĩ</label>
                            <input type="text" class="form-control" name="doctorName" placeholder="Nhập tên bác sĩ..." value="${doctorNameFilter}">
                        </div>
                        <div class="col-md-3">
                            <label class="form-label fw-semibold text-secondary">Chuyên khoa</label>
                            <select class="form-select" name="department">
                                <option value="">Tất cả chuyên khoa</option>
                                <c:forEach var="dep" items="${departments}">
                                    <option value="${dep}" ${selectedDepartment == dep ? 'selected' : ''}>
                                        <c:choose>
                                            <c:when test="${dep == 'Endocrinology'}">Nội tiết - Tiểu đường</c:when>
                                            <c:when test="${dep == 'Cardiology'}">Tim mạch</c:when>
                                            <c:when test="${dep == 'Nephrology'}">Thận học</c:when>
                                            <c:when test="${dep == 'General'}">Tổng quát</c:when>
                                            <c:otherwise>${dep}</c:otherwise>
                                        </c:choose>
                                    </option>
                                </c:forEach>
                            </select>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label fw-semibold text-secondary">Ngày trực</label>
                            <input type="date" class="form-control" name="workDate" value="${selectedWorkDate}" placeholder="Chọn ngày">
                        </div>
                        <div class="col-md-3">
                            <label class="form-label fw-semibold text-secondary">Trạng thái</label>
                            <select class="form-select" name="doctorStatus">
                                <option value="" ${empty selectedDoctorStatus ? 'selected' : ''}>Tất cả trạng thái</option>
                                <option value="Available" ${selectedDoctorStatus == 'Available' ? 'selected' : ''}>Khả dụng</option>
                                <option value="Full" ${selectedDoctorStatus == 'Full' ? 'selected' : ''}>Đã đầy</option>
                                <option value="Cancelled" ${selectedDoctorStatus == 'Cancelled' ? 'selected' : ''}>Đã hủy</option>
                                <option value="Expired" ${selectedDoctorStatus == 'Expired' ? 'selected' : ''}>Đã qua</option>
                            </select>
                        </div>
                        
                        <!-- Row 2: Hiển thị & Thao tác -->
                        <div class="col-md-3">
                            <label class="form-label fw-semibold text-secondary">Khoảng thời gian hiển thị</label>
                            <select class="form-select" name="doctorViewMode">
                                <option value="upcoming" ${selectedDoctorViewMode == 'upcoming' ? 'selected' : ''}>Lịch sắp diễn ra</option>
                                <option value="history" ${selectedDoctorViewMode == 'history' ? 'selected' : ''}>Lịch 30 ngày</option>
                            </select>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label fw-semibold text-secondary">Số dòng</label>
                            <select class="form-select" name="doctorPageSize">
                                <option value="10" ${doctorPageSize == 10 ? 'selected' : ''}>10 dòng</option>
                                <option value="20" ${doctorPageSize == 20 ? 'selected' : ''}>20 dòng</option>
                                <option value="50" ${doctorPageSize == 50 ? 'selected' : ''}>50 dòng</option>
                            </select>
                            <input type="hidden" name="doctorPage" value="1">
                        </div>
                        <div class="col-md-3"></div>
                        <div class="col-md-3 d-flex justify-content-end gap-2">
                            <button type="submit" class="btn btn-primary px-4 fw-semibold w-100"><i class="fa-solid fa-filter me-2"></i>Lọc</button>
                            <a class="btn btn-outline-secondary px-4 fw-semibold w-100" href="${pageContext.request.contextPath}/admin?action=schedule"><i class="fa-solid fa-rotate-left me-2"></i>Đặt lại</a>
                        </div>
                    </form>
                </div>
            </div>

            <div class="card">
                <div class="card-header fw-semibold">Lịch trực bác sĩ khám</div>
                <div class="table-responsive schedule-list-scroll schedule-table-wrapper">
                    <table class="table table-hover align-middle mb-0 schedule-table schedule-list-table schedule-table-doctor">
                        <thead style="background:#1e3a5f; color:#ffffff;">
                            <tr>
                                <th class="col-person" style="font-weight:700;font-size:0.81rem;letter-spacing:.03em;padding:10px 12px;">Bác sĩ</th>
                                <th class="col-role" style="font-weight:700;font-size:0.81rem;padding:10px 12px;">Chuyên khoa</th>
                                <th class="col-date" style="font-weight:700;font-size:0.81rem;padding:10px 12px;">Ngày trực</th>
                                <th class="col-slot" style="font-weight:700;font-size:0.81rem;padding:10px 12px;">Khung giờ</th>
                                <th class="col-load" style="font-weight:700;font-size:0.81rem;padding:10px 12px;">Công suất</th>
                                <th class="col-quota" style="font-weight:700;font-size:0.81rem;padding:10px 12px;">Suất online</th>
                                <th class="col-load" style="font-weight:700;font-size:0.81rem;padding:10px 12px;">Mức tải</th>
                                <th class="col-status" style="font-weight:700;font-size:0.81rem;padding:10px 12px;">Trạng thái</th>
                                <th class="col-actions" style="font-weight:700;font-size:0.81rem;padding:10px 12px;">Thao tác</th>
                            </tr>
                        </thead>
                        <tbody id="scheduleTableBody">
                            <c:if test="${empty schedules}">
                                <tr>
                                    <td colspan="9">
                                        <div class="schedule-empty-state"><span class="schedule-empty-icon"><i class="bi bi-calendar-x"></i></span><div><div class="schedule-empty-title">Chưa có lịch trực bác sĩ khám</div><p class="schedule-empty-description">Không tìm thấy lịch phù hợp với bộ lọc hiện tại. Hãy thay đổi bộ lọc hoặc tạo ca trực mới.</p></div></div>
                                    </td>
                                </tr>
                            </c:if>
                            <c:forEach var="s" items="${schedules}">
                                <c:set var="bookedAppointments" value="${empty s.bookedAppointments ? 0 : s.bookedAppointments}" />
                                <c:set var="activeAppointments" value="${empty s.activeAppointments ? 0 : s.activeAppointments}" />
                                <c:set var="onlineQuota" value="${empty s.onlineQuota ? 0 : s.onlineQuota}" />
                                <c:set var="onlineBookedCount" value="${empty s.onlineBookedCount ? 0 : s.onlineBookedCount}" />
                                <c:set var="reservedSlots" value="${empty s.reservedSlots ? (s.maxPatients - onlineQuota) : s.reservedSlots}" />
                                <c:set var="loadPct" value="${s.maxPatients > 0 ? (bookedAppointments * 100.0 / s.maxPatients) : 0}" />
                                <tr data-schedule-id="${s.scheduleId}" data-doctor-name="${s.doctorName}" data-department="${s.department}" data-load-pct="${loadPct}" data-active-appointments="${activeAppointments}" data-booked-appointments="${bookedAppointments}" data-online-booked-count="${onlineBookedCount}" data-max-patients="${s.maxPatients}" data-online-quota="${onlineQuota}" data-reserved-slots="${reservedSlots}">
                                    <td>${s.doctorName}</td>
                                    <td>
                                        <c:choose>
                                            <c:when test="${s.department == 'Endocrinology'}">N&#7897;i ti&#7871;t - Ti&#7875;u &#273;&#432;&#7901;ng</c:when>
                                            <c:when test="${s.department == 'Cardiology'}">Tim m&#7841;ch</c:when>
                                            <c:when test="${s.department == 'Nephrology'}">Th&#7853;n h&#7885;c</c:when>
                                            <c:when test="${s.department == 'General'}">T&#7893;ng qu&#225;t</c:when>
                                            <c:otherwise>${s.department}</c:otherwise>
                                        </c:choose>
                                    </td>
                                    <td><fmt:formatDate value="${s.workDate}" pattern="dd/MM/yyyy" /></td>
                                    <td>${s.timeSlot}</td>
                                    <td class="text-center"><div class="fw-semibold">${bookedAppointments}/${s.maxPatients}</div><small class="text-muted d-block">${activeAppointments} đang khám</small></td>
                                    <td class="text-center"><div class="fw-semibold">${onlineBookedCount}/${onlineQuota}</div></td>
                                    <c:set var="displayPct" value="${loadPct gt 100 ? 100 : loadPct}" />
                                    <td class="schedule-load-cell">
                                        <div class="schedule-load-wrap" title="${loadPct >= 100 ? 'Quá tải' : (loadPct >= 80 ? 'Cận đầy' : 'Tải thấp')}">
                                            <div class="progress schedule-load-progress">
                                                <div class="progress-bar ${loadPct >= 100 ? 'bg-danger' : (loadPct >= 80 ? 'bg-warning' : 'bg-success')}"
                                                     role="progressbar"
                                                     style="width: ${displayPct}%;"
                                                     aria-valuemin="0" aria-valuemax="100" aria-valuenow="${loadPct}"></div>
                                            </div>
                                            <span class="badge schedule-load-percent ${loadPct >= 100 ? 'text-bg-danger' : (loadPct >= 80 ? 'text-bg-warning' : 'text-bg-success')}">
                                                <fmt:formatNumber value="${loadPct}" maxFractionDigits="0"/>%
                                            </span>
                                        </div>
                                    </td>
                                    <td>
                                        <c:choose>
                                            <c:when test="${s.effectiveStatus == 'Expired'}">
                                                <span class="badge" style="background:#6c757d;"><i class="bi bi-clock me-1"></i>Đã qua</span>
                                            </c:when>
                                            <c:when test="${s.effectiveStatus == 'Cancelled'}">
                                                <span class="badge" style="background:#dc3545;"><i class="bi bi-x-circle me-1"></i>Đã hủy</span>
                                            </c:when>
                                            <c:when test="${s.effectiveStatus == 'Full'}">
                                                <span class="badge" style="background:#fd7e14;"><i class="bi bi-exclamation-circle me-1"></i>Đã đầy</span>
                                            </c:when>
                                            <c:when test="${s.effectiveStatus == 'Ongoing'}">
                                                <span class="badge" style="background:#0d6efd;"><i class="bi bi-play-circle me-1"></i>Đang diễn ra</span>
                                            </c:when>
                                            <c:when test="${s.effectiveStatus == 'Upcoming'}">
                                                <span class="badge" style="background:#0dcaf0;color:#000;"><i class="bi bi-calendar-event me-1"></i>Sắp diễn ra</span>
                                            </c:when>
                                            <c:when test="${s.effectiveStatus == 'Available'}">
                                                <span class="badge" style="background:#198754;"><i class="bi bi-check-circle me-1"></i>Khả dụng</span>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="badge" style="background:#6c757d;">${s.effectiveStatus}</span>
                                            </c:otherwise>
                                        </c:choose>
                                    </td>
                                    <td>
                                        <c:choose>
                                            <c:when test="${s.effectiveStatus == 'Expired'}">
                                                <div class="dropdown table-actions">
                                                    <button type="button" class="btn btn-sm btn-outline-secondary rounded-circle"
                                                            data-bs-toggle="dropdown" aria-expanded="false" aria-label="Thao tác lịch đã qua">
                                                        <i class="bi bi-three-dots-vertical"></i>
                                                    </button>
                                                    <ul class="dropdown-menu dropdown-menu-end">
                                                        <li>
                                                            <button type="button" class="dropdown-item schedule-detail-action" data-schedule-id="${s.scheduleId}">
                                                                <i class="bi bi-eye me-2"></i>Xem chi tiết
                                                            </button>
                                                        </li>
                                                    </ul>
                                                </div>
                                            </c:when>
                                            <c:when test="${s.effectiveStatus == 'Cancelled'}">
                                                <div class="dropdown table-actions">
                                                    <button type="button" class="btn btn-sm btn-outline-secondary rounded-circle"
                                                            data-bs-toggle="dropdown" aria-expanded="false" aria-label="Thao tác lịch đã hủy">
                                                        <i class="bi bi-three-dots-vertical"></i>
                                                    </button>
                                                    <ul class="dropdown-menu dropdown-menu-end">
                                                        <li>
                                                            <button type="button" class="dropdown-item schedule-detail-action" data-schedule-id="${s.scheduleId}">
                                                                <i class="bi bi-eye me-2"></i>Xem chi tiết
                                                            </button>
                                                        </li>
                                                    </ul>
                                                </div>
                                            </c:when>
                                            <c:otherwise>
                                                <div class="dropdown table-actions">
                                                    <button type="button" class="btn btn-sm btn-outline-secondary rounded-circle"
                                                            data-bs-toggle="dropdown" aria-expanded="false" aria-label="Thao tác lịch trực">
                                                        <i class="bi bi-three-dots-vertical"></i>
                                                    </button>
                                                    <ul class="dropdown-menu dropdown-menu-end">
                                                        <li>
                                                            <button type="button" class="dropdown-item schedule-detail-action" data-schedule-id="${s.scheduleId}">
                                                                <i class="bi bi-eye me-2"></i>Xem chi tiết
                                                            </button>
                                                        </li>
                                                        <li>
                                                            <button type="button" class="dropdown-item" onclick="openEditScheduleModal('${s.scheduleId}'); return false;">
                                                                <i class="bi bi-pencil-square me-2"></i>Chỉnh sửa
                                                            </button>
                                                        </li>
                                                        <li>
                                                            <button type="button" class="dropdown-item" onclick="openTransferModalFromRow(this); return false;">
                                                                <i class="bi bi-arrow-left-right me-2"></i>Chuyển ca
                                                            </button>
                                                        </li>
                                                        <li>
                                                            <form method="post" action="${pageContext.request.contextPath}/admin"
                                                                  onsubmit="return confirm('Bạn chắc chắn muốn hủy ca trực này?');">
                                                                <input type="hidden" name="action" value="cancelSchedule">
                                                                <input type="hidden" name="scheduleId" value="${s.scheduleId}">
                                                                <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                                                                <button type="submit" class="dropdown-item text-danger">
                                                                    <i class="bi bi-trash me-2"></i>Hủy lịch
                                                                </button>
                                                            </form>
                                                        </li>
                                                    </ul>
                                                </div>
                                            </c:otherwise>
                                        </c:choose>
                                    </td>

                                </tr>
                            </c:forEach>
                        </tbody>
                    </table>
                </div>
                <div class="schedule-pagination-footer">
                    <div class="text-muted fw-semibold" style="font-size:0.82rem;">
                        Hiển thị ${doctorPage.startRecord}–${doctorPage.endRecord} trong tổng số ${doctorPage.totalRecords} lịch trực
                    </div>
                    <nav aria-label="Phân trang lịch trực bác sĩ">
                        <ul class="pagination pagination-sm mb-0">
                            <li class="page-item ${doctorPage.currentPage <= 1 ? 'disabled' : ''}">
                                <a class="page-link" href="${doctorPaginationBaseUrl}&doctorPage=${doctorPage.currentPage - 1}#doctorRolePane">&lsaquo; Trước</a>
                            </li>
                            <li class="page-item disabled">
                                <span class="page-link text-muted" style="font-size:0.78rem;">Trang ${doctorPage.currentPage} / ${doctorPage.totalPages}</span>
                            </li>
                            <li class="page-item ${doctorPage.currentPage >= doctorPage.totalPages ? 'disabled' : ''}">
                                <a class="page-link" href="${doctorPaginationBaseUrl}&doctorPage=${doctorPage.currentPage + 1}#doctorRolePane">Sau &rsaquo;</a>
                            </li>
                        </ul>
                    </nav>
                </div>

            </div>
                </div>

