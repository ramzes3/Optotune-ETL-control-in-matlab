% Script serves as a demonstration of some of the functionality of optotune
% class


% adjust COM port accordingly
AL = Optotune('COM4'); 

%%
AL.Open();

%% current mode

AL.currentMode();

AL.setCurrent(100);
pause(0.5)
AL.setCurrent(-100);
pause(0.5)
AL.setCurrent(0);

%% refractive power mode
AL.focalPowerMode();
AL.setRefractivePower(5);
pause(0.5)
AL.setRefractivePower(-5);
pause(0.5)
AL.setRefractivePower(0);

%% sinusoidal mode

AL.setModeLowerCurrent(0);
AL.setModeUpperCurrent(50);
AL.setModeFrequency(0.25); 
AL.sinusoidalMode();



%% read current temperature
AL.getTemperature();
AL.temperature

%%
AL.Close();