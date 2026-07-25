CREATE VIEW `spatial-vision-343005.warehouse.view_d_eleven_list_conversation_details`
AS select a.*, row_number() over (order by null) as stt from (

SELECT
t.conversation_id,
JSON_VALUE(js.conversation_initiation_client_data.dynamic_variables.custid) AS custid,
JSON_VALUE(js.conversation_initiation_client_data.dynamic_variables.name) AS name,
JSON_VALUE(js.analysis.transcript_summary) AS transcript_summary,
JSON_VALUE(g,"$.message") AS message,
JSON_VALUE(g,"$.role") AS role,
c.start_time_utc,
c.call_duration_secs,
c.message_count,
c.status,
CONCAT('https://bi.meraplion.com/DMS/omcs_data/audio_file/',t.conversation_id,'.mp3') as audio_link
FROM `spatial-vision-343005.staging.d_eleven_list_conversation_details` t ,
UNNEST(JSON_QUERY_ARRAY(t.js, "$.transcript")) AS g
LEFT JOIN staging.d_eleven_list_conversations c ON t.conversation_id = c.conversation_id
-- where t.conversation_id = 'conv_0901k5947er6ffh9pck7nxd2zn54'
) a
;