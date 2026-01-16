# TwoTank-Dataset-Code: Adaptive Control & Anomaly Detection

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This repository contains the source code used for data acquisition, real-time control, and technical validation described in the Data Descriptor paper: **"Multi-scenario datasets for system identification and adaptive control of a nonlinear two tank system"**.

This code accompanies the dataset, which captures the dynamics of a nonlinear two-tank system under various regimes, including laminar flow, turbulence (saturation), and abrupt hydraulic faults.

## Data Access
The complete dataset (CSV files) is publicly hosted on Zenodo:

**[Download the Dataset here (DOI: 10.5281/zenodo.17688566)](https://doi.org/10.5281/zenodo.17688566)**

## Repository Structure

```text
TwoTank-Dataset-Code/
│
├── Arduino_Firmware/        # C++ code for ESP32/Arduino interface
│   └── Interface_Control.ino
│
├── MATLAB_Control/          # Real-time control & Data Acquisition
│   ├── Control_Scheme.slx   # Simulink model (RLS Estimator + Adaptive PID)
│   └── Main_Supervisory.m   # Initialization and supervisory script
│
├── Python_Validation/       # Technical Validation & Analysis
│   ├── requirements.txt     # Python dependencies
│   ├── 1_EDA_Analysis.ipynb # Exploratory Data Analysis (Histograms, Correlations)
│   └── 2_Anomaly_SVM.ipynb  # One-Class SVM for Fault Detection
│
├── LICENSE                  # MIT License
└── README.md                # This file
