CREATE VIEW `spatial-vision-343005.warehouse.tiktok_content`
AS select
author,
aweme_id,
create_time,
date_trunc(create_time, MONTH) as month,

-- Trích xuất giờ từ trường create_time
EXTRACT(HOUR FROM create_time) AS hour_of_day,

    CASE
        -- 🌃 Khuya (00:00:00 đến 05:59:59)
        WHEN EXTRACT(HOUR FROM create_time) >= 0 AND EXTRACT(HOUR FROM create_time) < 6 THEN 'Khuya'
        
        -- ☀️ Sáng (06:00:00 đến 11:59:59)
        WHEN EXTRACT(HOUR FROM create_time) >= 6 AND EXTRACT(HOUR FROM create_time) < 12 THEN 'Sáng'
        
        -- 🌤️ Chiều (12:00:00 đến 17:59:59)
        WHEN EXTRACT(HOUR FROM create_time) >= 12 AND EXTRACT(HOUR FROM create_time) < 18 THEN 'Chiều'
        
        -- 🌙 Tối (18:00:00 đến 23:59:59)
        ELSE 'Tối' -- Chỉ còn lại 18:00:00 đến 23:59:59
    END AS time_of_day_label,

RANK() OVER (
  ORDER BY
  CAST(JSON_VALUE(js, "$.statistics.digg_count") AS FLOAT64) DESC
) AS digg_rank,

JSON_VALUE(js, "$.desc") AS video_desc,
JSON_VALUE(js, "$.video.download_no_watermark_addr.url_list[0]") as download_no_watermark_addr,
CAST(JSON_VALUE(js, "$.video.duration") AS FLOAT64)/1000  as duration,
CAST(JSON_VALUE(js, "$.video.duration") AS FLOAT64)  as duration_ms,
CAST(JSON_VALUE(js, "$.statistics.collect_count") AS FLOAT64) AS collect_count,
CAST(JSON_VALUE(js, "$.statistics.comment_count") AS FLOAT64) AS comment_count,
CAST(JSON_VALUE(js, "$.statistics.digg_count") AS FLOAT64) AS digg_count,
CAST(JSON_VALUE(js, "$.statistics.download_count") AS FLOAT64) AS download_count,
CAST(JSON_VALUE(js, "$.author.nickname") AS STRING) AS nickname,
-- CAST(JSON_VALUE(js, "$.statistics.lose_comment_count") AS FLOAT64) AS lose_comment_count,
-- CAST(JSON_VALUE(js, "$.statistics.lose_count") AS FLOAT64) AS lose_count,
-- CAST(JSON_VALUE(js, "$.statistics.play_count") AS FLOAT64)/1000000 AS play_count,
CAST(JSON_VALUE(js, "$.statistics.play_count") AS FLOAT64) AS play_count,

-- CAST(JSON_VALUE(js, "$.statistics.repost_count") AS FLOAT64) AS repost_count,
CAST(JSON_VALUE(js, "$.statistics.share_count") AS FLOAT64) AS share_count,
-- CAST(JSON_VALUE(js, "$.statistics.whatsapp_share_count") AS FLOAT64) AS whatsapp_share_count

from `spatial-vision-343005.staging.tiktok_videos_data` p
-- where author = 'letuankhang2002'
order by create_time desc;