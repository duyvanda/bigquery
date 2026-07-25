CREATE VIEW `spatial-vision-343005.warehouse.tiktok_content_word_frequency_count`
AS WITH videos_idol as

(
    SELECT a.*
    FROM `staging.tiktok_videos_comments` a
    INNER JOIN  `staging.tiktok_videos_data` b on a.aweme_id = b.aweme_id and b.author = 'phuongmychiofficial'
)

SELECT
    word AS tu_xuat_hien,
    COUNT(word) AS so_lan_xuat_hien -- The frequency (lần)
FROM
    `videos_idol` AS t1,
    UNNEST(
        REGEXP_EXTRACT_ALL(
            -- Clean the text: convert to lowercase and replace any non-letter/non-space character with a space.
            -- NOTE: The pattern r'[^\p{L}\s]' explicitly excludes numbers (\p{N}).
            REGEXP_REPLACE(
                LOWER(t1.text),
                r'[^\p{L}\s]', -- Only matches and keeps L (Letter) and s (space)
                ' '
            ),
            r'\S+' -- Pattern to match one or more non-whitespace characters (a word token)
        )
    ) AS word
WHERE
    word <> '' -- Exclude any empty strings that might result from cleaning
    and word not in ('là', 'và', 'của', 'tôi', 'này', 'với', 'rất', 'thật', 
'quá', 'nhưng', 'một', 'sẽ', 'thì', 'đã', 'bị', 'được', 
'các', 'những', 'cái', 'chiếc', 'mà', 'nên', 'vậy', 'chỉ', 
'không', 'khi', 'trong', 'từ', 'cho', 'vì', 'chứ', 'gì',
'rồi', 'luôn', 'sao', 'mình', 'cũng', 'nha', 'anh','em','a','e','t')
GROUP BY
    word
ORDER BY
    so_lan_xuat_hien DESC;