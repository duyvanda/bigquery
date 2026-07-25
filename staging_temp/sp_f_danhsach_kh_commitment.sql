CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_danhsach_kh_commitment()
BEGIN 
  DECLARE p_diem_quy_doi_kh_th int64;
  DECLARE p_diem_quy_doi_cl int64;
  DECLARE p_ds_quy_doi_kh_th int64;
  DECLARE p_ds_quy_doi_cl int64;
  set p_diem_quy_doi_kh_th =(SELECT cast(diem_quy_doi_kh_th as int) FROM `staging.d_manual_danhsach_commitment` WHERE diem_quy_doi_kh_th IS NOT NULL);
  set p_diem_quy_doi_cl= (SELECT cast(diem_quy_doi_cl as int) FROM`staging.d_manual_danhsach_commitment`WHERE diem_quy_doi_cl IS NOT NULL);
  set p_ds_quy_doi_kh_th = (SELECT cast(ds_quy_doi_kh_th AS int) FROM `staging.d_manual_danhsach_commitment`  WHERE ds_quy_doi_kh_th IS NOT NULL);
  set p_ds_quy_doi_cl =  (SELECT cast(ds_quy_doi_cl AS int) FROM `staging.d_manual_danhsach_commitment` WHERE ds_quy_doi_cl IS NOT NULL);


 TRUNCATE TABLE staging_temp.f_danhsach_kh_commitment_temp;

 INSERT INTO `staging_temp.f_danhsach_kh_commitment_temp`
