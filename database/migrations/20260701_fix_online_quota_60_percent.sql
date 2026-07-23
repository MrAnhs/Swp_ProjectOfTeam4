/*
 * Recalculate Doctor_Schedule.online_quota using the Admin online booking rule.
 *
 * Rule:
 * - max_patients <= 1: online_quota = max_patients
 * - max_patients > 1: online_quota = CEILING(max_patients * 0.6)
 * - Always keep at least one reserved slot when max_patients > 1
 *
 * Expected examples:
 * max_patients = 5  => online_quota = 3, reserved_slots = 2
 * max_patients = 8  => online_quota = 5, reserved_slots = 3
 * max_patients = 10 => online_quota = 6, reserved_slots = 4
 */

UPDATE Doctor_Schedule
SET online_quota =
    CASE
        WHEN max_patients <= 1 THEN max_patients
        WHEN CEILING(max_patients * 0.6) >= max_patients THEN max_patients - 1
        ELSE CAST(CEILING(max_patients * 0.6) AS INT)
    END;

