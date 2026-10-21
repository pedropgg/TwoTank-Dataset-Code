# TwoTank-Dataset-Code: Adaptive Control & Anomaly Detection

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Source code for data acquisition, real-time adaptive control and technical validation of the Data Descriptor:

> Gómez-González, P.-P., Michelena, Á., García Fischer, A., Freire-Mahía, N., Jove, E. & Calvo-Rolle, J. L.
> **Multi-scenario datasets for system identification and adaptive control of a nonlinear two tank system.**
> *Scientific Data* 13, 1465 (2026). https://doi.org/10.1038/s41597-026-07686-2

The dataset (25 closed-loop runs, 765 000 samples at 1 Hz) is hosted on Zenodo:
**https://doi.org/10.5281/zenodo.17688566** (all versions). Use **version 2.0**, which corrects the logged
`Ki`/`Kd` gains and the valve metadata of version 1.0. See the dataset `CHANGELOG.md` and [Changes](#changes-in-this-version).

## Repository structure

| Path | Content |
|---|---|
| `MATLAB_Control/` | Acquisition and control scripts: RLS identification (`RLS.m`), Dahlin self-tuning PID (`PID_dahlin.m`), serial DAQ interface (`DAQ_*.m`) and one script per experiment type. See its [README](MATLAB_Control/README.md). |
| `Arduino Firmware/TwoTank_DAQ_reconstructed/` | Reconstructed DAQ firmware implementing the serial protocol used by the MATLAB scripts (see note below). |
| `Python_Validation/` | Technical validation on dataset v2: `eda.py` (exploratory analysis) and `ocsvm_anomaly.py` (One-Class SVM anomaly detection). |
| `Python_Validation/legacy_v1/` | Original EDA notebooks used for the paper, kept for reference (outputs removed). They expect dataset v1 files in the working folder. |
| `tools/` | `make_v2.py` builds dataset v2 from v1; `verify_v2.py` checks v2 against v1. |

## Quick start (Python)

```bash
pip install -r requirements.txt
# download and unzip the dataset v2 from Zenodo, then:
cd Python_Validation
python eda.py path/to/Dataset Baseline
python eda.py path/to/Dataset Disturbance --pattern "Disturbance_LowOutflow_*"
python ocsvm_anomaly.py path/to/Dataset               # reproduces Table 11 of the paper
python ocsvm_anomaly.py path/to/Dataset --window 120  # rolling-window features
```

## Control loop summary

Every second (Ts = 1 s): read level → RLS update of `y(k) = -a1·y(k-1) - a2·y(k-2) + b1·u(k-2)` (forgetting
factor 0.9) → Dahlin PID gains (λ = 3.0) → incremental PID → saturation to [0, 100] % → pump command.
Note the **two-sample input delay** of the identified model; Eq. (1) of the paper writes `b1·z⁻¹`.

## Notes and known limitations

- **Firmware.** The firmware used during the 2025 experiments is not available. The sketch in
  `Arduino Firmware/` is a reference re-implementation of the protocol expected by `DAQ_Read.m` / `DAQ_Write.m`
  (command 136: send two 8-bit analog readings; command 65 + 2 bytes: set two PWM outputs). Pin assignments
  and PWM frequency are assumptions, and it has not yet been compiled or tested on the plant.
- **Anomaly detection.** The original One-Class SVM code is not available. `ocsvm_anomaly.py` re-implements
  the experiment: train on the 10 Baseline runs, test on one outflow-increase run, ground truth = `perturbation`.
  The paper's test run is `Disturbance_LowOutflow_40pct.csv` in dataset v2 (electrovalve opening 40 %). Its
  3616 disturbance samples match Table 11. The paper calls it the "50 %" run because the validation notebooks
  subtracted 10 from the logged closure (60 %). On that run the paper's result is reproduced:

  | Configuration | Accuracy | Anomaly precision | Anomaly recall |
  |---|---|---|---|
  | Paper (Table 11) | 0.98 | 0.85 | 1.00 |
  | Process signals, ν = 0.01 (default) | 0.990 | 0.925 | 0.997 |
  | Rolling mean/std, 120 s window (`--window 120`) | 0.983 | 0.878 | 0.996 |

  On the other outflow-increase run (`--test-file Disturbance_LowOutflow_50pct.csv`), recall stays below 0.55
  for every configuration tried, with or without rolling windows. The controller rejects that disturbance
  quickly, so it leaves only a small signature in the signals. Results vary slightly with `--seed`.
- `MATLAB_Control` uses the legacy `serial` interface, which recent MATLAB releases replace with `serialport`.

## Changes in this version

- `DAQ_*.m`: fixed the output order of `PID_dahlin` (`[u, Kp, Td, Ti]`). The previous order swapped Ti and Td in
  the logged `Ki`/`Kd` columns. The control action applied to the plant was not affected.
- `DAQ_*.m`: `Valve_Closure_pct` logs the electrovalve closure, and output files are named after the opening
  (100 − closure), as in dataset v2. Removed the commented-out sample-rectification block, which was not used.
- Replaced the unrelated encoder firmware with the reconstructed DAQ firmware.
- New validation scripts for dataset v2; legacy notebooks moved to `Python_Validation/legacy_v1/` with outputs removed.
- Added `tools/`, `requirements.txt` and `CITATION.cff`.

## How to cite

Please cite the paper above and the dataset (see `CITATION.cff`).

## License

Code: MIT. Dataset: CC BY 4.0.
