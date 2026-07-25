CREATE PROCEDURE `spatial-vision-343005`.staging_temp.api_ds_kh_commitment_old(p_makhdms STRING, p_startdate STRING, p_enddate STRING, p_ma_crs STRING)
BEGIN

  DECLARE p_diem_quy_doi_kh_th int64;
  DECLARE p_diem_quy_doi_cl int64;
  DECLARE p_ds_quy_doi_kh_th int64;
  DECLARE p_ds_quy_doi_cl int64;


  DECLARE current_dt DATE DEFAULT CURRENT_DATE("+7");
  DECLARE set_enddate, set_startdate DATE;
  
  SET set_startdate = IF (p_startdate = '', Date('2023-10-01'), DATE(p_startdate) );
  SET set_enddate = IF (p_enddate = '', current_dt, DATE(p_enddate) );
  set p_diem_quy_doi_kh_th =(SELECT cast(diem_quy_doi_kh_th as int) FROM `staging.d_manual_danhsach_commitment` WHERE diem_quy_doi_kh_th IS NOT NULL);
  set p_diem_quy_doi_cl= (SELECT cast(diem_quy_doi_cl as int) FROM`staging.d_manual_danhsach_commitment`WHERE diem_quy_doi_cl IS NOT NULL);
  set p_ds_quy_doi_kh_th = (SELECT cast(ds_quy_doi_kh_th AS int) FROM `staging.d_manual_danhsach_commitment`  WHERE ds_quy_doi_kh_th IS NOT NULL);
  set p_ds_quy_doi_cl =  (SELECT cast(ds_quy_doi_cl AS int) FROM `staging.d_manual_danhsach_commitment` WHERE ds_quy_doi_cl IS NOT NULL);

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
    select * from (
    SELECT
        *, row_number() over (
            PARTITION by custid
            ORDER BY
                routetype ASC,
                crtd_datetime DESC
        ) as loc
    FROM
        data_tuyen ) where loc = 1
),

sales as 
(
select
a.masanpham,
a.ngaychungtu,
a.makhdms,
ifnull(b.hcotypeid,c.hcotypeid) as hcotypeid,
sum(doanhsocovat) as doanhsocovat,
from `warehouse.f_sales_crs` a
LEFT JOIN  `staging.sync_dms_pda_so` b on a.sodondathang =b.ordernbr and a.macongtycn =b.branchid
LEFT JOIN `staging.d_master_khachhang` c on a.makhdms = c.custid 
where ngaychungtu >='2023-10-01'
and date(ngaychungtu) >= set_startdate
and date(ngaychungtu) <= set_enddate
and makenh_moi not in ('NB','OTH_LAB')
group by 1,2,3,4
having doanhsocovat <> 0
),

mapping_sales AS (
    SELECT
        a.ma_kh,
        a.ten_kh,
        a.ma_pl_hco as hcotypeid,
  	  	a.da_ky_bb_thoa_thuan,
        Case when a.ngay_sinh like '%1970-01-01%' then null else a.ngay_sinh end as ngay_sinh,
        date(a.ngay_tham_gia ) AS ngay_tham_gia,
        date(a.ngay_ket_thuc) AS ngay_ket_thuc,
        a.diem_tich_luy_quan_tam_oa_dang_ky,
        a.diem_tich_luy_sinh_nhat,
        a.diem_tich_luy_sp_moitang_diem,
        a.diem_tl_da_sd,
        a.tien_quy_doi_da_sd,
        min( Case when trim(c.commitment) IN ('Kháng sinh', 'Tiêu hóa', 'Còn lại') THEN ngaychungtu
                 ELSE NULL
             END)
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
        ) AS doanhsocovat_cl
    FROM
        `staging.d_manual_danhsach_commitment` a
        LEFT JOIN sales b ON a.ma_kh = b.makhdms and b.hcotypeid =a.ma_pl_hco
        LEFT JOIN `staging.d_manual_danhsach_commitment` c ON b.masanpham = c.ma_sp
        AND c.ma_sp IS NOT NULL 
    WHERE
        a.ma_kh IS NOT NULL 
    GROUP BY
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
  		11,
        12       
),

