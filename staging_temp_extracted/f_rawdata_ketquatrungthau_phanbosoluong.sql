-- ==========================================================================
-- Routine Name : f_rawdata_ketquatrungthau_phanbosoluong
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2024-08-15 06:11:33.559000+00:00
-- Last Altered : 2024-08-15 06:11:33.559000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.f_rawdata_ketquatrungthau_phanbosoluong()
BEGIN

--  TRUNCATE TABLE staging_temp.f_rawdata_ketquatrungthau_phanbosoluong_temp;
--  INSERT INTO `staging_temp.f_rawdata_ketquatrungthau_phanbosoluong_temp`
Create or replace table `warehouse.f_rawdata_ketquatrungthau_phanbosoluong`
as

(

SELECT
a.*except(contractprice_le,qty_le,custid,custname),
a.qty_le as sl_chua_phanbo_le,
a.contractprice_le as giatrungthau_chua_phanbo_le,
b.custid,
b.custname,
b.qty_le as sl_phanbo_le,
b.contractprice_le as giatrungthau_phanbo_le,
FROM `spatial-vision-343005.warehouse.sp_f_baocao_ketquatrungthau` a
left join `spatial-vision-343005.warehouse.sp_f_baocao_phanbothau` b on a.unitcode = b.unitcode and a.noticenbr = b.noticenbr and a.invtid = b.invtid

);

-- Create or replace table `warehouse.f_rawdata_ketquatrungthau_phanbosoluong`
-- copy `staging_temp.f_rawdata_ketquatrungthau_phanbosoluong_temp`;
END;
