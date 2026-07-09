<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Phòng xét nghiệm - DiabetesCare</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <style>
        body { background: #f5f7fb; color: #1f2937; }
        .lab-shell { min-height: 100vh; display: grid; grid-template-columns: 260px 1fr; }
        .lab-sidebar { background: #123a3f; color: #e6fffb; padding: 24px 18px; }
        .lab-brand { display: flex; align-items: center; gap: 10px; font-weight: 800; font-size: 1.05rem; margin-bottom: 28px; }
        .lab-nav a { display: flex; align-items: center; gap: 10px; color: #d1faf4; text-decoration: none; padding: 11px 12px; border-radius: 8px; margin-bottom: 8px; }
        .lab-nav a.active, .lab-nav a:hover { background: rgba(255,255,255,.12); color: #fff; }
        .lab-main { padding: 28px; }
        .stat-card { background: #fff; border: 1px solid #e5e7eb; border-radius: 8px; padding: 18px; height: 100%; }
        .stat-label { color: #6b7280; font-size: .85rem; font-weight: 700; text-transform: uppercase; }
        .stat-value { font-size: 2rem; font-weight: 800; margin-top: 4px; }
        .toolbar, .table-panel { background: #fff; border: 1px solid #e5e7eb; border-radius: 8px; }
        .status-badge { border-radius: 999px; padding: 6px 10px; font-weight: 700; font-size: .78rem; }
        .status-requested { background: #fff7ed; color: #9a3412; }
        .status-processing { background: #eff6ff; color: #1d4ed8; }
        .status-completed { background: #ecfdf5; color: #047857; }
        .metric-grid { display: grid; grid-template-columns: repeat(4, minmax(110px, 1fr)); gap: 10px; }
        @media (max-width: 900px) {
            .lab-shell { grid-template-columns: 1fr; }
            .lab-sidebar { position: static; }
            .metric-grid { grid-template-columns: repeat(2, minmax(110px, 1fr)); }
        }
    </style>
</head>
<body>
<div class="lab-shell">
    <aside class="lab-sidebar">
        <div class="lab-brand">
            <i class="bi bi-clipboard2-pulse-fill"></i>
            <span>Phòng xét nghiệm</span>
        </div>
        <nav class="lab-nav">
            <a class="active" href="${pageContext.request.contextPath}/doctor-lab/dashboard">
                <i class="bi bi-list-check"></i> Danh sách xét nghiệm
            </a>
            <a href="${pageContext.request.contextPath}/logout">
                <i class="bi bi-box-arrow-right"></i> Đăng xuất
            </a>
        </nav>
    </aside>

    <main class="lab-main">
        <div class="d-flex flex-column flex-lg-row justify-content-between align-items-lg-center gap-3 mb-4">
            <div>
                <h1 class="h3 fw-bold mb-1">Danh sách chỉ định xét nghiệm</h1>
                <p class="text-secondary mb-0">Theo dõi chỉ định đã thanh toán, nhận xử lý và nhập kết quả xét nghiệm.</p>
            </div>
            <form class="toolbar p-2 d-flex gap-2 align-items-center" method="get" action="${pageContext.request.contextPath}/doctor-lab/dashboard">
                <label class="text-secondary fw-semibold small px-2" for="status">Trạng thái</label>
                <select class="form-select" id="status" name="status" onchange="this.form.submit()">
                    <option value="All" ${selectedStatus == 'All' ? 'selected' : ''}>Tất cả</option>
                    <option value="Requested" ${selectedStatus == 'Requested' ? 'selected' : ''}>Chờ phòng xét nghiệm</option>
                    <option value="Processing" ${selectedStatus == 'Processing' ? 'selected' : ''}>Đang xử lý</option>
                    <option value="Completed" ${selectedStatus == 'Completed' ? 'selected' : ''}>Đã hoàn thành</option>
                </select>
            </form>
        </div>

        <c:if test="${not empty successMsg}">
            <div class="alert alert-success" role="alert">${successMsg}</div>
        </c:if>
        <c:if test="${not empty errorMsg}">
            <div class="alert alert-danger" role="alert">${errorMsg}</div>
        </c:if>

        <div class="row g-3 mb-4">
            <div class="col-md-4">
                <div class="stat-card">
                    <div class="stat-label">Chờ xử lý</div>
                    <div class="stat-value">${requestedCount}</div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="stat-card">
                    <div class="stat-label">Đang xử lý</div>
                    <div class="stat-value">${processingCount}</div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="stat-card">
                    <div class="stat-label">Đã hoàn thành</div>
                    <div class="stat-value">${completedCount}</div>
                </div>
            </div>
        </div>

        <div class="table-panel p-3">
            <div class="table-responsive">
                <table class="table align-middle mb-0">
                    <thead>
                        <tr>
                            <th>Mã</th>
                            <th>Bệnh nhân</th>
                            <th>Dịch vụ</th>
                            <th>Thanh toán</th>
                            <th>Trạng thái</th>
                            <th>Ghi chú</th>
                            <th class="text-end">Thao tác</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="lab" items="${requests}">
                            <tr>
                                <td class="fw-semibold">#${lab.laboratoryRequestId}</td>
                                <td>
                                    <div class="fw-semibold">${lab.patientName}</div>
                                    <div class="text-secondary small">BN #${lab.patientId}</div>
                                </td>
                                <td>${lab.testTypeDisplay}</td>
                                <td>${lab.paymentStatusDisplay}</td>
                                <td>
                                    <span class="status-badge ${lab.status == 'Completed' ? 'status-completed' : (lab.status == 'Processing' ? 'status-processing' : 'status-requested')}">
                                        ${lab.statusDisplay}
                                    </span>
                                </td>
                                <td class="text-secondary">${lab.requestNote}</td>
                                <td class="text-end">
                                    <c:choose>
                                        <c:when test="${lab.status == 'Requested'}">
                                            <form method="post" action="${pageContext.request.contextPath}/doctor-lab/dashboard" class="d-inline">
                                                <input type="hidden" name="action" value="start">
                                                <input type="hidden" name="laboratoryRequestId" value="${lab.laboratoryRequestId}">
                                                <input type="hidden" name="status" value="${selectedStatus}">
                                                <button class="btn btn-sm btn-primary" type="submit">
                                                    <i class="bi bi-play-fill"></i> Nhận xử lý
                                                </button>
                                            </form>
                                        </c:when>
                                        <c:when test="${lab.status == 'Processing'}">
                                            <button class="btn btn-sm btn-success" type="button" data-bs-toggle="collapse" data-bs-target="#result-${lab.laboratoryRequestId}">
                                                <i class="bi bi-check2-circle"></i> Nhập kết quả
                                            </button>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="text-secondary small">Đã hoàn tất</span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                            </tr>
                            <c:if test="${lab.status == 'Processing'}">
                                <tr class="collapse" id="result-${lab.laboratoryRequestId}">
                                    <td colspan="7">
                                        <form method="post" action="${pageContext.request.contextPath}/doctor-lab/dashboard" class="p-3 bg-light rounded-2">
                                            <input type="hidden" name="action" value="complete">
                                            <input type="hidden" name="laboratoryRequestId" value="${lab.laboratoryRequestId}">
                                            <input type="hidden" name="status" value="${selectedStatus}">
                                            <div class="metric-grid mb-3">
                                                <input class="form-control" type="number" step="0.01" name="urea" placeholder="Urea">
                                                <input class="form-control" type="number" step="0.01" name="cr" placeholder="Creatinine">
                                                <input class="form-control" type="number" step="0.01" name="hba1c" placeholder="HbA1c">
                                                <input class="form-control" type="number" step="0.01" name="chol" placeholder="Cholesterol">
                                                <input class="form-control" type="number" step="0.01" name="tg" placeholder="Triglyceride">
                                                <input class="form-control" type="number" step="0.01" name="hdl" placeholder="HDL">
                                                <input class="form-control" type="number" step="0.01" name="ldl" placeholder="LDL">
                                                <input class="form-control" type="number" step="0.01" name="vldl" placeholder="VLDL">
                                                <input class="form-control" type="number" step="0.01" name="weight" placeholder="Cân nặng">
                                                <input class="form-control" type="number" step="0.01" name="height" placeholder="Chiều cao">
                                                <input class="form-control" type="number" step="0.01" name="bmi" placeholder="BMI">
                                            </div>
                                            <textarea class="form-control mb-3" name="result" rows="3" placeholder="Nhận xét/kết luận xét nghiệm"></textarea>
                                            <div class="text-end">
                                                <button class="btn btn-success" type="submit">
                                                    <i class="bi bi-save2"></i> Lưu kết quả
                                                </button>
                                            </div>
                                        </form>
                                    </td>
                                </tr>
                            </c:if>
                        </c:forEach>
                        <c:if test="${empty requests}">
                            <tr>
                                <td colspan="7" class="text-center text-secondary py-5">Không có chỉ định xét nghiệm phù hợp.</td>
                            </tr>
                        </c:if>
                    </tbody>
                </table>
            </div>
        </div>
    </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