quydoi_diem as (
select a.*,
        doanhsocovat_ks + doanhsocovat_cl AS doanhsocovat,
        -- doanhsocovat_ks_cum + doanhsocovat_cl_cum as doanhsocovat_cum,
        CASE
            WHEN doanhsocovat_ks < 0 THEN 0
            ELSE div(cast(doanhsocovat_ks AS int),p_ds_quy_doi_kh_th) * p_diem_quy_doi_kh_th
        END AS diem_quy_doi_ks_th,
        CASE
            WHEN doanhsocovat_cl < 0 THEN 0
            ELSE div(cast(doanhsocovat_cl AS int),p_ds_quy_doi_cl ) * p_diem_quy_doi_cl
        END AS diem_quy_doi_ks_cl,

 from mapping_sales a

),
tong_diem_tl_t as 
(
  select a.*,
  a.diem_tich_luy_quan_tam_oa_dang_ky + a.diem_tich_luy_sinh_nhat + a.diem_tich_luy_sp_moitang_diem  + a.diem_quy_doi_ks_cl + a.diem_quy_doi_ks_th AS tongdiem_tl,

  
  from quydoi_diem a 
    LEFT JOIN `spatial-vision-343005.staging.d_manual_danhsach_commitment` c1 ON 
    (a.diem_tich_luy_quan_tam_oa_dang_ky + a.diem_tich_luy_sinh_nhat + a.diem_tich_luy_sp_moitang_diem  + a.diem_quy_doi_ks_cl + a.diem_quy_doi_ks_th ) >= c1.muc_diem_tu
    AND (a.diem_tich_luy_quan_tam_oa_dang_ky + a.diem_tich_luy_sinh_nhat + a.diem_tich_luy_sp_moitang_diem  + a.diem_quy_doi_ks_cl + a.diem_quy_doi_ks_th ) <= c1.muc_diem_den
    AND c1.hang_kh IS NOT NULL
)
,
hang_kh_result as (
SELECT
    a.*except(tongdiem_tl),
    c1.hang_kh,
    c1.muc_diem_tu,
    c1.muc_diem_den,
    c1.thuong_thang_hang,
    c1.tien_quy_doi,
    a.tongdiem_tl + IFNULL(c1.thuong_thang_hang, 0) as tongdiem_tl,
    (a.tongdiem_tl + IFNULL(c1.thuong_thang_hang, 0) ) * cast(c1.tien_quy_doi as int) AS tien_quydoi,
    a.tongdiem_tl  + IFNULL(c1.thuong_thang_hang, 0)- a.diem_tl_da_sd as diem_tl_conlai,
    (a.tongdiem_tl + IFNULL(c1.thuong_thang_hang, 0) - a.diem_tl_da_sd) * cast(c1.tien_quy_doi as int)  as tien_quydoi_conlai,
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
    f.statedescr,
    f.shortterritorydescr,
    f.branchid,
    f.branchname,
FROM
    tong_diem_tl_t a
    LEFT JOIN `spatial-vision-343005.staging.d_manual_danhsach_commitment` c1 ON 
    tongdiem_tl >= c1.muc_diem_tu
    AND tongdiem_tl <= c1.muc_diem_den
    AND c1.hang_kh IS NOT NULL
    -- LEFT JOIN tuyen_dms_moinhat d on d.custid = a.ma_kh
    LEFT JOIN `warehouse.f_mapping_crs` l on l.custid = a.ma_kh 
    LEFT JOIN `staging.d_users` e on e.manv = l.col.ma_nvbh
    LEFT JOIN `staging.d_master_khachhang` f on f.custid = a.ma_kh
where contains_substr(concat(ifnull(e.supid,''),ifnull(l.col.ma_nvbh,'')),p_ma_crs)
and contains_substr(a.ma_kh,p_makhdms)

)

select 
'202311-TL-QD60-PCL' as ma_chuong_trinh,
branchid as ma_cn,
slsperid as ma_cvbh,
tencvbh as ten_cvbh,
supid as ma_ql_tt,
tenquanlytt as ten_ql_tt,
ma_kh,
custname as ten_khach_hang,
hcotypeid as ma_pl_hco,
ngay_sinh,
ngay_tham_gia,
ngay_ket_thuc
da_ky_bb_thoa_thuan,
hang_kh,
doanhsocovat as doanh_so_co_vat,
doanhsocovat_ks as doanh_so_co_vat_ks_th,
doanhsocovat_cl as doanh_so_co_vat_cl,
diem_quy_doi_ks_th,
diem_quy_doi_ks_cl as diem_quy_doi_cl,
thuong_thang_hang as diem_thuong_thang_hang,
diem_tich_luy_quan_tam_oa_dang_ky,
diem_tich_luy_sinh_nhat,
diem_tich_luy_sp_moitang_diem as diem_tich_luy_sp_moi_tang_diem,
tongdiem_tl as tong_diem_tl,
diem_tl_da_sd,
diem_tl_conlai as diem_tl_con_lai,
tien_quydoi as tien_quy_doi,
tien_quy_doi_da_sd,
tien_quydoi_conlai as tien_quy_doi_con_lai,
from hang_kh_result a

order by doanh_so_co_vat desc
;
END;