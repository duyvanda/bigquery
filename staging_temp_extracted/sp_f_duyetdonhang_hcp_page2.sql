-- ==========================================================================
-- Routine Name : sp_f_duyetdonhang_hcp_page2
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2026-04-14 04:26:21.294000+00:00
-- Last Altered : 2026-04-14 04:26:21.294000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_duyetdonhang_hcp_page2()
BEGIN

TRUNCATE TABLE staging_temp.f_duyetdonhang_hcp_page2_temp;
INSERT INTO staging_temp.f_duyetdonhang_hcp_page2_temp(

with data_duyet as (
select
ordernbr,
CAST(NULL AS STRING) AS ordernbr_co,   -- Ép kiểu STRING để không bị lỗi INT64
CAST(NULL AS STRING) AS status_pda_so, -- Tương tự cho các cột NULL khác
trangthai_hoadon as status_iv,
trangthai_donhang as status_so,
lupd_user as nguoiduyetdon,
lupd_datetime as ngayduyetdon,
CAST(NULL AS STRING) as slsperid_pda_so,
invtid,
tensp as tensp_viettat,
lineref,
channel,
shoptype,
custid,
custname as tenkhachhang,
territorydescr,
statedescr,
ma_nvbh as ma_nv_pda_sod,
sum(thanhtien_truocthue) as doanhsochuavat,
sum(lineqty) as soluong
from `spatial-vision-343005.warehouse.f_trangthaidonhang_new` a --warehouse.f_leadtime_new_detail1 a
WHERE (
    -- Khối điều kiện xử lý thời gian và user
    (lupd_datetime >= '2026-01-01' AND lupd_datetime < '2026-04-01' AND lupd_user = 'MR0292')
    OR
    (lupd_datetime >= '2026-04-01' AND lupd_user IN ('MR0292', 'DHNO'))
)
-- Khối điều kiện về trạng thái áp dụng chung
AND LOWER(trangthai_hoadon) = 'đã phát hành'
AND LOWER(trangthai_donhang) = 'đã duyệt đơn hàng'
-- LEFT JOIN `staging.d_master_khachhang` b on
-- a.custid = b.custid
-- where (ngaytaodon >='2023-03-01'  and status_pda_so ='Đã duyệt đơn hàng' and ordernbr_co <>'Hủy HĐ' and nguoiduyetdon in ('Đỗ Thị Hồng Thủy' )
-- and ( ( ngayduyetdon >='2023-03-01' and ngayduyetdon <'2023-07-08') or ngayduyetdon >='2023-07-16') ---24/7 Chí Tâm update k tính doanh số duyệt đơn từ 8-7 đến 15-7
-- and b.channel in ('INS','CLC'))
-- or (
--   ngaytaodon >='2023-10-01'  and status_pda_so ='Đã duyệt đơn hàng' and ordernbr_co <>'Hủy HĐ' and nguoiduyetdon in ('Lương Tấn Khả' )
-- and b.channel in ('INS','CLC')
-- )
-- or (
--   ngaytaodon >='2023-09-01'  and status_pda_so ='Đã duyệt đơn hàng' and ordernbr_co <>'Hủy HĐ' and nguoiduyetdon in ('Lê Thị Ngọc Anh')
-- )
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18
),
pda_sod as
(
  select distinct ordernbr,invtid,lineref,slsperid from `staging.sync_dms_pda_sod`
)

select a.*,b.tencvbh,b.tenquanlytt as tenquanlytt,b.supid as macrm,ma_nv_pda_sod as slsperid
from data_duyet a
LEFT JOIN `staging.d_users_bytime` b on a.ma_nv_pda_sod = b.manv and date_trunc(a.ngayduyetdon,month) = b.thang

  );

Create or replace table `warehouse.f_duyetdonhang_hcp_page2`

copy `staging_temp.f_duyetdonhang_hcp_page2_temp`;

End;
