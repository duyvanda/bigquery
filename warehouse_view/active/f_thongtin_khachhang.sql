CREATE VIEW `spatial-vision-343005.warehouse.f_thongtin_khachhang`
AS with tuyen_dms_moinhat as (
    with data_tuyen as (
        SELECT
            *except(routetype),
            Case
                when routetype in ('B', 'D') then 1
                else 2
            end as routetype,
        FROM
            `spatial-vision-343005.staging.sync_dms_srm`
    )
    select
        *
    from
        data_tuyen 
        qualify row_number() over (
            partition by custid
            order by
                routetype asc,
                crtd_datetime desc
        ) = 1
),

phan_loai as (
select 
t1.branchid,
t1.branchname,
t1.custid,
t1.refcustid,
t1.pubcustid,
t1.pubcustname,
t1.custname,
CONCAT(t1.custid,"|",t1.custname) as cc_id_name,
t1.address,
t1.wardname,
t1.districtdescr,
t1.statedescr,
t1.territorydescr,
t1.custidinvoice,
t1.custnameinvoice,
t1.citizenid,
t1.phoneinvoice,
-- t1.emailinvoice,
concat("https://ds.merapgroup.com/reportscreen/21?params=%257B%22df25%22%3A%22include%2525EE%252580%2525800%2525EE%252580%252580IN%2525EE%252580%252580MR0000%22%2C%22df26%22%3A%22include%2525EE%252580%2525800%2525EE%252580%252580IN%2525EE%252580%252580",t1.custid,"%22%257D") as emailinvoice,
-- https://www.urlencoder.org/
-- t1.addr1,
t1.newaddress as addr1,
t1.taxregnbr,
t1.channel,
t1.shoptype,
t1.shoptypedescr,
t1.phone,
t1.hcotypename,
t1.hcotypeid,
t1.classid,
t1.paymentsform,
t1.terms,
t1.active,
t1.inactive,
t1.autogenorder,
t1.attn,
t1.businessscope,
t1.businessname,
Case when legaldate='1900-01-01' then null else date(t1.legaldate) end as legaldate,
t1.taxdeclaration,
t1.vendorid,
t1.market,
t1.oricustid,
t1.billmarket,
t1.establishdate,
t1.establishdate2,
t1.stocksales,
t1.isagency,
t1.agencyid,
t1.agencyname,
t1.salessystemdescr,
t1.checkterm,
t1.shoperid,
t1.streetname,
t1.channeldescr,
t1.hcoid,
t1.legalname,
t1.chargereceive,
t1.chargepayment,
t1.chargephar,
t1.generalcustid,
t1.batchexpform,
t1.lat,
t1.lng,
t1.crtd_user,
t1.crtd_datetime,
t1.inserted_at,
t1.gtype,
t1.shortterritorydescr,
t1.legaldate as thoihanhieulucgdpgpp, 
t1.classid as phanhanghco, 
t4.startdate, 
t4.enddate,
Case 
  when stocksales in ('Ngừng hoạt động và đã đóng MST','Ngừng hoạt động nhưng chưa hoàn thành thủ tục đóng MST','Tạm nghỉ kinh doanh có thời hạn') then 'Ngưng bán'
  else 'Bán theo HSPL' end as check_tinh_trang_ban_hang_theo_mst,
Case 
  when market = '08' or market like '%KH bán%' then 'Không xét GDP'
  when t1.shoptype in ('CLC1','CLC2') then 'Không xét GDP'
  when t1.channel in ('INS','NB','OTH_LAB') then 'Không xét GDP'
  when hcotypeid in ('CSDYDL','NTXQPK','PKNK') then 'Không xét GDP'
else 'Có xét GDP' end as phan_loai_xet_gdp, 
t2.slsperid,
t3.supid
from `staging.d_master_khachhang` t1
left join tuyen_dms_moinhat t4 on t1.custid = t4.custid
left join `warehouse.view_thongtin_tuyen_banhang` t2 on t1.custid = t2.custid
left join `staging.d_users` t3 on t2.slsperid = t3.manv

where ifnull(t1.channel, 'none') != 'NB'
)

select a.*,
Case 
  when phan_loai_xet_gdp ='Có xét GDP' and (thoihanhieulucgdpgpp is null or thoihanhieulucgdpgpp ='1900-01-01') then 'Chưa có GPP'
  when phan_loai_xet_gdp ='Có xét GDP' and date_diff(date(thoihanhieulucgdpgpp), current_date("+7"),day) >= 0 then 'GDP còn hạn'
  when phan_loai_xet_gdp ='Có xét GDP' and date_diff(date(thoihanhieulucgdpgpp), current_date("+7"),day) >= -90 
        and date_diff(date(thoihanhieulucgdpgpp), current_date("+7"),day) < 0 then 'Hết hạn GDP < 90n - Được bán tiếp'
  when phan_loai_xet_gdp ='Có xét GDP' and date_diff(date(thoihanhieulucgdpgpp), current_date("+7"),day) >= -180 
        and date_diff(date(thoihanhieulucgdpgpp), current_date("+7"),day) < -90 then 'Hết hạn GDP < 180n - Cảnh báo'
  when phan_loai_xet_gdp ='Có xét GDP' and date_diff(date(thoihanhieulucgdpgpp), current_date("+7"),day) < -180  then 'Hết hạn GDP > 180n - Ngưng'

else 'Không xét GPP' end as tinh_trang_gdp,
from phan_loai a;