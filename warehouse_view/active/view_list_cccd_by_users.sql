CREATE VIEW `spatial-vision-343005.warehouse.view_list_cccd_by_users`
AS with dms_cccd as

(
SELECT
id, full_name as gmm_name,status,reason  FROM `spatial-vision-343005.staging.insert_list_cccd` 
QUALIFY ROW_NUMBER() OVER (PARTITION BY id ORDER BY inserted_at ASC) = 1
)

, data_cccd as (
SELECT
CAST(JSON_VALUE(js, "$.id") AS INT64) AS id,
CAST(JSON_VALUE(js, "$.user_id") AS INT64) AS user_id,
JSON_VALUE(js, "$.user_code_upload") AS user_code_upload,
JSON_VALUE(js, "$.user_name_upload") AS user_name_upload,
JSON_VALUE(js, "$.tax_options") AS tax_options,
JSON_VALUE(js, "$.citizenIdentity_number") AS citizenIdentity_number,
JSON_VALUE(js, "$.full_name") AS full_name,
CAST(JSON_VALUE(js, "$.dob") AS DATE) AS dob,
JSON_VALUE(js, "$.code_id") AS code_id,
JSON_VALUE(js, "$.gender") AS gender,
JSON_VALUE(js, "$.address") AS address,
JSON_VALUE(js, "$.image_file") AS image_file,
JSON_VALUE(js, "$.created_at") AS created_at,
p_manv,
p_version,
etl_at
FROM `staging.list_cccd_by_users`
)

SELECT
a.id,
a.user_id,
a.user_code_upload,
a.user_name_upload,
a.tax_options,
a.citizenidentity_number,
a.full_name,
a.dob,
a.code_id,
a.gender,
a.address,
a.image_file,
a.created_at,
a.p_manv,
a.p_version,
c.col.ma_nvbh as manv,
a.etl_at  as inserted_at,
c.channel,
c.shoptype,
d.custname,
e.tencvbh,
e.supid,
e.tenquanlytt,
f.gmm_name,
f.status,
f.reason
FROM `data_cccd` AS a
LEFT JOIN warehouse.f_mapping_crs c on c.custid = a.code_id
left join spatial-vision-343005.staging.d_master_khachhang d on a.code_id = d.custid
left join spatial-vision-343005.staging.d_users  e on c.col.ma_nvbh = e.manv
LEFT JOIN `dms_cccd` f on f.id = a.id;