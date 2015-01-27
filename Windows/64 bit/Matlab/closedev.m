fprintf('\nclosing all TimeHarp 260 devices\n');
if (libisloaded('TH260lib'))   
    for(i=0:7); % no harm to close all
        calllib('TH260lib', 'TH260_CloseDevice', i);
    end;
end;
