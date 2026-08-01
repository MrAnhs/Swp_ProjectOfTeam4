<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<c:set var="currentPage" value="queue" />
<!DOCTYPE html>
<html lang="vi">
<head>
    <title>Hàng đợi khám - DiabetesCare</title>
    <%@ include file="/WEB-INF/views/components/shared/master-head.jspf" %>
    <link href="${pageContext.request.contextPath}/assets/css/pages/receptionist/receptionist.css?v=20260801" rel="stylesheet">
</head>
<body class="receptionist-page master-ui-body master-ui-dark">
<div class="receptionist-shell">
    <%@ include file="/WEB-INF/views/components/receptionist/sidebar.jspf" %>
    <main class="receptionist-main">
        <div class="page-kicker">Vận hành</div>
        <h1 class="page-title">Hàng đợi khám hôm nay</h1>
        <p class="page-subtitle">Danh sách bệnh nhân đang chờ, đã xác nhận hoặc đang khám trong ngày.</p>

        <section class="panel-card mt-4">
            <div class="row g-3">
                <div class="col-md-4">
                    <label class="form-label fw-semibold">Trạng thái</label>
                    <select id="queueStatusFilter" class="form-select">
                        <option value="">Tất cả</option>
                        <option value="Waiting">Đang chờ xác nhận</option>
                        <option value="Checked_In">Đã xác nhận</option>
                        <option value="In_Progress">Đang khám</option>
                    </select>
                </div>
                <div class="col-md-8 d-flex align-items-end justify-content-md-end">
                    <button id="reloadQueueBtn" class="btn btn-outline-primary" type="button">
                        <i class="bi bi-arrow-clockwise me-1"></i>Tải lại
                    </button>
                </div>
            </div>
            <div id="queueList" class="mt-4"></div>
        </section>
    </main>
</div>
<script>
    window.ReceptionistConfig = {
        contextPath: '${pageContext.request.contextPath}',
        apiBase: '${pageContext.request.contextPath}/receptionist/api'
    };
</script>
<script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/receptionist/receptionist-utils.js?v=20260709-fontfix2"></script>
<script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/receptionist/queue-management.js?v=20260723-v3"></script>
</body>
</html>
