-- ============================================================================
-- KỊCH BẢN TẠO BẢNG RECORD_SHARING (CHIA SẺ HỒ SƠ Y TẾ GIA ĐÌNH 2 CHIỀU)
-- Dự án: DiabetesCare - SWP391
-- ============================================================================

USE [Project]; -- Hoặc tên Database của bạn
GO

-- Xóa bảng cũ nếu đã tồn tại
IF OBJECT_ID('dbo.Record_Sharing', 'U') IS NOT NULL
    DROP TABLE dbo.Record_Sharing;
GO

-- Tạo bảng Record_Sharing
CREATE TABLE dbo.Record_Sharing (
    SharingID INT IDENTITY(1,1) NOT NULL,
    Owner_AccountID INT NOT NULL,
    Viewer_AccountID INT NOT NULL,
    Initiator_AccountID INT NOT NULL,
    CanViewAppointments BIT NOT NULL CONSTRAINT DF_RecordSharing_CanViewAppointments DEFAULT (0),
    CanViewInvoices BIT NOT NULL CONSTRAINT DF_RecordSharing_CanViewInvoices DEFAULT (0),
    CanViewRecords BIT NOT NULL CONSTRAINT DF_RecordSharing_CanViewRecords DEFAULT (0),
    Status VARCHAR(20) NOT NULL CONSTRAINT DF_RecordSharing_Status DEFAULT ('PENDING'),
    CreatedAt DATETIME NOT NULL CONSTRAINT DF_RecordSharing_CreatedAt DEFAULT (GETDATE()),
    UpdatedAt DATETIME NOT NULL CONSTRAINT DF_RecordSharing_UpdatedAt DEFAULT (GETDATE()),

    -- Khóa chính
    CONSTRAINT PK_RecordSharing PRIMARY KEY CLUSTERED (SharingID ASC),

    -- Khóa ngoại đến bảng Account (sử dụng cột account_id của bảng Account)
    CONSTRAINT FK_RecordSharing_Owner FOREIGN KEY (Owner_AccountID) REFERENCES dbo.Account (account_id) ON DELETE CASCADE,
    CONSTRAINT FK_RecordSharing_Viewer FOREIGN KEY (Viewer_AccountID) REFERENCES dbo.Account (account_id),
    CONSTRAINT FK_RecordSharing_Initiator FOREIGN KEY (Initiator_AccountID) REFERENCES dbo.Account (account_id),

    -- Ràng buộc Cấm tự chia sẻ/theo dõi chính mình
    CONSTRAINT CHK_RecordSharing_NoSelfSharing CHECK (Owner_AccountID <> Viewer_AccountID),

    -- Ràng buộc các trạng thái hợp lệ
    CONSTRAINT CHK_RecordSharing_Status CHECK (Status IN ('PENDING', 'ACCEPTED', 'REJECTED')),

    -- Ràng buộc Chống trùng lặp cặp (Owner_AccountID, Viewer_AccountID)
    CONSTRAINT UQ_RecordSharing_OwnerViewer UNIQUE (Owner_AccountID, Viewer_AccountID)
);
GO

-- Tạo Index tăng tốc truy vấn cho 2 chiều Tab 1 và Tab 2
CREATE NONCLUSTERED INDEX IX_RecordSharing_Viewer ON dbo.Record_Sharing (Viewer_AccountID, Status);
CREATE NONCLUSTERED INDEX IX_RecordSharing_Owner ON dbo.Record_Sharing (Owner_AccountID, Status);
GO
