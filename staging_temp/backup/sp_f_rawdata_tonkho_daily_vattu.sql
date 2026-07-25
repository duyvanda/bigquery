CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_rawdata_tonkho_daily_vattu()
BEGIN
TRUNCATE TABLE staging_temp.f_rawdata_tonkho_daily_vattu_temp;
INSERT INTO staging_temp.f_rawdata_tonkho_daily_vattu_temp(

-- Create or replace table staging_temp.f_rawdata_tonkho_daily_vattu_temp
-- partition by date(ngay_capture)
-- as
SELECT
  branchid,
            Case
            when branchid in('MR0001', 'HCM001') then 'HCM'
            when branchid = 'MR0003' then 'HÀ NỘI'
            when branchid in('MR0014', 'KHA014') then 'KHÁNH HÒA'
            when branchid in('MR0015', 'DNI015') then 'ĐỒNG NAI'
            when branchid = 'MR0011' then 'HẢI PHÒNG'
            when branchid in('MR0012', 'NAN012') then 'NGHỆ AN'
            when branchid in('MR0010', 'HNI010') then 'HÀ NỘI'
            when branchid in('MR0013', 'DNG013') then 'ĐÀ NẴNG'
            when branchid in('MR0016', 'CTO016') then 'CẦN THƠ'
            when branchid in ('HYN017') then 'NM'
            ELSE branchname
        END AS chinhanh,
  branchname,
  siteid as makho,
  tenkho,
  invtid,
  tensanpham,
  tenspviettat,
  lotsernbr,
  expdate,
  toncuoi,
  sltreohoadonao,
  sltreochuataohoadon,
  toncuoisosach,
  created_date as ngay_capture
FROM `spatial-vision-343005.staging.f_sc_daily_raw_invt`
where created_date >='2024-01-01'and (invtid like 'V%' or invtid like 'D%' or invtid ='E0111088')
and created_date = (select max(created_date) FROM `spatial-vision-343005.staging.f_sc_daily_raw_invt` )

);
Create or replace table `warehouse.f_rawdata_tonkho_daily_vattu`

copy `staging_temp.f_rawdata_tonkho_daily_vattu_temp`;

End;