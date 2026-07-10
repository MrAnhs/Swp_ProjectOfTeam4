/*
 * SWP Project - SQL Server database dump
 *
 * Muc dich:
 * - Luu cau truc database project_SWP de phan tich nghiep vu.
 * - Luu CREATE TABLE, PRIMARY KEY, FOREIGN KEY, UNIQUE, CHECK, INDEX.
 * - Luu du lieu mau can thiet de doi chieu luong chuong trinh.
 *
 * Cach su dung:
 * 1. Mo SQL Server Management Studio.
 * 2. Nhap chuot phai database project_SWP.
 * 3. Chon Tasks -> Generate Scripts.
 * 4. Chon "Script entire database and all database objects".
 * 5. Trong Advanced, dat "Types of data to script" thanh
 *    "Schema and data".
 * 6. Luu ket qua, sau do thay noi dung file nay bang script da xuat.
 *
 * Luu y bao mat:
 * - Khong dua mat khau dang ro, API key hoac thong tin that nhay cam.
 * - Co the giu password_hash neu day chi la du lieu test.
 * - Nen an danh ho ten, email, so dien thoai va dia chi cua nguoi that.
 *
 * Nhung bang quan trong can co:
 * - Account
 * - Patient
 * - Doctor
 * - Healthy_Record
 * - Medical_Record
 * - AI_Conversation
 * - Cac bang role, phan quyen hoac bang lien ket khac neu co
 */

USE [project_SWP];
GO

/*
 * Dan script do SQL Server Management Studio sinh ra o ben duoi.
 * Khi da dan xong, khong can giu dong placeholder nay.
 */

USE [master]
GO

-- 1. Xóa database cũ nếu nó lỡ tồn tại dở dang
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'Project')
BEGIN
    ALTER DATABASE [Project] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [Project];
END
GO

-- 2. Tạo database đơn giản (SQL Server sẽ tự cấu hình đường dẫn chuẩn trên máy bạn)
CREATE DATABASE [Project]
GO

