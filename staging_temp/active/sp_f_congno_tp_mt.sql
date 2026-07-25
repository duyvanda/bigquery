CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_congno_tp_mt()
BEGIN 

CREATE TEMP TABLE `f_congno_tp_mt_temp` AS 
WITH
congno AS (
    SELECT
        a.BranchID,
        a.slsperid,
        a.CustId,
        a.DocType,
        a.Ordnbr,
        a.docdesc,
        a.InvcNote,
        a.InvcNbr,
        a.mahd_so,
        a.sotien_nogoc,
        a.sotien_da_thanhtoan,
        a.so_du_chungtu,
        a.dateoforder,
        a.duedate,
        a.orderdate,
        a.so_du_dh,
        a.phan_loai_no as phanloaino,
        a.thoigian_noqh,
        -- a.terms,
        a.day_terms,
        a.terms_name AS terms,
        a.is_diadiem,
        a.thoi_diem_no_vang,
        a.thoi_diem_no_do,
        a.thoi_diem_no_den,

        a.channel AS channel,
        a.shoptype AS shoptype,
        a.districtdescr,
        a.statedescr AS statedescr,
        a.wardname,
        a.custname AS custname,
        a.paymentsform AS paymentsform_goc,
        a.paymentsform_hien_tai AS paymentsform,
        a.refcustid AS refcustid,
        a.territorydescr AS territorydescr,
        b.firstname AS ten_nvgh,
        a.manv
        
    FROM
        `staging_temp.d_rawdata_debt` a
        LEFT JOIN `staging.d_dms_master_users` b ON a.slsperid = b.username
    WHERE
        a.channel IN ('TP')
        AND (
            left(lower(a.custname), 5) <> 'xuất '
            OR lower(a.custname) NOT LIKE '%anh sách%'
            OR lower(a.custname) NOT LIKE '%quà%'
        )

        AND (
                so_du_dh > 1000
                OR so_du_dh < -1000
        )
),
result0 as (

SELECT
    a.* EXCEPT(manv),
    case when a.shoptype IN ('PMC','CTD','PCL', 'NT', 'PK', 'SI', 'SI23') 
              AND paymentsform_goc in ('B','C') 
              and terms in ('Thu tiền ngay có VP PN','Thu tiền ngay không có VP PN', 
                              'Gối 1 Đơn Hàng (trong 30 ngày)','Gối Đầu 30 Pha Nam','30 Ngày',
                              'TT vào ngày 25 hàng tháng','Thời hạn thanh toán 10 ngày','15 Ngày','7 Ngày')  THEN 'MDS'
         when a.shoptype in ('CHUOI', 'NTC','CCD','ECOM') 
              AND paymentsform_goc in ('B','C') 
              AND terms in ('Thu tiền ngay có VP PN','Thu tiền ngay không có VP PN') THEN 'MDS' 
         else 'PBH' end as phong_phu_trach_no,

    case when a.shoptype IN ('PMC','CTD','PCL', 'NT', 'PK', 'SI', 'SI23') 
              AND paymentsform_goc in ('B','C') 
              and terms in ('Thu tiền ngay có VP PN','Thu tiền ngay không có VP PN', 
                              'Gối 1 Đơn Hàng (trong 30 ngày)','Gối Đầu 30 Pha Nam','30 Ngày',
                              'TT vào ngày 25 hàng tháng','Thời hạn thanh toán 10 ngày','15 Ngày','7 Ngày')  THEN a.slsperid
         when a.shoptype in ('CHUOI', 'NTC','CCD','ECOM') 
              AND paymentsform_goc in ('B','C') 
              AND terms in ('Thu tiền ngay có VP PN','Thu tiền ngay không có VP PN') THEN a.slsperid 
         else a.manv end as ma_nv_phu_trach_no,
    a.manv as ma_crs,
    timestamp(current_datetime("+7")) inserted_at
FROM
    congno a
    --LEFT JOIN `warehouse.f_mapping_crs` l on l.custid = a.custid
)

select
a.*,
c.tencvbh,
c.supid as ma_crm,
c.tenquanlytt,
c.asm as ma_scrm,
c.tenquanlykhuvuc,
c.rsmid as ma_ncxm,
c.tenquanlyvung,
b.tencvbh as nv_phu_trach_no,

from result0 a 
LEFT JOIN `staging.d_users` c on a.ma_crs = c.manv
LEFT JOIN `staging.d_users` b on a.ma_nv_phu_trach_no = b.manv;


Create or replace table `warehouse.f_congno_tp_mt`

COPY `f_congno_tp_mt_temp`;


END;