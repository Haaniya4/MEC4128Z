
% Turns Simulink outputs x, z, phi (already in your base workspace)
% into an animated GIF of the quadcopter moving in the X-Z plane,
% drawn in the same style as your "idealised hover" figure.
%
% Works whether x, z, phi are:
%   - timeseries objects (Simulink "To Workspace" -> Save format: Timeseries), or
%   - plain numeric arrays, paired with a time vector called "tout"
%     (Simulink "To Workspace" -> Save format: Array, with time logged too), or
%   - plain numeric arrays with no time vector, in which case a time
%     vector is invented using SAMPLE_TIME below.
%
% Just run this script after your model has finished simulating
% (x, z, phi must exist in the base workspace).

%% ---------- USER SETTINGS ----------
gifFileName   = 'quadcopter_animation.gif';
frameRate     = 20;      % playback fps of the gif
maxFrames     = 150;     % gif will be downsampled to about this many frames
SAMPLE_TIME   = 0.01;    % only used if no time vector can be found
trailOn       = true;    % draw a faint path behind the vehicle

% How the camera frames the vehicle:
%   'follow' - view stays centered & zoomed on the quadcopter (good when
%              armLength is small relative to how far it travels, e.g.
%              a long forward-flight trajectory)
%   'fixed'  - view is fixed to show the entire trajectory at once (good
%              for near-hover tests where the vehicle barely moves)
viewMode      = 'follow';
followSpan    = 1.0;     % (m) half-width of the follow window, 'follow' mode only

