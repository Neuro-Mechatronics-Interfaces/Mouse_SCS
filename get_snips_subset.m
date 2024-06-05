function [snip_subset,Tsub] = get_snips_subset(snips, T, frequency, intensity)
Tsub = sortrows(T(T.frequency == frequency,:),'intensity','ascend');
Tsub = Tsub(ismember(Tsub.intensity, intensity),:);
index = Tsub.block+1;
snip_subset = cat(3,snips{index});
end