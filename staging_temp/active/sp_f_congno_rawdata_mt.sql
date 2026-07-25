CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_congno_rawdata_mt()
BEGIN


TRUNCATE TABLE staging_temp.f_congno_rawdata_mt_temp;
INSERT INTO staging_temp.f_congno_rawdata_mt_temp
(


--Create or replace table staging_temp.f_congno_rawdata_mt_temp 
--as
--
with leadtime1 as
(
  select 
  branchid,
  ordernbr,
  status,
  delivery_date, 
  lupd_datetime,
  slsperid, 
  row_number() over (partition by concat(branchid,ordernbr) order by sequence desc) as loc 
  from `spatial-vision-343005.staging.sync_dms_dv`
)
,

leadtime as
(
  select *
  from leadtime1
  where loc = 1
)

,
--- lấy ra khách hàng còn nợ
bang_no1 as
(
  SELECT 
  CustId,
  sum(so_du_chungtu) as so_du_chungtu 
  FROM `spatial-vision-343005.staging_temp.d_rawdata_debt` 
  group by 1
  having so_du_chungtu != 0 
)
,
--- lấy ra hóa đơn còn nợ
bang_no2 as 
(
  SELECT 
  a.CustId,
  concat (a.InvcNote,a.InvcNbr) as noi_hd, 
  sum(a.so_du_chungtu) as so_du_chungtu 

  FROM `spatial-vision-343005.staging_temp.d_rawdata_debt` a
  join bang_no1 b on a.CustId = b.CustId
  -- WHERE b.so_du_chungtu != 0 
  group by 1,2
  having so_du_chungtu != 0 
)
,

ten_nvbh as
(
  SELECT 
  a.ordernbr, 
  a.branchid, 
  a.slsperid,
  b.tencvbh
  FROM `spatial-vision-343005.staging.sync_dms_pda_sod` a
  left join `staging.d_users` b on a.slsperid = b.manv
  group by 1,2,3,4
)
,

--- CÔNG NỢ
bang_no as 
(  
  SELECT 
    a.branchid,
    a.Ordnbr,
    a.custid, 
    a.custname,
    a.slsperid,
    a.tencvbh,
    a.tenquanlytt,
    b.tenquanlykhuvuc,
    b.tenquanlyvung,
    a.dateoforder as ngaydatdon,
    a.InvcNbr,
    a.channel,
    a.shoptype,
    a.statedescr,
    ifnull(a.pubcustid,'TỔNG HỢP KH SỈ CÓ NỢ') as pubcustid,
    ifnull(a.pubcustname,'TỔNG HỢP KH SỈ CÓ NỢ') as pubcustname,
    a.DocType,
    a.terms,
    a.day_terms,
    a.terms_name as thoihanthanhtoan,
    
    a.paymentsform_hien_tai as paymentsform,
    a.hcotypeid,
    a.so_du_chungtu as so_du_chungtu,
    a.sotien_da_thanhtoan,
    a.duedate,
    a.inserted_at as inserted_at,
    concat (a.InvcNote,a.InvcNbr) as noi_hd,
    e.batnbr,
    case when f.slsperid is null then a.slsperid else f.slsperid end as ma_nvgh,
    case when g.tencvbh is null then b.tencvbh else g.tencvbh end as nvgh,
    case when g.supid is null then b.supid else g.supid end as manv_sup_gh,
    case when g.tenquanlytt is null then b.tenquanlytt else g.tenquanlytt end as sup_gh,
    case when g.asm is null then b.asm else g.asm end as manv_mgr_gh,
    case when g.tenquanlykhuvuc is null then b.tenquanlykhuvuc else g.tenquanlykhuvuc end as mgr_gh,
    case when g.rsmid is null then b.rsmid else g.rsmid end as manv_dir_gh,
    case when g.tenquanlyvung is null then b.tenquanlyvung else g.tenquanlyvung end as dir_gh,
    h.status,
    h.delivery_date as ngaygiaohang,
    h.lupd_datetime as thoigiancapnhattrangthai,
    i.slsperid as ma_nvbh,
    i.tencvbh as ten_nvbh,
    j.tram,

    case 
    when h.status = 'A' then 'Đã xác nhận'
    when h.status = 'C' then 'Đã giao hàng'
    when h.status = 'D' then 'KH không nhận'
    when h.status = 'H' then 'Chưa xác nhận'
    when h.status = 'R' then 'Từ chối giao hàng'
    when h.status = 'E' then 'Không tiếp tục giao hàng' 
    when h.status is null then 'Chưa xác nhận' else h.status end as trangthaigiaohang,


    case 

      when a.channel ='MT' THEN 'MT'
      else 'CS' end as phutrachno,

    case 
        when 
        (a.terms not in ('03','01','Gối Đầu 30 Pha Nam') and date(a.duedate) <= current_date())
      or
        (h.status = ('C') and a.terms in ('03','01','Gối Đầu 30 Pha Nam') and (date_add (date (h.delivery_date), interval 1 day)) <= current_date())
      or
        (h.status not in ('C') and a.terms in ('01','Gối Đầu 30 Pha Nam') and (date_add(date(a.dateoforder), interval 1 day)) <= current_date())
      or 
        (h.status not in ('C') and a.terms in ('03','Gối Đầu 30 Pha Nam') and (date_add(date(a.dateoforder), interval 3 day)) <= current_date()) 
      then 'Nợ đến hạn' else 'Chưa đến hạn' end as no_toi_han,
    
    FROM `spatial-vision-343005.staging_temp.d_rawdata_debt` a
    LEFT JOIN `staging.d_users` b on a.slsperid = b.manv
    JOIN bang_no2 d on concat (a.InvcNote,a.InvcNbr) = d.noi_hd
    LEFT JOIN `spatial-vision-343005.staging.sync_dms_ibd` e on a.BranchID = e.branchid and a.Ordnbr = e.ordernbr
    LEFT JOIN `spatial-vision-343005.staging.sync_dms_ib` f on e.branchid = f.branchid and e.batnbr =  f.batnbr
    LEFT JOIN `staging.d_users` g on g.manv = f.slsperid
    LEFT JOIN leadtime h on a.Ordnbr = h.ordernbr and a.BranchID = h.branchid 
    LEFT JOIN ten_nvbh i on a.BranchID = i.branchid and a.Ordnbr = i.ordernbr
    LEFT JOIN `spatial-vision-343005.staging.d_tinh`  j on a.statedescr = j.tinh
    where a.channel ='MT' and DocType = 'IN' 
    -- and c.pubcustid ='007619'

    )
,
  result0 as
  (
    select 
    aa.*,
    Case 
    when thoihanthanhtoan like '%Thu tiền ngay%' and tram ='Trong CN' then 
 date_add(date(duedate),interval 1 day)   
    when thoihanthanhtoan like '%Thu tiền ngay%' and tram ='Trạm' then 
 date_add(date(duedate),interval 3 day)

     when thoihanthanhtoan in ('Gối 1 Đơn Hàng (trong 30 ngày)') and tram ='Trong CN' then 
 date_add(date(duedate),interval 2 day) 
    when thoihanthanhtoan in ('Gối 1 Đơn Hàng (trong 30 ngày)') and tram ='Trạm' then 
 date_add(date(duedate),interval 4 day) 

    when day_terms <=15
     and tram ='Trong CN' then 
 date_add(date(duedate),interval 2 day) 
    when day_terms <=15
     and tram ='Trạm' then 
 date_add(date(duedate),interval 4 day) 
    
    when day_terms > 15
     and tram ='Trong CN' then 
 date_add(date(duedate),interval 2 day) 
     when day_terms > 15
     and tram ='Trạm' then 
 date_add(date(duedate),interval 4 day) 
 
 
  else  null

 end as thoi_diem_no_vang,


 Case 
    when thoihanthanhtoan like '%Thu tiền ngay%' and tram ='Trong CN' then 
 date_add(date(duedate),interval 6 day)   
    when thoihanthanhtoan like '%Thu tiền ngay%' and tram ='Trạm' then 
 date_add(date(duedate),interval 8 day)

     when thoihanthanhtoan in ('Gối 1 Đơn Hàng (trong 30 ngày)') and tram ='Trong CN' then 
 date_add(date(duedate),interval 7 day) 
    when thoihanthanhtoan in ('Gối 1 Đơn Hàng (trong 30 ngày)') and tram ='Trạm' then 
 date_add(date(duedate),interval 9 day) 

    when day_terms <= 15
     and tram ='Trong CN' then 
 date_add(date(duedate),interval 17 day) 
    when day_terms <= 15
     and tram ='Trạm' then 
 date_add(date(duedate),interval 19 day) 
    
    when day_terms > 15
     and tram ='Trong CN' then 
 date_add(date(duedate),interval 32 day) 
     when day_terms > 15
     and tram ='Trạm' then 
 date_add(date(duedate),interval 34 day) 
 
  else  null

 end as thoi_diem_no_do,
 Case 
    when thoihanthanhtoan like '%Thu tiền ngay%' and tram ='Trong CN' then 
 date_add(date(duedate),interval 10 day)   
    when thoihanthanhtoan like '%Thu tiền ngay%' and tram ='Trạm' then 
 date_add(date(duedate),interval 12 day)

     when thoihanthanhtoan in ('Gối 1 Đơn Hàng (trong 30 ngày)') and tram ='Trong CN' then 
 date_add(date(duedate),interval 11 day) 
    when thoihanthanhtoan in ('Gối 1 Đơn Hàng (trong 30 ngày)') and tram ='Trạm' then 
 date_add(date(duedate),interval 13 day) 

    when day_terms <= 15
     and tram ='Trong CN' then 
 date_add(date(duedate),interval 32 day) 
    when day_terms <= 15
     and tram ='Trạm' then 
 date_add(date(duedate),interval 34 day) 
    
    when day_terms > 15
     and tram ='Trong CN' then 
 date_add(date(duedate),interval 62 day) 
     when day_terms > 15
     and tram ='Trạm' then 
 date_add(date(duedate),interval 64 day) 
 
  else  null

 end as thoi_diem_no_den,
  Case when pubcustid ='007619' and extract(dayofweek from ngaydatdon) = 1 then ngaydatdon + interval 5 day
       when pubcustid ='007619' and extract(dayofweek from ngaydatdon) = 2 then ngaydatdon + interval 4 day
       when pubcustid ='007619' and extract(dayofweek from ngaydatdon) = 3 then ngaydatdon + interval 3 day
       when pubcustid ='007619' and extract(dayofweek from ngaydatdon) = 4 then ngaydatdon + interval 2 day
       when pubcustid ='007619' and extract(dayofweek from ngaydatdon) = 5 then ngaydatdon + interval 1 day
       when pubcustid ='007619' and extract(dayofweek from ngaydatdon) = 6 then ngaydatdon + interval 0 day
       when pubcustid ='007619' and extract(dayofweek from ngaydatdon) = 7 then ngaydatdon + interval 6 day
  else null end as ngay_chung_tu_chuyen_doi_win,

  Case when pubcustid ='007619' and extract(dayofweek from ngaydatdon) = 1 then ngaydatdon + interval 5 day + interval 45 day
       when pubcustid ='007619' and extract(dayofweek from ngaydatdon) = 2 then ngaydatdon + interval 4 day + interval 45 day
       when pubcustid ='007619' and extract(dayofweek from ngaydatdon) = 3 then ngaydatdon + interval 3 day + interval 45 day
       when pubcustid ='007619' and extract(dayofweek from ngaydatdon) = 4 then ngaydatdon + interval 2 day + interval 45 day
       when pubcustid ='007619' and extract(dayofweek from ngaydatdon) = 5 then ngaydatdon + interval 1 day + interval 45 day
       when pubcustid ='007619' and extract(dayofweek from ngaydatdon) = 6 then ngaydatdon + interval 0 day + interval 45 day
       when pubcustid ='007619' and extract(dayofweek from ngaydatdon) = 7 then ngaydatdon + interval 6 day + interval 45 day
  else null end as ngay_den_han45_ngay_win,

  Case when pubcustid ='007619' and extract(dayofweek from ngaydatdon) = 1 then ngaydatdon + interval 5 day + interval 55 day
       when pubcustid ='007619' and extract(dayofweek from ngaydatdon) = 2 then ngaydatdon + interval 4 day + interval 55 day
       when pubcustid ='007619' and extract(dayofweek from ngaydatdon) = 3 then ngaydatdon + interval 3 day + interval 55 day
       when pubcustid ='007619' and extract(dayofweek from ngaydatdon) = 4 then ngaydatdon + interval 2 day + interval 55 day
       when pubcustid ='007619' and extract(dayofweek from ngaydatdon) = 5 then ngaydatdon + interval 1 day + interval 55 day
       when pubcustid ='007619' and extract(dayofweek from ngaydatdon) = 6 then ngaydatdon + interval 0 day + interval 55 day
       when pubcustid ='007619' and extract(dayofweek from ngaydatdon) = 7 then ngaydatdon + interval 6 day + interval 55 day
  else null end as ngay_den_han55_ngay_win
    FROM bang_no aa 
  )
  ,
  result1 as (
  select 
  *,
  Case 
      when extract(day from ngay_den_han45_ngay_win) <= 15  then date(extract(year from ngay_den_han45_ngay_win),extract(month from ngay_den_han45_ngay_win),15)

      -- when extract(day from ngay_den_han45_ngay_win) > 25 and extract(month from ngay_den_han45_ngay_win) = 12  then date(extract(year from ngay_den_han45_ngay_win) + 1,1,15)

      when extract(day from ngay_den_han45_ngay_win) > 25   then date_trunc(date(ngay_den_han45_ngay_win),month) + interval 1 month + interval 14 day

      when extract(day from ngay_den_han45_ngay_win) > 15 and extract(day from ngay_den_han45_ngay_win) <=25  then date(extract(year from ngay_den_han45_ngay_win),extract(month from ngay_den_han45_ngay_win),25)
  else null end as ngay_den_han_convert_15_25,

  Case when pubcustid ='008152' and  extract(day from ngaydatdon) <=15 then date(extract(year from ngaydatdon),extract(month from ngaydatdon),25)
      --  when pubcustid ='008152' and  extract(day from ngaydatdon) > 15  and extract(month from ngaydatdon) = 12 then date(extract(year from ngaydatdon) + 1,1,15)
       when pubcustid ='008152' and  extract(day from ngaydatdon) > 15 then date_trunc(date(ngaydatdon),month) + interval 1 month + interval 14 day
  else null end as ngay_den_han_sen_do,
  Case 
    -- when doctype ='CM' then 'Nợ xanh' 
    when current_date("+7")  
  >= thoi_diem_no_den and so_du_chungtu  > 0 then 'Nợ đen'
      when current_date("+7")
    < thoi_diem_no_den and so_du_chungtu  > 0  and current_date("+7")
  >= thoi_diem_no_do  then 'Nợ đỏ'
      when current_date("+7")
    < thoi_diem_no_do and so_du_chungtu  > 0  and current_date("+7")
    >= thoi_diem_no_vang  then 'Nợ vàng'
      when current_date("+7")
    < thoi_diem_no_vang and so_du_chungtu  > 0  then 'Nợ xanh'
  else null end as phanloaino,
  
  from result0
  )

  select 
  r1.*,
  remark,
  -- if(ngay_den_han_convert_15_25 >= ngay_den_han55_ngay_win,ngay_den_han55_ngay_win,ngay_den_han_convert_15_25) 
  
  ngay_den_han_convert_15_25 as ngay_den_han_win_final,
  Case when pubcustid ='007619' and ngay_den_han_convert_15_25 <= current_date("+7") then 'Nợ đến hạn'
       when pubcustid ='007619' then 'Chưa đến hạn'
       else null end as no_toi_han_win,
  Case when pubcustid ='008152' and ngay_den_han_sen_do <= current_date("+7") then 'Nợ đến hạn'
       when pubcustid ='008152' then 'Chưa đến hạn'
       else null end as no_toi_han_sendo,
  Case when  phanloaino in('Nợ vàng','Nợ đỏ','Nợ đen') then date_diff(current_date("+7"), date(thoi_diem_no_vang),day)
      else 0 end as thoigian_noqh, 
  Case when  phanloaino in('Nợ vàng','Nợ đỏ','Nợ đen') then so_du_chungtu
      else 0 end as so_du_noqh, 
  from result1 r1
  LEFT JOIN `spatial-vision-343005.staging.sync_dms_pda_so` rmk ON r1.Ordnbr = rmk.ordernbr AND r1.branchid = rmk.branchid
-- where custid not in ('007447','007213','007569','007568','010550')


  
)
;

Create or replace table `warehouse.f_congno_rawdata_mt`

copy `staging_temp.f_congno_rawdata_mt_temp`;


End;