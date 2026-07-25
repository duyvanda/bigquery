CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_raw_data_sales_yoy(partition_date STRING)
BEGIN

/*
Auto refresh https://bi.meraplion.com/airflow/dags/SYNC_warehouse_pg
*/

DECLARE partition_date_3m_ago STRING;
SET partition_date_3m_ago = FORMAT_DATE('%Y-%m-%d', DATE_SUB(CAST(partition_date AS DATE), INTERVAL 3 MONTH));

CREATE TEMP TABLE `raw_data_sales_bytime_temp` PARTITION BY DATE(ngaychungtu) AS

(

WITH data_pda AS (
SELECT
    ordernbr,
    custid,
    branchid,
    'TMDT_001' AS crtd_user
FROM
    `staging.sync_dms_pda_so`
WHERE
    (
        crtd_user = 'TMDT_001'
        OR slsperid = 'TMDT_001'
    )
    AND date(crtd_datetime) >= date(partition_date_3m_ago)
)

,   api_orderforward_fix as (
SELECT
    DISTINCT
    d.idcodebranchoffice,
    d.idcodecus,
    d.productcode,
    d.idcodeorder,
    d.lotno,
    d.lineref,
    d.beforevatprice,
    d.beforevatamount,
    d.aftervatamount,
    d.quantity,
    FROM `staging.sync_api_orderforward` d
    WHERE d.idcodeorder NOT IN (
        "DL5-0123-01387",
        "DL5-0123-01389",
        "DL5-0123-00783",
        "DH0-0423-00167"
        )
        AND d.beforevatamount != 0
        and date(d.dateaddorder) >= date(partition_date_3m_ago)
UNION ALL
    SELECT
    DISTINCT
    d.idcodebranchoffice,
    d.idcodecus,
    d.productcode,
    d.idcodeorder,
    d.lotno,
    d.lineref,
    d.beforevatprice,
    d.beforevatamount,
    d.aftervatamount,
    d.quantity,
    FROM `staging.sync_api_orderforward_return` d
    WHERE true
        AND d.beforevatamount != 0
        and date(d.dateaddorder) >= date(partition_date_3m_ago)
)

, raw_data as(
    SELECT

        EXTRACT(YEAR FROM ngaychungtu) AS year,

        CASE
            WHEN EXTRACT(MONTH FROM ngaychungtu) <= 6 THEN 'C1.' || EXTRACT(YEAR FROM ngaychungtu)
            ELSE 'C2.' || EXTRACT(YEAR FROM ngaychungtu)
        END AS cycle,

        EXTRACT(MONTH FROM ngaychungtu) AS thang_number,
        a.macongtycn,

        CASE
            WHEN STARTS_WITH(a.macongtycn, 'M') THEN 'PHA NAM'
            ELSE 'MERAP'
        END AS phap_nhan,

        c.branchname AS congtycn,
        IFNULL(a.makhcu, a.makhdms) AS makhcu,
        a.makhdms,
        c.custname AS tenkhachhang,
        c.statedescr AS tentinhkh,
        c.statedescr AS statedescr,
        c.territorydescr AS territorydescr,

        CASE
            WHEN c.districtdescr IN ('Quận 2', 'Quận 9') THEN 'Thành phố Thủ Đức'
            ELSE c.districtdescr
        END AS districtdescr,

        c.wardname,
        c.shortterritorydescr AS khuvucviettat,
        c.cluster_state,
        c.hcoid,
        c.hcotypeid,
        c.classid,
        c.pubcustid,
        c.custidinvoice AS custidinvoice_dongnhat,
        c.custnameinvoice AS custnameinvoice_dongnhat,
        c.taxregnbr AS taxregnbr_dongnhat,
        c.custname AS custname_dongnhat,
        c.pubcustname,
        a.sodondathang,
        a.sodontrahang,
        a.ngaychungtu,
        a.ngaydatdon,
        EXTRACT(MONTH FROM a.ngaychungtu) AS month,
        a.thang,
        a.lineref,
        a.masanpham,
        a.tensanphamnb,
        a.tensanphamviettat,

        -- 26/7 update: hàng khuyến mãi không cộng số lượng
        CASE
            WHEN doanhsochuavat = 0 THEN 0
            ELSE a.soluong
        END AS soluong,

        soluong as soluongori,

        a.dongiachuavat,
        IFNULL(d.beforevatprice,a.dongiachuavat) as dongiachuavat_ori,
        a.dongiacovat,
        a.doanhsocovat,
        a.doanhsochuavat,

        CASE
            WHEN a.kieudonhang IN ('UP','DP') THEN b.beforevatprice * a.soluong
            WHEN a.soluong<0 AND a.doanhsochuavat != 0 THEN b.beforevatprice * a.soluong
            ELSE IFNULL(d.beforevatamount,a.doanhsochuavat)
            END AS doanhsochuavat_ori,

        CASE
            WHEN a.kieudonhang IN ('UP','DP') THEN b.aftervatprice * a.soluong
            WHEN a.soluong<0 AND a.doanhsochuavat != 0 THEN b.aftervatprice * a.soluong
            ELSE IFNULL(d.aftervatamount,a.doanhsocovat)
            END as doanhsocovat_ori,
    
        a.kieudonhang,
        Case when a.doanhsochuavat = 0 then 'Hàng KM' else 'Hàng bán' end as is_hang_km,

        CASE
            WHEN makhdms IN ('008140', '003589', '013410', '018851','019455') THEN 'ECE'
            WHEN a.masanpham = 'EH092'
                AND ngaychungtu >= '2024-04-01'
                AND a.makenhkh = 'INS' THEN 'CLC'
            ELSE a.makenhkh
        END AS makenhkh_cu,

        CASE
            WHEN a.masanpham = 'EH092' AND ngaychungtu >= '2024-04-01' AND a.makenhphu = 'INS1' THEN 'CLC1'
            WHEN a.masanpham = 'EH092' AND ngaychungtu >= '2024-04-01' AND a.makenhphu = 'INS2' THEN 'CLC2'
            WHEN a.masanpham = 'EH092' AND ngaychungtu >= '2024-04-01' AND a.makenhphu = 'INS3' THEN 'CLC3'
            ELSE a.makenhphu
        END AS makenhphu_cu,

        Case
        WHEN a.makhdms IN ('008140', '003589', '013410', '018851','019455') THEN 'ECE'
        when a.masanpham ='EH092' and ngaychungtu >='2024-04-01' 
        and ifnull(c.channel,a.makenhkh) ='INS' then 'CLC' else ifnull(c.channel,a.makenhkh) 
        end as makenhkh,
        
        Case
            when  a.masanpham ='EH092' and ngaychungtu >='2024-04-01' and ifnull(c.shoptype,a.makenhphu) ='INS1' then 'CLC1'
            when  a.masanpham ='EH092' and ngaychungtu >='2024-04-01' and ifnull(c.shoptype,a.makenhphu) ='INS2' then 'CLC2'
            when  a.masanpham ='EH092' and ngaychungtu >='2024-04-01' and ifnull(c.shoptype,a.makenhphu) ='INS3' then 'CLC3'
            when c.shoptype ='SI23' then 'SI' 
            else ifnull(c.shoptype,a.makenhphu)
        end as makenhphu,


        a.mahco AS mahco_cu,
        a.maphanhanghco as maphanhanghco_cu,
        a.maphanloaihco AS maphanloaihco_cu,
        a.mahd,
        a.solo,
        l.expdate,
        a.hoadon,

        CASE
            WHEN UPPER(IFNULL(a3.crtd_user, a.manv)) LIKE '%KN%'
                THEN LEFT(IFNULL(a3.crtd_user, a.manv), 6)
            ELSE IFNULL(a3.crtd_user, a.manv)
        END AS manv,

        CASE
            WHEN a3.ordernbr IS NOT NULL THEN 'Ecom'
            ELSE 'Merap'
        END AS is_ecom,

        IFNULL(e.nhomcpa, 'OTHERS') AS datatype,
        e.spcl2023tp_mt,
        e.spcl2023pcl_clc_ins,
        -- IFNULL(e.spcl2023tp_mt, e1.spcl2023tp_mt) AS spcl2023tp_mt,
        -- IFNULL(e.spcl2023pcl_clc_ins, e1.spcl2023pcl_clc_ins) AS spcl2023pcl_clc_ins,

        Case when a.makenhkh in ('TP','MT') then e.spcl2023tp_mt --IFNULL(e.spcl2023tp_mt, e1.spcl2023tp_mt) 
            when a.makenhkh in ('INS','CLC','PCL') then e.spcl2023pcl_clc_ins --then IFNULL(e.spcl2023pcl_clc_ins, e1.spcl2023pcl_clc_ins)  
            else null 
        end as spcl2023_all,
        
        e.brand2023,
        e.brand,
        --IFNULL(e.brand2023, e1.brand2023) AS brand2023,
        --IFNULL(e.brand, e1.brand) AS brand,
        e.brandnew2023,
        --IFNULL(e.brandnew2023, e1.brandnew2023) AS brandnew2023,
        e.branddongnhat,
        --IFNULL(e.branddongnhat, e1.branddongnhat) AS branddongnhat,
        a.manv AS ori_manv,
        a.manvgh,
        a.nguoigiaohang as ten_nvgh,
        a.donvigiaohang,

        f.invoicecustid,
        f.custinvcname,
        f.taxregnbr,
        f.invcnote,
        k.descr as thoi_han_thanh_toan,

        case
            when f.paymentsform = 'A' then	'Chuyển Khoản'
            when f.paymentsform = 'B' then 'Tiền Mặt'
            when f.paymentsform = 'C' then 'Tiền Mặt/Chuyển Khoản'
            when f.paymentsform = 'D'	then 'Ghi Nợ'
            when f.paymentsform = 'E'	then 'TM/CK/CTH'
            when f.paymentsform = 'F' then	'Cấn Trừ Nợ'
        else f.paymentsform 
        end as hinh_thuc_thanh_toan,

        a.inserted_at AS updated_at,
        'MERAP' AS is_phanam,
        g.classid AS phan_hang_c2_2023,
        h.classid AS phan_hang_c1_2024,
        j.descr as ten_sp_day_du,
        t.ten_mien,
        t.chinhanh_sc as cn_dia_ly

    FROM
    `staging.f_sales` a
    LEFT JOIN data_pda a3 on a3.ordernbr = a.sodondathang
    and a3.branchid = a.macongtycn
    LEFT JOIN `staging.d_master_khachhang` c on c.custid = a.makhdms
    LEFT JOIN `staging.d_nhom_sp_trading` e ON e.masanpham = a.masanpham
    --LEFT JOIN `staging.d_nhom_sp_trading_bytime` e1 ON e1.masanpham = a.masanpham AND EXTRACT(YEAR FROM ngaychungtu) < 2025 AND e1.nam = 2024
    LEFT JOIN `staging.sync_dms_so` f ON f.ordernbr = a.mahd AND f.branchid = a.macongtycn and date(f.crtd_datetime) >= date(partition_date_3m_ago)
    LEFT JOIN `staging.sync_dms_sod1` b ON b.branchid = a.macongtycn AND b.ordernbr = a.mahd AND a.lineref = b.lineref 
    AND date(b.crtd_datetime) >= date(partition_date_3m_ago)
    LEFT JOIN `staging.d_master_khachhang_bytime` g ON a.makhdms = g.custid AND g.thang = '2023-12-01'
    LEFT JOIN `staging.d_master_khachhang_bytime` h ON a.makhdms = h.custid AND h.thang = '2024-06-01'
    LEFT JOIN `staging.d_dms_master_invtid` j on j.invtid = a.masanpham
    LEFT JOIN `staging.d_tinh` t on c.statedescr = t.tinh
    LEFT JOIN `staging.d_manual_terms_detail` k on k.termsid = f.terms
    LEFT JOIN `staging.sync_dms_lt` l on l.branchid = a.macongtycn and l.ordernbr = a.mahd and l.omlineref = a.lineref and a.solo = l.lotsernbr
        AND date(l.crtd_datetime) >= date(partition_date_3m_ago)

    LEFT JOIN `api_orderforward_fix` d 
        ON d.idcodebranchoffice = a.macongtycn AND d.idcodecus = a.makhdms AND d.productcode = a.masanpham 
            AND d.idcodeorder = a.sodondathang AND a.solo = d.lotno and a.lineref = d.lineref
            AND a.doanhsochuavat != 0
    WHERE
        date(a.ngaychungtu) >= date(partition_date)
        AND LEFT(a.masanpham, 1) != 'V'
        AND makenhkh not in ('NB')
        AND
        (
        CASE
        WHEN makhdms IN ('008140', '003589', '013410', '018851','019455') THEN TRUE
        WHEN makenhkh in ('OTH_LAB','EXP') THEN TRUE
        WHEN a.manv NOT IN ('GH001', 'QUYNHPTA', 'MA001', 'MA002') THEN TRUE
        ELSE FALSE END
        )
        -- AND makhdms not in ('016010', '016020','016022','016023','016021')
)
, t2 as (
SELECT
    a.* EXCEPT(manv), -- mapping lại cột mã NV
    CASE 
        WHEN l.col.phan_loai_mcp = 'Rural' THEN LEFT(l.col.ma_nvbh,6)
        WHEN a.manv = 'TMDT_001' THEN LEFT(l.col.ma_nvbh,6)
        WHEN a.manv IN (
              'MR1682KN','MR2504','MR1232','MR0806','MR2608','MR2111','MR1682','MR2504KN',
              'MR1232KN','MR0806KN','MR2608KN','MR2111KN','MR2993','MR2993KN','MR3038','MR3038KN',
              'MR2948','MR2948KN','MR2608','MR3196','MR3196KN'
          )
        THEN LEFT(l.col.ma_nvbh,6)
        ELSE a.manv
    END AS manv,

    CASE 
        WHEN l.col.phan_loai_mcp = 'Rural' THEN 'Rural'
        WHEN a.manv = 'TMDT_001' AND l.col.phan_loai_mcp = 'CRS (Trong MCP)' THEN 'Trong MCP (Ecom)'
        WHEN a.manv = 'TMDT_001' AND l.col.phan_loai_mcp = 'CRS (Ngoài MCP)' THEN 'Ngoài MCP (Ecom)'
        WHEN a.manv IN (
              'MR1682KN','MR2504','MR1232','MR0806','MR2608','MR2111','MR1682','MR2504KN',
              'MR1232KN','MR0806KN','MR2608KN','MR2111KN','MR2993','MR2993KN','MR3038','MR3038KN',
              'MR2948','MR2948KN','MR2608','MR3196','MR3196KN'
          ) 
        THEN 'Ngoài MCP (CX)'
        ELSE 'Trong MCP'
    END AS phanloai_tuyen_chitiet

FROM raw_data a
LEFT JOIN `warehouse.f_mapping_crs_bytime` l ON l.custid = a.makhdms AND DATE_TRUNC(ngaychungtu, MONTH) = l.thang
LEFT JOIN `staging.d_users_bytime` b ON b.manv = a.manv AND DATE(a.thang) = DATE(b.thang)


)

, t3 as 
(
SELECT
    a.*,
        CASE 
        WHEN phanloai_tuyen_chitiet IN ('Rural') THEN 'Rural'
        WHEN phanloai_tuyen_chitiet IN ('Ngoài MCP (Ecom)', 'Ngoài MCP', 'Ngoài MCP (CX)') THEN 'Ngoài MCP'
        WHEN phanloai_tuyen_chitiet IN ('Trong MCP', 'Trong MCP (Ecom)') THEN 'Trong MCP'
        ELSE 'Khác'
    END AS phanloai_tuyen,

    CASE
        WHEN a.manv = 'CX' THEN 'MR1682'
        ELSE LEFT(b.supid, 6)
    END AS ma_crm,

    b.asm AS scrm,

    CASE
        WHEN a.manv = 'CX' AND ngaychungtu >= '2024-01-01' THEN 'MR0485'
        WHEN b.tenquanlytt = 'Lê Thị Hương Sa' THEN b.supid
        ELSE LEFT(b.rsmid, 6)
    END AS ma_ncxm,

    CASE
        WHEN a.manv = 'CX' THEN 'CX'
        ELSE b.tencvbh
    END AS tencvbh,

    CASE
        WHEN a.manv = 'CX' THEN 'Đinh Thị Ngọc Mẫn'
        ELSE b.tenquanlytt
    END AS tenquanlytt,

    b.tenquanlykhuvuc,

    CASE
        WHEN b.tenquanlytt = 'Lê Thị Hương Sa' THEN 'Lê Thị Hương Sa'
        WHEN a.manv = 'CX' AND ngaychungtu >= '2024-01-01' THEN 'Nguyễn Hoàng Viển'
        WHEN a.manv = 'CX' THEN 'Nguyễn Thị Ngọc Diệp'
        ELSE IFNULL(b.tenquanlyvung, 'Chưa xác định')
    END AS tenquanlyvung,

    CASE
        WHEN a.makenhkh IN ('INS','CLC','PCL') THEN 'HCP'
        WHEN a.makenhkh IN ('TP','GT') THEN 'TP'
        WHEN a.makenhkh = 'MT' THEN 'MT'
        ELSE NULL
    END AS phong_kh,

    CASE
        WHEN a.makenhkh_cu IN ('INS', 'CLC', 'PCL') THEN 'HCP'
        WHEN a.makenhkh_cu IN ('TP','GT') THEN 'TP'
        WHEN a.makenhkh_cu = 'MT' THEN 'MT'
        ELSE NULL
    END AS phong_kh_cu,

    SUM(a.doanhsochuavat) OVER(PARTITION BY a.thang) AS ds_sp_thang,
    CURRENT_DATETIME("+7") AS inserted_at

FROM t2 a
LEFT JOIN `staging.d_users_bytime` b ON b.manv = a.manv AND DATE(a.thang) = DATE(b.thang)
)

,don_hang_da_giao as(
select 
  dv.crtd_datetime as crtd_datetime_dv, 
  dv.branchid,
  dv.ordernbr,
  dv.status as status_dv,
  dv.delivery_date
FROM `staging.sync_dms_dv` dv
  where dv.delivery_date IS NOT NULL AND dv.status = 'C'  
)

select a.*,
a.manv AS manv_dongnhat,
c.tencvbh AS tencvbh_dongnhat,
c.supid AS ma_crm_dongnhat,
c.tenquanlytt AS tenquanlytt_dongnhat,
b.ma_cre,
b.ho_ten_cre,

CASE WHEN a.ma_crm = 'MR1682' THEN 'MR0485' ELSE c.asm END AS ma_scrm_dongnhat,

CASE WHEN a.ma_crm = 'MR1682' THEN 'Nguyễn Hoàng Viển(KN)' ELSE c.tenquanlykhuvuc END AS tenquanlykhuvuc_dongnhat,

CASE
    WHEN a.makenhkh IN ('INS', 'CLC', 'PCL') THEN 'MR1137'
    WHEN a.makenhkh = 'TP' THEN 'MR0485'
    WHEN a.makenhkh = 'MT' THEN 'MR2685'
    ELSE NULL
END AS ma_ncxm_dongnhat,

CASE
    WHEN a.makenhkh IN ('INS', 'CLC', 'PCL') THEN 'Vũ Mừng'
    WHEN a.makenhkh = 'TP' THEN 'Nguyễn Hoàng Viển'
    WHEN a.makenhkh = 'MT' THEN 'Lê Thị Hương Sa'
    ELSE NULL
END AS tenquanlyvung_dongnhat,

CASE
    WHEN dv.ordernbr IS NOT NULL THEN 'Đã giao hàng'
    ELSE 'Chưa giao hàng' END AS trang_thai_giao_hang,
CASE
    WHEN a.makenhkh_cu in ('TP','PCL') THEN t.ma_tuyenbh ELSE NULL END AS ma_tuyenbh,
CASE
    WHEN a.makenhkh_cu in ('TP','PCL') THEN t.tentuyen ELSE NULL END AS tentuyen,


FROM t3 a
LEFT JOIN `staging.d_users` c ON a.manv = c.manv
LEFT JOIN don_hang_da_giao dv ON dv.ordernbr = a.sodondathang AND dv.branchid = a.macongtycn
LEFT JOIN `warehouse.f_thongtin_tuyen_mcp_tp_pcl` t ON t.thang = a.thang AND t.ma_khachhang = a.makhdms
LEFT JOIN `staging.d_calendar_cre` b ON a.manv = b.ma_crs AND date(b.thang) = date(a.thang)

);

-- Create or replace table `warehouse.f_raw_data_sales_yoy`
-- copy `raw_data_sales_bytime_temp`;

BEGIN TRANSACTION;
DELETE FROM
    `warehouse.f_raw_data_sales_yoy`
WHERE
    DATE(ngaychungtu) >= DATE(partition_date);
INSERT INTO
    `warehouse.f_raw_data_sales_yoy`
SELECT
    *
FROM
    `raw_data_sales_bytime_temp`;
COMMIT TRANSACTION;
END;