<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<<<<<<< Updated upstream
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<fmt:setLocale value="vi_VN" />

<c:set var="currentAction" value="schedule" />

<%--
    Trang Quản lý lịch trực bác sĩ:
    - Lọc, xem tải ca trực theo bác sĩ/khoa/ngày
    - Tạo ca thủ công và hủy ca
    - Tích hợp modal AI lập lịch (Gemini + fallback)
--%>

<!DOCTYPE html>
<html lang="vi">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Quản lý Lịch trực Bác sĩ - S-COMS</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
        <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css" rel="stylesheet">

        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
        <link href="${pageContext.request.contextPath}/assets/css/pages/admin/admin-ui.css" rel="stylesheet">
        <style>
            .schedule-load-cell {
                min-width: 150px;
            }

            .schedule-load-wrap {
                display: grid;
                grid-template-columns: minmax(64px, 1fr) 48px 58px;
                align-items: center;
                column-gap: 0.35rem;
            }

            .schedule-load-progress {
                height: 10px;
                margin: 0;
            }

            .schedule-load-percent {
                min-width: 48px;
                text-align: center;
                font-weight: 600;
            }

            .schedule-table > :not(caption) > * > * {
                padding: 0.48rem 0.5rem;
            }

            .schedule-table thead th {
                white-space: normal;
                line-height: 1.2;
                font-size: 0.78rem;
            }

            .schedule-table td {
                font-size: 0.86rem;
                line-height: 1.3;
            }

            .schedule-table small,
            .schedule-list-table small {
                font-size: 0.76rem;
                line-height: 1.25;
            }
            .schedule-list-scroll {
                --schedule-row-height: 54px;
                --schedule-head-height: 38px;
                height: calc(var(--schedule-head-height) + (var(--schedule-row-height) * 10));
                max-height: calc(var(--schedule-head-height) + (var(--schedule-row-height) * 10));
                min-height: calc(var(--schedule-head-height) + (var(--schedule-row-height) * 10));
                overflow: auto;
                border-radius: 0;
            }

            .schedule-list-scroll.is-scroll-limited {
                overflow: auto;
            }

            #scheduleRoleTabContent,
            #scheduleRoleTabContent .schedule-role-pane {
                outline: none !important;
            }

            .schedule-pagination-footer {
                display: flex;
                align-items: center;
                justify-content: space-between;
                gap: 0.75rem;
                flex-wrap: wrap;
                padding: 0.8rem 0.95rem;
                border-top: 1px solid #dbe4f0;
                background: #fff;
                border-radius: 0 0 16px 16px;
            }

            .schedule-pagination-footer nav {
                max-width: 100%;
                overflow-x: auto;
                padding-bottom: 0.1rem;
            }

            .schedule-pagination-footer .pagination {
                margin-bottom: 0;
                flex-wrap: wrap;
                gap: 0.15rem;
            }

            .schedule-pagination-footer .page-link {
                padding: 0.32rem 0.48rem;
                line-height: 1.1;
            }

            .schedule-page-size-form {
                display: inline-flex;
                align-items: center;
                gap: 0.5rem;
            }

            .schedule-page-size-form .form-select {
                width: auto;
                min-width: 82px;
            }

            .schedule-list-scroll thead th {
                position: sticky;
                top: 0;
                z-index: 2;
                background: inherit;
                box-shadow: inset 0 -1px 0 rgba(0,0,0,0.15);
            }
            .schedule-list-table {
                width: 100%;
                min-width: 0;
                table-layout: fixed;
            }

            .schedule-list-table > :not(caption) > * > * {
                padding: 0.36rem 0.38rem;
                font-size: 0.8rem;
                line-height: 1.2;
            }

            .schedule-list-table th,
            .schedule-list-table td {
                vertical-align: middle;
                overflow-wrap: anywhere;
            }

            .schedule-list-table .badge {
                white-space: nowrap;
            }

            .schedule-list-table thead th {
                font-size: 0.76rem;
                line-height: 1.18;
                white-space: normal;
            }

            .schedule-table td div[style*="background-color"] {
                padding: 0.28rem 0.45rem !important;
                border-radius: 6px !important;
                min-width: 86px;
            }

            .schedule-table .progress {
                height: 8px;
            }

            .schedule-list-table .col-person {
                width: 108px;
            }

            .schedule-list-table .col-role {
                width: 108px;
            }

            .schedule-list-table .col-room {
                width: 72px;
            }

            .schedule-list-table .col-date {
                width: 82px;
            }

            .schedule-list-table .col-slot {
                width: 82px;
            }

            .schedule-list-table .col-load {
                width: 122px;
            }

            .schedule-list-table .col-quota {
                width: 112px;
            }

            .schedule-list-table .col-status {
                width: 106px;
            }

            .schedule-list-table .col-actions {
                width: 66px;
            }

            .schedule-list-table .col-location {
                width: 138px;
            }

            .schedule-list-table .col-source {
                width: 82px;
            }

            .schedule-list-table .col-actions {
                text-align: center;
            }

            .schedule-list-table .table-actions .btn {
                width: 34px;
                height: 34px;
                padding: 0;
                display: inline-flex;
                align-items: center;
                justify-content: center;
            }

            .schedule-list-table .progress {
                min-width: 56px;
            }

            .schedule-list-table .btn,
            .admin-page-header .btn,
            .card-body .btn {
                white-space: nowrap;
            }

            .schedule-filter-grid {
                display: grid;
                grid-template-columns: minmax(210px, 1fr) minmax(240px, 1.2fr) minmax(170px, 0.8fr) auto;
                gap: 0.9rem;
                align-items: end;
            }

            .schedule-filter-actions {
                display: flex;
                gap: 0.65rem;
                align-items: center;
                justify-content: flex-start;
                flex-wrap: nowrap;
            }

            .schedule-filter-actions .btn,
            .schedule-primary-action,
            .schedule-ai-action {
                min-height: 44px;
            }

            .schedule-filter-actions .btn {
                min-width: 90px;
                width: auto;
                padding-inline: 1rem;
            }

            .schedule-table-wrapper {
                max-width: 100%;
                overflow: auto;
                border-radius: 0;
                background: #fff;
            }

            .schedule-table-wrapper.is-scroll-limited {
                overflow: auto;
            }

            .staff-role-pane .schedule-table-wrapper {
                padding-bottom: 0;
            }

            .schedule-list-table thead tr {
                height: var(--schedule-head-height);
            }

            .schedule-list-table tbody tr {
                height: var(--schedule-row-height);
            }

            .schedule-list-table tbody td {
                height: var(--schedule-row-height);
                vertical-align: middle;
            }

            .schedule-list-table .dropdown-menu {
                z-index: 1080;
            }

            .schedule-table-doctor,
            .schedule-table-receptionist,
            .schedule-table-lab {
                min-width: 0;
            }

            .schedule-empty-state {
                display: flex;
                align-items: center;
                justify-content: center;
                gap: 0.75rem;
                min-height: calc(var(--schedule-row-height) * 10);
                padding: 1.2rem 1rem;
                color: #64748b;
            }

            .schedule-empty-icon {
                width: 40px;
                height: 40px;
                border-radius: 50%;
                display: inline-flex;
                align-items: center;
                justify-content: center;
                background: #eef7f5;
                color: #0f9f8f;
                flex: 0 0 auto;
            }

            .schedule-empty-title {
                font-weight: 800;
                color: #1f2a44;
                margin-bottom: 0.15rem;
            }

            .schedule-empty-description {
                margin: 0;
                font-size: 0.9rem;
            }

            .schedule-source-column {
                width: 82px;
            }

            @media (max-width: 1200px) {
                .schedule-source-column,
                .schedule-source-cell {
                    display: none;
                }
            }

            @media (max-width: 991.98px) {
                .schedule-filter-grid {
                    grid-template-columns: 1fr 1fr;
                }

                .schedule-filter-actions {
                    grid-column: 1 / -1;
                }
            }

            @media (max-width: 575.98px) {
                .schedule-filter-grid {
                    grid-template-columns: 1fr;
                }
            }

            .schedule-list-table .action-stack {
                display: flex;
                flex-direction: column;
                gap: 0.35rem;
                align-items: flex-start;
            }

            .schedule-list-table .action-stack .btn,
            .schedule-table .action-stack .btn {
                padding: 0.25rem 0.55rem;
                font-size: 0.82rem;
                line-height: 1.2;
                white-space: nowrap;
            }

            .schedule-list-table .badge,
            .schedule-table .badge {
                white-space: nowrap;
            }


            .text-purple {
                color: #6f42c1 !important;
            }

            .bg-purple-subtle {
                background: linear-gradient(135deg, rgba(111, 66, 193, 0.12), rgba(139, 92, 246, 0.18)) !important;
            }

            .ai-schedule-toolbar-btn {
                border: 1px solid rgba(111, 66, 193, 0.24);
                box-shadow: 0 8px 18px rgba(111, 66, 193, 0.10);
                transition: transform 0.18s ease, box-shadow 0.18s ease, border-color 0.18s ease;
            }

            .ai-schedule-toolbar-btn:hover,
            .ai-schedule-toolbar-btn:focus {
                color: #5b2fb0 !important;
                border-color: rgba(111, 66, 193, 0.42);
                transform: translateY(-1px);
                box-shadow: 0 12px 24px rgba(111, 66, 193, 0.16);
            }

            .ai-schedule-toolbar-btn:disabled {
                opacity: 0.78;
                transform: none;
                box-shadow: none;
            }

            .ai-schedule-loading {
                border: 1px solid rgba(111, 66, 193, 0.18);
                background: linear-gradient(135deg, rgba(111, 66, 193, 0.10), rgba(13, 202, 240, 0.10));
                color: #4b327f;
                border-radius: 16px;
                animation: ai-schedule-glow 1.25s ease-in-out infinite alternate;
            }

            @keyframes ai-schedule-glow {
                from {
                    box-shadow: 0 0 0 rgba(111, 66, 193, 0);
                }
                to {
                    box-shadow: 0 12px 28px rgba(111, 66, 193, 0.14);
                }
            }

            .ai-generated-row {
                background: linear-gradient(90deg, rgba(111, 66, 193, 0.08), rgba(13, 202, 240, 0.05));
                animation: ai-row-arrive 0.42s ease-out;
            }

            @keyframes ai-row-arrive {
                from {
                    opacity: 0;
                    transform: translateY(-8px);
                }
                to {
                    opacity: 1;
                    transform: translateY(0);
                }
            }

            .ai-schedule-badge {
                background: rgba(111, 66, 193, 0.12);
                color: #5b2fb0;
                border: 1px solid rgba(111, 66, 193, 0.22);
            }
