CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_hub_2()
BEGIN 
TRUNCATE TABLE staging_temp.f_hub_2_temp;
INSERT INTO staging_temp.f_hub_2_temp(

-- Create table staging_temp.f_hub_2_temp
-- partition by date(thang)
-- as

with doanhthu as 
(
  with b1 as
  (
    select 
      custid,
      Ordnbr,
      date_trunc(date(orderdate),month) as orderdate_thang,
      sum(sotien_da_thanhtoan) sotien_da_thanhtoan 
    from `staging_temp.d_rawdata_debt_detail` 
    where date(orderdate) >= '2022-01-01'
    group by 1,2,3
  )
  ,

  ketqua as
  (
    select 
    a.branchid, 
    a.branchname, 
    a.custid,
    a.custname,
    a.active,
    a.channel, 
    a.shoptype,
    a.classid,
    a.statedescr, 
    a.districtdescr, 
    a.wardname,
    a.terms,
    a.paymentsform,
    b.phanloaiub,
    c.orderdate_thang,
    c.Ordnbr,
    c.sotien_da_thanhtoan,
    d.chinhanh as chinhanh_dialy,

    case 
      WHEN a.channel in ('INS','CLC','PCL') THEN 'HCP'
      when (a.shoptype = 'PK') then 'HCP'
      WHEN (a.shoptype in ('PMC','SI23','CTD','SI','NT')) THEN 'TP'
      when (a.channel = 'DLPP') THEN 'TP'
      WHEN a.shoptype in ('NTC','CCD','CVS','CHUOI') THEN 'MT'
      ELSE a.channel end as kenh,

    from `staging.d_master_khachhang` a
    left join `spatial-vision-343005.staging.d_tinh` b on a.statecode = b.stateid
    left join b1 c on a.custid = c.custid
    left join `spatial-vision-343005.staging.d_tinh` d on a.statedescr = d.tinh
    where (a.channel not in ('OTH_LAB','NB') or a.channel is null) 
        and a.custid not like 'DS%' 
        and a.statedescr in ('Hà Nam','Ninh Bình','Nam Định','Thái Bình')
  )

  select 
    custid,
    Ordnbr,
    orderdate_thang,
    statedescr,
    channel,
    shoptype,
    classid,
    wardname,
    sum(sotien_da_thanhtoan) as sotien_da_thanhtoan
  from ketqua
  group by 1,2,3,4,5,6,7,8
)
,

doanhso_2022 as
(
    select 
      a.thang,
      a.makhdms,
      a.tenkhachhang,
      c.channel,
      c.shoptype,
      c.classid,
      a.tentinhkh,
      a.tenquanhuyen,
      a.sodondathang,
      a.tencvbh, 
      case when b.donvigiaohang is null then a.donvigiaohang else b.donvigiaohang end as donvigiaohang,
      sum(a.doanhsochuavat) as doanhsochuavat
    from `spatial-vision-343005.staging.f_sales` a
    left join `spatial-vision-343005.staging.d_dieuchinhmds` b on a.sodondathang = b.sodondathang
    left join `spatial-vision-343005.staging.d_master_khachhang` c on a.makhdms = c.custid
    where DATE(a.ngaychungtu) >= "2022-01-01" 
          and a.makenhkh not in ('NB','OTH_LAB')
          and a.tentinhkh in ('Hà Nam','Ninh Bình','Nam Định','Thái Bình')
    group by 1,2,3,4,5,6,7,8,9,10,11
)
,

danhsach_kh22 as
(
  SELECT 
    statedescr,
    districtdescr,
    wardname,
    custid,
    custname,
    active,
    crtd_datetime,
    channel,
    shoptype,
    classid
  FROM `spatial-vision-343005.staging.d_master_khachhang`
  where channel not in ('NB','OTH_LAB')
        and custid not like 'DS%'
        and statedescr in ('Hà Nam','Ninh Bình','Nam Định','Thái Bình')
)
,

result as
(
select 
    thang,
    makhdms,
    tenkhachhang,
    channel,
    shoptype,
    classid,
    tentinhkh,
    tenquanhuyen,
    sodondathang,
    tencvbh, 
    donvigiaohang,
    doanhsochuavat,
    null as sotien_da_thanhtoan
from doanhso_2022

union all

select 
    cast(date(orderdate_thang) as timestamp) as thang,
    custid as makhdms,
    null as tenkhachang,
    channel as channel,
    shoptype as shoptype, 
    classid as classid,
    statedescr as tentinhkh,
    wardname as tenquanhuyen,
    Ordnbr as sodondathang,
    null as tencvbh,
    null as donvigiaohang,
    null as doanhsochuavat,
    sotien_da_thanhtoan
from doanhthu
)

select *
from result

  );

Create or replace table `warehouse.f_hub_2`

copy `staging_temp.f_hub_2_temp`;

End;