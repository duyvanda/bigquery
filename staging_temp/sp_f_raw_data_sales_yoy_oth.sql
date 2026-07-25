CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_raw_data_sales_yoy_oth()
BEGIN 

TRUNCATE TABLE `staging_temp.f_raw_data_sales_yoy_oth_temp`;
INSERT INTO `staging_temp.f_raw_data_sales_yoy_oth_temp`

(  
-- Create or replace table staging_temp.f_raw_data_sales_yoy_oth_temp
-- partition by date(ngaychungtu)
-- cluster by makhdms,makenhkh,makenhphu,hcoid
-- as 
with  

data_pda as (
select ordernbr,custid,branchid,

 'TMDT_001' as  crtd_user from `spatial-vision-343005.staging.sync_dms_pda_so` 
WHERE (crtd_user ='TMDT_001' or slsperid ='TMDT_001')  and crtd_datetime >='2022-06-01' --or slsperid ='TMDT_001'
),

--Update từ ngày 1/4
tuyen_dms_moinhat as 
(
with data_tuyen as (
SELECT custid,slsperid,crtd_datetime,
Case when routetype in ('B','D') then 1 else 2 end as routetype,
FROM `spatial-vision-343005.staging.sync_dms_srm` 
where delroutedet is false --and slsperid not in ('MR1008','MR1705','MR2610','MR1225','MR2596','MR2594','MR2611')
)
select * from (
select *,row_number() over (partition by custid order by routetype asc,crtd_datetime desc) as loc  from data_tuyen
)
where loc =1

),

-- tuyen_ngoai_mcp_theo_sup as 
-- (
--   SELECT distinct a.tinhtp,b.supid,b.tenquanlytt FROM `spatial-vision-343005.staging.d_manual_tuyenbanhang_crs` a
-- LEFT JOIN `staging.d_users` b on a.macrs =b.manv
-- where b.supid is not null

-- ),

---Tuyến bán hàng theo hợp đồng
tuyen_cvbh_hd as 
(
  with data_crs_theohopdong as (
select *,
row_number() over( partition by custid order by crtd_date desc) as loc 
from `spatial-vision-343005.staging.d_get_contract_det` 
)

select * from data_crs_theohopdong where loc =1 

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
    d.shortterritorydescr  as territorydescr,
    Case when ifnull(d.districtdescr,a.tenquanhuyen) in ('Quận 2','Quận 9') then 'Thành phố Thủ Đức' else ifnull(d.districtdescr,a.tenquanhuyen) end as districtdescr,
    d.wardname as wardname,
    a.sodondathang,
    a.ngaychungtu,
    date_trunc(ngaychungtu,month) as thang,
    a.masanpham,
    a.tensanphamviettat,
    Case when doanhsochuavat =0 then 0 else a.soluong end as soluong, --26/7 update hàng khuyến mãi k cộng số lượng
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

    Case when ifnull(d.shoptype,a.makenhphu) ='PK' and d.channel ='OTC' then 'PCL' 
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

    d.classid as classid,
    d.pubcustid,
    d.pubcustname,
    Case when a3.ordernbr is not null then 'Ecom' else 'Merap' end as is_ecom,
    a.mahd,
    a.hoadon,
    d.cluster_state,
    a.sodontrahang

  FROM `spatial-vision-343005.staging.f_sales` a
  LEFT JOIN data_pda a3 on a3.ordernbr =a.sodondathang and a3.branchid = a.macongtycn
  LEFT JOIN `staging.d_master_khachhang` d on d.custid = a.makhdms
  WHERE  
    ngaychungtu <'2023-01-01' 
    and makenhkh !='NB'
    and left(masanpham,1) !='V'
      AND (a.manv  IN ( 'GH001','QUYNHPTA','MA001','MA002','MA003') 

      or makenhkh  in ( 'OTH_LAB') )
),

result as (

select a.*except(manv),
  
  Case 
        when l.col.phan_loai_mcp = 'Rural' 
        or a.manv = 'TMDT_001'
        or a.manv in ("MR1682KN","MR2504","MR1232","MR0806","MR2608","MR2111","MR1682","MR2504KN","MR1232KN","MR0806KN","MR2608KN",
        "MR2111KN","MR2993","MR2993KN","MR3038","MR3038KN","MR2608KN","MR2948","MR2948KN","MR2608")
        or (a.makenhphu not in ('SI23', 'SI', 'CTD') and b.tenquanlytt = 'Nguyễn Văn Tiến' and ngaychungtu < '2024-01-01') 
        then l.col.ma_nvbh
      else a.manv
      end as manv, 
  a.manv as ori_manv,
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
 LEFT JOIN `staging.d_users` b on a.manv =b.manv


),
result1 as (
select 

extract (year from ngaychungtu) as year,

Case when extract (month from ngaychungtu) <=6 then  'C1.' ||  extract (year from ngaychungtu) else 'C2.' ||  extract (year from ngaychungtu) end as cycle,

extract (month from ngaychungtu) as thang_number,

Case when makenhkh in ('INS','CLC','PCL') then 'HCP'else makenhkh end as phong_kh,

a.*except(phanloai,manv,ma_ncxm),
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
ifnull(e.spcl2023tp_mt,e1.spcl2023tp_mt)  as spcl2023tp_mt,
ifnull(e.spcl2023pcl_clc_ins,e1.spcl2023pcl_clc_ins) as spcl2023pcl_clc_ins,
ifnull(e.brand2023,e1.brand2023) as brand2023,
ifnull(e.brand,e1.brand) as brand,
ifnull(e.brandnew2023,e1.brandnew2023) as brandnew2023 ,
ifnull(e.branddongnhat,e1.branddongnhat) as branddongnhat,
-- e.spcl2023tp_mt,
-- e.spcl2023pcl_clc_ins,
-- e.brand2023,
-- e.brand,
-- e.brandnew2023,
-- e.branddongnhat,
f.invoicecustid,
f.custinvcname,
f.taxregnbr,
f.invcnote
 from result a
LEFT JOIN `staging.d_users` c on c.manv =a.manv
LEFT JOIN `staging.d_users` d on d.manv =a.ma_ncxm
LEFT JOIN `staging.d_nhom_sp_trading` e on e.masanpham = a.masanpham
LEFT JOIN `staging.d_nhom_sp_trading_bytime` e1 on e1.masanpham = a.masanpham and extract(year from ngaychungtu) < 2025 and e1.nam =2024
LEFT JOIN `spatial-vision-343005.staging.sync_dms_so` f on f.ordernbr = a.mahd and f.branchid =a.macongtycn

),

bytime_oth_lab as (
  with
data_pda as (
    select
        ordernbr,
        custid,
        branchid,
        'TMDT_001' as crtd_user
    from
        `spatial-vision-343005.staging.sync_dms_pda_so`
    WHERE
        (
            crtd_user = 'TMDT_001'
            or slsperid = 'TMDT_001'
        )
        and crtd_datetime >= '2022-06-01' --or slsperid ='TMDT_001'
),

data as(
    SELECT
        a.macongtycn,
        d.branchname as congtycn,
        a.maphanloaihco,
        ifnull(a.makhcu, a.makhdms) as makhcu,
        a.makhdms,
        d.custname as tenkhachhang,
        d.statedescr as tentinhkh,
        d.statedescr as statedescr,
        d.territorydescr as territorydescr,
        Case
            when d.districtdescr in ('Quận 2', 'Quận 9') then 'Thành phố Thủ Đức'
            else d.districtdescr
        end as districtdescr,
        d.wardname,
        d.shortterritorydescr as khuvucviettat,
        a.sodondathang,
        a.ngaychungtu,
        EXTRACT(
            month
            FROM
                a.ngaychungtu
        ) AS month,
        a.thang,
        a.masanpham,
        a.tensanphamnb,
        a.tensanphamviettat,
        Case
            when doanhsochuavat = 0 then 0
            else a.soluong
        end as soluong,
        a.dongiachuavat,
        a.dongiacovat,
        a.doanhsocovat,
        a.doanhsochuavat,
        Case
            when upper(ifnull(a3.crtd_user, a.manv)) like '%KN' then LEFT(ifnull(a3.crtd_user, a.manv), 6)
            else ifnull(a3.crtd_user, a.manv)
        end as manv,
        Case
            when a.masanpham ='EH092' and ngaychungtu >='2024-04-01' and a.makenhkh ='INS' then 'CLC'
            else a.makenhkh
        end as makenhkh,
        a.tenkenhkh,
        Case
            when a.masanpham ='EH092' and ngaychungtu >='2024-04-01' and a.makenhphu ='INS1' then 'CLC1'
            when a.masanpham ='EH092' and ngaychungtu >='2024-04-01' and a.makenhphu ='INS2' then 'CLC2'
            when a.masanpham ='EH092' and ngaychungtu >='2024-04-01' and a.makenhphu ='INS3' then 'CLC3'
            else a.makenhphu
        end as makenhphu,
        a.tenkenhphu,
        a.inserted_at as updated_at,
        0 as kh_total,
        Case
            when a.manv = 'MR0868'
            and a.masanpham in ('EH115', 'EBS10', 'OH082', 'MDR125KC')
            and (
                a.makenhphu in('SI')
                or a.makenhkh in ('MT')
            ) then doanhsochuavat
            when a.masanpham in ('EH115', 'EBS10', 'OH082', 'MDR125KC')
            and a.makenhkh in ('TP', 'PCL') then doanhsochuavat
            when a.masanpham in ('EH092', 'OH082', 'EH115', 'EH102', 'OH076')
            and makenhkh in ('OTC', 'DLPP')
            and ngaychungtu >= '2022-04-01'
            and ngaychungtu < '2022-07-01' then doanhsochuavat
            when a.masanpham in ('EH115', 'OH080', 'OH082')
            and ngaychungtu >= '2022-01-01'
            and ngaychungtu < '2022-04-01'
            and makenhkh in ('OTC', 'DLPP') then doanhsochuavat
            when a.masanpham in ('EH092', 'OH082', 'OH083', 'EH102', 'EH115')
            and ngaychungtu >= '2022-07-01'
            and makenhkh in ('OTC', 'DLPP') then doanhsochuavat
            else 0
        end as thuchien_spmoi,
        0 as kh_spmoi,
        Case
            when a.makenhphu in ('INS2', 'INS3', 'CLC2', 'CLC3') then doanhsochuavat
            else 0
        end as thuchien_yttn,
        0 as kh_yttn,
        Case
            when a.masanpham in (
                'EH072',
                'EH105',
                'OH016',
                'OH032',
                'OH047',
                'OH057',
                'OH058',
                'OH071',
                'OH079',
                'OH081'
            )
            and ngaychungtu < '2023-01-01' then 'PHANAM'
            else 'MERAP'
        end as is_phanam,
        'f_sales' as datatype1,
        Case
            when a3.ordernbr is not null then 'Ecom'
            else 'Merap'
        end as is_ecom,
        a.manvghreal,
        a.pda_crtd_user,
        a.pda_slsperid,
        a.hoadon,
        cast(0 as float64) as slpp_ebysta,
        cast(0 as float64) as slpp_medoral,
        0 as kpi_ds_pcl,
        
        Case
            when a.ngaychungtu >='2024-10-01' and ngaychungtu <'2024-11-01' and masanpham in ('T303102009')  
            and a.makenhkh = 'TP'
            and  doanhsochuavat <> 0 
            and sum(soluong) over (partition by doanhsochuavat <> 0 ,date_trunc(ngaychungtu,month),makhdms,masanpham) >= 5
            then makhdms

            when a.ngaychungtu >='2024-07-01' and a.ngaychungtu <'2024-10-01' and masanpham in ('T302203003')  
            and a.makenhkh = 'TP'
            and soluong > 0 and doanhsochuavat >0 
            and sum(soluong) over (partition by macongtycn,sodondathang,masanpham)  >= 5
            then ifnull(makhcu, makhdms)

            when a.ngaychungtu >='2024-04-01' and ngaychungtu <'2024-07-01' and masanpham in ('T3044004')  
            and a.makenhkh = 'TP'
            and soluong > 0 and doanhsochuavat >0 
            and sum(soluong) over (partition by macongtycn,sodondathang,masanpham)  >= 3
            then ifnull(makhcu, makhdms)

            when a.ngaychungtu >='2024-01-01' and ngaychungtu <'2024-04-01' and masanpham in ('T302202003','T302202004','T302202005')  
            and a.makenhkh = 'TP'
            and doanhsochuavat > 0 then ifnull(makhcu, makhdms)

         ---quý 1,2 2023 sptt qua ebysta
            when a.ngaychungtu <'2023-10-01' and masanpham = 'EH115'
            and a.makenhkh = 'TP'
            and doanhsochuavat > 0 then ifnull(makhcu, makhdms)
            else null
        end as th_slpp_ebysta,
        -----18/7 chị Linh update những hàng tặng từ các chương trình sẽ không tính vào phân phối
        Case
        ---2024 chuyển sptt qua SHEMA
            when a.ngaychungtu >='2024-07-01' then null -- k có tiêu chí sp2

            when a.ngaychungtu >='2024-04-01' and masanpham in ('T302204004')  
            and a.makenhkh = 'TP'
            and soluong > 0 and doanhsochuavat >0 
            and sum(soluong) over (partition by macongtycn,sodondathang,masanpham)  >= 3
            then ifnull(makhcu, makhdms)
            
            when a.ngaychungtu >='2024-01-01'and ngaychungtu <'2024-04-01' and masanpham in ('T302105002')  
            and a.makenhkh = 'TP'
            and doanhsochuavat > 0 then ifnull(makhcu, makhdms) 

            when ngaychungtu >='2023-10-01' then null -- tháng 10 chuyển sang kpi doanh số sản phẩm tt XPL
            when masanpham in('EH092', 'OH082', 'OH084', 'EH102', 'EH121')
            and a.makenhkh = 'TP'
            and doanhsochuavat > 0
            and ngaychungtu < '2023-07-01' then ifnull(makhcu, makhdms)
            when masanpham in(
                'OH074',
                'OH075',
                'OH077',
                'OH078',
                'T302101008',
                'T302101007',
                'T302101006',
                'T302101005'
            )
            and a.makenhkh = 'TP'
            and doanhsochuavat > 0
            and ngaychungtu >= '2023-09-01'
            and sum(soluong) over (partition by macongtycn,sodondathang,(Case when masanpham in ('OH074',
                'OH075',
                'OH077',
                'OH078',
                'T302101008',
                'T302101007',
                'T302101006',
                'T302101005') then 1 else 2 end))  >= 3 then ifnull(makhcu, makhdms) --tháng 9 tính tổng sl shema trên 1 đơn hàng >=3 mới tính 1 phân phối
            when masanpham in(
                'OH074',
                'OH075',
                'OH077',
                'OH078',
                'T302101008',
                'T302101007',
                'T302101006',
                'T302101005'
            )
            and a.makenhkh = 'TP'
            and doanhsochuavat > 0
            and ngaychungtu >= '2023-07-01'
            and ngaychungtu < '2023-09-01' then ifnull(makhcu, makhdms) --tháng 7 đổi medoral qua shema lá đôi
            else null
        end as th_slpp_medoral,
        Case
            when makenhkh = 'PCL' then doanhsochuavat
            else 0
        end as th_ds_pcl,
        Case
                ----Từ 2024 chị Nga phụ trách SPTT Ebysta còn Đạt phụ trách FMCG
                ---Tháng 3/2024 bỏ doanh số kênh phụ ECOM ra
            when ngaychungtu >='2024-03-01' and  ( manv in('MR3057','MR3066','MR3070') or tenquanlytt in ('Dương Thanh Sơn') )  and makenhphu in( 'FMCG')
            and makenhkh = 'MT' and makhdms not in ('008140', '003589')
            then doanhsochuavat 

            when ngaychungtu <'2024-03-01' and ngaychungtu >= '2024-01-01'and  manv ='MR3057' and makenhphu in('ECOM', 'FMCG')
            and makenhkh = 'MT' and makhdms not in ('008140', '003589')
              then doanhsochuavat 
            --- Từ tháng 7/2023 cập nhật thêm doanh số ECOM để tính lương
           
            when (manv  in ('MR0868','MR1360') or tenquanlytt in ('Nguyễn Thị Nga') ) and makenhkh = 'MT'and masanpham ='EH115' and ngaychungtu >='2024-01-01' then doanhsochuavat
            
            ----rule năm 2024 trở xuống
            when makenhphu in('ECOM', 'FMCG')
            and makenhkh = 'MT' and makhdms not in ('008140', '003589')
            and ngaychungtu >= '2023-07-01' and ngaychungtu <'2024-01-01' then doanhsochuavat --- Từ tháng 7 cập nhật thêm doanh số ECOM để tính lương
            when (
                makhdms = 'MC017'
                or makenhphu in('CCD', 'FMCG')
            )
            and makenhkh = 'MT' and ngaychungtu <'2023-07-01' then doanhsochuavat
            else 0
        end as th_ds_fmcg,
        0 as kpi_ds_fmcg,
        kieudonhang,
        a.mahco,
        a.maphanhanghco,
        a.mahd,
        Case when ngaychungtu >='2024-11-01' and ngaychungtu <'2025-01-01' and masanpham in('T303102006','T303102005','EH086','EH087','EH108','T303102008','T303102010','T303102011','T303102009') 
                  and a.makenhkh = 'TP' then doanhsochuavat
            when ngaychungtu >='2023-10-01' and ngaychungtu <'2024-01-01' and masanpham in('T303102005','EH087','EH108','EH086') and a.makenhkh = 'TP' then doanhsochuavat
        else 0 end as th_ds_sptt,
        0 as kpi_ds_sptt,
        d.cluster_state,
        a.sodontrahang
    FROM
        `spatial-vision-343005.staging.f_sales` a
        LEFT JOIN data_pda a3 on a3.ordernbr = a.sodondathang
        and a3.branchid = a.macongtycn
        LEFT JOIN `staging.d_master_khachhang` d on d.custid = a.makhdms
    WHERE
        a.ngaychungtu >= '2023-01-01'
        and makenhkh !='NB'
    and left(masanpham,1) !='V'
        AND ( a.manv  IN ('GH001', 'QUYNHPTA', 'MA001', 'MA002')
           
        or makhdms  in ('008140', '003589','013410','018851')
        or makenhkh in ('OTH_LAB'))
    UNION
    ALL
    SELECT
        null as macongtycn,
        null as congtycn,
        null as maphanloaihco,
        null as makhcu,
        null as makhdms,
        null as tenkhachhang,
        null as tentinhkh,
        null as statedescr,
        null as territorydescr,
        null as districtdescr,
        null as wardname,
        null as khuvucviettat,
        null as sodondathang,
        a.thang as ngaychungtu,
        EXTRACT(
            month
            FROM
                a.thang
        ) AS month,
        a.thang,
        null as masanpham,
        null as tensanphamnb,
        null as tensanphamviettat,
        0 as soluong,
        0 as dongiachuavat,
        0 as dongiacovat,
        0 as doanhsocovat,
        0 as doanhsochuavat,
        Case
            when upper(a.manv) like '%KN' then LEFT(a.manv, 6)
            else a.manv
        end as manv,
        Case
            when a.makenhkh = 'SI' then 'TP'
            when a.htbh = 'MDS'
            and thang <= '2023-01-01' then 'MDS'
            else a.makenhkh
        end as makenhkh,
        null as tenkenhkh,
        null as makenhphu,
        null as tenkenhphu,
        a.inserted_at as updated_at,
        a.kh_total,
        0 as thuchien_spmoi,
        a.kh_spmoi,
        0 as thuchien_yttn,
        a.kh_yttn,
        null as is_phanam,
        'd_calendar' as datatype1,
        null as is_ecom,
        null as manvghreal,
        null as pda_crtd_user,
        null as pda_slsperid,
        null as hoadon,
        Case  
            -- when thang >='2024-03-01' and makenhkh ='MT' then kpi_vieng_tham_kh_mt
            when makenhkh ='TP' and thang >='2023-10-01' and thang < '2024-01-01' then 0 
            when makenhkh ='TP' and thang < '2024-11-01' then  round(slkh_ebysta, 1) 
        else  0
        end as slkh_ebysta, ---2024 chuyển qua XP, cột slkh_ebysta = xp
        Case
            when makenhkh ='TP' and thang >='2024-01-01' then round(slkh_ladoi, 1) ---2024 chuyển qua shema, cột slkh_ladoi = shema (sản phẩm 2)
            when makenhkh ='TP' and thang >= '2023-07-01' and thang <'2024-01-01' then round(slkh_ladoi, 1) 
            when makenhkh ='TP' and thang < '2024-11-01' then round(slkh_medoral, 1) 
            else 0
        end as slkh_medoral,
        Case
            when makenhkh = 'PCL' then kh_total
        end as kpi_ds_pcl,
        null as th_slpp_ebysta,
        null as th_slpp_medoral,
        0 as th_ds_pcl,
        0 as th_ds_fmcg,
        kh_fmcg as kpi_ds_fmcg,
        null as kieudonhang,
        null as mahco,
        null as maphanhanghco,
        null as mahd,
        0 as th_ds_sptt,
        Case 
            when makenhkh ='TP' and thang >='2024-11-01' and thang <'2025-01-01' then slkh_ebysta * 1000 
            when makenhkh ='TP' and thang >='2023-10-01' and thang <'2024-01-01' then slkh_ebysta * 1000       
            else 0 end as kpi_ds_sptt,
        null as cluster_state,
        null as sodontrahang
    FROM
        `spatial-vision-343005.staging.d_calendar` a
    WHERE
        thang >= '2023-01-01'
        and makenhkh  in ('OTH_LAB','NB')
),
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
        Case
            when a.territorydescr = 'Miền Đông 1' then 'MN'
            when a.territorydescr = 'Bắc Trung Bộ' then 'MB'
            when a.territorydescr = 'Nam Trung Bộ' then 'MN'
            when a.territorydescr = 'Đông Nam 2' then 'MN'
            when a.territorydescr = 'Hà Nội 2' then 'MB'
            when a.territorydescr = 'Hồ Chí Minh 2' then 'MN'
            when a.territorydescr = 'Đông Bắc 1' then 'MB'
            when a.territorydescr = 'Mê Kông 2' then 'MN'
            when a.territorydescr = 'Mê Kông 1' then 'MN'
            when a.territorydescr = 'Tây Bắc HN' then 'MB'
            when a.territorydescr = 'Hà Nội 1' then 'MB'
            when a.territorydescr = 'Miền Đông 2' then 'MN'
            when a.territorydescr = 'Đông Bắc 2' then 'MB'
            when a.territorydescr = 'Đông Nam 1' then 'MN'
            when a.territorydescr = 'Hồ Chí Minh 1' then 'MN'
            else null
        end as vungmien,
        a.cluster_state,
        a.sodondathang,
        a.sodontrahang,
        a.ngaychungtu,
        a.hoadon,
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

/* 
khbt.phan_loai_mcp = 'Rural'
or a.manv = 'TMDT_001'
or a.manv in ("MR1682KN","MR2504","MR1232","MR0806","MR2608","MR2111","MR1682","MR2504KN","MR1232KN","MR0806KN","MR2608KN",
"MR2111KN","MR2993","MR2993KN","MR3038","MR3038KN","MR2608KN","MR2948","MR2948KN","MR2608")
or (a.makenhphu not in ('SI23', 'SI', 'CTD') and b.tenquanlytt = 'Nguyễn Văn Tiến' and ngaychungtu < '2024-01-01')
then khbt.ma_nvbh else a.manv
end as manv,
*/

      Case 
        when l.col.phan_loai_mcp = 'Rural' 
        or a.manv = 'TMDT_001'
        or a.manv in ("MR1682KN","MR2504","MR1232","MR0806","MR2608","MR2111","MR1682","MR2504KN","MR1232KN","MR0806KN","MR2608KN",
        "MR2111KN","MR2993","MR2993KN","MR3038","MR3038KN","MR2608KN","MR2948","MR2948KN","MR2608",'MR3196','MR3196KN')
        or (a.makenhphu not in ('SI23', 'SI', 'CTD') and b.tenquanlytt = 'Nguyễn Văn Tiến' and ngaychungtu < '2024-01-01') 
        then l.col.ma_nvbh
      else a.manv
      end as manv, 
      Case 
        when l.col.phan_loai_mcp = 'Rural'then 'Rural'
        when a.manv = 'TMDT_001' and l.col.phan_loai_mcp = 'CRS (Trong MCP)' then 'Trong MCP (Ecom)'
        when a.manv = 'TMDT_001' and l.col.phan_loai_mcp = 'CRS (Ngoài MCP)' then 'Ngoài MCP (Ecom)'
        when a.manv in ("MR1682KN","MR2504","MR1232","MR0806","MR2608","MR2111","MR1682","MR2504KN","MR1232KN","MR0806KN","MR2608KN",
        "MR2111KN","MR2993","MR2993KN","MR3038","MR3038KN","MR2608KN","MR2948","MR2948KN","MR2608",'MR3196','MR3196KN') then 'Ngoài MCP (CX)'
      else 'Trong MCP'
      end as phanloai,
        a.makenhkh,
        a.tenkenhkh,
        a.makenhphu,
        a.tenkenhphu,
        a.updated_at,
        a.is_ecom,
        a.kh_total,
        a.thuchien_spmoi,
        a.kh_spmoi,
        a.thuchien_yttn,
        a.kh_yttn,
        Case
            when a1.nhomcpa is not null then a1.nhomcpa
            else 'OTHERS'
        end as datatype,
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
        th_ds_sptt,
        kpi_ds_sptt,
        kieudonhang,
        mahco,
        maphanhanghco,
        mahd,
        a.manv as manv_original,
        null as manv_mds,
        a.manvghreal,
        a.pda_crtd_user,
        a.pda_slsperid,
    FROM
        data a
        LEFT JOIN `staging.d_nhom_sp_trading` a1 on a1.masanpham = a.masanpham
        LEFT JOIN `warehouse.f_mapping_crs_bytime` l on l.custid = a.makhdms and date_trunc(ngaychungtu,month) = l.thang
        LEFT JOIN staging.d_users_bytime b on b.manv = a.manv
        and date(a.thang) = date(b.thang)
),
result0_1 as (
    select
        a.*,
        Case
            when phanloai = 'Rural' then 'Rural'
            when phanloai = 'Ngoài MCP (Ecom)' then 'Ngoài MCP'
            when phanloai = 'Trong MCP (Ecom)' then 'Trong MCP'
            when phanloai = 'Trong MCP' then 'Trong MCP'
            when phanloai = 'Ngoài MCP' then 'Ngoài MCP'
            when phanloai = 'Ngoài MCP (CX)' then 'Ngoài MCP'
            else 'Khác'
        end as crs_tuyenbanhang_trongmcp,
    from
        result0 a
),
result1 as (
    select
        a.*
    except(manv, makenhkh, th_slpp_ebysta, th_slpp_medoral),
        th_slpp_ebysta,
        th_slpp_medoral,
        th_slpp_ebysta as th_slpp_ebysta_ori,
        th_slpp_medoral as th_slpp_medoral_ori,
        a.makenhkh as makenhkh,
        Case
            when is_ecom = 'Merap'
            and ngaychungtu >= '2022-01-01' then 'Merap'
            when is_ecom = 'Ecom'
            and ngaychungtu >= '2022-01-01' then 'Ecom'
            else null
        end as is_mrtd,
        a.manv,
        Case
            when a.manv = 'CX' then 'MR1682'
            else left(b.supid,6)
        end as crm,
        b.asm as scrm,
        Case
            when a.manv ='CX' and ngaychungtu >='2024-01-01' then 'MR0485' 
            when b.tenquanlytt = 'Lê Thị Hương Sa' then b.supid
            else Left(b.rsmid, 6)
        end as ncxm,
        Case
            when a.manv = 'CX' then 'CX'
            else b.tencvbh
        end as tencvbh,
        -- b.tencvbh,
        Case
            when a.manv = 'CX' then 'Đinh Thị Ngọc Mẫn'
            else b.tenquanlytt
        end as tenquanlytt,
        b.tenquanlykhuvuc,
        Case
            when b.tenquanlytt = 'Lê Thị Hương Sa' then 'Lê Thị Hương Sa'
            when a.manv ='CX' and ngaychungtu >='2024-01-01' then 'Nguyễn Hoàng Viển'
            when a.manv = 'CX' then 'Nguyễn Thị Ngọc Diệp'
            else ifnull(b.tenquanlyvung, "Chưa xác định")
        end as tenquanlyvung,
        sum(doanhsochuavat) over(partition by a.thang) as ds_sp_thang,
        k.firstname as ten_nguoi_taodon,
        k1.firstname as tencvbh_header,
        k2.firstname as tencvbh_ori,
        0 as doanhso_gh_crs
    from
        result0_1 a
        LEFT JOIN `staging.d_users_bytime` b on b.manv = a.manv
        and date(a.thang) = date(b.thang)
        LEFT JOIN `staging.d_dms_master_users` k on k.username = a.pda_crtd_user
        LEFT JOIN `staging.d_dms_master_users` k1 on k1.username = a.pda_slsperid
        LEFT JOIN `staging.d_dms_master_users` k2 on k2.username = a.manv_original
)

select
macongtycn,
congtycn,
maphanloaihco,
makhcu,
makhdms,
tenkhachhang,
tentinhkh,
statedescr,
territorydescr,
districtdescr,
wardname,
khuvucviettat,
vungmien,
cluster_state,
sodondathang,
sodontrahang,
ngaychungtu,
hoadon,
month,
thang,
masanpham,
tensanphamnb,
tensanphamviettat,
soluong,
dongiachuavat,
dongiacovat,
doanhsocovat,
doanhsochuavat,
manv_mds,
manv_original,
manvghreal,
pda_crtd_user,
pda_slsperid,
tenkenhkh,
makenhphu,
tenkenhphu,
updated_at,
is_ecom,
kh_total,
thuchien_spmoi,
kh_spmoi,
thuchien_yttn,
kh_yttn,
datatype,
team,
datatype1,
slpp_ebysta,
slpp_medoral,
kpi_ds_pcl,
th_ds_pcl,
th_ds_fmcg,
kpi_ds_fmcg,
th_ds_sptt,
kpi_ds_sptt,
kieudonhang,
mahco,
maphanhanghco,
mahd,
crs_tuyenbanhang_trongmcp,
phanloai,
th_slpp_ebysta,
th_slpp_medoral,
th_slpp_ebysta_ori,
th_slpp_medoral_ori,
makenhkh,
is_mrtd,
manv,
crm,
scrm,
ncxm,
tencvbh,
tenquanlytt,
tenquanlykhuvuc,
tenquanlyvung,
ds_sp_thang,
ten_nguoi_taodon,
tencvbh_header,
tencvbh_ori,
doanhso_gh_crs

from
    result1
)

