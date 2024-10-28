function [sigmoidFit, gof] = fit_sigmoid_response(xData, yData)

% Perform linear fit
p = polyfit(xData, yData, 1); % Fit a 1st degree polynomial (linear)
slope = p(1); % The slope of the linear fit

% Define the model and fit options
if slope > 0
    ft = fittype('c + (d - c) / (1 + exp(-a * (x - b)))', 'independent', 'x', 'coefficients', {'a', 'b', 'c', 'd'});
else
    ft = fittype('d + (c - d) ./ (1 + exp(-a * (x - b)))', 'independent', 'x', 'coefficients', {'a', 'b', 'c', 'd'});
end
fitOptions = fitoptions('Method', 'NonlinearLeastSquares', ...
                        'StartPoint', [mean(yData)/mean(xData), mean(xData), min(yData), max(yData)], ... % Initial guesses for a, b, c, and d
                        'Lower', [0, min(xData), -Inf, 0], ...
                        'Upper', [Inf, max(xData), 0, Inf]);

% Fit the model
[sigmoidFit, gof] = fit(xData, yData, ft, fitOptions);

end