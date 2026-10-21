"""Shared loader for the v2 dataset (Zenodo 10.5281/zenodo.23529910, version 2.0)."""
import glob
import os

import pandas as pd

GROUPS = ('Baseline', 'PassiveOutflow', 'Disturbance')
DYNAMIC_FEATURES = ['Level_pct', 'Control_Signal_pct', 'Setpoint_pct', 'Error_pct',
                    'Valve_Opening_pct', 'Kp', 'Ki', 'Kd', 'b1', 'a1', 'a2']


def load_group(dataset_dir, group, pattern='*.csv', drop_dropouts=True):
    """Concatenate the CSV files of one experiment group, keeping each run in time order.

    Rows are ordered by file and Time_s (not by Timestamp: Baseline timestamps only have
    minute resolution). Sensor dropouts (Level_pct == 0 readings) are removed if requested.
    """
    files = sorted(glob.glob(os.path.join(dataset_dir, group, pattern)))
    if not files:
        raise FileNotFoundError(f'No CSV files found in {os.path.join(dataset_dir, group)}')
    frames = []
    for f in files:
        df = pd.read_csv(f)
        df['File'] = os.path.splitext(os.path.basename(f))[0]
        frames.append(df)
    data = pd.concat(frames, ignore_index=True)
    if drop_dropouts:
        data = data[data['Sensor_Dropout'] == 0].reset_index(drop=True)
    return data
