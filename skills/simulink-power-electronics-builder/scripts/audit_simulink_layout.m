function report = audit_simulink_layout(modelPath, minLongRun, nearParallelGap)
%AUDIT_SIMULINK_LAYOUT Read-only block and line-geometry audit for an SLX.
% Long-line findings are candidates for visual review. Intentional branches
% of one Simscape electrical node may share the same geometry.

arguments
    modelPath {mustBeTextScalar}
    minLongRun (1,1) double {mustBePositive} = 100
    nearParallelGap (1,1) double {mustBeNonnegative} = 4
end

modelPath = char(string(modelPath));
if ~isfile(modelPath)
    error('SimulinkLayout:MissingModel', ...
        'Model file does not exist: %s', modelPath);
end
[~, modelName, ext] = fileparts(modelPath);
if ~strcmpi(ext, '.slx')
    error('SimulinkLayout:WrongExtension', ...
        'Expected an .slx model: %s', modelPath);
end

wasLoaded = bdIsLoaded(modelName);
if wasLoaded
    loadedFile = get_param(modelName, 'FileName');
    if ~samePath(loadedFile, modelPath)
        error('SimulinkLayout:NameCollision', ...
            'A different loaded model uses the name %s: %s', ...
            modelName, loadedFile);
    end
else
    load_system(modelPath);
end
cleanup = onCleanup(@() closeIfNeeded(modelName, wasLoaded));

topBlocks = find_system(modelName, 'SearchDepth', 1, 'Type', 'Block');
allEditableBlocks = find_system(modelName, 'LookUnderMasks', 'all', ...
    'FollowLinks', 'off', 'Type', 'Block');
topLines = find_system(modelName, 'SearchDepth', 1, ...
    'FindAll', 'on', 'Type', 'line');

blockOverlapPairs = findBlockOverlapPairs(topBlocks);
segments = collectOrthogonalSegments(topLines);
[collinearCandidates, nearParallelCandidates] = findLongRunCandidates( ...
    segments, topLines, minLongRun, nearParallelGap);

if isempty(allEditableBlocks)
    visibleNameCount = 0;
else
    visibleNameCount = sum(strcmp( ...
        get_param(allEditableBlocks, 'ShowName'), 'on'));
end

report = struct( ...
    'model_path', string(modelPath), ...
    'dirty_in_this_session', strcmp(get_param(modelName, 'Dirty'), 'on'), ...
    'top_block_count', numel(topBlocks), ...
    'top_line_count', numel(topLines), ...
    'editable_block_count', numel(allEditableBlocks), ...
    'visible_name_count', visibleNameCount, ...
    'block_overlap_count', size(blockOverlapPairs, 1), ...
    'block_overlap_pairs', blockOverlapPairs, ...
    'long_collinear_candidate_count', numel(collinearCandidates), ...
    'long_collinear_candidates', collinearCandidates, ...
    'long_near_parallel_candidate_count', numel(nearParallelCandidates), ...
    'long_near_parallel_candidates', nearParallelCandidates, ...
    'minimum_long_run_pixels', minLongRun, ...
    'near_parallel_gap_pixels', nearParallelGap);

fprintf(['LAYOUT_AUDIT blocks=%d lines=%d overlaps=%d visibleNames=%d ' ...
    'longCollinearCandidates=%d nearParallelCandidates=%d\n'], ...
    report.top_block_count, report.top_line_count, ...
    report.block_overlap_count, report.visible_name_count, ...
    report.long_collinear_candidate_count, ...
    report.long_near_parallel_candidate_count);
if ~isempty(blockOverlapPairs)
    disp('Block overlap pairs:');
    disp(blockOverlapPairs);
