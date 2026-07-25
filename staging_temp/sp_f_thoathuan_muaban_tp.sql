CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_thoathuan_muaban_tp()
BEGIN 
TRUNCATE TABLE staging_temp.f_thoathuan_muaban_tp_temp;

INSERT INTO staging_temp.f_thoathuan_muaban_tp_temp(

-- Create or replace table staging_temp.f_thoathuan_muaban_tp_temp
-- as

with d_accumulatedregis as (
  select
    a.*
  from
    `spatial-vision-343005.staging.d_accumulatedregis` a
  where
    accumulateid in ( '202401-TL-QD976-PMC-CTD')

-- qualify row_number() over (partition by accumulateid,custid order by crtd_datetime desc ) = 1
qualify row_number() over (partition by custid order by crtd_datetime desc ) = 1
),

tuyen_dms_moinhat as (

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
      delroutedet is false --and slsperid not in ('MR1008','MR1705','MR2610','MR1225','MR2596','MR2594','MR2611')
      qualify row_number() over ( partition by custid order by routetype asc,crtd_datetime desc) = 1

),
group_split as (
  SELECT
    branchid,
    ordernbr,
    discamt,
    split(groupreflineref, ",") as group_split,
    length(groupreflineref) - length(replace(groupreflineref, ',', '')) + 1 as count_lineref
  FROM
    `spatial-vision-343005.staging.f_orddisc_all`
    where discidpn in ( '202401-TL-QD976-PMC-CTD')
),
flattened as (
  select
    branchid,
    ordernbr,
    count_lineref,
    flattened_group,
    sum(discamt) as discamt
  FROM
    group_split,
    group_split.group_split AS flattened_group
    group by 1,2,3,4
),

f_accumulatedresult_d as 

(
  select distinct ordernbr, custid from staging.f_accumulatedresult_d where accumulateid = '202401-TL-QD976-PMC-CTD'
)


, data_sales as 
(
    select 
    a.macongtycn,
    a.makhdms,
    a.sodondathang,
    a.lineref,
    date_trunc(ngaychungtu,month) as ngaychungtu,
    count_lineref, 
    sum(doanhsocovat) as doanhsocovat,
    sum(Case when doanhsocovat <0 then discamt * -1 else discamt end) as discamt,
    FROM
    `spatial-vision-343005.staging.f_sales` a
    JOIN flattened b ON a.mahd = b.ordernbr
    and a.macongtycn = b.branchid
    and a.lineref = b.flattened_group
      where
    date(a.ngaychungtu) >= '2024-01-01'
    and a.masanpham != 'T3041007'
    group by 1,2,3,4,5,6
),



result as (
  SELECT
    t2.accumulateid,
    t2.custid as makhdms,
    t4.custname tenkhachhang,
    Case
      when extract(
        month
        from
          a.ngaychungtu
      ) = 1 then a.doanhsocovat
      else 0
    end as accumulatedvalue_t1,
    Case
      when extract(
        month
        from
          a.ngaychungtu
      ) = 2 then a.doanhsocovat
      else 0
    end as accumulatedvalue_t2,
    Case
      when extract(
        month
        from
          a.ngaychungtu
      ) = 3 then a.doanhsocovat
      else 0
    end as accumulatedvalue_t3,
    Case
      when extract(
        month
        from
          a.ngaychungtu
      ) = 4 then a.doanhsocovat
      else 0
    end as accumulatedvalue_t4,
    Case
      when extract(
        month
        from
          a.ngaychungtu
      ) = 5 then a.doanhsocovat
      else 0
    end as accumulatedvalue_5,
    Case
      when extract(
        month
        from
          a.ngaychungtu
      ) = 6 then a.doanhsocovat
      else 0
    end as accumulatedvalue_t6,
    Case
      when extract(
        month
        from
          a.ngaychungtu
      ) = 7 then a.doanhsocovat
      else 0
    end as accumulatedvalue_t7,
    Case
      when extract(
        month
        from
          a.ngaychungtu
      ) = 8 then a.doanhsocovat
      else 0
    end as accumulatedvalue_t8,
    Case
      when extract(
        month
        from
          a.ngaychungtu
      ) = 9 then a.doanhsocovat
      else 0
    end as accumulatedvalue_t9,
    Case
      when extract(
        month
        from
          a.ngaychungtu
      ) = 10 then a.doanhsocovat
      else 0
    end as accumulatedvalue_t10,
    Case
      when extract(
        month
        from
          a.ngaychungtu
      ) = 11 then a.doanhsocovat
      else 0
    end as accumulatedvalue_t11,
    Case
      when extract(
        month
        from
          a.ngaychungtu
      ) = 12 then a.doanhsocovat
      else 0
    end as accumulatedvalue_t12,
    doanhsocovat as accumulatedvalue,
    ngaychungtu as orderdate,
    -- sodondathang as origordernbr,
    safe_divide(discamt, count_lineref) as sumdiscamt,
    t3.col.ma_nvbh as crtd_user,
    t2.purchaseagreementvalue,
    -- ,t3.tencvbh tencvbh1
    Case
      when t5.tenquanlyvung = 'Lương Trịnh Thắng' then t5.supid_bh
      else t5.supid
    end as ma_crm,
    t5.asm as ma_scrm,
    LEFT(t5.rsmid, 6) as ma_ncxm,
    t5.tencvbh tencvbh,
    Case
      when t5.tenquanlyvung = 'Lương Trịnh Thắng' then t5.tenquanlytt_bh
      else t5.tenquanlytt
    end as tenquanlytt,
    t5.tenquanlykhuvuc as tenquanlykhuvuc,
    t5.tenquanlyvung as tenquanlyvung,
    t4.channel,
    t4.branchid,
    t4.statedescr,
    t4.shortterritorydescr,
    t4.shoptype,
    t4.branchid as macongtycn,
    count_lineref,
  
    discamt as ori_discamt,
    doanhsocovat as dstichluy,
    current_datetime("+7") as updated_at,
    a.sodondathang,
    a.lineref

  FROM  d_accumulatedregis t2 
    -- `spatial-vision-343005.staging.f_sales` a
    -- JOIN flattened b ON a.mahd = b.ordernbr
    -- and a.macongtycn = b.branchid
    -- and a.lineref = b.flattened_group

    LEFT JOIN data_sales a on t2.custid = a.makhdms
    LEFT JOIN f_accumulatedresult_d c ON a.sodondathang = c.ordernbr
    and a.makhdms = c.custid
    -- LEFT JOIN tuyen_dms_moinhat t3 on t3.custid = t2.custid 
    LEFT JOIN `warehouse.f_mapping_crs` t3 on t3.custid = t2.custid 
    left join `spatial-vision-343005.staging.d_users` t5 on t3.col.ma_nvbh = t5.manv
    left join `spatial-vision-343005.staging.d_master_khachhang` t4 on t2.custid = t4.custid
  where c.ordernbr is null

  order by
    a.makhdms
)
select
  *
from
  result


 );

Create or replace table `warehouse.f_thoathuan_muaban_tp`

copy `staging_temp.f_thoathuan_muaban_tp_temp`;

End;