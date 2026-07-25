CREATE FUNCTION `spatial-vision-343005`.staging_temp.fun_get_xeploai_phanloai(diem_xeploai_quy FLOAT64) RETURNS STRING
AS (
CASE
    WHEN diem_xeploai_quy < 2 THEN 'Cần hoàn thiện'
    WHEN diem_xeploai_quy >= 2 AND diem_xeploai_quy < 3 THEN 'Đạt yêu cầu'
    WHEN diem_xeploai_quy >= 3 AND diem_xeploai_quy < 4 THEN 'Khá'
    WHEN diem_xeploai_quy >= 4 AND diem_xeploai_quy < 5 THEN 'Tốt'  -- again, <5
    WHEN diem_xeploai_quy >= 5 THEN 'Xuất sắc'
    ELSE NULL
  END
);