,
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
Case when  a.masanpham ='EH092' and ngaychungtu >='2024-04-01' and ifnull(c.channel,a.makenhkh) ='INS' then 'CLC' else ifnull(c.channel,a.makenhkh) end  as makenhkh,
Case 
  when  a.masanpham ='EH092' and ngaychungtu >='2024-04-01' and ifnull(c.shoptype,a.makenhphu) ='INS1' then 'CLC1'
  when  a.masanpham ='EH092' and ngaychungtu >='2024-04-01' and ifnull(c.shoptype,a.makenhphu) ='INS2' then 'CLC2'
  when  a.masanpham ='EH092' and ngaychungtu >='2024-04-01' and ifnull(c.shoptype,a.makenhphu) ='INS3' then 'CLC3'
  when c.shoptype ='SI23' then 'SI' 
  else ifnull(c.shoptype,a.makenhphu)
end as makenhphu,
c.hcoid as ma_hco,
c.hcotypeid as phanloai_hco,
c.classid as phanhang_hco,
c.pubcustid,
c.pubcustname, --hco_me
a.is_ecom,
a.mahd,
a.hoadon,
a.cluster_state,
a.sodontrahang,
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
       -- Kênh MT chị Hương Sa
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
ifnull(e.brandnew2023,e1.brandnew2023) as brandnew2023 ,
ifnull(e.branddongnhat,e1.branddongnhat) as branddongnhat,
-- e.spcl2023tp_mt,
-- e.spcl2023pcl_clc_ins,
-- e.brand2023,
-- e.brand,
-- e.brandnew2023,
-- e.branddongnhat,
f.invoicecustid,
f.custinvcname,
f.taxregnbr,
f.invcnote

 from bytime_oth_lab a 
 LEFT JOIN `staging.d_master_khachhang` c on a.makhdms =c.custid
 LEFT JOIN `staging.d_nhom_sp_trading` e on e.masanpham = a.masanpham
 LEFT JOIN `staging.d_nhom_sp_trading_bytime` e1 on e1.masanpham = a.masanpham and extract(year from ngaychungtu) < 2025 and e1.nam =2024
 LEFT JOIN `spatial-vision-343005.staging.sync_dms_so` f on f.ordernbr = a.mahd and f.branchid =a.macongtycn

 where datatype1 <>'d_calendar' 
)
,
mapping_all_sales as (
select *
 from result1 
UNION ALL
select *
 from mapping_data_sales_t4_2023
),
tach_pl_theonam_2023 as (
SELECT ma_sp,
pl_diamon,
parse_date("%d/%m/%Y" ,split(ten_san_pham,"&&")[OFFSET(1)]) as start_date,
parse_date("%d/%m/%Y" ,split(ten_san_pham,"&&")[OFFSET(2)]) as end_date,
 FROM `spatial-vision-343005.staging.d_manual_danhsach_khachhang_diamond` where ma_sp is not null
and parse_date("%d/%m/%Y" ,split(ten_san_pham,"&&")[OFFSET(2)]) <'2024-01-01'
),
tach_pl_theonam_2024 as (
SELECT ma_sp,
pl_diamon,
parse_date("%d/%m/%Y" ,split(ten_san_pham,"&&")[OFFSET(1)]) as start_date,
parse_date("%d/%m/%Y" ,split(ten_san_pham,"&&")[OFFSET(2)]) as end_date,
 FROM `spatial-vision-343005.staging.d_manual_danhsach_khachhang_diamond` where ma_sp is not null
and parse_date("%d/%m/%Y" ,split(ten_san_pham,"&&")[OFFSET(2)]) >='2024-01-01'
),

