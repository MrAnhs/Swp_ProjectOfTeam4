package com.diabetes.monitoring.doctorlab;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;

public final class RandomTestGenerator {
    private static final Random RANDOM = new Random();

    private RandomTestGenerator() {
    }

    public static Map<String, BigDecimal> generateForService(String serviceName) {
        String normalized = serviceName == null ? "" : serviceName.toLowerCase();
        if (normalized.contains("nước tiểu") || normalized.contains("urine")) {
            return generateUrineMetrics();
        }
        if (normalized.contains("mỡ") || normalized.contains("lipid")) {
            return generateLipidMetrics();
        }
        if (normalized.contains("thận") || normalized.contains("kidney")) {
            return generateKidneyMetrics();
        }
        if (normalized.contains("gan") || normalized.contains("liver")) {
            return generateLiverMetrics();
        }
        if (normalized.contains("hba1c") || normalized.contains("đường huyết")) {
            return generateBloodSugarMetrics();
        }
        return generateGeneralMetrics();
    }

    private static Map<String, BigDecimal> generateBloodSugarMetrics() {
        Map<String, BigDecimal> metrics = emptyMetrics();
        metrics.put("urea", random(3.5, 18.0, 2));
        metrics.put("hba1c", random(4.0, 12.0, 2));
        addBodyMetrics(metrics);
        return metrics;
    }

    private static Map<String, BigDecimal> generateLipidMetrics() {
        Map<String, BigDecimal> metrics = emptyMetrics();
        BigDecimal tg = random(0.5, 5.5, 2);
        BigDecimal hdl = random(0.7, 2.3, 2);
        BigDecimal ldl = random(1.0, 7.0, 2);
        BigDecimal vldl = tg.divide(BigDecimal.valueOf(2.2), 2, RoundingMode.HALF_UP);
        metrics.put("tg", tg);
        metrics.put("hdl", hdl);
        metrics.put("ldl", ldl);
        metrics.put("vldl", vldl);
        metrics.put("chol", ldl.add(hdl).add(vldl).setScale(2, RoundingMode.HALF_UP));
        addBodyMetrics(metrics);
        return metrics;
    }

    private static Map<String, BigDecimal> generateKidneyMetrics() {
        Map<String, BigDecimal> metrics = emptyMetrics();
        metrics.put("urea", random(2.5, 15.0, 2));
        metrics.put("cr", random(45.0, 220.0, 2));
        addBodyMetrics(metrics);
        return metrics;
    }

    private static Map<String, BigDecimal> generateLiverMetrics() {
        Map<String, BigDecimal> metrics = emptyMetrics();
        metrics.put("chol", random(15.0, 90.0, 1));
        metrics.put("tg", random(15.0, 90.0, 1));
        addBodyMetrics(metrics);
        return metrics;
    }

    private static Map<String, BigDecimal> generateUrineMetrics() {
        Map<String, BigDecimal> metrics = emptyMetrics();
        boolean abnormal = RANDOM.nextDouble() < 0.3;
        metrics.put("urea", abnormal ? random(1.0, 15.0, 2) : random(0.0, 0.7, 2));
        metrics.put("cr", abnormal ? random(0.2, 3.0, 2) : random(0.0, 0.09, 2));
        metrics.put("hba1c", abnormal ? random(25.0, 500.0, 0) : random(0.0, 10.0, 0));
        metrics.put("hdl", BigDecimal.valueOf(abnormal && RANDOM.nextBoolean() ? 1 : 0));
        metrics.put("ldl", BigDecimal.valueOf(abnormal && RANDOM.nextBoolean() ? 1 : 0));
        metrics.put("vldl", random(1.005, 1.030, 3));
        metrics.put("tg", random(4.6, 8.0, 1));
        addBodyMetrics(metrics);
        return metrics;
    }

    private static Map<String, BigDecimal> generateGeneralMetrics() {
        Map<String, BigDecimal> metrics = emptyMetrics();
        metrics.put("urea", random(2.5, 15.0, 2));
        metrics.put("cr", random(45.0, 180.0, 2));
        metrics.put("hba1c", random(4.0, 12.0, 2));
        metrics.put("tg", random(0.5, 5.5, 2));
        metrics.put("hdl", random(0.7, 2.3, 2));
        metrics.put("ldl", random(1.0, 7.0, 2));
        metrics.put("vldl", metrics.get("tg").divide(BigDecimal.valueOf(2.2), 2, RoundingMode.HALF_UP));
        metrics.put("chol", metrics.get("ldl").add(metrics.get("hdl")).add(metrics.get("vldl")).setScale(2, RoundingMode.HALF_UP));
        addBodyMetrics(metrics);
        return metrics;
    }

    private static Map<String, BigDecimal> emptyMetrics() {
        Map<String, BigDecimal> metrics = new HashMap<>();
        metrics.put("urea", null);
        metrics.put("cr", null);
        metrics.put("hba1c", null);
        metrics.put("chol", null);
        metrics.put("tg", null);
        metrics.put("hdl", null);
        metrics.put("ldl", null);
        metrics.put("vldl", null);
        metrics.put("weight", null);
        metrics.put("height", null);
        metrics.put("bmi", null);
        return metrics;
    }

    private static void addBodyMetrics(Map<String, BigDecimal> metrics) {
        BigDecimal weight = random(40.0, 120.0, 1);
        BigDecimal height = random(145.0, 190.0, 1);
        BigDecimal heightMeters = height.divide(BigDecimal.valueOf(100), 4, RoundingMode.HALF_UP);
        BigDecimal bmi = weight.divide(heightMeters.multiply(heightMeters), 2, RoundingMode.HALF_UP);
        metrics.put("weight", weight);
        metrics.put("height", height);
        metrics.put("bmi", bmi);
    }

    private static BigDecimal random(double min, double max, int scale) {
        double value = min + (max - min) * RANDOM.nextDouble();
        return BigDecimal.valueOf(value).setScale(scale, RoundingMode.HALF_UP);
    }
}
