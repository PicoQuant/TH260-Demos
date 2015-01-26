
% Demo for access to TimeHarp 260 Hardware via TH260LIB.DLL v 1.1.
% The program performs a TTTR measurement based on hardcoded settings.
% The resulting data stream is stored in a binary output file.
%
% Michael Wahl, PicoQuant, September 2013


% Constants from hhdefin.h

REQLIBVER   =     '1.1';	 % this is the version this program expects
MAXDEVNUM   =         4;
TTREADMAX   =    131072;     % 128K event records 
MODE_HIST   =         0;
MODE_T2	    =         2;
MODE_T3	    =         3;

FLAG_FIFOFULL = hex2dec('0002');

% Errorcodes from errorcodes.h

TH260_ERROR_DEVICE_OPEN_FAIL		 = -1;

% Settings for the measurement, Adapt to your setup!
Mode          = MODE_T2; % you can change this
SyncDiv       = 1;       %  you can change this (observe mode!)
Binning       = 0;       %  you can change this (observe mode!)
Tacq          = 1000;    %  you can change this  

SyncOffset    = -10000;  %  you can change this
InputOffset   = 0;       %  you can change this

% These settings will apply for TimeHarp 260 P boards
SyncCFDZeroX  = -10;      %  you can change this
SyncCFDLevel  = -50;      %  you can change this
InputCFDZeroX = -10;      %  you can change this
InputCFDLevel = -50;      %  you can change this

% These settings will apply for TimeHarp 260 N boards
SyncTiggerEdge    =0;     %  you can change this
SyncTriggerLevel  =-50;   %  you can change this
InputTriggerEdge  =0;     %  you can change this
InputTriggerLevel =-50;   %  you can change this
 
      
fprintf('\nTimeHarp 260 TH260Lib Demo Application             PicoQuant 2013\n');

if (~libisloaded('TH260lib'))    
    %Attention: The header file name given below is case sensitive and must
    %be spelled exactly the same as the actual name on disk except the file 
    %extension. 
    %Wrong case will apparently do the load successfully but you will not
    %be able to access the library!
    %The alias is used to provide a fixed spelling for any further access via
    %calllib() etc, which is also case sensitive.
    loadlibrary('th260lib64.dll', 'th260lib.h', 'alias', 'TH260lib');
else
    fprintf('Note: TH260lib was already loaded\n');
end;

if (libisloaded('TH260lib'))
    fprintf('TH260lib opened successfully\n');
    %libfunctionsview('TH260lib'); %use this to test for proper loading
else
    fprintf('Could not open TH260lib\n');
    return;
end;
    
LibVersion    = blanks(8); % reserve enough length!
LibVersionPtr = libpointer('cstring', LibVersion);

[ret, LibVersion] = calllib('TH260lib', 'TH260_GetLibraryVersion', LibVersionPtr);
if (ret<0)
    fprintf('Error in GetLibraryVersion. Aborted.\n');
    err = TH260_GETLIBVERSION_ERROR;
else
	fprintf('TH260lib version is %s\n', LibVersion);
end;

if ~strcmp(LibVersion,REQLIBVER)
    fprintf('This program requires TH260lib version %s\n', REQLIBVER);
    return;
end;

fid = fopen('tttrmode.out','wb');
if (fid<0)
    fprintf('Cannot open output file\n');
    return;
end;

fprintf('\nSearching for TimeHarp 260 devices...');

dev = [];
found = 0;
Serial     = blanks(8); %enough length!
SerialPtr  = libpointer('cstring', Serial);

for i=0:MAXDEVNUM-1
    [ret, Serial] = calllib('TH260lib', 'TH260_OpenDevice', i, SerialPtr);
    if (ret==0)       % Grab any TimeHarp 260 we successfully opened
        fprintf('\n  %1d        S/N %s', i, Serial);
        found = found+1;            
        dev(found)=i; %keep index to devices we may want to use
    else
        if(ret==TH260_ERROR_DEVICE_OPEN_FAIL)
            fprintf('\n  %1d        no device', i);
        else 
            fprintf('\n  %1d        %s', i, geterrorstring(ret));
        end;
	end;
