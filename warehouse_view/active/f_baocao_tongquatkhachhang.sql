CREATE VIEW `spatial-vision-343005.warehouse.f_baocao_tongquatkhachhang`
AS with 

masterdata as 
(
  select 
    distinct (crtd_datetime) as ngaytao,
    custid as makh,
    statecode,
    'khdms' as source, 
    cast(legaldate as date) as thoihanhieulucgdpgpp,
    Case when legaldate is not null then custid else null end as is_co_gpp,
    Case when legaldate is null then custid else null end as is_ko_gpp,
    case when cast (legaldate as date) < CURRENT_DATETIME() then custid else null end as gpp_hethan,
    case when cast (legaldate as date) >= CURRENT_DATETIME() then custid else null end as gpp_conhan,
    taxregnbr,
    Case when taxregnbr is not null then custid else null end as is_co_mst,
    Case when taxregnbr is null then custid else null end as is_ko_mst,
  from `spatial-vision-343005.staging.d_master_khachhang` 
  -- where active = 'Active'
)
-- , caresoft as
-- (
--   WITH bang1a as 
--   (
--     select 
--       distinct date (thoidiemtao) as ngaytao,
--       inserted_at,
--       makhdms as makhOA,
--       sodienthoaichinh as sdtOA,
--       'OA' as source,
--       row_number() over (partition by makhdms order by thoidiemtao asc ) as loc
--     from `spatial-vision-343005.staging.d_caresoft_customer`
--     where makhdms is not null
--   )
--   select * from bang1a
--   where loc = 1
-- )
,

ecom as 
(
  with bang2a as 
  (
    select 
      distinct date(created_at) as ngayactive,
      customer_phone as sdtEO,
      customer_code as makhEO,
      follow_phone,
      'EO' as source,
      row_number() over (partition by customer_code order by created_at asc) as loc
    from `spatial-vision-343005.staging.f_crawl_activate_ecom`
  )
  select * from bang2a 
  where loc = 1
)
,

pda_so as 
( 
  with bang3a as
  (
  select 
      custid as makhDMS,
      'DMS' as source,
      min( date (crtd_datetime)) as ngaytaodonDMS,
      
      -- row_number() over (partition by custid order by crtd_datetime asc ) as loc
    from `spatial-vision-343005.staging.sync_dms_pda_so` 
    where (crtd_user ='TMDT_001' and slsperid = 'TMDT_001') and status = 'C'
    group by 1,2
  )
  select * from bang3a 
  -- where loc = 1
)
,

bang_doanhso_2022 as
(
  select 
    a.makhdms,
    sum(a.doanhsochuavat) as doanhsochuavat
  from  `spatial-vision-343005.staging.f_sales` a 
  where ngaychungtu >='2022-01-01'
  group by 1
  having doanhsochuavat > 0
)
,

data_sales as 

(
  select makhdms,min(ngaychungtu) as ngaychungtu,sum(doanhsochuavat) as doanhsochuavat from `staging.f_sales` where kieudonhang ='IN' group by 1
)

,

cum as
(
  select 
    distinct statedescr,
    case when districtdescr = 'Huyện Đảo Cồn Cỏ' then 'Huyện Cồn Cỏ' 
         when districtdescr in ('Quận 2','Quận 9') then 'Thành phố Thủ Đức'
         else districtdescr end as districtdescr ,
    wardname,
    cluster_state
  from `spatial-vision-343005.staging.d_leadtimekpi`
)
,

cum1 as
(
  select 
    distinct statedescr,
    case when districtdescr = 'Huyện Đảo Cồn Cỏ' then 'Huyện Cồn Cỏ' 
         when districtdescr in ('Quận 2','Quận 9') then 'Thành phố Thủ Đức'
         else districtdescr end as districtdescr,
    cluster_state
  from `spatial-vision-343005.staging.d_leadtimekpi`
  where districtdescr != 'Huyện Bình Chánh'
)
,

