CREATE VIEW `spatial-vision-343005.warehouse.tiktok_content_profiles`
AS select
JSON_VALUE(js, "$.unique_id") as author,
cast(JSON_VALUE(js, "$.total_favorited") as float64) AS total_favorited,
cast(JSON_VALUE(js, "$.follower_count") as float64) AS follower_count,
cast(JSON_VALUE(js, "$.aweme_count") as float64) AS aweme_count,
cast(JSON_VALUE(js, "$.sec_uid") as string) AS sec_uid,
cast(JSON_VALUE(js, "$.uid") as string) AS uid
from `staging.tiktok_profiles`
-- where
-- JSON_VALUE(js, "$.unique_id") = 'letuankhang2002'

;