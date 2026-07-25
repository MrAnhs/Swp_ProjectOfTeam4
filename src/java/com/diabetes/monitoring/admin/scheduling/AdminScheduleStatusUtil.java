package com.diabetes.monitoring.admin.scheduling;

import java.sql.Date;
import java.time.LocalDate;
import java.time.LocalTime;

/**
 * Utility class to evaluate schedule status rules dynamically.
 */
public class AdminScheduleStatusUtil {

    public static String getEffectiveStatus(Date workDate, String timeSlot, String storedStatus) {
        if ("Cancelled".equalsIgnoreCase(storedStatus)
                || "Completed".equalsIgnoreCase(storedStatus)
                || "Pending".equalsIgnoreCase(storedStatus)) {
            return storedStatus;
        }
        LocalTime[] range = parseTimeSlotRange(timeSlot);
        if (workDate == null || range == null) {
            return "Upcoming";
        }
        LocalDate scheduleDate = workDate.toLocalDate();
        LocalDate today = LocalDate.now();
        if (scheduleDate.isBefore(today)) {
            return "Completed";
        }
        if (scheduleDate.isAfter(today)) {
            return "Upcoming";
        }
        LocalTime now = LocalTime.now();
        if (now.isBefore(range[0])) {
            return "Upcoming";
        }
        if (now.isBefore(range[1])) {
            return "Ongoing";
        }
        return "Completed";
    }

    private static LocalTime[] parseTimeSlotRange(String timeSlot) {
        if (timeSlot == null || !timeSlot.contains("-")) {
            return null;
        }
        try {
            String compact = timeSlot.replace(" ", "");
            String[] parts = compact.split("-", 2);
            if (parts.length != 2) {
                return null;
            }
            LocalTime start = LocalTime.parse(parts[0]);
            LocalTime end = LocalTime.parse(parts[1]);
            if (!end.isAfter(start)) {
                return null;
            }
            return new LocalTime[]{start, end};
        } catch (RuntimeException ex) {
            return null;
        }
    }
}
