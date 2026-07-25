CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_baocao_phanbothau()
BEGIN 
 
-- TRUNCATE TABLE staging_temp.f_baocao_phanbothau_temp;

-- INSERT INTO `staging_temp.f_baocao_phanbothau_temp`

Create or replace table `warehouse.sp_f_baocao_phanbothau` as
(


-- as

SELECT a.* ,
  b.custname,
  b.statedescr,
  b.channel,
  b.shoptype,
    case when DATE(d.startdate) <= '2023-03-06' then 'PHA NAM'
         when ((DATE(d.startdate) >= '2023-03-07' and DATE(d.startdate) <= '2023-11-30') and trim(f.phaply) = 'PN') then 'PHA NAM'
         when ((DATE(d.startdate) >= '2023-03-07' and DATE(d.startdate) <= '2023-11-30') and trim(f.phaply) = 'MR') then 'MERAP'
         ELSE 'MERAP' END as phaply,
  c.descr as tensanpham,
  c.tendonvitinhleviethoa,
  a.contractprice / (case when c.invtid ='EH126' THEN 20 ELSE c.donvitinhle end) as contractprice_le, 
  a.qty * (case when c.invtid ='EH126' THEN 20 ELSE c.donvitinhle end) as qty_le,
  d.contractorid,
  d.unitcode,
  d.supid,
  d.qlkv
FROM `spatial-vision-343005.staging.d_contractorallocate` a
left join `spatial-vision-343005.staging.d_master_khachhang` b on a.custid = b.custid
left join `spatial-vision-343005.staging.d_dms_master_invtid` c on a.invtid = c.invtid
left join `spatial-vision-343005.warehouse.sp_f_baocao_ketquatrungthau` d on a.noticenbr = d.noticenbr and a.invtid = d.invtid
left join `spatial-vision-343005.staging.d_tinh` e on b.statedescr = e.tinh
left join `spatial-vision-343005.staging.chuanhoa_phaply_dmtt` f on e.tinhviethoa = trim(f.tinh) and a.noticenbr = trim(f.so_ttqd_trungthau) --- Phong mail ngày 2/12/23


);

-- Create or replace table `warehouse.sp_f_baocao_phanbothau`

-- copy `staging_temp.f_baocao_phanbothau_temp`;

END;