CREATE TABLE FUNCTION `spatial-vision-343005`.staging_temp.api_doanh_so_kh_table(p_ma_crs STRING)
AS
select 
makhdms as ma_kh_dms,
a.tenkhachhang as ten_kh,
left(a.manv,6) as ma_crs,
b.tencvbh as ten_crs,
date(a.thang) as thang,
current_date("+7") as ngay_hien_tai,
Case when date(date_trunc(a.thang,month)) <  date_trunc(current_date("+7"),month) then 0 
    else date_diff( date((date_trunc(current_date("+7"),month) + interval 1 month - interval 1 day)) , current_date("+7"),day)
end as so_ngay_con_lai,
count(distinct sodondathang) as don_hang,
sum(doanhsochuavat) as doanh_so,
sum(kh_total) as ke_hoach,


  from `staging_temp.f_sales_crs_lhq_bytime`  a
  LEFT JOIN `staging.d_users_bytime` b on left(a.manv,6) =b.manv and a.thang =b.thang 
  where 
  date(a.ngaychungtu) between date(date_trunc(current_date("+7"),month)) and current_date("+7")
  and starts_with(left(a.manv,6),p_ma_crs)
  -- and date(a.thang) = date(date_trunc(current_date("+7"),month))
  and crs_tuyenbanhang_trongmcp not in ('Rural') 
  and a.manv not in ('OTH_LAB')
  group by 1,2,3,4,5,6,7
  order by doanh_so desc;