CREATE VIEW `spatial-vision-343005.warehouse.view_f_data_checkin_pbh_v3`
AS WITH comebined as
(
SELECT
a.custid,
a.visitdate,
a.ma_call_kh,
a.thang_visitdate,
a.noteid,
a.slsperid,
a.note,
a.descr,
a.salesid,
a.distance,
a.checkintype,
a.imagefilename,
a.channel,
a.checkin,
a.time_checkin,
a.lat,
a.lng,
a.checkout,
a.time_checkout,
a.ordernbr,
a.saordernbr,
a.ordamt,
a.role,
a.so_lan_call_1kh_trong_ngay,
a.so_lan_call_1kh_trong_thang,
a.ma_call_kh_co_dh,
a.is_mcp,
a.is_dung_ngay,
a.is_nghi_phep,
a.is_check_mds_checkin_gh_saitoado,
a.is_call_dat,
a.ma_kh_checkin_ngoai_mcp,
a.ma_kh_phat_sinh_dh,
a.ma_kh_mcp,
a.slsfreq,
a.ma_kh_dat,
a.stt_di_call_1kh_trong_ngay,
a.ma_call_kh_dat_ban_dau,
a.stt_di_call_1kh_trong_thang,
a.solan_call_qd,
a.ma_call_kh_dat,
a.phan_loai_vuot_gioi_han_call,
a.is_call_dat_v2,
NULL as ma_kh_can_vieng_tham,
'result_call' as dtype
FROM `spatial-vision-343005.warehouse.f_call_result` a
UNION ALL
SELECT
custid,
Cast(visitdate as timestamp) as visitdate,
NULL as ma_call_kh,
date(date_trunc(date(visitdate), month)) as thang_visitdate,
NULL as noteid,
slsperid,
NULL as note,
NULL as descr,
NULL as salesid,
NULL as distance,
NULL as checkintype,
NULL as imagefilename,
channel,
NULL as checkin,
NULL as time_checkin,
NULL as lat,
NULL as lng,
NULL as checkout,
NULL as time_checkout,
NULL as ordernbr,
NULL as saordernbr,
NULL as ordamt,
NULL as role,
NULL as so_lan_call_1kh_trong_ngay,
NULL as so_lan_call_1kh_trong_thang,
NULL as ma_call_kh_co_dh,
'Trong' as is_mcp,
NULL as is_dung_ngay,
NULL as is_nghi_phep,
NULL as is_check_mds_checkin_gh_saitoado,
NULL as is_call_dat,
NULL as ma_kh_checkin_ngoai_mcp,
NULL as ma_kh_phat_sinh_dh,
NULL as ma_kh_mcp,
NULL as slsfreq,
NULL as ma_kh_dat,
NULL as stt_di_call_1kh_trong_ngay,
NULL as ma_call_kh_dat_ban_dau,
NULL as stt_di_call_1kh_trong_thang,
NULL as solan_call_qd,
NULL as ma_call_kh_dat,
NULL as phan_loai_vuot_gioi_han_call,
NULL as is_call_dat_v2,
custid as ma_kh_can_vieng_tham,
'schedule_call' as dtype
FROM `warehouse.data_quy_dinh_vieng_tham`
)


, data_check_dh_1 as (
    SELECT
        makhdms,
        max(date(ngaychungtu)) as ngaychungtu,
        sum(doanhsochuavat) as ds
    from
        `staging.f_sales`
    where
        ngaychungtu >= '2024-01-01'
    group by
        1
    having ds > 0
),

data_check_dh_2 as (
    select
        a.custid,
        date_diff(current_date("+7"),ifnull(ngaychungtu,date(a.crtd_datetime)),day) as so_ngay_chua_mua_hang
        
    from
        `staging.d_master_khachhang` a
        LEFT JOIN data_check_dh_1 b on a.custid = b.makhdms
)

, check_qd_viengtham as (
select 
    date(date_trunc(visitdate,month)) as thang,
    slsperid,
    count(distinct ma_kh_dat) as sl_kh_checkin_dat,
    count(distinct ma_kh_can_vieng_tham) as sl_kh_can_vieng_tham,
    count( ma_kh_can_vieng_tham) as sl_call_can_checkin,
    count(distinct ma_call_kh_dat) as sl_call_checkin_dat,
from comebined
group by 1,2
)



select a.*,
c.custname,
c.statedescr,
c.districtdescr,
c.territorydescr,
c.shoptype,
c.branchid,
c.classid,
c.taxregnbr,
c.phone,
c.attn,
date(c.legaldate) as thoihanhieulucgdpgpp,

