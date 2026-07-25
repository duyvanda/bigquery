CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_danh_sach_kh_xo()
BEGIN 
 
 TRUNCATE TABLE `staging_temp.f_danh_sach_kh_xo_temp`;


 INSERT INTO `staging_temp.f_danh_sach_kh_xo_temp`

(   
-- Create table staging_temp.f_danh_sach_kh_xo_temp as

with 
tuyen_dms_moinhat as (
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
        data_tuyen 
        qualify row_number() over (
            partition by custid
            order by
                routetype asc,
                crtd_datetime desc
        ) = 1
),

data_sales as ( 
select 
makhdms,
-- sum(Case when extract(month from ngaychungtu)=4 then doanhsocovat else 0 end ) as doanhsocovat_t4, 
sum(Case when extract(month from ngaychungtu)=5 then doanhsocovat else 0 end ) as doanhsocovat_t5,
sum(Case when extract(month from ngaychungtu)=6 then doanhsocovat else 0 end ) as doanhsocovat_t6,
-- sum(Case when extract(month from ngaychungtu)=7 then doanhsocovat else 0 end ) as doanhsocovat_t7,
-- sum(Case when extract(month from ngaychungtu)=8 then doanhsocovat else 0 end ) as doanhsocovat_t8,
-- sum(Case when extract(month from ngaychungtu)=9 then doanhsocovat else 0 end ) as doanhsocovat_t9,
-- sum(Case when extract(month from ngaychungtu)=10 then doanhsocovat else 0 end ) as doanhsocovat_t10,
-- sum(Case when extract(month from ngaychungtu)=11 then doanhsocovat else 0 end ) as doanhsocovat_t11,
-- sum(Case when extract(month from ngaychungtu)=12 then doanhsocovat else 0 end ) as doanhsocovat_t12,
sum(doanhsocovat) as doanhsocovat 
 from `warehouse.f_sales_crs` a
 LEFT JOIN `staging.sync_dms_so` b on a.mahd= b.ordernbr and a.macongtycn =b.branchid
 where ngaychungtu >='2024-05-01' and ngaychungtu <'2024-06-30' and b.crtd_datetime <= '2024-06-29 10:00:00'
 and masanpham in ('OH051','OH050','OH049','T302203002','OH052','T302201014','T302201018','T302201017','OH059','OH031')
group by 1

)

select 
d.custid,
d.custname,
d.channel,
d.shoptype,
d.statedescr,
d.shortterritorydescr,
d.hcotypeid,
d.branchid,
-- ifnull(doanhsocovat_t4,0) as doanhsocovat_t4,
ifnull(doanhsocovat_t5,0) as doanhsocovat_t5,
ifnull(doanhsocovat_t6,0) as doanhsocovat_t6,
-- ifnull(doanhsocovat_t7,0) as doanhsocovat_t7,
-- ifnull(doanhsocovat_t8,0) as doanhsocovat_t8,
-- ifnull(doanhsocovat_t9,0) as doanhsocovat_t9,
-- ifnull(doanhsocovat_t10,0) as doanhsocovat_t10,
-- ifnull(doanhsocovat_t11,0) as doanhsocovat_t11,
-- ifnull(doanhsocovat_t12,0) as doanhsocovat_t12,
ifnull(doanhsocovat,0) as doanhsocovat,
Case when ifnull(doanhsocovat,0) >=10000000 then ifnull(doanhsocovat,0) * 3/100 else 0 end as tien_km,
e.slsperid as ma_crs,
c.tencvbh as ten_crs,
c.supid as ma_crm,
Case when e.slsperid  in (
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
                'MR2993KN',
                'MR3038',
                'MR3038KN',
                'MR2608KN',
                'MR2948',
                'MR2948KN',
                'MR2608'
            ) then 'Đinh Thị Ngọc Mẫn' else
c.tenquanlytt end as ten_crm,
'MR0485' as ma_ncxm,
'Nguyễn Hoàng Viển' as tenquanlyvung,
timestamp(current_datetime("+7")) as updated_at,
 from `staging.d_master_khachhang` d 
LEFT JOIN data_sales b on d.custid =b.makhdms
LEFT JOIN tuyen_dms_moinhat e on e.custid =d.custid
LEFT JOIN `staging.d_users` c on e.slsperid =c.manv
where d.channel ='TP' and d.hcotypeid ='CTD' and d.active ='Active' 

and d.custid not in (
    select distinct b.custid from staging.d_posm_regis a
INNER JOIN staging.d_master_khachhang b on a.custid = b.custid and b.shoptype = 'CTD'
)
-- ('001020','N06113002','010099','003760','TD42O497','TD42O514','TN72H006','TN72O663','TN72H004','000124','003809','TN72O664','TN72H001','TN72O662','TN72O059','TN72O500','TN72O878','TN72H002','TD30O220','TD32H001','TD32O194','TD32O610','TN73O705','TN73H004','TN73H005','TN60H003','TN70H006','TN70O096','TN70H005','000352','TN90O1006','N01101001','N01101520','N01106024','N01106038','N01106180','P5501-0052','P5505-0122','N011050031','N01105042','N01108001','TN80O2029','TN80O204','TN80H003','TN80O1583','TT51O171','TT50H001','TT50H003','HH06O062','HH10O497','N02201033','N06202138','P0707-0232','P3617-0105','N01104059','N01104002','TN80O1113')

);

Create or replace table `warehouse.f_danh_sach_kh_xo`

copy `staging_temp.f_danh_sach_kh_xo_temp`;

END;