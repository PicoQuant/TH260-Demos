{
  TimeHarp 260  TH260LIB v.3.1 - Usage Demo with Delphi or Lazarus.
  Tested with Lazarus 1.0.4 and Delphi 10.1 on Windows 8
  and with Lazarus 1.4.4 on Linux

  Demo access to TimeHarp 260 Hardware via TH260LIB.
  The program performs a histogram measurement based on hardcoded settings.
  The resulting histogram is stored in an ASCII output file.

  Michael Wahl, Andreas Podubrin, PicoQuant GmbH, March 2017

  Note: This is a console application

  Note: At the API level channel numbers are indexed 0..N-1
        where N is the number of channels the device has.
}

program histomode;
{$ifdef MSWINDOWS}
{$APPTYPE CONSOLE}
{$endif}

uses
  {$ifdef fpc}
  SysUtils,
  {$else}
  System.SysUtils,
  System.Ansistrings,
  {$endif}
  th260lib in 'th260lib.pas';


type
  THistogramCounts   = array [0..MAXHISTLEN-1] of longword;


var
  iRetCode           : longint;
  outf               : Text;
  i                  : integer;
  iFound             : integer =   0;

  iMode              : longint =    MODE_HIST ;
  iBinning           : longint =    0; // you can change this (meaningless in T2 mode)
  iOffset            : longint =    0; // normally no need to change this
  iTAcq              : longint = 1000; // you can change this, unit is millisec
  iSyncDivider       : longint =    8; // you can change this

  //These settings will apply for TimeHarp 260 P boards
  iSyncCFDZeroCross  : longint =   -10; // you can change this
  iSyncCFDLevel      : longint =   -50; // you can change this
  iInputCFDZeroCross : longint =   -10; // you can change this
  iInputCFDLevel     : longint =   -50; // you can change this

   //These settings will apply for TimeHarp 260 N boards
  iSyncTriggerEdge   : longint =   0;   // you can change this
  iSyncTriggerLevel  : longint =   -50; // you can change this
  iInputTriggerEdge  : longint =   0;   // you can change this
  iInputTriggerlevel : longint =   -50; // you can change this

  iNumChannels       : longint;
  iHistoBin          : longint;
  iChanIdx           : longint;
  iHistLen           : longint;
  dResolution        : double;
  iSyncRate          : longint;
  iCountRate         : longint;
  iCTCStatus         : longint;
  dIntegralCount     : double;
  iFlags             : longint;
  iWarnings          : longint;
  cCmd               : char    = #0;

  Counts             : array [0..HHMAXINPCHAN-1]  of THistogramCounts;

  procedure ex (iRetCode : integer);
  begin
    if iRetCode <> TH260_ERROR_NONE
    then begin
      TH260_GetErrorString (pcErrText, iRetCode);
      writeln ('Error ', iRetCode:3, ' = "', Trim (strErrText), '"');
    end;
    writeln;
    {$I-}
      closefile (outf);
      IOResult();
    {$I+}
    writeln('press RETURN to exit');
    readln;
    halt (iRetCode);
  end;