tuyenban as 
(
    WITH
    data_tuyen AS (
    SELECT
        a.custid,
        a.slsperid,
        a.crtd_datetime,
        CASE
        WHEN routetype IN ('B', 'D') THEN 1
        ELSE 2
    END
        AS routetype,
    FROM
        `spatial-vision-343005.staging.sync_dms_srm` a 
         LEFT JOIN `staging.d_master_khachhang` c on a.custid =c.custid
       where c.channel in ('TP','PCL')
       and
              delroutedet IS FALSE 
              and routetype IN ('B', 'D') 
              )

    SELECT
    a.*,b.tencvbh, 
    Case when a.slsperid  in (
                'MR1682KN',
                'MR2504',
                'MR1232',
                'MR0806',
                'MR2608',
                'MR2111',
                'MR1682',
                'MR2504KN',
                'MR1232KN',
                'MR0806KN',
                'MR2608KN',
                'MR2111KN',
                'MR2993',
                'MR2993KN',
                'MR3038',
                'MR3038KN',
                'MR2608KN',
                'MR2948',
                'MR2948KN',
                'MR2608'
            ) then 'CX' else b.tenquanlytt end as tenquanlytt,b.tenquanlyvung,

    FROM
    data_tuyen a 
    LEFT JOIN `staging.d_users` b on a.slsperid =b.manv
    where tenquanlyvung not in ('Lương Trịnh Thắng') or tenquanlyvung is null
    QUALIFY
    ROW_NUMBER() OVER (PARTITION BY custid ORDER BY routetype ASC, crtd_datetime DESC ) = 1 
),

 tuyen_cvbh_hd as 
(
SELECT a.contractid, b.custid, b.gentodate,a.slsperid,c.supid as macrm,c.tenquanlytt
 FROM `spatial-vision-343005.staging.d_oricontractdet` a 
INNER JOIN `spatial-vision-343005.staging.d_oricontract` b on a.contractid = b.contractid
LEFT JOIN `staging.d_users` c on a.slsperid = c.manv
where c.tenquanlyvung ='Nguyễn Thọ Chiến' and left(invtid,1) <>'V'
qualify row_number() over (partition by custid order by genlupd_datetime desc) = 1
)
,

