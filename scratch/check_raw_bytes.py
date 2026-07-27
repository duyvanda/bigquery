with open(r"d:\bigquery\staging_table\csv\d_gia_von_vttd.csv", "rb") as f:
    lines = [f.readline() for _ in range(5)]
for idx, line in enumerate(lines):
    print(f"Line {idx+1}: {line}")
