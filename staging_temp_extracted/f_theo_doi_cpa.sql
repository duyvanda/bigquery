-- ==========================================================================
-- Routine Name : f_theo_doi_cpa
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2026-02-12 02:17:49.917000+00:00
-- Last Altered : 2026-02-12 02:17:49.917000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.f_theo_doi_cpa()
BEGIN

TRUNCATE TABLE staging_temp.f_theo_doi_cpa_temp;
INSERT INTO `staging_temp.f_theo_doi_cpa_temp`

(
-- Create or replace table staging_temp.f_theo_doi_cpa_temp as
with
clean_mact as (
  with ct as

(
  select stt,replace(kenh,'\n',',') as kenh from `staging.d_manual_theo_doi_cpa`
)

  SELECT  stt,kenh_cv
  FROM ct,
  UNNEST(SPLIT(kenh)) kenh_cv
),
data_ds as (
  select
    discidpn,
    makenhkh,
    -- ngaychungtu,
    sum(Case
      when masanpham in ('VT80307','VT80098') then 160000 * soluong
      when doanhsocovat = 0 then soluong * dongiachuavat
    else 0 end)  as chi_phi_hang_km,
    sum(ifnull(discamt,0)) as chi_phi_tien_ck,
    sum(doanhsochuavat) as doanhsochuavat,
    sum(doanhsocovat) as doanhsocovat
  from `warehouse.f_tongquat_ctkm`
  group by all
),
result as (
SELECT
  a.pl,
  a.socpacsbh,
  a.tenchuongtrinh,
  c.kenh_cv kenh,
  a.hieuluc,
  a.denngay,
  a.mactdms,
  a.mactdms as mactid,
  a.sotbsct,
  a.linkfile_next_cloud,
  a.linkfilesotbsct,
  cast(a.chiphi as INT) as chi_phi_sct,
  cast(a.theocpa as INT) as chi_phi_cpa,
  a.doanhsokh,
  ifnull(b.chi_phi_hang_km,0) as chi_phi_hang_km,
  ifnull(b.chi_phi_tien_ck,0) as chi_phi_tien_ck,
  ifnull(b.doanhsochuavat,0) as doanhsochuavat,
  ifnull(b.doanhsocovat,0) as doanhsocovat
FROM `spatial-vision-343005.staging.d_manual_theo_doi_cpa` a
LEFT JOIN clean_mact c on a.stt =c.stt
LEFT JOIN data_ds b on trim(upper(a.mactdms)) = trim(upper(b.discidpn)) and trim(c.kenh_cv) = b.makenhkh

)

select
*,
Case when date(denngay) < current_date("+7") then 'Hết hiệu lực' else 'Còn hiệu lực' end as is_active,
chi_phi_hang_km + chi_phi_tien_ck as chi_phi_da_th,
safe_divide((chi_phi_hang_km+chi_phi_tien_ck),chi_phi_sct) as ty_le_sct,
safe_divide((chi_phi_hang_km+chi_phi_tien_ck),chi_phi_cpa) as ty_le_cpa,
safe_divide(doanhsocovat,doanhsokh) as ty_le_dskh,
current_datetime("+7") as inserted_at
from result

);

Create or replace table `warehouse.f_theo_doi_cpa`
copy `staging_temp.f_theo_doi_cpa_temp`;
END;
