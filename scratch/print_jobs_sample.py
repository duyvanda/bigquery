import os, sys
sys.stdout.reconfigure(encoding='utf-8')
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = 'D:/bigquery1508.json'
from google.cloud import bigquery
client = bigquery.Client(project='spatial-vision-343005')

# Tim job co sp_f_baocao_phanbothau
sql = """
    SELECT query, creation_time, statement_type, user_email
    FROM `region-asia-southeast1`.INFORMATION_SCHEMA.JOBS
    WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 180 DAY)
      AND LOWER(query) LIKE '%sp_f_baocao_phanbothau%'
    ORDER BY creation_time DESC
    LIMIT 5
"""
rows = list(client.query(sql).result())
print(f'So records co sp_f_baocao_phanbothau: {len(rows)}')
for i, row in enumerate(rows):
    print(f'--- #{i+1} [{row.statement_type}] {row.creation_time} ---')
    print(row.query[:500])
    print()
