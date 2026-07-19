package com.diabetes.monitoring.admin.ai;

import com.diabetes.monitoring.util.DatabaseConnection;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.text.Normalizer;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

public class CSVExporter {
    private static final Logger LOGGER = Logger.getLogger(CSVExporter.class.getName());

    public static String getDatasetCsvPath() {
        Properties props = new Properties();
        try (InputStream in = CSVExporter.class.getClassLoader().getResourceAsStream("application.properties")) {
            if (in != null) {
                props.load(in);
                String path = props.getProperty("ai.dataset.path");
                if (path != null && !path.trim().isEmpty()) {
                    return path.trim();
                }
            }
        } catch (IOException e) {
            LOGGER.log(Level.WARNING, "Cannot read application.properties, fallback to default", e);
        }
        // Fallback default
        return "d:/ky5/Github_SWP391/Diabetes-Prediction-System/Diabetes-Prediction-System/dataset/update/doctor_feedback.csv";
    }

    public static boolean exportToDoctorFeedback(Connection conn, List<Integer> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return false;
        }

        String path = getDatasetCsvPath();
        File file = new File(path);

        // Ensure parent directories exist
        File parent = file.getParentFile();
        if (parent != null && !parent.exists()) {
            parent.mkdirs();
        }

        String selectSql = "SELECT mr.record_id, mr.patient_id, p.gender, p.date_of_birth, " +
                           "hr.urea, hr.cr, hr.hba1c, hr.chol, hr.tg, hr.hdl, hr.ldl, hr.vldl, hr.bmi, " +
                           "mr.final_diagnosis " +
                           "FROM Medical_record mr " +
                           "JOIN Patient p ON mr.patient_id = p.patient_id " +
                           "LEFT JOIN Healthy_Record hr ON mr.health_record_id = hr.health_record_id " +
                           "WHERE mr.record_id = ?";

