CREATE PROCEDURE `spatial-vision-343005`.staging_temp.f_tracuu_ctkm_sanpham()
OPTIONS(
  strict_mode=false)
BEGIN 
 
 TRUNCATE TABLE staging_temp.f_tracuu_ctkm_sanpham_temp;

 INSERT INTO `staging_temp.f_tracuu_ctkm_sanpham_temp`

(

-- Create or replace table `staging_temp.f_tracuu_ctkm_sanpham_temp`
-- as

--Danh sách KH tham gia thỏa thuận mua bán

with max_d_accumulatedregis as 
(
	select
		accumulateid,
		custid,
		max(crtd_datetime) as crtd_datetime
	from `spatial-vision-343005.staging.d_accumulatedregis`
	where accumulateid = '202301-TL-QD01-NT-QT-PKN-PKQ'
	group by 1,2
)
,

thoathuan_muaban as 
(
	select
		a.*,
		'Thỏa thuận mua bán' as datatype
	from `spatial-vision-343005.staging.d_accumulatedregis` a
	JOIN max_d_accumulatedregis b on a.accumulateid = b.accumulateid
                               and a.crtd_datetime = b.crtd_datetime
                               and a.custid = b.custid
)
,

----Danh sách KH tham gia viplus
viplus as 
(
	select
		ma_hco_tren_dms as mahcotrendms,
		'Viplus' as datatype
	FROM `spatial-vision-343005.staging.d_manual_vipplus` a
	LEFT JOIN `staging.d_master_khachhang` d on d.custid = a.ma_hco_tren_dms
	where d.shoptype in ('PMC', 'PCL', 'CTD')
		    and d.hcotypeid not in ('NTPP', 'QTDN', 'NTXQPK', 'DLPP3') -- chị Cúc bỏ DLPP3 ngày 26/6 
		    and ma_hco_tren_dms not in ('NAN012', 'N06502071', '003374')
)
,

----Danh sách KH tham gia trưng bày Ebysta
trungbay_ebysta as 
(
	SELECT 
    distinct
		makhachhang, 
    'Trưng bày Ebysta' as datatype
	FROM `spatial-vision-343005.staging.d_tdisplay`
	where machuongtrinh = '2307-CTTB-CPA26-NT-QT' and trangthaiduyettrungbay ='Đã duyệt'
)

SELECT
	a.discseq,
	a.discidpn,
	a.discounttype,
	a.discountdescr,
	a.descr,
	a.startdate,
	a.enddate,
	case when (cast(a.enddate as datetime)) >= current_datetime() then 1 else 0 end as active,
	a.statusname,
	b.invtid,
	b.descr as tensp,
	case when c.channelid is null then e.channel else c.channelid end as kenh_apdung,
	case when c.shoptypeid is null then e.shoptype else c.shoptypeid end as kenhphu_apdung,
	d.custid,
	e.custname,
	i.lineref,
	i.descr as bac_ctkm ,
	i.breakamt,
  c.contractformid,
	k.nhomcpa2,
	Case when g.datatype is not null and f.datatype is not null and h.datatype is not null then g.datatype || ',' || f.datatype || ',' || h.datatype
		   when g.datatype is null and f.datatype is not null and h.datatype is not null then f.datatype || ',' || h.datatype
		   when g.datatype is not null and f.datatype is null and h.datatype is not null then g.datatype || ',' || h.datatype
		   when g.datatype is not null and f.datatype is not null and h.datatype is null then g.datatype || ',' || f.datatype
		   when g.datatype is not null and f.datatype is null and h.datatype is null then g.datatype
		   when g.datatype is null and f.datatype is not null and h.datatype is null then f.datatype
		   when g.datatype is null and f.datatype is null and h.datatype is not null then h.datatype
		   else ''
	     end as check_cttl

FROM `spatial-vision-343005.staging.d_discseq` a
LEFT JOIN `spatial-vision-343005.staging.d_discitem` b on a.discid = b.discid
                                                          and a.discseq = b.discseq
LEFT JOIN `spatial-vision-343005.staging.d_discorg` c on a.discid = c.discid
	                                                       and a.discseq = c.discseq
LEFT join `spatial-vision-343005.staging.d_disccust` d on a.discid = d.discid
	                                                        and a.discseq = d.discseq
LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` e on d.custid = e.custid
LEFT JOIN thoathuan_muaban f on f.custid = e.custid
LEFT JOIN viplus g on g.mahcotrendms = e.custid
LEFT JOIN trungbay_ebysta h on h.makhachhang = e.custid 
LEFT JOIN `spatial-vision-343005.staging.disbreak` i on a.discid = i.discid
	                                                      and a.discseq = i.discseq
LEFT JOIN `spatial-vision-343005.staging.d_nhom_sp_trading` k on b.invtid = k.masanpham																							

);

Create or replace table `warehouse.f_tracuu_ctkm_sanpham`

copy `staging_temp.f_tracuu_ctkm_sanpham_temp`;

END;