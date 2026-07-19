USE [master]
GO
/****** Object:  Database [Project]    Script Date: 7/11/2026 12:19:40 AM ******/
CREATE DATABASE [Project]
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
EXEC sys.sp_db_vardecimal_storage_format N'Project', N'ON'
GO
ALTER DATABASE [Project] SET QUERY_STORE = ON
GO
ALTER DATABASE [Project] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 1000, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)
GO
USE [Project]
GO
/****** Object:  Table [dbo].[Account]    Script Date: 7/11/2026 12:19:41 AM ******/
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
/****** Object:  Table [dbo].[AI_Summary]    Script Date: 7/11/2026 12:19:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AI_Summary](
	[summary_id] [varchar](50) NOT NULL,
	[appointment_id] [int] NOT NULL,
	[patient_id] [int] NOT NULL,
	[ai_summary] [nvarchar](max) NOT NULL,
	[created_at] [datetime] NULL,
 CONSTRAINT [PK_AISummary] PRIMARY KEY CLUSTERED 
(
	[summary_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Appointment]    Script Date: 7/11/2026 12:19:41 AM ******/
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
	[consultation_start_time] [datetime2](7) NULL,
 CONSTRAINT [PK_Appointment] PRIMARY KEY CLUSTERED 
(
	[appointment_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Doctor]    Script Date: 7/11/2026 12:19:41 AM ******/
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
	[date_of_birth] [date] NULL,
	[gender] [varchar](10) NULL,
	[address] [nvarchar](255) NULL,
PRIMARY KEY CLUSTERED 
(
	[doctor_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Doctor_AI]    Script Date: 7/11/2026 12:19:41 AM ******/
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
/****** Object:  Table [dbo].[Doctor_Lab]    Script Date: 7/11/2026 12:19:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Doctor_Lab](
	[lab_id] [int] IDENTITY(1,1) NOT NULL,
	[full_name] [nvarchar](100) NOT NULL,
	[phone] [varchar](20) NULL,
	[email] [varchar](100) NULL,
	[lab_name] [nvarchar](100) NULL,
	[account_id] [int] NOT NULL,
	[date_of_birth] [date] NULL,
	[gender] [varchar](10) NULL,
	[address] [nvarchar](255) NULL,
PRIMARY KEY CLUSTERED 
(
	[lab_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Doctor_Schedule]    Script Date: 7/11/2026 12:19:41 AM ******/
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
	[online_quota] [int] NULL,
	[room_id] [varchar](50) NULL,
 CONSTRAINT [PK_Doctor_Schedule] PRIMARY KEY CLUSTERED 
(
	[schedule_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Healthy_Record]    Script Date: 7/11/2026 12:19:41 AM ******/
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
/****** Object:  Table [dbo].[Invoice]    Script Date: 7/11/2026 12:19:41 AM ******/
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
/****** Object:  Table [dbo].[Invoice_Detail]    Script Date: 7/11/2026 12:19:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Invoice_Detail](
	[invoice_detail_id] [int] IDENTITY(1,1) NOT NULL,
	[invoice_id] [int] NOT NULL,
	[service_id] [int] NOT NULL,
	[appointment_id] [int] NULL,
	[quantity] [int] NOT NULL,
	[price] [decimal](18, 2) NOT NULL,
	[health_record_id] [int] NULL,
	[doctor_id] [int] NULL,
	[request_note] [nvarchar](1000) NULL,
	[lab_status] [varchar](20) NULL,
	[lab_result] [nvarchar](max) NULL,
	[requested_at] [datetime] NULL,
	[completed_at] [datetime] NULL,
 CONSTRAINT [PK_Invoice_Detail] PRIMARY KEY CLUSTERED 
(
	[invoice_detail_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Lab_Order]    Script Date: 7/11/2026 12:19:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Lab_Order](
	[order_id] [varchar](50) NOT NULL,
	[appointment_id] [int] NOT NULL,
	[patient_id] [int] NOT NULL,
	[room_id] [varchar](50) NOT NULL,
	[service_id] [int] NOT NULL,
	[lab_id] [int] NULL,
	[status] [varchar](20) NULL,
	[created_at] [datetime] NULL,
 CONSTRAINT [PK_LabOrder] PRIMARY KEY CLUSTERED 
(
	[order_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Lab_Schedule]    Script Date: 7/11/2026 12:19:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Lab_Schedule](
	[lab_sched_id] [int] IDENTITY(1,1) NOT NULL,
	[lab_id] [int] NOT NULL,
	[work_date] [date] NOT NULL,
	[time_slot] [varchar](50) NOT NULL,
	[room_id] [nvarchar](100) NULL,
	[status] [nvarchar](50) NULL,
 CONSTRAINT [PK_Lab_Schedule] PRIMARY KEY CLUSTERED 
(
	[lab_sched_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Medical_record]    Script Date: 7/11/2026 12:19:41 AM ******/
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
	[laboratory_test_types] [nvarchar](max) NULL,
	[laboratory_total_price] [decimal](18, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[record_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Medical_Service]    Script Date: 7/11/2026 12:19:41 AM ******/
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
/****** Object:  Table [dbo].[Notification]    Script Date: 7/11/2026 12:19:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Notification](
	[NotificationID] [int] IDENTITY(1,1) NOT NULL,
	[AccountID] [int] NULL,
	[Title] [nvarchar](255) NULL,
	[Content] [nvarchar](max) NULL,
	[Type] [varchar](50) NULL,
	[IsRead] [bit] NULL,
	[CreatedAt] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[NotificationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Patient]    Script Date: 7/11/2026 12:19:41 AM ******/
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
/****** Object:  Table [dbo].[Reception]    Script Date: 7/11/2026 12:19:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Reception](
	[reception_id] [int] IDENTITY(1,1) NOT NULL,
	[full_name] [nvarchar](100) NOT NULL,
	[date_of_birth] [date] NULL,
	[gender] [varchar](10) NULL,
	[phone] [varchar](20) NULL,
	[email] [varchar](100) NULL,
	[address] [nvarchar](255) NULL,
	[account_id] [int] NULL,
	[desk_location] [nvarchar](50) NULL,
 CONSTRAINT [PK_Reception] PRIMARY KEY CLUSTERED 
(
	[reception_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Reception_Schedule]    Script Date: 7/11/2026 12:19:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Reception_Schedule](
	[reception_sched_id] [int] IDENTITY(1,1) NOT NULL,
	[reception_id] [int] NOT NULL,
	[work_date] [date] NOT NULL,
	[time_slot] [nvarchar](50) NOT NULL,
	[status] [nvarchar](50) NULL,
 CONSTRAINT [PK_Reception_Schedule] PRIMARY KEY CLUSTERED 
(
	[reception_sched_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Record_Transfer_History]    Script Date: 7/11/2026 12:19:41 AM ******/
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
/****** Object:  Table [dbo].[Room]    Script Date: 7/11/2026 12:19:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE SEQUENCE [dbo].[Seq_RoomId] 
 AS [int]
 START WITH 301
 INCREMENT BY 1
GO
CREATE TABLE [dbo].[Room](
	[room_id] [varchar](50) NOT NULL,
	[room_name] [nvarchar](100) NOT NULL,
	[location] [nvarchar](255) NULL,
	[status] [varchar](20) NULL,
 CONSTRAINT [PK_Room] PRIMARY KEY CLUSTERED 
(
	[room_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Room] ADD  CONSTRAINT [DF_Room_RoomId]  DEFAULT ('R' + CAST(NEXT VALUE FOR [dbo].[Seq_RoomId] AS [varchar](10))) FOR [room_id]
GO
SET IDENTITY_INSERT [dbo].[Account] ON 
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (2, N'BS. Nguyễn Văn A', N'hash_123', N'bs.a@hospital.com', N'Doctor', CAST(N'2026-06-21T21:24:15.620' AS DateTime), N'Active')

INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (3, N'BS. Trần Thị B', N'hash_123', N'bs.b@hospital.com', N'Doctor', CAST(N'2026-06-21T21:24:15.627' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (6, N'Bệnh nhân Test 1', N'hash123', N'patient_new1@gmail.com', N'Patient', CAST(N'2026-06-22T01:04:10.290' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (7, N'Bệnh nhân Test 2', N'hash123', N'patient_new2@gmail.com', N'Patient', CAST(N'2026-06-22T01:04:10.293' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (8, N'Bệnh nhân Test 3', N'hash123', N'patient_new3@gmail.com', N'Patient', CAST(N'2026-06-22T01:04:10.293' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (9, N'Bệnh nhân Test 4', N'hash123', N'patient_new4@gmail.com', N'Patient', CAST(N'2026-06-22T01:04:10.293' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (10, N'Bệnh nhân Test 5', N'hash123', N'patient_new5@gmail.com', N'Patient', CAST(N'2026-06-22T01:04:10.297' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (11, N'Bệnh nhân Test 6', N'hash123', N'patient_new6@gmail.com', N'Patient', CAST(N'2026-06-22T01:04:10.297' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (12, N'Bệnh nhân Test 7', N'hash123', N'patient_new7@gmail.com', N'Patient', CAST(N'2026-06-22T01:04:10.297' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (13, N'Bệnh nhân Test 8', N'hash123', N'patient_new8@gmail.com', N'Patient', CAST(N'2026-06-22T01:04:10.297' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (14, N'Bệnh nhân Test 9', N'hash123', N'patient_new9@gmail.com', N'Patient', CAST(N'2026-06-22T01:04:10.297' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (15, N'Bệnh nhân Test 10', N'hash123', N'patient_new10@gmail.com', N'Patient', CAST(N'2026-06-22T01:04:10.300' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (16, N'BS Nội Tiết 1', N'hash123', N'doctor_nt1@hospital.com', N'Doctor', CAST(N'2026-06-22T01:04:10.300' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (17, N'BS Nội Tiết 2', N'hash123', N'doctor_nt2@hospital.com', N'Doctor', CAST(N'2026-06-22T01:04:10.303' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (18, N'BS Nội Tiết 3', N'hash123', N'doctor_nt3@hospital.com', N'Doctor', CAST(N'2026-06-22T01:04:10.303' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (19, N'BS Nội Tiết 4', N'hash123', N'doctor_nt4@hospital.com', N'Doctor', CAST(N'2026-06-22T01:04:10.307' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (20, N'BS Nội Tiết 5', N'hash123', N'doctor_nt5@hospital.com', N'Doctor', CAST(N'2026-06-22T01:04:10.307' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (21, N'BS Nội Tiết 6', N'hash123', N'doctor_nt6@hospital.com', N'Doctor', CAST(N'2026-06-22T01:04:10.307' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (22, N'BS Nội Tiết 7', N'hash123', N'doctor_nt7@hospital.com', N'Doctor', CAST(N'2026-06-22T01:04:10.307' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (23, N'BS Nội Tiết 8', N'hash123', N'doctor_nt8@hospital.com', N'Doctor', CAST(N'2026-06-22T01:04:10.307' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (24, N'BS Nội Tiết 9', N'hash123', N'doctor_nt9@hospital.com', N'Doctor', CAST(N'2026-06-22T01:04:10.310' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (25, N'BS Nội Tiết 10', N'hash123', N'doctor_nt10@hospital.com', N'Doctor', CAST(N'2026-06-22T01:04:10.310' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (26, N'Quản Trị Viên', N'hash123', N'admin@hospital.com', N'Admin', CAST(N'2026-06-30T23:37:55.317' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (27, N'Trần Đức Lương', N'ef797c8118f02dfb649607dd5d3f8c7623048c9c063d532cc95c5ed7a898a64f', N'luongtd2008@gmail.com', N'Patient', CAST(N'2026-07-01T13:49:47.620' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (28, N'Nhân viên Lễ tân 1', N'hash123', N'receptionist1@hospital.com', N'Receptionist', CAST(N'2026-07-01T13:50:42.897' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (30, N'BS Phòng Lab 1', N'hash123', N'lab_doctor1@hospital.com', N'Doctor_Lab', CAST(N'2026-07-08T22:40:45.530' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (31, N'Bác sĩ xét nghiệm', N'3705b578e8fcb1b82a94ad917881ec248bbd4111645e91aed3c19af12d82116f', N'lab@diabetescare.com', N'doctor_lab', CAST(N'2026-07-08T23:06:34.160' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (32, N'Phan Van Bao Trung', N'279b9021be8c239c8d57464922eed2f8df746e787659ff4db9def35a4b261ddf', N'trungkitit@gmail.com', N'Patient', CAST(N'2026-07-10T16:11:54.953' AS DateTime), N'Active')
SET IDENTITY_INSERT [dbo].[Account] OFF
GO
SET IDENTITY_INSERT [dbo].[Appointment] ON 

INSERT [dbo].[Appointment] ([appointment_id], [patient_id], [schedule_id], [appointment_time], [booking_type], [queue_number], [status], [created_at], [consultation_start_time]) VALUES (15, 2, 10, CAST(N'2026-07-15T08:00:00.000' AS DateTime), N'Online', 1, N'Completed', CAST(N'2026-07-15T08:00:00.000' AS DateTime), NULL)
INSERT [dbo].[Appointment] ([appointment_id], [patient_id], [schedule_id], [appointment_time], [booking_type], [queue_number], [status], [created_at], [consultation_start_time]) VALUES (16, 3, 20, CAST(N'2026-07-15T08:00:00.000' AS DateTime), N'Online', 1, N'Completed', CAST(N'2026-07-15T08:00:00.000' AS DateTime), NULL)
INSERT [dbo].[Appointment] ([appointment_id], [patient_id], [schedule_id], [appointment_time], [booking_type], [queue_number], [status], [created_at], [consultation_start_time]) VALUES (17, 4, 30, CAST(N'2026-07-15T08:00:00.000' AS DateTime), N'Online', 1, N'Completed', CAST(N'2026-07-15T08:00:00.000' AS DateTime), NULL)
INSERT [dbo].[Appointment] ([appointment_id], [patient_id], [schedule_id], [appointment_time], [booking_type], [queue_number], [status], [created_at], [consultation_start_time]) VALUES (18, 5, 40, CAST(N'2026-07-15T08:00:00.000' AS DateTime), N'Online', 1, N'Completed', CAST(N'2026-07-15T08:00:00.000' AS DateTime), NULL)
INSERT [dbo].[Appointment] ([appointment_id], [patient_id], [schedule_id], [appointment_time], [booking_type], [queue_number], [status], [created_at], [consultation_start_time]) VALUES (19, 6, 50, CAST(N'2026-07-15T08:00:00.000' AS DateTime), N'Online', 1, N'Completed', CAST(N'2026-07-15T08:00:00.000' AS DateTime), NULL)
INSERT [dbo].[Appointment] ([appointment_id], [patient_id], [schedule_id], [appointment_time], [booking_type], [queue_number], [status], [created_at], [consultation_start_time]) VALUES (20, 7, 60, CAST(N'2026-07-15T08:00:00.000' AS DateTime), N'Online', 1, N'Completed', CAST(N'2026-07-15T08:00:00.000' AS DateTime), NULL)
SET IDENTITY_INSERT [dbo].[Appointment] OFF
GO
SET IDENTITY_INSERT [dbo].[Doctor] ON 

INSERT [dbo].[Doctor] ([doctor_id], [full_name], [phone], [email], [department], [account_id], [date_of_birth], [gender], [address]) VALUES (1, N'BS. Nguyễn Văn A', N'0901234567', N'bs.a@hospital.com', N'Khoa Nội Tổng Hợp', 2, NULL, NULL, NULL)
INSERT [dbo].[Doctor] ([doctor_id], [full_name], [phone], [email], [department], [account_id], [date_of_birth], [gender], [address]) VALUES (2, N'BS. Trần Thị B', N'0912345678', N'bs.b@hospital.com', N'Khoa Tim Mạch', 3, NULL, NULL, NULL)
INSERT [dbo].[Doctor] ([doctor_id], [full_name], [phone], [email], [department], [account_id], [date_of_birth], [gender], [address]) VALUES (5, N'BS Nội Tiết 1', N'0911111101', N'doctor_nt1@hospital.com', N'Khoa Nội Tiết', 16, NULL, NULL, NULL)
INSERT [dbo].[Doctor] ([doctor_id], [full_name], [phone], [email], [department], [account_id], [date_of_birth], [gender], [address]) VALUES (6, N'BS Nội Tiết 2', N'0911111102', N'doctor_nt2@hospital.com', N'Khoa Nội Tiết', 17, NULL, NULL, NULL)
INSERT [dbo].[Doctor] ([doctor_id], [full_name], [phone], [email], [department], [account_id], [date_of_birth], [gender], [address]) VALUES (7, N'BS Nội Tiết 3', N'0911111103', N'doctor_nt3@hospital.com', N'Khoa Nội Tiết', 18, NULL, NULL, NULL)
INSERT [dbo].[Doctor] ([doctor_id], [full_name], [phone], [email], [department], [account_id], [date_of_birth], [gender], [address]) VALUES (8, N'BS Nội Tiết 4', N'0911111104', N'doctor_nt4@hospital.com', N'Khoa Nội Tiết', 19, NULL, NULL, NULL)
INSERT [dbo].[Doctor] ([doctor_id], [full_name], [phone], [email], [department], [account_id], [date_of_birth], [gender], [address]) VALUES (9, N'BS Nội Tiết 5', N'0911111105', N'doctor_nt5@hospital.com', N'Khoa Nội Tiết', 20, NULL, NULL, NULL)
INSERT [dbo].[Doctor] ([doctor_id], [full_name], [phone], [email], [department], [account_id], [date_of_birth], [gender], [address]) VALUES (10, N'BS Nội Tiết 6', N'0911111106', N'doctor_nt6@hospital.com', N'Khoa Nội Tiết', 21, NULL, NULL, NULL)
INSERT [dbo].[Doctor] ([doctor_id], [full_name], [phone], [email], [department], [account_id], [date_of_birth], [gender], [address]) VALUES (11, N'BS Nội Tiết 7', N'0911111107', N'doctor_nt7@hospital.com', N'Khoa Nội Tiết', 22, NULL, NULL, NULL)
INSERT [dbo].[Doctor] ([doctor_id], [full_name], [phone], [email], [department], [account_id], [date_of_birth], [gender], [address]) VALUES (12, N'BS Nội Tiết 8', N'0911111108', N'doctor_nt8@hospital.com', N'Khoa Nội Tiết', 23, NULL, NULL, NULL)
INSERT [dbo].[Doctor] ([doctor_id], [full_name], [phone], [email], [department], [account_id], [date_of_birth], [gender], [address]) VALUES (13, N'BS Nội Tiết 9', N'0911111109', N'doctor_nt9@hospital.com', N'Khoa Nội Tiết', 24, NULL, NULL, NULL)
INSERT [dbo].[Doctor] ([doctor_id], [full_name], [phone], [email], [department], [account_id], [date_of_birth], [gender], [address]) VALUES (14, N'BS Nội Tiết 10', N'0911111110', N'doctor_nt10@hospital.com', N'Khoa Nội Tiết', 25, NULL, NULL, NULL)
SET IDENTITY_INSERT [dbo].[Doctor] OFF
GO
SET IDENTITY_INSERT [dbo].[Doctor_Lab] ON 

INSERT [dbo].[Doctor_Lab] ([lab_id], [full_name], [phone], [email], [lab_name], [account_id], [date_of_birth], [gender], [address]) VALUES (1, N'Bác sĩ xét nghiệm', N'0987654321', N'lab@diabetescare.com', N'Phòng xét nghiệm', 31, NULL, NULL, NULL)
SET IDENTITY_INSERT [dbo].[Doctor_Lab] OFF
GO
SET IDENTITY_INSERT [dbo].[Doctor_Schedule] ON 

INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (1, 2, CAST(N'2026-06-25' AS Date), N'08:00 - 09:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (2, 2, CAST(N'2026-06-25' AS Date), N'09:00 - 10:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (3, 2, CAST(N'2026-06-26' AS Date), N'13:30 - 15:00', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (4, 2, CAST(N'2026-06-26' AS Date), N'15:00 - 16:30', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (5, 13, CAST(N'2026-06-22' AS Date), N'08:00 - 10:00', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (6, 13, CAST(N'2026-06-22' AS Date), N'13:30 - 15:30', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (7, 12, CAST(N'2026-06-22' AS Date), N'08:00 - 10:00', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (8, 12, CAST(N'2026-06-22' AS Date), N'13:30 - 15:30', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (9, 6, CAST(N'2026-06-22' AS Date), N'08:00 - 10:00', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (10, 6, CAST(N'2026-06-22' AS Date), N'13:30 - 15:30', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (11, 11, CAST(N'2026-06-22' AS Date), N'08:00 - 10:00', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (12, 11, CAST(N'2026-06-22' AS Date), N'13:30 - 15:30', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (13, 14, CAST(N'2026-06-22' AS Date), N'08:00 - 10:00', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (14, 14, CAST(N'2026-06-22' AS Date), N'13:30 - 15:30', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (15, 9, CAST(N'2026-06-22' AS Date), N'08:00 - 10:00', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (16, 9, CAST(N'2026-06-22' AS Date), N'13:30 - 15:30', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (17, 7, CAST(N'2026-06-22' AS Date), N'08:00 - 10:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (18, 7, CAST(N'2026-06-22' AS Date), N'13:30 - 15:30', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (19, 11, CAST(N'2026-06-23' AS Date), N'08:00 - 10:00', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (20, 11, CAST(N'2026-06-23' AS Date), N'13:30 - 15:30', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (21, 9, CAST(N'2026-06-23' AS Date), N'08:00 - 10:00', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (22, 9, CAST(N'2026-06-23' AS Date), N'13:30 - 15:30', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (23, 14, CAST(N'2026-06-23' AS Date), N'08:00 - 10:00', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (24, 14, CAST(N'2026-06-23' AS Date), N'13:30 - 15:30', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (25, 13, CAST(N'2026-06-23' AS Date), N'08:00 - 10:00', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (26, 13, CAST(N'2026-06-23' AS Date), N'13:30 - 15:30', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (27, 12, CAST(N'2026-06-23' AS Date), N'08:00 - 10:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (28, 12, CAST(N'2026-06-23' AS Date), N'13:30 - 15:30', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (29, 10, CAST(N'2026-06-23' AS Date), N'08:00 - 10:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (30, 10, CAST(N'2026-06-23' AS Date), N'13:30 - 15:30', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (31, 13, CAST(N'2026-06-24' AS Date), N'08:00 - 10:00', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (32, 13, CAST(N'2026-06-24' AS Date), N'13:30 - 15:30', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (33, 14, CAST(N'2026-06-24' AS Date), N'08:00 - 10:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (34, 14, CAST(N'2026-06-24' AS Date), N'13:30 - 15:30', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (35, 7, CAST(N'2026-06-24' AS Date), N'08:00 - 10:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (36, 7, CAST(N'2026-06-24' AS Date), N'13:30 - 15:30', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (37, 8, CAST(N'2026-06-24' AS Date), N'08:00 - 10:00', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (38, 8, CAST(N'2026-06-24' AS Date), N'13:30 - 15:30', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (39, 11, CAST(N'2026-06-24' AS Date), N'08:00 - 10:00', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (40, 11, CAST(N'2026-06-24' AS Date), N'13:30 - 15:30', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (41, 7, CAST(N'2026-06-25' AS Date), N'08:00 - 10:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (42, 7, CAST(N'2026-06-25' AS Date), N'13:30 - 15:30', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (43, 5, CAST(N'2026-06-25' AS Date), N'08:00 - 10:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (44, 5, CAST(N'2026-06-25' AS Date), N'13:30 - 15:30', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (45, 9, CAST(N'2026-06-25' AS Date), N'08:00 - 10:00', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (46, 9, CAST(N'2026-06-25' AS Date), N'13:30 - 15:30', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (47, 11, CAST(N'2026-06-25' AS Date), N'08:00 - 10:00', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (48, 11, CAST(N'2026-06-25' AS Date), N'13:30 - 15:30', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (49, 6, CAST(N'2026-06-25' AS Date), N'08:00 - 10:00', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (50, 6, CAST(N'2026-06-25' AS Date), N'13:30 - 15:30', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (51, 13, CAST(N'2026-06-25' AS Date), N'08:00 - 10:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (52, 13, CAST(N'2026-06-25' AS Date), N'13:30 - 15:30', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (53, 7, CAST(N'2026-06-26' AS Date), N'08:00 - 10:00', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (54, 7, CAST(N'2026-06-26' AS Date), N'13:30 - 15:30', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (55, 11, CAST(N'2026-06-26' AS Date), N'08:00 - 10:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (56, 11, CAST(N'2026-06-26' AS Date), N'13:30 - 15:30', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (57, 9, CAST(N'2026-06-26' AS Date), N'08:00 - 10:00', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (58, 9, CAST(N'2026-06-26' AS Date), N'13:30 - 15:30', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (59, 6, CAST(N'2026-06-26' AS Date), N'08:00 - 10:00', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (60, 6, CAST(N'2026-06-26' AS Date), N'13:30 - 15:30', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (61, 10, CAST(N'2026-06-26' AS Date), N'08:00 - 10:00', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (62, 10, CAST(N'2026-06-26' AS Date), N'13:30 - 15:30', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (63, 13, CAST(N'2026-06-26' AS Date), N'08:00 - 10:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (64, 13, CAST(N'2026-06-26' AS Date), N'13:30 - 15:30', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (65, 14, CAST(N'2026-06-26' AS Date), N'08:00 - 10:00', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (66, 14, CAST(N'2026-06-26' AS Date), N'13:30 - 15:30', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (67, 7, CAST(N'2026-06-27' AS Date), N'08:00 - 10:00', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (68, 7, CAST(N'2026-06-27' AS Date), N'13:30 - 15:30', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (69, 6, CAST(N'2026-06-27' AS Date), N'08:00 - 10:00', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (70, 6, CAST(N'2026-06-27' AS Date), N'13:30 - 15:30', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (71, 13, CAST(N'2026-06-27' AS Date), N'08:00 - 10:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (72, 13, CAST(N'2026-06-27' AS Date), N'13:30 - 15:30', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (73, 14, CAST(N'2026-06-27' AS Date), N'08:00 - 10:00', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (74, 14, CAST(N'2026-06-27' AS Date), N'13:30 - 15:30', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (75, 8, CAST(N'2026-06-27' AS Date), N'08:00 - 10:00', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (76, 8, CAST(N'2026-06-27' AS Date), N'13:30 - 15:30', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (77, 9, CAST(N'2026-06-27' AS Date), N'08:00 - 10:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (78, 9, CAST(N'2026-06-27' AS Date), N'13:30 - 15:30', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (79, 11, CAST(N'2026-06-27' AS Date), N'08:00 - 10:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (80, 11, CAST(N'2026-06-27' AS Date), N'13:30 - 15:30', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (81, 5, CAST(N'2026-06-27' AS Date), N'08:00 - 10:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (82, 5, CAST(N'2026-06-27' AS Date), N'13:30 - 15:30', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (83, 9, CAST(N'2026-06-28' AS Date), N'08:00 - 10:00', 3, N'Cancelled', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (84, 9, CAST(N'2026-06-28' AS Date), N'13:30 - 15:30', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (85, 7, CAST(N'2026-06-28' AS Date), N'08:00 - 10:00', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (86, 7, CAST(N'2026-06-28' AS Date), N'13:30 - 15:30', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (87, 12, CAST(N'2026-06-28' AS Date), N'08:00 - 10:00', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (88, 12, CAST(N'2026-06-28' AS Date), N'13:30 - 15:30', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (89, 6, CAST(N'2026-06-28' AS Date), N'08:00 - 10:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (90, 6, CAST(N'2026-06-28' AS Date), N'13:30 - 15:30', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (91, 11, CAST(N'2026-06-28' AS Date), N'08:00 - 10:00', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (92, 11, CAST(N'2026-06-28' AS Date), N'13:30 - 15:30', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (93, 10, CAST(N'2026-06-28' AS Date), N'08:00 - 10:00', 3, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (94, 10, CAST(N'2026-06-28' AS Date), N'13:30 - 15:30', 4, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (95, 5, CAST(N'2026-07-01' AS Date), N'07:00-09:00', 5, N'Expired', 2, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (96, 14, CAST(N'2026-07-02' AS Date), N'07:00-09:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (97, 14, CAST(N'2026-07-01' AS Date), N'07:00-09:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (98, 6, CAST(N'2026-07-01' AS Date), N'07:00-09:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (99, 7, CAST(N'2026-07-01' AS Date), N'09:00-11:00', 5, N'Expired', 3, NULL)
GO
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (100, 8, CAST(N'2026-07-01' AS Date), N'09:00-11:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (101, 9, CAST(N'2026-07-01' AS Date), N'11:00-13:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (102, 10, CAST(N'2026-07-01' AS Date), N'11:00-13:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (103, 11, CAST(N'2026-07-01' AS Date), N'13:00-15:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (104, 12, CAST(N'2026-07-01' AS Date), N'13:00-15:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (105, 13, CAST(N'2026-07-01' AS Date), N'15:00-17:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (106, 1, CAST(N'2026-07-01' AS Date), N'15:00-17:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (107, 2, CAST(N'2026-07-01' AS Date), N'17:00-19:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (108, 5, CAST(N'2026-07-01' AS Date), N'17:00-19:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (109, 5, CAST(N'2026-07-09' AS Date), N'07:00-08:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (110, 14, CAST(N'2026-07-09' AS Date), N'07:00-08:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (111, 6, CAST(N'2026-07-09' AS Date), N'08:00-09:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (112, 7, CAST(N'2026-07-09' AS Date), N'08:00-09:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (113, 8, CAST(N'2026-07-09' AS Date), N'09:00-10:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (114, 9, CAST(N'2026-07-09' AS Date), N'09:00-10:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (115, 10, CAST(N'2026-07-09' AS Date), N'10:00-11:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (116, 11, CAST(N'2026-07-09' AS Date), N'10:00-11:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (117, 12, CAST(N'2026-07-09' AS Date), N'11:00-12:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (118, 13, CAST(N'2026-07-09' AS Date), N'11:00-12:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (119, 1, CAST(N'2026-07-09' AS Date), N'12:00-13:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (120, 2, CAST(N'2026-07-09' AS Date), N'12:00-13:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (121, 5, CAST(N'2026-07-09' AS Date), N'13:00-14:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (122, 14, CAST(N'2026-07-09' AS Date), N'13:00-14:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (123, 6, CAST(N'2026-07-09' AS Date), N'14:00-15:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (124, 7, CAST(N'2026-07-09' AS Date), N'14:00-15:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (125, 8, CAST(N'2026-07-09' AS Date), N'15:00-16:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (126, 9, CAST(N'2026-07-09' AS Date), N'15:00-16:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (127, 10, CAST(N'2026-07-09' AS Date), N'16:00-17:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (128, 11, CAST(N'2026-07-09' AS Date), N'16:00-17:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (129, 12, CAST(N'2026-07-09' AS Date), N'17:00-18:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (130, 13, CAST(N'2026-07-09' AS Date), N'17:00-18:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (131, 1, CAST(N'2026-07-09' AS Date), N'18:00-19:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (132, 2, CAST(N'2026-07-09' AS Date), N'18:00-19:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (133, 5, CAST(N'2026-07-10' AS Date), N'07:00-08:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (134, 14, CAST(N'2026-07-10' AS Date), N'07:00-08:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (135, 6, CAST(N'2026-07-10' AS Date), N'08:00-09:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (136, 7, CAST(N'2026-07-10' AS Date), N'08:00-09:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (137, 8, CAST(N'2026-07-10' AS Date), N'09:00-10:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (138, 9, CAST(N'2026-07-10' AS Date), N'09:00-10:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (139, 10, CAST(N'2026-07-10' AS Date), N'10:00-11:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (140, 11, CAST(N'2026-07-10' AS Date), N'10:00-11:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (141, 12, CAST(N'2026-07-10' AS Date), N'11:00-12:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (142, 13, CAST(N'2026-07-10' AS Date), N'11:00-12:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (143, 1, CAST(N'2026-07-10' AS Date), N'12:00-13:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (144, 2, CAST(N'2026-07-10' AS Date), N'12:00-13:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (145, 5, CAST(N'2026-07-10' AS Date), N'13:00-14:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (146, 14, CAST(N'2026-07-10' AS Date), N'13:00-14:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (147, 6, CAST(N'2026-07-10' AS Date), N'14:00-15:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (148, 7, CAST(N'2026-07-10' AS Date), N'14:00-15:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (149, 8, CAST(N'2026-07-10' AS Date), N'15:00-16:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (150, 9, CAST(N'2026-07-10' AS Date), N'15:00-16:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (151, 10, CAST(N'2026-07-10' AS Date), N'16:00-17:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (152, 11, CAST(N'2026-07-10' AS Date), N'16:00-17:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (153, 12, CAST(N'2026-07-10' AS Date), N'17:00-18:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (154, 13, CAST(N'2026-07-10' AS Date), N'17:00-18:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (155, 1, CAST(N'2026-07-10' AS Date), N'18:00-19:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (156, 2, CAST(N'2026-07-10' AS Date), N'18:00-19:00', 5, N'Expired', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (157, 5, CAST(N'2026-07-11' AS Date), N'07:00-08:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (158, 14, CAST(N'2026-07-11' AS Date), N'07:00-08:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (159, 6, CAST(N'2026-07-11' AS Date), N'08:00-09:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (160, 7, CAST(N'2026-07-11' AS Date), N'08:00-09:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (161, 8, CAST(N'2026-07-11' AS Date), N'09:00-10:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (162, 9, CAST(N'2026-07-11' AS Date), N'09:00-10:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (163, 10, CAST(N'2026-07-11' AS Date), N'10:00-11:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (164, 11, CAST(N'2026-07-11' AS Date), N'10:00-11:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (165, 12, CAST(N'2026-07-11' AS Date), N'11:00-12:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (166, 13, CAST(N'2026-07-11' AS Date), N'11:00-12:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (167, 1, CAST(N'2026-07-11' AS Date), N'12:00-13:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (168, 2, CAST(N'2026-07-11' AS Date), N'12:00-13:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (169, 5, CAST(N'2026-07-11' AS Date), N'13:00-14:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (170, 14, CAST(N'2026-07-11' AS Date), N'13:00-14:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (171, 6, CAST(N'2026-07-11' AS Date), N'14:00-15:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (172, 7, CAST(N'2026-07-11' AS Date), N'14:00-15:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (173, 8, CAST(N'2026-07-11' AS Date), N'15:00-16:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (174, 9, CAST(N'2026-07-11' AS Date), N'15:00-16:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (175, 10, CAST(N'2026-07-11' AS Date), N'16:00-17:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (176, 11, CAST(N'2026-07-11' AS Date), N'16:00-17:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (177, 12, CAST(N'2026-07-11' AS Date), N'17:00-18:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (178, 13, CAST(N'2026-07-11' AS Date), N'17:00-18:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (179, 1, CAST(N'2026-07-11' AS Date), N'18:00-19:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (180, 2, CAST(N'2026-07-11' AS Date), N'18:00-19:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (181, 5, CAST(N'2026-07-12' AS Date), N'07:00-08:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (182, 14, CAST(N'2026-07-12' AS Date), N'07:00-08:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (183, 6, CAST(N'2026-07-12' AS Date), N'08:00-09:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (184, 7, CAST(N'2026-07-12' AS Date), N'08:00-09:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (185, 8, CAST(N'2026-07-12' AS Date), N'09:00-10:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (186, 9, CAST(N'2026-07-12' AS Date), N'09:00-10:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (187, 10, CAST(N'2026-07-12' AS Date), N'10:00-11:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (188, 11, CAST(N'2026-07-12' AS Date), N'10:00-11:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (189, 12, CAST(N'2026-07-12' AS Date), N'11:00-12:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (190, 13, CAST(N'2026-07-12' AS Date), N'11:00-12:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (191, 1, CAST(N'2026-07-12' AS Date), N'12:00-13:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (192, 2, CAST(N'2026-07-12' AS Date), N'12:00-13:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (193, 5, CAST(N'2026-07-12' AS Date), N'13:00-14:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (194, 14, CAST(N'2026-07-12' AS Date), N'13:00-14:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (195, 6, CAST(N'2026-07-12' AS Date), N'14:00-15:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (196, 7, CAST(N'2026-07-12' AS Date), N'14:00-15:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (197, 8, CAST(N'2026-07-12' AS Date), N'15:00-16:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (198, 9, CAST(N'2026-07-12' AS Date), N'15:00-16:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (199, 10, CAST(N'2026-07-12' AS Date), N'16:00-17:00', 5, N'Available', 3, NULL)
GO
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (200, 11, CAST(N'2026-07-12' AS Date), N'16:00-17:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (201, 12, CAST(N'2026-07-12' AS Date), N'17:00-18:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (202, 13, CAST(N'2026-07-12' AS Date), N'17:00-18:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (203, 1, CAST(N'2026-07-12' AS Date), N'18:00-19:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (204, 2, CAST(N'2026-07-12' AS Date), N'18:00-19:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (205, 5, CAST(N'2026-07-13' AS Date), N'07:00-08:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (206, 14, CAST(N'2026-07-13' AS Date), N'07:00-08:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (207, 6, CAST(N'2026-07-13' AS Date), N'08:00-09:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (208, 7, CAST(N'2026-07-13' AS Date), N'08:00-09:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (209, 8, CAST(N'2026-07-13' AS Date), N'09:00-10:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (210, 9, CAST(N'2026-07-13' AS Date), N'09:00-10:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (211, 10, CAST(N'2026-07-13' AS Date), N'10:00-11:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (212, 11, CAST(N'2026-07-13' AS Date), N'10:00-11:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (213, 12, CAST(N'2026-07-13' AS Date), N'11:00-12:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (214, 13, CAST(N'2026-07-13' AS Date), N'11:00-12:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (215, 1, CAST(N'2026-07-13' AS Date), N'12:00-13:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (216, 2, CAST(N'2026-07-13' AS Date), N'12:00-13:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (217, 5, CAST(N'2026-07-13' AS Date), N'13:00-14:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (218, 14, CAST(N'2026-07-13' AS Date), N'13:00-14:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (219, 6, CAST(N'2026-07-13' AS Date), N'14:00-15:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (220, 7, CAST(N'2026-07-13' AS Date), N'14:00-15:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (221, 8, CAST(N'2026-07-13' AS Date), N'15:00-16:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (222, 9, CAST(N'2026-07-13' AS Date), N'15:00-16:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (223, 10, CAST(N'2026-07-13' AS Date), N'16:00-17:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (224, 11, CAST(N'2026-07-13' AS Date), N'16:00-17:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (225, 12, CAST(N'2026-07-13' AS Date), N'17:00-18:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (226, 13, CAST(N'2026-07-13' AS Date), N'17:00-18:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (227, 1, CAST(N'2026-07-13' AS Date), N'18:00-19:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (228, 2, CAST(N'2026-07-13' AS Date), N'18:00-19:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (229, 5, CAST(N'2026-07-14' AS Date), N'07:00-08:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (230, 14, CAST(N'2026-07-14' AS Date), N'07:00-08:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (231, 6, CAST(N'2026-07-14' AS Date), N'08:00-09:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (232, 7, CAST(N'2026-07-14' AS Date), N'08:00-09:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (233, 8, CAST(N'2026-07-14' AS Date), N'09:00-10:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (234, 9, CAST(N'2026-07-14' AS Date), N'09:00-10:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (235, 10, CAST(N'2026-07-14' AS Date), N'10:00-11:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (236, 11, CAST(N'2026-07-14' AS Date), N'10:00-11:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (237, 12, CAST(N'2026-07-14' AS Date), N'11:00-12:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (238, 13, CAST(N'2026-07-14' AS Date), N'11:00-12:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (239, 1, CAST(N'2026-07-14' AS Date), N'12:00-13:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (240, 2, CAST(N'2026-07-14' AS Date), N'12:00-13:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (241, 5, CAST(N'2026-07-14' AS Date), N'13:00-14:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (242, 14, CAST(N'2026-07-14' AS Date), N'13:00-14:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (243, 6, CAST(N'2026-07-14' AS Date), N'14:00-15:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (244, 7, CAST(N'2026-07-14' AS Date), N'14:00-15:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (245, 8, CAST(N'2026-07-14' AS Date), N'15:00-16:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (246, 9, CAST(N'2026-07-14' AS Date), N'15:00-16:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (247, 10, CAST(N'2026-07-14' AS Date), N'16:00-17:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (248, 11, CAST(N'2026-07-14' AS Date), N'16:00-17:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (249, 12, CAST(N'2026-07-14' AS Date), N'17:00-18:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (250, 13, CAST(N'2026-07-14' AS Date), N'17:00-18:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (251, 1, CAST(N'2026-07-14' AS Date), N'18:00-19:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (252, 2, CAST(N'2026-07-14' AS Date), N'18:00-19:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (253, 5, CAST(N'2026-07-15' AS Date), N'07:00-08:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (254, 14, CAST(N'2026-07-15' AS Date), N'07:00-08:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (255, 6, CAST(N'2026-07-15' AS Date), N'08:00-09:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (256, 7, CAST(N'2026-07-15' AS Date), N'08:00-09:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (257, 8, CAST(N'2026-07-15' AS Date), N'09:00-10:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (258, 9, CAST(N'2026-07-15' AS Date), N'09:00-10:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (259, 10, CAST(N'2026-07-15' AS Date), N'10:00-11:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (260, 11, CAST(N'2026-07-15' AS Date), N'10:00-11:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (261, 12, CAST(N'2026-07-15' AS Date), N'11:00-12:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (262, 13, CAST(N'2026-07-15' AS Date), N'11:00-12:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (263, 1, CAST(N'2026-07-15' AS Date), N'12:00-13:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (264, 2, CAST(N'2026-07-15' AS Date), N'12:00-13:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (265, 5, CAST(N'2026-07-15' AS Date), N'13:00-14:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (266, 14, CAST(N'2026-07-15' AS Date), N'13:00-14:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (267, 6, CAST(N'2026-07-15' AS Date), N'14:00-15:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (268, 7, CAST(N'2026-07-15' AS Date), N'14:00-15:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (269, 8, CAST(N'2026-07-15' AS Date), N'15:00-16:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (270, 9, CAST(N'2026-07-15' AS Date), N'15:00-16:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (271, 10, CAST(N'2026-07-15' AS Date), N'16:00-17:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (272, 11, CAST(N'2026-07-15' AS Date), N'16:00-17:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (273, 12, CAST(N'2026-07-15' AS Date), N'17:00-18:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (274, 13, CAST(N'2026-07-15' AS Date), N'17:00-18:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (275, 1, CAST(N'2026-07-15' AS Date), N'18:00-19:00', 5, N'Available', 3, NULL)
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (276, 2, CAST(N'2026-07-15' AS Date), N'18:00-19:00', 5, N'Available', 3, NULL)
SET IDENTITY_INSERT [dbo].[Doctor_Schedule] OFF
GO
SET IDENTITY_INSERT [dbo].[Healthy_Record] ON 
SET IDENTITY_INSERT [dbo].[Healthy_Record] OFF
GO
SET IDENTITY_INSERT [dbo].[Invoice] ON 

INSERT [dbo].[Invoice] ([invoice_id], [patient_id], [receptionist_id], [total_amount], [insurance_deduction], [final_amount], [payment_method], [status], [created_at], [exported_at]) VALUES (5, 2, NULL, CAST(150000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(150000.00 AS Decimal(18, 2)), N'Cash', N'Paid', CAST(N'2026-07-15T08:00:00.000' AS DateTime), NULL)
INSERT [dbo].[Invoice] ([invoice_id], [patient_id], [receptionist_id], [total_amount], [insurance_deduction], [final_amount], [payment_method], [status], [created_at], [exported_at]) VALUES (6, 3, NULL, CAST(80000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(80000.00 AS Decimal(18, 2)), N'Cash', N'Paid', CAST(N'2026-07-15T08:00:00.000' AS DateTime), NULL)
INSERT [dbo].[Invoice] ([invoice_id], [patient_id], [receptionist_id], [total_amount], [insurance_deduction], [final_amount], [payment_method], [status], [created_at], [exported_at]) VALUES (7, 4, NULL, CAST(150000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(150000.00 AS Decimal(18, 2)), N'Cash', N'Paid', CAST(N'2026-07-15T08:00:00.000' AS DateTime), NULL)
INSERT [dbo].[Invoice] ([invoice_id], [patient_id], [receptionist_id], [total_amount], [insurance_deduction], [final_amount], [payment_method], [status], [created_at], [exported_at]) VALUES (8, 5, NULL, CAST(80000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(80000.00 AS Decimal(18, 2)), N'Cash', N'Paid', CAST(N'2026-07-15T08:00:00.000' AS DateTime), NULL)
INSERT [dbo].[Invoice] ([invoice_id], [patient_id], [receptionist_id], [total_amount], [insurance_deduction], [final_amount], [payment_method], [status], [created_at], [exported_at]) VALUES (9, 6, NULL, CAST(150000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(150000.00 AS Decimal(18, 2)), N'Cash', N'Paid', CAST(N'2026-07-15T08:00:00.000' AS DateTime), NULL)
INSERT [dbo].[Invoice] ([invoice_id], [patient_id], [receptionist_id], [total_amount], [insurance_deduction], [final_amount], [payment_method], [status], [created_at], [exported_at]) VALUES (10, 7, NULL, CAST(80000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(80000.00 AS Decimal(18, 2)), N'Cash', N'Paid', CAST(N'2026-07-15T08:00:00.000' AS DateTime), NULL)
SET IDENTITY_INSERT [dbo].[Invoice] OFF
GO
SET IDENTITY_INSERT [dbo].[Invoice_Detail] ON 

INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at]) VALUES (14, 5, 1, 15, 1, CAST(150000.00 AS Decimal(18, 2)), NULL, 5, N'Cần khám bộ mỡ máu và đường huyết', N'Requested', NULL, CAST(N'2026-07-15T08:00:00.000' AS DateTime), NULL)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at]) VALUES (15, 6, 2, 16, 1, CAST(80000.00 AS Decimal(18, 2)), NULL, 5, N'Khám sức khỏe tổng quát', N'Requested', NULL, CAST(N'2026-07-15T08:10:00.000' AS DateTime), NULL)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at]) VALUES (16, 7, 1, 17, 1, CAST(150000.00 AS Decimal(18, 2)), NULL, 5, N'Tái khám đái tháo đường', N'Requested', NULL, CAST(N'2026-07-15T08:20:00.000' AS DateTime), NULL)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at]) VALUES (17, 8, 2, 18, 1, CAST(80000.00 AS Decimal(18, 2)), NULL, 5, N'Xét nghiệm định kỳ nước tiểu', N'Requested', NULL, CAST(N'2026-07-15T08:30:00.000' AS DateTime), NULL)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at]) VALUES (18, 9, 1, 19, 1, CAST(150000.00 AS Decimal(18, 2)), NULL, 5, N'Theo dõi chức năng gan thận', N'Requested', NULL, CAST(N'2026-07-15T08:40:00.000' AS DateTime), NULL)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at]) VALUES (19, 10, 2, 20, 1, CAST(80000.00 AS Decimal(18, 2)), NULL, 5, N'Kiểm tra đạm niệu', N'Requested', NULL, CAST(N'2026-07-15T08:50:00.000' AS DateTime), NULL)
SET IDENTITY_INSERT [dbo].[Invoice_Detail] OFF
GO



SET IDENTITY_INSERT [dbo].[Medical_record] ON 

SET IDENTITY_INSERT [dbo].[Medical_record] OFF
GO
SET IDENTITY_INSERT [dbo].[Medical_Service] ON 

INSERT [dbo].[Medical_Service] ([service_id], [service_name], [price], [service_type], [status]) VALUES (1, N'Xét nghiệm máu (Đường huyết)', CAST(150000.00 AS Decimal(18, 2)), N'Lab_Test', N'Active')
INSERT [dbo].[Medical_Service] ([service_id], [service_name], [price], [service_type], [status]) VALUES (2, N'Xét nghiệm nước tiểu', CAST(80000.00 AS Decimal(18, 2)), N'Lab_Test', N'Active')
INSERT [dbo].[Medical_Service] ([service_id], [service_name], [price], [service_type], [status]) VALUES (3, N'Xét nghiệm máu (Mỡ máu)', CAST(300000.00 AS Decimal(18, 2)), N'Lab_Test', N'Active')
INSERT [dbo].[Medical_Service] ([service_id], [service_name], [price], [service_type], [status]) VALUES (4, N'Xét nghiệm máu (Chức năng gan)', CAST(150000.00 AS Decimal(18, 2)), N'Lab_Test', N'Active')
INSERT [dbo].[Medical_Service] ([service_id], [service_name], [price], [service_type], [status]) VALUES (5, N'Xét nghiệm máu (Chức năng thận)', CAST(150000.00 AS Decimal(18, 2)), N'Lab_Test', N'Active')
SET IDENTITY_INSERT [dbo].[Medical_Service] OFF
GO
SET IDENTITY_INSERT [dbo].[Patient] ON 

INSERT [dbo].[Patient] ([patient_id], [full_name], [date_of_birth], [gender], [phone], [email], [address], [account_id]) VALUES (2, N'Bệnh nhân Test 1', CAST(N'2005-06-22' AS Date), N'male', N'0900000001', N'patient_new1@gmail.com', N'Hà Nội', 6)
INSERT [dbo].[Patient] ([patient_id], [full_name], [date_of_birth], [gender], [phone], [email], [address], [account_id]) VALUES (3, N'Bệnh nhân Test 2', CAST(N'2004-06-22' AS Date), N'female', N'0900000002', N'patient_new2@gmail.com', N'Hà Nội', 7)
INSERT [dbo].[Patient] ([patient_id], [full_name], [date_of_birth], [gender], [phone], [email], [address], [account_id]) VALUES (4, N'Bệnh nhân Test 3', CAST(N'2003-06-22' AS Date), N'male', N'0900000003', N'patient_new3@gmail.com', N'Hà Nội', 8)
INSERT [dbo].[Patient] ([patient_id], [full_name], [date_of_birth], [gender], [phone], [email], [address], [account_id]) VALUES (5, N'Bệnh nhân Test 4', CAST(N'2002-06-22' AS Date), N'female', N'0900000004', N'patient_new4@gmail.com', N'Hà Nội', 9)
INSERT [dbo].[Patient] ([patient_id], [full_name], [date_of_birth], [gender], [phone], [email], [address], [account_id]) VALUES (6, N'Bệnh nhân Test 5', CAST(N'2001-06-22' AS Date), N'male', N'0900000005', N'patient_new5@gmail.com', N'Hà Nội', 10)
INSERT [dbo].[Patient] ([patient_id], [full_name], [date_of_birth], [gender], [phone], [email], [address], [account_id]) VALUES (7, N'Bệnh nhân Test 6', CAST(N'2000-06-22' AS Date), N'female', N'0900000006', N'patient_new6@gmail.com', N'Hà Nội', 11)
INSERT [dbo].[Patient] ([patient_id], [full_name], [date_of_birth], [gender], [phone], [email], [address], [account_id]) VALUES (8, N'Bệnh nhân Test 7', CAST(N'1999-06-22' AS Date), N'male', N'0900000007', N'patient_new7@gmail.com', N'Hà Nội', 12)
INSERT [dbo].[Patient] ([patient_id], [full_name], [date_of_birth], [gender], [phone], [email], [address], [account_id]) VALUES (9, N'Bệnh nhân Test 8', CAST(N'1998-06-22' AS Date), N'female', N'0900000008', N'patient_new8@gmail.com', N'Hà Nội', 13)
INSERT [dbo].[Patient] ([patient_id], [full_name], [date_of_birth], [gender], [phone], [email], [address], [account_id]) VALUES (10, N'Bệnh nhân Test 9', CAST(N'1997-06-22' AS Date), N'male', N'0900000009', N'patient_new9@gmail.com', N'Hà Nội', 14)
INSERT [dbo].[Patient] ([patient_id], [full_name], [date_of_birth], [gender], [phone], [email], [address], [account_id]) VALUES (11, N'Bệnh nhân Test 10', CAST(N'1996-06-22' AS Date), N'female', N'0900000010', N'patient_new10@gmail.com', N'Hà Nội', 15)
INSERT [dbo].[Patient] ([patient_id], [full_name], [date_of_birth], [gender], [phone], [email], [address], [account_id]) VALUES (12, N'Trần Đức Lương', CAST(N'2008-06-22' AS Date), N'male', N'0972528433', N'luongtd2008@gmail.com', N'Xã Tân Xã, Huyện Thạch Thất, Hà Nội, Việt Nam', 27)
INSERT [dbo].[Patient] ([patient_id], [full_name], [date_of_birth], [gender], [phone], [email], [address], [account_id]) VALUES (13, N'Phan Van Bao Trung', CAST(N'2005-02-22' AS Date), N'Male', N'0946477995', N'trungkitit@gmail.com', N'Tân Xã, thạch thất, Hà Nội', 32)
SET IDENTITY_INSERT [dbo].[Patient] OFF
GO
INSERT [dbo].[Room] ([room_id], [room_name], [location], [status]) VALUES (N'R101', N'Phòng Khám Tổng Quát 1', N'Tầng 1 - Khu A', N'Active')
INSERT [dbo].[Room] ([room_id], [room_name], [location], [status]) VALUES (N'R102', N'Phòng Khám Tổng Quát 2', N'Tầng 1 - Khu A', N'Active')
INSERT [dbo].[Room] ([room_id], [room_name], [location], [status]) VALUES (N'R103', N'Phòng Khám Tổng Quát 3', N'Tầng 1 - Khu A', N'Active')
INSERT [dbo].[Room] ([room_id], [room_name], [location], [status]) VALUES (N'R104', N'Phòng Khám Tổng Quát 4', N'Tầng 1 - Khu B', N'Active')
INSERT [dbo].[Room] ([room_id], [room_name], [location], [status]) VALUES (N'R105', N'Phòng Khám Tổng Quát 5', N'Tầng 1 - Khu B', N'Active')
INSERT [dbo].[Room] ([room_id], [room_name], [location], [status]) VALUES (N'R201', N'Phòng Khám Tổng Quát 6', N'Tầng 2 - Khu A', N'Active')
INSERT [dbo].[Room] ([room_id], [room_name], [location], [status]) VALUES (N'R202', N'Phòng Khám Tổng Quát 7', N'Tầng 2 - Khu A', N'Active')
INSERT [dbo].[Room] ([room_id], [room_name], [location], [status]) VALUES (N'R203', N'Phòng Khám Tổng Quát 8', N'Tầng 2 - Khu B', N'Active')
INSERT [dbo].[Room] ([room_id], [room_name], [location], [status]) VALUES (N'R204', N'Phòng Khám Tổng Quát 9', N'Tầng 2 - Khu B', N'Active')
INSERT [dbo].[Room] ([room_id], [room_name], [location], [status]) VALUES (N'R205', N'Phòng Khám Tổng Quát 10', N'Tầng 2 - Khu B', N'Active')
INSERT [dbo].[Room] ([room_name], [location], [status]) VALUES (N'Phòng xét nghiệm máu', N'Tầng 3 - Khu C', N'Active')
INSERT [dbo].[Room] ([room_name], [location], [status]) VALUES (N'Phòng xét nghiệm nước tiểu', N'Tầng 3 - Khu C', N'Active')
GO
INSERT [dbo].[Lab_Order] ([order_id], [appointment_id], [patient_id], [room_id], [service_id], [lab_id], [status], [created_at]) VALUES (N'LO003', 15, 2, N'R301', 1, 1, N'Waiting', CAST(N'2026-07-15T08:10:00.000' AS DateTime))
INSERT [dbo].[Lab_Order] ([order_id], [appointment_id], [patient_id], [room_id], [service_id], [lab_id], [status], [created_at]) VALUES (N'LO004', 16, 3, N'R302', 2, 1, N'Waiting', CAST(N'2026-07-15T08:15:00.000' AS DateTime))
INSERT [dbo].[Lab_Order] ([order_id], [appointment_id], [patient_id], [room_id], [service_id], [lab_id], [status], [created_at]) VALUES (N'LO005', 17, 4, N'R301', 1, 1, N'Waiting', CAST(N'2026-07-15T08:20:00.000' AS DateTime))
INSERT [dbo].[Lab_Order] ([order_id], [appointment_id], [patient_id], [room_id], [service_id], [lab_id], [status], [created_at]) VALUES (N'LO006', 18, 5, N'R302', 2, 1, N'Waiting', CAST(N'2026-07-15T08:25:00.000' AS DateTime))
INSERT [dbo].[Lab_Order] ([order_id], [appointment_id], [patient_id], [room_id], [service_id], [lab_id], [status], [created_at]) VALUES (N'LO007', 19, 6, N'R301', 1, 1, N'Waiting', CAST(N'2026-07-15T08:30:00.000' AS DateTime))
INSERT [dbo].[Lab_Order] ([order_id], [appointment_id], [patient_id], [room_id], [service_id], [lab_id], [status], [created_at]) VALUES (N'LO008', 20, 7, N'R302', 2, 1, N'Waiting', CAST(N'2026-07-15T08:35:00.000' AS DateTime))
SET ANSI_PADDING ON
GO
/****** Object:  Index [UX_Account_Email]    Script Date: 7/11/2026 12:19:41 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_Account_Email] ON [dbo].[Account]
(
	[email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Appointment_ConsultationStartTime]    Script Date: 7/11/2026 12:19:41 AM ******/
CREATE NONCLUSTERED INDEX [IX_Appointment_ConsultationStartTime] ON [dbo].[Appointment]
(
	[consultation_start_time] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Appointment_Patient]    Script Date: 7/11/2026 12:19:41 AM ******/
CREATE NONCLUSTERED INDEX [IX_Appointment_Patient] ON [dbo].[Appointment]
(
	[patient_id] ASC,
	[created_at] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UX_Appointment_Queue]    Script Date: 7/11/2026 12:19:41 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_Appointment_Queue] ON [dbo].[Appointment]
(
	[schedule_id] ASC,
	[queue_number] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UX_Doctor_Account]    Script Date: 7/11/2026 12:19:41 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_Doctor_Account] ON [dbo].[Doctor]
(
	[account_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UX_DoctorAI_HealthRecord]    Script Date: 7/11/2026 12:19:41 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_DoctorAI_HealthRecord] ON [dbo].[Doctor_AI]
(
	[health_record_id] ASC
)
WHERE ([health_record_id] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UX_DoctorLab_Account]    Script Date: 7/11/2026 12:19:41 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_DoctorLab_Account] ON [dbo].[Doctor_Lab]
(
	[account_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UX_DoctorSchedule_Slot]    Script Date: 7/11/2026 12:19:41 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_DoctorSchedule_Slot] ON [dbo].[Doctor_Schedule]
(
	[doctor_id] ASC,
	[work_date] ASC,
	[time_slot] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UX_HealthyRecord_InvoiceDetail]    Script Date: 7/11/2026 12:19:41 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_HealthyRecord_InvoiceDetail] ON [dbo].[Healthy_Record]
