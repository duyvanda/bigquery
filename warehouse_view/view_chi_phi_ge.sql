CREATE VIEW `spatial-vision-343005.warehouse.view_chi_phi_ge`
AS /*
ở lần quét một - ưu tiên quét bộ phận quản lý theo danh mục tài sản cố định thì anh thêm điều kiện chỉ áp dụng với các trường hợp có tài khoản đối ứng là (left(th.ma_tk1,3)='214' or left(th.ma_tk1,3)='242') thôi nhé
*/

with bp1 as

(
  select makhoanmuc, bophan, kenhtong, bophanquanly  from `spatial-vision-343005.staging.d_ge_bpql`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY makhoanmuc, bophan, kenhtong ) = 1

)
,

bp2 as

(
  select makhoanmuc, bophan, bophanquanly  from `spatial-vision-343005.staging.d_ge_bpql`
  where kenhtong is null
  QUALIFY ROW_NUMBER() OVER (PARTITION BY makhoanmuc, bophan ) = 1

)

, bp3 as

(
  select makhoanmuc, bophanquanly from `spatial-vision-343005.staging.d_ge_bpql`
  -- where kenhtong is null
  QUALIFY ROW_NUMBER() OVER (PARTITION BY makhoanmuc ) = 1

)


SELECT
cp.idtscd,
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
cp.khoanmuc,
teneng,
cp.makmchung,
cp.tenkmchung,
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
    IFNULL(
            IFNULL(bp0.bophanquanly, bp1.bophanquanly)
            ,bp2.bophanquanly
          )
          ,bp3.bophanquanly
          )
  ,cp.bophan
) 

as bpquanlycp,
bp0.bophanquanly as bophanquanly_tscd,
bp1.bophanquanly as bophanquanly_1,
bp2.bophanquanly as bophanquanly_2,
bp3.bophanquanly as bophanquanly_3,
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

--DK0
LEFT JOIN `spatial-vision-343005.staging.d_ge_tscd` bp0 on
(
CASE 
WHEN LEFT(trim(tkco),3) = '242' then cp.idtscd
WHEN LEFT(trim(tkco),3) = '214' then cp.idtscd
else null
END
)

= cast(bp0.idtscd as STRING)

--DK1
LEFT JOIN bp1 on
cp.makm = bp1.makhoanmuc and cp.bophan = bp1.bophan and cp.kenhtong = bp1.kenhtong

--DK2
LEFT JOIN bp2 on
-- cp.kenhtong is null and
-- and bp1.bophanquanly is null
cp.makm = bp2.makhoanmuc and cp.bophan = bp2.bophan

--DK3
LEFT JOIN bp3 on
-- cp.bophan is null and
-- and bp1.bophanquanly is null
cp.makm = bp3.makhoanmuc

where date(ngaychungtu)>= '2023-01-01' 
-- and date(ngaychungtu)<= '2024-04-30'  and makmchung = 'KM042'
-- and sochungtu = 'PK2401-027';