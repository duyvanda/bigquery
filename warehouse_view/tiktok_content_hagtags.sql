CREATE VIEW `spatial-vision-343005.warehouse.tiktok_content_hagtags`
AS select
aweme_id,
create_time,
lower(hashtag_word) as hashtag_word,
author
FROM (
SELECT
    t.aweme_id,
    t.create_time,
    author,
    REGEXP_EXTRACT_ALL(JSON_VALUE(js, "$.desc"), r'#(\w+)') AS hashtag_words_only
FROM
    `staging.tiktok_videos_data` AS t
    -- where author = 'letuankhang2002'
) t,
UNNEST(t.hashtag_words_only) AS hashtag_word;