result_sales as (
select a.*,
Case when makenhkh in ('TP','MT') then spcl2023tp_mt 
      when makenhkh in ('INS','CLC','PCL') then spcl2023pcl_clc_ins  else null end as spcl2023_all,
sum(soluong) over(partition by makhdms,masanpham,year,thang) as soluong_filter,
sum(doanhsochuavat) over(partition by makhdms,masanpham,year,thang) as doanhsochuavat_filter,
coalesce(c.pl_diamon,d.pl_diamon,e.pl_diamon) as pl_diamon,
Case when f.ma_kh_dms is not null then 'Có' else 'Không' end as is_check_gold
 
  from mapping_all_sales a 
LEFT JOIN tach_pl_theonam_2023 c on a.masanpham = trim(c.ma_sp) and c.ma_sp is not null and date(a.ngaychungtu) >= c.start_date and date(a.ngaychungtu) <=c.end_date
LEFT JOIN tach_pl_theonam_2024 d on a.masanpham = trim(d.ma_sp) and d.ma_sp is not null and date(a.ngaychungtu) >= d.start_date and date(a.ngaychungtu) <=d.end_date
LEFT JOIN tach_pl_theonam_2024 e on a.masanpham = trim(e.ma_sp) and e.ma_sp is not null and  date(a.ngaychungtu) <=d.end_date
LEFT JOIN (select distinct ma_kh_dms from staging.d_manual_danhsach_khachhang_diamond) f on a.makhdms =f.ma_kh_dms

)

