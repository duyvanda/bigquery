CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_solieu_vanhanh_giaohang_bang_oto()
BEGIN 
TRUNCATE TABLE staging_temp.f_solieu_vanhanh_giaohang_bang_oto_temp;

INSERT INTO staging_temp.f_solieu_vanhanh_giaohang_bang_oto_temp
(

-- Create or replace table staging_temp.f_solieu_vanhanh_giaohang_bang_oto_temp
-- partition by date(ngayphathanhhd)
-- as

select a.*except(thongtinxe),
  b.tram,
  c.gtype,
  trim(a.thongtinxe) as thongtinxe
  -- case when trim(a.thongtinxe)  = 	'DNI-51C-62637 (600kg)-GHTT'	then 	'PNHCM-51C-62637 (600kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'CTO-51C-62637 (600kg)-GHTT'	then 	'PNHCM-51C-62637 (600kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'PNHCM-51C-62637 (600kg)-GHTT'	then 	'PNHCM-51C-62637 (600kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'DNI-51D-65828 (1000kg)-GHTT'	then 	'PNHCM-51D-65828 (1000kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'PNHCM-51D-65828 (1000kg)-GHTT'	then 	'PNHCM-51D-65828 (1000kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'DNG-51D-785.42(900kg)-GHTT'	then 	'PNDNG-51D-78542 (900kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'DNG-51D-785.42 (900kg)-GHTT'	then 	'PNDNG-51D-78542 (900kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'PNHN-29C-80049 (1050kg)-GHTT'	then 	'PNHNI-29C-80049 (1050kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'HNI-29C-80049 (1050kg)-GHTT'	then 	'PNHNI-29C-80049 (1050kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'CTO-51D-02012 (900kg)-GHTT'	then 	'PNHCM-51D-02012 (900kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'HCM001-51D-02012 (900kg)-GHTT'	then 	'PNHCM-51D-02012 (900kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'HCM-51D-02012 (900kg)-GHTT'	then 	'PNHCM-51D-02012 (900kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'PNHCM-51D-02012 (900kg)-GHTT'	then 	'PNHCM-51D-02012 (900kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'KHA -50LD-21315(945kg)-GHTT'	then 	'PNKHA-50LD-21315(945kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'KHA-50LD-21315(945kg)-GHTT'	then 	'PNKHA-50LD-21315(945kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'PNKH-50LD-21315 (945kg)-GHTT'	then 	'PNKHA-50LD-21315(945kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'HCM-51C-20031 (1100kg)-GHTT'	then 	'PNHCM-51C-20031 (1100kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'PNHCM-51C-20031 (1100kg)-GHTT'	then 	'PNHCM-51C-20031 (1100kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'PNDNI-60D-00698 (900kg)-GHTT'	then 	'PNDNI-51D-78152 (782kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'PNĐNI-60D-00698 (900kg)-GHTT'	then 	'PNDNI-51D-78152 (782kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'DNI-51D-78152 (782kg)-GHTT'	then 	'PNDNI-51D-78152 (782kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'PNNA-37D-02246 (600kg)-GHTT'	then 	'PNNAN-29D-55219 (600kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'NAN-37D-02246 (600kg)-GHTT'	then 	'PNNAN-29D-55219 (600kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'PNHN -29D-04683 (600kg)-GHTT'	then 	'PNHN-29D-04683 (600kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'PNHN-29D-04683 (600kg)-GHTT'	then 	'PNHN-29D-04683 (600kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'HNI-29D-04683 (600kg)-GHTT'	then 	'PNHN-29D-04683 (600kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'KHA-51D-783.43(782kg)-GHTT'	then 	'PNKHA-51D-78343(782kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'HCM-51D-783.43(782kg)-GHTT'	then 	'PNKHA-51D-78343(782kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'PNHCM-51D-02122 (900kg)-GHTT'	then 	'PNHCM-51D-02122 (900kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'NAN-29D-55219 (600kg)-GHTT'	then 	'PNNAN-29D-55219 (600kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'PNDNG-43D-00298 (900kg)-GHTT'	then 	'DNG-51D-78542 (900kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'HCM-50LD-21118 (945kg)-GHTT'	then 	'PNHCM-50LD-21118 (945kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'CTO-65D-00299 (600kg)-GHTT'	then 	'PNCTO-65D-00299 (600kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'PNCT-65D-00299 (600kg)-GHTT'	then 	'PNCTO-65D-00299 (600kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'DNI-51D-781.52 (782kg)-GHTT'	then 	'PNDNI-51D-78152 (782kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'PNKH-79D-00185 (800kg)-GHTT'	then 	'PNKHA-51D-78343(782kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'PNKH-79D-001.85 (900kg) - GHTT'	then 	'PNKHA-51D-78343(782kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'CTO-50LD-21299 (945kg)-GHTT'	then 	'PNCTO-50LD-21299 (945kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'PNCT-50LD-21299 (945kg)-GHTT'	then 	'PNCTO-50LD-21299 (945kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'HNI-50LD-21145 (945kg)-GHTT'	then 	'PNHNI-50LD-21145 (945kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'PNHN-50LD-21145 (945kg)-GHTT'	then 	'PNHNI-50LD-21145 (945kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'CTO-51D-785.51 (600kg)-GHTT'	then 	'PNCTO-51D-78551 (600kg)-GHTT'
  --     when trim(a.thongtinxe)  = 	'DNI-50LD-21307 (945kg)-GHTT'	then 	'PNDNI-50LD-21307 (945kg)-GHTT'
  --     else trim(a.thongtinxe) end as thongtinxe

from `spatial-vision-343005.warehouse.f_overview_mds_hanh1` a 
left join `spatial-vision-343005.staging.d_tinh` b  on b.tinh = a.tinh 
left join  `staging.d_master_khachhang`c on a.custid = c.custid
-- left join  `staging.d_xetai_chinhanhlog`d on trim(a.thongtinxe) = trim(d.thongtinxe)
-- where a.thongtinxe in  ( "PNHN-29C-80049 (1050kg)-GHTT",
-- "PNHCM-51D-02122 (900kg)-GHTT",
-- "PNDNI-60D-00698 (900kg)-GHTT",
-- "PNĐNI-60D-00698 (900kg)-GHTT",
-- "PNNA-37D-02246 (600kg)-GHTT",
-- "PNHCM-51D-65828 (1000kg)-GHTT",
-- "PNDNG-43D-00298 (900kg)-GHTT",
-- "PNKH-79D-001.85 (900kg) - GHTT",
-- "PNHN-29D-04683 (600kg)-GHTT",
-- " PNHCM-51C-20031 (1100kg)-GHTT ",
-- "PNHCM-51C-62637 (600kg)-GHTT",
-- "PNCT-65D-00299 (600kg)-GHTT",
-- "PNHCM-51D-02012 (900kg)-GHTT",
-- "PNKH-79D-00185 (800kg)-GHTT")


);

Create or replace table `warehouse.f_solieu_vanhanh_giaohang_bang_oto`

copy `staging_temp.f_solieu_vanhanh_giaohang_bang_oto_temp`;

End;