package com.diabetes.monitoring.util;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;

public class RandomTestGenerator {

    private static final Random random = new Random();

    // Human Physiological Limits matching SubmitHealthRecordServlet.java
    private static final double UREA_MIN = 0.5;
    private static final double UREA_MAX = 60.0;
    
    private static final double CR_MIN = 0.01;
    private static final double CR_MAX = 2000.0;
    
    private static final double HBA1C_MIN = 0.0;
    private static final double HBA1C_MAX = 500.0;
    
    private static final double CHOL_MIN = 0.5;
    private static final double CHOL_MAX = 150.0;
    
    private static final double TG_MIN = 0.1;
    private static final double TG_MAX = 150.0;
    
    private static final double HDL_MIN = 0.0;
    private static final double HDL_MAX = 5.0;
    
    private static final double LDL_MIN = 0.0;
    private static final double LDL_MAX = 15.0;
    
    private static final double WEIGHT_MIN = 0.1;
    private static final double WEIGHT_MAX = 800.0;
    
    private static final double HEIGHT_MIN = 0.1;
    private static final double HEIGHT_MAX = 300.0;

    private static BigDecimal randomInRange(double min, double max, int scale) {
        double val = min + (max - min) * random.nextDouble();
        return BigDecimal.valueOf(val).setScale(scale, RoundingMode.HALF_UP);
    }

    private static BigDecimal clamp(BigDecimal val, double min, double max) {
        BigDecimal minDec = BigDecimal.valueOf(min);
        BigDecimal maxDec = BigDecimal.valueOf(max);
        if (val.compareTo(minDec) < 0) return minDec.setScale(val.scale(), RoundingMode.HALF_UP);
        if (val.compareTo(maxDec) > 0) return maxDec.setScale(val.scale(), RoundingMode.HALF_UP);
        return val;
    }

    public static Map<String, BigDecimal> generateBloodSugarMetrics() {
        Map<String, BigDecimal> metrics = new HashMap<>();
        
        BigDecimal urea = randomInRange(3.5, 25.0, 2); // Represents Blood Sugar
        urea = clamp(urea, UREA_MIN, UREA_MAX);
        metrics.put("urea", urea);
        
        BigDecimal hba1c = randomInRange(4.0, 16.0, 2);
        hba1c = clamp(hba1c, HBA1C_MIN, HBA1C_MAX);
        metrics.put("hba1c", hba1c);
        
        metrics.put("cr", null);
        metrics.put("chol", null);
        metrics.put("tg", null);
        metrics.put("hdl", null);
        metrics.put("ldl", null);
        metrics.put("vldl", null);
        
        return metrics;
    }

    public static Map<String, BigDecimal> generateLiverMetrics() {
        Map<String, BigDecimal> metrics = new HashMap<>();
        
        BigDecimal chol = randomInRange(15.0, 90.0, 1); // AST stored in chol
        chol = clamp(chol, CHOL_MIN, CHOL_MAX);
        metrics.put("chol", chol);
        
        BigDecimal tg = randomInRange(15.0, 90.0, 1); // ALT stored in tg
        tg = clamp(tg, TG_MIN, TG_MAX);
        metrics.put("tg", tg);
        
        metrics.put("urea", null);
        metrics.put("cr", null);
        metrics.put("hba1c", null);
        metrics.put("hdl", null);
        metrics.put("ldl", null);
        metrics.put("vldl", null);
        
        return metrics;
    }

    public static Map<String, BigDecimal> generateKidneyMetrics() {
        Map<String, BigDecimal> metrics = new HashMap<>();
        
        BigDecimal urea = randomInRange(2.5, 15.0, 2); // Ure (mmol/L)
        urea = clamp(urea, UREA_MIN, UREA_MAX);
        metrics.put("urea", urea);
        
        BigDecimal cr = randomInRange(0.5, 3.5, 2); // Creatinin (mg/dL)
        cr = clamp(cr, CR_MIN, CR_MAX);
        metrics.put("cr", cr);
        
        metrics.put("hba1c", null);
        metrics.put("chol", null);
        metrics.put("tg", null);
        metrics.put("hdl", null);
        metrics.put("ldl", null);
        metrics.put("vldl", null);
        
        return metrics;
    }

    public static Map<String, BigDecimal> generateLipidsMetrics() {
        Map<String, BigDecimal> metrics = new HashMap<>();
        
        BigDecimal chol = randomInRange(2.0, 9.0, 2); // Cholesterol (mmol/L)
        chol = clamp(chol, CHOL_MIN, CHOL_MAX);
        metrics.put("chol", chol);
        
        BigDecimal tg = randomInRange(0.5, 5.5, 2); // Triglyceride (mmol/L)
        tg = clamp(tg, TG_MIN, TG_MAX);
        metrics.put("tg", tg);
        
        metrics.put("urea", null);
        metrics.put("cr", null);
        metrics.put("hba1c", null);
        metrics.put("hdl", null);
        metrics.put("ldl", null);
        metrics.put("vldl", null);
        
        return metrics;
    }