-- Tiếp tục chạy các lệnh cấu hình bên dưới của bạn...
ALTER DATABASE [Project] SET COMPATIBILITY_LEVEL = 160
GO
GO
ALTER DATABASE [Project] SET COMPATIBILITY_LEVEL = 160
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [Project].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [Project] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [Project] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [Project] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [Project] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [Project] SET ARITHABORT OFF 
GO
ALTER DATABASE [Project] SET AUTO_CLOSE ON 
GO
ALTER DATABASE [Project] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [Project] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [Project] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [Project] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [Project] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [Project] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [Project] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [Project] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [Project] SET  ENABLE_BROKER 
GO
ALTER DATABASE [Project] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [Project] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [Project] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [Project] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [Project] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [Project] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [Project] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [Project] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [Project] SET  MULTI_USER 
GO
ALTER DATABASE [Project] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [Project] SET DB_CHAINING OFF 
GO
ALTER DATABASE [Project] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [Project] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [Project] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [Project] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
ALTER DATABASE [Project] SET QUERY_STORE = ON
GO
ALTER DATABASE [Project] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 1000, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)
GO
USE [Project]
GO
/****** Object:  Table [dbo].[Account]    Script Date: 6/18/2026 23:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Account](
	[account_id] [int] IDENTITY(1,1) NOT NULL,
	[full_name] [nvarchar](100) NOT NULL,
	[password_hash] [varchar](255) NOT NULL,
	[email] [varchar](100) NOT NULL,
	[role] [varchar](20) NOT NULL,
	[created_at] [datetime] NULL,
	[status] [varchar](20) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[account_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[AI_Conversation]    Script Date: 6/18/2026 23:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AI_Conversation](
	[conversation_id] [int] IDENTITY(1,1) NOT NULL,
	[patient_id] [int] NOT NULL,
	[chat_history] [nvarchar](max) NOT NULL,
	[health_record_id] [int] NULL,
	[ai_summary] [nvarchar](max) NULL,
	[created_at] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[conversation_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Appointment]    Script Date: 6/18/2026 23:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Appointment](
	[appointment_id] [int] IDENTITY(1,1) NOT NULL,
	[patient_id] [int] NOT NULL,
	[schedule_id] [int] NOT NULL,
	[appointment_time] [datetime] NOT NULL,
	[booking_type] [varchar](20) NOT NULL,
	[queue_number] [int] NOT NULL,
	[status] [varchar](20) NOT NULL,
	[created_at] [datetime] NOT NULL,
 CONSTRAINT [PK_Appointment] PRIMARY KEY CLUSTERED 
(
	[appointment_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Doctor]    Script Date: 6/18/2026 23:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Doctor](
	[doctor_id] [int] IDENTITY(1,1) NOT NULL,
	[full_name] [nvarchar](100) NOT NULL,
	[phone] [varchar](15) NOT NULL,
	[email] [varchar](100) NULL,
	[department] [nvarchar](100) NULL,
	[account_id] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[doctor_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Doctor_AI]    Script Date: 6/18/2026 23:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Doctor_AI](
	[doctor_ai_id] [int] IDENTITY(1,1) NOT NULL,
	[health_record_id] [int] NULL,
	[diabetes_probability] [decimal](5, 2) NULL,
	[pre_diabetes_probability] [decimal](5, 2) NULL,
	[normal_probability] [decimal](5, 2) NULL,
	[doctor_id] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[doctor_ai_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Doctor_Schedule]    Script Date: 6/18/2026 23:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Doctor_Schedule](
	[schedule_id] [int] IDENTITY(1,1) NOT NULL,
	[doctor_id] [int] NOT NULL,
	[work_date] [date] NOT NULL,
	[time_slot] [varchar](50) NOT NULL,
	[max_patients] [int] NOT NULL,
	[status] [varchar](20) NOT NULL,
 CONSTRAINT [PK_Doctor_Schedule] PRIMARY KEY CLUSTERED 
(
	[schedule_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Healthy_Record]    Script Date: 6/18/2026 23:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Healthy_Record](
	[health_record_id] [int] IDENTITY(1,1) NOT NULL,
	[urea] [decimal](5, 2) NULL,
	[cr] [decimal](5, 2) NULL,
	[hba1c] [decimal](5, 2) NULL,
	[chol] [decimal](5, 2) NULL,
	[tg] [decimal](5, 2) NULL,
	[hdl] [decimal](5, 2) NULL,
	[idl] [decimal](5, 2) NULL,
	[vldl] [decimal](5, 2) NULL,
	[bmi] [decimal](5, 2) NULL,
	[patient_id] [int] NULL,
	[weight] [decimal](5, 2) NULL,
	[height] [decimal](5, 2) NULL,
	[other_information] [nvarchar](max) NULL,
	[status] [nvarchar](20) NULL,
	[created_at] [datetime] NULL,
	[doctor_id] [int] NULL,
	[record_id] [int] NULL,
	[invoice_detail_id] [int] NULL,
	[ldl] [decimal](5, 2) NULL,
	[is_synced_automatically] [bit] NOT NULL,
	[synced_at] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[health_record_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Invoice]    Script Date: 6/18/2026 23:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Invoice](
	[invoice_id] [int] IDENTITY(1,1) NOT NULL,
	[patient_id] [int] NOT NULL,
	[receptionist_id] [int] NULL,
	[total_amount] [decimal](18, 2) NOT NULL,
	[insurance_deduction] [decimal](18, 2) NOT NULL,
	[final_amount] [decimal](18, 2) NOT NULL,
	[payment_method] [varchar](20) NULL,
	[status] [varchar](20) NOT NULL,
	[created_at] [datetime] NOT NULL,
	[exported_at] [datetime] NULL,
 CONSTRAINT [PK_Invoice] PRIMARY KEY CLUSTERED 
(
	[invoice_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Invoice_Detail]    Script Date: 6/18/2026 23:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Invoice_Detail](
	[invoice_detail_id] [int] IDENTITY(1,1) NOT NULL,
	[invoice_id] [int] NOT NULL,
	[service_id] [int] NOT NULL,
	[appointment_id] [int] NOT NULL,
	[quantity] [int] NOT NULL,
	[price] [decimal](18, 2) NOT NULL,
 CONSTRAINT [PK_Invoice_Detail] PRIMARY KEY CLUSTERED 
(
	[invoice_detail_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Medical_record]    Script Date: 6/18/2026 23:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Medical_record](
	[record_id] [int] IDENTITY(1,1) NOT NULL,
	[patient_id] [int] NOT NULL,
	[doctor_id] [int] NOT NULL,
	[final_diagnosis] [nvarchar](max) NULL,
	[doctor_note] [nvarchar](max) NULL,
	[health_record_id] [int] NULL,
	[result_visibility] [bit] NULL,
	[processed_at] [datetime] NULL,
	[appointment_id] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[record_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Medical_Service]    Script Date: 6/18/2026 23:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Medical_Service](
	[service_id] [int] IDENTITY(1,1) NOT NULL,
	[service_name] [nvarchar](150) NOT NULL,
	[price] [decimal](18, 2) NOT NULL,
	[service_type] [varchar](20) NOT NULL,
	[status] [varchar](20) NOT NULL,
 CONSTRAINT [PK_Medical_Service] PRIMARY KEY CLUSTERED 
(
	[service_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Patient]    Script Date: 6/18/2026 23:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Patient](
	[patient_id] [int] IDENTITY(1,1) NOT NULL,
	[full_name] [nvarchar](100) NOT NULL,
	[date_of_birth] [date] NOT NULL,
	[gender] [nvarchar](10) NULL,
	[phone] [varchar](15) NOT NULL,
	[email] [varchar](100) NULL,
	[address] [nvarchar](255) NULL,
	[account_id] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[patient_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Record_Transfer_History]    Script Date: 6/18/2026 23:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Record_Transfer_History](
	[transfer_id] [int] IDENTITY(1,1) NOT NULL,
	[health_record_id] [int] NOT NULL,
	[from_doctor_id] [int] NOT NULL,
	[to_doctor_id] [int] NOT NULL,
	[reason] [nvarchar](500) NULL,
	[created_at] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[transfer_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UX_Account_Email]    Script Date: 6/18/2026 23:26:40 ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_Account_Email] ON [dbo].[Account]
(
	[email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Appointment_Patient]    Script Date: 6/18/2026 23:26:40 ******/
