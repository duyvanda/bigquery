CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_data_checkin_pbh_v2()
BEGIN

TRUNCATE TABLE staging_temp.f_data_checkin_pbh_v2_temp;
INSERT INTO staging_temp.f_data_checkin_pbh_v2_temp(

-- Create or replace table staging_temp.f_data_checkin_pbh_v2_temp
-- partition by date(visitdate)
-- as

with data_kh_da_viengtham as (
    SELECT
        slsperid,
        date_trunc(visitdate, month) as thang_,
        custid,
        count(distinct soluong_checkin_thucte) as solan_checkin
    from
        `staging_temp.f_data_checkin_pbh`
    where
        visitdate >= '2022-06-01'
    group by
        1,
        2,
        3
    having
        solan_checkin > 0
),
data_checkdh as (
    SELECT
        makhdms,
        max(date(ngaychungtu)) as ngaychungtu,
        sum(doanhsochuavat) as ds
    from
        `staging.f_sales`
    where
        ngaychungtu >= '2022-01-01' --and custid ='N07610295'
    group by
        1
    having ds > 0
),
data_kh_co_dh_trong2thang as (
    select
        a.custid,
        date_diff(current_date("+7"),ifnull(ngaychungtu,date(a.crtd_datetime)),day) as so_ngay_chua_mua_hang
        
    from
        `staging.d_master_khachhang` a
        LEFT JOIN data_checkdh b on a.custid = b.makhdms
),
result0 as (
    select
        a.*except(channel),
        k.custname,
        k.statedescr,
        k.districtdescr,
        k.territorydescr,
        k.channel,
        k.shoptype,
        k.branchid,
        Case
            when k.classid = 'PC1' then 'KA'
            when k.classid = 'PC2' then 'KB'
            when k.classid = 'PC3' then 'KC'
            when k.classid is null then '-'
            else k.classid
        end as classid,
        k.taxregnbr,
        k.phone,
        k.attn,
        date(k.legaldate) as thoihanhieulucgdpgpp,
        Case
            when k.legaldate is null then null
            when date(k.legaldate) < (
                select
                    *
                from
                    `staging.d_current_table`
            ) then 'Y'
            when date(k.legaldate) >= (
                select
                    *
                from
                    `staging.d_current_table`
            ) then 'N'
            else null
        end as is_hetthoihanhieuluc,
        Case
            when date_add(
                (
                    select
                        *
                    from
                        `staging.d_current_table`
                ),
                interval 30 day
            ) >= date(k.legaldate)
            and date(k.legaldate) > (
                select
                    *
                from
                    `staging.d_current_table`
            ) then 'Y'
            when k.legaldate is null then null
            else 'N'
        end as is_saphetthoihanhieuluc,
    from
        `staging_temp.f_data_checkin_pbh` a
        LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang_bytime` k on k.custid = a.custid and date(date_trunc(a.visitdate,month)) = date(k.thang)

),
result1 as (
    select
        a.*
    except
(slsperid),
        Case
            when classid = 'KA'
            and sl_quydinh is not null then sl_quydinh
            else null
        end as sl_quydinh_ka,
        Case
            when classid = 'KB'
            and sl_quydinh is not null then sl_quydinh
            else null
        end as sl_quydinh_kb,
        Case
            when classid = 'KC'
            and sl_quydinh is not null then sl_quydinh
            else null
        end as sl_quydinh_kc,
        Case
            when (
                classid not in('KA', 'KB', 'KC')
                or classid is null
            )
            and sl_quydinh is not null then sl_quydinh
            else null
        end as sl_quydinh_khac,
        Case
            when classid = 'KA'
            and sl_kh_checkin is not null then sl_kh_checkin
            else null
        end as sl_checkin_ka,
        Case
            when classid = 'KB'
            and sl_kh_checkin is not null then sl_kh_checkin
            else null
        end as sl_checkin_kb,
        Case
            when classid = 'KC'
            and sl_kh_checkin is not null then sl_kh_checkin
            else null
        end as sl_checkin_kc,
        Case
            when (
                classid not in('KA', 'KB', 'KC')
                or classid is null
            )
            and sl_kh_checkin is not null then sl_kh_checkin
            else null
        end as sl_checkin_khac,
        Case
            when classid = 'KA'
            and soluong_checkin_thucte is not null then soluong_checkin_thucte
            else null
        end as sl_kh_checkin_thucte_ka,
        Case
            when classid = 'KB'
            and soluong_checkin_thucte is not null then soluong_checkin_thucte
            else null
        end as sl_kh_checkin_thucte_kb,
        Case
            when classid = 'KC'
            and soluong_checkin_thucte is not null then soluong_checkin_thucte
            else null
        end as sl_kh_checkin_thucte_kc,
        Case
            when (
                classid not in('KA', 'KB', 'KC')
                or classid is null
            )
            and soluong_checkin_thucte is not null then soluong_checkin_thucte
            else null
        end as sl_kh_checkin_thucte_khac,
        Case
            when distance > 1000 then 'Y'
            when distance <= 1000 then 'N'
            else null
        end as is_checkin_onl,
        Case
            when distance > 1000 then null
            when distance <= 1000 then custid
            else null
        end as so_kh_viengtham_tt,
        left(a.slsperid, 6) as slsperid,
        Case when c.tenquanlyvung ='Lương Trịnh Thắng' then c.supid_bh
            else c.supid
        end as ma_crm,
        c.asm as ma_scrm,
        LEft(c.rsmid, 6) as ma_ncxm,
        c.tencvbh as mds,
        Case when c.tenquanlyvung ='Lương Trịnh Thắng' then c.tenquanlytt_bh
            else c.tenquanlytt
        end as tenquanlytt,
        c.tenquanlykhuvuc,
        c.tenquanlyvung,
    from
        result0 a
        LEFT JOIN `staging.d_users_bytime` c on c.manv = left(a.slsperid, 6) and date(date_trunc(a.visitdate,month)) = date(c.thang)
),
result2 as (
    select
        a.*,
        Case
            when pl_kh_checkin ='Đạt' then 'Yes'
            else 'No'
        end as is_daviengtham,
        -- Case
        --     when c.sodon is null then 0
        --     else c.sodon
        -- end as sodon,
        -- Case
        --     when c.sodon_1 is null then 0
        --     else c.sodon_1
        -- end as sodon_1,
        -- Case
        --     when c.sodon_2 is null then 0
        --     else c.sodon_2
        -- end as sodon_2,
        c.so_ngay_chua_mua_hang
    from
        result1 a
        LEFT JOIN data_kh_co_dh_trong2thang c on a.custid = c.custid
),
result3 as (
    select
        *,
        -- so_ngay_chua_mua_hang as is_chuaco_dh_trong2thang,
        Case
            when taxregnbr is not null
            and is_hetthoihanhieuluc = 'N' then 'Đầy đủ'
            when is_hetthoihanhieuluc = 'N'
            and taxregnbr is null then 'Thiếu Mã Số Thuế'
            when is_hetthoihanhieuluc = 'Y'
            and taxregnbr is not null then 'GPP hết hạn'
            when (
                is_hetthoihanhieuluc = 'Y'
                or is_hetthoihanhieuluc is null
            )
            and taxregnbr is null then 'Thiếu MST,GPP'
            when thoihanhieulucgdpgpp is null
            and taxregnbr is not null then 'Thiếu GPP'
            else null
        end as is_hspl,
        Case
            when phone is not null
            and attn is not null then 'Đầy đủ'
            when phone is null
            and attn is null then 'Thiếu TTKH'
            when phone is null
            and attn is not null then 'Thiếu SDT'
            when phone is not null
            and attn is null then 'Thiếu họ & tên NLH'
            else null
        end as is_ttkh
    from
        result2
),
result4 as (
    select
        *,
        Case
            when (
                is_hspl like 'Thiếu%'
                or is_hspl = 'GPP hết hạn'
            )
            and is_ttkh like 'Thiếu%' then concat('HSPL', ' & ', 'TTKH')
            when is_hspl = 'GPP hết hạn' then 'HSPL'
            when is_hspl like 'Thiếu%' then 'HSPL'
            when is_ttkh like 'Thiếu%' then 'TTKH'
            when is_hspl like 'Đầy đủ%'
            and is_ttkh like 'Đầy đủ%' then 'Đầy đủ'
            else null
        end as is_bosung_crs
    from
        result3
),
check_qd_viengtham as (
select 
    date(date_trunc(visitdate,month)) as thang,
    slsperid,
    count(distinct sl_kh_checkin) as sl_kh_checkin,
    count(distinct sl_quydinh) as sl_quydinh,
    count( sl_quydinh) as sl_call_can_checkin,
    count(distinct soluong_checkin_thucte) as sl_call_checkin_thucte,
from result4
group by 1,2
)
select
    a.*,
    Case
     when 
     a.channel = 'TP' 
    --  and round(safe_divide(b.sl_kh_checkin,b.sl_quydinh)*100,1) >= 90 
        and round(safe_divide(b.sl_call_checkin_thucte,b.sl_call_can_checkin)*100,1) >=90  then 'Đạt' 

    when a.channel = 'PCL' and round(safe_divide(b.sl_kh_checkin,b.sl_quydinh)*100,1) >= 80  then 'Đạt'
        else 'Không đạt'
    end as check_viengtham_thang,
    current_timestamp() + interval 7 hour as inserted_at,
    datetime_diff (time_checkout,time_checkin, minute) as thoi_gian_checkin

from
    result4 a 
LEFT JOIN check_qd_viengtham b on date(date_trunc(visitdate,month)) = b.thang and a.slsperid =b.slsperid
where tenquanlytt not in ('Đinh Thị Ngọc Mẫn') and tenquanlyvung not in ('Lương Trịnh Thắng')

	 );

Create or replace table `warehouse.f_data_checkin_pbh_v2`

copy `staging_temp.f_data_checkin_pbh_v2_temp`;


End;