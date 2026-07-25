CREATE VIEW `spatial-vision-343005.warehouse.view_f_baocao_tonkho_hangngay_realtime`
AS with base as (
    select
        masanpham,
        Case
            when macongtycn in('MR0001', 'HCM001') then 'HCM'
            when macongtycn = 'MR0003' then 'HÀ NỘI'
            when macongtycn in('MR0014', 'KHA014') then 'KHÁNH HÒA'
            when macongtycn in('MR0015', 'DNI015') then 'ĐỒNG NAI'
            when macongtycn = 'MR0011' then 'HẢI PHÒNG'
            when macongtycn in('MR0012', 'NAN012') then 'NGHỆ AN'
            when macongtycn in('MR0010', 'HNI010') then 'HÀ NỘI'
            when macongtycn in('MR0013', 'DNG013') then 'ĐÀ NẴNG'
            when macongtycn in('MR0016', 'CTO016') then 'CẦN THƠ'
            when macongtycn in ('HYN017') then 'NM'
            ELSE NULL
        END AS chinhanh,
        sum(
            case
                when date(ngaychungtu) <= current_date("+7")
                and date(ngaychungtu) > current_date("+7") -7 then soluong
            end
        ) as soluong_7ngay,
        sum(
            case
                when date(ngaychungtu) <= current_date("+7")
                and date(ngaychungtu) > current_date("+7") -30 then soluong
            end
        ) as soluong_30ngay,
        sum(
            case
                when date(ngaychungtu) <= current_date("+7")
                and date(ngaychungtu) > current_date("+7") -60 then soluong
            end
        ) as soluong_60ngay,
        sum(
            case
                when date_trunc(date(ngaychungtu), month) = date_trunc(current_date("+7"), month) then soluong
            end
        ) SL_ban_MTD,
        sum(soluong) soluong
    from
        `spatial-vision-343005.staging.f_sales` a
    where
        LEFT(a.masanpham, 1) != 'V'
        AND makenhkh not in ('NB', 'OTH_LAB')
        and date(ngaychungtu) >= date_trunc(
            date_sub(current_date("+7"), interval 3 month),
            month
        )
    group by
        1,
        2
),
base_tonkho as (
    select
        'null' as makho,
        created_date,
        masanpham,
        tensanpham,
        donvi,
        chinhanh,
        toncn,
        tonhcm,
        tonao,
        tonhangdiduong,
        tonmerap,
        tonvime,
        tonhangdiduongvime,
        tonnmtpbt,
        -- tonnmtp,
        -- inserted_at,
        0 as tonnmbt,
        tonnmhh,
        -- 0 as soluong,
        -- 0 asavg_3m,
        -- songaynhan,
        0 as tonnmpo,
        0 as tonnmno,
        inserted_at2,
        case
            when b.chinhanh = 'CT' then 'CẦN THƠ'
            when b.chinhanh = 'NA' then 'NGHỆ AN'
            when b.chinhanh = 'HN' then 'HÀ NỘI'
            when b.chinhanh = 'DNANG' then 'ĐÀ NẴNG'
            when b.chinhanh = 'HP' then 'HẢI PHÒNG'
            when b.chinhanh = 'HCM' then 'HCM'
            when b.chinhanh = 'KH' then 'KHÁNH HÒA'
            when b.chinhanh = 'DNAI' then 'ĐỒNG NAI'
            else b.chinhanh
        end chinhanh_new,
        manv,
        version
    from
        `spatial-vision-343005.staging.f_sc_daily_invt_realtime` b
    where
        lower(masanpham) not like 'v%'
        and lower(masanpham) not like 'p%'
),
group_base_tonkho as (
    select
        makho,
        created_date,
        inserted_at2,
        manv,
        version,
        masanpham,
        chinhanh_new chinhanh,
        SUM(toncn + tonhcm + tonmerap) AS ton_kho_cn,
        SUM(tonnmhh + tonnmtpbt) AS ton_kho_nm,
        SUM(tonhangdiduong) AS tonhangdiduong,
        SUM(tonvime) AS tonvime,
        SUM(tonhangdiduongvime) AS tonhangdiduongvime,
        SUM(tonao) AS tonao
    from
        base_tonkho
    group by
        1,
        2,
        3,
        4,
        5,
        6,
        7
)


, fc_month_sales as (
    select
        date('2025-12-01') as month,
        'A01' as masp,
        0.0 fcvalues
)

-- , fc_month_sales as (
--     select
--         t6.month,
--         t6.masp,
--         sum(t6.fcvalues) fcvalues
--     from
--         `spatial-vision-343005.staging.d_forecast_sc_realtime` t6
--     where
--         date(t6.month) = date(date_trunc(current_date("+7"), month))
--     group by
--         1,
--         2
-- )

