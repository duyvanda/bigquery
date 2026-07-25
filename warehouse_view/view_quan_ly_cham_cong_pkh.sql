CREATE VIEW `spatial-vision-343005.warehouse.view_quan_ly_cham_cong_pkh`
AS WITH base_date as
(
SELECT
     ngay,
     date_trunc(ngay, month) as thang,
    --  'Thứ ' || 
     extract(dayofweek from ngay) as thu_ngay,
    --  'Tuần ' || 
     row_number() over (partition by extract(month from ngay),extract(dayofweek from ngay) order by ngay) as tuan
    FROM
        unnest(
            GENERATE_DATE_ARRAY(
                date('2025-04-01'),
                date('2026-12-31')
        )) AS ngay
where extract(dayofweek from ngay) not in (1, 7)
order by 1

)

,   tuyen_mcp_anh_vien as (
SELECT distinct 
thang,
manv
FROM `spatial-vision-343005.warehouse.f_thongtin_tuyen_mcp_tp_pcl` 
where 
active = 'Active' and thang >= '2025-04-01'
AND
(CASE WHEN tenquanlyvung = 'Nguyễn Hoàng Viển' AND kenh = 'TP' THEN TRUE
      WHEN tenquanlyvung = 'Lê Thị Hương Sa' AND kenh = 'MT' THEN TRUE
      WHEN manv = 'MR4016' AND kenh = 'GT' AND thang < '2026-01-01' THEN TRUE
      WHEN kenh = 'GT' AND thang >= '2026-01-01' THEN TRUE
      ELSE FALSE END)

)
, combined_base_date_and_dsns as

(

SELECT
bd.ngay,
hr.ngayvaolamonboarddate as on_board_date,
EXTRACT(DAYOFWEEK FROM DATE(bd.ngay)) as dow,
hr.msnvcsmmoi,
hr.hovatenfullname,
hr.phongdeptsummary,
IF(mcp.manv IS NOT NULL, TRUE, FALSE) as co_trong_mcp,
CASE
WHEN REPLACE(REPLACE(chucdanhengtitlesum, ' ', ''), '-', '') like '%SDS%' THEN 'SDS'
WHEN REPLACE(REPLACE(chucdanhengtitlesum, ' ', ''), '-', '') like '%CRS%' THEN 'CRS'
WHEN REPLACE(REPLACE(chucdanhengtitlesum, ' ', ''), '-', '') like '%CRE%' THEN 'CRE'
WHEN phongdeptsummary = 'MT' THEN chucdanhengtitlesum
ELSE null END AS vai_tro,

FROM `spatial-vision-343005.staging.d_hr_dsns_bytime` hr
LEFT JOIN tuyen_mcp_anh_vien mcp on mcp.manv = hr.msnvcsmmoi and hr.thang = mcp.thang
LEFT JOIN base_date bd on date(hr.thang) = date(bd.thang)
where hr.thang >= '2025-04-01' --and hr.phongdeptsummary IN ('TP','MT')
AND hr.msnvcsmmoi not in ('MR2685') 
AND (
CASE 
WHEN REPLACE(REPLACE(chucdanhengtitlesum, ' ', ''), '-', '') like '%SDS%' AND phongdeptsummary = 'TP' THEN TRUE
WHEN REPLACE(REPLACE(chucdanhengtitlesum, ' ', ''), '-', '') like '%CRS%' AND phongdeptsummary = 'TP' THEN TRUE
WHEN REPLACE(REPLACE(chucdanhengtitlesum, ' ', ''), '-', '') like '%CRE%' AND phongdeptsummary = 'TP' THEN TRUE
WHEN hr.msnvcsmmoi = 'MR4016' THEN TRUE
--WHEN chucdanhengtitlesum like '%KAS%' AND phongdeptsummary = 'MT' THEN TRUE
WHEN chucdanhengtitlesum not like '%KAM%' AND phongdeptsummary = 'MT' THEN TRUE
--WHEN chucdanhengtitlesum like '%KA%' AND phongdeptsummary = 'MT' THEN TRUE
ELSE FALSE END
)
)

, actual_call as
(
SELECT
date(visitdate) as ngay_vt,
EXTRACT(DAYOFWEEK FROM DATE(visitdate)) as dow,
slsperid,
count (distinct ma_kh_dat) as so_call_dat,
CASE
  WHEN COUNT(DISTINCT CASE WHEN channel IN ('TP', 'GT') THEN ma_kh_dat END) BETWEEN 4 AND 7 THEN 0.5
  WHEN COUNT(DISTINCT CASE WHEN channel IN ('TP', 'GT') THEN ma_kh_dat END) >= 8 THEN 1
  WHEN COUNT(DISTINCT CASE WHEN channel = 'MT' THEN ma_kh_dat END) BETWEEN 3 AND 5  THEN 0.5
  WHEN COUNT(DISTINCT CASE WHEN channel = 'MT' THEN ma_kh_dat END) >= 6 THEN 1
  ELSE 0
END AS quy_doi_ngay_cong
FROM `spatial-vision-343005.warehouse.f_call_result_cham_cong` 
WHERE TIMESTAMP_TRUNC(visitdate, DAY) >= TIMESTAMP("2025-04-01")
AND EXTRACT(DAYOFWEEK FROM DATE(visitdate)) != 1 
AND channel in ('TP','MT','GT')
GROUP BY ngay_vt,dow,slsperid

)


