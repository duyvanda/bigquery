CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_call_result_cham_cong()
BEGIN

CREATE TEMP TABLE `data_nghi_phep` AS
(
    SELECT DISTINCT
        manvcsm,
        DATE(ngay) AS ngay,
        CASE 
            WHEN EXTRACT(DAYOFWEEK FROM ngay) = 7 THEN 'P'
            ELSE loainghiphep 
        END AS loainghiphep
    FROM 
        `spatial-vision-343005.staging.d_manual_danhsach_nghiphep_pbh`
    WHERE
        bophan IN ('TP', 'MT', 'SDS')
        AND 
        (
        CASE 
        WHEN loainghiphep like 'P%' then true
        WHEN loainghiphep like 'T%' then true
        else false end
        )
);

CREATE TEMP TABLE `f_call_result_cham_cong` PARTITION BY DATE(visitdate) AS 

(


WITH checkin_note as (
    select
        a.custid,
        a.visitdate,
        concat(date(a.visitdate),'_',a.custid) as ma_call_kh,
        date(date_trunc(date(a.visitdate), month)) as thang_visitdate,
        a.noteid,
        a.slsperid,
        a.note,
        a.descr,
        a.salesid,
        a.distance,
        a.checkintype,
        a.imagefilename,
        b.channel
    from
        `spatial-vision-343005.staging.sync_dms_oc` a
        left join `staging.d_master_khachhang_bytime` b on a.custid = b.custid and date_trunc(a.visitdate,month) = b.thang
    where

        date(visitdate) >='2025-01-01' and
        a.checkintype = 'Bán Hàng'
        and b.channel not in ('CLC','INS')
)


, result_call_1 as (
    select
        b.*,
        g.role,
        
        count(b.ma_call_kh) over (partition by b.custid, date(b.visitdate), b.slsperid) as so_lan_call_1kh_trong_ngay,
        count(b.ma_call_kh) over (partition by b.thang_visitdate, b.slsperid, b.custid) as so_lan_call_1kh_trong_thang,

        Case when  c.manvcsm is not null then 'Y' else 'N' end as is_nghi_phep,

        Case when b.descr ='Sai tọa độ khách hàng' then 'Có' else 'Không' end as is_check_mds_checkin_gh_saitoado,

        CASE
        WHEN channel = 'PCL' AND b.distance <  200 AND c.manvcsm IS NULL AND b.imagefilename IS NOT NULL
            THEN 'Đạt'
        WHEN channel = 'PCL' AND b.distance >= 200 AND c.manvcsm IS NULL AND b.imagefilename IS NOT NULL AND b.descr = 'Sai tọa độ khách hàng'
            THEN 'Đạt'
        WHEN channel IN ('TP', 'MT','GT') AND b.distance < 400 AND c.manvcsm IS NULL AND b.imagefilename IS NOT NULL
            THEN 'Đạt'
        WHEN channel IN ('TP', 'MT','GT') AND b.distance >= 400 AND c.manvcsm IS NULL AND b.imagefilename IS NOT NULL AND b.descr = 'Sai tọa độ khách hàng' 
            THEN 'Đạt'
        ELSE 'Không đạt'
        END AS is_call_dat

    FROM
        checkin_note b
        LEFT JOIN `spatial-vision-343005.staging.d_dms_master_users` g on g.username = b.slsperid
        LEFT JOIN data_nghi_phep c on date(b.visitdate) = c.ngay and b.slsperid = c.manvcsm
)


    select r.*,
    case when is_call_dat = 'Đạt' then ma_call_kh else null end as ma_call_kh_dat,
    case when is_call_dat = 'Đạt' then custid else null end as ma_kh_dat
    from result_call_1 r

)
;

Create or replace table `warehouse.f_call_result_cham_cong`
copy `f_call_result_cham_cong`;


END;