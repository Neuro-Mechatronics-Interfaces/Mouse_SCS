function T = build_weights_metadata(outdir)
if nargin<1 
    F = dir(fullfile(pwd,"NEURON","MotorNeuron","out_*")); 
    F(~[F.isdir]) = [];
    T = [];
    for iF = 1:numel(F)
        T = [T; build_weights_metadata(fullfile(F(iF).folder,F(iF).name))]; %#ok<AGROW>
    end
    return;
end

files = dir(fullfile(outdir,'voltage_*.dat'));
if numel(files) < 1
    T = [];
    return;
end

% Regex: look for "_<float>_<float>_<float>_<W1>_<W2>_<W3>_<float>gl"
pat = 'p[0-9.eE+-]+_[0-9.eE+-]+_[0-9.eE+-]+_([0-9.eE+-]+)_([0-9.eE+-]+)_([0-9.eE+-]+)_';

W = [];
for i = 1:numel(files)
    fn = files(i).name;
    tok = regexp(fn, pat, 'tokens','once');
    if ~isempty(tok)
        W(end+1,:) = str2double(tok); %#ok<AGROW>
    end
end

Wuniq = unique(W,'rows','stable');
T = table((0:size(Wuniq,1)-1)', Wuniq(:,1), Wuniq(:,2), Wuniq(:,3), ...
    'VariableNames',{'row','W1','W2','W3'});

writetable(T, fullfile(outdir,'weights.tsv'), 'Delimiter','\t','FileType','text');
fprintf('Wrote %d unique W triplets to weights.tsv\n', size(T,1));
end