(
	[invoice_detail_id] ASC
)
WHERE ([invoice_detail_id] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Invoice_PatientStatus]    Script Date: 7/11/2026 12:19:41 AM ******/
CREATE NONCLUSTERED INDEX [IX_Invoice_PatientStatus] ON [dbo].[Invoice]
(
	[patient_id] ASC,
	[status] ASC,
	[created_at] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_InvoiceDetail_Appointment]    Script Date: 7/11/2026 12:19:41 AM ******/
CREATE NONCLUSTERED INDEX [IX_InvoiceDetail_Appointment] ON [dbo].[Invoice_Detail]
(
	[appointment_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_InvoiceDetail_Invoice]    Script Date: 7/11/2026 12:19:41 AM ******/
CREATE NONCLUSTERED INDEX [IX_InvoiceDetail_Invoice] ON [dbo].[Invoice_Detail]
(
	[invoice_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_InvoiceDetail_LabWorkflow]    Script Date: 7/11/2026 12:19:41 AM ******/
CREATE NONCLUSTERED INDEX [IX_InvoiceDetail_LabWorkflow] ON [dbo].[Invoice_Detail]
(
	[lab_status] ASC,
	[health_record_id] ASC,
	[doctor_id] ASC
)
INCLUDE([invoice_id],[service_id],[requested_at],[completed_at]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UX_MedicalRecord_Appointment]    Script Date: 7/11/2026 12:19:41 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_MedicalRecord_Appointment] ON [dbo].[Medical_record]
(
	[appointment_id] ASC
)
WHERE ([appointment_id] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Patient_Phone]    Script Date: 7/11/2026 12:19:41 AM ******/
CREATE NONCLUSTERED INDEX [IX_Patient_Phone] ON [dbo].[Patient]
(
	[phone] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UX_Patient_Account]    Script Date: 7/11/2026 12:19:41 AM ******/
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
ALTER TABLE [dbo].[AI_Summary] ADD  DEFAULT (getdate()) FOR [created_at]
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
ALTER TABLE [dbo].[Lab_Order] ADD  DEFAULT ('Pending') FOR [status]
GO
ALTER TABLE [dbo].[Lab_Order] ADD  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[Lab_Schedule] ADD  DEFAULT (N'Active') FOR [status]
GO

ALTER TABLE [dbo].[Medical_record] ADD  CONSTRAINT [DF_MedicalRecord_Visibility]  DEFAULT ((1)) FOR [result_visibility]
GO
ALTER TABLE [dbo].[Medical_Service] ADD  CONSTRAINT [DF_MedicalService_Status]  DEFAULT ('Active') FOR [status]
GO
ALTER TABLE [dbo].[Notification] ADD  DEFAULT ((0)) FOR [IsRead]
GO
ALTER TABLE [dbo].[Notification] ADD  DEFAULT (getdate()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[Reception_Schedule] ADD  DEFAULT (N'Active') FOR [status]
GO
ALTER TABLE [dbo].[Record_Transfer_History] ADD  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[Room] ADD  DEFAULT ('Active') FOR [status]
GO
ALTER TABLE [dbo].[AI_Summary]  WITH CHECK ADD  CONSTRAINT [FK_AISummary_Appointment] FOREIGN KEY([appointment_id])
REFERENCES [dbo].[Appointment] ([appointment_id])
GO
ALTER TABLE [dbo].[AI_Summary] CHECK CONSTRAINT [FK_AISummary_Appointment]
GO
ALTER TABLE [dbo].[AI_Summary]  WITH CHECK ADD  CONSTRAINT [FK_AISummary_Patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[Patient] ([patient_id])
GO
ALTER TABLE [dbo].[AI_Summary] CHECK CONSTRAINT [FK_AISummary_Patient]
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
ALTER TABLE [dbo].[Doctor_Lab]  WITH CHECK ADD  CONSTRAINT [FK_DoctorLab_Account] FOREIGN KEY([account_id])
REFERENCES [dbo].[Account] ([account_id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Doctor_Lab] CHECK CONSTRAINT [FK_DoctorLab_Account]
GO
ALTER TABLE [dbo].[Doctor_Schedule]  WITH CHECK ADD  CONSTRAINT [FK_DoctorSchedule_Doctor] FOREIGN KEY([doctor_id])
REFERENCES [dbo].[Doctor] ([doctor_id])
GO
ALTER TABLE [dbo].[Doctor_Schedule] CHECK CONSTRAINT [FK_DoctorSchedule_Doctor]
GO
ALTER TABLE [dbo].[Doctor_Schedule]  WITH CHECK ADD  CONSTRAINT [FK_DoctorSchedule_Room] FOREIGN KEY([room_id])
REFERENCES [dbo].[Room] ([room_id])
ON UPDATE CASCADE
ON DELETE SET NULL
GO
ALTER TABLE [dbo].[Doctor_Schedule] CHECK CONSTRAINT [FK_DoctorSchedule_Room]
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
ALTER TABLE [dbo].[Invoice_Detail]  WITH CHECK ADD  CONSTRAINT [FK_InvoiceDetail_Doctor] FOREIGN KEY([doctor_id])
REFERENCES [dbo].[Doctor] ([doctor_id])
GO
ALTER TABLE [dbo].[Invoice_Detail] CHECK CONSTRAINT [FK_InvoiceDetail_Doctor]
GO
ALTER TABLE [dbo].[Invoice_Detail]  WITH CHECK ADD  CONSTRAINT [FK_InvoiceDetail_HealthRecord] FOREIGN KEY([health_record_id])
REFERENCES [dbo].[Healthy_Record] ([health_record_id])
GO
ALTER TABLE [dbo].[Invoice_Detail] CHECK CONSTRAINT [FK_InvoiceDetail_HealthRecord]
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
ALTER TABLE [dbo].[Lab_Order]  WITH CHECK ADD  CONSTRAINT [FK_LabOrder_Appointment] FOREIGN KEY([appointment_id])
REFERENCES [dbo].[Appointment] ([appointment_id])
GO
ALTER TABLE [dbo].[Lab_Order] CHECK CONSTRAINT [FK_LabOrder_Appointment]
GO
ALTER TABLE [dbo].[Lab_Order]  WITH CHECK ADD  CONSTRAINT [FK_LabOrder_DoctorLab] FOREIGN KEY([lab_id])
REFERENCES [dbo].[Doctor_Lab] ([lab_id])
GO
ALTER TABLE [dbo].[Lab_Order] CHECK CONSTRAINT [FK_LabOrder_DoctorLab]
GO
ALTER TABLE [dbo].[Lab_Order]  WITH CHECK ADD  CONSTRAINT [FK_LabOrder_Patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[Patient] ([patient_id])
GO
ALTER TABLE [dbo].[Lab_Order] CHECK CONSTRAINT [FK_LabOrder_Patient]
GO
ALTER TABLE [dbo].[Lab_Order]  WITH CHECK ADD  CONSTRAINT [FK_LabOrder_Room] FOREIGN KEY([room_id])
REFERENCES [dbo].[Room] ([room_id])
GO
ALTER TABLE [dbo].[Lab_Order] CHECK CONSTRAINT [FK_LabOrder_Room]
GO
ALTER TABLE [dbo].[Lab_Order]  WITH CHECK ADD  CONSTRAINT [FK_LabOrder_Service] FOREIGN KEY([service_id])
REFERENCES [dbo].[Medical_Service] ([service_id])
GO
ALTER TABLE [dbo].[Lab_Order] CHECK CONSTRAINT [FK_LabOrder_Service]
GO
ALTER TABLE [dbo].[Lab_Schedule]  WITH CHECK ADD  CONSTRAINT [FK_Lab_Schedule_Doctor_Lab] FOREIGN KEY([lab_id])
REFERENCES [dbo].[Doctor_Lab] ([lab_id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Lab_Schedule] CHECK CONSTRAINT [FK_Lab_Schedule_Doctor_Lab]
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
ALTER TABLE [dbo].[Notification]  WITH CHECK ADD  CONSTRAINT [FK_Notification_Account] FOREIGN KEY([AccountID])
REFERENCES [dbo].[Account] ([account_id])
GO
ALTER TABLE [dbo].[Notification] CHECK CONSTRAINT [FK_Notification_Account]
GO
ALTER TABLE [dbo].[Patient]  WITH CHECK ADD  CONSTRAINT [FK_Patient_Account] FOREIGN KEY([account_id])
REFERENCES [dbo].[Account] ([account_id])
GO
ALTER TABLE [dbo].[Patient] CHECK CONSTRAINT [FK_Patient_Account]
GO
ALTER TABLE [dbo].[Reception_Schedule]  WITH CHECK ADD  CONSTRAINT [FK_Reception_Schedule_Reception] FOREIGN KEY([reception_id])
REFERENCES [dbo].[Reception] ([reception_id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Reception_Schedule] CHECK CONSTRAINT [FK_Reception_Schedule_Reception]
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
ALTER TABLE [dbo].[Account]  WITH CHECK ADD  CONSTRAINT [CK_Account_Role] CHECK  (([role]='doctor_lab' OR [role]='Patient' OR [role]='Doctor' OR [role]='Receptionist' OR [role]='Admin'))
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
ALTER TABLE [dbo].[Appointment]  WITH CHECK ADD  CONSTRAINT [CK_Appointment_Status] CHECK  (([status]='Cancelled' OR [status]='Absent' OR [status]='Completed' OR [status]='In_Progress' OR [status]='Checked_In' OR [status]='Waiting'))
GO
ALTER TABLE [dbo].[Appointment] CHECK CONSTRAINT [CK_Appointment_Status]
GO
ALTER TABLE [dbo].[Doctor_Schedule]  WITH CHECK ADD  CONSTRAINT [CK_DoctorSchedule_MaxPatients] CHECK  (([max_patients]>(0)))
GO
ALTER TABLE [dbo].[Doctor_Schedule] CHECK CONSTRAINT [CK_DoctorSchedule_MaxPatients]
GO
ALTER TABLE [dbo].[Doctor_Schedule]  WITH CHECK ADD  CONSTRAINT [CK_DoctorSchedule_Status] CHECK  (([status]='Expired' OR [status]='Cancelled' OR [status]='Full' OR [status]='Available'))
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
ALTER TABLE [dbo].[Invoice_Detail]  WITH CHECK ADD  CONSTRAINT [CK_InvoiceDetail_LabStatus] CHECK  (([lab_status] IS NULL OR ([lab_status]='Cancelled' OR [lab_status]='Completed' OR [lab_status]='Processing' OR [lab_status]='Requested' OR [lab_status]='Waiting_Payment')))
GO
ALTER TABLE [dbo].[Invoice_Detail] CHECK CONSTRAINT [CK_InvoiceDetail_LabStatus]
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
