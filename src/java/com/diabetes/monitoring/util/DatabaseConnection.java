package com.diabetes.monitoring.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;

public class DatabaseConnection {
    private static final String URL = "jdbc:sqlserver://localhost:1433;databaseName=Project;encrypt=false";
    private static final String USER = "sa";
    private static final String PASSWORD = "123";

    static {
        try {
            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
            try (Connection conn = DriverManager.getConnection(URL, USER, PASSWORD);
                 Statement stmt = conn.createStatement()) {
                // Tự động thêm cột invoice_detail_id vào Healthy_Record nếu chưa tồn tại
                String sqlAddCol = 
                    "IF COL_LENGTH('Healthy_Record', 'invoice_detail_id') IS NULL " +
                    "BEGIN " +
                    "    ALTER TABLE Healthy_Record ADD invoice_detail_id INT NULL; " +
                    "END";
                stmt.execute(sqlAddCol);

                // Tự động thêm khóa ngoại nếu chưa tồn tại
                String sqlAddFK = 
                    "IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_HealthyRecord_InvoiceDetail') " +
                    "BEGIN " +
                    "    ALTER TABLE Healthy_Record ADD CONSTRAINT FK_HealthyRecord_InvoiceDetail " +
                    "    FOREIGN KEY (invoice_detail_id) REFERENCES Invoice_Detail(invoice_detail_id); " +
                    "END";
                stmt.execute(sqlAddFK);

                // Tự động cập nhật CHECK constraint cho Doctor_Schedule để hỗ trợ trạng thái 'Pending'
                String sqlUpdateConstraint = 
                    "IF EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_DoctorSchedule_Status') " +
                    "BEGIN " +
                    "    ALTER TABLE Doctor_Schedule DROP CONSTRAINT CK_DoctorSchedule_Status; " +
                    "END; " +
                    "ALTER TABLE Doctor_Schedule ADD CONSTRAINT CK_DoctorSchedule_Status CHECK (status IN ('Expired', 'Cancelled', 'Full', 'Available', 'Pending'));";
                stmt.execute(sqlUpdateConstraint);
            } catch (Exception e) {
                System.err.println("Loi khi tu dong kiem tra/nang cap schema DB: " + e.getMessage());
            }
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
    }

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USER, PASSWORD);
    }
}
