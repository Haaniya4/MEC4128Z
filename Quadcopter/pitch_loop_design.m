
%Constraint for PID

run('setup.m');

s = tf('s');

Po = 1/(Jyy*s^2)*exp(-s*td);

Ts = 1;
OS = 15;

zeta = -log(OS/100)/sqrt(pi()^2+log(OS/100)^2); %damping ratio
wn = 4/zeta/Ts;
wp = wn*sqrt(1-2*zeta^2); %critical deisgn frequency
Ma = 1/(2*zeta*sqrt(1-zeta^2)); %stay below boundary
Mb =0.98;

disp(['zeta= ', num2str(zeta)])
disp(['wn= ', num2str(wn)])
disp(['wp= ', num2str(wp)])
disp(['Ma= ', num2str(Ma)])

%build P only controller

alpha = 1;
beta = 1;
K =1;
G = K*(1+s/alpha)/(1+s/beta);
L = Po*G;

figure(1), clf, hold on
M = [Ma Mb];
for k = 1:length(M)
    phi = linspace(0,2*pi,1e4);
    c = -1; r = 1/M(k);
    Kc = c + r*exp(1i*phi);
    mag_Kc = 20*log10(abs(Kc));
    phi_Kc = angle(Kc)*180/pi;
    phi_Kc(phi_Kc>0) = phi_Kc(phi_Kc>0)-360;
    if k==1
        mag_Ka = mag_Kc; phi_Ka = phi_Kc;   % <-- save M_A boundary
        plot(phi_Ka(2:end-1), -mag_Ka(2:end-1), '--b', 'LineWidth', 2)
    else
        mag_Kb = mag_Kc; phi_Kb = phi_Kc;   % <-- save M_B boundary
        plot(phi_Kb(2:end-1), -mag_Kb(2:end-1), '-g', 'LineWidth', 2)
    end
end

[magL,phiL] = nichols(L,{1e-3,1e3}); %plotting L
plot(squeeze(phiL), squeeze(20*log10(magL)))
plot(-180,0,'ro','MarkerFaceColor','r')

Lw = squeeze(freqresp(L,wp)); %critical frquency pt
ang_Lw = angle(Lw)*180/pi;
if ang_Lw>0, ang_Lw=ang_Lw-360; end
plot(ang_Lw, 20*log10(abs(Lw)), 'o', 'MarkerFaceColor','g','MarkerEdgeColor','k')

xlim([-360,0]), ylim([-40,60])
legend('$|T(j\omega)|\leq M_A$','$|T(j\omega)|\geq M_B$','$L(j\omega)$','Critical Point','$L(j\omega_p)$','Interpreter','latex')

w = logspace(-2,2,2000);
Lw_sweep = squeeze(freqresp(L,w));
Tw = Lw_sweep./(1+Lw_sweep);
magT = 20*log10(abs(Tw));
MadB = 20*log10(Ma);
MbdB = 20*log10(Mb);
violates_Ma = any(magT > MadB)
violates_Mb = any(magT(w<=wp) < MbdB)



Lw = squeeze(freqresp(L,wp));
mag_at_wp = 20*log10(abs(Lw));
phase_at_wp = angle(Lw)*180/pi;
if phase_at_wp > 0, phase_at_wp = phase_at_wp - 360; end
disp(['mag_at_wp = ', num2str(mag_at_wp)])
disp(['phase_at_wp = ', num2str(phase_at_wp)])

tol = 0.5;
candidates = find(abs(-mag_Ka - mag_at_wp) < tol);
if isempty(candidates)
    disp('wp is outside the Ma ellipse range — check a different frequency')
else
    boundary_phase = max(phi_Ka(candidates));
    disp(['boundary_phase = ', num2str(boundary_phase)])
    phi_required = boundary_phase - phase_at_wp
end














% Kp = 0.005;
% alpha_p = 0.325;
% beta_p = 42.44;
% Ti_p= 5;
% 
% 
% Kx = 0.2;
% alpha_x = 0.1738;
% beta_x = 10.026;
% Ti_x = 10;
% 
% Kz = 0.2;
% alpha_z = 0.1738;
% beta_z = 10.026;
% Ti_z = 10;