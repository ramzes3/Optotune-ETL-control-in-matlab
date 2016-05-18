classdef Optotune < handle
    
    % Optotune class is designed to control electro tunable lens from optotune.com
    % The script is written by R. Spesyvtsev from the Optical manipulation group (http://www.st-andrews.ac.uk/~photon/manipulation/)
    %
    % constructor Optotune(com port), example lens = Optotune('COM9');
    % connect: lens = lens.Connect();
    % set current to 100 mA:  lens = lens.setCurrent(100);
    
    properties
        etl_port;
        port;
        status;
        response;
        
        temperature = 0;
        current = 0; %% in mAmpers
        max_current = 0; % in mAmpers
        min_current = 0; % in mAmpers
        calibration = 1;  % in mAmpers/micrometer
        
        max_bin = 0;
        time_pause = 0.3;
        time_laps = 0.01;
        last_time_laps;
    end
    
    methods
        function lens=Optotune(port)
            if (nargin<1)
                lens.port='COM3';
            else
                lens.port = port;
            end
        end
        
        function lens = Open(lens)
            %% Setting up initial parameters for the com port
            lens.etl_port = serial(lens.port);
            lens.etl_port.Baudrate=115200;
            lens.etl_port.StopBits=1;
            lens.etl_port.Parity='none';
            
            fopen(lens.etl_port);
            lens.status = lens.etl_port.Status;   %%% checking if initialization was completed the status should be "open"
            
            %% Initialize communication        
            fprintf(lens.etl_port, 'Start'); %%% initiating the communication
            lens.last_time_laps = checkStatus(lens); 
            %lens.etl_port.BytesAvailable;  %%% checking number of bytes in the response
            fscanf(lens.etl_port);  %%% reading out the response which should read "Ready"
            if lens.etl_port.BytesAvailable
                fread(lens.etl_port,lens.etl_port.BytesAvailable);
            end
            lens = lens.getUpperLimitA();
        end
        
        function lens = readTemperature(lens)
            command = append_crc('TA'-0);
            fwrite(lens.etl_port, command);
            lens.last_time_laps = checkStatus(lens);            
            %pause(lens.time_pause);
            %lens.etl_port.BytesAvailable;  %%% checking number of bytes in the response
            lens.response = fread(lens.etl_port,lens.etl_port.BytesAvailable);
            x = lens.response(4)*(hex2dec('ff')+1) + lens.response(5);
            lens.temperature = x*0.0625;
        end
        
        function lens = readCurrent(lens)
            %% Get current in mA %%%%%%%%
            command = append_crc(['Ar'-0 0 0]);
            fwrite(lens.etl_port, command);
            %pause(lens.time_pause);
            lens.last_time_laps = checkStatus(lens); 
            lens.response = fread(lens.etl_port,lens.etl_port.BytesAvailable);
            lens.current = lens.response(2)*(hex2dec('ff')+1) + lens.response(3);
            lens.current = lens.current * lens.max_current / (lens.max_bin+1);            
        end
        
        function setCurrent(lens, ci) %% Set current in mA via ci variable
            %% Set current %%%%%%%%       
            set_i = (floor(ci*(lens.max_bin+1) / lens.max_current));
            LB = mod(set_i,256); %% low byte
            HB = (set_i-LB)/256; %% high byte            
            command = append_crc(['Aw'-0 HB LB]);
            fwrite(lens.etl_port, command);             
            %pause(lens.time_pause);
        end
        
        function lens = setTemperatureLimits(lens)
            %% setting temperature limits for operation in focal power mode
            % The function has not been finished
            temp_high = 80/0.0625;  %% Upper limit 80 degrees (see Optotune manual for available limits) 
            temp_low = 0/0.0625;     %% Lower limit 0 degrees
            LBH = mod(temp_high,256); %% low byte
            HBH = (temp_high-LBH)/256; %% high byte
            LBL = mod(temp_low,256); %% low byte
            HBL = (temp_low-LBL)/256; %% high byte
            command = append_crc(['PrTA'-0 HBH LBH HBL LBL]);
            fwrite(lens.etl_port, command);
            lens.last_time_laps = checkStatus(lens); 
            lens.response = fread(lens.etl_port,lens.etl_port.BytesAvailable);
            
        end
        
        function lens = getUpperLimitA(lens)
            %% Get current limit %%%%%%%%
            command = append_crc(['CrUA'-0 0 0]);
            fwrite(lens.etl_port, command);
            %pause(lens.time_pause);
            lens.last_time_laps = checkStatus(lens); 
            lens.response = fread(lens.etl_port,lens.etl_port.BytesAvailable);
            lens.max_bin = lens.response(4)*(hex2dec('ff')+1) + lens.response(5)+1;  %% hardware current limit usually 4095;
            %%
            command = append_crc(['CrMA'-0 0 0]);
            fwrite(lens.etl_port, command);
            lens.last_time_laps = checkStatus(lens); 
            %pause(lens.time_pause);           
            lens.response = fread(lens.etl_port,lens.etl_port.BytesAvailable);
            lens.max_current = lens.response(4)*(hex2dec('ff')+1) + lens.response(5);  %% software current limit usually 292.84 mA;
            lens.max_current = lens.max_current / 100; %% reads current in mili ampers 
        end
        
        function lens = Close(lens)
            %%  Closing the port when finished using it %%%%%%%%%%%%
            fclose(lens.etl_port);
            delete(lens.etl_port);
            clear lens.etl_port
            
            lens.status = 'closed';
            lens.response = 'Shut down';
            
        end        
                
        function tElapsed = checkStatus(lens)            
            bts = lens.etl_port.BytesAvailable;  %%% checking number of bytes in the response
            tStart = tic;
            tElapsed = 0;
            while (bts ==0) || (tElapsed >5)
                bts = lens.etl_port.BytesAvailable;  %%% checking number of bytes in the response
                pause(lens.time_laps);
                tElapsed = toc(tStart);
            end                
        end
        
    end
    
end
