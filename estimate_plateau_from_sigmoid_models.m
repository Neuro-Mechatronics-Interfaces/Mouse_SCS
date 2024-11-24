function plateau_value = estimate_plateau_from_sigmoid_models(mdl, default)

arguments
    mdl (:,1) cell % Array containing `fit` objects from `Somatotopy.fit_sigmoid_response` where x-variate is intensity and y-variate is response amplitude/peak-to-peak etc.
    default = 1000000;
end

maxval = -1;
for ii = 1:numel(mdl) % 'd' is the fitted value for the plateau
    ci = confint(mdl{ii});
    cv = coeffvalues(mdl{ii});
    if ci(1,4) > 0 % Then the fit was significant
        maxval = max(cv(4),maxval); % Use `d` from sigmoid for the plateau estimate.
    end
end

if maxval < 0
    plateau_value = default;
else
    plateau_value = maxval;
end

end