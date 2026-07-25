CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_data_checkin_pbh_16042025()
BEGIN

TRUNCATE TABLE `staging_temp.f_data_checkin_pbh_temp`;

INSERT INTO `staging_temp.f_data_checkin_pbh_temp`

(   
WITH nghiphep AS (
    SELECT DISTINCT
        manvcsm,
        DATE(ngay) AS ngay,
        CASE 
            WHEN EXTRACT(DAYOFWEEK FROM ngay) = 7 THEN 'P'
            ELSE loainghiphep 
        END AS loainghiphep
    FROM 
        `spatial-vision-343005.staging.d_manual_danhsach_nghiphep_pbh`
    WHERE
        bophan IN ('TP', 'MT', 'SDS')
        AND 
        (
        CASE 
        WHEN loainghiphep like 'P%' then true
        WHEN loainghiphep like 'T%' then true
        else false end
        )
),

tuyen_dms_moinhat AS (
    SELECT
        a.custid,
        slsperid,
        a.crtd_datetime,
        DATE(a.thang) AS thang,
        CASE
            WHEN routetype IN ('B', 'D') THEN 1
            ELSE 2
        END AS routetype,
        slsfreq
    FROM 
        `spatial-vision-343005.staging.sync_dms_srm_bytime` a
        LEFT JOIN `staging.d_master_khachhang_bytime` b 
            ON a.custid = b.custid 
            AND a.thang = b.thang
    WHERE
        a.thang >= '2024-01-01' 
        AND delroutedet IS FALSE 
        AND b.active = 'Active'
        AND (
            CASE 
                WHEN b.channel IN ('MT', 'PCL') THEN TRUE
                WHEN b.channel = 'TP' 
                    AND b.statedescr NOT IN ('Lạng Sơn') 
                    AND CONCAT(b.statedescr, b.districtdescr) NOT IN (
                        'Quảng NinhThành phố Móng Cái',
                        'Quảng NinhHuyện Hải Hà',
                        'Quảng NinhHuyện Ba Chẽ',
                        'Quảng Ninh Huyện Tiên Yên',
                        'Quảng NinhHuyện Đầm Hà'
                    )
                THEN TRUE
                ELSE FALSE 
            END
        )
    QUALIFY ROW_NUMBER() OVER (PARTITION BY custid, thang ORDER BY routetype ASC, crtd_datetime DESC) = 1
)

, data_checkin as (
    select
        slsperid,
        custid,
        branchid,
        lat,
        lng,
        typ,
        checktype,
        updatetime,
        numbercico
    from
        `spatial-vision-343005.staging.d_checkin`
    where
        updatetime >= '2024-01-01'
        QUALIFY ROW_NUMBER() OVER (PARTITION BY slsperid, numbercico, checktype ORDER BY branchid) = 1
),

checkin_note as (
    select
        a.custid,
        a.visitdate,
        a.noteid,
        a.slsperid,
        a.note,
        a.descr,
        a.salesid,
        a.distance,
        a.checkintype,
        a.imagefilename,
        b.channel
    from
        `spatial-vision-343005.staging.sync_dms_oc` a
        left join `staging.d_master_khachhang_bytime` b on a.custid = b.custid and date_trunc(a.visitdate,month) =b.thang
    where

        date(visitdate) >='2024-01-01' and
        a.checkintype = 'Bán Hàng'
        and 
        (
            b.channel in ('MT','PCL') or 
        (
            b.channel ='TP'
            and b.statedescr not in ('Lạng Sơn') and 
            concat(b.statedescr,b.districtdescr) not in ('Quảng NinhThành phố Móng Cái','Quảng NinhHuyện Hải Hà','Quảng NinhHuyện Ba Chẽ','Quảng Ninh Huyện Tiên Yên','Quảng NinhHuyện Đầm Hà')
        )
        )
        and b.active ='Active'

        qualify row_number() over(
            partition by slsperid,
            salesid
            order by
                a.branchid
        ) = 1
),

/*
 CL = Close
 IO= In outlet
 PS= Program Sales
 SO= Sales ord vào step ghi nhận đơn hàng
 PA= Thanh toán công nợ
 OO= Out outlet
 DP= trưng bày
 SA= Có đơn hàng
 FC= Feedback customer
 PO = POSM/Gimmick
 SK= Stock keeping
 */
data_quydinh_viengtham as (
    SELECT
        date(visitdate) as visitdate1,
        a.slsperid as slsperid1,
        a.custid as custid1,
        b.channel
        
    FROM
        `spatial-vision-343005.staging.sync_dms_salesroutedet` a
        left join `staging.d_master_khachhang_bytime` b on a.custid =b.custid and date_trunc(a.visitdate,month) =b.thang
        JOIN tuyen_dms_moinhat c on date_trunc(date(a.visitdate), month) =c.thang 
                                 and a.custid =c.custid and a.slsperid =c.slsperid
    where
        ( (extendroute is false and date(visitdate) >='2025-03-01') or
        (date(visitdate) >='2024-01-01' and date(visitdate) <'2025-03-01') ) and
        delroutedet is false
        and b.active='Active'
        -- and b.channel in ('TP','PCL','MT')
        and 
        (
            b.channel in ('MT','PCL') or 
        (
            b.channel ='TP'
            and b.statedescr not in ('Lạng Sơn') and 
            concat(b.statedescr,b.districtdescr) not in ('Quảng NinhThành phố Móng Cái','Quảng NinhHuyện Hải Hà','Quảng NinhHuyện Ba Chẽ','Quảng Ninh Huyện Tiên Yên','Quảng NinhHuyện Đầm Hà')
        )
        )
        and concat(a.slsperid,date(a.visitdate)) not in (select concat(manvcsm,ngay) from nghiphep)
        and a.custid not in ('013079','013452','013458','013469','013472','007441','007442','014342')
        and concat(a.slsperid,concat(a.custid,date(a.visitdate))) not in (SELECT concat(slsperid,concat(custid,date(visitdate))) FROM `spatial-vision-343005.staging.d_manual_loai_tru_call`)
),

data_quydinh_viengtham_thang as 
(
select slsperid1 as slsperid,custid1 as custid,date(date_trunc(date(visitdate1), month)) as thang from data_quydinh_viengtham group by 1,2,3
),

result_checkin as (
    SELECT
        b.*,
        a.typ as checkin,
        Case
            when a.updatetime is null then b.visitdate
            else a.updatetime
        end as time_checkin,
        a.lat,
        a.lng,
        c.typ as checkout,
        c.updatetime as time_checkout,
        f.saordernbr as ordernbr,
        f.saordernbr,
        f.ordamt
    FROM
        checkin_note b
        LEFT JOIN data_checkin a on a.slsperid = b.slsperid
        and a.custid = b.custid
        and b.salesid = a.numbercico
        and a.checktype = 'IO'
        LEFT JOIN data_checkin c on c.slsperid = b.slsperid
        and c.custid = b.custid
        and b.salesid = c.numbercico
        and c.checktype = 'OO'
        LEFT JOIN `spatial-vision-343005.staging.sync_dms_sacheckin` f on f.numbercico = b.salesid
        and f.slsperid = b.slsperid
         
),
mapping_viengtham as (
    select
        custid1 as custid,
        Cast(visitdate1 as timestamp) as visitdate,
        null as noteid,
        slsperid1 as slsperid,
        null as note,
        null as descr,
        null as salesid,
        null as distance,
        null as checkintype,
        null as imagefilename,
        channel,
        null as checkin,
        null as time_checkin,
        null as lat,
        null as lng,
        null as checkout,
        null as time_checkout,
        null as ordernbr,
        null as saordernbr,
        null as ordamt,
        custid1 as sl_quydinh,
        visitdate1 as visitdate_mapping,
        'Y' as is_lich_call,
        
    from
        data_quydinh_viengtham

    UNION ALL
    select
        *,
        null as sl_quydinh,
        null as visitdate_mapping,
        null as is_lich_call,
    from
        result_checkin
)

, result0 as (
    select
        b.*except(sl_quydinh),
        g.role,
        Case
            when b.salesid is not null  then count(b.salesid) over (partition by b.custid,date(b.visitdate),b.slsperid)
            else null
        end as so_lan_call_trong_ngay,
        Case
            when b.salesid is not null  then count(b.salesid) over (partition by date_trunc(b.visitdate,month),b.slsperid,b.custid)
            else null
        end as so_lan_call_trong_thang,

        Case
            when b.saordernbr is not null  then concat(b.custid, date(b.visitdate))
            else null
        end as sl_dh_thucte,
        Case
            when a.custid is not null then sl_quydinh
            else null
        end as sl_quydinh,
        Case
            -- when channel ='MT'  and b.salesid is not null and a.custid is not null and c.manvcsm is null then a.custid     
            when channel ='PCL' and b.salesid is not null and a.custid is not null and b.distance < 200 and c.manvcsm is null  then a.custid
            when channel ='PCL' and b.salesid is not null and a.custid is not null and b.distance >= 200 and b.descr ='Sai tọa độ khách hàng' and b.imagefilename is not null and c.manvcsm is null  then a.custid

            when channel in ('TP','MT') and b.salesid is not null and a.custid is not null and b.distance < 400 and c.manvcsm is null  then a.custid
            when channel in ('TP','MT') and b.salesid is not null and a.custid is not null and b.distance >= 400 and b.descr ='Sai tọa độ khách hàng' and b.imagefilename is not null and c.manvcsm is null  then a.custid
            else null
        end as sl_kh_checkin,

        Case
            -- when c.manvcsm is not null then null
            when a.custid is  null then b.custid
            else null
        end as sl_kh_checkin_ngoaimcp,

        Case
            -- when channel = 'MT' then null
            -- when channel = 'PCL' then null
            when channel = 'PCL' and b.salesid is not null and a.custid is not null and c.manvcsm is null and b.distance < 200  then concat(b.custid, date(b.visitdate)) 
            when channel = 'PCL' and b.salesid is not null and a.custid is not null and c.manvcsm is null and b.distance >= 200 and b.descr ='Sai tọa độ khách hàng' and b.imagefilename is not null 
                    then concat(b.custid, date(b.visitdate)) 
            when channel in ('TP','MT') and b.salesid is not null and a.custid is not null and c.manvcsm is null and b.distance < 400  then concat(b.custid, date(b.visitdate)) 
            when channel in ('TP','MT') and b.salesid is not null and a.custid is not null and c.manvcsm is null and b.distance >= 400 and b.descr ='Sai tọa độ khách hàng' and b.imagefilename is not null 
                    then concat(b.custid, date(b.visitdate)) 
            else null
        end as soluong_checkin_thucte,
        Case
            when b.saordernbr is not null then b.custid
            else null
        end as sl_kh_phatsinhdh,
        Case
            when a.custid is not null then 'Trong'
            else 'Ngoài'
        end as is_mcp,
        Case when b.descr ='Sai tọa độ khách hàng' then 'Có' else 'Không' end as is_check_mds_checkin_gh_saitoado,
        Case
            -- when channel ='MT' and b.salesid is not null and a.custid is not null and c.manvcsm is null then 'Đạt'
            when (channel = 'PCL' and b.salesid is not null and a.custid is not null and b.distance < 200  and c.manvcsm is null)   
            or (channel = 'PCL' and b.salesid is not null and a.custid is not null and b.distance >= 200 and b.descr ='Sai tọa độ khách hàng' and b.imagefilename is not null  and c.manvcsm is null) then 'Đạt'

            when (channel  in ('TP','MT') and b.salesid is not null and a.custid is not null and b.distance < 400  and c.manvcsm is null)   
            or (channel  in ('TP','MT') and b.salesid is not null and a.custid is not null and b.distance >= 400 and b.descr ='Sai tọa độ khách hàng' and b.imagefilename is not null  and c.manvcsm is null) then 'Đạt'
            else 'Không đạt'
        end as is_checkin_bh,
        a.custid as custid_mcp,
        d.slsfreq,
        Case when  c.manvcsm is not null then 'Y' else 'N' end as is_nghi_phep
    from
        mapping_viengtham b
        LEFT JOIN `spatial-vision-343005.staging.d_dms_master_users` g on g.username = b.slsperid
        LEFT JOIN data_quydinh_viengtham_thang a on date_trunc(date(b.visitdate), month) =a.thang 
                                 and a.custid =b.custid and a.slsperid =b.slsperid
        LEFT JOIN nghiphep c on date(b.visitdate) = c.ngay and b.slsperid = c.manvcsm --and b.is_lich_call is null 
        LEFT JOIN  tuyen_dms_moinhat  d on date_trunc(date(b.visitdate), month) = d.thang 
                                 and b.custid =d.custid and b.slsperid =d.slsperid
),
result1 as (
select *,
  count(concat(date(visitdate_mapping),sl_quydinh)) over (partition by custid,date_trunc(visitdate,month),slsperid) as solan_call_qd,
    dense_rank() over (partition by custid,date_trunc(visitdate,month),slsperid order by soluong_checkin_thucte ) as xephang,
    soluong_checkin_thucte as soluong_checkin_thucte_ori
from
    result0
),
result2 as 
(
select *except(soluong_checkin_thucte), 
    Case when solan_call_qd + 1 >= xephang then soluong_checkin_thucte else null end as soluong_checkin_thucte,
    Case 
        -- when channel ='MT' then null
        -- when channel ='PCL' then null
        when solan_call_qd + 2 <= xephang 
            or (
             row_number() over (partition by custid,date_trunc(visitdate,month),slsperid,soluong_checkin_thucte) >1 )
    then soluong_checkin_thucte else null end as soluong_checkin_thucte_vuot,
    Case
        -- when channel ='MT' then null
        -- when channel ='PCL' then null
        when visitdate_mapping is not null then null
        when row_number() over (partition by custid,case when visitdate_mapping is null then date(visitdate) else null end,slsperid order by soluong_checkin_thucte desc,time_checkin asc) >1 then 'Vượt số call trong ngày'
        when solan_call_qd + 2 <= xephang then 'Vượt số call quy định'
        else null 
    end as ischeck_vuot_gioihancall,
 from result1
),

result3 as (
select a.*except(custid_mcp),
        Case
            when b.custid1 is not null  then soluong_checkin_thucte
            else null
        end as soluong_trongtuyen,
        Case
            when b.custid1 is null  then soluong_checkin_thucte
            else null
        end as soluong_ngoaituyen,
        Case
            when b.custid1 is not null  
            and a.saordernbr is not null then soluong_checkin_thucte
            else null
        end as soluong_dh_trongtuyen,
        Case
            when b.custid1 is null
            and a.saordernbr is not null then soluong_checkin_thucte
            else null
        end as soluong_dh_ngoaituyen,
        Case
            -- when a.channel ='MT'  and (a.salesid is not null and a.custid_mcp is not null and is_nghi_phep ='N') then 'Đạt'
            when (a.channel ='PCL'  and a.salesid is not null and a.custid_mcp is not null and a.distance < 200 and ischeck_vuot_gioihancall is null and is_nghi_phep ='N' ) then 'Đạt'
            when  (a.channel ='PCL'  and a.salesid is not null and a.custid_mcp is not null and a.distance >= 200 and is_check_mds_checkin_gh_saitoado ='Có' 
                                and a.imagefilename is not null and ischeck_vuot_gioihancall is null and is_nghi_phep ='N') 
                    then 'Đạt'

            when (a.channel in ('TP','MT') and a.salesid is not null and a.custid_mcp is not null and a.distance < 400 and ischeck_vuot_gioihancall is null and is_nghi_phep ='N' ) then 'Đạt'
            when  (a.channel in ('TP','MT') and a.salesid is not null and a.custid_mcp is not null and a.distance >= 400 and is_check_mds_checkin_gh_saitoado ='Có' 
                                and a.imagefilename is not null and ischeck_vuot_gioihancall is null and is_nghi_phep ='N') 
                    then 'Đạt'
            else 'Không đạt'
        end as is_checkin_bh_v2,
        Case when is_nghi_phep ='Y' then 'Nghỉ phép'
             when is_mcp ='Trong' then 'Trong MCP'
             when is_mcp ='Ngoài' then 'Ngoài MCP'
        else null end as phan_loai_call    

 from result2 a 
        LEFT JOIN data_quydinh_viengtham b on b.visitdate1 = date(a.visitdate)
        and b.custid1 = a.custid
        and a.slsperid = b.slsperid1
        
),

pl_kh_tp as 

(
    select  date(date_trunc(visitdate,month)) as thang,custid,is_checkin_bh_v2,
    max(xephang) as so_call_dat,
    from result3   
    where is_checkin_bh_v2 ='Đạt' 
    group by 1,2,3
)

select a.*,
    Case 
        when  b.custid is not null then 'Đạt'
    else 'Không đạt'
    end as pl_kh_checkin,
    Case 
        when channel in ('TP','MT','PCL') and b.so_call_dat  >= solan_call_qd + 1 then 'Đủ'
        -- when channel in ('MT') then null
        else 'Không đủ'
    end as pl_solan_call
from result3 a 
LEFT JOIN pl_kh_tp b on a.custid = b.custid and date(date_trunc(a.visitdate,month))= b.thang 

);

Create or replace table `staging_temp.f_data_checkin_pbh`

copy `staging_temp.f_data_checkin_pbh_temp`;

END;