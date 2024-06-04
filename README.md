# MOUSE_SCS #  
For mouse SCS procedures.  

## Quick Start ##
Following steps assume you are running an experiment for `"Pilot_SCS_N_CEJ_03"`:  
1. Start Intan RHX software. Select 20kHz for sample rate.  
2. In RHX UI, click `File > Load Settings` and select `Mouse_SCS.xml`.  
3. In RHX UI, click `Network > Remote TCP Control`, set Host to `127.0.0.1` and click `Connect`.  
4. In MATLAB, navigate to `C:/MyRepos/NML/Mouse_SCS`.  
5. Open `experiment_2024_06_04.m` and click `Run` from the `Editor` tab in the UI.  
6. Open `processing_2024_06_04.m`. 
7. Enter experimental parameters and click `RUN` from the stimulation controller GUI.  
8. After each sweep, update the `SWEEP` constant at the top of `processing_2024_06_04.m` and then click `Run` from the `Editor` tab in the UI.  
  + This should generate a new Powerpoint for each sweep with the stimulus response curves, on the Google Drive mapped in `parameters.m`.   

## Contents ##  
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

