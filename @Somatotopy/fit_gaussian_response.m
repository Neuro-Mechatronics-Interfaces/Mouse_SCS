function [gaussianFit, gof] = fit_gaussian_response(xData, yData)
% Define the fit type with the Gaussian model
ft = fittype('A * exp(-((x - mu)^2) / (2 * sigma^2))', ...
             'independent', 'x', 'coefficients', {'A', 'mu', 'sigma'});

w = yData ./ sum(yData);

% Set fit options, with initial guesses for A, mu, and sigma
fitOptions = fitoptions('Method', 'NonlinearLeastSquares', ...
                        'StartPoint', [max(yData), sum(xData.*w), mean(abs(sum(xData.*w)-xData))], ...
                        'Lower', [0, min(xData), 0], ...
                        'Upper', [Inf, max(xData), Inf]);

% Perform the fit
[gaussianFit, gof] = fit(xData, yData, ft, fitOptions);

end