.ai-step-banner,
            .ai-task-summary {
                border: 1px solid rgba(111, 66, 193, 0.16);
                background: #f8f7fc;
                border-radius: 14px;
            }

            .ai-section-number {
                display: inline-flex;
                width: 28px;
                height: 28px;
                align-items: center;
                justify-content: center;
                border-radius: 50%;
                background: #6f42c1;
                color: #fff;
                font-size: 0.8rem;
                margin-right: 0.55rem;
            }

            .weekday-options {
                display: grid;
                grid-template-columns: repeat(7, minmax(50px, 1fr));
                gap: 0.3rem;
            }

            #aiScheduleModal .modal-dialog {
                max-width: 540px;
            }

            #aiScheduleModal .modal-header {
                padding: 0.85rem 1.25rem;
                background: #f8f6fc;
                border-bottom: 1px solid #ebdffd;
            }

            #aiScheduleModal .modal-body {
                padding: 1.25rem;
                max-height: calc(100vh - 210px);
                overflow-y: auto;
            }

            #aiScheduleModal .modal-footer {
                position: sticky;
                bottom: 0;
                background: #ffffff;
                border-top: 1px solid #e2e8f0;
                padding: 0.85rem 1.25rem;
                z-index: 10;
                margin: 0;
                box-shadow: 0 -4px 12px rgba(0, 0, 0, 0.03);
            }

            #aiScheduleModal .modal-header h5 {
                margin-bottom: 0.15rem !important;
            }

            #aiScheduleModal .modal-header .small {
                font-size: 0.73rem;
            }

            #aiScheduleModal .modal-title {
                font-size: 1.05rem;
                font-weight: 600;
            }

            #aiScheduleModal .form-label {
                margin-bottom: 0.35rem;
                font-size: 0.82rem;
                font-weight: 600;
                color: #334155;
            }

            #aiScheduleModal .ai-section-number {
                width: 20px;
                height: 20px;
                font-size: 0.7rem;
                margin-right: 0.45rem;
                display: inline-flex;
                align-items: center;
                justify-content: center;
                background: #7c3aed;
                color: #fff;
                border-radius: 50%;
                font-weight: 700;
                flex-shrink: 0;
            }

            #aiScheduleModal .ai-section-label {
                font-size: 0.8rem;
                font-weight: 700;
                color: #5b2fb0;
                text-transform: uppercase;
                letter-spacing: .04em;
                display: flex;
                align-items: center;
                padding: 0.4rem 0;
                border-bottom: 2px solid #e9d5ff;
                margin-top: 0.85rem;
                margin-bottom: 0.85rem;
            }

            #aiScheduleModal .weekday-option label {
                padding: 0.38rem 0.35rem;
                border-radius: 8px;
                font-size: 0.78rem;
            }

            #aiScheduleModal .row {
                --bs-gutter-x: 0.75rem;
                --bs-gutter-y: 0.5rem;
                margin-right: calc(var(--bs-gutter-x) * -0.5) !important;
                margin-left: calc(var(--bs-gutter-x) * -0.5) !important;
            }

            #aiScheduleModal .col-md-4,
            #aiScheduleModal .col-md-6,
            #aiScheduleModal .col-12 {
                margin-bottom: 0.75rem;
            }

            #aiScheduleModal .form-control,
            #aiScheduleModal .form-select,
            #aiScheduleModal .input-group {
                font-size: 0.82rem;
            }

            #aiScheduleModal .template-preview {
                max-height: 80px;
                font-size: 0.78rem;
                resize: none;
            }

            #aiScheduleModal .ai-step-banner,
            #aiScheduleModal .ai-task-summary {
                background: #faf5ff !important;
                border: 1px solid #f3e8ff;
                border-radius: 10px;
                padding: 0.75rem 1rem !important;
                margin-top: 0.5rem;
                margin-bottom: 0.5rem !important;
                font-size: 0.82rem;
                color: #4c1d95;
            }

            #aiScheduleModal .ai-task-summary .fw-bold {
                font-size: 0.85rem;
                color: #6b21a8;
                margin-bottom: 0.25rem !important;
            }

            #aiScheduleModal .ai-task-summary div:last-child {
                font-size: 0.8rem;
                color: #5b21b6;
                line-height: 1.4;
            }

            #aiScheduleModal .btn {
                padding: 0.4rem 0.95rem;
                font-size: 0.85rem;
                font-weight: 600;
            }

            .cursor-pointer {
                cursor: pointer;
                user-select: none;
            }

            #aiDepartmentList .badge {
                cursor: pointer;
                transition: opacity 0.2s;
                font-size: 0.8rem;
                padding: 0.3rem 0.5rem;
            }

            #aiDepartmentList .badge:hover {
                opacity: 0.8;
            }

            #aiScheduleModal .input-group-sm > .btn {
                padding: 0.25rem 0.55rem;
                font-size: 0.85rem;
            }

            .weekday-option {
                position: relative;
            }

            .weekday-option input {
                position: absolute;
                opacity: 0;
                pointer-events: none;
            }

            .weekday-option label {
                display: block;
                padding: 0.4rem 0.3rem;
                border: 1px solid #cbd5e1;
                border-radius: 8px;
                background: #f8fafc;
                color: #64748b;
                text-align: center;
                cursor: pointer;
                transition: all 0.15s ease;
                font-size: 0.8rem;
                font-weight: 600;
                white-space: nowrap;
            }

            .weekday-option input:checked + label {
                border-color: #7c3aed;
                background: #7c3aed;
                color: #ffffff;
                font-weight: 700;
                box-shadow: 0 3px 8px rgba(124, 58, 237, 0.2);
            }

            .template-preview {
                max-height: 172px;
                resize: none;
                background: #fbfbfd;
            }

            .role-switch-card {
                border: 1px solid #dbe4f0;
                background: #fff;
                border-radius: 18px;
                padding: 0.85rem;
            }

            .role-switch-card .nav-pills {
                gap: 0.65rem;
            }

            .role-switch-card .nav-link {
                border: 1px solid #dbe4f0;
                color: #334155;
                border-radius: 14px;
                min-height: 58px;
                text-align: left;
                font-weight: 700;
                background: #f8fafc;
            }

            .role-switch-card .nav-link.active {
                background: #0f9f8f;
                border-color: #0f9f8f;
                color: #fff;
                box-shadow: 0 14px 28px rgba(15, 159, 143, 0.18);
            }

            .role-switch-card .nav-link small {
                display: block;
                font-weight: 500;
                opacity: 0.82;
                margin-top: 0.15rem;
            }

            .staff-role-pane .border {
                border-color: #dbe4f0 !important;
            }
            #scheduleRoleTabContent .schedule-role-pane {
                display: block;
                opacity: 1;
                visibility: visible;
            }

            #scheduleRoleTabContent .schedule-role-pane[hidden] {
                display: none !important;
            }
