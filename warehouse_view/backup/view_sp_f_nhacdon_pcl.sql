CREATE VIEW `spatial-vision-343005.warehouse.view_sp_f_nhacdon_pcl`
AS with dskh_pcl as
(
  SELECT  
    a.makhdms,
    a.tenkhachhang,
    a.makenhkh,
    a.makenhphu,
    a.ngaychungtu,
    extract (DAYOFWEEK FROM a.ngaychungtu) as week_day,
    case when extract (DAYOFWEEK FROM a.ngaychungtu) = 7 then date_add (date(ngaychungtu), interval 2 day)
          when extract (DAYOFWEEK FROM a.ngaychungtu) = 1 then date_add (date(ngaychungtu), interval 1 day)
          else date(a.ngaychungtu) end as ngaychuyendoi,
    a.sodondathang,
    row_number() over (partition by a.makhdms order by ngaychungtu desc ) as loc

  FROM `spatial-vision-343005.staging.f_sales` a
  inner join `spatial-vision-343005.staging.d_nhacdonpcl` b on a.makhdms = b.ma_khach_hang_dms
)
,

result as
(
  select 
    a.*except(loc), 
    b.phone as phone_master,
    b.phoneinvoice,
    c.created_at,
    c.phone,
    c.ten_khach_hang_theo_dms as tenkhachhang_ip,
    case when a.ngaychuyendoi = current_date() then null
        else date_diff (current_date(), a.ngaychuyendoi,day) end as songay,

    mod (case when a.ngaychuyendoi = current_date() then null
        else date_diff (current_date(), a.ngaychuyendoi,day) end,28) as dieukien_guitn,

    28 - (mod (case when a.ngaychuyendoi = current_date() then null else date_diff (current_date(), a.ngaychuyendoi,day) end,28)) as tinh_songay_guitn,    

    (date_diff(current_date(), a.ngaychuyendoi,day))/7 as sotuan_chuadatdon

  from dskh_pcl a
  left join `spatial-vision-343005.staging.d_master_khachhang` b on a.makhdms = b.custid
  left join `spatial-vision-343005.staging.d_nhacdonpcl` c on a.makhdms = c.ma_khach_hang_dms 
  where loc = 1
)
select *,
case when tinh_songay_guitn is null then date_add(current_date(),interval 28 day) 
      else date_add (current_date(),interval tinh_songay_guitn day) end as ngayguitn
from result   ;