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
            <div><span>Trợ lý sức khỏe</span><h1>Chat với AI</h1><p>Trao đổi triệu chứng và thông tin sức khỏe để hỗ trợ bác sĩ trong quá trình khám.</p></div>
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
                </div>
                <div class="chat-input-area">
                    <form class="chat-form" id="chatForm">
                        <input class="chat-input" id="chatInput" placeholder="Nhập tin nhắn..." autocomplete="off" required>
                        <button type="submit" class="btn-send"><i class="bi bi-send-fill"></i> Gửi</button>
                    </form>
                    <button type="button" class="btn-page-secondary finish-chat-button"
                            id="finishChatButton" hidden>
                        <i class="bi bi-check-circle"></i> Kết thúc và tạo tóm tắt
                    </button>
                </div>
            </section>

            <aside class="info-panel">
                <div class="panel-card">
                    <h2><i class="bi bi-info-circle"></i> Mục đích cuộc trò chuyện</h2>
                    <p class="chat-guidance">
                        Hãy mô tả triệu chứng, thời điểm xuất hiện, mức độ và tiền sử liên quan.
                        Nội dung quan trọng sẽ được tổng hợp để bác sĩ phụ trách tham khảo.
                    </p>
                    <p class="chat-warning">
                        Chat AI không thay thế chẩn đoán hoặc chỉ định chính thức của bác sĩ.
                    </p>
                </div>
            </aside>
        </div>
    </main>

    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/app-config.js?v=20260709-fontfix2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/api-client.js?v=20260709-fontfix2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/patient/ai-chat.js?v=20260709-fontfix2"></script>
</body>
</html>
