<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Phòng Xét nghiệm - DiabetesCare</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/layouts/patient-shell.css">
    <style>
        body {
            font-family: 'Inter', sans-serif;
            background-color: #f4fbf9;
            color: #333;
        }
        /* Sidebar custom overrides */
        .sidebar-modern {
            background: #ffffff;
            border-right: 1px solid #e0f2f1;
            padding-top: 1rem;
            overflow-y: auto;
            scrollbar-width: thin;
            scrollbar-color: #b2dfdb transparent;
        }
        /* Custom scrollbar for sidebar */
        .sidebar-modern::-webkit-scrollbar {
            width: 4px;
        }
        .sidebar-modern::-webkit-scrollbar-track {
            background: transparent;
        }
        .sidebar-modern::-webkit-scrollbar-thumb {
            background: #b2dfdb;
            border-radius: 4px;
        }
        .sidebar-modern::-webkit-scrollbar-thumb:hover {
            background: #007f61;
        }
        .sidebar-modern .user-profile {
            display: flex;
            align-items: center;
            gap: 0.85rem;
            padding: 1rem 1.2rem;
            border-bottom: 1px solid #e5f5f2;
            background: linear-gradient(135deg, #ffffff 0%, #f4fbf9 100%);
            margin: 0.5rem 0.85rem 1.5rem 0.85rem;
            border-radius: 12px;
            box-shadow: 0 4px 15px rgba(0, 127, 97, 0.03);
            transition: transform 0.2s ease;
        }
        .sidebar-modern .user-profile:hover {
            transform: translateY(-2px);
        }
        .sidebar-modern .user-avatar {
            width: 44px;
            height: 44px;
            border-radius: 10px;
            font-weight: 700;
            font-size: 1.25rem;
            display: flex;
            align-items: center;
            justify-content: center;
            background-color: #007f61 !important;
            box-shadow: 0 4px 10px rgba(0, 127, 97, 0.2);
        }
        .sidebar-modern .user-info h6 {
            margin: 0;
            font-weight: 600;
            color: #2b3a37;
            font-size: 0.95rem;
        }
        .sidebar-modern .user-info small {
            display: inline-block;
            margin-top: 0.2rem;
            font-size: 0.7rem;
            padding: 0.15rem 0.5rem;
            border-radius: 6px;
            letter-spacing: 0.5px;
            font-weight: 700;
            box-shadow: 0 2px 5px rgba(0, 127, 97, 0.1);
        }
        .sidebar-modern .nav-item-dash {
            width: auto;
            text-align: left;
            border: none;
            background: transparent;
            font-family: inherit;
            font-size: 0.95rem;
            font-weight: 500;
            cursor: pointer;
            outline: none;
            display: flex;
            align-items: center;
            gap: 0.85rem;
            padding: 0.75rem 1.25rem;
            color: #51625e;
            text-decoration: none;
            transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
            border-left: 4px solid transparent;
            border-radius: 0 8px 8px 0;
            margin-right: 0.85rem;
            margin-bottom: 0.25rem;
        }
        .sidebar-modern .nav-item-dash i {
            font-size: 1.15rem;
            transition: transform 0.2s ease;
        }
        .sidebar-modern .nav-item-dash:hover i {
            transform: scale(1.1);
        }
        .sidebar-modern .nav-item-dash:hover,
        .sidebar-modern .nav-item-dash.active {
            background-color: #e6f6f3;
            color: #007f61;
            font-weight: 600;
            border-left-color: #007f61;
            padding-left: 1.5rem;
        }
        
        /* Nested sidebar menu styling */
        .sidebar-modern .sub-menu {
            display: none;
            flex-direction: column;
            background: #fafdfc;
            border-left: 2px solid #b2dfdb;
            margin-left: 2.3rem;
            margin-bottom: 0.5rem;
            border-radius: 0 8px 8px 0;
            padding-left: 0.25rem;
            transition: all 0.3s ease;
        }
        .sidebar-modern .sub-menu-level2 {
            display: none;
            flex-direction: column;
            background: #fafdfc;
            border-left: 1.5px dashed #b2dfdb;
            margin-left: 1.3rem;
            margin-bottom: 0.4rem;
            border-radius: 0 8px 8px 0;
            padding-left: 0.25rem;
            transition: all 0.3s ease;
        }
        @keyframes slideDown {
            from {
                opacity: 0;
                transform: translateY(-8px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        .sidebar-modern .sub-menu.show,
        .sidebar-modern .sub-menu-level2.show {
            display: flex;
            animation: slideDown 0.25s cubic-bezier(0.4, 0, 0.2, 1) forwards;
        }
        .sidebar-modern .nav-item-sub {
            padding: 0.55rem 1rem;
            color: #617370;
            font-size: 0.85rem;
            font-weight: 500;
            text-decoration: none;
            transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
            display: flex;
            align-items: center;
            gap: 0.6rem;
            border-left: 3px solid transparent;
            border-radius: 0 6px 6px 0;
            margin-right: 0.5rem;
        }
        .sidebar-modern .nav-item-sub:hover {
            color: #007f61;
            background-color: #f0faf8;
            border-left-color: #80cbc4;
            padding-left: 1.25rem;
        }
        .sidebar-modern .nav-item-sub.active {
            color: #007f61;
            font-weight: 600;
            background-color: #e6f6f3;
            border-left-color: #007f61;
            padding-left: 1.25rem;
        }
        .sidebar-modern .sub-menu-level2 .nav-item-sub {
            font-size: 0.82rem;
            padding: 0.45rem 0.8rem;
        }
        .sidebar-modern .btn-logout {
            color: #d9534f;
            border-left: 4px solid transparent;
            border-radius: 0 8px 8px 0;
            margin-right: 0.85rem;
        }
        .sidebar-modern .btn-logout:hover {
            background-color: #fdf2f2;
            color: #d9534f;
            border-left-color: #d9534f;
            padding-left: 1.5rem;
        }
        .sidebar-modern .badge.bg-danger {
            background: linear-gradient(135deg, #ff5252 0%, #ff1744 100%) !important;
            box-shadow: 0 2px 8px rgba(255, 23, 68, 0.4);
            animation: pulse-badge 2s infinite;
        }
        @keyframes pulse-badge {
            0% {
                transform: scale(1);
                box-shadow: 0 2px 8px rgba(255, 23, 68, 0.4);
            }
            50% {
                transform: scale(1.08);
                box-shadow: 0 2px 12px rgba(255, 23, 68, 0.6);
            }
            100% {
                transform: scale(1);
                box-shadow: 0 2px 8px rgba(255, 23, 68, 0.4);
            }
        }
        .main-content-dash {
            margin-left: 260px;
            padding: 2rem;
            background-color: #f4fbf9;
            min-height: 100vh;
        }
        @media (max-width: 900px) {
            .main-content-dash {
                margin-left: 76px;
                padding: 1rem;
            }
        }
        .btn-vinmec {
            background-color: #007f61;
            border-color: #007f61;
            color: white;
            transition: all 0.3s ease;
            font-weight: 600;
        }
        .btn-vinmec:hover {
            background-color: #005f48;
            border-color: #005f48;
            color: white;
            transform: translateY(-1px);
        }
        .btn-outline-vinmec {
            background-color: transparent;
            border: 1px solid #007f61;
            color: #007f61;
            transition: all 0.3s ease;
            font-weight: 600;
        }
        .btn-outline-vinmec:hover {
            background-color: #e6f6f3;
            color: #005f48;
            border-color: #005f48;
            transform: translateY(-1px);
        }
        .card-custom {
            border: none;
            border-radius: 12px;
            box-shadow: 0 4px 12px rgba(0, 127, 97, 0.05);
            background: #ffffff;
            margin-bottom: 24px;
            overflow: hidden;
        }
        .card-header-custom {
            background-color: #e6f6f3;
            border-bottom: 1px solid #ccece6;
            color: #007f61;
            font-weight: 600;
        }
        .badge-status-approved {
            background-color: #e8f7f4;
            color: #007f61;
        }
        .badge-status-pending {
            background-color: #fff8e1;
            color: #ffb300;
        }
        .table-custom th {
            font-weight: 600;
            color: #555;
            background-color: #f9fbfb;
            border-bottom: 2px solid #e0f2f1;
            font-size: 0.85rem;
        }
        .table-custom td {
            vertical-align: middle;
            font-size: 0.9rem;
        }
        .nav-tabs-custom .nav-link {
            color: #555;
            font-weight: 500;
            border: none;
            border-bottom: 3px solid transparent;
            padding: 10px 16px;
            transition: all 0.2s ease;
        }
        .nav-tabs-custom .nav-link.active {
            color: #007f61;
            background: transparent;
            border-bottom: 3px solid #007f61;
            font-weight: 600;
        }
        /* Full-screen loading overlay to block interactions */
        .loading-overlay {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100vw;
            height: 100vh;
            background-color: rgba(255, 255, 255, 0.8);
            z-index: 99999;
            align-items: center;
            justify-content: center;
            flex-direction: column;
            gap: 1rem;
        }
        .loading-overlay.show {
            display: flex;
        }
        .spinner-vinmec {
            width: 3rem;
            height: 3rem;
            border: 4px solid #e6f6f3;
            border-top: 4px solid #007f61;
            border-radius: 50%;
            animation: spin 1s linear infinite;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        /* Overview Dashboard styling */
        .card-summary {
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            border-radius: 12px;
            overflow: hidden;
            background: #ffffff;
            cursor: default;
        }
        .card-summary:hover {
            transform: translateY(-4px);
            box-shadow: 0 8px 24px rgba(0, 127, 97, 0.08) !important;
        }
        .icon-box-summary {
            width: 48px;
            height: 48px;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 50%;
        }
        .pulsating-icon {
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0% {
                transform: scale(1);
                opacity: 1;
            }
            50% {
                transform: scale(1.15);
                opacity: 0.8;
            }
            100% {
                transform: scale(1);
                opacity: 1;
            }
        }
        .hba1c-donut-wrapper {
            width: 120px;
            height: 120px;
        }
        .hba1c-donut-wrapper svg {
            width: 100%;
            height: 100%;
        }
        .donut-text {
            width: 100%;
            line-height: 1.1;
        }
        .timeline-card-hover:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0,0,0,0.05);
            background-color: #e6f6f3 !important;
        }
        /* FAP Schedule Custom Styling */
        .fap-card-slot {
            padding: 6px 8px;
            border-radius: 8px;
            background: #ffffff;
            border: 1px solid #e9ecef;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.02);
            line-height: 1.3;
            text-align: center;
            transition: all 0.2s ease;
        }
        .fap-card-slot:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 16px rgba(0, 0, 0, 0.08);
        }
        .slot-blood_sugar { 
            border-left: 4px solid #dc3545 !important; 
            background-color: #fef2f2 !important;
            color: #991b1b !important;
        }
        .slot-urine_test  { 
            border-left: 4px solid #0d6efd !important; 
            background-color: #eff6ff !important;
            color: #1e40af !important;
        }
        .slot-liver_test  { border-left: 4px solid #198754 !important; }
        .slot-kidney_test { border-left: 4px solid #fd7e14 !important; }
        .slot-lipids_test { border-left: 4px solid #0dcaf0 !important; }
        .slot-lab_test    { border-left: 4px solid #6c757d !important; }
        .fap-badge-mat {
            background-color: #fff3cd !important;
            color: #856404 !important;
            border: 1px solid #ffeeba;
            font-size: 0.65rem;
            font-weight: 500;
        }
        .fap-badge-edunext {
            background-color: #cce5ff !important;
            color: #004085 !important;
            border: 1px solid #b8daff;
            font-size: 0.65rem;
            font-weight: 500;
        }
        .fap-badge-meet {
            background-color: #e2e3e5 !important;
            color: #383d41 !important;
            border: 1px solid #d6d8db;
            font-size: 0.65rem;
            font-weight: 500;
        }
        .fap-status-dot {
            font-size: 0.75rem;
            margin-right: 4px;
        }
    </style>
</head>
<body>

    <!-- Sidebar Modern Layout -->
    <aside class="sidebar-modern">
        <div class="sidebar-header">
            <span class="brand-dashboard">
                <div class="brand-icon-dash bg-success">
                    <i class="bi bi-activity"></i>
                </div>
                <span class="brand-text text-success">DiabetesCare</span>
            </span>
        </div>

        <div class="user-profile">
            <div class="user-avatar bg-success text-white">${sessionScope.currentUser.fullName.charAt(0)}</div>
            <div class="user-info">
                <h6 class="text-truncate" style="max-width: 140px;" title="${sessionScope.currentUser.fullName}">${sessionScope.currentUser.fullName}</h6>
                <small class="badge bg-success text-white font-monospace text-wrap">LAB SYSTEM</small>
            </div>
        </div>

        <!-- Sidebar Navigation (Bootstrap Pills/Tabs) -->
        <nav class="sidebar-nav nav flex-column" id="v-pills-tab" role="tablist" aria-orientation="vertical">
            <a href="#pill-overview" class="nav-link nav-item-dash active" id="pill-overview-tab" data-bs-toggle="pill" role="tab" aria-controls="pill-overview" aria-selected="true">
                <i class="bi bi-grid-1x2-fill text-success"></i>
                <span class="nav-text">Tổng quan dashboard</span>
            </a>
            <a href="#pill-patients" class="nav-link nav-item-dash" id="pill-patients-tab" data-bs-toggle="pill" role="tab" aria-controls="pill-patients" aria-selected="false">
                <i class="bi bi-people-fill text-success"></i>
                <span class="nav-text">Danh sách bệnh nhân</span>
            </a>
            <div class="nav-item-group-rooms">
                <a href="#pill-rooms" class="nav-link nav-item-dash" id="pill-rooms-tab" data-bs-toggle="pill" role="tab" aria-controls="pill-rooms" aria-selected="false" onclick="onParentRoomClick()">
                    <i class="bi bi-door-closed text-success"></i>
                    <span class="nav-text">Phòng xét nghiệm</span>
                    <c:if test="${not empty waitingPatients}">
                        <span class="badge bg-danger ms-auto rounded-pill">${waitingPatients.size()}</span>
                    </c:if>
                </a>
                <div class="sub-menu" id="rooms-sub-menu">
                    <a href="javascript:void(0)" class="nav-item-sub d-flex align-items-center justify-content-between" id="sub-room-mau" onclick="toggleBloodSubMenu()">
                        <div class="d-flex align-items-center gap-2">
                            <i class="bi bi-droplet-fill text-danger"></i>
                            <span>Xét nghiệm máu</span>
                        </div>
                        <i class="bi bi-chevron-down small" id="blood-chevron" style="transition: transform 0.2s ease;"></i>
                    </a>
                    <div class="sub-menu-level2 ps-3" id="blood-sub-menu" style="display: none; flex-direction: column;">
                        <a href="javascript:void(0)" class="nav-item-sub py-1 my-1" id="sub-room-duonghuyet" onclick="selectSidebarRoom('phòng xét nghiệm máu - đường huyết')">
                            <i class="bi bi-activity text-danger"></i>
                            <span>Đường huyết</span>
                        </a>
                        <a href="javascript:void(0)" class="nav-item-sub py-1 my-1" id="sub-room-gan" onclick="selectSidebarRoom('phòng xét nghiệm máu - chức năng gan')">
                            <i class="bi bi-heart-pulse-fill text-success"></i>
                            <span>Chức năng gan</span>
                        </a>
                        <a href="javascript:void(0)" class="nav-item-sub py-1 my-1" id="sub-room-than" onclick="selectSidebarRoom('phòng xét nghiệm máu - chức năng thận')">
                            <i class="bi bi-prescription text-warning"></i>
                            <span>Chức năng thận</span>
                        </a>
                        <a href="javascript:void(0)" class="nav-item-sub py-1 my-1" id="sub-room-momau" onclick="selectSidebarRoom('phòng xét nghiệm máu - mỡ máu')">
                            <i class="bi bi-droplet-half text-info"></i>
                            <span>Mỡ máu</span>
                        </a>
                    </div>

                    <a href="javascript:void(0)" class="nav-item-sub" id="sub-room-nuoctieu" onclick="selectSidebarRoom('phòng xét nghiệm nước tiểu')">
                        <i class="bi bi-droplet text-info"></i>
                        <span>Xét nghiệm nước tiểu</span>
                    </a>
                </div>
            </div>
            

            <a href="#pill-history" class="nav-link nav-item-dash" id="pill-history-tab" data-bs-toggle="pill" role="tab" aria-controls="pill-history" aria-selected="false">
                <i class="bi bi-clock-history text-success"></i>
                <span class="nav-text">Lịch sử xét nghiệm</span>
            </a>
            <a href="#pill-schedule" class="nav-link nav-item-dash" id="pill-schedule-tab" data-bs-toggle="pill" role="tab" aria-controls="pill-schedule" aria-selected="false">
                <i class="bi bi-calendar3 text-success"></i>
                <span class="nav-text">Lịch làm việc</span>
            </a>
        </nav>

        <div class="sidebar-footer">
            <form action="${pageContext.request.contextPath}/logout" method="get" class="m-0">
                <button type="submit" class="nav-item-dash btn-logout border-0 w-100 text-start bg-transparent">
                    <i class="bi bi-box-arrow-right"></i>
                    <span class="nav-text">Đăng xuất</span>
                </button>
            </form>
        </div>
    </aside>

    <!-- Main Content Shell -->
    <main class="main-content-dash">
        <!-- Display alert messages -->
        <c:if test="${not empty sessionScope.successMsg}">
            <div class="alert alert-success alert-dismissible fade show border-0 shadow-sm mb-4" role="alert">
                <i class="bi bi-check-circle-fill me-2"></i> ${sessionScope.successMsg}
                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
            </div>
            <% session.removeAttribute("successMsg"); %>
        </c:if>
        <c:if test="${not empty sessionScope.errorMsg}">
            <div class="alert alert-danger alert-dismissible fade show border-0 shadow-sm mb-4" role="alert">
                <i class="bi bi-exclamation-triangle-fill me-2"></i> ${sessionScope.errorMsg}
                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
            </div>
            <% session.removeAttribute("errorMsg"); %>
        </c:if>

        <div class="tab-content" id="v-pills-tabContent">

            <!-- Module 1: Tổng quan dashboard -->
            <div class="tab-pane fade show active" id="pill-overview" role="tabpanel" aria-labelledby="pill-overview-tab">
                <!-- Overview / Summary Dashboard Content -->
                <div class="dashboard-header-banner mb-4">
                    <div class="banner-overlay p-4 rounded shadow-sm text-white" style="background: linear-gradient(135deg, #007f61 0%, #005f48 100%);">
                        <h4 class="fw-bold mb-1"><i class="bi bi-grid-1x2-fill me-2"></i> Báo cáo Tổng quan &amp; Thống kê Lâm sàng</h4>
                        <p class="mb-0 text-white-50 small">Tổng hợp chỉ số xét nghiệm, phân bố phòng chức năng, và phân tích sức khỏe đường huyết thời gian thực.</p>
                    </div>
                </div>

                <!-- 4 Top Cards -->
                <div class="row g-3 mb-4">
                    <div class="col-md-3">
                        <div class="card card-summary shadow-sm border-0 h-100 p-3" style="border-left: 4px solid #198754 !important;">
                            <div class="d-flex align-items-center justify-content-between">
                                <div>
                                    <h6 class="text-secondary small text-uppercase fw-semibold mb-1">Tổng bệnh nhân</h6>
                                    <h3 class="fw-bold text-success mb-0">${totalPatients}</h3>
                                </div>
                                <div class="icon-box-summary bg-success bg-opacity-10 text-success rounded-circle p-3">
                                    <i class="bi bi-people-fill fs-4"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="card card-summary shadow-sm border-0 h-100 p-3" style="border-left: 4px solid #ffc107 !important;">
                            <div class="d-flex align-items-center justify-content-between">
                                <div>
                                    <h6 class="text-secondary small text-uppercase fw-semibold mb-1">Chờ xét nghiệm</h6>
                                    <h3 class="fw-bold text-warning mb-0">${waitingCount}</h3>
                                </div>
                                <div class="icon-box-summary bg-warning bg-opacity-10 text-warning rounded-circle p-3 position-relative">
                                    <i class="bi bi-hourglass-split fs-4 pulsating-icon"></i>
                                    <c:if test="${waitingCount > 0}">
                                        <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" style="font-size: 0.65rem;">!</span>
                                    </c:if>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="card card-summary shadow-sm border-0 h-100 p-3" style="border-left: 4px solid #0dcaf0 !important;">
                            <div class="d-flex align-items-center justify-content-between">
                                <div>
                                    <h6 class="text-secondary small text-uppercase fw-semibold mb-1">Đã xét nghiệm</h6>
                                    <h3 class="fw-bold text-info mb-0">${completedCount}</h3>
                                </div>
                                <div class="icon-box-summary bg-info bg-opacity-10 text-info rounded-circle p-3">
                                    <i class="bi bi-check-circle-fill fs-4"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="card card-summary shadow-sm border-0 h-100 p-3" style="border-left: 4px solid #0d6efd !important;">
                            <div class="d-flex align-items-center justify-content-between">
                                <div>
                                    <h6 class="text-secondary small text-uppercase fw-semibold mb-1">Tổng lượt đo</h6>
                                    <h3 class="fw-bold text-primary mb-0">${totalRecords}</h3>
                                </div>
                                <div class="icon-box-summary bg-primary bg-opacity-10 text-primary rounded-circle p-3">
                                    <i class="bi bi-file-earmark-medical-fill fs-4"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- 2 Columns of Charts / Details -->
                <div class="row g-4 mb-4">
                    <!-- Left: Rooms Distribution -->
                    <div class="col-lg-6">
                        <div class="card card-custom h-100">
                            <div class="card-header card-header-custom py-3">
                                <span><i class="bi bi-door-closed-fill me-2 text-success"></i> Phân bố bệnh nhân theo Phòng xét nghiệm</span>
                            </div>
                            <div class="card-body p-4">
                                <div class="room-stat-item mb-3">
                                    <div class="d-flex justify-content-between align-items-center mb-1">
                                        <span class="fw-semibold text-secondary small"><i class="bi bi-droplet-fill text-danger me-1"></i>Xét nghiệm máu</span>
                                        <span class="badge bg-danger">${bloodTestCount} BN</span>
                                    </div>
                                    <div class="progress" style="height: 10px;">
                                        <c:set var="bloodPct" value="${totalPatients > 0 ? (bloodTestCount * 100.0 / totalPatients) : 0}" />
                                        <div class="progress-bar bg-danger" role="progressbar" style="width: ${bloodPct}%;" aria-valuenow="${bloodPct}" aria-valuemin="0" aria-valuemax="100"></div>
                                    </div>
                                </div>

                                <div class="room-stat-item mb-3">
                                    <div class="d-flex justify-content-between align-items-center mb-1">
                                        <span class="fw-semibold text-secondary small"><i class="bi bi-prescription text-warning me-1"></i>Xét nghiệm thận</span>
                                        <span class="badge bg-warning text-dark">${kidneyTestCount} BN</span>
                                    </div>
                                    <div class="progress" style="height: 10px;">
                                        <c:set var="kidneyPct" value="${totalPatients > 0 ? (kidneyTestCount * 100.0 / totalPatients) : 0}" />
                                        <div class="progress-bar bg-warning" role="progressbar" style="width: ${kidneyPct}%;" aria-valuenow="${kidneyPct}" aria-valuemin="0" aria-valuemax="100"></div>
                                    </div>
                                </div>

                                <div class="room-stat-item mb-3">
                                    <div class="d-flex justify-content-between align-items-center mb-1">
                                        <span class="fw-semibold text-secondary small"><i class="bi bi-heart-pulse-fill text-success me-1"></i>Xét nghiệm gan</span>
                                        <span class="badge bg-success">${liverTestCount} BN</span>
                                    </div>
                                    <div class="progress" style="height: 10px;">
                                        <c:set var="liverPct" value="${totalPatients > 0 ? (liverTestCount * 100.0 / totalPatients) : 0}" />
                                        <div class="progress-bar bg-success" role="progressbar" style="width: ${liverPct}%;" aria-valuenow="${liverPct}" aria-valuemin="0" aria-valuemax="100"></div>
                                    </div>
                                </div>

                                <div class="room-stat-item">
                                    <div class="d-flex justify-content-between align-items-center mb-1">
                                        <span class="fw-semibold text-secondary small"><i class="bi bi-droplet text-info me-1"></i>Xét nghiệm nước tiểu</span>
                                        <span class="badge bg-info text-dark">${urineTestCount} BN</span>
                                    </div>
                                    <div class="progress" style="height: 10px;">
                                        <c:set var="urinePct" value="${totalPatients > 0 ? (urineTestCount * 100.0 / totalPatients) : 0}" />
                                        <div class="progress-bar bg-info" role="progressbar" style="width: ${urinePct}%;" aria-valuenow="${urinePct}" aria-valuemin="0" aria-valuemax="100"></div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Right: Health Risks Analysis -->
                    <div class="col-lg-6">
                        <div class="card card-custom h-100">
                            <div class="card-header card-header-custom py-3">
                                <span><i class="bi bi-shield-fill-exclamation me-2 text-success"></i> Thống kê Sức khỏe Đường huyết (HbA1c)</span>
                            </div>
                            <div class="card-body p-4 d-flex flex-column justify-content-between">
                                <div class="row align-items-center g-3">
                                    <div class="col-sm-6 text-center">
                                        <div class="hba1c-donut-wrapper d-inline-block position-relative">
                                            <svg width="120" height="120" viewBox="0 0 100 100">
                                                <circle cx="50" cy="50" r="40" fill="transparent" stroke="#e9ecef" stroke-width="12"></circle>
                                                <circle cx="50" cy="50" r="40" fill="transparent" stroke="#dc3545" stroke-width="12"
                                                        stroke-dasharray="251.2" stroke-dashoffset="${dashOffset}"
                                                        transform="rotate(-90 50 50)"></circle>
                                            </svg>
                                            <div class="donut-text position-absolute top-50 start-50 translate-middle text-center">
                                                <span class="fs-4 fw-bold text-danger">${highPct}%</span><br>
                                                <span class="text-secondary" style="font-size: 0.65rem;">Nguy cơ</span>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-sm-6">
                                        <div class="d-flex align-items-center mb-3">
                                            <span class="indicator-color bg-danger rounded-circle me-2" style="width: 12px; height: 12px; display: inline-block;"></span>
                                            <div>
                                                <small class="text-secondary d-block lh-1">Nguy cơ cao (HbA1c &ge; 6.5%)</small>
                                                <strong class="text-dark">${highHbA1cCount} lượt đo</strong>
                                            </div>
                                        </div>
                                        <div class="d-flex align-items-center">
                                            <span class="indicator-color bg-secondary rounded-circle me-2" style="width: 12px; height: 12px; display: inline-block; background-color: #e9ecef !important; border: 2px solid #ccc;"></span>
                                            <div>
                                                <small class="text-secondary d-block lh-1">Bình thường/tiền ĐT (&lt; 6.5%)</small>
                                                <strong class="text-dark">${normalHbA1cCount} lượt đo</strong>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div class="alert alert-warning border-0 shadow-none mt-3 p-2 small d-flex align-items-start gap-2 bg-warning bg-opacity-10 text-dark" style="margin: 0 !important;">
                                    <i class="bi bi-info-circle-fill text-warning mt-1"></i>
                                    <span>Tỉ lệ nguy cơ cao phản ánh phần trăm lượt đo chỉ số HbA1c nằm trong mức cảnh báo tiểu đường nguy hiểm.</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Bottom: Recent Activity Timeline -->
                <div class="card card-custom mb-4">
                    <div class="card-header card-header-custom py-3">
                        <span><i class="bi bi-activity me-2 text-success"></i> Nhật ký hoạt động xét nghiệm gần đây</span>
                    </div>
                    <div class="card-body p-4">
                        <div class="timeline-activity">
                            <c:choose>
                                <c:when test="${empty records}">
                                    <div class="text-center py-3 text-secondary small">Không có hoạt động nào gần đây.</div>
                                </c:when>
                                <c:otherwise>
                                    <div class="row">
                                        <c:forEach var="r" items="${records}" varStatus="status">
                                            <c:if test="${status.index < 4}">
                                                <c:choose>
                                                    <c:when test="${fn:contains(r.otherInfo, 'gan')}">
                                                        <c:set var="cardTestName" value="Xét nghiệm chức năng gan" />
                                                        <c:set var="cardBadgeClass" value="bg-success" />
                                                        <c:set var="cardIcon" value="bi-heart-pulse-fill" />
                                                    </c:when>
                                                    <c:when test="${fn:contains(r.otherInfo, 'thận')}">
                                                        <c:set var="cardTestName" value="Xét nghiệm chức năng thận" />
                                                        <c:set var="cardBadgeClass" value="bg-warning text-dark" />
                                                        <c:set var="cardIcon" value="bi-prescription" />
                                                    </c:when>
                                                    <c:when test="${fn:contains(r.otherInfo, 'mỡ máu')}">
                                                        <c:set var="cardTestName" value="Xét nghiệm mỡ máu" />
                                                        <c:set var="cardBadgeClass" value="bg-primary" />
                                                        <c:set var="cardIcon" value="bi-droplet-half" />
                                                    </c:when>
                                                    <c:when test="${fn:contains(r.otherInfo, 'nước tiểu')}">
                                                        <c:set var="cardTestName" value="Xét nghiệm nước tiểu" />
                                                        <c:set var="cardBadgeClass" value="bg-info text-dark" />
                                                        <c:set var="cardIcon" value="bi-droplet" />
                                                    </c:when>
                                                    <c:when test="${fn:contains(r.otherInfo, 'đường huyết') or fn:contains(r.otherInfo, 'xét nghiệm máu')}">
                                                        <c:set var="cardTestName" value="Xét nghiệm đường huyết" />
                                                        <c:set var="cardBadgeClass" value="bg-danger" />
                                                        <c:set var="cardIcon" value="bi-activity" />
                                                    </c:when>
                                                    <c:otherwise>
                                                        <c:choose>
                                                            <c:when test="${isLiverTest}">
                                                                <c:set var="cardTestName" value="Xét nghiệm chức năng gan" />
                                                                <c:set var="cardBadgeClass" value="bg-success" />
                                                                <c:set var="cardIcon" value="bi-heart-pulse-fill" />
                                                            </c:when>
                                                            <c:when test="${isKidneyTest}">
                                                                <c:set var="cardTestName" value="Xét nghiệm chức năng thận" />
                                                                <c:set var="cardBadgeClass" value="bg-warning text-dark" />
                                                                <c:set var="cardIcon" value="bi-prescription" />
                                                            </c:when>
                                                            <c:when test="${isLipidsTest}">
                                                                <c:set var="cardTestName" value="Xét nghiệm mỡ máu" />
                                                                <c:set var="cardBadgeClass" value="bg-primary" />
                                                                <c:set var="cardIcon" value="bi-droplet-half" />
                                                            </c:when>
                                                            <c:when test="${not empty r.hba1c and r.hba1c ne '0' and r.hba1c ne '0.0'}">
                                                                <c:set var="cardTestName" value="Xét nghiệm đường huyết" />
                                                                <c:set var="cardBadgeClass" value="bg-danger" />
                                                                <c:set var="cardIcon" value="bi-activity" />
                                                            </c:when>
                                                            <c:otherwise>
                                                                <c:set var="cardTestName" value="Xét nghiệm nước tiểu" />
                                                                <c:set var="cardBadgeClass" value="bg-info text-dark" />
                                                                <c:set var="cardIcon" value="bi-droplet" />
                                                            </c:otherwise>
                                                        </c:choose>
                                                    </c:otherwise>
                                                </c:choose>
                                                <div class="col-md-6 mb-3">
                                                    <div class="p-3 rounded border bg-light bg-opacity-50 d-flex justify-content-between align-items-center timeline-card-hover" style="transition: transform 0.2s, box-shadow 0.2s;">
                                                        <div class="d-flex align-items-start gap-3">
                                                            <div class="activity-icon bg-success bg-opacity-10 text-success rounded p-2">
                                                                <i class="bi bi-file-earmark-check-fill"></i>
                                                            </div>
                                                            <div>
                                                                <h6 class="fw-bold text-dark mb-1"><c:out value="${r.patientName}" /></h6>
                                                                <small class="text-secondary d-block mb-1" style="font-size: 0.75rem;"><i class="bi bi-clock me-1"></i><c:out value="${r.createdAt}" /></small>
                                                                <span class="badge ${cardBadgeClass} font-monospace" style="font-size: 0.7rem; font-family: inherit;"><i class="bi ${cardIcon} me-1"></i>${cardTestName}</span>
                                                                <c:if test="${cardTestName eq 'Xét nghiệm đường huyết' and not empty r.hba1c and r.hba1c ne '0'}">
                                                                    <span class="badge bg-secondary font-monospace ms-1" style="font-size: 0.7rem;">HbA1c: <c:out value="${r.hba1c}" />%</span>
                                                                </c:if>
                                                            </div>
                                                        </div>
                                                        <button type="button" class="btn btn-outline-success btn-xs px-2 py-1" style="font-size: 0.7rem;" data-bs-toggle="modal" data-bs-target="#recordModal${r.recordId}">
                                                            Chi tiết
                                                        </button>
                                                    </div>
                                                </div>
                                            </c:if>
                                        </c:forEach>
                                    </div>
                                </c:otherwise>
                            </c:choose>
                        </div>
                    </div>
                </div>
            </div>



            <!-- Module 2: Lịch sử xét nghiệm -->
            <div class="tab-pane fade" id="pill-history" role="tabpanel" aria-labelledby="pill-history-tab">
                <div class="card card-custom">
                    <div class="card-header card-header-custom py-2 d-flex justify-content-between align-items-center">
                        <span><i class="bi bi-clock-history me-2"></i> Lịch sử kết quả xét nghiệm gần đây</span>
                        <span class="badge bg-success">approved</span>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive" style="max-height: 600px; overflow-y: auto;">
                            <table class="table table-hover table-custom m-0">
                                <thead>
                                    <tr>
                                        <th>Bệnh nhân</th>
                                        <th>Thời gian</th>
                                        <th>Dịch vụ xét nghiệm</th>
                                        <th>Chỉ định tiếp</th>
                                        <th>Chi tiết XN</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <c:choose>
                                        <c:when test="${empty records}">
                                            <tr>
                                                <td colspan="5" class="text-center py-4 text-secondary">Chưa có kết quả xét nghiệm nào.</td>
                                            </tr>
                                        </c:when>
                                        <c:otherwise>
                                            <c:forEach var="r" items="${records}">
                                                <tr>
                                                    <c:choose>
                                                         <c:when test="${fn:contains(r.otherInfo, 'gan')}">
                                                             <c:set var="isLiverTest" value="true" />
                                                             <c:set var="isLipidsTest" value="false" />
                                                             <c:set var="isKidneyTest" value="false" />
                                                         </c:when>
                                                         <c:when test="${fn:contains(r.otherInfo, 'thận')}">
                                                             <c:set var="isLiverTest" value="false" />
                                                             <c:set var="isLipidsTest" value="false" />
                                                             <c:set var="isKidneyTest" value="true" />
                                                         </c:when>
                                                         <c:when test="${fn:contains(r.otherInfo, 'mỡ máu')}">
                                                             <c:set var="isLiverTest" value="false" />
                                                             <c:set var="isLipidsTest" value="true" />
                                                             <c:set var="isKidneyTest" value="false" />
                                                         </c:when>
                                                         <c:otherwise>
                                                             <c:set var="isLiverTest" value="${(empty r.hba1c or r.hba1c eq '0' or r.hba1c eq '0.0') and (empty r.cr or r.cr eq '0' or r.cr eq '0.0') and (empty r.ldl or r.ldl eq '0' or r.ldl eq '0.0') and not empty r.chol and r.chol ne '0'}" />
                                                             <c:set var="isLipidsTest" value="${(empty r.hba1c or r.hba1c eq '0' or r.hba1c eq '0.0') and (empty r.cr or r.cr eq '0' or r.cr eq '0.0') and not empty r.ldl and r.ldl ne '0' and r.ldl ne '0.0'}" />
                                                             <c:set var="isKidneyTest" value="${(empty r.hba1c or r.hba1c eq '0' or r.hba1c eq '0.0') and (empty r.chol or r.chol eq '0' or r.chol eq '0.0') and not empty r.cr and r.cr ne '0' and r.cr ne '0.0'}" />
                                                         </c:otherwise>
                                                    </c:choose>
                                                    <td class="fw-semibold"><c:out value="${r.patientName}" /></td>
                                                    <td class="small text-secondary"><c:out value="${r.createdAt}" /></td>
                                                    <td>
                                                        <c:choose>
                                                            <c:when test="${fn:contains(r.otherInfo, 'gan')}">
                                                                <span class="badge bg-success"><i class="bi bi-heart-pulse-fill me-1"></i>Xét nghiệm chức năng gan</span>
                                                            </c:when>
                                                            <c:when test="${fn:contains(r.otherInfo, 'thận')}">
                                                                <span class="badge bg-warning text-dark"><i class="bi bi-prescription me-1"></i>Xét nghiệm chức năng thận</span>
                                                            </c:when>
                                                            <c:when test="${fn:contains(r.otherInfo, 'mỡ máu')}">
                                                                <span class="badge bg-primary"><i class="bi bi-droplet-half me-1"></i>Xét nghiệm mỡ máu</span>
                                                            </c:when>
                                                            <c:when test="${fn:contains(r.otherInfo, 'nước tiểu')}">
                                                                <span class="badge bg-info text-dark"><i class="bi bi-droplet me-1"></i>Xét nghiệm nước tiểu</span>
                                                            </c:when>
                                                            <c:when test="${fn:contains(r.otherInfo, 'đường huyết') or fn:contains(r.otherInfo, 'xét nghiệm máu')}">
                                                                <span class="badge bg-danger"><i class="bi bi-activity me-1"></i>Xét nghiệm đường huyết</span>
                                                            </c:when>
                                                            <c:otherwise>
                                                                <c:choose>
                                                                    <c:when test="${isLiverTest}">
                                                                        <span class="badge bg-success"><i class="bi bi-heart-pulse-fill me-1"></i>Xét nghiệm chức năng gan</span>
                                                                    </c:when>
                                                                    <c:when test="${isKidneyTest}">
                                                                        <span class="badge bg-warning text-dark"><i class="bi bi-prescription me-1"></i>Xét nghiệm chức năng thận</span>
                                                                    </c:when>
                                                                    <c:when test="${isLipidsTest}">
                                                                        <span class="badge bg-primary"><i class="bi bi-droplet-half me-1"></i>Xét nghiệm mỡ máu</span>
                                                                    </c:when>
                                                                    <c:when test="${not empty r.hba1c and r.hba1c ne '0' and r.hba1c ne '0.0'}">
                                                                        <span class="badge bg-danger"><i class="bi bi-activity me-1"></i>Xét nghiệm đường huyết</span>
                                                                    </c:when>
                                                                    <c:otherwise>
                                                                        <span class="badge bg-info text-dark"><i class="bi bi-droplet me-1"></i>Xét nghiệm nước tiểu</span>
                                                                    </c:otherwise>
                                                                </c:choose>
                                                            </c:otherwise>
                                                        </c:choose>
                                                    </td>
                                                     <td>
                                                         <div class="d-inline-block">
                                                             <form action="${pageContext.request.contextPath}/doctor-lab/dashboard" method="POST" class="d-flex align-items-center gap-1 m-0">
                                                                 <input type="hidden" name="action" value="assign">
                                                                 <input type="hidden" name="patientId" value="${r.patientId}">
                                                                 <select name="newRoom" class="form-select form-select-xs py-0 px-2" style="font-size: 0.75rem; height: 28px; max-width: 155px;" required>
                                                                     <option value="">-- Chỉ định XN --</option>
                                                                     <option value="phòng xét nghiệm máu - chức năng gan">Chức năng gan</option>
                                                                     <option value="phòng xét nghiệm máu - chức năng thận">Chức năng thận</option>
                                                                     <option value="phòng xét nghiệm máu - mỡ máu">Mỡ máu</option>
                                                                 </select>
                                                                 <button type="submit" class="btn btn-vinmec btn-xs px-2 py-1" style="font-size: 0.75rem;">
                                                                     Chỉ định
                                                                 </button>
                                                             </form>
                                                         </div>
                                                     </td>
                                                     <td>
                                                         <button type="button" class="btn btn-outline-success btn-xs" data-bs-toggle="modal" data-bs-target="#recordModal${r.recordId}">
                                                             <i class="bi bi-eye"></i> Xem
                                                         </button>
                                                     </td>
                                                </tr>
                                            </c:forEach>
                                        </c:otherwise>
                                    </c:choose>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Module 3: Danh sách bệnh nhân -->
            <div class="tab-pane fade" id="pill-patients" role="tabpanel" aria-labelledby="pill-patients-tab">
                <div class="card card-custom">
                    <div class="card-header card-header-custom py-2 d-flex flex-wrap align-items-center justify-content-between gap-3">
                        <span class="fw-bold"><i class="bi bi-people-fill me-2"></i> Danh sách bệnh nhân xét nghiệm</span>
                        
                        <!-- Search Box and Status Filters -->
                        <div class="d-flex align-items-center gap-2 flex-wrap">
                            <!-- Status filter buttons -->
                            <div class="btn-group btn-group-sm" role="group" aria-label="Status filters">
                                <button type="button" class="btn btn-outline-success active" id="filter-all-btn" onclick="setStatusFilter('all')">Tất cả</button>
                                <button type="button" class="btn btn-outline-success" id="filter-waiting-btn" onclick="setStatusFilter('waiting')">Chờ xét nghiệm</button>
                                <button type="button" class="btn btn-outline-success" id="filter-testing-btn" onclick="setStatusFilter('testing')">Đang xét nghiệm</button>
                                <button type="button" class="btn btn-outline-success" id="filter-completed-btn" onclick="setStatusFilter('completed')">Đã xét nghiệm</button>
                            </div>
                            
                            <!-- Search input -->
                            <div class="input-group input-group-sm" style="max-width: 250px;">
                                <span class="input-group-text bg-white border-end-0 text-secondary"><i class="bi bi-search"></i></span>
                                <input type="text" class="form-control border-start-0 ps-0 shadow-none" id="patientSearchInput" placeholder="Tìm tên, email, SĐT..." onkeyup="filterPatientsDebounced()">
                            </div>
                        </div>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive" style="max-height: 600px; overflow-y: auto;">
                            <table class="table table-hover table-custom m-0" id="patientMergeTable">
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Họ và tên</th>
                                        <th>Email / SĐT</th>
                                        <th>Phòng</th>
                                        <th>Trạng thái</th>
                                        <th>Hành động</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <c:choose>
                                        <c:when test="${empty patients}">
                                            <tr>
                                                <td colspan="6" class="text-center py-4 text-secondary">Chưa có bệnh nhân nào đăng ký.</td>
                                            </tr>
                                        </c:when>
                                        <c:otherwise>
                                            <c:forEach var="p" items="${patients}">
                                                <!-- Determine status -->
                                                <c:set var="isCompleted" value="${p.waitlistStatus eq 'completed' or (empty p.waitlistStatus and Integer.parseInt(p.recordCount) gt 0)}" />
                                                <c:set var="isTesting" value="${p.waitlistStatus eq 'testing'}" />
                                                <c:set var="isWaiting" value="${p.waitlistStatus eq 'waiting'}" />
                                                <tr class="patient-row" 
                                                    data-status="${isCompleted ? 'completed' : (isTesting ? 'testing' : (isWaiting ? 'waiting' : 'none'))}" 
                                                    data-room="${empty p.labRoom ? 'none' : p.labRoom}"
                                                    data-search-text="${p.fullName.toLowerCase()} ${p.email.toLowerCase()} ${p.phone.toLowerCase()}">
                                                    <td>#<c:out value="${p.patientId}" /></td>
                                                    <td>
                                                        <span class="fw-semibold"><c:out value="${p.fullName}" /></span><br>
                                                        <small class="text-secondary">Ngày sinh: <c:out value="${p.dob}" /> | <c:out value="${p.gender}" /></small>
                                                    </td>
                                                    <td class="small">
                                                        <i class="bi bi-envelope text-secondary me-1"></i><c:out value="${p.email}" /><br>
                                                        <i class="bi bi-telephone text-secondary me-1"></i><c:out value="${p.phone}" />
                                                    </td>
                                                    <td>
                                                        <c:choose>
                                                            <c:when test="${p.labRoom eq 'phòng xét nghiệm máu' or p.labRoom eq 'phòng xét nghiệm máu - đường huyết'}">
                                                                <span class="badge bg-danger bg-opacity-10 text-danger border border-danger-subtle"><i class="bi bi-activity me-1"></i>Xét nghiệm đường huyết</span>
                                                            </c:when>
                                                            <c:when test="${p.labRoom eq 'phòng xét nghiệm nước tiểu'}">
                                                                <span class="badge bg-info bg-opacity-10 text-info border border-info-subtle"><i class="bi bi-droplet me-1"></i>Xét nghiệm nước tiểu</span>
                                                            </c:when>
                                                            <c:when test="${p.labRoom eq 'phòng xét nghiệm máu - chức năng gan'}">
                                                                <span class="badge bg-success bg-opacity-10 text-success border border-success-subtle"><i class="bi bi-heart-pulse-fill me-1"></i>Chức năng gan</span>
                                                            </c:when>
                                                            <c:when test="${p.labRoom eq 'phòng xét nghiệm máu - chức năng thận'}">
                                                                <span class="badge bg-warning bg-opacity-10 text-warning border border-warning-subtle"><i class="bi bi-prescription me-1"></i>Chức năng thận</span>
                                                            </c:when>
                                                            <c:when test="${p.labRoom eq 'phòng xét nghiệm máu - mỡ máu'}">
                                                                <span class="badge bg-primary bg-opacity-10 text-primary border border-primary-subtle"><i class="bi bi-droplet-half me-1"></i>Mỡ máu</span>
                                                            </c:when>
                                                            <c:when test="${not empty p.labRoom}">
                                                                <span class="badge bg-secondary bg-opacity-10 text-secondary border border-secondary-subtle" style="text-transform: capitalize;"><i class="bi bi-door-closed me-1"></i><c:out value="${p.labRoom}" /></span>
                                                            </c:when>
                                                            <c:otherwise>
                                                                <span class="text-secondary">-</span>
                                                            </c:otherwise>
                                                         </c:choose>
                                                     </td>
                                                    <td>
                                                         <c:choose>
                                                             <c:when test="${isCompleted}">
                                                                 <span class="badge bg-success"><i class="bi bi-check-circle-fill me-1"></i>Đã xét nghiệm</span>
                                                             </c:when>
                                                             <c:when test="${isTesting}">
                                                                 <span class="badge bg-primary text-white"><i class="bi bi-activity me-1"></i>Đang xét nghiệm</span>
                                                             </c:when>
                                                             <c:when test="${isWaiting}">
                                                                 <span class="badge bg-warning text-dark"><i class="bi bi-hourglass-split me-1"></i>Chờ xét nghiệm</span>
                                                             </c:when>
                                                             <c:otherwise>
                                                                 <span class="badge bg-secondary"><i class="bi bi-dash-circle me-1"></i>Chưa chỉ định</span>
                                                             </c:otherwise>
                                                         </c:choose>
                                                     </td>
                                                    <td>
                                                        <c:choose>
                                                            <c:when test="${isCompleted}">
                                                                <button type="button" class="btn btn-secondary btn-xs px-2 py-1" style="font-size: 0.75rem;" disabled>
                                                                    <i class="bi bi-slash-circle me-1"></i> Đã hoàn thành
                                                                </button>
                                                            </c:when>
                                                            <c:when test="${isTesting}">
                                                                <button type="button" class="btn btn-outline-info btn-xs px-2 py-1" style="font-size: 0.75rem;" disabled>
                                                                    <i class="bi bi-activity me-1"></i> Đang xét nghiệm
                                                                </button>
                                                            </c:when>
                                                            <c:when test="${isWaiting}">
                                                                <button type="button" class="btn btn-vinmec btn-xs px-2 py-1" style="font-size: 0.75rem;"
                                                                        onclick="invitePatient('${p.waitingId}')">
                                                                    <i class="bi bi-megaphone-fill me-1"></i> Mời vào phòng
                                                                </button>
                                                            </c:when>
                                                            <c:otherwise>
                                                                <div class="dropdown d-inline-block">
                                                                    <button type="button" class="btn btn-outline-vinmec btn-xs dropdown-toggle px-2 py-1" data-bs-toggle="dropdown" aria-expanded="false" style="font-size: 0.75rem;">
                                                                        <i class="bi bi-file-earmark-plus-fill me-1"></i> Nhập xét nghiệm
                                                                    </button>
                                                                    <ul class="dropdown-menu dropdown-menu-end shadow-sm" style="font-size: 0.8rem;">
                                                                        <li>
                                                                            <a class="dropdown-item py-1" href="javascript:void(0)" onclick="selectPatientForTestType('${p.patientId}', 'phòng xét nghiệm máu - đường huyết')">
                                                                                <i class="bi bi-activity text-danger me-1"></i> Đường huyết
                                                                            </a>
                                                                        </li>
                                                                        <li>
                                                                            <a class="dropdown-item py-1" href="javascript:void(0)" onclick="selectPatientForTestType('${p.patientId}', 'phòng xét nghiệm nước tiểu')">
                                                                                <i class="bi bi-droplet text-info me-1"></i> Nước tiểu
                                                                            </a>
                                                                        </li>
                                                                    </ul>
                                                                </div>
                                                            </c:otherwise>
                                                        </c:choose>
                                                    </td>
                                                 </tr>
                                             </c:forEach>
                                         </c:otherwise>
                                     </c:choose>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Module: Phòng xét nghiệm -->
            <div class="tab-pane fade" id="pill-rooms" role="tabpanel" aria-labelledby="pill-rooms-tab">
                <div class="card card-custom">
                    <div class="card-header card-header-custom py-2 d-flex flex-wrap align-items-center justify-content-between gap-3">
                        <span class="fw-bold" id="room-table-title"><i class="bi bi-door-closed me-2"></i> Phòng xét nghiệm chức năng</span>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive" style="max-height: 600px; overflow-y: auto;">
                            <table class="table table-hover table-custom m-0">
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Họ và tên</th>
                                        <th>Email / SĐT</th>
                                        <th>Trạng thái</th>
                                        <th>Hành động</th>
                                    </tr>
                                </thead>
                                <tbody id="roomPatientsTableBody">
                                     <c:choose>
                                         <c:when test="${empty patients}">
                                             <tr>
                                                 <td colspan="5" class="text-center py-4 text-secondary">Chưa có bệnh nhân nào đăng ký.</td>
                                             </tr>
                                         </c:when>
                                         <c:otherwise>
                                             <c:forEach var="p" items="${patients}">
                                                 <c:if test="${not empty p.labRoom and (p.waitlistStatus eq 'testing' or p.waitlistStatus eq 'completed')}">
                                                     <c:set var="isCompleted" value="${p.waitlistStatus eq 'completed' or (empty p.waitlistStatus and Integer.parseInt(p.recordCount) gt 0)}" />
                                                     <c:set var="isTesting" value="${p.waitlistStatus eq 'testing'}" />
                                                     <c:set var="isWaiting" value="${p.waitlistStatus eq 'waiting'}" />
                                                     <tr class="room-patient-row" 
                                                         data-room="${p.labRoom}">
                                                         <td>#<c:out value="${p.patientId}" /></td>
                                                         <td>
                                                             <span class="fw-semibold"><c:out value="${p.fullName}" /></span><br>
                                                             <small class="text-secondary">Ngày sinh: <c:out value="${p.dob}" /> | <c:out value="${p.gender}" /></small>
                                                         </td>
                                                         <td class="small">
                                                             <i class="bi bi-envelope text-secondary me-1"></i><c:out value="${p.email}" /><br>
                                                             <i class="bi bi-telephone text-secondary me-1"></i><c:out value="${p.phone}" />
                                                         </td>
                                                         <td>
                                                             <c:choose>
                                                                 <c:when test="${isCompleted}">
                                                                     <span class="badge bg-success"><i class="bi bi-check-circle-fill me-1"></i>Đã xét nghiệm</span>
                                                                 </c:when>
                                                                 <c:when test="${isTesting}">
                                                                     <span class="badge bg-primary text-white"><i class="bi bi-activity me-1"></i>Đang xét nghiệm</span>
                                                                 </c:when>
                                                                 <c:otherwise>
                                                                     <span class="badge bg-warning text-dark"><i class="bi bi-hourglass-split me-1"></i>Chờ xét nghiệm</span>
                                                                 </c:otherwise>
                                                             </c:choose>
                                                         </td>
                                                         <td>
                                                             <c:choose>
                                                                  <c:when test="${isCompleted}">
                                                                      <button type="button" class="btn btn-secondary btn-xs px-2 py-1" style="font-size: 0.75rem;" disabled>
                                                                          <i class="bi bi-slash-circle me-1"></i> Đã hoàn thành
                                                                      </button>
                                                                  </c:when>
                                                                  <c:when test="${isTesting}">
                                                                      <button type="button" class="btn btn-info btn-xs px-2 py-1 text-white" style="font-size: 0.75rem;"
                                                                              onclick="selectWaitingPatient('${p.patientId}', '<c:out value="${p.fullName}"/>', '<c:out value="${p.email}"/>', '<c:out value="${p.phone}"/>', '<c:out value="${p.dob}"/>', '<c:out value="${p.gender}"/>', '<c:out value="${p.address}"/>', '${p.waitingId}')">
                                                                          <i class="bi bi-play-fill me-1"></i> Tiến hành xét nghiệm
                                                                      </button>
                                                                  </c:when>
                                                              </c:choose>
                                                         </td>
                                                     </tr>
                                                 </c:if>
                                             </c:forEach>
                                         </c:otherwise>
                                     </c:choose>
                                 </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        
            <!-- Module 5: Lịch làm việc -->
            
            <div class="tab-pane fade" id="pill-schedule" role="tabpanel" aria-labelledby="pill-schedule-tab">
                <div class="card card-custom">
                    <div class="card-header card-header-custom py-2 d-flex justify-content-between align-items-center">
                        <div class="d-flex align-items-center gap-2">
                            <i class="bi bi-calendar3 fs-5"></i>
                            <span class="fw-bold fs-5">Lịch làm việc theo tuần (Weekly Timetable)</span>
                        </div>
                        <span class="badge bg-success text-white fw-bold px-2 py-1" style="background-color: #007f61 !important;">Cập nhật liên tục</span>
                    </div>
                    <div class="card-body p-2 bg-light-subtle">
                        <div class="table-responsive">
                            <table class="table table-bordered text-center align-middle m-0" style="width: 100%; border-color: #dee2e6; table-layout: fixed;">
                                <thead>
                                    <tr style="background: linear-gradient(135deg, #007f61, #009672); color: white; border: none;">
                                        <th class="py-2" style="width: 14.28%; font-size: 0.8rem;">MON<br><span class="small text-white-50">13/07</span></th>
                                        <th class="py-2" style="width: 14.28%; font-size: 0.8rem;">TUE<br><span class="small text-white-50">14/07</span></th>
                                        <th class="py-2" style="width: 14.28%; font-size: 0.8rem;">WED<br><span class="small text-white-50">15/07</span></th>
                                        <th class="py-2" style="width: 14.28%; font-size: 0.8rem;">THU<br><span class="small text-white-50">16/07</span></th>
                                        <th class="py-2" style="width: 14.28%; font-size: 0.8rem;">FRI<br><span class="small text-white-50">17/07</span></th>
                                        <th class="py-2" style="width: 14.28%; font-size: 0.8rem;">SAT<br><span class="small text-white-50">18/07</span></th>
                                        <th class="py-2" style="width: 14.28%; font-size: 0.8rem;">SUN<br><span class="small text-white-50">19/07</span></th>
                                    </tr>
                                </thead>
                                <tbody id="fap-timetable-body">
                                    <!-- Generated by JavaScript -->
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
</div>
</div>
    </main>

    <script>
        function invitePatient(waitingId) {
            const form = document.createElement('form');
            form.method = 'POST';
            form.action = '${pageContext.request.contextPath}/doctor-lab/dashboard';
            
            const inputAction = document.createElement('input');
            inputAction.type = 'hidden';
            inputAction.name = 'action';
            inputAction.value = 'invite';
            form.appendChild(inputAction);
            
            const inputWaitingId = document.createElement('input');
            inputWaitingId.type = 'hidden';
            inputWaitingId.name = 'waitingId';
            inputWaitingId.value = waitingId;
            form.appendChild(inputWaitingId);
            
            document.body.appendChild(form);
            form.submit();
        }

        // Select a patient from waiting list and run test
        function selectWaitingPatient(patientId, fullName, email, phone, dob, gender, address, waitingId) {
            submitRandomTest(patientId, waitingId);
        }

        // Fast patient selection from Patients list for a specific test type
        function selectPatientForTestType(patientId, labRoom) {
            submitRandomTest(patientId, '', labRoom);
        }
 
        function submitRandomTest(patientId, waitingId, labRoom) {
            if (!confirm("Tiến hành xét nghiệm tự động cho bệnh nhân này?")) {
                return;
            }
 
            const overlay = document.getElementById('loadingOverlay');
            if (overlay) {
                overlay.classList.add('show');
            }
 
            // Create a hidden form and submit it instantly
            const form = document.createElement('form');
            form.method = 'POST';
            form.action = '${pageContext.request.contextPath}/doctor-lab/dashboard';
            
            const inputPatientId = document.createElement('input');
            inputPatientId.type = 'hidden';
            inputPatientId.name = 'patientId';
            inputPatientId.value = patientId;
            form.appendChild(inputPatientId);
            
            const inputWaitingId = document.createElement('input');
            inputWaitingId.type = 'hidden';
            inputWaitingId.name = 'waitingId';
            inputWaitingId.value = waitingId;
            form.appendChild(inputWaitingId);
            
            const inputIsRandom = document.createElement('input');
            inputIsRandom.type = 'hidden';
            inputIsRandom.name = 'isRandom';
            inputIsRandom.value = 'true';
            form.appendChild(inputIsRandom);
            
            if (labRoom) {
                const inputLabRoom = document.createElement('input');
                inputLabRoom.type = 'hidden';
                inputLabRoom.name = 'labRoom';
                inputLabRoom.value = labRoom;
                form.appendChild(inputLabRoom);
            }
            
            document.body.appendChild(form);
            form.submit();
        }

        let currentStatusFilter = 'all';
        let activeSidebarRoom = 'phòng xét nghiệm máu - đường huyết';

        function setSidebarRoomFilter(room) {
            activeSidebarRoom = room;
            filterSidebarRoomPatients();
        }

        function toggleBloodSubMenu() {
            const bloodSubMenu = document.getElementById('blood-sub-menu');
            const chevron = document.getElementById('blood-chevron');
            if (bloodSubMenu) {
                const isHidden = bloodSubMenu.style.display === 'none' || !bloodSubMenu.classList.contains('show');
                if (isHidden) {
                    bloodSubMenu.style.display = 'flex';
                    bloodSubMenu.classList.add('show');
                    if (chevron) chevron.style.transform = 'rotate(180deg)';
                    selectSidebarRoom('phòng xét nghiệm máu - đường huyết');
                } else {
                    bloodSubMenu.style.display = 'none';
                    bloodSubMenu.classList.remove('show');
                    if (chevron) chevron.style.transform = 'rotate(0deg)';
                }
            }
        }

        function selectSidebarRoom(room) {
            // Highlight parent tab "Phòng xét nghiệm"
            const parentTab = document.getElementById('pill-rooms-tab');
            if (parentTab) {
                document.querySelectorAll('.sidebar-nav .nav-link').forEach(link => {
                    link.classList.remove('active');
                });
                parentTab.classList.add('active');
                const tabTrigger = new bootstrap.Tab(parentTab);
                tabTrigger.show();
            }

            // Show sub-menu
            const subMenu = document.getElementById('rooms-sub-menu');
            if (subMenu) {
                subMenu.classList.add('show');
            }

            // Expand level 2 blood menu if active room belongs to blood test
            const bloodSub = document.getElementById('blood-sub-menu');
            const chevron = document.getElementById('blood-chevron');
            if (room.startsWith('phòng xét nghiệm máu')) {
                if (bloodSub) {
                    bloodSub.style.display = 'flex';
                    bloodSub.classList.add('show');
                }
                if (chevron) chevron.style.transform = 'rotate(180deg)';
            }

            // Highlight sub-items (clean active highlights first)
            document.querySelectorAll('.nav-item-sub').forEach(item => {
                item.classList.remove('active');
            });

            // Highlight chosen item
            if (room === 'phòng xét nghiệm máu - đường huyết') {
                const el = document.getElementById('sub-room-duonghuyet');
                if (el) el.classList.add('active');
                const parentEl = document.getElementById('sub-room-mau');
                if (parentEl) parentEl.classList.add('active');
            } else if (room === 'phòng xét nghiệm máu - chức năng gan') {
                const el = document.getElementById('sub-room-gan');
                if (el) el.classList.add('active');
                const parentEl = document.getElementById('sub-room-mau');
                if (parentEl) parentEl.classList.add('active');
            } else if (room === 'phòng xét nghiệm máu - chức năng thận') {
                const el = document.getElementById('sub-room-than');
                if (el) el.classList.add('active');
                const parentEl = document.getElementById('sub-room-mau');
                if (parentEl) parentEl.classList.add('active');
            } else if (room === 'phòng xét nghiệm máu - mỡ máu') {
                const el = document.getElementById('sub-room-momau');
                if (el) el.classList.add('active');
                const parentEl = document.getElementById('sub-room-mau');
                if (parentEl) parentEl.classList.add('active');
            } else if (room === 'phòng xét nghiệm nước tiểu') {
                const el = document.getElementById('sub-room-nuoctieu');
                if (el) el.classList.add('active');
            } else if (room === 'phòng xét nghiệm máu') {
                const el = document.getElementById('sub-room-mau');
                if (el) el.classList.add('active');
            }

            // Update title
            const titleSpan = document.getElementById('room-table-title');
            if (titleSpan) {
                let displayName = 'Phòng xét nghiệm';
                if (room === 'phòng xét nghiệm nước tiểu') {
                    displayName = 'Phòng xét nghiệm nước tiểu';
                } else if (room.includes('đường huyết')) {
                    displayName = 'Xét nghiệm máu - Đường huyết';
                } else if (room.includes('gan')) {
                    displayName = 'Xét nghiệm máu - Chức năng gan';
                } else if (room.includes('thận')) {
                    displayName = 'Xét nghiệm máu - Chức năng thận';
                } else if (room.includes('mỡ máu')) {
                    displayName = 'Xét nghiệm máu - Mỡ máu';
                } else {
                    displayName = 'Xét nghiệm máu';
                }
                titleSpan.innerHTML = `<i class="bi bi-door-closed me-2"></i> ` + displayName;
            }

            // Apply filter
            setSidebarRoomFilter(room);
        }

        function onParentRoomClick() {
            const subMenu = document.getElementById('rooms-sub-menu');
            if (subMenu) {
                subMenu.classList.add('show');
            }
            const activeSub = document.querySelector('.nav-item-sub.active');
            if (!activeSub) {
                selectSidebarRoom('phòng xét nghiệm máu - đường huyết');
            }
        }

        function filterSidebarRoomPatients() {
            const rows = document.querySelectorAll('.room-patient-row');
            rows.forEach(row => {
                const room = row.getAttribute('data-room');
                let matched = (room === activeSidebarRoom);
                if (!matched && activeSidebarRoom === 'phòng xét nghiệm máu' && room.startsWith('phòng xét nghiệm máu')) {
                    matched = true;
                }
                if (matched) {
                    row.style.display = '';
                } else {
                    row.style.display = 'none';
                }
            });
        }

        function setStatusFilter(status) {
            currentStatusFilter = status;
            
            // Update active states of button filters
            const allBtn = document.getElementById('filter-all-btn');
            const waitingBtn = document.getElementById('filter-waiting-btn');
            const testingBtn = document.getElementById('filter-testing-btn');
            const completedBtn = document.getElementById('filter-completed-btn');
            
            if (allBtn) allBtn.classList.toggle('active', status === 'all');
            if (waitingBtn) waitingBtn.classList.toggle('active', status === 'waiting');
            if (testingBtn) testingBtn.classList.toggle('active', status === 'testing');
            if (completedBtn) completedBtn.classList.toggle('active', status === 'completed');
            
            filterPatients();
        }

        function filterPatients() {
            const searchInput = document.getElementById('patientSearchInput');
            if (!searchInput) return;
            const query = searchInput.value.toLowerCase().trim();
            const rows = document.querySelectorAll('.patient-row');
            
            rows.forEach(row => {
                const status = row.getAttribute('data-status');
                const searchText = row.getAttribute('data-search-text');
                
                const matchesStatus = (currentStatusFilter === 'all' || status === currentStatusFilter);
                const matchesQuery = (query === '' || searchText.includes(query));
                
                if (matchesStatus && matchesQuery) {
                    row.style.display = '';
                } else {
                    row.style.display = 'none';
                }
            });
        }

        let searchTimeout = null;
        function filterPatientsDebounced() {
            clearTimeout(searchTimeout);
            searchTimeout = setTimeout(filterPatients, 150);
        }

        document.addEventListener('DOMContentLoaded', () => {
            setSidebarRoomFilter('phòng xét nghiệm máu - đường huyết');

            // Add click listeners to other tabs to collapse the sub-menu
            const otherTabs = ['pill-overview-tab', 'pill-patients-tab', 'pill-history-tab', 'pill-schedule-tab'];
            otherTabs.forEach(tabId => {
                const el = document.getElementById(tabId);
                if (el) {
                    el.addEventListener('click', () => {
                        const subMenu = document.getElementById('rooms-sub-menu');
                        if (subMenu) {
                            subMenu.classList.remove('show');
                        }
                        const bloodSubMenu = document.getElementById('blood-sub-menu');
                        if (bloodSubMenu) {
                            bloodSubMenu.style.display = 'none';
                            bloodSubMenu.classList.remove('show');
                        }
                        const chevron = document.getElementById('blood-chevron');
                        if (chevron) {
                            chevron.style.transform = 'rotate(0deg)';
                        }
                        document.querySelectorAll('.nav-item-sub').forEach(item => {
                            item.classList.remove('active');
                        });
                    });
                }
            });
        });
    </script>
    <!-- Modal Detail Containers for all records -->
    <c:forEach var="r" items="${records}">
        <c:choose>
             <c:when test="${fn:contains(r.otherInfo, 'gan')}">
                 <c:set var="isLiverTest" value="true" />
                 <c:set var="isLipidsTest" value="false" />
                 <c:set var="isKidneyTest" value="false" />
                 <c:set var="isUrineTest" value="false" />
             </c:when>
             <c:when test="${fn:contains(r.otherInfo, 'thận')}">
                 <c:set var="isLiverTest" value="false" />
                 <c:set var="isLipidsTest" value="false" />
                 <c:set var="isKidneyTest" value="true" />
                 <c:set var="isUrineTest" value="false" />
             </c:when>
             <c:when test="${fn:contains(r.otherInfo, 'mỡ máu')}">
                 <c:set var="isLiverTest" value="false" />
                 <c:set var="isLipidsTest" value="true" />
                 <c:set var="isKidneyTest" value="false" />
                 <c:set var="isUrineTest" value="false" />
             </c:when>
             <c:when test="${fn:contains(r.otherInfo, 'nước tiểu')}">
                 <c:set var="isLiverTest" value="false" />
                 <c:set var="isLipidsTest" value="false" />
                 <c:set var="isKidneyTest" value="false" />
                 <c:set var="isUrineTest" value="true" />
             </c:when>
             <c:otherwise>
                 <c:set var="isLiverTest" value="${(empty r.hba1c or r.hba1c eq '0' or r.hba1c eq '0.0') and (empty r.cr or r.cr eq '0' or r.cr eq '0.0') and (empty r.ldl or r.ldl eq '0' or r.ldl eq '0.0') and not empty r.chol and r.chol ne '0'}" />
                 <c:set var="isLipidsTest" value="${(empty r.hba1c or r.hba1c eq '0' or r.hba1c eq '0.0') and (empty r.cr or r.cr eq '0' or r.cr eq '0.0') and not empty r.ldl and r.ldl ne '0' and r.ldl ne '0.0'}" />
                 <c:set var="isKidneyTest" value="${(empty r.hba1c or r.hba1c eq '0' or r.hba1c eq '0.0') and (empty r.chol or r.chol eq '0' or r.chol eq '0.0') and not empty r.cr and r.cr ne '0' and r.cr ne '0.0'}" />
                 <c:set var="isUrineTest" value="${(empty r.hba1c or r.hba1c eq '0' or r.hba1c eq '0.0') and (empty r.chol or r.chol eq '0' or r.chol eq '0.0') and (empty r.cr or r.cr eq '0' or r.cr eq '0.0') and not empty r.tg}" />
             </c:otherwise>
        </c:choose>
        <div class="modal fade" id="recordModal${r.recordId}" tabindex="-1" aria-labelledby="recordModalLabel${r.recordId}" aria-hidden="true">
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header bg-success text-white">
                        <h5 class="modal-title fw-bold" id="recordModalLabel${r.recordId}">
                            <i class="bi bi-file-earmark-medical me-2"></i>Chi tiết kết quả xét nghiệm
                        </h5>
                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <div class="patient-modal-info mb-3 pb-3 border-bottom">
                            <h6 class="fw-bold text-dark mb-1"><c:out value="${r.patientName}" /></h6>
                            <span class="text-secondary small"><i class="bi bi-clock me-1"></i>Thời gian: <c:out value="${r.createdAt}" /></span>
                        </div>
                        <div class="table-responsive">
                            <table class="table table-bordered table-sm m-0">
                                <thead class="table-light">
                                    <tr>
                                        <th>Chỉ số</th>
                                        <th>Kết quả xét nghiệm</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <c:if test="${not isUrineTest}">
                                        <!-- Urea / AST / Đường huyết -->
                                        <c:if test="${not empty r.urea and r.urea ne '0' and r.urea ne '0.0' and r.urea ne '0.00'}">
                                            <c:choose>
                                                <c:when test="${fn:contains(r.otherInfo, 'đường huyết') or fn:contains(r.otherInfo, 'xét nghiệm máu')}">
                                                    <tr><td>Chỉ số đường huyết (mmol/L)</td><td class="fw-bold"><c:out value="${r.urea}" /> mmol/L</td></tr>
                                                </c:when>
                                                <c:otherwise>
                                                    <tr><td>Ure</td><td class="fw-bold"><c:out value="${r.urea}" /> mmol/L</td></tr>
                                                </c:otherwise>
                                            </c:choose>
                                        </c:if>
                                         <!-- HbA1c -->
                                         <c:if test="${not empty r.hba1c and r.hba1c ne '0' and r.hba1c ne '0.0' and r.hba1c ne '0.00'}">
                                             <tr><td>Chỉ số đường huyết (HbA1c)</td><td class="fw-bold text-danger"><c:out value="${r.hba1c}" /> %</td></tr>
                                         </c:if>
                                        <!-- Creatinine (Cr) -->
                                        <c:if test="${not empty r.cr and r.cr ne '0' and r.cr ne '0.0' and r.cr ne '0.00'}">
                                            <c:choose>
                                                <c:when test="${isKidneyTest}">
                                                    <tr><td>Creatinin</td><td class="fw-bold"><c:out value="${r.cr}" /> mg/dL</td></tr>
                                                </c:when>
                                                <c:otherwise>
                                                    <tr><td>Creatinine (Cr)</td><td class="fw-bold"><c:out value="${r.cr}" /> μmol/L</td></tr>
                                                </c:otherwise>
                                            </c:choose>
                                        </c:if>
                                        <!-- Cholesterol (Chol) / AST -->
                                        <c:if test="${not empty r.chol and r.chol ne '0' and r.chol ne '0.0' and r.chol ne '0.00'}">
                                            <c:choose>
                                                <c:when test="${isLiverTest}">
                                                    <tr><td>AST</td><td class="fw-bold"><c:out value="${r.chol}" /> UI/L</td></tr>
                                                </c:when>
                                                <c:when test="${isLipidsTest}">
                                                    <tr><td>Cholesterol</td><td class="fw-bold"><c:out value="${r.chol}" /> mmol/L</td></tr>
                                                </c:when>
                                                <c:otherwise>
                                                    <tr><td>Cholesterol (Chol)</td><td class="fw-bold"><c:out value="${r.chol}" /> mmol/L</td></tr>
                                                </c:otherwise>
                                            </c:choose>
                                        </c:if>
                                        <!-- Triglyceride (TG) / ALT -->
                                        <c:if test="${not empty r.tg and r.tg ne '0' and r.tg ne '0.0' and r.tg ne '0.00'}">
                                            <c:choose>
                                                <c:when test="${isLiverTest}">
                                                    <tr><td>ALT</td><td class="fw-bold"><c:out value="${r.tg}" /> UI/L</td></tr>
                                                </c:when>
                                                <c:when test="${isLipidsTest}">
                                                    <tr><td>Triglyceride</td><td class="fw-bold"><c:out value="${r.tg}" /> mmol/L</td></tr>
                                                </c:when>
                                                <c:otherwise>
                                                    <tr><td>Triglyceride (TG)</td><td class="fw-bold"><c:out value="${r.tg}" /> mmol/L</td></tr>
                                                </c:otherwise>
                                            </c:choose>
                                        </c:if>
                                        <!-- HDL -->
                                        <c:if test="${not empty r.hdl and r.hdl ne '0' and r.hdl ne '0.0' and r.hdl ne '0.00'}">
                                            <tr><td>HDL</td><td class="fw-bold"><c:out value="${r.hdl}" /> mmol/L</td></tr>
                                        </c:if>
                                        <!-- LDL -->
                                        <c:if test="${not empty r.ldl and r.ldl ne '0' and r.ldl ne '0.0' and r.ldl ne '0.00'}">
                                            <tr><td>LDL</td><td class="fw-bold"><c:out value="${r.ldl}" /> mmol/L</td></tr>
                                        </c:if>
                                        <!-- VLDL -->
                                        <c:if test="${not empty r.vldl and r.vldl ne '0' and r.vldl ne '0.0' and r.vldl ne '0.00'}">
                                            <tr><td>VLDL</td><td class="fw-bold"><c:out value="${r.vldl}" /> mmol/L</td></tr>
                                        </c:if>
                                    </c:if>
                                    <c:if test="${isUrineTest}">
                                        <!-- GLU -->
                                        <c:if test="${not empty r.urea and r.urea ne '0' and r.urea ne '0.0' and r.urea ne '0.00'}">
                                            <tr>
                                                <td>GLU (Glucose / Đường)</td>
                                                <td class="fw-bold ${r.urea >= 0.8 ? 'text-danger' : 'text-success'}">
                                                    <c:out value="${r.urea}" /> mmol/L
                                                </td>
                                            </tr>
                                        </c:if>
                                        <!-- PRO -->
                                        <c:if test="${not empty r.cr and r.cr ne '0' and r.cr ne '0.0' and r.cr ne '0.00'}">
                                            <tr>
                                                <td>PRO (Protein / Đạm)</td>
                                                <td class="fw-bold ${r.cr >= 0.1 ? 'text-danger' : 'text-success'}">
                                                    <c:out value="${r.cr}" /> g/L
                                                </td>
                                            </tr>
                                        </c:if>
                                        <!-- LEU -->
                                        <c:if test="${not empty r.hba1c and r.hba1c ne '0' and r.hba1c ne '0.0' and r.hba1c ne '0.00'}">
                                            <tr>
                                                <td>LEU (Leukocytes / Bạch cầu)</td>
                                                <td class="fw-bold ${r.hba1c > 25 ? 'text-danger' : 'text-success'}">
                                                    <c:out value="${r.hba1c}" /> Leu/&micro;L
                                                </td>
                                            </tr>
                                        </c:if>
                                        <!-- NIT -->
                                        <c:if test="${not empty r.hdl}">
                                            <tr>
                                                <td>NIT (Nitrit)</td>
                                                <td class="fw-bold ${r.hdl eq '1' or r.hdl eq '1.0' or r.hdl eq '1.00' ? 'text-danger' : 'text-success'}">
                                                    <c:choose>
                                                        <c:when test="${r.hdl eq '1' or r.hdl eq '1.0' or r.hdl eq '1.00'}">Dương tính (+)</c:when>
                                                        <c:otherwise>Âm tính</c:otherwise>
                                                    </c:choose>
                                                </td>
                                            </tr>
                                        </c:if>
                                        <!-- BLD -->
                                        <c:if test="${not empty r.ldl}">
                                            <tr>
                                                <td>BLD (Blood / Hồng cầu)</td>
                                                <td class="fw-bold ${r.ldl eq '1' or r.ldl eq '1.0' or r.ldl eq '1.00' ? 'text-danger' : 'text-success'}">
                                                    <c:choose>
                                                        <c:when test="${r.ldl eq '1' or r.ldl eq '1.0' or r.ldl eq '1.00'}">Dương tính (+)</c:when>
                                                        <c:otherwise>Âm tính</c:otherwise>
                                                    </c:choose>
                                                </td>
                                            </tr>
                                        </c:if>
                                        <!-- SG -->
                                        <c:if test="${not empty r.vldl and r.vldl ne '0' and r.vldl ne '0.0' and r.vldl ne '0.00'}">
                                            <tr>
                                                <td>SG (Tỷ trọng / Specific Gravity)</td>
                                                <td class="fw-bold ${r.vldl < 1.005 or r.vldl > 1.030 ? 'text-danger' : 'text-success'}">
                                                    <c:out value="${r.vldl}" />
                                                </td>
                                            </tr>
                                        </c:if>
                                        <!-- pH -->
                                        <c:if test="${not empty r.tg and r.tg ne '0' and r.tg ne '0.0' and r.tg ne '0.00'}">
                                            <tr>
                                                <td>pH (Độ acid / kiềm)</td>
                                                <td class="fw-bold ${r.tg < 4.6 or r.tg > 8.0 ? 'text-danger' : 'text-success'}">
                                                     <c:out value="${r.tg}" />
                                                 </td>
                                            </tr>
                                        </c:if>
                                    </c:if>
                                    <!-- Weight -->
                                    <c:if test="${not empty r.weight and r.weight ne '0' and r.weight ne '0.0' and r.weight ne '0.00'}">
                                        <tr><td>Cân nặng</td><td><c:out value="${r.weight}" /> kg</td></tr>
                                    </c:if>
                                    <!-- Height -->
                                    <c:if test="${not empty r.height and r.height ne '0' and r.height ne '0.0' and r.height ne '0.00'}">
                                        <tr><td>Chiều cao</td><td><c:out value="${r.height}" /> cm</td></tr>
                                    </c:if>
                                    <!-- BMI -->
                                    <c:if test="${not empty r.bmi and r.bmi ne '0' and r.bmi ne '0.0' and r.bmi ne '0.00'}">
                                        <tr><td>BMI</td><td class="fw-bold text-primary"><c:out value="${r.bmi}" /></td></tr>
                                    </c:if>
                                </tbody>
                            </table>
                        </div>
                        <c:if test="${not empty r.otherInfo}">
                            <div class="mt-3 p-3 bg-light rounded border">
                                <strong class="text-success d-block mb-1"><i class="bi bi-info-circle-fill me-1"></i> Ghi chú &amp; Xét nghiệm khác:</strong>
                                <pre class="m-0 text-secondary" style="font-family: inherit; font-size: 0.85rem; white-space: pre-wrap;"><c:out value="${r.otherInfo}" /></pre>
                            </div>
                        </c:if>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Đóng</button>
                    </div>
                </div>
            </div>
        </div>
    </c:forEach>

    <!-- Loading Overlay Blocker -->
    <div class="loading-overlay" id="loadingOverlay">
        <div class="spinner-vinmec"></div>
        <h5 class="text-success fw-bold m-0">Đang tiến hành xét nghiệm...</h5>
        <p class="text-secondary small m-0">Hệ thống đang tự động khởi tạo kết quả, vui lòng đợi trong giây lát.</p>
    </div>
    <script>
        const slotsConfig = {
            "Hành chính": { time: "08:00 - 12:00 & 13:30 - 17:30", label: "Ca hành chính (8h/ngày)" },
            "Trực 24h": { time: "08:00 - 08:00 (Sáng hôm sau)", label: "Trực 24h" },
            "Cấp cứu Ca 1": { time: "06:00 - 14:00", label: "Cấp cứu Ca 1" },
            "Cấp cứu Ca 2": { time: "14:00 - 22:00", label: "Cấp cứu Ca 2" },
            "Cấp cứu Ca 3": { time: "22:00 - 06:00", label: "Cấp cứu Ca 3" }
        };

        const mockSchedules = [
            // Ca hành chính (8h/ngày, 40h/tuần): Mon - Fri
            { slotKey: "Hành chính", dateStr: "2026-07-13", roomId: "phòng xét nghiệm máu - đường huyết", type: "blood" },
            { slotKey: "Hành chính", dateStr: "2026-07-14", roomId: "phòng xét nghiệm nước tiểu", type: "urine" },
            { slotKey: "Hành chính", dateStr: "2026-07-15", roomId: "phòng xét nghiệm máu - đường huyết", type: "blood" },
            { slotKey: "Hành chính", dateStr: "2026-07-16", roomId: "phòng xét nghiệm nước tiểu", type: "urine" },
            { slotKey: "Hành chính", dateStr: "2026-07-17", roomId: "phòng xét nghiệm máu - đường huyết", type: "blood" },
            
            // Trực tùy bệnh viện (24h): Saturday
            { slotKey: "Trực 24h", dateStr: "2026-07-18", roomId: "phòng xét nghiệm máu - đường huyết", type: "blood" },
            
            // Cấp cứu (8h x 3 ca): Sunday emergency shifts
            { slotKey: "Cấp cứu Ca 2", dateStr: "2026-07-19", roomId: "phòng xét nghiệm nước tiểu", type: "urine" }
        ];

        const weekDates = [
            "2026-07-13",
            "2026-07-14",
            "2026-07-15",
            "2026-07-16",
            "2026-07-17",
            "2026-07-18",
            "2026-07-19"
        ];

        document.addEventListener('DOMContentLoaded', () => {
            const tbody = document.getElementById("fap-timetable-body");
            if (tbody) {
                tbody.innerHTML = "";
                const slotKeys = ["Hành chính", "Trực 24h", "Cấp cứu Ca 1", "Cấp cứu Ca 2", "Cấp cứu Ca 3"];
                
                slotKeys.forEach(slotKey => {
                    const config = slotsConfig[slotKey];
                    const tr = document.createElement("tr");
                    
                    for (let d = 0; d < 7; d++) {
                        const dateStr = weekDates[d];
                        const td = document.createElement("td");
                        td.className = "align-middle p-1";
                        td.style.width = "14.28%";
                        td.style.height = "55px";
                        
                        const match = mockSchedules.find(s => s.dateStr === dateStr && s.slotKey === slotKey);
                        
                        if (match) {
                            let slotClass = match.type === "blood" ? "slot-blood_sugar" : "slot-urine_test";
                            let badgeStyle = match.type === "blood" 
                                ? "background-color: #fee2e2 !important; color: #b91c1c !important; border: 1px solid #fecaca !important;" 
                                : "background-color: #dbeafe !important; color: #1d4ed8 !important; border: 1px solid #bfdbfe !important;";
                            td.innerHTML = `
                                <div class="fap-card-slot \${slotClass}">
                                    <div class="fw-bold" style="font-size: 0.72rem; word-break: break-word;">\${match.roomId}</div>
                                    <div class="mt-1">
                                        <span class="badge px-1.5 py-0.5 font-monospace" style="font-size: 0.65rem; border-radius: 4px; \${badgeStyle}">\${config.label} (\${config.time})</span>
                                    </div>
                                </div>
                            `;
                        } else {
                            td.innerHTML = "";
                        }
                        tr.appendChild(td);
                    }
                    tbody.appendChild(tr);
                });
            }
        });
    </script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>

