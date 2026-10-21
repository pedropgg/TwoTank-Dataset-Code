"""Verify v2 against v1. Usage: python verify_v2.py <v1_Dataset_dir> <v2_Dataset_dir>"""
import sys, os, glob
import numpy as np
import pandas as pd

V1, V2 = sys.argv[1], sys.argv[2]
NAME_MAP = {
    'Disturbance_HighOutflow_80pct.csv': 'Disturbance_HighOutflow_10pct.csv',
    'Disturbance_HighOutflow_90pct.csv': 'Disturbance_HighOutflow_100pct.csv',
    'Disturbance_LowOutflow_60pct..csv': 'Disturbance_LowOutflow_40pct.csv',
}
UNCHANGED = ['Level_pct', 'Control_Signal_pct', 'Setpoint_pct', 'Error_pct', 'Kp', 'b1', 'a1', 'a2']
Q = 1 - np.exp(-1 / 3.0)
rows = []
for f1 in sorted(glob.glob(os.path.join(V1, '*', '*.csv'))):
    g, n1 = os.path.basename(os.path.dirname(f1)), os.path.basename(f1)
    n2 = NAME_MAP.get(n1, n1)
    a = pd.read_csv(f1, dtype=str, keep_default_na=False)
    a = a[~(a == '').all(axis=1)].reset_index(drop=True)
    b = pd.read_csv(os.path.join(V2, g, n2), dtype=str, keep_default_na=False)
    cols = UNCHANGED + (['perturbation'] if 'perturbation' in a else [])
    r = {'v2_file': n2, 'rows_equal': len(a) == len(b),
         'v1_cols_in_place': list(b.columns[:a.shape[1]]) == list(a.columns),
         'unchanged_cols_identical': bool((a[cols] == b[cols]).all().all())}
    ts = pd.to_datetime(b['Timestamp'], format='%Y-%m-%d %H:%M:%S')
    r['ts_iso_ok'] = ts.notna().all()
    r['ts_monotonic'] = bool((ts.diff().dropna().dt.total_seconds() >= 0).all())
    num = b.apply(pd.to_numeric, errors='coerce')
    a1, a2, b1, Kp, Ki, Kd = (num[c].values for c in ['a1', 'a2', 'b1', 'Kp', 'Ki', 'Kd'])
    with np.errstate(all='ignore'):
        Kpc = -(a1 + 2 * a2) * Q / b1
        Td = a2 * Q / (Kpc * b1)
        Ti = -1 / (1 / (a1 + 2 * a2) + 1 + Td)
    s = np.arange(len(b)) >= 2
    rel = lambda x, y: np.abs(x - y) / np.maximum(np.abs(y), 1e-9)
    r['Ki_vs_Dahlin_rel<1e-4_%'] = round(100 * np.mean(rel(Ki, Kpc / Ti)[s] < 1e-4), 2)
    r['Kd_vs_Dahlin_rel<1e-4_%'] = round(100 * np.mean(rel(Kd, Kpc * Td)[s] < 1e-4), 2)
    r['Ki_vs_Dahlin_rel<1e-2_%'] = round(100 * np.mean(rel(Ki, Kpc / Ti)[s] < 1e-2), 2)
    r['Kd_vs_Dahlin_rel<1e-2_%'] = round(100 * np.mean(rel(Kd, Kpc * Td)[s] < 1e-2), 2)
    r['Ki_median'] = round(np.median(Ki[s]), 3)
    r['Kd_median'] = round(np.median(Kd[s]), 3)
    r['opening+closure=100'] = bool((num['Valve_Opening_pct'] + num['Valve_Closure_pct'] == 100).all())
    r['name_X==opening'] = int(n2.rsplit('_', 1)[1].replace('pct.csv', '')) == int(num['Valve_Opening_pct'].iloc[0])
    r['Time_s_ok'] = bool((num['Time_s'].values == np.arange(len(b))).all())
    r['dropouts'] = int(num['Sensor_Dropout'].sum())
    r['dropout_level_zero'] = bool((num.loc[num.Sensor_Dropout == 1, 'Level_pct'] == 0).all())
    rows.append(r)
df = pd.DataFrame(rows).set_index('v2_file')
pd.set_option('display.width', 250)
print(df.to_string())
bools = df.select_dtypes(bool)
print('\nALL BOOLEAN CHECKS PASS:', bool(bools.all().all()))
if not bools.all().all():
    print(bools.loc[~bools.all(axis=1), ~bools.all(axis=0)])
