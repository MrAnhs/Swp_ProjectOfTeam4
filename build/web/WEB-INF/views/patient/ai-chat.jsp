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
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/layouts/patient-shell.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/patient/ai-chat.css">
</head>
<body>
    <c:set var="activePatientPage" value="ai-chat" />
    <%@ include file="/WEB-INF/views/components/patient/sidebar.jspf" %>

    <main class="main-content-dash">
        <header class="chat-page-header">
            <div><span>Tr&#7907; l&#253; s&#7913;c kh&#7887;e</span><h1>Chat v&#7899;i AI</h1><p>Trao &#273;&#7893;i tri&#7879;u ch&#7913;ng v&#224; thu th&#7853;p d&#7919; li&#7879;u &#273;&#7875; t&#7841;o h&#7891; s&#417; s&#7913;c kh&#7887;e.</p></div>
            <strong><i class="bi bi-circle-fill"></i> AI &#273;ang ho&#7841;t &#273;&#7897;ng</strong>
        </header>

        <div class="chat-layout">
            <section class="chat-container">
                <div class="chat-messages" id="chatWindow">
                    <div class="message incoming">
                        <div class="message-avatar ai"><i class="bi bi-robot"></i></div>
                        <div class="message-content">
                            <div class="message-bubble">Xin ch&#224;o! H&#227;y cho t&#244;i bi&#7871;t t&#236;nh tr&#7841;ng s&#7913;c kh&#7887;e ho&#7863;c c&#225;c ch&#7881; s&#7889; x&#233;t nghi&#7879;m g&#7847;n nh&#7845;t c&#7911;a b&#7841;n.</div>
                            <div class="message-time">V&#7915;a xong</div>
                        </div>
                    </div>
                    <c:if test="${reachedLimit}">
                        <div class="message incoming">
                            <div class="message-avatar ai"><i class="bi bi-robot"></i></div>
                            <div class="message-content">
                                <div class="message-bubble text-danger fw-bold">B&#7841;n &#273;&#227; &#273;&#7841;t gi&#7899;i h&#7841;n 10 l&#432;&#7907;t trao &#273;&#7893;i tin nh&#7855;n v&#7899;i Tr&#7907; l&#253; AI trong phi&#234;n n&#224;y. Vui l&#242;ng b&#7845;m "T&#7841;o h&#7891; s&#417; t&#7915; cu&#7897;c tr&#242; chuy&#7879;n" &#7903; b&#234;n ph&#7843;i &#273;&#7875; g&#7917;i th&#244;ng tin cho b&#225;c s&#297;.</div>
                                <div class="message-time">V&#7915;a xong</div>
                            </div>
                        </div>
                    </c:if>
                </div>
                <div class="chat-input-area">
                    <form class="chat-form" id="chatForm">
                        <input class="chat-input" id="chatInput" placeholder="${reachedLimit ? '&#272;&#227; &#273;&#7841;t gi&#7899;i h&#7841;n tin nh&#7855;n. Vui l&#242;ng t&#7841;o h&#7891; s&#417;.' : 'Nh&#7853;p tin nh&#7855;n...'}" autocomplete="off" required ${reachedLimit ? 'disabled' : ''}>
                        <button type="submit" class="btn-send" ${reachedLimit ? 'disabled' : ''}><i class="bi bi-send-fill"></i> G&#7917;i</button>
                    </form>
                </div>
            </section>

            <aside class="info-panel">
                <div class="panel-card">
                    <h2><i class="bi bi-heart-pulse"></i> D&#7919; li&#7879;u AI &#273;&#227; thu th&#7853;p</h2>
                    <div class="mini-health-form">
                        <label>Urea<input type="number" id="chatUrea" readonly placeholder="-"></label>
                        <label>Creatinine<input type="number" id="chatCr" readonly placeholder="-"></label>
                        <label>HbA1c<input type="number" id="chatHba1c" readonly placeholder="-"></label>
                        <label>Cholesterol<input type="number" id="chatChol" readonly placeholder="-"></label>
                        <label>Triglycerides<input type="number" id="chatTg" readonly placeholder="-"></label>
                        <label>HDL<input type="number" id="chatHdl" readonly placeholder="-"></label>
                        <label>LDL<input type="number" id="chatLdl" readonly placeholder="-"></label>
                        <label>VLDL<input type="number" id="chatVldl" readonly placeholder="-"></label>
                        <label>C&#226;n n&#7863;ng<input type="number" id="chatWeight" readonly placeholder="-"></label>
                        <label>Chi&#7873;u cao<input type="number" id="chatHeight" readonly placeholder="-"></label>
                        <label class="full-width">Tri&#7879;u ch&#7913;ng<textarea id="chatSymptoms" readonly rows="3" placeholder="-"></textarea></label>
                    </div>
                    <button type="button" class="btn-submit-health" onclick="submitHealthRecordFromChat()">
                        <i class="bi bi-check-circle"></i> T&#7841;o h&#7891; s&#417; t&#7915; cu&#7897;c tr&#242; chuy&#7879;n
                    </button>
                </div>
            </aside>
        </div>
    </main>

    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/app-config.js?v=20260710-patient-fontfix-all2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/api-client.js?v=20260710-patient-fontfix-all2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/patient/ai-chat.js?v=20260710-patient-fontfix-all2"></script>
</body>
</html>