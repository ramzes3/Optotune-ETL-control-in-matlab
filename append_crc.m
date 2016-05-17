function output = append_crc(intput_command)
%% Calculates check sum for Optotune lens driver and appends it to the end of the message
%% written by Roman Spesyvtsev  %%%%%%%%%%%%%
%%% The code is provided under the GPL licinse without any warranty %%%%%

a = intput_command;
s1 = length(a); %% size of the command array
crc = uint16(0); %%, i;
i = uint16(0);
c1 = hex2dec('a001');
for i=1:s1
    crc = bitxor(crc,a(i)); %% crc = crc^a;
    for j = 1:8
        if bitand(crc,1)  %%crc & 1
            crc = bitshift(crc,-1); %% crc = crc >> 1; %% crc = (crc >> 1) ^ 0xA001;
            crc = bitxor(crc, c1); %% crc = crc ^ c1;
        else
            crc = bitshift(crc,-1); %% crc = crc >> 1 
        end
    end
    
end
check_sum = a;
check_sum(end+1) = bitand(crc,hex2dec('ff'));
check_sum(end+1) = bitshift(crc,-8);
%%check_sum(end+1) = bitshift(bitand(crc,hex2dec('ff00')),-8);

output = check_sum;