, first_visits_by_halfday as

(
SELECT
a.slsperid,
DATE(a.visitdate) AS ngay,

MIN(CASE 
    WHEN EXTRACT(HOUR FROM b.time_checkin) > 6 AND EXTRACT(HOUR FROM b.time_checkin) < 14 AND b.ma_kh_dat is not null  THEN b.time_checkin 
END) AS vt_dau_tien_truoc_12pm,

MIN(CASE 
    WHEN EXTRACT(HOUR FROM b.time_checkin) >= 14 AND b.ma_kh_dat is not null THEN b.time_checkin
END) AS vt_dau_tien_sau_12pm,

TIMESTAMP_DIFF(
    MAX(CASE WHEN b.ma_kh_dat IS NOT NULL THEN b.time_checkout END),
    MAX(CASE WHEN b.ma_kh_dat IS NOT NULL THEN b.time_checkin END),
    MINUTE
  ) AS thoi_gian_visit_cuoi_cung,
MAX(CASE 
    WHEN b.ma_kh_dat IS NOT NULL THEN b.time_checkin
END) as checkin_cuoi_cung_trong_ngay,

MAX(CASE 
    WHEN b.ma_kh_dat IS NOT NULL THEN b.time_checkout 
END) as checkout_cuoi_cung_trong_ngay

FROM
`spatial-vision-343005.staging.sync_dms_oc` a
LEFT JOIN `spatial-vision-343005.warehouse.f_call_result` b ON a.slsperid = b.slsperid AND DATE(a.visitdate) = DATE(b.visitdate) AND b.custid = a.custid
WHERE DATE(a.visitdate) >= '2025-01-01'

GROUP BY
slsperid,
DATE(a.visitdate)

)

SELECT
d.ngay,
d.on_board_date,
d.dow,
d.msnvcsmmoi as manv,
d.hovatenfullname as tencvbh,
u.supid,
u.tenquanlytt,
d.vai_tro,
d.phongdeptsummary,
/*update ngay_cong_co_dinh: Nếu đang thử việc mà không có trong mcp => cho số ngày cần chấm công = 0*/
case when d.vai_tro = 'SDS' then sds.ngay_cong
     when d.msnvcsmmoi in ('MR4151','MR4122') AND d.ngay >= '2026-05-01' then 0 -- đang theo dự án Nha khoa, chưa có MCP bán hàng
    when  d.ngay < date(d.on_board_date) then 0
    WHEN d.co_trong_mcp IS FALSE THEN 0
    else 1 end as ngay_cong_co_dinh,
-- IF(sds.ngay is not null, sds.ngay_cong, 1.0) as ngay_cong_co_dinh,
IFNULL(ac.so_call_dat, 0 ) as so_call_dat,

if (dk.leave_date is null, 0,1) as ngay_nghi_co_ly_do,
CASE 
    WHEN if (dk.leave_date is null, 0,1) = 1 then 0 --- nghỉ phép rồi thì ko chấm công nữa
    else IFNULL(ac.quy_doi_ngay_cong, 0 ) 
END as quy_doi_ngay_cong,

dk.type as phan_loai_ngay_nghi,
fd.vt_dau_tien_truoc_12pm,
fd.vt_dau_tien_sau_12pm,
fd.checkout_cuoi_cung_trong_ngay,
fd.thoi_gian_visit_cuoi_cung,
checkin_cuoi_cung_trong_ngay
FROM `combined_base_date_and_dsns` d
LEFT JOIN `actual_call` ac on d.msnvcsmmoi = ac.slsperid and d.ngay = ac.ngay_vt
LEFT JOIN `staging.view_d_dang_ky_nghi_phep_co_ly_do_pkh_by_user` dk on dk.manv = d.msnvcsmmoi and dk.leave_date = d.ngay
LEFT JOIN `staging.d_ngay_cong_sds` sds on 
sds.manv = d.msnvcsmmoi 
and date(sds.ngay) = date(d.ngay)
LEFT JOIN `staging.d_users` u on d.msnvcsmmoi = u.manv
LEFT JOIN `first_visits_by_halfday` fd on fd.slsperid = d.msnvcsmmoi and fd.ngay = d.ngay
--where d.ngay >= '2025-11-01' AND d.ngay <= '2025-11-30'
--phongdeptsummary = 'MT'
--d.msnvcsmmoi = 'MR1179' and d.ngay = date('2025-04-04')

;