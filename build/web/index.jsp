<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>DiabetesCare - Theo dõi và cảnh báo sớm tiểu đường</title>
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
                <a href="login.jsp" class="btn-primary-nav">Vào hệ thống</a>
            </div>
        </div>
    </nav>

    <section class="hero-modern">
        <div class="hero-content">
            <div class="hero-text">
                <div class="hero-badge">
                    <i class="bi bi-shield-check"></i>
                    <span>Hệ thống hỗ trợ chăm sóc sức khỏe</span>
                </div>
                <h1 class="hero-title">
                    Theo dõi và <span>cảnh báo sớm</span> nguy cơ tiểu đường
                </h1>
                <p class="hero-description">
                    Quản lý hồ sơ bệnh nhân, hỗ trợ bác sĩ đánh giá nguy cơ, theo dõi xét nghiệm và giúp bệnh nhân chủ động chăm sóc sức khỏe.
                </p>
                <div class="hero-buttons">
                    <a href="register.jsp" class="btn-hero-primary">
                        <span>Tạo tài khoản</span>
                        <i class="bi bi-arrow-right"></i>
                    </a>
                    <a href="login.jsp" class="btn-hero-secondary">
                        <i class="bi bi-box-arrow-in-right"></i>
                        <span>Đăng nhập</span>
                    </a>
                </div>
            </div>
            <div class="hero-visual">
                <div class="hero-card-modern">
                    <h5 class="fw-bold mb-3 text-dark">
                        <i class="bi bi-activity text-vinmec me-2"></i>Theo dõi sức khỏe
                    </h5>
                    <p class="text-secondary small mb-4">Tổng hợp chỉ số xét nghiệm, lịch khám và cảnh báo nguy cơ trong cùng một hệ thống.</p>
                    <div class="d-flex justify-content-between mb-4">
                        <div>
                            <div class="stat-number">98%</div>
                            <div class="stat-label">Độ ổn định</div>
                        </div>
                        <div>
                            <div class="stat-number">24/7</div>
                            <div class="stat-label">Theo dõi</div>
                        </div>
                        <div>
                            <div class="stat-number">15k+</div>
                            <div class="stat-label">Hồ sơ</div>
                        </div>
                    </div>
                    <div class="progress mb-2" style="height: 8px;">
                        <div class="progress-bar" role="progressbar" style="width: 75%; background: linear-gradient(90deg, #2dbbbc, #239495);"></div>
                    </div>
                    <small class="text-muted">Đường huyết: 7.8 mmol/L - cần theo dõi</small>
                </div>
                <div class="floating-card floating-card-1">
                    <div class="d-flex align-items-center gap-3">
                        <div class="bg-success rounded-circle p-2">
                            <i class="bi bi-check-lg text-white"></i>
                        </div>
                        <div>
                            <div class="fw-bold text-dark">Hồ sơ đã cập nhật</div>
                            <small class="text-muted">Dữ liệu sẵn sàng cho bác sĩ</small>
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
                <div class="stat-card-label">Hồ sơ bệnh nhân</div>
            </div>
            <div class="stat-card-modern">
                <div class="stat-card-number">98%</div>
                <div class="stat-card-label">Quy trình số hóa</div>
            </div>
            <div class="stat-card-modern">
                <div class="stat-card-number">24/7</div>
                <div class="stat-card-label">Theo dõi dữ liệu</div>
            </div>
            <div class="stat-card-modern">
                <div class="stat-card-number">50+</div>
                <div class="stat-card-label">Nhân sự y tế</div>
            </div>
        </div>
    </section>

    <section class="features-section">
        <div class="section-header">
            <div class="section-tag">
                <i class="bi bi-stars"></i>
                <span>Chức năng chính</span>
            </div>
            <h2 class="section-title">Giải pháp quản lý chăm sóc tiểu đường</h2>
            <p class="section-subtitle">Từ tiếp nhận, thanh toán, xét nghiệm đến khám bệnh và theo dõi hồ sơ, mọi bước đều được kết nối rõ ràng.</p>
        </div>
        <div class="features-grid">
            <div class="feature-card-modern">
                <div class="feature-icon"><i class="bi bi-file-medical"></i></div>
                <h3 class="feature-title">Tiếp nhận bệnh nhân</h3>
                <p class="feature-desc">Lễ tân quản lý lịch hẹn, hàng chờ và hóa đơn theo quy trình khám.</p>
            </div>
            <div class="feature-card-modern">
                <div class="feature-icon"><i class="bi bi-clipboard2-pulse"></i></div>
                <h3 class="feature-title">Xét nghiệm</h3>
                <p class="feature-desc">Phòng xét nghiệm nhận chỉ định đã thanh toán, nhập kết quả và đồng bộ vào hồ sơ sức khỏe.</p>
            </div>
            <div class="feature-card-modern">
                <div class="feature-icon"><i class="bi bi-person-vcard"></i></div>
                <h3 class="feature-title">Khám bác sĩ</h3>
                <p class="feature-desc">Bác sĩ xem bệnh án, kết quả xét nghiệm và hoàn tất chẩn đoán cho bệnh nhân.</p>
            </div>
        </div>
    </section>

    <section class="ai-section">
        <div class="ai-container">
            <div class="ai-content">
                <h3 class="ai-title">
                    <i class="bi bi-cpu me-2"></i>Hỗ trợ đánh giá nguy cơ
                </h3>
                <p class="ai-desc">
                    Hệ thống tổng hợp chỉ số sức khỏe như HbA1c, BMI, mỡ máu và chức năng thận để hỗ trợ bác sĩ xem xét nguy cơ tiểu đường.
                </p>
                <ul class="ai-list">
                    <li><i class="bi bi-check"></i>Thu thập dữ liệu sức khỏe có cấu trúc</li>
                    <li><i class="bi bi-check"></i>Gợi ý nguy cơ, không thay thế chẩn đoán</li>
                    <li><i class="bi bi-check"></i>Hiển thị kết quả cho bác sĩ ra quyết định</li>
                    <li><i class="bi bi-check"></i>Theo dõi diễn biến qua từng lần khám</li>
                </ul>
            </div>
            <div class="ai-cards">
                <div class="ai-card-item">
                    <div class="ai-card-icon"><i class="bi bi-heart-pulse"></i></div>
                    <h4 class="ai-card-title">Đánh giá nguy cơ</h4>
                    <p class="ai-card-desc">Phân tích nhiều chỉ số để đưa ra gợi ý hỗ trợ bác sĩ.</p>
                </div>
                <div class="ai-card-item">
                    <div class="ai-card-icon"><i class="bi bi-graph-up-arrow"></i></div>
                    <h4 class="ai-card-title">Theo dõi xu hướng</h4>
                    <p class="ai-card-desc">So sánh dữ liệu qua thời gian để phát hiện thay đổi bất thường.</p>
                </div>
            </div>
        </div>
    </section>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
