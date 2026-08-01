package com.diabetes.monitoring.admin.common;

import java.util.Locale;

/**
 * Central mapping for Admin status constants, normalization, and labels.
 */
public final class AdminStatusMapper {
    public static final String APPOINTMENT_WAITING = "Waiting";
    public static final String APPOINTMENT_CHECKED_IN = "Checked_In";
    public static final String APPOINTMENT_IN_PROGRESS = "In_Progress";
    public static final String APPOINTMENT_COMPLETED = "Completed";
    public static final String APPOINTMENT_CANCELLED = "Cancelled";
    public static final String APPOINTMENT_ABSENT = "Absent";

    public static final String SCHEDULE_AVAILABLE = "Available";
    public static final String SCHEDULE_FULL = "Full";
    public static final String SCHEDULE_CANCELLED = "Cancelled";
    public static final String SCHEDULE_COMPLETED = "Completed";
    public static final String SCHEDULE_EXPIRED = "Completed";

    public static final String BOOKING_ONLINE = "Online";
    public static final String BOOKING_RECEPTIONIST = "Receptionist";
    public static final String BOOKING_ADMIN = "Admin";
    public static final String BOOKING_WALK_IN = "Walk_In";
    public static final String BOOKING_EMERGENCY_ROUTING = "Emergency_Routing";

    /**
     * Prevents instantiation of the AdminStatusMapper utility class.
     */
    private AdminStatusMapper() {
    }

    public static String normalizeBookingSource(String raw) {
        if (raw == null || raw.isBlank()) {
            return BOOKING_ONLINE;
        }
        String normalized = raw.trim();
        if (normalized.equalsIgnoreCase("walkin") || normalized.equalsIgnoreCase("walk-in")) {
            return BOOKING_WALK_IN;
        }
        if (normalized.equalsIgnoreCase("reception") || normalized.equalsIgnoreCase("receptionist")) {
            return BOOKING_RECEPTIONIST;
        }
        if (normalized.equalsIgnoreCase("admin")) {
            return BOOKING_ADMIN;
        }
        if (normalized.equalsIgnoreCase("emergency") || normalized.equalsIgnoreCase("emergency_routing")) {
            return BOOKING_EMERGENCY_ROUTING;
        }
        if (normalized.equalsIgnoreCase(BOOKING_ONLINE)) {
            return BOOKING_ONLINE;
        }
        return normalized;
    }

    public static boolean isAppointmentStatus(String status) {
        if (status == null) {
            return false;
        }
        String normalized = status.trim();
        return normalized.equalsIgnoreCase(APPOINTMENT_WAITING)
                || normalized.equalsIgnoreCase(APPOINTMENT_CHECKED_IN)
                || normalized.equalsIgnoreCase(APPOINTMENT_IN_PROGRESS)
                || normalized.equalsIgnoreCase(APPOINTMENT_COMPLETED)
                || normalized.equalsIgnoreCase(APPOINTMENT_CANCELLED)
                || normalized.equalsIgnoreCase(APPOINTMENT_ABSENT);
    }

    public static boolean isCountedAppointmentStatus(String status) {
        if (status == null) {
            return false;
        }
        String normalized = status.trim();
        return normalized.equalsIgnoreCase(APPOINTMENT_WAITING)
                || normalized.equalsIgnoreCase(APPOINTMENT_CHECKED_IN)
                || normalized.equalsIgnoreCase(APPOINTMENT_IN_PROGRESS)
                || normalized.equalsIgnoreCase(APPOINTMENT_COMPLETED);
    }

    public static boolean isCountedOnlineAppointmentStatus(String status, String bookingSource) {
        return isCountedAppointmentStatus(status)
                && BOOKING_ONLINE.equalsIgnoreCase(normalizeBookingSource(bookingSource));
    }

    public static String normalizeScheduleStatus(String raw) {
        if (raw == null || raw.isBlank()) {
            return SCHEDULE_AVAILABLE;
        }
        String normalized = raw.trim();
        if (normalized.equalsIgnoreCase("available") || normalized.equalsIgnoreCase("scheduled")) {
            return SCHEDULE_AVAILABLE;
        }
        if (normalized.equalsIgnoreCase("full")) {
            return SCHEDULE_FULL;
        }
        if (normalized.equalsIgnoreCase("cancelled") || normalized.equalsIgnoreCase("canceled")) {
            return SCHEDULE_CANCELLED;
        }
        if (normalized.equalsIgnoreCase("expired") || normalized.equalsIgnoreCase("completed")) {
            return SCHEDULE_COMPLETED;
        }
        return normalized;
    }

    /**
     * Maps appointment workflow status to a Vietnamese label for Admin screens.
     */
    public static String toVietnameseAppointmentStatus(String status) {
        if (status == null) {
            return "";
        }
        String normalized = status.trim().replace('-', '_').toLowerCase(Locale.ROOT);
        switch (normalized) {
            case "waiting":
                return "Đã đặt lịch";
            case "checked_in":
                return "Đã check-in";
            case "in_progress":
                return "Đang khám";
            case "completed":
                return "Đã hoàn tất";
            case "cancelled":
            case "canceled":
                return "Đã hủy";
            case "absent":
                return "Không đến";
            default:
                return status;
        }
    }

    /**
     * Maps doctor schedule status to a Vietnamese label for Admin screens.
     */
    public static String toVietnameseScheduleStatus(String status) {
        if (status == null) {
            return "";
        }
        String normalized = status.trim().toLowerCase(Locale.ROOT);
        switch (normalized) {
            case "available":
                return "Sẵn sàng";
            case "full":
                return "Đã đầy";
            case "cancelled":
            case "canceled":
                return "Đã hủy";
            case "completed":
            case "expired":
                return "Đã hoàn thành";
            default:
                return status;
        }
    }
}

