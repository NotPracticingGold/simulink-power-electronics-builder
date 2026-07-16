function report = hide_and_verify_block_names(modelPath, createBackup)
%HIDE_AND_VERIFY_BLOCK_NAMES Hide all block names and verify the saved SLX.
% Set createBackup=false only when a verified backup was just created.

arguments
    modelPath {mustBeTextScalar}
    createBackup (1,1) logical = true
end
modelPath = char(string(modelPath));
if ~isfile(modelPath)
    error('SimulinkNames:MissingModel', 'Model file does not exist: %s', modelPath);
end
[~, modelName, ext] = fileparts(modelPath);
if ~strcmpi(ext, '.slx')
    error('SimulinkNames:WrongExtension', 'Expected an .slx model: %s', modelPath);
end
if createBackup
    backupPath = backup_simulink_model(modelPath, "hide-block-names");
else
    backupPath = "";
end

wasLoaded = bdIsLoaded(modelName);
if wasLoaded
    loadedFile = get_param(modelName, 'FileName');
    if ~samePath(loadedFile, modelPath)
        error('SimulinkNames:NameCollision', ...
            'A different loaded model uses the name %s: %s', modelName, loadedFile);
    end
    if strcmp(get_param(modelName, 'Dirty'), 'on')
        error('SimulinkNames:UnsavedChanges', ...
            ['The loaded model has unsaved changes. Save it or save a recovery copy ' ...
             'before running this file-based operation.']);
    end
else
    load_system(modelPath);
end
cleanup = onCleanup(@() closeIfNeeded(modelName, wasLoaded)); %#ok<NASGU>

blocks = find_system(modelName, 'LookUnderMasks', 'all', ...
    'FollowLinks', 'off', 'Type', 'Block');
for k = 1:numel(blocks)
    set_param(blocks{k}, 'ShowName', 'off');
end
visibleBeforeSave = sum(strcmp(get_param(blocks, 'ShowName'), 'on'));
if visibleBeforeSave ~= 0
    error('SimulinkNames:InMemoryVerificationFailed', ...
        '%d block names remain visible before save.', visibleBeforeSave);
end
save_system(modelName, modelPath);

visibleAfterSave = sum(strcmp(get_param(blocks, 'ShowName'), 'on'));
if visibleAfterSave ~= 0
    error('SimulinkNames:SavedVerificationFailed', ...
        '%d block names remain visible after save.', visibleAfterSave);
end
report = struct('model_path', string(modelPath), ...
    'backup_path', string(backupPath), ...
    'block_count', numel(blocks), ...
    'visible_name_count', visibleAfterSave);
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
