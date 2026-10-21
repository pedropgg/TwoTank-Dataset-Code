"""One-Class SVM anomaly detection baseline (Technical Validation, "Baseline Anomaly Detection").

Usage: python ocsvm_anomaly.py <Dataset_dir> [--test-file NAME] [--features ...] [--nu 0.01]
                               [--window 0] [--n-train 20000] [--seed 0]

Trains on the 10 Baseline runs (normal operation) and tests on one outflow-increase run.
Ground truth: the 'perturbation' flag. Sensor dropouts are excluded from training and testing.

The paper's test run is Disturbance_LowOutflow_40pct.csv in dataset v2 (electrovalve closure 60 %,
opening 40 %; its 3616 disturbance samples match Table 11). The paper labels it "50 %" because the
validation notebooks subtracted 10 from the valve value. With the defaults below (process signals,
nu = 0.01) the paper's result is reproduced: accuracy ~0.99, anomaly recall ~1.00.
On the other outflow-increase run (--test-file Disturbance_LowOutflow_50pct.csv) recall stays
below ~0.55 for every configuration tried, with or without rolling windows.

--window W > 0 replaces each process signal with its causal rolling mean and standard deviation
over the last W samples, computed separately for each run.
"""
import argparse
import os

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from sklearn.metrics import ConfusionMatrixDisplay, classification_report, confusion_matrix
from sklearn.preprocessing import StandardScaler
from sklearn.svm import OneClassSVM

from common import load_group

DEFAULT_FEATURES = ['Level_pct', 'Control_Signal_pct', 'Setpoint_pct', 'Error_pct']
ROLLED = ['Level_pct', 'Control_Signal_pct', 'Error_pct']


def build_features(data, features, window):
    if window <= 0:
        return data[features]
    X = data[[c for c in features if c not in ROLLED]].copy()
    for col in [c for c in features if c in ROLLED]:
        rolling = data.groupby('File')[col].rolling(window, min_periods=1)
        X[f'{col}_mean{window}'] = rolling.mean().reset_index(level=0, drop=True)
        X[f'{col}_std{window}'] = rolling.std().reset_index(level=0, drop=True).fillna(0)
    return X


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('dataset_dir')
    ap.add_argument('--test-file', default='Disturbance_LowOutflow_40pct.csv')
    ap.add_argument('--features', nargs='+', default=DEFAULT_FEATURES)
    ap.add_argument('--nu', type=float, default=0.01)
    ap.add_argument('--window', type=int, default=0, help='rolling window in samples (0 = none)')
    ap.add_argument('--n-train', type=int, default=20000, help='random subsample of the Baseline data')
    ap.add_argument('--seed', type=int, default=0)
    ap.add_argument('--out', default='OCSVM_results')
    args = ap.parse_args()

    train = load_group(args.dataset_dir, 'Baseline')
    test = load_group(args.dataset_dir, 'Disturbance', args.test_file)
    X_train = build_features(train, args.features, args.window)
    X_test = build_features(test, args.features, args.window)
    rng = np.random.default_rng(args.seed)
    X_train = X_train.iloc[rng.choice(len(X_train), min(args.n_train, len(X_train)), replace=False)]

    scaler = StandardScaler().fit(X_train)
    model = OneClassSVM(kernel='rbf', nu=args.nu, gamma='scale').fit(scaler.transform(X_train))
    y_true = test['perturbation'].astype(int).values
    y_pred = (model.predict(scaler.transform(X_test)) == -1).astype(int)

    os.makedirs(args.out, exist_ok=True)
    report = classification_report(y_true, y_pred, target_names=['Normal', 'Anomaly'], digits=3)
    header = (f'Test file: {args.test_file}\nFeatures: {list(X_train.columns)}\n'
              f'nu={args.nu}, gamma=scale, window={args.window}, n_train={len(X_train)}, seed={args.seed}\n'
              f'Test samples: {len(test)}, anomalous: {y_true.sum()}\n\n')
    with open(os.path.join(args.out, 'classification_report.txt'), 'w', encoding='utf-8') as f:
        f.write(header + report)
    print(header + report)

    ConfusionMatrixDisplay(confusion_matrix(y_true, y_pred), display_labels=['Normal', 'Anomaly']).plot(cmap='Blues')
    plt.title(f'One-Class SVM: Baseline (train) vs {os.path.splitext(args.test_file)[0]} (test)', fontsize=9)
    plt.tight_layout()
    plt.savefig(os.path.join(args.out, 'confusion_matrix.png'), dpi=120)

    fig, ax = plt.subplots(figsize=(14, 4))
    t = test['Time_s'].values / 3600
    ax.plot(t, test['Level_pct'], lw=0.6, label='Level_pct')
    ax.plot(t, test['Setpoint_pct'], lw=0.8, label='Setpoint_pct')
    ax.fill_between(t, 0, 100, where=y_true == 1, color='orange', alpha=0.2, label='perturbation')
    ax.scatter(t[y_pred == 1], np.full((y_pred == 1).sum(), 98), s=2, color='red', label='flagged')
    ax.set_xlabel('Time (h)')
    ax.set_ylabel('%')
    ax.legend(loc='lower right')
    plt.tight_layout()
    plt.savefig(os.path.join(args.out, 'detections_timeline.png'), dpi=120)
    print(f'Results written to {os.path.abspath(args.out)}')


if __name__ == '__main__':
    main()
