function create_heatmap_table(summary_struct, disp_struct, title_str)
    FinalTable = struct2table(summary_struct);
    DisplayTable = struct2table(disp_struct);
    fig = figure('Name', title_str, 'Position', [50, 50, 1600, 800], 'Color', 'w');
    
    % สร้าง UI Table
    uit = uitable(fig, 'Data', table2cell(DisplayTable), 'ColumnName', DisplayTable.Properties.VariableNames, ...
        'Units', 'Normalized', 'Position', [0.03 0.05 0.94 0.9]);
    
    % ปรับความสูงแถวให้มองเห็นข้อความหลายบรรทัด
    uit.RowHeight = 60; 

    for r = 1:size(FinalTable, 1)
        for c = 5:size(FinalTable, 2)
            status = FinalTable{r,c};
            % ดึงค่า Error จากบรรทัดสุดท้ายของข้อความ (ใช้ regex หาตัวเลขหลัง Er: หรือ Err:)
            cell_str = DisplayTable{r,c};
            tokens = regexp(cell_str, 'E[r]+:([\d.]+)', 'tokens');
            err_val = 0; if ~isempty(tokens), err_val = str2double(tokens{1}{1}); end
            
            if strcmp(status, 'PASSED')
                addStyle(uit, uistyle('BackgroundColor', [0.8 1.0 0.8]), 'cell', [r, c]); % เขียว
            elseif strcmp(status, 'VIB')
                addStyle(uit, uistyle('BackgroundColor', [0.3 0.3 0.3], 'FontColor', 'w'), 'cell', [r, c]); % เทา
            elseif ~strcmp(status, 'MISSING')
                % FAILED: ไล่สีตาม Error (ใช้เกณฑ์ 0.1 rad หรือ deg ตามความเหมาะสม)
                if err_val >= 0.1
                    addStyle(uit, uistyle('BackgroundColor', [1.0 0.6 0.6], 'FontWeight', 'bold'), 'cell', [r, c]); % แดง
                elseif err_val >= 0.01
                    addStyle(uit, uistyle('BackgroundColor', [1.0 0.8 0.4]), 'cell', [r, c]); % ส้ม
                else
                    addStyle(uit, uistyle('BackgroundColor', [1.0 1.0 0.7]), 'cell', [r, c]); % เหลือง (Error ผ่านแต่ PO/Time ไม่ผ่าน)
                end
            end
        end
    end
end