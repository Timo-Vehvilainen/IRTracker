function [s_n, p_n, c_n] = IterateCondensation(t)
% Performs single iteration of the Condensation algorithm
% Prakash Manandhar http://p-manandhar.info
global N M sigma s p c q obs T
global MIN MAX LENGTH lambda alpha obs_factor

% Generate new sample set, s' by sampling
s_p = zeros(N, 1);
for n = 1:N
    s_p(n) = pick_base_sample;
end

% diffusion
s_n = zeros(N, 1);
for n = 1:N
    s_n(n) = s_p(n) + randn*sigma;
    % fold for circular domain
    if (s_n(n) < MIN) 
        s_n(n) = s_n(n) + LENGTH;
    elseif (s_n(n) >= MAX) 
        s_n(n) = s_n(n) - LENGTH;
    end
end

s_n = sort(s_n);

% measurement
p_n = zeros(N, 1);
c_n = zeros(N, 1);
for n = 1:N
   p_n(n) = 1 + obs_factor * sum(exp(-(obs(t, 1:M) - s_n(n)).^2/(2*sigma^2)));
   if n == 1
       c_n(1) = p_n(1);
   else
       c_n(n) = c_n(n-1) + p_n(n);
   end
end
sum_p = sum(p_n);
p_n = p_n/sum_p;
c_n = c_n/sum_p;

% % binary search adapted from source code at Condensation website
% % http://homepages.inf.ed.ac.uk/rbf/CVonline/LOCAL_COPIES/ISARD1/condensation.html
function s_new = pick_base_sample
    global N s c

    choice = rand*max(c);

    low = 1;
    high = N;

    while (high > (low+1)) 
        middle = floor((high + low)/2);
        if (choice > c(middle))
            low = middle;
        else 
            high = middle;
        end
    end
    s_new = s(low);