begin
  writeln;
  writeln ('TimeHarp 260 TH260Lib        Usage Demo             PicoQuant GmbH, 2017');
  writeln ('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
  iRetCode := TH260_GetLibraryVersion (pcLibVersion);
  if iRetCode <> TH260_ERROR_NONE
  then begin
    writeln ('TH260_GetLibraryVersion error ', iRetCode:3, '. Aborted.');
    ex (iRetCode);
  end;
  writeln ('TH260LIB version is ' + strLibVersion);
  if trim (strLibVersion) <> trim (AnsiString (LIB_VERSION))
  then
    writeln ('Warning: The application was built for version ' + LIB_VERSION);

  assignfile (outf, 'histomode.out');
  {$I-}
    rewrite (outf);
  {$I+}
  if IOResult <> 0 then
  begin
    writeln ('cannot open output file');
    ex (TH260_ERROR_NONE);
  end;

  writeln;
  writeln ('Searching for TimeHarp 260 devices...');
  writeln;
  writeln ('Devidx     Status');

  for i:=0 to MAXDEVNUM-1
  do begin
    iRetCode := TH260_OpenDevice (i, pcHWSerNr);
    //
    if iRetCode = TH260_ERROR_NONE
    then begin
      // Grab any device we can open
      iDevIdx [iFound] := i; // keep index to devices we want to use
      inc (iFound);
      writeln ('   ', i, '      S/N ', strHWSerNr);
    end
    else begin
      if iRetCode = TH260_ERROR_DEVICE_OPEN_FAIL
      then
        writeln ('   ', i, '       no device')
      else begin
        TH260_GetErrorString (pcErrText, iRetCode);
        writeln ('   ', i, '       ', Trim (strErrText));
      end;
    end;
  end;

  // in this demo we will use the first TimeHarp 260 device we found,
  // i.e. iDevIdx[0].  You can also use multiple devices in parallel.
  // you could also check for a specific serial number, so that you
  // always know which physical device you are talking to.

  if iFound < 1 then
  begin
    writeln ('No device available.');
    ex (TH260_ERROR_NONE);
  end;

  writeln;
  writeln ('Using device ', iDevIdx[0]);

  writeln;
  writeln (outf, 'Mode              : ', iMode);
  writeln (outf, 'Binning           : ', iBinning);
  writeln (outf, 'Offset            : ', iOffset);
  writeln (outf, 'AcquisitionTime   : ', iTacq);
  writeln (outf, 'SyncDivider       : ', iSyncDivider);

  writeln ('Initializing the device...');

  iRetCode := TH260_Initialize (iDevIdx[0], iMode);
  if iRetCode <> TH260_ERROR_NONE
  then begin
    writeln ('TH260_Initialize error ', iRetCode:3, '. Aborted.');
    ex (iRetCode);
  end;

  iRetCode := TH260_GetHardwareInfo (iDevIdx[0], pcHWModel, pcHWPartNo, pcHWVersion);
  if iRetCode <> TH260_ERROR_NONE
  then begin
    writeln ('TH260_GetHardwareInfo error ', iRetCode:3, '. Aborted.');
    ex (iRetCode);
  end
  else
    writeln ('Found Model ', strHWModel,'  Part no ', strHWPartNo,'  Version ', strHWVersion);

  if strHWModel = 'TimeHarp 260 P'  //Picosecond resolving board
  then begin
    writeln (outf, 'SyncCFDZeroCross  : ', iSyncCFDZeroCross);
    writeln (outf, 'SyncCFDLevel      : ', iSyncCFDLevel);
    writeln (outf, 'InputCFDZeroCross : ', iInputCFDZeroCross);
    writeln (outf, 'InputCFDLevel     : ', iInputCFDLevel);
  end
  else
    if strHWModel = 'TimeHarp 260 N'  //Nanosecond resolving board
    then begin
      writeln (outf, 'SyncTriggerEdge  : ', iSyncTriggerEdge);
      writeln (outf, 'SyncTriggerLevel : ', iSyncTriggerLevel);
      writeln (outf, 'InputTriggerEdge : ', iInputTriggerEdge);
      writeln (outf, 'InputTriggerlevel: ', iInputTriggerlevel);
    end
    else
    begin
      writeln ('Unknown hardware model. Aborted.');
      ex (0);
    end;

  iRetCode := TH260_GetNumOfInputChannels (iDevIdx[0], iNumChannels);
  if iRetCode <> TH260_ERROR_NONE
  then begin
    writeln ('TH260_GetNumOfInputChannels error ', iRetCode:3, '. Aborted.');
    ex (iRetCode);
  end
  else
    writeln ('Device has ', iNumChannels, ' input channels.');

  iRetCode := TH260_SetSyncDiv (iDevIdx[0], iSyncDivider);
  if iRetCode <> TH260_ERROR_NONE
  then begin
    writeln ('TH260_SetSyncDiv error ', iRetCode:3, '. Aborted.');
    ex (iRetCode);
  end;

  if strHWModel = 'TimeHarp 260 P'  //Picosecond resolving board
  then begin
    iRetCode := TH260_SetSyncCFD (iDevIdx[0], iSyncCFDLevel, iSyncCFDZeroCross);
    if iRetCode <> TH260_ERROR_NONE
    then begin
      writeln ('TH260_SetSyncCFD error ', iRetCode:3, '. Aborted.');
      ex (iRetCode);
    end;

    for iChanIdx:=0 to iNumChannels-1 // we use the same input settings for all channels
    do begin
      iRetCode := TH260_SetInputCFD (iDevIdx[0], iChanIdx, iInputCFDLevel, iInputCFDZeroCross);
      if iRetCode <> TH260_ERROR_NONE
      then begin
        writeln ('TH260_SetInputCFD channel ', iChanIdx:2, ' error ', iRetCode:3, '. Aborted.');
        ex (iRetCode);
      end;
    end;
  end;

   if strHWModel = 'TimeHarp 260 N'  //Nanosecond resolving board
  then begin
    iRetCode := TH260_SetSyncEdgeTrg (iDevIdx[0], iSyncTriggerLevel, iSyncTriggerEdge);
    if iRetCode <> TH260_ERROR_NONE
    then begin
      writeln ('TH260_SetSyncEdgeTrg error ', iRetCode:3, '. Aborted.');
      ex (iRetCode);
    end;

    for iChanIdx:=0 to iNumChannels-1 // we use the same input settings for all channels
    do begin
      iRetCode := TH260_SetInputEdgeTrg (iDevIdx[0], iChanIdx, iInputTriggerLevel, iInputTriggerEdge);
      if iRetCode <> TH260_ERROR_NONE
      then begin
        writeln ('TH260_SetInputEdgeTrg channel ', iChanIdx:2, ' error ', iRetCode:3, '. Aborted.');
        ex (iRetCode);
      end;
    end;
  end;

  iRetCode := TH260_SetSyncChannelOffset (iDevIdx[0], 0);
  if iRetCode <> TH260_ERROR_NONE
  then begin
    writeln ('TH260_SetSyncChannelOffset error ', iRetCode:3, '. Aborted.');
    ex (iRetCode);
  end;

  for iChanIdx:=0 to iNumChannels-1 // we use the same input settings for all channels
  do begin
    iRetCode := TH260_SetInputChannelOffset (iDevIdx[0], iChanIdx, 0);
    if iRetCode <> TH260_ERROR_NONE
    then begin
      writeln ('TH260_SetInputChannelOffset channel ', iChanIdx:2, ' error ', iRetCode:3, '. Aborted.');
      ex (iRetCode);
    end;

    iRetCode := TH260_SetInputChannelEnable (iDevIdx[0], iChanIdx, 1);
    if iRetCode <> TH260_ERROR_NONE
    then begin
      writeln ('TH260_SetInputChannelEnable channel ', iChanIdx:2, ' error ', iRetCode:3, '. Aborted.');
      ex (iRetCode);
    end;
  end;

  iRetCode := TH260_SetHistoLen (iDevIdx[0], MAXLENCODE, iHistLen);
  if iRetCode <> TH260_ERROR_NONE
  then begin
    writeln ('TH260_SetHistoLen error ', iRetCode:3, '. Aborted.');
    ex (iRetCode);
  end;
  writeln ('Histogram length is ', iHistLen);

  iRetCode := TH260_SetBinning (iDevIdx[0], iBinning);
  if iRetCode <> TH260_ERROR_NONE
  then begin
    writeln ('TH260_SetBinning error ', iRetCode:3, '. Aborted.');
    ex (iRetCode);
  end;

  iRetCode := TH260_SetOffset(iDevIdx[0], iOffset);
  if iRetCode <> TH260_ERROR_NONE
  then begin
    writeln ('TH260_SetOffset error ', iRetCode:3, '. Aborted.');
    ex (iRetCode);
  end;

  iRetCode := TH260_GetResolution (iDevIdx[0], dResolution);
  if iRetCode <> TH260_ERROR_NONE
  then begin
    writeln ('TH260_GetResolution error ', iRetCode:3, '. Aborted.');
    ex (iRetCode);
  end;
  writeln ('Resolution is ', dResolution:7:3, 'ps');

  // After Init allow 150 ms for valid new count rate readings
  // Subsequently you get new values every 100 ms
  Sleep (150);

  writeln;

  iRetCode := TH260_GetSyncRate (iDevIdx[0], iSyncRate);
  if iRetCode <> TH260_ERROR_NONE
  then begin
    writeln ('TH260_GetSyncRate error ', iRetCode:3, '. Aborted.');
    ex (iRetCode);
  end;
  writeln ('SyncRate = ', iSyncRate, '/s');

  writeln;

  for iChanIdx := 0 to iNumChannels-1 // for all channels
  do begin
    iRetCode := TH260_GetCountRate (iDevIdx[0], iChanIdx, iCountRate);
    if iRetCode <> TH260_ERROR_NONE
    then begin
      writeln ('TH260_GetCountRate error ', iRetCode:3, '. Aborted.');
      ex (iRetCode);
    end;
    writeln ('Countrate [', iChanIdx:2, '] = ', iCountRate:8, '/s');
  end;

  writeln;

  //after getting the count rates you can check for warnings
  iRetCode := TH260_GetWarnings(iDevIdx[0], iWarnings);
  if iRetCode <> TH260_ERROR_NONE
  then begin
    writeln ('TH260_GetWarnings error ', iRetCode:3, '. Aborted.');
    ex (iRetCode);
  end;
  if iWarnings <> 0
  then begin
    TH260_GetWarningsText(iDevIdx[0], pcWtext, iWarnings);
    writeln (strWtext);
  end;

  iRetCode := TH260_SetStopOverflow (iDevIdx[0], 0, 10000); // for example only
  if iRetCode <> TH260_ERROR_NONE
  then begin
    writeln ('TH260_SetStopOverflow error ', iRetCode:3, '. Aborted.');
    ex (iRetCode);
  end;

  repeat

    TH260_ClearHistMem (iDevIdx[0]);
    if iRetCode <> TH260_ERROR_NONE
    then begin
      writeln ('TH260_ClearHistMem error ', iRetCode:3, '. Aborted.');
      ex (iRetCode);
    end;

    writeln('press RETURN to start measurement');
    readln (cCmd);

    writeln;

    iRetCode := TH260_GetSyncRate (iDevIdx[0], iSyncRate);
    if iRetCode <> TH260_ERROR_NONE
    then begin
      writeln ('TH260_GetSyncRate error ', iRetCode:3, '. Aborted.');
      ex (iRetCode);
    end;
    writeln ('SyncRate = ', iSyncRate, '/s');

    writeln;

    for iChanIdx := 0 to iNumChannels-1 // for all channels
    do begin
      iRetCode := TH260_GetCountRate (iDevIdx[0], iChanIdx, iCountRate);
      if iRetCode <> TH260_ERROR_NONE
      then begin
        writeln ('TH260_GetCountRate error ', iRetCode:3, '. Aborted.');
        ex (iRetCode);
      end;
      writeln ('Countrate [', iChanIdx:2, '] = ', iCountRate:8, '/s');
    end;

    writeln;
    iRetCode := TH260_StartMeas (iDevIdx[0], iTacq);
    if iRetCode <> TH260_ERROR_NONE
    then begin
      writeln ('TH260_StartMeas error ', iRetCode:3, '. Aborted.');
      ex (iRetCode);
    end;
    writeln ('Measuring for ', iTacq, ' milliseconds...');

    repeat

      iRetCode := TH260_CTCStatus (iDevIdx[0], iCTCStatus);
      if iRetCode <> TH260_ERROR_NONE
      then begin
        writeln ('TH260_CTCStatus error ', iRetCode:3, '. Aborted.');
        ex (iRetCode);
      end;

    until (iCTCStatus <> 0);

    iRetCode := TH260_StopMeas (iDevIdx[0]);
    if iRetCode <> TH260_ERROR_NONE
    then begin
      writeln ('TH260_StopMeas error ', iRetCode:3, '. Aborted.');
      ex (iRetCode);
    end;

    writeln;

    for iChanIdx := 0 to iNumChannels-1 // for all channels
    do begin
      iRetCode := TH260_GetHistogram (iDevIdx[0], counts[iChanIdx][0], iChanIdx, 0);
      if iRetCode <> TH260_ERROR_NONE
      then begin
        writeln ('TH260_GetHistogram error ', iRetCode:3, '. Aborted.');
        ex (iRetCode);
      end;

      dIntegralCount := 0;

      for iHistoBin := 0 to iHistLen-1
      do dIntegralCount := dIntegralCount + counts [iChanIdx][iHistoBin];

      writeln ('  Integralcount [', iChanIdx:2, '] = ', dIntegralCount:9:0);

    end;

    writeln;

    iRetCode := TH260_GetFlags (iDevIdx[0], iFlags);
    if iRetCode <> TH260_ERROR_NONE
    then begin
      writeln ('TH260_GetFlags error ', iRetCode:3, '. Aborted.');
      ex (iRetCode);
    end;

    if (iFlags and FLAG_OVERFLOW) > 0 then writeln ('  Overflow.');

    writeln('Enter c to continue or q to quit and save the count data.');
    readln(cCmd);

  until (cCmd = 'q');


  for iHistoBin := 0 to iHistLen-1
  do begin
    for iChanIdx := 0 to iNumChannels-1
    do write (outf, Counts [iChanIdx][iHistoBin]:5, ' ');
    writeln (outf);
  end;

  TH260_CloseAllDevices;

  ex (TH260_ERROR_NONE);
end.
