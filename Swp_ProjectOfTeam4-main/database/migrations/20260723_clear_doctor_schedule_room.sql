-- Migration: Xoa thong tin phong khoi lich truc bac si
-- Khong xoa cot room_id, khong them cot moi
-- Chi cap nhat gia tri ve NULL vi UI khong con dung room_id nua
-- Date: 2026-07-23

USE [Project];
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- Dat room_id = NULL cho TAT CA lich truc bac si hien co
UPDATE [dbo].[Doctor_Schedule]
SET    [room_id] = NULL;
GO

PRINT N'Migration hoan thanh: room_id da duoc xoa khoi tat ca lich truc bac si.';
GO
