(function (window) {
    const STATUS_META = {
        Waiting: { label: "Chờ khám", className: "waiting" },
        In_Progress: { label: "Đang khám", className: "in-progress" },
        Completed: { label: "Đã hoàn thành", className: "completed" },
        Cancelled: { label: "Đã hủy", className: "cancelled" },
        Absent: { label: "Vắng mặt", className: "absent" }
    };

    window.PatientAppointmentStatus = {
        get(status) {
            return STATUS_META[status] || { label: status || "Không xác định", className: "" };
        }
    };
})(window);
