function [data, info] = Readh9(dataFile, hdrFile)
% 读取 ENVI 二进制 (.9) 并按头文件自动还原反射率 (0-1)
%
% 用法:
%   [cube, info] = readENVI9('qinghai_roi_cal_bip_FLAASH_2.9', ...
%                            'qinghai_roi_cal_bip_FLAASH_2.txt');
%   cube: [lines, samples, bands] 反射率 0-1

    info = parseENVIHeader(hdrFile);

    samples = str2double(info.samples);
    info.samples = samples;
    lines   = str2double(info.lines);
    info.lines = lines;
    bands   = str2double(info.bands);
    info.bands = bands;
    interlv = lower(strtrim(info.interleave));
    info.interlv =interlv;
    dtype   = str2double(info.data_type);
    info.dtype =dtype;
    bOrder  = str2double(info.byte_order);
    info.bOrder = bOrder;
    offset  = 0;
    if isfield(info, 'header_offset')
        offset = str2double(info.header_offset);
    end
        
    info.offset = offset;
    

    % ---- ENVI data type 映射 ----
    switch dtype
        case 1,  prec = 'uint8';
        case 2,  prec = 'int16';
        case 3,  prec = 'int32';
        case 4,  prec = 'single';
        case 5,  prec = 'double';
        case 6,  prec = 'single';   % complex32, 这里不会用到
        case 12, prec = 'uint16';
        case 13, prec = 'uint32';
        otherwise, error('不支持的 data type: %d', dtype);
    end

    if bOrder == 1
        fmt = 'ieee-be';
    else
        fmt = 'ieee-le';
    end

    % ---- 读原始二进制 ----
    data = multibandread(dataFile, [lines samples bands], ...
        prec, offset, interlv, fmt);

    % ---- 反射率还原 (0-1) ----
    data = double(data);
    if isfield(info, 'reflectance_scale_factor')
        sf = str2double(info.reflectance_scale_factor);
        if sf > 0
            data = data / sf;
        end
    end

    fprintf('读取完成: %d×%d 像元 × %d 波段, 原始=%s, 缩放=%.0f\n', ...
            lines, samples, bands, prec, sf);
end