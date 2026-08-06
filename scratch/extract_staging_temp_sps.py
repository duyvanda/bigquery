import os
import sys
import json
from datetime import datetime
from google.cloud import bigquery

# Force UTF-8 stdout for Windows CLI
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

# Configuration
CREDENTIALS_PATH = 'D:/bigquery1508.json'
PROJECT_ID = 'spatial-vision-343005'
DATASET_ID = 'staging_temp'
OUTPUT_DIR = r'd:\bigquery\staging_temp_extracted'

def clean_sql_content(sql_text):
    """
    Cleans up excessive empty lines (\n\n\n...) and redundant blank lines
    between SQL columns, DECLARE, SET, WHERE, and CASE statements.
    """
    if not sql_text:
        return ""
    
    # Standardize line endings and strip trailing whitespace
    lines = [line.rstrip() for line in sql_text.replace('\r\n', '\n').split('\n')]
    new_lines = []
    
    for i, line in enumerate(lines):
        stripped = line.strip()
        
        if stripped == '':
            # Get previous non-empty line
            prev_non_empty = ''
            for p in reversed(new_lines):
                if p.strip() != '':
                    prev_non_empty = p.strip()
                    break
            
            # Get next non-empty line
            next_non_empty = ''
            for n in lines[i+1:]:
                if n.strip() != '':
                    next_non_empty = n.strip()
                    break
            
            # Skip empty lines in common SQL clauses & lists
            if prev_non_empty.endswith(',') or prev_non_empty.startswith(('DECLARE', 'SET', 'SELECT', 'FROM', 'WHERE', 'AND', 'OR', 'WHEN', 'THEN', 'ELSE', 'CASE', '--')):
                continue
            
            if next_non_empty.startswith((',', 'THEN', 'ELSE', 'WHEN', 'END', 'AND', 'OR', 'ON', 'FROM', 'WHERE', 'GROUP BY', 'ORDER BY', 'LIMIT')):
                continue

            if prev_non_empty.startswith(('WHEN', 'THEN', 'ELSE', 'CASE', 'DATE_DIFF(', 'DATE(')):
                continue

            # Eliminate consecutive blank lines (max 1 empty line between main blocks)
            if new_lines and new_lines[-1].strip() == '':
                continue

        new_lines.append(line)
        
    return '\n'.join(new_lines)

def extract_stored_procedures(
    credentials_path=CREDENTIALS_PATH,
    project_id=PROJECT_ID,
    dataset_id=DATASET_ID,
    output_dir=OUTPUT_DIR
):
    print("=" * 60)
    print(f" EXTRACTING ALL ROUTINES / STORED PROCEDURES FROM BIGQUERY")
    print(f" Dataset: `{project_id}.{dataset_id}`")
    print(f" Target Directory: {output_dir}")
    print("=" * 60 + "\n")

    # Set authentication
    if os.path.exists(credentials_path):
        os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = credentials_path
    else:
        print(f"[!] Warning: Credentials file not found at '{credentials_path}'. Using default environment auth.")

    client = bigquery.Client(project=project_id)

    # Query INFORMATION_SCHEMA.ROUTINES
    query = f"""
    SELECT 
        routine_name,
        routine_type,
        created,
        last_altered,
        routine_definition,
        ddl
    FROM `{project_id}.{dataset_id}.INFORMATION_SCHEMA.ROUTINES`
    ORDER BY routine_name ASC
    """

    print("Executing query on INFORMATION_SCHEMA.ROUTINES...")
    try:
        results = list(client.query(query).result())
        print(f"-> Found total {len(results)} routines in dataset `{dataset_id}`.\n")
    except Exception as e:
        print(f"[!] Error fetching routines from BigQuery: {e}")
        return

    # Create output directory
    os.makedirs(output_dir, exist_ok=True)

    manifest = []
    success_count = 0
    error_count = 0

    for idx, row in enumerate(results, 1):
        routine_name = row.routine_name
        routine_type = row.routine_type
        created_str = str(row.created) if row.created else "Unknown"
        last_altered_str = str(row.last_altered) if row.last_altered else "Unknown"

        # Determine SQL content
        sql_content = row.ddl
        if not sql_content and row.routine_definition:
            sql_content = f"-- Definition for {routine_type} {routine_name}\n{row.routine_definition}"
        
        if not sql_content:
            print(f" [{idx}/{len(results)}] ⚠️ Skipping {routine_name}: No DDL or definition available.")
            error_count += 1
            continue

        # Clean redundant blank lines / newline padding
        sql_content = clean_sql_content(sql_content)

        # Format header in SQL file
        header = (
            f"-- ==========================================================================\n"
            f"-- Routine Name : {routine_name}\n"
            f"-- Routine Type : {routine_type}\n"
            f"-- Dataset      : {project_id}.{dataset_id}\n"
            f"-- Created      : {created_str}\n"
            f"-- Last Altered : {last_altered_str}\n"
            f"-- Extracted At : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
            f"-- ==========================================================================\n\n"
        )
        full_file_content = header + sql_content.strip() + "\n"

        # Save to file
        file_name = f"{routine_name}.sql"
        file_path = os.path.join(output_dir, file_name)

        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(full_file_content)
            
            success_count += 1
            manifest.append({
                "routine_name": routine_name,
                "routine_type": routine_type,
                "created": created_str,
                "last_altered": last_altered_str,
                "file_name": file_name,
                "file_path": file_path,
                "size_bytes": len(full_file_content.encode('utf-8'))
            })
            if idx % 20 == 0 or idx == len(results):
                print(f" Progress: [{idx}/{len(results)}] Processed routines...")
        except Exception as e:
            print(f" [{idx}/{len(results)}] ❌ Error saving {file_name}: {e}")
            error_count += 1

    # Save Manifest Summary JSON
    manifest_path = os.path.join(output_dir, 'manifest_routines.json')
    with open(manifest_path, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)

    print("\n" + "=" * 60)
    print(" EXTRACTION COMPLETED SUMMARY")
    print(f" Total Routines Found  : {len(results)}")
    print(f" Successfully Exported : {success_count}")
    print(f" Failed / Skipped      : {error_count}")
    print(f" Output Folder         : {os.path.abspath(output_dir)}")
    print(f" Manifest File         : {os.path.abspath(manifest_path)}")
    print("=" * 60 + "\n")

if __name__ == '__main__':
    extract_stored_procedures()
