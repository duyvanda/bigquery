CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_view_logs_page2()
BEGIN 
  TRUNCATE TABLE staging_temp.f_view_logs_page2_temp;

 INSERT INTO staging_temp.f_view_logs_page2_temp(

-- CREATE OR REPLACE table `staging_temp.f_view_logs_page2_temp`
-- partition by date(createTime)
-- as

SELECT 
DATETIME(timestamp, "Asia/Bangkok") as createTime,
jsonPayload.id, 
jsonPayload.manv,
jsonPayload.ismb,
jsonPayload.dv_width,
b.tenreport,

e.hovatenfullname,
e.chucdanhvntitle,
e.phongdeptvn,

-- c.hovaten,
-- c.chucdanhtiengviet,
-- d.phong,
-- d.congtyquanly
FROM `spatial-vision-343005.staging.django_bi_team_logger`a 
left join `staging.d_report_name` b on b.id = a.jsonPayload.id 

left join `spatial-vision-343005.staging.d_hr_dsns`e on a.jsonPayload.manv = e.msnvcsmmoi
 );
Create or replace table `warehouse.f_view_logs_page2`

copy `staging_temp.f_view_logs_page2_temp`;

End;