function [detrended, trend, mdl, fig] = exponential_detrend(t, y, options)
%EXPONENTIAL_DETREND  Exponential detrend function
%
% Syntax:
%   [detrended, trend, mdl, fig] = exponential_detrend(t, y, 'Name', value);
%
% Example:
%   t = linspace(0,10,1000)';
%   y = 20 * exp(-0.05 * x) + randn(1000,1);  % Original data with exponential trend
%   [detrended, trend, mdl, fig] = exponential_detrend(t, y, 'Plot', true);
%
% Inputs:
%   t - Independent variable (e.g., time) - column vector
%   y - Dependent variable (data to be detrended) - column vector same number of elements as x.
%
% Options:
%   'Plot' (1,1) logical = false  -- Set true to plot the original/trend/detrend
%
% Output:
%   detrended - Output detrended data
%
% See also: Contents

arguments
    t (:,1) double
    y (:,1) double
    options.Plot (1,1) logical = false;
    options.Verbose (1,1) logical = false;
end

% Define the exponential fit type (decaying to zero)
exp_fit_type = fittype('k*exp(-tau*t)', 'independent', 't', 'coefficients', {'k', 'tau'});

% Set initial guesses for k, tau, and t0
[maxVal,iMax] = max(abs(y));
initial_guess = [maxVal.*sign(y(iMax)), 1/(mean(t(end)-t(1)))];

% Fit the data
try
    mdl = fit(t, y, exp_fit_type, 'StartPoint', initial_guess, 'TolX', 1e-1, 'TolFun', 0.75);
catch me
    if strcmpi(me.identifier,'curvefit:fit:infComputed')
        trend = zeros(size(y));
        detrended = y;
        mdl = [];
        fig = [];
        warning('Failed to fit exponential detrend.');
        return;
    end
end

% Get the fitted values
trend = mdl.k * exp(-mdl.tau * t);

% Subtract the fitted exponential trend from the original data
detrended = y - trend;

if options.Verbose
    disp(mdl);
end

if options.Plot
    % Plot the original data, the fitted exponential trend, and the detrended data
    fig = figure('Color','w','Units','inches','Name','Exponential detrend');
    subplot(3, 1, 1);
    plot(t, y, 'b');
    title('Original Data');
    xlabel('x');
    ylabel('y');
    
    subplot(3, 1, 2);
    plot(t, trend, 'r');
    title('Fitted Exponential Trend');
    xlabel('x');
    ylabel('Fitted Values');
    
    subplot(3, 1, 3);
    plot(t, detrended, 'g');
    title('Detrended Data');
    xlabel('x');
    ylabel('Detrended y');
else
    fig = [];
end
end
