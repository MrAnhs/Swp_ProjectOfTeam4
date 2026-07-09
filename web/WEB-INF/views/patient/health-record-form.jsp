<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="app-context-path" content="${pageContext.request.contextPath}">
    <title>Nộp hồ sơ sức khỏe - DiabetesCare</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/layouts/patient-shell.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/patient/patient-pages.css">
</head>
<body>
    <c:set var="activePatientPage" value="new-record" />
    <%@ include file="/WEB-INF/views/components/patient/sidebar.jspf" %>

    <main class="main-content-dash">
        <header class="page-header">
            <div>
                <p class="page-eyebrow">Hồ sơ sức khỏe</p>
                <h1>Nộp hồ sơ mới</h1>
                <p>Nhập các chỉ số bạn đang có. Các trường không có dữ liệu có thể để trống.</p>
            </div>
            <a class="btn-page-secondary" href="${pageContext.request.contextPath}/patient/ai-chat">
                <i class="bi bi-robot"></i> Thu thập dữ liệu qua AI
            </a>
        </header>

        <section class="page-card">
            <form id="healthRecordForm" class="record-form">
                <h2>Chỉ số xét nghiệm</h2>
                <div class="form-grid form-grid--four">
                    <label>Urea (mmol/L)<input type="number" step="0.01" min="0.5" max="60" name="urea"></label>
                    <label>Creatinine (µmol/L)<input type="number" step="0.01" min="10" max="2000" name="creatinine"></label>
                    <label>HbA1c (%)<input type="number" step="0.01" min="2" max="25" name="hba1c"></label>
                    <label>Cholesterol (mmol/L)<input type="number" step="0.01" min="0.5" max="25" name="cholesterol"></label>
                    <label>Triglycerides (mmol/L)<input type="number" step="0.01" min="0.1" max="50" name="tg"></label>
                    <label>HDL (mmol/L)<input type="number" step="0.01" min="0.1" max="5" name="hdl"></label>
                    <label>LDL (mmol/L)<input type="number" step="0.01" min="0.1" max="15" name="ldl"></label>
                    <label>VLDL (mmol/L)<input type="number" step="0.01" name="vldl"></label>
                </div>

                <h2>Thông tin cơ thể</h2>
                <div class="form-grid form-grid--three">
                    <label>Cân nặng (kg)<input id="weight" type="number" step="0.1" max="800" name="weight"></label>
                    <label>Chiều cao (cm)<input id="height" type="number" step="0.1" max="300" name="height"></label>
                    <label>BMI<input id="bmi" type="number" step="0.01" readonly></label>
                </div>

                <label class="form-field-full">Triệu chứng và thông tin khác
                    <textarea name="symptoms" rows="4" placeholder="Mô tả triệu chứng hiện tại..."></textarea>
                </label>

                <div id="formMessage" class="form-message" hidden></div>
                <div class="form-actions">
                    <button type="reset" class="btn-page-secondary">Nhập lại</button>
                    <button type="submit" class="btn-page-primary"><i class="bi bi-send"></i> Gửi hồ sơ</button>
                </div>
            </form>
        </section>
    </main>

    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/app-config.js"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/api-client.js"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/patient/health-record-form.js"></script>
</body>
</html>
