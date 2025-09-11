@echo off
REM ========================================================
REM This batch file is used to run NEURON simulations using 
REM the nrniv executable. It takes three parameters:
REM 1. The target directory where the simulation files are located.
REM 2. The hoc file to be executed by nrniv.
REM 3. (Optional) The directory where nrniv.exe and mknrndll.exe are located.
REM    If not provided, the default is C:/nrn/bin.
REM Usage:
REM    nrniv.bat <target_directory> <hoc_file> <out_folder> [<nrniv_binary_directory>]
REM Example:
REM    nrniv.bat C:/MyRepos/NML/Mouse_SCS/NEURON/MotorNeuron C:/MyRepos/NML/Mouse_SCS/NEURON/MotorNeuron/main_leak_freq_sweep.hoc out_leak C:/nrn/bin
REM See Also:
REM    run_neuron_simulation.m - MATLAB function that interfaces to this batch script to allow running simulations from MATLAB directly. 
REM ========================================================

REM Check if the correct number of parameters are provided
IF "%~2"=="" (
    echo Usage: nrniv.bat target_directory hoc_file out_folder [nrniv_binary_directory]
    exit /b 1
)

IF "%~3"=="" (
    echo Usage: nrniv.bat target_directory hoc_file out_folder [nrniv_binary_directory]
    exit /b 1
)

REM Set the default NEURON binary directory if the third parameter is not provided
IF "%~4"=="" (
    set nrniv_bin_dir=C:/nrn/bin
) ELSE (
    set nrniv_bin_dir=%~4
)

REM Add the NEURON binary directory to the PATH
set PATH=%nrniv_bin_dir%;%PATH%

REM Change to the target directory
cd /d "%~1"
IF %ERRORLEVEL% NEQ 0 (
    echo Failed to change directory to %~1
    exit /b 1
)

REM Ensure the output folder exists. Delete it if it already exists, then recreate.
set outdir=%~3
IF EXIST "%outdir%" (
    rmdir /s /q "%outdir%"
    IF %ERRORLEVEL% NEQ 0 (
        echo Failed to remove existing directory %~1\%outdir%
        exit /b 1
    )
)
mkdir "%outdir%"
IF %ERRORLEVEL% NEQ 0 (
    echo Failed to create directory %~1\%outdir%
    exit /b 1
)

REM Run mknrndll to ensure the mechanisms dll is current
call "%nrniv_bin_dir%\mknrndll"
echo mknrndll executed.

REM Execute nrniv with the specified hoc file
"%nrniv_bin_dir%\nrniv.exe" -nobanner -nogui "%~2"
IF %ERRORLEVEL% NEQ 0 (
    echo Failed to execute nrniv with %~2
    exit /b 1
)

REM Count the number of voltage*.dat files in the out folder
cd "%outdir%"
setlocal enabledelayedexpansion
set count=0
for %%f in (voltage*.dat) do (
    set /a count+=1
)
endlocal & set total_count=%count%

echo Total number of voltage*.dat files generated in %outdir%: %total_count%

REM Return to project root (one level up from the location of this batch file)
cd /d "%~dp0.."

exit /b 0
