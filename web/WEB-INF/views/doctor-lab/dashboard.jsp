<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="vi" style="color-scheme: light;">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="color-scheme" content="light">
    <title>Phòng Xét nghiệm - DiabetesCare</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/layouts/patient-shell.css">
    <style>
        :root {
            color-scheme: light;
            --primary:     #00a67e;
            --primary-dark:#007f61;
            --primary-deep:#005f48;
            --primary-pale:#e8f5f1;
            --primary-soft:#f5faf9;
            --bg-app:      #f5f7fa;
            --sidebar-w:   264px;
            --radius-card: 16px;
            --shadow-card: 0 2px 16px rgba(0,0,0,.06);
            --shadow-hover: 0 10px 32px rgba(0,0,0,.12);
        }

        /* ===== GLOBAL ===== */
        html { color-scheme: light !important; background: #f5f7fa !important; }
        *, *::before, *::after { box-sizing: border-box; }
        body {
            font-family: 'Inter', sans-serif;
            background: #f5f7fa !important;
            color: #1a202c !important;
            font-size: 0.93rem;
        }

        /* ===== SIDEBAR ===== */
        .sidebar-modern {
            background: #ffffff !important;
            border-right: 1px solid #e8ecf0 !important;
            padding-top: 0.5rem;
            overflow-y: auto;
            scrollbar-width: thin;
            scrollbar-color: #c5d1d0 transparent;
        }
        .sidebar-modern::-webkit-scrollbar { width: 4px; }
        .sidebar-modern::-webkit-scrollbar-track { background: transparent; }
        .sidebar-modern::-webkit-scrollbar-thumb { background: #b2dfdb; border-radius: 4px; }
        .sidebar-modern::-webkit-scrollbar-thumb:hover { background: var(--primary-dark); }

        /* Sidebar brand */
        .sidebar-header { padding: 1rem 1.1rem 0.5rem; }
        .brand-dashboard { display:flex; align-items:center; gap:.6rem; text-decoration:none; }
        .brand-icon-dash {
            width: 34px; height: 34px;
            border-radius: 9px;
            display: flex; align-items: center; justify-content: center;
            font-size: 1rem; color: #fff;
        }
        .brand-text { font-size: 1.05rem; font-weight: 800; letter-spacing: -.3px; }

        /* Nav items - optimized for light theme */
        .sidebar-modern .nav-item-dash {
            width: auto; text-align: left; border: none; background: transparent;
            font-family: inherit; font-size: 0.875rem; font-weight: 500; cursor: pointer;
            outline: none; display: flex; align-items: center; gap: 0.65rem;
            padding: 0.65rem 0.9rem;
            color: #4a5568 !important; text-decoration: none;
            transition: all 0.18s ease;
            border-radius: 10px;
            margin: 1px 0.5rem;
        }
        .sidebar-modern .nav-item-dash i { font-size: 1rem; transition: transform 0.18s ease; color: #64748b; }
        .sidebar-modern .nav-item-dash:hover i { transform: scale(1.1) translateX(1px); color: #007f61; }
        .sidebar-modern .nav-item-dash:hover {
            background: #f0faf7;
            color: #007f61 !important;
        }
        .sidebar-modern .nav-item-dash.active {
            background: #e6f7f2 !important;
            color: #007f61 !important;
            font-weight: 700;
            border-left: 3px solid #007f61;
            padding-left: calc(0.9rem - 3px);
        }
        .sidebar-modern .nav-item-dash.active i { color: #007f61 !important; }

        /* Sub-menus */
        .sidebar-modern .sub-menu {
            display: none; flex-direction: column;
            background: #fafdfc;
            border-left: 2px solid #b2dfdb;
            margin-left: 2.1rem; margin-bottom: 0.4rem;
            border-radius: 0 8px 8px 0; padding-left: 0.2rem;
        }
        .sidebar-modern .sub-menu-level2 {
            display: none; flex-direction: column;
            border-left: 1.5px dashed #b2dfdb;
            margin-left: 1.2rem; margin-bottom: 0.3rem;
            border-radius: 0 8px 8px 0; padding-left: 0.15rem;
        }
        @keyframes slideDown {
            from { opacity:0; transform:translateY(-6px); }
            to   { opacity:1; transform:translateY(0);    }
        }
        .sidebar-modern .sub-menu.show,
        .sidebar-modern .sub-menu-level2.show {
            display: flex;
            animation: slideDown 0.22s ease forwards;
        }
        .sidebar-modern .nav-item-sub {
            padding: 0.48rem 0.9rem; color: #5e7370; font-size: 0.82rem; font-weight: 500;
            text-decoration: none; transition: all 0.2s ease;
            display: flex; align-items: center; gap: 0.5rem;
            border-left: 3px solid transparent; border-radius: 0 6px 6px 0;
            margin-right: 0.4rem;
        }
        .sidebar-modern .nav-item-sub:hover {
            color: var(--primary-dark); background: var(--primary-soft);
            border-left-color: #80cbc4; padding-left: 1.1rem;
        }
        .sidebar-modern .nav-item-sub.active {
            color: var(--primary-dark); font-weight: 600;
            background: var(--primary-pale); border-left-color: var(--primary-dark);
        }
        .sidebar-modern .sub-menu-level2 .nav-item-sub { font-size: 0.79rem; padding: 0.4rem 0.7rem; }

        /* Logout button */
        .sidebar-modern .btn-logout {
            color: #dc2626 !important; border: none;
            border-radius: 10px; margin: 0 0.5rem;
            font-weight: 600;
        }
        .sidebar-modern .btn-logout:hover {
            background: #fef2f2 !important; color: #b91c1c !important;
        }

        /* Badge pulse */
        .sidebar-modern .badge.bg-danger {
            background: linear-gradient(135deg,#ff5252 0%,#ff1744 100%) !important;
            box-shadow: 0 2px 8px rgba(255,23,68,.4);
            animation: pulse-badge 2s infinite;
        }
        @keyframes pulse-badge {
            0%,100% { transform:scale(1);   box-shadow:0 2px 8px rgba(255,23,68,.4); }
            50%      { transform:scale(1.1); box-shadow:0 2px 14px rgba(255,23,68,.55); }
        }

        /* ===== MAIN CONTENT ===== */
        .main-content-dash {
            margin-left: var(--sidebar-w);
            padding: 1.5rem 2rem;
            background: #f5f7fa !important;
            min-height: 100vh;
        }
        @media (max-width: 900px) {
            .main-content-dash { margin-left: 72px; padding: 1rem; }
        }

        /* ===== BUTTONS ===== */
        .btn-vinmec {
            background: linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%);
            border: none; color: #fff; font-weight: 600;
            transition: all 0.25s ease; letter-spacing: .01em;
        }
        .btn-vinmec:hover {
            background: linear-gradient(135deg, var(--primary-dark) 0%, var(--primary-deep) 100%);
            color: #fff; transform: translateY(-1px);
            box-shadow: 0 6px 16px rgba(0,127,97,.3);
        }
        .btn-outline-vinmec {
            background: transparent; border: 1.5px solid var(--primary-dark);
            color: var(--primary-dark); font-weight: 600; transition: all 0.25s ease;
        }
        .btn-outline-vinmec:hover {
            background: var(--primary-pale); color: var(--primary-deep);
            transform: translateY(-1px);
        }

        /* ===== CARDS (generic) ===== */
        .card-custom {
            border: 1px solid #e8ecf0;
            border-radius: var(--radius-card);
            box-shadow: 0 2px 12px rgba(0,0,0,.05);
            background: #ffffff;
            margin-bottom: 1.5rem;
            overflow: hidden;
        }
        .card-header-custom {
            background: #f8fafb;
            border-bottom: 1px solid #e8ecf0;
            color: var(--primary-dark);
            font-weight: 700;
            font-size: 0.88rem;
            letter-spacing: .02em;
            padding: 0.85rem 1.25rem;
        }

        /* ===== DASHBOARD SUMMARY CARDS ===== */
        .card-summary {
            border-radius: var(--radius-card);
            background: #ffffff;
            border: none;
            overflow: hidden;
            position: relative;
            transition: transform 0.28s cubic-bezier(.4,0,.2,1), box-shadow 0.28s ease;
        }
        .card-summary::before {
            content: '';
            position: absolute; inset: 0;
            opacity: 0;
            transition: opacity 0.28s ease;
        }
        .card-summary:hover {
            transform: translateY(-6px);
            box-shadow: var(--shadow-hover);
        }
        .card-summary:hover::before { opacity: 1; }

        /* coloured accent bar inside cards */
        .cs-patients  { border-top: 3px solid #00b887; }
        .cs-waiting   { border-top: 3px solid #f6a623; }
        .cs-done      { border-top: 3px solid #0ea5e9; }
        .cs-records   { border-top: 3px solid #8b5cf6; }

        .card-summary .stat-number {
            font-size: 2rem; font-weight: 800; line-height: 1;
            background: linear-gradient(135deg, #1e2d2b 0%, #4a6360 100%);
            -webkit-background-clip: text; -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        .cs-patients .stat-number  { background: linear-gradient(135deg,#007f61,#00b887); -webkit-background-clip:text; background-clip:text; }
        .cs-waiting  .stat-number  { background: linear-gradient(135deg,#d97706,#f6a623); -webkit-background-clip:text; background-clip:text; }
        .cs-done     .stat-number  { background: linear-gradient(135deg,#0369a1,#0ea5e9); -webkit-background-clip:text; background-clip:text; }
        .cs-records  .stat-number  { background: linear-gradient(135deg,#6d28d9,#8b5cf6); -webkit-background-clip:text; background-clip:text; }

        .icon-box-summary {
            width: 52px; height: 52px;
            display: flex; align-items: center; justify-content: center;
            border-radius: 14px;
            flex-shrink: 0;
        }

        /* pulsing waiting icon */
        .pulsating-icon { animation: pulse 2s infinite; }
        @keyframes pulse {
            0%,100% { transform:scale(1);    opacity:1;   }
            50%      { transform:scale(1.18); opacity:0.75; }
        }

        /* ===== DASHBOARD HEADER BANNER ===== */
        .dashboard-header-banner .banner-overlay {
            background: linear-gradient(135deg, #e8f5f0 0%, #d4eee7 60%, #c2e5dc 100%) !important;
            border: 1px solid #b8dfd4 !important;
            border-radius: var(--radius-card);
            position: relative; overflow: hidden;
        }
        .dashboard-header-banner .banner-overlay::before {
            content: '';
            position: absolute; top: -40%; right: -5%;
            width: 320px; height: 320px;
            background: radial-gradient(circle, rgba(0,166,126,.06) 0%, transparent 70%);
            border-radius: 50%;
        }
        .dashboard-header-banner .banner-overlay::after {
            content: '';
            position: absolute; bottom: -30%; left: -3%;
            width: 220px; height: 220px;
            background: radial-gradient(circle, rgba(0,127,97,.08) 0%, transparent 70%);
            border-radius: 50%;
        }

        /* ===== PROGRESS BARS ===== */
        .progress { border-radius: 50px; background: #edf4f2; }
        .progress-bar { border-radius: 50px; transition: width .9s ease; }

        /* ===== DONUT CHART ===== */
        .hba1c-donut-wrapper { width: 130px; height: 130px; }
        .hba1c-donut-wrapper svg { width: 100%; height: 100%; }
        .donut-text { width: 100%; line-height: 1.1; }

        /* ===== TABLES ===== */
        .badge-status-approved { background: #e0f5ee; color: #007f61; }
        .badge-status-pending  { background: #fff8e1; color: #d97706; }
        .table-custom th {
            font-weight: 700; color: #5a6a78;
            background: #f8fafb;
            border-bottom: 2px solid #e2e8f0;
            font-size: 0.8rem; text-transform: uppercase; letter-spacing: .04em;
        }
        .table-custom td { vertical-align: middle; font-size: 0.875rem; }

        /* ===== MODAL SCROLLABLE FIX - footer always visible ===== */
        /* NOTE: form wraps modal-body + modal-footer, need form to also be flex */
        #editProfileModal .modal-dialog { max-height: 92vh; }
        #editProfileModal .modal-content {
            max-height: 90vh;
            display: flex !important;
            flex-direction: column !important;
            overflow: hidden !important;
        }
        #editProfileModal .modal-content form {
            flex: 1 1 auto;
            display: flex;
            flex-direction: column;
            overflow: hidden;
            min-height: 0;
        }
        #editProfileModal .modal-body {
            overflow-y: auto !important;
            flex: 1 1 auto !important;
            min-height: 0 !important;
        }
        #editProfileModal .modal-footer {
            flex-shrink: 0 !important;
            position: sticky;
            bottom: 0;
            z-index: 10;
        }

        /* ===== NAV TABS ===== */
        .nav-tabs-custom .nav-link {
            color: #6b8b86; font-weight: 500; border: none;
            border-bottom: 3px solid transparent; padding: 10px 18px;
            transition: all 0.2s ease; border-radius: 0;
        }
        .nav-tabs-custom .nav-link:hover { color: var(--primary-dark); }
        .nav-tabs-custom .nav-link.active {
            color: var(--primary-dark); background: transparent;
            border-bottom-color: var(--primary-dark); font-weight: 700;
        }

        /* ===== LOADING OVERLAY ===== */
        .loading-overlay {
            display: none; position: fixed; inset: 0;
            background: rgba(255,255,255,.82);
            z-index: 99999; align-items: center; justify-content: center;
            flex-direction: column; gap: 1rem; backdrop-filter: blur(3px);
        }
        .loading-overlay.show { display: flex; }
        .spinner-vinmec {
            width: 3rem; height: 3rem;
            border: 4px solid #d9f0eb;
            border-top-color: var(--primary-dark);
            border-radius: 50%; animation: spin 0.85s linear infinite;
        }
        @keyframes spin { to { transform:rotate(360deg); } }

        /* ===== TIMELINE ACTIVITY CARDS ===== */
        .timeline-card-hover {
            border-radius: 12px !important;
            border: 1px solid #e8ecf0 !important;
            background: #ffffff !important;
            transition: transform 0.22s ease, box-shadow 0.22s ease, border-color 0.22s ease;
        }
        .timeline-card-hover:hover {
            transform: translateY(-3px);
            box-shadow: 0 8px 20px rgba(0,0,0,.08) !important;
            border-color: #c5d9d4 !important;
        }

        /* ===== FAP SCHEDULE ===== */
        .fap-card-slot {
            padding: 7px 10px; border-radius: 10px; background: #fff;
            border: 1px solid #e4eceb;
            box-shadow: 0 2px 6px rgba(0,0,0,.03);
            line-height: 1.35; text-align: center;
            transition: transform 0.2s ease, box-shadow 0.2s ease;
        }
        .fap-card-slot:hover { transform: translateY(-2px); box-shadow: 0 6px 16px rgba(0,0,0,.08); }
        .slot-blood_sugar { border-left: 4px solid #dc3545 !important; background: #fef2f2 !important; color: #991b1b !important; }
        .slot-urine_test  { border-left: 4px solid #0d6efd !important; background: #eff6ff !important; color: #1e40af !important; }
        .slot-liver_test  { border-left: 4px solid #198754 !important; }
        .slot-kidney_test { border-left: 4px solid #fd7e14 !important; }
        .slot-lipids_test { border-left: 4px solid #0dcaf0 !important; }
        .slot-lab_test    { border-left: 4px solid #6c757d !important; }
        .fap-badge-mat    { background: #fff3cd !important; color: #856404 !important; border: 1px solid #ffeeba; font-size:.65rem; }
        .fap-badge-edunext{ background: #cce5ff !important; color: #004085 !important; border: 1px solid #b8daff; font-size:.65rem; }
        .fap-badge-meet   { background: #e2e3e5 !important; color: #383d41 !important; border: 1px solid #d6d8db; font-size:.65rem; }
        .fap-status-dot   { font-size: 0.72rem; margin-right: 3px; }

        /* ===== FADE-IN ANIMATION FOR CARDS ===== */
        @keyframes fadeInUp {
            from { opacity:0; transform:translateY(14px); }
            to   { opacity:1; transform:translateY(0);     }
        }
        .card-summary { animation: fadeInUp 0.45s ease both; }
        .col-6.col-md-3:nth-child(1) .card-summary { animation-delay: 0.05s; }
        .col-6.col-md-3:nth-child(2) .card-summary { animation-delay: 0.12s; }
        .col-6.col-md-3:nth-child(3) .card-summary { animation-delay: 0.19s; }
        .col-6.col-md-3:nth-child(4) .card-summary { animation-delay: 0.26s; }

        /* ===== SIDEBAR SECTION DIVIDER ===== */
        .sidebar-section-label {
            font-size: 0.65rem; font-weight: 700; letter-spacing: .08em;
            text-transform: uppercase; color: #9eb5b0;
            padding: 0.5rem 1.2rem 0.25rem;
            margin-top: 0.25rem;
        }

        /* ===== ALERTS (improved) ===== */
        .alert { border-radius: 12px; }
        .alert-success { background: #f0faf6; color: #065f46; border: 1px solid #a7f3d0; }
        .alert-warning { background: #fffbeb; color: #78350f; border: 1px solid #fde68a; }
        .alert-danger  { background: #fef2f2; color: #991b1b; border: 1px solid #fca5a5; }

        /* ===== FORCE LIGHT THEME ===== */
        .sidebar-modern, .main-content-dash, .card, .card-custom,
        .card-summary, .modal-content, .modal-body, .table,
        .nav-tabs-custom, .form-control, .form-select {
            color-scheme: light !important;
        }
        /* Ensure all sidebar text is dark (prevent dark mode color inheritance) */
        .sidebar-modern { color: #1a202c !important; }
        .sidebar-modern .user-profile-card h6,
        .sidebar-modern .user-profile-card .user-doctor-name {
            color: #1a202c !important;
            display: block !important;
            font-weight: 700 !important;
        }
        .sidebar-modern .sidebar-section-label { color: #9eb5b0 !important; }
    </style>
</head>
<body style="color-scheme: light; background: #f5f7fa;">

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

        <!-- Doctor profile card – click anywhere to open edit modal -->
        <div class="user-profile-card position-relative rounded-3 border shadow-sm"
             data-bs-toggle="modal" data-bs-target="#editProfileModal"
             role="button" tabindex="0" title="Nhấn để chỉnh sửa thông tin cá nhân"
             style="background: #ffffff; margin: 0.5rem 0.75rem 1rem 0.75rem; border-color: #e2e8f0 !important; cursor: pointer; padding: 0.75rem 0.85rem; transition: box-shadow 0.2s ease, border-color 0.2s ease;">

            <!-- Edit icon overlay (top-right corner) -->
            <span class="position-absolute top-0 end-0 me-2 mt-2 text-success" style="font-size: 0.8rem; opacity: 0.5;">
                <i class="bi bi-pencil-fill"></i>
            </span>

            <div class="d-flex align-items-center gap-2">
                <div class="flex-shrink-0" style="width:40px;height:40px;border-radius:10px;background:linear-gradient(135deg,#007f61,#00b887);font-weight:800;font-size:1.15rem;display:flex;align-items:center;justify-content:center;color:#fff;box-shadow:0 3px 10px rgba(0,127,97,.3);">${sessionScope.currentUser.fullName.charAt(0)}</div>
                <div style="flex:1;min-width:0;overflow:hidden;">
                    <div class="user-doctor-name" style="font-size:0.88rem;font-weight:700;color:#1a202c !important;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;line-height:1.3;margin-bottom:3px;" title="${sessionScope.currentUser.fullName}">${sessionScope.currentUser.fullName}</div>
                    <span style="display:inline-block;background:rgba(0,127,97,0.1);color:#007f61;border:1px solid rgba(0,127,97,0.25);font-size:0.62rem;font-weight:700;padding:1px 7px;border-radius:6px;font-family:monospace;letter-spacing:.04em;">LAB SYSTEM</span>
                </div>
            </div>
            <div class="mt-2 pt-2 border-top d-flex justify-content-between align-items-center">
                <c:choose>
                    <c:when test="${isProfileComplete}">
                        <span class="badge bg-success-subtle text-success border border-success-subtle" style="font-size: 0.68rem; padding: 3px 8px;">
                            <i class="bi bi-patch-check-fill me-1"></i>Hồ sơ hoàn tất
                        </span>
                    </c:when>
                    <c:otherwise>
                        <span class="badge bg-warning-subtle text-warning-emphasis border border-warning-subtle" style="font-size: 0.68rem; padding: 3px 8px;">
                            <i class="bi bi-exclamation-triangle-fill me-1"></i>Chưa hoàn tất
                        </span>
                    </c:otherwise>
                </c:choose>
                <span class="text-success fw-semibold" style="font-size: 0.72rem;">
                    <i class="bi bi-pencil-square me-1"></i>Chỉnh sửa
                </span>
            </div>
        </div>
        <style>
            .user-profile-card:hover {
                box-shadow: 0 6px 20px rgba(0, 127, 97, 0.12) !important;
                border-color: #a7d9d0 !important;
                background: #f8fdfb !important;
            }
            .user-profile-card:hover .bi-pencil-fill {
                opacity: 1 !important;
                color: #007f61 !important;
            }
            .user-profile-card:focus {
                outline: 2px solid #00b887;
                outline-offset: 2px;
            }
            /* Brand section */
            .sidebar-header { background: #ffffff; }
            .brand-icon-dash.bg-success {
                background: linear-gradient(135deg, #00a67e, #007f61) !important;
                box-shadow: 0 3px 10px rgba(0,127,97,.2);
            }
        </style>

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
        <c:if test="${not isProfileComplete}">
            <div class="alert alert-warning alert-dismissible fade show border-0 shadow-sm mb-2 py-2 px-3 d-flex align-items-center justify-content-between" role="alert">
                <div>
                    <i class="bi bi-exclamation-triangle-fill me-2 text-warning fs-5"></i>
                    <strong>Tài khoản được Admin khởi tạo!</strong> Vui lòng bổ sung đầy đủ thông tin cá nhân (SĐT, Email, Phòng xét nghiệm) để kích hoạt toàn bộ tính năng.
                </div>
                <button type="button" class="btn btn-sm btn-warning fw-bold text-dark ms-3 text-nowrap" data-bs-toggle="modal" data-bs-target="#editProfileModal">
                    <i class="bi bi-pencil-square me-1"></i>Cập nhật ngay
                </button>
            </div>
        </c:if>
        <c:if test="${not empty sessionScope.successMsg}">
            <div class="alert alert-success alert-dismissible fade show border-0 shadow-sm mb-2 py-1.5 px-3" role="alert">
                <i class="bi bi-check-circle-fill me-2"></i> ${sessionScope.successMsg}
                <button type="button" class="btn-close py-2" data-bs-dismiss="alert" aria-label="Close"></button>
            </div>
            <% session.removeAttribute("successMsg"); %>
        </c:if>
        <c:if test="${not empty sessionScope.errorMsg}">
            <div class="alert alert-danger alert-dismissible fade show border-0 shadow-sm mb-2 py-1.5 px-3" role="alert">
                <i class="bi bi-exclamation-triangle-fill me-2"></i> ${sessionScope.errorMsg}
                <button type="button" class="btn-close py-2" data-bs-dismiss="alert" aria-label="Close"></button>
            </div>
            <% session.removeAttribute("errorMsg"); %>
        </c:if>

        <div class="tab-content" id="v-pills-tabContent">

            <!-- Module 1: Tổng quan dashboard -->
            <div class="tab-pane fade show active" id="pill-overview" role="tabpanel" aria-labelledby="pill-overview-tab">
                <!-- Overview / Summary Dashboard Content -->
                <div class="dashboard-header-banner mb-4">
                    <div class="banner-overlay p-4 rounded-4 position-relative" style="overflow:hidden;">
                        <!-- decorative circles -->
                        <div style="position:absolute;top:-40%;right:-4%;width:280px;height:280px;background:radial-gradient(circle,rgba(0,127,97,.06) 0%,transparent 70%);border-radius:50%;pointer-events:none;"></div>
                        <div style="position:absolute;bottom:-30%;left:-2%;width:200px;height:200px;background:radial-gradient(circle,rgba(0,127,97,.08) 0%,transparent 70%);border-radius:50%;pointer-events:none;"></div>
                        <div class="d-flex align-items-center gap-3 position-relative">
                            <div style="width:48px;height:48px;border-radius:14px;background:rgba(0,127,97,.12);display:flex;align-items:center;justify-content:center;font-size:1.4rem;flex-shrink:0;color:#007f61;">
                                <i class="bi bi-grid-1x2-fill"></i>
                            </div>
                            <div>
                                <h4 class="fw-bold mb-0" style="font-size:1.2rem;letter-spacing:-.01em;color:#004d3a;">Báo cáo Tổng quan &amp; Thống kê Lâm sàng</h4>
                                <p class="mb-0 small" style="color:#4a7a68;margin-top:2px;">Tổng hợp chỉ số xét nghiệm, phân bố phòng chức năng, và phân tích sức khỏe đường huyết thời gian thực.</p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- 4 Top Summary Cards -->
                <div class="row g-3 mb-4">
                    <!-- Tổng bệnh nhân -->
                    <div class="col-6 col-md-3">
                        <div class="card card-summary cs-patients shadow-sm border-0 h-100 p-3">
                            <div class="d-flex align-items-center justify-content-between">
                                <div>
                                    <p class="text-muted small text-uppercase fw-semibold mb-1" style="font-size:.7rem;letter-spacing:.06em;">Tổng bệnh nhân</p>
                                    <div class="stat-number">${totalPatients}</div>
                                    <p class="text-muted mb-0 mt-1" style="font-size:.72rem;">Đã tiếp nhận</p>
                                </div>
                                <div class="icon-box-summary" style="background:rgba(0,184,135,.12);">
                                    <i class="bi bi-people-fill fs-4" style="color:#00a67e;"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                    <!-- Chờ xét nghiệm -->
                    <div class="col-6 col-md-3">
                        <div class="card card-summary cs-waiting shadow-sm border-0 h-100 p-3">
                            <div class="d-flex align-items-center justify-content-between">
                                <div>
                                    <p class="text-muted small text-uppercase fw-semibold mb-1" style="font-size:.7rem;letter-spacing:.06em;">Chờ xét nghiệm</p>
                                    <div class="stat-number">${waitingCount}</div>
                                    <p class="text-muted mb-0 mt-1" style="font-size:.72rem;">Đang trong hàng đợi</p>
                                </div>
                                <div class="icon-box-summary position-relative" style="background:rgba(246,166,35,.12);">
                                    <i class="bi bi-hourglass-split fs-4 pulsating-icon" style="color:#d97706;"></i>
                                    <c:if test="${waitingCount > 0}">
                                        <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" style="font-size:.6rem;">!</span>
                                    </c:if>
                                </div>
                            </div>
                        </div>
                    </div>
                    <!-- Đã xét nghiệm -->
                    <div class="col-6 col-md-3">
                        <div class="card card-summary cs-done shadow-sm border-0 h-100 p-3">
                            <div class="d-flex align-items-center justify-content-between">
                                <div>
                                    <p class="text-muted small text-uppercase fw-semibold mb-1" style="font-size:.7rem;letter-spacing:.06em;">Đã xét nghiệm</p>
                                    <div class="stat-number">${completedCount}</div>
                                    <p class="text-muted mb-0 mt-1" style="font-size:.72rem;">Hoàn thành hôm nay</p>
                                </div>
                                <div class="icon-box-summary" style="background:rgba(14,165,233,.12);">
                                    <i class="bi bi-check-circle-fill fs-4" style="color:#0ea5e9;"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                    <!-- Tổng lượt đo -->
                    <div class="col-6 col-md-3">
                        <div class="card card-summary cs-records shadow-sm border-0 h-100 p-3">
                            <div class="d-flex align-items-center justify-content-between">
                                <div>
                                    <p class="text-muted small text-uppercase fw-semibold mb-1" style="font-size:.7rem;letter-spacing:.06em;">Tổng lượt đo</p>
                                    <div class="stat-number">${totalRecords}</div>
                                    <p class="text-muted mb-0 mt-1" style="font-size:.72rem;">Kết quả ghi nhận</p>
                                </div>
                                <div class="icon-box-summary" style="background:rgba(139,92,246,.12);">
                                    <i class="bi bi-file-earmark-medical-fill fs-4" style="color:#8b5cf6;"></i>
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
                                <span><i class="bi bi-pie-chart-fill me-2 text-success"></i> Phân bố bệnh nhân theo Phòng xét nghiệm</span>
                            </div>
                            <div class="card-body p-4">
                                <div class="room-stat-item mb-3">
                                    <div class="d-flex justify-content-between align-items-center mb-1">
                                        <span class="fw-semibold text-secondary small"><i class="bi bi-droplet-fill text-danger me-1"></i>Xét nghiệm máu</span>
                                        <span class="badge rounded-pill bg-danger">${bloodTestCount} BN</span>
                                    </div>
                                    <div class="progress" style="height:8px;">
                                        <c:set var="bloodPct" value="${totalPatients > 0 ? (bloodTestCount * 100.0 / totalPatients) : 0}" />
                                        <div class="progress-bar bg-danger" role="progressbar" style="width:${bloodPct}%;"></div>
                                    </div>
                                </div>
                                <div class="room-stat-item mb-3">
                                    <div class="d-flex justify-content-between align-items-center mb-1">
                                        <span class="fw-semibold text-secondary small"><i class="bi bi-prescription text-warning me-1"></i>Xét nghiệm thận</span>
                                        <span class="badge rounded-pill bg-warning text-dark">${kidneyTestCount} BN</span>
                                    </div>
                                    <div class="progress" style="height:8px;">
                                        <c:set var="kidneyPct" value="${totalPatients > 0 ? (kidneyTestCount * 100.0 / totalPatients) : 0}" />
                                        <div class="progress-bar bg-warning" role="progressbar" style="width:${kidneyPct}%;"></div>
                                    </div>
                                </div>
                                <div class="room-stat-item mb-3">
                                    <div class="d-flex justify-content-between align-items-center mb-1">
                                        <span class="fw-semibold text-secondary small"><i class="bi bi-heart-pulse-fill text-success me-1"></i>Xét nghiệm gan</span>
                                        <span class="badge rounded-pill bg-success">${liverTestCount} BN</span>
                                    </div>
                                    <div class="progress" style="height:8px;">
                                        <c:set var="liverPct" value="${totalPatients > 0 ? (liverTestCount * 100.0 / totalPatients) : 0}" />
                                        <div class="progress-bar bg-success" role="progressbar" style="width:${liverPct}%;"></div>
                                    </div>
                                </div>
                                <div class="room-stat-item">
                                    <div class="d-flex justify-content-between align-items-center mb-1">
                                        <span class="fw-semibold text-secondary small"><i class="bi bi-droplet text-info me-1"></i>Xét nghiệm nước tiểu</span>
                                        <span class="badge rounded-pill bg-info text-dark">${urineTestCount} BN</span>
                                    </div>
                                    <div class="progress" style="height:8px;">
                                        <c:set var="urinePct" value="${totalPatients > 0 ? (urineTestCount * 100.0 / totalPatients) : 0}" />
                                        <div class="progress-bar bg-info" role="progressbar" style="width:${urinePct}%;"></div>
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
                <div class="dashboard-header-banner mb-4">
                    <div class="banner-overlay p-4 rounded shadow-sm text-white" style="background: linear-gradient(135deg, #007f61 0%, #005f48 100%);">
                        <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 align-items-lg-center">
                            <div>
                                <h4 class="fw-bold mb-1"><i class="bi bi-calendar3 me-2"></i> Lịch trực cá nhân</h4>
                                <p class="mb-0 text-white-50 small">Xem danh sách phân công lịch trực phòng xét nghiệm theo từng tuần.</p>
                            </div>
                            <div class="btn-group btn-group-sm">
                                <button type="button" class="btn btn-outline-success btn-sm" onclick="changeTimetableWeek(-1)" title="Tuần trước">
                                    <i class="bi bi-chevron-left"></i>
                                </button>
                                <button type="button" class="btn btn-outline-success btn-sm" onclick="changeTimetableWeek(1)" title="Tuần sau">
                                    <i class="bi bi-chevron-right"></i>
                                </button>
                            </div>
                        </div>
                    </div>
                    <div class="card-body p-2 bg-light-subtle">
                        <div class="table-responsive">
                            <table class="table table-bordered text-center align-middle m-0" style="width: 100%; border-color: #dee2e6; table-layout: fixed;">
                                <thead>
                                    <tr style="background: #edf7f3; color: #004d3a; border: none;">
                                        <th class="py-2" style="width: 12%; font-size: 0.85rem; background: transparent; color: #004d3a;">Ca làm việc</th>
                                        <th class="py-2" id="th-day-0" style="width: 12.57%; font-size: 0.8rem; background: transparent; color: #004d3a;">MON<br><span class="small" style="color:#5a9080;">27/07</span></th>
                                        <th class="py-2" id="th-day-1" style="width: 12.57%; font-size: 0.8rem; background: transparent; color: #004d3a;">TUE<br><span class="small" style="color:#5a9080;">28/07</span></th>
                                        <th class="py-2" id="th-day-2" style="width: 12.57%; font-size: 0.8rem; background: transparent; color: #004d3a;">WED<br><span class="small" style="color:#5a9080;">29/07</span></th>
                                        <th class="py-2" id="th-day-3" style="width: 12.57%; font-size: 0.8rem; background: transparent; color: #004d3a;">THU<br><span class="small" style="color:#5a9080;">30/07</span></th>
                                        <th class="py-2" id="th-day-4" style="width: 12.57%; font-size: 0.8rem; background: transparent; color: #004d3a;">FRI<br><span class="small" style="color:#5a9080;">31/07</span></th>
                                        <th class="py-2" id="th-day-5" style="width: 12.57%; font-size: 0.8rem; background: transparent; color: #004d3a;">SAT<br><span class="small" style="color:#5a9080;">01/08</span></th>
                                        <th class="py-2" id="th-day-6" style="width: 12.57%; font-size: 0.8rem; background: transparent; color: #004d3a;">SUN<br><span class="small" style="color:#5a9080;">02/08</span></th>
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
                    <div class="modal-header" style="background: linear-gradient(135deg, #e8f5f0 0%, #d4eee7 100%); border-bottom: 1px solid #b8dfd4;">
                        <h5 class="modal-title fw-bold" id="recordModalLabel${r.recordId}" style="color:#004d3a;">
                            <i class="bi bi-file-earmark-medical me-2" style="color:#007f61;"></i>Chi tiết kết quả xét nghiệm
                        </h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
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

    <!-- Modal Registration for Work Schedule -->
    <div class="modal fade" id="registerScheduleModal" tabindex="-1" aria-labelledby="registerScheduleModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content border-0 shadow">
                <div class="modal-header" style="background: linear-gradient(135deg, #e8f5f0 0%, #d4eee7 100%); border-bottom: 1px solid #b8dfd4;">
                    <h5 class="modal-title fw-bold" id="registerScheduleModalLabel" style="color:#004d3a;">
                        <i class="bi bi-calendar-plus-fill me-2" style="color:#007f61;"></i>Đăng ký lịch làm việc
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <form action="${pageContext.request.contextPath}/doctor-lab/dashboard" method="POST">
                    <input type="hidden" name="action" value="registerSchedule">
                    <div class="modal-body p-4">
                        <div class="mb-3">
                            <label for="workDate" class="form-label fw-bold text-dark">
                                <i class="bi bi-calendar-date text-success me-1"></i>Chọn ngày làm việc:
                            </label>
                            <input type="date" class="form-control" id="workDate" name="workDate" required value="2026-07-20">
                        </div>

                        <div class="mb-3">
                            <label for="timeSlot" class="form-label fw-bold text-dark">
                                <i class="bi bi-clock-history text-success me-1"></i>Chọn ca làm việc:
                            </label>
                            <select class="form-select" id="timeSlot" name="timeSlot" required>
                                <option value="Ca 1">Ca 1 (7:30 - 12:00)</option>
                                <option value="Ca 2">Ca 2 (13:30 - 16:30)</option>
                            </select>
                        </div>

                        <div class="mb-3">
                            <label for="roomId" class="form-label fw-bold text-dark">
                                <i class="bi bi-door-open text-success me-1"></i>Chọn phòng xét nghiệm:
                            </label>
                            <select class="form-select" id="roomId" name="roomId" required>
                                <option value="phòng xét nghiệm máu">Phòng xét nghiệm máu</option>
                                <option value="phòng xét nghiệm nước tiểu">Phòng xét nghiệm nước tiểu</option>
                            </select>
                        </div>
                    </div>
                    <div class="modal-footer bg-light">
                        <button type="button" class="btn btn-secondary px-3" data-bs-dismiss="modal">Hủy</button>
                        <button type="submit" class="btn btn-vinmec px-4 fw-bold">
                            <i class="bi bi-check-circle me-1"></i>Đăng ký ca làm
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script>
        const slotsConfig = {
            "Ca 1": { time: "7:30 - 12:00", label: "Ca 1" },
            "Ca 2": { time: "13:30 - 16:30", label: "Ca 2" }
        };

        const registeredDBSchedules = [
            <c:forEach var="s" items="${registeredSchedules}" varStatus="loop">
                { slotKey: "${s.slotKey}", dateStr: "${s.dateStr}", roomId: "${s.roomId}", type: "${s.type}", doctorName: "${s.doctorName}" }<c:if test="${!loop.last}">,</c:if>
            </c:forEach>
        ];

        const mockSchedules = registeredDBSchedules;

        let selectedYear = new Date().getFullYear();
        let selectedWeekIndex = 0;
        let currentYearWeeks = [];

        function getFirstMondayOfYear(year) {
            const jan1 = new Date(year, 0, 1);
            const day = jan1.getDay(); // 0: Sun, 1: Mon...
            const diff = (day === 0 ? -6 : 1 - day);
            const firstMon = new Date(jan1);
            firstMon.setDate(jan1.getDate() + diff);
            firstMon.setHours(0, 0, 0, 0);
            return firstMon;
        }

        function generateWeeksForYear(year) {
            const weeks = [];
            const firstMon = getFirstMondayOfYear(year);
            const formatDM = (d) => {
                const day = String(d.getDate()).padStart(2, '0');
                const month = String(d.getMonth() + 1).padStart(2, '0');
                return day + '/' + month;
            };

            for (let i = 0; i < 52; i++) {
                const mon = new Date(firstMon);
                mon.setDate(firstMon.getDate() + (i * 7));
                const sun = new Date(mon);
                sun.setDate(mon.getDate() + 6);

                const label = formatDM(mon) + ' To ' + formatDM(sun);
                const dateStrs = [];
                for (let d = 0; d < 7; d++) {
                    const dt = new Date(mon);
                    dt.setDate(mon.getDate() + d);
                    const y = dt.getFullYear();
                    const m = String(dt.getMonth() + 1).padStart(2, '0');
                    const dayNum = String(dt.getDate()).padStart(2, '0');
                    dateStrs.push(y + '-' + m + '-' + dayNum);
                }

                weeks.push({
                    index: i,
                    mon: mon,
                    sun: sun,
                    label: label,
                    dateStrs: dateStrs
                });
            }
            return weeks;
        }

        function initYearAndWeekDropdowns() {
            const yearDropdowns = [document.getElementById('yearSelectDropdown'), document.getElementById('yearSelectDropdownReg')];
            const weekDropdowns = [document.getElementById('weekSelectDropdown'), document.getElementById('weekSelectDropdownReg')];

            const realYear = new Date().getFullYear();
            yearDropdowns.forEach(yd => {
                if (yd) {
                    yd.innerHTML = '';
                    for (let y = realYear - 1; y <= realYear + 2; y++) {
                        const opt = document.createElement('option');
                        opt.value = y;
                        opt.textContent = y;
                        if (y === selectedYear) opt.selected = true;
                        yd.appendChild(opt);
                    }
                }
            });

            // Generate weeks for selectedYear
            currentYearWeeks = generateWeeksForYear(selectedYear);

            // Find default week (Next Week Monday)
            const today = new Date();
            const dayOfWeek = today.getDay();
            const daysUntilNextMon = dayOfWeek === 0 ? 1 : (8 - dayOfWeek);
            const nextMon = new Date(today);
            nextMon.setDate(today.getDate() + daysUntilNextMon);
            const nextMonStr = nextMon.getFullYear() + '-' + String(nextMon.getMonth() + 1).padStart(2, '0') + '-' + String(nextMon.getDate()).padStart(2, '0');

            let defaultIndex = 0;
            currentYearWeeks.forEach((w, idx) => {
                if (w.dateStrs[0] === nextMonStr) {
                    defaultIndex = idx;
                }
            });
            selectedWeekIndex = defaultIndex;

            weekDropdowns.forEach(wd => {
                if (wd) {
                    wd.innerHTML = '';
                    currentYearWeeks.forEach((w, idx) => {
                        const opt = document.createElement('option');
                        opt.value = idx;
                        opt.textContent = w.label;
                        wd.appendChild(opt);
                    });
                    wd.value = selectedWeekIndex;
                }
            });
        }

        function syncDropdownValues() {
            const yearDropdowns = [document.getElementById('yearSelectDropdown'), document.getElementById('yearSelectDropdownReg')];
            const weekDropdowns = [document.getElementById('weekSelectDropdown'), document.getElementById('weekSelectDropdownReg')];

            yearDropdowns.forEach(yd => { if (yd) yd.value = selectedYear; });
            weekDropdowns.forEach(wd => { if (wd) wd.value = selectedWeekIndex; });
        }

        function onYearDropdownChange(val) {
            selectedYear = parseInt(val, 10);
            currentYearWeeks = generateWeeksForYear(selectedYear);

            const weekDropdowns = [document.getElementById('weekSelectDropdown'), document.getElementById('weekSelectDropdownReg')];
            selectedWeekIndex = 0;

            weekDropdowns.forEach(wd => {
                if (wd) {
                    wd.innerHTML = '';
                    currentYearWeeks.forEach((w, idx) => {
                        const opt = document.createElement('option');
                        opt.value = idx;
                        opt.textContent = w.label;
                        wd.appendChild(opt);
                    });
                    wd.value = 0;
                }
            });
            syncDropdownValues();
            renderTimetableWeek();
        }

        function onWeekDropdownChange(val) {
            selectedWeekIndex = parseInt(val, 10);
            syncDropdownValues();
            renderTimetableWeek();
        }

        function changeTimetableWeek(delta) {
            let newIndex = selectedWeekIndex + delta;
            if (newIndex >= 0 && newIndex < currentYearWeeks.length) {
                selectedWeekIndex = newIndex;
                syncDropdownValues();
                renderTimetableWeek();
            } else if (newIndex < 0) {
                selectedYear--;
                onYearDropdownChange(selectedYear);
                selectedWeekIndex = currentYearWeeks.length - 1;
                syncDropdownValues();
                renderTimetableWeek();
            } else if (newIndex >= currentYearWeeks.length) {
                selectedYear++;
                onYearDropdownChange(selectedYear);
                selectedWeekIndex = 0;
                syncDropdownValues();
                renderTimetableWeek();
            }
        }

        const currentDoctorName = "${sessionScope.currentUser != null ? sessionScope.currentUser.fullName : ''}".trim().toLowerCase();

        function renderTimetableWeek() {
            if (!currentYearWeeks || currentYearWeeks.length === 0) {
                currentYearWeeks = generateWeeksForYear(selectedYear);
            }

            const currentWeek = currentYearWeeks[selectedWeekIndex] || currentYearWeeks[0];
            const targetWeekDateStrs = currentWeek.dateStrs;
            const dayNames = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"];

            // Update column headers for both tables
            for (let i = 0; i < 7; i++) {
                const dateParts = targetWeekDateStrs[i].split('-'); // YYYY-MM-DD
                const dt = dateParts[2];
                const m = dateParts[1];

                const thEl = document.getElementById('th-day-' + i);
                if (thEl) {
                    thEl.innerHTML = dayNames[i] + '<br><span class="small" style="color:#5a9080;">' + dt + '/' + m + '</span>';
                }
                const thRegEl = document.getElementById('th-reg-day-' + i);
                if (thRegEl) {
                    thRegEl.innerHTML = dayNames[i] + '<br><span class="small" style="color:#5a9080;">' + dt + '/' + m + '</span>';
                }
            }

            const slotKeys = ["Ca 1", "Ca 2"];

            // 1. Render Module 5: Lịch làm việc cá nhân của tôi (fap-timetable-body)
            const tbodyPersonal = document.getElementById("fap-timetable-body");
            if (tbodyPersonal) {
                tbodyPersonal.innerHTML = "";
                slotKeys.forEach(slotKey => {
                    const config = slotsConfig[slotKey];
                    const tr = document.createElement("tr");

                    const tdShift = document.createElement("td");
                    tdShift.className = "align-middle text-center p-2 bg-light";
                    tdShift.style.width = "12%";
                    tdShift.innerHTML = `
                        <div class="fw-bold text-dark mb-1" style="font-size: 0.92rem; color: #333;">\${config.label}</div>
                        <span class="badge px-2 py-1" style="background-color: #e6f6f3; color: #007f61; font-weight: 600; font-size: 0.8rem; border-radius: 10px; border: 1px solid #b2dfdb;">
                            \${config.time}
                        </span>
                    `;
                    tr.appendChild(tdShift);

                    for (let d = 0; d < 7; d++) {
                        const dateStr = targetWeekDateStrs[d];
                        const td = document.createElement("td");
                        td.className = "align-middle p-1";
                        td.style.width = "12.57%";
                        td.style.minHeight = "50px";

                        // Filter ONLY current doctor's registered schedules
                        const matches = mockSchedules.filter(s => s.dateStr === dateStr && s.slotKey === slotKey && (
                            !currentDoctorName || (s.doctorName && s.doctorName.trim().toLowerCase() === currentDoctorName)
                        ));

                        if (matches && matches.length > 0) {
                            td.innerHTML = "";
                            matches.forEach(match => {
                                let slotClass = match.type === "blood" ? "slot-blood_sugar" : "slot-urine_test";
                                let badgeStyle = match.type === "blood"
                                    ? "background-color: #fee2e2 !important; color: #b91c1c !important; border: 1px solid #fecaca !important;"
                                    : "background-color: #dbeafe !important; color: #1d4ed8 !important; border: 1px solid #bfdbfe !important;";
                                let iconClass = match.type === "blood" ? "bi-activity" : "bi-droplet";

                                const div = document.createElement("div");
                                div.className = `fap-card-slot \${slotClass} mb-1 p-1 rounded text-start shadow-sm`;
                                div.style.cssText = `border-left: 3px solid \${match.type === 'blood' ? '#dc2626' : '#2563eb'}; background-color: \${match.type === 'blood' ? '#fff5f5' : '#f0f9ff'};`;
                                div.innerHTML = `
                                    <div class="fw-bold text-dark d-flex align-items-center gap-1" style="font-size: 0.75rem; word-break: break-word;">
                                        <i class="bi bi-person-fill text-success" style="font-size: 0.82rem;"></i>
                                        <span>\${match.doctorName}</span>
                                    </div>
                                    <div class="text-secondary mt-0.5 small" style="font-size: 0.7rem;">
                                        <i class="bi \${iconClass} me-1"></i>\${match.roomId}
                                    </div>
                                    <div class="mt-0.5">
                                        <span class="badge px-1 py-0.5 font-monospace" style="font-size: 0.62rem; border-radius: 4px; \${badgeStyle}">
                                            \${config.label} (\${config.time})
                                        </span>
                                    </div>
                                `;
                                td.appendChild(div);
                            });
                        } else {
                            td.innerHTML = `<span class="text-muted small">-</span>`;
                        }
                        tr.appendChild(td);
                    }
                    tbodyPersonal.appendChild(tr);
                });
            }

            // 2. Render Module 6: Lịch làm việc chung của tất cả bác sĩ (reg-timetable-body)
            const tbodyAll = document.getElementById("reg-timetable-body");
            if (tbodyAll) {
                tbodyAll.innerHTML = "";
                slotKeys.forEach(slotKey => {
                    const config = slotsConfig[slotKey];
                    const tr = document.createElement("tr");

                    const tdShift = document.createElement("td");
                    tdShift.className = "align-middle text-center p-1.5 bg-light";
                    tdShift.style.width = "12%";
                    tdShift.innerHTML = `
                        <div class="fw-bold text-dark mb-0.5" style="font-size: 0.88rem; color: #333;">\${config.label}</div>
                        <span class="badge px-1.5 py-0.5" style="background-color: #e6f6f3; color: #007f61; font-weight: 600; font-size: 0.75rem; border-radius: 8px; border: 1px solid #b2dfdb;">
                            \${config.time}
                        </span>
                    `;
                    tr.appendChild(tdShift);

                    for (let d = 0; d < 7; d++) {
                        const dateStr = targetWeekDateStrs[d];
                        const td = document.createElement("td");
                        td.className = "align-middle p-1";
                        td.style.width = "12.57%";
                        td.style.minHeight = "50px";

                        // All registered schedules across ALL doctors
                        const matches = mockSchedules.filter(s => s.dateStr === dateStr && s.slotKey === slotKey);

                        if (matches && matches.length > 0) {
                            td.innerHTML = "";
                            matches.forEach(match => {
                                let slotClass = match.type === "blood" ? "slot-blood_sugar" : "slot-urine_test";
                                let badgeStyle = match.type === "blood"
                                    ? "background-color: #fee2e2 !important; color: #b91c1c !important; border: 1px solid #fecaca !important;"
                                    : "background-color: #dbeafe !important; color: #1d4ed8 !important; border: 1px solid #bfdbfe !important;";
                                let iconClass = match.type === "blood" ? "bi-activity" : "bi-droplet";

                                const div = document.createElement("div");
                                div.className = `fap-card-slot \${slotClass} mb-1 p-1 rounded text-start shadow-sm`;
                                div.style.cssText = `border-left: 3px solid \${match.type === 'blood' ? '#dc2626' : '#2563eb'}; background-color: \${match.type === 'blood' ? '#fff5f5' : '#f0f9ff'};`;
                                div.innerHTML = `
                                    <div class="fw-bold text-dark d-flex align-items-center gap-1" style="font-size: 0.75rem; word-break: break-word;">
                                        <i class="bi bi-person-fill text-success" style="font-size: 0.82rem;"></i>
                                        <span>\${match.doctorName}</span>
                                    </div>
                                    <div class="text-secondary mt-0.5 small" style="font-size: 0.7rem;">
                                        <i class="bi \${iconClass} me-1"></i>\${match.roomId}
                                    </div>
                                    <div class="mt-0.5">
                                        <span class="badge px-1 py-0.5 font-monospace" style="font-size: 0.62rem; border-radius: 4px; \${badgeStyle}">
                                            \${config.label} (\${config.time})
                                        </span>
                                    </div>
                                `;
                                td.appendChild(div);
                            });
                        } else {
                            td.innerHTML = `<span class="text-muted small">-</span>`;
                        }
                        tr.appendChild(td);
                    }
                    tbodyAll.appendChild(tr);
                });
            }
        }

        // ===== Vietnam phone real-time validator =====
        const VN_PHONE_RE = /^(03[2-9]|05[25689]|07[06-9]|08[1-9]|09[0-9])\d{7}$/;
        const VN_CARRIERS = {
            '03': 'Viettel', '086': 'Viettel', '096': 'Viettel', '097': 'Viettel', '098': 'Viettel',
            '07': 'Mobifone', '089': 'Mobifone', '090': 'Mobifone', '093': 'Mobifone',
            '081': 'Vinaphone', '082': 'Vinaphone', '083': 'Vinaphone',
            '084': 'Vinaphone', '085': 'Vinaphone', '088': 'Vinaphone', '091': 'Vinaphone', '094': 'Vinaphone',
            '052': 'Vietnamobile', '056': 'Vietnamobile', '058': 'Vietnamobile', '092': 'Vietnamobile',
            '055': 'Reddi', '059': 'Gmobile', '099': 'Gmobile'
        };
        function getCarrier(phone) {
            if (!phone || phone.length < 3) return null;
            return VN_CARRIERS[phone.substring(0,3)]
                || VN_CARRIERS[phone.substring(0,2)]
                || null;
        }
        function validateVnPhone(el) {
            const hint = document.getElementById('phoneHint');
            const val  = (el.value || '').trim();
            if (!val) {
                el.classList.remove('is-valid','is-invalid');
                if (hint) hint.innerHTML = '<span class="text-muted">Số điện thoại Việt Nam: 03x, 05x, 07x, 08x, 09x</span>';
                return;
            }
            if (VN_PHONE_RE.test(val)) {
                el.classList.add('is-valid'); el.classList.remove('is-invalid');
                const carrier = getCarrier(val);
                if (hint) hint.innerHTML = '<span class="text-success"><i class="bi bi-check-circle-fill me-1"></i>Hợp lệ'
                    + (carrier ? ' · Mạng: <strong>' + carrier + '</strong>' : '') + '</span>';
            } else {
                el.classList.add('is-invalid'); el.classList.remove('is-valid');
                let msg = 'Số không hợp lệ';
                if (val.length > 0 && !/^0/.test(val)) msg = 'Phải bắt đầu bằng số 0';
                else if (val.length > 0 && val.length < 10) msg = 'Cần đủ 10 chữ số (' + val.length + '/10)';
                else if (val.length === 10) msg = 'Đầu số không đúng (dùng: 03x, 05x, 07x, 08x, 09x)';
                else if (val.length > 10) msg = 'Quá 10 chữ số';
                if (hint) hint.innerHTML = '<span class="text-danger"><i class="bi bi-x-circle-fill me-1"></i>' + msg + '</span>';
            }
        }

        function validateProfileForm(event) {
            const nameEl = document.getElementById('profFullName');
            const phoneEl = document.getElementById('profPhone');
            const dobEl = document.getElementById('profDob');
            const addrEl = document.getElementById('profAddress');
            const jsAlert = document.getElementById('profJsAlert');

            if (jsAlert) {
                jsAlert.classList.add('d-none');
                jsAlert.innerHTML = '';
            }

            const name = nameEl ? nameEl.value.trim() : '';
            const phone = phoneEl ? phoneEl.value.trim() : '';
            const dob = dobEl ? dobEl.value.trim() : '';
            const addr = addrEl ? addrEl.value.trim() : '';

            if (!name) {
                if (jsAlert) { jsAlert.innerHTML = '<i class="bi bi-exclamation-circle-fill me-1"></i><strong>Vui lòng nhập Họ và tên bác sĩ!</strong>'; jsAlert.classList.remove('d-none'); }
                if (nameEl) nameEl.focus();
                if (event) event.preventDefault();
                return false;
            }

            // ---- Vietnam phone validation (2024 number plan) ----
            // Đầu số hợp lệ: 032-039, 086, 096-098 (Viettel)
            //                070, 076-079, 089, 090, 093 (Mobifone)
            //                081-085, 088, 091, 094 (Vinaphone)
            //                052, 055-056, 058, 092 (Vietnamobile/Reddi)
            //                059, 099 (Gmobile)
            const VN_PHONE_REGEX = /^(03[2-9]|05[25689]|07[06-9]|08[1-9]|09[0-9])\d{7}$/;

            if (!phone || !VN_PHONE_REGEX.test(phone)) {
                if (jsAlert) {
                    jsAlert.innerHTML = '<i class="bi bi-telephone-x-fill me-1"></i>'
                        + '<strong>Số điện thoại không hợp lệ!</strong> '
                        + 'Vui lòng nhập số điện thoại Việt Nam hợp lệ (10 số, bắt đầu bằng đầu số mạng: 03x, 05x, 07x, 08x, 09x).<br>'
                        + '<small class="text-muted">Ví dụ hợp lệ: 0987654321 (Viettel), 0912345678 (Vinaphone), 0765432109 (Mobifone)</small>';
                    jsAlert.classList.remove('d-none');
                }
                if (phoneEl) phoneEl.focus();
                if (event) event.preventDefault();
                return false;
            }

            if (!dob) {
                if (jsAlert) { jsAlert.innerHTML = '<i class="bi bi-exclamation-circle-fill me-1"></i><strong>Vui lòng chọn Ngày tháng năm sinh!</strong>'; jsAlert.classList.remove('d-none'); }
                if (dobEl) dobEl.focus();
                if (event) event.preventDefault();
                return false;
            }

            const bYear = new Date(dob).getFullYear();
            const cYear = new Date().getFullYear();
            if (isNaN(bYear) || (cYear - bYear < 18)) {
                if (jsAlert) { jsAlert.innerHTML = '<i class="bi bi-exclamation-circle-fill me-1"></i><strong>Ngày sinh không hợp lệ!</strong> Bác sĩ phải từ 18 tuổi trở lên.'; jsAlert.classList.remove('d-none'); }
                if (dobEl) dobEl.focus();
                if (event) event.preventDefault();
                return false;
            }

            if (!addr) {
                if (jsAlert) { jsAlert.innerHTML = '<i class="bi bi-exclamation-circle-fill me-1"></i><strong>Vui lòng nhập Địa chỉ liên hệ!</strong>'; jsAlert.classList.remove('d-none'); }
                if (addrEl) addrEl.focus();
                if (event) event.preventDefault();
                return false;
            }

            return true;
        }

        document.addEventListener('DOMContentLoaded', () => {
            // Initialize YEAR & WEEK dropdowns matching image layout
            initYearAndWeekDropdowns();

            // Set min date and default date in registration form
            const today = new Date();
            const dayOfWeek = today.getDay();
            const daysUntilNextMon = dayOfWeek === 0 ? 1 : (8 - dayOfWeek);
            const nextMon = new Date(today);
            nextMon.setDate(today.getDate() + daysUntilNextMon);
            const yearStr = nextMon.getFullYear();
            const monthStr = String(nextMon.getMonth() + 1).padStart(2, '0');
            const dayStr = String(nextMon.getDate()).padStart(2, '0');
            const nextMonStr = yearStr + '-' + monthStr + '-' + dayStr;

            const dateInput = document.getElementById('workDateMain');
            if (dateInput) {
                dateInput.min = nextMonStr;
                if (!dateInput.value || dateInput.value < nextMonStr) {
                    dateInput.value = nextMonStr;
                }
                dateInput.addEventListener('change', function() {
                    if (this.value < nextMonStr) {
                        const p = nextMonStr.split('-');
                        const formattedMin = p[2] + '/' + p[1] + '/' + p[0];
                        alert('Bác sĩ phải đăng ký lịch làm việc trước ít nhất 1 tuần!\nHạn chốt đăng ký tuần tới là 23:59 Chủ nhật tuần này.\nNgày làm việc sớm nhất có thể đăng ký: ' + formattedMin);
                        this.value = nextMonStr;
                    }
                });
            }

            // Check hash URL to open Schedule tab if redirected after login/action
            if (window.location.hash === '#pill-schedule') {
                const scheduleTab = document.getElementById('pill-schedule-tab');
                if (scheduleTab) {
                    const tabTrigger = new bootstrap.Tab(scheduleTab);
                    tabTrigger.show();
                }
            }

            // Initial render of timetable for target week
            renderTimetableWeek();

            <c:if test="${not isProfileComplete}">
            // Auto open edit profile modal if profile is incomplete
            const editModalEl = document.getElementById('editProfileModal');
            if (editModalEl) {
                const editModal = new bootstrap.Modal(editModalEl);
                editModal.show();
            }
            </c:if>
        });
    </script>


    <div class="modal fade" id="editProfileModal" tabindex="-1" aria-labelledby="editProfileModalLabel" aria-hidden="true" data-bs-backdrop="${isProfileComplete ? 'true' : 'static'}" data-bs-keyboard="${isProfileComplete ? 'true' : 'false'}">
        <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable">
            <form class="modal-content border-0 shadow-lg rounded-4 overflow-hidden" action="${pageContext.request.contextPath}/doctor-lab/dashboard" method="POST" accept-charset="UTF-8" onsubmit="return validateProfileForm(event)" style="max-height: 85vh; display: flex; flex-direction: column;">
                <input type="hidden" name="action" value="updateProfile">

                <!-- Modal Header -->
                <div class="modal-header text-white" style="background: linear-gradient(135deg, #007f61 0%, #005f48 100%); padding: 1.1rem 1.4rem; flex-shrink: 0;">
                    <div class="d-flex align-items-center gap-3">
                        <div style="width:42px;height:42px;border-radius:10px;background:rgba(0,127,97,0.12);display:flex;align-items:center;justify-content:center;font-size:1.2rem;color:#007f61;">
                            <i class="bi bi-person-gear"></i>
                        </div>
                        <div>
                            <h5 class="modal-title fw-bold mb-0" id="editProfileModalLabel" style="color:#004d3a;">Chỉnh sửa thông tin bác sĩ</h5>
                            <small style="color:#4a7a68;font-size:0.78rem;">Phòng Xét nghiệm – ${sessionScope.currentUser.fullName}</small>
                        </div>
                    </div>
                    <c:if test="${isProfileComplete}">
                        <button type="button" class="btn-close ms-auto" data-bs-dismiss="modal" aria-label="Close"></button>
                    </c:if>
                </div>

                <div class="modal-body" style="padding: 1.5rem; background: #f8fffe; overflow-y: auto; flex: 1 1 auto;">

                        <!-- JS validation alert -->
                        <div id="profJsAlert" class="alert alert-danger border-0 shadow-sm mb-3 py-2 px-3 small d-none" role="alert"></div>

                        <!-- Incomplete warning banner -->
                        <c:if test="${not isProfileComplete}">
                            <div class="alert alert-warning border-0 rounded-3 shadow-sm mb-3 py-1 px-3 small d-flex gap-2 align-items-start" role="alert">
                                <i class="bi bi-exclamation-triangle-fill text-warning mt-0" style="font-size:0.9rem;flex-shrink:0;"></i>
                                <div><strong>Tài khoản do Admin cấp:</strong> Vui lòng bổ sung
                                    (<span class="text-danger">*</span> Họ tên, SĐT, Ngày sinh &ge;18 tuổi, Giới tính, Địa chỉ) để kích hoạt tài khoản.
                                </div>
                            </div>
                        </c:if>

                        <!-- ── Section 1: Thông tin cơ bản ── -->
                        <div class="mb-2">
                            <p class="text-uppercase fw-bold small mb-2" style="color:#007f61;letter-spacing:.6px;font-size:0.7rem;">
                                <i class="bi bi-person-lines-fill me-1"></i>Thông tin cơ bản
                            </p>
                            <div class="row g-2">
                                <!-- Họ và tên -->
                                <div class="col-md-6">
                                    <label for="profFullName" class="form-label fw-semibold text-dark small mb-1">
                                        <i class="bi bi-person-fill text-success me-1"></i>Họ và tên bác sĩ <span class="text-danger">*</span>
                                    </label>
                                    <input type="text" class="form-control form-control-sm border-success-subtle fw-semibold"
                                           id="profFullName" name="fullName" required
                                           placeholder="Nhập họ và tên đầy đủ..."
                                           value="${doctorProfile.fullName}">
                                </div>

                                <!-- Số điện thoại -->
                                <div class="col-md-6">
                                    <label for="profPhone" class="form-label fw-semibold text-dark small mb-1">
                                        <i class="bi bi-telephone-fill text-success me-1"></i>Số điện thoại <span class="text-danger">*</span>
                                    </label>
                                    <input type="tel" class="form-control form-control-sm border-success-subtle fw-semibold"
                                           id="profPhone" name="phone" required
                                           pattern="^(03[2-9]|05[25689]|07[06-9]|08[1-9]|09[0-9])\d{7}$"
                                           title="Số điện thoại Việt Nam hợp lệ: 10 số, bắt đầu bằng 03x/05x/07x/08x/09x"
                                           placeholder="VD: 0987654321"
                                           oninput="validateVnPhone(this)"
                                           value="${doctorProfile.phone}">
                                    <div id="phoneHint" class="form-text" style="font-size:0.7rem;">
                                        <span class="text-muted">Số điện thoại Việt Nam: 03x, 05x, 07x, 08x, 09x</span>
                                    </div>
                                </div>

                                <!-- Ngày sinh -->
                                <div class="col-md-4">
                                    <label for="profDob" class="form-label fw-semibold text-dark small mb-1">
                                        <i class="bi bi-calendar-event text-success me-1"></i>Ngày sinh <span class="text-danger">*</span>
                                    </label>
                                    <input type="date" class="form-control form-control-sm border-success-subtle fw-semibold"
                                           id="profDob" name="dob" required
                                           max="${maxDobStr}"
                                           value="${doctorProfile.dob}">
                                    <span class="form-text text-muted" style="font-size:0.7rem;">Tuổi &ge; 18</span>
                                </div>

                                <!-- Giới tính -->
                                <div class="col-md-4">
                                    <label for="profGender" class="form-label fw-semibold text-dark small mb-1">
                                        <i class="bi bi-gender-ambiguous text-success me-1"></i>Giới tính <span class="text-danger">*</span>
                                    </label>
                                    <select class="form-select form-select-sm border-success-subtle fw-semibold" id="profGender" name="gender" required>
                                        <option value="Nam" ${doctorProfile.gender == 'Nam' || doctorProfile.gender == '' || empty doctorProfile.gender ? 'selected' : ''}>Nam</option>
                                        <option value="Nu" ${doctorProfile.gender == 'Nu' || doctorProfile.gender == 'Nữ' ? 'selected' : ''}>Nữ</option>
                                        <option value="Khac" ${doctorProfile.gender == 'Khac' || doctorProfile.gender == 'Khác' ? 'selected' : ''}>Khác</option>
                                    </select>
                                </div>

                                <!-- Địa chỉ -->
                                <div class="col-md-4">
                                    <label for="profAddress" class="form-label fw-semibold text-dark small mb-1">
                                        <i class="bi bi-geo-alt-fill text-success me-1"></i>Địa chỉ <span class="text-danger">*</span>
                                    </label>
                                    <input type="text" class="form-control form-control-sm border-success-subtle fw-semibold"
                                           id="profAddress" name="address" required
                                           placeholder="Hà Nội, Việt Nam"
                                           value="${doctorProfile.address}">
                                </div>
                            </div>
                        </div>

                        <hr class="my-3" style="border-color:#d4edda;">

                        <!-- ── Section 2: Thông tin tài khoản (readonly) ── -->
                        <div class="mb-2">
                            <p class="text-uppercase fw-bold small mb-2" style="color:#6c757d;letter-spacing:.6px;font-size:0.7rem;">
                                <i class="bi bi-shield-lock me-1"></i>Thông tin tài khoản (cố định)
                            </p>
                            <div class="row g-2">
                                <!-- Email (Readonly) -->
                                <div class="col-md-6">
                                    <label for="profEmail" class="form-label fw-semibold text-dark small mb-1">
                                        <i class="bi bi-envelope-fill text-secondary me-1"></i>Email đăng nhập
                                    </label>
                                    <input type="email" class="form-control form-control-sm bg-light text-secondary fw-bold border-secondary-subtle"
                                           id="profEmail" name="email" readonly
                                           value="${not empty doctorProfile.email ? doctorProfile.email : sessionScope.currentUser.email}">
                                    <span class="form-text text-muted" style="font-size:0.7rem;"><i class="bi bi-lock-fill me-1"></i>Do Admin khởi tạo – không thể thay đổi</span>
                                </div>

                                <!-- Bộ phận (Readonly) -->
                                <div class="col-md-6">
                                    <label for="profLabName" class="form-label fw-semibold text-dark small mb-1">
                                        <i class="bi bi-building-fill text-secondary me-1"></i>Bộ phận / Chuyên khoa
                                    </label>
                                    <input type="text" class="form-control form-control-sm bg-light text-secondary fw-bold border-secondary-subtle"
                                           id="profLabName" name="labName" readonly
                                           value="Phòng xét nghiệm">
                                    <span class="form-text text-muted" style="font-size:0.7rem;"><i class="bi bi-lock-fill me-1"></i>Đơn vị cố định</span>
                                </div>
                            </div>
                        </div>

                        <hr class="my-2" style="border-color:#d4edda;">

                        <!-- ── Section 3: Đổi mật khẩu ── -->
                        <div>
                            <p class="text-uppercase fw-bold small mb-2" style="color:#856404;letter-spacing:.6px;font-size:0.7rem;">
                                <i class="bi bi-key-fill me-1"></i>Bảo mật
                            </p>
                            <div class="col-md-8">
                                <label for="profNewPassword" class="form-label fw-semibold text-dark small mb-1">
                                    Đổi mật khẩu đăng nhập
                                    <span class="text-muted fw-normal">(bỏ trống = giữ nguyên)</span>
                                </label>
                                <div class="input-group input-group-sm">
                                    <span class="input-group-text bg-warning-subtle border-warning-subtle">
                                        <i class="bi bi-key-fill text-warning"></i>
                                    </span>
                                    <input type="password" class="form-control"
                                           id="profNewPassword" name="newPassword"
                                           placeholder="Nhập mật khẩu mới nếu muốn thay đổi...">
                                </div>
                                <span class="form-text text-muted" style="font-size:0.7rem;">Khuyến nghị đổi mật khẩu cá nhân mới để tăng bảo mật.</span>
                            </div>
                        </div>

                    </div><!-- /modal-body -->

                    <div class="modal-footer bg-white border-top d-flex justify-content-between align-items-center" style="padding: 1rem 1.5rem; flex-shrink: 0;">
                        <c:choose>
                            <c:when test="${isProfileComplete}">
                                <button type="button" class="btn btn-outline-secondary btn-sm px-4 fw-bold" data-bs-dismiss="modal">
                                    <i class="bi bi-x-circle me-1"></i>Hủy bỏ
                                </button>
                            </c:when>
                            <c:otherwise>
                                <a href="${pageContext.request.contextPath}/logout" class="btn btn-outline-danger btn-sm px-3 fw-bold" title="Đăng xuất khỏi hệ thống">
                                    <i class="bi bi-box-arrow-right me-1"></i>Đăng xuất
                                </a>
                            </c:otherwise>
                        </c:choose>
                        <button type="submit" id="btnSaveLabProfile" class="btn btn-success btn-sm px-4 fw-bold shadow-sm">
                            <i class="bi bi-check-circle-fill me-1"></i>Lưu thông tin & Kích hoạt
                        </button>
                    </div>
                </form>
            </div>
        </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
