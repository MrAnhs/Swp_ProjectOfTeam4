<%@ page pageEncoding="UTF-8" %>
            <div id="labRolePane" class="schedule-role-pane staff-role-pane" role="tabpanel" aria-labelledby="lab-role-tab" tabindex="0" hidden>
            <div class="card">
                <div class="card-header fw-semibold d-flex justify-content-between align-items-center flex-wrap gap-2">
                    <span>Lịch trực bác sĩ xét nghiệm</span>
                </div>
                <div class="card-body border-bottom">
                    <form method="get" action="${pageContext.request.contextPath}/admin" class="row g-3 align-items-end">
                        <input type="hidden" name="action" value="schedule">
                        <input type="hidden" name="staffType" value="doctor_lab">
                        
                        <div class="col-md-4">
                            <label class="form-label fw-semibold text-secondary">Tên bác sĩ xét nghiệm</label>
                            <input type="text" class="form-control" name="staffName" value="${staffNameFilter}" placeholder="Nhập tên bác sĩ xét nghiệm...">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label fw-semibold text-secondary">Ngày trực</label>
                            <input type="date" class="form-control" name="staffWorkDate" value="${selectedStaffWorkDate}" placeholder="Chọn ngày">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label fw-semibold text-secondary">Trạng thái</label>
                            <select class="form-select" name="labStatus">
                                <option value="" ${empty selectedLabStatus ? 'selected' : ''}>Tất cả trạng thái</option>
                                <option value="Scheduled" ${selectedLabStatus == 'Scheduled' ? 'selected' : ''}>Đã xếp lịch</option>
                                <option value="Cancelled" ${selectedLabStatus == 'Cancelled' ? 'selected' : ''}>Đã hủy</option>
                                <option value="Expired" ${selectedLabStatus == 'Expired' ? 'selected' : ''}>Đã qua</option>
                                <option value="Completed" ${selectedLabStatus == 'Completed' ? 'selected' : ''}>Hoàn tất</option>
                            </select>
                        </div>
                        
                        <div class="col-md-4">
                            <label class="form-label fw-semibold text-secondary">Khoảng thời gian hiển thị</label>
                            <select class="form-select" name="labViewMode">
                                <option value="upcoming" ${selectedLabViewMode == 'upcoming' ? 'selected' : ''}>Lịch sắp diễn ra</option>
                                <option value="history" ${selectedLabViewMode == 'history' ? 'selected' : ''}>Lịch 30 ngày</option>
                            </select>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label fw-semibold text-secondary">Số dòng</label>
                            <select class="form-select" name="labPageSize">
                                <option value="10" ${labPageSize == 10 ? 'selected' : ''}>10 dòng</option>
                                <option value="20" ${labPageSize == 20 ? 'selected' : ''}>20 dòng</option>
                                <option value="50" ${labPageSize == 50 ? 'selected' : ''}>50 dòng</option>
                            </select>
                            <input type="hidden" name="labPage" value="1">
                        </div>
                        <div class="col-md-4 d-flex justify-content-end gap-2">
                            <button type="submit" class="btn btn-primary px-4 fw-semibold w-100"><i class="fa-solid fa-filter me-2"></i>Lọc</button>
                            <a class="btn btn-outline-secondary px-4 fw-semibold w-100" href="${pageContext.request.contextPath}/admin?action=schedule&staffType=doctor_lab"><i class="fa-solid fa-rotate-left me-2"></i>Đặt lại</a>
                        </div>
                    </form>
                </div>
                <div class="table-responsive schedule-list-scroll schedule-table-wrapper">
                    <table class="table table-hover align-middle mb-0 schedule-list-table schedule-table-lab">
                        <thead style="background:#1e3a5f; color:#ffffff;">
                            <tr>
                                <th style="width:20%;font-weight:700;font-size:0.81rem;padding:10px 12px;">Bác sĩ xét nghiệm</th>
                                <th style="width:25%;font-weight:700;font-size:0.81rem;padding:10px 12px;">Phòng xét nghiệm</th>
                                <th style="width:10%;font-weight:700;font-size:0.81rem;padding:10px 12px;">Số phòng</th>
                                <th style="width:13%;font-weight:700;font-size:0.81rem;padding:10px 12px;">Ngày trực</th>
                                <th style="width:12%;font-weight:700;font-size:0.81rem;padding:10px 12px;">Khung giờ</th>
                                <th style="width:13%;font-weight:700;font-size:0.81rem;padding:10px 12px;">Trạng thái</th>
                                <th style="width:7%;font-weight:700;font-size:0.81rem;padding:10px 12px;">Thao tác</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:if test="${empty labSchedules}">
                                <tr>
                                    <td colspan="7"><div class="schedule-empty-state"><span class="schedule-empty-icon"><i class="bi bi-calendar-x"></i></span><div><div class="schedule-empty-title">Chưa có lịch trực bác sĩ xét nghiệm</div><p class="schedule-empty-description">Không tìm thấy lịch phù hợp với bộ lọc hiện tại. Hãy thay đổi bộ lọc hoặc tạo ca trực mới.</p></div></div></td>
                                </tr>
                            </c:if>
                            <c:forEach var="ss" items="${labSchedules}">
                                <tr data-staff-schedule-id="${ss.staffScheduleId}">
                                    <td>${ss.staffName}</td>
                                    <td><c:choose><c:when test="${not empty ss.roomName}">${ss.roomName}</c:when><c:otherwise>-</c:otherwise></c:choose></td>
                                    <td>${empty ss.roomNumber ? '-' : ss.roomNumber}</td>
                                    <td><fmt:formatDate value="${ss.workDate}" pattern="dd/MM/yyyy" /></td>
                                    <td>${ss.timeSlot}</td>
                                    <td>
                                        <c:choose>
                                            <c:when test="${ss.effectiveStatus eq 'Expired'}"><span class="badge" style="background:#6c757d;"><i class="bi bi-clock-history me-1"></i>Đã qua</span></c:when>
                                            <c:when test="${ss.effectiveStatus eq 'Cancelled'}"><span class="badge" style="background:#dc3545;"><i class="bi bi-x-circle me-1"></i>Đã hủy</span></c:when>
                                            <c:when test="${ss.effectiveStatus eq 'Completed'}"><span class="badge" style="background:#0f766e;"><i class="bi bi-check2-circle me-1"></i>Hoàn tất</span></c:when>
                                            <c:when test="${ss.effectiveStatus eq 'Ongoing'}"><span class="badge" style="background:#0d6efd;"><i class="bi bi-play-circle me-1"></i>Đang diễn ra</span></c:when>
                                            <c:when test="${ss.effectiveStatus eq 'Upcoming'}"><span class="badge" style="background:#0dcaf0;color:#000;"><i class="bi bi-calendar-event me-1"></i>Sắp diễn ra</span></c:when>
                                            <c:otherwise><span class="badge" style="background:#198754;"><i class="bi bi-check-circle me-1"></i>Đã xếp lịch</span></c:otherwise>
                                        </c:choose>
                                    </td>
                                    <td>
                                        <div class="dropdown table-actions">
                                            <button type="button" class="btn btn-sm btn-outline-secondary rounded-circle" data-bs-toggle="dropdown" aria-expanded="false" aria-label="Thao tác lịch trực bác sĩ xét nghiệm">
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
                        Hiển thị ${labPage.startRecord}–${labPage.endRecord} trong tổng số ${labPage.totalRecords} lịch trực
                    </div>
                    <nav aria-label="Phân trang lịch trực xét nghiệm">
                        <ul class="pagination pagination-sm mb-0">
                            <li class="page-item ${labPage.currentPage <= 1 ? 'disabled' : ''}">
                                <a class="page-link" href="${labPaginationBaseUrl}&labPage=${labPage.currentPage - 1}#labRolePane">&lsaquo; Trước</a>
                            </li>
                            <li class="page-item disabled">
                                <span class="page-link text-muted" style="font-size:0.78rem;">Trang ${labPage.currentPage} / ${labPage.totalPages}</span>
                            </li>
                            <li class="page-item ${labPage.currentPage >= labPage.totalPages ? 'disabled' : ''}">
                                <a class="page-link" href="${labPaginationBaseUrl}&labPage=${labPage.currentPage + 1}#labRolePane">Sau &rsaquo;</a>
                            </li>
                        </ul>
                    </nav>
                </div>
            </div>
            </div>


