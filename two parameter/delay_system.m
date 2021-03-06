function [time,states] = delay_system(z_in,a_normalized,omega,modes,Tf,points,physical_parameters) 
history = [pi/24; 0; 0; 0];
tspan = [0 Tf];
tau = physical_parameters(10);
sol = dde23(@ddex1de,tau,history,tspan,[],z_in,modes,omega,a_normalized,physical_parameters);
time = linspace(0,Tf,points);
states = deval(sol,time);
end

function states_dot = ddex1de(t,states,Z,z_in,modes,omega,a_normalized,physical_parameters)  

m = physical_parameters(1); 
l = physical_parameters(2); 
kappa = physical_parameters(3); 
k1 = physical_parameters(4); 
k2 = physical_parameters(5);  
M = physical_parameters(6); 
C = physical_parameters(7);  
K = physical_parameters(8);  
g = physical_parameters(9);
tau = physical_parameters(10);
a = a_normalized*sqrt(omega^2*C^2+K^2);

% Reconstructs signals in time domain from Fourier coefficients
Fourier_sum = zeros(2*modes+2); 
Fourier_sum(1) = z_in(1);  
Fourier_sum(modes+2) = z_in(2*modes+2);

for i = 1:modes
   Fourier_sum(i+1,1) = z_in(2*i) + j*z_in(2*i+1); 
   Fourier_sum(modes+i+2) = z_in(2*modes+1+2*i) + j*z_in(2*modes+1+2*i+1); 
end


theta_dot = zeros(2,1);
theta = states(1:2);
theta_tilde = Fourier_sum(1);  
thetadot_tilde = 0;
y_a_ddot = 0;

for k = 1:modes
    theta_tilde = theta_tilde + 2*real(Fourier_sum(k+1)*exp(k*j*2*pi*(t-tau)));
    thetadot_tilde = thetadot_tilde + 2*real(Fourier_sum(k+1)*(k*j*2*pi)*exp(k*j*2*pi*(t-tau)));
    y_a_ddot = y_a_ddot + 2*real(Fourier_sum(modes+k+i)*(k*j*2*pi)^2*exp(k*j*2*pi*(t-tau)));                   
end

timescale = (omega/(4*pi)); %Timescale to scale inputs to period 1
y_a_ddot = y_a_ddot*(timescale^2); 
thetadot_tilde = thetadot_tilde*timescale;

thetalag1 = Z(1);
thetalag2 = Z(2);

% Pendulum system
theta_dot(1) = theta(2);
PD_control = k1*(thetalag1 - theta_tilde) + k2*((thetalag2*timescale) - thetadot_tilde)/(timescale^2);
theta_dot(2) = (-(sin(theta(1))/l)*(y_a_ddot+g) - kappa/(m*l^2)*theta(2)*timescale)/(timescale^2) - PD_control;

% Force calculation
F = -m*y_a_ddot - m*l*(theta_dot(2)*sin(theta(1))*(timescale^2) + ((theta(2)))^2*cos(theta(1))*(timescale^2)); 
          
% MSD system
y_dot = zeros(2,1);
y = states(3:4,1);
y_dot(1) = y(2);
C = C*(omega/4*pi);
y_dot(2) = (1/M)*(-C*y(2) - K*y(1) + a*cos(4*pi*t) + F)/(timescale^2);

states_dot = [theta_dot;y_dot];
end