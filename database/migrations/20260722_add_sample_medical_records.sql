-- Script thêm dữ liệu mẫu vào bảng Medical_record với các ngày tái khám tương đối (dùng DATEADD)
-- Thích hợp để chạy thử nghiệm tính năng chọn ngày và tính năng nhắc hẹn tự động trước 2 ngày.

INSERT INTO [dbo].[Medical_record] (
    [patient_id], 
    [doctor_id], 
    [final_diagnosis], 
    [doctor_note], 
    [health_record_id], 
    [result_visibility], 
    [processed_at], 
    [appointment_id], 
    [laboratory_test_types], 
    [laboratory_total_price], 
    [revisit_date]
) VALUES 
-- === 3 mẫu về lịch tái khám NGÀY HÔM QUA (-1 ngày kể từ lúc chạy script) ===
(1, 2, N'Tiền tiểu đường - Theo dõi định kỳ', N'Bệnh nhân cần tăng cường vận động.', NULL, 1, GETDATE(), NULL, NULL, NULL, CAST(DATEADD(day, -1, GETDATE()) AS DATE)),
(2, 5, N'Đái tháo đường tuýp 2 giai đoạn ổn định', N'Chỉ số đường huyết đã giảm, tiếp tục duy trì liều thuốc.', NULL, 1, GETDATE(), NULL, NULL, NULL, CAST(DATEADD(day, -1, GETDATE()) AS DATE)),
(3, 6, N'Rối loạn lipid máu', N'Hạn chế đồ chiên xào, uống thuốc mỡ máu đầy đủ.', NULL, 1, GETDATE(), NULL, NULL, NULL, CAST(DATEADD(day, -1, GETDATE()) AS DATE)),

-- === 2 mẫu về lịch tái khám NGÀY HÔM NAY (0 ngày kể từ lúc chạy script) ===
(1, 2, N'Theo dõi đái tháo đường thai kỳ', N'Ăn uống lành mạnh, chia nhỏ bữa ăn.', NULL, 1, GETDATE(), NULL, NULL, NULL, CAST(GETDATE() AS DATE)),
(4, 5, N'Tiền tiểu đường tiến triển', N'Cần tuân thủ nghiêm ngặt đơn thuốc.', NULL, 1, GETDATE(), NULL, NULL, NULL, CAST(GETDATE() AS DATE)),

-- === 3 mẫu về lịch tái khám NGÀY MAI (+1 ngày kể từ lúc chạy script) ===
(2, 5, N'Đái tháo đường biến chứng nhẹ', N'Khám mắt định kỳ, kiểm tra bàn chân hàng ngày.', NULL, 1, GETDATE(), NULL, NULL, NULL, CAST(DATEADD(day, 1, GETDATE()) AS DATE)),
(3, 6, N'Tăng huyết áp kèm đái tháo đường', N'Theo dõi huyết áp hàng ngày tại nhà.', NULL, 1, GETDATE(), NULL, NULL, NULL, CAST(DATEADD(day, 1, GETDATE()) AS DATE)),
(5, 7, N'Bình thường - Đã kiểm soát tốt đường huyết', N'Duy trì chế độ ăn và sinh hoạt hiện tại.', NULL, 1, GETDATE(), NULL, NULL, NULL, CAST(DATEADD(day, 1, GETDATE()) AS DATE));
