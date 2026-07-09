package com.diabetes.monitoring.doctorlab;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

public class DoctorLabServlet extends HttpServlet {
    private final DoctorLabService service = new DoctorLabService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String status = request.getParameter("status");
        if (status == null || status.trim().isEmpty()) {
            status = "All";
        }
        request.setAttribute("selectedStatus", status);
        request.setAttribute("statusCounts", service.getStatusCounts());
        request.setAttribute("requests", service.getRequests(status));
        request.getRequestDispatcher("/WEB-INF/views/doctor-lab/dashboard.jsp")
                .forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        String action = request.getParameter("action");
        int invoiceDetailId = parseId(request.getParameter("invoiceDetailId"));

        try {
            if (invoiceDetailId <= 0) {
                throw new IllegalArgumentException("Mã yêu cầu xét nghiệm không hợp lệ.");
            }
            if ("start".equals(action)) {
                if (!service.startProcessing(invoiceDetailId)) {
                    throw new IllegalStateException("Yêu cầu không còn ở trạng thái chờ xét nghiệm.");
                }
                request.getSession().setAttribute("doctorLabMessage",
                        "Đã chuyển yêu cầu #" + invoiceDetailId + " sang trạng thái đang xử lý.");
            } else if ("complete-random".equals(action)) {
                service.completeRandom(invoiceDetailId);
                request.getSession().setAttribute("doctorLabMessage",
                        "Đã sinh và lưu kết quả xét nghiệm cho yêu cầu #" + invoiceDetailId + ".");
            } else if ("complete".equals(action)) {
                LabRequest labRequest = buildManualRequest(request, invoiceDetailId);
                service.completeManual(labRequest);
                request.getSession().setAttribute("doctorLabMessage",
                        "Đã lưu kết quả xét nghiệm cho yêu cầu #" + invoiceDetailId + ".");
            } else {
                throw new IllegalArgumentException("Thao tác không hợp lệ.");
            }
        } catch (Exception e) {
            request.getSession().setAttribute("doctorLabError",
                    e.getMessage() == null ? "Không thể xử lý yêu cầu." : e.getMessage());
        }

        response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard");
    }

    private LabRequest buildManualRequest(HttpServletRequest request, int invoiceDetailId) {
        LabRequest labRequest = new LabRequest();
        labRequest.setInvoiceDetailId(invoiceDetailId);
        labRequest.setUrea(parseDouble(request.getParameter("urea")));
        labRequest.setCr(parseDouble(request.getParameter("cr")));
        labRequest.setHba1c(parseDouble(request.getParameter("hba1c")));
        labRequest.setChol(parseDouble(request.getParameter("chol")));
        labRequest.setTg(parseDouble(request.getParameter("tg")));
        labRequest.setHdl(parseDouble(request.getParameter("hdl")));
        labRequest.setLdl(parseDouble(request.getParameter("ldl")));
        labRequest.setVldl(parseDouble(request.getParameter("vldl")));
        labRequest.setWeight(parseDouble(request.getParameter("weight")));
        labRequest.setHeight(parseDouble(request.getParameter("height")));
        labRequest.setBmi(parseDouble(request.getParameter("bmi")));
        return labRequest;
    }

    private int parseId(String raw) {
        if (raw == null || raw.trim().isEmpty()) {
            return 0;
        }
        return Integer.parseInt(raw.trim());
    }

    private Double parseDouble(String raw) {
        if (raw == null || raw.trim().isEmpty()) {
            return null;
        }
        return Double.valueOf(raw.trim());
    }
}
