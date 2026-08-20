
%Constraint for PID

run('setup.m');

s = tf('s');

Ts = 1;
OS = 15;

zeta = -log(OS/100)/sqrt(pi()^2+log(OS/100)^2);
wn = 4/zeta/Ts;
wp = wn*sqrt(1-2*zeta^2);
Ma = 1/(2*zeta*sqrt(1-zeta^2));

disp(['zeta= ', num2str(zeta)])
disp(['wn= ', num2str(wn)])
disp(['wp= ', num2str(wp)])
disp(['Ma= ', num2str(Ma)])th



Kp = 0.005;
alpha_p = 0.325;
beta_p = 42.44;
Ti_p= 5;


Kx = 0.2;
alpha_x = 0.1738;
beta_x = 10.026;
Ti_x = 10;

Kz = 0.2;
alpha_z = 0.1738;
beta_z = 10.026;
Ti_z = 10;