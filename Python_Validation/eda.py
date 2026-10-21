"""Exploratory data analysis of one experiment group (Technical Validation section).

Usage: python eda.py <Dataset_dir> <Baseline|PassiveOutflow|Disturbance> [--pattern GLOB] [--out DIR]

Writes descriptive statistics, coherence checks and figures (time series, distributions,
correlation matrix) to the output folder.
"""
import argparse
import os

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns

from common import DYNAMIC_FEATURES, GROUPS, load_group


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('dataset_dir')
    ap.add_argument('group', choices=GROUPS)
    ap.add_argument('--pattern', default='*.csv', help="file filter, e.g. 'Disturbance_LowOutflow_*'")
    ap.add_argument('--out', default=None)
    args = ap.parse_args()

    out = args.out or f'EDA_{args.group}'
    os.makedirs(out, exist_ok=True)
    data = load_group(args.dataset_dir, args.group, args.pattern)

    lines = [f'EDA report: {args.group} ({args.pattern})',
             f"Files: {', '.join(data['File'].unique())}",
             f'Samples (sensor dropouts removed): {len(data)}', '',
             'Descriptive statistics', data[DYNAMIC_FEATURES].describe().to_string(), '']
    err = (data['Error_pct'] - (data['Setpoint_pct'] - data['Level_pct'])).abs().max()
    lines.append(f'Coherence: max |Error_pct - (Setpoint_pct - Level_pct)| = {err:.2e}')
    with open(os.path.join(out, 'eda_report.txt'), 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n')

    axes = data[DYNAMIC_FEATURES].plot(subplots=True, figsize=(16, 2 * len(DYNAMIC_FEATURES)), legend=False)
    for ax, col in zip(axes, DYNAMIC_FEATURES):
        ax.set_ylabel(col, rotation=0, ha='right')
    axes[-1].set_xlabel('Sample (runs concatenated in file order)')
    plt.tight_layout()
    plt.savefig(os.path.join(out, 'eda_01_time_series.png'), dpi=120)
    plt.close('all')

    n_rows = (len(DYNAMIC_FEATURES) + 1) // 2
    axes = data[DYNAMIC_FEATURES].hist(bins=50, figsize=(12, 3 * n_rows), layout=(n_rows, 2))
    for ax in axes.flatten():
        if ax.get_title() == 'Error_pct':
            ax.set_xlim(-10, 10)
    plt.tight_layout()
    plt.savefig(os.path.join(out, 'eda_02_distributions.png'), dpi=120)
    plt.close('all')

    plt.figure(figsize=(10, 8))
    sns.heatmap(data[DYNAMIC_FEATURES].corr(), annot=True, fmt='.2f', cmap='coolwarm', vmin=-1, vmax=1)
    plt.title(f'Correlation matrix: {args.group}')
    plt.tight_layout()
    plt.savefig(os.path.join(out, 'eda_03_correlation.png'), dpi=120)
    plt.close('all')
    print(f'Results written to {os.path.abspath(out)}')


if __name__ == '__main__':
    main()
