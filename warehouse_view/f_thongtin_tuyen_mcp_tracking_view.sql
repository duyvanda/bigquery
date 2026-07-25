CREATE VIEW `spatial-vision-343005.warehouse.f_thongtin_tuyen_mcp_tracking_view`
AS with tuyen_dms_moinhat as (
    with data_tuyen as (
        SELECT
          *except(routetype,inserted_at),
            Case
                when routetype in ('B', 'D') then 1
                else 2
            end as routetype,
            date(inserted_at) as inserted_at
        FROM
            `spatial-vision-343005.staging.d_manual_sync_dms_srm`

        where
            delroutedet is false
    )
    select
        *
    from
        data_tuyen 
        qualify row_number() over (
            partition by custid,inserted_at
            order by
                routetype asc,
                crtd_datetime desc
        ) = 1
),
result as (
SELECT
  a.inserted_at as ngay,
  a.slsperid as manv,
  trim(c.tencvbh) as tencvbh,
  c.supid,
  c.tenquanlytt,
  c.rsmid,
  c.tenquanlyvung,
  a.custid as ma_khachhang,
  d.custname as tenkhachhang,
  d.statedescr as tinh,
  d.districtdescr as quanhuyen,
  d.channel as kenh,
  d.shoptype as kenhphu,
  d.hcotypeid as phanloai_hco,
  a.salesrouteid as ma_tuyenbh,
  a.srdescr as tentuyen,
  date(a.startdate) AS tu_ngay,
  date(a.enddate) AS den_ngay,
  a.subrouteid AS sub_route,
  a.slsfreq as tansuat_bh,
  a.weekofvisit AS tuan_tham_kh,
  case when weekdate ='MS1111111'  then 'Thu 2,Thu 3,Thu 4,Thu 5,Thu 6,Thu 7,Chu nhat'
            when weekdate ='MS1111110'  then 'Thu 2,Thu 3,Thu 4,Thu 5,Thu 6,Thu 7'
            when weekdate ='MS0000001'  then 'Chu nhat'
            when weekdate ='MS1000000'  then 'Thu 2'
            when weekdate ='MS0100000'  then 'Thu 3'
            when weekdate ='MS0010000'  then 'Thu 4'
            when weekdate ='MS0001000'  then 'Thu 5'
            when weekdate ='MS0000100'  then 'Thu 6'
            when weekdate ='MS0000010'  then 'Thu 7'
            when weekdate ='MS1101010'  then 'Thu 2,Thu 3,Thu 5,Thu 7'
            else weekdate end as thu,
  a.inserted_at,
  d.pubcustid,
  d.pubcustname,
  d.classid,
  format_date('%d-%m',a.inserted_at)  as ngay_text
FROM
  tuyen_dms_moinhat a
  LEFT JOIN `staging.d_users` c on a.slsperid = c.manv 
--   and date_trunc(a.inserted_at,month) = date(c.thang)
  LEFT JOIN `staging.d_master_khachhang_bytime` d on d.custid =a.custid and date_trunc(a.inserted_at,month) = date(d.thang)
  where 
   d.active  in ('Active')
)

select *,
replace(replace(replace(ngay_text,'16','17'),'30','31'),'19','17') as ngay_text1
 from result;