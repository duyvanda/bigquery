-- ==========================================================================
-- Routine Name : sp_f_congno_hcp_crs
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2026-08-06 02:45:27.277000+00:00
-- Last Altered : 2026-08-06 02:45:27.277000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_congno_hcp_crs()
BEGIN
  CREATE TEMP TABLE `f_congno_hcp_crs_temp` AS (

    with data_debt_ins2_1 as (
      select
        Case when a.refcustid = 'TD42I004A' then 'MR001'
             when a.refcustid = 'TT55I011A' then 'MR001'
             else a.BranchID end as branchid,
        a.Ordnbr as ordernbr,
        a.dateoforder,
        a.CustId as custid,
        Case when a.refcustid = 'TD42I004A' then 'TD42I004'
             when a.refcustid = 'TT55I011A' then 'TT55I011'
             when a.refcustid = 'TD42I025A' then 'TD42I025'
             else a.refcustid
        end as refcustid,
        a.InvcNbr,
        a.orderdate,
        a.sotien_nogoc,
        a.so_du_chungtu,
        a.sotien_da_thanhtoan,
        a.duedate,
        a.paymentsform_hien_tai as paymentsform,
        a.day_terms,
        a.terms_name as terms,
        a.DocType as doctype,
        a.docdesc,
        a.channel,
        a.shoptype,
        a.statedescr as tinh,
        a.territorydescr as khuvuc,
        a.custname,
        concat(date(g.thoigiangoi), ': ', g.thongtinthanhtoan) as thongtinthanhtoan,
        date(g.thoigiangoi) as thoigiangoi,
        a.is_diadiem,
        a.so_du_dh,
        a.mahd_so,
        a.thoi_diem_no_vang,
        a.thoi_diem_no_do,
        a.thoi_diem_no_den,
        a.phan_loai_no as phanloaino,
        a.thang_chung_tu as thang_chungtu,
        a.thang_thu,
        a.thoigian_no,
        a.thoigian_noqh,
        a.thoigian_noxau,
        a.no_xanh,
        a.no_vang,
        a.no_do,
        a.no_den,
        a.no_xau,
        a.vung_no_kh as vungno_kh,
        a.phan_loai_vung_no as phanloai_vungno,
        a.bbnt08,
        cast(a.contractid as int) as contractid,
        a.contractnbr,
        a.noticenbr,
        a.thanh_ly_dac_biet,
        a.manv,
        a.tencvbh as CRSS,
        a.tenquanlytt,
        a.districtdescr,
        a.wardname,
        cast(null as string) as datatype,
        cast(current_datetime("+7") as timestamp) as updated_at
      from `staging_temp.d_rawdata_debt` a
      LEFT JOIN (
        SELECT
          makhcu,
          thongtinthanhtoan,
          thoigiangoi,
          row_number() over(partition by makhcu order by thoigiangoi desc, inserted_at desc) as loc
        FROM `spatial-vision-343005.staging.d_tttt_ins`
        where thoigiangoi >= '2023-04-30'
      ) g on g.makhcu = a.CustId and g.loc = 1
      where a.channel in ('INS', 'PCL', 'CLC')
      and (a.so_du_dh > 1000 or a.so_du_dh < -1000)
      and (left(lower(a.custname), 5) <> 'xuất ' or lower(a.custname) not like '%anh sách%' or lower(a.custname) not like '%quà%')
    ),
    doanhso6t_sales as (
      SELECT
        macongtycn,
        makhdms,
        ngaychungtu,
        sodondathang,
        doanhsochuavat as soluong,
        manv,
        doanhsocovat,
        masanpham
      from `warehouse.f_raw_data_sales_yoy`
      where makenhkh in('INS', 'PCL', 'CLC')
      and date((select * from `staging.d_current_table`)) <= date_add(date(ngaychungtu), INTERVAL 6 month)
    ),
    doanhso12t_sales as (
      SELECT
        macongtycn,
        makhdms,
        ngaychungtu,
        sodondathang,
        manv,
        doanhsocovat as soluong,
        masanpham
      from `warehouse.f_raw_data_sales_yoy`
      where makenhkh in('INS', 'PCL', 'CLC')
      and date((select * from `staging.d_current_table`)) <= date_add(date(ngaychungtu), INTERVAL 12 month)
    ),
    doanhso12t as (
      SELECT makhdms, sum(soluong) as soluong_12t
      from doanhso12t_sales
      GROUP BY 1
    ),
    doanhso6t as (
      SELECT makhdms, sum(soluong) as soluong_6t
      from doanhso6t_sales
      GROUP BY 1
    ),
    doanhso as (
      SELECT
        b.makhdms,
        b.soluong_12t,
        c.soluong_6t
      from doanhso12t b
      LEFT JOIN doanhso6t c on c.makhdms = b.makhdms
    ),
    doanhthu as (
      with data_doanhthu as (
        select
          custid,
          sotien_da_thanhtoan as DebConfirmAmtRelease,
          orderdate
        from `spatial-vision-343005.staging_temp.d_rawdata_debt_detail`
        where date_diff(date((select * from `staging.d_current_table`)), cast(orderdate as date), month) <= 12
      ),
      doanhthu_6t as (
        select custid, sum(DebConfirmAmtRelease) as doanhthu_6t
        from data_doanhthu
        where date_diff(date((select * from `staging.d_current_table`)), cast(orderdate as date), month) <= 6
        group by 1
      ),
      doanhthu_12t as (
        select custid, sum(DebConfirmAmtRelease) as doanhthu_12t
        from data_doanhthu
        group by 1
      ),
      result_doanhthu as (
        select a.*, b.doanhthu_6t
        from doanhthu_12t a
        LEFT JOIN doanhthu_6t b on a.custid = b.custid
      )
      select
        custid,
        sum(doanhthu_12t) as doanhthu_12t,
        sum(doanhthu_6t) as doanhthu_6t
      from result_doanhthu
      group by 1
    ),
    max_thoigianno as (
      SELECT
        custid,
        max(thoigian_no) as max_thoigian_no,
        max(thoigian_noqh) as max_thoigian_nqh,
        max(thoigian_noxau) as max_thoigian_noxau,
        min(date(dateoforder)) as min_ngaychungtu,
        min(thoi_diem_no_vang) as thoi_diem_no_vang,
        min(thoi_diem_no_do) as thoi_diem_no_do,
        min(thoi_diem_no_den) as thoi_diem_no_den
      from data_debt_ins2_1
      GROUP BY 1
    ),
    temp_f_sales1 as (
      SELECT distinct
        branchid,
        custid,
        ordernbr,
        date(ngayduyetdon) as ngaytaodon,
        status_pda_so,
        status_iv
      FROM `spatial-vision-343005.warehouse.f_leadtime_new_detail1`
      WHERE ngaytaodon >= '2022-04-01'
      and status_pda_so in ('Đã duyệt đơn hàng')
      and ordernbr_co <> 'Hủy HĐ'
    ),
    temp_f_sales2 as (
      SELECT distinct
        branchid,
        custid,
        ordernbr,
        date(ngaytaodon) as ngaytaodon,
        status_pda_so,
        status_iv
      FROM `spatial-vision-343005.warehouse.f_leadtime_new_detail1`
      WHERE ngaytaodon >= '2022-04-01'
      and status_pda_so in ('Chờ xử lý duyệt đơn hàng', 'Đơn hàng tạm')
      and trangthaidon = 'Tạo mới'
    ),
    sodon_tao_ngaytoihan as (
      select
        custid,
        count(ordernbr) as soluong_dh,
        date(max(ngaytaodon)) as phatsinh_dontao
      from temp_f_sales2
      group by 1
    ),
    mapping_ngaytoihan_no as (
      select
        a.*,
        b.phanloai_vungno as vungno_kh
      from max_thoigianno a
      LEFT JOIN (
        SELECT custid, MAX(phanloai_vungno) as phanloai_vungno
        FROM data_debt_ins2_1
        GROUP BY 1
      ) b on a.custid = b.custid
      where b.phanloai_vungno > 1
    ),
    sodon_phatsinh_ngaytoihan as (
      select
        a.vungno_kh,
        a.custid,
        count(b.ordernbr) as soluong_dh_novang,
        date(max(b.ngaytaodon)) as phatsinhdoncuoi_novang,
        count(c.ordernbr) as soluong_dh_nodo,
        date(max(c.ngaytaodon)) as phatsinhdoncuoi_nodo,
        count(d.ordernbr) as soluong_dh_noden,
        date(max(d.ngaytaodon)) as phatsinhdoncuoi_noden
      from mapping_ngaytoihan_no a
      LEFT JOIN temp_f_sales1 b on a.custid = b.custid and a.vungno_kh = 2 and a.thoi_diem_no_vang <= date(b.ngaytaodon)
      LEFT JOIN temp_f_sales1 c on a.custid = c.custid and a.vungno_kh = 3 and a.thoi_diem_no_do <= date(c.ngaytaodon)
      LEFT JOIN temp_f_sales1 d on a.custid = d.custid and a.vungno_kh = 4 and a.thoi_diem_no_den <= date(d.ngaytaodon)
      group by a.vungno_kh, a.custid
    ),
    phanloai_nokh1 as (
      SELECT
        a.* except(vungno_kh, phanloai_vungno),
        Case when a.phanloai_vungno = 1 then 'Nợ xanh'
             when a.phanloai_vungno = 2 then 'Nợ vàng'
             when a.phanloai_vungno = 3 then 'Nợ đỏ'
             when a.phanloai_vungno = 4 then 'Nợ đen'
             else 'Nợ xanh'
        end as vungno_kh,
        c.max_thoigian_no as ngay_dh_xa_nhat,
        c.max_thoigian_nqh,
        c.min_ngaychungtu as min_ngaydatdon,
        Case when d.soluong_6t is null then 0 else soluong_6t end as soluong_6t,
        Case when d.soluong_12t is null then 0 else soluong_12t end as soluong_12t,
        -- Cảnh báo nhóm KH nợ xấu --
        Case
          -- INS --
          when c.max_thoigian_noxau >= 365 and channel = 'INS' and (soluong_12t = 0 or soluong_12t is null) and (e.doanhthu_12t = 0 or e.doanhthu_12t is null) then 'N1 >=365 ngày & Không PS Dso,Dthu 12 tháng'
          when c.max_thoigian_noxau >= 365 and channel = 'INS' and (soluong_6t = 0 or soluong_6t is null) and (e.doanhthu_6t = 0 or e.doanhthu_6t is null) then 'N2 >=365 ngày & Không PS Dso,Dthu 6 tháng'
          when sum(a.no_xau) over (partition by a.custid) > 0 and c.max_thoigian_noxau >= 365 and channel = 'INS' then 'N3_NX >=365 ngày'
          when sum(a.no_xau) over (partition by a.custid) >= 300000000 and c.max_thoigian_noxau < 365 and channel = 'INS' then 'N4_NX <365 ngày & NX >=300 triệu'
          when c.max_thoigian_noxau < 365 and channel = 'INS' and sum(a.no_xau) over (partition by a.custid) > 0 then 'N5_NX <365 ngày'

          -- CLC --
          when c.max_thoigian_noxau >= 180 and channel = 'CLC' and (soluong_12t = 0 or soluong_12t is null) and (e.doanhthu_12t = 0 or e.doanhthu_12t is null) then 'N1 >=180 ngày & Không PS Dso,Dthu 12 tháng'
          when c.max_thoigian_noxau >= 180 and channel = 'CLC' and (soluong_6t = 0 or soluong_6t is null) and (e.doanhthu_6t = 0 or e.doanhthu_6t is null) then 'N2 >=180 ngày & Không PS Dso,Dthu 6 tháng'
          when sum(a.no_xau) over (partition by a.custid) > 0 and c.max_thoigian_noxau >= 180 and channel = 'CLC' then 'N3_NX >=180 ngày'
          when sum(a.no_xau) over (partition by a.custid) >= 150000000 and c.max_thoigian_noxau < 180 and channel = 'CLC' then 'N4_NX <180 ngày & NX >=150 triệu'
          when c.max_thoigian_noxau < 180 and channel = 'CLC' and sum(a.no_xau) over (partition by a.custid) > 0 then 'N5_NX <180 ngày'

          -- PCL --
          when sum(a.no_xau) over (partition by a.custid) > 0 and channel = 'PCL' then 'N1_Có nợ xấu'
          when sum(a.no_vang) over (partition by a.custid) > 0 and channel = 'PCL' then 'N2_Có nợ vàng'
          when sum(a.no_vang) over (partition by a.custid) <= 0 and sum(a.no_xau) over (partition by a.custid) <= 0 and channel = 'PCL' then 'Không có nợ quá hạn'
          when sum(a.no_xau) over (partition by a.custid) <= 0 then 'Không có nợ xấu'
          else null
        end as canhbao_noxau,
        c.thoi_diem_no_den as ngaytoihan_noden_kh,
        c.thoi_diem_no_do as ngaytoihan_nodo_kh
      from data_debt_ins2_1 a
      LEFT JOIN max_thoigianno c on a.custid = c.custid
      LEFT JOIN doanhso d on d.makhdms = a.custid
      LEFT JOIN doanhthu e on e.custid = a.custid
    ),
    result_1 as (
      SELECT
        A.* except(dateoforder, phanloaino, shoptype, so_du_chungtu),
        so_du_chungtu as tiennocongty,
        phanloaino as phanloai_no,
        shoptype as kenhphu,
        dateoforder as ngaydatdon,
        dateoforder as ngaychungtu,
        Case
          -- Nợ xanh giao bình thường --
          when d.vungno_kh is null or d.vungno_kh not in (2, 3, 4) then 'Giao bình thường'

          when d.vungno_kh in (1, 2) and a.shoptype in ('INS1', 'INS2', 'INS3', 'INS') then 'Giao bình thường'
          when d.vungno_kh = 4 and a.shoptype = 'INS1' and d.soluong_dh_noden = 1 then 'Ngưng giao hàng - Đã duyệt 1 đơn, ngày phát sinh cuối: ' || d.phatsinhdoncuoi_noden || ')'
          when d.vungno_kh = 4 and a.shoptype = 'INS1' and d.soluong_dh_noden > 1 then 'Ngưng giao hàng - Đã duyệt hơn 1 đơn, ngày phát sinh cuối: ' || d.phatsinhdoncuoi_noden || ')'
          when d.vungno_kh = 4 and a.shoptype = 'INS1' then 'Giao 1 đơn (DS<= DS bình quân 6 tháng gần nhất)'
          when d.vungno_kh = 3 and a.shoptype = 'INS1' then 'Giao bình thường'

          when d.vungno_kh = 4 and a.shoptype = 'INS2' then 'Ngưng giao hàng'
          when d.vungno_kh = 3 and a.shoptype = 'INS2' and d.soluong_dh_nodo = 0 then 'Giao 2 đơn (INS2 <=200tr,CLC2 <=100tr)'
          when d.vungno_kh = 3 and a.shoptype = 'INS2' and d.soluong_dh_nodo = 1 then 'Giao 1 đơn (INS2 <=200tr,CLC2 <=100tr) - Đã duyệt 1 đơn, ngày phát sinh cuối: ' || d.phatsinhdoncuoi_nodo
          when d.vungno_kh = 3 and a.shoptype = 'INS2' and d.soluong_dh_nodo = 2 then 'Ngưng giao hàng - Đã duyệt 2 đơn, ngày phát sinh cuối: ' || d.phatsinhdoncuoi_nodo
          when d.vungno_kh = 3 and a.shoptype = 'INS2' and d.soluong_dh_nodo > 2 then 'Ngưng giao hàng - Đã duyệt hơn 2 đơn, ngày phát sinh cuối:' || d.phatsinhdoncuoi_nodo

          when d.vungno_kh = 4 and a.shoptype = 'INS3' then 'Ngưng giao hàng'
          when d.vungno_kh = 3 and a.shoptype = 'INS3' and d.soluong_dh_nodo = 0 then 'Giao 1 đơn (DS<= DS bình quân 6 tháng gần nhất)'
          when d.vungno_kh = 3 and a.shoptype = 'INS3' and d.soluong_dh_nodo = 1 then 'Ngưng giao hàng - Đã duyệt 1 đơn, ngày phát sinh cuối: ' || d.phatsinhdoncuoi_nodo
          when d.vungno_kh = 3 and a.shoptype = 'INS3' and d.soluong_dh_nodo > 1 then 'Ngưng giao hàng - Đã duyệt hơn 1 đơn, ngày phát sinh cuối: ' || d.phatsinhdoncuoi_nodo

          -- Kênh phụ ('CLC3','CLC4') --
          when d.vungno_kh in (2) and a.shoptype in ('CLC3', 'CLC4') and d.soluong_dh_novang > 0 then 'Ngưng giao hàng - Đã duyệt ' || d.soluong_dh_novang || ' đơn,ngày phát sinh cuối:' || d.phatsinhdoncuoi_novang
          when d.vungno_kh in (2) and a.shoptype in ('CLC3', 'CLC4') and (d.soluong_dh_novang is null or d.soluong_dh_novang = 0) then 'Giao 1 đơn (DS<= DS bình quân 6 tháng gần nhất)'
          when d.vungno_kh in (3) and a.shoptype in ('CLC3', 'CLC4') and d.soluong_dh_nodo > 0 then 'Ngưng giao hàng - Đã duyệt ' || d.soluong_dh_nodo || ' đơn,ngày phát sinh cuối:' || d.phatsinhdoncuoi_nodo
          when d.vungno_kh in (3) and a.shoptype in ('CLC3', 'CLC4') and (d.soluong_dh_nodo is null or d.soluong_dh_nodo = 0) then 'Ngưng giao hàng'
          when d.vungno_kh in (4) and a.shoptype in ('CLC3', 'CLC4') and d.soluong_dh_noden > 0 then 'Ngưng giao hàng - Đã duyệt ' || d.soluong_dh_noden || ' đơn,ngày phát sinh cuối:' || d.phatsinhdoncuoi_noden
          when d.vungno_kh in (4) and a.shoptype in ('CLC3', 'CLC4') and (d.soluong_dh_noden is null or d.soluong_dh_noden = 0) then 'Ngưng giao hàng'

          -- Kênh phụ ('CLC1') --
          when d.vungno_kh in (2, 3) and a.shoptype in ('CLC1') then 'Giao bình thường'
          when d.vungno_kh in (4) and a.shoptype in ('CLC1') and d.soluong_dh_noden > 0 then 'Ngưng giao hàng - Đã duyệt ' || d.soluong_dh_noden || ' đơn,ngày phát sinh cuối:' || d.phatsinhdoncuoi_noden
          when d.vungno_kh in (4) and a.shoptype in ('CLC1') and (d.soluong_dh_noden is null or d.soluong_dh_noden = 0) then 'Giao 1 đơn (DS<= DS bình quân 6 tháng gần nhất)'

          -- Kênh phụ ('CLC2') --
          when d.vungno_kh in (2) and a.shoptype in ('CLC2') then 'Giao bình thường'
          when d.vungno_kh in (3) and a.shoptype in ('CLC2') and d.soluong_dh_nodo = 1 then 'Giao 1 đơn (INS2 <=200tr,CLC2 <=100tr) - Đã duyệt ' || d.soluong_dh_nodo || ' đơn,ngày phát sinh cuối:' || d.phatsinhdoncuoi_nodo
          when d.vungno_kh in (3) and a.shoptype in ('CLC2') and d.soluong_dh_nodo > 1 then 'Ngưng giao hàng - Đã duyệt ' || d.soluong_dh_nodo || ' đơn,ngày phát sinh cuối:' || d.phatsinhdoncuoi_nodo
          when d.vungno_kh in (3) and a.shoptype in ('CLC2') and (d.soluong_dh_nodo is null or d.soluong_dh_nodo = 0) then 'Giao 2 đơn (INS2 <=200tr,CLC2 <=100tr)'
          when d.vungno_kh in (4) and a.shoptype in ('CLC2') and d.soluong_dh_noden > 0 then 'Ngưng giao hàng - Đã duyệt ' || d.soluong_dh_noden || ' đơn,ngày phát sinh cuối:' || d.phatsinhdoncuoi_noden
          when d.vungno_kh in (4) and a.shoptype in ('CLC2') and (d.soluong_dh_noden is null or d.soluong_dh_noden = 0) then 'Ngưng giao hàng'

          -- Chuyển đổi kênh năm 2023 --
          when d.vungno_kh is null or d.vungno_kh not in (2, 3, 4) then 'Giao bình thường'
          when d.vungno_kh in (2, 3, 4) and a.shoptype in ('PMC', 'SI', 'CTD', 'PCL', 'SI23') and d.soluong_dh_novang > 0 then 'Ngưng giao hàng - Đã duyệt ' || d.soluong_dh_novang || ' đơn,ngày phát sinh cuối:' || d.phatsinhdoncuoi_novang
          when d.vungno_kh in (2, 3, 4) and a.shoptype in ('PMC', 'SI', 'CTD', 'PCL', 'SI23') and (d.soluong_dh_novang is null or d.soluong_dh_novang = 0) then 'Ngưng giao hàng'

        end as duyet_donhang
      from phanloai_nokh1 a
      LEFT JOIN sodon_phatsinh_ngaytoihan d on a.custid = d.custid
    ),
    result_2 as (
      select
        a.*,
        Case when duyet_donhang like '%Ngưng giao hàng%' and b.custid is not null then 'Đang có ' || b.soluong_dh || ' đơn tạo mới,ngày phát sinh:' || b.phatsinh_dontao
             else null
        end as canhbao_duyetdon
      from result_1 a
      LEFT JOIN sodon_tao_ngaytoihan b on a.custid = b.custid
    )

    select * from result_2
  );

  Create or replace table `warehouse.f_congno_hcp_crs`
  copy `f_congno_hcp_crs_temp`;
END;
