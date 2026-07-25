CREATE FUNCTION `spatial-vision-343005`.staging_temp.fun_get_xeploai_abc(diem_xeploai_quy FLOAT64) RETURNS STRING
AS (
CASE
    WHEN diem_xeploai_quy < 2 THEN 'C'
    WHEN diem_xeploai_quy >= 2 AND diem_xeploai_quy < 3 THEN 'B'
    WHEN diem_xeploai_quy >= 3 AND diem_xeploai_quy < 4 THEN 'A2'
    WHEN diem_xeploai_quy >= 4 AND diem_xeploai_quy < 4.5 THEN 'A1'
    WHEN diem_xeploai_quy >= 4.5 THEN 'A'
    ELSE NULL
  END
);