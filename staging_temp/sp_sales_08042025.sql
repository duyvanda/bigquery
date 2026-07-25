CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_sales_08042025()
BEGIN 
 
TRUNCATE TABLE staging_temp.f_sales_crs_temp;
INSERT INTO `staging_temp.f_sales_crs_temp`

(   
-- Create or replace table `staging_temp.f_sales_crs_temp`
-- partition by date(ngaychungtu)
-- cluster by makhdms,sodondathang,mahd,manv
-- as
WITH data_pda AS (
    SELECT
        ordernbr,
        custid,
        branchid,
        'TMDT_001' AS crtd_user
    FROM
        `spatial-vision-343005.staging.sync_dms_pda_so`
    WHERE
        (
            crtd_user = 'TMDT_001'
            OR slsperid = 'TMDT_001'
        )
        AND crtd_datetime >= '2022-06-01' --or slsperid ='TMDT_001'
),
--Update từ ngày 1/4
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
            delroutedet IS FALSE
    )
    SELECT
        *
    FROM
        data_tuyen QUALIFY ROW_NUMBER() OVER (
            PARTITION BY custid
            ORDER BY
                routetype ASC,
                crtd_datetime DESC
        ) = 1
),
---Tuyến bán hàng theo hợp đồng
tuyen_cvbh_hd AS (
    SELECT
        *,
        ROW_NUMBER() OVER(
            PARTITION BY custid
            ORDER BY
                crtd_date DESC
        ) AS loc
    FROM
        `spatial-vision-343005.staging.d_get_contract_det` QUALIFY ROW_NUMBER() OVER(
            PARTITION BY custid
            ORDER BY
                crtd_date DESC
        ) = 1
),
cum_tinh_quan_huyen AS (
    SELECT
        DISTINCT statedescr,
        districtdescr,
        cluster_state
    FROM
        staging.d_leadtimekpi
    WHERE
        districtdescr != 'Huyện Bình Chánh'
),
cum_phuong_xa AS (
    SELECT
        DISTINCT statedescr,
        districtdescr,
        wardname,
        cluster_state
    FROM
        staging.d_leadtimekpi
    WHERE
        districtdescr = 'Huyện Bình Chánh'
),
data AS(
    SELECT
        a.macongtycn,
        d.branchname AS congtycn,
        CASE
            WHEN ngaychungtu < '2023-01-01'
            AND makhdms = 'MC014'
            AND IFNULL(d.channel, a.makenhkh) = 'DLPP' THEN 'DLPP3'
            WHEN ngaychungtu < '2023-01-01'
            AND makhdms = 'N06202285'
            AND IFNULL(d.channel, a.makenhkh) = 'DLPP' THEN 'CTD'
            WHEN ngaychungtu < '2023-01-01'
            AND(
                d.active <> 'Active'
                OR d.active IS NULL
            )
            AND IFNULL(d.channel, a.makenhkh) = 'DLPP'
            AND IFNULL(d.shoptype, a.makenhphu) LIKE '%DLPP%' THEN 'CTD'
            WHEN ngaychungtu < '2023-01-01'
            AND IFNULL(d.channel, a.makenhkh) = 'OTC'
            AND IFNULL(d.shoptype, a.makenhphu) IN ('DLPP') THEN 'CTD'
            WHEN ngaychungtu < '2023-01-01' THEN IFNULL(d.hcoid, a.mahco)
            ELSE d.hcoid
        END AS mahco,
        -- d.hcoid as mahco,
        -- d.hcotypeid  as maphanloaihco,
        CASE
            WHEN ngaychungtu < '2023-01-01'
            AND makhdms = 'MC014'
            AND IFNULL(d.channel, a.makenhkh) = 'DLPP' THEN 'NT'
            WHEN ngaychungtu < '2023-01-01'
            AND makhdms = 'N06202285'
            AND IFNULL(d.channel, a.makenhkh) = 'DLPP' THEN 'CTD'
            WHEN ngaychungtu < '2023-01-01'
            AND (
                d.active <> 'Active'
                OR d.active IS NULL
            )
            AND IFNULL(d.channel, a.makenhkh) = 'DLPP'
            AND IFNULL(d.shoptype, a.makenhphu) LIKE '%DLPP%' THEN 'CTD'
            WHEN ngaychungtu < '2023-01-01'
            AND IFNULL(d.channel, a.makenhkh) = 'OTC'
            AND IFNULL(d.shoptype, a.makenhphu) IN ('DLPP') THEN 'CTD'
            WHEN ngaychungtu < '2023-01-01' THEN IFNULL(d.hcotypeid, a.maphanloaihco)
            ELSE d.hcotypeid
        END AS maphanloaihco,
        IFNULL(a.makhcu, a.makhdms) AS makhcu,
        a.makhdms,
        d.custname AS tenkhachhang,
        d.statedescr AS tentinhkh,
        d.statedescr AS statedescr,
        d.territorydescr AS territorydescr,
        CASE
            WHEN d.districtdescr IN ('Quận 2', 'Quận 9') THEN 'Thành phố Thủ Đức'
            ELSE d.districtdescr
        END AS districtdescr,
        d.wardname,
        d.shortterritorydescr AS khuvucviettat,
        a.sodondathang,
        a.ngaychungtu,
        EXTRACT(
            MONTH
            FROM
                a.ngaychungtu
        ) AS MONTH,
        a.thang,
        a.masanpham,
        e.descr AS tensanphamnb,
        e.descr1 AS tensanphamviettat,
        CASE
            WHEN doanhsochuavat = 0 THEN 0
            ELSE a.soluong
        END AS soluong,
        ---- 26/7 update hàng khuyến mãi k cộng số lượng
        -- a.soluong,
        a.dongiachuavat,
        a.dongiacovat,
        a.doanhsocovat,
        a.doanhsochuavat,
        CASE
            WHEN upper(IFNULL(a3.crtd_user, a.manv)) LIKE '%KN' THEN LEFT(IFNULL(a3.crtd_user, a.manv), 6)
            ELSE IFNULL(a3.crtd_user, a.manv)
        END AS manv,
        -- Case
        --     when a.masanpham ='EH092' and ngaychungtu >='2024-04-01' and makenhkh ='INS' then 'CLC'
        --     when a.makhdms  in ('008140', '003589') then 'ECE'
        --     when a.makhdms = 'M1017123' then 'TP' ----- Thời điểm post đơn KH vẫn là OTC 
        --     when a.makenhkh = 'DLPP'
        --     and ngaychungtu < '2023-01-01' THEN 'OTC'
        --     when a.makenhkh = 'DLPP' then 'TP'            
        --     else a.makenhkh
        -- end as makenhkh,
        a.makenhkh,
        a.tenkenhkh,
        CASE
            WHEN ngaychungtu < '2023-01-01'
            AND IFNULL(d.shoptype, a.makenhphu) = 'PK'
            AND d.channel = 'OTC' THEN 'PCL'
            WHEN ngaychungtu < '2023-01-01'
            AND IFNULL(d.shoptype, a.makenhphu) IN('DCYK', 'NT')
            AND d.channel = 'OTC' THEN 'PMC'
            WHEN ngaychungtu < '2023-01-01'
            AND IFNULL(d.channel, a.makenhkh) = 'OTC'
            AND IFNULL(d.shoptype, a.makenhphu) IN ('CHUOI')
            AND d.hcoid = 'MT' THEN 'CCD'
            WHEN ngaychungtu < '2023-01-01'
            AND makhdms = 'MC014'
            AND IFNULL(d.channel, a.makenhkh) = 'DLPP' THEN 'PMC'
            WHEN ngaychungtu < '2023-01-01'
            AND makhdms = 'N06202285'
            AND IFNULL(d.channel, a.makenhkh) = 'DLPP' THEN 'CTD'
            WHEN ngaychungtu < '2023-01-01'
            AND (
                d.active <> 'Active'
                OR d.active IS NULL
            )
            AND IFNULL(d.channel, a.makenhkh) = 'DLPP'
            AND IFNULL(d.shoptype, a.makenhphu) LIKE '%DLPP%' THEN 'CTD'
            WHEN ngaychungtu < '2023-01-01'
            AND IFNULL(d.channel, a.makenhkh) = 'OTC'
            AND IFNULL(d.shoptype, a.makenhphu) IN ('DLPP') THEN 'CTD'
            WHEN ngaychungtu < '2023-01-01'
            AND IFNULL(d.shoptype, a.makenhphu) = 'SI23' THEN 'SI' -- when ngaychungtu < '2023-01-01' then ifnull(d.shoptype,a.makenhphu)
            WHEN a.masanpham = 'EH092'
            AND ngaychungtu >= '2024-04-01'
            AND IFNULL(d.shoptype, a.makenhphu) = 'INS1' THEN 'CLC1'
            WHEN a.masanpham = 'EH092'
            AND ngaychungtu >= '2024-04-01'
            AND IFNULL(d.shoptype, a.makenhphu) = 'INS2' THEN 'CLC2'
            WHEN a.masanpham = 'EH092'
            AND ngaychungtu >= '2024-04-01'
            AND IFNULL(d.shoptype, a.makenhphu) = 'INS3' THEN 'CLC3'
            WHEN d.shoptype = 'SI23' THEN 'SI'
            ELSE IFNULL(d.shoptype, a.makenhphu)
        END AS makenhphu,
        a.tenkenhphu,
        0 AS kh_total,
        CASE
            WHEN a.manv = 'MR0868'
            AND a.masanpham IN ('EH115', 'EBS10', 'OH082', 'MDR125KC')
            AND (
                a.makenhphu IN('SI')
                OR a.makenhkh IN ('MT')
            ) THEN doanhsochuavat
            WHEN a.masanpham IN ('EH115', 'EBS10', 'OH082', 'MDR125KC')
            AND a.makenhkh IN ('TP', 'PCL') THEN doanhsochuavat
            WHEN a.masanpham IN ('EH092', 'OH082', 'EH115', 'EH102', 'OH076')
            AND makenhkh IN ('OTC', 'DLPP')
            AND ngaychungtu >= '2022-04-01'
            AND ngaychungtu < '2022-07-01' THEN doanhsochuavat
            WHEN a.masanpham IN ('EH115', 'OH080', 'OH082')
            AND ngaychungtu >= '2022-01-01'
            AND ngaychungtu < '2022-04-01'
            AND makenhkh IN ('OTC', 'DLPP') THEN doanhsochuavat
            WHEN a.masanpham IN ('EH092', 'OH082', 'OH083', 'EH102', 'EH115')
            AND ngaychungtu >= '2022-07-01'
            AND makenhkh IN ('OTC', 'DLPP') THEN doanhsochuavat
            ELSE 0
        END AS thuchien_spmoi,
        0 AS kh_spmoi,
        CASE
            WHEN a.makenhphu IN ('INS2', 'INS3', 'CLC2', 'CLC3') THEN doanhsochuavat
            ELSE 0
        END AS thuchien_yttn,
        0 AS kh_yttn,
        CASE
            WHEN a.masanpham IN (
                'EH072',
                'EH105',
                'OH016',
                'OH032',
                'OH047',
                'OH057',
                'OH058',
                'OH071',
                'OH079',
                'OH081'
            )
            AND ngaychungtu < '2023-01-01' THEN 'PHANAM'
            ELSE 'MERAP'
        END AS is_phanam,
        'f_sales' AS datatype1,
        CASE
            WHEN a3.ordernbr IS NOT NULL THEN 'Ecom'
            ELSE 'Merap'
        END AS is_ecom,
        a.manvghreal,
        a.pda_crtd_user,
        a.pda_slsperid,
        a.hoadon,
        cast(0 AS float64) AS slpp_ebysta,
        cast(0 AS float64) AS slpp_medoral,
        0 AS kpi_ds_pcl,
        ---SLPP Sản phẩm 1 
        CASE
            ---2024 chuyển sptt qua XP
            -- when a.ngaychungtu >='2024-03-01' and a.makenhkh ='MT' then makhdms
            WHEN a.ngaychungtu >= '2024-10-01'
            AND a.ngaychungtu < '2024-11-01'
            AND masanpham IN ('T303102009')
            AND a.makenhkh = 'TP'
            AND doanhsochuavat <> 0
            AND sum(soluong) over (
                PARTITION by doanhsochuavat <> 0,
                IFNULL(sodontrahang, sodondathang),
                makhdms,
                masanpham
            ) >= 5 THEN makhdms
            WHEN a.ngaychungtu >= '2024-07-01'
            AND a.ngaychungtu < '2024-10-01'
            AND masanpham IN ('T302203003')
            AND a.makenhkh = 'TP'
            AND soluong > 0
            AND doanhsochuavat > 0
            AND sum(soluong) over (PARTITION by macongtycn, sodondathang, masanpham) >= 5 -- and sum(soluong) over (partition by macongtycn,ifnull(sodondathang, sodontrahang),masanpham) >= 5
            THEN IFNULL(makhcu, makhdms)
            WHEN a.ngaychungtu >= '2024-04-01'
            AND ngaychungtu < '2024-07-01'
            AND masanpham IN ('T3044004')
            AND a.makenhkh = 'TP'
            AND soluong > 0
            AND doanhsochuavat > 0
            AND sum(soluong) over (PARTITION by macongtycn, sodondathang, masanpham) >= 3 THEN IFNULL(makhcu, makhdms)
            WHEN a.ngaychungtu >= '2024-01-01'
            AND ngaychungtu < '2024-04-01'
            AND masanpham IN ('T302202003', 'T302202004', 'T302202005')
            AND a.makenhkh = 'TP'
            AND doanhsochuavat > 0 THEN IFNULL(makhcu, makhdms) ---quý 1,2 2023 sptt qua ebysta
            WHEN a.ngaychungtu < '2023-10-01'
            AND masanpham = 'EH115'
            AND a.makenhkh = 'TP'
            AND doanhsochuavat > 0 THEN IFNULL(makhcu, makhdms)
            ELSE NULL
        END AS th_slpp_ebysta,
        ---SLPP Sản phẩm 2
        CASE
            WHEN a.ngaychungtu >= '2024-07-01' THEN NULL -- k có tiêu chí sp2
            WHEN a.ngaychungtu >= '2024-04-01'
            AND a.ngaychungtu < '2024-07-01'
            AND masanpham IN ('T302204004')
            AND a.makenhkh = 'TP'
            AND soluong > 0
            AND doanhsochuavat > 0
            AND sum(soluong) over (PARTITION by macongtycn, sodondathang, masanpham) >= 3 THEN IFNULL(makhcu, makhdms)
            WHEN a.ngaychungtu >= '2024-01-01'
            AND ngaychungtu < '2024-04-01'
            AND masanpham IN ('T302105002')
            AND a.makenhkh = 'TP'
            AND doanhsochuavat > 0 THEN IFNULL(makhcu, makhdms)
            WHEN ngaychungtu >= '2023-10-01' THEN NULL -- tháng 10 chuyển sang kpi doanh số sản phẩm tt XPL
            WHEN masanpham IN('EH092', 'OH082', 'OH084', 'EH102', 'EH121')
            AND a.makenhkh = 'TP'
            AND doanhsochuavat > 0
            AND ngaychungtu < '2023-07-01' THEN IFNULL(makhcu, makhdms)
            WHEN masanpham IN(
                'OH074',
                'OH075',
                'OH077',
                'OH078',
                'T302101008',
                'T302101007',
                'T302101006',
                'T302101005'
            )
            AND a.makenhkh = 'TP'
            AND doanhsochuavat > 0
            AND ngaychungtu >= '2023-09-01'
            AND a.ngaychungtu < '2024-01-01'
            AND sum(soluong) over (
                PARTITION by macongtycn,
                sodondathang,
                (
                    CASE
                        WHEN masanpham IN (
                            'OH074',
                            'OH075',
                            'OH077',
                            'OH078',
                            'T302101008',
                            'T302101007',
                            'T302101006',
                            'T302101005'
                        ) THEN 1
                        ELSE 2
                    END
                )
            ) >= 3 THEN IFNULL(makhcu, makhdms) --tháng 9 tính tổng sl shema trên 1 đơn hàng >=3 mới tính 1 phân phối
            WHEN masanpham IN(
                'OH074',
                'OH075',
                'OH077',
                'OH078',
                'T302101008',
                'T302101007',
                'T302101006',
                'T302101005'
            )
            AND a.makenhkh = 'TP'
            AND doanhsochuavat > 0
            AND ngaychungtu >= '2023-07-01'
            AND ngaychungtu < '2023-09-01' THEN IFNULL(makhcu, makhdms) --tháng 7 đổi medoral qua shema lá đôi
            ELSE NULL
        END AS th_slpp_medoral,
        CASE
            WHEN makenhkh = 'PCL' THEN doanhsochuavat
            ELSE 0
        END AS th_ds_pcl,
        CASE
            ----Từ 2024 chị Nga phụ trách SPTT Ebysta còn Đạt phụ trách FMCG
            ---Tháng 3/2024 bỏ doanh số kênh phụ ECOM ra
            WHEN ngaychungtu >= '2024-03-01'
            AND (
                manv IN('MR3057', 'MR3066', 'MR3070')
                OR tenquanlytt IN ('Dương Thanh Sơn')
            )
            AND makenhphu IN('FMCG')
            AND makenhkh = 'MT'
            AND makhdms NOT IN ('008140', '003589') THEN doanhsochuavat
            WHEN ngaychungtu < '2024-03-01'
            AND ngaychungtu >= '2024-01-01'
            AND manv = 'MR3057'
            AND makenhphu IN('ECOM', 'FMCG')
            AND makenhkh = 'MT'
            AND makhdms NOT IN ('008140', '003589') THEN doanhsochuavat
            WHEN (
                manv IN ('MR0868', 'MR1360')
                OR tenquanlytt IN ('Nguyễn Thị Nga')
            )
            AND makenhkh = 'MT'
            AND masanpham = 'EH115'
            AND ngaychungtu >= '2024-01-01' THEN doanhsochuavat ----rule năm 2024 trở xuống --- Từ tháng 7 cập nhật thêm doanh số ECOM để tính lương
            WHEN makenhphu IN('ECOM', 'FMCG')
            AND makenhkh = 'MT'
            AND makhdms NOT IN ('008140', '003589')
            AND ngaychungtu >= '2023-07-01'
            AND ngaychungtu < '2024-01-01' THEN doanhsochuavat --- Từ tháng 7 cập nhật thêm doanh số ECOM để tính lương
            WHEN (
                makhdms = 'MC017'
                OR makenhphu IN('CCD', 'FMCG')
            )
            AND makenhkh = 'MT'
            AND ngaychungtu < '2023-07-01' THEN doanhsochuavat
            ELSE 0
        END AS th_ds_fmcg,
        0 AS kpi_ds_fmcg,
        CASE
            WHEN ngaychungtu >= '2025-01-01'
            AND ngaychungtu < '2025-04-01'
            AND masanpham IN('T303102009')
            AND a.makenhkh = 'TP' THEN doanhsochuavat
            WHEN ngaychungtu >= '2024-11-01'
            AND ngaychungtu < '2025-01-01'
            AND masanpham IN(
                'T303102006',
                'T303102005',
                'EH086',
                'EH087',
                'EH108',
                'T303102008',
                'T303102010',
                'T303102011',
                'T303102009'
            )
            AND a.makenhkh = 'TP' THEN doanhsochuavat
            WHEN ngaychungtu >= '2023-10-01'
            AND ngaychungtu < '2024-01-01'
            AND masanpham IN('T303102005', 'EH087', 'EH108', 'EH086')
            AND a.makenhkh = 'TP' THEN doanhsochuavat
            ELSE 0
        END AS th_ds_sptt,
        0 AS kpi_ds_sptt,
        kieudonhang,
        CASE
            WHEN ngaychungtu < '2023-01-01'
            AND IFNULL(d.channel, a.makenhkh) = 'OTC'
            AND IFNULL(d.shoptype, a.makenhphu) IN ('NT', 'DCYK', 'SI', 'SI23') THEN 'TP'
            WHEN ngaychungtu < '2023-01-01'
            AND IFNULL(d.channel, a.makenhkh) = 'OTC'
            AND IFNULL(d.shoptype, a.makenhphu) IN ('PK') THEN 'PCL'
            WHEN ngaychungtu < '2023-01-01'
            AND IFNULL(d.channel, a.makenhkh) = 'OTC'
            AND IFNULL(d.shoptype, a.makenhphu) IN ('CHUOI') THEN 'MT'
            WHEN ngaychungtu < '2023-01-01'
            AND IFNULL(d.channel, a.makenhkh) = 'OTC'
            AND IFNULL(d.shoptype, a.makenhphu) IN ('DLPP') THEN 'TP'
            WHEN ngaychungtu < '2023-01-01'
            AND makhdms = 'MC014'
            AND IFNULL(d.channel, a.makenhkh) = 'DLPP' THEN 'TP'
            WHEN ngaychungtu < '2023-01-01'
            AND makhdms = 'N06202285'
            AND IFNULL(d.channel, a.makenhkh) = 'DLPP' THEN 'TP'
            WHEN ngaychungtu < '2023-01-01'
            AND (
                d.active <> 'Active'
                OR d.active IS NULL
            )
            AND IFNULL(d.channel, a.makenhkh) = 'DLPP' THEN 'TP'
            WHEN a.makhdms IN ('008140', '003589', '013410', '018851') THEN 'ECE'
            WHEN a.masanpham = 'EH092'
            AND ngaychungtu >= '2024-04-01'
            AND IFNULL(d.channel, a.makenhkh) = 'INS' THEN 'CLC'
            ELSE IFNULL(d.channel, a.makenhkh)
        END AS makenh_moi,
        mahd,
        lineref,
        d.cluster_state,
        a.sodontrahang
    FROM
        `spatial-vision-343005.staging.f_sales` a
        LEFT JOIN data_pda a3 ON a3.ordernbr = a.sodondathang
        AND a3.branchid = a.macongtycn
        LEFT JOIN `staging.d_master_khachhang` d ON d.custid = a.makhdms
        LEFT JOIN `staging.d_dms_master_invtid` e ON a.masanpham = e.invtid
    WHERE
        a.ngaychungtu >= '2022-01-01'
        AND LEFT(a.masanpham, 1) != 'V'
        AND (
            a.manv NOT IN ('GH001', 'QUYNHPTA', 'MA001', 'MA002')
            OR (
                a.manv IN ('QUYNHPTA', 'MA001', 'MA002')
                AND makenhkh = 'OTH_LAB'
            )
            OR makhdms IN ('008140', '003589', '013410', '018851')
        ) -- and (
        --     makhdms not in ('008140', '003589')
        --     or makhdms is null
        -- ) -- 2 KH này là ko tính lương cho PKH
        AND makenhkh NOT IN ('NB')
    UNION
    ALL (
        SELECT
            NULL AS macongtycn,
            NULL AS congtycn,
            NULL AS mahco,
            NULL AS maphanloaihco,
            NULL AS makhcu,
            NULL AS makhdms,
            NULL AS tenkhachhang,
            NULL AS tentinhkh,
            NULL AS statedescr,
            NULL AS territorydescr,
            NULL AS districtdescr,
            NULL AS wardname,
            NULL AS khuvucviettat,
            NULL AS sodondathang,
            a.thang AS ngaychungtu,
            EXTRACT(
                MONTH
                FROM
                    a.thang
            ) AS MONTH,
            a.thang,
            NULL AS masanpham,
            NULL AS tensanphamnb,
            NULL AS tensanphamviettat,
            0 AS soluong,
            0 AS dongiachuavat,
            0 AS dongiacovat,
            0 AS doanhsocovat,
            0 AS doanhsochuavat,
            CASE
                WHEN upper(a.manv) LIKE '%KN' THEN LEFT(a.manv, 6)
                ELSE a.manv
            END AS manv,
            CASE
                WHEN a.makenhkh = 'SI' THEN 'TP'
                WHEN a.htbh = 'MDS'
                AND thang <= '2023-01-01' THEN 'MDS'
                ELSE a.makenhkh
            END AS makenhkh,
            NULL AS tenkenhkh,
            NULL AS makenhphu,
            NULL AS tenkenhphu,
            a.kh_total,
            0 AS thuchien_spmoi,
            a.kh_spmoi,
            0 AS thuchien_yttn,
            a.kh_yttn,
            NULL AS is_phanam,
            'd_calendar' AS datatype1,
            NULL AS is_ecom,
            NULL AS manvghreal,
            NULL AS pda_crtd_user,
            NULL AS pda_slsperid,
            NULL AS hoadon,
            CASE
                -- when thang >='2024-03-01' and makenhkh ='MT' then kpi_vieng_tham_kh_mt
                WHEN makenhkh = 'TP'
                AND thang >= '2023-10-01'
                AND thang < '2024-01-01' THEN 0
                WHEN makenhkh = 'TP'
                AND thang < '2024-11-01' THEN round(slkh_ebysta, 1)
                ELSE 0
            END AS slkh_ebysta,
            ---2024 chuyển qua XP, cột slkh_ebysta = xp (sản phẩm 1)
            CASE
                WHEN makenhkh = 'TP'
                AND thang >= '2024-01-01' THEN round(slkh_ladoi, 1) ---2024 chuyển qua shema, cột slkh_ladoi = shema (sản phẩm 2)
                WHEN makenhkh = 'TP'
                AND thang >= '2023-07-01'
                AND thang < '2024-01-01' THEN round(slkh_ladoi, 1)
                WHEN makenhkh = 'TP'
                AND thang < '2024-11-01' THEN round(slkh_medoral, 1)
                ELSE 0
            END AS slkh_medoral,
            CASE
                WHEN makenhkh = 'PCL' THEN kh_total
            END AS kpi_ds_pcl,
            NULL AS th_slpp_ebysta,
            NULL AS th_slpp_medoral,
            0 AS th_ds_pcl,
            0 AS th_ds_fmcg,
            kh_fmcg AS kpi_ds_fmcg,
            0 AS th_ds_sptt,
            CASE
                WHEN makenhkh = 'TP'
                AND thang >= '2025-01-01'
                AND thang < '2025-04-01' THEN slkh_ebysta * 1000
                WHEN makenhkh = 'TP'
                AND thang >= '2024-11-01'
                AND thang < '2025-01-01' THEN slkh_ebysta * 1000
                WHEN makenhkh = 'TP'
                AND thang >= '2023-10-01'
                AND thang < '2024-01-01' THEN slkh_ebysta * 1000
                ELSE 0
            END AS kpi_ds_sptt,
            NULL AS kieudonhang,
            CASE
                WHEN makenhkh IN ('MDS', 'OTC', 'SI') THEN 'TP'
                ELSE makenhkh
            END AS makenh_moi,
            NULL AS mahd,
            NULL AS lineref,
            NULL AS cluster_state,
            NULL AS sodontrahang
        FROM
            `spatial-vision-343005.staging.d_calendar` a
        WHERE
            thang >= '2022-01-01'
    )
),
result0 AS (
    SELECT
        a.macongtycn,
        a.congtycn,
        a.mahco,
        a.maphanloaihco,
        a.makhcu,
        a.makhdms,
        a.tenkhachhang,
        a.tentinhkh,
        a.statedescr,
        a.territorydescr,
        a.districtdescr,
        a.wardname,
        a.khuvucviettat,
        CASE
            WHEN a.territorydescr = 'Miền Đông 1' THEN 'MN'
            WHEN a.territorydescr = 'Bắc Trung Bộ' THEN 'MB'
            WHEN a.territorydescr = 'Nam Trung Bộ' THEN 'MN'
            WHEN a.territorydescr = 'Đông Nam 2' THEN 'MN'
            WHEN a.territorydescr = 'Hà Nội 2' THEN 'MB'
            WHEN a.territorydescr = 'Hồ Chí Minh 2' THEN 'MN'
            WHEN a.territorydescr = 'Đông Bắc 1' THEN 'MB'
            WHEN a.territorydescr = 'Mê Kông 2' THEN 'MN'
            WHEN a.territorydescr = 'Mê Kông 1' THEN 'MN'
            WHEN a.territorydescr = 'Tây Bắc HN' THEN 'MB'
            WHEN a.territorydescr = 'Hà Nội 1' THEN 'MB'
            WHEN a.territorydescr = 'Miền Đông 2' THEN 'MN'
            WHEN a.territorydescr = 'Đông Bắc 2' THEN 'MB'
            WHEN a.territorydescr = 'Đông Nam 1' THEN 'MN'
            WHEN a.territorydescr = 'Hồ Chí Minh 1' THEN 'MN'
            ELSE NULL
        END AS vungmien,
        a.sodondathang,
        a.sodontrahang,
        a.ngaychungtu,
        a.mahd,
        a.hoadon,
        a.month,
        a.thang,
        a.masanpham,
        a.tensanphamnb,
        a.tensanphamviettat,
        a.lineref,
        a.soluong,
        a.dongiachuavat,
        a.dongiacovat,
        a.doanhsocovat,
        a.doanhsochuavat,
        ----Update Từ tháng 4/2023 trở đi, nv nào post sẽ dc tính doanh số cho ng đó 
        CASE
            WHEN l.col.phan_loai_mcp = 'Rural'
            OR a.manv = 'TMDT_001'
            OR a.manv IN (
                "MR1682KN",
                "MR2504",
                "MR1232",
                "MR0806",
                "MR2608",
                "MR2111",
                "MR1682",
                "MR2504KN",
                "MR1232KN",
                "MR0806KN",
                "MR2608KN",
                "MR2111KN",
                "MR2993",
                "MR2993KN",
                "MR3038",
                "MR3038KN",
                "MR2608KN",
                "MR2948",
                "MR2948KN",
                "MR2608",
                'MR3196',
                'MR3196KN'
            )
            OR (
                a.makenhphu NOT IN ('SI23', 'SI', 'CTD')
                AND b.tenquanlytt = 'Nguyễn Văn Tiến'
                AND ngaychungtu < '2024-01-01'
            ) THEN l.col.ma_nvbh
            ELSE a.manv
        END AS manv,
        CASE
            WHEN l.col.phan_loai_mcp = 'Rural' THEN 'Rural'
            WHEN a.manv = 'TMDT_001'
            AND l.col.phan_loai_mcp = 'CRS (Trong MCP)' THEN 'Trong MCP (Ecom)'
            WHEN a.manv = 'TMDT_001'
            AND l.col.phan_loai_mcp = 'CRS (Ngoài MCP)' THEN 'Ngoài MCP (Ecom)'
            WHEN a.manv IN (
                "MR1682KN",
                "MR2504",
                "MR1232",
                "MR0806",
                "MR2608",
                "MR2111",
                "MR1682",
                "MR2504KN",
                "MR1232KN",
                "MR0806KN",
                "MR2608KN",
                "MR2111KN",
                "MR2993",
                "MR2993KN",
                "MR3038",
                "MR3038KN",
                "MR2608KN",
                "MR2948",
                "MR2948KN",
                "MR2608",
                'MR3196',
                'MR3196KN'
            ) THEN 'Ngoài MCP (CX)'
            ELSE 'Trong MCP'
        END AS phanloai,
        a.makenhkh,
        a.tenkenhkh,
        CASE
            WHEN a.makenhphu = 'SI23' THEN 'SI'
            ELSE a.makenhphu
        END AS makenhphu,
        a.tenkenhphu,
        cast(current_datetime("+7") AS timestamp) AS updated_at,
        a.is_ecom,
        a.kh_total,
        a.thuchien_spmoi,
        a.kh_spmoi,
        a.thuchien_yttn,
        a.kh_yttn,
        CASE
            -- when a.makenhkh = 'INS' then 'TENDER'
            WHEN a1.nhomcpa IS NOT NULL THEN a1.nhomcpa
            ELSE 'OTHERS'
        END AS datatype,
        a1.brand AS team,
        a.datatype1,
        slpp_ebysta,
        slpp_medoral,
        kpi_ds_pcl,
        th_slpp_ebysta,
        th_slpp_medoral,
        th_ds_pcl,
        th_ds_fmcg,
        kpi_ds_fmcg,
        th_ds_sptt,
        kpi_ds_sptt,
        kieudonhang,
        makenh_moi,
        a1.brandnew2023,
        a.cluster_state,
        NULL AS manv_mds,
        a.manv AS manv_original,
        a.manvghreal,
        a.pda_crtd_user,
        a.pda_slsperid,
    FROM
        data a
        LEFT JOIN `staging.d_nhom_sp_trading` a1 ON a1.masanpham = a.masanpham
        LEFT JOIN `warehouse.f_mapping_crs` l ON l.custid = a.makhdms
        LEFT JOIN staging.d_users b ON b.manv = a.manv
),
result0_1 AS (
    SELECT
        a.*,
        CASE
            WHEN phanloai = 'Rural' THEN 'Rural'
            WHEN phanloai = 'Ngoài MCP (Ecom)' THEN 'Ngoài MCP'
            WHEN phanloai = 'Trong MCP (Ecom)' THEN 'Trong MCP'
            WHEN phanloai = 'Trong MCP' THEN 'Trong MCP'
            WHEN phanloai = 'Ngoài MCP' THEN 'Ngoài MCP'
            WHEN phanloai = 'Ngoài MCP (CX)' THEN 'Ngoài MCP'
            ELSE 'Khác'
        END AS crs_tuyenbanhang_trongmcp
    FROM
        result0 a
),
result1 AS (
    SELECT
        a.*,
        CASE
            WHEN is_ecom = 'Merap'
            AND ngaychungtu >= '2022-01-01' THEN 'Merap'
            WHEN is_ecom = 'Ecom'
            AND ngaychungtu >= '2022-01-01' THEN 'Ecom'
            ELSE NULL
        END AS is_mrtd,
        CASE
            WHEN a.manv = 'MR2082'
            AND ngaychungtu < '2023-06-01' THEN 'MR2355'
            WHEN a.manv = 'CX' THEN 'MR1682'
            WHEN b.tenquanlyvung = 'Lương Trịnh Thắng' THEN supid_bh
            ELSE left(b.supid, 6)
        END AS crm,
        --Case nguyễn hồng sơn chuyển từ HCP sang TP 1/6
        CASE
            WHEN a.manv = 'MR2082'
            AND ngaychungtu < '2023-06-01' THEN 'MR1681'
            WHEN b.tenquanlytt = 'Lê Thị Hương Sa' THEN b.supid
            WHEN b.tenquanlyvung = 'Lương Trịnh Thắng' THEN asm_bh
            ELSE b.asm
        END AS scrm,
        CASE
            WHEN a.manv = 'CX'
            AND ngaychungtu >= '2024-01-01' THEN 'MR0485' ---Mail 25/1/2024 chuyển toàn bộ kênh CX phụ trách TP qua Viển
            WHEN a.manv = 'CX'
            AND ngaychungtu < '2024-01-01' THEN 'MR1214'
            WHEN b.tenquanlytt = 'Lê Thị Hương Sa' THEN b.supid
            ELSE Left(b.rsmid, 6)
        END AS ncxm,
        CASE
            WHEN a.manv = 'CX' THEN 'CX'
            ELSE b.tencvbh
        END AS tencvbh,
        CASE
            WHEN a.manv = 'CX' THEN 'Đinh Thị Ngọc Mẫn'
            WHEN a.manv = 'MR2082'
            AND ngaychungtu < '2023-06-01' THEN 'Nguyễn Văn Đôn'
            WHEN b.tenquanlyvung = 'Lương Trịnh Thắng' THEN b.tenquanlytt_bh
            ELSE b.tenquanlytt
        END AS tenquanlytt,
        CASE
            WHEN a.manv = 'MR2082'
            AND ngaychungtu < '2023-06-01' THEN 'Bùi Hữu Toàn'
            WHEN b.tenquanlytt = 'Lê Thị Hương Sa' THEN 'Lê Thị Hương Sa'
            WHEN b.tenquanlyvung = 'Lương Trịnh Thắng' THEN b.tenquanlykhuvuc_bh
            ELSE b.tenquanlykhuvuc
        END AS tenquanlykhuvuc,
        CASE
            WHEN b.tenquanlytt = 'Lê Thị Hương Sa' THEN 'Lê Thị Hương Sa'
            WHEN a.manv = 'CX'
            AND ngaychungtu < '2024-01-01' THEN 'Nguyễn Thị Ngọc Diệp'
            WHEN a.manv = 'CX'
            AND ngaychungtu >= '2024-01-01' THEN 'Nguyễn Hoàng Viển'
            WHEN a.manv = 'MR2082'
            AND ngaychungtu < '2023-06-01' THEN 'Nguyễn Thọ Chiến'
            ELSE IFNULL(b.tenquanlyvung, "Chưa xác định")
        END AS tenquanlyvung,
        sum(doanhsochuavat) over(PARTITION by thang) AS ds_sp_thang,
        k.firstname AS ten_nguoi_taodon,
        k1.firstname AS tencvbh_header,
        k2.firstname AS tencvbh_ori,
        0 AS doanhso_gh_crs
    FROM
        result0_1 a
        LEFT JOIN `staging.d_users` b ON b.manv = a.manv
        LEFT JOIN `staging.d_dms_master_users` k ON k.username = a.pda_crtd_user
        LEFT JOIN `staging.d_dms_master_users` k1 ON k1.username = a.pda_slsperid
        LEFT JOIN `staging.d_dms_master_users` k2 ON k2.username = a.manv_original
)
SELECT
    *
FROM
    result1


);

Create or replace table `warehouse.f_sales_crs` COPY `staging_temp.f_sales_crs_temp`;

-- CREATE OR REPLACE TABLE staging.f_sales_crs_partition_manv_int
-- PARTITION BY RANGE_BUCKET(manv_int, GENERATE_ARRAY(110000, 114000, 1))
-- AS
-- (
-- SELECT *, safe_cast(replace(manv, 'MR','11') as INT) as manv_int FROM `spatial-vision-343005.warehouse.f_sales_crs_temp`
-- );

END;