CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_all_cxs_khac()
BEGIN 




---CXS | Thông tin PVKH & HSPL (All)


---CXS | HCP | Báo cáo đơn hàng chưa duyệt


----CXS | Báo cáo tổng quát về Khách hàng



---CXS | Tracking Lịch sử thay đổi Thông tin KH


---CXS | Cảnh báo bán sai PVKD


----CXS | Báo cáo đơn hàng đổi date


---MGM | BigQuery & Report Monitoring
-- CALL `spatial-vision-343005.staging_temp.sp_f_view_logs_page2`();
-- CALL `spatial-vision-343005.staging_temp.sp_f_view_logs`();

---ALL | Tra cứu thông tin khách hàng



---HRM | Thông tin quản trị nhân sự


---PRN | Nhiệt Độ & Độ Ẩm Kho
-- Call  `spatial-vision-343005.staging_temp.sp_f_nhietdo_doam`();
-- Call  `spatial-vision-343005.staging_temp.sp_d_nhietdo_doam_detail`();

---MGM | Daily Snapshot




---MGM | Chi tiết khuyến mãi trên đơn


---MGM | Chính sách bán hàng


---MGM | Báo cáo MBM




--SCN | Báo cáo dữ liệu PXKKVCNB


---PMO | Báo cáo theo dõi nghiệp vụ DMS


---MGM | Danh sách và chi tiết đơn hàng (All)
---MGM | Báo cáo tổng quát Trạng thái đơn hàng




---CXS | Danh mục hợp đồng & THẦU





---CXS | Caresoft Performance


End;