function backupPath = backup_simulink_model(modelPath, reason)
%BACKUP_SIMULINK_MODEL Create and verify a timestamped pre-edit SLX backup.
% Backups are stored in <formal-dir>/backups/<model-name>/.

arguments
    modelPath {mustBeTextScalar}
    reason {mustBeTextScalar} = "edit"
end

modelPath = char(string(modelPath));
reason = char(string(reason));
if ~isfile(modelPath)
    error('SimulinkBackup:MissingModel', 'Model file does not exist: %s', modelPath);
end
[formalDir, modelName, ext] = fileparts(modelPath);
if ~strcmpi(ext, '.slx')
    error('SimulinkBackup:WrongExtension', 'Expected an .slx model: %s', modelPath);
end

if bdIsLoaded(modelName)
    loadedFile = get_param(modelName, 'FileName');
    if ~samePath(loadedFile, modelPath)
        error('SimulinkBackup:NameCollision', ...
            'A different loaded model uses the name %s: %s', modelName, loadedFile);
    end
    if strcmp(get_param(modelName, 'Dirty'), 'on')
        error('SimulinkBackup:UnsavedChanges', ...
            ['The loaded model has unsaved changes. Save it or save a recovery copy ' ...
             'before creating an on-disk backup.']);
    end
end

% Keep the complete backup filename a valid MATLAB model identifier so a
% backup can be copied back or opened directly for recovery verification.
safeReason = lower(regexprep(strtrim(reason), '[^A-Za-z0-9]+', '_'));
safeReason = regexprep(safeReason, '^_+|_+$', '');
safeReason = regexprep(safeReason, '^before_+', '');
if isempty(safeReason), safeReason = 'edit'; end
stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss_SSS'));
backupDir = fullfile(formalDir, 'backups', modelName);
if ~isfolder(backupDir)
    [ok, msg] = mkdir(backupDir);
    if ~ok, error('SimulinkBackup:MkdirFailed', '%s', msg); end
end
backupPath = fullfile(backupDir, ...
    sprintf('%s__%s__before_%s%s', modelName, stamp, safeReason, ext));

[ok, msg] = copyfile(modelPath, backupPath, 'f');
if ~ok
    error('SimulinkBackup:CopyFailed', 'Backup copy failed: %s', msg);
end
if ~filesEqual(modelPath, backupPath)
    error('SimulinkBackup:VerificationFailed', ...
        'Backup differs from source. Do not modify the formal model.');
end

backupPath = string(backupPath);
fprintf('Verified Simulink backup: %s\n', backupPath);
end

function tf = filesEqual(a, b)
da = dir(a); db = dir(b);
if isempty(da) || isempty(db) || da.bytes ~= db.bytes
    tf = false; return
end
fa = fopen(a, 'rb'); fb = fopen(b, 'rb');
if fa < 0 || fb < 0
    if fa >= 0, fclose(fa); end
    if fb >= 0, fclose(fb); end
    tf = false; return
end
ca = onCleanup(@() fclose(fa)); %#ok<NASGU>
cb = onCleanup(@() fclose(fb)); %#ok<NASGU>
tf = true;
while true
    xa = fread(fa, 1024 * 1024, '*uint8');
    xb = fread(fb, 1024 * 1024, '*uint8');
    if ~isequal(xa, xb), tf = false; break; end
    if isempty(xa), break; end
end
end

function tf = samePath(a, b)
if isempty(a), tf = false; return; end
tf = strcmpi(char(java.io.File(a).getCanonicalPath()), ...
             char(java.io.File(b).getCanonicalPath()));
end
