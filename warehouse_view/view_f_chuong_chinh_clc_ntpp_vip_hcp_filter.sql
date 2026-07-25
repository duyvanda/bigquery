CREATE VIEW `spatial-vision-343005.warehouse.view_f_chuong_chinh_clc_ntpp_vip_hcp_filter`
AS SELECT distinct branchid,invoicecustid,custnameinvoice, custid,custname,shoptype,hcotypeid,statedescr,tencvbh,tenquanlytt,tenquanlyvung,ma_crs,ma_crm,ma_ncxm
 FROM `spatial-vision-343005.warehouse.view_f_chuongtrinh_clc123_2025_kt` 
 UNION ALL  
 SELECT distinct branchid,invoicecustid,custnameinvoice,custid,custname,shoptype,hcotypeid,statedescr,tencvbh,tenquanlytt,tenquanlyvung,ma_crs,ma_crm,ma_ncxm
 FROM `spatial-vision-343005.warehouse.view_f_chuongtrinh_vip_hcp_2025_kt` 
 UNION ALL  
 SELECT distinct branchid,invoicecustid,custnameinvoice,custid,custname,shoptype,hcotypeid,statedescr,tencvbh,tenquanlytt,tenquanlyvung,ma_crs,ma_crm,ma_ncxm
 FROM `spatial-vision-343005.warehouse.view_f_chuongtrinh_ntpp_2025_kt`;