end;
    
% In this demo we will use the first TimeHarp 260 device we found, i.e. dev(1).
% If you have nultiple TimeHarp 260 devices you could also check for a specific 
% serial number, so that you always know which physical device you are talking to.

if (found<1)
	fprintf('\nNo device available. Aborted.\n');
	return; 
end;

fprintf('\nUsing device #%1d',dev(1));
fprintf('\nInitializing the device...');

[ret] = calllib('TH260lib', 'TH260_Initialize', dev(1), Mode); 
if(ret<0)
	fprintf('\nTH260_Initialize error %s. Aborted.\n', geterrorstring(ret));
    closedev;
	return;
end; 

%this is only for information
Model      = blanks(16); % reserve enough length!
Partno     = blanks(8);  % reserve enough length!
Version    = blanks(16); % reserve enough length!
ModelPtr   = libpointer('cstring', Model);
PartnoPtr  = libpointer('cstring', Partno);
VersionPtr = libpointer('cstring', Version);

[ret, Model, Partno, Version] = calllib('TH260lib', 'TH260_GetHardwareInfo', dev(1), ModelPtr, PartnoPtr, VersionPtr);
if (ret<0)
    fprintf('\nTH260_GetHardwareInfo error %s. Aborted.\n', geterrorstring(ret));
    closedev;
	return;
else
	fprintf('\nFound model %s part number: %s version : %s', Model, Partno, Version);             
end;

NumInpChannels = int32(0);
NumChPtr = libpointer('int32Ptr', NumInpChannels);
[ret,NumInpChannels] = calllib('TH260lib', 'TH260_GetNumOfInputChannels', dev(1), NumChPtr); 
if (ret<0)
    fprintf('\nTH260_GetNumOfInputChannels error %s. Aborted.\n', geterrorstring(ret));
    closedev;
	return;
else
	fprintf('\nDevice has %i input channels.\n', NumInpChannels);             
end;

fprintf('\n');
fprintf('Measurement Mode  : T%ld\n',Mode);
fprintf('Binning           : %ld\n',Binning);
fprintf('AcquisitionTime   : %ld\n',Tacq);
fprintf('SyncDivider       : %ld\n',SyncDiv);

if (Model == 'TimeHarp 260 P')
 fprintf('SyncCFDZeroCross  : %ld\n',SyncCFDZeroX);
 fprintf('SyncCFDLevel      : %ld\n',SyncCFDLevel);
 fprintf('InputCFDZeroCross : %ld\n',InputCFDZeroX);
 fprintf('InputCFDLevel1    : %ld\n',InputCFDLevel);
end;

if (Model == 'TimeHarp 260 N')
 fprintf('SyncTiggerEdge    : %ld\n',SyncTiggerEdge);
 fprintf('SyncTriggerLevel  : %ld\n',SyncTriggerLevel);
 fprintf('InputTriggerEdge  : %ld\n',InputTriggerEdge);
 fprintf('InputTriggerLevel : %ld\n',InputTriggerLevel);
end;

[ret] = calllib('TH260lib', 'TH260_SetSyncDiv', dev(1), SyncDiv);
if (ret<0)
    fprintf('\nTH260_SetSyncDiv error %s. Aborted.\n', geterrorstring(ret));
    closedev;
    return;
end;

[ret] = calllib('TH260lib', 'TH260_SetSyncChannelOffset', dev(1), SyncOffset);
if (ret<0)
   fprintf('\nTH260_SetSyncChannelOffset error %s. Aborted.\n', geterrorstring(ret));
   closedev;
   return;
end; 

