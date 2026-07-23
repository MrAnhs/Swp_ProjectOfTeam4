<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="app-context-path" content="${pageContext.request.contextPath}">
    <title>N&#7897;p h&#7891; s&#417; s&#7913;c kh&#7887;e - DiabetesCare</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css?v=20260721-ui2">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/layouts/patient-shell.css?v=20260721-ui2">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/patient/patient-pages.css?v=20260721-ui2">
</head>
<body>
    <c:set var="activePatientPage" value="submit-record" />
    <%@ include file="/WEB-INF/views/components/patient/sidebar.jspf" %>
    <main class="main-content-dash">
        <header class="page-header"><div><p class="page-eyebrow">H&#7891; s&#417; s&#7913;c kh&#7887;e</p><h1>N&#7897;p h&#7891; s&#417; th&#7911; c&#244;ng</h1><p>Nh&#7853;p c&#225;c ch&#7881; s&#7889; b&#7841;n &#273;ang c&#243;. C&#225;c tr&#432;&#7901;ng kh&#244;ng c&#243; d&#7919; li&#7879;u c&#243; th&#7875; &#273;&#7875; tr&#7889;ng.</p></div></header>
        <section class="page-card">
            <form id="healthRecordForm" class="stack-form">
                <h2>Ch&#7881; s&#7889; x&#233;t nghi&#7879;m</h2>
                <div class="form-grid">
                    <label>Urea (mmol/L)<input type="number" step="0.01" min="0.5" max="60" name="urea"></label>
                    <label>Creatinine (&micro;mol/L)<input type="number" step="0.01" min="10" max="2000" name="creatinine"></label>
                    <label>HbA1c (%)<input type="number" step="0.01" min="2" max="25" name="hba1c"></label>
                    <label>Cholesterol (mmol/L)<input type="number" step="0.01" min="0.5" max="25" name="cholesterol"></label>
                    <label>Triglycerides (mmol/L)<input type="number" step="0.01" min="0.1" max="50" name="tg"></label>
                    <label>HDL (mmol/L)<input type="number" step="0.01" min="0.1" max="5" name="hdl"></label>
                    <label>LDL (mmol/L)<input type="number" step="0.01" min="0.1" max="15" name="ldl"></label>
                    <label>VLDL (mmol/L)<input type="number" step="0.01" min="0" name="vldl"></label>
                </div>
                <h2>Th&#244;ng tin c&#417; th&#7875;</h2>
                <div class="form-grid">
                    <label>C&#226;n n&#7863;ng (kg)<input id="weight" type="number" step="0.1" max="800" name="weight"></label>
                    <label>Chi&#7873;u cao (cm)<input id="height" type="number" step="0.1" max="300" name="height"></label>
                    <label>BMI<input id="bmi" type="number" step="0.01" name="bmi" readonly></label>
                </div>
                <label class="form-field-full">Tri&#7879;u ch&#7913;ng v&#224; th&#244;ng tin kh&#225;c
                    <textarea name="symptoms" rows="4" placeholder="M&#244; t&#7843; tri&#7879;u ch&#7913;ng hi&#7879;n t&#7841;i..."></textarea>
                </label>
                <p id="formMessage" class="form-message"></p>
                <button class="btn-primary" type="submit"><i class="bi bi-send"></i> G&#7917;i h&#7891; s&#417;</button>
            </form>
        </section>
    </main>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/app-config.js?v=20260710-patient-fontfix-all2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/api-client.js?v=20260710-patient-fontfix-all2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/patient/health-record-form.js?v=20260710-patient-fontfix-all2"></script>
</body>
</html>