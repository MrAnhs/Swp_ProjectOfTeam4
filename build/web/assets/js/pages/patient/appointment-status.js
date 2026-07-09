(function (window) {
    const STATUS_META = {
        Waiting: { label: "Ch\u1EDD kh\u00E1m", className: "waiting" },
        In_Progress: { label: "\u0110ang kh\u00E1m", className: "in-progress" },
        Completed: { label: "\u0110\u00E3 ho\u00E0n th\u00E0nh", className: "completed" },
        Cancelled: { label: "\u0110\u00E3 h\u1EE7y", className: "cancelled" },
        Absent: { label: "V\u1EAFng m\u1EB7t", className: "absent" }
    };

    window.PatientAppointmentStatus = {
        get(status) {
            return STATUS_META[status] || { label: status || "Kh\u00F4ng x\u00E1c \u0111\u1ECBnh", className: "" };
        }
    };
})(window);
