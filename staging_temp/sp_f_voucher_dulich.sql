CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_voucher_dulich(manv_p STRING, version_p STRING)
BEGIN 
INSERT INTO warehouse.f_voucher_dulich (

-- create or replace table warehouse.f_voucher_dulich as

with tuyenban as 
(
  with data_tuyen as 
    (
      SELECT 
        -- thang,
        a.custid,
        a.slsperid,
        a.crtd_datetime,
        Case when a.routetype in ('B','D') then 1 else 2 end as routetype,
        b.tenquanlytt_bh
      FROM `spatial-vision-343005.staging.sync_dms_srm` a
      left join `spatial-vision-343005.staging.d_users` b on a.slsperid = b.manv
      where a.delroutedet is false --and slsperid not in ('MR1008','MR1705','MR2610','MR1225','MR2596','MR2594','MR2611')
    )
      select * 
      from (  select *,
                row_number() over (partition by custid order by routetype asc,crtd_datetime desc) as loc  
              from data_tuyen
          )
      where loc =1 --and custid  = '008817'
)
,

da_tra as 
(
  select *except(datatype,qty), sum(qty) as qty 
  from `spatial-vision-343005.staging.d_voucher_ctr_dulich`
  where datatype = 'DA_TRA' and status in ('C','H')
  group by 1,2,3,4,5,6
)
,

thuong_goc as
(
  SELECT a.*except(status),
    b.custname, 
    b.statedescr,
    b.branchid, 
    b.channel,
    b.shoptype,
    c.slsperid as crs,
    d.tencvbh,
    d.supid,
    d.tenquanlytt,
    
  FROM `spatial-vision-343005.staging.d_voucher_ctr_dulich` a
  LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` b on a.custid = b.custid
  LEFT JOIN tuyenban c on a.custid = c.custid
  LEFT JOIN `spatial-vision-343005.staging.d_users` d on c.slsperid = d.manv
  where a.datatype = 'THUONG_BAN_DAU' and a.p_manv = manv_p and a.p_version = version_p
  -- group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
) 
  select 
  a.*,
    b.qty as sl_datra,
    case when b.status = 'C' then 'Đã phát hành hóa đơn'
         when b.status = 'H' then 'Chờ xử lý' 
         else null end as status, 
    
  from thuong_goc a
  left join da_tra b on a.custid = b.custid and a.invtid = b.invtid and a.p_manv = b.p_manv and a.p_version = b.p_version
  -- where a.custid = 'P4719-0301'and a.invtid in ('V3MMR') AND A.p_version = '092020' and a.p_manv ='AM0000'

);

End;