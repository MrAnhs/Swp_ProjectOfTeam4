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
            background: linear-gradient(180deg, #0B0F19 0%, #0F172A 100%) !important;
            border-top: 1px solid rgba(255, 255, 255, 0.04) !important;
            padding: 5rem 0 !important;
        }
        .feature-card-modern {
            background: rgba(30, 41, 59, 0.45) !important;
            border: 1px solid rgba(255, 255, 255, 0.08) !important;
            border-radius: 20px !important;
            padding: 2.25rem !important;
            backdrop-filter: blur(12px) !important;
            transition: all 0.35s cubic-bezier(0.4, 0, 0.2, 1) !important;
            position: relative;
            overflow: hidden;
        }
        .feature-card-modern::before {
            content: '';
            position: absolute;
            top: 0; left: 0; right: 0;
            height: 3px;
            background: linear-gradient(90deg, transparent, #2AB5A3, transparent);
            opacity: 0;
            transition: opacity 0.35s ease;
        }
        .feature-card-modern:hover {
            transform: translateY(-8px) !important;
            border-color: rgba(42, 181, 163, 0.4) !important;
            box-shadow: 0 20px 40px rgba(42, 181, 163, 0.15) !important;
            background: rgba(30, 41, 59, 0.7) !important;
        }
        .feature-card-modern:hover::before {
            opacity: 1;
        }
        .feature-title {
            color: #ffffff !important;
            font-size: 1.35rem !important;
            font-weight: 700 !important;
            margin-top: 1.25rem !important;
            margin-bottom: 0.75rem !important;
        }
        .feature-desc {
            color: #94A3B8 !important;
            font-size: 0.95rem !important;
            line-height: 1.6 !important;
            margin-bottom: 0 !important;
        }
        .feature-icon {
            width: 60px !important;
            height: 60px !important;
            border-radius: 16px !important;
            background: linear-gradient(135deg, rgba(42, 181, 163, 0.2), rgba(32, 138, 124, 0.05)) !important;
            border: 1px solid rgba(42, 181, 163, 0.3) !important;
            color: #2AB5A3 !important;
            font-size: 1.6rem !important;
            display: flex !important;
            align-items: center !important;
            justify-content: center !important;
            transition: all 0.35s ease !important;
        }
        .feature-card-modern:hover .feature-icon {
            transform: scale(1.1) rotate(5deg) !important;
            background: linear-gradient(135deg, rgba(42, 181, 163, 0.35), rgba(32, 138, 124, 0.15)) !important;
            box-shadow: 0 0 20px rgba(42, 181, 163, 0.3) !important;
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
                <a href="${pageContext.request.contextPath}/login.jsp" class="nav-link text-white-50 text-decoration-none small">Đăng nhập</a>
                <a href="${pageContext.request.contextPath}/register.jsp" class="nav-link text-white-50 text-decoration-none small">Đăng ký</a>
                <a href="${pageContext.request.contextPath}/login.jsp" class="btn-primary-nav text-white text-decoration-none small fw-bold px-4 py-2" style="background: linear-gradient(135deg, #2AB5A3, #208A7C); border-radius: 50px; box-shadow: 0 4px 15px rgba(42, 181, 163, 0.4);">BẮT ĐẦU CHAT AI</a>
            </div>
        </div>
    </nav>

    <section class="hero-modern text-white py-5">
        <div class="container position-relative z-2 py-4" style="max-width: 1280px;">
            <div class="row align-items-center g-5">
                <!-- Left Column: Content -->
                <div class="col-lg-6 text-center text-lg-start">
                    
                    <!-- Pill Badge -->
                    <div class="badge-glow px-4 py-2 mb-3 rounded-pill d-inline-flex align-items-center gap-2" style="background: rgba(42, 181, 163, 0.12); border: 1px solid rgba(42, 181, 163, 0.3); color: #2AB5A3; font-size: 0.85rem; font-weight: 600; letter-spacing: 0.05em; backdrop-filter: blur(10px);">
                        <i class="bi bi-shield-fill-check fs-6"></i> NỀN TẢNG CHĂM SÓC SỨC KHỎE THÔNG MINH 4.0
                    </div>

                    <!-- Title -->
                    <h1 class="hero-title text-white text-uppercase fw-extrabold mb-3" style="font-size: clamp(2.2rem, 3.8vw, 3.4rem); line-height: 1.18; letter-spacing: -0.02em; font-weight: 800;">
                        GIÁM SÁT TIỂU ĐƯỜNG <br>
                        <span style="background: linear-gradient(135deg, #2AB5A3 0%, #00D2D3 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text;">VÀ CẢNH BÁO SỚM</span>
                    </h1>

                    <!-- Description -->
                    <p class="hero-description text-white-50 mb-4" style="font-size: 1.08rem; line-height: 1.7; max-width: 540px; opacity: 0.88;">
                        Hệ thống y tế AI thông minh giúp theo dõi hồ sơ sức khỏe toàn diện, hỗ trợ phát hiện sớm nguy cơ tiểu đường, và kết nối bệnh nhân trực tiếp với bác sĩ chuyên khoa để có kết luận chính xác nhất.
                    </p>

                    <!-- Primary Action Button -->
                    <div class="hero-buttons mb-4">
                        <a href="${pageContext.request.contextPath}/login.jsp" class="btn btn-hero-start text-white text-decoration-none fw-bold px-5 py-3 rounded-pill d-inline-flex align-items-center gap-3" style="background: linear-gradient(135deg, #2AB5A3, #208A7C); font-size: 1rem; letter-spacing: 0.03em; transition: all 0.3s ease; box-shadow: 0 10px 30px rgba(42, 181, 163, 0.45);">
                            BẮT ĐẦU NGAY <i class="bi bi-arrow-right fs-5"></i>
                        </a>
                    </div>

                    <!-- Trust Feature Highlights -->
                    <div class="d-flex flex-wrap justify-content-center justify-content-lg-start gap-4 text-white-50 small" style="opacity: 0.85; font-size: 0.88rem;">
                        <span class="d-inline-flex align-items-center gap-2"><i class="bi bi-cpu-fill" style="color: #2AB5A3;"></i> AI Phân Tích Chỉ Số</span>
                        <span class="d-inline-flex align-items-center gap-2"><i class="bi bi-shield-lock-fill" style="color: #2AB5A3;"></i> Bảo Mật Y Tế</span>
                        <span class="d-inline-flex align-items-center gap-2"><i class="bi bi-person-heart" style="color: #2AB5A3;"></i> Bác Sĩ Tư Vấn</span>
                    </div>

                </div>

                <!-- Right Column: Medical Team Image -->
                <div class="col-lg-6">
                    <div class="position-relative">
                        <div class="hero-image-wrapper p-2 rounded-4" style="background: rgba(255, 255, 255, 0.05); border: 1px solid rgba(255, 255, 255, 0.12); backdrop-filter: blur(12px); box-shadow: 0 25px 60px rgba(0, 0, 0, 0.5);">
                            <img src="${pageContext.request.contextPath}/assets/images/hero-medical-team.png" alt="Đội ngũ y bác sĩ DiabetesCare" class="img-fluid rounded-3 w-100" style="object-fit: cover; max-height: 440px;" />
                        </div>
                        
                        <!-- Floating Experience Badge -->
                        <div class="position-absolute bottom-0 start-0 translate-middle-y ms-3 p-3 rounded-3 text-start shadow-lg d-none d-sm-flex align-items-center gap-3" style="background: rgba(15, 23, 42, 0.92); border: 1px solid rgba(42, 181, 163, 0.35); backdrop-filter: blur(16px); z-index: 3;">
                            <div class="d-flex align-items-center justify-content-center rounded-circle" style="width: 44px; height: 44px; background: rgba(42, 181, 163, 0.2); color: #2AB5A3;">
                                <i class="bi bi-patch-check-fill fs-4"></i>
                            </div>
                            <div>
                                <div class="fw-bold text-white small">Đội Ngũ Y Bác Sĩ Chuyên Khoa</div>
                                <div class="text-white-50" style="font-size: 0.78rem;">Sẵn sàng hỗ trợ & chẩn đoán 24/7</div>
                            </div>
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
                    <i class="bi bi-person-vcard-fill"></i>
                </div>
                <h3 class="feature-title">Đăng ký bệnh nhân</h3>
                <p class="feature-desc">Quy trình đăng ký đơn giản, giúp bệnh nhân dễ dàng tạo và quản lý hồ sơ thông tin sức khỏe cá nhân.</p>
                <div class="feature-link mt-3 pt-3 border-top border-secondary border-opacity-10 d-flex align-items-center gap-2 text-primary small fw-bold" style="color: #2AB5A3 !important;">
                    <span>Khám phá ngay</span> <i class="bi bi-arrow-right"></i>
                </div>
            </div>
            <div class="feature-card-modern">
                <div class="feature-icon">
                    <i class="bi bi-shield-check"></i>
                </div>
                <h3 class="feature-title">Đánh giá nguy cơ</h3>
                <p class="feature-desc">Hỗ trợ phát hiện sớm nguy cơ tiểu đường dựa trên các chỉ số xét nghiệm y tế và thông tin lâm sàng chuẩn xác.</p>
                <div class="feature-link mt-3 pt-3 border-top border-secondary border-opacity-10 d-flex align-items-center gap-2 text-primary small fw-bold" style="color: #2AB5A3 !important;">
                    <span>Tầm soát AI</span> <i class="bi bi-arrow-right"></i>
                </div>
            </div>
            <div class="feature-card-modern">
                <div class="feature-icon">
                    <i class="bi bi-robot"></i>
                </div>
                <h3 class="feature-title">Chat AI</h3>
                <p class="feature-desc">Hỗ trợ bệnh nhân mô tả triệu chứng, tự động tóm tắt dữ liệu y khoa để bác sĩ tham khảo nhanh chóng.</p>
                <div class="feature-link mt-3 pt-3 border-top border-secondary border-opacity-10 d-flex align-items-center gap-2 text-primary small fw-bold" style="color: #2AB5A3 !important;">
                    <span>Trò chuyện ngay</span> <i class="bi bi-arrow-right"></i>
                </div>
            </div>
        </div>
    </section>

    <section class="complications-section py-5" id="about" style="background: linear-gradient(180deg, #0F172A 0%, #0B0F19 100%) !important; border-top: 1px solid rgba(255, 255, 255, 0.04);">
        <div class="container py-4">
            <div class="section-header text-center mb-5">
                <div class="section-tag d-inline-flex align-items-center gap-1 mb-2 px-3 py-1 rounded-pill small" style="background: rgba(42, 181, 163, 0.15); border: 1px solid rgba(42, 181, 163, 0.3); color: #2AB5A3;">
                    <i class="bi bi-hospital-fill"></i>
                    <span class="fw-semibold">Về chúng tôi</span>
                </div>
                <h2 class="section-title fw-bold text-white mt-2 mb-3">Trung Tâm Y Tế Chuyên Khoa DiabetesCare</h2>
                <p class="section-subtitle text-white-50 mx-auto" style="max-width: 800px; font-size: 1.05rem; line-height: 1.6;">
                    Cơ sở y tế đạt chuẩn quốc tế hàng đầu về chẩn đoán, tầm soát và điều trị tiểu đường. Kết hợp giữa đội ngũ y bác sĩ đầu ngành và công nghệ AI tiên tiến.
                </p>
            </div>
            
            <div class="row g-4 align-items-stretch">
                <!-- Left Column: Hospital Info, Location & Ratings -->
                <div class="col-lg-6">
                    <div class="h-100 p-4 rounded-4" style="background: rgba(30, 41, 59, 0.45); border: 1px solid rgba(255, 255, 255, 0.08); backdrop-filter: blur(12px);">
                        <div class="d-flex align-items-center gap-3 mb-4">
                            <div class="p-3 rounded-3" style="background: linear-gradient(135deg, rgba(42, 181, 163, 0.2), rgba(32, 138, 124, 0.05)); border: 1px solid rgba(42, 181, 163, 0.3); color: #2AB5A3; font-size: 1.8rem;">
                                <i class="bi bi-geo-alt-fill"></i>
                            </div>
                            <div>
                                <h3 class="h5 fw-bold text-white mb-1">Vị Trí & Hạ Tầng Hiện Đại</h3>
                                <p class="text-white-50 small mb-0">Trung tâm Y tế Cao cấp • Kết nối thuận tiện 24/7</p>
                            </div>
                        </div>

                        <ul class="list-unstyled d-flex flex-column gap-3 text-white-50 small mb-4">
                            <li class="d-flex align-items-start gap-2">
                                <i class="bi bi-pin-map-fill fs-5" style="color: #2AB5A3 !important;"></i>
                                <div><strong class="text-white">Địa chỉ:</strong> Số 188 Phố Y Học, Phường Trung Hòa, Quận Cầu Giấy, Hà Nội.</div>
                            </li>
                            <li class="d-flex align-items-start gap-2">
                                <i class="bi bi-building-check fs-5" style="color: #2AB5A3 !important;"></i>
                                <div><strong class="text-white">Quy mô:</strong> Phức hợp y tế khép kín với hệ thống phòng xét nghiệm ISO 15189 tự động.</div>
                            </li>
                            <li class="d-flex align-items-start gap-2">
                                <i class="bi bi-clock-history fs-5" style="color: #2AB5A3 !important;"></i>
                                <div><strong class="text-white">Thời gian hoạt động:</strong> Thứ 2 - Chủ Nhật (7:00 - 20:00). Tiếp nhận cấp cứu & Tư vấn AI 24/7.</div>
                            </li>
                        </ul>

                        <!-- Ratings Box -->
                        <div class="p-3 rounded-3" style="background: rgba(42, 181, 163, 0.08); border: 1px solid rgba(42, 181, 163, 0.2);">
                            <div class="d-flex align-items-center justify-content-between">
                                <div>
                                    <div class="d-flex align-items-center gap-1 text-warning mb-1">
                                        <i class="bi bi-star-fill"></i>
                                        <i class="bi bi-star-fill"></i>
                                        <i class="bi bi-star-fill"></i>
                                        <i class="bi bi-star-fill"></i>
                                        <i class="bi bi-star-fill"></i>
                                        <span class="fw-bold text-white ms-2">4.9 / 5.0</span>
                                    </div>
                                    <div class="text-white-50" style="font-size: 0.75rem;">Đánh giá chất lượng dịch vụ từ bệnh nhân</div>
                                </div>
                                <div class="text-end">
                                    <span class="badge" style="background: rgba(42, 181, 163, 0.25); color: #2AB5A3; border: 1px solid rgba(42, 181, 163, 0.4); font-size: 0.75rem;">12.500+ Đánh giá</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Right Column: Expert Medical Team & Standards -->
                <div class="col-lg-6">
                    <div class="h-100 p-4 rounded-4" style="background: rgba(30, 41, 59, 0.45); border: 1px solid rgba(255, 255, 255, 0.08); backdrop-filter: blur(12px);">
                        <div class="d-flex align-items-center gap-3 mb-4">
                            <div class="p-3 rounded-3" style="background: linear-gradient(135deg, rgba(42, 181, 163, 0.2), rgba(32, 138, 124, 0.05)); border: 1px solid rgba(42, 181, 163, 0.3); color: #2AB5A3; font-size: 1.8rem;">
                                <i class="bi bi-person-badge-fill"></i>
                            </div>
                            <div>
                                <h3 class="h5 fw-bold text-white mb-1">Đội Ngũ Bác Sĩ Chuyên Khoa Đầu Ngành</h3>
                                <p class="text-white-50 small mb-0">Phó Giáo Sư • Tiến Sĩ • Bác Sĩ Chuyên Khoa II</p>
                            </div>
                        </div>

                        <div class="row g-3 mb-4">
                            <div class="col-sm-6">
                                <div class="p-3 rounded-3" style="background: rgba(255, 255, 255, 0.03); border: 1px solid rgba(255, 255, 255, 0.05);">
                                    <div class="h4 fw-bold mb-1" style="color: #2AB5A3;">50+ Bác sĩ</div>
                                    <p class="text-white-50 small mb-0">Trên 15 - 25 năm kinh nghiệm điều trị Nội tiết.</p>
                                </div>
                            </div>
                            <div class="col-sm-6">
                                <div class="p-3 rounded-3" style="background: rgba(255, 255, 255, 0.03); border: 1px solid rgba(255, 255, 255, 0.05);">
                                    <div class="h4 fw-bold mb-1" style="color: #2AB5A3;">100% Chuẩn Y Khoa</div>
                                    <p class="text-white-50 small mb-0">Tuân thủ phác đồ khuyến cáo của Bộ Y Tế & ADA.</p>
                                </div>
                            </div>
                        </div>

                        <div class="p-3 rounded-3" style="background: rgba(255, 255, 255, 0.03); border: 1px solid rgba(255, 255, 255, 0.05);">
                            <div class="fw-bold text-white small mb-2"><i class="bi bi-award-fill text-warning me-1"></i> Cam Kết Chất Lượng Khám Chữa Bệnh:</div>
                            <ul class="list-unstyled mb-0 text-white-50 small d-flex flex-column gap-1">
                                <li><i class="bi bi-check2 me-1" style="color: #2AB5A3 !important;"></i> Chẩn đoán chính xác kết hợp phân tích thuật toán AI y tế.</li>
                                <li><i class="bi bi-check2 me-1" style="color: #2AB5A3 !important;"></i> Bảo mật tuyệt đối dữ liệu hồ sơ bệnh án theo chuẩn HIPAA.</li>
                                <li><i class="bi bi-check2 me-1" style="color: #2AB5A3 !important;"></i> Hỗ trợ bác sĩ theo dõi sát sao chỉ số sinh hiệu từng ngày.</li>
                            </ul>
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

    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/public/home.js?v=20260709-fontfix2"></script>
</body>
</html>
