<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="app-context-path" content="${pageContext.request.contextPath}">
    <title>Chat AI - DiabetesCare</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/layouts/patient-shell.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/patient/ai-chat.css">
</head>
<body>
    <c:set var="activePatientPage" value="ai-chat" />
    <%@ include file="/WEB-INF/views/components/patient/sidebar.jspf" %>

    <main class="main-content-dash">
        <header class="chat-page-header">
            <div><span>Trợ lý sức khỏe</span><h1>Chat với AI</h1><p>Trao đổi triệu chứng và thu thập dữ liệu để tạo hồ sơ sức khỏe.</p></div>
            <strong><i class="bi bi-circle-fill"></i> AI đang hoạt động</strong>
        </header>

        <div class="chat-layout">
            <section class="chat-container">
                <div class="chat-messages" id="chatWindow">
                    <div class="message incoming">
                        <div class="message-avatar ai"><i class="bi bi-robot"></i></div>
                        <div class="message-content">
                            <div class="message-bubble">Xin chào! Hãy cho tôi biết tình trạng sức khỏe hoặc các chỉ số xét nghiệm gần nhất của bạn.</div>
                            <div class="message-time">Vừa xong</div>
                        </div>
                    </div>
                    <c:if test="${reachedLimit}">
                        <div class="message incoming">
                            <div class="message-avatar ai"><i class="bi bi-robot"></i></div>
                            <div class="message-content">
                                <div class="message-bubble text-danger fw-bold">Bạn đã đạt giới hạn 10 lượt trao đổi tin nhắn với Trợ lý AI trong phiên này. Vui lòng bấm "Tạo hồ sơ từ cuộc trò chuyện" ở bên phải để gửi thông tin cho bác sĩ.</div>
                                <div class="message-time">Vừa xong</div>
                            </div>
                        </div>
                    </c:if>
                </div>
                <div class="chat-input-area">
                    <form class="chat-form" id="chatForm">
                        <input class="chat-input" id="chatInput" placeholder="${reachedLimit ? 'Đã đạt giới hạn tin nhắn. Vui lòng tạo hồ sơ.' : 'Nhập tin nhắn...'}" autocomplete="off" required ${reachedLimit ? 'disabled' : ''}>
                        <button type="submit" class="btn-send" ${reachedLimit ? 'disabled' : ''}><i class="bi bi-send-fill"></i> Gửi</button>
                    </form>
                </div>
            </section>

            <aside class="info-panel">
                <div class="panel-card">
                    <h2><i class="bi bi-heart-pulse"></i> Dữ liệu AI đã thu thập</h2>
                    <div class="mini-health-form">
                        <label>Urea<input type="number" id="chatUrea" readonly placeholder="-"></label>
                        <label>Creatinine<input type="number" id="chatCr" readonly placeholder="-"></label>
                        <label>HbA1c<input type="number" id="chatHba1c" readonly placeholder="-"></label>
                        <label>Cholesterol<input type="number" id="chatChol" readonly placeholder="-"></label>
                        <label>Triglycerides<input type="number" id="chatTg" readonly placeholder="-"></label>
                        <label>HDL<input type="number" id="chatHdl" readonly placeholder="-"></label>
                        <label>LDL<input type="number" id="chatLdl" readonly placeholder="-"></label>
                        <label>VLDL<input type="number" id="chatVldl" readonly placeholder="-"></label>
                        <label>Cân nặng<input type="number" id="chatWeight" readonly placeholder="-"></label>
                        <label>Chiều cao<input type="number" id="chatHeight" readonly placeholder="-"></label>
                        <label class="full-width">Triệu chứng<textarea id="chatSymptoms" readonly rows="3" placeholder="-"></textarea></label>
                    </div>
                    <button type="button" class="btn-submit-health" onclick="submitHealthRecordFromChat()">
                        <i class="bi bi-check-circle"></i> Tạo hồ sơ từ cuộc trò chuyện
                    </button>
                </div>
            </aside>
        </div>
    </main>

    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/app-config.js?v=20260709-fontfix4"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/api-client.js?v=20260709-fontfix4"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/patient/ai-chat.js?v=20260709-fontfix4"></script>
</body>
</html>
