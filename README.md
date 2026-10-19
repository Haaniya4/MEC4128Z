# MEC4128Z Final Year Project

**Title:** Dynamic Performance Modelling and Energy Optimisation of a Battery-Powered 
Quadcopter Using MATLAB  
**Project:** 135  
**Author:** Haaniya Carelse (CRLHAA001)  
**Supervisor:** Dr A. Pretorious  
**Date:** 20 October 2026

## 1. Overview

This repository contains the Simulink models, MATLAB scripts and data used in the report. 
The model couples a planar (x, z, pitch) quadcopter model to a first-order Thevenin battery 
model of a Tattu R-Line 550 mAh 3S LiPo pack, through a propulsion model based on the 
T-Motor F1203 7000 KV motor data. Battery parameters were identified from HPPC tests on a 
Regatron battery emulator.

## 2. Requirements

- MATLAB R2025b
- Simulink
- Simscape
- Simscape Battery
- Microsoft Excel (propulsion parameter calculations only)

## 3. Folder contents

```
CRLHAA001_Quadcopter_Battery_Model/
├── CRLHAA001 - Motor Data.xlsx        Manufacturer's test data and the k_f, k_tau,
│                                      K_v and R_int calculations (LINEST fit)
└── Seven iteration/
    ├── Quadcopter/
    │   ├── Quadcopter_2DoF_Model_7_a.slx   Coupled quadcopter-battery Simulink model
    │   │                                   (includes the thrust_vector, thrust_feedback,
    │   │                                   p_e_interface and emergency_stop blocks)
    │   ├── Quadcopter_2DoF_Model_7_b.slx   Same model with the battery replaced by an
    │   │                                   ideal 12.6 V source
    │   ├── mission_config.m                Defines the mission profiles (fast_move and
    │   │                                   endurance) and sets the stop time
    │   ├── repeated_flight_sim.m           Runs the fast-move mission over a range of
    │   │                                   starting SOCs and classifies each run as
    │   │                                   Completed, Emergency or Crash
    │   └── soc_sweep_results.mat / .csv    Results of the starting-SOC sweep
    │                                       (created by repeated_flight_sim.m)
    └── Battery_data/
        └── output/
            ├── data_extraction.m           Loads the HPPC logs, extracts OCV, R0, R1,
            │                               C1 and tau1, fits them against SOC and saves
            │                               the lookup tables
            ├── all_sessions.xlsx           HPPC logs from the emulator, one sheet per
            │                               SOC step
            ├── hppc_data.mat               Processed HPPC records and OCV-SOC points
            └── hppc_params.mat             Fitted curves and lookup tables loaded by
                                            the model
```

## 4. How to run

1. **Keep the folder structure above.** `Battery_data` must sit next to `Quadcopter` 
inside `Seven iteration`. The model's InitFcn (*Model Settings > Model Properties > Callbacks > InitFcn*) 
adds both folders to the MATLAB path automatically.

2. **Battery parameters** (only needed if `hppc_params.mat` is missing): 
run `Battery_data/output/data_extraction.m`. This reads `all_sessions.xlsx` 
and saves `hppc_params.mat`. R0 is capped at 51 mΩ, the highest value measured on 
the physical pack.

3. **Single mission:** open `Quadcopter/Quadcopter_2DoF_Model_7_a.slx` and press **Run**. 
The InitFcn sets the vehicle parameters, loads the battery lookup tables and loads the 
mission.
   - To change the mission, edit the InitFcn line
```matlab
     mis = mission_config('fast_move', false);
```
     replacing `'fast_move'` with `'endurance'`.
   - The starting SOC defaults to 1.0. To change it, set it in the Command Window before 
running, e.g. `soc0 = 0.3;`. 
Type `clear soc0` afterwards to return to the default.

4. **Ideal-source comparison:** open `Quadcopter/Quadcopter_2DoF_Model_7_b.slx` and run the fast-move mission from full charge. 
Compare the energy used with the result from model 7_a.

5. **Starting-SOC sweep:** set MATLAB's current folder to `Seven iteration/Quadcopter` 
and run `repeated_flight_sim.m`. It runs model 7_a from SOC 1.0 to 0.3 in steps of 0.1, then in steps of 0.01 near the 
lowest completed SOC, and saves `soc_sweep_results.mat` and `.csv`.

## 5. Settings and notes

- **Vehicle mass:** `m = 0.1207` kg in the InitFcn is the total mass of the 
vehicle (0.075 kg) and battery (0.0457 kg).
- **Failsafe trigger voltage:** `V_trig = 9.6` V in the `emergency_stop` block. 
To disable the failsafe (e.g. for the endurance run to cut-off), set `V_trig = 0`.
- **Hard cut-off:** the simulation stops when the terminal voltage reaches 9.0 V.
- **Touchdown** is only checked after t = 10 s, since the vehicle starts on the 
ground at z = 0.
- **Solver:** ode23t (variable step), maximum step 1 ms, relative tolerance 1e-3.

## 6. AI use

Parts of the code and some figures were developed with the assistance of Claude (Anthropic). 
All code was reviewed, tested and modified by the author. 
See the AI declaration in the report for details.