if (Model == 'TimeHarp 260 P')
    [ret] = calllib('TH260lib', 'TH260_SetSyncCFD', dev(1), SyncCFDLevel, SyncCFDZeroX);
    if (ret<0)
        fprintf('\nTH260_SetSyncCFD error %s. Aborted.\n', geterrorstring(ret));
        closedev;
        return;
    end;

    for i=0:NumInpChannels-1 % we use the same input settings for all channels

        [ret] = calllib('TH260lib', 'TH260_SetInputCFD', dev(1), i, InputCFDLevel, InputCFDZeroX);
            if (ret<0)
            fprintf('\nTH260_SetInputCFD error %s. Aborted.\n', geterrorstring(ret));
            closedev;
            return;
            end;   
    end
end; 
 
if (Model == 'TimeHarp 260 N')
    [ret] = calllib('TH260lib', 'TH260_SetSyncEdgeTrg', dev(1), SyncTriggerLevel, SyncTiggerEdge);
    if (ret<0)
        fprintf('\nTH260_SetSyncEdgeTrg error %s. Aborted.\n', geterrorstring(ret));
        closedev;
        return;
    end;

    for i=0:NumInpChannels-1 % we use the same input settings for all channels

        [ret] = calllib('TH260lib', 'TH260_SetInputEdgeTrg', dev(1), i, InputTriggerLevel, InputTriggerEdge);
            if (ret<0)
            fprintf('\nTH260_SetInputEdgeTrg error %s. Aborted.\n', geterrorstring(ret));
            closedev;
            return;
            end;   
    end
end; 

for i=0:NumInpChannels-1 % we use the same input offset for all channels        
    [ret] = calllib('TH260lib', 'TH260_SetInputChannelOffset', dev(1), i, InputOffset);
        if (ret<0)
        fprintf('\nTH260_SetInputChannelOffset error %s. Aborted.\n', geterrorstring(ret));
        closedev;
        return;
        end;
end;

if(Mode==MODE_T3) % the following is meaningless in T2 mode
    [ret] = calllib('TH260lib', 'TH260_SetBinning', dev(1), Binning);
    if (ret<0)
        fprintf('\nTH260_SetBinning error %s. Aborted.\n', geterrorstring(ret));
        closedev;
        return;
    end;
    [ret] = calllib('TH260lib', 'TH260_SetOffset', dev(1), 0);
    if (ret<0)
        fprintf('\nTH260_SetOffset error %s. Aborted.\n', geterrorstring(ret));
        closedev;
        return;
    end;
end;

ret = calllib('TH260lib', 'TH260_SetStopOverflow', dev(1), 0, 10000); %for example only 
if (ret<0)
    fprintf('\nTH260_SetStopOverflow error %s. Aborted.\n', geterrorstring(ret));
    closedev;
    return;
 end;
 
Resolution = 0;
ResolutionPtr = libpointer('doublePtr', Resolution);
[ret, Resolution] = calllib('TH260lib', 'TH260_GetResolution', dev(1), ResolutionPtr);
if (ret<0)
    fprintf('\nTH260_GetResolution error %s. Aborted.\n', geterrorstring(ret));
    closedev;
    return;
 end;
 fprintf('\nResolution=%1dps', Resolution);


pause(0.2); % after Init or SetSyncDiv allow 150 ms for valid new count rates
            % you get new values only every 100 ms

% From here you can repeat the measurement (with the same settings)


Syncrate = 0;
SyncratePtr = libpointer('int32Ptr', Syncrate);
[ret, Syncrate] = calllib('TH260lib', 'TH260_GetSyncRate', dev(1), SyncratePtr);
if (ret<0)
    fprintf('\nTH260_GetSyncRate error %s. Aborted.\n', geterrorstring(ret));
    closedev;
    return;
end;
fprintf('\nSyncrate=%1d/s', Syncrate);
 