CREATE NONCLUSTERED INDEX [IX_Appointment_Patient] ON [dbo].[Appointment]
(
	[patient_id] ASC,
	[created_at] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UX_Appointment_Queue]    Script Date: 6/18/2026 23:26:40 ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_Appointment_Queue] ON [dbo].[Appointment]
(
	[schedule_id] ASC,
	[queue_number] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UX_Doctor_Account]    Script Date: 6/18/2026 23:26:40 ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_Doctor_Account] ON [dbo].[Doctor]
(
	[account_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UX_DoctorAI_HealthRecord]    Script Date: 6/18/2026 23:26:40 ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_DoctorAI_HealthRecord] ON [dbo].[Doctor_AI]
(
	[health_record_id] ASC
)
WHERE ([health_record_id] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UX_DoctorSchedule_Slot]    Script Date: 6/18/2026 23:26:40 ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_DoctorSchedule_Slot] ON [dbo].[Doctor_Schedule]
(
	[doctor_id] ASC,
	[work_date] ASC,
	[time_slot] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UX_HealthyRecord_InvoiceDetail]    Script Date: 6/18/2026 23:26:40 ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_HealthyRecord_InvoiceDetail] ON [dbo].[Healthy_Record]
(
	[invoice_detail_id] ASC
)
WHERE ([invoice_detail_id] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Invoice_PatientStatus]    Script Date: 6/18/2026 23:26:40 ******/
CREATE NONCLUSTERED INDEX [IX_Invoice_PatientStatus] ON [dbo].[Invoice]
(
	[patient_id] ASC,
	[status] ASC,
	[created_at] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_InvoiceDetail_Appointment]    Script Date: 6/18/2026 23:26:40 ******/
CREATE NONCLUSTERED INDEX [IX_InvoiceDetail_Appointment] ON [dbo].[Invoice_Detail]
(
	[appointment_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_InvoiceDetail_Invoice]    Script Date: 6/18/2026 23:26:40 ******/
CREATE NONCLUSTERED INDEX [IX_InvoiceDetail_Invoice] ON [dbo].[Invoice_Detail]
(
	[invoice_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UX_MedicalRecord_Appointment]    Script Date: 6/18/2026 23:26:40 ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_MedicalRecord_Appointment] ON [dbo].[Medical_record]
(
	[appointment_id] ASC
)
WHERE ([appointment_id] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Patient_Phone]    Script Date: 6/18/2026 23:26:40 ******/
CREATE NONCLUSTERED INDEX [IX_Patient_Phone] ON [dbo].[Patient]
(
	[phone] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UX_Patient_Account]    Script Date: 6/18/2026 23:26:40 ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_Patient_Account] ON [dbo].[Patient]
