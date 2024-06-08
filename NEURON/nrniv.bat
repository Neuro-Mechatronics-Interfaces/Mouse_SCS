@echo off
REM ========================================================
REM This batch file is used to run NEURON simulations using 
REM the nrniv executable. It takes three parameters:
REM 1. The target directory where the simulation files are located.
REM 2. The hoc file to be executed by nrniv.
REM 3. (Optional) The directory where nrniv.exe is located.
REM    If not provided, the default is C:/nrn/bin.
REM Usage:
REM    nrniv.bat <target_directory> <hoc_file> [<nrniv_binary_directory>]
REM Example:
REM    nrniv.bat C:/MyRepos/NML/Mouse_SCS/NEURON/MotorNeuron C:/MyRepos/NML/Mouse_SCS/NEURON/MotorNeuron/main.hoc C:/nrn/bin
REM ========================================================

REM Check if the correct number of parameters are provided
IF "%~2"=="" (
    echo Usage: nrniv.bat target_directory hoc_file [nrniv_binary_directory]
    exit /b 1
)

REM Set the default NEURON binary directory if the third parameter is not provided
IF "%~3"=="" (
    set nrniv_bin_dir=C:/nrn/bin
) ELSE (
    set nrniv_bin_dir=%~3
)

REM Add the NEURON binary directory to the PATH
set PATH=%nrniv_bin_dir%;%PATH%

REM Change to the target directory
cd /d "%~1"
IF %ERRORLEVEL% NEQ 0 (
    echo Failed to change directory to %~1
    exit /b 1
)

REM Ensure the "out" folder exists
IF NOT EXIST out (
    mkdir out
    IF %ERRORLEVEL% NEQ 0 (
        echo Failed to create directory %~1\out
        exit /b 1
    )
)

REM Execute nrniv with the specified hoc file
nrniv "%~2"
IF %ERRORLEVEL% NEQ 0 (
    echo Failed to execute nrniv with %~2
    exit /b 1
)

REM Count the number of voltage*.dat files in the out folder
cd out
setlocal enabledelayedexpansion
set count=0
for %%f in (voltage*.dat) do (
    set /a count+=1
)
endlocal & set total_count=%count%

echo Total number of voltage*.dat files generated: %total_count%

exit /b 0
