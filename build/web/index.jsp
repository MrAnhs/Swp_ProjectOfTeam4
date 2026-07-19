<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>DiabetesCare - Giám sát tiểu đường và cảnh báo sớm</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/public/common.css" />
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/public/home.css">
    <style>
        html {
            scroll-behavior: smooth;
        }
        section {
            scroll-margin-top: 100px !important;
        }
        /* Dark Theme Hero Override */
        .hero-modern {
            background: #0F172A !important;
            color: #ffffff !important;
            padding-top: 130px !important;
            min-height: 100vh !important;
            position: relative;
            overflow: hidden;
            display: flex;
            align-items: center;
        }
        /* Gradient Glow Effects */
        .hero-modern::before {
            content: '';
            position: absolute;
            top: -20%;
            right: -10%;
            width: 700px;
            height: 700px;
            background: radial-gradient(circle, rgba(42, 181, 163, 0.18) 0%, transparent 70%) !important;
            border-radius: 50%;
            z-index: 0;
            pointer-events: none;
        }
        .hero-modern::after {
            content: '';
            position: absolute;
            bottom: -15%;
            left: -5%;
            width: 550px;
            height: 550px;
            background: radial-gradient(circle, rgba(32, 138, 124, 0.12) 0%, transparent 70%) !important;
            border-radius: 50%;
            z-index: 0;
            pointer-events: none;
        }
        .hero-title {
            color: #ffffff !important;
            font-size: 3.8rem !important;
            font-weight: 800 !important;
            line-height: 1.15 !important;
            letter-spacing: -0.02em;
            margin-bottom: 1.5rem !important;
        }
        .hero-title span {
            background: linear-gradient(135deg, #2AB5A3, #208A7C) !important;
            -webkit-background-clip: text !important;
            -webkit-text-fill-color: transparent !important;
            background-clip: text !important;
        }
        .hero-description {
            color: #E2E8F0 !important;
            font-size: 1.15rem !important;
            line-height: 1.7 !important;
            max-width: 540px !important;
            margin-bottom: 2.5rem !important;
        }
        .hero-badge {
            background: rgba(42, 181, 163, 0.15) !important;
            color: #2AB5A3 !important;
            border: 1px solid rgba(42, 181, 163, 0.25) !important;
            padding: 0.5rem 1.25rem !important;
            font-size: 0.875rem !important;
            font-weight: 600 !important;
            margin-bottom: 1.5rem !important;
            border-radius: 50px;
        }
        /* Buttons padding & breathe */
        .btn-hero-primary {
            padding: 1.1rem 2.2rem !important;
            font-size: 1.05rem !important;
            border-radius: 50px !important;
            box-shadow: 0 10px 25px rgba(42, 181, 163, 0.3) !important;
        }
        .btn-hero-secondary {
            padding: 1.1rem 2.2rem !important;
            font-size: 1.05rem !important;
            border-radius: 50px !important;
            background: transparent !important;
            color: #cbd5e1 !important;
            border: 2px solid rgba(255, 255, 255, 0.2) !important;
        }
        .btn-hero-secondary:hover {
            border-color: #2AB5A3 !important;
            color: #ffffff !important;
            background: rgba(255, 255, 255, 0.05) !important;
        }

        /* Glassmorphism Dashboard Console */
        .hero-visual-dashboard {
            background: rgba(15, 23, 42, 0.6) !important;
            backdrop-filter: blur(16px) !important;
            -webkit-backdrop-filter: blur(16px) !important;
            border: 1px solid rgba(255, 255, 255, 0.08) !important;
            border-radius: 28px;
            padding: 2.25rem !important;
            box-shadow: 0 30px 100px rgba(0, 0, 0, 0.55);
            position: relative;
            z-index: 2;
        }
        .dashboard-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 1.75rem;
            border-bottom: 1px solid rgba(255, 255, 255, 0.08);
            padding-bottom: 1rem;
        }
        .dashboard-dots {
            display: flex;
            gap: 6px;
        }
        .dashboard-dot {
            width: 10px;
            height: 10px;
            border-radius: 50%;
        }
        .dashboard-dot.red { background: #ff5f56; }
        .dashboard-dot.yellow { background: #ffbd2e; }
        .dashboard-dot.green { background: #27c93f; }
        
        .dashboard-title {
            color: #94A3B8;
            font-size: 0.85rem;
            font-weight: 600;
            letter-spacing: 0.05em;
            text-transform: uppercase;
        }

        .hero-card-modern {
            background: transparent !important;
            box-shadow: none !important;
            padding: 0 !important;
        }
        .hero-card-modern h5 {
            color: #ffffff !important;
        }
        .hero-card-modern .text-secondary {
            color: #cbd5e1 !important;
            opacity: 0.9;
        }
        .hero-card-modern .stat-label {
            color: #94a3b8 !important;
        }
        .hero-card-modern .text-muted {
            color: #e2e8f0 !important;
            opacity: 0.9;
        }
        .stat-number {
            color: #2AB5A3 !important;
            font-size: 2.2rem !important;
            font-weight: 800;
        }
        .progress {
            background-color: rgba(255, 255, 255, 0.12) !important;
        }

        /* Glassmorphism Floating Cards */
        .floating-card {
            background: rgba(15, 23, 42, 0.8) !important;
            backdrop-filter: blur(12px) !important;
            -webkit-backdrop-filter: blur(12px) !important;
            border: 1px solid rgba(255, 255, 255, 0.1) !important;
            box-shadow: 0 15px 40px rgba(0, 0, 0, 0.4) !important;
            color: #ffffff !important;
        }
        .floating-card .text-dark {
            color: #ffffff !important;
        }
        .floating-card .text-muted {
            color: #cbd5e1 !important;
            opacity: 0.85;
        }
        .floating-card-1 {
            top: -25px !important;
            right: -15px !important;
        }
        .floating-card-2 {
            bottom: -20px !important;
            left: -15px !important;
        }

        /* Floating Navbar overrides for dark background compatibility */
        .modern-navbar {
            background: rgba(15, 23, 42, 0.8) !important;
            backdrop-filter: blur(16px) !important;
            -webkit-backdrop-filter: blur(16px) !important;
            border-bottom: 1px solid rgba(255, 255, 255, 0.05) !important;
            position: sticky !important;
            top: 0 !important;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.04) !important;
        }
        .modern-navbar .nav-link {
            color: #cbd5e1 !important;
        }
        .modern-navbar .nav-link:hover {
            color: #2AB5A3 !important;
        }
        .modern-navbar .brand span {
            color: #ffffff !important;
        }
        .lang-switcher {
            background: rgba(255, 255, 255, 0.05) !important;
            border-color: rgba(255, 255, 255, 0.1) !important;
            color: #cbd5e1 !important;
        }
        .lang-switcher:hover {
            border-color: #2AB5A3 !important;
            color: #ffffff !important;
        }
        .complications-section {
            background-color: #f8fafc;
        }
        .complications-img-wrapper {
            transition: transform 0.3s ease;
        }
        .complications-img-wrapper:hover {
            transform: scale(1.02);
        }
        .bg-primary-light {
            background-color: var(--primary-light) !important;
        }
        .text-primary {
            color: var(--primary-color) !important;
        }
        .border-primary {
            border-color: var(--primary-color) !important;
        }
        @keyframes pulse {
            0% { transform: scale(1); }
            50% { transform: scale(1.1); }
            100% { transform: scale(1); }
        }
        .animate-pulse {
            animation: pulse 2s infinite;
        }
        .btn-floating-hotline:hover {
            transform: scale(1.08) translateY(-3px);
            box-shadow: 0 8px 25px rgba(42, 181, 163, 0.5) !important;
            color: white;
        }

        /* Whitespace & Radius Consistency (Design System Refactoring) */
        .features-section, .ai-section, .complications-section, .cta-section {
            padding: 8rem 2rem !important;
        }
        .stats-container, .features-grid, .ai-container {
            max-width: 1280px !important; /* standard max-w-7xl */
            margin: 0 auto !important;
            padding: 0 1.5rem !important;
        }
        .ai-container {
            grid-template-columns: 5fr 7fr !important;
            gap: 5rem !important;
        }
        .ai-content {
            padding: 4.5rem 3.5rem !important;
            border-radius: 32px !important;
        }
        .ai-card-item {
            background: #ffffff !important;
            border: 1px solid #e2e8f0 !important;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.03) !important;
            border-radius: 20px !important;
        }
        .ai-list li {
            display: flex !important;
            align-items: flex-start !important; /* align items-start perfectly */
            gap: 0.75rem !important;
            margin-bottom: 1.25rem !important;
        }
        .ai-list li i {
            background: rgba(255, 255, 255, 0.25) !important;
            color: #ffffff !important;
            margin-top: 3px !important; /* slightly offset check icon for first text line */
        }
        .section-header {
            max-width: 800px !important;
            margin-bottom: 5rem !important; /* mb-20 space */
        }
        .section-title {
            font-size: 2.75rem !important;
            font-weight: 800 !important;
            letter-spacing: -0.03em !important; /* tracking-tight */
            line-height: 1.25 !important; /* leading-tight */
            margin-bottom: 1.5rem !important; /* mb-6 spacing */
            color: #1E293B !important;
        }
        .section-subtitle {
            font-size: 1.05rem !important;
            line-height: 1.7 !important; /* leading-relaxed */
            color: #64748B !important;
            max-width: 680px;
            margin: 0 auto;
        }

        /* Mockup Dashboard Specific Overrides */
        .hero-dashboard-mockup {
            background: rgba(15, 23, 42, 0.5) !important;
            backdrop-filter: blur(24px) !important;
            -webkit-backdrop-filter: blur(24px) !important;
            border: 1px solid rgba(255, 255, 255, 0.08) !important;
            border-radius: 24px !important;
            padding: 1.75rem 1.75rem 1.75rem 5rem !important; /* padding-left left space for sidebar */
            box-shadow: 0 30px 80px rgba(0, 0, 0, 0.55) !important;
            position: relative;
            z-index: 2;
        }
        .dashboard-sidebar {
            position: absolute;
            left: 0;
            top: 0;
            bottom: 0;
            width: 60px;
            background: rgba(15, 23, 42, 0.35);
            border-right: 1px solid rgba(255, 255, 255, 0.05);
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 1.5rem 0;
            gap: 1.5rem;
            border-top-left-radius: 24px;
            border-bottom-left-radius: 24px;
        }
        .sidebar-icon {
            color: rgba(255, 255, 255, 0.25);
            font-size: 1.25rem;
            cursor: pointer;
            transition: color 0.3s;
        }
        .sidebar-icon.active {
            color: #2AB5A3;
        }
        .dashboard-pills-container {
            position: absolute;
            top: -24px;
            left: 80px;
            right: 20px;
            display: flex;
            justify-content: space-between;
            gap: 10px;
            z-index: 10;
        }
        .dashboard-floating-pill-left {
            background: rgba(15, 23, 42, 0.85) !important;
            backdrop-filter: blur(8px) !important;
            border: 1px solid rgba(255, 255, 255, 0.1) !important;
            border-radius: 50px !important;
            padding: 0.5rem 1.25rem !important;
            box-shadow: 0 10px 25px rgba(0,0,0,0.5) !important;
            white-space: nowrap;
        }
        .dashboard-floating-pill-right {
            background: rgba(15, 23, 42, 0.85) !important;
            backdrop-filter: blur(8px) !important;
            border: 1px solid rgba(255, 255, 255, 0.1) !important;
            border-radius: 50px !important;
            padding: 0.5rem 1.25rem !important;
            box-shadow: 0 10px 25px rgba(0,0,0,0.5) !important;
            white-space: nowrap;
        }
        @media (max-width: 991px) {
            .dashboard-pills-container {
                top: -45px;
                flex-wrap: wrap;
                justify-content: center;
                gap: 5px;
            }
            .dashboard-floating-pill-left, .dashboard-floating-pill-right {
                font-size: 0.75rem !important;
                padding: 0.35rem 0.75rem !important;
            }
        }
        .dashboard-floating-sidebar-tab {
            position: absolute;
            left: -32px;
            top: 50%;
            transform: translateY(-50%);
            background: rgba(42, 181, 163, 0.15) !important;
            border: 1px solid rgba(42, 181, 163, 0.25) !important;
            border-radius: 12px !important;
            padding: 0.75rem 0.5rem !important;
            color: #2AB5A3 !important;
            font-size: 0.725rem !important;
            font-weight: bold;
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 4px;
            z-index: 10;
            writing-mode: vertical-rl;
            text-orientation: mixed;
        }
        .dashboard-stat-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 1.5rem;
            gap: 1.25rem;
        }
        .dashboard-stat-item {
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }
        .dashboard-stat-value {
            color: #ffffff;
            font-weight: 800;
            font-size: 1.25rem;
        }
        .dashboard-stat-label {
            color: rgba(255, 255, 255, 0.4);
            font-size: 0.7rem;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }
        .dashboard-grid {
            display: grid;
            grid-template-columns: 1.3fr 1fr;
            gap: 1rem;
            margin-top: 1.5rem;
        }
        .dashboard-chart-card {
            background: rgba(15, 23, 42, 0.4) !important;
            border: 1px solid rgba(255, 255, 255, 0.05) !important;
            border-radius: 16px !important;
            padding: 1rem !important;
        }
        .dashboard-alert-card {
            background: rgba(180, 83, 9, 0.15) !important;
            border: 1px solid rgba(217, 119, 6, 0.25) !important;
            border-radius: 16px !important;
            padding: 1rem !important;
            display: flex;
            flex-direction: column;
            justify-content: center;
        }
        .btn-floating-hotline-capsule:hover {
            transform: scale(1.05) translateY(-3px) !important;
            box-shadow: 0 12px 30px rgba(42, 181, 163, 0.6) !important;
        }

        /* Dark Theme Global Page Override */
        body {
            background-color: #0B0F19 !important;
            color: #E2E8F0 !important;
        }
        .stats-section {
            background: #0B0F19 !important;
        }
        .stat-card-modern {
            background: rgba(30, 41, 59, 0.45) !important;
            border: 1px solid rgba(255, 255, 255, 0.06) !important;
            backdrop-filter: blur(8px) !important;
        }
        .stat-card-label {
            color: #94A3B8 !important;
        }
        .features-section {
            background: #0F172A !important;
            border-top: 1px solid rgba(255, 255, 255, 0.03) !important;
        }
        .feature-card-modern {
            background: rgba(30, 41, 59, 0.45) !important;
            border: 1px solid rgba(255, 255, 255, 0.06) !important;
            backdrop-filter: blur(8px) !important;
        }
        .feature-card-modern:hover {
            border-color: rgba(42, 181, 163, 0.3) !important;
            box-shadow: 0 15px 35px rgba(42, 181, 163, 0.1) !important;
        }
        .feature-title {
            color: #ffffff !important;
        }
        .feature-desc {
            color: #94A3B8 !important;
        }
        .feature-icon {
            background: rgba(42, 181, 163, 0.12) !important;
            color: #2AB5A3 !important;
        }
        .complications-section {
            background: #0B0F19 !important;
            border-top: 1px solid rgba(255, 255, 255, 0.03) !important;
        }
        .complications-img-wrapper {
            background: rgba(30, 41, 59, 0.45) !important;
            border: 1px solid rgba(255, 255, 255, 0.06) !important;
        }
        .complications-section .bg-white {
            background: rgba(30, 41, 59, 0.45) !important;
            border: 1px solid rgba(255, 255, 255, 0.06) !important;
        }
        .complications-section .text-dark {
            color: #ffffff !important;
        }
        .complications-section .text-muted {
            color: #94A3B8 !important;
        }
        .bg-primary-light {
            background-color: rgba(42, 181, 163, 0.08) !important;
            border-color: rgba(42, 181, 163, 0.2) !important;
        }
        .bg-primary-light h4 {
            color: #2AB5A3 !important;
        }
        .bg-primary-light .text-dark {
            color: #cbd5e1 !important;
        }
        .bg-primary-light i {
            color: #2AB5A3 !important;
        }
        .ai-section {
            background: #0F172A !important;
            border-top: 1px solid rgba(255, 255, 255, 0.03) !important;
        }
        .ai-content {
            background: linear-gradient(135deg, #1e293b, #0f172a) !important;
            border: 1px solid rgba(255, 255, 255, 0.06) !important;
        }
        .ai-card-item {
            background: rgba(30, 41, 59, 0.45) !important;
            border: 1px solid rgba(255, 255, 255, 0.06) !important;
            box-shadow: none !important;
        }
        .ai-card-item:hover {
            transform: translateX(8px) !important;
            border-color: rgba(42, 181, 163, 0.3) !important;
            box-shadow: 0 10px 30px rgba(42, 181, 163, 0.08) !important;
        }
        .ai-card-title {
            color: #ffffff !important;
        }
        .ai-card-desc {
            color: #94A3B8 !important;
        }
        .ai-card-icon {
            background: rgba(42, 181, 163, 0.12) !important;
            color: #2AB5A3 !important;
        }
        .cta-section {
            background: radial-gradient(circle at center, rgba(42, 181, 163, 0.12) 0%, #0B0F19 80%) !important;
            border-top: 1px solid rgba(255, 255, 255, 0.03) !important;
        }
        .btn-cta {
            background: linear-gradient(135deg, #2AB5A3, #208A7C) !important;
            color: #ffffff !important;
            box-shadow: 0 8px 25px rgba(42, 181, 163, 0.35) !important;
        }
        .btn-cta:hover {
            transform: translateY(-3px) !important;
            box-shadow: 0 12px 30px rgba(42, 181, 163, 0.5) !important;
        }
        .footer-modern {
            background: #070A13 !important;
            border-top: 1px solid rgba(255, 255, 255, 0.05) !important;
            padding-top: 6rem !important;
        }
        .footer-title {
            color: #ffffff !important;
        }
        .footer-links a {
            color: #94A3B8 !important;
        }
        .footer-links a:hover {
            color: #2AB5A3 !important;
        }
        .footer-brand-text {
            color: #ffffff !important;
        }
        .section-tag {
            background: rgba(42, 181, 163, 0.15) !important;
            color: #2AB5A3 !important;
            border: 1px solid rgba(42, 181, 163, 0.25) !important;
        }

        /* Blog Section Specific Styles */
        .blog-section {
            background: #0B0F19 !important;
            border-top: 1px solid rgba(255, 255, 255, 0.03) !important;
        }
        .blog-card {
            background: rgba(12, 19, 34, 0.45) !important;
            border: 1px solid rgba(255, 255, 255, 0.06) !important;
            border-radius: 20px !important; /* rounded-2xl */
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1) !important;
            overflow: hidden;
        }
        .blog-card:hover {
            transform: translateY(-6px) !important;
            border-color: rgba(42, 181, 163, 0.3) !important;
            box-shadow: 0 15px 35px rgba(42, 181, 163, 0.1) !important;
        }
        .blog-thumbnail-wrapper {
            position: relative;
            overflow: hidden;
            aspect-ratio: 16/9;
            border-top-left-radius: 20px;
            border-top-right-radius: 20px;
        }
        .blog-img {
            transition: transform 0.5s ease !important;
        }
        .blog-card:hover .blog-img {
            transform: scale(1.05) !important;
        }
        .text-line-clamp-2 {
            display: -webkit-box;
            -webkit-line-clamp: 2;
            -webkit-box-orient: vertical;
            overflow: hidden;
        }
        .text-line-clamp-3 {
            display: -webkit-box;
            -webkit-line-clamp: 3;
            -webkit-box-orient: vertical;
            overflow: hidden;
        }
        .hover-arrow {
            color: #2AB5A3 !important;
            transition: color 0.3s;
        }
        .hover-arrow:hover {
            color: #00d2d3 !important;
        }
        .animate-arrow {
            transition: transform 0.3s ease;
        }
        .hover-arrow:hover .animate-arrow {
            transform: translateX(4px);
        }
    </style>
</head>

<body>
    <nav class="modern-navbar" id="navbar">
        <div class="nav-container d-flex justify-content-between align-items-center w-100 px-3">
            <a href="index.jsp" class="brand d-flex align-items-center gap-2 text-decoration-none">
                <div class="brand-icon d-flex align-items-center justify-content-center" style="width: 36px; height: 36px; background: linear-gradient(135deg, #2AB5A3, #208A7C); border-radius: 8px;">
                    <i class="bi bi-heart-pulse-fill text-white fs-5"></i>
                </div>
                <span class="text-white fw-bold fs-5">DiabetesCare</span>
            </a>
            <div class="nav-links d-none d-lg-flex align-items-center gap-4">
                <a href="#" class="nav-link text-white-50 text-decoration-none small">Trang chủ</a>
                <a href="#features" class="nav-link text-white-50 text-decoration-none small">Tính năng</a>
                <a href="#about" class="nav-link text-white-50 text-decoration-none small">Về chúng tôi</a>
                <a href="#blog" class="nav-link text-white-50 text-decoration-none small">Blog</a>
                <div style="position: relative;">
                    <button class="lang-switcher border-0 bg-transparent text-white-50 small d-flex align-items-center gap-1" type="button">
                        <i class="bi bi-globe"></i>
                        <span>Tiếng Việt</span>
                        <i class="bi bi-chevron-down" style="font-size: 0.75rem;"></i>
                    </button>
                </div>
                <a href="login.jsp" class="nav-link text-white-50 text-decoration-none small">Đăng nhập</a>
                <a href="register.jsp" class="nav-link text-white-50 text-decoration-none small">Đăng ký</a>
                <a href="login.jsp" class="btn-primary-nav text-white text-decoration-none small fw-bold px-4 py-2" style="background: linear-gradient(135deg, #2AB5A3, #208A7C); border-radius: 50px; box-shadow: 0 4px 15px rgba(42, 181, 163, 0.4);">BẮT ĐẦU CHAT AI</a>
            </div>
        </div>
    </nav>

    <section class="hero-modern">
        <div class="hero-content">
            <div class="hero-text">
                <h1 class="hero-title text-white text-uppercase" style="font-size: 3.8rem; line-height: 1.1; letter-spacing: -0.02em; font-weight: 800;">
                    GIÁM SÁT TIỂU<br>ĐƯỜNG VÀ CẢNH<br>BÁO SỚM
                </h1>
                <p class="hero-description text-white-50 mt-4 mb-4" style="font-size: 1.05rem; line-height: 1.6; max-width: 480px;">
                    Hệ thống y tế AI thông minh giúp theo dõi hồ sơ sức khỏe toàn diện, hỗ trợ phát hiện sớm nguy cơ tiểu đường, và kết nối bệnh nhân trực tiếp với bác sĩ để có kết luận chính xác nhất.
                </p>
                <div class="hero-buttons">
                    <a href="register.jsp" class="btn-hero-primary text-white text-decoration-none fw-bold px-4 py-3 d-inline-flex align-items-center gap-2" style="background: linear-gradient(135deg, #2AB5A3, #00d2d3); border-radius: 50px; box-shadow: 0 8px 30px rgba(42, 181, 163, 0.5); font-size: 0.95rem;">
                        BẮT ĐẦU NGAY <i class="bi bi-arrow-right"></i>
                    </a>
                    <a href="login.jsp" class="btn-hero-secondary text-white text-decoration-none fw-bold px-4 py-3 d-inline-flex align-items-center gap-2" style="background: transparent; border: 2px solid rgba(255, 255, 255, 0.2); border-radius: 50px; font-size: 0.95rem;">
                        <i class="bi bi-play-circle-fill text-primary"></i> XEM DEMO
                    </a>
                </div>
            </div>
             <div class="hero-visual">
                <!-- Background heart pulse animation decoration -->
                <svg class="position-absolute" style="right: -40px; top: 10%; width: 120px; opacity: 0.15; z-index: 1;" viewBox="0 0 100 50">
                    <path d="M0 25 L30 25 L35 10 L40 40 L45 20 L50 30 L55 25 L100 25" fill="none" stroke="#2AB5A3" stroke-width="2" />
                </svg>
                
                <!-- Background molecular node decoration -->
                <div class="position-absolute" style="left: -30px; bottom: -20px; width: 100px; height: 100px; opacity: 0.2; z-index: 1;">
                    <svg viewBox="0 0 100 100" class="w-100 h-100">
                        <line x1="20" y1="80" x2="50" y2="50" stroke="#2AB5A3" stroke-width="1.5" />
                        <line x1="50" y1="50" x2="80" y2="80" stroke="#2AB5A3" stroke-width="1.5" />
                        <line x1="50" y1="50" x2="50" y2="20" stroke="#2AB5A3" stroke-width="1.5" />
                        <circle cx="20" cy="80" r="6" fill="#2AB5A3" />
                        <circle cx="50" cy="50" r="8" fill="#2AB5A3" />
                        <circle cx="80" cy="80" r="6" fill="#2AB5A3" />
                        <circle cx="50" cy="20" r="6" fill="#2AB5A3" />
                    </svg>
                </div>

                <div class="hero-dashboard-mockup">
                    <!-- Left Sidebar -->
                    <div class="dashboard-sidebar">
                        <div class="sidebar-icon active" title="Tiếp nhận hồ sơ"><i class="bi bi-calendar2-check"></i></div>
                        <div class="sidebar-icon" title="Khám tổng quát"><i class="bi bi-person-vcard"></i></div>
                        <div class="sidebar-icon" title="Xét nghiệm"><i class="bi bi-eyedropper"></i></div>
                        <div class="sidebar-icon" title="Khám chi tiết"><i class="bi bi-clipboard2-pulse-fill"></i></div>
                        <div class="sidebar-icon" title="Đã hoàn thành"><i class="bi bi-archive"></i></div>
                        <div class="sidebar-icon mt-auto" title="Đăng xuất"><i class="bi bi-box-arrow-left"></i></div>
                    </div>

                    <!-- Floating sidebar vertical tab -->
                    <div class="dashboard-floating-sidebar-tab">
                        <i class="bi bi-heart-pulse"></i> BÁC SĨ
                    </div>

                    <!-- Floating Top Pills -->
                    <div class="dashboard-pills-container">
                        <div class="dashboard-floating-pill-left small text-white d-flex align-items-center gap-2">
                            <div class="bg-primary rounded-circle p-1 animate-pulse" style="width: 8px; height: 8px; background-color: #2AB5A3 !important;"></div>
                            <span>Bác sĩ phụ trách: #5</span>
                        </div>

                        <div class="dashboard-floating-pill-right small text-white d-flex align-items-center gap-2">
                            <i class="bi bi-shield-check text-primary"></i>
                            <span>Cổng Bác Sĩ</span>
                        </div>
                    </div>

                    <!-- Dashboard Main Body -->
                    <div class="d-flex align-items-center gap-2 text-primary small fw-bold mb-1" style="color: #2AB5A3 !important;">
                        <i class="bi bi-activity animate-pulse"></i> TIẾP NHẬN BỆNH NHÂN
                    </div>
                    <div class="text-white-50 small mb-4">Danh sách lấy trực tiếp từ lịch hẹn đã liên kết với bác sĩ hiện tại.</div>

                    <!-- Statistics Row -->
                    <div class="dashboard-stat-row">
                        <div class="dashboard-stat-item">
                            <i class="bi bi-calendar2-check-fill text-primary"></i>
                            <div>
                                <div class="dashboard-stat-value">3 ca</div>
                                <div class="dashboard-stat-label">Chờ tiếp nhận</div>
                            </div>
                        </div>
                        <div class="dashboard-stat-item">
                            <i class="bi bi-check2-circle text-primary"></i>
                            <div>
                                <div class="dashboard-stat-value">15 ca</div>
                                <div class="dashboard-stat-label">Đã hoàn thành</div>
                            </div>
                        </div>
                        <div class="dashboard-stat-item">
                            <i class="bi bi-people-fill text-primary"></i>
                            <div>
                                <div class="dashboard-stat-value">95%</div>
                                <div class="dashboard-stat-label">Hài lòng</div>
                            </div>
                        </div>
                    </div>

                    <!-- Teal Progress Bar -->
                    <div class="progress mb-2" style="height: 6px; background-color: rgba(255, 255, 255, 0.12) !important;">
                        <div class="progress-bar" role="progressbar" style="width: 75%; background: linear-gradient(90deg, #2AB5A3, #208A7C);"></div>
                    </div>

                    <!-- Bottom widgets grid -->
                    <div class="dashboard-grid">
                        <!-- Queue Card -->
                        <div class="dashboard-chart-card" style="padding: 1rem !important;">
                            <div class="small text-white fw-bold mb-2">Lịch hẹn chờ khám</div>
                            <div class="d-flex flex-column gap-2">
                                <div class="d-flex justify-content-between align-items-center p-2 rounded" style="background: rgba(255, 255, 255, 0.05); font-size: 0.75rem;">
                                    <div>
                                        <div class="fw-bold text-white">#13 Nguyễn Thị Bình</div>
                                        <div class="text-white-50" style="font-size: 0.7rem;">Số thứ tự: 1 • Tại quầy</div>
                                    </div>
                                    <span class="badge bg-success" style="font-size: 0.65rem; padding: 4px 8px;">Tiếp nhận</span>
                                </div>
                                <div class="d-flex justify-content-between align-items-center p-2 rounded" style="background: rgba(255, 255, 255, 0.05); font-size: 0.75rem;">
                                    <div>
                                        <div class="fw-bold text-white">#14 Trần Văn Cường</div>
                                        <div class="text-white-50" style="font-size: 0.7rem;">Số thứ tự: 2 • Trực tuyến</div>
                                    </div>
                                    <span class="badge bg-success" style="font-size: 0.65rem; padding: 4px 8px;">Tiếp nhận</span>
                                </div>
                            </div>
                        </div>

                        <!-- AI Symptoms Summary Card -->
                        <div class="dashboard-alert-card text-warning" style="padding: 1rem !important; border: 1px solid rgba(42, 181, 163, 0.2) !important; background: rgba(42, 181, 163, 0.05) !important;">
                            <div class="d-flex align-items-center gap-2 small fw-bold mb-1" style="color: #2AB5A3 !important;">
                                <i class="bi bi-stars animate-pulse"></i> TRIỆU CHỨNG TỪ AI:
                            </div>
                            <div class="small text-white-50" style="font-size: 0.7rem; line-height: 1.3;">
                                Bệnh nhân Bình: Mệt mỏi, sụt cân nhẹ, chỉ số đường huyết cũ 7.2 mmol/L. Cần theo dõi chỉ số HbA1c định kỳ.
                            </div>
                        </div>
                    </div>

                    <!-- Bottom Status bar -->
                    <div class="d-flex justify-content-end mt-3">
                        <div class="d-flex align-items-center gap-2 small px-3 py-1 bg-success-subtle border border-success-subtle rounded-pill" style="background-color: rgba(39, 201, 63, 0.1) !important; border-color: rgba(39, 201, 63, 0.2) !important;">
                            <i class="bi bi-check-circle-fill text-success" style="font-size: 0.8rem;"></i>
                            <span class="text-success fw-bold" style="font-size: 0.75rem;">TRẠNG THÁI: ỔN ĐỊNH</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <section class="stats-section">
        <div class="stats-container">
            <div class="stat-card-modern">
                <div class="stat-card-number">15k+</div>
                <div class="stat-card-label">Bệnh nhân đang theo dõi</div>
            </div>
            <div class="stat-card-modern">
                <div class="stat-card-number">98%</div>
                <div class="stat-card-label">Mức độ hài lòng</div>
            </div>
            <div class="stat-card-modern">
                <div class="stat-card-number">24/7</div>
                <div class="stat-card-label">Hỗ trợ theo dõi</div>
            </div>
            <div class="stat-card-modern">
                <div class="stat-card-number">50+</div>
                <div class="stat-card-label">Bác sĩ chuyên môn</div>
            </div>
        </div>
    </section>

    <section class="features-section" id="features">
        <div class="section-header">
            <div class="section-tag">
                <i class="bi bi-stars"></i>
                <span>Tính năng chính</span>
            </div>
            <h2 class="section-title">Giải pháp quản lý chăm sóc sức khỏe</h2>
            <p class="section-subtitle">Từ đăng ký tài khoản, đặt lịch khám, xét nghiệm đến hỗ trợ bác sĩ chẩn đoán, hệ thống được thiết kế để rõ ràng và dễ vận hành.</p>
        </div>
        <div class="features-grid">
            <div class="feature-card-modern">
                <div class="feature-icon">
                    <i class="bi bi-file-medical"></i>
                </div>
                <h3 class="feature-title">Đăng ký bệnh nhân</h3>
                <p class="feature-desc">Quy trình đăng ký đơn giản, giúp bệnh nhân tạo và quản lý thông tin sức khỏe.</p>
            </div>
            <div class="feature-card-modern">
                <div class="feature-icon">
                    <i class="bi bi-exclamation-triangle"></i>
                </div>
                <h3 class="feature-title">Đánh giá nguy cơ</h3>
                <p class="feature-desc">Hỗ trợ phát hiện sớm nguy cơ tiểu đường dựa trên chỉ số xét nghiệm và thông tin lâm sàng.</p>
            </div>
            <div class="feature-card-modern">
                <div class="feature-icon">
                    <i class="bi bi-robot"></i>
                </div>
                <h3 class="feature-title">Chat AI</h3>
                <p class="feature-desc">Hỗ trợ bệnh nhân mô tả triệu chứng và tóm tắt thông tin để bác sĩ tham khảo.</p>
            </div>
        </div>
    </section>

    <section class="complications-section py-5 bg-light" id="about">
        <div class="container py-4">
            <div class="section-header text-center mb-5">
                <div class="section-tag d-inline-flex align-items-center gap-1 mb-2 px-3 py-1 bg-white border rounded-pill text-primary small">
                    <i class="bi bi-exclamation-octagon-fill text-danger"></i>
                    <span class="text-danger fw-semibold">Biến chứng nguy hiểm</span>
                </div>
                <h2 class="section-title fw-bold text-dark mt-2 mb-3">Hiểm họa khôn lường từ bệnh tiểu đường</h2>
                <p class="section-subtitle text-muted mx-auto" style="max-width: 800px; font-size: 1.1rem; line-height: 1.6;">
                    Tiểu đường là căn bệnh phát triển âm thầm, nhưng để lại những biến chứng vô cùng nghiêm trọng ảnh hưởng đến toàn bộ cơ thể nếu không được tầm soát kịp thời.
                </p>
            </div>
            
             <div class="row g-5 align-items-center justify-content-center">
                <div class="col-lg-5 d-flex align-items-center justify-content-center">
                    <div class="complications-img-wrapper p-3 bg-white rounded-4 shadow-sm border border-light" style="max-width: 460px; width: 100%;">
                        <img src="${pageContext.request.contextPath}/assets/images/diabetes-complications.png" alt="Biến chứng tiểu đường nguy hiểm" class="img-fluid rounded-3" style="width: 100%; height: auto;">
                    </div>
                </div>
                <div class="col-lg-7">
                    <div class="ps-lg-4">
                        <h3 class="fw-bold mb-4 text-dark"><i class="bi bi-info-circle text-primary me-2"></i>Thống kê đáng báo động tại Việt Nam</h3>
                        <div class="row g-3 mb-4">
                            <div class="col-sm-6">
                                <div class="p-3 bg-white rounded-3 shadow-sm border-start border-primary border-4">
                                    <div class="h3 fw-bold text-primary mb-1">5 triệu +</div>
                                    <p class="text-muted small mb-0">Người Việt Nam đang sống chung với bệnh tiểu đường.</p>
                                </div>
                            </div>
                            <div class="col-sm-6">
                                <div class="p-3 bg-white rounded-3 shadow-sm border-start border-primary border-4">
                                    <div class="h3 fw-bold text-primary mb-1">65% +</div>
                                    <p class="text-muted small mb-0">Người bệnh không biết mình mắc bệnh cho đến khi có biến chứng.</p>
                                </div>
                            </div>
                            <div class="col-sm-6">
                                <div class="p-3 bg-white rounded-3 shadow-sm border-start border-primary border-4">
                                    <div class="h3 fw-bold text-primary mb-1">100%</div>
                                    <p class="text-muted small mb-0">Người lớn có nguy cơ nên kiểm tra chỉ số HbA1c định kỳ.</p>
                                </div>
                            </div>
                            <div class="col-sm-6">
                                <div class="p-3 bg-white rounded-3 shadow-sm border-start border-primary border-4">
                                    <div class="h3 fw-bold text-primary mb-1">Hàng năm</div>
                                    <p class="text-muted small mb-0">Khuyến cáo của các tổ chức y tế về tần suất nên đi tầm soát.</p>
                                </div>
                            </div>
                        </div>
                        
                        <div class="bg-primary-light p-4 rounded-4 border border-info-subtle mb-4">
                            <h4 class="h5 fw-bold text-primary mb-3">
                                <i class="bi bi-heart-pulse-fill me-2"></i>Tại sao cần tầm soát tiểu đường hàng năm?
                            </h4>
                            <ul class="list-unstyled mb-0 d-flex flex-column gap-2 text-dark small">
                                <li class="d-flex gap-2">
                                    <i class="bi bi-shield-check-fill text-success"></i>
                                    <span><strong>Phát hiện giai đoạn tiền tiểu đường:</strong> Giúp bạn kịp thời thay đổi chế độ sinh hoạt để đảo ngược tình trạng bệnh.</span>
                                </li>
                                <li class="d-flex gap-2">
                                    <i class="bi bi-shield-check-fill text-success"></i>
                                    <span><strong>Tránh các tổn thương vĩnh viễn:</strong> Hạn chế tối đa các biến chứng nguy hiểm như suy thận mạn, đột quỵ, hoại tử chi, suy tim và tổn thương võng mạc.</span>
                                </li>
                                <li class="d-flex gap-2">
                                    <i class="bi bi-shield-check-fill text-success"></i>
                                    <span><strong>Tối ưu hóa sức khỏe chủ động:</strong> Nhận các chẩn đoán chính xác nhất từ bác sĩ và chế độ dinh dưỡng cá nhân hóa của AI hàng năm.</span>
                                </li>
                            </ul>
                        </div>
                        
                        <div class="text-center text-lg-start">
                            <a href="register.jsp" class="btn btn-primary btn-lg px-4 py-3 rounded-pill fw-semibold shadow-sm text-white" style="background: linear-gradient(135deg, var(--primary-color), var(--primary-dark)); border: none;">
                                <i class="bi bi-calendar-heart me-2"></i>Đăng ký tầm soát ngay hôm nay
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <section class="ai-section" id="ai-section">
        <div class="ai-container">
            <div class="ai-content">
                <h3 class="ai-title">
                    <i class="bi bi-cpu me-2"></i>Hỗ trợ đánh giá nguy cơ bằng AI
                </h3>
                <p class="ai-desc">
                    Chat AI hỗ trợ thu thập thông tin sức khỏe như đường huyết, BMI, triệu chứng và tiền sử để bác sĩ có thêm dữ liệu tham khảo.
                </p>
                <ul class="ai-list">
                    <li><i class="bi bi-check"></i> Thu thập thông tin từ cuộc trò chuyện</li>
                    <li><i class="bi bi-check"></i> Đưa ra gợi ý nguy cơ, không thay thế chẩn đoán</li>
                    <li><i class="bi bi-check"></i> Tóm tắt thông tin để bác sĩ xem nhanh</li>
                    <li><i class="bi bi-check"></i> Hỗ trợ theo dõi dữ liệu bệnh nhân theo thời gian</li>
                </ul>
            </div>
            <div class="ai-cards">
                <div class="ai-card-item">
                    <div class="ai-card-icon"><i class="bi bi-heart-pulse"></i></div>
                    <h4 class="ai-card-title">Đánh giá nguy cơ</h4>
                    <p class="ai-card-desc">Phân tích nhiều chỉ số sức khỏe để hỗ trợ bác sĩ nhận diện nguy cơ.</p>
                </div>
                <div class="ai-card-item">
                    <div class="ai-card-icon"><i class="bi bi-graph-up-arrow"></i></div>
                    <h4 class="ai-card-title">Theo dõi xu hướng</h4>
                    <p class="ai-card-desc">Quan sát thay đổi chỉ số sức khỏe qua từng lần khám và xét nghiệm.</p>
                </div>
                <div class="ai-card-item">
                    <div class="ai-card-icon"><i class="bi bi-bell"></i></div>
                    <h4 class="ai-card-title">Cảnh báo thông minh</h4>
                    <p class="ai-card-desc">Nhắc nhở khi có dữ liệu cần bác sĩ hoặc bệnh nhân chú ý.</p>
                </div>
            </div>
        </div>
    </section>

    <section class="blog-section py-24" id="blog">
        <div class="container" style="max-width: 1280px; margin: 0 auto; padding: 0 1.5rem;">
            <div class="section-header text-center mb-5">
                <div class="section-tag d-inline-flex align-items-center gap-1 mb-2 px-3 py-1 rounded-pill text-primary small">
                    <i class="bi bi-book-half text-primary"></i>
                    <span class="fw-semibold">📚 Kiến thức & Tin tức</span>
                </div>
                <h2 class="section-title fw-bold text-white mt-2 mb-3">Cẩm nang chăm sóc và chủ động quản lý tiểu đường</h2>
                <p class="section-subtitle text-muted mx-auto" style="max-width: 800px;">
                    Cung cấp các thông tin hữu ích về chế độ dinh dưỡng, tiến bộ khoa học và hướng dẫn thực tiễn từ đội ngũ chuyên gia để đồng hành cùng sức khỏe của bạn.
                </p>
            </div>
            
            <div class="row g-4 justify-content-center">
                <!-- Blog Card 1 -->
                <div class="col-lg-4 col-md-6">
                    <div class="blog-card h-100 d-flex flex-column">
                        <div class="blog-thumbnail-wrapper overflow-hidden">
                            <img src="${pageContext.request.contextPath}/assets/images/blog1.png" alt="Chế độ ăn low-carb" class="w-100 h-100 object-fit-cover blog-img">
                        </div>
                        <div class="p-4 d-flex flex-column flex-grow-1">
                            <div class="d-flex align-items-center justify-content-between mb-3">
                                <span class="badge px-3 py-1 rounded-pill text-primary small" style="background: rgba(42, 181, 163, 0.1); font-weight: 600;">Dinh dưỡng</span>
                                <small class="text-white-50"><i class="bi bi-clock me-1"></i> 5 phút đọc</small>
                            </div>
                            <h3 class="h5 fw-bold text-white mb-2 text-line-clamp-2" style="line-height: 1.4;">Chế độ ăn low-carb có thực sự tốt cho người tiểu đường Type 2?</h3>
                            <p class="text-white-50 small mb-4 text-line-clamp-3">Tìm hiểu cách thức carbohydrate ảnh hưởng đến đường huyết, các nghiên cứu mới nhất và cách thiết lập thực đơn ăn uống khoa học hằng ngày.</p>
                            <a href="#" class="text-primary text-decoration-none mt-auto fw-semibold d-inline-flex align-items-center gap-1 hover-arrow">
                                Đọc thêm <i class="bi bi-arrow-right animate-arrow"></i>
                            </a>
                        </div>
                    </div>
                </div>

                <!-- Blog Card 2 -->
                <div class="col-lg-4 col-md-6">
                    <div class="blog-card h-100 d-flex flex-column">
                        <div class="blog-thumbnail-wrapper overflow-hidden">
                            <img src="${pageContext.request.contextPath}/assets/images/blog2.png" alt="Công nghệ AI" class="w-100 h-100 object-fit-cover blog-img">
                        </div>
                        <div class="p-4 d-flex flex-column flex-grow-1">
                            <div class="d-flex align-items-center justify-content-between mb-3">
                                <span class="badge px-3 py-1 rounded-pill text-primary small" style="background: rgba(42, 181, 163, 0.1); font-weight: 600;">Công nghệ</span>
                                <small class="text-white-50"><i class="bi bi-clock me-1"></i> 6 phút đọc</small>
                            </div>
                            <h3 class="h5 fw-bold text-white mb-2 text-line-clamp-2" style="line-height: 1.4;">AI của DiabetesCare giúp phát hiện sớm nguy cơ biến chứng như thế nào?</h3>
                            <p class="text-white-50 small mb-4 text-line-clamp-3">Khám phá cách hệ thống học máy phân tích dữ liệu lâm sàng của bệnh nhân để dự đoán sớm các tổn thương về thận, tim mạch và võng mạc.</p>
                            <a href="#" class="text-primary text-decoration-none mt-auto fw-semibold d-inline-flex align-items-center gap-1 hover-arrow">
                                Đọc thêm <i class="bi bi-arrow-right animate-arrow"></i>
                            </a>
                        </div>
                    </div>
                </div>

                <!-- Blog Card 3 -->
                <div class="col-lg-4 col-md-6">
                    <div class="blog-card h-100 d-flex flex-column">
                        <div class="blog-thumbnail-wrapper overflow-hidden">
                            <img src="${pageContext.request.contextPath}/assets/images/blog3.png" alt="Sống khỏe" class="w-100 h-100 object-fit-cover blog-img">
                        </div>
                        <div class="p-4 d-flex flex-column flex-grow-1">
                            <div class="d-flex align-items-center justify-content-between mb-3">
                                <span class="badge px-3 py-1 rounded-pill text-primary small" style="background: rgba(42, 181, 163, 0.1); font-weight: 600;">Sống khỏe</span>
                                <small class="text-white-50"><i class="bi bi-clock me-1"></i> 4 phút đọc</small>
                            </div>
                            <h3 class="h5 fw-bold text-white mb-2 text-line-clamp-2" style="line-height: 1.4;">5 thói quen buổi sáng giúp ổn định đường huyết tự nhiên</h3>
                            <p class="text-white-50 small mb-4 text-line-clamp-3">Những hành động nhỏ nhưng mang lại hiệu quả to lớn trong việc kiểm soát chỉ số HbA1c suốt cả ngày dài mà bạn nên thực hiện ngay.</p>
                            <a href="#" class="text-primary text-decoration-none mt-auto fw-semibold d-inline-flex align-items-center gap-1 hover-arrow">
                                Đọc thêm <i class="bi bi-arrow-right animate-arrow"></i>
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <section class="cta-section">
        <div class="cta-container">
            <h2 class="cta-title">Sẵn sàng quản lý sức khỏe chủ động hơn?</h2>
            <p class="cta-desc">Đăng ký tài khoản để đặt lịch khám, theo dõi hồ sơ và xem kết quả khi bác sĩ cho phép.</p>
            <a href="register.jsp" class="btn-cta">
                Tạo tài khoản miễn phí
                <i class="bi bi-arrow-right ms-2"></i>
            </a>
        </div>
    </section>

    <footer class="footer-modern">
        <div class="footer-container">
            <div class="footer-grid">
                <div>
                    <div class="footer-brand">
                        <div class="footer-brand-icon">
                            <i class="bi bi-heart-pulse-fill"></i>
                        </div>
                        <span class="footer-brand-text">DiabetesCare</span>
                    </div>
                    <p class="footer-desc">
                        Hệ thống hỗ trợ quản lý chăm sóc tiểu đường, đặt lịch khám, xét nghiệm và theo dõi hồ sơ sức khỏe.
                    </p>
                </div>
                <div>
                    <h4 class="footer-title">Sản phẩm</h4>
                    <ul class="footer-links">
                        <li><a href="#">Tính năng</a></li>
                        <li><a href="#">Quy trình khám</a></li>
                        <li><a href="#">Tài liệu</a></li>
                        <li><a href="#">API</a></li>
                    </ul>
                </div>
                <div>
                    <h4 class="footer-title">Hệ thống</h4>
                    <ul class="footer-links">
                        <li><a href="login.jsp">Đăng nhập</a></li>
                        <li><a href="register.jsp">Đăng ký</a></li>
                        <li><a href="#">Giới thiệu</a></li>
                        <li><a href="#">Liên hệ</a></li>
                    </ul>
                </div>
                <div>
                    <h4 class="footer-title">Thông tin liên hệ</h4>
                    <ul class="footer-links text-white-50 small list-unstyled d-flex flex-column gap-2" style="padding-left: 0;">
                        <li><i class="bi bi-telephone-fill text-warning me-1"></i> Hotline: <strong class="text-warning">1900 6868</strong></li>
                        <li><i class="bi bi-geo-alt-fill me-1"></i> Tòa nhà DiabetesCare, Cầu Giấy, Hà Nội</li>
                        <li><i class="bi bi-clock-fill me-1"></i> 08:00 - 22:00 (Tất cả các ngày)</li>
                        <li><i class="bi bi-envelope-fill me-1"></i> support@diabetescare.edu</li>
                    </ul>
                </div>
            </div>
            <div class="footer-bottom">
                <p>© 2026 DiabetesCare. Đã đăng ký bản quyền.</p>
            </div>
        </div>
    </footer>
    <!-- Floating Hotline -->
    <a href="tel:19006868" class="btn-floating-hotline-capsule d-none d-md-flex align-items-center justify-content-between" style="position: fixed; bottom: 30px; right: 30px; width: 140px; height: 52px; background: rgba(15, 23, 42, 0.85); backdrop-filter: blur(10px); border: 2px solid rgba(42, 181, 163, 0.3); border-radius: 100px; text-decoration: none; z-index: 9999; padding: 4px; box-shadow: 0 10px 30px rgba(0, 0, 0, 0.4); transition: all 0.3s ease;">
        <div class="d-flex align-items-center justify-content-center text-white" style="width: 40px; height: 40px; background: rgba(255, 255, 255, 0.05); border-radius: 50%;">
            <i class="bi bi-telephone-fill text-primary fs-5" style="color: #2AB5A3 !important;"></i>
        </div>
        <div class="d-flex align-items-center justify-content-center text-white animate-pulse" style="width: 40px; height: 40px; background: linear-gradient(135deg, #2AB5A3, #208A7C); border-radius: 50%; box-shadow: 0 4px 15px rgba(42, 181, 163, 0.5);">
            <i class="bi bi-arrow-right-short fs-4"></i>
        </div>
    </a>

    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/public/home.js?v=20260709-fontfix2"></script>
</body>
</html>