(
	[account_id] ASC
)
WHERE ([account_id] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Account] ADD  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[Account] ADD  CONSTRAINT [DF_Account_Status]  DEFAULT ('Active') FOR [status]
GO
ALTER TABLE [dbo].[AI_Conversation] ADD  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[Appointment] ADD  CONSTRAINT [DF_Appointment_Status]  DEFAULT ('Waiting') FOR [status]
GO
ALTER TABLE [dbo].[Appointment] ADD  CONSTRAINT [DF_Appointment_CreatedAt]  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[Doctor_Schedule] ADD  CONSTRAINT [DF_Doctor_Schedule_Status]  DEFAULT ('Available') FOR [status]
GO
ALTER TABLE [dbo].[Healthy_Record] ADD  CONSTRAINT [DF_HealthyRecord_StatusV2]  DEFAULT ('Pending_Payment') FOR [status]
GO
ALTER TABLE [dbo].[Healthy_Record] ADD  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[Healthy_Record] ADD  CONSTRAINT [DF_HealthyRecord_AutoSync]  DEFAULT ((1)) FOR [is_synced_automatically]
GO
ALTER TABLE [dbo].[Invoice] ADD  CONSTRAINT [DF_Invoice_Insurance]  DEFAULT ((0)) FOR [insurance_deduction]
GO
ALTER TABLE [dbo].[Invoice] ADD  CONSTRAINT [DF_Invoice_Status]  DEFAULT ('Pending') FOR [status]
GO
ALTER TABLE [dbo].[Invoice] ADD  CONSTRAINT [DF_Invoice_CreatedAt]  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[Invoice_Detail] ADD  CONSTRAINT [DF_InvoiceDetail_Quantity]  DEFAULT ((1)) FOR [quantity]
GO
ALTER TABLE [dbo].[Medical_record] ADD  CONSTRAINT [DF_MedicalRecord_Visibility]  DEFAULT ((1)) FOR [result_visibility]
GO
ALTER TABLE [dbo].[Medical_Service] ADD  CONSTRAINT [DF_MedicalService_Status]  DEFAULT ('Active') FOR [status]
GO
ALTER TABLE [dbo].[Record_Transfer_History] ADD  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[AI_Conversation]  WITH CHECK ADD  CONSTRAINT [FK_AIConversation_HealthyRecord] FOREIGN KEY([health_record_id])
REFERENCES [dbo].[Healthy_Record] ([health_record_id])
GO
ALTER TABLE [dbo].[AI_Conversation] CHECK CONSTRAINT [FK_AIConversation_HealthyRecord]
GO
ALTER TABLE [dbo].[AI_Conversation]  WITH CHECK ADD  CONSTRAINT [fk_patient_ai_patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[Patient] ([patient_id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AI_Conversation] CHECK CONSTRAINT [fk_patient_ai_patient]
GO
ALTER TABLE [dbo].[Appointment]  WITH CHECK ADD  CONSTRAINT [FK_Appointment_Patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[Patient] ([patient_id])
GO
ALTER TABLE [dbo].[Appointment] CHECK CONSTRAINT [FK_Appointment_Patient]
GO
ALTER TABLE [dbo].[Appointment]  WITH CHECK ADD  CONSTRAINT [FK_Appointment_Schedule] FOREIGN KEY([schedule_id])
REFERENCES [dbo].[Doctor_Schedule] ([schedule_id])
GO
ALTER TABLE [dbo].[Appointment] CHECK CONSTRAINT [FK_Appointment_Schedule]
GO
ALTER TABLE [dbo].[Doctor]  WITH CHECK ADD  CONSTRAINT [FK_Doctor_Account] FOREIGN KEY([account_id])
REFERENCES [dbo].[Account] ([account_id])
GO
ALTER TABLE [dbo].[Doctor] CHECK CONSTRAINT [FK_Doctor_Account]
GO
ALTER TABLE [dbo].[Doctor_AI]  WITH NOCHECK ADD  CONSTRAINT [FK_DoctorAI_HealthyRecord] FOREIGN KEY([health_record_id])
REFERENCES [dbo].[Healthy_Record] ([health_record_id])
GO
ALTER TABLE [dbo].[Doctor_AI] CHECK CONSTRAINT [FK_DoctorAI_HealthyRecord]
GO
ALTER TABLE [dbo].[Doctor_Schedule]  WITH CHECK ADD  CONSTRAINT [FK_DoctorSchedule_Doctor] FOREIGN KEY([doctor_id])
REFERENCES [dbo].[Doctor] ([doctor_id])
GO
ALTER TABLE [dbo].[Doctor_Schedule] CHECK CONSTRAINT [FK_DoctorSchedule_Doctor]
GO
ALTER TABLE [dbo].[Healthy_Record]  WITH CHECK ADD  CONSTRAINT [FK_HealthyRecord_InvoiceDetail] FOREIGN KEY([invoice_detail_id])
REFERENCES [dbo].[Invoice_Detail] ([invoice_detail_id])
GO
ALTER TABLE [dbo].[Healthy_Record] CHECK CONSTRAINT [FK_HealthyRecord_InvoiceDetail]
GO
ALTER TABLE [dbo].[Healthy_Record]  WITH CHECK ADD  CONSTRAINT [FK_HealthyRecord_MedicalRecord] FOREIGN KEY([record_id])
REFERENCES [dbo].[Medical_record] ([record_id])
GO
ALTER TABLE [dbo].[Healthy_Record] CHECK CONSTRAINT [FK_HealthyRecord_MedicalRecord]
GO
ALTER TABLE [dbo].[Healthy_Record]  WITH CHECK ADD  CONSTRAINT [FK_HealthyRecord_Patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[Patient] ([patient_id])
GO
ALTER TABLE [dbo].[Healthy_Record] CHECK CONSTRAINT [FK_HealthyRecord_Patient]
GO
ALTER TABLE [dbo].[Invoice]  WITH CHECK ADD  CONSTRAINT [FK_Invoice_Patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[Patient] ([patient_id])
GO
ALTER TABLE [dbo].[Invoice] CHECK CONSTRAINT [FK_Invoice_Patient]
GO
ALTER TABLE [dbo].[Invoice]  WITH CHECK ADD  CONSTRAINT [FK_Invoice_Receptionist] FOREIGN KEY([receptionist_id])
REFERENCES [dbo].[Account] ([account_id])
GO
ALTER TABLE [dbo].[Invoice] CHECK CONSTRAINT [FK_Invoice_Receptionist]
GO
ALTER TABLE [dbo].[Invoice_Detail]  WITH CHECK ADD  CONSTRAINT [FK_InvoiceDetail_Appointment] FOREIGN KEY([appointment_id])
REFERENCES [dbo].[Appointment] ([appointment_id])
GO
ALTER TABLE [dbo].[Invoice_Detail] CHECK CONSTRAINT [FK_InvoiceDetail_Appointment]
GO
ALTER TABLE [dbo].[Invoice_Detail]  WITH CHECK ADD  CONSTRAINT [FK_InvoiceDetail_Invoice] FOREIGN KEY([invoice_id])
REFERENCES [dbo].[Invoice] ([invoice_id])
GO
ALTER TABLE [dbo].[Invoice_Detail] CHECK CONSTRAINT [FK_InvoiceDetail_Invoice]
GO
ALTER TABLE [dbo].[Invoice_Detail]  WITH CHECK ADD  CONSTRAINT [FK_InvoiceDetail_Service] FOREIGN KEY([service_id])
REFERENCES [dbo].[Medical_Service] ([service_id])
GO
ALTER TABLE [dbo].[Invoice_Detail] CHECK CONSTRAINT [FK_InvoiceDetail_Service]
GO
ALTER TABLE [dbo].[Medical_record]  WITH CHECK ADD  CONSTRAINT [fk_medical_record_doctor] FOREIGN KEY([doctor_id])
REFERENCES [dbo].[Doctor] ([doctor_id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Medical_record] CHECK CONSTRAINT [fk_medical_record_doctor]
GO
ALTER TABLE [dbo].[Medical_record]  WITH CHECK ADD  CONSTRAINT [fk_medical_record_patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[Patient] ([patient_id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Medical_record] CHECK CONSTRAINT [fk_medical_record_patient]
GO
ALTER TABLE [dbo].[Medical_record]  WITH CHECK ADD  CONSTRAINT [FK_MedicalRecord_Appointment] FOREIGN KEY([appointment_id])
REFERENCES [dbo].[Appointment] ([appointment_id])
GO
ALTER TABLE [dbo].[Medical_record] CHECK CONSTRAINT [FK_MedicalRecord_Appointment]
GO
ALTER TABLE [dbo].[Medical_record]  WITH CHECK ADD  CONSTRAINT [FK_MedicalRecord_HealthyRecord] FOREIGN KEY([health_record_id])
REFERENCES [dbo].[Healthy_Record] ([health_record_id])
GO
ALTER TABLE [dbo].[Medical_record] CHECK CONSTRAINT [FK_MedicalRecord_HealthyRecord]
GO
ALTER TABLE [dbo].[Patient]  WITH CHECK ADD  CONSTRAINT [FK_Patient_Account] FOREIGN KEY([account_id])
REFERENCES [dbo].[Account] ([account_id])
GO
ALTER TABLE [dbo].[Patient] CHECK CONSTRAINT [FK_Patient_Account]
GO
ALTER TABLE [dbo].[Record_Transfer_History]  WITH CHECK ADD  CONSTRAINT [FK_RTH_FromDoctor] FOREIGN KEY([from_doctor_id])
REFERENCES [dbo].[Doctor] ([doctor_id])
GO
ALTER TABLE [dbo].[Record_Transfer_History] CHECK CONSTRAINT [FK_RTH_FromDoctor]
GO
ALTER TABLE [dbo].[Record_Transfer_History]  WITH CHECK ADD  CONSTRAINT [FK_RTH_HealthyRecord] FOREIGN KEY([health_record_id])
REFERENCES [dbo].[Healthy_Record] ([health_record_id])
GO
ALTER TABLE [dbo].[Record_Transfer_History] CHECK CONSTRAINT [FK_RTH_HealthyRecord]
GO
ALTER TABLE [dbo].[Record_Transfer_History]  WITH CHECK ADD  CONSTRAINT [FK_RTH_ToDoctor] FOREIGN KEY([to_doctor_id])
REFERENCES [dbo].[Doctor] ([doctor_id])
GO
ALTER TABLE [dbo].[Record_Transfer_History] CHECK CONSTRAINT [FK_RTH_ToDoctor]
GO
ALTER TABLE [dbo].[Account]  WITH CHECK ADD  CONSTRAINT [CK_Account_Role] CHECK  (([role]='Admin' OR [role]='Receptionist' OR [role]='Doctor' OR [role]='Patient'))
GO
ALTER TABLE [dbo].[Account] CHECK CONSTRAINT [CK_Account_Role]
GO
ALTER TABLE [dbo].[Account]  WITH CHECK ADD  CONSTRAINT [CK_Account_Status] CHECK  (([status]='Locked' OR [status]='Active'))
GO
ALTER TABLE [dbo].[Account] CHECK CONSTRAINT [CK_Account_Status]
GO
ALTER TABLE [dbo].[Appointment]  WITH CHECK ADD  CONSTRAINT [CK_Appointment_BookingType] CHECK  (([booking_type]='At_Counter' OR [booking_type]='Online'))
GO
ALTER TABLE [dbo].[Appointment] CHECK CONSTRAINT [CK_Appointment_BookingType]
GO
ALTER TABLE [dbo].[Appointment]  WITH CHECK ADD  CONSTRAINT [CK_Appointment_QueueNumber] CHECK  (([queue_number]>(0)))
GO
ALTER TABLE [dbo].[Appointment] CHECK CONSTRAINT [CK_Appointment_QueueNumber]
GO
ALTER TABLE [dbo].[Appointment]  WITH CHECK ADD  CONSTRAINT [CK_Appointment_Status] CHECK  (([status]='Absent' OR [status]='Cancelled' OR [status]='Completed' OR [status]='In_Progress' OR [status]='Waiting'))
GO
ALTER TABLE [dbo].[Appointment] CHECK CONSTRAINT [CK_Appointment_Status]
GO
ALTER TABLE [dbo].[Doctor_Schedule]  WITH CHECK ADD  CONSTRAINT [CK_DoctorSchedule_MaxPatients] CHECK  (([max_patients]>(0)))
GO
ALTER TABLE [dbo].[Doctor_Schedule] CHECK CONSTRAINT [CK_DoctorSchedule_MaxPatients]
GO
ALTER TABLE [dbo].[Doctor_Schedule]  WITH CHECK ADD  CONSTRAINT [CK_DoctorSchedule_Status] CHECK  (([status]='Cancelled' OR [status]='Full' OR [status]='Available'))
GO
ALTER TABLE [dbo].[Doctor_Schedule] CHECK CONSTRAINT [CK_DoctorSchedule_Status]
GO
ALTER TABLE [dbo].[Invoice]  WITH CHECK ADD  CONSTRAINT [CK_Invoice_Amounts] CHECK  (([total_amount]>=(0) AND [insurance_deduction]>=(0) AND [final_amount]>=(0) AND [insurance_deduction]<=[total_amount]))
GO
ALTER TABLE [dbo].[Invoice] CHECK CONSTRAINT [CK_Invoice_Amounts]
GO
ALTER TABLE [dbo].[Invoice]  WITH CHECK ADD  CONSTRAINT [CK_Invoice_FinalAmount] CHECK  (([final_amount]=([total_amount]-[insurance_deduction])))
GO
ALTER TABLE [dbo].[Invoice] CHECK CONSTRAINT [CK_Invoice_FinalAmount]
GO
ALTER TABLE [dbo].[Invoice]  WITH CHECK ADD  CONSTRAINT [CK_Invoice_PaymentMethod] CHECK  (([payment_method] IS NULL OR ([payment_method]='Bank_Transfer' OR [payment_method]='VNPay' OR [payment_method]='Momo' OR [payment_method]='Cash')))
GO
ALTER TABLE [dbo].[Invoice] CHECK CONSTRAINT [CK_Invoice_PaymentMethod]
GO
ALTER TABLE [dbo].[Invoice]  WITH CHECK ADD  CONSTRAINT [CK_Invoice_Status] CHECK  (([status]='Paid' OR [status]='Pending'))
GO
ALTER TABLE [dbo].[Invoice] CHECK CONSTRAINT [CK_Invoice_Status]
GO
ALTER TABLE [dbo].[Invoice_Detail]  WITH CHECK ADD  CONSTRAINT [CK_InvoiceDetail_Price] CHECK  (([price]>=(0)))
GO
ALTER TABLE [dbo].[Invoice_Detail] CHECK CONSTRAINT [CK_InvoiceDetail_Price]
GO
ALTER TABLE [dbo].[Invoice_Detail]  WITH CHECK ADD  CONSTRAINT [CK_InvoiceDetail_Quantity] CHECK  (([quantity]>(0)))
GO
ALTER TABLE [dbo].[Invoice_Detail] CHECK CONSTRAINT [CK_InvoiceDetail_Quantity]
GO
ALTER TABLE [dbo].[Medical_Service]  WITH CHECK ADD  CONSTRAINT [CK_MedicalService_Price] CHECK  (([price]>=(0)))
GO
ALTER TABLE [dbo].[Medical_Service] CHECK CONSTRAINT [CK_MedicalService_Price]
GO
ALTER TABLE [dbo].[Medical_Service]  WITH CHECK ADD  CONSTRAINT [CK_MedicalService_Status] CHECK  (([status]='Inactive' OR [status]='Active'))
GO
ALTER TABLE [dbo].[Medical_Service] CHECK CONSTRAINT [CK_MedicalService_Status]
GO
ALTER TABLE [dbo].[Medical_Service]  WITH CHECK ADD  CONSTRAINT [CK_MedicalService_Type] CHECK  (([service_type]='Lab_Test' OR [service_type]='Examination'))
GO
ALTER TABLE [dbo].[Medical_Service] CHECK CONSTRAINT [CK_MedicalService_Type]
GO
USE [master]
GO
ALTER DATABASE [Project] SET  READ_WRITE 
GO

-- Cài đặt ID Bệnh nhân bạn đang dùng để test
DECLARE @MyPatientID INT = 1; 

-- ==========================================
-- 1. THÊM DỮ LIỆU BÁC SĨ (MOCK DOCTORS)
-- Dùng để test chức năng xem danh sách bác sĩ
-- ==========================================
-- Bác sĩ 1
INSERT INTO Account (full_name, password_hash, email, role, status)
VALUES (N'BS. Nguyễn Văn A', 'hash_123', 'bs.a@hospital.com', 'Doctor', 'Active');
DECLARE @AccountDoc1 INT = SCOPE_IDENTITY();

INSERT INTO Doctor (full_name, phone, email, department, account_id)
VALUES (N'BS. Nguyễn Văn A', '0901234567', 'bs.a@hospital.com', N'Khoa Nội Tổng Hợp', @AccountDoc1);
DECLARE @Doc1 INT = SCOPE_IDENTITY();

-- Bác sĩ 2
INSERT INTO Account (full_name, password_hash, email, role, status)
VALUES (N'BS. Trần Thị B', 'hash_123', 'bs.b@hospital.com', 'Doctor', 'Active');
DECLARE @AccountDoc2 INT = SCOPE_IDENTITY();

INSERT INTO Doctor (full_name, phone, email, department, account_id)
VALUES (N'BS. Trần Thị B', '0912345678', 'bs.b@hospital.com', N'Khoa Tim Mạch', @AccountDoc2);
DECLARE @Doc2 INT = SCOPE_IDENTITY();

-- ==========================================
-- 2. THÊM LỊCH TRỰC CỦA BÁC SĨ (MOCK SCHEDULES)
-- Dùng để test tính năng Chọn khung giờ / Chọn bác sĩ
-- ==========================================
-- Lịch tương lai để bạn thao tác Đặt lịch trên UI
INSERT INTO Doctor_Schedule (doctor_id, work_date, time_slot, max_patients, status)
VALUES 
(@Doc1, '2026-06-25', '08:00 - 09:00', 5, 'Available'),
(@Doc1, '2026-06-25', '09:00 - 10:00', 5, 'Available'),
(@Doc2, '2026-06-26', '13:30 - 15:00', 3, 'Available'),
(@Doc2, '2026-06-26', '15:00 - 16:30', 3, 'Available');

-- ==========================================
-- 3. THÊM DANH MỤC DỊCH VỤ Y TẾ 
-- Dùng để tính tiền và hiển thị hóa đơn
-- ==========================================
INSERT INTO Medical_Service (service_name, price, service_type, status)
VALUES 
(N'Khám lâm sàng ban đầu', 150000, 'Examination', 'Active'),
(N'Xét nghiệm sinh hóa máu', 350000, 'Lab_Test', 'Active'),
(N'Siêu âm ổ bụng', 200000, 'Lab_Test', 'Active');

-- ==========================================
-- 4. TẠO HÓA ĐƠN CHƯA THANH TOÁN (MOCK INVOICE PENDING)
-- Dùng để test giao diện Mục "Chưa thanh toán" và nút Thanh toán online
-- ==========================================
-- 4.1. Tạo 1 lịch hẹn "giả" trong quá khứ để gắn với hóa đơn
INSERT INTO Appointment (patient_id, schedule_id, appointment_time, booking_type, queue_number, status, created_at)
VALUES (@MyPatientID, 1, '2026-06-20 08:00:00', 'Online', 1, 'In_Progress', GETDATE());
DECLARE @MockApptID INT = SCOPE_IDENTITY();

-- 4.2. Tạo hóa đơn trạng thái Pending
INSERT INTO Invoice (patient_id, total_amount, final_amount, status, created_at)
VALUES (@MyPatientID, 500000, 500000, 'Pending', GETDATE());
DECLARE @MockInvoiceID INT = SCOPE_IDENTITY();

-- 4.3. Thêm chi tiết hóa đơn (1 Khám, 1 Xét nghiệm)
INSERT INTO Invoice_Detail (invoice_id, service_id, appointment_id, quantity, price)
VALUES 
(@MockInvoiceID, 1, @MockApptID, 1, 150000);
-- Lưu lại ID của dòng xét nghiệm để lát gắn vào kết quả
INSERT INTO Invoice_Detail (invoice_id, service_id, appointment_id, quantity, price)
VALUES 
(@MockInvoiceID, 2, @MockApptID, 1, 350000);
DECLARE @MockLabDetailID INT = SCOPE_IDENTITY();

-- ==========================================
-- 5. TẠO HỒ SƠ BỆNH ÁN CŨ ĐỂ TEST LỊCH SỬ KHÁM
-- Test chức năng: Ẩn / Hiện kết quả xét nghiệm (result_visibility)
-- ==========================================

-- CASE 1: BÁC SĨ CHO XEM KẾT QUẢ (result_visibility = 1)
INSERT INTO Medical_record (appointment_id, patient_id, doctor_id, final_diagnosis, doctor_note, result_visibility, processed_at)
VALUES (@MockApptID, @MyPatientID, @Doc1, N'Viêm dạ dày cấp', N'Uống thuốc đúng giờ, kiêng đồ cay nóng', 1, GETDATE());
DECLARE @MockRecordID1 INT = SCOPE_IDENTITY();

-- Đổ số liệu xét nghiệm random (đã hoàn thành) cho Case 1
INSERT INTO Healthy_Record (record_id, invoice_detail_id, urea, cr, hba1c, chol, bmi, status, is_synced_automatically, created_at, synced_at)
VALUES (@MockRecordID1, @MockLabDetailID, 4.5, 75.0, 5.2, 4.1, 22.5, 'Completed', 1, GETDATE(), GETDATE());

-- CASE 2: BÁC SĨ ẨN KẾT QUẢ (result_visibility = 0)
-- Tạo nhanh 1 lượt khám khác
INSERT INTO Appointment (patient_id, schedule_id, appointment_time, booking_type, queue_number, status, created_at)
VALUES (@MyPatientID, 3, '2026-06-21 09:00:00', 'Online', 2, 'Completed', GETDATE());
DECLARE @MockApptID2 INT = SCOPE_IDENTITY();

INSERT INTO Medical_record (appointment_id, patient_id, doctor_id, final_diagnosis, doctor_note, result_visibility, processed_at)
VALUES (@MockApptID2, @MyPatientID, @Doc2, N'Nghi ngờ u bướu', N'Chờ xét nghiệm sinh thiết để đánh giá thêm', 0, GETDATE());
-- Không cần đổ số liệu Healthy_Record cho Case 2 vì UI sẽ bị chặn hiển thị do cờ = 0.
