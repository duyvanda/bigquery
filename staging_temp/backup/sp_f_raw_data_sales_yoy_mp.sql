CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_raw_data_sales_yoy_mp()
BEGIN 
 
 TRUNCATE TABLE `staging_temp.f_raw_data_sales_yoy_mp_temp`;


 INSERT INTO `staging_temp.f_raw_data_sales_yoy_mp_temp`

(   

-- Create or replace table staging_temp.f_raw_data_sales_yoy_mp_temp
-- partition by date(ngaychungtu)
-- cluster by makhdms,makenhkh,makenhphu,hcoid
-- as
with 

data_pda as (
select ordernbr,custid,branchid,

 'TMDT_001' as  crtd_user from `spatial-vision-343005.staging.sync_dms_pda_so` 
WHERE (crtd_user ='TMDT_001' or slsperid ='TMDT_001')  and crtd_datetime >='2022-06-01' --or slsperid ='TMDT_001'
),

data as (
  SELECT
    a.macongtycn,
    a.congtycn,
    ifnull(a.makhcu,a.makhdms) as makhcu,
    a.makenhkh as makenhkh_cu,
    a.makenhphu as makenhphu_cu,
    a.mahco as mahco_cu,
    a.maphanloaihco as maphanloaihco_cu,
    a.makhdms,
    ifnull(d.custname,a.tenkhachhang) as tenkhachhang,
    ifnull(d.statedescr,a.tentinhkh) as statedescr,
    d.shortterritorydescr as territorydescr,
    Case when ifnull(d.districtdescr,a.tenquanhuyen) in ('Quận 2','Quận 9') then 'Thành phố Thủ Đức' else ifnull(d.districtdescr,a.tenquanhuyen) end as districtdescr,
    d.wardname as wardname,
    a.sodondathang,
    a.ngaychungtu,
    date_trunc(ngaychungtu,month) as thang,
    a.masanpham,
    a.tensanphamviettat,
    a.soluong,
    a.doanhsocovat,
    a.doanhsochuavat,
    Case when a3.ordernbr is not null then 'TMDT_001' else   a.manv end as manv,
    Case 
          when ifnull(d.channel,a.makenhkh) ='OTC' and ifnull(d.shoptype,a.makenhphu) in ('NT','DCYK','SI','SI23') then 'TP'
          when ifnull(d.channel,a.makenhkh) ='OTC' and ifnull(d.shoptype,a.makenhphu) in ('PK') then 'PCL'
          when ifnull(d.channel,a.makenhkh) ='OTC' and ifnull(d.shoptype,a.makenhphu) in ('CHUOI') then 'MT' 
          when ifnull(d.channel,a.makenhkh) ='OTC' and ifnull(d.shoptype,a.makenhphu) in ('DLPP') then 'TP' 
          when makhdms ='MC014' and ifnull(d.channel,a.makenhkh) ='DLPP' then 'TP'
          when makhdms ='N06202285' and ifnull(d.channel,a.makenhkh) ='DLPP' then 'TP'
          when (d.active <>'Active'or d.active is null) and ifnull(d.channel,a.makenhkh) ='DLPP' then 'TP'
        else ifnull(d.channel,a.makenhkh) 
    end as makenhkh,

    Case 
        when ifnull(d.shoptype,a.makenhphu) ='PK' and d.channel ='OTC' then 'PCL' 
        when ifnull(d.shoptype,a.makenhphu) in('DCYK','NT') and d.channel ='OTC' then 'PMC'
        when ifnull(d.channel,a.makenhkh) ='OTC' and ifnull(d.shoptype,a.makenhphu) in ('CHUOI') and d.hcoid='MT' then 'CCD'
        when makhdms ='MC014' and ifnull(d.channel,a.makenhkh) ='DLPP' then 'PMC'
        when makhdms ='N06202285' and ifnull(d.channel,a.makenhkh) ='DLPP' then 'CTD'
        when (d.active <>'Active'or d.active is null) and ifnull(d.channel,a.makenhkh) ='DLPP' and  ifnull(d.shoptype,a.makenhphu) like '%DLPP%' then 'CTD'
        when ifnull(d.channel,a.makenhkh) ='OTC' and ifnull(d.shoptype,a.makenhphu) in ('DLPP') then 'CTD' 
        when ifnull(d.shoptype,a.makenhphu) ='SI23' then 'SI'
    else ifnull(d.shoptype,a.makenhphu) end   as makenhphu,

    Case when   makhdms ='MC014' and ifnull(d.channel,a.makenhkh) ='DLPP' then 'DLPP3'
            when makhdms ='N06202285' and ifnull(d.channel,a.makenhkh) ='DLPP' then 'CTD'
            when (d.active <>'Active'or d.active is null) and ifnull(d.channel,a.makenhkh) ='DLPP' and  ifnull(d.shoptype,a.makenhphu) like '%DLPP%' then 'CTD'
                        when ifnull(d.channel,a.makenhkh) ='OTC' and ifnull(d.shoptype,a.makenhphu) in ('DLPP') then 'CTD' 

    else ifnull(d.hcoid,a.mahco) end  as hcoid,

   Case when makhdms ='MC014' and ifnull(d.channel,a.makenhkh) ='DLPP' then 'NT'
            when makhdms ='N06202285' and ifnull(d.channel,a.makenhkh) ='DLPP' then 'CTD'
            when (d.active <>'Active'or d.active is null) and ifnull(d.channel,a.makenhkh) ='DLPP' and  ifnull(d.shoptype,a.makenhphu) like '%DLPP%' then 'CTD'
            when ifnull(d.channel,a.makenhkh) ='OTC' and ifnull(d.shoptype,a.makenhphu) in ('DLPP') then 'CTD' 

            else ifnull(d.hcotypeid,a.maphanloaihco) end as hcotypeid,

    ifnull(d.classid,maphanhanghco) as classid,
    d.pubcustid,
    d.pubcustname,
    Case when a3.ordernbr is not null then 'Ecom' else 'Merap' end as is_ecom,
    hoadon,
    solo,
    a.mahd,
    a.manvgh,
    a.lineref,
    a.dongiachuavat,
    a.dongiacovat

  FROM `spatial-vision-343005.staging.f_sales` a
  LEFT JOIN data_pda a3 on a3.ordernbr =a.sodondathang and a3.branchid = a.macongtycn
  LEFT JOIN `staging.d_master_khachhang` d on d.custid = a.makhdms
  -- LEFT JOIN `staging.d_master_khachhang2022` e on e.custid = a.makhdms
  WHERE  ( 
    ngaychungtu <'2023-01-01' and
  LEFT(a.masanpham,1) != 'V' 
      -- AND (a.manv NOT IN ( 'GH001','QUYNHPTA','MA001','MA002','MA003') )

      -- AND makenhkh not in ( 'NB','OTH_LAB')
  )
  or manv is null
),

result as (

select a.*except(manv),
  a.manv as ori_manv,
    Case 
        when l.col.phan_loai_mcp = 'Rural' 
        or a.manv = 'TMDT_001'
        or a.manv in ("MR1682KN","MR2504","MR1232","MR0806","MR2608","MR2111","MR1682","MR2504KN","MR1232KN","MR0806KN","MR2608KN",
        "MR2111KN","MR2993","MR2993KN","MR3038","MR3038KN","MR2608KN","MR2948","MR2948KN","MR2608")
        or (a.makenhphu not in ('SI23', 'SI', 'CTD') and b.tenquanlytt = 'Nguyễn Văn Tiến' and ngaychungtu < '2024-01-01') 
        then l.col.ma_nvbh
      else a.manv
      end as manv, 
  Case  
    when a.makenhkh in ('INS','CLC','PCL') then 'MR0081'
    when a.makenhkh ='TP'  then 'MR0485' 
       -- Kênh MT chị Hương Sa
    when a.makenhkh ='MT' then 'MR2685'
  else null end as ma_ncxm,
  Case 
        when l.col.phan_loai_mcp = 'Rural'then 'Rural'
        when a.manv = 'TMDT_001' and l.col.phan_loai_mcp = 'CRS (Trong MCP)' then 'Trong MCP (Ecom)'
        when a.manv = 'TMDT_001' and l.col.phan_loai_mcp = 'CRS (Ngoài MCP)' then 'Ngoài MCP (Ecom)'
        -- when l.col.phan_loai_mcp = 'CRS (Ngoài MCP)' and a.manv in ("MR1682KN","MR2504","MR1232","MR0806","MR2608","MR2111","MR1682","MR2504KN","MR1232KN","MR0806KN","MR2608KN",
        -- "MR2111KN","MR2993","MR2993KN","MR3038","MR3038KN","MR2608KN","MR2948","MR2948KN","MR2608") then 'Ngoài MCP (CX)'
        when l.col.phan_loai_mcp = 'CRS (Ngoài MCP)' then 'Ngoài MCP'
    else 'Trong MCP'
  end as phanloai,

from data a 
LEFT JOIN `warehouse.f_mapping_crs` l on a.makhdms =l.custid
LEFT JOIN staging.d_users b on b.manv = a.manv


),
result1 as (
select 

extract (year from ngaychungtu) as year,
Case when extract (month from ngaychungtu) <=6 then  'C1.' ||  extract (year from ngaychungtu) else 'C2.' ||  extract (year from ngaychungtu) end as cycle,

extract (month from ngaychungtu) as thang_number,

Case when makenhkh in ('INS','CLC','PCL') then 'HCP' else makenhkh end as phong_kh,
a.*except(phanloai,mahd,manvgh,lineref,manv,ma_ncxm,dongiacovat,dongiachuavat),
Case
            when phanloai = 'Rural' then 'Rural'
            when phanloai = 'Ngoài MCP (Ecom)' then 'Ngoài MCP'
            when phanloai = 'Trong MCP (Ecom)' then 'Trong MCP'
            when phanloai = 'Trong MCP' then 'Trong MCP'
            when phanloai = 'Ngoài MCP' then 'Ngoài MCP'
            when phanloai = 'Ngoài MCP (CX)' then 'Ngoài MCP'
            else 'Khác'
        end as phanloai_tuyen,
a.phanloai  as phanloai_tuyen_chitiet,
a.manv,
Case when a.manv ='CX' then 'CX' else c.tencvbh end as tencvbh,
Case when a.manv ='CX' then 'MR1682' else c.supid end as ma_crm,
Case when a.manv ='CX' then 'Đinh Thị Ngọc Mẫn' else c.tenquanlytt end as tenquanlytt,
Case when a.manv ='CX' then 'MR0485' else c.asm end as scrm,
Case when a.manv ='CX' then 'Nguyễn Hoàng Viển(KN)' else c.tenquanlykhuvuc end as tenquanlykhuvuc,
a.ma_ncxm,
d.tencvbh  as tenquanlyvung,
-- e.spcl2023tp_mt,
-- e.spcl2023pcl_clc_ins,
-- e.brand2023,
-- e.brand,
ifnull(e.spcl2023tp_mt,e1.spcl2023tp_mt)  as spcl2023tp_mt,
ifnull(e.spcl2023pcl_clc_ins,e1.spcl2023pcl_clc_ins) as spcl2023pcl_clc_ins,
ifnull(e.brand2023,e1.brand2023) as brand2023,
ifnull(e.brand,e1.brand) as brand,
a.mahd,
a.manvgh,
a.lineref,
a.dongiachuavat,
a.dongiacovat
 from result a
 LEFT JOIN `staging.d_users` c on c.manv =a.manv
LEFT JOIN `staging.d_users` d on d.manv =a.ma_ncxm
LEFT JOIN `staging.d_nhom_sp_trading` e on e.masanpham = a.masanpham
 LEFT JOIN `staging.d_nhom_sp_trading_bytime` e1 on e1.masanpham = a.masanpham and extract(year from ngaychungtu) < 2025 and e1.nam =2024
LEFT JOIN (select distinct manv from `staging.d_calendar`) k1 on k1.manv =a.manv

),

sales_lhq_bytime as (
with 
data_pda as (
select ordernbr,custid,branchid,

 'TMDT_001' as  crtd_user from `spatial-vision-343005.staging.sync_dms_pda_so` 
WHERE (crtd_user ='TMDT_001' or slsperid ='TMDT_001')  and crtd_datetime >='2022-06-01' --or slsperid ='TMDT_001'
),


data as(
  SELECT
    a.macongtycn,
    d.branchname as congtycn,
    a.maphanloaihco,
    ifnull(a.makhcu,a.makhdms) as makhcu,
    a.makhdms,
    d.custname as tenkhachhang,
    d.statedescr as tentinhkh,
    d.statedescr as statedescr,
    d.territorydescr as territorydescr,
    Case when d.districtdescr in ('Quận 2','Quận 9') then 'Thành phố Thủ Đức' else d.districtdescr end as districtdescr,
    d.wardname,
    d.shortterritorydescr as khuvucviettat,
    a.sodondathang,
    a.ngaychungtu,
    EXTRACT(month
    FROM
    a.ngaychungtu) AS month,
    a.thang,
    a.masanpham,
    a.tensanphamnb,
    a.tensanphamviettat,
    a.soluong,
    a.dongiachuavat,
    a.dongiacovat,
    a.doanhsocovat,
    a.doanhsochuavat,
    Case when upper(ifnull(a3.crtd_user,a.manv)) like '%KN' then LEFT( ifnull(a3.crtd_user,a.manv),6) else ifnull(a3.crtd_user,a.manv) end  as manv,
    Case 
        when a.masanpham ='EH092' and ngaychungtu >='2024-04-01' and a.makenhkh ='INS' then 'CLC'
        when  a.makhdms ='M1017123' then 'TP' ----- Thời điểm post đơn KH vẫn là OTC 
        WHEN a.makenhkh = 'DLPP' and ngaychungtu <'2023-01-01' THEN 'OTC' 
        when a.makenhkh ='DLPP' then 'TP'
           
    else a.makenhkh end as makenhkh,
    
    a.tenkenhkh,
    Case 
        when a.masanpham ='EH092' and ngaychungtu >='2024-04-01' and a.makenhphu ='INS1' then 'CLC1'
        when a.masanpham ='EH092' and ngaychungtu >='2024-04-01' and a.makenhphu ='INS2' then 'CLC2'
        when a.masanpham ='EH092' and ngaychungtu >='2024-04-01' and a.makenhphu ='INS3' then 'CLC3'
        when a.makhdms ='M1017123' then 'PMC' else a.makenhphu 
    
    end as makenhphu,
    a.tenkenhphu,
    a.inserted_at as updated_at,
    0 as kh_total,
    Case 
    when a.manv ='MR0868' and a.masanpham in ('EH115','EBS10','OH082','MDR125KC') and ( a.makenhphu in('SI') or a.makenhkh in ('MT') ) then doanhsochuavat
    when a.masanpham in ('EH115','EBS10','OH082','MDR125KC') and  a.makenhkh in ('TP','PCL') then doanhsochuavat
    when a.masanpham in ('EH092','OH082','EH115','EH102','OH076') 
    and makenhkh in ('OTC','DLPP')
    and ngaychungtu >='2022-04-01' and ngaychungtu <'2022-07-01' then doanhsochuavat
           when a.masanpham in ('EH115','OH080','OH082') and ngaychungtu >='2022-01-01' and ngaychungtu <'2022-04-01' 
           and makenhkh in ('OTC','DLPP') then doanhsochuavat
         when a.masanpham in ('EH092','OH082','OH083','EH102','EH115') and ngaychungtu >='2022-07-01' 
         and makenhkh in ('OTC','DLPP') then doanhsochuavat  
     else 0 end  as thuchien_spmoi,
    0 as  kh_spmoi,
    Case when a.makenhphu in ('INS2','INS3','CLC2','CLC3') then doanhsochuavat else 0 end as thuchien_yttn,
    0 as  kh_yttn,
    Case when  a.masanpham  in ('EH072','EH105','OH016','OH032','OH047','OH057','OH058','OH071','OH079','OH081') and ngaychungtu <'2023-01-01' then  'PHANAM'
    else 'MERAP' end as is_phanam,
    'f_sales' as datatype1,
    Case when a3.ordernbr is not null then 'Ecom' else 'Merap' end as is_ecom,
  
  a.manvghreal,
  a.pda_crtd_user,
  a.pda_slsperid,
  cast(0 as float64)  as slpp_ebysta,
  cast(0 as float64)  as slpp_medoral,
  0 as kpi_ds_pcl,

    -----18/7 chị Linh update những hàng tặng từ các chương trình sẽ không tính vào phân phối
  Case when masanpham ='EH115' and a.makenhkh='TP' and doanhsochuavat > 0 then ifnull(makhcu,makhdms) else null end as th_slpp_ebysta,
    Case when masanpham in('EH092','OH082','OH084','EH102','EH121') and a.makenhkh='TP' and doanhsochuavat >0  and ngaychungtu <'2023-07-01' then ifnull(makhcu,makhdms) 
         when masanpham in('OH074','OH075','OH077','OH078','T302101008','T302101007','T302101006','T302101005')and a.makenhkh='TP' and doanhsochuavat >0  and ngaychungtu >='2023-07-01' then ifnull(makhcu,makhdms) else null --tháng 7 đổi medoral qua shema lá đôi
    end as th_slpp_medoral,
    
    Case when makenhkh ='PCL' then doanhsochuavat else 0 end as th_ds_pcl,
  Case  when makenhphu in('ECOM','FMCG') and makenhkh='MT' and ngaychungtu >='2023-07-01' then doanhsochuavat --- Từ tháng 7 cập nhật thêm doanh số ECOM để tính lương
    when (makhdms ='MC017' or makenhphu in('CCD','FMCG') ) and makenhkh='MT' then doanhsochuavat
   else 0 end as th_ds_fmcg,
  0 as kpi_ds_fmcg,
  kieudonhang,
  a.mahco,
  a.maphanhanghco,
  a.mahd,
  a.hoadon,
  a.solo,
  a.manvgh,
  a.lineref,


  FROM `spatial-vision-343005.staging.f_sales` a
  LEFT JOIN data_pda a3 on a3.ordernbr =a.sodondathang and a3.branchid = a.macongtycn
  LEFT JOIN `staging.d_master_khachhang` d on d.custid = a.makhdms
  WHERE a.ngaychungtu >= '2023-01-01' 
  AND LEFT(a.masanpham,1) != 'V' 

) ,

result0 as (
select  
    a.macongtycn,
    a.congtycn,
    a.maphanloaihco,
    a.makhcu,
    a.makhdms,
    a.tenkhachhang,
    a.tentinhkh,
    a.statedescr,
    a.territorydescr,
    a.districtdescr,
    a.wardname,
    a.khuvucviettat,
    Case  when a.territorydescr='Miền Đông 1' then'MN'
          when a.territorydescr='Bắc Trung Bộ' then'MB'
          when a.territorydescr='Nam Trung Bộ' then'MN'
          when a.territorydescr='Đông Nam 2' then'MN'
          when a.territorydescr='Hà Nội 2' then'MB'
          when a.territorydescr='Hồ Chí Minh 2' then'MN'
          when a.territorydescr='Đông Bắc 1' then'MB'
          when a.territorydescr='Mê Kông 2' then'MN'
          when a.territorydescr='Mê Kông 1' then'MN'
          when a.territorydescr='Tây Bắc HN' then'MB'
          when a.territorydescr='Hà Nội 1' then'MB'
          when a.territorydescr='Miền Đông 2' then'MN'
          when a.territorydescr='Đông Bắc 2' then'MB'
          when a.territorydescr='Đông Nam 1' then'MN'
          when a.territorydescr='Hồ Chí Minh 1' then'MN'
    else null end as vungmien,
    a.sodondathang,
    a.ngaychungtu,
    a.month,
    a.thang,
    a.masanpham,
    a.tensanphamnb,
    a.tensanphamviettat,
    a.soluong,
    a.dongiachuavat,
    a.dongiacovat,
    a.doanhsocovat,
    a.doanhsochuavat,
     Case 
        when l.col.phan_loai_mcp = 'Rural' 
        or a.manv = 'TMDT_001'
        or a.manv in ("MR1682KN","MR2504","MR1232","MR0806","MR2608","MR2111","MR1682","MR2504KN","MR1232KN","MR0806KN","MR2608KN",
        "MR2111KN","MR2993","MR2993KN","MR3038","MR3038KN","MR2608KN","MR2948","MR2948KN","MR2608")
        or (a.makenhphu not in ('SI23', 'SI', 'CTD') and b.tenquanlytt = 'Nguyễn Văn Tiến' and ngaychungtu < '2024-01-01') 
        then l.col.ma_nvbh
      else a.manv
      end as manv, 
      Case 
        when l.col.phan_loai_mcp = 'Rural'then 'Rural'
        when a.manv = 'TMDT_001' and l.col.phan_loai_mcp = 'CRS (Trong MCP)' then 'Trong MCP (Ecom)'
        when a.manv = 'TMDT_001' and l.col.phan_loai_mcp = 'CRS (Ngoài MCP)' then 'Ngoài MCP (Ecom)'
        -- when l.col.phan_loai_mcp = 'CRS (Ngoài MCP)' and a.manv in ("MR1682KN","MR2504","MR1232","MR0806","MR2608","MR2111","MR1682","MR2504KN","MR1232KN","MR0806KN","MR2608KN",
        -- "MR2111KN","MR2993","MR2993KN","MR3038","MR3038KN","MR2608KN","MR2948","MR2948KN","MR2608") then 'Ngoài MCP (CX)'
        when l.col.phan_loai_mcp = 'CRS (Ngoài MCP)' then 'Ngoài MCP'
      else 'Trong MCP'
      end as phanloai,
    null as manv_mds,
    a.manv as manv_original,
    a.manvghreal,
    a.pda_crtd_user,
    a.pda_slsperid,
    a.makenhkh,
    a.tenkenhkh,
    a.makenhphu,
    a.tenkenhphu,
    a.updated_at,
    a.is_ecom,
    a.hoadon,
    a.solo,
    a.kh_total,
    a.thuchien_spmoi,
    a.kh_spmoi,
    a.thuchien_yttn,
    a.kh_yttn,
    Case when a.makenhkh ='INS' then 'TENDER'
        --  when a1.segment is not null then a1.segment
    else 'OTHERS'end as datatype,
    a1.brand as team,
    a.datatype1,
    slpp_ebysta,
    slpp_medoral,
    kpi_ds_pcl,
  th_slpp_ebysta,
  th_slpp_medoral, 
  th_ds_pcl,
  th_ds_fmcg,
  kpi_ds_fmcg,
  kieudonhang,
  mahco,
  maphanhanghco,
  mahd,
  manvgh,
  a.lineref

 from data a  
 LEFT JOIN `staging.d_nhom_sp_trading` a1 on a1.masanpham =a.masanpham
 LEFT JOIN `warehouse.f_mapping_crs_bytime` l on l.custid = a.makhdms and date_trunc(ngaychungtu,month) = l.thang
 LEFT JOIN staging.d_users_bytime b on b.manv = a.manv and date(a.thang) =date(b.thang)

)
,

result0_1 as 
(
select 
a.*except(phanloai),    
Case 
            when phanloai = 'Rural' then 'Rural'
            when phanloai = 'Ngoài MCP (Ecom)' then 'Ngoài MCP'
            when phanloai = 'Trong MCP (Ecom)' then 'Trong MCP'
            when phanloai = 'Trong MCP' then 'Trong MCP'
            when phanloai = 'Ngoài MCP' then 'Ngoài MCP'
            when phanloai = 'Ngoài MCP (CX)' then 'Ngoài MCP'
            else 'Khác'
end as crs_tuyenbanhang_trongmcp,
a.phanloai

 from result0 a 
 LEFT JOIN (select distinct manv from `staging.d_calendar`) k1 on k1.manv =a.manv
 LEFT JOIN `staging.d_users_bytime` b on a.manv =b.manv and date(a.thang) = date(b.thang)

),

result1 as (
select 
a.*,
    Case 
         when is_ecom ='Merap' and ngaychungtu >='2022-01-01' then 'Merap'
         when is_ecom ='Ecom' and ngaychungtu >='2022-01-01' then 'Ecom'
         
         else null end as is_mrtd,

    Case when a.manv='CX' then 'MR1682' else b.supid end as crm,

    Case when makenhkh ='MT' then 'MR2685' else b.asm end as scrm,
    
    Case when b.tenquanlytt ='Lê Thị Hương Sa' then b.supid else Left(b.rsmid,6) end as ncxm,
    
    Case when a.manv ='CX' then 'CX' else b.tencvbh end as tencvbh,

    Case when a.manv ='CX' then 'Đinh Thị Ngọc Mẫn' else b.tenquanlytt end as tenquanlytt,
    Case when makenhkh ='MT' then 'Lê Thị Hương Sa' else b.tenquanlykhuvuc end as tenquanlykhuvuc,
    Case
        when b.tenquanlytt ='Lê Thị Hương Sa' then  'Lê Thị Hương Sa'
        when a.manv ='CX' then 'Nguyễn Thị Ngọc Diệp' else ifnull(b.tenquanlyvung,"Chưa xác định") end as tenquanlyvung,

sum(doanhsochuavat)over(partition by a.thang) as ds_sp_thang,
k.firstname as ten_nguoi_taodon,
k1.firstname as tencvbh_header,
k2.firstname as tencvbh_ori,
0 as doanhso_gh_crs
from result0_1  a
LEFT JOIN `staging.d_users_bytime` b on b.manv =  a.manv and date(a.thang) =date(b.thang)
LEFT JOIN `staging.d_dms_master_users` k on k.username =a.pda_crtd_user
LEFT JOIN `staging.d_dms_master_users` k1 on k1.username =a.pda_slsperid
LEFT JOIN `staging.d_dms_master_users` k2 on k2.username =  a.manv_original

)

select * from result1 
),


mapping_data_sales_t4_2023 as (
select 
extract (year from ngaychungtu) as year,

Case when extract (month from ngaychungtu) <=6 then  'C1.' ||  extract (year from ngaychungtu)
  else 'C2.' ||  extract (year from ngaychungtu) end as cycle,

extract (month from ngaychungtu) as thang_number,
Case when c.channel in ('INS','CLC','PCL') then 'HCP'
      when c.channel in('TP') then 'TP'
      when c.channel ='MT' then 'MT'
      else null end as phong_kh,

a.macongtycn,
a.congtycn,
a.makhcu,
a.makenhkh as makenhkh_cu,
a.makenhphu as makenhphu_cu,
a.mahco as mahco_cu,
a.maphanloaihco as maphanloaihco_cu,
a.makhdms,
c.custname as tenkhachhang,
a.tentinhkh,
ifnull(c.shortterritorydescr,a.khuvucviettat)  as khuvucviettat,
a.districtdescr,
a.wardname,
a.sodondathang,
a.ngaychungtu,
date_trunc(ngaychungtu, month) as thang,
a.masanpham,
a.tensanphamviettat,
a.soluong,
a.doanhsocovat,
a.doanhsochuavat,
Case when a.masanpham ='EH092' and ngaychungtu >='2024-04-01' and ifnull(c.channel,a.makenhkh) ='INS' then 'CLC' else c.channel end as makenhkh,

Case 
  when a.masanpham ='EH092' and ngaychungtu >='2024-04-01' and ifnull(c.shoptype,a.makenhphu) ='INS1' then 'CLC1' 
  when a.masanpham ='EH092' and ngaychungtu >='2024-04-01' and ifnull(c.shoptype,a.makenhphu) ='INS2' then 'CLC2' 
  when a.masanpham ='EH092' and ngaychungtu >='2024-04-01' and ifnull(c.shoptype,a.makenhphu) ='INS3' then 'CLC3' 
  when c.shoptype ='SI23' then 'SI' 
else c.shoptype end as makenhphu,
c.hcoid as ma_hco,
c.hcotypeid as phanloai_hco,
c.classid as phanhang_hco,
c.pubcustid,
c.pubcustname, --hco_me
a.is_ecom,
a.hoadon,
a.solo,
a.manv_original,
a.crs_tuyenbanhang_trongmcp as phanloai_tuyen,
a.phanloai as phanloai_tuyen_chitiet,
a.manv,
a.tencvbh,
a.crm,
a.tenquanlytt,
Case when a.crm ='MR1682'  then 'MR0485' else a.scrm end as scrm,
Case when a.crm ='MR1682' then 'Nguyễn Hoàng Viển(KN)' else a.tenquanlykhuvuc end as tenquanlykhuvuc,
Case   
    when ifnull(c.channel,a.makenhkh) in ('INS','CLC','PCL') then 'MR0081'
    when ifnull(c.channel,a.makenhkh) ='TP'  then 'MR0485' 
    when ifnull(c.channel,a.makenhkh) ='MT' then 'MR2685'
else null end as ncxm,
Case   
    when ifnull(c.channel,a.makenhkh) in ('INS','CLC','PCL') then 'Nguyễn Thọ Chiến'
    when ifnull(c.channel,a.makenhkh) ='TP'  then 'Nguyễn Hoàng Viển' 
    when ifnull(c.channel,a.makenhkh) ='MT' then 'Lê Thị Hương Sa' 
else a.tenquanlyvung end as tenquanlyvung,
ifnull(e.spcl2023tp_mt,e1.spcl2023tp_mt)  as spcl2023tp_mt,
ifnull(e.spcl2023pcl_clc_ins,e1.spcl2023pcl_clc_ins) as spcl2023pcl_clc_ins,
ifnull(e.brand2023,e1.brand2023) as brand2023,
ifnull(e.brand,e1.brand) as brand,
-- e.spcl2023tp_mt,
-- e.spcl2023pcl_clc_ins,
-- e.brand2023,
-- e.brand,
a.mahd,
a.manvgh,
a.lineref,
a.dongiachuavat,
a.dongiacovat
 from sales_lhq_bytime a 
 LEFT JOIN `staging.d_master_khachhang` c on a.makhdms =c.custid
 LEFT JOIN `staging.d_nhom_sp_trading` e on e.masanpham = a.masanpham
  LEFT JOIN `staging.d_nhom_sp_trading_bytime` e1 on e1.masanpham = a.masanpham and extract(year from ngaychungtu) < 2025 and e1.nam =2024
),

result_union as (
select *,
 from result1 
UNION ALL
select *,
 from mapping_data_sales_t4_2023
)

select a.*,
Case when makenhkh in ('TP','MT') then spcl2023tp_mt 
      when makenhkh in ('INS','CLC','PCL') then spcl2023pcl_clc_ins  else null end as spcl2023_all,
Case when doanhsochuavat = 0 then 'Hàng KM' else 'Hàng bán' end as is_hangkm,
Case when a.statedescr in ('Bình Phước','Đắk Nông','Thành phố Hồ Chí Minh','Lâm Đồng','Long An','Tây Ninh','Tiền Giang','Bến Tre','Đồng Nai','Bà Rịa - Vũng Tàu','Bình Dương','An Giang','Cà Mau','Thành phố Cần Thơ','Đồng Tháp','Hậu Giang','Kiên Giang','Bạc Liêu','Sóc Trăng','Trà Vinh','Vĩnh Long') then 'Miền Nam'
      when a.statedescr in ('Cao Bằng','Điện Biên','Hà Giang','Hà Nam','Thành phố Hà Nội','Hải Dương','Hải Phòng','Bắc Giang','Hòa Bình','Hưng Yên','Lai Châu','Lạng Sơn','Lào Cai','Bắc Kạn','Nam Định','Ninh Bình','Phú Thọ','Quảng Ninh','Sơn La','Thái Bình','Thái Nguyên','Bắc Ninh','Tuyên Quang','Vĩnh Phúc','Yên Bái','Hà Tĩnh','Nghệ An','Thanh Hóa') then 'Miền Bắc'
      when a.statedescr in ('Thành phố Đà Nẵng','Quảng Bình','Quảng Nam','Quảng Ngãi','Quảng Trị','Thừa Thiên - Huế','Bình Định','Bình Thuận','Đắk Lắk','Gia Lai','Khánh Hòa','Kon Tum','Ninh Thuận','Phú Yên') then'Miền Trung'
      else null end as ten_mien,
Case 
       when a.statedescr in('Bình Phước','Đắk Nông','Thành phố Hồ Chí Minh','Long An','Tây Ninh','Tiền Giang','Bến Tre') then 'HCM' 
       when a.statedescr in('Bình Thuận','Đắk Lắk','Gia Lai','Khánh Hòa','Kon Tum','Ninh Thuận','Phú Yên') then 'KHANH HOA'
       when a.statedescr in('Lâm Đồng','Đồng Nai','Bà Rịa - Vũng Tàu','Bình Dương') then 'DONG NAI'
       when a.statedescr in('Hà Tĩnh','Nghệ An','Thanh Hóa') then 'NGHE AN'
       when a.statedescr in('Cao Bằng','Điện Biên','Hà Giang','Hà Nam','Thành phố Hà Nội','Hải Dương','Hải Phòng','Bắc Giang','Hòa Bình','Hưng Yên','Lai Châu','Lạng Sơn','Lào Cai','Bắc Kạn','Nam Định','Ninh Bình','Phú Thọ','Quảng Ninh','Sơn La','Thái Bình','Thái Nguyên','Bắc Ninh','Tuyên Quang','Vĩnh Phúc','Yên Bái') then 'HN'
       when a.statedescr in('Thành phố Đà Nẵng','Quảng Bình','Quảng Nam','Quảng Ngãi','Quảng Trị','Thừa Thiên - Huế','Bình Định') then 'DA NANG'
       when a.statedescr in('An Giang','Cà Mau','Thành phố Cần Thơ','Đồng Tháp','Hậu Giang','Kiên Giang','Bạc Liêu','Sóc Trăng','Trà Vinh','Vĩnh Long') then 'CAN THO'
  else null  
end as branchname_filter,
f.quycachthung,
f.grosswtkg,
f.daim,
f.rongm,
f.caom,
round(f.vm3,2) as vd3thung,
null as vd3hop,
round(safe_divide(f.grosswtkg * abs(soluong),f.quycachthung),2) as khoiluong,
round(safe_divide(f.vm3 * abs(soluong),f.quycachthung),2) as thetich,
safe_divide(abs(soluong),f.quycachthung) as kien,
ifnull(b.channel,c.channel) as channel_pda,
ifnull(b.shoptype,c.shoptype) as shoptype_pda,
ifnull(b.hcoid,c.hcoid) as hcoid_pda,
ifnull(b.hcotypeid,c.hcotypeid) as  hcotypeid_pda,
d.taxregnbr as ma_so_thue,
d.invoicecustid,
d.custinvcname,
e.descr as terms,
case 
      when d.paymentsform = 'A' then	'Chuyển Khoản'
      when d.paymentsform = 'B' then 'Tiền Mặt'
      when d.paymentsform = 'C' then 'Tiền Mặt/Chuyển Khoản'
      when d.paymentsform = 'D'	then 'Ghi Nợ'
      when d.paymentsform = 'E'	then 'TM/CK/CTH'
      when d.paymentsform = 'F' then	'Cấn Trừ Nợ' 
  else d.paymentsform end as hinhthucthanhtoan ,
 g.tencvbh as ten_nvgh,
 h.lotsernbr,
 h.expdate,
 k.descr as tensanphamnb,
case
    when macongtycn in( 'NAN012','KHA014','HYN017','HNI010','HCM001', 'DNI015','DNG013', 'CTO016') then 'MERAP'
  ELSE 'PHA NAM'
END as phap_nhan,
 from result_union a 
  LEFT JOIN `staging.d_manual_danhsach_banggia_sanpham2023` f on f.masp = a.masanpham
  LEFT JOIN `staging.sync_dms_pda_so` b on a.macongtycn =b.branchid and a.sodondathang =b.ordernbr
  LEFT JOIN `staging.d_master_khachhang` c on a.makhdms = c.custid 
  LEFT JOIN `staging.sync_dms_so` d on d.ordernbr = a.mahd and a.macongtycn =d.branchid
  LEFT JOIN `staging.d_manual_terms_detail` e on e.termsid = d.terms
  LEFT JOIN `staging.d_users` g on a.manvgh =g.manv
  LEFT JOIN staging.sync_dms_lt h on h.branchid = a.macongtycn and h.ordernbr = a.mahd and h.omlineref = a.lineref
  LEFT JOIN staging.d_dms_master_invtid k on k.invtid = a.masanpham
);
Create or replace table `warehouse.f_raw_data_sales_yoy_mp`
copy `staging_temp.f_raw_data_sales_yoy_mp_temp`;
END;