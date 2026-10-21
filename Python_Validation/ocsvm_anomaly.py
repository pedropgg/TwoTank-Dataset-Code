"""One-Class SVM anomaly detection baseline (Technical Validation, "Baseline Anomaly Detection").

Usage: python ocsvm_anomaly.py <Dataset_dir> [--features ...] [--nu 0.01] [--n-train 20000] [--seed 0]

Trains on the 10 Baseline runs (normal operation) and tests on the outflow-increase run with
the electrovalve at 50% opening (Disturbance_LowOutflow_50pct.csv). Ground truth: the
'perturbation' flag. Sensor dropouts are excluded from training and testing.

NOTE: the original validation code is not available. This script re-implements the experiment
as described in the paper; the feature set and hyperparameters are not reported there, so the
defaults below are a choice, and the results differ from Table 11 of the paper (see README).
"""
import argparse
import os

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
from sklearn.metrics import ConfusionMatrixDisplay, classification_report, confusion_matrix
from sklearn.preprocessing import StandardScaler
from sklearn.svm import OneClassSVM

from common import load_group

DEFAULT_FEATURES = ['Level_pct', 'Control_Signal_pct', 'Setpoint_pct', 'Error_pct', 'Valve_Opening_pct']


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('dataset_dir')
    ap.add_argument('--features', nargs='+', default=DEFAULT_FEATURES)
    ap.add_argument('--nu', type=float, default=0.01)
    ap.add_argument('--n-train', type=int, default=20000, help='random subsample of the Baseline data')
    ap.add_argument('--seed', type=int, default=0)
    ap.add_argument('--out', default='OCSVM_results')
    args = ap.parse_args()

    train = load_group(args.dataset_dir, 'Baseline')
    test = load_group(args.dataset_dir, 'Disturbance', 'Disturbance_LowOutflow_50pct.csv')
    rng = np.random.default_rng(args.seed)
    train = train.iloc[rng.choice(len(train), min(args.n_train, len(train)), replace=False)]

    scaler = StandardScaler().fit(train[args.features])
    model = OneClassSVM(kernel='rbf', nu=args.nu, gamma='scale').fit(scaler.transform(train[args.features]))
    y_true = test['perturbation'].astype(int).values
    y_pred = (model.predict(scaler.transform(test[args.features])) == -1).astype(int)

    os.makedirs(args.out, exist_ok=True)
    report = classification_report(y_true, y_pred, target_names=['Normal', 'Anomaly'], digits=3)
    header = (f'Features: {args.features}\nnu={args.nu}, gamma=scale, n_train={len(train)}, seed={args.seed}\n'
              f'Test samples: {len(test)}, anomalous: {y_true.sum()}\n\n')
    with open(os.path.join(args.out, 'classification_report.txt'), 'w', encoding='utf-8') as f:
        f.write(header + report)
    print(header + report)

    ConfusionMatrixDisplay(confusion_matrix(y_true, y_pred), display_labels=['Normal', 'Anomaly']).plot(cmap='Blues')
    plt.title('One-Class SVM: Baseline (train) vs LowOutflow 50% (test)')
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