result as 
(
  select
  current_datetime('+7') as update_at,
  e.ngaytao as ngaytao_kh,
  e.makh,
  e.source as source_total_kh,
  e.thoihanhieulucgdpgpp,
  e.taxregnbr,
  e.is_co_gpp,
  e.is_ko_gpp,
  e.is_co_mst,
  e.is_ko_mst,
  e.gpp_hethan,
  e.gpp_conhan,
  
  -- Các cột của bảng caresoft cũ (a), nay set null vì bảng đã bị comment
  CAST(NULL AS DATE) as ngaytao,
  CAST(NULL AS STRING) as makhOA,
  CAST(NULL AS TIMESTAMP) as inserted_at,
  
  e.makh as kh_chua_OA,
  case when b.makhEO is not null then e.makh else null end as kh_chuaOA_OE,
  case when b.makhEO is null then e.makh else null end as kh_chuaOA_chuaOE,
  case when b.makhEO is not null and c.makhDMS is not null then e.makh else null end as kh_chuaOA_OE_DMS,
  case when b.makhEO is not null and c.makhDMS is null then e.makh else null end as kh_chuaOA_OE_chuaDMS,

  case when b.makhEO is null and c.makhDMS is null then e.makh else null end as kh_chuaOA_chuaOE_chuaDMS,
  case when b.makhEO is null and c.makhDMS is not null then e.makh else null end as kh_chuaOA_chuaOE_DMS,

  CAST(NULL AS STRING) as source0A,
  CAST(NULL AS STRING) as sdtOA,
  b.ngayactive,
  b.makhEO,
  b.sdtEO,
  b.follow_phone,
 
  CAST(NULL AS STRING) as kh_OA_OE,
  CAST(NULL AS STRING) as kh_OA_chuaOE,
  CAST(NULL AS STRING) as kh_OA_OE_DMS,
  CAST(NULL AS STRING) as kh_OA_OE_chuaDMS,

  CAST(NULL AS STRING) as kh_OA_chuaOE_chuaDMS,
  CAST(NULL AS STRING) as kh_OA_chuaOE_DMS,

  b.source as sourceEO,
  c.ngaytaodonDMS,
  c.makhDMS,
  case when c.makhDMS is not null then e.makh else null end as KH_chua_DMS,
  c.source as sourceDMS,
  d.custname,
  d.custidinvoice,
  d.custnameinvoice,
  d.branchid,
  d.legaldate,
  d.channel,
  d.shoptype,
  d.statedescr,
  case when d.districtdescr in ('Quận 2','Quận 9') then 'Thành phố Thủ Đức' else d.districtdescr end as districtdescr,
  d.wardname,
  d.territorydescr,
  d.hcoid,
  d.hcotypeid,
  d.classid,
  d.phone as sdtdms,
  d.terms,
  d.paymentsform,
  d.active,
  d.crtd_user,
  d.market,
  ifnull(d.OriCustID,'Chưa có') as so_giay_gpp,
  ifnull(d.GeneralCustID,'Chưa có') as so_giay_du_dkkd,
  ifnull(d.VendorID,'Chưa có') as ds_dong_thue_khoan,
  IfNULL(d.EstablishDate,'Chưa có') as ngay_cap_du_dkkd,
  ifnull(d.BillMarket,'Chưa có') as ghi_chu_dieu_chinh,
  ifnull(d.legalname,'Chưa có') as ten_tren_giay_gdp,
  d.newaddress as addr1,
  d.refcustid,
  d.pubcustname,
  d.pubcustid,
  case when m.firstname is null then d.crtd_user else m.firstname end as nguoitao,
  -- g.ngaychungtu,
  h.phanloaiub,
  h.chinhanh as chinhanh_dialy,
  -- g.doanhsochuavat,
  case when n.cluster_state is null then i.cluster_state else n.cluster_state end as cluster_state,
  
  case when d.shoptype in ('PMC','SI23','CTD') THEN 'TP'
       WHEN d.shoptype in ('INS','CLC','PCL') THEN 'HCP'
       WHEN d.shoptype in ('NTC','CCD','CVS') THEN 'MT' 
       ELSE d.channel end as kenh,
  
  -- case when g.tencvbh in ( 'Phạm Thị Quỳnh Ảo','User Ảo INS','User Ảo OCM') then 0 else g.doanhsochuavat end as doanhsochuavat,

  DATETIME_ADD(DATETIME (legaldate), INTERVAL 180 day) as legaldate_cong90,
  DATETIME_ADD(DATETIME (current_date("+7")), INTERVAL 180 day) as today_cong90,

  DATETIME_ADD(DATETIME (current_date("+7")), INTERVAL -180 day) as today_tru90,

  case when gpp_conhan is not null and cast(legaldate as date) <= DATETIME_ADD(DATETIME (current_date("+7")), INTERVAL 180 day) then 'gpp_conhan_duoi90' 
       when gpp_conhan is not null and cast(legaldate as date) > DATETIME_ADD(DATETIME (current_date("+7")), INTERVAL 180 day) then 'gpp_conhan_tren90' 
       else null end AS gpp_conhan_90,
  case when gpp_hethan is not null and cast(legaldate as date) <= DATETIME_ADD(DATETIME (current_date("+7")), INTERVAL -180 day) then 'gpp_hethan_tren90' 
       when gpp_hethan is not null and cast(legaldate as date) > DATETIME_ADD(DATETIME (current_date("+7")), INTERVAL -180 day) then 'gpp_hethan_duoi90' 
       else null end as gpp_hethan_90,

  l.col.ma_nvbh as ma_nvbh,

  l.col.phan_loai_mcp as phan_loai_mcp,
  Case when k.makhdms is not null then 'Y' else 'N' end as is_co_ds_2022,
  c1.doanhsochuavat,
  c1.ngaychungtu      

  from masterdata e
  --left join caresoft a on e.makh = a.makhOA
  left join ecom b on e.makh =  b.makhEO
  left join pda_so c on e.makh = c.makhDMS
  left join data_sales c1 on e.makh = c1.makhdms
  left join `staging.d_master_khachhang` d on e.makh = d.custid
  left join (select distinct stateid,chinhanh,phanloaiub from `spatial-vision-343005.staging.d_tinh`) h on e.statecode = h.stateid
  left join `spatial-vision-343005.staging.d_dms_master_users` m on d.crtd_user = m.username
  left join cum n on 
                concat (d.statedescr,(case when d.districtdescr in ('Quận 2','Quận 9') then 'Thành phố Thủ Đức' else d.districtdescr end),d.wardname) 
              = concat(n.statedescr,n.districtdescr,n.wardname)
  left join cum1 i on 
                concat (d.statedescr,(case when d.districtdescr in ('Quận 2','Quận 9') then 'Thành phố Thủ Đức' else d.districtdescr end)) 
              = concat(i.statedescr,i.districtdescr)
  LEFT JOIN `warehouse.f_mapping_crs` l on l.custid = e.makh 

  left join bang_doanhso_2022 k on k.makhdms = e.makh                                                               
  WHERE d.channel not in ('OTH_LAB','NB') and e.makh not like 'DS%' and d.market != '08'

),
result_1 as (
select a.*,
 Case when a.ma_nvbh ='CX' then 'CX' else b.tencvbh end as tencvbh,
 b.tenquanlytt as tenquanlytt_bh,
--  b.role,  
  case when gpp_conhan is not null and taxregnbr is not null then taxregnbr else null end as gppconhan_comst,
  case when gpp_conhan is not null and taxregnbr is not null and makhDMS is not null then makhDMS else null end as gppconhan_comst_codms,
  case when gpp_conhan is not null and taxregnbr is not null and KH_chua_DMS is not null then KH_chua_DMS else null end as gppconhan_comst_chuadms,

  case when gpp_conhan_90 = 'gpp_conhan_duoi90' and taxregnbr is not null then 'gpp_conhanduoi90_comst'
       when gpp_conhan_90 = 'gpp_conhan_duoi90' and taxregnbr is null then 'gpp_conhanduoi90_komst'
       when gpp_conhan_90 = 'gpp_conhan_tren90' and taxregnbr is not null then 'gpp_conhantren90_comst'
       when gpp_conhan_90 = 'gpp_conhan_tren90' and taxregnbr is null then 'gpp_conhantren90_komst'

       when gpp_hethan_90 = 'gpp_hethan_duoi90' and taxregnbr is not null then 'gpp_hethanduoi90_comst'
       when gpp_hethan_90 = 'gpp_hethan_duoi90' and taxregnbr is null then 'gpp_hethanduoi90_komst'
       when gpp_hethan_90 = 'gpp_hethan_tren90' and taxregnbr is not null then 'gpp_hethantren90_comst'
       when gpp_hethan_90 = 'gpp_hethan_tren90' and taxregnbr is null then 'gpp_hethantren90_komst' 
       else '' end as phanloai_gpp_mst,

  case when gpp_conhan_90 = 'gpp_conhan_duoi90' and taxregnbr is not null and makhdms is not null then 'gpp_conhanduoi90_comst_codh'
       when gpp_conhan_90 = 'gpp_conhan_duoi90' and taxregnbr is not null and makhdms is null then 'gpp_conhanduoi90_comst_kodh'
       when gpp_conhan_90 = 'gpp_conhan_duoi90' and taxregnbr is null and makhdms is not null then 'gpp_conhanduoi90_komst_codh'
       when gpp_conhan_90 = 'gpp_conhan_duoi90' and taxregnbr is null and makhdms is null then 'gpp_conhanduoi90_komst_kodh'
       when gpp_conhan_90 = 'gpp_conhan_tren90' and taxregnbr is not null and makhdms is not null then 'gpp_conhantren90_comst_codh'
       when gpp_conhan_90 = 'gpp_conhan_tren90' and taxregnbr is not null and makhdms is null then 'gpp_conhantren90_comst_kodh'
       when gpp_conhan_90 = 'gpp_conhan_tren90' and taxregnbr is null and makhdms is not null then 'gpp_conhantren90_komst_codh'
       when gpp_conhan_90 = 'gpp_conhan_tren90' and taxregnbr is null and makhdms is null then 'gpp_conhantren90_komst_kodh'

       when gpp_hethan_90 = 'gpp_hethan_duoi90' and taxregnbr is not null and makhdms is not null then 'gpp_hethanduoi90_comst_codh'
       when gpp_hethan_90 = 'gpp_hethan_duoi90' and taxregnbr is not null and makhdms is null then 'gpp_hethanduoi90_comst_kodh'
       when gpp_hethan_90 = 'gpp_hethan_duoi90' and taxregnbr is null and makhdms is not null then 'gpp_hethanduoi90_komst_codh'
       when gpp_hethan_90 = 'gpp_hethan_duoi90' and taxregnbr is null and makhdms is null then 'gpp_hethanduoi90_komst_kodh'
       when gpp_hethan_90 = 'gpp_hethan_tren90' and taxregnbr is not null and makhdms is not null then 'gpp_hethantren90_comst_codh'
       when gpp_hethan_90 = 'gpp_hethan_tren90' and taxregnbr is not null and makhdms is null then 'gpp_hethantren90_comst_kodh'
       when gpp_hethan_90 = 'gpp_hethan_tren90' and taxregnbr is null and makhdms is not null then 'gpp_hethantren90_komst_codh'
       when gpp_hethan_90 = 'gpp_hethan_tren90' and taxregnbr is null and makhdms is null then 'gpp_hethantren90_komst_kodh'
       else '' end as phanloai_gpp_mst_dh,

  case when terms in ('Thu tiền ngay không có VP PN','Thu tiền ngay có VP PN') then 'Thanh toán ngay'
       when terms in ('Gối 1 Đơn Hàng (trong 30 ngày)') then 'Nợ gối đầu'
       when terms in ('Thời hạn thanh toán 10 ngày','7 Ngày','15 Ngày') then 'Có nợ dưới 30 ngày'
       when terms in ('90 Ngày','Thời hạn thanh toán 180 ngày','Thời hạn thanh toán 120 ngày') then 'Nợ từ 90 trở lên' 
       else 'Nợ từ 30 đến dưới 90' end as thoihanno

from result  a
LEFT JOIN `staging.d_users` b on a.ma_nvbh = b.manv

)

select * from result_1;