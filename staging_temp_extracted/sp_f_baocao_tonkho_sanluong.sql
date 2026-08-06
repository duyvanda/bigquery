-- ==========================================================================
-- Routine Name : sp_f_baocao_tonkho_sanluong
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2024-06-05 06:24:46.393000+00:00
-- Last Altered : 2024-06-05 06:24:46.393000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_baocao_tonkho_sanluong()
BEGIN
TRUNCATE TABLE staging_temp.f_baocao_tonkho_sanluong_temp;
 INSERT INTO staging_temp.f_baocao_tonkho_sanluong_temp(

-- Create or replace table staging_temp.f_baocao_tonkho_sanluong_temp
-- partition by ngaychungtu
-- cluster by makhdms,channel,makho,tentinhkh
-- as
SELECT
  DATE(t1.ngaychungtu) AS ngaychungtu,
  t1.sodondathang,
  t1.makho,
  t1.tenkho,
  t1.masanpham,
  t1.tensanphamnb,
  t1.tensanphamviettat,
  t1.tenquanlytt,
  t1.makhdms,
  b.custname as tenkhachhang,
  b.channel,
  b.shoptype as makenhphu,
  b.shoptypedescr as tenkenhphu,
  b.classid as phanhanghco,
  b.statedescr as tentinhkh,
  b.shortterritorydescr as tenkhuvuc,
  t1.solo,
  t2.expdate,
  SUM(soluong) AS soluong,
  max(t1.inserted_at) as inserted_at
FROM
  `spatial-vision-343005.staging.f_sales` t1
  LEFT JOIN `staging.d_master_khachhang` b on t1.makhdms =b.custid
  left join `spatial-vision-343005.staging.sync_dms_lt` t2 on t1.macongtycn = t2.branchid and t1.lineref =t2.omlineref and t1.mahd = t2.ordernbr and t1.solo = t2.lotsernbr
where
  ngaychungtu >='2024-01-01'
  and LEFT(masanpham,1) != 'V'
  AND makenhkh not in ('NB','OTH_LAB')
  group by all

  );

Create or replace table `warehouse.f_baocao_tonkho_sanluong`

copy `staging_temp.f_baocao_tonkho_sanluong_temp`;

End;
