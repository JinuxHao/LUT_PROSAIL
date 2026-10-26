%使用waves_LUT对指数进行反演，例如LAI、caw等

%% 读取构造好的table


% 读取自己的waves_LUT
table_path = "../Output.csv";
% 读取提供的表
%table_path='../青海草地叶面积指数测量值.xlsx';

data_LUT=readtable(table_path);

waves_LUT = [data_LUT.B1_blue,data_LUT.B2_green,data_LUT.B3_red,...
         data_LUT.B4_NIR,data_LUT.B5_SWIR1,data_LUT.B6_SWIR2];
LAI = data_LUT.LAI;



%% 读取envi数据

envi_path ='../乌图美仁遥感数据/qinghai_roi_cal_bip_FLAASH_2.9';
hdr_path = '../乌图美仁遥感数据/qinghai_roi_cal_bip_FLAASH_2.hdr';

[cube, info] = Readh9(envi_path, hdr_path);

%% 逐像元计算波段RMSE，选择平均LAI，使用KDTree加速计算

[H, W, L] = size(cube);

% 参数设置
K = 10;                  % 选择最相近的5组waves_LUT
batchSize = 10000;      % 每批处理50000个像元

% 将影像转换为二维矩阵 (N×6)
pixels = reshape(cube, [], L);

% 排除无效waves_LUT
validwaves_LUT = all(isfinite(waves_LUT), 2) & isfinite(LAI);
waves_LUT = waves_LUT(validwaves_LUT, :);
LAI = LAI(validwaves_LUT);

K = min(K, size(waves_LUT, 1));

% 构建KD-Tree
Mdl = createns(waves_LUT, 'NSMethod', 'kdtree', 'Distance','euclidean');

% 初始化LAI结果
N = size(pixels, 1);
LAI_result = nan(N, 1, 'single');

tic;

% 分块搜索最近邻
for startIdx = 1:batchSize:N

    endIdx = min(startIdx + batchSize - 1, N);

    % 当前批次像元
    block = double(pixels(startIdx:endIdx, :));

    % 排除无效像元
    valid = all(isfinite(block), 2);

    if ~any(valid)
        continue;
    end

    % KD-Tree搜索最近的K组LUT
    idx = knnsearch(Mdl, block(valid, :), 'K', K);

    % 计算对应LAI平均值
    lai_block = mean(LAI(idx), 2);

    % 写入结果
    blockResult = nan(size(block, 1), 1);
    blockResult(valid) = lai_block;

    LAI_result(startIdx:endIdx) = single(blockResult);

end

fprintf('KD-Tree反演耗时：%.2f 秒\n', toc);

%恢复影像尺寸
LAI_map = reshape(LAI_result, H, W);

%显示反演结果
figure;
imagesc(LAI_map);
axis image;
colorbar;
colormap(parula);
title('KD-Tree LUT LAI反演结果');
xlabel('Column');
ylabel('Row');

%% 导出带空间参考信息的LAI GeoTIFF

[H, W] = size(LAI_map);

% 从ENVI头文件获取的空间参数
xMin = 443265;
yMax = 4143105;
pixelSize = 30;

% 计算影像空间范围
xMax = xMin + W * pixelSize;
yMin = yMax - H * pixelSize;

% 创建地图栅格参考对象
R = maprefcells( ...
    [xMin, xMax], ...
    [yMin, yMax], ...
    [H, W], ...
    'ColumnsStartFrom', 'north', ...
    'RowsStartFrom', 'west');

% 输出路径
output_path = '../LAI_result.tif';

% 写入GeoTIFF，指定EPSG:32646
geotiffwrite(output_path, single(LAI_map), R, ...
    'CoordRefSysCode', 32646);

fprintf('LAI GeoTIFF导出完成：%s\n', output_path);