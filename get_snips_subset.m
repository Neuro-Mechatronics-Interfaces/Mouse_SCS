function [snip_subset,Tsub] = get_snips_subset(snips, T, frequency, intensity)
%GET_SNIPS_SUBSET  Returns subset of snippets, with indexing table sorted by increasing intensity.
%
% Syntax:
%	[snips_subset,Tsub] = get_snips_subset(snips, T);
%	[...] = get_snips_subset(snips, T, frequency, intensity);
%
% Inputs:
%   snips 							- If cell, 1 element per freq/intensity/channel/return combo; if tensor, 3rd dim is # stim instances
%   T 								- Table of conditions. If snips is cell, has number of rows equal to number of cell elements. If snips is tensor, has same number of rows as 3rd dimension.
%   frequency (1,:) double = []; 	- Desired frequency subset
%   intensity (1,:) double = []; 	- Desired intensity subset
%
% Output:
%	snip_subset - Tensor of snippets that we are interested in
%	Tsub 		- Indexing table for the snippets of interest
%
% See also: Contents
arguments
    snips % If cell, 1 element per freq/intensity/channel/return combo; if tensor, 3rd dim is # stim instances
    T % Table of conditions. If snips is cell, has number of rows equal to number of cell elements. If snips is tensor, has same number of rows as 3rd dimension.
    frequency (1,:) double = []; % Desired frequency subset
    intensity (1,:) double = []; % Desired intensity subset
end
if isempty(frequency)
    frequency = unique(T.frequency);
end
if isempty(intensity)
    intensity = unique(T.intensity);
end
if iscell(snips)
    if numel(snips)~=size(T,1)
        error("Must have same number of table rows in T as cell elements in snips.");
    end
    Tsub = sortrows(T(ismember(T.frequency,frequency),:),'intensity','ascend');
    Tsub = Tsub(ismember(Tsub.intensity, intensity),:);
    index = Tsub.block+1;
    snip_subset = cat(3,snips{index});
else
    if size(snips,3)~=size(T,1)
        error("Must have same number of table rows in T as 3rd dimension size of snips.");
    end
    iKeep = ismember(T.frequency,frequency) & ismember(T.intensity, intensity);
    snip_subset = snips(:,:,iKeep);
    Tsub = T(iKeep,:);
    [Tsub,index] = sortrows(Tsub,'intensity','ascend');
    snip_subset = snip_subset(:,:,index);
end
end