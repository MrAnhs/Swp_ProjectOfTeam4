USE [master]
GO
/****** Object:  Database [Project]    Script Date: 7/27/2026 3:49:00 AM ******/
CREATE DATABASE [Project]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Project', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\Project.mdf' , SIZE = 73728KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'Project_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\Project_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF
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
/****** Object:  Table [dbo].[Account]    Script Date: 7/27/2026 3:49:00 AM ******/
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
/****** Object:  Table [dbo].[AI_Summary]    Script Date: 7/27/2026 3:49:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AI_Summary](
	[summary_id] [varchar](50) NOT NULL,
	[patient_id] [int] NOT NULL,
	[ai_summary] [nvarchar](max) NOT NULL,
	[created_at] [datetime] NULL,
 CONSTRAINT [PK_AISummary] PRIMARY KEY CLUSTERED 
(
	[summary_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Appointment]    Script Date: 7/27/2026 3:49:00 AM ******/
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
/****** Object:  Table [dbo].[Doctor]    Script Date: 7/27/2026 3:49:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Doctor](
	[doctor_id] [int] IDENTITY(1,1) NOT NULL,
	[full_name] [nvarchar](100) NOT NULL,
	[phone] [varchar](20) NULL,
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
/****** Object:  Table [dbo].[Doctor_AI]    Script Date: 7/27/2026 3:49:00 AM ******/
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
/****** Object:  Table [dbo].[Doctor_Lab]    Script Date: 7/27/2026 3:49:00 AM ******/
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
/****** Object:  Table [dbo].[Doctor_Schedule]    Script Date: 7/27/2026 3:49:00 AM ******/
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
/****** Object:  Table [dbo].[Email_Verification]    Script Date: 7/27/2026 3:49:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Email_Verification](
	[verification_id] [bigint] IDENTITY(1,1) NOT NULL,
	[account_id] [int] NULL,
	[purpose] [varchar](30) NOT NULL,
	[target_email] [varchar](255) NOT NULL,
	[otp_hash] [varchar](255) NOT NULL,
	[expires_at] [datetime2](7) NOT NULL,
	[failed_attempts] [int] NOT NULL,
	[consumed_at] [datetime2](7) NULL,
	[created_at] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[verification_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Healthy_Record]    Script Date: 7/27/2026 3:49:00 AM ******/
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
	[invoice_id] [int] NULL,
	[ldl] [decimal](5, 2) NULL,
	[is_synced_automatically] [bit] NOT NULL,
	[synced_at] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[health_record_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Invoice]    Script Date: 7/27/2026 3:49:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Invoice](
	[invoice_id] [int] IDENTITY(1,1) NOT NULL,
	[patient_id] [int] NOT NULL,
	[receptionist_id] [int] NULL,
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
/****** Object:  Table [dbo].[Invoice_Detail]    Script Date: 7/27/2026 3:49:00 AM ******/
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
	[lab_id] [int] NULL,
 CONSTRAINT [PK_Invoice_Detail] PRIMARY KEY CLUSTERED 
(
	[invoice_detail_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Lab_Order]    Script Date: 7/27/2026 3:49:00 AM ******/
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
/****** Object:  Table [dbo].[Lab_Schedule]    Script Date: 7/27/2026 3:49:00 AM ******/
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
	[max_patients] [int] NULL,
 CONSTRAINT [PK_Lab_Schedule] PRIMARY KEY CLUSTERED 
(
	[lab_sched_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Medical_record]    Script Date: 7/27/2026 3:49:00 AM ******/
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
	[revisit_date] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[record_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Medical_Service]    Script Date: 7/27/2026 3:49:00 AM ******/
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
/****** Object:  Table [dbo].[Notification]    Script Date: 7/27/2026 3:49:00 AM ******/
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
	[TargetUrl] [nvarchar](500) NULL,
	[EventKey] [nvarchar](150) NULL,
PRIMARY KEY CLUSTERED 
(
	[NotificationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Patient]    Script Date: 7/27/2026 3:49:00 AM ******/
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
/****** Object:  Table [dbo].[Reception]    Script Date: 7/27/2026 3:49:00 AM ******/
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
/****** Object:  Table [dbo].[Reception_Schedule]    Script Date: 7/27/2026 3:49:00 AM ******/
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
/****** Object:  Table [dbo].[Record_Sharing]    Script Date: 7/27/2026 3:49:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Record_Sharing](
	[SharingID] [int] IDENTITY(1,1) NOT NULL,
	[Owner_AccountID] [int] NOT NULL,
	[Viewer_AccountID] [int] NOT NULL,
	[CanViewAppointments] [bit] NULL,
	[CanViewInvoices] [bit] NULL,
	[CanViewRecords] [bit] NULL,
	[Status] [varchar](20) NULL,
	[CreatedAt] [datetime] NULL,
	[UpdatedAt] [datetime] NULL,
	[Initiator_AccountID] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[SharingID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Room]    Script Date: 7/27/2026 3:49:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
SET IDENTITY_INSERT [dbo].[Account] ON 

INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (26, N'Quản Trị Viên', N'hash123', N'admin@hospital.com', N'Admin', CAST(N'2026-06-30T23:37:55.317' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (56, N'BS Nội Tiết 1', N'b415b310b77f856e6c2209b904fb84f287281a460f7e6bfbe600750f1b366483', N'doctornt1@gmail.com', N'Doctor', CAST(N'2026-07-23T22:54:29.930' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (57, N'BS Nội Tiết 2', N'b415b310b77f856e6c2209b904fb84f287281a460f7e6bfbe600750f1b366483', N'doctornt2@gmail.com', N'Doctor', CAST(N'2026-07-23T22:54:55.370' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (58, N'BS Nội Tiết 3', N'b415b310b77f856e6c2209b904fb84f287281a460f7e6bfbe600750f1b366483', N'doctornt3@gmail.com', N'Doctor', CAST(N'2026-07-23T22:57:09.907' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (59, N'BS Nội Tiết 4', N'b415b310b77f856e6c2209b904fb84f287281a460f7e6bfbe600750f1b366483', N'doctornt4@gmail.com', N'Doctor', CAST(N'2026-07-23T22:58:42.780' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (60, N'BS Nội Tiết 5', N'b415b310b77f856e6c2209b904fb84f287281a460f7e6bfbe600750f1b366483', N'doctornt5@gmail.com', N'Doctor', CAST(N'2026-07-23T22:59:15.393' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (61, N'BS Tim Mạch 1', N'b415b310b77f856e6c2209b904fb84f287281a460f7e6bfbe600750f1b366483', N'doctortm1@gmail.com', N'Doctor', CAST(N'2026-07-23T22:59:44.957' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (62, N'BS Tim Mạch 2', N'b415b310b77f856e6c2209b904fb84f287281a460f7e6bfbe600750f1b366483', N'doctortm2@gmail.com', N'Doctor', CAST(N'2026-07-23T23:00:28.107' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (63, N'BS Tim Mạch 3', N'b415b310b77f856e6c2209b904fb84f287281a460f7e6bfbe600750f1b366483', N'doctortm3@gmail.com', N'Doctor', CAST(N'2026-07-23T23:00:52.707' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (64, N'BS Da Liễu 1', N'b415b310b77f856e6c2209b904fb84f287281a460f7e6bfbe600750f1b366483', N'doctordl1@gmail.com', N'Doctor', CAST(N'2026-07-23T23:01:22.257' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (65, N'BS Da Liễu 2', N'b415b310b77f856e6c2209b904fb84f287281a460f7e6bfbe600750f1b366483', N'doctordl2@gmail.com', N'Doctor', CAST(N'2026-07-23T23:01:43.217' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (66, N'BS Da Liễu 3', N'b415b310b77f856e6c2209b904fb84f287281a460f7e6bfbe600750f1b366483', N'doctordl3@gmail.com', N'Doctor', CAST(N'2026-07-23T23:02:21.860' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (67, N'Nguyễn Thị Hồng Hảo', N'b415b310b77f856e6c2209b904fb84f287281a460f7e6bfbe600750f1b366483', N'letan1@gmail.com', N'Receptionist', CAST(N'2026-07-23T23:02:50.000' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (68, N'Hà Thị Ngọc', N'b415b310b77f856e6c2209b904fb84f287281a460f7e6bfbe600750f1b366483', N'letan2@gmail.com', N'Receptionist', CAST(N'2026-07-23T23:03:09.093' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (69, N'Nguyễn Ngọc Yến', N'b415b310b77f856e6c2209b904fb84f287281a460f7e6bfbe600750f1b366483', N'letan3@gmail.com', N'Receptionist', CAST(N'2026-07-23T23:03:35.743' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (70, N'BS Xét Nghiệm 1', N'b415b310b77f856e6c2209b904fb84f287281a460f7e6bfbe600750f1b366483', N'doctorxn1@gmail.com', N'doctor_lab', CAST(N'2026-07-23T23:04:28.167' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (71, N'BS Xét Nghiệm 2', N'b415b310b77f856e6c2209b904fb84f287281a460f7e6bfbe600750f1b366483', N'doctorxn2@gmail.com', N'doctor_lab', CAST(N'2026-07-23T23:06:31.727' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (72, N'BS Xét Nghiệm 3', N'b415b310b77f856e6c2209b904fb84f287281a460f7e6bfbe600750f1b366483', N'doctorxn3@gmail.com', N'doctor_lab', CAST(N'2026-07-23T23:07:18.430' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (73, N'Nguyễn Văn Ánh', N'b415b310b77f856e6c2209b904fb84f287281a460f7e6bfbe600750f1b366483', N'nguyenanh6868vp@gmail.com', N'Patient', CAST(N'2026-07-24T00:30:28.487' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (74, N'Phan Văn Bảo Trung', N'b415b310b77f856e6c2209b904fb84f287281a460f7e6bfbe600750f1b366483', N'trungkitich1324@gmail.com', N'Patient', CAST(N'2026-07-24T20:51:45.653' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (75, N'Lê Trọng Nghĩa', N'b415b310b77f856e6c2209b904fb84f287281a460f7e6bfbe600750f1b366483', N'lenghia211105@gmail.com', N'Patient', CAST(N'2026-07-25T03:09:56.917' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (76, N'Trường Giang', N'b415b310b77f856e6c2209b904fb84f287281a460f7e6bfbe600750f1b366483', N'giangnt.he194257@gmail.com', N'Patient', CAST(N'2026-07-25T16:48:01.753' AS DateTime), N'Active')
INSERT [dbo].[Account] ([account_id], [full_name], [password_hash], [email], [role], [created_at], [status]) VALUES (1076, N'Phan Van Bao Trung', N'767cf9d337565e145eebf390e39c51432f7efd809064cb2a65f40e935f0cb202', N'trungkitit@gmail.com', N'Patient', CAST(N'2026-07-25T18:14:27.787' AS DateTime), N'Active')
SET IDENTITY_INSERT [dbo].[Account] OFF
GO
SET IDENTITY_INSERT [dbo].[Appointment] ON 

INSERT [dbo].[Appointment] ([appointment_id], [patient_id], [schedule_id], [appointment_time], [booking_type], [queue_number], [status], [created_at]) VALUES (45, 18, 454, CAST(N'2026-07-24T00:34:00.000' AS DateTime), N'Online', 1, N'In_Progress', CAST(N'2026-07-24T00:37:51.527' AS DateTime))
INSERT [dbo].[Appointment] ([appointment_id], [patient_id], [schedule_id], [appointment_time], [booking_type], [queue_number], [status], [created_at]) VALUES (46, 19, 456, CAST(N'2026-07-25T00:39:00.000' AS DateTime), N'Online', 1, N'In_Progress', CAST(N'2026-07-25T01:07:23.787' AS DateTime))
INSERT [dbo].[Appointment] ([appointment_id], [patient_id], [schedule_id], [appointment_time], [booking_type], [queue_number], [status], [created_at]) VALUES (47, 20, 458, CAST(N'2026-07-25T03:13:00.000' AS DateTime), N'Online', 1, N'In_Progress', CAST(N'2026-07-25T03:12:06.613' AS DateTime))
INSERT [dbo].[Appointment] ([appointment_id], [patient_id], [schedule_id], [appointment_time], [booking_type], [queue_number], [status], [created_at]) VALUES (48, 18, 458, CAST(N'2026-07-25T03:13:00.000' AS DateTime), N'Online', 2, N'Cancelled', CAST(N'2026-07-25T04:18:37.040' AS DateTime))
INSERT [dbo].[Appointment] ([appointment_id], [patient_id], [schedule_id], [appointment_time], [booking_type], [queue_number], [status], [created_at]) VALUES (49, 18, 459, CAST(N'2026-07-25T10:00:00.000' AS DateTime), N'Online', 1, N'Completed', CAST(N'2026-07-25T10:03:27.177' AS DateTime))
INSERT [dbo].[Appointment] ([appointment_id], [patient_id], [schedule_id], [appointment_time], [booking_type], [queue_number], [status], [created_at]) VALUES (50, 18, 460, CAST(N'2026-07-25T16:00:00.000' AS DateTime), N'Online', 1, N'Completed', CAST(N'2026-07-25T16:23:19.853' AS DateTime))
INSERT [dbo].[Appointment] ([appointment_id], [patient_id], [schedule_id], [appointment_time], [booking_type], [queue_number], [status], [created_at]) VALUES (51, 21, 460, CAST(N'2026-07-25T16:00:00.000' AS DateTime), N'Online', 2, N'Completed', CAST(N'2026-07-25T16:48:14.773' AS DateTime))
INSERT [dbo].[Appointment] ([appointment_id], [patient_id], [schedule_id], [appointment_time], [booking_type], [queue_number], [status], [created_at]) VALUES (1051, 18, 460, CAST(N'2026-07-25T16:00:00.000' AS DateTime), N'Online', 3, N'Absent', CAST(N'2026-07-25T18:34:37.610' AS DateTime))
INSERT [dbo].[Appointment] ([appointment_id], [patient_id], [schedule_id], [appointment_time], [booking_type], [queue_number], [status], [created_at]) VALUES (1052, 18, 464, CAST(N'2026-07-27T00:08:00.000' AS DateTime), N'Online', 1, N'Completed', CAST(N'2026-07-27T00:14:20.467' AS DateTime))
INSERT [dbo].[Appointment] ([appointment_id], [patient_id], [schedule_id], [appointment_time], [booking_type], [queue_number], [status], [created_at]) VALUES (1053, 19, 464, CAST(N'2026-07-27T00:08:00.000' AS DateTime), N'Online', 2, N'Completed', CAST(N'2026-07-27T00:31:08.000' AS DateTime))
INSERT [dbo].[Appointment] ([appointment_id], [patient_id], [schedule_id], [appointment_time], [booking_type], [queue_number], [status], [created_at]) VALUES (1054, 20, 464, CAST(N'2026-07-27T00:08:00.000' AS DateTime), N'Online', 3, N'Completed', CAST(N'2026-07-27T01:18:10.953' AS DateTime))
INSERT [dbo].[Appointment] ([appointment_id], [patient_id], [schedule_id], [appointment_time], [booking_type], [queue_number], [status], [created_at]) VALUES (1055, 18, 465, CAST(N'2026-07-27T01:25:00.000' AS DateTime), N'Online', 1, N'Completed', CAST(N'2026-07-27T01:23:25.200' AS DateTime))
INSERT [dbo].[Appointment] ([appointment_id], [patient_id], [schedule_id], [appointment_time], [booking_type], [queue_number], [status], [created_at]) VALUES (1056, 20, 465, CAST(N'2026-07-27T01:25:00.000' AS DateTime), N'Online', 2, N'Completed', CAST(N'2026-07-27T01:34:20.463' AS DateTime))
INSERT [dbo].[Appointment] ([appointment_id], [patient_id], [schedule_id], [appointment_time], [booking_type], [queue_number], [status], [created_at]) VALUES (1057, 19, 465, CAST(N'2026-07-27T01:25:00.000' AS DateTime), N'Online', 3, N'Completed', CAST(N'2026-07-27T01:51:16.990' AS DateTime))
INSERT [dbo].[Appointment] ([appointment_id], [patient_id], [schedule_id], [appointment_time], [booking_type], [queue_number], [status], [created_at]) VALUES (1058, 18, 466, CAST(N'2026-07-27T02:06:00.000' AS DateTime), N'Online', 1, N'Completed', CAST(N'2026-07-27T02:06:26.587' AS DateTime))
INSERT [dbo].[Appointment] ([appointment_id], [patient_id], [schedule_id], [appointment_time], [booking_type], [queue_number], [status], [created_at]) VALUES (1059, 20, 466, CAST(N'2026-07-27T02:06:00.000' AS DateTime), N'Online', 2, N'In_Progress', CAST(N'2026-07-27T02:09:51.963' AS DateTime))
INSERT [dbo].[Appointment] ([appointment_id], [patient_id], [schedule_id], [appointment_time], [booking_type], [queue_number], [status], [created_at]) VALUES (1060, 19, 466, CAST(N'2026-07-27T02:06:00.000' AS DateTime), N'Online', 3, N'Completed', CAST(N'2026-07-27T02:14:49.673' AS DateTime))
INSERT [dbo].[Appointment] ([appointment_id], [patient_id], [schedule_id], [appointment_time], [booking_type], [queue_number], [status], [created_at]) VALUES (1061, 18, 467, CAST(N'2026-07-27T03:20:00.000' AS DateTime), N'Online', 1, N'In_Progress', CAST(N'2026-07-27T03:19:50.980' AS DateTime))
SET IDENTITY_INSERT [dbo].[Appointment] OFF
GO
SET IDENTITY_INSERT [dbo].[Doctor] ON 

INSERT [dbo].[Doctor] ([doctor_id], [full_name], [phone], [email], [department], [account_id], [date_of_birth], [gender], [address]) VALUES (33, N'BS Nội Tiết 1', N'0988589155', N'doctornt1@gmail.com', N'Nội tiết', 56, CAST(N'2008-02-16' AS Date), N'male', N'Hà Nội')
INSERT [dbo].[Doctor] ([doctor_id], [full_name], [phone], [email], [department], [account_id], [date_of_birth], [gender], [address]) VALUES (34, N'BS Nội Tiết 2', N'0332255444', N'doctornt2@gmail.com', N'Nội tiết', 57, CAST(N'2005-06-18' AS Date), N'male', N'TP Hồ Chí Minh')
INSERT [dbo].[Doctor] ([doctor_id], [full_name], [phone], [email], [department], [account_id], [date_of_birth], [gender], [address]) VALUES (35, N'BS Nội Tiết 3', NULL, N'doctornt3@gmail.com', N'Nội tiết', 58, NULL, NULL, NULL)
INSERT [dbo].[Doctor] ([doctor_id], [full_name], [phone], [email], [department], [account_id], [date_of_birth], [gender], [address]) VALUES (36, N'BS Nội Tiết 4', NULL, N'doctornt4@gmail.com', N'Nội tiết', 59, NULL, NULL, NULL)
INSERT [dbo].[Doctor] ([doctor_id], [full_name], [phone], [email], [department], [account_id], [date_of_birth], [gender], [address]) VALUES (37, N'BS Nội Tiết 5', NULL, N'doctornt5@gmail.com', N'Nội tiết', 60, NULL, NULL, NULL)
INSERT [dbo].[Doctor] ([doctor_id], [full_name], [phone], [email], [department], [account_id], [date_of_birth], [gender], [address]) VALUES (38, N'BS Tim Mạch 1', NULL, N'doctortm1@gmail.com', N'Tim mạch', 61, NULL, NULL, NULL)
INSERT [dbo].[Doctor] ([doctor_id], [full_name], [phone], [email], [department], [account_id], [date_of_birth], [gender], [address]) VALUES (39, N'BS Tim Mạch 2', NULL, N'doctortm2@gmail.com', N'Tim mạch', 62, NULL, NULL, NULL)
INSERT [dbo].[Doctor] ([doctor_id], [full_name], [phone], [email], [department], [account_id], [date_of_birth], [gender], [address]) VALUES (40, N'BS Tim Mạch 3', NULL, N'doctortm3@gmail.com', N'Tim mạch', 63, NULL, NULL, NULL)
INSERT [dbo].[Doctor] ([doctor_id], [full_name], [phone], [email], [department], [account_id], [date_of_birth], [gender], [address]) VALUES (41, N'BS Da Liễu 1', NULL, N'doctordl1@gmail.com', N'Da liễu', 64, NULL, NULL, NULL)
INSERT [dbo].[Doctor] ([doctor_id], [full_name], [phone], [email], [department], [account_id], [date_of_birth], [gender], [address]) VALUES (42, N'BS Da Liễu 2', NULL, N'doctordl2@gmail.com', N'Da liễu', 65, NULL, NULL, NULL)
INSERT [dbo].[Doctor] ([doctor_id], [full_name], [phone], [email], [department], [account_id], [date_of_birth], [gender], [address]) VALUES (43, N'BS Da Liễu 3', NULL, N'doctordl3@gmail.com', N'Da liễu', 66, NULL, NULL, NULL)
INSERT [dbo].[Doctor] ([doctor_id], [full_name], [phone], [email], [department], [account_id], [date_of_birth], [gender], [address]) VALUES (44, N'BS Xét Nghiệm 1', NULL, N'doctorxl1@gmail.com', N'Nội tiết', 70, NULL, NULL, NULL)
INSERT [dbo].[Doctor] ([doctor_id], [full_name], [phone], [email], [department], [account_id], [date_of_birth], [gender], [address]) VALUES (45, N'BS Xét Nghiệm 2', NULL, N'doctorxn2@gmail.com', N'Nội tiết', 71, NULL, NULL, NULL)
INSERT [dbo].[Doctor] ([doctor_id], [full_name], [phone], [email], [department], [account_id], [date_of_birth], [gender], [address]) VALUES (46, N'BS Xét Nghiệm 3', NULL, N'doctorxn3@gmail.com', N'Nội tiết', 72, NULL, NULL, NULL)
SET IDENTITY_INSERT [dbo].[Doctor] OFF
GO
SET IDENTITY_INSERT [dbo].[Doctor_AI] ON 

INSERT [dbo].[Doctor_AI] ([doctor_ai_id], [health_record_id], [diabetes_probability], [pre_diabetes_probability], [normal_probability], [doctor_id]) VALUES (1, 43, CAST(0.78 AS Decimal(5, 2)), CAST(0.09 AS Decimal(5, 2)), CAST(0.13 AS Decimal(5, 2)), NULL)
INSERT [dbo].[Doctor_AI] ([doctor_ai_id], [health_record_id], [diabetes_probability], [pre_diabetes_probability], [normal_probability], [doctor_id]) VALUES (2, 44, CAST(0.80 AS Decimal(5, 2)), CAST(0.09 AS Decimal(5, 2)), CAST(0.11 AS Decimal(5, 2)), NULL)
INSERT [dbo].[Doctor_AI] ([doctor_ai_id], [health_record_id], [diabetes_probability], [pre_diabetes_probability], [normal_probability], [doctor_id]) VALUES (3, 45, CAST(0.82 AS Decimal(5, 2)), CAST(0.07 AS Decimal(5, 2)), CAST(0.11 AS Decimal(5, 2)), NULL)
INSERT [dbo].[Doctor_AI] ([doctor_ai_id], [health_record_id], [diabetes_probability], [pre_diabetes_probability], [normal_probability], [doctor_id]) VALUES (4, 46, CAST(0.59 AS Decimal(5, 2)), CAST(0.11 AS Decimal(5, 2)), CAST(0.30 AS Decimal(5, 2)), NULL)
INSERT [dbo].[Doctor_AI] ([doctor_ai_id], [health_record_id], [diabetes_probability], [pre_diabetes_probability], [normal_probability], [doctor_id]) VALUES (5, 48, CAST(0.75 AS Decimal(5, 2)), CAST(0.11 AS Decimal(5, 2)), CAST(0.14 AS Decimal(5, 2)), NULL)
INSERT [dbo].[Doctor_AI] ([doctor_ai_id], [health_record_id], [diabetes_probability], [pre_diabetes_probability], [normal_probability], [doctor_id]) VALUES (6, 47, CAST(0.75 AS Decimal(5, 2)), CAST(0.07 AS Decimal(5, 2)), CAST(0.17 AS Decimal(5, 2)), NULL)
INSERT [dbo].[Doctor_AI] ([doctor_ai_id], [health_record_id], [diabetes_probability], [pre_diabetes_probability], [normal_probability], [doctor_id]) VALUES (7, 49, CAST(0.80 AS Decimal(5, 2)), CAST(0.08 AS Decimal(5, 2)), CAST(0.11 AS Decimal(5, 2)), NULL)
INSERT [dbo].[Doctor_AI] ([doctor_ai_id], [health_record_id], [diabetes_probability], [pre_diabetes_probability], [normal_probability], [doctor_id]) VALUES (8, 50, CAST(0.50 AS Decimal(5, 2)), CAST(0.12 AS Decimal(5, 2)), CAST(0.37 AS Decimal(5, 2)), NULL)
INSERT [dbo].[Doctor_AI] ([doctor_ai_id], [health_record_id], [diabetes_probability], [pre_diabetes_probability], [normal_probability], [doctor_id]) VALUES (9, 51, CAST(0.28 AS Decimal(5, 2)), CAST(0.54 AS Decimal(5, 2)), CAST(0.18 AS Decimal(5, 2)), NULL)
INSERT [dbo].[Doctor_AI] ([doctor_ai_id], [health_record_id], [diabetes_probability], [pre_diabetes_probability], [normal_probability], [doctor_id]) VALUES (10, 53, CAST(0.69 AS Decimal(5, 2)), CAST(0.11 AS Decimal(5, 2)), CAST(0.20 AS Decimal(5, 2)), NULL)
SET IDENTITY_INSERT [dbo].[Doctor_AI] OFF
GO
SET IDENTITY_INSERT [dbo].[Doctor_Lab] ON 

INSERT [dbo].[Doctor_Lab] ([lab_id], [full_name], [phone], [email], [lab_name], [account_id], [date_of_birth], [gender], [address]) VALUES (3, N'BS Xét Nghiệm 1', N'0332255451', N'doctorxn1@gmail.com', N'Phòng xét nghiệm', 70, CAST(N'2008-07-10' AS Date), N'Nam', N'Tan Xa Thach That Ha Noi Viet Nam')
INSERT [dbo].[Doctor_Lab] ([lab_id], [full_name], [phone], [email], [lab_name], [account_id], [date_of_birth], [gender], [address]) VALUES (4, N'BS Xét Nghiệm 2', N'0332244450', N'doctorxn2@gmail.com', NULL, 71, CAST(N'2006-07-25' AS Date), N'male', N'Hà Nội')
INSERT [dbo].[Doctor_Lab] ([lab_id], [full_name], [phone], [email], [lab_name], [account_id], [date_of_birth], [gender], [address]) VALUES (5, N'BS Xét Nghiệm 3', N'0988589152', N'doctorxn3@gmail.com', NULL, 72, CAST(N'2002-06-24' AS Date), N'male', N'Nghệ An , Hà Nội')
SET IDENTITY_INSERT [dbo].[Doctor_Lab] OFF
GO
SET IDENTITY_INSERT [dbo].[Doctor_Schedule] ON 

INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (454, 33, CAST(N'2026-07-24' AS Date), N'00:34-03:00', 5, N'Expired', 5, N'R102')
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (455, 34, CAST(N'2026-07-24' AS Date), N'21:23-23:00', 5, N'Expired', 4, N'R102')
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (456, 33, CAST(N'2026-07-25' AS Date), N'00:39-03:00', 5, N'Expired', 4, N'R101')
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (457, 41, CAST(N'2026-07-25' AS Date), N'00:55-03:00', 5, N'Expired', 5, N'R104')
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (458, 34, CAST(N'2026-07-25' AS Date), N'03:13-06:30', 6, N'Expired', 5, N'R201')
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (459, 35, CAST(N'2026-07-25' AS Date), N'10:00-14:00', 10, N'Expired', 6, N'R101')
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (460, 36, CAST(N'2026-07-25' AS Date), N'16:00-20:00', 10, N'Expired', 5, N'R102')
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (461, 37, CAST(N'2026-07-26' AS Date), N'07:00-09:00', 10, N'Expired', 8, N'R102')
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (462, 33, CAST(N'2026-07-17' AS Date), N'21:50-23:00', 10, N'Expired', 5, N'R101')
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (463, 33, CAST(N'2026-07-27' AS Date), N'07:00-09:00', 10, N'Available', 5, N'R102')
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (464, 33, CAST(N'2026-07-27' AS Date), N'00:08-04:00', 10, N'Available', 5, N'R102')
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (465, 34, CAST(N'2026-07-27' AS Date), N'01:25-04:00', 10, N'Available', 6, N'R101')
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (466, 35, CAST(N'2026-07-27' AS Date), N'02:06-04:00', 10, N'Available', 10, N'R201')
INSERT [dbo].[Doctor_Schedule] ([schedule_id], [doctor_id], [work_date], [time_slot], [max_patients], [status], [online_quota], [room_id]) VALUES (467, 36, CAST(N'2026-07-27' AS Date), N'03:20-05:20', 10, N'Available', 5, N'R202')
SET IDENTITY_INSERT [dbo].[Doctor_Schedule] OFF
GO
SET IDENTITY_INSERT [dbo].[Email_Verification] ON 

INSERT [dbo].[Email_Verification] ([verification_id], [account_id], [purpose], [target_email], [otp_hash], [expires_at], [failed_attempts], [consumed_at], [created_at]) VALUES (29, NULL, N'REGISTER', N'giangnt.he194257@gmail.com', N'542be07f8378e33c2c3e162622f17b807b6d5b65c83848bcdbb0b01cb84036c2', CAST(N'2026-07-25T16:51:54.2033333' AS DateTime2), 0, CAST(N'2026-07-25T16:48:01.6933333' AS DateTime2), CAST(N'2026-07-25T16:46:54.2033333' AS DateTime2))
INSERT [dbo].[Email_Verification] ([verification_id], [account_id], [purpose], [target_email], [otp_hash], [expires_at], [failed_attempts], [consumed_at], [created_at]) VALUES (27, NULL, N'REGISTER', N'lenghia211105@gmail.com', N'46dcc30e20d73ae22440a9518fa3b1a4551e8a024ca5637377c5c95778b8252f', CAST(N'2026-07-25T03:13:38.0100000' AS DateTime2), 0, CAST(N'2026-07-25T03:09:56.8766667' AS DateTime2), CAST(N'2026-07-25T03:08:38.0100000' AS DateTime2))
INSERT [dbo].[Email_Verification] ([verification_id], [account_id], [purpose], [target_email], [otp_hash], [expires_at], [failed_attempts], [consumed_at], [created_at]) VALUES (23, NULL, N'REGISTER', N'lenghia211105@gmail.com', N'8af0f927e2475ccb00b616dfc19d52013ff3fa8900ff29414c1cdea747026f60', CAST(N'2026-07-23T16:35:04.7433333' AS DateTime2), 0, CAST(N'2026-07-23T16:31:34.3433333' AS DateTime2), CAST(N'2026-07-23T16:30:04.7433333' AS DateTime2))
INSERT [dbo].[Email_Verification] ([verification_id], [account_id], [purpose], [target_email], [otp_hash], [expires_at], [failed_attempts], [consumed_at], [created_at]) VALUES (28, 73, N'CHANGE_EMAIL', N'nam30112k5@gmail.com', N'2e44871a61ea10f4f3b2a9c7c76d45bfd62ed8011656c10f980312b9e7216813', CAST(N'2026-07-25T06:20:43.3733333' AS DateTime2), 1, NULL, CAST(N'2026-07-25T06:15:43.3733333' AS DateTime2))
INSERT [dbo].[Email_Verification] ([verification_id], [account_id], [purpose], [target_email], [otp_hash], [expires_at], [failed_attempts], [consumed_at], [created_at]) VALUES (25, NULL, N'REGISTER', N'nguyenanh6868vp@gmail.com', N'a88c05aaa2a68e0365597834cecd7954016eb6bf9cb66d4fa6fd548dda599960', CAST(N'2026-07-24T00:34:36.8500000' AS DateTime2), 0, CAST(N'2026-07-24T00:30:28.4566667' AS DateTime2), CAST(N'2026-07-24T00:29:36.8500000' AS DateTime2))
INSERT [dbo].[Email_Verification] ([verification_id], [account_id], [purpose], [target_email], [otp_hash], [expires_at], [failed_attempts], [consumed_at], [created_at]) VALUES (19, 1, N'RESET_PASSWORD', N'nguyenanh6868vp@gmail.com', N'33bedb4382bc8f1bca69259ba14c348e1b330e0720b25d8e353ebae22859fe18', CAST(N'2026-07-23T15:06:49.6900000' AS DateTime2), 0, CAST(N'2026-07-23T15:02:14.3666667' AS DateTime2), CAST(N'2026-07-23T15:01:49.6900000' AS DateTime2))
INSERT [dbo].[Email_Verification] ([verification_id], [account_id], [purpose], [target_email], [otp_hash], [expires_at], [failed_attempts], [consumed_at], [created_at]) VALUES (18, 1, N'RESET_PASSWORD', N'nguyenanh6868vp@gmail.com', N'3751b77ba5fb1cb3abff93273d525a1a99ab91ebeb07b23a8384c95ddd415bfb', CAST(N'2026-07-23T09:42:01.3733333' AS DateTime2), 0, CAST(N'2026-07-23T15:01:49.6800000' AS DateTime2), CAST(N'2026-07-23T09:37:01.3733333' AS DateTime2))
INSERT [dbo].[Email_Verification] ([verification_id], [account_id], [purpose], [target_email], [otp_hash], [expires_at], [failed_attempts], [consumed_at], [created_at]) VALUES (17, 1, N'RESET_PASSWORD', N'nguyenanh6868vp@gmail.com', N'c9a99e56b8f9a1d8d4d56eb3adf11e7f3b18a617a0a90c430ea831a5f779fd9a', CAST(N'2026-07-19T13:00:42.2733333' AS DateTime2), 0, CAST(N'2026-07-19T12:56:12.3300000' AS DateTime2), CAST(N'2026-07-19T12:55:42.2733333' AS DateTime2))
INSERT [dbo].[Email_Verification] ([verification_id], [account_id], [purpose], [target_email], [otp_hash], [expires_at], [failed_attempts], [consumed_at], [created_at]) VALUES (15, 1, N'RESET_PASSWORD', N'nguyenanh6868vp@gmail.com', N'e0580d4ebbe5fe731cc5cd8ca40e10d3229a7d8867a7fd40d72d1411f0bc18c8', CAST(N'2026-07-18T22:43:09.8166667' AS DateTime2), 0, CAST(N'2026-07-18T22:38:31.7066667' AS DateTime2), CAST(N'2026-07-18T22:38:09.8166667' AS DateTime2))
INSERT [dbo].[Email_Verification] ([verification_id], [account_id], [purpose], [target_email], [otp_hash], [expires_at], [failed_attempts], [consumed_at], [created_at]) VALUES (14, 1, N'RESET_PASSWORD', N'nguyenanh6868vp@gmail.com', N'3679c3a475f24a68c69170d49e30cecdafc19da91fa6a01ee6b100a2bb5da9ac', CAST(N'2026-07-18T22:26:49.3400000' AS DateTime2), 3, CAST(N'2026-07-18T22:38:09.8066667' AS DateTime2), CAST(N'2026-07-18T22:21:49.3400000' AS DateTime2))
INSERT [dbo].[Email_Verification] ([verification_id], [account_id], [purpose], [target_email], [otp_hash], [expires_at], [failed_attempts], [consumed_at], [created_at]) VALUES (13, 1, N'RESET_PASSWORD', N'nguyenanh6868vp@gmail.com', N'a18a37662416beddce33dacba6e75d4b4b177f6d327c472abcfb7aa3f9d16219', CAST(N'2026-07-18T22:22:57.0266667' AS DateTime2), 0, CAST(N'2026-07-18T22:18:11.8333333' AS DateTime2), CAST(N'2026-07-18T22:17:57.0266667' AS DateTime2))
INSERT [dbo].[Email_Verification] ([verification_id], [account_id], [purpose], [target_email], [otp_hash], [expires_at], [failed_attempts], [consumed_at], [created_at]) VALUES (12, 1, N'RESET_PASSWORD', N'nguyenanh6868vp@gmail.com', N'c66c897f6604cb5bd71fb4425b2b4a81727fca90a42bc3fdb14c39bab1297c2e', CAST(N'2026-07-18T22:21:32.6700000' AS DateTime2), 5, CAST(N'2026-07-18T22:17:09.9500000' AS DateTime2), CAST(N'2026-07-18T22:16:32.6700000' AS DateTime2))
INSERT [dbo].[Email_Verification] ([verification_id], [account_id], [purpose], [target_email], [otp_hash], [expires_at], [failed_attempts], [consumed_at], [created_at]) VALUES (11, 1, N'RESET_PASSWORD', N'nguyenanh6868vp@gmail.com', N'bf9668ff6ea3ce9eb400ed0985547c5a6a5c07f0161448c72772b387da618222', CAST(N'2026-07-15T15:02:02.3400000' AS DateTime2), 0, CAST(N'2026-07-18T22:16:32.6533333' AS DateTime2), CAST(N'2026-07-15T14:57:02.3400000' AS DateTime2))
INSERT [dbo].[Email_Verification] ([verification_id], [account_id], [purpose], [target_email], [otp_hash], [expires_at], [failed_attempts], [consumed_at], [created_at]) VALUES (10, 1, N'RESET_PASSWORD', N'nguyenanh6868vp@gmail.com', N'd2870f1e04c942cf2e74cf5afd9570d8a5f7e6d0c946afc6b1538bba25b17b4b', CAST(N'2026-07-15T14:42:16.5400000' AS DateTime2), 0, CAST(N'2026-07-15T14:38:05.6166667' AS DateTime2), CAST(N'2026-07-15T14:37:16.5400000' AS DateTime2))
INSERT [dbo].[Email_Verification] ([verification_id], [account_id], [purpose], [target_email], [otp_hash], [expires_at], [failed_attempts], [consumed_at], [created_at]) VALUES (8, 1, N'RESET_PASSWORD', N'nguyenanh6868vp@gmail.com', N'2ca9521f2534b237711437be51a55998c8d7ba8b79c5108090e2ae0fc2d5f8d7', CAST(N'2026-07-15T13:58:02.5433333' AS DateTime2), 0, CAST(N'2026-07-15T13:53:46.0100000' AS DateTime2), CAST(N'2026-07-15T13:53:02.5433333' AS DateTime2))
INSERT [dbo].[Email_Verification] ([verification_id], [account_id], [purpose], [target_email], [otp_hash], [expires_at], [failed_attempts], [consumed_at], [created_at]) VALUES (7, 1, N'RESET_PASSWORD', N'nguyenanh6868vp@gmail.com', N'e5e75f0463f08af095d014c37cb9aca13a2c977178b72062843992c5cbc151a4', CAST(N'2026-07-15T13:56:27.7166667' AS DateTime2), 0, CAST(N'2026-07-15T13:53:02.5366667' AS DateTime2), CAST(N'2026-07-15T13:51:27.7166667' AS DateTime2))
INSERT [dbo].[Email_Verification] ([verification_id], [account_id], [purpose], [target_email], [otp_hash], [expires_at], [failed_attempts], [consumed_at], [created_at]) VALUES (9, 1, N'CHANGE_EMAIL', N'nguyenanh6868vp1@gmail.com', N'391521fc8d2b6ee82d86cdce22ddcfd3cfc3d1dcc765f14d5f52ae42a2b3849e', CAST(N'2026-07-15T13:59:37.6100000' AS DateTime2), 0, NULL, CAST(N'2026-07-15T13:54:37.6100000' AS DateTime2))
INSERT [dbo].[Email_Verification] ([verification_id], [account_id], [purpose], [target_email], [otp_hash], [expires_at], [failed_attempts], [consumed_at], [created_at]) VALUES (16, 1, N'CHANGE_EMAIL', N'trungkitich1324@gmail.com', N'949ad45eb0498c0962f4d6f2b938f2932a158ccb577585efd9151a51ef6da2f1', CAST(N'2026-07-19T12:51:20.3300000' AS DateTime2), 0, NULL, CAST(N'2026-07-19T12:46:20.3300000' AS DateTime2))
INSERT [dbo].[Email_Verification] ([verification_id], [account_id], [purpose], [target_email], [otp_hash], [expires_at], [failed_attempts], [consumed_at], [created_at]) VALUES (26, NULL, N'REGISTER', N'trungkitich1324@gmail.com', N'02eaf0a42525a6b8f39171eedbdbd7824688a021ce8fb33711894266fa6c82e1', CAST(N'2026-07-24T20:54:08.3933333' AS DateTime2), 1, CAST(N'2026-07-24T20:51:45.6166667' AS DateTime2), CAST(N'2026-07-24T20:49:08.3933333' AS DateTime2))
INSERT [dbo].[Email_Verification] ([verification_id], [account_id], [purpose], [target_email], [otp_hash], [expires_at], [failed_attempts], [consumed_at], [created_at]) VALUES (24, NULL, N'REGISTER', N'trungkitich1324@gmail.com', N'8c594dd10c2e0de6c73c50d47d55c4daa496bd058d5c3856dcc6fc44e710c6a4', CAST(N'2026-07-23T17:05:55.1200000' AS DateTime2), 0, CAST(N'2026-07-24T20:49:08.3566667' AS DateTime2), CAST(N'2026-07-23T17:00:55.1200000' AS DateTime2))
SET IDENTITY_INSERT [dbo].[Email_Verification] OFF
GO
SET IDENTITY_INSERT [dbo].[Healthy_Record] ON 

INSERT [dbo].[Healthy_Record] ([health_record_id], [urea], [cr], [hba1c], [chol], [tg], [hdl], [vldl], [bmi], [patient_id], [weight], [height], [other_information], [status], [created_at], [doctor_id], [record_id], [invoice_id], [ldl], [is_synced_automatically], [synced_at]) VALUES (39, CAST(8.19 AS Decimal(5, 2)), CAST(361.21 AS Decimal(5, 2)), CAST(4.63 AS Decimal(5, 2)), CAST(5.35 AS Decimal(5, 2)), CAST(0.79 AS Decimal(5, 2)), CAST(0.87 AS Decimal(5, 2)), CAST(0.36 AS Decimal(5, 2)), CAST(15.43 AS Decimal(5, 2)), 18, CAST(50.00 AS Decimal(5, 2)), CAST(180.00 AS Decimal(5, 2)), N'phòng xét nghiệm máu - đường huyết', N'Accepted', CAST(N'2026-07-24T00:39:10.613' AS DateTime), 33, 21, 30, CAST(4.12 AS Decimal(5, 2)), 0, NULL)
INSERT [dbo].[Healthy_Record] ([health_record_id], [urea], [cr], [hba1c], [chol], [tg], [hdl], [vldl], [bmi], [patient_id], [weight], [height], [other_information], [status], [created_at], [doctor_id], [record_id], [invoice_id], [ldl], [is_synced_automatically], [synced_at]) VALUES (40, CAST(11.28 AS Decimal(5, 2)), NULL, CAST(10.08 AS Decimal(5, 2)), NULL, NULL, NULL, NULL, CAST(15.43 AS Decimal(5, 2)), 19, CAST(50.00 AS Decimal(5, 2)), CAST(180.00 AS Decimal(5, 2)), N'phòng xét nghiệm máu - đường huyết', N'Accepted', CAST(N'2026-07-25T01:44:48.143' AS DateTime), 33, 22, 31, NULL, 0, NULL)
INSERT [dbo].[Healthy_Record] ([health_record_id], [urea], [cr], [hba1c], [chol], [tg], [hdl], [vldl], [bmi], [patient_id], [weight], [height], [other_information], [status], [created_at], [doctor_id], [record_id], [invoice_id], [ldl], [is_synced_automatically], [synced_at]) VALUES (41, CAST(29.82 AS Decimal(5, 2)), CAST(507.90 AS Decimal(5, 2)), CAST(4.07 AS Decimal(5, 2)), CAST(10.09 AS Decimal(5, 2)), CAST(10.01 AS Decimal(5, 2)), CAST(1.82 AS Decimal(5, 2)), CAST(4.55 AS Decimal(5, 2)), CAST(21.48 AS Decimal(5, 2)), 20, CAST(55.00 AS Decimal(5, 2)), CAST(160.00 AS Decimal(5, 2)), N'phòng xét nghiệm máu - đường huyết', N'Accepted', CAST(N'2026-07-25T03:50:48.070' AS DateTime), 34, 23, 32, CAST(3.72 AS Decimal(5, 2)), 0, NULL)
INSERT [dbo].[Healthy_Record] ([health_record_id], [urea], [cr], [hba1c], [chol], [tg], [hdl], [vldl], [bmi], [patient_id], [weight], [height], [other_information], [status], [created_at], [doctor_id], [record_id], [invoice_id], [ldl], [is_synced_automatically], [synced_at]) VALUES (42, CAST(27.91 AS Decimal(5, 2)), CAST(232.93 AS Decimal(5, 2)), CAST(6.81 AS Decimal(5, 2)), CAST(8.32 AS Decimal(5, 2)), CAST(3.38 AS Decimal(5, 2)), CAST(2.27 AS Decimal(5, 2)), CAST(1.54 AS Decimal(5, 2)), CAST(21.60 AS Decimal(5, 2)), 18, CAST(70.00 AS Decimal(5, 2)), CAST(180.00 AS Decimal(5, 2)), N'phòng xét nghiệm máu - đường huyết', N'Completed', CAST(N'2026-07-25T10:05:09.107' AS DateTime), 35, 24, 33, CAST(4.51 AS Decimal(5, 2)), 0, NULL)
INSERT [dbo].[Healthy_Record] ([health_record_id], [urea], [cr], [hba1c], [chol], [tg], [hdl], [vldl], [bmi], [patient_id], [weight], [height], [other_information], [status], [created_at], [doctor_id], [record_id], [invoice_id], [ldl], [is_synced_automatically], [synced_at]) VALUES (43, CAST(10.09 AS Decimal(5, 2)), CAST(45.61 AS Decimal(5, 2)), CAST(10.67 AS Decimal(5, 2)), CAST(8.48 AS Decimal(5, 2)), CAST(1.63 AS Decimal(5, 2)), CAST(1.43 AS Decimal(5, 2)), CAST(0.74 AS Decimal(5, 2)), CAST(15.43 AS Decimal(5, 2)), 18, CAST(50.00 AS Decimal(5, 2)), CAST(180.00 AS Decimal(5, 2)), N'phòng xét nghiệm máu - đường huyết', N'AI_Processed', CAST(N'2026-07-25T16:24:49.970' AS DateTime), 36, 25, 34, CAST(6.31 AS Decimal(5, 2)), 0, NULL)
INSERT [dbo].[Healthy_Record] ([health_record_id], [urea], [cr], [hba1c], [chol], [tg], [hdl], [vldl], [bmi], [patient_id], [weight], [height], [other_information], [status], [created_at], [doctor_id], [record_id], [invoice_id], [ldl], [is_synced_automatically], [synced_at]) VALUES (44, CAST(26.62 AS Decimal(5, 2)), CAST(584.12 AS Decimal(5, 2)), CAST(12.76 AS Decimal(5, 2)), CAST(9.91 AS Decimal(5, 2)), CAST(10.84 AS Decimal(5, 2)), CAST(1.89 AS Decimal(5, 2)), CAST(4.93 AS Decimal(5, 2)), CAST(24.69 AS Decimal(5, 2)), 21, CAST(80.00 AS Decimal(5, 2)), CAST(180.00 AS Decimal(5, 2)), N'phòng xét nghiệm máu - đường huyết', N'Completed', CAST(N'2026-07-25T17:25:02.053' AS DateTime), 36, 26, 35, CAST(3.09 AS Decimal(5, 2)), 0, NULL)
INSERT [dbo].[Healthy_Record] ([health_record_id], [urea], [cr], [hba1c], [chol], [tg], [hdl], [vldl], [bmi], [patient_id], [weight], [height], [other_information], [status], [created_at], [doctor_id], [record_id], [invoice_id], [ldl], [is_synced_automatically], [synced_at]) VALUES (45, CAST(0.58 AS Decimal(5, 2)), CAST(0.05 AS Decimal(5, 2)), CAST(10.00 AS Decimal(5, 2)), CAST(10.00 AS Decimal(5, 2)), CAST(7.40 AS Decimal(5, 2)), CAST(0.00 AS Decimal(5, 2)), CAST(1.02 AS Decimal(5, 2)), CAST(15.43 AS Decimal(5, 2)), 18, CAST(50.00 AS Decimal(5, 2)), CAST(180.00 AS Decimal(5, 2)), N'phòng xét nghiệm nước tiểu', N'Completed', CAST(N'2026-07-27T00:15:56.270' AS DateTime), 33, 27, 36, CAST(0.00 AS Decimal(5, 2)), 0, NULL)
INSERT [dbo].[Healthy_Record] ([health_record_id], [urea], [cr], [hba1c], [chol], [tg], [hdl], [vldl], [bmi], [patient_id], [weight], [height], [other_information], [status], [created_at], [doctor_id], [record_id], [invoice_id], [ldl], [is_synced_automatically], [synced_at]) VALUES (46, CAST(0.60 AS Decimal(5, 2)), CAST(0.06 AS Decimal(5, 2)), CAST(2.00 AS Decimal(5, 2)), CAST(5.00 AS Decimal(5, 2)), CAST(7.70 AS Decimal(5, 2)), CAST(0.00 AS Decimal(5, 2)), CAST(1.02 AS Decimal(5, 2)), CAST(15.43 AS Decimal(5, 2)), 19, CAST(50.00 AS Decimal(5, 2)), CAST(180.00 AS Decimal(5, 2)), N'phòng xét nghiệm nước tiểu', N'Completed', CAST(N'2026-07-27T00:31:39.560' AS DateTime), 33, 28, 37, CAST(0.00 AS Decimal(5, 2)), 0, NULL)
INSERT [dbo].[Healthy_Record] ([health_record_id], [urea], [cr], [hba1c], [chol], [tg], [hdl], [vldl], [bmi], [patient_id], [weight], [height], [other_information], [status], [created_at], [doctor_id], [record_id], [invoice_id], [ldl], [is_synced_automatically], [synced_at]) VALUES (47, CAST(0.56 AS Decimal(5, 2)), CAST(0.04 AS Decimal(5, 2)), CAST(5.00 AS Decimal(5, 2)), CAST(12.00 AS Decimal(5, 2)), CAST(4.80 AS Decimal(5, 2)), CAST(0.00 AS Decimal(5, 2)), CAST(1.01 AS Decimal(5, 2)), CAST(18.52 AS Decimal(5, 2)), 20, CAST(60.00 AS Decimal(5, 2)), CAST(180.00 AS Decimal(5, 2)), N'phòng xét nghiệm nước tiểu', N'Completed', CAST(N'2026-07-27T01:18:55.107' AS DateTime), 33, 29, 38, CAST(0.00 AS Decimal(5, 2)), 0, NULL)
INSERT [dbo].[Healthy_Record] ([health_record_id], [urea], [cr], [hba1c], [chol], [tg], [hdl], [vldl], [bmi], [patient_id], [weight], [height], [other_information], [status], [created_at], [doctor_id], [record_id], [invoice_id], [ldl], [is_synced_automatically], [synced_at]) VALUES (48, CAST(18.00 AS Decimal(5, 2)), CAST(118.00 AS Decimal(5, 2)), CAST(16.00 AS Decimal(5, 2)), CAST(3.80 AS Decimal(5, 2)), CAST(5.31 AS Decimal(5, 2)), CAST(1.00 AS Decimal(5, 2)), CAST(4.00 AS Decimal(5, 2)), CAST(16.62 AS Decimal(5, 2)), 18, CAST(60.00 AS Decimal(5, 2)), CAST(190.00 AS Decimal(5, 2)), N'phòng xét nghiệm máu - mỡ máu', N'Completed', CAST(N'2026-07-27T01:23:51.537' AS DateTime), 34, 30, 39, CAST(6.00 AS Decimal(5, 2)), 0, NULL)
INSERT [dbo].[Healthy_Record] ([health_record_id], [urea], [cr], [hba1c], [chol], [tg], [hdl], [vldl], [bmi], [patient_id], [weight], [height], [other_information], [status], [created_at], [doctor_id], [record_id], [invoice_id], [ldl], [is_synced_automatically], [synced_at]) VALUES (49, CAST(6.00 AS Decimal(5, 2)), CAST(94.00 AS Decimal(5, 2)), CAST(7.00 AS Decimal(5, 2)), CAST(6.65 AS Decimal(5, 2)), CAST(1.37 AS Decimal(5, 2)), CAST(2.00 AS Decimal(5, 2)), CAST(3.00 AS Decimal(5, 2)), CAST(15.43 AS Decimal(5, 2)), 20, CAST(50.00 AS Decimal(5, 2)), CAST(180.00 AS Decimal(5, 2)), N'phòng xét nghiệm máu - mỡ máu', N'Completed', CAST(N'2026-07-27T01:34:56.580' AS DateTime), 34, 31, 40, CAST(2.00 AS Decimal(5, 2)), 0, NULL)
INSERT [dbo].[Healthy_Record] ([health_record_id], [urea], [cr], [hba1c], [chol], [tg], [hdl], [vldl], [bmi], [patient_id], [weight], [height], [other_information], [status], [created_at], [doctor_id], [record_id], [invoice_id], [ldl], [is_synced_automatically], [synced_at]) VALUES (50, CAST(26.17 AS Decimal(5, 2)), CAST(537.68 AS Decimal(5, 2)), CAST(4.46 AS Decimal(5, 2)), CAST(5.83 AS Decimal(5, 2)), CAST(1.74 AS Decimal(5, 2)), CAST(1.76 AS Decimal(5, 2)), CAST(0.79 AS Decimal(5, 2)), CAST(15.43 AS Decimal(5, 2)), 19, CAST(50.00 AS Decimal(5, 2)), CAST(180.00 AS Decimal(5, 2)), N'phòng xét nghiệm máu - đường huyết', N'Completed', CAST(N'2026-07-27T01:51:41.020' AS DateTime), 34, 32, 41, CAST(3.28 AS Decimal(5, 2)), 0, NULL)
INSERT [dbo].[Healthy_Record] ([health_record_id], [urea], [cr], [hba1c], [chol], [tg], [hdl], [vldl], [bmi], [patient_id], [weight], [height], [other_information], [status], [created_at], [doctor_id], [record_id], [invoice_id], [ldl], [is_synced_automatically], [synced_at]) VALUES (51, CAST(21.27 AS Decimal(5, 2)), CAST(297.77 AS Decimal(5, 2)), CAST(6.16 AS Decimal(5, 2)), CAST(11.34 AS Decimal(5, 2)), CAST(8.61 AS Decimal(5, 2)), CAST(2.26 AS Decimal(5, 2)), CAST(3.91 AS Decimal(5, 2)), CAST(30.86 AS Decimal(5, 2)), 18, CAST(100.00 AS Decimal(5, 2)), CAST(180.00 AS Decimal(5, 2)), N'phòng xét nghiệm máu - đường huyết', N'Completed', CAST(N'2026-07-27T02:06:53.067' AS DateTime), 35, 33, 43, CAST(5.17 AS Decimal(5, 2)), 0, NULL)
INSERT [dbo].[Healthy_Record] ([health_record_id], [urea], [cr], [hba1c], [chol], [tg], [hdl], [vldl], [bmi], [patient_id], [weight], [height], [other_information], [status], [created_at], [doctor_id], [record_id], [invoice_id], [ldl], [is_synced_automatically], [synced_at]) VALUES (52, NULL, NULL, NULL, NULL, NULL, NULL, NULL, CAST(18.52 AS Decimal(5, 2)), 20, CAST(60.00 AS Decimal(5, 2)), CAST(180.00 AS Decimal(5, 2)), NULL, N'Accepted', CAST(N'2026-07-27T02:10:17.417' AS DateTime), 35, 34, NULL, NULL, 0, NULL)
INSERT [dbo].[Healthy_Record] ([health_record_id], [urea], [cr], [hba1c], [chol], [tg], [hdl], [vldl], [bmi], [patient_id], [weight], [height], [other_information], [status], [created_at], [doctor_id], [record_id], [invoice_id], [ldl], [is_synced_automatically], [synced_at]) VALUES (53, CAST(2.00 AS Decimal(5, 2)), CAST(480.00 AS Decimal(5, 2)), CAST(10.00 AS Decimal(5, 2)), CAST(2.40 AS Decimal(5, 2)), CAST(1.24 AS Decimal(5, 2)), CAST(2.00 AS Decimal(5, 2)), CAST(4.00 AS Decimal(5, 2)), CAST(15.43 AS Decimal(5, 2)), 19, CAST(50.00 AS Decimal(5, 2)), CAST(180.00 AS Decimal(5, 2)), N'phòng xét nghiệm máu - mỡ máu', N'Completed', CAST(N'2026-07-27T02:15:18.997' AS DateTime), 35, 35, 44, CAST(4.00 AS Decimal(5, 2)), 0, NULL)
INSERT [dbo].[Healthy_Record] ([health_record_id], [urea], [cr], [hba1c], [chol], [tg], [hdl], [vldl], [bmi], [patient_id], [weight], [height], [other_information], [status], [created_at], [doctor_id], [record_id], [invoice_id], [ldl], [is_synced_automatically], [synced_at]) VALUES (54, NULL, NULL, NULL, NULL, NULL, NULL, NULL, CAST(24.69 AS Decimal(5, 2)), 18, CAST(80.00 AS Decimal(5, 2)), CAST(180.00 AS Decimal(5, 2)), NULL, N'Accepted', CAST(N'2026-07-27T03:20:45.843' AS DateTime), 36, 36, 48, NULL, 0, NULL)
SET IDENTITY_INSERT [dbo].[Healthy_Record] OFF
GO
SET IDENTITY_INSERT [dbo].[Invoice] ON 

INSERT [dbo].[Invoice] ([invoice_id], [patient_id], [receptionist_id], [final_amount], [payment_method], [status], [created_at], [exported_at]) VALUES (30, 18, NULL, CAST(100000.00 AS Decimal(18, 2)), N'VNPay', N'Paid', CAST(N'2026-07-24T00:55:27.723' AS DateTime), CAST(N'2026-07-24T00:56:40.330' AS DateTime))
INSERT [dbo].[Invoice] ([invoice_id], [patient_id], [receptionist_id], [final_amount], [payment_method], [status], [created_at], [exported_at]) VALUES (31, 19, NULL, CAST(100000.00 AS Decimal(18, 2)), N'VNPay', N'Paid', CAST(N'2026-07-25T01:45:08.720' AS DateTime), CAST(N'2026-07-25T01:47:35.897' AS DateTime))
INSERT [dbo].[Invoice] ([invoice_id], [patient_id], [receptionist_id], [final_amount], [payment_method], [status], [created_at], [exported_at]) VALUES (32, 20, NULL, CAST(100000.00 AS Decimal(18, 2)), N'VNPay', N'Paid', CAST(N'2026-07-25T03:51:07.760' AS DateTime), CAST(N'2026-07-25T03:53:32.230' AS DateTime))
INSERT [dbo].[Invoice] ([invoice_id], [patient_id], [receptionist_id], [final_amount], [payment_method], [status], [created_at], [exported_at]) VALUES (33, 18, 68, CAST(100000.00 AS Decimal(18, 2)), N'Cash', N'Paid', CAST(N'2026-07-25T10:10:49.293' AS DateTime), CAST(N'2026-07-25T10:11:58.430' AS DateTime))
INSERT [dbo].[Invoice] ([invoice_id], [patient_id], [receptionist_id], [final_amount], [payment_method], [status], [created_at], [exported_at]) VALUES (34, 18, 67, CAST(100000.00 AS Decimal(18, 2)), N'Cash', N'Paid', CAST(N'2026-07-25T16:32:39.057' AS DateTime), CAST(N'2026-07-25T16:33:12.343' AS DateTime))
INSERT [dbo].[Invoice] ([invoice_id], [patient_id], [receptionist_id], [final_amount], [payment_method], [status], [created_at], [exported_at]) VALUES (35, 21, 67, CAST(100000.00 AS Decimal(18, 2)), N'Cash', N'Paid', CAST(N'2026-07-25T17:25:21.363' AS DateTime), CAST(N'2026-07-25T17:25:45.410' AS DateTime))
INSERT [dbo].[Invoice] ([invoice_id], [patient_id], [receptionist_id], [final_amount], [payment_method], [status], [created_at], [exported_at]) VALUES (36, 18, 69, CAST(250000.00 AS Decimal(18, 2)), N'Cash', N'Paid', CAST(N'2026-07-27T00:16:20.323' AS DateTime), CAST(N'2026-07-27T00:19:32.270' AS DateTime))
INSERT [dbo].[Invoice] ([invoice_id], [patient_id], [receptionist_id], [final_amount], [payment_method], [status], [created_at], [exported_at]) VALUES (37, 19, 69, CAST(370000.00 AS Decimal(18, 2)), N'Cash', N'Paid', CAST(N'2026-07-27T00:32:14.170' AS DateTime), CAST(N'2026-07-27T01:18:38.100' AS DateTime))
INSERT [dbo].[Invoice] ([invoice_id], [patient_id], [receptionist_id], [final_amount], [payment_method], [status], [created_at], [exported_at]) VALUES (38, 20, 69, CAST(250000.00 AS Decimal(18, 2)), N'Cash', N'Paid', CAST(N'2026-07-27T01:19:35.947' AS DateTime), CAST(N'2026-07-27T01:31:41.613' AS DateTime))
INSERT [dbo].[Invoice] ([invoice_id], [patient_id], [receptionist_id], [final_amount], [payment_method], [status], [created_at], [exported_at]) VALUES (39, 18, 69, CAST(350000.00 AS Decimal(18, 2)), N'Cash', N'Paid', CAST(N'2026-07-27T01:24:14.337' AS DateTime), CAST(N'2026-07-27T01:31:34.443' AS DateTime))
INSERT [dbo].[Invoice] ([invoice_id], [patient_id], [receptionist_id], [final_amount], [payment_method], [status], [created_at], [exported_at]) VALUES (40, 20, 69, CAST(200000.00 AS Decimal(18, 2)), N'Cash', N'Paid', CAST(N'2026-07-27T01:36:07.053' AS DateTime), CAST(N'2026-07-27T01:50:44.243' AS DateTime))
INSERT [dbo].[Invoice] ([invoice_id], [patient_id], [receptionist_id], [final_amount], [payment_method], [status], [created_at], [exported_at]) VALUES (41, 19, 69, CAST(100000.00 AS Decimal(18, 2)), N'Cash', N'Paid', CAST(N'2026-07-27T01:52:00.990' AS DateTime), CAST(N'2026-07-27T02:06:41.490' AS DateTime))
INSERT [dbo].[Invoice] ([invoice_id], [patient_id], [receptionist_id], [final_amount], [payment_method], [status], [created_at], [exported_at]) VALUES (43, 18, 2, CAST(100000.00 AS Decimal(18, 2)), N'Cash', N'Paid', CAST(N'2026-07-27T02:28:44.117' AS DateTime), CAST(N'2026-07-27T03:11:46.083' AS DateTime))
INSERT [dbo].[Invoice] ([invoice_id], [patient_id], [receptionist_id], [final_amount], [payment_method], [status], [created_at], [exported_at]) VALUES (44, 19, 2, CAST(200000.00 AS Decimal(18, 2)), N'Cash', N'Paid', CAST(N'2026-07-27T02:47:45.097' AS DateTime), CAST(N'2026-07-27T03:11:42.503' AS DateTime))
INSERT [dbo].[Invoice] ([invoice_id], [patient_id], [receptionist_id], [final_amount], [payment_method], [status], [created_at], [exported_at]) VALUES (48, 18, 4, CAST(100000.00 AS Decimal(18, 2)), N'Cash', N'Paid', CAST(N'2026-07-27T03:42:15.660' AS DateTime), CAST(N'2026-07-27T03:45:59.973' AS DateTime))
SET IDENTITY_INSERT [dbo].[Invoice] OFF
GO
SET IDENTITY_INSERT [dbo].[Invoice_Detail] ON 

INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at], [lab_id]) VALUES (52, 30, 10, 45, 1, CAST(100000.00 AS Decimal(18, 2)), 39, 33, N'', N'Completed', N'Hoàn thành xét nghiệm', CAST(N'2026-07-24T00:55:27.730' AS DateTime), CAST(N'2026-07-26T20:41:08.573' AS DateTime), 3)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at], [lab_id]) VALUES (53, 31, 10, 46, 1, CAST(100000.00 AS Decimal(18, 2)), 40, 33, N'', N'Completed', N'Hoàn thành xét nghiệm', CAST(N'2026-07-25T01:45:08.727' AS DateTime), CAST(N'2026-07-25T11:12:07.533' AS DateTime), 3)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at], [lab_id]) VALUES (54, 32, 10, 47, 1, CAST(100000.00 AS Decimal(18, 2)), 41, 34, N'', N'Completed', N'Hoàn thành xét nghiệm', CAST(N'2026-07-25T03:51:07.763' AS DateTime), CAST(N'2026-07-27T00:08:12.943' AS DateTime), 3)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at], [lab_id]) VALUES (55, 32, 4, 47, 1, CAST(150000.00 AS Decimal(18, 2)), NULL, 5, NULL, N'Requested', NULL, CAST(N'2026-07-25T04:15:44.807' AS DateTime), NULL, NULL)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at], [lab_id]) VALUES (56, 33, 10, 49, 1, CAST(100000.00 AS Decimal(18, 2)), 42, 35, N'', N'Completed', N'Hoàn thành xét nghiệm', CAST(N'2026-07-25T10:10:49.300' AS DateTime), CAST(N'2026-07-25T11:38:05.740' AS DateTime), 4)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at], [lab_id]) VALUES (57, 34, 10, 50, 1, CAST(100000.00 AS Decimal(18, 2)), 43, 36, N'', N'Completed', N'Hoàn thành xét nghiệm', CAST(N'2026-07-25T16:32:39.063' AS DateTime), CAST(N'2026-07-25T16:34:34.300' AS DateTime), 5)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at], [lab_id]) VALUES (58, 35, 10, 51, 1, CAST(100000.00 AS Decimal(18, 2)), 44, 36, N'', N'Completed', N'Hoàn thành xét nghiệm', CAST(N'2026-07-25T17:25:21.373' AS DateTime), CAST(N'2026-07-25T17:26:45.817' AS DateTime), 5)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at], [lab_id]) VALUES (59, 35, 4, 51, 1, CAST(150000.00 AS Decimal(18, 2)), NULL, 5, NULL, N'Requested', NULL, CAST(N'2026-07-26T20:34:36.480' AS DateTime), NULL, NULL)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at], [lab_id]) VALUES (60, 35, 3, 51, 1, CAST(300000.00 AS Decimal(18, 2)), NULL, 5, NULL, N'Requested', NULL, CAST(N'2026-07-26T21:34:50.940' AS DateTime), NULL, NULL)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at], [lab_id]) VALUES (61, 35, 5, 51, 1, CAST(150000.00 AS Decimal(18, 2)), NULL, 5, NULL, N'Requested', NULL, CAST(N'2026-07-26T21:35:02.310' AS DateTime), NULL, NULL)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at], [lab_id]) VALUES (62, 36, 10, 1052, 1, CAST(100000.00 AS Decimal(18, 2)), 45, 33, N'', N'Completed', N'Hoàn thành xét nghiệm', CAST(N'2026-07-27T00:16:20.327' AS DateTime), CAST(N'2026-07-27T00:17:07.840' AS DateTime), 3)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at], [lab_id]) VALUES (63, 36, 15, 1052, 1, CAST(150000.00 AS Decimal(18, 2)), 45, 33, N'', N'Completed', N'Hoàn thành xét nghiệm', CAST(N'2026-07-27T00:16:20.327' AS DateTime), CAST(N'2026-07-27T00:17:23.893' AS DateTime), 3)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at], [lab_id]) VALUES (64, 37, 10, 1053, 1, CAST(100000.00 AS Decimal(18, 2)), 46, 33, N'', N'Completed', N'Hoàn thành xét nghiệm', CAST(N'2026-07-27T00:32:14.173' AS DateTime), CAST(N'2026-07-27T00:34:14.573' AS DateTime), 3)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at], [lab_id]) VALUES (65, 37, 13, 1053, 1, CAST(120000.00 AS Decimal(18, 2)), 46, 33, N'', N'Completed', N'Hoàn thành xét nghiệm', CAST(N'2026-07-27T00:32:14.177' AS DateTime), CAST(N'2026-07-27T00:32:57.237' AS DateTime), 3)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at], [lab_id]) VALUES (66, 37, 15, 1053, 1, CAST(150000.00 AS Decimal(18, 2)), 46, 33, N'', N'Completed', N'Hoàn thành xét nghiệm', CAST(N'2026-07-27T00:32:14.177' AS DateTime), CAST(N'2026-07-27T00:34:48.160' AS DateTime), 3)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at], [lab_id]) VALUES (67, 38, 10, 1054, 1, CAST(100000.00 AS Decimal(18, 2)), 47, 33, N'', N'Completed', N'Hoàn thành xét nghiệm', CAST(N'2026-07-27T01:19:35.950' AS DateTime), CAST(N'2026-07-27T01:29:39.083' AS DateTime), 3)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at], [lab_id]) VALUES (68, 38, 15, 1054, 1, CAST(150000.00 AS Decimal(18, 2)), 47, 33, N'', N'Completed', N'Hoàn thành xét nghiệm', CAST(N'2026-07-27T01:19:35.950' AS DateTime), CAST(N'2026-07-27T01:29:54.367' AS DateTime), 3)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at], [lab_id]) VALUES (69, 39, 10, 1055, 1, CAST(100000.00 AS Decimal(18, 2)), 48, 34, N'', N'Completed', N'Hoàn thành xét nghiệm', CAST(N'2026-07-27T01:24:14.343' AS DateTime), CAST(N'2026-07-27T01:29:35.453' AS DateTime), 3)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at], [lab_id]) VALUES (70, 39, 11, 1055, 1, CAST(150000.00 AS Decimal(18, 2)), 48, 34, N'', N'Completed', N'Hoàn thành xét nghiệm', CAST(N'2026-07-27T01:24:14.347' AS DateTime), CAST(N'2026-07-27T01:29:43.400' AS DateTime), 3)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at], [lab_id]) VALUES (71, 39, 14, 1055, 1, CAST(100000.00 AS Decimal(18, 2)), 48, 34, N'', N'Completed', N'Hoàn thành xét nghiệm', CAST(N'2026-07-27T01:24:14.347' AS DateTime), CAST(N'2026-07-27T01:29:49.870' AS DateTime), 3)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at], [lab_id]) VALUES (72, 40, 10, 1056, 1, CAST(100000.00 AS Decimal(18, 2)), 49, 34, N'', N'Completed', N'Hoàn thành xét nghiệm', CAST(N'2026-07-27T01:36:07.070' AS DateTime), CAST(N'2026-07-27T01:49:42.677' AS DateTime), 3)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at], [lab_id]) VALUES (73, 40, 14, 1056, 1, CAST(100000.00 AS Decimal(18, 2)), 49, 34, N'', N'Completed', N'Hoàn thành xét nghiệm', CAST(N'2026-07-27T01:36:07.070' AS DateTime), CAST(N'2026-07-27T01:49:49.983' AS DateTime), 3)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at], [lab_id]) VALUES (74, 41, 10, 1057, 1, CAST(100000.00 AS Decimal(18, 2)), 50, 34, N'', N'Completed', N'Hoàn thành xét nghiệm', CAST(N'2026-07-27T01:52:00.993' AS DateTime), CAST(N'2026-07-27T02:14:08.903' AS DateTime), 3)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at], [lab_id]) VALUES (77, 43, 10, 1058, 1, CAST(100000.00 AS Decimal(18, 2)), 51, 35, N'', N'Completed', N'Hoàn thành xét nghiệm', CAST(N'2026-07-27T02:28:44.120' AS DateTime), CAST(N'2026-07-27T03:14:05.560' AS DateTime), 3)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at], [lab_id]) VALUES (78, 44, 10, 1060, 1, CAST(100000.00 AS Decimal(18, 2)), 53, 35, N'', N'Completed', N'Hoàn thành xét nghiệm', CAST(N'2026-07-27T02:47:45.100' AS DateTime), CAST(N'2026-07-27T03:14:09.837' AS DateTime), 3)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at], [lab_id]) VALUES (79, 44, 14, 1060, 1, CAST(100000.00 AS Decimal(18, 2)), 53, 35, N'', N'Completed', N'Hoàn thành xét nghiệm', CAST(N'2026-07-27T02:47:45.103' AS DateTime), CAST(N'2026-07-27T03:14:16.220' AS DateTime), 3)
INSERT [dbo].[Invoice_Detail] ([invoice_detail_id], [invoice_id], [service_id], [appointment_id], [quantity], [price], [health_record_id], [doctor_id], [request_note], [lab_status], [lab_result], [requested_at], [completed_at], [lab_id]) VALUES (83, 48, 10, 1061, 1, CAST(100000.00 AS Decimal(18, 2)), 54, 36, N'', N'Requested', NULL, CAST(N'2026-07-27T03:42:15.667' AS DateTime), NULL, 3)
SET IDENTITY_INSERT [dbo].[Invoice_Detail] OFF
GO
INSERT [dbo].[Lab_Order] ([order_id], [appointment_id], [patient_id], [room_id], [service_id], [lab_id], [status], [created_at]) VALUES (N'LAB-52', 45, 18, N'LAB01', 10, NULL, N'Completed', CAST(N'2026-07-24T00:56:40.390' AS DateTime))
INSERT [dbo].[Lab_Order] ([order_id], [appointment_id], [patient_id], [room_id], [service_id], [lab_id], [status], [created_at]) VALUES (N'LAB-53', 46, 19, N'LAB02', 10, NULL, N'Completed', CAST(N'2026-07-25T01:47:35.947' AS DateTime))
INSERT [dbo].[Lab_Order] ([order_id], [appointment_id], [patient_id], [room_id], [service_id], [lab_id], [status], [created_at]) VALUES (N'LAB-54', 47, 20, N'LAB01', 10, 3, N'Completed', CAST(N'2026-07-25T03:53:32.283' AS DateTime))
INSERT [dbo].[Lab_Order] ([order_id], [appointment_id], [patient_id], [room_id], [service_id], [lab_id], [status], [created_at]) VALUES (N'LAB-77', 1058, 18, N'LAB01', 10, 3, N'Completed', CAST(N'2026-07-27T03:11:46.163' AS DateTime))
INSERT [dbo].[Lab_Order] ([order_id], [appointment_id], [patient_id], [room_id], [service_id], [lab_id], [status], [created_at]) VALUES (N'LAB-78', 1060, 19, N'LAB01', 10, 3, N'Completed', CAST(N'2026-07-27T03:11:42.593' AS DateTime))
INSERT [dbo].[Lab_Order] ([order_id], [appointment_id], [patient_id], [room_id], [service_id], [lab_id], [status], [created_at]) VALUES (N'LAB-79', 1060, 19, N'LAB01', 14, 3, N'Completed', CAST(N'2026-07-27T03:11:42.593' AS DateTime))
INSERT [dbo].[Lab_Order] ([order_id], [appointment_id], [patient_id], [room_id], [service_id], [lab_id], [status], [created_at]) VALUES (N'LAB-83', 1061, 18, N'LAB01', 10, 3, N'Requested', CAST(N'2026-07-27T03:42:15.720' AS DateTime))
GO
SET IDENTITY_INSERT [dbo].[Lab_Schedule] ON 

INSERT [dbo].[Lab_Schedule] ([lab_sched_id], [lab_id], [work_date], [time_slot], [room_id], [status], [max_patients]) VALUES (3, 3, CAST(N'2026-07-24' AS Date), N'00:38-02:36', N'LAB01', N'Completed', NULL)
INSERT [dbo].[Lab_Schedule] ([lab_sched_id], [lab_id], [work_date], [time_slot], [room_id], [status], [max_patients]) VALUES (4, 3, CAST(N'2026-07-24' AS Date), N'21:24-23:56', N'LAB01', N'Completed', NULL)
INSERT [dbo].[Lab_Schedule] ([lab_sched_id], [lab_id], [work_date], [time_slot], [room_id], [status], [max_patients]) VALUES (5, 3, CAST(N'2026-07-25' AS Date), N'07:50-17:50', N'LAB01', N'Completed', 10)
INSERT [dbo].[Lab_Schedule] ([lab_sched_id], [lab_id], [work_date], [time_slot], [room_id], [status], [max_patients]) VALUES (6, 4, CAST(N'2026-07-25' AS Date), N'10:05-14:01', N'LAB02', N'Completed', 20)
INSERT [dbo].[Lab_Schedule] ([lab_sched_id], [lab_id], [work_date], [time_slot], [room_id], [status], [max_patients]) VALUES (7, 5, CAST(N'2026-07-25' AS Date), N'16:02-20:01', N'LAB02', N'Completed', 10)
INSERT [dbo].[Lab_Schedule] ([lab_sched_id], [lab_id], [work_date], [time_slot], [room_id], [status], [max_patients]) VALUES (8, 3, CAST(N'2026-07-27' AS Date), N'00:13-04:12', N'LAB01', N'Available', 10)
SET IDENTITY_INSERT [dbo].[Lab_Schedule] OFF
GO
SET IDENTITY_INSERT [dbo].[Medical_record] ON 

INSERT [dbo].[Medical_record] ([record_id], [patient_id], [doctor_id], [final_diagnosis], [doctor_note], [health_record_id], [result_visibility], [processed_at], [appointment_id], [laboratory_test_types], [laboratory_total_price], [revisit_date]) VALUES (21, 18, 33, NULL, NULL, 39, 0, NULL, 45, N'Huyết Học - Tế Bào Máu', CAST(100000.00 AS Decimal(18, 2)), NULL)
INSERT [dbo].[Medical_record] ([record_id], [patient_id], [doctor_id], [final_diagnosis], [doctor_note], [health_record_id], [result_visibility], [processed_at], [appointment_id], [laboratory_test_types], [laboratory_total_price], [revisit_date]) VALUES (22, 19, 33, NULL, NULL, 40, 0, NULL, 46, N'Huyết Học - Tế Bào Máu', CAST(100000.00 AS Decimal(18, 2)), NULL)
INSERT [dbo].[Medical_record] ([record_id], [patient_id], [doctor_id], [final_diagnosis], [doctor_note], [health_record_id], [result_visibility], [processed_at], [appointment_id], [laboratory_test_types], [laboratory_total_price], [revisit_date]) VALUES (23, 20, 34, NULL, NULL, 41, 0, NULL, 47, N'Huyết Học - Tế Bào Máu', CAST(100000.00 AS Decimal(18, 2)), NULL)
INSERT [dbo].[Medical_record] ([record_id], [patient_id], [doctor_id], [final_diagnosis], [doctor_note], [health_record_id], [result_visibility], [processed_at], [appointment_id], [laboratory_test_types], [laboratory_total_price], [revisit_date]) VALUES (24, 18, 35, N'Tiểu đường Type 1', N'Về chú ý ăn uống điều độ, tránh ăn nhiều đường', 42, 1, CAST(N'2026-07-25T12:03:20.713' AS DateTime), 49, N'Huyết Học - Tế Bào Máu', CAST(100000.00 AS Decimal(18, 2)), CAST(N'2026-07-25T00:00:00.000' AS DateTime))
INSERT [dbo].[Medical_record] ([record_id], [patient_id], [doctor_id], [final_diagnosis], [doctor_note], [health_record_id], [result_visibility], [processed_at], [appointment_id], [laboratory_test_types], [laboratory_total_price], [revisit_date]) VALUES (25, 18, 36, N'Tiểu đường Type 1', N'', 43, 1, CAST(N'2026-07-25T16:35:48.017' AS DateTime), 50, N'Huyết Học - Tế Bào Máu', CAST(100000.00 AS Decimal(18, 2)), CAST(N'2026-07-26T00:00:00.000' AS DateTime))
INSERT [dbo].[Medical_record] ([record_id], [patient_id], [doctor_id], [final_diagnosis], [doctor_note], [health_record_id], [result_visibility], [processed_at], [appointment_id], [laboratory_test_types], [laboratory_total_price], [revisit_date]) VALUES (26, 21, 36, N'Tiểu đường Type 1', N'', 44, 1, CAST(N'2026-07-25T17:27:32.543' AS DateTime), 51, N'Huyết Học - Tế Bào Máu', CAST(100000.00 AS Decimal(18, 2)), CAST(N'2026-07-26T00:00:00.000' AS DateTime))
INSERT [dbo].[Medical_record] ([record_id], [patient_id], [doctor_id], [final_diagnosis], [doctor_note], [health_record_id], [result_visibility], [processed_at], [appointment_id], [laboratory_test_types], [laboratory_total_price], [revisit_date]) VALUES (27, 18, 33, N'Tiểu đường Type 1', N'', 45, 1, CAST(N'2026-07-27T00:22:14.493' AS DateTime), 1052, N'Huyết Học - Tế Bào Máu, Tổng Phân Tích Nước Tiểu ', CAST(250000.00 AS Decimal(18, 2)), CAST(N'2026-07-28T00:00:00.000' AS DateTime))
INSERT [dbo].[Medical_record] ([record_id], [patient_id], [doctor_id], [final_diagnosis], [doctor_note], [health_record_id], [result_visibility], [processed_at], [appointment_id], [laboratory_test_types], [laboratory_total_price], [revisit_date]) VALUES (28, 19, 33, N'Tiểu đường Type 1', N'', 46, 1, CAST(N'2026-07-27T01:32:08.117' AS DateTime), 1053, N'Huyết Học - Tế Bào Máu, Chức Năng Gan, Tổng Phân Tích Nước Tiểu ', CAST(370000.00 AS Decimal(18, 2)), CAST(N'2026-07-28T00:00:00.000' AS DateTime))
INSERT [dbo].[Medical_record] ([record_id], [patient_id], [doctor_id], [final_diagnosis], [doctor_note], [health_record_id], [result_visibility], [processed_at], [appointment_id], [laboratory_test_types], [laboratory_total_price], [revisit_date]) VALUES (29, 20, 33, N'Bình thường', N'', 47, 1, CAST(N'2026-07-27T01:33:51.167' AS DateTime), 1054, N'Huyết Học - Tế Bào Máu, Tổng Phân Tích Nước Tiểu ', CAST(250000.00 AS Decimal(18, 2)), NULL)
INSERT [dbo].[Medical_record] ([record_id], [patient_id], [doctor_id], [final_diagnosis], [doctor_note], [health_record_id], [result_visibility], [processed_at], [appointment_id], [laboratory_test_types], [laboratory_total_price], [revisit_date]) VALUES (30, 18, 34, N'Tiểu đường Type 1', N'', 48, 1, CAST(N'2026-07-27T01:32:31.893' AS DateTime), 1055, N'Huyết Học - Tế Bào Máu, Đái Tháo Đường, Sinh Hóa - Mỡ Máu', CAST(350000.00 AS Decimal(18, 2)), CAST(N'2026-07-28T00:00:00.000' AS DateTime))
INSERT [dbo].[Medical_record] ([record_id], [patient_id], [doctor_id], [final_diagnosis], [doctor_note], [health_record_id], [result_visibility], [processed_at], [appointment_id], [laboratory_test_types], [laboratory_total_price], [revisit_date]) VALUES (31, 20, 34, N'Bình thường', N'', 49, 1, CAST(N'2026-07-27T01:51:01.377' AS DateTime), 1056, N'Huyết Học - Tế Bào Máu, Sinh Hóa - Mỡ Máu', CAST(200000.00 AS Decimal(18, 2)), NULL)
INSERT [dbo].[Medical_record] ([record_id], [patient_id], [doctor_id], [final_diagnosis], [doctor_note], [health_record_id], [result_visibility], [processed_at], [appointment_id], [laboratory_test_types], [laboratory_total_price], [revisit_date]) VALUES (32, 19, 34, N'Bình thường', N'', 50, 1, CAST(N'2026-07-27T02:14:34.283' AS DateTime), 1057, N'Huyết Học - Tế Bào Máu', CAST(100000.00 AS Decimal(18, 2)), NULL)
INSERT [dbo].[Medical_record] ([record_id], [patient_id], [doctor_id], [final_diagnosis], [doctor_note], [health_record_id], [result_visibility], [processed_at], [appointment_id], [laboratory_test_types], [laboratory_total_price], [revisit_date]) VALUES (33, 18, 35, N'Bình thường', N'', 51, 1, CAST(N'2026-07-27T03:19:26.167' AS DateTime), 1058, N'Huyết Học - Tế Bào Máu', CAST(100000.00 AS Decimal(18, 2)), NULL)
INSERT [dbo].[Medical_record] ([record_id], [patient_id], [doctor_id], [final_diagnosis], [doctor_note], [health_record_id], [result_visibility], [processed_at], [appointment_id], [laboratory_test_types], [laboratory_total_price], [revisit_date]) VALUES (34, 20, 35, NULL, NULL, 52, 0, NULL, 1059, NULL, NULL, NULL)
INSERT [dbo].[Medical_record] ([record_id], [patient_id], [doctor_id], [final_diagnosis], [doctor_note], [health_record_id], [result_visibility], [processed_at], [appointment_id], [laboratory_test_types], [laboratory_total_price], [revisit_date]) VALUES (35, 19, 35, N'Bình thường', N'', 53, 0, CAST(N'2026-07-27T03:19:36.710' AS DateTime), 1060, N'Huyết Học - Tế Bào Máu, Sinh Hóa - Mỡ Máu', CAST(200000.00 AS Decimal(18, 2)), NULL)
INSERT [dbo].[Medical_record] ([record_id], [patient_id], [doctor_id], [final_diagnosis], [doctor_note], [health_record_id], [result_visibility], [processed_at], [appointment_id], [laboratory_test_types], [laboratory_total_price], [revisit_date]) VALUES (36, 18, 36, NULL, NULL, 54, 0, NULL, 1061, N'Huyết Học - Tế Bào Máu', CAST(100000.00 AS Decimal(18, 2)), NULL)
SET IDENTITY_INSERT [dbo].[Medical_record] OFF
GO
SET IDENTITY_INSERT [dbo].[Medical_Service] ON 

INSERT [dbo].[Medical_Service] ([service_id], [service_name], [price], [service_type], [status]) VALUES (10, N'Huyết Học - Tế Bào Máu', CAST(100000.00 AS Decimal(18, 2)), N'Lab_Test', N'Active')
INSERT [dbo].[Medical_Service] ([service_id], [service_name], [price], [service_type], [status]) VALUES (11, N'Đái Tháo Đường', CAST(150000.00 AS Decimal(18, 2)), N'Lab_Test', N'Active')
INSERT [dbo].[Medical_Service] ([service_id], [service_name], [price], [service_type], [status]) VALUES (12, N'Chức Năng Thận', CAST(200000.00 AS Decimal(18, 2)), N'Lab_Test', N'Active')
INSERT [dbo].[Medical_Service] ([service_id], [service_name], [price], [service_type], [status]) VALUES (13, N'Chức Năng Gan', CAST(120000.00 AS Decimal(18, 2)), N'Lab_Test', N'Active')
INSERT [dbo].[Medical_Service] ([service_id], [service_name], [price], [service_type], [status]) VALUES (14, N'Sinh Hóa - Mỡ Máu', CAST(100000.00 AS Decimal(18, 2)), N'Lab_Test', N'Active')
INSERT [dbo].[Medical_Service] ([service_id], [service_name], [price], [service_type], [status]) VALUES (15, N'Tổng Phân Tích Nước Tiểu ', CAST(150000.00 AS Decimal(18, 2)), N'Lab_Test', N'Active')
SET IDENTITY_INSERT [dbo].[Medical_Service] OFF
GO
SET IDENTITY_INSERT [dbo].[Notification] ON 

INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (79, 73, N'Đặt lịch thành công', N'Lịch hẹn với BS Nội Tiết 1 lúc 00:34 24/07/2026 đã được tạo.', N'APPOINTMENT_CREATED', 0, CAST(N'2026-07-24T00:37:51.560' AS DateTime), N'/patient/appointments/detail?id=45', N'APPOINTMENT_CREATED:45')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (80, 73, N'Có hóa đơn mới', N'Hóa đơn #30 có số tiền 100000.00 đang chờ thanh toán.', N'INVOICE_CREATED', 0, CAST(N'2026-07-24T00:55:27.780' AS DateTime), N'/patient/invoices/detail?id=30', N'INVOICE_CREATED:30')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (81, 73, N'Thanh toán thành công', N'Hóa đơn #30 đã được xác nhận thanh toán.', N'INVOICE_PAID', 0, CAST(N'2026-07-24T00:56:40.410' AS DateTime), N'/patient/invoices/detail?id=30', N'INVOICE_PAID:30')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (82, 73, N'Yêu cầu xét nghiệm', N'Yêu cầu xét nghiệm đã sẵn sàng. Vui lòng đến Phòng xét nghiệm 1 (Tầng 2 - Khu xét nghiệm).', N'LAB_REQUESTED', 1, CAST(N'2026-07-24T00:56:40.430' AS DateTime), N'/patient/appointments/detail?id=45', N'LAB_REQUESTED:30')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (83, 73, N'Yêu cầu theo dõi hồ sơ', N'Tài khoản trungkitich1324@gmail.com đã gửi yêu cầu muốn theo dõi hồ sơ y tế gia đình của bạn.', N'SYSTEM', 1, CAST(N'2026-07-24T20:54:00.950' AS DateTime), N'/patient/family-sharing', N'NOTIF_1784901240860_862')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (84, 74, N'Đã tạo yêu cầu theo dõi', N'Bạn đã gửi yêu cầu xin phép theo dõi hồ sơ y tế gia đình của tài khoản nguyenanh6868vp@gmail.com.', N'SYSTEM', 0, CAST(N'2026-07-24T20:54:00.980' AS DateTime), N'/patient/family-sharing', N'NOTIF_1784901240951_378')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (85, 74, N'Chấp nhận chia sẻ hồ sơ', N'Yêu cầu liên kết hồ sơ y tế gia đình của bạn với tài khoản nguyenanh6868vp@gmail.com đã được chấp nhận.', N'SYSTEM', 1, CAST(N'2026-07-24T20:55:27.607' AS DateTime), N'/patient/family-sharing', N'NOTIF_1784901327568_104')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (86, 67, N'Thông tin cá nhân đã cập nhật', N'Thông tin cá nhân của bạn đã được cập nhật thành công.', N'PROFILE_UPDATE', 0, CAST(N'2026-07-24T21:08:57.777' AS DateTime), N'/settings', N'PROFILE_UPDATED:67:1784902137711')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (87, 68, N'Thông tin cá nhân đã cập nhật', N'Thông tin cá nhân của bạn đã được cập nhật thành công.', N'PROFILE_UPDATE', 0, CAST(N'2026-07-24T21:10:23.883' AS DateTime), N'/settings', N'PROFILE_UPDATED:68:1784902223820')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (88, 69, N'Thông tin cá nhân đã cập nhật', N'Thông tin cá nhân của bạn đã được cập nhật thành công.', N'PROFILE_UPDATE', 0, CAST(N'2026-07-24T21:14:15.380' AS DateTime), N'/settings', N'PROFILE_UPDATED:69:1784902455278')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (89, 73, N'Lời mời chia sẻ hồ sơ', N'Tài khoản trungkitich1324@gmail.com đã mời bạn xem hồ sơ y tế gia đình.', N'SYSTEM', 1, CAST(N'2026-07-25T00:48:33.040' AS DateTime), N'/patient/family-sharing', N'NOTIF_1784915312926_718')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (90, 74, N'Đã tạo lời mời chia sẻ', N'Bạn đã gửi lời mời xem hồ sơ y tế gia đình của bạn cho tài khoản nguyenanh6868vp@gmail.com.', N'SYSTEM', 0, CAST(N'2026-07-25T00:48:33.077' AS DateTime), N'/patient/family-sharing', N'NOTIF_1784915313053_906')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (91, 74, N'Chấp nhận chia sẻ hồ sơ', N'Yêu cầu liên kết hồ sơ y tế gia đình của bạn với tài khoản nguyenanh6868vp@gmail.com đã được chấp nhận.', N'SYSTEM', 0, CAST(N'2026-07-25T00:48:45.347' AS DateTime), N'/patient/family-sharing', N'NOTIF_1784915325237_752')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (92, 74, N'Đặt lịch thành công', N'Lịch hẹn với BS Nội Tiết 1 lúc 00:39 25/07/2026 đã được tạo.', N'APPOINTMENT_CREATED', 0, CAST(N'2026-07-25T01:07:24.543' AS DateTime), N'/patient/appointments/detail?id=46', N'APPOINTMENT_CREATED:46')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (93, 74, N'Có hóa đơn mới', N'Hóa đơn #31 có số tiền 100000.00 đang chờ thanh toán.', N'INVOICE_CREATED', 0, CAST(N'2026-07-25T01:45:08.830' AS DateTime), N'/patient/invoices/detail?id=31', N'INVOICE_CREATED:31')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (94, 74, N'Thanh toán thành công', N'Hóa đơn #31 đã được xác nhận thanh toán.', N'INVOICE_PAID', 0, CAST(N'2026-07-25T01:47:36.013' AS DateTime), N'/patient/invoices/detail?id=31', N'INVOICE_PAID:31')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (95, 74, N'Yêu cầu xét nghiệm', N'Yêu cầu xét nghiệm đã sẵn sàng. Vui lòng đến Phòng xét nghiệm 2 (Tầng 2 - Khu xét nghiệm).', N'LAB_REQUESTED', 0, CAST(N'2026-07-25T01:47:36.030' AS DateTime), N'/patient/appointments/detail?id=46', N'LAB_REQUESTED:31')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (96, 75, N'Đặt lịch thành công', N'Lịch hẹn với BS Nội Tiết 2 lúc 03:13 25/07/2026 đã được tạo.', N'APPOINTMENT_CREATED', 0, CAST(N'2026-07-25T03:12:06.640' AS DateTime), N'/patient/appointments/detail?id=47', N'APPOINTMENT_CREATED:47')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (97, 75, N'Có hóa đơn mới', N'Hóa đơn #32 có số tiền 100000.00 đang chờ thanh toán.', N'INVOICE_CREATED', 0, CAST(N'2026-07-25T03:51:07.860' AS DateTime), N'/patient/invoices/detail?id=32', N'INVOICE_CREATED:32')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (98, 75, N'Thanh toán thành công', N'Hóa đơn #32 đã được xác nhận thanh toán.', N'INVOICE_PAID', 0, CAST(N'2026-07-25T03:53:32.353' AS DateTime), N'/patient/invoices/detail?id=32', N'INVOICE_PAID:32')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (99, 75, N'Yêu cầu xét nghiệm', N'Yêu cầu xét nghiệm đã sẵn sàng. Vui lòng đến Phòng xét nghiệm 1 (Tầng 2 - Khu xét nghiệm).', N'LAB_REQUESTED', 1, CAST(N'2026-07-25T03:53:32.370' AS DateTime), N'/patient/appointments/detail?id=47', N'LAB_REQUESTED:32')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (100, 73, N'Đặt lịch thành công', N'Lịch hẹn với BS Nội Tiết 2 lúc 03:13 25/07/2026 đã được tạo.', N'APPOINTMENT_CREATED', 1, CAST(N'2026-07-25T04:18:37.067' AS DateTime), N'/patient/appointments/detail?id=48', N'APPOINTMENT_CREATED:48')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (101, 73, N'Lịch khám đã bị hủy', N'Lịch khám ngày 2026-07-25 03:13 với BS Nội Tiết 2 đã được hủy bởi Lễ tân. Lý do: Bệnh Nhân Yêu Cầu Hủy Lịch', N'Appointment_Cancelled', 1, CAST(N'2026-07-25T04:26:59.313' AS DateTime), NULL, NULL)
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (102, 73, N'Thông tin cá nhân đã cập nhật', N'Thông tin cá nhân của bạn đã được cập nhật thành công.', N'PROFILE_UPDATE', 0, CAST(N'2026-07-25T06:07:05.730' AS DateTime), N'/settings', N'PROFILE_UPDATED:73:1784934425642')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (103, 56, N'Thông tin cá nhân đã cập nhật', N'Thông tin cá nhân của bạn đã được cập nhật thành công.', N'PROFILE_UPDATE', 0, CAST(N'2026-07-25T09:53:54.363' AS DateTime), N'/settings', N'PROFILE_UPDATED:56:1784948034279')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (104, 57, N'Thông tin cá nhân đã cập nhật', N'Thông tin cá nhân của bạn đã được cập nhật thành công.', N'PROFILE_UPDATE', 0, CAST(N'2026-07-25T09:59:00.787' AS DateTime), N'/settings', N'PROFILE_UPDATED:57:1784948340688')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (105, 71, N'Thông tin cá nhân đã cập nhật', N'Thông tin cá nhân của bạn đã được cập nhật thành công.', N'PROFILE_UPDATE', 0, CAST(N'2026-07-25T10:00:45.620' AS DateTime), N'/settings', N'PROFILE_UPDATED:71:1784948445525')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (106, 73, N'Đặt lịch thành công', N'Lịch hẹn với BS Nội Tiết 3 lúc 10:00 25/07/2026 đã được tạo.', N'APPOINTMENT_CREATED', 0, CAST(N'2026-07-25T10:03:27.200' AS DateTime), N'/patient/appointments/detail?id=49', N'APPOINTMENT_CREATED:49')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (107, 73, N'Có hóa đơn mới', N'Hóa đơn #33 có số tiền 100000.00 đang chờ thanh toán.', N'INVOICE_CREATED', 0, CAST(N'2026-07-25T10:10:49.420' AS DateTime), N'/patient/invoices/detail?id=33', N'INVOICE_CREATED:33')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (108, 73, N'Kết quả khám bệnh', N'Bác sĩ đã hoàn tất kết quả khám và chỉ số xét nghiệm của bạn.', N'DIAGNOSIS_COMPLETED', 1, CAST(N'2026-07-25T12:03:20.860' AS DateTime), N'/patient/history/detail?id=49', N'DIAGNOSIS_COMPLETED:42:1784955800768')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (109, 73, N'Lịch hẹn tái khám', N'Bạn có lịch hẹn tái khám vào ngày 25/07/2026.', N'REVISIT_SCHEDULED', 0, CAST(N'2026-07-25T12:03:20.870' AS DateTime), N'/patient/history/detail?id=49', N'REVISIT_SCHEDULED:42:1784912400000')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (110, 72, N'Thông tin cá nhân đã cập nhật', N'Thông tin cá nhân của bạn đã được cập nhật thành công.', N'PROFILE_UPDATE', 0, CAST(N'2026-07-25T16:01:01.307' AS DateTime), N'/settings', N'PROFILE_UPDATED:72:1784970061244')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (111, 73, N'Đặt lịch thành công', N'Lịch hẹn với BS Nội Tiết 4 lúc 16:00 25/07/2026 đã được tạo.', N'APPOINTMENT_CREATED', 0, CAST(N'2026-07-25T16:23:19.893' AS DateTime), N'/patient/appointments/detail?id=50', N'APPOINTMENT_CREATED:50')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (112, 73, N'Có hóa đơn mới', N'Hóa đơn #34 có số tiền 100000.00 đang chờ thanh toán.', N'INVOICE_CREATED', 0, CAST(N'2026-07-25T16:32:39.183' AS DateTime), N'/patient/invoices/detail?id=34', N'INVOICE_CREATED:34')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (113, 73, N'Kết quả khám bệnh', N'Bác sĩ đã hoàn tất kết quả khám và chỉ số xét nghiệm của bạn.', N'DIAGNOSIS_COMPLETED', 1, CAST(N'2026-07-25T16:35:48.203' AS DateTime), N'/patient/history/detail?id=50', N'DIAGNOSIS_COMPLETED:43:1784972148081')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (114, 73, N'Lịch hẹn tái khám', N'Bạn có lịch hẹn tái khám vào ngày 26/07/2026.', N'REVISIT_SCHEDULED', 1, CAST(N'2026-07-25T16:35:48.207' AS DateTime), N'/patient/history/detail?id=50', N'REVISIT_SCHEDULED:43:1784998800000')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (115, 76, N'Đặt lịch thành công', N'Lịch hẹn với BS Nội Tiết 4 lúc 16:00 25/07/2026 đã được tạo.', N'APPOINTMENT_CREATED', 0, CAST(N'2026-07-25T16:48:14.827' AS DateTime), N'/patient/appointments/detail?id=51', N'APPOINTMENT_CREATED:51')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1115, 76, N'Có hóa đơn mới', N'Hóa đơn #35 có số tiền 100000.00 đang chờ thanh toán.', N'INVOICE_CREATED', 0, CAST(N'2026-07-25T17:25:21.503' AS DateTime), N'/patient/invoices/detail?id=35', N'INVOICE_CREATED:35')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1116, 76, N'Kết quả khám bệnh', N'Bác sĩ đã hoàn tất kết quả khám và chỉ số xét nghiệm của bạn.', N'DIAGNOSIS_COMPLETED', 1, CAST(N'2026-07-25T17:27:32.680' AS DateTime), N'/patient/history/detail?id=51', N'DIAGNOSIS_COMPLETED:44:1784975252606')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1117, 76, N'Lịch hẹn tái khám', N'Bạn có lịch hẹn tái khám vào ngày 26/07/2026.', N'REVISIT_SCHEDULED', 0, CAST(N'2026-07-25T17:27:32.683' AS DateTime), N'/patient/history/detail?id=51', N'REVISIT_SCHEDULED:44:1784998800000')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1118, 73, N'Đặt lịch thành công', N'Lịch hẹn với BS Nội Tiết 4 lúc 16:00 25/07/2026 đã được tạo.', N'APPOINTMENT_CREATED', 1, CAST(N'2026-07-25T18:34:37.633' AS DateTime), N'/patient/appointments/detail?id=1051', N'APPOINTMENT_CREATED:1051')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1119, 73, N'Đặt lịch thành công', N'Lịch hẹn với BS Nội Tiết 1 lúc 00:08 27/07/2026 đã được tạo.', N'APPOINTMENT_CREATED', 0, CAST(N'2026-07-27T00:14:20.490' AS DateTime), N'/patient/appointments/detail?id=1052', N'APPOINTMENT_CREATED:1052')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1120, 73, N'Có hóa đơn mới', N'Hóa đơn #36 có số tiền 250000.00 đang chờ thanh toán.', N'INVOICE_CREATED', 0, CAST(N'2026-07-27T00:16:20.437' AS DateTime), N'/patient/invoices/detail?id=36', N'INVOICE_CREATED:36')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1121, 73, N'Kết quả khám bệnh', N'Bác sĩ đã hoàn tất kết quả khám và chỉ số xét nghiệm của bạn.', N'DIAGNOSIS_COMPLETED', 0, CAST(N'2026-07-27T00:22:14.650' AS DateTime), N'/patient/history/detail?id=1052', N'DIAGNOSIS_COMPLETED:45:1785086534553')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1122, 73, N'Lịch hẹn tái khám', N'Bạn có lịch hẹn tái khám vào ngày 28/07/2026.', N'REVISIT_SCHEDULED', 0, CAST(N'2026-07-27T00:22:14.657' AS DateTime), N'/patient/history/detail?id=1052', N'REVISIT_SCHEDULED:45:1785171600000')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1123, 74, N'Đặt lịch thành công', N'Lịch hẹn với BS Nội Tiết 1 lúc 00:08 27/07/2026 đã được tạo.', N'APPOINTMENT_CREATED', 0, CAST(N'2026-07-27T00:31:08.023' AS DateTime), N'/patient/appointments/detail?id=1053', N'APPOINTMENT_CREATED:1053')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1124, 74, N'Có hóa đơn mới', N'Hóa đơn #37 có số tiền 370000.00 đang chờ thanh toán.', N'INVOICE_CREATED', 0, CAST(N'2026-07-27T00:32:14.270' AS DateTime), N'/patient/invoices/detail?id=37', N'INVOICE_CREATED:37')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1125, 75, N'Đặt lịch thành công', N'Lịch hẹn với BS Nội Tiết 1 lúc 00:08 27/07/2026 đã được tạo.', N'APPOINTMENT_CREATED', 0, CAST(N'2026-07-27T01:18:10.970' AS DateTime), N'/patient/appointments/detail?id=1054', N'APPOINTMENT_CREATED:1054')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1126, 75, N'Có hóa đơn mới', N'Hóa đơn #38 có số tiền 250000.00 đang chờ thanh toán.', N'INVOICE_CREATED', 0, CAST(N'2026-07-27T01:19:36.060' AS DateTime), N'/patient/invoices/detail?id=38', N'INVOICE_CREATED:38')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1127, 73, N'Đặt lịch thành công', N'Lịch hẹn với BS Nội Tiết 2 lúc 01:25 27/07/2026 đã được tạo.', N'APPOINTMENT_CREATED', 0, CAST(N'2026-07-27T01:23:25.253' AS DateTime), N'/patient/appointments/detail?id=1055', N'APPOINTMENT_CREATED:1055')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1128, 73, N'Có hóa đơn mới', N'Hóa đơn #39 có số tiền 350000.00 đang chờ thanh toán.', N'INVOICE_CREATED', 0, CAST(N'2026-07-27T01:24:14.480' AS DateTime), N'/patient/invoices/detail?id=39', N'INVOICE_CREATED:39')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1129, 74, N'Kết quả khám bệnh', N'Bác sĩ đã hoàn tất kết quả khám và chỉ số xét nghiệm của bạn.', N'DIAGNOSIS_COMPLETED', 0, CAST(N'2026-07-27T01:32:08.273' AS DateTime), N'/patient/history/detail?id=1053', N'DIAGNOSIS_COMPLETED:46:1785090728181')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1130, 74, N'Lịch hẹn tái khám', N'Bạn có lịch hẹn tái khám vào ngày 28/07/2026.', N'REVISIT_SCHEDULED', 0, CAST(N'2026-07-27T01:32:08.277' AS DateTime), N'/patient/history/detail?id=1053', N'REVISIT_SCHEDULED:46:1785171600000')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1131, 73, N'Kết quả khám bệnh', N'Bác sĩ đã hoàn tất kết quả khám và chỉ số xét nghiệm của bạn.', N'DIAGNOSIS_COMPLETED', 0, CAST(N'2026-07-27T01:32:31.923' AS DateTime), N'/patient/history/detail?id=1055', N'DIAGNOSIS_COMPLETED:48:1785090751923')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1132, 73, N'Lịch hẹn tái khám', N'Bạn có lịch hẹn tái khám vào ngày 28/07/2026.', N'REVISIT_SCHEDULED', 0, CAST(N'2026-07-27T01:32:31.923' AS DateTime), N'/patient/history/detail?id=1055', N'REVISIT_SCHEDULED:48:1785171600000')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1133, 75, N'Kết quả khám bệnh', N'Bác sĩ đã hoàn tất kết quả khám và chỉ số xét nghiệm của bạn.', N'DIAGNOSIS_COMPLETED', 0, CAST(N'2026-07-27T01:33:51.283' AS DateTime), N'/patient/history/detail?id=1054', N'DIAGNOSIS_COMPLETED:47:1785090831222')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1134, 75, N'Đặt lịch thành công', N'Lịch hẹn với BS Nội Tiết 2 lúc 01:25 27/07/2026 đã được tạo.', N'APPOINTMENT_CREATED', 0, CAST(N'2026-07-27T01:34:20.503' AS DateTime), N'/patient/appointments/detail?id=1056', N'APPOINTMENT_CREATED:1056')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1135, 75, N'Có hóa đơn mới', N'Hóa đơn #40 có số tiền 200000.00 đang chờ thanh toán.', N'INVOICE_CREATED', 0, CAST(N'2026-07-27T01:36:07.187' AS DateTime), N'/patient/invoices/detail?id=40', N'INVOICE_CREATED:40')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1136, 75, N'Kết quả khám bệnh', N'Bác sĩ đã hoàn tất kết quả khám và chỉ số xét nghiệm của bạn.', N'DIAGNOSIS_COMPLETED', 0, CAST(N'2026-07-27T01:51:01.503' AS DateTime), N'/patient/history/detail?id=1056', N'DIAGNOSIS_COMPLETED:49:1785091861442')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1137, 74, N'Đặt lịch thành công', N'Lịch hẹn với BS Nội Tiết 2 lúc 01:25 27/07/2026 đã được tạo.', N'APPOINTMENT_CREATED', 0, CAST(N'2026-07-27T01:51:17.007' AS DateTime), N'/patient/appointments/detail?id=1057', N'APPOINTMENT_CREATED:1057')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1138, 74, N'Có hóa đơn mới', N'Hóa đơn #41 có số tiền 100000.00 đang chờ thanh toán.', N'INVOICE_CREATED', 0, CAST(N'2026-07-27T01:52:01.087' AS DateTime), N'/patient/invoices/detail?id=41', N'INVOICE_CREATED:41')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1139, 73, N'Đặt lịch thành công', N'Lịch hẹn với BS Nội Tiết 3 lúc 02:06 27/07/2026 đã được tạo.', N'APPOINTMENT_CREATED', 0, CAST(N'2026-07-27T02:06:26.617' AS DateTime), N'/patient/appointments/detail?id=1058', N'APPOINTMENT_CREATED:1058')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1140, 75, N'Đặt lịch thành công', N'Lịch hẹn với BS Nội Tiết 3 lúc 02:06 27/07/2026 đã được tạo.', N'APPOINTMENT_CREATED', 0, CAST(N'2026-07-27T02:09:51.987' AS DateTime), N'/patient/appointments/detail?id=1059', N'APPOINTMENT_CREATED:1059')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1141, 74, N'Kết quả khám bệnh', N'Bác sĩ đã hoàn tất kết quả khám và chỉ số xét nghiệm của bạn.', N'DIAGNOSIS_COMPLETED', 0, CAST(N'2026-07-27T02:14:34.390' AS DateTime), N'/patient/history/detail?id=1057', N'DIAGNOSIS_COMPLETED:50:1785093274338')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1142, 74, N'Đặt lịch thành công', N'Lịch hẹn với BS Nội Tiết 3 lúc 02:06 27/07/2026 đã được tạo.', N'APPOINTMENT_CREATED', 0, CAST(N'2026-07-27T02:14:49.710' AS DateTime), N'/patient/appointments/detail?id=1060', N'APPOINTMENT_CREATED:1060')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1143, 73, N'Có hóa đơn mới', N'Hóa đơn #43 có số tiền 100000.00 đang chờ thanh toán.', N'INVOICE_CREATED', 0, CAST(N'2026-07-27T02:28:44.230' AS DateTime), N'/patient/invoices/detail?id=43', N'INVOICE_CREATED:43')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1144, 74, N'Có hóa đơn mới', N'Hóa đơn #44 có số tiền 200000.00 đang chờ thanh toán.', N'INVOICE_CREATED', 0, CAST(N'2026-07-27T02:47:45.210' AS DateTime), N'/patient/invoices/detail?id=44', N'INVOICE_CREATED:44')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1149, 73, N'Kết quả khám bệnh', N'Bác sĩ đã hoàn tất kết quả khám và chỉ số xét nghiệm của bạn.', N'DIAGNOSIS_COMPLETED', 0, CAST(N'2026-07-27T03:19:26.280' AS DateTime), N'/patient/history/detail?id=1058', N'DIAGNOSIS_COMPLETED:51:1785097166230')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1150, 74, N'Kết quả khám bệnh', N'Bác sĩ đã hoàn tất kết quả khám và chỉ số xét nghiệm của bạn.', N'DIAGNOSIS_COMPLETED', 0, CAST(N'2026-07-27T03:19:36.820' AS DateTime), N'/patient/history/detail?id=1060', N'DIAGNOSIS_COMPLETED:53:1785097176766')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1151, 73, N'Đặt lịch thành công', N'Lịch hẹn với BS Nội Tiết 4 lúc 03:20 27/07/2026 đã được tạo.', N'APPOINTMENT_CREATED', 0, CAST(N'2026-07-27T03:19:51.050' AS DateTime), N'/patient/appointments/detail?id=1061', N'APPOINTMENT_CREATED:1061')
INSERT [dbo].[Notification] ([NotificationID], [AccountID], [Title], [Content], [Type], [IsRead], [CreatedAt], [TargetUrl], [EventKey]) VALUES (1152, 73, N'Có hóa đơn mới', N'Hóa đơn #48 có số tiền 100000.00 đang chờ thanh toán.', N'INVOICE_CREATED', 0, CAST(N'2026-07-27T03:42:15.813' AS DateTime), N'/patient/invoices/detail?id=48', N'INVOICE_CREATED:48')
SET IDENTITY_INSERT [dbo].[Notification] OFF
GO
SET IDENTITY_INSERT [dbo].[Patient] ON 

INSERT [dbo].[Patient] ([patient_id], [full_name], [date_of_birth], [gender], [phone], [email], [address], [account_id]) VALUES (18, N'Nguyễn Văn Ánh', CAST(N'2005-06-24' AS Date), N'male', N'0332255450', N'nguyenanh6868vp@gmail.com', N'Tan Xa Ha Noi Viet Nam', 73)
INSERT [dbo].[Patient] ([patient_id], [full_name], [date_of_birth], [gender], [phone], [email], [address], [account_id]) VALUES (19, N'Phan Văn Bảo Trung', CAST(N'2005-06-24' AS Date), N'male', N'0332255451', N'trungkitich1324@gmail.com', N'Nghệ An , Việt Nam', 74)
INSERT [dbo].[Patient] ([patient_id], [full_name], [date_of_birth], [gender], [phone], [email], [address], [account_id]) VALUES (20, N'Lê Trọng Nghĩa', CAST(N'2004-07-23' AS Date), N'male', N'0332255447', N'lenghia211105@gmail.com', N'Sầm Sơn , Việt Nam', 75)
INSERT [dbo].[Patient] ([patient_id], [full_name], [date_of_birth], [gender], [phone], [email], [address], [account_id]) VALUES (21, N'Trường Giang', CAST(N'2005-06-24' AS Date), N'male', N'0332255458', N'giangnt.he194257@gmail.com', N'Hà Nội', 76)
INSERT [dbo].[Patient] ([patient_id], [full_name], [date_of_birth], [gender], [phone], [email], [address], [account_id]) VALUES (1021, N'Phan Van Bao Trung', CAST(N'2006-03-02' AS Date), N'Male', N'0946477995', N'trungkitit@gmail.com', N'', 1076)
SET IDENTITY_INSERT [dbo].[Patient] OFF
GO
SET IDENTITY_INSERT [dbo].[Reception] ON 

INSERT [dbo].[Reception] ([reception_id], [full_name], [date_of_birth], [gender], [phone], [email], [address], [account_id], [desk_location]) VALUES (2, N'Nguyễn Thị Hồng Hảo', CAST(N'2005-06-22' AS Date), N'female', N'0332255452', N'letan1@gmail.com', N'Thành Phố HCM, Hà Nội', 67, NULL)
INSERT [dbo].[Reception] ([reception_id], [full_name], [date_of_birth], [gender], [phone], [email], [address], [account_id], [desk_location]) VALUES (3, N'Hà Thị Ngọc', CAST(N'2005-06-23' AS Date), N'male', N'0332255454', N'letan2@gmail.com', N'Thanh Hóa, Việt Nam', 68, NULL)
INSERT [dbo].[Reception] ([reception_id], [full_name], [date_of_birth], [gender], [phone], [email], [address], [account_id], [desk_location]) VALUES (4, N'Nguyễn Ngọc Yến', CAST(N'2004-12-30' AS Date), N'female', N'0332255455', N'letan3@gmail.com', N'Vũng Tàu, Hà Nội', 69, NULL)
SET IDENTITY_INSERT [dbo].[Reception] OFF
GO
SET IDENTITY_INSERT [dbo].[Reception_Schedule] ON 

INSERT [dbo].[Reception_Schedule] ([reception_sched_id], [reception_id], [work_date], [time_slot], [status]) VALUES (2, 3, CAST(N'2026-07-24' AS Date), N'21:20-23:00', N'Completed')
INSERT [dbo].[Reception_Schedule] ([reception_sched_id], [reception_id], [work_date], [time_slot], [status]) VALUES (6, 2, CAST(N'2026-07-25' AS Date), N'03:50-08:00', N'Completed')
INSERT [dbo].[Reception_Schedule] ([reception_sched_id], [reception_id], [work_date], [time_slot], [status]) VALUES (7, 3, CAST(N'2026-07-25' AS Date), N'10:00-14:00', N'Completed')
INSERT [dbo].[Reception_Schedule] ([reception_sched_id], [reception_id], [work_date], [time_slot], [status]) VALUES (8, 2, CAST(N'2026-07-25' AS Date), N'16:00-20:00', N'Completed')
INSERT [dbo].[Reception_Schedule] ([reception_sched_id], [reception_id], [work_date], [time_slot], [status]) VALUES (9, 4, CAST(N'2026-07-27' AS Date), N'00:15-04:00', N'Available')
SET IDENTITY_INSERT [dbo].[Reception_Schedule] OFF
GO
SET IDENTITY_INSERT [dbo].[Record_Sharing] ON 

INSERT [dbo].[Record_Sharing] ([SharingID], [Owner_AccountID], [Viewer_AccountID], [CanViewAppointments], [CanViewInvoices], [CanViewRecords], [Status], [CreatedAt], [UpdatedAt], [Initiator_AccountID]) VALUES (2, 6, 1, 1, 1, 1, N'ACCEPTED', CAST(N'2026-07-20T09:28:43.080' AS DateTime), CAST(N'2026-07-20T09:29:11.643' AS DateTime), 1)
INSERT [dbo].[Record_Sharing] ([SharingID], [Owner_AccountID], [Viewer_AccountID], [CanViewAppointments], [CanViewInvoices], [CanViewRecords], [Status], [CreatedAt], [UpdatedAt], [Initiator_AccountID]) VALUES (3, 7, 1, 0, 0, 1, N'ACCEPTED', CAST(N'2026-07-20T15:19:41.163' AS DateTime), CAST(N'2026-07-20T15:20:32.640' AS DateTime), 1)
INSERT [dbo].[Record_Sharing] ([SharingID], [Owner_AccountID], [Viewer_AccountID], [CanViewAppointments], [CanViewInvoices], [CanViewRecords], [Status], [CreatedAt], [UpdatedAt], [Initiator_AccountID]) VALUES (4, 8, 1, 0, 0, 0, N'PENDING', CAST(N'2026-07-20T16:47:39.973' AS DateTime), CAST(N'2026-07-20T16:47:39.973' AS DateTime), 1)
INSERT [dbo].[Record_Sharing] ([SharingID], [Owner_AccountID], [Viewer_AccountID], [CanViewAppointments], [CanViewInvoices], [CanViewRecords], [Status], [CreatedAt], [UpdatedAt], [Initiator_AccountID]) VALUES (5, 1, 10, 1, 1, 1, N'ACCEPTED', CAST(N'2026-07-22T21:28:00.617' AS DateTime), CAST(N'2026-07-22T21:28:22.703' AS DateTime), 10)
INSERT [dbo].[Record_Sharing] ([SharingID], [Owner_AccountID], [Viewer_AccountID], [CanViewAppointments], [CanViewInvoices], [CanViewRecords], [Status], [CreatedAt], [UpdatedAt], [Initiator_AccountID]) VALUES (6, 73, 74, 0, 1, 1, N'ACCEPTED', CAST(N'2026-07-24T20:54:00.857' AS DateTime), CAST(N'2026-07-24T20:55:27.563' AS DateTime), 74)
INSERT [dbo].[Record_Sharing] ([SharingID], [Owner_AccountID], [Viewer_AccountID], [CanViewAppointments], [CanViewInvoices], [CanViewRecords], [Status], [CreatedAt], [UpdatedAt], [Initiator_AccountID]) VALUES (7, 74, 73, 1, 0, 0, N'ACCEPTED', CAST(N'2026-07-25T00:48:32.920' AS DateTime), CAST(N'2026-07-25T00:48:45.233' AS DateTime), 74)
SET IDENTITY_INSERT [dbo].[Record_Sharing] OFF
GO
INSERT [dbo].[Room] ([room_id], [room_name], [location], [status]) VALUES (N'LAB01', N'Phòng xét nghiệm 1', N'Tầng 2 - Khu xét nghiệm', N'Active')
INSERT [dbo].[Room] ([room_id], [room_name], [location], [status]) VALUES (N'LAB02', N'Phòng xét nghiệm 2', N'Tầng 2 - Khu xét nghiệm', N'Active')
INSERT [dbo].[Room] ([room_id], [room_name], [location], [status]) VALUES (N'R101', N'Phòng Khám Nội Tiết 1', N'Tầng 1 - Khu A', N'Active')
INSERT [dbo].[Room] ([room_id], [room_name], [location], [status]) VALUES (N'R102', N'Phòng Khám Nội Tiết 2', N'Tầng 1 - Khu A', N'Active')
INSERT [dbo].[Room] ([room_id], [room_name], [location], [status]) VALUES (N'R103', N'Phòng Khám Tim Mạch 1', N'Tầng 1 - Khu A', N'Active')
INSERT [dbo].[Room] ([room_id], [room_name], [location], [status]) VALUES (N'R104', N'Phòng Khám Da Liễu 1', N'Tầng 1 - Khu B', N'Active')
INSERT [dbo].[Room] ([room_id], [room_name], [location], [status]) VALUES (N'R105', N'Quầy Lễ Tân', N'Tầng 1 - Khu B', N'Active')
INSERT [dbo].[Room] ([room_id], [room_name], [location], [status]) VALUES (N'R201', N'Phòng Khám Nội Tiết 3', N'Tầng 2 - Khu A', N'Active')
INSERT [dbo].[Room] ([room_id], [room_name], [location], [status]) VALUES (N'R202', N'Phòng Khám Nội Tiết 4', N'Tầng 2 - Khu A', N'Active')
INSERT [dbo].[Room] ([room_id], [room_name], [location], [status]) VALUES (N'R203', N'Phòng Khám Tổng Quát 8', N'Tầng 2 - Khu B', N'Inactive')
INSERT [dbo].[Room] ([room_id], [room_name], [location], [status]) VALUES (N'R204', N'Phòng Khám Tổng Quát 9', N'Tầng 2 - Khu B', N'Inactive')
INSERT [dbo].[Room] ([room_id], [room_name], [location], [status]) VALUES (N'R205', N'Phòng Khám Tổng Quát 10', N'Tầng 2 - Khu B', N'Inactive')
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UX_Account_Email]    Script Date: 7/27/2026 3:49:00 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_Account_Email] ON [dbo].[Account]
(
	[email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Appointment_Patient]    Script Date: 7/27/2026 3:49:00 AM ******/
CREATE NONCLUSTERED INDEX [IX_Appointment_Patient] ON [dbo].[Appointment]
(
	[patient_id] ASC,
	[created_at] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UX_Appointment_Queue]    Script Date: 7/27/2026 3:49:00 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_Appointment_Queue] ON [dbo].[Appointment]
(
	[schedule_id] ASC,
	[queue_number] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UX_Doctor_Account]    Script Date: 7/27/2026 3:49:00 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_Doctor_Account] ON [dbo].[Doctor]
(
	[account_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UX_DoctorAI_HealthRecord]    Script Date: 7/27/2026 3:49:00 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_DoctorAI_HealthRecord] ON [dbo].[Doctor_AI]
(
	[health_record_id] ASC
)
WHERE ([health_record_id] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UX_DoctorLab_Account]    Script Date: 7/27/2026 3:49:00 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_DoctorLab_Account] ON [dbo].[Doctor_Lab]
(
	[account_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UX_DoctorSchedule_Slot]    Script Date: 7/27/2026 3:49:00 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_DoctorSchedule_Slot] ON [dbo].[Doctor_Schedule]
(
	[doctor_id] ASC,
	[work_date] ASC,
	[time_slot] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_EmailVerification_Account_Purpose_Created]    Script Date: 7/27/2026 3:49:00 AM ******/
CREATE NONCLUSTERED INDEX [IX_EmailVerification_Account_Purpose_Created] ON [dbo].[Email_Verification]
(
	[account_id] ASC,
	[purpose] ASC,
	[created_at] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_EmailVerification_Target_Purpose_Created]    Script Date: 7/27/2026 3:49:00 AM ******/
CREATE NONCLUSTERED INDEX [IX_EmailVerification_Target_Purpose_Created] ON [dbo].[Email_Verification]
(
	[target_email] ASC,
	[purpose] ASC,
	[created_at] DESC
)
INCLUDE([account_id],[otp_hash],[expires_at],[failed_attempts],[consumed_at]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UX_HealthyRecord_Invoice]    Script Date: 7/27/2026 3:49:00 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_HealthyRecord_Invoice] ON [dbo].[Healthy_Record]
(
	[invoice_id] ASC
)
WHERE ([invoice_id] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Invoice_PatientStatus]    Script Date: 7/27/2026 3:49:00 AM ******/
CREATE NONCLUSTERED INDEX [IX_Invoice_PatientStatus] ON [dbo].[Invoice]
(
	[patient_id] ASC,
	[status] ASC,
	[created_at] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_InvoiceDetail_Appointment]    Script Date: 7/27/2026 3:49:00 AM ******/