.staff-role-pane .card-header,
            #doctorRolePane .card-header {
                min-height: 68px;
                display: flex;
                align-items: center;
            }

            @media (max-width: 767.98px) {
                .weekday-options {
                    grid-template-columns: repeat(4, 1fr);
                }

                .schedule-list-scroll {
                    max-height: 640px;
                }

                #aiScheduleModal .modal-dialog {
                    max-width: calc(100% - 1rem);
                    margin: 0.5rem auto;
                }

                #aiScheduleModal .modal-title {
                    font-size: 1.1rem;
                }

                #aiScheduleModal .modal-body {
                    padding: 0.8rem;
                }
            /* Wizard Stepper Styling */
            .wizard-stepper {
                display: flex;
                justify-content: space-between;
                align-items: center;
                margin-bottom: 2rem;
                position: relative;
            }
            .wizard-step-indicator {
                display: flex;
                flex-direction: column;
                align-items: center;
                z-index: 2;
                background: #ffffff;
                padding: 0 10px;
                color: #cbd5e1;
                transition: color 0.3s ease;
            }
            .wizard-step-indicator.active {
                color: #7c3aed;
            }
            .wizard-step-indicator.completed {
                color: #10b981;
            }
            .wizard-step-indicator .step-num {
                width: 32px;
                height: 32px;
                border-radius: 50%;
                border: 2px solid #cbd5e1;
                display: flex;
                align-items: center;
                justify-content: center;
                font-weight: 700;
                font-size: 0.85rem;
                margin-bottom: 0.25rem;
                transition: all 0.3s ease;
                background: #ffffff;
            }
            .wizard-step-indicator.active .step-num {
                border-color: #7c3aed;
                background: #7c3aed;
                color: #ffffff;
            }
            .wizard-step-indicator.completed .step-num {
                border-color: #10b981;
                background: #10b981;
                color: #ffffff;
            }
            .wizard-step-indicator .step-label {
                font-size: 0.72rem;
                font-weight: 700;
                text-transform: uppercase;
                letter-spacing: 0.05em;
            }
            .ai-wizard-step {
                transition: all 0.25s ease-in-out;
            }
            /* Proposed schedules preview table */
            .proposed-table-container {
                max-height: 320px;
                overflow-y: auto;
                border: 1px solid #cbd5e1;
                border-radius: 12px;
                background: #ffffff;
            }
            .proposed-table {
                width: 100%;
                margin-bottom: 0;
            }
            .proposed-table th {
                background: #f8fafc;
                font-size: 0.75rem;
                font-weight: 700;
                color: #475569;
                position: sticky;
                top: 0;
                z-index: 10;
                box-shadow: inset 0 -1px 0 #e2e8f0;
            }
            .proposed-table td {
                font-size: 0.82rem;
                vertical-align: middle;
            }
            }

            /* Custom styled dropdown table actions */
            .table-actions .dropdown-menu {
                border: none;
                border-radius: 12px;
                box-shadow: 0 10px 30px rgba(124, 58, 237, 0.12), 0 1px 8px rgba(0, 0, 0, 0.05);
                padding: 6px;
                min-width: 160px;
                animation: fadeInDropdown 0.2s ease-out;
                z-index: 1050;
            }

            @keyframes fadeInDropdown {
                from {
                    opacity: 0;
                    transform: translateY(5px);
                }
                to {
                    opacity: 1;
                    transform: translateY(0);
                }
            }

            .table-actions .dropdown-item {
                border-radius: 8px;
                padding: 8px 12px;
                font-size: 0.85rem;
                font-weight: 550;
                color: #4b5563;
                display: flex;
                align-items: center;
                transition: all 0.2s ease;
                background: none;
                border: none;
                width: 100%;
                text-align: left;
            }

            .table-actions .dropdown-item i {
                font-size: 1rem;
                transition: transform 0.2s ease;
            }

            .table-actions .dropdown-item:hover {
                background-color: rgba(124, 58, 237, 0.08) !important;
                color: #7c3aed !important;
            }

            .table-actions .dropdown-item:hover i {
                transform: scale(1.15);
            }

            /* Icons colors for dropdown menu */
            .table-actions .dropdown-item i.bi-eye {
                color: #6366f1 !important; /* Indigo */
            }
            .table-actions .dropdown-item i.bi-pencil-square {
                color: #0ea5e9 !important; /* Sky Blue */
            }
            .table-actions .dropdown-item i.bi-arrow-left-right {
                color: #f59e0b !important; /* Amber */
            }
            .table-actions .dropdown-item.text-danger i.bi-trash,
            .table-actions .dropdown-item i.bi-trash {
                color: #ef4444 !important; /* Red */
            }
            .table-actions .dropdown-item.text-danger:hover {
                background-color: rgba(239, 68, 68, 0.08) !important;
                color: #ef4444 !important;
            }

            /* Beautiful circular trigger button */
            .table-actions button.btn-outline-secondary.rounded-circle {
                width: 32px;
                height: 32px;
                display: inline-flex;
                align-items: center;
                justify-content: center;
                padding: 0;
                border: 1px solid #e5e7eb;
                background-color: #ffffff;
                color: #4b5563;
                transition: all 0.2s ease;
            }

            .table-actions button.btn-outline-secondary.rounded-circle:hover,
            .table-actions button.btn-outline-secondary.rounded-circle[aria-expanded="true"] {
                background-color: #f3e8ff !important;
                border-color: #d8b4fe !important;
                color: #7c3aed !important;
                box-shadow: 0 4px 12px rgba(124, 58, 237, 0.15);
            }
        </style>
    </head>
    <body class="bg-light">
        <div class="container py-4">
            <div class="admin-layout row g-3">
                <div class="col-lg-3 admin-sidebar-col">
                    <%@ include file="/WEB-INF/views/components/admin/sidebar.jspf" %>
                </div>
                <div class="col-lg-9 admin-content-col">
                    <div class="admin-page-header schedule-page-header d-flex justify-content-between align-items-center mb-3">
                        <div>
                            <h3 class="mb-1">Quản lý lịch trực theo vai trò</h3>
                        </div>
                        <div class="d-flex gap-2">
                            <button type="button" id="aiScheduleGeminiBtn" class="btn bg-purple-subtle text-purple fw-bold ai-schedule-toolbar-btn schedule-ai-action" data-bs-toggle="modal" data-bs-target="#aiScheduleModal" aria-label="Lập lịch bằng AI">
                                <i class="fa-solid fa-brain me-2"></i>Lập lịch bằng AI
                            </button>
                            <button type="button" id="createScheduleToolbarBtn" class="btn btn-primary schedule-primary-action" data-bs-toggle="modal" data-bs-target="#createScheduleModal">Tạo ca bác sĩ</button>
                        </div>
                    </div>

                    <div class="role-switch-card schedule-role-tabs mb-3">
                        <ul class="nav nav-pills role-tabs" id="scheduleRoleTabs" role="tablist">
                            <li class="nav-item flex-fill" role="presentation">
                                <button class="nav-link active w-100 schedule-role-tab" id="doctor-role-tab" data-role-target="#doctorRolePane" type="button" role="tab">
                                    <i class="bi bi-heart-pulse me-2"></i>Bác sĩ khám
                                    <small>Lịch bác sĩ khám, suất đặt online và tải bệnh nhân</small>
                                </button>
                            </li>
                            <li class="nav-item flex-fill" role="presentation">
                                <button class="nav-link w-100 schedule-role-tab" id="receptionist-role-tab" data-role-target="#receptionistRolePane" type="button" role="tab">
                                    <i class="bi bi-person-badge me-2"></i>Lễ tân
                                    <small>Lịch nhân sự tại quầy tiếp nhận</small>
                                </button>
                            </li>
                            <li class="nav-item flex-fill" role="presentation">
                                <button class="nav-link w-100 schedule-role-tab" id="lab-role-tab" data-role-target="#labRolePane" type="button" role="tab">
                                    <i class="bi bi-clipboard2-pulse me-2"></i>Bác sĩ xét nghiệm
                                    <small>Lịch nhân sự tại phòng xét nghiệm</small>
                                </button>
                            </li>
                        </ul>
                    </div>

                    <!-- Modal chuyển giao ca trực (AJAX) -->
                    <div class="modal fade" id="transferScheduleModal" tabindex="-1" aria-hidden="true">
                        <div class="modal-dialog">
                            <div class="modal-content">
                                <div class="modal-header">
                                    <h5 class="modal-title">Chuyển giao ca trực</h5>
                                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                                </div>
                                <div class="modal-body">
                                    <div id="transferAlert" class="alert d-none" role="alert"></div>
                                    <div class="mb-3">
                                        <label class="form-label">Ca đang chọn</label>
                                        <div id="transferSelectedInfo" class="fw-semibold"></div>
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label">Chọn bác sĩ nhận ca</label>
                                        <select id="transferTargetDoctor" class="form-select"></select>
                                    </div>
                                </div>
                                <div class="modal-footer">
                                    <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Hủy</button>
                                    <button type="button" id="transferConfirmBtn" class="btn btn-primary">Xác nhận chuyển giao</button>
                                </div>