        List<String[]> rowsToWrite = new ArrayList<>();
        try (PreparedStatement selectPs = conn.prepareStatement(selectSql)) {
            for (int recordId : recordIds) {
                selectPs.setInt(1, recordId);
                try (ResultSet rs = selectPs.executeQuery()) {
                    if (rs.next()) {
                        int id = rs.getInt("record_id");
                        int patientId = rs.getInt("patient_id");

                        String rawGender = rs.getString("gender");
                        String gender = "F";
                        if (rawGender != null) {
                            String gNorm = rawGender.trim().toLowerCase();
                            if (gNorm.equals("male") || gNorm.startsWith("m")) {
                                gender = "M";
                            }
                        }

                        // Calculate age
                        Date dob = rs.getDate("date_of_birth");
                        int age = 40;
                        if (dob != null) {
                            Calendar birth = Calendar.getInstance();
                            birth.setTime(dob);
                            Calendar today = Calendar.getInstance();
                            age = today.get(Calendar.YEAR) - birth.get(Calendar.YEAR);
                            if (today.get(Calendar.DAY_OF_YEAR) < birth.get(Calendar.DAY_OF_YEAR)) {
                                age--;
                            }
                        }

                        BigDecimal urea = rs.getBigDecimal("urea");
                        BigDecimal cr = rs.getBigDecimal("cr");
                        BigDecimal hba1c = rs.getBigDecimal("hba1c");
                        BigDecimal chol = rs.getBigDecimal("chol");
                        BigDecimal tg = rs.getBigDecimal("tg");
                        BigDecimal hdl = rs.getBigDecimal("hdl");
                        BigDecimal ldl = rs.getBigDecimal("ldl");
                        BigDecimal vldl = rs.getBigDecimal("vldl");
                        BigDecimal bmi = rs.getBigDecimal("bmi");
                        String finalDiagnosis = rs.getString("final_diagnosis");

                        String klass = mapDiagnosisToClass(finalDiagnosis);

                        String[] row = new String[14];
                        row[0] = String.valueOf(id);
                        row[1] = String.valueOf(patientId);
                        row[2] = gender;
                        row[3] = String.valueOf(age);
                        row[4] = (urea != null) ? urea.toString() : "0.0";
                        row[5] = (cr != null) ? cr.toString() : "0.0";
                        row[6] = (hba1c != null) ? hba1c.toString() : "0.0";
                        row[7] = (chol != null) ? chol.toString() : "0.0";
                        row[8] = (tg != null) ? tg.toString() : "0.0";
                        row[9] = (hdl != null) ? hdl.toString() : "0.0";
                        row[10] = (ldl != null) ? ldl.toString() : "0.0";
                        row[11] = (vldl != null) ? vldl.toString() : "0.0";
                        row[12] = (bmi != null) ? bmi.toString() : "0.0";
                        row[13] = klass;

                        rowsToWrite.add(row);
                    }
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Database error mapping records for CSV export", e);
            return false;
        }

        if (rowsToWrite.isEmpty()) {
            return false;
        }

        // Write to primary path
        boolean primarySuccess = writeCsvWithoutDuplicates(file, rowsToWrite);
        
        // Mirror to alternate path if primary succeeded
        if (primarySuccess) {
            String altPath = "d:/ky5/Github_SWP391/Diabetes_AI/dataset/update/doctor_feedback.csv";
            if (!path.replace('\\', '/').equalsIgnoreCase(altPath)) {
                File altFile = new File(altPath);
                if (altFile.getParentFile().exists()) {
                    writeCsvWithoutDuplicates(altFile, rowsToWrite);
                }
            }
        }

        return primarySuccess;
    }

    private static boolean writeCsvWithoutDuplicates(File file, List<String[]> newRows) {
        java.util.Map<String, String> existingRows = new java.util.LinkedHashMap<>();
        String header = "ID,No_Pation,Gender,AGE,Urea,Cr,HbA1c,Chol,TG,HDL,LDL,VLDL,BMI,CLASS";
        
        if (file.exists() && file.length() > 0) {
            try (java.io.BufferedReader br = new java.io.BufferedReader(new java.io.FileReader(file))) {
                String fileHeader = br.readLine();
                if (fileHeader != null && !fileHeader.trim().isEmpty()) {
                    header = fileHeader.trim();
                }
                String line;
                while ((line = br.readLine()) != null) {
                    if (line.trim().isEmpty()) continue;
                    String[] cols = line.split(",");
                    if (cols.length > 0) {
                        existingRows.put(cols[0].trim(), line.trim());
                    }
                }
            } catch (IOException e) {
                LOGGER.log(Level.WARNING, "Error reading existing CSV to prevent duplicates: " + file.getAbsolutePath(), e);
            }
        }

        // Override or put new records
        for (String[] r : newRows) {
            String id = r[0];
            String line = String.join(",", r);
            existingRows.put(id, line);
        }

        // Write back
        try (FileWriter fw = new FileWriter(file, false); // Overwrite entirely
             BufferedWriter bw = new BufferedWriter(fw);
             PrintWriter pw = new PrintWriter(bw)) {
             
            pw.println(header);
            for (String line : existingRows.values()) {
                pw.println(line);
            }
            return true;
        } catch (IOException e) {
            LOGGER.log(Level.SEVERE, "IO error writing to CSV file: " + file.getAbsolutePath(), e);
            return false;
        }
    }

    private static String mapDiagnosisToClass(String finalDiagnosis) {
        if (finalDiagnosis == null) {
            return "N";
        }
        String normalized = Normalizer.normalize(finalDiagnosis, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .replace('đ', 'd')
                .replace('Đ', 'D')
                .toLowerCase();

        if (normalized.contains("tien tieu duong") || normalized.matches(".*\\bpre-diabetic\\b.*") || normalized.matches(".*\\bp\\b.*")) {
            return "P";
        }
        if (normalized.contains("tieu duong") || normalized.contains("diabetic") || normalized.matches(".*\\by\\b.*") || normalized.equals("co") || normalized.equals("yes")) {
            if (normalized.contains("khong tieu duong") || normalized.contains("non-diabetic")) {
                return "N";
            }
            return "Y";
        }
        return "N";
    }
}