end
if ~isempty(collinearCandidates)
    disp('Long collinear candidates (review same-node buses before editing):');
    disp(string({collinearCandidates.description})');
end
if ~isempty(nearParallelCandidates)
    disp('Long near-parallel candidates:');
    disp(string({nearParallelCandidates.description})');
end
end

function pairs = findBlockOverlapPairs(blocks)
pairs = strings(0, 2);
if numel(blocks) < 2, return; end
positions = cell2mat(get_param(blocks, 'Position'));
names = string(get_param(blocks, 'Name'));
for i = 1:numel(blocks)-1
    for j = i+1:numel(blocks)
        a = positions(i,:); b = positions(j,:);
        if min(a(3),b(3)) > max(a(1),b(1)) && ...
                min(a(4),b(4)) > max(a(2),b(2))
            pairs(end+1,:) = [names(i) names(j)]; %#ok<AGROW>
        end
    end
end
end

function segments = collectOrthogonalSegments(lineHandles)
% Columns: line index, orientation (1 H/2 V), fixed, low, high, length.
segments = zeros(0, 6);
for i = 1:numel(lineHandles)
    points = get_param(lineHandles(i), 'Points');
    if isempty(points) || size(points,1) < 2, continue; end
    for k = 1:size(points,1)-1
        p1 = points(k,:); p2 = points(k+1,:);
        if p1(2) == p2(2)
            low = min(p1(1),p2(1)); high = max(p1(1),p2(1));
            segments(end+1,:) = [i 1 p1(2) low high high-low]; %#ok<AGROW>
        elseif p1(1) == p2(1)
            low = min(p1(2),p2(2)); high = max(p1(2),p2(2));
            segments(end+1,:) = [i 2 p1(1) low high high-low]; %#ok<AGROW>
        end
    end
end
end

function [collinear, nearParallel] = findLongRunCandidates( ...
        segments, lineHandles, minLongRun, nearParallelGap)
template = struct('line_a', 0, 'line_b', 0, 'orientation', "", ...
    'separation_pixels', 0, 'overlap_pixels', 0, ...
    'line_a_endpoints', "", 'line_b_endpoints', "", ...
    'description', "");
collinear = repmat(template, 0, 1);
nearParallel = repmat(template, 0, 1);
for i = 1:size(segments,1)-1
    for j = i+1:size(segments,1)
        a = segments(i,:); b = segments(j,:);
        if a(1) == b(1) || a(2) ~= b(2), continue; end
        overlap = min(a(5),b(5)) - max(a(4),b(4));
        if overlap < minLongRun, continue; end
        separation = abs(a(3)-b(3));
        if separation > nearParallelGap, continue; end
        if a(2) == 1
            orientation = "horizontal";
        else
            orientation = "vertical";
        end
        endpointsA = lineEndpointText(lineHandles(a(1)));
        endpointsB = lineEndpointText(lineHandles(b(1)));
        item = template;
        item.line_a = a(1);
        item.line_b = b(1);
        item.orientation = orientation;
        item.separation_pixels = separation;
        item.overlap_pixels = overlap;
        item.line_a_endpoints = endpointsA;
        item.line_b_endpoints = endpointsB;
        item.description = sprintf( ...
            '%s overlap=%g px separation=%g px: %s || %s', ...
            orientation, overlap, separation, endpointsA, endpointsB);
        if separation == 0
            collinear(end+1,1) = item; %#ok<AGROW>
        else
            nearParallel(end+1,1) = item; %#ok<AGROW>
        end
    end
end
end

function text = lineEndpointText(lineHandle)
src = get_param(lineHandle, 'SrcPortHandle');
dst = get_param(lineHandle, 'DstPortHandle');
srcName = portBlockName(src);
dstNames = strings(0,1);
for k = 1:numel(dst)
    dstNames(end+1,1) = portBlockName(dst(k)); %#ok<AGROW>
end
if isempty(dstNames), dstNames = "<branch-or-none>"; end
text = srcName + " -> " + strjoin(unique(dstNames), "|");
end

function name = portBlockName(portHandle)
if isempty(portHandle) || portHandle == -1
    name = "<branch-or-none>";
    return;
end
try
    parent = get_param(portHandle, 'Parent');
    name = string(get_param(parent, 'Name'));
catch
    name = "<unknown>";
end
end

function closeIfNeeded(modelName, wasLoaded)
if ~wasLoaded && bdIsLoaded(modelName), close_system(modelName, 0); end
end

function tf = samePath(a, b)
if isempty(a), tf = false; return; end
tf = strcmpi(char(java.io.File(a).getCanonicalPath()), ...
             char(java.io.File(b).getCanonicalPath()));
end
