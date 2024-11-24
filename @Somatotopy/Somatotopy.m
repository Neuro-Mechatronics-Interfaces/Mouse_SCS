classdef Somatotopy < handle
    %SOMATOTOPY  
    %   Detailed explanation goes here

    properties (Access=public)
        fig
        ax
        cdata
        x_p
        x_n
        y
        mdl % Fitted model (per-column)
        gof % Model goodness-of-fit (per-column)
        fit_method {mustBeMember(fit_method,{'gaussian', 'sigmoid'})} = 'gaussian';
    end

    properties (Access=protected)
        h_ % Holds chart data graphics handle
        x_p_ % The x-centers for "right" data columns
        x_n_ % The x-centers for "left" data columns
        y_ % The y-centers for data columns
        data_ % Cell grid for somatotopy response variates
        has_multidata_ (1,1) logical = false;
        use_normalization_ (1,1) logical = false;
    end

    methods
        function self = Somatotopy(options)
            %SOMATOTOPY Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                options.Data = [];
                options.FitMethod {mustBeMember(options.FitMethod,{'gaussian', 'sigmoid'})} = 'gaussian';
                options.SomatotopicOutput (1,:) string = ["L-P-DELT", "L-TRI", "L-BIC", "L-WEXT", "L-PARA", "R-PARA", "R-WEXT", "R-BIC", "R-TRI", "R-P-DELT"];
                options.SomatotopyFigureFile = 'Somatotopy-DRGS_Template_Mouse.png'; % Determines "good" values for all options **except** SomatotopicOutput
                options.Segments = ["C2", "C3", "C4", "C5", "C6", "C7", "T1", "T2"];
                options.LabelWidth = 90;
                options.BorderWidth = 10;
                options.LabelYGridExtent = [30, 650];
                options.Width = 1400;
                options.Height = 950;
                options.Title = "";
                options.Subtitle = "";
                options.NormalizeData (1,1) logical = false;
            end
            n = numel(options.SomatotopicOutput);
            if rem(n,2)~=0
                error("Must have even number of elements in SomatotopicOutput");
            end

            [self.fig, self.ax, yEdges, self.y, xEdges_n, self.x_n, xEdges_p, self.x_p, self.cdata] = Somatotopy.init_somatotopy_fig(...
                'SomatotopyFigureFile',options.SomatotopyFigureFile, ...
                'SomatotopicOutputNegative', options.SomatotopicOutput(1:(n/2)), ...
                'SomatotopicOutputPositive', options.SomatotopicOutput(((n/2)+1):end), ...
                'Segments', options.Segments, ...
                'LabelWidth', options.LabelWidth, ...
                'Title', options.Title, ...
                'Subtitle', options.Subtitle);
            self.fit_method = options.FitMethod;
            self.x_n_ = round(xEdges_n(1:(end-1)) + mean(diff(xEdges_n))/2);
            self.x_p_ = round(xEdges_p(1:(end-1)) + mean(diff(xEdges_p))/2);
            self.y_ = round(yEdges(1:(end-1)) + mean(diff(yEdges))/2);
            self.use_normalization_ = options.NormalizeData;
            self.fig.CloseRequestFcn = @self.handleFigureClosing;
            x_= [self.x_n_, self. x_p_];
            if ~isempty(options.Data)
                [r,c] = size(options.Data);
                if (r == numel(self.y_)) && (c == numel(x_))
                    if ~iscell(options.Data)
                        self.data_ = num2cell(options.Data);
                    else
                        self.data_ = options.Data;
                    end
                    self.update();
                else
                    error("Tried to assign Data option but it must have exactly %d rows (has: %d) and exactly %d columns (has: %d).", numel(self.y_), r, numel(x_), c);
                end
            else
                self.data_ = num2cell(nan(numel(self.y_),numel(self.x_n_) + numel(self.x_p_)));
            end
        end

        function setNormalizationMode(self, enable)
            arguments
                self
                enable (1,1) logical
            end
            self.use_normalization_ = enable;
            self.update();
        end

        function save(self, root_folder, fname_tag)
            if exist(root_folder,'dir')==0
                mkdir(root_folder);
            end
            saveas(self.fig, fullfile(root_folder, sprintf('%s.png', fname_tag)));
            savefig(self.fig, fullfile(root_folder, sprintf('%s.fig', fname_tag)));
            mdl = self.mdl; %#ok<PROPLC> 
            gof = self.gof; %#ok<PROPLC> 
            data = self.data_;
            label = [self.x_n, self.x_p];
            level = self.y;
            save(fullfile(root_folder, sprintf('%s.mat', fname_tag)), 'mdl', 'gof', 'data', 'label', 'level', '-v7.3');
        end

        function handleFigureClosing(self,~,~)
            delete(self);
        end

        function val = subsref(self, s)
            %SUBSREF Overload of indexing for data retrieval.
            %
            % MUST USE '()' operator, and MUST have TWO subscripts.
            %
            % Example 1:
            %   response = self(:,"EDC"); % Returns data from "EDC" column 
            %                             in "response grid".
            %
            % Example 2:
            %   response = self(:,["EDC", "ED45"]); % Returns data from
            %                                       % "EDC" and "ED45"
            %                                       % "response grid"
            %                                       % columns.
            %
            % Example 3:
            %   response = self("C4",:); % Returns data aligned with "C4"
            %                            % row from "response grid"
            %
            % Example 4:
            %   response = self(:, 2); % Returns all data from the second 
            %                          % "response grid" column (by
            %                          % default, this should be "EDC",
            %                          % making this example identical with
            %                          % Example 1). 
               
            if strcmpi(s(1).type,'()')
                if numel(s.subs)~=2
                    error("Must have exactly TWO subscripts for reference using operator `()`.");
                end
                [iRow, iCol] = self.getGridIndexing(s);
                val = self.data(iRow, iCol);
                if ~self.has_multidata_
                    val = cell2mat(val);
                end
            elseif strcmpi(s(1).type,'.')
                val = self.(s(1).subs);
            else
                val = builtin('subsref', self, s);
            end
        end
        
        function subsasgn(self, s, val)
            %SUBSASGN Overload of assignment indexing operator.
            %
            % Example 1:
            %   self("
            if strcmpi(s(1).type,'()')
                if numel(s.subs)~=2
                    error("Must have exactly TWO subscripts for assignment using operator `()`.");
                end
                [iRow, iCol] = self.getGridIndexing(s);
                if isscalar(iRow) && isscalar(iCol)
                    if numel(val) > 1
                        self.has_multidata_ = true;
                    end
                    self.data_{iRow,iCol} = val;
                else
                    if numel(iRow) * numel(iCol) ~= numel(val)
                        if ~isa(val,'cell')
                            error("Assigned value must be cell if assigning multi-data for multiple grid elements at once.");
                        end
                        self.data_(iRow,iCol) = val;
                        self.has_multidata_ = true;
                    else
                        for r = 1:numel(iRow)
                            for c = 1:numel(iCol)
                                self.data_{iRow(r),iCol(c)} = val(r,c);
                            end
                        end
                    end
                end
            else
                builtin('subsasgn',self, s, val);
            end
            self.update();
        end

        function delete(self)
            try %#ok<*TRYNC> 
                if isvalid(self.fig)
                    self.fig.CloseRequestFcn = @closereq;
                end
            end
            try
                if isvalid(self.fig)
                    delete(self.fig);
                end
            end
        end

        function update(self)
            %UPDATE  Updates the figure handle with new data.
            self.checkMultidata();
            delete(self.h_);
            x = [self.x_n, self.x_p];
            x_ = [self.x_n_, self.x_p_];
            [xg, yg] = meshgrid(x_, self.y_);
            if ~self.has_multidata_
                cg = repelem(self.cdata,numel(self.y_),1);
                sz = cell2mat(self.data_);
                self.h_ = bubblechart(xg(:), yg(:), sz(:), ...
                    'CData', cg, 'Parent', self.ax);
            else
                w = mean(diff(self.x_n_));
                h = mean(diff(self.y_));
                self.h_ = gobjects(numel(x_),2);
                for iCol = 1:numel(x_)
                    x0 = x_(iCol)+w/2; % We will subtract rescaled curves so that bells go to the left of whichever line they are with (matches label horizontal alignment)
                    somatotopyData0 = [];
                    responseData0 = [];
                    all_data_ = vertcat(self.data_{:,iCol});
                    all_data_ = all_data_(:);
                    all_data_(isnan(all_data_)) = [];
                    if isempty(all_data_)
                        continue;
                    end
                    dataLim = [min(all_data_), max(all_data_)];
                    deltaData = diff(dataLim);
                    for iRow = 1:numel(self.y_)
                        y0 = self.y_(iRow);
                        tmpData = self.data_{iRow, iCol}(~isnan(self.data_{iRow, iCol}));
                        if self.use_normalization_
                            scaledData = (tmpData(:)-dataLim(1))./deltaData;
                        else
                            scaledData = tmpData(:);
                        end
                        % somatotopyData0 = [somatotopyData0; y0 + randn(numel(scaledData),1).*(h/3.5)]; %#ok<AGROW> 
                        somatotopyData0 = [somatotopyData0; ones(numel(scaledData),1).*y0]; %#ok<AGROW>
                        responseData0 = [responseData0; scaledData]; %#ok<AGROW> 
                    end
                    nanmask = ~isnan(responseData0) & ~isnan(somatotopyData0);
                    if nnz(nanmask) < 4
                        continue;
                    end
                    switch self.fit_method
                        case 'gaussian'
                            [self.mdl{iCol},self.gof{iCol}] = Somatotopy.fit_gaussian_response(somatotopyData0(nanmask), responseData0(nanmask));
                        case 'sigmoid'
                            [self.mdl{iCol},self.gof{iCol}] = Somatotopy.fit_sigmoid_response(somatotopyData0(nanmask), responseData0(nanmask));
                        otherwise
                            error("Unexpected Somatotopy.fit_method: %s", self.fit_method);
                    end
                    fprintf(1,'[%s]::[%s]:R-SQUARE=%.2f\n', x(iCol),upper(self.fit_method),self.gof{iCol}.rsquare);
%                     disp(self.gof{iCol});
                    xData = [];
                    yData = [];
                    for iRow = 1:numel(self.y_)
                        y0 = self.y_(iRow)+h/2;
                        tmpData = self.data_{iRow, iCol}(~isnan(self.data_{iRow, iCol}));
                        if self.use_normalization_
                            scaledData = (tmpData(:)-dataLim(1))./deltaData;
                        else
                            scaledData = tmpData(:);
                        end
                        yData_tmp = y0 + linspace(-h, 0, numel(scaledData))';
                        yData_asgn = yData_tmp;
                        if self.gof{iCol}.rsquare > 0.4
                            scaledData_sig = self.mdl{iCol}(yData_tmp);
                            for ii = 1:numel(scaledData)
                                [~,idx] = min(abs(scaledData_sig-scaledData(ii)));
                                yData_asgn(ii) = yData_tmp(idx); % Assign to the nearest "good" value
                            end
                        end
                        yData = [yData; yData_asgn]; %#ok<AGROW> % Just space them uniformly within the grid box
                        xData = [xData; x0-scaledData*w]; %#ok<AGROW> 
                    end
                    if self.gof{iCol}.rsquare > 0.4
                        yData_sig = linspace(self.y_(1)-h/2,self.y_(end)+h/2,numel(yData));
                        xData_sig = x0 - self.mdl{iCol}(yData_sig)*w;
                        self.h_(iCol,2) = line(self.ax, xData_sig, yData_sig, ...
                            'Color', self.cdata(iCol,:), 'LineWidth', 2);
                        self.h_(iCol,2).Annotation.LegendInformation.IconDisplayStyle = 'off';
                    end
                    self.h_(iCol,1) = scatter(self.ax, xData, yData, ...
                        'Color', self.cdata(iCol,:), ...
                        'Marker', 'o', 'MarkerEdgeColor','none',...
                        'MarkerFaceColor', self.cdata(iCol,:));
                    
                end
            end
            drawnow();
        end
    end

    methods (Access=protected)
        function checkMultidata(self)
            has_multidata = false;
            for ii = 1:numel(self.data_)
                has_multidata = has_multidata || ~isscalar(self.data_{ii});
            end
            self.has_multidata_ = has_multidata;
        end
        function [iRow, iCol] = getGridIndexing(self, s)
            x_ = [self.x_n_, self.x_p_];
            x = [self.x_n, self.x_p];
            if ischar(s.subs{1}) || isstring(s.subs{1})
                if strcmpi(s.subs{1},':')
                    iRow = 1:numel(self.y_);
                else
                    if isstring(s.subs{1})
                        iRow = nan(1,numel(s.subs{1}));
                        for ii = 1:numel(s.subs{1})
                            tmp = find(strcmpi(self.y, s.subs{1}(ii)),1,'first');
                            if isempty(tmp)
                                error("Could not find row for index: %s", s.subs{1}(ii));
                            end
                            iRow(ii) = tmp;
                        end
                    else
                        iRow = find(strcmpi(self.y, s.subs{2}),1,'first');
                        if isempty(iRow)
                            error("Could not find row for index: %s", s.subs{1});
                        end
                    end
                end
            else
                iRow = s.subs{1};
            end
            if ischar(s.subs{2}) || isstring(s.subs{2})
                if strcmpi(s.subs{2},':')
                    iCol = 1:numel(x_);
                else
                    if isstring(s.subs{2})
                        iCol = nan(1,numel(s.subs{2}));
                        for ii = 1:numel(s.subs{2})
                            tmp = find(strcmpi(x, s.subs{2}(ii)),1,'first');
                            if isempty(tmp)
                                error("Could not find column for index: %s", s.subs{2}(ii));
                            end
                            iCol(ii) = tmp;
                        end
                    else
                        iCol = find(strcmpi(x, s.subs{2}),1,'first');
                        if isempty(iCol)
                            error("Could not find column for index: %s", s.subs{2});
                        end
                    end
                end
            else
                iCol = s.subs{2};
            end
        end
    end

    methods (Static, Access=public)
        [gaussianFit,gof] = fit_gaussian_response(xData, yData);
        [sigmoidFit,gof] = fit_sigmoid_response(xData, yData);
        [fig, ax, yEdges, yLab, xEdges_n, xLab_n, xEdges_p, xLab_p, cData] = init_somatotopy_fig(options);
    end
end