    public static Map<String, BigDecimal> generateUrineMetrics() {
        Map<String, BigDecimal> metrics = new HashMap<>();
        boolean abnormal = random.nextDouble() < 0.3; // 30% chance of abnormal values
        
        double gluVal = abnormal ? (1.0 + 14.0 * random.nextDouble()) : (0.5 + 0.2 * random.nextDouble());
        BigDecimal urea = BigDecimal.valueOf(gluVal).setScale(2, RoundingMode.HALF_UP); // GLU
        urea = clamp(urea, UREA_MIN, UREA_MAX);
        metrics.put("urea", urea);
        
        double proVal = abnormal ? (0.2 + 2.8 * random.nextDouble()) : (0.01 + 0.08 * random.nextDouble());
        BigDecimal cr = BigDecimal.valueOf(proVal).setScale(2, RoundingMode.HALF_UP); // PRO
        cr = clamp(cr, CR_MIN, CR_MAX);
        metrics.put("cr", cr);
        
        double leuVal = abnormal ? (25 + random.nextInt(475)) : (random.nextInt(11));
        BigDecimal hba1c = BigDecimal.valueOf(leuVal).setScale(0, RoundingMode.HALF_UP); // LEU
        hba1c = clamp(hba1c, HBA1C_MIN, HBA1C_MAX);
        metrics.put("hba1c", hba1c);
        
        double nitVal = abnormal && random.nextDouble() < 0.5 ? 1.0 : 0.0;
        BigDecimal hdl = BigDecimal.valueOf(nitVal).setScale(0, RoundingMode.HALF_UP); // NIT
        hdl = clamp(hdl, HDL_MIN, HDL_MAX);
        metrics.put("hdl", hdl);
        
        double bldVal = abnormal && random.nextDouble() < 0.5 ? 1.0 : 0.0;
        BigDecimal ldl = BigDecimal.valueOf(bldVal).setScale(0, RoundingMode.HALF_UP); // BLD
        ldl = clamp(ldl, LDL_MIN, LDL_MAX);
        metrics.put("ldl", ldl);
        
        double sgVal = 1.005 + 0.025 * random.nextDouble();
        BigDecimal vldl = BigDecimal.valueOf(sgVal).setScale(3, RoundingMode.HALF_UP); // SG
        metrics.put("vldl", vldl);
        
        double phVal = 4.6 + 3.4 * random.nextDouble();
        BigDecimal tg = BigDecimal.valueOf(phVal).setScale(1, RoundingMode.HALF_UP); // pH
        tg = clamp(tg, TG_MIN, TG_MAX);
        metrics.put("tg", tg);
        
        metrics.put("chol", null);
        
        return metrics;
    }

    public static Map<String, BigDecimal> generateRandomMetrics() {
        Map<String, BigDecimal> metrics = new HashMap<>();
        
        // 1. HbA1c (4.0% to 16.0% - normal to severe diabetes)
        BigDecimal hba1c = randomInRange(4.0, 16.0, 2);
        hba1c = clamp(hba1c, HBA1C_MIN, HBA1C_MAX);
        metrics.put("hba1c", hba1c);
        
        // 2. Triglycerides (TG) (0.3 to 12.0 mmol/L - normal to hypertriglyceridemia)
        BigDecimal tg = randomInRange(0.3, 12.0, 2);
        tg = clamp(tg, TG_MIN, TG_MAX);
        metrics.put("tg", tg);
        
        // 3. VLDL = TG / 2.2
        BigDecimal vldl = tg.divide(BigDecimal.valueOf(2.2), 2, RoundingMode.HALF_UP);
        metrics.put("vldl", vldl);
        
        // 4. HDL (0.5 to 2.5 mmol/L)
        BigDecimal hdl = randomInRange(0.5, 2.5, 2);
        hdl = clamp(hdl, HDL_MIN, HDL_MAX);
        metrics.put("hdl", hdl);
        
        // 5. LDL (1.0 to 8.0 mmol/L)
        BigDecimal ldl = randomInRange(1.0, 8.0, 2);
        ldl = clamp(ldl, LDL_MIN, LDL_MAX);
        metrics.put("ldl", ldl);
        
        // 6. Total Cholesterol = LDL + HDL + VLDL (clamped to remain within limit)
        BigDecimal chol = ldl.add(hdl).add(vldl).setScale(2, RoundingMode.HALF_UP);
        chol = clamp(chol, CHOL_MIN, CHOL_MAX);
        metrics.put("chol", chol);
        
        // 7. Kidney functions (Urea and Creatinine)
        BigDecimal urea = randomInRange(1.5, 30.0, 2); // Kidney dysfunction can go high
        urea = clamp(urea, UREA_MIN, UREA_MAX);
        metrics.put("urea", urea);

        BigDecimal cr = randomInRange(35.0, 600.0, 2); // Renal issues can go high
        cr = clamp(cr, CR_MIN, CR_MAX);
        metrics.put("cr", cr);
        
        // 8. Weight, Height & BMI belong to physical vitals, not lab tests
        metrics.put("weight", null);
        metrics.put("height", null);
        metrics.put("bmi", null);
        
        return metrics;
    }
}
