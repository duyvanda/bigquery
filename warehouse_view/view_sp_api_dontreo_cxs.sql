CREATE VIEW `spatial-vision-343005.warehouse.view_sp_api_dontreo_cxs`
AS with

loi_duyet_tudong as 
(
    SELECT branchid,ordernbr,case when errormessage is not null then 'Y' else 'N' end as is_err_duyet_tudong,errormessage
 FROM `spatial-vision-343005.staging.sync_dms_err_don_treo` 
 where errormessage not in ('tem.Byte[]') and errormessage is not null
 qualify row_number() over(partition by branchid,ordernbr order by errormessage) =1


),

mapping as (
    select
        distinct
        ifnull(a.branchid, b.branchid) as branchid,
        ifnull(a.custid, b.custid) as custid,
        ifnull(a.ordernbr, b.origordernbr) as ordernbr,
        a.status_pda,
        b.status_so,
        ifnull(a.ordertype, b.ordertype) as ordertype,
        ifnull(a.slsperid_pda, b.slsperid_so) as crtd_user,
        ifnull(a.crtd_datetime_pda, b.crtd_datetime_so) as crtd_datetime,
        ifnull(a.orderdate, b.orderdate) as orderdate,
    from
        `staging.sync_dms_pda_so_don_treo` a 
        LEFT JOIN `staging.sync_dms_so_don_treo` b on a.key_pda = b.key_so
                and a.manv = b.manv
                and a.version = b.version

),
order_detail as (
    select
        a.branchid,
        a.ordernbr,
        b.ordernbr as ordernbr_mapping,
        Case
            when b.originallineref is not null then b.originallineref
            else a.lineref
        end as lineref,
        a.invtid,
        Case
            when b.lineqty is not null then b.lineqty
            else a.lineqty
        end as lineqty,
        b.ordertype,
        a.siteid,
        a.crtd_user,
        ifnull(a.slsperid, b.slsperid) as slsperid,
        a.beforevatprice,
        Case
            when b.freeitem = true then 0
            when a.freeitem = true then 0
            when b.beforevatamount is not null or b.beforevatamount <> 0 then b.beforevatamount
            when a.beforevatamount = 0 then a.lineqty * a.slsprice
            else a.beforevatamount
        end as beforevatamount,
        a.aftervatprice,
        Case
            when b.freeitem = true then 0
            when a.freeitem = true then 0
            when b.aftervatamount is not null then b.aftervatamount
            when a.aftervatamount = 0 then a.lineqty * a.slsprice
            else a.aftervatamount
        end as aftervatamount,
        a.vatamount,
        a.freeitem,
        -- a.slsprice,
    from
        `staging.sync_dms_pda_sod_don_treo` a
        left join `staging.sync_dms_sod_don_treo` b on a.branchid = b.branchid
        and a.ordernbr = b.origordernbr
        and a.invtid = b.invtid
        and b.originallineref = a.lineref
                and a.manv = b.manv
                and a.version = b.version

),
tuyen_dms_moinhat as (
    with data_tuyen as (
        SELECT
            custid,
            slsperid,
            crtd_datetime,
            Case
                when routetype in ('B', 'D') then 1
                else 2
            end as routetype,
        FROM
            `spatial-vision-343005.staging.sync_dms_srm`
        where
            delroutedet is false
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

result0 as (
    select
        a.*
    except(crtd_user),
        Case
            when a.crtd_user = 'TMDT_001'
            and k1.tenquanlytt <> 'Nguyễn Văn Tiến' then h.slsperid
            when a.crtd_user = 'TMDT_001' then ifnull(g1.macrs, g2.macrs)
            else null
        end as crtd_user,
        Case
            when a.crtd_user = 'TMDT_001' then 'ECOM'
            else 'DMS'
        end as datatype
    from
        mapping a
        LEFT JOIN `staging.d_master_khachhang` a1 on a1.custid = a.custid
        LEFT JOIN `spatial-vision-343005.staging.d_manual_tuyenbanhang_crs` g1 on g1.phuongxa is not null
        and trim(
            upper(
                concat(concat(g1.tinhtp, g1.quanhuyen), g1.phuongxa)
            )
        ) = trim(
            upper(
                concat(
                    concat(a1.statedescr, a1.districtdescr),
                    a1.wardname
                )
            )
        )
        LEFT JOIN `spatial-vision-343005.staging.d_manual_tuyenbanhang_crs` g2 on g2.phuongxa is null
        and trim(upper(concat(g2.tinhtp, g2.quanhuyen))) = trim(upper(concat(a1.statedescr, a1.districtdescr)))
        LEFT JOIN tuyen_dms_moinhat h on a.custid = h.custid
        LEFT JOIN staging.d_users k1 on h.slsperid = k1.manv
),
result as (
    select
        a.*except(crtd_user),
        Case
            when a.status_so = 'C' then 'Đã phát hành hóa đơn'
            when a.status_so = 'V' then 'Hủy hóa đơn'
            when a.status_so = 'I' then 'Tạo hóa đơn'
            when a.status_so = 'N' then 'Tạo hóa đơn'
            when a.status_so = 'H' then 'Chờ xử lý hóa đơn'
            when a.status_so = 'E' then 'Đóng đơn hàng'
            when a.status_so = 'D' then 'Đơn hàng tạm'
            when a.status_so is null
            and a.status_pda = 'C' then 'Chưa tạo HĐ ảo'
            when a.status_so is null
            and a.status_pda = 'E' then 'Đóng đơn hàng'
            when a.status_so is null
            and a.status_pda = 'D' then 'Đơn hàng tạm'
            when a.status_so is null
            and a.status_pda = 'H' then 'Chờ xử lý duyệt đơn hàng'
            when a.status_so is null
            and a.status_pda = 'V' then 'Hủy đơn hàng'
            when a.status_so is null
            and a.status_pda = 'X' then 'Đóng đơn hàng tạm'
            else null
        end as status_iv,
        -- Trạng thái phát hành hóa đơn
        k.invtid,
        k.lineqty,
        Case
            when k.freeitem = true then 'Hàng tặng'
            when k.freeitem is null then null
            else 'Hàng bán'
        end as freeitem,
        k.siteid,
        k.beforevatprice,
        Case
            when a.ordertype = 'CO' then -1 * k.beforevatamount
            else k.beforevatamount
        end as beforevatamount,
        k.aftervatprice,
        Case
            when a.ordertype = 'CO' then -1 * k.aftervatamount
            else k.aftervatamount
        end as aftervatamount,
        k.vatamount,
        h.custname,
        h.terms,
        h.paymentsform,
        h.channel,
        --kênh
        h.statedescr,
        --tỉnh
        h.shortterritorydescr as territorydescr,
        --khu vuc
        h.active,
        h.phone,
        h.attn as nglienhe,
        -- h.custid,
        h.refcustid,
        h.classid,
        h.hcotypeid,
        h.address as addr1,
        h.shoptype,
        --kênh phụ
        h.districtdescr,
        h.wardname,
        o.descr1 as tensp_viettat,
        o.descr as tensp_daydu,
        ifnull(a.crtd_user, k.slsperid) as crtd_user,
        c.tencvbh as nguoi_taodon,
        Case when c.tenquanlyvung ='Lương Trịnh Thắng' then c.supid_bh else c.supid end as ma_crm,
        c.asm as ma_scrm,
        LEFT(c.rsmid, 6) as ma_ncxm,
        Case when c.tenquanlyvung ='Lương Trịnh Thắng' then c.tenquanlytt_bh else c.tenquanlytt end as tenquanlytt,
        
        c.tenquanlykhuvuc,
        c.tenquanlyvung,
        '' as manv,
        '' as version,
        
        current_datetime("+7") as updated_at,
        d.errormessage  as is_err_duyet_tudong,
    from
        result0 a
        LEFT JOIN order_detail k on k.branchid = a.branchid
        and k.ordernbr = a.ordernbr
        LEFT JOIN `staging.d_master_khachhang` h on a.custid = h.custid
        LEFT JOIN `spatial-vision-343005.staging.d_dms_master_invtid` o on o.invtid = k.invtid
        LEFT JOIN `spatial-vision-343005.staging.d_users` c on c.manv = ifnull(a.crtd_user, k.slsperid)
        LEFT JOIN loi_duyet_tudong d on d.branchid = a.branchid and d.ordernbr = a.ordernbr
        LEFT JOIN 
	        (Select distinct sodondathang from `spatial-vision-343005.staging.f_sales`) b 
                ON a.ordernbr = b.sodondathang
    where b.sodondathang is null

        
)
select
    *
from
    result;