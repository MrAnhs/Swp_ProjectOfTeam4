-- Script tạo table AI_Conversation nếu chưa tồn tại
-- Dùng tên AI_Conversation để khớp với AIChatServlet.java

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='AI_Conversation' AND xtype='U')
BEGIN
    CREATE TABLE AI_Conversation (
        conversation_id INT IDENTITY(1,1) PRIMARY KEY,
        patient_id      INT NOT NULL,
        chat_history    NVARCHAR(MAX) NULL,
        ai_summary      NVARCHAR(MAX) NULL,
        created_at      DATETIME DEFAULT GETDATE(),
        CONSTRAINT FK_AIConversation_Patient FOREIGN KEY (patient_id)
            REFERENCES Patient(patient_id) ON DELETE CASCADE
    );
    PRINT 'Table AI_Conversation created successfully.';
END
ELSE
BEGIN
    PRINT 'Table AI_Conversation already exists.';
END
GO

-- Nếu table AI_Summary tồn tại từ migration cũ, tạo view để tương thích
-- (Tuỳ chọn - không cần nếu chạy script tạo AI_Conversation ở trên)
