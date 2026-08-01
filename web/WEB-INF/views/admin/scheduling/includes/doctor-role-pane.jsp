<%@ page pageEncoding="UTF-8" %>
    <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
        <%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
            <%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
                <div class="schedule-role-pane" id="doctorRolePane" role="tabpanel"
                    aria-labelledby="doctor-role-tab" tabindex="0" ${currentRoleFilter != 'Doctor' && currentRoleFilter != 'all' ? 'hidden style="display:none;"' : ''}>

                    <div class="card">
                        <div class="card-header fw-semibold">Lịch trực bác sĩ khám</div>
                        <div class="table-responsive schedule-list-scroll schedule-table-wrapper">
                            <table
                                class="table table-hover align-middle mb-0 schedule-table schedule-list-table schedule-table-doctor">
                                <thead style="background:#1e3a5f; color:#ffffff;">
                                    <tr>
                                        <th class="col-person"
                                            style="font-weight:700;font-size:0.81rem;letter-spacing:.03em;padding:10px 12px;">
                                            Bác sĩ</th>
                                        <th class="col-role"
                                            style="font-weight:700;font-size:0.81rem;padding:10px 12px;">Chuyên khoa
                                        </th>
                                        <th class="col-date"
                                            style="font-weight:700;font-size:0.81rem;padding:10px 12px;">Ngày trực</th>
                                        <th class="col-slot"
                                            style="font-weight:700;font-size:0.81rem;padding:10px 12px;">Khung giờ</th>
                                        <th class="col-room"
                                            style="font-weight:700;font-size:0.81rem;padding:10px 12px;">Phòng khám</th>
                                        <th class="col-load"
                                            style="font-weight:700;font-size:0.81rem;padding:10px 12px;">Công suất</th>
                                        <th class="col-quota"
                                            style="font-weight:700;font-size:0.81rem;padding:10px 12px;">Suất online
                                        </th>
                                        <th class="col-load"
                                            style="font-weight:700;font-size:0.81rem;padding:10px 12px;">Mức tải</th>
                                        <th class="col-status"
                                            style="font-weight:700;font-size:0.81rem;padding:10px 12px;">Trạng thái</th>
                                        <th class="col-actions"
                                            style="font-weight:700;font-size:0.81rem;padding:10px 12px;">Thao tác</th>
                                    </tr>
                                </thead>
                                <tbody id="scheduleTableBody">
                                    <c:if test="${empty schedules}">
                                        <tr>
                                            <td colspan="10" class="text-center py-5">
                                                <div class="schedule-empty-container text-center py-3">
                                                    <span class="schedule-empty-icon"><i
                                                            class="fa-solid fa-calendar-minus text-secondary fs-4"></i></span>
                                                    <div class="schedule-empty-title mt-2">Chưa có lịch trực bác sĩ khám
                                                    </div>
                                                    <div class="schedule-empty-subtitle text-muted small">Không tìm thấy
                                                        lịch phù hợp với bộ lọc hiện tại. Hãy thay đổi bộ lọc hoặc tạo
                                                        ca trực mới.</div>
                                                </div>
                                            </td>
                                        </tr>
                                    </c:if>
                                    <c:forEach var="s" items="${schedules}">
                                        <c:set var="bookedAppointments"
                                            value="${empty s.bookedAppointments ? 0 : s.bookedAppointments}" />
                                        <c:set var="activeAppointments"
                                            value="${empty s.activeAppointments ? 0 : s.activeAppointments}" />
                                        <c:set var="onlineQuota" value="${empty s.onlineQuota ? 0 : s.onlineQuota}" />
                                        <c:set var="onlineBookedCount"
                                            value="${empty s.onlineBookedCount ? 0 : s.onlineBookedCount}" />
                                        <c:set var="reservedSlots"
                                            value="${empty s.reservedSlots ? (s.maxPatients - onlineQuota) : s.reservedSlots}" />
                                        <c:set var="loadPct"
                                            value="${s.maxPatients > 0 ? (bookedAppointments * 100.0 / s.maxPatients) : 0}" />
                                        <tr data-schedule-id="${s.scheduleId}" data-doctor-name="${s.doctorName}"
                                            data-department="${s.department}" data-room-id="${s.roomId}"
                                            data-load-pct="${loadPct}" data-active-appointments="${activeAppointments}"
                                            data-booked-appointments="${bookedAppointments}"
                                            data-online-booked-count="${onlineBookedCount}"
                                            data-max-patients="${s.maxPatients}" data-online-quota="${onlineQuota}"
                                            data-reserved-slots="${reservedSlots}">
                                            <td>${s.doctorName}</td>
                                            <td>
                                                <c:choose>
                                                    <c:when test="${s.department == 'Endocrinology'}">N&#7897;i
                                                        ti&#7871;t - Ti&#7875;u &#273;&#432;&#7901;ng</c:when>
                                                    <c:when test="${s.department == 'Cardiology'}">Tim m&#7841;ch
                                                    </c:when>
                                                    <c:when test="${s.department == 'Nephrology'}">Th&#7853;n h&#7885;c
                                                    </c:when>
                                                    <c:when test="${s.department == 'General'}">T&#7893;ng qu&#225;t
                                                    </c:when>
                                                    <c:otherwise>${s.department}</c:otherwise>
                                                </c:choose>
                                            </td>
                                            <td>
                                                <fmt:formatDate value="${s.workDate}" pattern="dd/MM/yyyy" />
                                            </td>
                                            <td>${s.timeSlot}</td>
                                            <td>
                                                <c:choose>
                                                    <c:when test="${not empty s.roomName}">
                                                        <span class="badge bg-light text-dark border"><i
                                                                class="fa-solid fa-hospital-user me-1 text-primary"></i>${s.roomName} (${s.roomId})</span>
                                                    </c:when>
                                                    <c:when test="${not empty s.roomId}">
                                                        <span class="badge bg-light text-dark border"><i
                                                                class="fa-solid fa-hospital-user me-1 text-primary"></i>${s.roomId}</span>
                                                    </c:when>
                                                    <c:otherwise>
                                                        <span class="badge bg-light text-dark border"><i
                                                                class="fa-solid fa-hospital-user me-1 text-secondary"></i>Chưa xếp phòng</span>
                                                    </c:otherwise>
                                                </c:choose>
                                            </td>
                                            <td class="text-center">
                                                <div class="fw-semibold">${bookedAppointments}/${s.maxPatients}</div>
                                                <small class="text-muted d-block">${activeAppointments} đang
                                                    khám</small>
                                            </td>
                                            <td class="text-center">
                                                <div class="fw-semibold">${onlineBookedCount}/${onlineQuota}</div>
                                            </td>
                                            <c:set var="displayPct" value="${loadPct gt 100 ? 100 : loadPct}" />
                                            <td class="schedule-load-cell">
                                                <div class="schedule-load-wrap"
                                                    title="${loadPct >= 100 ? 'Quá tải' : (loadPct >= 80 ? 'Cận đầy' : 'Tải thấp')}">
                                                    <div class="progress schedule-load-progress">
                                                        <div class="progress-bar ${loadPct >= 100 ? 'bg-danger' : (loadPct >= 80 ? 'bg-warning' : 'bg-success')}"
                                                            role="progressbar"
                                                            style="--w: ${displayPct}%; width: var(--w);"
                                                            aria-valuemin="0" aria-valuemax="100"
                                                            aria-valuenow="${loadPct}"></div>
                                                    </div>
                                                    <span
                                                        class="badge schedule-load-percent ${loadPct >= 100 ? 'text-bg-danger' : (loadPct >= 80 ? 'text-bg-warning' : 'text-bg-success')}">
                                                        <fmt:formatNumber value="${loadPct}" maxFractionDigits="0" />%
                                                    </span>
                                                </div>
                                            </td>
                                            <td>
                                                <c:choose>
                                                    <c:when test="${s.effectiveStatus == 'Pending'}">
                                                        <span class="badge" style="background:#ffc107;color:#000;"><i
                                                                class="bi bi-hourglass-split me-1"></i>Chờ duyệt</span>
                                                    </c:when>
                                                    <c:when test="${s.effectiveStatus == 'Completed' || s.effectiveStatus == 'Expired'}">
                                                        <span class="badge" style="background:#6c757d;"><i
                                                                class="bi bi-check2-circle me-1"></i>Đã hoàn thành</span>
                                                    </c:when>
                                                    <c:when test="${s.effectiveStatus == 'Cancelled'}">
                                                        <span class="badge" style="background:#dc3545;"><i
                                                                class="bi bi-x-circle me-1"></i>Đã hủy</span>
                                                    </c:when>
                                                    <c:when test="${s.effectiveStatus == 'Full'}">
                                                        <span class="badge" style="background:#fd7e14;"><i
                                                                class="bi bi-exclamation-circle me-1"></i>Đã đầy</span>
                                                    </c:when>
                                                    <c:when test="${s.effectiveStatus == 'Ongoing'}">
                                                        <span class="badge" style="background:#0d6efd;"><i
                                                                class="bi bi-play-circle me-1"></i>Đang diễn ra</span>
                                                    </c:when>
                                                    <c:when test="${s.effectiveStatus == 'Upcoming'}">
                                                        <span class="badge" style="background:#0dcaf0;color:#000;"><i
                                                                class="bi bi-calendar-event me-1"></i>Sắp diễn ra</span>
                                                    </c:when>
                                                    <c:when test="${s.effectiveStatus == 'Available'}">
                                                        <span class="badge" style="background:#198754;"><i
                                                                class="bi bi-check-circle me-1"></i>Khả dụng</span>
                                                    </c:when>
                                                    <c:otherwise>
                                                        <span class="badge"
                                                            style="background:#6c757d;">${s.effectiveStatus}</span>
                                                    </c:otherwise>
                                                </c:choose>
                                            </td>
                                            <td>
                                                <c:choose>
                                                    <c:when test="${s.effectiveStatus == 'Pending'}">
                                                        <div class="dropdown table-actions">
                                                            <button type="button"
                                                                class="btn btn-sm btn-outline-secondary rounded-circle"
                                                                data-bs-toggle="dropdown" aria-expanded="false"
                                                                aria-label="Thao tác lịch chờ duyệt">
                                                                <i class="bi bi-three-dots-vertical"></i>
                                                            </button>
                                                            <ul class="dropdown-menu dropdown-menu-end">
                                                                <li>
                                                                    <button type="button"
                                                                        class="dropdown-item schedule-detail-action"
                                                                        data-schedule-id="${s.scheduleId}">
                                                                        <i class="bi bi-eye me-2"></i>Xem chi tiết
                                                                    </button>
                                                                </li>
                                                                <li>
                                                                    <form method="post"
                                                                        action="${pageContext.request.contextPath}/admin"
                                                                        onsubmit="return confirm('Bạn chắc chắn muốn duyệt ca trực này?');"
                                                                        style="display:inline;">
                                                                        <input type="hidden" name="action"
                                                                            value="approveSchedule">
                                                                        <input type="hidden" name="scheduleId"
                                                                            value="${s.scheduleId}">
                                                                        <input type="hidden" name="csrfToken"
                                                                            value="${sessionScope.csrfToken}">
                                                                        <button type="submit"
                                                                            class="dropdown-item text-success">
                                                                            <i
                                                                                class="bi bi-check-circle me-2 text-success"></i>Duyệt
                                                                            ca trực
                                                                        </button>
                                                                    </form>
                                                                </li>
                                                                <li>
                                                                    <form method="post"
                                                                        action="${pageContext.request.contextPath}/admin"
                                                                        onsubmit="return confirm('Bạn chắc chắn muốn từ chối ca trực này? (Ca trực sẽ bị xóa)');"
                                                                        style="display:inline;">
                                                                        <input type="hidden" name="action"
                                                                            value="deleteSchedule">
                                                                        <input type="hidden" name="scheduleId"
                                                                            value="${s.scheduleId}">
                                                                        <input type="hidden" name="csrfToken"
                                                                            value="${sessionScope.csrfToken}">
                                                                        <button type="submit"
                                                                            class="dropdown-item text-danger">
                                                                            <i
                                                                                class="bi bi-x-circle me-2 text-danger"></i>Từ
                                                                            chối (Xóa)
                                                                        </button>
                                                                    </form>
                                                                </li>
                                                            </ul>
                                                        </div>
                                                    </c:when>
                                                    <c:when test="${s.effectiveStatus == 'Expired'}">
                                                        <div class="dropdown table-actions">
                                                            <button type="button"
                                                                class="btn btn-sm btn-outline-secondary rounded-circle"
                                                                data-bs-toggle="dropdown" aria-expanded="false"
                                                                aria-label="Thao tác lịch đã qua">
                                                                <i class="bi bi-three-dots-vertical"></i>
                                                            </button>
                                                            <ul class="dropdown-menu dropdown-menu-end">
                                                                <li>
                                                                    <button type="button"
                                                                        class="dropdown-item schedule-detail-action"
                                                                        data-schedule-id="${s.scheduleId}">
                                                                        <i class="bi bi-eye me-2"></i>Xem chi tiết
                                                                    </button>
                                                                </li>
                                                            </ul>
                                                        </div>
                                                    </c:when>
                                                    <c:when test="${s.effectiveStatus == 'Cancelled'}">
                                                        <div class="dropdown table-actions">
                                                            <button type="button"
                                                                class="btn btn-sm btn-outline-secondary rounded-circle"
                                                                data-bs-toggle="dropdown" aria-expanded="false"
                                                                aria-label="Thao tác lịch đã hủy">
                                                                <i class="bi bi-three-dots-vertical"></i>
                                                            </button>
                                                            <ul class="dropdown-menu dropdown-menu-end">
                                                                <li>
                                                                    <button type="button"
                                                                        class="dropdown-item schedule-detail-action"
                                                                        data-schedule-id="${s.scheduleId}">
                                                                        <i class="bi bi-eye me-2"></i>Xem chi tiết
                                                                    </button>
                                                                </li>
                                                            </ul>
                                                        </div>
                                                    </c:when>
                                                    <c:otherwise>
                                                        <div class="dropdown table-actions">
                                                            <button type="button"
                                                                class="btn btn-sm btn-outline-secondary rounded-circle"
                                                                data-bs-toggle="dropdown" aria-expanded="false"
                                                                aria-label="Thao tác lịch trực">
                                                                <i class="bi bi-three-dots-vertical"></i>
                                                            </button>
                                                            <ul class="dropdown-menu dropdown-menu-end">
                                                                <li>
                                                                    <button type="button"
                                                                        class="dropdown-item schedule-detail-action"
                                                                        data-schedule-id="${s.scheduleId}">
                                                                        <i class="bi bi-eye me-2"></i>Xem chi tiết
                                                                    </button>
                                                                </li>
                                                                <li>
                                                                    <button type="button" class="dropdown-item"
                                                                        onclick="openEditScheduleModal('${s.scheduleId}'); return false;">
                                                                        <i class="bi bi-pencil-square me-2"></i>Chỉnh
                                                                        sửa
                                                                    </button>
                                                                </li>
                                                                <li>
                                                                    <form method="post"
                                                                        action="${pageContext.request.contextPath}/admin"
                                                                        onsubmit="return confirm('Bạn chắc chắn muốn hủy ca trực này?');">
                                                                        <input type="hidden" name="action"
                                                                            value="cancelSchedule">
                                                                        <input type="hidden" name="scheduleId"
                                                                            value="${s.scheduleId}">
                                                                        <input type="hidden" name="csrfToken"
                                                                            value="${sessionScope.csrfToken}">
                                                                        <button type="submit"
                                                                            class="dropdown-item text-danger">
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
                                Hiển thị ${doctorPage.startRecord}–${doctorPage.endRecord} trong tổng số
                                ${doctorPage.totalRecords} lịch trực
                            </div>
                            <nav aria-label="Phân trang lịch trực bác sĩ">
                                <ul class="pagination pagination-sm mb-0">
                                    <li class="page-item ${doctorPage.currentPage <= 1 ? 'disabled' : ''}">
                                        <a class="page-link"
                                            href="${doctorPaginationBaseUrl}&doctorPage=${doctorPage.currentPage - 1}#doctorRolePane">&lsaquo;
                                            Trước</a>
                                    </li>
                                    <li class="page-item disabled">
                                        <span class="page-link text-muted" style="font-size:0.78rem;">Trang
                                            ${doctorPage.currentPage} / ${doctorPage.totalPages}</span>
                                    </li>
                                    <li
                                        class="page-item ${doctorPage.currentPage >= doctorPage.totalPages ? 'disabled' : ''}">
                                        <a class="page-link"
                                            href="${doctorPaginationBaseUrl}&doctorPage=${doctorPage.currentPage + 1}#doctorRolePane">Sau
                                            &rsaquo;</a>
                                    </li>
                                </ul>
                            </nav>
                        </div>

                    </div>
                </div>