select a.*,
Case 
  when tenquanlyvung is null or tenquanlyvung ='Chưa xác định' then 'Thiếu thông tin NCXM'
else null end as is_rule1,
Case 
  when tenquanlykhuvuc is null or tenquanlykhuvuc ='Chưa xác định' then 'Thiếu thông tin SCRM'
  when ( concat(tenquanlykhuvuc,date(thang)) not in (select distinct concat(tenquanlykhuvuc,date(thang)) from `staging.d_users_bytime` where left(rsmid,6) = 'MR0485') and makenhkh_cu = 'TP' )
      or 
      ( concat(tenquanlykhuvuc,date(thang)) not in (select distinct concat(tenquanlykhuvuc,date(thang)) from `staging.d_users_bytime` where left(rsmid,6) = 'MR0081') and makenhkh_cu in ('INS','CLC','PCL') )
      or 
      ( concat(tenquanlykhuvuc,date(thang)) not in (select distinct concat(tenquanlykhuvuc,date(thang)) from `staging.d_users_bytime` where left(rsmid,6) = 'MR2685') and makenhkh_cu = 'MT' )
      then 'Sai thông tin SCRM'
else null end as is_rule2,
Case 
  when tenquanlytt is null or tenquanlytt ='Chưa xác định' then 'Thiếu thông tin A.CRM'
  when ( concat(tenquanlytt,date(thang)) not in (select distinct concat(tenquanlytt,date(thang)) from `staging.d_users_bytime` where left(rsmid,6) = 'MR0485') and makenhkh_cu = 'TP' )
      or 
      ( concat(tenquanlytt,date(thang)) not in (select distinct concat(tenquanlytt,date(thang)) from `staging.d_users_bytime` where left(rsmid,6) = 'MR0081') and makenhkh_cu in ('INS','CLC','PCL') )
      or 
      ( concat(tenquanlytt,date(thang)) not in (select distinct concat(tenquanlytt,date(thang)) from `staging.d_users_bytime` where left(rsmid,6) = 'MR2685') and makenhkh_cu = 'MT' )
      then 'Sai thông tin A.CRM'
