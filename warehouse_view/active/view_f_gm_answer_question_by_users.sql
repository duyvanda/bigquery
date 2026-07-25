CREATE VIEW `spatial-vision-343005.warehouse.view_f_gm_answer_question_by_users`
AS WITH bang_doanhso_2024 AS (
  SELECT 
    a.makhdms,
    SUM(a.doanhsochuavat) AS doanhsochuavat_ytd,
    -- MAX(ngaychungtu) as max_ngay_chung_tu
  FROM `spatial-vision-343005.staging.f_sales` a 
  WHERE ngaychungtu >= '2024-01-01'
  GROUP BY 1
  HAVING doanhsochuavat_ytd > 0
)

, bang_doanhso_online AS (
  SELECT 
    a.makhdms,
    SUM(a.doanhsochuavat) AS doanhsochuavat_online_from_t7,
    SUM(Case when extract(month from ngaychungtu) = 9 then doanhsochuavat else 0 end) as ds_chua_vat_t9,
    -- MAX(ngaychungtu) as max_ngay_chung_tu
  FROM `spatial-vision-343005.staging.f_sales` a 
  WHERE ngaychungtu >= '2024-07-01'
  and masanpham = 'T302203003'
  GROUP BY 1
  HAVING doanhsochuavat_online_from_t7 > 0
)

SELECT
-- a.index,
-- a.id_user,
-- a.id_customer_oa,
-- a.id_customer,
a.customer_code,
a.customer_name,
a.pharmacy_name,
a.phone, --zalo follow phone
-- a.avatar,
a.card_code,
a.card_seri,
a.card_price,
a.lucky_code,
a.card_type_name,
-- a.times,
-- a.is_win,
-- a.is_rewarded,
-- a.is_finished,
-- a.active,
a.created_at,
a.updated_at,
a.status_reward, -- trạng thái nhận thưởng
-- a.answers,
-- a.ori_index,
a.status_name,
a.p_version,
a.datatype,
a.tong_card, -- tong ke hoach cho moi card
a.full_name,
a.zalo_name,
a.customer_role_name,

c.doanhsochuavat_ytd as ds_ytd,
c1.doanhsochuavat_online_from_t7,
c1.ds_chua_vat_t9,
-- b.col.ma_nvbh as ma_crs,
ifnull(b.col.ma_nvbh, 'CX') as ma_crs,
ifnull(d.tencvbh, 'CX') as tencvbh,
ifnull(d.tenquanlytt, 'CX') as tenquanlytt,
-- d.tenquanlytt,
q.channel,
q.shoptype,
q.shoptypedescr,
q.districtdescr,
q.territorydescr


FROM `spatial-vision-343005.staging.f_gm_answer_question_by_users` a
left join `warehouse.f_mapping_crs` b on a.customer_code = b.custid and b.custid not in ('00180400','010142')
left join bang_doanhso_2024 c on a.customer_code = c.makhdms
left join bang_doanhso_online c1 on a.customer_code = c1.makhdms
left join spatial-vision-343005.staging.d_users   d on col.ma_nvbh = d.manv
LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` q on a.customer_code = q.custid
-- WHERE a.datatype = 'detail'







;