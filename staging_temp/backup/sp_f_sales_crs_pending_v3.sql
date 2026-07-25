CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_sales_crs_pending_v3()
BEGIN 

WITH
loi_duyet_thu_hoi_hd as (

select * from (
SELECT * FROM `spatial-vision-343005.staging.sync_dms_err` 


qualify row_number() over (partition by pk order by lupd_datetime desc ) = 1
    ) a  
WHERE  errormessage like '%Hợp đồng chưa thu hồi%' 
)

, da_co_trong_f_sales as (
    select distinct sodondathang from `staging.f_sales` where date(ngaychungtu)>= '2026-01-01'
)


, mapping_dontreo as (
    SELECT
        distinct a.BranchID,
        a.custid,
        a.OrderNbr,
        a.Status as status_pda,
        b.Status as status_so,
        a.ordertype,
        a.slsperid as crtd_user,
        a.orderdate,
        a.crtd_datetime,
    FROM
        `staging.sync_dms_pda_so` a
        LEFT JOIN `staging.sync_dms_so` b on a.BranchID = b.BranchID
        and a.OrderNbr = b.OrigOrderNbr
        LEFT JOIN da_co_trong_f_sales f on f.sodondathang = a.OrderNbr
    where
        a.OrderType in ('IN', 'CO','IR','LO')
        and a.Status not in ('X', 'E')
        and ifnull(b.Status, '') not in ('C', 'V')
        and cast (a.orderdate as DATE) >= '2026-01-01'
        and f.sodondathang is null
        
)

,mapping as(
    SELECT
        a.*,
        ifnull(c.originallineref, b.lineref) as LineRef,
        ifnull(c.lineqty, b.LineQty) as LineQty,
        b.InvtID,
        b.FreeItem,
        b.beforevatprice,
        b.aftervatprice,
        b.slsprice,
        Case
            when c.freeitem = true then 0
            when b.freeitem = true then 0
            when c.beforevatamount is not null or c.beforevatamount <> 0 then c.beforevatamount
            when b.beforevatamount = 0 then b.lineqty * b.slsprice
            else b.beforevatamount
        end as beforevatamount,
        Case
            when c.freeitem = true then 0
            when b.freeitem = true then 0
            when c.aftervatamount is not null or c.aftervatamount <> 0  then c.aftervatamount
            when b.aftervatamount = 0 then b.lineqty * b.slsprice
            else b.aftervatamount
        end as aftervatamount,
        b.slsperid,
        b.siteid,
        b.vatamount
    from
        mapping_dontreo a
        LEFT JOIN `staging.sync_dms_pda_sod` b on b.BranchID = a.BranchID
        and b.OrderNbr = a.OrderNbr
        LEFT JOIN `staging.sync_dms_sod1` c on b.branchid = c.branchid
        and b.ordernbr = c.origordernbr
        and b.invtid = c.invtid
        and c.originallineref = b.lineref
        where 
        --true
        b.crtd_datetime >='2025-01-01'
        --and (CASE WHEN b.crtd_datetime BETWEEN '2025-09-29 18:00:00' AND '2025-09-30 23:59:59' AND b.InvtID = 'T302203014' THEN FALSE ELSE TRUE END)
)

,tuyen_dms_moinhat as (
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
        data_tuyen qualify row_number() over (
            partition by custid
            order by
                routetype asc,
                crtd_datetime desc
        ) = 1
),
result0 as (
    select
        a.*
    except
(crtd_user),
        Case 
        when l.col.phan_loai_mcp = 'Rural' 
        or a.crtd_user = 'TMDT_001'
        or a.crtd_user in ("MR1682KN","MR2504","MR1232","MR0806","MR2608","MR2111","MR1682","MR2504KN","MR1232KN","MR0806KN","MR2608KN",
        "MR2111KN","MR2993","MR2993KN","MR3038","MR3038KN","MR2608KN","MR2948","MR2948KN","MR2608",'MR3196','MR3196KN')
        then l.col.ma_nvbh
      else a.crtd_user
      end as crtd_user, 
        Case
            when a.crtd_user = 'TMDT_001' then 'ECOM'
            else 'DMS'
        end as datatype
    from
        mapping a
        LEFT JOIN `staging.d_master_khachhang` a1 on a1.custid = a.custid
        LEFT JOIN `warehouse.f_mapping_crs` l on l.custid = a.custid 
),
result as (
    select
        a.*
    except
(
            crtd_user,
            beforevatamount,
            aftervatamount,
            freeitem,
            crtd_datetime
        ),
        Case
            when a.freeitem = true then 'Hàng tặng'
            when a.freeitem is null then null
            else 'Hàng bán'
        end as freeitem,
        Case
            when a.ordertype in ('CO','IR','LO') then -1 * a.beforevatamount
            else a.beforevatamount
        end as beforevatamount,
        Case
            when a.ordertype in ('CO','IR','LO') then -1 * a.aftervatamount
            else a.aftervatamount
        end as aftervatamount,
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
        h.custname,
        h.terms,
        h.paymentsform,
        h.channel,
        h.statedescr,
        h.shortterritorydescr as territorydescr,
        h.active,
        h.phone,
        h.attn as nglienhe,
        h.refcustid,
        h.classid,
        h.hcotypeid,
        h.address as addr1,
        h.shoptype,
        h.districtdescr,
        h.wardname,
        o.descr1 as tensp_viettat,
        o.descr as tensp_daydu,
        a.crtd_user,
        c.tencvbh as nguoi_taodon,
        Case
            when c.tenquanlyvung = 'Lương Trịnh Thắng' then c.supid_bh
            else c.supid
        end as ma_crm,
        c.asm as ma_scrm,
        LEFT(c.rsmid, 6) as ma_ncxm,
        Case
            when c.tenquanlyvung = 'Lương Trịnh Thắng' then c.tenquanlytt_bh
            else c.tenquanlytt
        end as tenquanlytt,
        c.tenquanlykhuvuc,
        c.tenquanlyvung,
        d.errormessage,
        e.name as ten_kho,
        current_datetime("+7") as updated_at,
        a.crtd_datetime
    from
        result0 a
        LEFT JOIN `staging.d_master_khachhang` h on a.custid = h.custid
        LEFT JOIN `spatial-vision-343005.staging.d_dms_master_invtid` o on o.invtid = a.invtid
        LEFT JOIN `spatial-vision-343005.staging.d_users` c on c.manv = a.crtd_user
        LEFT JOIN loi_duyet_thu_hoi_hd d on d.branchid = a.branchid and d.ordernbr =a.ordernbr
        LEFT JOIN `spatial-vision-343005.staging.d_dms_master_siteid` e on e.siteid = a.siteid
)
select
    *
from
    result;
End;