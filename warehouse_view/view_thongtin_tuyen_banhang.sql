CREATE VIEW `spatial-vision-343005.warehouse.view_thongtin_tuyen_banhang`
AS SELECT 
t1.custid,
CONCAT(t2.custid,"|",t2.custname) as cc_id_name,
t1.startdate, 
t1.enddate,
Case when t1.extendroute is true then 'Tuyến tạm'
     when t1.delroutedet is false then 'Đang hoạt động'
    --  when  t1.delroutedet is true then  
else 'Không hoạt động' end as delroutedet,
t2.custname,
t2.statedescr,
t2.channel,
t1.slsfreq,
t1.salesrouteid,
t1.weekofvisit,
t1.weekdate,
t1.slsperid,
t3.firstname slspername,
t1.srdescr,
case when t1.routetype ='A' then 'Tuyến MDS'
    when t1.routetype ='B' then 'TUYẾN DELIGHT'
    when t1.routetype ='C' then 'TUYẾN NURTURE'
    when t1.routetype ='D' then 'TUYẾN DELIGHT & NURTURE'
    when t1.routetype ='E' then 'TUYẾN KHÔNG DÀNH CHO BÁN HÀNG'
	when t1.routetype ='F' then 'TUYẾN TO' 
end routetype,
supid
FROM `spatial-vision-343005.staging.sync_dms_srm` t1
left join `spatial-vision-343005.staging.d_master_khachhang` t2 on t1.custid=t2.custid
left join `spatial-vision-343005.staging.d_dms_master_users` t3 on t1.slsperid=t3.username
left join `staging.d_users` t4 on t1.slsperid=t4.manv

qualify row_number() over (
            partition by custid
            order by
            t1.delroutedet asc,
                (Case
                when t1.routetype in ('B', 'D') then 1
                else 2
            end) asc,
                
                t1.crtd_datetime desc
        ) = 1;