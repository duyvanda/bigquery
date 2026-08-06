-- ==========================================================================
-- Routine Name : sp_f_baocao_trangthaidonhang_p2
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2023-07-14 08:18:04.763000+00:00
-- Last Altered : 2023-07-14 08:18:04.763000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_baocao_trangthaidonhang_p2()
BEGIN
  TRUNCATE TABLE staging_temp.f_baocao_trangthaidonhang_p2_temp;

 INSERT INTO staging_temp.f_baocao_trangthaidonhang_p2_temp(

-- Create table staging_temp.f_baocao_trangthaidonhang_p2_temp
-- partition by date(ngaytaodon)
-- as
with result as (
select
distinct a.ordernbr,
a.ngaytaodon,
Case
  WHEN a.channel in ('INS','CLC','PCL') THEN 'HCP'
  when (a.shoptype = 'PK') then 'HCP'
  WHEN (a.shoptype in ('PMC','SI23','CTD','SI','NT')) THEN 'TP'
  when (a.channel = 'DLPP') THEN 'TP'
  WHEN a.shoptype in ('NTC','CCD','CVS','CHUOI') THEN 'MT'
  ELSE a.channel end as channel,
-- a.channel,
a.shoptype,
a.custid,
c.custname,
a.ngayduyetdon,
a.branchid,
a.branchname,
a.status_pda_so,
a.status_iv,
a.status_so,
a.status_ib,
a.status_dv,
a.trangthaidon,
a.check_sot,
a.inserted_at,
b.errormessage,
a.nguoiduyetdon,
c.batchexpform,
c.territorydescr,
c.statedescr,
case when a.status_pda_so = 'Đã duyệt đơn hàng' and (a.status_dv not in ('Đã giao hàng', 'Không tiếp tục giao hàng') or a.status_dv is null) then a.ordernbr else null end as daduyetdh,
case when a.status_pda_so != 'Đã duyệt đơn hàng' and (a.status_dv not in ('Đã giao hàng', 'Không tiếp tục giao hàng') or a.status_dv is null) then a.ordernbr else null end as chuaduyetdh,
case when a.status_pda_so != 'Đã duyệt đơn hàng' and b.errormessage like '%Không Đủ Tồn Kho Cho Sản Phẩm%' then a.ordernbr else null end as chuaduyetthieuhang,
case when a.status_pda_so != 'Đã duyệt đơn hàng' and b.errormessage like '%Có Nợ Quá Hạn Hoặc Vượt Hạn Mức Nợ%' then a.ordernbr else null end as chuaduyetvuongno,
case when a.status_pda_so = 'Đơn hàng tạm' and (b.errormessage not like '%Có Nợ Quá Hạn Hoặc Vượt Hạn Mức Nợ%' and b.errormessage not like '%Không Đủ Tồn Kho Cho Sản Phẩm%' or b.errormessage is null) then a.ordernbr else null end as chuaduyetdontam,
case when a.status_pda_so = 'Chờ xử lý duyệt đơn hàng' and (b.errormessage not like '%Có Nợ Quá Hạn Hoặc Vượt Hạn Mức Nợ%' and b.errormessage not like '%Không Đủ Tồn Kho Cho Sản Phẩm%' or b.errormessage is null) and c.batchexpform = 'LT' then a.ordernbr else null end as chuaduyet_lotien,
case when a.status_pda_so = 'Chờ xử lý duyệt đơn hàng' and (b.errormessage not like '%Có Nợ Quá Hạn Hoặc Vượt Hạn Mức Nợ%' and b.errormessage not like '%Không Đủ Tồn Kho Cho Sản Phẩm%' or b.errormessage is null) and c.batchexpform !='LT' and a.channel = 'INS'  then a.ordernbr else null end as chuaduyet_ins,
case when a.status_pda_so = 'Chờ xử lý duyệt đơn hàng' and (b.errormessage not like '%Có Nợ Quá Hạn Hoặc Vượt Hạn Mức Nợ%' and b.errormessage not like '%Không Đủ Tồn Kho Cho Sản Phẩm%' or b.errormessage is null) and a.channel != 'INS' and c.batchexpform != 'LT' then a.ordernbr else null end as chuaduyetdonkhac,
case when a.status_pda_so = 'Đã duyệt đơn hàng' and a.status_ib ='Đã chốt sổ' then a.ordernbr else null end as dachotso,
case when a.status_pda_so = 'Đã duyệt đơn hàng' and (a.status_ib !='Đã chốt sổ' or a.status_ib is null) then a.ordernbr else null end as chuachotso,
datetime (current_datetime("+7")) as today,
DATETIME_DIFF (datetime (current_datetime("+7")),datetime (a.ngaytaodon),hour) as gio_tuluctaodon,
case
when a.status_pda_so = 'Đã duyệt đơn hàng' and a.status_ib ='Đã chốt sổ' and DATETIME_DIFF (datetime (current_datetime("+7")),datetime (a.ngaytaodon),hour) <= 48 then 'Trong 48H'
when a.status_pda_so = 'Đã duyệt đơn hàng' and a.status_ib ='Đã chốt sổ' and (DATETIME_DIFF (datetime (current_datetime("+7")),datetime (a.ngaytaodon),hour) > 48 and DATETIME_DIFF (datetime (current_datetime("+7")),datetime (a.ngaytaodon),hour) <= 72) then 'Từ 48H - 72H'
when a.status_pda_so = 'Đã duyệt đơn hàng' and a.status_ib ='Đã chốt sổ' and DATETIME_DIFF (datetime (current_datetime("+7")),datetime (a.ngaytaodon),hour) > 72  then 'Quá 72H'
else null
end as phanloaigio_dachotso,
case
when a.status_pda_so = 'Đã duyệt đơn hàng' and (a.status_ib !='Đã chốt sổ' or a.status_ib is null) and DATETIME_DIFF (datetime (current_datetime("+7")),datetime (a.ngaytaodon),hour) <= 48 then 'Trong 48H'
when a.status_pda_so = 'Đã duyệt đơn hàng' and (a.status_ib !='Đã chốt sổ' or a.status_ib is null) and (DATETIME_DIFF (datetime (current_datetime("+7")),datetime (a.ngaytaodon),hour) > 48 and DATETIME_DIFF (datetime (current_datetime("+7")),datetime (a.ngaytaodon),hour) <= 72) then 'Từ 48H - 72H'
when a.status_pda_so = 'Đã duyệt đơn hàng' and (a.status_ib !='Đã chốt sổ' or a.status_ib is null) and DATETIME_DIFF (datetime (current_datetime("+7")),datetime (a.ngaytaodon),hour) > 72  then 'Quá 72H'
else null
end as phanloaigio_chuachotso,
FROM `spatial-vision-343005.warehouse.f_leadtime_new_detail1`  a
left join `spatial-vision-343005.staging.sync_dms_err` b on a.ordernbr = b.ordernbr and a.branchid =b.branchid
left join `spatial-vision-343005.staging.d_master_khachhang` c on a.custid = c.custid

where
-- (a.status_dv not in ('Đã giao hàng', 'Không tiếp tục giao hàng') or a.status_dv is null) and
 a.status_pda_so not in ('Đóng đơn hàng tạm','Đóng đơn hàng')
and a.channel not in ('OTH_LAB','NB')
-- and a.trangthaidon not in ('Đóng đơn hàng','Hủy hóa đơn')
)

-- select ordernbr,branchid ,count(distinct status_pda_so) as dem from result group by 1,2 having dem >1
select * from result
 );

Create or replace table `warehouse.f_baocao_trangthaidonhang_p2`

copy `staging_temp.f_baocao_trangthaidonhang_p2_temp`;

End;