(

--   Create or replace table staging_temp.f_danhsach_kh_commitment_temp as


/*
SELECT ma_kh,
sum(ifnull(thanh_tien,0)) as thanh_tien_doi_sp_mr,
sum(ifnull(thanh_tien_ve,0)) as thanh_tien_ve,
sum(ifnull(thanh_tien_suat,0)) as thanh_tien_suat,
sum(ifnull(thanh_tien_qua,0)) as thanh_tien_qua,
sum(ifnull(thanh_tien,0)+ifnull(thanh_tien_ve,0)+ifnull(thanh_tien_suat,0)+ifnull(thanh_tien_qua,0)) as tong_gt_qt
 FROM `spatial-vision-343005.staging.d_manual_theo_doi_chon_qua_cmm_gd2_2024` group by 1
*/
WITH 

tuyen_dms_moinhat AS (
    WITH data_tuyen AS (
        SELECT
            custid,
            slsperid,
            crtd_datetime,
            CASE
                WHEN routetype IN ('B', 'D') THEN 1
                ELSE 2
            END AS routetype,
        FROM
            `spatial-vision-343005.staging.sync_dms_srm`
        WHERE
            delroutedet IS false
    )
    SELECT
        *
    FROM
        data_tuyen qualify row_number() over (
            PARTITION by custid
            ORDER BY
                routetype ASC,
                crtd_datetime DESC
        ) = 1
),

-- max_hcotypeid as 

-- (
-- select custid,hcotypeid,date_trunc(crtd_datetime,month) as thang from `staging.sync_dms_pda_so` where hcotypeid is not null 
-- qualify row_number() over (partition by custid order by crtd_datetime) = 1
-- )
-- ,


sales as 
(
select 
a.masanpham,
a.ngaychungtu,
a.hoadon,
d.taxregnbr,
a.makhdms,
ifnull(b.hcotypeid,c.hcotypeid) as hcotypeid,
sum(doanhsocovat) as doanhsocovat,
sum(doanhsochuavat) as doanhsochuavat
 from `warehouse.f_raw_data_sales_yoy` a 
 LEFT JOIN  `staging.sync_dms_pda_so` b on a.sodondathang =b.ordernbr and a.macongtycn =b.branchid
 LEFT JOIN `staging.d_master_khachhang` c on a.makhdms = c.custid --and c.thang = date_trunc(ngaychungtu,month)
 LEFT JOIN `staging.sync_dms_so` d on d.ordernbr = a.mahd and d.branchid =a.macongtycn
 where ngaychungtu >='2023-10-01' and makenhkh not in ('NB','OTH_LAB') 
  and ngaychungtu < '2025-01-01'
 group by all
 having doanhsocovat <>0
),
mapping_sales AS (
    SELECT
        a.ma_kh,
        a.ma_pl_hco as hcotypeid,
        a.ten_kh,
        a.da_ky_bb_thoa_thuan,
        a.da_quan_tam_zalo_oa,
        a.hien_trang_doi_qua,
        Case when cast(a.ngay_sinh as string) like '%1970-01-01%' then null else cast(a.ngay_sinh as string) end as ngay_sinh,
        date(a.ngay_tham_gia) as ngay_tham_gia,
        date(a.ngay_ket_thuc) as ngay_ket_thuc,
        a.diem_tich_luy_quan_tam_oa_dang_ky,
        a.diem_tich_luy_sinh_nhat,
        a.diem_tich_luy_sp_moitang_diem,
        a.diem_tl_da_sd,
        a.tien_quy_doi_da_sd,
        ifnull(a.diem_tl_da_sd_gd2,0) as diem_tl_da_sd_gd2,
        ifnull(cast(a.tien_quy_doi_da_sd_gd2 as int),0) as tien_quy_doi_da_sd_gd2,
        Case when trim(c.commitment) IN ('Kháng sinh', 'Tiêu hóa', 'Còn lại') THEN hoadon
                ELSE NULL
            END
         AS hoadon,
        Case when trim(c.commitment) IN ('Kháng sinh', 'Tiêu hóa', 'Còn lại') THEN taxregnbr
                ELSE NULL
            END
         AS taxregnbr,
        Case when trim(c.commitment) IN ('Kháng sinh', 'Tiêu hóa', 'Còn lại') THEN ngaychungtu
                ELSE NULL
            END
         AS ngaychungtu,
        sum(
        CASE
            WHEN date(ngaychungtu) >= date(a.ngay_tham_gia)
            AND date(ngaychungtu) <= date(a.ngay_ket_thuc)
            AND trim(c.commitment) IN ('Kháng sinh', 'Tiêu hóa') THEN doanhsocovat
            ELSE 0
        END
        ) AS doanhsocovat_ks,
        sum(
            CASE
                WHEN date(ngaychungtu) >= date(a.ngay_tham_gia)
                AND date(ngaychungtu) <= date(a.ngay_ket_thuc)
                AND trim(c.commitment) IN ('Còn lại') THEN doanhsocovat
                ELSE 0
            END
        ) AS doanhsocovat_cl,

                 sum(
            CASE
                WHEN date(ngaychungtu) >= date(
                    a.ngay_tham_gia
                )
                AND date(ngaychungtu) <= date(
                    a.ngay_ket_thuc
                )
                AND trim(c.commitment) IN ('Kháng sinh', 'Tiêu hóa') THEN doanhsochuavat
                ELSE 0
            END
        ) AS doanhsocovat_ks_chuavat,
        sum(
            CASE
                WHEN date(ngaychungtu) >= date(
                    a.ngay_tham_gia
                )
                AND date(ngaychungtu) <= date(
                    a.ngay_ket_thuc
                )
                AND trim(c.commitment) IN ('Còn lại') THEN doanhsochuavat
                ELSE 0
            END
        ) AS doanhsocovat_cl_chuavat,

    FROM
        `staging.d_manual_danhsach_commitment` a
        LEFT JOIN sales b ON a.ma_kh = b.makhdms
        AND a.ma_pl_hco = b.hcotypeid
        AND date(ngaychungtu) >= date(
                    a.ngay_tham_gia
                )
        AND date(ngaychungtu) <= date(
                   a.ngay_ket_thuc
                )
        LEFT JOIN `staging.d_manual_danhsach_commitment` c ON b.masanpham = c.ma_sp
        AND c.ma_sp IS NOT NULL 
    WHERE
        a.ma_kh IS NOT NULL
    GROUP BY
        all
                
),
quydoi_diem AS (
    SELECT
        a.*,
    row_number() over (partition by ma_kh,hcotypeid order by ngaychungtu desc) as stt,
    sum(doanhsocovat_ks) over (partition by a.ma_kh,hcotypeid order by ngaychungtu asc ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW  ) as doanhsocovat_ks_cum,
    sum(doanhsocovat_cl) over (partition by a.ma_kh,hcotypeid order by ngaychungtu asc ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ) as doanhsocovat_cl_cum,

    sum(doanhsocovat_ks_chuavat) over (partition by a.ma_kh,hcotypeid order by ngaychungtu asc ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW  ) as doanhsocovat_ks_cum_chuavat,
    sum(doanhsocovat_cl_chuavat) over (partition by a.ma_kh,hcotypeid order by ngaychungtu asc ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ) as doanhsocovat_cl_cum_chuavat,
    FROM
        mapping_sales a
),

quydoi_diem2 as (
select a.*,
        doanhsocovat_ks + doanhsocovat_cl AS doanhsocovat,
        doanhsocovat_ks_chuavat + doanhsocovat_cl_chuavat AS doanhsochuavat,
        doanhsocovat_ks_cum + doanhsocovat_cl_cum as doanhsocovat_cum,
        doanhsocovat_ks_cum_chuavat + doanhsocovat_cl_cum_chuavat as doanhsocovat_cum_chuavat,
        CASE
            WHEN doanhsocovat_ks_cum < 0 THEN 0
            ELSE div(cast(doanhsocovat_ks_cum AS int),p_ds_quy_doi_kh_th) * p_diem_quy_doi_kh_th
        END AS diem_quy_doi_ks_th,
        CASE
            WHEN doanhsocovat_cl_cum < 0 THEN 0
            ELSE div(cast(doanhsocovat_cl_cum AS int), p_ds_quy_doi_cl) * p_diem_quy_doi_cl 
        END AS diem_quy_doi_ks_cl,

 from quydoi_diem a

),
tong_diem_tl as 
(
  select a.*,
  a.diem_tich_luy_quan_tam_oa_dang_ky + a.diem_tich_luy_sinh_nhat + a.diem_tich_luy_sp_moitang_diem  + a.diem_quy_doi_ks_cl + a.diem_quy_doi_ks_th AS tongdiem_tl,

  
  from quydoi_diem2 a 
    LEFT JOIN `spatial-vision-343005.staging.d_manual_danhsach_commitment` c1 ON 
    (a.diem_tich_luy_quan_tam_oa_dang_ky + a.diem_tich_luy_sinh_nhat + a.diem_tich_luy_sp_moitang_diem  + a.diem_quy_doi_ks_cl + a.diem_quy_doi_ks_th ) >= c1.muc_diem_tu
    AND (a.diem_tich_luy_quan_tam_oa_dang_ky + a.diem_tich_luy_sinh_nhat + a.diem_tich_luy_sp_moitang_diem  + a.diem_quy_doi_ks_cl + a.diem_quy_doi_ks_th ) <= c1.muc_diem_den
    AND c1.hang_kh IS NOT NULL
)
,
hang_kh_result as (
SELECT
    a.*except(tongdiem_tl,taxregnbr),
    c1.hang_kh,
    c1.muc_diem_tu,
    c1.muc_diem_den,
    c1.thuong_thang_hang,
    ifnull(cast(c1.tien_quy_doi as float64),0) as tien_quy_doi,
    a.tongdiem_tl + IFNULL(c1.thuong_thang_hang, 0) as tongdiem_tl,
    (a.tongdiem_tl + IFNULL(c1.thuong_thang_hang, 0)) * ifnull(cast(c1.tien_quy_doi as float64),0)  AS tien_quydoi,
    a.tongdiem_tl + IFNULL(c1.thuong_thang_hang, 0)- a.diem_tl_da_sd - a.diem_tl_da_sd_gd2 as diem_tl_conlai,
    ( a.tongdiem_tl + IFNULL(c1.thuong_thang_hang, 0) - a.diem_tl_da_sd  ) * ifnull(cast(c1.tien_quy_doi as float64),0) - a.tien_quy_doi_da_sd_gd2 as tien_quydoi_conlai, --29/7 đổi công thức tính tiền quy đổi còn lại
    /*
    cũ: tổng tien quy đổi - tien da su dung
    mới: diem_conlai * tien quy doi/1d
    */
    ( (a.tongdiem_tl + IFNULL(c1.thuong_thang_hang, 0) - a.diem_tl_da_sd) * CAST(c1.tien_quy_doi AS INT) - a.tien_quy_doi_da_sd_gd2 )
    + a.tien_quy_doi_da_sd_gd2
    + a.tien_quy_doi_da_sd as tien_quydoi_v1,
    
    l.col.ma_nvbh as slsperid,
    e.tencvbh,
    e.supid,
    e.tenquanlytt,
    e.asm,
    e.tenquanlykhuvuc,
    e.rsmid,
    e.tenquanlyvung,
    f.custname,
    f.channel,
    f.shoptype,
    f.hcoid,
    -- f.hcotypeid,
    f.statedescr,
    f.shortterritorydescr,
    f.branchid,
    f.branchname,
    f.custidinvoice,
    f.custnameinvoice,
    a.taxregnbr,
    current_timestamp() + interval 7 hour as inserted_at
FROM
    tong_diem_tl a
    LEFT JOIN `spatial-vision-343005.staging.d_manual_danhsach_commitment` c1 ON 
    tongdiem_tl >= c1.muc_diem_tu
    AND tongdiem_tl <= c1.muc_diem_den
    AND c1.hang_kh IS NOT NULL
    -- LEFT JOIN tuyen_dms_moinhat d on d.custid = a.ma_kh
    LEFT JOIN `warehouse.f_mapping_crs` l on l.custid = a.ma_kh 
    LEFT JOIN `staging.d_users` e on e.manv = l.col.ma_nvbh   
    LEFT JOIN `staging.d_master_khachhang` f on f.custid = a.ma_kh
),
min_ngay_thanghang_gannhat as(
    select ma_kh,hang_kh,hcoid,min(ngaychungtu) as min_ngaychungtu 
    from hang_kh_result  group by 1,2,3
    )

select a.*,b.min_ngaychungtu 

from hang_kh_result a
LEFT JOIN min_ngay_thanghang_gannhat b on a.ma_kh =b.ma_kh and a.hang_kh = b.hang_kh and a.hcoid =b.hcoid


    order by ma_kh,stt
    
);

Create or replace table `warehouse.f_danhsach_kh_commitment`

copy `staging_temp.f_danhsach_kh_commitment_temp`;


END;