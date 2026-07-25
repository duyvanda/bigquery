CREATE VIEW `spatial-vision-343005.warehouse.view_f_theo_doi_san_pham_bat_thuong`
AS with current_sales as (
select masanpham,sum(soluong) as soluong_cur
from `warehouse.f_sales_crs` 
where date(ngaychungtu) between date(date_trunc(current_date("+7"),month)) and current_date("+7")
-- and masanpham ='EH065'
group by all
)
,
pre_sales as (
select masanpham,sum(soluong) as soluong_pre
from `warehouse.f_sales_crs` 
where date(ngaychungtu) between date(date_trunc(current_date("+7"),month)) - interval 1 year and current_date("+7") - interval 1 year
-- and masanpham ='EH065'
group by all
)
select 
c.descr,
c.descr1,
a.*,
ifnull(b.soluong_pre,0) as soluong_pre,
safe_divide(soluong_cur-soluong_pre, soluong_pre) as ty_le,
(select max(updated_at) from `warehouse.f_sales_crs`  where ngaychungtu >='2024-09-01') as inserted_at
 from current_sales a 
LEFT JOIN pre_sales b on a.masanpham =b.masanpham
LEFT JOIN `staging.d_dms_master_invtid` c on a.masanpham =c.invtid;