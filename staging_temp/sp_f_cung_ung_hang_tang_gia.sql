CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_cung_ung_hang_tang_gia()
BEGIN 
 
 TRUNCATE TABLE staging_temp.f_cung_ung_hang_tang_gia_temp;


 INSERT INTO `staging_temp.f_cung_ung_hang_tang_gia_temp`

(   
-- Create or replace table staging_temp.f_cung_ung_hang_tang_gia_temp as
-- with 

-- mapping_data as (
-- select 
-- date(ngaychungtu) as ngaychungtu,
-- date(thang) as thang,
-- extract(month from ngaychungtu) as thang_int,
-- extract(year from ngaychungtu) as nam,
-- macongtycn,
-- masanpham,
-- makenhkh,
-- crm,sum(soluong) as soluong_ban,
-- 0 as soluong_cungung,
-- 0 as soluong_treo,
-- 'f_sales' datatype
-- from `warehouse.f_sales_crs` a
-- WHERE
--         a.ngaychungtu >= '2023-10-01'
--         AND LEFT(a.masanpham, 1) != 'V'
--         AND (
--             a.manv NOT IN ('GH001', 'QUYNHPTA', 'MA001', 'MA002')
--         )
--         and (
--             makhdms not in ('008140', '003589')
--             or makhdms is null
--         ) -- 2 KH này là ko tính lương cho PKH
--         AND makenhkh not in ('NB','OTH_LAB','INS','CLC','PCL')
        
--         group by 1,2,3,4,5,6,7,8
-- UNION ALL 
-- SELECT 
-- date(nam,thang,1) as ngaychungtu,
-- date(nam,thang,1) as thang,
-- thang as thang_int,
-- nam,
-- chinhanh,
-- masp,
-- kenh,
-- macrm,
-- 0 as soluong_ban,
-- sum(sodukiencungung) as sodukiencungung,
-- 0 as soluong_treo,
-- 'cungung' datatype
--  FROM `spatial-vision-343005.staging.d_cung_ung_hang_tang_gia` 
-- group by 1,2,3,4,5,6,7,8
-- UNION ALL
--     select 
--     date(crtd_datetime) as ngaytao,
--     date(date_trunc(crtd_datetime,month)) as thang,
--     extract(month from crtd_datetime) as thang_int,
--     extract(year from crtd_datetime) as nam,
--     branchid,
--     invtid,
--     channel,
--     ma_crm,
--     0 as soluong_ban,
--     0 as soluong_cungung,
--     sum(lineqty) as soluong_treo,
--     'treo' datatype
--      from `warehouse.f_sales_crs_pending_v3`
-- group by 1,2,3,4,5,6,7,8

-- ),
-- result as (
-- select a.*,
-- Case when crm ='MR1682' then 'Đinh Thị Ngọc Mẫn' else
-- b.tencvbh end as tencvbh,b.tenquanlyvung,c.descr as tensanpham,
-- -- d.soluong_treo,
-- current_datetime("+7") as inserted_at
-- from mapping_data a
-- LEFT JOIN `staging.d_users` b on a.crm =b.manv
-- LEFT JOIN `staging.d_dms_master_invtid` c on c.invtid = a.masanpham
-- -- LEFT JOIN soluong_treo d on a.ngaychungtu =d.ngaytao and a.macongtycn =d.branchid and d.invtid = a.masanpham and a.crm =d.ma_crm
-- where concat(a.macongtycn,a.masanpham,a.crm) in (SELECT distinct concat(chinhanh,masp,macrm) FROM `spatial-vision-343005.staging.d_cung_ung_hang_tang_gia` )
-- )

-- select * from result

with 

data_sales as (
    with tuyen_dms_moinhat as (
    with data_tuyen as (
        SELECT
            custid,
            slsperid,
            crtd_datetime,
            Case
                when routetype in ('B', 'D') then 1
                else 2
            end as routetype,
        FROM
            `spatial-vision-343005.staging.sync_dms_srm`
        where
            delroutedet is false
    )
    select
        *
    from
        data_tuyen qualify row_number() over (
            partition by custid
            order by
                routetype asc,
                crtd_datetime desc
        ) = 1
),
data_pda as (
    select
        ordernbr,
        custid,
        branchid,
        'TMDT_001' as crtd_user
    from
        `spatial-vision-343005.staging.sync_dms_pda_so`
    WHERE
        (
            crtd_user = 'TMDT_001'
            or slsperid = 'TMDT_001'
        )
        and crtd_datetime >= '2022-06-01'
),
data_sales as (
    select
        ngaychungtu,
        macongtycn,
        masanpham,
        a.makenhkh,
        a.makhdms,
        statedescr,
        districtdescr,
        wardname,
        Case
            when upper(ifnull(a3.crtd_user, a.manv)) like '%KN' then LEFT(ifnull(a3.crtd_user, a.manv), 6)
            else ifnull(a3.crtd_user, a.manv)
        end as manv,
        Case
            when doanhsochuavat = 0 then soluong
            else 0
        end as soluong_km,
        Case
            when doanhsochuavat <> 0 then soluong
            else 0
        end as soluong_ban,
        doanhsochuavat
    from
        `staging.f_sales` a
        LEFT JOIN `staging.d_master_khachhang` b on a.makhdms = b.custid
        LEFT JOIN data_pda a3 on a3.ordernbr = a.sodondathang
        and a3.branchid = a.macongtycn
    where
        ngaychungtu >= '2023-10-01'
        and makhdms not in ('008140', '003589')
        and makenhkh not in ('NB', 'OTH_LAB','PCL','CLC','INS')
),
mapping as (
    select
        a.*except(manv),
        Case
            when a.statedescr in (
                'Lạng Sơn',
                'Sơn La',
                'Hòa Bình',
                'Bắc Kạn',
                'Lào Cai',
                'Hà Giang',
                'Cao Bằng',
                'Điện Biên',
                'Lai Châu'
            )
            and a.makenhkh = 'TP' then 'CX'
            when a.manv = 'TMDT_001' and a.makenhkh = 'TP' 
            and b.slsperid not in (
                'MR1682KN',
                'MR2504',
                'MR1232',
                'MR0806',
                'MR2608',
                'MR2111',
                'MR1682',
                'MR2504KN',
                'MR1232KN',
                'MR0806KN',
                'MR2608KN',
                'MR2111KN',
                 'MR2993',
                'MR2993KN'
            )then b.slsperid
            when a.manv = 'TMDT_001'and a.makenhkh = 'TP' then ifnull(g1.macrs, g2.macrs)
            when a.manv in (
                'MR1682KN',
                'MR2504',
                'MR1232',
                'MR0806',
                'MR2608',
                'MR2111',
                'MR1682',
                'MR2504KN',
                'MR1232KN',
                'MR0806KN',
                'MR2608KN',
                'MR2111KN',
                'MR2993',
                'MR2993KN'
            ) and a.makenhkh = 'TP' then ifnull(g1.macrs, g2.macrs)
            else a.manv
        end as manv
    from
        data_sales a
        left join tuyen_dms_moinhat b on a.makhdms = b.custid
        LEFT JOIN `spatial-vision-343005.staging.d_manual_tuyenbanhang_crs` g1 on g1.phuongxa is not null
        and trim(
            upper(
                concat(concat(g1.tinhtp, g1.quanhuyen), g1.phuongxa)
            )
        ) = trim(
            upper(
                concat(
                    concat(a.statedescr, a.districtdescr),
                    a.wardname
                )
            )
        )
        LEFT JOIN `spatial-vision-343005.staging.d_manual_tuyenbanhang_crs` g2 on g2.phuongxa is null
        and trim(upper(concat(g2.tinhtp, g2.quanhuyen))) = trim(upper(concat(a.statedescr, a.districtdescr)))
)

-- select * from data_sales where manv like '%KN%'

select
    date(ngaychungtu) as ngaychungtu,
    date(date_trunc(ngaychungtu, month)) as thang,
    extract(
        month
        from
            ngaychungtu
    ) as thang_int,
    extract(
        year
        from
            ngaychungtu
    ) as nam,
    macongtycn,
    masanpham,
    makenhkh,
    Case when a.manv ='CX' then 'MR1682'else supid end as crm,
    sum(soluong_ban) as soluong_ban,
    sum(soluong_km) as soluong_km,
    0 as soluong_cungung,
    0 as soluong_treo,
    'f_sales' datatype
from
    mapping a
    LEFT JOIN `staging.d_users` b on a.manv = b.manv
group by
    1,
    2,
    3,
    4,
    5,
    6,
    7,8
),


mapping_data as (
select 
* 
from data_sales
UNION ALL 
SELECT 
date(nam,thang,1) as ngaychungtu,
date(nam,thang,1) as thang,
thang as thang_int,
nam,
chinhanh,
masp,
kenh,
macrm,
0 as soluong_ban,
0 as soluong_km,
sum(sodukiencungung) as sodukiencungung,
0 as soluong_treo,
'cungung' datatype
 FROM `spatial-vision-343005.staging.d_cung_ung_hang_tang_gia` 
group by 1,2,3,4,5,6,7,8
UNION ALL
    select 
    date(crtd_datetime) as ngaytao,
    date(date_trunc(crtd_datetime,month)) as thang,
    extract(month from crtd_datetime) as thang_int,
    extract(year from crtd_datetime) as nam,
    branchid,
    invtid,
    channel,
    ma_crm,
    0 as soluong_ban,
    0 as soluong_km,
    0 as soluong_cungung,
    sum(lineqty) as soluong_treo,
    'treo' datatype
     from `warehouse.f_sales_crs_pending_v3`
     where channel not in ('PCL','INS','CLC')
group by 1,2,3,4,5,6,7,8

),
result as (
select a.*,
Case when crm ='MR1682' then 'Đinh Thị Ngọc Mẫn' else
b.tencvbh end as tencvbh,b.tenquanlyvung,c.descr as tensanpham,
-- d.soluong_treo,
Case when concat(a.macongtycn,a.masanpham,a.crm) in (SELECT distinct concat(chinhanh,masp,macrm) FROM `spatial-vision-343005.staging.d_cung_ung_hang_tang_gia` ) then 'Y' else 'N' end as is_check,
current_datetime("+7") as inserted_at
from mapping_data a
LEFT JOIN `staging.d_users` b on a.crm =b.manv
LEFT JOIN `staging.d_dms_master_invtid` c on c.invtid = a.masanpham
-- LEFT JOIN soluong_treo d on a.ngaychungtu =d.ngaytao and a.macongtycn =d.branchid and d.invtid = a.masanpham and a.crm =d.ma_crm
-- where concat(a.macongtycn,a.masanpham,a.crm) in (SELECT distinct concat(chinhanh,masp,macrm) FROM `spatial-vision-343005.staging.d_cung_ung_hang_tang_gia` )
)

select * from result

);

Create or replace table `warehouse.f_cung_ung_hang_tang_gia`

copy `staging_temp.f_cung_ung_hang_tang_gia_temp`;
END;