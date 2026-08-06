-- ==========================================================================
-- Routine Name : sp_f_lichsuduyetdon_thieuhang
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2025-02-06 06:42:18.704000+00:00
-- Last Altered : 2025-02-06 06:42:18.704000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_lichsuduyetdon_thieuhang()
BEGIN

TRUNCATE TABLE staging_temp.f_lichsuduyetdon_thieuhang_temp;
INSERT INTO staging_temp.f_lichsuduyetdon_thieuhang_temp
(

-- Create or replace table staging_temp.f_lichsuduyetdon_thieuhang_temp
-- partition by date(crtd_datetime)
-- as
with thieuhang as
(
  with bang1 as
  (
    select
      branchid,
      ordernbr,
      errormessage,
      lupd_datetime,
      row_number() over (partition by ordernbr order by lupd_datetime desc) as loc
      from  `spatial-vision-343005.staging.sync_dms_err`
      where errormessage like '%Không Đủ Tồn Kho Cho Sản Phẩm%'
  )
    select *
    from bang1
    where
    loc = 1
)
, vuong_no as

(
      select
      branchid,
      ordernbr,
      -- errormessage,
      -- lupd_datetime,
      row_number() over (partition by ordernbr, branchid order by lupd_datetime desc) as loc
      from  `spatial-vision-343005.staging.sync_dms_err`
      where errormessage like '%Khách Hàng Có Nợ%'
      QUALIFY loc = 1
)
, dataset as
(
  select
    a.branchid,
    c.branchname,
    a.ordernbr,
    a.errormessage,
    case when b.status = 'C' then b.approvaldate
    else null
    end as lupd_datetime,
    b.custid,
    b.remark,
    b.remark_km,
    b.crtd_datetime,
    b.inserted_at,
    b.status,
    c.custname,
    c.batchexpform,
    c.statedescr,
    c.channel,
    c.shoptype,
    c.territorydescr,
    d.chinhanh as chinhan_vatly,
    e.invtid,
    f.descr as tensp,
    case when g.ordernbr is null then 'n' else 'y' end as co_vuong_no,
    REGEXP_EXTRACT_ALL(a.errormessage, r' (OH.+?) Trong Kho') AS OHname,
    REGEXP_EXTRACT_ALL(a.errormessage, r' (EH.+?) Trong Kho') AS EHname,
    REGEXP_EXTRACT_ALL(a.errormessage, r' (T3.+?) Trong Kho') AS Tname,
    sum(e.lineqty) as lineqty,
    sum(e.beforevatamount) as beforevatamount,
    FROM thieuhang a
    left join `spatial-vision-343005.staging.sync_dms_pda_so` b on a.ordernbr = b.ordernbr and a.branchid = b.branchid
    left join `spatial-vision-343005.staging.d_master_khachhang` c on b.custid = c.custid
    left join `spatial-vision-343005.staging.d_tinh` d on c.statedescr = d.tinh
    left join `spatial-vision-343005.staging.sync_dms_pda_sod` e on a.ordernbr = e.ordernbr and a.branchid = e.branchid
    left join  `spatial-vision-343005.staging.d_dms_master_invtid` f on e.invtid = f.invtid
    LEFT JOIN vuong_no g on g.ordernbr = a.ordernbr and g.branchid = a.branchid

    where b.ordertype = 'IN' AND b.status not in ('X','E')
    group by all
),
-- Khi post trong trong giờ hành chính từ 2-7 chia ra làm 2 TH
-- TH1 : Nếu duyệt trong ngày tạo thì giữ nguyên
-- TH2 : Nếu duyệt khác ngày thì chia làm 2 đoạn tính (1+2):
-- 1- Tính ngày duyệt đến 17h , ngày tạo giữ nguyên
-- 2- chuyển ngày tạo đơn qua 7h30 ngày hôm sau và ngày duyệt tính đến khi hoàn thành
check_ngay_tao_duyet as (
select
*,
if(date(crtd_datetime) = date(lupd_datetime),'Y','N') as is_check_tao_duyet,
case when branchid in ('NAN012','KHA014','HYN017','HNI010','HCM001','DNI015','DNG013','CTO016') then 'MERAP'
ELSE 'PHA NAM' end as phapnhan
from dataset
),
--Convert ngày tạo
phanloai_ngaytao as (
select *,
Case
  --Chủ nhật tính qua 7h30 ngày hôm sau
  when extract(dayofweek from crtd_datetime) = 1 then 'CN - Ngày tạo chuyển đến 7h30 ngày hôm sau'
  --Post đơn từ 2-7 trước 7h30 thì tính là 7h30
  when extract(dayofweek from crtd_datetime) in (2,3,4,5,6,7) and timestamp( date(crtd_datetime) + interval 450 minute ) > timestamp(crtd_datetime) then 'T2-7 0h-7h30 - Ngày tạo chuyển đến 7h30'

  --TH1 Post đơn từ 2-6 từ 7h30 ->16h30
  when extract(dayofweek from crtd_datetime) in (2,3,4,5,6) and timestamp( date(crtd_datetime) + interval 450 minute ) <= timestamp(crtd_datetime) and
       timestamp( date(crtd_datetime) + interval 990 minute ) > timestamp(crtd_datetime) and is_check_tao_duyet ='Y' then 'T2-6 7h30-16h30 TH1'
  --TH2 Post đơn từ 2-6 từ 7h30 ->16h30
  when extract(dayofweek from crtd_datetime) in (2,3,4,5,6) and timestamp( date(crtd_datetime) + interval 450 minute ) <= timestamp(crtd_datetime) and
       timestamp( date(crtd_datetime) + interval 990 minute ) > timestamp(crtd_datetime) and is_check_tao_duyet ='N' then 'T2-6 7h30-16h30 TH2'
  --Post đơn từ 2-6 sau 16h30 mà ngày duyệt trong ngày thì giữ nguyên
  when extract(dayofweek from crtd_datetime) in (2,3,4,5,6) and timestamp( date(crtd_datetime) + interval 990 minute ) <= timestamp(crtd_datetime) and is_check_tao_duyet ='Y' then 'T2-6 >16h30 Ngày tạo giữ nguyên'
  --Post đơn từ 2-6 sau 16h30 mà ngày duyệt khác ngày thì chuyển ngày tạo sang 7h30 hôm sau
  when extract(dayofweek from crtd_datetime) in (2,3,4,5,6) and timestamp( date(crtd_datetime) + interval 990 minute ) <= timestamp(crtd_datetime) and is_check_tao_duyet ='N'
        then 'T2-6 >16h30  Ngày tạo chuyển đến 7h30 ngày hôm sau'

  --TH1 Post đơn thứ 7 từ 7h30 ->11h30
  when extract(dayofweek from crtd_datetime) in (7) and timestamp( date(crtd_datetime) + interval 450 minute ) <= timestamp(crtd_datetime) and
       timestamp( date(crtd_datetime) + interval 690 minute ) > timestamp(crtd_datetime) and is_check_tao_duyet ='Y' then 'T7 7h30-11h30 TH1'
  --TH2 Post đơn thứ 7 từ 7h30 ->11h30
  when extract(dayofweek from crtd_datetime) in (7) and timestamp( date(crtd_datetime) + interval 450 minute ) <= timestamp(crtd_datetime) and
       timestamp( date(crtd_datetime) + interval 690 minute ) > timestamp(crtd_datetime) and is_check_tao_duyet ='N' then 'T7 7h30-11h30 TH2'
  --Post đơn từ thứ 7 sau 11h30 mà ngày duyệt trong ngày thì giữ nguyên
  when extract(dayofweek from crtd_datetime) in (7) and timestamp( date(crtd_datetime) + interval 690 minute ) <= timestamp(crtd_datetime) and is_check_tao_duyet ='Y' then 'T7 >11h30 Ngày tạo giữ nguyên'
  --Post đơn thứ 7 sau 11h30 mà ngày duyệt khác ngày thì chuyển ngày tạo sang 7h30 hôm t2
  when extract(dayofweek from crtd_datetime) in (7) and timestamp( date(crtd_datetime) + interval 690 minute ) <= timestamp(crtd_datetime) and is_check_tao_duyet ='N'
        then 'T7 >11h30  Ngày tạo chuyển đến 7h30 ngày hôm T2'

else null end as phanloai_crtd,
 from check_ngay_tao_duyet

),
result as (
select
*,
Case
  when phanloai_crtd = 'CN - Ngày tạo chuyển đến 7h30 ngày hôm sau' then datetime_diff(datetime(lupd_datetime),datetime(date(crtd_datetime) + interval 450 minute +interval 1 day),hour)

  when phanloai_crtd = 'T2-7 0h-7h30 - Ngày tạo chuyển đến 7h30' then datetime_diff(datetime(lupd_datetime),datetime(date(crtd_datetime) + interval 450 minute),hour)

  when phanloai_crtd = 'T2-6 7h30-16h30 TH1' then datetime_diff(datetime(lupd_datetime),datetime(crtd_datetime),hour)

  when phanloai_crtd = 'T2-6 7h30-16h30 TH2' then datetime_diff(datetime(date(crtd_datetime)+ interval 1020 minute),datetime(crtd_datetime),hour) +
                  datetime_diff(datetime(lupd_datetime),datetime(date(crtd_datetime) + interval 450 minute +interval 1 day),hour)

  when phanloai_crtd = 'T2-6 >16h30 Ngày tạo giữ nguyên' then datetime_diff(datetime(lupd_datetime),datetime(crtd_datetime),hour)
  when phanloai_crtd = 'T2-6 >16h30  Ngày tạo chuyển đến 7h30 ngày hôm sau' then datetime_diff(datetime(lupd_datetime),datetime(date(crtd_datetime) + interval 450 minute +interval 1 day),hour)

  when phanloai_crtd = 'T7 7h30-11h30 TH1' then datetime_diff(datetime(lupd_datetime),datetime(crtd_datetime),hour)

  when phanloai_crtd = 'T7 7h30-11h30 TH2' then datetime_diff(datetime(date(crtd_datetime)+ interval 720 minute),datetime(crtd_datetime),hour) +
                  datetime_diff(datetime(lupd_datetime),datetime(date(crtd_datetime) + interval 450 minute +interval 2 day),hour)

  when phanloai_crtd = 'T7 >11h30 Ngày tạo giữ nguyên' then datetime_diff(datetime(lupd_datetime),datetime(crtd_datetime),hour)
  when phanloai_crtd = 'T7 >11h30  Ngày tạo chuyển đến 7h30 ngày hôm T2' then datetime_diff(datetime(lupd_datetime),datetime(date(crtd_datetime) + interval 450 minute +interval 2 day),hour)

else null end as so_gio
  from phanloai_ngaytao
)

select *except(so_gio), if(so_gio <0,0,so_gio) as so_gio  from result

);

Create or replace table `warehouse.f_lichsuduyetdon_thieuhang`

copy `staging_temp.f_lichsuduyetdon_thieuhang_temp`;

End;
