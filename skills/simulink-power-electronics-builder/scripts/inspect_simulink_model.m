function report = inspect_simulink_model(modelPath)
%INSPECT_SIMULINK_MODEL Read model safety state without saving it.

arguments
    modelPath {mustBeTextScalar}
end
modelPath = char(string(modelPath));
if ~isfile(modelPath)
    error('SimulinkInspect:MissingModel', 'Model file does not exist: %s', modelPath);
end
[~, modelName, ext] = fileparts(modelPath);
if ~strcmpi(ext, '.slx')
    error('SimulinkInspect:WrongExtension', 'Expected an .slx model: %s', modelPath);
end

wasLoaded = bdIsLoaded(modelName);
if wasLoaded
    loadedFile = get_param(modelName, 'FileName');
    if ~samePath(loadedFile, modelPath)
        error('SimulinkInspect:NameCollision', ...
            'A different loaded model uses the name %s: %s', modelName, loadedFile);
    end
else
    load_system(modelPath);
end
cleanup = onCleanup(@() closeIfNeeded(modelName, wasLoaded)); %#ok<NASGU>

blocks = find_system(modelName, 'LookUnderMasks', 'all', ...
    'FollowLinks', 'off', 'Type', 'Block');
if isempty(blocks)
    visibleCount = 0;
else
    visibleCount = sum(strcmp(get_param(blocks, 'ShowName'), 'on'));
end
lines = find_system(modelName, 'FindAll', 'on', 'Type', 'line');
info = dir(modelPath);
report = struct( ...
    'model_path', string(modelPath), ...
    'file_bytes', info.bytes, ...
    'file_modified', string(info.date), ...
    'was_loaded_in_this_session', wasLoaded, ...
    'dirty_in_this_session', strcmp(get_param(modelName, 'Dirty'), 'on'), ...
    'stop_time', string(get_param(modelName, 'StopTime')), ...
    'block_count', numel(blocks), ...
    'line_count', numel(lines), ...
    'visible_name_count', visibleCount);
disp(report);
end

function closeIfNeeded(modelName, wasLoaded)
if ~wasLoaded && bdIsLoaded(modelName), close_system(modelName, 0); end
end

function tf = samePath(a, b)
if isempty(a), tf = false; return; end
tf = strcmpi(char(java.io.File(a).getCanonicalPath()), ...
             char(java.io.File(b).getCanonicalPath()));
end
