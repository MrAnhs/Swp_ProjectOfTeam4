package com.diabetes.monitoring.admin.common;

import java.math.BigDecimal;

/**
 * Simple chart series point for Admin reports.
 */
public class ReportSeriesDTO {
    private final String period;
    private final BigDecimal value;

    /**
     * Creates a new ReportSeriesDTO instance.
     */
    public ReportSeriesDTO(String period, BigDecimal value) {
        this.period = period == null ? "" : period;
        this.value = value == null ? BigDecimal.ZERO : value;
    }
    public String getPeriod() {
        return period;
    }
    public BigDecimal getValue() {
        return value;
    }
}


