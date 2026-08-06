-- ==========================================================================
-- Routine Name : sp_f_data_checkin_mds
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2025-11-11 06:08:02.434000+00:00
-- Last Altered : 2025-11-11 06:08:02.434000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_data_checkin_mds()
BEGIN

-- TRUNCATE TABLE staging_temp.f_data_checkin_mds_temp;
-- INSERT INTO staging_temp.f_data_checkin_mds_temp
DECLARE partition_date DATE DEFAULT DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH), MONTH);
BEGIN TRANSACTION;
DELETE FROM
    `warehouse.f_data_checkin_mds`
WHERE
    DATE(visitdate) >= DATE(partition_date);
INSERT INTO
    `warehouse.f_data_checkin_mds`

with order_checkin as
(
  with order_checkin as
  (
  	SELECT
 			branchid,
  		slsperid,
    	deordernbr,
      de_updatetime,
      numbercico,
      inserted_at
 		FROM `spatial-vision-343005.staging.sync_dms_decheckin`
		where true
		and date(de_updatetime) >= partition_date
	)
	,
 	max_order_checkin as
	(
		select
			branchid,
			slsperid,
			deordernbr,
			max(de_updatetime) as max_de_updatetime
		from `spatial-vision-343005.staging.sync_dms_decheckin`
		where true
		and date(de_updatetime) >= partition_date
		group by 1,2,3
  )

	select a.*
	from order_checkin a
	JOIN max_order_checkin b
	on a.branchid =b.branchid
	and a.slsperid =b.slsperid
	and a.deordernbr =b.deordernbr
	and a.de_updatetime = b.max_de_updatetime
)
,
data_checkin as
(
  select slsperid,custid,branchid,lat,lng,typ,checktype,updatetime,numbercico
  from `spatial-vision-343005.staging.d_checkin`
	where true
	and date(updatetime) >= partition_date
)
,
sales_checkin as
(
	select *
	from `spatial-vision-343005.staging.sync_dms_sacheckin`
	where true
	and date(sa_updatetime) >= partition_date
)
, display_remark as

(
	SELECT distinct salesid, 'Trưng bày' as checkintype FROM `spatial-vision-343005.staging.d_display_criteria_remark`
	where true
	and date(visitdate) >= partition_date
)
, checkin_note as
(
	select *
	from ( select custid,
  							visitdate,
    						noteid,
      					slsperid,
								branchid,
        				note,
          			descr,
            		a.salesid,
              	distance,
                case when b.checkintype is not null then b.checkintype else a.checkintype end as checkintype ,
                imagefilename,
                inserted_at,
								row_number() over(partition by slsperid, a.salesid order by branchid desc) as row_
   				from `spatial-vision-343005.staging.sync_dms_oc` a
					LEFT join display_remark b on a.salesid = b.salesid
					where true
					and date(visitdate) >= partition_date
			 ) a
	where row_ = 1
)
,
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

result as
(
	SELECT
		distinct b.*,
		Case when b.branchid ='MR0001' then 'DH0'
				 when b.branchid ='MR0010' then 'DH1'
				 when b.branchid ='MR0012' then 'DH2'
				 when b.branchid ='MR0013' then 'DH3'
				 when b.branchid ='MR0014' then 'DH4'
				 when b.branchid ='MR0015' then 'DH5'
				 when b.branchid ='MR0016' then 'DH6'
				 else null end as mapping_donhang,
		a.typ as checkin,
		Case when a.updatetime is null then b.visitdate else a.updatetime  end as time_checkin,
		a.lat,
		a.lng,
		c.typ as checkout,
		c.updatetime  as time_checkout,
--c.lat as lat_out, c.lng as lng_out,
-- d.typ as action, d.updatetime as time_action ,
-- Case when d.typ ='PA' and e.deordernbr is not null then 'Giao hàng'
-- 		 when d.typ like 'DE%'  then 'Giao hàng'
-- 		 when d.typ ='PA' and e.deordernbr is  null then 'Thanh toán công nợ'
-- 		 when d.typ ='CL' then 'Close'
-- 		 when d.typ ='IO' then 'In outlet'
-- 		 when d.typ ='PS' then 'Program Sales'
-- 		 when d.typ ='SO' then 'Sales ord vào step ghi nhận đơn hàng'
-- 		 when d.typ ='OO' then 'Out outlet'
-- 		 when d.typ ='DP' then 'trưng bày'
-- 		 when d.typ ='SA' then 'Có đơn hàng'
-- 		 when d.typ ='FC' then 'Feedback customer'
-- 		 when d.typ ='PO' then 'POSM/Gimmick'
-- 		 when d.typ ='SK' then 'Stock keeping'
-- else null end as phanloai_checkin,
--d.lat as lat_action, d.lng as lng_action
-- Case when d.typ like 'DE%' then substr(d.typ, 3)
-- else
-- e.deordernbr end as deordernbr,
		Case when b.checkintype ='Bán Hàng' then f.saordernbr
				when b.checkintype ='Giao Hàng' then e.deordernbr
				else null end as ordernbr,
		e.deordernbr,
		f.saordernbr,
		f.ordamt,
		h.manv,
		h.tencvbh as mds,
		h.supid,
		h.tenquanlytt,
		h.tenquanlykhuvuc,
		h.tenquanlyvung,
		k.custname,
		k.statedescr,
		k.territorydescr,
		g.role,
		l.chinhanh as chinhanh_dialy
		FROM checkin_note b
		LEFT JOIN data_checkin a  on a.slsperid = b.slsperid
															and a.custid = b.custid --and a.branchid =b.branchid
															and b.salesid = a.numbercico
															and a.checktype = 'IO'
		LEFT JOIN data_checkin c  on c.slsperid = b.slsperid
															and c.custid = b.custid --and c.branchid =b.branchid
															and b.salesid = c.numbercico
															and c.checktype ='OO'
		LEFT JOIN order_checkin e on e.slsperid = b.slsperid
															and e.branchid = b.branchid
															and e.numbercico = b.salesid
															and b.checkintype = 'Giao Hàng'--and (d.typ ='PA' or d.typ like 'DE%')
		LEFT JOIN sales_checkin f on f.numbercico = b.salesid
															and f.slsperid = b.slsperid
															and f.branchid = b.branchid
															and b.checkintype ='Bán Hàng'

		LEFT JOIN `spatial-vision-343005.staging.d_dms_master_users` g on g.username = b.slsperid
		LEFT JOIN `spatial-vision-343005.staging.d_users` h on h.manv = b.slsperid
		LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` k on k.custid = b.custid --and k.branchid = b.branchid
		left join `spatial-vision-343005.staging.d_tinh` l on k.statedescr = l.tinh

)
select *
from result
;

COMMIT TRANSACTION;
-- Create or replace table `warehouse.f_data_checkin_mds`
-- copy `staging_temp.f_data_checkin_mds_temp`;
End;
