CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_chuongtrinh_momoi_ebysta_pcl()
BEGIN 
  TRUNCATE TABLE staging_temp.f_chuongtrinh_momoi_ebysta_pcl_temp;


 INSERT INTO staging_temp.f_chuongtrinh_momoi_ebysta_pcl_temp(

-- Create or replace table staging_temp.f_chuongtrinh_momoi_ebysta_pcl_temp as

with tuyen_dms_moinhat as (
	with a as (
		select
			distinct makhdms as custid,
			manv,
			tenquanlyvung,
			tencvbh,
			tenquanlytt,
			ma_crm as crm,
			scrm,
			ma_ncxm as ncxm,
			Case
				when tenquanlyvung = 'Nguyễn Thọ Chiến' then 1
				else 3
			end as datatype,
			ngaychungtu
		from
			warehouse.f_raw_data_sales_yoy
		where
			ngaychungtu >= '2023-01-01'
			and tenquanlyvung in ('Nguyễn Thọ Chiến')
	)
	select
		*
	from
		a qualify row_number() over (
			partition by custid
			order by
				ngaychungtu desc,
				datatype asc
		) = 1
),
data_sales_kh_ebysta as (
	SELECT
		makhdms,
		sum(doanhsochuavat) as doanhsochuavat
	FROM
		`spatial-vision-343005.staging.f_sales` a
	where
		ngaychungtu >= '2023-01-01'
		and masanpham in ('EH115')
		and ngaychungtu < '2023-08-01'
	group by
		1
	having
		doanhsochuavat > 0
),
loc_kh_theo_quydinh as (
	select
		a.custid,
		-- a.crtd_datetime,
		-- a.statedescr,
		-- a.hcoid,
		-- a.custname,
		Case
			when a.crtd_datetime >= '2023-08-01' then 'Y'
			else 'N'
		end as is_taosau_t8,
		Case
			when b.makhdms is not null then 'Y'
			else 'N'
		end as is_phatsinh_doanhsochuavat
	from
		`staging.d_master_khachhang` a
		LEFT JOIN data_sales_kh_ebysta b on a.custid = b.makhdms
	where
		channel = 'PCL'
		and active = 'Active'
		and custid not like 'DS%'
),
data_kh_result as (
	select
		*
	from
		loc_kh_theo_quydinh
	where
		is_taosau_t8 = 'Y'
		or (
			is_taosau_t8 = 'N'
			and is_phatsinh_doanhsochuavat = 'N'
		)
),
data_sales_dh_dautien as (
	SELECT
		makhdms,
		sodondathang,
		manv,
		ngaychungtu,
		sum(doanhsochuavat) as doanhsochuavat,
		sum(soluong) as soluong
	FROM
		`spatial-vision-343005.warehouse.f_raw_data_sales_yoy` a
	LEFT JOIN `staging.d_master_khachhang` b on a.makhdms =b.custid
	where
		ngaychungtu >= '2023-08-01'
		and masanpham in ('EH115') 
		and b.channel = 'PCL'
		and b.active = 'Active'
		and b.custid not like 'DS%'
	group by
		1,
		2,
		3,
		4 qualify row_number() over (
			partition by makhdms
			order by
				ngaychungtu
		) = 1
),
data_sales as (
	SELECT
		makhdms,
		manv,
		-- date(date_trunc(ngaychungtu,month)) as thang,
		sum(doanhsochuavat) as doanhsochuavat,
		sum(
			Case
				when extract (
					month
					from
						ngaychungtu
				) = 8 then doanhsochuavat
				else 0
			end
		) as doanhsochuavat_t8,
		sum(
			Case
				when extract (
					month
					from
						ngaychungtu
				) = 9 then doanhsochuavat
				else 0
			end
		) as doanhsochuavat_t9,
		sum(
			Case
				when extract (
					month
					from
						ngaychungtu
				) = 10 then doanhsochuavat
				else 0
			end
		) as doanhsochuavat_t10
	FROM
		`spatial-vision-343005.warehouse.f_raw_data_sales_yoy` a
		LEFT JOIN `staging.d_master_khachhang` b on a.makhdms =b.custid
	where
		ngaychungtu >= '2023-08-01'
		and masanpham in ('EH115')
		and b.channel = 'PCL'
		and b.active = 'Active'
		and b.custid not like 'DS%'
	group by
		1,
		2 -- 3
	having
		doanhsochuavat <> 0
)
select
	ifnull(a.custid, c.makhdms) as custid,
	a.is_taosau_t8,
	a.is_phatsinh_doanhsochuavat,
	d.crtd_datetime,
	d.statedescr,
	d.hcoid,
	d.custname,
	d.branchid,
	d.branchname,
	d.channel,
	d.shoptype,
	d.shortterritorydescr,
	min(b.ngaychungtu) over (partition by ifnull(a.custid, c.makhdms)) as ngaychungtu,
	b.sodondathang,
	b.soluong,
	b.doanhsochuavat as doanhsochuavat_dh_dautien,
	Case
		when f.loaihdld in ('Thử việc', 'Học việc') or f.loaihdld is null then 0
		when b.soluong >= 3 and extract (month from b.ngaychungtu) = 8 then 50000
		else 0
	end as thuongmomoi_ebysta_t8,
		Case
		when f.loaihdld in ('Thử việc', 'Học việc') or f.loaihdld is null then 0
		when b.soluong >= 3 and extract (month from b.ngaychungtu) = 9 then 50000
		else 0
	end as thuongmomoi_ebysta_t9,
		Case
		when f.loaihdld in ('Thử việc', 'Học việc') or f.loaihdld is null then 0
		when b.soluong >= 3 and extract (month from b.ngaychungtu) = 10 then 50000
		else 0
	end as thuongmomoi_ebysta_t10,
		Case
		when f.loaihdld in ('Thử việc', 'Học việc') or f.loaihdld is null then 0
		when b.soluong >= 3 then 50000
		else 0
	end as thuongmomoi_ebysta,

	Case
		when f.loaihdld in ('Thử việc', 'Học việc') or f.loaihdld is null then 0
		else round(c.doanhsochuavat * 2 / 100, 2)
	end as thuong_crs,
	Case
		when f.loaihdld in ('Thử việc', 'Học việc') or f.loaihdld is null then 0
		else round(c.doanhsochuavat_t8 * 2 / 100, 2)
	end as thuong_crs_t8,
	Case
		when f.loaihdld in ('Thử việc', 'Học việc') or f.loaihdld is null then 0
		else round(c.doanhsochuavat_t9 * 2 / 100, 2)
	end as thuong_crs_t9,
	Case
		when f.loaihdld in ('Thử việc', 'Học việc') or f.loaihdld is null then 0
		else round(c.doanhsochuavat_t10 * 2 / 100, 2)
	end as thuong_crs_t10,
	c.doanhsochuavat,
	c.doanhsochuavat_t8,
	c.doanhsochuavat_t9,
	c.doanhsochuavat_t10,
	ifnull(b.manv, c.manv) as manv,
	e.supid_bh as crm,
	e.asm as scrm,
	left(e.rsmid, 6) as ncxm,
	e.tencvbh,
	e.tenquanlytt_bh as tenquanlytt,
	e.tenquanlyvung,
	Case when (b.ngaychungtu is null and doanhsochuavat_t9 > 0) or (extract(month from b.ngaychungtu)=9 ) then 'T9' else null end as filter_t9,
	Case when (b.ngaychungtu is null and doanhsochuavat_t8 > 0) or (extract(month from b.ngaychungtu)=8 ) then 'T8' else null end as filter_t8,
	Case when (b.ngaychungtu is null and doanhsochuavat_t10 > 0) or (extract(month from b.ngaychungtu)=10 ) then 'T10' else null end as filter_t10,
from
	data_kh_result a
	LEFT JOIN data_sales_dh_dautien b on a.custid = b.makhdms 
	FULL JOIN data_sales c on a.custid = c.makhdms
	and c.manv = b.manv
	LEFT JOIN `staging.d_master_khachhang` d on d.custid = ifnull(a.custid, c.makhdms)
	LEFT JOIN `staging.d_users` e on e.manv = ifnull(b.manv, c.manv)
	LEFT JOIN `staging.d_hr_dsns` f on f.msnvcsmmoi = ifnull(b.manv, c.manv)

    );

Create or replace table `warehouse.f_chuongtrinh_momoi_ebysta_pcl`

copy `staging_temp.f_chuongtrinh_momoi_ebysta_pcl_temp`;


End;