"""Build v2 of the Two-Tank dataset from the published v1 (Zenodo 10.5281/zenodo.17688567).

Usage: python make_v2.py <v1_Dataset_dir> <v2_Dataset_dir>

Corrections (see CHANGELOG.md):
  1. Ki/Kd: v1 logged Ki = Kp/Td and Kd = Kp*Ti (Ti/Td swapped at the PID_dahlin call).
     Since Td = Kp/Ki_v1 and Ti = Kd_v1/Kp, the correct gains are recovered exactly as
     Ki = Kp/Ti = Kp^2/Kd_v1 and Kd = Kp*Td = Kp^2/Ki_v1.
     The first two samples use the fixed start-up PID (Kp=2, Ki=0.1, Kd=0.5) and are kept.
  2. Valve_Closure_pct restored to the originally logged values in the HighOutflow runs.
  3. Files renamed so that X in *_Xpct.csv is always the electrovalve OPENING.
  4. Timestamps normalised to ISO 8601; date typo in the first two rows of the
     2025-09-19 LowOutflow run fixed; trailing empty rows removed.
  5. New columns appended (v1 columns keep their positions): Time_s, Valve_Opening_pct,
     Sensor_Dropout.
"""
import sys, os, glob
import numpy as np
import pandas as pd

SRC, DST = sys.argv[1], sys.argv[2]

# v1 file -> (v2 file, Valve_Closure_pct to use or None to keep)
DISTURBANCE = {
    'Disturbance_HighOutflow_80pct.csv': ('Disturbance_HighOutflow_10pct.csv', 90),   # run 2025-08-05
    'Disturbance_HighOutflow_90pct.csv': ('Disturbance_HighOutflow_100pct.csv', 0),   # run 2025-07-29
    'Disturbance_LowOutflow_50pct.csv': ('Disturbance_LowOutflow_50pct.csv', None),   # run 2025-09-19
    'Disturbance_LowOutflow_60pct..csv': ('Disturbance_LowOutflow_40pct.csv', None),  # run 2025-09-22
}
FILL_THRESHOLD = 5.0  # % level; zeros before the tank first reaches it are genuine (empty tank)


def fmt(x):
    return '' if not np.isfinite(x) else f'{x:.10g}'


log = []
for f in sorted(glob.glob(os.path.join(SRC, '*', '*.csv'))):
    group, name = os.path.basename(os.path.dirname(f)), os.path.basename(f)
    raw = pd.read_csv(f, dtype=str, keep_default_na=False)
    raw = raw[~(raw == '').all(axis=1)].reset_index(drop=True)
    n_empty_removed = sum(1 for _ in open(f, encoding='utf-8')) - 1 - len(raw)

    new_name, closure_override = DISTURBANCE.get(name, (name, None))

    # 4. timestamps
    ts = raw['Timestamp'].str.replace('/ ', ' ', regex=False)
    if name == 'Disturbance_LowOutflow_50pct.csv':
        ts.iloc[1] = ts.iloc[1].replace('2025/09/20', '2025/09/19')
    t = pd.to_datetime(ts, format='%Y/%m/%d %H:%M:%S')
    raw['Timestamp'] = t.dt.strftime('%Y-%m-%d %H:%M:%S')

    # 2. valve
    if closure_override is not None:
        raw['Valve_Closure_pct'] = str(closure_override)
    closure = raw['Valve_Closure_pct'].astype(float)

    # 1. Ki/Kd
    Kp = raw['Kp'].astype(float).values
    Ki1 = raw['Ki'].astype(float).values
    Kd1 = raw['Kd'].astype(float).values
    startup = np.arange(len(raw)) < 2
    with np.errstate(all='ignore'):
        Ki2 = np.where(startup, Ki1, Kp**2 / Kd1)
        Kd2 = np.where(startup, Kd1, Kp**2 / Ki1)
    raw['Ki'] = [fmt(v) for v in Ki2]
    raw['Kd'] = [fmt(v) for v in Kd2]

    # 5. new columns
    L = raw['Level_pct'].astype(float).values
    filled = np.maximum.accumulate(L >= FILL_THRESHOLD)
    raw['Time_s'] = np.arange(len(raw)).astype(str)
    raw['Valve_Opening_pct'] = (100 - closure).map(lambda v: f'{v:g}')
    raw['Sensor_Dropout'] = ((L == 0) & filled).astype(int).astype(str)

    out_dir = os.path.join(DST, group)
    os.makedirs(out_dir, exist_ok=True)
    raw.to_csv(os.path.join(out_dir, new_name), index=False, lineterminator='\n')
    log.append(dict(v1=name, v2=new_name, rows=len(raw), empty_removed=n_empty_removed,
                    closure=closure.iloc[0], opening=100 - closure.iloc[0],
                    dropouts=int(raw['Sensor_Dropout'].astype(int).sum()),
                    nonfinite_gains=int((~np.isfinite(Ki2)).sum() + (~np.isfinite(Kd2)).sum())))

print(pd.DataFrame(log).to_string(index=False))
