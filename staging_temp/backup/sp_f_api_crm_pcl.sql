CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_api_crm_pcl(pmanv STRING, pversion STRING)
BEGIN

-- SET PARAMS
DECLARE set_manv STRING DEFAULT 'None';
DECLARE set_version STRING DEFAULT 'None';


SET set_manv = IF (pmanv = '', set_manv, pmanv);
SET set_version = IF (pversion = '', set_version, pversion);
-- INSERT INTO `warehouse.f_api_crm_pcl`
-- (
-- Create table warehouse.f_api_crm_pcl as

with tuyen_dms_moinhat as (
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
employee as (
    select
        employee_code,
        id,
        full_name,
        organization_unit_id,
        p_manv,
        p_version
    from
        `staging.d_crm_employees_theo_user`
    where
        p_manv = pmanv
        and p_version = pversion
        qualify row_number() over (partition by p_manv,p_version,employee_code order by created_date desc)=1
)
SELECT
    139 as form_layout_id,
    a.id as owner_id,
    b.slsperid,
    Case when a.full_name is null then 'Nguyễn Thọ Chiến (MR0081)' 
        else a.full_name || ' (' || a.employee_code || ')' end as owner_name,
    c.pubcustname as account_name,
    c.pubcustid as account_number,
    c.statedescr || ', ' || 'Viêt Nam' as billing_address,
    'Viêt Nam' as billing_country,
    c.statedescr as billing_province,
    current_datetime("+7") as modified_date,
    'Nguyễn Thọ Chiến (MR0081)' as modified_by,
    'Khách hàng PCL' as form_layout,
    a.organization_unit_id,
    e.organization_unit_name,
    c.channel as custom_field58,
    c.shoptype as custom_field60,
    c.hcotypeid as custom_field59,
    p_manv,
    p_version
from
     `spatial-vision-343005.staging.d_master_khachhang` c 
    -- LEFT JOIN `spatial-vision-343005.staging.d_crm_customers` d on c.pubcustid = d.account_number
    LEFT JOIN tuyen_dms_moinhat b on c.custid = b.custid
    LEFT JOIN  employee a on a.employee_code = b.slsperid
    LEFT JOIN `staging.d_crm_organizationunits` e on cast(e.id as float64) = a.organization_unit_id
where
    c.pubcustid is not null
    and c.channel = 'PCL'
    and c.active = 'Active'
    -- and b.slsperid is not null
    -- and d.account_number is null
;
-- );

END;