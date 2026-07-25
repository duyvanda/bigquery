CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_trungbay_ebysta_quy3_2023()
BEGIN 
 TRUNCATE TABLE staging_temp.f_trungbay_ebysta_quy3_2023_temp;

 INSERT INTO staging_temp.f_trungbay_ebysta_quy3_2023_temp(

-- Create or replace table staging_temp.f_trungbay_ebysta_quy3_2023_temp
-- as
with data_sales as (
	select
		soluong,
		doanhsochuavat,
		makhdms,
		date(thang) as thang
	from
		 warehouse.f_sales_crs
	where
		ngaychungtu >= '2023-07-01'
		and ngaychungtu < '2024-01-01'
		and masanpham = 'EH115'
		and doanhsochuavat <> 0
		and makenhkh <>'OTH_LAB'
),
group_sales as (
	-- quy cách thùng ebysta là 20 gói / hộp ( doanh số đang tính theo số lượng gói )
	select
		makhdms,
		thang,
		sum(soluong) as soluong,
		sum(doanhsochuavat) as doanhsochuavat
	from
		data_sales
	group by
		1,
		2
),

data_trungbay as 
(
  SELECT
		machuongtrinh,
		tenchuongtrinh,
		thoigiantbtu,
		thoigiantbden,
		makhachhang as makh,
		tenkhachhang as tennhathuoctenhco,
		phanloaihco,
		diachikhachhang as diachitheodms,
		thanhphotinh as tinhtp,
		lienhe,
		sodienthoai,
		manhanviendangky,
		tennhanviendangky,
		manhanvienphutrach as macrs,
		tennhanvienphutrach as crs,
		somattrungbay
    	FROM
		`spatial-vision-343005.staging.d_tdisplay` a
    	WHERE
		 machuongtrinh in( '2307-CTTB-CPA26-NT-QT')
		and lower(trangthaiduyettrungbay) = 'đã duyệt' 
    QUALIFY ROW_NUMBER() OVER (PARTITION BY makhachhang ORDER BY manhanvienphutrach) = 1
),
mapping_sales as (
	SELECT
		a.*,
		b1.thang,
		b1.soluong
	FROM
		data_trungbay a
		LEFT JOIN group_sales b1 on trim(upper(a.makh)) = trim(upper(b1.makhdms))

),
pivot_result as (
	select
		*
	from
		mapping_sales pivot(
			sum(soluong) as soluong for thang in (
				'2023-07-01',
				'2023-08-01',
				'2023-09-01',
				'2023-10-01',
				'2023-11-01',
				'2023-12-01'
			)
		)
),
result as (
	select
		a.*,
		Case 
				when b2.tenquanlyvung ='Lương Trịnh Thắng' then b2.supid_bh 
				else b2.supid 
		end as ma_crm,
		b2.asm as ma_scrm,
		LEFT(b2.rsmid, 6) as ma_ncxm,
		Case 
				when b2.tenquanlyvung ='Lương Trịnh Thắng' then b2.tenquanlytt_bh 
				else b2.tenquanlytt 
		end as tenquanlytt_bh,
		b2.tenquanlykhuvuc,
		b2.tenquanlyvung,
		c.branchid,
		c.branchname,
		c.channel,
		c.shoptype,
		c.shortterritorydescr
	from
		pivot_result a
		LEFT JOIN `staging.d_users` b2 on a.macrs = b2.manv
		LEFT JOIN `staging.d_master_khachhang` c on c.custid =a.makh
)
select
	*
from
	result

  );
Create or replace table `warehouse.f_trungbay_ebysta_quy3_2023`

copy `staging_temp.f_trungbay_ebysta_quy3_2023_temp`;

End;