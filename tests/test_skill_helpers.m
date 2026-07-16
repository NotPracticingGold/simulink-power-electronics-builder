function test_skill_helpers
%TEST_SKILL_HELPERS Smoke-test the bundled Simulink safety helpers.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
skillDir = fullfile(repoRoot, 'skills', 'simulink-power-electronics-builder');
addpath(fullfile(skillDir, 'scripts'));

workDir = tempname;
mkdir(workDir);
modelName = 'SimulinkSkillHelperSmokeTest';
modelPath = fullfile(workDir, [modelName '.slx']);
cleanup = onCleanup(@() cleanupTest(workDir, modelName)); %#ok<NASGU>

load_system('simulink');
new_system(modelName);
add_block('simulink/Sources/Constant', [modelName '/Input'], ...
    'Value', '2', 'Position', [40 60 90 90]);
add_block('simulink/Math Operations/Gain', [modelName '/Gain'], ...
    'Gain', '3', 'Position', [150 55 210 95]);
add_block('simulink/Sinks/Out1', [modelName '/Output'], ...
    'Position', [280 60 310 90]);
add_line(modelName, 'Input/1', 'Gain/1');
add_line(modelName, 'Gain/1', 'Output/1');
save_system(modelName, modelPath);
close_system(modelName, 0);

before = inspect_simulink_model(modelPath);
assert(before.block_count == 3);
assert(before.visible_name_count == 3);

backupPath = backup_simulink_model(modelPath, 'smoke-test');
assert(isfile(backupPath));

afterHide = hide_and_verify_block_names(modelPath, false);
assert(afterHide.visible_name_count == 0);
after = inspect_simulink_model(modelPath);
assert(after.visible_name_count == 0);

load_system(modelPath);
set_param(modelName, 'Description', 'unsaved dirty-guard test');
guardWorked = false;
try
    backup_simulink_model(modelPath, 'dirty-guard');
catch errorInfo
    guardWorked = strcmp(errorInfo.identifier, 'SimulinkBackup:UnsavedChanges');
end
assert(guardWorked, 'Dirty-model protection did not reject the backup operation.');
close_system(modelName, 0);

fprintf('PASS: backup, name hiding, verification, and dirty guard.\n');
end

function cleanupTest(workDir, modelName)
if bdIsLoaded(modelName), close_system(modelName, 0); end
if isfolder(workDir), rmdir(workDir, 's'); end
end
