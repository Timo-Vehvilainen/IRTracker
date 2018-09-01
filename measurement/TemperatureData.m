classdef TemperatureData < handle
    %TEMPERATUREDATA Temperature data abstraction
    %   TEMPERATUREDATA is a container for measurement node temperature
    %   data. It stores raw temperature data which is then averaged to the
    %   output. This object also allows the user to set error data for each
    %   sample that is applied on the temperature data at the output.
    
    properties (Constant)
        ALLOC_SIZE = 32  % Size of the allocation when a data vector runs out of space
    end
    
    properties
        t_data              % Time stamp data container
        val_data            % Raw temperature data
        err_data            % Error data
        i_back              % Index to the first element after the (already set) data

        integration_frames  % Number of integration frames
        integration_coeffs  % Weights for each frame
    end
    
    methods
        
        function [obj] = TemperatureData()
            %TEMPERATUREDATA  Create new TemperatureData object.
            obj.t_data = [];
            obj.val_data = [];
            obj.err_data = [];
            obj.i_back = 1;
            obj.setIntegrationCoeffs('polynomial', 3);
        end
        
        
        function skip(obj)
            %SKIP  Skip one element.
            obj.i_back = obj.i_back + 1;
        end
        
        
        function [t_out, val_out] = step(obj, t_in, val_in)
            %STEP  Add one data point.
            obj.checkAllocation();
            obj.t_data(obj.i_back) = t_in;
            obj.val_data(obj.i_back) = val_in;
            % integrate 
            [t_out, val_out] = obj.integrate(obj.i_back);
            obj.i_back = obj.i_back + 1;
        end
        
        
        function [t_out, val_out] = setError(obj, err_signal, start_idx)
            %SETERROR  Add error signal for certain samples.
            e_len = length(err_signal);
            idx = (start_idx - 1) + (1 : e_len);
            obj.err_data(idx) = err_signal;
            % Get revised signal
            [t_out, val_out] = obj.integrateInterval(start_idx, e_len);
        end
        
    end  % public methods
    
    
    methods (Access = protected)
        
        function setIntegrationCoeffs(obj, type, n)
            %SETINTEGRATIONCOEFFS  Compute and set integration coefficients.
            obj.integration_frames = n;
            coeffs = ones(n);
            switch lower(type)
                case 'polynomial', coeffs = generatePolynomialCoeffs(n);
            end
            obj.integration_coeffs = coeffs / sum(coeffs);
        end
        
        
        function [t, val] = integrate(obj, step)
            %INTEGRATE Integrate over frames
            t = NaN;
            val = NaN;
            if step >= obj.integration_frames
                indices = step + (1 - obj.integration_frames : 0);
                val = ...
                    sum((obj.val_data(indices) - obj.err_data(indices)) ...
                    .* obj.integration_coeffs);
                t = sum(obj.t_data(indices) .* obj.integration_coeffs);
            end
        end
        
        
        function [t_out, val_out] = integrateInterval(obj, start_idx, len)
            %INTEGRATEINTERVAL Integrate over a collection of samples.
            t_out = zeros(1, len);
            val_out = zeros(1, len);
            for i = 1 : len
                [t_out(i), val_out(i)] = ...
                    obj.integrate(i + (start_idx - 1));
            end
        end
        
    end  % protected methods
    
    
    methods (Access = private)
        
        function checkAllocation(obj)
            %CHECKALLOCATION  Ensure that new data fits the data vectors.
            if obj.i_back > length(obj.t_data)
                obj.t_data = [obj.t_data, ...
                              zeros(1, TemperatureData.ALLOC_SIZE)];
                obj.val_data = [obj.val_data, ...
                                NaN(1, TemperatureData.ALLOC_SIZE)];
                obj.err_data = [obj.err_data, ...
                                zeros(1, TemperatureData.ALLOC_SIZE)];
            end
        end
        
    end  % private methods
end


function [coeffs] = generatePolynomialCoeffs(n_coeffs)
    %GENERATEPOLYNOMIALCOEFFS  Generate polynomial coefficients for polynomial integration filter.
    n = n_coeffs - 1;
    coeffs = zeros(1, n_coeffs);
    for i = 1 : n_coeffs
        coeffs(i) = nchoosek(n, i-1);
    end
end
