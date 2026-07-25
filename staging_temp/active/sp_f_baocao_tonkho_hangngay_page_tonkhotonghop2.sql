CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_baocao_tonkho_hangngay_page_tonkhotonghop2()
BEGIN 
  TRUNCATE TABLE staging_temp.f_baocao_tonkho_hangngay_page_tonkhotonghop2_temp;


 INSERT INTO staging_temp.f_baocao_tonkho_hangngay_page_tonkhotonghop2_temp(
-- Create table `staging_temp.f_baocao_tonkho_hangngay_page_tonkhotonghop2_temp`
-- as
with 
  base_name as
  ( select *
   from (select masanpham,tensanpham,row_number() over (partition by masanpham order by (toncn+tonhcm+tonao+tonhangdiduong+tonvime+tonnmtp+tonnmhh) desc) as row_
         from `spatial-vision-343005.staging.f_sc_daily_invt` ) b
 where row_=1
    )
    


select  a.masanpham,
a.created_date,
case when a.masanpham='OH072' then 'Osla Online' else c.tensanpham end tensanpham,
a.ton_kho_cn,
a.ton_kho_nm,
chinhanh


from (select 
	 masanpham,case when b.chinhanh = 'CT' then  'CẦN THƠ'
                                                                   when b.chinhanh =  'NA' then 'NGHỆ AN'
                                                             when b.chinhanh = 'HN' then 'HÀ NỘI'
                                                             when b.chinhanh = 'DNANG' then 'ĐÀ NẴNG'
                                                             when b.chinhanh =  'HP' then 'HẢI PHÒNG'
                                                             when b.chinhanh = 'HCM' then 'HCM'
                                                             when b.chinhanh = 'KH' then 'KHÁNH HÒA'
                                                             when b.chinhanh = 'DNAI' then 'ĐỒNG NAI'
                                                             else b.chinhanh end as chinhanh
      ,date(created_date) created_date
	--, tensanpham
	,sum(toncn + tonhcm + tonmerap + tonvime + tonao + tonhangdiduong) ton_kho_cn --
	,sum(tonnmtp+tonnmhh) ton_kho_nm
	from `spatial-vision-343005.staging.f_sc_daily_invt` b
    where lower(masanpham) not like 'v%' and lower(masanpham) not like 'p%'
    group by 1,2,3) a

left join base_name c on a.masanpham =c.masanpham

  );

Create or replace table `warehouse.f_baocao_tonkho_hangngay_page_tonkhotonghop2`

copy `staging_temp.f_baocao_tonkho_hangngay_page_tonkhotonghop2_temp`;

End;