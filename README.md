# MOUSE_SCS #  
For mouse SCS procedures.  

## Contents ##
1. [Quick Start](#quick-start)
  + [Runner Script Prep](#prepare-procedure-code-and-files)
  + [Intan](#start-intan)
  + [Stimulator](#start-am4100)
  + [GUI](#start-matlab-gui)
2. [Code Overview](#code-contents)
3. [NEURON Simulations](#neuron-simulations)

## Quick Start ##
Following steps assume you are running an experiment for `"Pilot_SCS_N_CEJ_07"` on `2024-07-25`:  

### Prepare Procedure Code and Files ###  
1. Open MATLAB R202b and navigate to `C:/MyRepos/NML/Mouse_SCS`.  
1. Copy `experiment_2024_07_17.m` to `experiment_2024_07_25.m`. Rename the `SUBJECT_NAME` from `"Pilot_SCS_N_CEJ_06"` to `"Pilot_SCS_N_CEJ_07"`.  
2. Copy `processing_2024_07_17.m` to `processing_2024_07_25.m`. Rename `SUBJ` from `"Pilot_SCS_N_CEJ_06"` to `"Pilot_SCS_N_CEJ_07"`. Make sure `YYYY`, `MM`, and `DD` accurately reflect today's date. 
3. Copy `Pilot_SCS_N_CEJ_06_Channel_Map.txt` to `Pilot_SCS_N_CEJ_07_Channel_Map.txt`. Draw the Picasso Rat on the whiteboard with numbers according to channels in that file.  
4. Copy `Muscle_Response_Times_Exponential_2024_07_17.xlsx` to `Muscle_Response_Times_Exponential_2024_07_25.xlsx`. Adjust latencies in this file as needed during experiment (make sure the file is otherwise closed).  
5. Leave this MATLAB instance open on `processing_2024_07_25.m`. You will update `SWEEP` number to reflect any experiment you want to export figures for.  

### Start Intan ###
1. Make sure that Intan 512ch RECORDING CONTROLLER is powered on and plugged into the computer via USB.
2. Start Intan RHX software. Select 20kHz for sample rate.  
3. In RHX UI, click `File > Load Settings` and select `Mouse_SCS.xml`.  
4. On the `Triggers` tab you can toggle "Triggered" mode on and off, which can be helpful to enable during the actual stimulation runs but otherwise should be toggled off.  
5. The Spike Scope is accessed from the menu bar at the top. Make sure to toggle `Lock to Selected` so the scope shows the current channel you click in the main interface.  
6. In RHX UI, click `Network > Remote TCP Control`, set Host to `127.0.0.1` and click `Connect`.  

### Start AM4100 ### 
1. Get the stimulation leads and plug into the anode/cathode ports on AM4100.
2. Make sure that AM4100 is powered on.
3. Make sure the green ENABLE switch is pressed.  
  + After depressing the switch, click OK when it gives the high voltage warning.  
4. Connect BNC from AM4100 `Sync 1` to Intan `DIGITAL IN 1`, and from AM4100 `Sync 2` to Intan `DIGITAL IN 2`. Connect BNC from AM4100 `MONITOR` to Intan `ANALOG IN 1`.  

### Start MATLAB GUI ###
1. Right-click MATLAB icon and then click MATLAB R2020b to open a second MATLAB instance.
2. Open `experiment_2024_07_25.m` and click `Run` from the `Editor` tab in the UI.  
  + This should cause the stim controller GUI to populate. Move that somewhere convenient on-screen.  
3. Make this MATLAB instance a small window and minimize it- DO NOT RUN `processing...m` from this window or you'll need to restart everything. Go back to the other previously opened MATLAB instance.  
4. Enter experimental parameters and click `RUN` from the stimulation controller GUI.  
5. After each sweep, update the `SWEEP` constant at the top of `processing_2024_07_25.m` and then click `Run` from the `Editor` tab in the UI.  
  + This should generate a new Powerpoint for each sweep with the stimulus response curves, on the Google Drive mapped in `parameters.m`.   

## Code Contents ##  
* [Configuration](#important)
* [Experiments](#experiment-scripts)
* [Main Experiment Functions](#main-experiment-functions)
* [AM4100 Interface](#am4100-functions)
* [TMSi Interface](#tmsi-saga-controller-functions)
* [Initializers](#interface-initializers)
* [Loaders](#data-loaders)
* [Plotting](#plotting-functions)

### Important ###  
 + [`parameters`](parameters.m) - Return parameters struct, which sets default values for things like epoch durations etc.  

### Experiment Scripts ###  
 + [`example_run_experiment`](example_run_experiment.m) - Script for testing/setup prior to experiment.  

### Main Experiment Functions ###  
 + [`runStimRecSweep`](runStimRecSweep.m) - Returns a table of the stim/rec sweep intensity and block indices.  
 + [`runStimRecSweepAllChannels`](runStimRecSweepAllChannels.m) - Returns a table of the stim/rec sweep intensity and block indices, for ALL channels. Requires Raspberry Pi v4b with Relay module to MUX the AM4100 anode to the stimulation channels. 

### AM4100 Functions ###  
 + [`AM4100_sendCommand`](AM4100_sendCommand.m) - Send message to stimulator and return formatted response message.  
 + [`AM4100_setInterPhaseInterval`](AM4100_setInterPhaseInterval.m) - Sets the interval between the two phases of asymmetric/biphasic pulses.  
 + [`AM4100_setStimEventPeriodAndCount`](AM4100_setStimEventPeriodAndCount.m) - Set the AM4100 stimulation event period and number of stimuli.  
 + [`AM4100_setStimParameters`](AM4100_setStimParameters.m) - Set the stimulation parameters for AM4100 experiment.  
 + [`AM4100_stimulate`](AM4100_stimulate.m) - Stimulate using the AM4100, while recording this event.  

### TMSi SAGA Controller Functions ###  
 + [`SAGA_impedances`](SAGA_impedances.m) - Measure impedances on HD-EMG array(s).  
 + [`SAGA_record`](SAGA_record.m) - Run and increment the recording for TMSi-SAGAs AND Plexon (do not manually increment Plexon!).  
 + [`SAGA_setBufferSize`](SAGA_setBufferSize.m) - Updates tmsi client recording buffer samples for the next record.  
 + [`SAGA_stop`](SAGA_stop.m) - Stop the current recording/running SAGA state.  
 + [`SAGA_updateFileNames`](SAGA_updateFileNames.m) - Update filenames for SAGA A and SAGA B devices.  

### Interface Initializers ###  
 + [`initAM4100`](initAM4100.m) - Initialize TCP interface to AM4100.  
 + [`initInterfaces`](initInterfaces.m) - Initialize interfaces to TMSi and AM4100, plus logging.  
 + [`initTMSi`](initTMSi.m) - Create UDP client to control SAGA state machine running on some host device over IPv4 + UDP.  

### Data Loaders ###  
 + [`loadData`](loadData.m) - Load all data associated with a single sweep.  
 + [`loadMultiData`](loadMultiData.m) - Load multiple sweeps into single sweep table.  
 + [`loadSweepSpreadsheet`](loadSweepSpreadsheet.m) - Load spreadsheet for sweeps based on `sweep` folder and raw data root folder.  

### Plotting Functions ###  
 + [`plotRecruitment`](plotRecruitment.m) - Plot recruitment summary figure.  
 + [`plotSagaRecruitmentRaw`](plotSagaRecruitmentRaw.m) - Plot recruitment for individual SAGA channel data.  

### Raspberry Pi Stim Channel Switcher ###  
Code that was run on the Raspberry Pi v4b that managed stimulation switching is saved in the following [gist](https://gist.github.com/m053m716/467d81521e5ea66db066c23a15b5570e).

## NEURON Simulations ##
`NEURON` simulations are parameter grid searches encapsulated within `NEURON/MotorNeuron/main_<name>_sweep.hoc`. As of 2025-09-10 there are two `.hoc` files: `NEURON/MotorNeuron/main_leak_freq_sweep.hoc` and `NEURON/MotorNeuron/main_m2_freq_sweep.hoc`. They have to be run as shown below, before any of the related MATLAB loading/plotting utilities can be applied to generate PowerPoint decks summarizing the parameter grids.  

### NEURON Leak Sweep ###
To launch the passive leak conductance frequency parameter sweep simulations, run:  
```bat
call NEURON\nrniv.bat C:/MyRepos/NML/Mouse_SCS/NEURON/MotorNeuron C:/MyRepos/NML/Mouse_SCS/NEURON/MotorNeuron/main_leak_freq_sweep.hoc out_leak C:/nrn/bin
```
Alternatively, launch `nrn_export_leak_deck` script from MATLAB and/or follow instructions in comments. 
This assumes you have installed NEURON at `C:/nrn` (the default). 

### NEURON M2 Sweep ###
To launch the M2-receptor frequency parameter sweep simulations, run: 
```bat
call NEURON\nrniv.bat C:/MyRepos/NML/Mouse_SCS/NEURON/MotorNeuron C:/MyRepos/NML/Mouse_SCS/NEURON/MotorNeuron/main_m2_freq_sweep.hoc out_m2 C:/nrn/bin
```
Alternatively, launch `nrn_export_m2_deck` script from MATLAB and/or follow instructions in comments.  
This assumes you have installed NEURON at `C:/nrn` (the default). 
Note that the `MOTONEURON_M2.mod` file has been modified from the original `MOTONEURON.mod` -- specifically, in addition to the `m2_modulation` parameter (default value of 1 has no influence on base MOTONEURON), which is included by modifying the calculation of `ikrect`. A few parameter update equations effecting Calcium dynamics are also modified:
* `tau_h` : Default is unmodified, change via `tau_n_gain`
* `tau_m` : Default is unmodified, change via `tau_n_gain`
* `tau_n` : Default is unmodified, change via `tau_n_gain`
There are additional new parameters influencing the Calcium dynamics:  
* `tau_ca` : Default 25 ms value keeps same Ca2+ clearance as in Capogrosso & Formento model. Increasing the value slows Ca2+ clearance and effectively gates Max Firing rate.  
* `picton` : Default 10000 ms value disables `PIC`-like step change in `gcaL` when simulation reaches time `picton` by setting the value outside of typical simulation duration length. 
  + `kdrop` : Default value is 0; set between 0 and 1 to couple PIC influence on outward Potassium current changes, causing broader PIC plateau.  
  + `gcaL_pic` : Default value is 0.001 (mho/cm2), which is 10x `gcaL` by default. So when the "PIC" is on, it makes `gcaL` 10x more conductive.  
  + `pic_tau` : Makes the gating "smoother" by providing a time-constant for gate transition. Default value is 5, changes `pic_gate` according to: `pic_gate = 1 / (1 + Exp(-(t - pic_ton)/pic_tau))`

### NEURON F-I Sweep ###
To launch the F-I sweep and associated voltage clamp/time-voltage-concentration recordings, run:
```bat
cd NEURON/MotorNeuron
call C:/nrn/bin/nrniv.exe -nobanner -nogui main_m2_amplitude_sweep.hoc
```
To enable the plotter while simulating (which slows it down):  
```bat
cd NEURON/MotorNeuron
call C:/nrn/bin/nrniv.exe -c "show_trace_plot=1" -c "show_fi_plot=1" main_m2_amplitude_sweep.hoc
```
Alternatively, launch `nrn_plot_fi_curves` script from MATLAB and/or follow instructions in comments.  