% Pull physical parameters (armLength, etc.) from setup.m so this script
% always stays in sync with your model instead of using hardcoded guesses.
% setup.m must be on your MATLAB path (it usually is, if it's in the same
% project folder you're running this from).
try
    run('setup.m');
catch ME
    error(['Could not run setup.m (%s). Make sure setup.m is on your ' ...
        'MATLAB path or current folder, e.g.:\n' ...
        'cd(''C:\\Users\\Haaniya\\OneDrive - University of Cape Town\\' ...
        '4th Year\\Sem 2\\MEC4128Z\\MEC4128Z Final Year Project Submission\\' ...
        'Modelling\\Quadcopter'')'], ME.message);
end

% setup.m defines "l" = arm length, COM to each motor shaft.
if exist('l', 'var')
    armLength = l;
else
    warning('Variable "l" not found after running setup.m; defaulting armLength to 0.1.');
    armLength = 0.1;
end

%% ---------- LOAD / NORMALISE DATA ----------
% Tries a few common variable names so this works whether your
% To Workspace blocks are named x/z/phi or x_log/z_log/phi_log etc.
xVar   = local_find_var({'x_log', 'x', 'X_log', 'X'});
zVar   = local_find_var({'z_log', 'z', 'Z_log', 'Z'});
phiVar = local_find_var({'phi_log', 'phi', 'Phi_log', 'Phi'});

[t, xd]   = local_extract(xVar,   'x');
[~, zd]   = local_extract(zVar,   'z');
[~, phid] = local_extract(phiVar, 'phi');

n = min([numel(t), numel(xd), numel(zd), numel(phid)]);
t = t(1:n); xd = xd(1:n); zd = zd(1:n); phid = phid(1:n);

% Resample evenly in TIME (not in sample index) so GIF playback speed
% matches real simulation time: one frame every 1/frameRate seconds of
% simulated time, using the nearest actual logged sample for each.
frameDt = 1 / frameRate;
tGrid = (t(1):frameDt:t(end))';
if numel(tGrid) > maxFrames
    warning(['Real-time playback at %d fps needs %d frames for this %.2fs ' ...
        'simulation, exceeding maxFrames (%d). Producing the full-length, ' ...
        'true-to-time GIF anyway - increase maxFrames to silence this, or ' ...
        'lower frameRate if the file gets too large.'], ...
        frameRate, numel(tGrid), t(end)-t(1), maxFrames);
end
idx = interp1(t, 1:n, tGrid, 'nearest', 'extrap');
t = t(idx); xd = xd(idx); zd = zd(idx); phid = phid(idx);

%% ---------- FIGURE SETUP ----------
fig = figure('Color', 'w');
ax = axes(fig); hold(ax, 'on'); grid(ax, 'on'); axis(ax, 'equal');
xlabel(ax, 'X (m)'); ylabel(ax, 'Z (m)');
title(ax, 'Quadcopter simulation');

padX = 0.3 * max(max(xd)-min(xd), armLength) + armLength;
padZ = 0.3 * max(max(zd)-min(zd), armLength) + armLength;
if strcmp(viewMode, 'fixed')
    xlim(ax, [min(xd)-padX, max(xd)+padX]);
    ylim(ax, [min(zd)-padZ, max(zd)+padZ]);
else
    % 'follow': initial limits, will be re-centered on the vehicle each frame
    xlim(ax, [xd(1)-followSpan, xd(1)+followSpan]);
    ylim(ax, [zd(1)-followSpan, zd(1)+followSpan]);
end

if trailOn
    trailLine = plot(ax, NaN, NaN, '-', 'Color', [0.6 0.6 1], 'LineWidth', 1);
end

% Body handles, created once and updated each frame
armLine1 = plot(ax, NaN, NaN, 'k-', 'LineWidth', 2);   % arm 1 (front-back)
armLine2 = plot(ax, NaN, NaN, 'k-', 'LineWidth', 2);   % arm 2 (left-right, drawn slightly offset for a "+" look)
rotor1 = patch(ax, 'XData', NaN, 'YData', NaN, 'FaceColor', 'r', 'EdgeColor', 'none');
rotor2 = patch(ax, 'XData', NaN, 'YData', NaN, 'FaceColor', 'r', 'EdgeColor', 'none');
centerDot = plot(ax, NaN, NaN, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 5);
timeText = text(ax, 0, 0, '', 'Units', 'normalized', 'Position', [0.02 0.95], ...
    'FontSize', 10, 'BackgroundColor', 'w');

theta = linspace(0, 2*pi, 30); % for drawing rotor ellipses

%% ---------- ANIMATE + CAPTURE ----------
for k = 1:numel(idx)
    xc = xd(k); zc = zd(k); ph = phid(k);

    R = [cos(ph) -sin(ph); sin(ph) cos(ph)];

    % Arm endpoints in body frame (a simple "+" quad layout, arm 1 along
    % body x-axis, arm 2 along body z-axis, matching the reference image)
    tip1 = R * [ armLength; 0 ];
    tip2 = R * [-armLength; 0 ];
    tip3 = R * [ 0;  armLength*0.4 ]; % shortened vertical strut just for visual flair

    set(armLine1, 'XData', xc + [-tip1(1) tip1(1)], 'YData', zc + [-tip1(2) tip1(2)]);
    set(armLine2, 'XData', xc + [0 tip3(1)],        'YData', zc + [0 tip3(2)]);

    % Rotor blobs (small ellipses) at each arm tip
    rw = armLength*0.35; rh = armLength*0.12;
    ellipseLocal = [rw*cos(theta); rh*sin(theta)];

    p1 = R*ellipseLocal + [xc + tip1(1); zc + tip1(2)];
    p2 = R*ellipseLocal + [xc - tip1(1); zc - tip1(2)];
    set(rotor1, 'XData', p1(1,:), 'YData', p1(2,:));
    set(rotor2, 'XData', p2(1,:), 'YData', p2(2,:));

    set(centerDot, 'XData', xc, 'YData', zc);
    set(timeText, 'String', sprintf('t = %.2f s', t(k)));

    if trailOn
        set(trailLine, 'XData', xd(1:k), 'YData', zd(1:k));
    end

    if strcmp(viewMode, 'follow')
        xlim(ax, [xc-followSpan, xc+followSpan]);
        ylim(ax, [zc-followSpan, zc+followSpan]);
    end

    drawnow;

    frame = getframe(fig);
    im = frame2im(frame);
    [imind, cm] = rgb2ind(im, 256);
    if k == 1
        imwrite(imind, cm, gifFileName, 'gif', 'Loopcount', inf, ...
            'DelayTime', 1/frameRate);
    else
        imwrite(imind, cm, gifFileName, 'gif', 'WriteMode', 'append', ...
            'DelayTime', 1/frameRate);
    end
end

fprintf('Saved animation to %s\n', gifFileName);

%% ---------- HELPERS ----------
function v = local_find_var(candidateNames)
% Looks in the base workspace for the first variable name in
% candidateNames that actually exists, and returns its value.
    for i = 1:numel(candidateNames)
        nm = candidateNames{i};
        if evalin('base', sprintf('exist(''%s'',''var'')', nm))
            v = evalin('base', nm);
            return;
        end
    end
    error(['None of these variables were found in the base workspace: %s.\n' ...
        'Run "whos" in MATLAB after simulating and update the candidate ' ...
        'names in animate_quadcopter.m to match your actual logged signal names.'], ...
        strjoin(candidateNames, ', '));
end

function [t, d] = local_extract(v, name)
% Normalises a Simulink logged variable into a plain time vector t and
% data vector d, regardless of whether it was logged as a timeseries or
% a plain array.
    if isa(v, 'timeseries')
        t = v.Time(:);
        d = v.Data(:);
    elseif isstruct(v) && isfield(v, 'time') && isfield(v, 'signals')
        % "Structure" logging format from To Workspace
        t = v.time(:);
        d = v.signals.values(:);
    else
        d = v(:);
        if evalin('base', 'exist(''tout'',''var'')')
            t = evalin('base', 'tout');
            t = t(:);
        else
            ts = evalin('base', 'SAMPLE_TIME');
            warning(['No time vector found for "%s"; assuming a fixed ' ...
                'sample time of %.4g s. Set SAMPLE_TIME at the top of ' ...
                'this script if that is wrong.'], name, ts);
            t = (0:numel(d)-1)' * ts;
        end
    end
end