Jyy = 5.343596e-5; %Mass moment of inertia about yB(kg.m^2)
Jxx = 5.473766e-5;%Mass moment of inertia about xB(kg.m^2)
Jzz = 9.8934e-5;%Mass moment of inertia about zB(kg.m^2)

m = 0.5; %Total mass of the quadcopter (kg)
g = 9.81; %gravitational acceleration
kf = 1e-5; %thrust coefficient 
kt = 1e-8; %torque coefficient. smaller than kf
l = 0.1; %Arm length, COM to each motor shaft
td = 0.01; %Delay
w_lim = 8000; %Max rotor speed

