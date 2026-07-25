import os
import glob
import re

active_job_file = r'd:\bigquery\sp_handle\call_active_job.md'
active_sps = set()

with open(active_job_file, 'r', encoding='utf-8') as f:
    text = f.read()

# Pattern match CALL ...
lines = text.split('\n')
for line in lines:
    calls = line.split(';')
    for c in calls:
        c = c.strip()
        if 'CALL' in c.upper():
            parts = c.split('.')
            if len(parts) >= 2:
                sp_name = parts[-1].replace('`', '').replace('()', '').strip().lower()
                if sp_name:
                    active_sps.add(sp_name)

print(f"Total Active SPs in call_active_job.md: {len(active_sps)}")
print("Is 'sp_f_so_sanh_toa_do_longchau_hn' in Active SPs list?", 'sp_f_so_sanh_toa_do_longchau_hn' in active_sps)

# Now check which SP files in staging_temp match Active SPs
sp_files = glob.glob(r'd:\bigquery\staging_temp\*.sql')
active_sp_files = []
inactive_sp_files = []

for sf in sp_files:
    fname = os.path.splitext(os.path.basename(sf))[0].lower()
    if fname in active_sps:
        active_sp_files.append(sf)
    else:
        inactive_sp_files.append(sf)

print(f"SP SQL files matching Active SPs: {len(active_sp_files)}")
print(f"SP SQL files matching Inactive SPs: {len(inactive_sp_files)}")

# Check if d_manual_toa_do_nt_long_chau_hn is referenced in ACTIVE SP files
referenced_in_active_sp = False
for sf in active_sp_files:
    with open(sf, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read().lower()
    if 'd_manual_toa_do_nt_long_chau_hn' in content:
        print(f"Found reference in ACTIVE SP: {os.path.basename(sf)}")
        referenced_in_active_sp = True

if not referenced_in_active_sp:
    print("\n[RESULT] Table 'd_manual_toa_do_nt_long_chau_hn' is NOT referenced in any ACTIVE SP!")