=======
    <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
        <%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
            <fmt:setLocale value="vi_VN" />

            <c:set var="currentAction" value="schedule" />

            <%-- Trang Quản lý lịch trực bác sĩ: - Lọc, xem tải ca trực theo bác sĩ/khoa/ngày - Tạo ca thủ công và hủy
                ca - Tích hợp modal AI lập lịch (Gemini + fallback) --%>

                <!DOCTYPE html>
                <html lang="vi">

                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <title>Quản lý Lịch trực Bác sĩ - S-COMS</title>
                    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css"
                        rel="stylesheet">
                    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css"
                        rel="stylesheet">

                    <link rel="stylesheet"
                        href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
                    <link href="${pageContext.request.contextPath}/assets/css/pages/admin/admin-ui.css"
                        rel="stylesheet">
                </head>

                <body class="bg-light">
                    <div class="container py-4">
                        <div class="admin-layout row g-3">
                            <div class="col-lg-3 admin-sidebar-col">
                                <%@ include file="/WEB-INF/views/components/admin/sidebar.jspf" %>
                            </div>
                            <div class="col-lg-9 admin-content-col">
                                <div class="admin-page-header schedule-page-header d-flex justify-content-between align-items-center mb-3">
                                    <div>
                                        <h3 class="mb-1">Quản lý lịch trực</h3>
                                    </div>
                                    <div class="d-flex gap-2">
                                        <!-- Dropdown Lập lịch thông minh -->
                                        <div class="custom-dropdown-container">
                                            <button type="button" class="btn text-white fw-bold shadow-sm" id="aiScheduleGeminiBtn" style="background: linear-gradient(135deg, #7c3aed, #6d28d9); border: 1px solid #6d28d9;">
                                                <i class="fa-solid fa-wand-magic-sparkles me-2"></i>✦ Lập lịch AI thông minh
                                            </button>
                                            <div class="custom-dropdown-menu-list shadow border-0" id="aiScheduleGeminiMenu">
                                                <a class="dropdown-item ai-universal-trigger py-2" href="#" data-bs-toggle="modal" data-bs-target="#aiScheduleModal" data-staff-type="Doctor"><i class="fa-solid fa-user-doctor me-2 text-teal"></i>Lập lịch Bác sĩ khám</a>
                                                <a class="dropdown-item ai-universal-trigger py-2" href="#" data-bs-toggle="modal" data-bs-target="#aiScheduleModal" data-staff-type="Receptionist"><i class="fa-solid fa-headset me-2 text-primary"></i>Lập lịch Lễ tân</a>
                                                <a class="dropdown-item ai-universal-trigger py-2" href="#" data-bs-toggle="modal" data-bs-target="#aiScheduleModal" data-staff-type="doctor_lab"><i class="fa-solid fa-flask-vial me-2 text-warning"></i>Lập lịch Bác sĩ xét nghiệm</a>
                                            </div>
                                        </div>
                                        <!-- Dropdown Tạo ca trực -->
                                        <div class="custom-dropdown-container">
                                            <button type="button" class="btn btn-primary fw-bold" id="createScheduleToolbarBtn">
                                                <i class="fa-solid fa-plus me-2"></i>Tạo ca trực
                                            </button>
                                            <div class="custom-dropdown-menu-list shadow border-0" id="createScheduleToolbarMenu">
                                                <a class="dropdown-item py-2" href="#" data-bs-toggle="modal" data-bs-target="#createScheduleModal"><i class="fa-solid fa-user-doctor me-2 text-teal"></i>Ca trực Bác sĩ khám</a>
                                                <a class="dropdown-item py-2" href="#" data-bs-toggle="modal" data-bs-target="#createReceptionistScheduleModal"><i class="fa-solid fa-headset me-2 text-primary"></i>Ca trực Lễ tân</a>
                                                <a class="dropdown-item py-2" href="#" data-bs-toggle="modal" data-bs-target="#createLabScheduleModal"><i class="fa-solid fa-flask-vial me-2 text-warning"></i>Ca trực Bác sĩ xét nghiệm</a>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div class="d-flex justify-content-between align-items-center mb-3 flex-wrap gap-3">
                                    <!-- View Switcher -->
                                    <div class="btn-group p-1 bg-white border rounded-pill shadow-sm" role="group" style="height: 42px; display: inline-flex; align-items: center;">
                                        <button type="button" id="viewModeCalendarBtn" class="btn btn-sm rounded-pill px-3 py-1 fw-bold text-white" style="font-size: 0.88rem; background-color: #7c3aed; transition: all 0.2s;">
                                            <i class="fa-solid fa-calendar-week me-1"></i>📅 Lịch theo tuần
                                        </button>
                                        <button type="button" id="viewModeListBtn" class="btn btn-sm rounded-pill px-3 py-1 fw-semibold text-secondary bg-transparent" style="font-size: 0.88rem; transition: all 0.2s;">
                                            <i class="fa-solid fa-list-check me-1"></i>📋 Danh sách chi tiết
                                        </button>
                                    </div>
                                </div>

                                <!-- Unified Filter Bar -->
                                <div class="card border-0 shadow-sm mb-3" style="border-radius: 16px;">
                                    <div class="card-body p-3">
                                        <form id="unifiedFilterForm" method="GET" action="${pageContext.request.contextPath}/admin" class="row g-2 align-items-center">
                                            <input type="hidden" name="action" value="schedule">
                                            <input type="hidden" id="selectedViewTab" name="viewTab" value="calendar">

                                            <!-- Vai trò -->
                                            <div class="col-md-2" id="unifiedRoleFilterContainer">
                                                <label class="form-label text-secondary small fw-bold mb-1">Vai trò</label>
                                                <select id="unifiedRoleFilter" name="roleFilter" class="form-select form-select-sm" style="border-radius: 8px;">
                                                    <option value="Doctor" selected>🩺 Bác sĩ khám</option>
                                                    <option value="Receptionist">🎧 Lễ tân</option>
                                                    <option value="doctor_lab">🧪 Bác sĩ xét nghiệm</option>
                                                    <option value="all">Tất cả vai trò</option>
                                                </select>
                                            </div>

                                            <!-- Chọn tuần / Ngày -->
                                            <div class="col-md-3" id="unifiedTimeFilterContainer">
                                                <label id="filterTimeLabel" class="form-label text-secondary small fw-bold mb-1">${param.viewTab == 'list' ? 'Chọn ngày' : 'Chọn tuần'}</label>

                                                <!-- Picker Tuần -->
                                                <div id="filterWeekPickerGroup" class="input-group input-group-sm flex-nowrap ${param.viewTab == 'list' ? 'd-none' : ''}" style="flex-wrap: nowrap !important; ${param.viewTab == 'list' ? 'display: none !important;' : 'display: flex !important;'}">
                                                    <button type="button" id="unifiedPrevWeekBtn" class="btn btn-outline-secondary px-2" title="Tuần trước" style="border-top-left-radius: 8px; border-bottom-left-radius: 8px;"><i class="fa-solid fa-chevron-left"></i></button>
                                                    <input type="date" id="unifiedWeekPicker" name="weekDate" class="form-control text-center px-1" style="font-size: 0.85rem;">
                                                    <button type="button" id="unifiedTodayBtn" class="btn btn-outline-secondary px-2 fw-semibold" style="font-size: 0.82rem; white-space: nowrap;" title="Hôm nay">Hôm nay</button>
                                                    <button type="button" id="unifiedNextWeekBtn" class="btn btn-outline-secondary px-2" title="Tuần sau" style="border-top-right-radius: 8px; border-bottom-right-radius: 8px;"><i class="fa-solid fa-chevron-right"></i></button>
                                                </div>

                                                <!-- Picker Ngày -->
                                                <input type="date" id="unifiedDatePicker" name="workDate" class="form-control form-control-sm ${param.viewTab == 'list' ? '' : 'd-none'} px-2" style="border-radius: 8px; font-size: 0.88rem; ${param.viewTab == 'list' ? 'display: block !important;' : 'display: none !important;'}">
                                            </div>

                                            <!-- Phòng / Chuyên khoa -->
                                            <div class="col-md-3" id="unifiedRoomFilterContainer">
                                                <label class="form-label text-secondary small fw-bold mb-1">Phòng / Chuyên khoa</label>
                                                <select id="unifiedRoomFilter" name="roomId" class="form-select form-select-sm" style="border-radius: 8px;">
                                                    <option value="all" selected>Tất cả phòng / khoa</option>
                                                    <c:forEach var="r" items="${rooms}">
                                                        <option value="room_${r.roomId}">${r.roomName} (${r.roomId})</option>
                                                    </c:forEach>
                                                </select>
                                            </div>

                                            <!-- Tìm kiếm -->
                                            <div class="col-md-3">
                                                <label class="form-label text-secondary small fw-bold mb-1">Tìm kiếm nhân sự</label>
                                                <div class="input-group input-group-sm">
                                                    <span class="input-group-text bg-white border-end-0" style="border-top-left-radius: 8px; border-bottom-left-radius: 8px;"><i class="fa-solid fa-magnifying-glass text-muted"></i></span>
                                                    <input type="text" id="unifiedSearchInput" name="search" class="form-control border-start-0" placeholder="Tên nhân sự..." value="${param.search}" style="border-top-right-radius: 8px; border-bottom-right-radius: 8px;">
                                                </div>
                                            </div>

                                            <!-- Nút Lọc & Reset -->
                                            <div class="col-md-1 d-flex align-items-end gap-1" style="margin-top: 24px;">
                                                <button type="submit" class="btn btn-sm text-white fw-bold w-100 py-1" style="background-color: #0d9488; border-radius: 8px;" title="Áp dụng bộ lọc">
                                                    <i class="fa-solid fa-filter"></i>
                                                </button>
                                                <button type="button" id="unifiedFilterResetBtn" class="btn btn-sm btn-outline-secondary py-1" style="border-radius: 8px;" title="Đặt lại">
                                                    <i class="fa-solid fa-rotate-left"></i>
                                                </button>
                                            </div>
                                        </form>
                                    </div>
                                </div>

                                <div class="tab-content" id="scheduleRoleTabContent">
                                    <!-- Detailed List Pane (Danh sách chi tiết) -->
                                    <div class="schedule-role-pane" id="detailedListPane" style="display: none;">
                                        <!-- Bộ 3 Tab Role chuyên nghiệp 1-Click cho chế độ Danh sách chi tiết -->
                                        <div id="detailedListRoleSwitch" class="card border-0 shadow-sm p-2 mb-3 bg-white" style="border-radius: 12px;">
                                            <div class="d-flex align-items-center justify-content-between flex-wrap gap-2">
                                                <span class="fw-bold text-dark small ms-2"><i class="fa-solid fa-users-gear me-2 text-primary"></i>Chọn vai trò nhân sự:</span>
                                                <div class="btn-group p-1 bg-light rounded-pill border" role="group">
                                                    <button type="button" class="btn btn-sm rounded-pill px-3 py-1 fw-bold detailed-role-tab active text-white bg-primary" data-role="Doctor" style="font-size: 0.86rem; transition: all 0.2s;">
                                                        <i class="fa-solid fa-user-doctor me-1"></i>🩺 Bác sĩ khám
                                                    </button>
                                                    <button type="button" class="btn btn-sm rounded-pill px-3 py-1 fw-semibold text-secondary bg-transparent detailed-role-tab" data-role="Receptionist" style="font-size: 0.86rem; transition: all 0.2s;">
                                                        <i class="fa-solid fa-headset me-1"></i>🎧 Lễ tân
                                                    </button>
                                                    <button type="button" class="btn btn-sm rounded-pill px-3 py-1 fw-semibold text-secondary bg-transparent detailed-role-tab" data-role="doctor_lab" style="font-size: 0.86rem; transition: all 0.2s;">
                                                        <i class="fa-solid fa-flask-vial me-1"></i>🧪 Bác sĩ xét nghiệm
                                                    </button>
                                                </div>
                                            </div>
                                        </div>

                                        <%@ include file="/WEB-INF/views/admin/scheduling/includes/doctor-role-pane.jsp" %>
                                        <%@ include file="/WEB-INF/views/admin/scheduling/includes/receptionist-role-pane.jsp" %>
                                        <%@ include file="/WEB-INF/views/admin/scheduling/includes/lab-role-pane.jsp" %>
                                    </div>

                                    <!-- Weekly Calendar Pane (Lịch theo tuần) -->
                                    <div class="schedule-role-pane" id="weeklyCalendarPane">
                                        <!-- Alert Cảnh báo xung đột nếu có -->
                                        <div id="calendarConflictAlert"
                                            class="alert alert-danger d-none mb-3 py-2 px-3 align-items-center justify-content-between flex-wrap gap-2"
                                            style="border-radius: 12px;">
                                            <div class="d-flex align-items-center gap-2">
                                                <i class="bi bi-exclamation-triangle-fill fs-5 text-danger me-1"></i>
                                                <span id="calendarConflictSummaryText" class="fw-semibold">Phát hiện xung đột trùng ca hoặc trùng phòng làm việc! Thẻ bị trùng đang được khoanh viền đỏ ⚠</span>
                                            </div>
                                            <button type="button" class="btn btn-sm btn-danger fw-bold px-3 py-1" onclick="openResolveConflictModal()" style="border-radius: 8px;">
                                                <i class="fa-solid fa-wand-magic-sparkles me-1"></i>Tháo gỡ xung đột
                                            </button>
                                        </div>

                                        <!-- Weekly Grid Calendar -->
                                        <div class="card border-0 shadow-sm mb-4"
                                            style="border-radius: 16px; overflow: hidden;">
                                            <div class="table-responsive">
                                                <table class="table table-bordered align-middle text-center mb-0 calendar-table">
                                                    <thead class="table-light">
                                                        <tr id="calendarWeekHeadRow">
                                                            <th style="width: 120px;" class="bg-light align-middle">Ca / Giờ</th>
                                                            <th class="cal-head-col" data-day="1">Thứ 2<br><small class="text-muted fw-normal" id="date-head-mon">-</small></th>
                                                            <th class="cal-head-col" data-day="2">Thứ 3<br><small class="text-muted fw-normal" id="date-head-tue">-</small></th>
                                                            <th class="cal-head-col" data-day="3">Thứ 4<br><small class="text-muted fw-normal" id="date-head-wed">-</small></th>
                                                            <th class="cal-head-col" data-day="4">Thứ 5<br><small class="text-muted fw-normal" id="date-head-thu">-</small></th>
                                                            <th class="cal-head-col" data-day="5">Thứ 6<br><small class="text-muted fw-normal" id="date-head-fri">-</small></th>
                                                            <th class="cal-head-col" data-day="6">Thứ 7<br><small class="text-muted fw-normal" id="date-head-sat">-</small></th>
                                                            <th class="cal-head-col" data-day="0">Chủ nhật<br><small class="text-muted fw-normal" id="date-head-sun">-</small></th>
                                                        </tr>
                                                    </thead>
                                                    <tbody>
                                                        <tr>
                                                            <td class="bg-light text-primary fw-bold text-center align-middle">
                                                                <i class="bi bi-sun fs-5 d-block mb-1 text-warning"></i>
                                                                Sáng<br><small class="text-muted fw-normal">07:00 - 11:30</small>
                                                            </td>
                                                            <td class="cal-cell" id="cell-mon-0800"></td>
                                                            <td class="cal-cell" id="cell-tue-0800"></td>
                                                            <td class="cal-cell" id="cell-wed-0800"></td>
                                                            <td class="cal-cell" id="cell-thu-0800"></td>
                                                            <td class="cal-cell" id="cell-fri-0800"></td>
                                                            <td class="cal-cell" id="cell-sat-0800"></td>
                                                            <td class="cal-cell" id="cell-sun-0800"></td>
                                                        </tr>
                                                        <tr>
                                                            <td class="bg-light text-warning fw-bold text-center align-middle">
                                                                <i class="bi bi-sunset fs-5 d-block mb-1 text-primary"></i>
                                                                Chiều<br><small class="text-muted fw-normal">13:30 - 17:30</small>
                                                            </td>
                                                            <td class="cal-cell" id="cell-mon-1300"></td>
                                                            <td class="cal-cell" id="cell-tue-1300"></td>
                                                            <td class="cal-cell" id="cell-wed-1300"></td>
                                                            <td class="cal-cell" id="cell-thu-1300"></td>
                                                            <td class="cal-cell" id="cell-fri-1300"></td>
                                                            <td class="cal-cell" id="cell-sat-1300"></td>
                                                            <td class="cal-cell" id="cell-sun-1300"></td>
                                                        </tr>
                                                    </tbody>
                                                </table>
                                            </div>
                                        </div>
                                    </div>
                                </div><!-- /.tab-content -->

                                <!-- Modal Chuyển giao ca trực -->
                                <div class="modal fade" id="transferScheduleModal" tabindex="-1" aria-hidden="true">
                                    <div class="modal-dialog">
                                        <div class="modal-content">
                                            <div class="modal-header">
                                                <h5 class="modal-title">Chuyển giao ca trực</h5>
                                                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                                            </div>
                                            <div class="modal-body">
                                                <div id="transferAlert" class="alert d-none" role="alert"></div>
                                                <div class="mb-3">
                                                    <label class="form-label">Ca đang chọn</label>
                                                    <div id="transferSelectedInfo" class="fw-semibold"></div>
                                                </div>
                                                <div class="mb-3">
                                                    <label class="form-label">Chọn bác sĩ nhận ca</label>
                                                    <select id="transferTargetDoctor" class="form-select"></select>
                                                </div>
                                            </div>
                                            <div class="modal-footer">
                                                <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Hủy</button>
                                                <button type="button" id="transferConfirmBtn" class="btn btn-primary">Xác nhận chuyển giao</button>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <c:if test="${not empty sessionScope.successMessage}">
                                    <div class="alert alert-success">${sessionScope.successMessage}</div>
                                    <% session.removeAttribute("successMessage"); %>
                                </c:if>
                                <c:if test="${not empty sessionScope.errorMessage}">
                                    <div class="alert alert-danger">${sessionScope.errorMessage}</div>
                                    <% session.removeAttribute("errorMessage"); %>
                                </c:if>

                                <div id="aiScheduleLoading" class="alert ai-schedule-loading d-none align-items-center gap-2 mb-3">
                                    <span class="spinner-grow spinner-grow-sm text-purple" aria-hidden="true"></span>
                                    <span class="fw-semibold">AI đang phân tích dữ liệu hiệu suất và tự động phân bổ ca trực...</span>
                                    <span id="aiScheduleLoadingDetail" class="small text-muted ms-2"></span>
                                </div>

                                <%@ include file="/WEB-INF/views/admin/scheduling/includes/schedule-modals.jsp" %>

