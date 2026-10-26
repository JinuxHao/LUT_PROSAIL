function info = parseENVIHeader(hdrFile)
%读取hdr文件，获取影像信息
    fid = fopen(hdrFile, 'r');
    if fid == -1, error('无法打开头文件: %s', hdrFile); end
    txt = fread(fid, '*char')';
    fclose(fid);
    txt = regexprep(txt, '^\s*ENVI\s*', '');
    
    % 匹配 key = value，value 可以是 {..} 或一行文本
    % key 允许含空格，value 用 {…} 跨行或多个连续字符直到换行或下一个 key
    pattern = '([^\s=][^=\r\n]*?)\s*=\s*(\{[^}]*\}|[^\r\n]*)';
    tokens = regexp(txt, pattern, 'tokens');
    info = struct();
    for i = 1:numel(tokens)
        key = strtrim(lower(tokens{i}{1}));
        key = regexprep(key, '\s+', '_');      % 'map info' → 'map_info'
        val = strtrim(tokens{i}{2});
        % 去掉花括号
        if startsWith(val, '{')
            val = regexprep(val, '^\{|\}$', '');
            val = strtrim(val);
        end
        info.(key) = val;
    end
end