CREATE PROCEDURE `spatial-vision-343005`.staging_temp.f_ge_chiphi()
BEGIN 
TRUNCATE TABLE staging_temp.f_ge_chiphi_temp;
INSERT INTO staging_temp.f_ge_chiphi_temp
(
-- Create or replace table `staging_temp.f_ge_chiphi_temp`
-- as

SELECT 
  sochungtu,
  ngayht,
  ngaychungtu,
  ngayhd,
  sohd,
  vat,
  tkno,
  tkco,
  psno,
  psco,
  tienvat,
  tongtien,
  makm,
  khoanmuc,
  teneng,
  makmchung,
  tenkmchung,
  tenchungeng,
  makmlion,
  tenkmlion,
  ghichulion,
  ghichu,
  ghichunoibo,
  diengiaichitiet,
  htcc,
  kenhpp,
  kenhphu,
  cp.kenhtong,
  cp.bophan,
  IFNULL(
  IFNULL(
  IFNULL(bp1.bophanquanly, bp2.bophanquanly),
  bp3.bophanquanly
  ),
  cp.bophan
  ) as bpquanlycp,
  maspcu,
  tensp,
  soluong,
  team,	
  sup,
  asm,
  rsm,	
  khuvuc,
  tinh,	
  macsm,	
  tendtcnnb,	
  cayql,	
  matscd,	
  tentscd,	
  vungdl

FROM `spatial-vision-343005.staging.f_ge_chi_phi` cp
--DK1
LEFT JOIN `spatial-vision-343005.staging.d_ge_bpql` bp1 on
cp.kenhtong is not null
and cp.makm = bp1.makhoanmuc and cp.bophan = bp1.bophan and cp.kenhtong = bp1.kenhtong

--DK2
LEFT JOIN `spatial-vision-343005.staging.d_ge_bpql` bp2 on
cp.kenhtong is null
-- and bp1.bophanquanly is null
and cp.makm = bp2.makhoanmuc and cp.bophan = bp2.bophan and cp.kenhtong = bp2.kenhtong

--DK3
LEFT JOIN `spatial-vision-343005.staging.d_ge_bpql` bp3 on
cp.bophan is null
-- and bp1.bophanquanly is null
and cp.makm = bp3.makhoanmuc

where date(ngaychungtu)>= '2024-01-01'

);

Create or replace table `warehouse.f_ge_chiphi`

copy `staging_temp.f_ge_chiphi_temp`;

End;