CASE
    WHEN c.legaldate IS NULL THEN NULL
    WHEN DATE(c.legaldate) < (
        SELECT *
        FROM `staging.d_current_table`
    ) THEN 'Y'
    WHEN DATE(c.legaldate) >= (
        SELECT *
        FROM `staging.d_current_table`
    ) THEN 'N'
    ELSE NULL
END AS is_hetthoihanhieuluc,

CASE
    WHEN DATE_ADD(
        (
            SELECT *
            FROM `staging.d_current_table`
        ),
        INTERVAL 30 DAY
    ) >= DATE(c.legaldate)
    AND DATE(c.legaldate) > (
        SELECT *
        FROM `staging.d_current_table`
    ) THEN 'Y'
    WHEN c.legaldate IS NULL THEN NULL
    ELSE 'N'
END AS is_saphetthoihanhieuluc,

u.supid as ma_crm,
u.asm as ma_scrm,
u.rsmid as ma_ncxm,
u.tencvbh,
'' as mds,
u.tenquanlytt,
u.tenquanlykhuvuc,
u.tenquanlyvung,

CASE WHEN is_dung_ngay = 'Dung' then ma_call_kh_dat else null end as ma_call_kh_dat_trong_tuyen,
CASE WHEN is_dung_ngay = 'Sai' then ma_call_kh_dat else null end as ma_call_kh_dat_ngoai_tuyen,

Case
    when a.channel in ('TP','GT' )
    and round(safe_divide(b.sl_call_checkin_dat,b.sl_call_can_checkin)*100,1) >=90  then 'Đạt' 
    when a.channel = 'PCL' and round(safe_divide(b.sl_kh_checkin_dat,b.sl_kh_can_vieng_tham)*100,1) >= 80  then 'Đạt'
    else 'Không đạt'
end as check_viengtham_thang,

dh.so_ngay_chua_mua_hang,
h.ma_cre,
h.ho_ten_cre,

--- NO USE FIELDS
'' as is_lich_call,
'' as sl_dh_thucte,
'' as sl_kh_phatsinhdh,
'' as soluong_checkin_thucte_vuot,
'' as soluong_dh_trongtuyen,
'' as soluong_dh_ngoaituyen,
'' as pl_kh_checkin,
'' as phan_loai_call,
'' as pl_solan_call,
'' as sl_quydinh_ka,
'' as sl_quydinh_kb,
'' as sl_quydinh_kc,
'' as sl_quydinh_khac,
'' as sl_checkin_ka,
'' as sl_checkin_kb,
'' as sl_checkin_kc,
'' as sl_checkin_khac,
'' as sl_kh_checkin_thucte_ka,
'' as sl_kh_checkin_thucte_kb,
'' as sl_kh_checkin_thucte_kc,
'' as sl_kh_checkin_thucte_khac,
'' as is_checkin_onl,
'' as so_kh_viengtham_tt,
'' as is_daviengtham,
'' as is_hspl,
'' as is_ttkh,
'' as is_bosung_crs,
TIMESTAMP(DATETIME(CURRENT_TIMESTAMP(), "Asia/Bangkok")) AS inserted_at,
date('1900-01-01') as visitdate_mapping,
0 as thoi_gian_checkin,

CASE 
    WHEN COUNT(a.ma_call_kh_dat) OVER (PARTITION BY a.custid, a.thang_visitdate) > 0 THEN 'Đạt' 
    ELSE 'Không đạt' 
END AS ket_qua_vt_final -- kết quả xem trong tháng kh này có đạt ko: 1 KH 1 tháng: có đạt là đạt

from comebined a
left join `staging.d_master_khachhang` c on a.custid = c.custid
left join `staging.d_users_bytime` u  on a.slsperid = u.manv and date(a.thang_visitdate) = date(u.thang)
left join data_check_dh_2 dh on dh.custid = a.custid
LEFT JOIN check_qd_viengtham b on date(a.thang_visitdate) = date(b.thang) and a.slsperid = b.slsperid
LEFT JOIN `spatial-vision-343005.staging.d_calendar_cre` h ON a.slsperid = h.ma_crs AND date(h.thang) = date(a.thang_visitdate)
where a.channel in ('PCL','TP', 'MT','GT') 

-- and tencvbh = 'Nguyễn Tuấn Anh' and dtype = 'schedule_call' and a.thang_visitdate = '2025-04-01';