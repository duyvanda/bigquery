-- ==========================================================================
-- Routine Name : sp_f_duyetdonhang_hcp
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2026-06-23 02:59:38.394000+00:00
-- Last Altered : 2026-06-23 02:59:38.394000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_duyetdonhang_hcp()
BEGIN
TRUNCATE TABLE staging_temp.f_duyetdonhang_hcp_temp;
INSERT INTO staging_temp.f_duyetdonhang_hcp_temp(

with
data_mapping as

(
SELECT
        CAST(THANG as date) as thang,
        msnvcsmmoi as macrm,
        hovatenfullname as tenquanlytt
    FROM `spatial-vision-343005.staging.d_hr_dsns_bytime`
    WHERE phongdeptsummary = 'HCP'
    AND (chucdanhengtitlesum LIKE '%CRM%' OR chucdanhengtitlesum LIKE '%CRD%')
    AND msnvcsmmoi not in ('MR0123', 'MR1650') -- loại vì thưởng doanh thu không áp dụng cho N.CRM
),
data_doanhthu as (
SELECT
  date(date_trunc(ngaythu_ge,month)) as thang,
  macrm as ma_crm,
  tenquanlytt,
  sum(case when phanloai_no='Nợ xanh' then sotien else 0 end) as no_xanh,
  sum(case when phanloai_no='Nợ vàng' then sotien else 0 end) as no_vang,
  sum(case when phanloai_no='Nợ đỏ' then sotien else 0 end) as no_do,
  sum(case when phanloai_no='Nợ đen' then sotien else 0 end) as no_den,
FROM
  `warehouse.f_doanhthu_hcp_crm`
WHERE
  -- tenquanlytt in ('Lâm Văn Cảnh','Phan Thị Bình Khê') and
  ngaythu_ge>='2023-01-01' and channels in ('CLC','INS')
  group by 1,2,3
  order by thang
),
doanhthu_mapping as (
 select
 ifnull(a.thang,b.thang) as thang ,
 ifnull(b.ma_crm,a.macrm) as macrm,
 ifnull(b.tenquanlytt,a.tenquanlytt) as tenquanlytt,
 b.no_xanh,
 b.no_vang,
 b.no_do,
 b.no_den,
 from data_doanhthu b
 FULL JOIN  data_mapping a  on a.thang = b.thang and a.macrm  =b.ma_crm
 where  ifnull(a.thang,b.thang)>='2023-01-01'

),
result_doanhthu as (
 select a.*,
 Case when a.macrm in ('MR0081','MR1137') then sum(b.no_xanh) over (partition by a.thang) else
 b.no_xanh end  as no_xanh_sub1,
Case when a.macrm in ('MR0081','MR1137') then sum(b.no_vang) over (partition by a.thang) else
 b.no_vang end as no_vang_sub1,
 Case when a.macrm in ('MR0081','MR1137') then sum(b.no_do) over (partition by a.thang) else
 b.no_do end as no_do_sub1,
 Case when a.macrm in ('MR0081','MR1137') then sum(b.no_den) over (partition by a.thang) else
 b.no_den end as no_den_sub1,
 Case when a.macrm in ('MR0081','MR1137') then round( (sum(b.no_do +  b.no_den) over (partition by a.thang) ) *40/100,1) else
 round((b.no_do +  b.no_den ) *20/100,1) end as dinhmuc_duyetdon
 from doanhthu_mapping a
LEFT JOIN doanhthu_mapping b on a.thang = date_add(b.thang,interval 1 month) and a.macrm =b.macrm
order by thang
),
data_duyetdon as
 (
   select
   --date(ngayduyetdon) as ngayduyetdon,
   date_trunc(date(ngayduyetdon),month) as thang,macrm, tenquanlytt,sum(doanhsochuavat) as doanhsochuavat,count(distinct ordernbr) as sl_dh
    from `warehouse.f_duyetdonhang_hcp_page2`
   where --channel  in ('CLC','PCL','INS') and
   (ngayduyetdon >='2023-01-01' and ngayduyetdon <'2023-07-08') or ngayduyetdon >='2023-07-16'  ---24/07 Chí Tâm lưu ý k tính định mức duyệt đơn từ 8/7-15-7
  --  and tenquanlytt in ('Lâm Văn Cảnh','Phan Thị Bình Khê')
   group by 1,2,3
  --  order by ngayduyetdon
 ),
result as (
 select
 ifnull(a.thang,b.thang) as thang,
 extract(quarter from ifnull(a.thang,b.thang)) || extract(year from ifnull(a.thang,b.thang)) as quy,
 ifnull(b.macrm,'') as macrm,
  Case when b.macrm like '%MR1681%' then 'Bùi Hữu Toàn(KN)' else
  ifnull(a.tenquanlytt,b.tenquanlytt) end as tenquanlytt,
 b.dinhmuc_duyetdon,
 avg(b.dinhmuc_duyetdon) over(partition by b.macrm,b.thang) - sum(ifnull(doanhsochuavat,0)) over(partition by b.macrm,a.thang)  as dinhmuc_duyetdon_conlai,
 Case when b.macrm in ('MR0081','MR1137') then sum(b.no_xanh) over (partition by ifnull(a.thang,b.thang)) else b.no_xanh end as no_xanh,
 Case when b.macrm in ('MR0081','MR1137') then sum(b.no_vang) over (partition by ifnull(a.thang,b.thang)) else b.no_vang end as no_vang,
 Case when b.macrm in ('MR0081','MR1137') then sum(b.no_do) over (partition by ifnull(a.thang,b.thang)) else b.no_do end as no_do,
 Case when b.macrm in ('MR0081','MR1137') then sum(b.no_den) over (partition by ifnull(a.thang,b.thang)) else b.no_den end as no_den,
 b.no_xanh_sub1,
 b.no_vang_sub1,
 b.no_do_sub1,
 b.no_den_sub1,
 Case
 when  b.macrm in ('MR0081_KN','MR1137_KN','KN1137') then 0
-- 1. Áp dụng cho giai đoạn MỚI (Từ ngày 01/03/2026 trở đi)
 when COALESCE(a.thang, b.thang) >= DATE '2026-03-01' then
        Case
          when b.macrm in ('MR0081','MR1137') then
          ROUND( SAFE_DIVIDE(SUM(b.no_xanh) OVER (PARTITION BY COALESCE(a.thang, b.thang)) * 0.6, 100)
          + SAFE_DIVIDE(SUM(b.no_vang) OVER (PARTITION BY COALESCE(a.thang, b.thang)) * 0.6, 100)
          + SAFE_DIVIDE(SUM(b.no_do) OVER (PARTITION BY COALESCE(a.thang, b.thang)) * 0.5, 100)
          + SAFE_DIVIDE(SUM(b.no_den) OVER (PARTITION BY COALESCE(a.thang, b.thang)) * 0.5, 100), 1 )
          else ROUND(SAFE_DIVIDE((b.no_xanh * 0.6 + b.no_vang * 0.6 + b.no_do * 0.5 + b.no_den * 0.5 ), 100), 1)
        end
    -- 2. Áp dụng cho giai đoạn CŨ (Trước ngày 01/03/2026)
  else
        Case
          when b.macrm in('MR0081','MR1137') then
            round( sum(b.no_xanh) over (partition by ifnull(a.thang,b.thang)) *0.25 /100
            + sum(b.no_vang) over (partition by ifnull(a.thang,b.thang)) *0.15 /100
            + sum(b.no_do) over (partition by ifnull(a.thang,b.thang)) *0.1/100
            + sum(b.no_den) over (partition by ifnull(a.thang,b.thang)) *0.1/100 ,1 )
          else round((b.no_xanh * 0.7 + b.no_vang * 0.6 + b.no_do * 0.5 + b.no_den * 0.4 )/100,1) end
 end as dinhmuc_thuong,
 Case
 -- 1. Áp dụng cho giai đoạn MỚI (Từ ngày 01/03/2026 trở đi)
    when COALESCE(a.thang, b.thang) >= DATE '2026-03-01' then
        ROUND(SAFE_DIVIDE((b.no_xanh * 0.15 + b.no_vang * 0.15 + b.no_do * 0.15 + b.no_den * 0.15 ), 100), 1)
        -- 2. Áp dụng cho giai đoạn CŨ (Trước ngày 01/03/2026)
    else round((b.no_xanh * 0.25 + b.no_vang * 0.15 + b.no_do * 0.1 + b.no_den * 0.1 )/100,1)
    end as dinhmuc_thuong_ncrd,
 a.*except(thang,tenquanlytt,doanhsochuavat,macrm),
 ifnull(doanhsochuavat,0) as doanhsochuavat
 from  result_doanhthu b
 LEFT JOIN  data_duyetdon a on a.macrm=b.macrm and a.thang =b.thang
 order by a.thang
)

select
r.*,
u.asm,
u.tenquanlykhuvuc

from result r
LEFT JOIN `spatial-vision-343005.staging.d_users_bytime` u
      ON r.macrm = u.manv
      AND r.thang = DATE(u.thang)
  )
  ;

Create or replace table `warehouse.f_duyetdonhang_hcp`

copy `staging_temp.f_duyetdonhang_hcp_temp`;

End;
