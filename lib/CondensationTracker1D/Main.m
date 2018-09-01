% 1D Tracker Using Condensation Algorithm
% Prakash Manandhar http://p-manandhar.info
% pmanandhar@umassd.edu Dec 2, 2008

% Consider a single parameter in a circular 1-D space (from 0 to 2*pi
% angle) to be estimated. The parameter, theta, evolves dynamically 
% following an AR(1) model, with mean zero and scaling 1:
% theta(t) = theta(t-1) + w_t
% where w_t is gaussian zero mean white noise with known variance.

% We start with the prior that the estimate is distributed uniformly in
% the space (0 to 2pi). A factored sampling approach is used to keep track
% of N samples (possibly overlapping) along with N probability densities 
% at these samples. This set is updated at each iteration using 
% Fokker-Plank style diffusion, again using the factored sampling approach.
% The resulting set is updated based on M measurements (although there is 
% only one parameter, M measurements result due to clutter) of theta at 
% time t. There is a constant probability, q, that none of the M 
% measurements are correct. 
% lambda is the clutter spatial density (average number of clutter detected
% per unit length)

%OBS_FILE = 'Set1Obs.dat'; GWD_FILE = 'Set1Ground.dat';
OBS_FILE = 'Set2Obs.dat'; GWD_FILE = 'Set2Ground.dat';

rand('state', 0); % reset random number generator seed
global N M sigma s p c q obs T
global MIN MAX LENGTH lambda alpha obs_factor

N = 100; % number of samples in factored samples set
M = 5; % number of measurements
sigma = 2*pi/256; % standard deviation of gaussian
lambda = 1/(2*pi); % clutter density

MIN = 0; MAX = 2*pi; LENGTH = MAX - MIN; % domain

s = rand(N, 1)*2*pi; % column vector of samples distributed uniformly between 0 and 1
p = ones(N, 1)/N;    % column vector of probabilities for the samples
c = p(1):p(1):1;     % column vector of cumulatives

q = 0.1; % probability of non-detection
alpha = q*lambda; 
obs_factor = 1/(sqrt(2*pi)*sigma*alpha);
% load measurements. This is a T by 10 matrix
% where t = 1..T is the time index and there are 10 measurements per frame
% at each frame, the 10 best estimates are selected
fid_obs = fopen(OBS_FILE);

obs = fread(fid_obs, [10 inf], 'int');
obs = 2*pi*obs'/256;
T = size(obs, 1);

theta_hat = zeros(T, 1);
t_step    = (1:T)';

for t = 1:T
    figure(1); plot(s, p, '-'); % comment for faster execution
    xlabel('theta (0..2\pi)'); ylabel ('\pi (prior probability)');
    axis([0 2*pi 0 0.02]);      % comment for faster execution
    [s, p, c] = IterateCondensation(t);
    theta_hat(t) = sum(p.*s);
     fprintf('%d: %f\n', t, theta_hat(t)); % comment for faster execution
    pause(0.1); % comment for faster execution
%     pause
end

fid_theta = fopen(GWD_FILE);
theta = fread(fid_theta, 'char');
theta = theta(2:2:end);
theta = 2*pi*theta/256;
figure(2); plot(t_step, theta_hat, t_step, theta, t_step, obs(:, 1:M));
xlabel('t(frame index)'); ylabel('theta (feature estimate/measurement)');
