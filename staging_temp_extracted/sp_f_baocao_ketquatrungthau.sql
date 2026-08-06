-- ==========================================================================
-- Routine Name : sp_f_baocao_ketquatrungthau
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2025-05-06 08:17:00.157000+00:00
-- Last Altered : 2025-05-06 08:17:00.157000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_baocao_ketquatrungthau()
BEGIN

-- TRUNCATE TABLE staging_temp.f_baocao_ketquatrungthau_temp;
-- INSERT INTO `staging_temp.f_baocao_ketquatrungthau_temp`
Create or replace table `warehouse.sp_f_baocao_ketquatrungthau`
as

(

with qlkh_kh as
(
  select
    distinct makhachhang,
    acrm
  from `spatial-vision-343005.staging.d_manual_gs_trung_thau_theo_ql`
)
,
kh_theo_qdtt as
(
  select
    a.noticeid,
    -- ifnull(a.noticenbr,'') noticenbr,
    a.custid,
    b.custname,
    b.channel
  from `staging.d_oricontract` a
  left join `staging.d_master_khachhang` b on a.custid = b.custid
  qualify row_number() over (partition by noticeid order by a.crtd_datetime desc) =1

)
, distinct_note as

(
  SELECT distinct noticenbr, note  from `spatial-vision-343005.staging.d_contractor` where note is not null
)
, result as

(
  SELECT
    a.crtd_datetime,
    a.crtd_user,
    a.id,
    a.noticenbr,
    a.startdate,
    a.exprdate,
    case
    when lower(a.contractorid) like '%20%%' then 'Trực tiếp - 20%'
    when lower(a.contractorid) like '%kpb%' then 'Áp thầu_KPB'
    when lower(a.contractorid) like '%cđt%' then 'CĐT Rút gọn'
    when lower(a.contractorid) like '%chỉ định thầu%' then 'CĐT Rút gọn'
    when lower(a.contractorid) like '%chị định thầu%' then 'CĐT Rút gọn'
    when lower(a.contractorid) like '%mua ngoài thầu%' then 'CĐT Rút gọn'
    when lower(a.contractorid) like '%chào hàng cạnh tranh%' then 'Chào hàng cạnh tranh'
    when lower(a.contractorid) like '%gián tiếp%' then 'Gián tiếp'
    when lower(a.contractorid) like '%mstt%' then 'MSTT'
    when lower(a.contractorid) like '%trực tiếp%' then 'Trực tiếp'
    when lower(a.contractorid) like '%rộng rãi%' then 'Trực tiếp'
    else a.contractorid
    END as contractorid,
    a.contractorname,
    a.projectname,
    a.year,
    a.unitcode,
    a.state,
    a.unittype,
    a.invtid,
    a.purchunit,
    a.contractprice,
    a.qty,
    a.totamt,
    a2.note,
    a.note as note_sp,
    a.tbmtcode,
    a.inserted_at,
    a1.custid,
    a1.custname,
    a1.channel,
    b.descr as tensanpham,
    e.tendonvitinhleviethoa,
    contractprice / (case when e.invtid ='EH126' THEN 20 ELSE e.donvitinhle end) as contractprice_le,
    qty * (case when e.invtid ='EH126' THEN 20 ELSE e.donvitinhle end) as qty_le,
    ifnull(a.investorname,d.custname) as investorname,
    ifnull(c.tinh,d.statedescr) as tinh,
    ifnull(c.khu_vuc,d.shortterritorydescr) as khuvuc,
    case when DATE(a.startdate) <= '2023-03-06' then 'PHA NAM'
        when ((DATE(a.startdate) >= '2023-03-07' and DATE(a.startdate) <= '2023-11-30') and trim(h.phaply) = 'PN') then 'PHA NAM'
        when ((DATE(a.startdate) >= '2023-03-07' and DATE(a.startdate) <= '2023-11-30') and trim(h.phaply) = 'MR') then 'MERAP'
        ELSE 'MERAP'
        END as phaply,
    case when ifnull(c.tinh,d.statedescr) in ('Hà Nam','Hà Tĩnh','Nam Định','Nghệ An','Ninh Bình','Thái Bình','Thanh Hóa') then	'Nguyễn Toàn'
        when ifnull(c.tinh,d.statedescr) in ('Bến Tre','Đồng Tháp','Long An','Tiền Giang','Trà Vinh','Vĩnh Long') then 'Hoàng Trung Thành'
        when ifnull(c.tinh,d.statedescr) in ('Bình Dương','Bình Phước','Đắk Nông','Tây Ninh')	then	'Lâm Văn Cảnh'
        when ifnull(c.tinh,d.statedescr) in ('Thành phố Hà Nội','Vĩnh Phúc')	then	'Lê Văn Tùng'
        when ifnull(c.tinh,d.statedescr) in ('Bà Rịa - Vũng Tàu','Lâm Đồng') then	'Mai Thị Thanh Phúc'
        when ifnull(c.tinh,d.statedescr) in ('Quảng Bình','Quảng Nam','Quảng Trị','Thành phố Đà Nẵng','Thừa Thiên - Huế','Thừa Thiên Huế') then	'Ngô Tiến Vũ'
        when ifnull(c.tinh,d.statedescr) in ('Bình Định','Đắk Lắk','Gia Lai','Kon Tum','Quảng Ngãi') then 'Nguyễn Hồng Hà'
        when ifnull(c.tinh,d.statedescr) in ('An Giang','Bạc Liêu','Cà Mau','Hậu Giang','Kiên Giang','Sóc Trăng','Thành phố Cần Thơ') then	'Nguyễn Ngọc Thiên Trang'
        when ifnull(c.tinh,d.statedescr) in ('Bắc Giang','Bắc Kạn','Bắc Ninh','Cao Bằng','Điện Biên','Hà Giang','Hải Dương','Hải Phòng','Hòa Bình','Hưng Yên','Lai Châu','Lạng Sơn','Lào Cai','Phú Thọ','Quảng Ninh','Sơn La','Thái Nguyên','Tuyên Quang','Yên Bái')	then	'Nguyễn Văn Đôn'
        when ifnull(c.tinh,d.statedescr) in ('Bình Thuận','Khánh Hòa','Ninh Thuận','Phú Yên') then	'Phan Thị Bình Khê'
        else f.acrm end as qlkv,
        b.phanloainhom
FROM `spatial-vision-343005.staging.d_contractor` a
LEFT JOIN kh_theo_qdtt a1 on a.id = a1.noticeid
LEFT JOIN distinct_note a2 on a.noticenbr = a2.noticenbr
left join `spatial-vision-343005.staging.d_dms_master_invtid` b on a.invtid = b.invtid
left join `spatial-vision-343005.staging.d_tinh` c on a.state = cast(stateid as string) and c.tinh != 'Thừa Thiên - Huế'
left join `spatial-vision-343005.staging.d_master_khachhang` d on a.unitcode = d.custid
left join `spatial-vision-343005.staging.d_dms_master_invtid` e on a.invtid = e.invtid
left join qlkh_kh f on a.unitcode = f.makhachhang
left join `spatial-vision-343005.staging.d_tinh` g on ifnull(c.tinh,d.statedescr) = g.tinh
left join `spatial-vision-343005.staging.chuanhoa_phaply_dmtt` h on g.tinhviethoa = trim(h.tinh) and a.noticenbr = trim(h.so_ttqd_trungthau)
)

select a.*,
case
when	qlkv='Lê Văn Tùng'	then	'MR1391'
when	qlkv='Nguyễn Toàn'	then	'MR1579'
when	qlkv='Nguyễn Văn Đôn'	then	'MR2355'
when	qlkv='Bùi Hữu Toàn'	then	'MR1681'
when	qlkv='Ngô Tiến Vũ'	then	'MR0123'
when	qlkv='Nguyễn Ngọc Thiên Trang'	then	'MR0683'
when	qlkv='Phan Thị Bình Khê'	then	'MR0055'
when	qlkv='Hoàng Trung Thành'	then	'MR1650'
when	qlkv='Lâm Văn Cảnh'	then	'MR0538'
when	qlkv='Mai Thị Thanh Phúc'	then	'MR0294'
when	qlkv='Nguyễn Thị Dung'	then	'MR0253'
when	qlkv='Vũ Mừng'	then	'MR1137'
when	qlkv='Nguyễn Hồng Hà'	then	'MR0992'
else null
end as supid
from result a

);

-- Create or replace table `warehouse.sp_f_baocao_ketquatrungthau`
-- copy `staging_temp.f_baocao_ketquatrungthau_temp`;
END;