, sales_sp as (
    select
        masanpham,
        sum(soluong_30ngay) soluong
    from
        base
    group by
        1
),
fc_sales as (
    select
        tt1.masanpham,
        tt1.chinhanh,
        SAFE_DIVIDE(tt1.soluong_30ngay, tt2.soluong)  * t2.fcvalues as fc_chinhanh
    from
        base tt1
        LEFT JOIN sales_sp tt2 on tt1.masanpham = tt2.masanpham
        left join fc_month_sales t2 on tt1.masanpham = t2.masp
),
base_sanpham as 
(
  SELECT a.invtid as masp,a.descr,
  t2.*except(masp) FROM `spatial-vision-343005.staging.d_dms_master_invtid` a
  LEFT JOIN staging.d_master_sanpham t2 on a.invtid =t2.masp
  
  where status ='AC' and classid ='Product'
),

base_tenkho as 
(
    select  siteid,tenkho from `staging.f_sc_daily_raw_invt` 
qualify row_number() over (partition by siteid order by created_date desc) =1
)
,
mapping_all as (
    select
        a.makho,
        t5.tenkho,
        created_date,
        inserted_at2,
        manv,
        version,
        COALESCE(a.masanpham, b.masanpham, tb2.masanpham) masanpham,
        COALESCE(a.chinhanh, b.chinhanh, tb2.chinhanh) chinhanh,
        case
            when COALESCE(a.masanpham, b.masanpham, tb2.masanpham) = 'OH072' then 'Osla Online'
            else t2.descr
        end tensanpham,
        a.ton_kho_cn,
        a.tonao,
        a.ton_kho_nm,
        a.tonhangdiduong,
        a.tonvime,
        a.tonhangdiduongvime,
        round(
            ifnull(b.soluong_7ngay, 0) / 5.5,
            0
        ) as AVG_7_ngay,
        ifnull(b.SL_ban_MTD, 0) as SL_ban_MTD,
        round(
            ifnull(b.soluong_30ngay, 0) / 24,
            0
        ) as AVG_30_ngay,
        round(
            ifnull(b.soluong_60ngay, 0) / 48,
            0
        ) as AVG_60_ngay,
        round(
            tb2.fc_chinhanh / 24,
            0
        ) as avg_forecast,
         t3.nhomcpa,
        t4.phannhomsp as nhomcpa2,
        t3.brand2023,
    from
        group_base_tonkho a 
        LEFT JOIN base b on a.masanpham = b.masanpham
        and lower(a.chinhanh) = lower(b.chinhanh)
        -- LEFT JOIN songay_lamviec cn1 on 1 = 1 
        LEFT JOIN fc_sales tb2 on COALESCE(a.masanpham, b.masanpham) = tb2.masanpham
        and lower(COALESCE(a.chinhanh, b.chinhanh)) = lower(tb2.chinhanh)
        LEFT JOIN base_sanpham t2 on COALESCE(a.masanpham, b.masanpham, tb2.masanpham) = t2.masp
        LEFT JOIN `staging.d_nhom_sp_trading` t3 on t3.masanpham =a.masanpham and t3.masanpham is not null --and t3.masanpham <> 'New'
        left join staging.d_nm_quycachdh t4 on a.masanpham = trim(t4.ma_san_pham_pha_nam)
        left join base_tenkho t5 on t5.siteid=a.makho
),
result as (
    select
        *,
        (ton_kho_cn + ton_kho_nm + tonhangdiduong) / if(AVG_60_ngay = 0, 0.001, AVG_60_ngay) as songay_banhet1,
        (ton_kho_cn + ton_kho_nm + tonhangdiduong) / if(AVG_30_ngay = 0, 0.001, AVG_30_ngay) as songay_banhet2,
        (ton_kho_cn + ton_kho_nm + tonhangdiduong) / if(avg_forecast = 0, 0.001, avg_forecast) as songay_banhet3
    from
        mapping_all
),
result1 as (
    select
        *,
        Case
            when songay_banhet1 >= 75
            and songay_banhet2 >= 75 then 'Sản phẩm bán chậm (>=75)'
            when songay_banhet1 >= 50
            and songay_banhet2 >= 50 then 'Sản phẩm bán chậm (>=50)'
            when songay_banhet1 < 10
            or songay_banhet2 < 10
            or songay_banhet3 < 10 then 'Sản phẩm gần hết hàng (<10)'
            when songay_banhet1 < 30
            or songay_banhet2 < 30
            or songay_banhet3 < 30 then 'Sản phẩm gần hết hàng (<30)'
            when songay_banhet1 < 50
            or songay_banhet2 < 50
            or songay_banhet3 < 50 then 'Sản phẩm gần hết hàng (<50)'
            when ifnull(ton_kho_cn, 0) + ifnull(ton_kho_nm, 0) + ifnull(tonhangdiduong, 0) = 0 then 'Sản phẩm hết tồn kho'
            else null
        end as is_check_sp
    from
        result
)
select
    *
from
    result1;