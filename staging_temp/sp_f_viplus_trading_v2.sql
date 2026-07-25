CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_viplus_trading_v2()
BEGIN 
TRUNCATE TABLE staging_temp.f_viplus_trading_temp;

INSERT INTO staging_temp.f_viplus_trading_temp(

-- Create or replace table staging_temp.f_viplus_trading_temp as
with

d_vipplus_trading as (
    select
    stt  as  stt,
    scrm  as  scrm,
    crmacrm  as  crmacrm,
    crsscrs  as  crsscrs,
    ncrm_2023  as  ncrm2023,
    crmacrm_2023  as  crmacrm2023,
    crs_2023  as  crs2023,
    ma_hco_tren_dms  as  mahcotrendms,
    ma_hco_cu  as  mahcocu,
    ten_hco  as  tenhco,
    phan_loai_hco  as  phanloaihco,
    dien_thoai  as  dienthoai,
    mst  as  mst,
    dia_chi  as  diachi,
    tinhtp  as  tinhtp,
    ho_va_ten  as  hovaten,
    ngay_sinh_nhat  as  ngaysinhnhat,
    thang_sinh_nhat  as  thangsinhnhat,
    nam_sinh_nhat  as  namsinhnhat,
    chuc_vu  as  chucvu,
    cast (muc_1 as INT)  as  muc1,
    cast (muc_2 as INT)  as  muc2,
    cast (muc_3 as INT)  as  muc3,
    cast (muc_4 as INT)  as  muc4,
    cast (muc_5 as INT)  as  muc5,
    ghi_chu  as  ghichu,
    cast (muc_1000d as INT)  as  muc,
    hang_kh  as  hangkh,
    ghi_chu_1_dot_dang_ky  as  ghichu1,
    ghi_chu_2  as  ghichu2,
    dso_tinh_tu  as  dsotinhtu,
    current_datetime() as  inserted_at
    from staging.d_manual_vipplus
),

data_sale as (
    with data_doanhso as (
    select 
    makhdms,
    thang,
    quy,
    nam,
    sum(doanhsocovat_khangsinh) as doanhsocovat_khangsinh,
    sum(doanhsocovat) as doanhsocovat,
    sum(  Case when trim(upper(brand_dl_nt)) in ('XISAT','OSLA','SHEMA') then doanhsocovat else 0 end) as ds_xos
    from (
            select 
            a.masanpham,
            b.brand as brand_dl_nt,
            Case 
            when makhdms='HH03O392' then '003637' --Update theo email 26/4
            else makhdms 
            end as makhdms,

            Case 
                when a.masanpham in ('EH104','EH103','EH093','EH070','EH068','EH069','EH065','EH095','EH106','EH109','EH096','EH100','EH066','EH067','EH072')
                then doanhsocovat
            else 0 
            end as doanhsocovat_khangsinh,

            extract(month from ngaychungtu) as thang,
            extract(QUARTER from ngaychungtu) as quy,
            extract(year from ngaychungtu) as nam,

            Case
                when makhdms in ('003374') and ngaychungtu >='2023-04-18' then 0 --Update theo email 26/4 (DSKH THAM GIA VIPPLUS 2023 UPDATE 26.04.2023)
                when makhdms in ('MSPC0033') and ngaychungtu >='2023-04-01'and  a.masanpham in ('EH104','EH103','EH093','EH070','EH068','EH069','EH065','EH095','EH106','EH109','EH096',
                'EH100','EH066','EH067','EH072') then 0 --Update theo email 26/4 (DSKH THAM GIA VIPPLUS 2023 UPDATE 26.04.2023)
                when makhdms in ('002153') and ngaychungtu >='2023-05-01' and ngaychungtu <'2023-07-01' then 0 --Update 17/7
                when ngaychungtu < dsotinhtu then 0

                /* -- Duy comment

                when makhdms in ('P3509-0104','N01106024','N01106038','N01106040','004888','TN72H006','TN72O662','TN72O663','TD30O1397','TN73O700','004143','TT50H001','TT50H003',
                'TN70O089','TN71O042','005299') and ngaychungtu <'2023-04-01'then 0   --Update theo email 26/4 (DSKH THAM GIA VIPPLUS 2023 UPDATE 26.04.2023)
                when makhdms in ('MSPC0033') and ngaychungtu <'2023-04-01' then 0 --Update theo email 26/4 (DSKH THAM GIA VIPPLUS 2023 UPDATE 26.04.2023)
                when makhdms in ('005797','P5603-0032','NSPC0110158','004191','MSPC0644') and ngaychungtu < '2023-04-01' then 0 -- Ngày 19/5 Update thêm 13 KH
                when makhdms in ('005939','HH06O011','006205','005508','006218','006219','004276','P4503-0232') and ngaychungtu < '2023-05-01' then 0 -- Ngày 19/5 Update thêm 13 KH
                when makhdms in ('004221','TN90O298','TN90O1065','TN90O1463','TN90O823') and ngaychungtu <'2023-04-01'then 0  -- Ngày 12/6 Update DSKH THAM GIA VIPPLUS UPDATE 12.06.2023
                when makhdms in ('N06720123','P1310-0092','004213','006592','006252','N06802024','006423','006668') and ngaychungtu <'2023-05-01'then 0  
                -- Ngày 12/6 Update DSKH THAM  GIA VIPPLUS UPDATE 12.06.2023
                when makhdms in ('M1902239','M1601024','004980','000117','006594','002533','006066') and ngaychungtu <'2023-06-01'then 0 
                -- Ngày 12/6 Update DSKH THAM GIA VIPPLUS UPDATE 12.06.2023
                when makhdms in ('M1017037') and ngaychungtu <'2023-04-01'then 0 --Chị Cúc Update KH xuống 1/4 ngày 20-6
                when makhdms in ('NSPC0710010','P4407-0390','NSPC0710031','NSPC0720012','004732','005093','005828','005010','N0310166','N07220007','P2006-0052')
                and ngaychungtu <'2023-04-01' then 0 --Update theo email ngày 24/6
                when makhdms in ('003959','006488','N01108121','006123')
                and ngaychungtu <'2023-05-01' then 0 --Update theo email ngày 24/6
                when makhdms in ('007034','007154','TN80O2029','005200','TD31H018','HH04O409')
                and ngaychungtu <'2023-06-01' then 0 --Update theo email ngày 24/6
                when makhdms in ('006349') and ngaychungtu <'2023-07-24' then 0 --Update theo email 31/7
                when makhdms in ('TD42O131','HH02O044','HH04O040','HH04O039','P0903-0024','MSPC0149','TN90O769','003996','005744','TN90O571','TN90O1703','TN90O758','005548','N01101413',
                'N01101056','006452','002522','002728','P4502-0069','N01101584','001764','N01101169','N01101054','N01101048','N01105199','N01105059','006620','006622','P5609-0136',
                'TN90O1228','TN90O1429','TN72H002','TD42O514','006425','TN80O453','TD32O271','001169','TD32O419','000145','N07020159','N07020163','P6002-0079','N07020085','N07020080',
                'N07020197','004559','N02208108','N02208228') and  ngaychungtu <'2023-07-01' then 0 --Update theo email 31/7

                */

                else doanhsocovat 
            end as doanhsocovat
            from warehouse.f_sales_crs a 
            LEFT JOIN `staging.d_nhom_sp_trading` b on a.masanpham =b.masanpham
            LEFT JOIN d_vipplus_trading c on a.makhdms = c.mahcotrendms
            where ( (ngaychungtu >='2023-01-03' and b.masanpham not in ('OH047','OH048','OH071') and ngaychungtu <'2023-04-01') or ngaychungtu >='2023-04-01')


            -- Chương trình vipplus tính từ 3/1/2023 - 31/12/2023
            -- and masanpham not in ('EH072','EH105','OH016','OH032','OH047','OH057','OH058','OH071','OH079','OH081')
            -- and masanpham in ('EH104','EH103','EH093','EH070','EH068','EH069','EH065','EH095','EH106','EH109','EH096','EH100','EH066','EH067','EH086','EH092','OH082','OH051','OH050'
            --'OH083','OH059','OH031','OH076','OH074','OH075','OH077','OH078','OH049','OH052','OH084')
            -- theo danh mục sản phẩm Merap kinh doanh năm 2023
            and  extract(year from ngaychungtu) = 2023
            and LEFT(a.masanpham,1) != 'V' 
            and makenhkh not in ('NB','OTH_LAB')
            -- AND manv NOT IN ( 'GH001','QUYNHPTA','MA001','MA002')
            -- and a.masanpham not in ('OH047','OH071') --- 14/4 loại các sản phẩm này ra
        ) a
            group by 1,2,3,4
),

    group_check_dk as (
    select 
    *, 
    Case when thang =1 then ds_xos  else 0 end as ds_xos_t1,
    Case when thang =2 then ds_xos else 0 end as ds_xos_t2,
    Case when thang =3 then ds_xos   else 0 end as ds_xos_t3,
    Case when thang =4 then ds_xos   else 0 end as ds_xos_t4,
    Case when thang =5 then ds_xos   else 0 end as ds_xos_t5,
    Case when thang =6 then ds_xos  else 0 end as ds_xos_t6,
    Case when thang =7 then ds_xos  else 0 end as ds_xos_t7,
    Case when thang =8 then ds_xos  else 0 end as ds_xos_t8,
    Case when thang =9 then ds_xos  else 0 end as ds_xos_t9,
    Case when thang =10 then ds_xos else 0 end as ds_xos_t10,
    Case when thang =11 then ds_xos  else 0 end as ds_xos_t11,
    Case when thang =12 then ds_xos  else 0 end as ds_xos_t12,

    Case when thang =1 then doanhsocovat  else 0 end as t01,
    Case when thang =2 then doanhsocovat  else 0 end as t02,
    Case when thang =3 then doanhsocovat else 0 end as t03,
    Case when thang =4 then doanhsocovat else 0 end as t04,
    Case when thang =5 then doanhsocovat else 0 end as t05,
    Case when thang =6 then doanhsocovat else 0 end as t06,
    Case when thang =7 then doanhsocovat else 0 end as t07,
    Case when thang =8 then doanhsocovat else 0 end as t08,
    Case when thang =9 then doanhsocovat else 0 end as t09,
    Case when thang =10 then doanhsocovat else 0 end as t10,
    Case when thang =11 then doanhsocovat else 0 end as t11,
    Case when thang =12 then doanhsocovat else 0 end as t12

    from data_doanhso
    ),

    convert_dk as (
    select makhdms,
    nam,
    sum(doanhsocovat) doanhsocovat,
    sum(doanhsocovat_khangsinh) doanhsocovat_khangsinh,
    sum(ds_xos) as ds_xos,
    sum(ds_xos_t1) as ds_xos_t1,
    sum(ds_xos_t2) as ds_xos_t2,
    sum(ds_xos_t3) as ds_xos_t3,
    sum(ds_xos_t4) as ds_xos_t4,
    sum(ds_xos_t5) as ds_xos_t5,
    sum(ds_xos_t6) as ds_xos_t6,
    sum(ds_xos_t7) as ds_xos_t7,
    sum(ds_xos_t8) as ds_xos_t8,
    sum(ds_xos_t9) as ds_xos_t9,
    sum(ds_xos_t10) as ds_xos_t10,
    sum(ds_xos_t11) as ds_xos_t11,
    sum(ds_xos_t12) as ds_xos_t12,
    sum(t01) as t01,
    sum(t02) as t02,
    sum(t03) as t03,
    sum(t04) as t04,
    sum(t05) as t05,
    sum(t06) as t06,
    sum(t07) as t07,
    sum(t08) as t08,
    sum(t09) as t09,
    sum(t10) as t10,
    sum(t11) as t11,
    sum(t12) as t12
    from group_check_dk group by 1,2 )

    select *,
    -- Case when check_t1 >= 1 or check_t2 >= 1 then 1 else 0 end as check_vl_1_2,
    -- Case when check_t2 >= 1 or check_t3 >= 1 then 1 else 0 end as check_vl_2_3,
    -- Case when check_t3 >= 1 or check_t4 = 1 then 1 else 0 end as check_vl_3_4,
    -- Case when check_t4 >= 1 or check_t5 = 1 then 1 else 0 end as check_vl_4_5,
    -- Case when check_t5 >= 1 or check_t6 = 1 then 1 else 0 end as check_vl_5_6,
    -- Case when check_t6 >= 1 or check_t7 = 1 then 1 else 0 end as check_vl_6_7,
    -- Case when check_t7 >= 1 or check_t8 = 1 then 1 else 0 end as check_vl_7_8,
    -- Case when check_t8 >= 1 or check_t9 = 1 then 1 else 0 end as check_vl_8_9,
    -- Case when check_t9 >= 1 or check_t10 = 1 then 1 else 0 end as check_vl_9_10,
    -- Case when check_t10 >= 1 or check_t11 = 1 then 1 else 0 end as check_vl_10_11,
    -- Case when check_t11 >= 1 or check_t12 = 1 then 1 else 0 end as check_vl_11_12
    from convert_dk
),


tichluy_dachot_c1 as 
(

SELECT custid,sum(reward) as c1_thuong_tichluy 
FROM `spatial-vision-343005.staging.f_accumulatedresult` where accumulateid ='202301-TLVIP-QD02-PMC-PCL-CTD-C1'
group by 1

),

tichluy_datra_c1 as 
(
SELECT  custid,sum(paidamt) as c1_da_tra  
FROM `spatial-vision-343005.staging.f_paidso_acculate` where accumulateid='202301-TLVIP-QD02-PMC-PCL-CTD-C1'
group by 1 
),

tichluy_dachot as 
(
    with tichluy_dachot as (
    select
    custid,
    extract(quarter from closedate) as quy,
    extract(year from closedate) as nam,
    sum(accumulatedvalue) giatri_tl,
    sum(reward) + sum(prepay) as tienthuong_dat_tichluy,
    sum(prepay) tra_truoc,
    sum(reward) + sum(rewardback * cast(pass as int))  thuong_tichluy,
    from `staging.f_accumulatedresult`  where accumulateid ='202301-TLVIP-QD02-PMC-PCL-CTD'
    and extract(year from closedate) = 2023
    group by 1,2,3
    )

    select custid,nam,
    sum(case when quy = 1 then thuong_tichluy else 0 end) as quy1_thuong_tichluy,
    sum(case when quy = 2 then thuong_tichluy else 0 end) as quy2_thuong_tichluy,
    sum(case when quy = 3 then thuong_tichluy else 0 end) as quy3_thuong_tichluy,
    sum(case when quy = 4 then thuong_tichluy else 0 end) as quy4_thuong_tichluy
    from tichluy_dachot
    group by 1,2

),

tichluy_datra as (
    with a as (
    select 
    custid,
    extract(quarter from cast(todate as date)) as quy,
    extract(year from cast(todate as date)) as nam,
    sum(amt) thuong_tichluy1,
    sum(paidamt) da_tra,

    from `staging.f_paidso_acculate`  where accumulateid ='202301-TLVIP-QD02-PMC-PCL-CTD'
    group by 1,2,3
    )
    select custid,
    sum(case when quy = 1 then da_tra else 0 end) as quy1_datra,
    sum(case when quy = 2 then da_tra else 0 end) as quy2_datra,
    sum(case when quy = 3 then da_tra else 0 end) as quy3_datra,
    sum(case when quy = 4 then da_tra else 0 end) as quy4_datra
    from a
    group by 1
),

result as (

SELECT 
row_number() over (partition by a.mahcotrendms) as stt,
a.*except(mahcotrendms,tenhco,diachi,tinhtp,stt),
trim(upper(a.mahcotrendms)) as mahcotrendms,
ifnull(d.custname,a.tenhco) as tenhco,
ifnull(d.address,a.diachi) as diachi,
ifnull(d.statedescr,a.tinhtp) as tinhtp,
d.channel,
d.shoptype,
d.hcotypeid,
d.branchid,
Case when d.branchid in('MR0001','HCM001') then 'Hồ Chí Minh'
    when d.branchid ='MR0003' then 'CÔNG TY TNHH MTV DƯỢC PHA NAM HÀ NỘI'
    when d.branchid in('MR0014','KHA014') then 'Khánh Hòa'
    when d.branchid in('MR0015','DNI015') then 'Đồng Nai'
    when d.branchid ='MR0011' then 'Hải Phòng'
    when d.branchid in('MR0012','NAN012') then 'Nghệ An'
    when d.branchid in('MR0010','HNI010') then 'Hà Nội'
    when d.branchid in('MR0013','DNG013') then 'Đà Nẵng'
    when d.branchid in('MR0016','CTO016') then 'Cần Thơ'
    else d.branchname 
end as branchname,  
d.shortterritorydescr,
d.taxregnbr,
d.custidinvoice,
d.custnameinvoice,
a.muc *1000 as muc_vipplus,
ifnull(d.statedescr,a.tinhtp) as filter_tinh,
c.doanhsocovat,
c.doanhsocovat_khangsinh,
c.ds_xos,
c.t01,
c.t02,
c.t03,
c.t04,
c.t05,
c.t06,
c.t07,
c.t08,
c.t09,
c.t10,
c.t11,
c.t12,
ds_xos_t1,
ds_xos_t2,
ds_xos_t3,
ds_xos_t4,
ds_xos_t5,
ds_xos_t6,
ds_xos_t7,
ds_xos_t8,
ds_xos_t9,
ds_xos_t10,
ds_xos_t11,
ds_xos_t12,
FROM d_vipplus_trading a

LEFT JOIN `staging.d_master_khachhang` d on d.custid =a.mahcotrendms
LEFT JOIN data_sale c on c.makhdms = a.mahcotrendms
where d.shoptype in ('PMC','PCL','CTD') and d.hcotypeid not in ('NTPP','QTDN','NTXQPK','DLPP3') -- chị Cúc bỏ DLPP3 ngày 26/6 
),

tichluy as 
(
SELECT
Case when makhdms='HH03O392' then '003637' else makhdms end as makhdms,
extract(quarter from orderdate) as quy,
sum(accumulatedvalue) as accumulatedvalue
FROM `spatial-vision-343005.warehouse.f_thoathuan_muaban` 
where orderdate >='2023-01-03' and extract(year from orderdate) =2023
group by 1 ,2 
),

-- tuyen_crs as (
--     with  mapping as
--     (
--     select a.custid, slsperid, a.crtd_datetime,row_number() over (partition by a.custid order by a.crtd_datetime desc) as loc
--     from `staging.sync_dms_srm` a
--     LEFT JOIN `staging.d_users` d on d.manv = a.slsperid
--     where routetype in ('B','C','D') and delroutedet is false and slsperid is not null
--     and d.position in ('S','SS','AM','RM','NS')
--     )
--     select  custid, slsperid, crtd_datetime from mapping  where loc =1
-- ),

tuyen_dms_moinhat as (
    with data_tuyen as (
    SELECT
    custid,
    slsperid,
    crtd_datetime,
    Case when routetype in ('B','D') then 1 else 2 end as routetype,
    FROM `spatial-vision-343005.staging.sync_dms_srm` 
    where delroutedet is false --and slsperid not in ('MR1008','MR1705','MR2610','MR1225','MR2596','MR2594','MR2611')
    )
    select * from (
    select *,row_number() over (partition by custid order by routetype asc,crtd_datetime desc) as loc  from data_tuyen
    )
    where loc =1
),

result1 as (
select
a.*except (crsscrs,crmacrm,scrm),
ifnull(b.tencvbh,'Khác') as crsscrs,
f.accumulatedvalue,
-- Chu kì quý
Case
    when t01 + t02 + t03 >= 300000000 then 'Diamond'
    when t01 + t02 + t03 >= 90000000 and t01 + t02 + t03 < 300000000 then 'Platinum'
    when t01 + t02 + t03 >= 45000000 and t01 + t02 + t03 < 90000000 then 'Gold'

    when t01 + t02 + t03 >= 15000000 and t01 + t02 + t03 < 45000000 then 'Silver'
    when t01 + t02 + t03 >= 9000000 and t01 + t02 + t03 < 15000000 then 'Member'
    else null
end as hang_q1,

Case
    when t04 + t05 + t06 >= 300000000 then 'Diamond'
    when t04 + t05 + t06 >= 90000000 and t04 + t05 + t06 < 300000000 then 'Platinum'
    when t04 + t05 + t06 >= 45000000 and t04 + t05 + t06 < 90000000 then 'Gold'
    when t04 + t05 + t06 >= 15000000 and t04 + t05 + t06 < 45000000 then 'Silver'
    when t04 + t05 + t06 >= 9000000 and t04 + t05 + t06 < 15000000 then 'Member'
    else null
end as hang_q2,

Case
    when t07 + t08 + t09 >= 300000000 then 'Diamond'
    when t07 + t08 + t09 >= 90000000 and t07 + t08 + t09 < 300000000 then 'Platinum'
    when t07 + t08 + t09 >= 45000000 and t07 + t08 + t09 < 90000000 then 'Gold'
    when t07 + t08 + t09 >= 15000000 and t07 + t08 + t09 < 45000000 then 'Silver'
    when t07 + t08 + t09 >= 9000000 and t07 + t08 + t09 < 15000000 then 'Member'
    else null
end as hang_q3,

Case
    when t10 + t11 + t12 >= 300000000 then 'Diamond'
    when t10 + t11 + t12 >= 90000000 and t10 + t11 + t12 < 300000000 then 'Platinum'
    when t10 + t11 + t12 >= 45000000 and t10 + t11 + t12 < 90000000 then 'Gold'
    when t10 + t11 + t12 >= 15000000 and t10 + t11 + t12 < 45000000 then 'Silver'
    when t10 + t11 + t12 >= 9000000 and t10 + t11 + t12 < 15000000 then 'Member'
    else null              
end as hang_q4,
    -- Chu kì 6 tháng
Case 
    when t01 + t02 + t03 + t04 + t05 + t06 >= 600000000 then 'Diamond'
    when t01 + t02 + t03 + t04 + t05 + t06 >= 180000000 and t01 + t02 + t03 + t04 + t05 + t06 < 600000000 then 'Platinum'
    when t01 + t02 + t03 + t04 + t05 + t06 >= 90000000 and t01 + t02 + t03 + t04 + t05 + t06 < 180000000 then 'Gold'
    when t01 + t02 + t03 + t04 + t05 + t06 >= 30000000 and t01 + t02 + t03 + t04 + t05 + t06 < 90000000 then 'Silver'
    when t01 + t02 + t03 + t04 + t05 + t06 >= 18000000 and t01 + t02 + t03 + t04 + t05 + t06 < 30000000 then 'Member'
    else null
end as hang_6thang_1,

Case 
    when t07 + t08 + t09 + t10 + t11 + t12 >= 600000000 then 'Diamond'
    when t07 + t08 + t09 + t10 + t11 + t12 >= 180000000 and t07 + t08 + t09 + t10 + t11 + t12 < 600000000 then 'Platinum'
    when t07 + t08 + t09 + t10 + t11 + t12 >= 90000000 and t07 + t08 + t09 + t10 + t11 + t12 < 180000000 then 'Gold'
    when t07 + t08 + t09 + t10 + t11 + t12 >= 30000000 and t07 + t08 + t09 + t10 + t11 + t12 < 90000000 then 'Silver'
    when t07 + t08 + t09 + t10 + t11 + t12 >= 18000000 and t07 + t08 + t09 + t10 + t11 + t12 < 30000000 then 'Member'
    else null
end as hang_6thang_2,
    -- Chu kì năm

Case 
    when t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 >= 1200000000 then 'Diamond'
    when t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 >= 360000000 
    and t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 < 1200000000 then 'Platinum'
    when t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 >= 180000000
    and t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 < 360000000 then 'Gold'
    when t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 >= 60000000 
    and t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 < 180000000 then 'Silver'
    when t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 >= 36000000 
    and t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 < 60000000 then 'Member'
    else null
end as hang_nam,

/*
đối với nhóm sản phẩm xos được xét chiết khấu tối đa doanh số 100 triệu
ví dụ: doanh số NT A: 150 triệu xos, 20 triệu SPCL
c sẽ tính doanh số quý 2 của họ = 100triệu + 20triệu = 120triệu (hưởng ck 2%)

----------Xét Quý ----------                                                              
                                                                                        
* Diamond DS >= 300tr CK 2.0%
* Platinum DS >= 90tr CK 1.5%
* Gold DS >= 45tr CK 1.25%
* Silver DS >= 15tr CK 1.0%
* Member DS >= 9tr CK 1.0%

-----------Xét 6 tháng ------------

'* Diamond DS >= 600tr CK 2.0%
* Platinum DS >= 180tr CK 1.5%
* Gold DS >= 90tr CK 1.25%
* Silver DS >= 30tr CK 1.0%
* Member DS >= 18tr KHÔNG CK
*/ 
t01+t02+t03 as doanhsoquy1,
t04+t05+t06 as doanhsoquy2,
t07+t08+t09 as doanhsoquy3,
t10+t11+t12 as doanhsoquy4,
ds_xos_t1 + ds_xos_t2 + ds_xos_t3 as ds_xos_quy1,
ds_xos_t4 + ds_xos_t5 + ds_xos_t6 as ds_xos_quy2,
ds_xos_t7 + ds_xos_t8 + ds_xos_t9 as ds_xos_quy3,
ds_xos_t10 + ds_xos_t11 + ds_xos_t12 as ds_xos_quy4,
t01+t02+t03 - (ds_xos_t1 + ds_xos_t2 + ds_xos_t3) as ds_dk_quy1_spcl,
t04+t05+t06 - (ds_xos_t4 + ds_xos_t5 + ds_xos_t6) as ds_dk_quy2_spcl,
t07+t08+t09 - (ds_xos_t7 + ds_xos_t8 + ds_xos_t9) as ds_dk_quy3_spcl,
t10+t11+t12 - (ds_xos_t10 + ds_xos_t11 + ds_xos_t12) as ds_dk_quy4_spcl,

Case 
    when shoptype in ('PMC','PCL') and ds_xos_t1 + ds_xos_t2 + ds_xos_t3 >100000000 then 100000000 
    else ds_xos_t1 + ds_xos_t2 + ds_xos_t3
end as ds_dk_quy1_xos,

Case 
    when shoptype in ('PMC','PCL') and ds_xos_t4 + ds_xos_t5 + ds_xos_t6 >100000000 then 100000000
    else ds_xos_t4 + ds_xos_t5 + ds_xos_t6
end as ds_dk_quy2_xos,

Case 
    when shoptype in ('PMC','PCL') and ds_xos_t7 + ds_xos_t8 + ds_xos_t9 >100000000 then 100000000 
    else ds_xos_t7 + ds_xos_t8 + ds_xos_t9
end as ds_dk_quy3_xos,

Case 
    when shoptype in ('PMC','PCL') and ds_xos_t10 + ds_xos_t11 + ds_xos_t12 >100000000 then 100000000
    else ds_xos_t10 + ds_xos_t11 + ds_xos_t12
end as ds_dk_quy4_xos,

Case when f.accumulatedvalue is null then t01+t02+t03 else (t01+t02+t03) - f.accumulatedvalue end as doanhso_tru_tichluy_quy1,

Case when f2.accumulatedvalue is null then t04+t05+t06 else (t04+t05+t06) - f2.accumulatedvalue end as doanhso_tru_tichluy_quy2,

Case when f3.accumulatedvalue is null then t07+t08+t09 else (t07+t08+t09) - f3.accumulatedvalue end as doanhso_tru_tichluy_quy3,

Case when f.accumulatedvalue is null then t10+t11+t12 else (t10+t11+t12) - f.accumulatedvalue end as doanhso_tru_tichluy_quy4,
d.tongdstinhthuong as tongdstinhthuong_2022,
d.hangkh as hangkh_2022,
concat(
    ifnull( replace ( cast(a.ngaysinhnhat as string),'.0',''),'/') ,'-',
    ifnull( replace(cast(a.thangsinhnhat as string),'.0',''),'/'),'-',
    ifnull( replace( cast(a.namsinhnhat as string),'.0',''),'/') ) as ngay_sinh,
d.quatangsinhnhat,
f.makhdms,
b.manv as ma_crs,
Case 
    when b.tenquanlyvung ='Lương Trịnh Thắng' then b.supid_bh 
    else b.supid 
end as ma_crm,

b.asm as ma_scrm,
LEFT(b.rsmid,6) as ma_ncxm,
Case 
    when b.tenquanlyvung ='Lương Trịnh Thắng' then b.tenquanlytt_bh 
    else ifnull(b.tenquanlytt,'Khác') 
end as crmacrm,
ifnull(b.tenquanlykhuvuc,'Khác') as scrm,
ifnull(b.tenquanlyvung,'Khác') as ncxm,
ifnull(quy1_datra,0) as quy1_datra,
ifnull(quy2_datra,0) as quy2_datra,
ifnull(quy3_datra,0) as quy3_datra,
ifnull(quy4_datra,0) as quy4_datra,
ifnull(quy1_thuong_tichluy,0) as quy1_thuong_tichluy,
ifnull(quy2_thuong_tichluy,0) as quy2_thuong_tichluy,
ifnull(quy3_thuong_tichluy,0) as quy3_thuong_tichluy,
ifnull(quy4_thuong_tichluy,0) as quy4_thuong_tichluy,
ifnull(quy1_thuong_tichluy,0) - ifnull(quy1_datra,0) as quy1_conlai,
ifnull(quy2_thuong_tichluy,0) - ifnull(quy2_datra,0) as quy2_conlai,
ifnull(quy3_thuong_tichluy,0) - ifnull(quy3_datra,0) as quy3_conlai,
ifnull(quy4_thuong_tichluy,0) - ifnull(quy4_datra,0) as quy4_conlai,
ifnull(h.c1_thuong_tichluy,0) as c1_thuong_tichluy,
ifnull(k.c1_da_tra,0) as c1_da_tra,
ifnull(h.c1_thuong_tichluy,0) - ifnull(k.c1_da_tra,0) as c1_conlai,
Case when l.ma_kh_dms is not null then 'Có' else 'Không' end as is_check_thamgia_diamond
from result a
LEFT JOIN tuyen_dms_moinhat a1 on trim(upper(a1.custid)) =trim(upper(a.mahcotrendms))
LEFT JOIN `staging.d_users` b on b.manv =a1.slsperid
LEFT JOIN `staging.d_tangqua_sn_kh_dat_vipplus2022` d on trim(upper(d.madms)) = trim(upper(a.mahcotrendms))
LEFT JOIN tichluy f on f.makhdms =a.mahcotrendms and f.quy =1 
LEFT JOIN tichluy f2 on f2.makhdms =a.mahcotrendms and f2.quy =2 
LEFT JOIN tichluy f3 on f3.makhdms =a.mahcotrendms and f3.quy =3 
LEFT JOIN tichluy f4 on f4.makhdms =a.mahcotrendms and f4.quy =4 
LEFT JOIN tichluy_datra e on e.custid =a.mahcotrendms
LEFT JOIN tichluy_dachot g on g.custid =a.mahcotrendms
LEFT JOIN tichluy_dachot_c1 h on h.custid =a.mahcotrendms
LEFT JOIN tichluy_datra_c1 k on k.custid =a.mahcotrendms
LEFT JOIN staging.d_manual_danhsach_khachhang_diamond l on l.ma_kh_dms = a.mahcotrendms
)
select *,

Case 
    when doanhsoquy2 >= 300000000 then 0.02
    when doanhsoquy2 >= 90000000 and doanhsoquy2 < 300000000 then 0.015
    when doanhsoquy2 >= 45000000 and doanhsoquy2 < 90000000 then 0.0125
    when doanhsoquy2 >= 15000000 and doanhsoquy2 < 45000000 then 0.01
    when doanhsoquy2 >= 9000000 and doanhsoquy2 < 15000000 then 0.01
    else 0
end as ck_q2,

Case 
    when doanhsoquy3 >= 300000000 then 0.02
    when doanhsoquy3 >= 90000000 and doanhsoquy3 < 300000000 then 0.015
    when doanhsoquy3 >= 45000000 and doanhsoquy3 < 90000000 then 0.0125
    when doanhsoquy3 >= 15000000 and doanhsoquy3 < 45000000 then 0.01
    when doanhsoquy3 >= 9000000 and doanhsoquy3 < 15000000 then 0.01
    else 0
end as ck_q3,

Case 
    when doanhsoquy4 >= 300000000 then 0.02
    when doanhsoquy4 >= 90000000 and doanhsoquy4 < 300000000 then 0.015
    when doanhsoquy4 >= 45000000 and doanhsoquy4 < 90000000 then 0.0125
    when doanhsoquy4 >= 15000000 and doanhsoquy4 < 45000000 then 0.01
    when doanhsoquy4 >= 9000000 and doanhsoquy4 < 15000000 then 0.01
    else 0
end as ck_q4,


Case 
    when t01 + t02 + t03 + t04 + t05 + t06 >= 600000000 then 0.02
    when t01 + t02 + t03 + t04 + t05 + t06 >= 180000000 and t01 + t02 + t03 + t04 + t05 + t06 < 600000000 then  0.015
    when t01 + t02 + t03 + t04 + t05 + t06 >= 90000000 and t01 + t02 + t03 + t04 + t05 + t06 < 180000000 then 0.0125
    when t01 + t02 + t03 + t04 + t05 + t06 >= 30000000 and t01 + t02 + t03 + t04 + t05 + t06 < 90000000 then 0.01
    when t01 + t02 + t03 + t04 + t05 + t06 >= 18000000 and t01 + t02 + t03 + t04 + t05 + t06 < 30000000 then 0
    else 0
end as ck_6thang_1,

Case 
    when t07 + t08 + t09 + t10 + t11 + t12 >= 600000000 then 0.02
    when t07 + t08 + t09 + t10 + t11 + t12 >= 180000000 and t07 + t08 + t09 + t10 + t11 + t12 < 600000000 then  0.015
    when t07 + t08 + t09 + t10 + t11 + t12 >= 90000000 and t07 + t08 + t09 + t10 + t11 + t12 < 180000000 then 0.0125
    when t07 + t08 + t09 + t10 + t11 + t12 >= 30000000 and t07 + t08 + t09 + t10 + t11 + t12 < 90000000 then 0.01
    when t07 + t08 + t09 + t10 + t11 + t12 >= 18000000 and t07 + t08 + t09 + t10 + t11 + t12 < 30000000 then 0
    else 0
end as ck_6thang_2,
Case 
    when t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 >= 1200000000 then 0.02
    when t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 >= 360000000 
    and t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 < 1200000000 then 0.015
    when t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 >= 180000000
    and t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 < 360000000 then 0.0125
    when t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 >= 60000000 
    and t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 < 180000000 then 0.01
    when t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 >= 36000000 
    and t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 < 60000000 then 0
    else null
end as ck_hang_nam,
Case 
    when t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 >= 1200000000 then '<= 2,1 triệu'
    when t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 >= 360000000 
    and t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 < 1200000000 then '<= 900 ngàn'
    when t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 >= 180000000
    and t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 < 360000000 then '<= 600 ngàn'
    when t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 >= 60000000 
    and t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 < 180000000 then '<= 300 ngàn'
    when t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 >= 36000000 
    and t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 < 60000000 then '<= 300 ngàn'
    else null
end as quatet_hang_nam,
Case 
    when t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 >= 1200000000 then '<= 1,2 triệu'
    when t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 >= 360000000 
    and t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 < 1200000000 then '<= 900 ngàn'
    when t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 >= 180000000
    and t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 < 360000000 then '<= 600 ngàn'
    when t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 >= 60000000 
    and t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 < 180000000 then '<= 300 ngàn'
    when t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 >= 36000000 
    and t01 + t02 + t03 + t04 + t05 + t06 + t07 + t08 + t09 + t10 + t11 + t12 < 60000000 then '<= 300 ngàn'
    else null
end as quasn_hang_nam,
case when mahcotrendms='002153'
then DATE_DIFF(date('2023-12-31'),date(dsotinhtu),month) - 1
else
DATE_DIFF(date('2023-12-31'),date(dsotinhtu),month) + 1
end as so_thang_thamgia



from result1 where mahcotrendms not in ('NAN012','N06502071','003374') 

);
Create or replace table `warehouse.f_viplus_trading`

copy `staging_temp.f_viplus_trading_temp`;

End;