CREATE NONCLUSTERED INDEX [IX_InvoiceDetail_Appointment] ON [dbo].[Invoice_Detail]
(
	[appointment_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_InvoiceDetail_Invoice]    Script Date: 7/27/2026 3:49:00 AM ******/
CREATE NONCLUSTERED INDEX [IX_InvoiceDetail_Invoice] ON [dbo].[Invoice_Detail]
(
	[invoice_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_InvoiceDetail_LabWorkflow]    Script Date: 7/27/2026 3:49:00 AM ******/
CREATE NONCLUSTERED INDEX [IX_InvoiceDetail_LabWorkflow] ON [dbo].[Invoice_Detail]
(
	[lab_status] ASC,
	[health_record_id] ASC,
	[doctor_id] ASC
)
INCLUDE([invoice_id],[service_id],[requested_at],[completed_at]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UQ_HealthRecord_In_Medical]    Script Date: 7/27/2026 3:49:00 AM ******/
ALTER TABLE [dbo].[Medical_record] ADD  CONSTRAINT [UQ_HealthRecord_In_Medical] UNIQUE NONCLUSTERED 
(
	[health_record_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UX_MedicalRecord_Appointment]    Script Date: 7/27/2026 3:49:00 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_MedicalRecord_Appointment] ON [dbo].[Medical_record]
(
	[appointment_id] ASC
)
WHERE ([appointment_id] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Notification_Account_Read_Created]    Script Date: 7/27/2026 3:49:00 AM ******/
CREATE NONCLUSTERED INDEX [IX_Notification_Account_Read_Created] ON [dbo].[Notification]
(
	[AccountID] ASC,
	[IsRead] ASC,
	[CreatedAt] DESC,
	[NotificationID] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UX_Notification_Account_EventKey]    Script Date: 7/27/2026 3:49:00 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_Notification_Account_EventKey] ON [dbo].[Notification]
(
	[AccountID] ASC,
	[EventKey] ASC
)
WHERE ([EventKey] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Patient_Phone]    Script Date: 7/27/2026 3:49:00 AM ******/
CREATE NONCLUSTERED INDEX [IX_Patient_Phone] ON [dbo].[Patient]
(
	[phone] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UX_Patient_Account]    Script Date: 7/27/2026 3:49:00 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_Patient_Account] ON [dbo].[Patient]
