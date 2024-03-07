% NHP_ACUTE_SCS Should really be NHP_ACUTE_DRGS but who keeps track?
%
% Important
%   parameters                        - Return parameters struct, which sets default values for things like epoch durations etc.
%
% Experiment Scripts
%   experiment_Frank_2024_03_06       - Script for testing/setup prior to experiment
%
% Main Experiment Functions
%   runStimRecSweep                   - Returns a table of the stim/rec sweep intensity and block indices.
%   runStimRecSweepFreqs              - Returns a table of the stim/rec sweep intensity and block indices.
%
% AM4100 Functions
%   AM4100_sendCommand                - Send message to stimulator and return formatted response message.
%   AM4100_setInterPhaseInterval      - Sets the interval between the two phases of asymmetric/biphasic pulses.
%   AM4100_setStimEventPeriodAndCount - Set the AM4100 stimulation event period and number of stimuli.
%   AM4100_setStimParameters          - Set the stimulation parameters for AM4100 experiment
%   AM4100_stimulate                  - Stimulate using the AM4100, while recording this event.
%
% TMSi SAGA Controller Functions
%   SAGA_impedances                   - Measure impedances on HD-EMG array(s)
%   SAGA_record                       - Run and increment the recording for TMSi-SAGAs AND Plexon (do not manually increment Plexon!)
%   SAGA_setBufferSize                - Updates tmsi client recording buffer samples for the next record.
%   SAGA_stop                         - Stop the current recording/running SAGA state
%   SAGA_updateFileNames              - Update filenames for SAGA A and SAGA B devices.
%
% Interface Initializers
%   initAM4100                        - Initialize TCP interface to AM4100.
%   initInterfaces                    - Initialize interfaces to TMSi and AM4100, plus logging.
%   initTMSi                          - Create UDP client to control SAGA state machine running on some host device over IPv4 + UDP.
%
% Data Loaders
%   loadData                          - Load all data associated with a single sweep.
%   loadMultiData                     - Load multiple sweeps into single sweep table. 
%   loadSweepSpreadsheet              - Load spreadsheet for sweeps based on `sweep` folder and raw data root folder.
%
% Plotting Functions
%   plotRecruitment                   - Plot recruitment summary figure
%   plotSagaRecruitmentRaw            - Plot recruitment for individual SAGA channel data

