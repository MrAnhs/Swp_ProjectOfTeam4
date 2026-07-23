<%@ page pageEncoding="UTF-8" %>
    <c:if test="${not empty selectedSchedule}">
        <div class="card mt-4 border-primary-subtle">
            <div class="card-header fw-semibold d-flex justify-content-between align-items-center">
                <span>Chuyển giao ca trực</span>
                <a class="btn btn-sm btn-outline-secondary"
                    href="${pageContext.request.contextPath}/admin?action=schedule">Đóng</a>
            </div>
            <div class="card-body">
                <div class="mb-3">
                    <div class="small text-muted mb-1">Ca đang chọn</div>
                    <div class="fw-semibold">
                        ${selectedSchedule.doctorName} -
                        <c:choose>
                            <c:when test="${selectedSchedule.department == 'Endocrinology'}">Nội tiết
                            </c:when>
                            <c:when test="${selectedSchedule.department == 'Cardiology'}">Tim mạch</c:when>
                            <c:when test="${selectedSchedule.department == 'Nephrology'}">Thận học</c:when>
                            <c:when test="${selectedSchedule.department == 'General'}">Tổng quát</c:when>
                            <c:otherwise>${selectedSchedule.department}</c:otherwise>
                        </c:choose>
                        -
                        <fmt:formatDate value="${selectedSchedule.workDate}" pattern="dd/MM/yyyy" />
                        - ${selectedSchedule.timeSlot}
                    </div>
                </div>
                <form method="post" action="${pageContext.request.contextPath}/admin" class="row g-3">
                    <input type="hidden" name="action" value="transferSchedule">
                    <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                    <input type="hidden" name="scheduleId" value="${selectedSchedule.scheduleId}">
                    <div class="col-md-8">
                        <label class="form-label">Chọn bác sĩ nhận ca</label>
                        <select class="form-select" name="targetDoctorId" required>
                            <option value="">-- Chọn bác sĩ thay thế --</option>
                            <c:forEach var="d" items="${transferCandidates}">
                                <option value="${d.doctorId}">${d.fullName} - ${d.department}</option>
                            </c:forEach>
                        </select>
                        <small class="text-muted">Hệ thống sẽ kiểm tra trùng ca và chỉ cho phép chuyển sang bác sĩ còn
                            khả dụng.</small>
                    </div>
                    <div class="col-md-4 d-flex align-items-end">
                        <button type="submit" class="btn btn-primary w-100">Xác nhận chuyển giao</button>
                    </div>
                </form>
            </div>
        </div>
    </c:if>
    </div>
    </div>

    <div class="modal fade" id="createScheduleModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <form method="post" action="${pageContext.request.contextPath}/admin">
                    <input type="hidden" name="action" value="createSchedule">
                    <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                    <div class="modal-header">
                        <h5 class="modal-title">Tạo ca bác sĩ</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <div class="mb-3">
                            <label class="form-label">Bác sĩ</label>
                            <select class="form-select" name="doctorId" id="createScheduleDoctorId" required>
                                <option value="">-- Chọn bác sĩ --</option>
                                <c:forEach var="d" items="${doctors}">
                                    <option value="${d.doctorId}" data-department="${d.department}">${d.fullName}
                                        (${d.department})</option>
                                </c:forEach>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Phòng trực</label>
                            <select class="form-select" name="roomId" id="createScheduleRoomId" required>
                                <option value="">-- Chọn phòng --</option>
                                <c:forEach var="room" items="${rooms}">
                                    <option value="${room.roomId}">${room.roomNumber} - ${room.roomName}</option>
                                </c:forEach>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Ngày trực</label>
                            <input type="date" class="form-control" name="workDate" required>
                            <div class="mt-1 d-flex justify-content-between align-items-center">
                                <a href="#" id="aiSuggestTimeBtn"
                                    class="text-purple fw-bold small text-decoration-none d-none"
                                    style="color: #7c3aed; cursor: pointer;">
                                    <i class="bi bi-cpu me-1"></i>Xem giờ gợi ý của AI
                                </a>
                                <span id="aiSuggestionFeedback" class="small text-muted"></span>
                            </div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Khung giờ</label>
                            <input class="form-control" name="timeSlot" placeholder="07:00-09:00" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Số bệnh nhân tối đa</label>
                            <input type="number" class="form-control" name="maxPatients" min="1" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Suất online</label>
                            <input type="number" class="form-control" name="onlineQuota" min="0"
                                placeholder="Tự động nếu bỏ trống">
                            <div class="form-text">Nếu để trống, hệ thống sẽ tự dùng cấu hình an toàn mặc định.</div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Hủy</button>
                        <button type="submit" class="btn btn-primary">Lưu lịch trực</button>
                    </div>
                </form>
            </div>
        </div>
    </div>



    <div class="modal fade" id="createReceptionistScheduleModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-lg modal-dialog-scrollable">
            <div class="modal-content">
                <form method="post" action="${pageContext.request.contextPath}/admin">
                    <div class="modal-header">
                        <h5 class="modal-title">Tạo ca lễ tân</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <input type="hidden" name="action" value="create-staff-schedule">
                        <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                        <input type="hidden" name="staffType" value="Receptionist">
                        <div class="row g-3">
                            <div class="col-md-6">
                                <label class="form-label">Lễ tân</label>
                                <select class="form-select" name="accountId" required>
                                    <c:forEach var="staff" items="${receptionists}">
                                        <option value="${staff.accountId}">${staff.fullName}</option>
                                    </c:forEach>
                                </select>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label">Ngày trực</label>
                                <input type="date" class="form-control" name="workDate" required>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label">Khung giờ</label>
                                <input class="form-control" name="timeSlot" placeholder="07:00-11:00" required>
                            </div>
                            <input type="hidden" name="department" value="Tiếp nhận">
                            <input type="hidden" name="workArea" value="">
                            <input type="hidden" name="maxWorkload" value="50">
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Hủy</button>
                        <button type="submit" class="btn btn-primary">Lưu ca lễ tân</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <div class="modal fade" id="createLabScheduleModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-lg modal-dialog-scrollable">
            <div class="modal-content">
                <form method="post" action="${pageContext.request.contextPath}/admin">
                    <div class="modal-header">
                        <h5 class="modal-title">Tạo ca bác sĩ xét nghiệm</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <input type="hidden" name="action" value="create-staff-schedule">
                        <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                        <input type="hidden" name="staffType" value="doctor_lab">
                        <div class="row g-3">
                            <div class="col-md-6">
                                <label class="form-label">Bác sĩ xét nghiệm</label>
                                <select class="form-select" name="accountId" required>
                                    <c:forEach var="staff" items="${labDoctors}">
                                        <option value="${staff.accountId}">${staff.fullName}</option>
                                    </c:forEach>
                                </select>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label">Ngày trực</label>
                                <input type="date" class="form-control" name="workDate" required>
                            </div>
                            <input type="hidden" name="timeSlot" data-lab-time-slot>
                            <input type="hidden" name="workArea" value="">
                            <div class="col-md-6">
                                <label class="form-label">Giờ bắt đầu</label>
                                <input type="time" class="form-control" name="startTime" required>
                                <div class="invalid-feedback">Vui lòng chọn giờ bắt đầu.</div>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label">Giờ kết thúc</label>
                                <input type="time" class="form-control" name="endTime" required>
                                <div class="invalid-feedback">Giờ kết thúc phải sau giờ bắt đầu.</div>
                            </div>
                            <div class="col-md-12">
                                <label class="form-label">Phòng xét nghiệm</label>
                                <select class="form-select" name="roomId" required>
                                    <option value="">-- Chọn phòng xét nghiệm --</option>
                                    <c:forEach var="room" items="${labRooms}">
                                        <option value="${room.roomId}">${room.roomNumber} - ${room.roomName}</option>
                                    </c:forEach>
                                </select>
                                <div class="invalid-feedback">Vui lòng chọn phòng xét nghiệm.</div>
                            </div>
                            <input type="hidden" name="department" value="Xét nghiệm">
                            <input type="hidden" name="maxWorkload" value="50">
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Hủy</button>
                        <button type="submit" class="btn btn-primary">Lưu ca xét nghiệm</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <div class="modal fade" id="aiScheduleModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-lg modal-dialog-centered modal-dialog-scrollable" style="max-height: 90vh;">
            <div class="modal-content border-0 shadow-lg"
                style="max-height: 90vh; display: flex; flex-direction: column;">
                <form id="aiScheduleForm" method="post" action="${pageContext.request.contextPath}/admin"
                    style="display: flex; flex-direction: column; height: 100%; overflow: hidden;">
                    <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                    <input type="hidden" name="action" id="aiAction" value="aiCreateSchedules">
                    <input type="hidden" name="staffType" id="aiStaffType" value="Doctor">

                    <div class="modal-header bg-purple-subtle flex-shrink-0">
                        <div>
                            <h5 class="modal-title text-purple fw-bold mb-1" id="aiModalTitle">
                                <i class="fa-solid fa-wand-magic-sparkles me-2"></i>Lập lịch thông minh
                            </h5>
                            <div class="small text-secondary" id="aiModalSubtitle">Tối ưu hóa nguồn lực và tự động phân
                                bổ ca trực bằng AI Gemini.</div>
                        </div>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>

                    <div class="modal-body flex-grow-1" style="overflow-y: auto; max-height: calc(90vh - 130px);">
                        <div class="row g-3">
                            <%-- ALERT FEEDBACK BOX --%>
                                <div class="col-12" id="aiScheduleAlert" style="display: none;"></div>

                                <%-- CẤU HÌNH THÔNG TIN CHUNG --%>
                                    <div class="col-12">
                                        <div class="ai-section-label mb-2 fw-bold text-purple"
                                            style="font-size: 0.85rem; border-bottom: 2px solid #e9d5ff; padding-bottom: 4px;">
                                            THÔNG TIN CẤU HÌNH
                                        </div>
                                        <div class="row g-2">
                                            <div class="col-md-6">
                                                <label class="form-label small text-secondary">Từ ngày</label>
                                                <input type="date" class="form-control form-control-sm" name="startDate"
                                                    id="aiStartDate" required>
                                            </div>
                                            <div class="col-md-6">
                                                <label class="form-label small text-secondary">Đến ngày</label>
                                                <input type="date" class="form-control form-control-sm" name="endDate"
                                                    id="aiEndDate" required>
                                            </div>
                                        </div>
                                    </div>

                                    <%-- DYNAMIC AREA: CHUYÊN KHOA ÁP DỤNG (CHỈ CHO BÁC SĨ KHÁM) --%>
                                        <div class="col-12" id="aiDeptSelectionSection">
                                            <label class="form-label small text-secondary fw-semibold">Chuyên khoa áp
                                                dụng</label>
                                            <div class="d-flex flex-wrap gap-3 p-2 bg-light rounded border"
                                                id="aiDoctorDeptCheckboxes">
                                                <div class="form-check">
                                                    <input class="form-check-input ai-dept-cb" type="checkbox"
                                                        value="Nội tiết" id="aiDeptEndo" checked>
                                                    <label class="form-check-label small" for="aiDeptEndo">Nội tiết</label>
                                                </div>
                                                <div class="form-check">
                                                    <input class="form-check-input ai-dept-cb" type="checkbox"
                                                        value="Tim mạch" id="aiDeptCardio" checked>
                                                    <label class="form-check-label small" for="aiDeptCardio">Tim
                                                        mạch</label>
                                                </div>
                                                <div class="form-check">
                                                    <input class="form-check-input ai-dept-cb" type="checkbox"
                                                        value="Thận học" id="aiDeptNephro" checked>
                                                    <label class="form-check-label small" for="aiDeptNephro">Thận
                                                        học</label>
                                                </div>
                                                <div class="form-check">
                                                    <input class="form-check-input ai-dept-cb" type="checkbox"
                                                        value="Tổng quát" id="aiDeptGen" checked>
                                                    <label class="form-check-label small" for="aiDeptGen">Tổng
                                                        quát</label>
                                                </div>
                                            </div>
                                        </div>

                                        <%-- DYNAMIC AREA: PHÒNG XÉT NGHIỆM ÁP DỤNG (CHỈ CHO LAB) --%>
                                            <div class="col-12 d-none" id="aiLabRoomSelectionSection">
                                                <label class="form-label small text-secondary fw-semibold">Phòng xét
                                                    nghiệm áp dụng</label>
                                                <div class="d-flex flex-wrap gap-3 p-2 bg-light rounded border mb-1"
                                                    id="aiLabRoomCheckboxes">
                                                    <c:forEach var="room" items="${labRooms}">
                                                        <div class="form-check">
                                                            <input class="form-check-input lab-room-cb" type="checkbox"
                                                                name="roomIds" value="${room.roomId}"
                                                                id="universalLabRoom_${room.roomId}" checked
                                                                data-room-name="${room.roomName}">
                                                            <label class="form-check-label small"
                                                                for="universalLabRoom_${room.roomId}">
                                                                ${room.roomNumber} - ${room.roomName}
                                                            </label>
                                                        </div>
                                                    </c:forEach>
                                                </div>
                                            </div>

                                            <%-- KHUNG CA TRỰC ÁP DỤNG & SỐ NHÂN SỰ MỖI CA --%>
                                                <div class="col-12">
                                                    <div class="row g-2">
                                                        <div class="col-md-6">
                                                            <label
                                                                class="form-label small text-secondary fw-semibold">Khung
                                                                ca trực áp dụng</label>
                                                            <div
                                                                class="d-flex flex-wrap gap-3 p-2 bg-light rounded border">
                                                                <div class="form-check">
                                                                    <input class="form-check-input doctor-ai-shift-cb"
                                                                        type="checkbox" name="aiSelectedShifts"
                                                                        value="07:00-11:30" id="universalShiftMorning"
                                                                        checked>
                                                                    <label
                                                                        class="form-check-label small fw-semibold text-dark"
                                                                        for="universalShiftMorning">Ca sáng (07:00 -
                                                                        11:30)</label>
                                                                </div>
                                                                <div class="form-check">
                                                                    <input class="form-check-input doctor-ai-shift-cb"
                                                                        type="checkbox" name="aiSelectedShifts"
                                                                        value="13:30-17:30" id="universalShiftAfternoon"
                                                                        checked>
                                                                    <label
                                                                        class="form-check-label small fw-semibold text-dark"
                                                                        for="universalShiftAfternoon">Ca chiều (13:30 -
                                                                        17:30)</label>
                                                                </div>
                                                            </div>
                                                        </div>
                                                        <div class="col-md-6">
                                                            <label class="form-label small text-secondary fw-semibold"
                                                                id="aiStaffPerShiftLabel">Số bác sĩ trực mỗi ca</label>
                                                            <select class="form-select form-select-sm"
                                                                name="staffPerShift" id="aiDoctorsPerShift" required>
                                                                <option value="1" selected>1 nhân sự/ca</option>
                                                                <option value="2">2 nhân sự/ca</option>
                                                                <option value="3">3 nhân sự/ca</option>
                                                            </select>
                                                        </div>
                                                    </div>
                                                </div>

                                                <%-- NGÀY ÁP DỤNG TRONG TUẦN --%>
                                                    <div class="col-12">
                                                        <label class="form-label small text-secondary fw-semibold">Ngày
                                                            áp dụng trong tuần</label>
                                                        <div class="weekday-options d-flex flex-wrap gap-2">
                                                            <div class="weekday-option"><input type="checkbox"
                                                                    id="uniWeekday1" name="selectedWeekdays" value="1"
                                                                    checked><label for="uniWeekday1">Thứ 2</label></div>
                                                            <div class="weekday-option"><input type="checkbox"
                                                                    id="uniWeekday2" name="selectedWeekdays" value="2"
                                                                    checked><label for="uniWeekday2">Thứ 3</label></div>
                                                            <div class="weekday-option"><input type="checkbox"
                                                                    id="uniWeekday3" name="selectedWeekdays" value="3"
                                                                    checked><label for="uniWeekday3">Thứ 4</label></div>
                                                            <div class="weekday-option"><input type="checkbox"
                                                                    id="uniWeekday4" name="selectedWeekdays" value="4"
                                                                    checked><label for="uniWeekday4">Thứ 5</label></div>
                                                            <div class="weekday-option"><input type="checkbox"
                                                                    id="uniWeekday5" name="selectedWeekdays" value="5"
                                                                    checked><label for="uniWeekday5">Thứ 6</label></div>
                                                            <div class="weekday-option"><input type="checkbox"
                                                                    id="uniWeekday6" name="selectedWeekdays"
                                                                    value="6"><label for="uniWeekday6">Thứ 7</label>
                                                            </div>
                                                            <div class="weekday-option"><input type="checkbox"
                                                                    id="uniWeekday7" name="selectedWeekdays"
                                                                    value="7"><label for="uniWeekday7">Chủ Nhật</label>
                                                            </div>
                                                        </div>
                                                    </div>

                                                    <%-- DYNAMIC AREA: CONFLICT HANDLING (CHO CẢ 3 VAI TRÒ) --%>
                                                        <div class="col-12" id="aiConflictHandlingSection">
                                                            <label
                                                                class="form-label small text-secondary fw-semibold">Xử
                                                                lý trùng ca trực (nếu có)</label>
                                                            <div class="d-flex flex-wrap gap-3">
                                                                <div class="form-check">
                                                                    <input class="form-check-input" type="radio"
                                                                        name="conflictHandling" value="overwrite"
                                                                        id="uniConflictOverwrite" checked>
                                                                    <label class="form-check-label small"
                                                                        for="uniConflictOverwrite">Ghi đè lịch
                                                                        cũ</label>
                                                                </div>
                                                                <div class="form-check">
                                                                    <input class="form-check-input" type="radio"
                                                                        name="conflictHandling" value="skip"
                                                                        id="uniConflictSkip">
                                                                    <label class="form-check-label small"
                                                                        for="uniConflictSkip">Chỉ tạo ca còn
                                                                        thiếu</label>
                                                                </div>
                                                            </div>
                                                        </div>

                                                        <%-- BẢN XEM TRƯỚC TÓM TẮT TÁC VỤ --%>
                                                            <div class="col-12">
                                                                <div class="p-3 bg-light border rounded-3 border-purple-subtle"
                                                                    id="aiScheduleSummaryBox">
                                                                    <div class="fw-bold text-purple mb-1"><i
                                                                            class="bi bi-info-circle-fill me-2"></i>Tóm
                                                                        tắt tổng số ca trực sẽ tạo:</div>
                                                                    <div id="aiScheduleSummary"
                                                                        class="small text-secondary">Vui lòng điền ngày
                                                                        trực để xem tính toán...</div>
                                                                </div>
                                                            </div>

                                                            <%-- LOADING STATE --%>
                                                                <div id="aiProposalLoading"
                                                                    class="col-12 text-center py-4 d-none">
                                                                    <div class="spinner-border text-purple mb-2"
                                                                        role="status"></div>
                                                                    <div class="fw-semibold text-purple"
                                                                        id="aiLoadingTitle">Đang gửi yêu cầu phân bổ
                                                                        bằng AI Gemini...</div>
                                                                    <div class="small text-secondary mt-1">Hệ thống đang
                                                                        đối chiếu lịch làm việc và tránh trùng lịch cho
                                                                        nhân viên.</div>
                                                                </div>

                                                                <%-- BẢN ĐỀ XUẤT PHÂN CÔNG TỪ AI (CHỈ HIỂN THỊ CHO BÁC
                                                                    SĨ) --%>
                                                                    <div id="aiProposalTableContainer"
                                                                        class="col-12 d-none">
                                                                        <div class="ai-section-label mb-2 fw-bold text-success"
                                                                            style="font-size: 0.85rem; border-bottom: 2px solid #a7f3d0; padding-bottom: 4px;">
                                                                            ĐỀ XUẤT PHÂN CÔNG BÁC SĨ CỦA AI (XEM & CHỈNH
                                                                            SỬA)
                                                                        </div>
                                                                        <div class="table-responsive proposed-table-container border rounded"
                                                                            style="max-height: 250px; overflow-y: auto;">
                                                                            <table
                                                                                class="table table-hover table-bordered proposed-table mb-0 small">
                                                                                <thead class="table-light sticky-top">
                                                                                    <tr>
                                                                                        <th style="width: 15%;">Ngày
                                                                                        </th>
                                                                                        <th style="width: 18%;">Khung
                                                                                            giờ</th>
                                                                                        <th style="width: 22%;">Chuyên
                                                                                            khoa</th>
                                                                                        <th style="width: 25%;">Bác sĩ
                                                                                            đề xuất</th>
                                                                                        <th style="width: 20%;">Lý do đề
                                                                                            xuất (AI)</th>
                                                                                    </tr>
                                                                                </thead>
                                                                                <tbody id="aiProposalTableBody">
                                                                                    <!-- Tải động bằng Javascript -->
                                                                                </tbody>
                                                                            </table>
                                                                        </div>
                                                                    </div>

                                                                    <input type="hidden" name="shiftTemplates"
                                                                        id="aiShiftTemplates">
                                                                    <input type="hidden" name="startTime" value="07:00">
                                                                    <input type="hidden" name="endTime" value="17:00">
                                                                    <input type="hidden" name="slotMinutes" value="60">
                                                                    <input type="hidden" name="department"
                                                                        id="aiDeptHiddenInput" value="">
                                                                    <input type="hidden" id="aiMaxSchedules"
                                                                        name="maxSchedules" value="0">
                                                                    <input type="hidden" name="maxPatients"
                                                                        id="aiMaxPatients" value="20">
                                                                    <input type="hidden" name="maxWorkload" value="50">
                                                                    <input type="hidden" name="workArea" value="">
                                                                    <input type="hidden" name="doctorsPerShift"
                                                                        id="aiDoctorsPerShiftHidden" value="1">
                        </div>
                    </div>

                    <div class="modal-footer py-2 bg-light border-top flex-shrink-0"
                        style="position: sticky; bottom: 0; z-index: 1050; width: 100%;">
                        <button type="button" class="btn btn-outline-secondary px-3" data-bs-dismiss="modal"
                            style="border-radius: 8px;">Hủy bỏ</button>
                        <button type="button" class="btn btn-purple text-white bg-purple border-purple px-4 fw-bold"
                            id="aiRunModelBtn"
                            style="background:#7c3aed; color:#fff; border-color:#7c3aed; border-radius: 8px;">
                            <i class="fa-solid fa-wand-magic-sparkles me-1"></i>Lập lịch thông minh
                        </button>
                        <button type="submit" id="aiScheduleSubmitBtn"
                            class="btn bg-purple-subtle text-purple fw-bold ai-schedule-toolbar-btn px-4"
                            style="display: none; border-radius: 8px;">
                            <i class="fa-solid fa-cloud-arrow-up me-2"></i>Xác nhận lưu lịch trực
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function () {
            const doctorSelect = document.getElementById('createScheduleDoctorId');
            const roomSelect = document.getElementById('createScheduleRoomId');

            if (doctorSelect && roomSelect) {
                doctorSelect.addEventListener('change', function () {
                    const selectedOpt = this.options[this.selectedIndex];
                    if (!selectedOpt) return;
                    const dept = selectedOpt.getAttribute('data-department') || '';
                    autoSelectRoomForDepartment(dept);
                });

                const modal = document.getElementById('createScheduleModal');
                if (modal) {
                    modal.addEventListener('shown.bs.modal', function () {
                        const selectedOpt = doctorSelect.options[doctorSelect.selectedIndex];
                        if (selectedOpt && selectedOpt.value) {
                            const dept = selectedOpt.getAttribute('data-department') || '';
                            autoSelectRoomForDepartment(dept);
                        }
                    });
                }
            }

            function autoSelectRoomForDepartment(dept) {
                if (!roomSelect) return;
                const options = Array.from(roomSelect.options);
                if (options.length <= 1) return;

                let targetKeywords = [];
                const lowerDept = dept.toLowerCase();

                if (lowerDept.includes('endocrin') || lowerDept.includes('nội tiết') || lowerDept.includes('tiểu đường')) {
                    targetKeywords = ['nội tiết', '102', '103', 'xét nghiệm'];
                } else if (lowerDept.includes('cardio') || lowerDept.includes('tim mạch')) {
                    targetKeywords = ['tim mạch', '104', '105', 'tổng quát'];
                } else if (lowerDept.includes('nephro') || lowerDept.includes('thận')) {
                    targetKeywords = ['thận', '103', '102', 'tổng quát'];
                } else {
                    targetKeywords = ['tổng quát', '104', '105', '202', '203'];
                }

                let bestOptionValue = "";
                for (let keyword of targetKeywords) {
                    const match = options.find(opt => opt.text.toLowerCase().includes(keyword.toLowerCase()));
                    if (match) {
                        bestOptionValue = match.value;
                        break;
                    }
                }

                if (!bestOptionValue && options.length > 1) {
                    bestOptionValue = options[1].value;
                }

                if (bestOptionValue) {
                    roomSelect.value = bestOptionValue;
                }
            }
        });
    </script>

    <!-- Modal Xem Danh sách Đầy đủ Ca Trực trong 1 Ô (Cell More Schedules Modal) -->
    <div class="modal fade" id="cellMoreSchedulesModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content border-0 shadow-lg" style="border-radius: 16px;">
                <div class="modal-header border-0 pb-0">
                    <h5 class="modal-title fw-bold text-dark"><i
                            class="fa-solid fa-list-check text-purple me-2"></i>Danh sách ca trực trong khung giờ</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body py-3" id="cellMoreSchedulesList">
                    <!-- Javascript sẽ tự động nạp danh sách ca ở đây -->
                </div>
                <div class="modal-footer border-0 pt-0">
                    <button type="button" class="btn btn-secondary px-4 fw-bold" data-bs-dismiss="modal"
                        style="border-radius: 8px;">Đóng</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Modal Tháo Gỡ Xung Đột 1-Click (Resolve Conflict Modal) -->
    <div class="modal fade" id="resolveConflictModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-lg modal-dialog-centered">
            <div class="modal-content border-0 shadow-lg" style="border-radius: 16px;">
                <div class="modal-header bg-danger-subtle text-danger border-0">
                    <h5 class="modal-title fw-bold"><i class="fa-solid fa-wand-magic-sparkles me-2"></i>Tháo gỡ xung đột
                        trùng ca & trùng phòng</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body py-3">
                    <p class="text-secondary small mb-3">Hệ thống đã tự động phát hiện các ca làm việc bị trùng lặp nhân
                        sự hoặc trùng phòng khám dưới đây. Bạn có thể tháo gỡ tự động chỉ với 1-click:</p>
                    <div id="resolveConflictList" class="d-flex flex-column gap-2">
                        <!-- Javascript sẽ render danh sách ca trùng ở đây -->
                    </div>
                </div>
                <div class="modal-footer border-0 pt-0">
                    <button type="button" class="btn btn-outline-secondary px-3" data-bs-dismiss="modal"
                        style="border-radius: 8px;">Đóng</button>
                    <button type="button" class="btn btn-danger px-4 fw-bold" id="autoResolveAllConflictsBtn"
                        style="border-radius: 8px;">
                        <i class="fa-solid fa-bolt me-1"></i>Tự động sửa tất cả ca trùng
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- Modal Xem Chi Tiết Ca Trực (Shift Detail Modal) -->
    <div class="modal fade" id="shiftDetailModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content border-0 shadow-lg" style="border-radius: 16px;">
                <div class="modal-header border-0 pb-0">
                    <h5 class="modal-title fw-bold text-dark"><i class="bi bi-info-circle text-primary me-2"></i>Chi tiết ca trực</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body py-3">
                    <div id="shiftDetailConflictAlert" class="alert alert-danger d-none mb-3" role="alert">
                        <i class="bi bi-exclamation-triangle-fill me-2"></i><span id="shiftDetailConflictText"></span>
                    </div>
                    <div class="list-group list-group-flush">
                        <div class="list-group-item d-flex justify-content-between align-items-center px-0">
                            <span class="text-muted"><i class="bi bi-person me-2"></i>Bác sĩ / Nhân sự:</span>
                            <span class="fw-semibold text-dark" id="shiftDetailStaff">-</span>
                        </div>
                        <div class="list-group-item d-flex justify-content-between align-items-center px-0">
                            <span class="text-muted"><i class="bi bi-tag me-2"></i>Chuyên khoa / Vai trò:</span>
                            <span class="fw-semibold text-dark" id="shiftDetailRole">-</span>
                        </div>
                        <div class="list-group-item d-flex justify-content-between align-items-center px-0">
                            <span class="text-muted"><i class="bi bi-geo-alt me-2"></i>Phòng / Khu vực:</span>
                            <span class="fw-semibold text-dark" id="shiftDetailRoom">-</span>
                        </div>
                        <div class="list-group-item d-flex justify-content-between align-items-center px-0">
                            <span class="text-muted"><i class="bi bi-calendar-event me-2"></i>Ngày trực:</span>
                            <span class="fw-semibold text-dark" id="shiftDetailDate">-</span>
                        </div>
                        <div class="list-group-item d-flex justify-content-between align-items-center px-0">
                            <span class="text-muted"><i class="bi bi-clock me-2"></i>Khung giờ:</span>
                            <span class="fw-semibold text-dark" id="shiftDetailTime">-</span>
                        </div>
                        <div class="list-group-item d-flex justify-content-between align-items-center px-0">
                            <span class="text-muted"><i class="bi bi-check-circle me-2"></i>Trạng thái:</span>
                            <span class="badge bg-success" id="shiftDetailStatus">Đã xếp lịch</span>
                        </div>
                    </div>
                </div>
                <div class="modal-footer border-0 pt-0">
                    <button type="button" class="btn btn-outline-secondary px-3" data-bs-dismiss="modal" style="border-radius: 8px;">Đóng</button>
                    <button type="button" class="btn btn-primary px-4 fw-bold" id="shiftDetailEditBtn" style="border-radius: 8px; display: none;">
                        <i class="bi bi-pencil-square me-1"></i>Chỉnh sửa ca trực
                    </button>
                </div>
            </div>
        </div>
    </div>