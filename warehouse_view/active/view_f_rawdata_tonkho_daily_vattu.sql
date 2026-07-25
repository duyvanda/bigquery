CREATE VIEW `spatial-vision-343005.warehouse.view_f_rawdata_tonkho_daily_vattu`
AS SELECT 
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
  a.invtid,
  tensanpham,
  tenspviettat,
  lotsernbr,
  ifnull(gia_gom_vat, giaban) as giaban,
  IFNULL (i.danhmucsanpham, d.phan_loai) as phan_loai,
  d.thue_xuat,
  expdate,
  toncuoi,
  sltreohoadonao,
  sltreochuataohoadon,
  toncuoisosach,
  created_date as ngay_capture,


FROM `spatial-vision-343005.staging.f_sc_daily_raw_invt` a
LEFT JOIN `staging.d_gia_von_vttd`  d on d.ma_sp = a.invtid
LEFT JOIN `staging.d_dms_master_invtid`  i on i.invtid = a.invtid
where date(created_date) between date(datetime_sub(current_datetime("+7"),interval 1 month)) and current_date("+7") 
and lower(i.classid) in ('vattu','gimmick')
QUALIFY DENSE_RANK() OVER (PARTITION BY date(created_date) ORDER BY created_date DESC) = 1;