else null end as is_rule3,
Case 
  when manv is null or manv not like 'MR%' then 'Thiếu thông tin Code CRS'
  when ( concat(left(manv,6),date(thang)) not in (select distinct concat(left(manv,6),date(thang)) from `staging.d_users_bytime` where left(rsmid,6) = 'MR0485') and makenhkh_cu = 'TP' )
      or 
      ( concat(left(manv,6),date(thang)) not in (select distinct concat(left(manv,6),date(thang)) from `staging.d_users_bytime` where left(rsmid,6) = 'MR0081') and makenhkh_cu in ('INS','CLC','PCL') )
      or 
      ( concat(left(manv,6),date(thang)) not in (select distinct concat(left(manv,6),date(thang)) from `staging.d_users_bytime` where left(rsmid,6) = 'MR2685') and makenhkh_cu = 'MT' ) then 'Sai Kênh CRS'
  when  concat(left(manv,6),date(thang)) not in (select concat(msnvcsmmoi,date(thang)) from `staging.d_hr_dsns_bytime` where msnvcsmmoi is not null) then 'CRS đã nghỉ việc'
else null end as is_rule4,
Case 
  when  left(manv,6)  in (select msnvcsmmoi from `staging.d_hr_dsns` where ngaynghiviecdieuchuyen ='TS') then 'Nhân viên nghỉ TS'
else null end as is_rule5,
Case 
  when  left(manv,6) != b.col.ma_nvbh and makenhkh_cu ='TP' then 'Đổi nhân viên TP'
else null end as is_rule6,
current_datetime("+7") as inserted_at

 from result_sales a 
 LEFT JOIN `warehouse.f_mapping_crs` b on a.makhdms =b.custid

)

;

Create or replace table `warehouse.f_raw_data_sales_yoy_oth`

copy `staging_temp.f_raw_data_sales_yoy_oth_temp`;


END;