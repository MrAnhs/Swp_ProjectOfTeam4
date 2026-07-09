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
</head>
<body>
    <nav class="modern-navbar" id="navbar">
        <div class="nav-container">
            <a href="index.jsp" class="brand">
                <div class="brand-icon">
                    <i class="bi bi-heart-pulse-fill"></i>
                </div>
                <span>DiabetesCare</span>
            </a>
            <div class="nav-links">
                <a href="index.jsp" class="nav-link">Trang chủ</a>
                <a href="login.jsp" class="nav-link">Đăng nhập</a>
                <a href="register.jsp" class="nav-link">Đăng ký</a>
                <div style="position: relative;">
                    <button class="lang-switcher" type="button">
                        <i class="bi bi-globe"></i>
                        <span>Tiếng Việt</span>
                    </button>
                </div>
                <a href="login.jsp" class="btn-primary-nav">Bắt đầu Chat AI</a>
            </div>
        </div>
    </nav>

    <section class="hero-modern">
        <div class="hero-content">
            <div class="hero-text">
                <div class="hero-badge">
                    <i class="bi bi-shield-check"></i>
                    <span>Hệ thống y tế thông minh</span>
                </div>
                <h1 class="hero-title">
                    Giám sát <span>tiểu đường</span> và cảnh báo sớm
                </h1>
                <p class="hero-description">
                    Theo dõi hồ sơ y tế, hỗ trợ phát hiện sớm nguy cơ tiểu đường và giúp bệnh nhân trao đổi thông tin với Chat AI trước khi bác sĩ đưa ra kết luận cuối cùng.
                </p>
                <div class="hero-buttons">
                    <a href="register.jsp" class="btn-hero-primary">
                        <span>Bắt đầu ngay</span>
                        <i class="bi bi-arrow-right"></i>
                    </a>
                    <a href="login.jsp" class="btn-hero-secondary">
                        <i class="bi bi-play-circle"></i>
                        <span>Xem demo</span>
                    </a>
                </div>
            </div>
            <div class="hero-visual">
                <div class="hero-card-modern">
                    <h5 class="fw-bold mb-3 text-dark">
                        <i class="bi bi-activity text-vinmec me-2"></i>Giám sát sức khỏe theo thời gian thực
                    </h5>
                    <p class="text-secondary small mb-4">Theo dõi các chỉ số quan trọng và nhận cảnh báo kịp thời.</p>
                    <div class="d-flex justify-content-between mb-4">
                        <div>
                            <div class="stat-number">98%</div>
                            <div class="stat-label">Độ chính xác</div>
                        </div>
                        <div>
                            <div class="stat-number">24/7</div>
                            <div class="stat-label">Theo dõi</div>
                        </div>
                        <div>
                            <div class="stat-number">15k+</div>
                            <div class="stat-label">Bệnh nhân</div>
                        </div>
                    </div>
                    <div class="progress mb-2" style="height: 8px;">
                        <div class="progress-bar" role="progressbar" style="width: 75%; background: linear-gradient(90deg, #2dbbbc, #239495);"></div>
                    </div>
                    <small class="text-muted">Mức đường huyết: 7.8 mmol/L (Bình thường)</small>
                </div>
                <div class="floating-card floating-card-1">
                    <div class="d-flex align-items-center gap-3">
                        <div class="bg-success rounded-circle p-2">
                            <i class="bi bi-check-lg text-white"></i>
                        </div>
                        <div>
                            <div class="fw-bold text-dark">Kiểm tra sức khỏe</div>
                            <small class="text-muted">Các chỉ số đang ổn định</small>
                        </div>
                    </div>
                </div>
                <div class="floating-card floating-card-2">
                    <div class="d-flex align-items-center gap-2 text-warning">
                        <i class="bi bi-bell-fill"></i>
                        <span class="fw-semibold">3 cảnh báo</span>
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

    <section class="features-section">
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

    <section class="ai-section">
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
                    <h4 class="footer-title">Hỗ trợ</h4>
                    <ul class="footer-links">
                        <li><a href="#">Trung tâm trợ giúp</a></li>
                        <li><a href="#">Chính sách bảo mật</a></li>
                        <li><a href="#">Điều khoản sử dụng</a></li>
                        <li><a href="#">support@diabetescare.edu</a></li>
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
