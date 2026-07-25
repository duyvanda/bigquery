CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_thongtin_tuyen_mcp_tp_pcl()
BEGIN 
  
Create or replace temp table f_thongtin_tuyen_mcp_tp_pcl_temp as 

(

WITH data_sales AS (

    SELECT
        makhdms,
        SUM(
            CASE 
                WHEN EXTRACT(YEAR FROM ngaychungtu) = 2023 THEN doanhsochuavat
                ELSE 0
            END
        ) AS doanhsochuavat_2023,

        SUM(
            CASE 
                WHEN EXTRACT(YEAR FROM ngaychungtu) = 2024 THEN doanhsochuavat
                ELSE 0
            END
        ) AS doanhsochuavat_2024,

        SUM(
            CASE 
                WHEN EXTRACT(YEAR FROM ngaychungtu) = 2025 THEN doanhsochuavat
                ELSE 0
            END
        ) AS doanhsochuavat

    FROM `staging.f_sales`
    WHERE ngaychungtu >= '2023-01-01'
    --and makenhkh = 'GT'
    GROUP BY 1

)

, tuyen_dms_moinhat AS (

    WITH data_tuyen AS (

        SELECT
            * EXCEPT(routetype),
            CASE
                WHEN routetype IN ('B', 'D') THEN 1
                ELSE 2
            END AS routetype
        FROM `spatial-vision-343005.staging.sync_dms_srm_bytime`
        WHERE delroutedet IS FALSE
        --AND CAST(enddate AS DATE) >= '2025-12-31' --CURRENT_DATE
        AND (
            case when date (thang) >= '2025-06-01'  and ifnull(salesrouteid,'') = ('CS_CTO1') then false else true end
        )

    
    )

    SELECT
        *
    FROM data_tuyen
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY custid, thang
        ORDER BY routetype ASC,enddate DESC 
    ) = 1

)


SELECT
    a.thang,
    a.slsperid AS manv,
    c.tencvbh,
    c.supid,
    c.tenquanlytt,
    c.rsmid,
    c.tenquanlyvung,
    a.custid AS ma_khachhang,
    d.custname AS tenkhachhang,
    d.statedescr AS tinh,
    d.districtdescr AS quanhuyen,
    d.channel AS kenh,
    d.shoptype AS kenhphu,
    d.hcotypeid AS phanloai_hco,

    -- start duy fix 01 08 2024
    -- a.branchrouteid AS ma_tuyenbh,
    a.salesrouteid AS ma_tuyenbh,
    -- end duy fix

    a.srdescr AS tentuyen,
    DATE(a.startdate) AS tu_ngay,
    DATE(a.enddate) AS den_ngay,
    a.subrouteid AS sub_route,
    a.slsfreq AS tansuat_bh,
    a.weekofvisit AS tuan_tham_kh,

    CASE 
        WHEN weekdate = 'MS1111111' THEN 'Thu 2,Thu 3,Thu 4,Thu 5,Thu 6,Thu 7,Chu nhat'

        WHEN weekdate = 'MS1111110' THEN 'Thu 2,Thu 3,Thu 4,Thu 5,Thu 6,Thu 7'

        WHEN weekdate = 'MS0000001' THEN 'Chu nhat'

        WHEN weekdate = 'MS1000000' THEN 'Thu 2'

        WHEN weekdate = 'MS0100000' THEN 'Thu 3'

        WHEN weekdate = 'MS0010000' THEN 'Thu 4'

        WHEN weekdate = 'MS0001000' THEN 'Thu 5'

        WHEN weekdate = 'MS0000100' THEN 'Thu 6'

        WHEN weekdate = 'MS0000010' THEN 'Thu 7'

        WHEN weekdate = 'MS1101010' THEN 'Thu 2,Thu 3,Thu 5,Thu 7'

        ELSE weekdate
    END AS thu,

    IF(right(weekdate, 1) = '1', 1, 0) as tuyen_cn,

    b.* EXCEPT(makhdms),
    a.inserted_at,
    d.pubcustid,
    d.pubcustname,
    d.classid,
    d.active,
    d.businessscope,
    d.streetname as so_nha_ten_duong,
    d.wardname as phuong_xa,
    d.branchid as ma_chi_nhanh,

    CASE
        WHEN d.businessscope LIKE '%05%' THEN 'Có'
        ELSE 'Không'
    END AS is_check_pvkd,

    CASE
    WHEN hr.msnvcsmmoi IS NULL THEN 'Nghỉ việc'
    WHEN hr.ngaynghiviecdieuchuyen like '%TS%' THEN 'Thai sản'
    ELSE 'Còn làm việc' 
    END as tinh_trang_lam_viec,

    a.branchid as ma_cn_tuyen

FROM tuyen_dms_moinhat a

LEFT JOIN data_sales b 
    ON a.custid = b.makhdms

LEFT JOIN `staging.d_users_bytime` c 
    ON a.slsperid = c.manv 
    AND c.thang = a.thang

LEFT JOIN `staging.d_master_khachhang_bytime` d
    ON d.custid = a.custid 
    AND d.thang = a.thang
LEFT JOIN `spatial-vision-343005.staging.d_hr_dsns` hr
    ON hr.msnvcsmmoi = a.slsperid

WHERE d.channel IN ('TP', 'PCL','GT','MT')


);

Create or replace table `warehouse.f_thongtin_tuyen_mcp_tp_pcl`

copy `f_thongtin_tuyen_mcp_tp_pcl_temp`;

END;