for i=0:NumInpChannels-1
    
	Countrate = 0;
	CountratePtr = libpointer('int32Ptr', Countrate);
	[ret, Countrate] = calllib('TH260lib', 'TH260_GetCountRate', dev(1), i, CountratePtr);
	if (ret<0)
   	fprintf('\nTH260_GetCountRate error %s. Aborted.\n', geterrorstring(ret));
   	closedev;
   	return;
	end;
	fprintf('\nCountrate%1d=%1d/s ', i, Countrate);
   
end;

%new from v1.2: after getting the count rates you can check for warnings
Warnings = 0;
WarningsPtr = libpointer('int32Ptr', Warnings);
[ret, Warnings] = calllib('TH260lib', 'TH260_GetWarnings', dev(1), WarningsPtr);
if (ret<0)
    fprintf('\nTH260_GetWarnings error %s. Aborted.\n', geterrorstring(ret));
    closedev;
    return;
end;
if (Warnings~=0)
    Warningstext = blanks(16384); %enough length!
    WtextPtr     = libpointer('cstring', Warningstext);
    [ret, Warningstext] = calllib('TH260lib', 'TH260_GetWarningsText', dev(1), WtextPtr, Warnings);
    fprintf('\n\n%s',Warningstext);
end;
        
buffer  = uint32(zeros(1,TTREADMAX));
bufferptr = libpointer('uint32Ptr', buffer);

nactual = int32(0);
nactualptr = libpointer('int32Ptr', nactual);

ctcdone = int32(0);
ctcdonePtr = libpointer('int32Ptr', ctcdone);

Progress = 0;
fprintf('\nProgress:%9d',Progress);
       
ret = calllib('TH260lib', 'TH260_StartMeas', dev(1),Tacq); 
if (ret<0)
    fprintf('\nTH260_StartMeas error %s. Aborted.\n', geterrorstring(ret));
    closedev;
    return;
end;
       
while(1)  
    
    flags = int32(0);
    flagsPtr = libpointer('int32Ptr', flags);
    [ret,flags] = calllib('TH260lib', 'TH260_GetFlags', dev(1), flagsPtr);
    if (ret<0)
    	  fprintf('\nTH260_GetFlags error %s. Aborted.\n', geterrorstring(ret));
    	  break
    end;
   
    if (bitand(uint32(flags),FLAG_FIFOFULL)) 
        fprintf('\nFiFo Overrun!\n'); 
        break;
    end;
		
    [ret, buffer, nactual] = calllib('TH260lib','TH260_ReadFiFo', dev(1), bufferptr, TTREADMAX, nactualptr);
    %Note that HH_ReadFiFo may return less than requested  
    if (ret<0)  
        fprintf('\nTH260_ReadFiFo error %s. Aborted.\n', geterrorstring(ret));
        break;
    end;  

    if(nactual) 
        cnt = fwrite(fid, buffer(1:nactual),'uint32');
        if(cnt ~= nactual)
            fprintf('\nfile write error\n');
            break;
        end;          
		  Progress = Progress + nactual;
		  fprintf('\b\b\b\b\b\b\b\b\b%9d',Progress);
    else
        [ret,ctcdone] = calllib('TH260lib', 'TH260_CTCStatus', dev(1), ctcdonePtr);
        if (ret<0)  
            fprintf('\nTH260_CTCStatus error %s. Aborted.\n', geterrorstring(ret)); 
            break;
        end;       
        if (ctcdone) 
            fprintf('\nDone\n'); 
            break;
        end;
    end;
     
	 %you can read the count rates here if needed

end; %while


ret = calllib('TH260lib', 'TH260_StopMeas', dev(1)); 
if (ret<0)
    fprintf('\nTH260_StopMeas error %s. Aborted.\n', geterrorstring(ret));
    closedev;
    return;
end;
        
closedev;
    
fprintf('\nBinary output data is in tttrmode.out\n');

if(fid>0) 
    fclose(fid);
end;

