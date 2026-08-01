<%@ page pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
            <div id="receptionistRolePane" class="schedule-role-pane staff-role-pane" role="tabpanel" aria-labelledby="receptionist-role-tab" tabindex="0" ${currentRoleFilter != 'Receptionist' && currentRoleFilter != 'all' ? 'hidden style="display:none;"' : ''}>
            <div class="card">
                <div class="card-header fw-semibold d-flex justify-content-between align-items-center flex-wrap gap-2">
                    <span>Lịch trực lễ tân</span>
                </div>
                <div class="table-responsive schedule-list-scroll schedule-table-wrapper">
                    <table class="table table-hover align-middle mb-0 schedule-list-table schedule-table-receptionist">
                        <thead style="background:#1e3a5f; color:#ffffff;">
                            <tr>
                                <th style="width:30%;font-weight:700;font-size:0.81rem;padding:10px 12px;">Lễ tân</th>
                                <th style="width:20%;font-weight:700;font-size:0.81rem;padding:10px 12px;">Ngày trực</th>
                                <th style="width:20%;font-weight:700;font-size:0.81rem;padding:10px 12px;">Khung giờ</th>
                                <th style="width:20%;font-weight:700;font-size:0.81rem;padding:10px 12px;">Trạng thái</th>
                                <th style="width:10%;font-weight:700;font-size:0.81rem;padding:10px 12px;">Thao tác</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:if test="${empty receptionistSchedules}">
                                        <tr>
                                            <td colspan="5" class="text-center py-5">
                                                <div class="schedule-empty-container text-center py-3">
                                                    <span class="schedule-empty-icon"><i class="fa-solid fa-calendar-minus text-secondary fs-4"></i></span>
                                                    <div class="schedule-empty-title mt-2">Chưa có lịch trực lễ tân</div>
                                                    <div class="schedule-empty-subtitle text-muted small">Không tìm thấy lịch phù hợp với bộ lọc hiện tại. Hãy thay đổi bộ lọc hoặc tạo ca trực mới.</div>
                                                </div>
                                            </td>
                                        </tr>
                            </c:if>
                            <c:forEach var="ss" items="${receptionistSchedules}">
                                <tr data-staff-schedule-id="${ss.staffScheduleId}" data-room-id="${ss.roomId}" data-department="${ss.department}">
                                    <td>${ss.staffName}</td>
                                    <td><fmt:formatDate value="${ss.workDate}" pattern="dd/MM/yyyy" /></td>
                                    <td>${ss.timeSlot}</td>
                                     <td>
                                         <c:choose>
                                             <c:when test="${ss.effectiveStatus eq 'Completed' || ss.effectiveStatus eq 'Expired'}"><span class="badge" style="background:#6c757d;"><i class="bi bi-check2-circle me-1"></i>Đã hoàn thành</span></c:when>
                                             <c:when test="${ss.effectiveStatus eq 'Cancelled'}"><span class="badge" style="background:#dc3545;"><i class="bi bi-x-circle me-1"></i>Đã hủy</span></c:when>
                                             <c:when test="${ss.effectiveStatus eq 'Ongoing'}"><span class="badge" style="background:#0d6efd;"><i class="bi bi-play-circle me-1"></i>Đang diễn ra</span></c:when>
                                             <c:when test="${ss.effectiveStatus eq 'Upcoming'}"><span class="badge" style="background:#0dcaf0;color:#000;"><i class="bi bi-calendar-event me-1"></i>Sắp diễn ra</span></c:when>
                                             <c:otherwise><span class="badge" style="background:#198754;"><i class="bi bi-check-circle me-1"></i>Sẵn sàng</span></c:otherwise>
                                         </c:choose>
                                     </td>
                                    <td>
                                        <div class="dropdown table-actions">
                                            <button type="button" class="btn btn-sm btn-outline-secondary rounded-circle" data-bs-toggle="dropdown" aria-expanded="false" aria-label="Thao tác lịch trực lễ tân">
                                                <i class="bi bi-three-dots-vertical"></i>
                                            </button>
                                            <ul class="dropdown-menu dropdown-menu-end">
                                                <li><button type="button" class="dropdown-item staff-schedule-detail-action" data-staff-schedule-id="${ss.staffScheduleId}"><i class="bi bi-eye me-2"></i>Xem chi tiết</button></li>
                                                <c:if test="${ss.isEditable}">
                                                    <li><button type="button" class="dropdown-item" onclick="openEditStaffScheduleModal('${ss.staffScheduleId}'); return false;"><i class="bi bi-pencil-square me-2"></i>Chỉnh sửa</button></li>
                                                    <li><hr class="dropdown-divider"></li>
                                                    <li>
                                                        <form method="post" action="${pageContext.request.contextPath}/admin" onsubmit="return confirm('Bạn có chắc muốn hủy lịch trực này?');">
                                                            <input type="hidden" name="action" value="cancel-staff-schedule">
                                                            <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                                                            <input type="hidden" name="staffScheduleId" value="${ss.staffScheduleId}">
                                                            <input type="hidden" name="staffType" value="${ss.staffType}">
                                                            <button type="submit" class="dropdown-item text-danger"><i class="bi bi-trash me-2"></i>Hủy lịch</button>
                                                        </form>
                                                    </li>
                                                </c:if>
                                            </ul>
                                        </div>
                                    </td>
                                </tr>
                            </c:forEach>
                        </tbody>
                    </table>
                </div>
                <div class="schedule-pagination-footer">
                    <div class="text-muted fw-semibold" style="font-size:0.82rem;">
                        Hiển thị ${receptionistPage.startRecord}–${receptionistPage.endRecord} trong tổng số ${receptionistPage.totalRecords} lịch trực
                    </div>
                    <nav aria-label="Phân trang lịch trực lễ tân">
                        <ul class="pagination pagination-sm mb-0">
                            <li class="page-item ${receptionistPage.currentPage <= 1 ? 'disabled' : ''}">
                                <a class="page-link" href="${receptionistPaginationBaseUrl}&receptionistPage=${receptionistPage.currentPage - 1}#receptionistRolePane">&lsaquo; Trước</a>
                            </li>
                            <li class="page-item disabled">
                                <span class="page-link text-muted" style="font-size:0.78rem;">Trang ${receptionistPage.currentPage} / ${receptionistPage.totalPages}</span>
                            </li>
                            <li class="page-item ${receptionistPage.currentPage >= receptionistPage.totalPages ? 'disabled' : ''}">
                                <a class="page-link" href="${receptionistPaginationBaseUrl}&receptionistPage=${receptionistPage.currentPage + 1}#receptionistRolePane">Sau &rsaquo;</a>
                            </li>
                        </ul>
                    </nav>
                </div>
            </div>
            </div>