>>>>>>> Stashed changes
                            </div>
                        </div>
                    </div>

<<<<<<< Updated upstream
            <c:if test="${not empty sessionScope.successMessage}">
                <div class="alert alert-success">${sessionScope.successMessage}</div>
                <% session.removeAttribute("successMessage"); %>
            </c:if>
            <c:if test="${not empty sessionScope.errorMessage}">
                <div class="alert alert-danger">${sessionScope.errorMessage}</div>
                <% session.removeAttribute("errorMessage"); %>
            </c:if>
=======
                        document.addEventListener('DOMContentLoaded', function () {
                            // Logic Toggle Custom Dropdowns
                            (function() {
                                function initCustomDropdown(btnId, menuId) {
                                    const btn = document.getElementById(btnId);
                                    const menu = document.getElementById(menuId);
                                    if (!btn || !menu) return;
                                    btn.addEventListener('click', function(e) {
                                        e.stopPropagation();
                                        // Ẩn dropdown kia nếu đang mở
                                        const otherMenuId = btnId === 'aiScheduleGeminiBtn' ? 'createScheduleToolbarMenu' : 'aiScheduleGeminiMenu';
                                        const otherMenu = document.getElementById(otherMenuId);
                                        if (otherMenu) otherMenu.classList.remove('show');
                                        
                                        menu.classList.toggle('show');
                                    });
                                }
                                initCustomDropdown('aiScheduleGeminiBtn', 'aiScheduleGeminiMenu');
                                initCustomDropdown('createScheduleToolbarBtn', 'createScheduleToolbarMenu');

                                document.addEventListener('click', function() {
                                    const m1 = document.getElementById('aiScheduleGeminiMenu');
                                    const m2 = document.getElementById('createScheduleToolbarMenu');
                                    if (m1) m1.classList.remove('show');
                                    if (m2) m2.classList.remove('show');
                                });

                                const menus = ['aiScheduleGeminiMenu', 'createScheduleToolbarMenu'];
                                menus.forEach(id => {
                                    const el = document.getElementById(id);
                                    if (el) {
                                        el.addEventListener('click', function(e) {
                                            if (e.target.closest('.dropdown-item')) {
                                                el.classList.remove('show');
                                            } else {
                                                e.stopPropagation();
                                            }
                                        });
                                    }
                                });
                            })();

                            var roleTabs = Array.prototype.slice.call(document.querySelectorAll('#scheduleRoleTabs [data-role-target]'));
                            var tabByHash = {
                                '#doctorRolePane': '#doctor-role-tab',
                                '#receptionistRolePane': '#receptionist-role-tab',
                                '#labRolePane': '#lab-role-tab'
                            };
>>>>>>> Stashed changes

            <div id="aiScheduleLoading" class="alert ai-schedule-loading d-none align-items-center gap-2 mb-3">
                <span class="spinner-grow spinner-grow-sm text-purple" aria-hidden="true"></span>
                <span class="fw-semibold">AI đang phân tích dữ liệu hiệu suất và tự động phân bổ ca trực...</span><span id="aiScheduleLoadingDetail" class="small text-muted ms-2"></span>
            </div>

            <div class="tab-content" id="scheduleRoleTabContent">
                  <%@ include file="/WEB-INF/views/admin/scheduling/includes/doctor-role-pane.jsp" %>
                  <%@ include file="/WEB-INF/views/admin/scheduling/includes/receptionist-role-pane.jsp" %>
                  <%@ include file="/WEB-INF/views/admin/scheduling/includes/lab-role-pane.jsp" %>
               </div>
               <%@ include file="/WEB-INF/views/admin/scheduling/includes/schedule-modals.jsp" %>
                    </div>
                </div>
            </div>
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
        <script>
    window.AdminConfig = window.AdminConfig || {};
    window.AdminConfig.contextPath = '${pageContext.request.contextPath}';
    window.AdminConfig.csrfToken = '${sessionScope.csrfToken}';
    window.AdminConfig.adminEndpoint = '${pageContext.request.contextPath}/admin';
    window.AdminConfig.loginUrl = '${pageContext.request.contextPath}/login.jsp';

    document.addEventListener('DOMContentLoaded', function () {
        var roleTabs = Array.prototype.slice.call(document.querySelectorAll('#scheduleRoleTabs [data-role-target]'));
        var tabByHash = {
            '#doctorRolePane': '#doctor-role-tab',
            '#receptionistRolePane': '#receptionist-role-tab',
            '#labRolePane': '#lab-role-tab'
        };

<<<<<<< Updated upstream
        function resolveInitialTab() {
            if (tabByHash[window.location.hash]) {
                return document.querySelector(tabByHash[window.location.hash]);
            }
            if (window.location.search.indexOf('staffType=Receptionist') !== -1) {
                return document.getElementById('receptionist-role-tab');
            }
            if (window.location.search.indexOf('staffType=doctor_lab') !== -1) {
                return document.getElementById('lab-role-tab');
            }
            return document.querySelector('#scheduleRoleTabs .nav-link.active') || document.getElementById('doctor-role-tab');
        }

        function forceSchedulePane(trigger) {
            if (!trigger) return;
            var targetSelector = trigger.getAttribute('data-role-target');
            var targetPane = targetSelector ? document.querySelector(targetSelector) : null;
            if (!targetPane) return;

            roleTabs.forEach(function (tab) {
                var isTarget = tab === trigger;
                tab.classList.toggle('active', isTarget);
                tab.setAttribute('aria-selected', isTarget ? 'true' : 'false');
            });
            document.querySelectorAll('#scheduleRoleTabContent .schedule-role-pane').forEach(function (pane) {
                var isTarget = pane === targetPane;
                pane.hidden = !isTarget;
                pane.style.display = isTarget ? 'block' : 'none';
                pane.classList.toggle('is-visible', isTarget);
                pane.classList.toggle('active', isTarget);
                pane.classList.toggle('show', isTarget);
            });

            if (window.history && window.history.replaceState) {
                window.history.replaceState(null, '', window.location.pathname + window.location.search + targetSelector);
            }
        }
        function updateScheduleToolbar() {
            var activePane = document.querySelector('#scheduleRoleTabContent .schedule-role-pane.is-visible');
            var aiBtn = document.getElementById('aiScheduleGeminiBtn');
            var createBtn = document.getElementById('createScheduleToolbarBtn');
            if (!activePane || !aiBtn || !createBtn) {
                return;
            }
            var config = {
                doctorRolePane: {
                    aiLabel: '<i class="fa-solid fa-brain me-2"></i>Lập lịch bác sĩ bằng AI',
                    aiTarget: '#aiScheduleModal',
                    createLabel: 'Tạo ca bác sĩ',
                    createTarget: '#createScheduleModal'
                },
                receptionistRolePane: {
                    aiLabel: '<i class="fa-solid fa-brain me-2"></i>Lập lịch lễ tân bằng AI',
                    aiTarget: '#aiReceptionistScheduleModal',
                    createLabel: 'Tạo ca lễ tân',
                    createTarget: '#createReceptionistScheduleModal'
                },
                labRolePane: {
                    aiLabel: '<i class="fa-solid fa-brain me-2"></i>Lập lịch xét nghiệm bằng AI',
                    aiTarget: '#aiLabScheduleModal',
                    createLabel: 'Tạo ca bác sĩ xét nghiệm',
                    createTarget: '#createLabScheduleModal'
                }
            }[activePane.id];
            if (!config) return;
            aiBtn.innerHTML = config.aiLabel;
            aiBtn.setAttribute('data-bs-target', config.aiTarget);
            aiBtn.setAttribute('aria-label', aiBtn.textContent.trim());
            createBtn.textContent = config.createLabel;
            createBtn.setAttribute('data-bs-target', config.createTarget);
        }

        function limitScheduleTablesToTenRows() {
            document.querySelectorAll('.schedule-list-scroll').forEach(function (wrap) {
                wrap.style.removeProperty('max-height');
                wrap.style.removeProperty('height');
                wrap.style.removeProperty('overflow');
                wrap.classList.add('is-scroll-limited');
            });
        }

        forceSchedulePane(resolveInitialTab());
        updateScheduleToolbar();
        limitScheduleTablesToTenRows();
        roleTabs.forEach(function (tab) {
            tab.addEventListener('click', function () {
                forceSchedulePane(tab);
                updateScheduleToolbar();
                limitScheduleTablesToTenRows();
            });
        });
        window.addEventListener('resize', limitScheduleTablesToTenRows);

        // Receptionist AI Scheduling Modal Logic
        const recModal = document.getElementById('aiReceptionistScheduleModal');
        if (recModal) {
            const startDate = recModal.querySelector('[name="startDate"]');
            const endDate = recModal.querySelector('[name="endDate"]');
            const department = recModal.querySelector('[name="department"]');
            const workArea = recModal.querySelector('[name="workArea"]');
            const staffPerShift = recModal.querySelector('[name="staffPerShift"]');
            const maxWorkload = recModal.querySelector('[name="maxWorkload"]');
            const checkboxes = recModal.querySelectorAll('.receptionist-ai-shift-cb');
            const previewBox = document.getElementById('receptionistAiPreviewBox');
            const submitBtn = recModal.querySelector('button[type="submit"]');
            const hiddenTemplates = document.getElementById('receptionistAiShiftTemplates');

            // Set default dates
            const todayStr = new Date().toISOString().slice(0, 10);
            const nextWeek = new Date();
            nextWeek.setDate(nextWeek.getDate() + 7);
            const nextWeekStr = nextWeek.toISOString().slice(0, 10);
            
            if (startDate && !startDate.value) startDate.value = todayStr;
            if (endDate && !endDate.value) endDate.value = nextWeekStr;

            function updatePreview() {
                if (!startDate || !endDate || !department || !workArea || !staffPerShift || !previewBox || !submitBtn || !hiddenTemplates) return;

                const startVal = startDate.value;
                const endVal = endDate.value;
                const deptVal = department.value.trim();
                const areaVal = workArea.value.trim();
                const staffVal = parseInt(staffPerShift.value, 10) || 1;
                const maxWorkVal = maxWorkload.value ? parseInt(maxWorkload.value, 10) : 0;

                const checkedShifts = Array.from(checkboxes).filter(cb => cb.checked).map(cb => cb.value);

                // Validation rules
                const isDatesValid = startVal && endVal && startVal <= endVal;
                const isDeptValid = deptVal !== '';
                const isAreaValid = true;
                const isStaffValid = staffVal >= 1;
                const isShiftsValid = checkedShifts.length > 0;

                const isValid = isDatesValid && isDeptValid && isAreaValid && isStaffValid && isShiftsValid;

                if (isValid) {
                    submitBtn.removeAttribute('disabled');

                    // Calculate number of days
                    const startD = new Date(startVal);
                    const endD = new Date(endVal);
                    const diffTime = Math.abs(endD - startD);
                    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1;

                    // Compute total shifts to create
                    const totalShifts = diffDays * checkedShifts.length * staffVal;

                    // Formulate shiftTemplates hidden input
                    const templateLines = checkedShifts.map(s => s + '|' + deptVal + '|' + areaVal).join('\n');
                    hiddenTemplates.value = templateLines;

                    // Render preview list
                    const shiftListHtml = checkedShifts.map(s => '<li>• <strong>' + s + '</strong> (' + staffVal + ' lễ tân/ca' + (maxWorkVal > 0 ? ', tối đa ' + maxWorkVal + ' lượt' : '') + ')</li>').join('');
                    
                    previewBox.className = 'p-3 bg-white border rounded border-success-subtle';
                    previewBox.innerHTML = 
                        '<div class="text-success fw-bold mb-2"><i class="bi bi-check-circle-fill me-2"></i>AI Sẽ Lập Lịch:</div>' +
                        '<ul class="list-unstyled mb-0 d-flex flex-column gap-1">' +
                        '<li><i class="bi bi-check2 text-success me-2"></i>Tổng số: <strong>' + totalShifts + ' ca trực</strong></li>' +
                        '<li><i class="bi bi-check2 text-success me-2"></i>Số ngày: <strong>' + diffDays + ' ngày</strong> (' + startVal.split('-').reverse().join('/') + ' - ' + endVal.split('-').reverse().join('/') + ')</li>' +
                        '<li><i class="bi bi-check2 text-success me-2"></i>Tại quầy: <strong>' + deptVal + '</strong></li>' +
                        '<li><i class="bi bi-check2 text-success me-2"></i>Khung giờ áp dụng:</li>' +
                        '<ul class="ps-3 mb-0 list-unstyled">' + shiftListHtml + '</ul>' +
                        '</ul>';
                } else {
                    submitBtn.setAttribute('disabled', 'true');
                    hiddenTemplates.value = '';

                    let errorMsg = 'Vui lòng điền đầy đủ các thông tin:';
                    const errors = [];
                    if (!startVal || !endVal) errors.push('Thời gian bắt đầu/kết thúc');
                    else if (startVal > endVal) errors.push('Ngày bắt đầu phải trước ngày kết thúc');
                    if (!isDeptValid) errors.push('Quầy làm việc');
                    if (!isStaffValid) errors.push('Số lễ tân mỗi ca (tối thiểu 1)');
                    if (!isShiftsValid) errors.push('Chọn ít nhất một khung ca trực');

                    previewBox.className = 'p-3 bg-white border rounded border-danger-subtle';
                    previewBox.innerHTML = 
                        '<div class="text-danger fw-bold mb-2"><i class="bi bi-exclamation-triangle-fill me-2"></i>Thông tin chưa hợp lệ:</div>' +
                        '<ul class="mb-0 text-muted ps-3">' + errors.map(err => '<li>' + err + '</li>').join('') + '</ul>';
                }
            }

            // Bind listeners
            [startDate, endDate, department, workArea, staffPerShift, maxWorkload].forEach(input => {
                if (input) {
                    input.addEventListener('input', updatePreview);
                    input.addEventListener('change', updatePreview);
                }
            });
            checkboxes.forEach(cb => {
                cb.addEventListener('change', updatePreview);
            });

            // Initial preview execution
            updatePreview();
        }

        // Lab AI Scheduling Modal Logic
        const labModal = document.getElementById('aiLabScheduleModal');
        if (labModal) {
            const startDate = labModal.querySelector('[name="startDate"]');
            const endDate   = labModal.querySelector('[name="endDate"]');
            const staffPerShift  = labModal.querySelector('[name="staffPerShift"]');
            const maxWorkload    = labModal.querySelector('[name="maxWorkload"]');
            const roomCbs        = labModal.querySelectorAll('.lab-room-cb');
            const checkboxes     = labModal.querySelectorAll('.lab-ai-shift-cb');
            const previewBox     = document.getElementById('labAiPreviewBox');
            const submitBtn      = labModal.querySelector('button[type="submit"]');
            const hiddenTemplates = document.getElementById('labAiShiftTemplates');

            // Set default dates
            const todayStrL = new Date().toISOString().slice(0, 10);
            const nextWeekL = new Date();
            nextWeekL.setDate(nextWeekL.getDate() + 7);
            const nextWeekStrL = nextWeekL.toISOString().slice(0, 10);
            if (startDate && !startDate.value) startDate.value = todayStrL;
            if (endDate   && !endDate.value)   endDate.value   = nextWeekStrL;

            function updateLabPreview() {
                if (!startDate || !endDate || !staffPerShift || !previewBox || !submitBtn || !hiddenTemplates) return;

                const startVal  = startDate.value;
                const endVal    = endDate.value;
                const staffVal  = parseInt(staffPerShift.value, 10) || 1;
                const maxVal    = maxWorkload && maxWorkload.value ? parseInt(maxWorkload.value, 10) : 0;
                const checkedShifts = Array.from(checkboxes).filter(cb => cb.checked).map(cb => cb.value);
                const checkedRooms = Array.from(roomCbs).filter(cb => cb.checked);

                const isDatesValid  = startVal && endVal && startVal <= endVal;
                const isRoomsValid  = checkedRooms.length > 0;
                const isStaffValid  = staffVal >= 1;
                const isShiftsValid = checkedShifts.length > 0;
                const isValid = isDatesValid && isRoomsValid && isStaffValid && isShiftsValid;

                if (isValid) {
                    submitBtn.removeAttribute('disabled');
                    const startD   = new Date(startVal);
                    const endD     = new Date(endVal);
                    const diffDays = Math.ceil(Math.abs(endD - startD) / (1000 * 60 * 60 * 24)) + 1;
                    const totalShifts = diffDays * checkedShifts.length * staffVal * checkedRooms.length;

                    const templateLines = checkedShifts.map(s => s + '||').join('\n');
                    hiddenTemplates.value = templateLines;

                    const shiftListHtml = checkedShifts.map(s =>
                        '<li>• <strong>' + s + '</strong> (' + staffVal + ' kỹ thuật viên/ca' + (maxVal > 0 ? ', tối đa ' + maxVal + ' mẫu' : '') + ')</li>'
                    ).join('');

                    previewBox.className = 'p-3 bg-white border rounded border-success-subtle';
                    previewBox.innerHTML =
                        '<div class="text-success fw-bold mb-2"><i class="bi bi-check-circle-fill me-2"></i>AI Sẽ Lập Lịch:</div>' +
                        '<ul class="list-unstyled mb-0 d-flex flex-column gap-1">' +
                        '<li><i class="bi bi-check2 text-success me-2"></i>Tổng số: <strong>' + totalShifts + ' ca trực</strong> (' + checkedRooms.length + ' phòng)</li>' +
                        '<li><i class="bi bi-check2 text-success me-2"></i>Số ngày: <strong>' + diffDays + ' ngày</strong> (' + startVal.split('-').reverse().join('/') + ' - ' + endVal.split('-').reverse().join('/') + ')</li>' +
                        '<li><i class="bi bi-check2 text-success me-2"></i>Các phòng áp dụng:</li>' +
                        '<ul class="ps-3 mb-1 list-unstyled text-muted">' +
                        checkedRooms.map(cb => {
                            const name = cb.getAttribute('data-room-name') || '';
                            const type = (name.toLowerCase().includes('nuoc tieu') || name.toLowerCase().includes('urine')) ? 'Nước tiểu' : 'Máu';
                            return '<li>• ' + name + ' (Nhóm: <strong>' + type + '</strong>)</li>';
                        }).join('') +
                        '</ul>' +
                        '<li><i class="bi bi-check2 text-success me-2"></i>Khung giờ áp dụng:</li>' +
                        '<ul class="ps-3 mb-0 list-unstyled">' + shiftListHtml + '</ul>' +
                        '</ul>';
                } else {
                    submitBtn.setAttribute('disabled', 'true');
                    hiddenTemplates.value = '';
                    const errors = [];
                    if (!startVal || !endVal) errors.push('Thời gian bắt đầu/kết thúc');
                    else if (startVal > endVal) errors.push('Ngày bắt đầu phải trước ngày kết thúc');
                    if (!isRoomsValid)  errors.push('Chọn ít nhất một phòng xét nghiệm');
                    if (!isStaffValid)  errors.push('Số kỹ thuật viên mỗi ca (tối thiểu 1)');
                    if (!isShiftsValid) errors.push('Chọn ít nhất một khung ca trực');
                    previewBox.className = 'p-3 bg-white border rounded border-danger-subtle';
                    previewBox.innerHTML =
                        '<div class="text-danger fw-bold mb-2"><i class="bi bi-exclamation-triangle-fill me-2"></i>Thông tin chưa hợp lệ:</div>' +
                        '<ul class="mb-0 text-muted ps-3">' + errors.map(err => '<li>' + err + '</li>').join('') + '</ul>';
                }
            }

            [startDate, endDate, staffPerShift, maxWorkload].forEach(input => {
                if (input) {
                    input.addEventListener('input', updateLabPreview);
                    input.addEventListener('change', updateLabPreview);
                }
            });
            roomCbs.forEach(cb => cb.addEventListener('change', updateLabPreview));
            checkboxes.forEach(cb => cb.addEventListener('change', updateLabPreview));
            updateLabPreview();
        }
    });
</script>
<script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/admin/schedule-management.js?v=20260713-staff-room1"></script>
</body>
</html>
=======
                                if (window.history && window.history.replaceState) {
                                    window.history.replaceState(null, '', window.location.pathname + window.location.search + targetSelector);
                                }
                            }
                            function limitScheduleTablesToTenRows() {
                                document.querySelectorAll('.schedule-list-scroll').forEach(function (wrap) {
                                    wrap.style.removeProperty('max-height');
                                    wrap.style.removeProperty('height');
                                    wrap.style.removeProperty('overflow');
                                    wrap.classList.add('is-scroll-limited');
                                });
                            }

                            forceSchedulePane(resolveInitialTab());
                            limitScheduleTablesToTenRows();
                            roleTabs.forEach(function (tab) {
                                tab.addEventListener('click', function () {
                                    forceSchedulePane(tab);
                                    limitScheduleTablesToTenRows();
                                });
                            });
                            window.addEventListener('resize', limitScheduleTablesToTenRows);
                        });
                    </script>
                    <script>
                        window.activeRoomsList = [];
                        <c:forEach var="r" items="${rooms}">
                        window.activeRoomsList.push({
                            roomId: "${r.roomId}",
                            roomName: "${r.roomName}",
                            department: "${r.department}",
                            status: "${r.status}"
                        });
                        </c:forEach>
                    </script>
                    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/admin/schedule-common.js?v=20260722-v1"></script>
                    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/admin/schedule-doctor.js?v=20260722-v1"></script>
                    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/admin/schedule-staff.js?v=20260722-v1"></script>
                    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/admin/schedule-wizard.js?v=20260722-v1"></script>
                </body>

                </html>
>>>>>>> Stashed changes
