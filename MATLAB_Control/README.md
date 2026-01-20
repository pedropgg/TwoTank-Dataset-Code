# TwoTank Dataset - MATLAB Control

Quick guide to run the experiments and log data for the two-tank system using MATLAB and an Arduino-based DAQ.

## Requirements
- MATLAB with Instrument Control toolbox access (to use `serial`).
- Arduino on `COM6` at 115200 baud (adjust the port in `DAQ_Start.m` if needed).
- Hardware connected to the two-tank setup (sensors on analog channels 0 and 1, actuators on PWM outputs).

## General flow
1) Connect the Arduino and the physical setup.
2) Run one of the acquisition scripts listed below. Each one starts the DAQ (`DAQ_Start`), runs the control loop with 1 s sampling, sweeps the setpoints (10–90%), logs data, and stops the DAQ (`DAQ_Stop`).
3) The script automatically writes a CSV with measurements and identified/controlled parameters for that experiment condition.

## Acquisition scripts
- `DAQ_Baseline.m`: baseline scenario with the manual valve fully closed. Dahlin PID + RLS identify the process online and save `Baseline_<valve>pct.csv`.
- `DAQ_HighOutflow.m`: disturbance scenario with reduced outflow. Adds a `perturbation` column; toggle it by pressing any key in the figure to mark perturbations. Produces `Disturbance_HighOutflow_<valve>pct.csv`.
- `DAQ_LowOutflow.m`: disturbance scenario with increased outflow. Same behavior as above: lets you flag perturbations via the window and saves `Disturbance_LowOutflow_<valve>pct.csv`.
- `DAQ_PassiveOutflow.m`: scenario where the manual valve keeps a fixed opening throughout the experiment. Dahlin PID + RLS identify the process online and save `PassiveOutflow_<valve>pct.csv`.

## Logged columns
`Timestamp`, `Valve_Closure_pct`, `Level_pct`, `Control_Signal_pct`, `Setpoint_pct`, `Error_pct`, `Kp`, `Ki`, `Kd`, `b1`, `a1`, `a2` and, when applicable, `perturbation`.

## Quick notes
- The loop uses 1 s sampling and 30 minutes per setpoint (10–90%). Adjust `Sample_Time` or `time_per_setpoint` in the scripts if you need a different duration.
- If the serial port is not `COM6`, update `DAQ_Start.m`.
- Control values are saturated between 0 and 100% before sending to the Arduino.