(
	[account_id] ASC
)
WHERE ([account_id] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UQ_Owner_Viewer]    Script Date: 7/27/2026 3:49:00 AM ******/
ALTER TABLE [dbo].[Record_Sharing] ADD  CONSTRAINT [UQ_Owner_Viewer] UNIQUE NONCLUSTERED 
(
	[Owner_AccountID] ASC,
	[Viewer_AccountID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
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
ALTER TABLE [dbo].[Email_Verification] ADD  DEFAULT ((0)) FOR [failed_attempts]
GO
ALTER TABLE [dbo].[Email_Verification] ADD  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[Healthy_Record] ADD  CONSTRAINT [DF_HealthyRecord_StatusV2]  DEFAULT ('Pending_Payment') FOR [status]
GO
ALTER TABLE [dbo].[Healthy_Record] ADD  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[Healthy_Record] ADD  CONSTRAINT [DF_HealthyRecord_AutoSync]  DEFAULT ((1)) FOR [is_synced_automatically]
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
ALTER TABLE [dbo].[Record_Sharing] ADD  DEFAULT ((0)) FOR [CanViewAppointments]
GO
ALTER TABLE [dbo].[Record_Sharing] ADD  DEFAULT ((0)) FOR [CanViewInvoices]
GO
ALTER TABLE [dbo].[Record_Sharing] ADD  DEFAULT ((0)) FOR [CanViewRecords]
GO
ALTER TABLE [dbo].[Record_Sharing] ADD  DEFAULT ('PENDING') FOR [Status]
GO
ALTER TABLE [dbo].[Record_Sharing] ADD  DEFAULT (getdate()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[Record_Sharing] ADD  DEFAULT (getdate()) FOR [UpdatedAt]
GO
ALTER TABLE [dbo].[Room] ADD  DEFAULT ('Active') FOR [status]
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
ALTER TABLE [dbo].[Doctor_AI]  WITH CHECK ADD  CONSTRAINT [FK_DoctorAI_HealthyRecord] FOREIGN KEY([health_record_id])
REFERENCES [dbo].[Healthy_Record] ([health_record_id])
GO
ALTER TABLE [dbo].[Doctor_AI] CHECK CONSTRAINT [FK_DoctorAI_HealthyRecord]
GO
ALTER TABLE [dbo].[Doctor_Lab]  WITH NOCHECK ADD  CONSTRAINT [FK_DoctorLab_Account] FOREIGN KEY([account_id])
REFERENCES [dbo].[Account] ([account_id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Doctor_Lab] NOCHECK CONSTRAINT [FK_DoctorLab_Account]
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
ALTER TABLE [dbo].[Email_Verification]  WITH NOCHECK ADD  CONSTRAINT [FK_EmailVerification_Account] FOREIGN KEY([account_id])
REFERENCES [dbo].[Account] ([account_id])
GO
ALTER TABLE [dbo].[Email_Verification] NOCHECK CONSTRAINT [FK_EmailVerification_Account]
GO
ALTER TABLE [dbo].[Healthy_Record]  WITH NOCHECK ADD  CONSTRAINT [FK_HealthyRecord_Invoice] FOREIGN KEY([invoice_id])
REFERENCES [dbo].[Invoice] ([invoice_id])
GO
ALTER TABLE [dbo].[Healthy_Record] NOCHECK CONSTRAINT [FK_HealthyRecord_Invoice]
GO
ALTER TABLE [dbo].[Healthy_Record]  WITH NOCHECK ADD  CONSTRAINT [FK_HealthyRecord_MedicalRecord] FOREIGN KEY([record_id])
REFERENCES [dbo].[Medical_record] ([record_id])
GO
ALTER TABLE [dbo].[Healthy_Record] NOCHECK CONSTRAINT [FK_HealthyRecord_MedicalRecord]
GO
ALTER TABLE [dbo].[Healthy_Record]  WITH NOCHECK ADD  CONSTRAINT [FK_HealthyRecord_Patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[Patient] ([patient_id])
GO
ALTER TABLE [dbo].[Healthy_Record] NOCHECK CONSTRAINT [FK_HealthyRecord_Patient]
GO
ALTER TABLE [dbo].[Invoice]  WITH NOCHECK ADD  CONSTRAINT [FK_Invoice_Patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[Patient] ([patient_id])
GO
ALTER TABLE [dbo].[Invoice] NOCHECK CONSTRAINT [FK_Invoice_Patient]
GO
ALTER TABLE [dbo].[Invoice]  WITH NOCHECK ADD  CONSTRAINT [FK_Invoice_Receptionist] FOREIGN KEY([receptionist_id])
REFERENCES [dbo].[Account] ([account_id])
GO
ALTER TABLE [dbo].[Invoice] NOCHECK CONSTRAINT [FK_Invoice_Receptionist]
GO
ALTER TABLE [dbo].[Invoice_Detail]  WITH NOCHECK ADD  CONSTRAINT [FK_InvoiceDetail_Appointment] FOREIGN KEY([appointment_id])
REFERENCES [dbo].[Appointment] ([appointment_id])
GO
ALTER TABLE [dbo].[Invoice_Detail] NOCHECK CONSTRAINT [FK_InvoiceDetail_Appointment]
GO
ALTER TABLE [dbo].[Invoice_Detail]  WITH NOCHECK ADD  CONSTRAINT [FK_InvoiceDetail_Doctor] FOREIGN KEY([doctor_id])
REFERENCES [dbo].[Doctor] ([doctor_id])
GO
ALTER TABLE [dbo].[Invoice_Detail] NOCHECK CONSTRAINT [FK_InvoiceDetail_Doctor]
GO
ALTER TABLE [dbo].[Invoice_Detail]  WITH NOCHECK ADD  CONSTRAINT [FK_InvoiceDetail_HealthRecord] FOREIGN KEY([health_record_id])
REFERENCES [dbo].[Healthy_Record] ([health_record_id])
GO
ALTER TABLE [dbo].[Invoice_Detail] NOCHECK CONSTRAINT [FK_InvoiceDetail_HealthRecord]
GO
ALTER TABLE [dbo].[Invoice_Detail]  WITH NOCHECK ADD  CONSTRAINT [FK_InvoiceDetail_Invoice] FOREIGN KEY([invoice_id])
REFERENCES [dbo].[Invoice] ([invoice_id])
GO
ALTER TABLE [dbo].[Invoice_Detail] NOCHECK CONSTRAINT [FK_InvoiceDetail_Invoice]
GO
ALTER TABLE [dbo].[Invoice_Detail]  WITH NOCHECK ADD  CONSTRAINT [FK_InvoiceDetail_Service] FOREIGN KEY([service_id])
REFERENCES [dbo].[Medical_Service] ([service_id])
GO
ALTER TABLE [dbo].[Invoice_Detail] NOCHECK CONSTRAINT [FK_InvoiceDetail_Service]
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
ALTER TABLE [dbo].[Medical_record]  WITH NOCHECK ADD  CONSTRAINT [fk_medical_record_doctor] FOREIGN KEY([doctor_id])
REFERENCES [dbo].[Doctor] ([doctor_id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Medical_record] NOCHECK CONSTRAINT [fk_medical_record_doctor]
GO
ALTER TABLE [dbo].[Medical_record]  WITH NOCHECK ADD  CONSTRAINT [fk_medical_record_patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[Patient] ([patient_id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Medical_record] NOCHECK CONSTRAINT [fk_medical_record_patient]
GO
ALTER TABLE [dbo].[Medical_record]  WITH NOCHECK ADD  CONSTRAINT [FK_MedicalRecord_Appointment] FOREIGN KEY([appointment_id])
REFERENCES [dbo].[Appointment] ([appointment_id])
GO
ALTER TABLE [dbo].[Medical_record] NOCHECK CONSTRAINT [FK_MedicalRecord_Appointment]
GO
ALTER TABLE [dbo].[Medical_record]  WITH NOCHECK ADD  CONSTRAINT [FK_MedicalRecord_HealthyRecord] FOREIGN KEY([health_record_id])
REFERENCES [dbo].[Healthy_Record] ([health_record_id])
GO
ALTER TABLE [dbo].[Medical_record] NOCHECK CONSTRAINT [FK_MedicalRecord_HealthyRecord]
GO
ALTER TABLE [dbo].[Notification]  WITH CHECK ADD  CONSTRAINT [FK_Notification_Account] FOREIGN KEY([AccountID])
REFERENCES [dbo].[Account] ([account_id])
GO
ALTER TABLE [dbo].[Notification] CHECK CONSTRAINT [FK_Notification_Account]
GO
ALTER TABLE [dbo].[Patient]  WITH NOCHECK ADD  CONSTRAINT [FK_Patient_Account] FOREIGN KEY([account_id])
REFERENCES [dbo].[Account] ([account_id])
GO
ALTER TABLE [dbo].[Patient] NOCHECK CONSTRAINT [FK_Patient_Account]
GO
ALTER TABLE [dbo].[Reception]  WITH CHECK ADD  CONSTRAINT [FK_Reception_Account] FOREIGN KEY([account_id])
REFERENCES [dbo].[Account] ([account_id])
GO
ALTER TABLE [dbo].[Reception] CHECK CONSTRAINT [FK_Reception_Account]
GO
ALTER TABLE [dbo].[Reception_Schedule]  WITH CHECK ADD  CONSTRAINT [FK_Reception_Schedule_Reception] FOREIGN KEY([reception_id])
REFERENCES [dbo].[Reception] ([reception_id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Reception_Schedule] CHECK CONSTRAINT [FK_Reception_Schedule_Reception]
GO
ALTER TABLE [dbo].[Record_Sharing]  WITH NOCHECK ADD  CONSTRAINT [FK_Sharing_Initiator] FOREIGN KEY([Initiator_AccountID])
REFERENCES [dbo].[Account] ([account_id])
GO
ALTER TABLE [dbo].[Record_Sharing] NOCHECK CONSTRAINT [FK_Sharing_Initiator]
GO
ALTER TABLE [dbo].[Record_Sharing]  WITH NOCHECK ADD  CONSTRAINT [FK_Sharing_Owner] FOREIGN KEY([Owner_AccountID])
REFERENCES [dbo].[Account] ([account_id])
GO
ALTER TABLE [dbo].[Record_Sharing] NOCHECK CONSTRAINT [FK_Sharing_Owner]
GO
ALTER TABLE [dbo].[Record_Sharing]  WITH NOCHECK ADD  CONSTRAINT [FK_Sharing_Viewer] FOREIGN KEY([Viewer_AccountID])
REFERENCES [dbo].[Account] ([account_id])
GO
ALTER TABLE [dbo].[Record_Sharing] NOCHECK CONSTRAINT [FK_Sharing_Viewer]
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
ALTER TABLE [dbo].[Appointment]  WITH CHECK ADD  CONSTRAINT [CK_Appointment_Status] CHECK  (([status]='Cancelled' OR [status]='Absent' OR [status]='Completed' OR [status]='In_Progress' OR [status]='Checked_In' OR [status]='Waiting' OR [status]='Accepted'))
GO
ALTER TABLE [dbo].[Appointment] CHECK CONSTRAINT [CK_Appointment_Status]
GO
ALTER TABLE [dbo].[Doctor_Schedule]  WITH CHECK ADD  CONSTRAINT [CK_DoctorSchedule_MaxPatients] CHECK  (([max_patients]>(0)))
GO
ALTER TABLE [dbo].[Doctor_Schedule] CHECK CONSTRAINT [CK_DoctorSchedule_MaxPatients]
GO
ALTER TABLE [dbo].[Doctor_Schedule]  WITH CHECK ADD  CONSTRAINT [CK_DoctorSchedule_Status] CHECK  (([status]='Pending' OR [status]='Available' OR [status]='Full' OR [status]='Cancelled' OR [status]='Expired'))
GO
ALTER TABLE [dbo].[Doctor_Schedule] CHECK CONSTRAINT [CK_DoctorSchedule_Status]
GO
ALTER TABLE [dbo].[Invoice]  WITH NOCHECK ADD  CONSTRAINT [CK_Invoice_PaymentMethod] CHECK  (([payment_method] IS NULL OR ([payment_method]='Bank_Transfer' OR [payment_method]='VNPay' OR [payment_method]='Momo' OR [payment_method]='Cash')))
GO
ALTER TABLE [dbo].[Invoice] NOCHECK CONSTRAINT [CK_Invoice_PaymentMethod]
GO
ALTER TABLE [dbo].[Invoice]  WITH NOCHECK ADD  CONSTRAINT [CK_Invoice_Status] CHECK  (([status]='Paid' OR [status]='Pending'))
GO
ALTER TABLE [dbo].[Invoice] NOCHECK CONSTRAINT [CK_Invoice_Status]
GO
ALTER TABLE [dbo].[Invoice_Detail]  WITH NOCHECK ADD  CONSTRAINT [CK_InvoiceDetail_LabStatus] CHECK  (([lab_status] IS NULL OR ([lab_status]='Cancelled' OR [lab_status]='Completed' OR [lab_status]='Processing' OR [lab_status]='Requested' OR [lab_status]='Waiting_Payment')))
GO
ALTER TABLE [dbo].[Invoice_Detail] NOCHECK CONSTRAINT [CK_InvoiceDetail_LabStatus]
GO
ALTER TABLE [dbo].[Invoice_Detail]  WITH NOCHECK ADD  CONSTRAINT [CK_InvoiceDetail_Price] CHECK  (([price]>=(0)))
GO
ALTER TABLE [dbo].[Invoice_Detail] NOCHECK CONSTRAINT [CK_InvoiceDetail_Price]
GO
ALTER TABLE [dbo].[Invoice_Detail]  WITH NOCHECK ADD  CONSTRAINT [CK_InvoiceDetail_Quantity] CHECK  (([quantity]>(0)))
GO
ALTER TABLE [dbo].[Invoice_Detail] NOCHECK CONSTRAINT [CK_InvoiceDetail_Quantity]
GO
ALTER TABLE [dbo].[Lab_Schedule]  WITH CHECK ADD  CONSTRAINT [CK_LabSchedule_Status] CHECK  (([status]='Completed' OR [status]='Cancelled' OR [status]='Full' OR [status]='Available'))
GO
ALTER TABLE [dbo].[Lab_Schedule] CHECK CONSTRAINT [CK_LabSchedule_Status]
GO
ALTER TABLE [dbo].[Medical_Service]  WITH NOCHECK ADD  CONSTRAINT [CK_MedicalService_Price] CHECK  (([price]>=(0)))
GO
ALTER TABLE [dbo].[Medical_Service] NOCHECK CONSTRAINT [CK_MedicalService_Price]
GO
ALTER TABLE [dbo].[Medical_Service]  WITH NOCHECK ADD  CONSTRAINT [CK_MedicalService_Status] CHECK  (([status]='Inactive' OR [status]='Active'))
GO
ALTER TABLE [dbo].[Medical_Service] NOCHECK CONSTRAINT [CK_MedicalService_Status]
GO
ALTER TABLE [dbo].[Medical_Service]  WITH NOCHECK ADD  CONSTRAINT [CK_MedicalService_Type] CHECK  (([service_type]='Lab_Test' OR [service_type]='Examination'))
GO
ALTER TABLE [dbo].[Medical_Service] NOCHECK CONSTRAINT [CK_MedicalService_Type]
GO
ALTER TABLE [dbo].[Reception_Schedule]  WITH CHECK ADD  CONSTRAINT [CK_ReceptionSchedule_Status] CHECK  (([status]='Completed' OR [status]='Cancelled' OR [status]='Available'))
GO
ALTER TABLE [dbo].[Reception_Schedule] CHECK CONSTRAINT [CK_ReceptionSchedule_Status]
GO
ALTER TABLE [dbo].[Record_Sharing]  WITH NOCHECK ADD  CONSTRAINT [CHK_NotSelfSharing] CHECK  (([Owner_AccountID]<>[Viewer_AccountID]))
GO
ALTER TABLE [dbo].[Record_Sharing] NOCHECK CONSTRAINT [CHK_NotSelfSharing]
GO
USE [master]
GO
ALTER DATABASE [Project] SET  READ_WRITE 
GO
