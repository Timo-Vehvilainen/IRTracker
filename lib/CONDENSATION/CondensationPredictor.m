classdef CondensationPredictor
    %CONDENSATIONPREDICTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % general process data
        m_n_samples
        m_n_iterations
        m_sample_size
        % specific process state data
        m_old_positions
        m_new_positions
        m_sample_weights
        m_cumul_prob_array
    end
    
    methods
        function obj = CondensationPredictor(sample_size, n_samples, ...
                                             n_iterations)
            if nargin < 3, n_iterations = 100; end;
            if nargin < 2, n_samples = 1000; end;
            if nargin < 1, sample_size = 1; end;
            obj.m_n_samples = n_samples;
            obj.m_n_iterations = n_iterations;
            obj.m_sample_size = sample_size;
            
            obj.m_old_positions = zeros(sample_size, n_samples);
            obj.m_new_positions = zeros(sample_size, n_samples);
            obj.m_sample_weights = zeros(1, n_samples);
            obj.m_cumul_prob_array = zeros(1, n_samples);
        end
    end
    
end

