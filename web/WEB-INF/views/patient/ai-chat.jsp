<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="chatCount" value="${empty sessionScope.patientChatCount ? 0 : sessionScope.patientChatCount}" />
<c:set var="reachedLimit" value="${chatCount >= 10}" />
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
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css?v=20260721-ui2">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/layouts/patient-shell.css?v=20260721-ui2">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/patient/ai-chat.css?v=20260721-ui2">
</head>
<body>
    <c:set var="activePatientPage" value="ai-chat" />
    <%@ include file="/WEB-INF/views/components/patient/sidebar.jspf" %>

    <main class="main-content-dash">
        <header class="chat-page-header">
            <div>
                <span>Tr&#7907; l&#253; s&#7913;c kh&#7887;e</span>
                <h1>Chat v&#7899;i AI</h1>
                <p>Chia s&#7867; tri&#7879;u ch&#7913;ng &#273;&#7875; b&#225;c s&#297; AI h&#7895; tr&#7907; v&#224; l&#432;u h&#7891; s&#417;.</p>
            </div>
            <strong><i class="bi bi-circle-fill"></i> AI &#273;ang ho&#7841;t &#273;&#7897;ng</strong>
        </header>

        <div class="chat-layout">
            <!-- Khung chat chính -->
            <section class="chat-container">
                <div class="chat-messages" id="chatWindow">
                    <div class="message incoming">
                        <div class="message-avatar ai"><i class="bi bi-robot"></i></div>
                        <div class="message-content">
                            <div class="message-bubble">Xin ch&#224;o! T&#244;i l&#224; B&#225;c s&#297; Tr&#7907; l&#253; AI chuy&#234;n theo d&#245;i b&#7879;nh ti&#7875;u &#273;&#432;&#7901;ng. H&#227;y cho t&#244;i bi&#7871;t t&#236;nh tr&#7841;ng s&#7913;c kh&#7887;e ho&#7863;c c&#225;c tri&#7879;u ch&#7913;ng hi&#7879;n t&#7841;i c&#7911;a b&#7841;n nh&#233;.</div>
                            <div class="message-time">V&#7915;a xong</div>
                        </div>
                    </div>
                    <c:if test="${reachedLimit}">
                        <div class="message incoming">
                            <div class="message-avatar ai"><i class="bi bi-robot"></i></div>
                            <div class="message-content">
                                <div class="message-bubble" style="color:#ef4444;font-weight:600;">B&#7841;n &#273;&#227; &#273;&#7841;t gi&#7899;i h&#7841;n 10 l&#432;&#7907;t tin nh&#7855;n. Vui l&#242;ng b&#7845;m &#8220;L&#432;u tri&#7879;u ch&#7913;ng&#8221; &#7903; b&#234;n ph&#7843;i &#273;&#7875; g&#7917;i th&#244;ng tin cho b&#225;c s&#297;.</div>
                                <div class="message-time">V&#7915;a xong</div>
                            </div>
                        </div>
                    </c:if>
                </div>
                <div class="chat-input-area">
                    <form class="chat-form" id="chatForm">
                        <input class="chat-input" id="chatInput"
                               placeholder="${reachedLimit ? 'Đã đạt giới hạn. Vui lòng lưu triệu chứng.' : 'Nhập triệu chứng hoặc câu hỏi...'}"
                               autocomplete="off" required ${reachedLimit ? 'disabled' : ''}>
                        <button type="submit" class="btn-send" ${reachedLimit ? 'disabled' : ''}>
                            <i class="bi bi-send-fill"></i> G&#7917;i
                        </button>
                    </form>
                </div>
            </section>

            <!-- Panel triệu chứng -->
            <aside class="info-panel">
                <div class="panel-card">
                    <h2><i class="bi bi-clipboard2-pulse"></i> Tri&#7879;u ch&#7913;ng ghi nh&#7853;n</h2>
                    <div class="mini-health-form symptoms-only">
                        <label class="full-width">
                            <span>AI t&#7921; &#273;&#7897;ng c&#7853;p nh&#7853;t khi b&#7841;n nh&#7855;p tin</span>
                            <textarea id="chatSymptoms" readonly rows="8"
                                      placeholder="Tri&#7879;u ch&#7913;ng s&#7869; hi&#7875;n th&#7883; &#7903; &#273;&#226;y khi AI thu th&#7853;p &#273;&#432;&#7907;c..."></textarea>
                        </label>
                    </div>
                    <p class="symptoms-hint">
                        <i class="bi bi-info-circle"></i>
                        AI s&#7869; t&#7893;ng h&#7907;p v&#224; l&#432;u tri&#7879;u ch&#7913;ng v&#224;o h&#7891; s&#417; khi b&#7841;n b&#7845;m n&#250;t b&#234;n d&#432;&#7899;i.
                    </p>
                    <button type="button" class="btn-submit-health" onclick="submitHealthRecordFromChat()">
                        <i class="bi bi-cloud-upload"></i> L&#432;u tri&#7879;u ch&#7913;ng v&#224;o h&#7891; s&#417;
                    </button>
                </div>
            </aside>
        </div>
    </main>

    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/app-config.js?v=20260722-v2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/api-client.js?v=20260722-v2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/patient/ai-chat.js?v=20260722-v2"></script>
</body>
</html>