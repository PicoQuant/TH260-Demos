{
TimeHarp 260  TH260LIB v.3.1 - Usage Demo with Delphi or Lazarus.
Tested with Lazarus 1.2.4 and Delphi 10.1 on Windows 8.

  The program performs a TTTR measurement based on hardcoded settings.
  The resulting event data is stored in a binary output file.

  Michael Wahl, Andreas Podubrin, PicoQuant GmbH, March 2017

  Note: This is a console application (i.e. run in Windows cmd box)

  Note: At the API level channel numbers are indexed 0..N-1
        where N is the number of channels the device has.

  Note: This demo writes only raw event data to the output file.
        It does not write a file header as regular .ht* files have it.
}

program tttrmode;

{$APPTYPE CONSOLE}

uses
  {$ifdef fpc}
  SysUtils,
  {$else}
  System.SysUtils,
  System.Ansistrings,
  {$endif}
  th260lib in 'th260lib.pas';

var
  iRetCode           : longint;
  outf               : File;
  i                  : integer;
  iWritten           : longint;
  iFound             : integer =       0;
  iProgress          : longint =       0;
  bFiFoFull          : boolean =   false;
  bTimeOut           : boolean =   false;
  bFileError         : boolean =   false;


  iMode              : longint = MODE_T2; // set T2 or T3 here, observe suitable Syncdivider and Range!
  iBinning           : longint =       0; // you can change this (meaningless in T2 mode)
  iOffset            : longint =       0; // normally no need to change this
  iTAcq              : longint =   10000; // you can change this, unit is millisec
  iSyncDivider       : longint =       1; // you can change this

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
  iChanIdx           : longint;
  dResolution        : double;
  iSyncRate          : longint;
  iCountRate         : longint;
  iCTCStatus         : longint;
  iFlags             : longint;
  iRecords           : longint;
  iWarnings          : longint;

  lwBuffer           : array [0..TTREADMAX-1] of longword;

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
  writeln ('TimeHarp 260 TH260Lib     Usage Demo                PicoQuant GmbH, 2017');
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

  assignfile (outf, 'tttrmode.out');
  {$I-}
    rewrite (outf, 4);
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
  writeln ('Mode              : ', iMode);
  writeln ('Binning           : ', iBinning);
  writeln ('Offset            : ', iOffset);
  writeln ('AcquisitionTime   : ', iTacq);
  writeln ('SyncDivider       : ', iSyncDivider);
  writeln;

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

  writeln;
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

  writeln;
  if strHWModel = 'TimeHarp 260 P'  //Picosecond resolving board
  then begin
    writeln ('SyncCFDZeroCross  : ', iSyncCFDZeroCross);
    writeln ('SyncCFDLevel      : ', iSyncCFDLevel);
    writeln ('InputCFDZeroCross : ', iInputCFDZeroCross);
    writeln ('InputCFDLevel     : ', iInputCFDLevel);
  end
  else
    if strHWModel = 'TimeHarp 260 N'  //Nanosecond resolving board
    then begin
      writeln ('SyncTriggerEdge  : ', iSyncTriggerEdge);
      writeln ('SyncTriggerLevel : ', iSyncTriggerLevel);
      writeln ('InputTriggerEdge : ', iInputTriggerEdge);
      writeln ('InputTriggerlevel: ', iInputTriggerlevel);
    end
    else
    begin
      writeln ('Unknown hardware model. Aborted.');
      ex (0);
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

  if (iMode <> MODE_T2)                      // These are meaningless in T2 mode
  then begin
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
  end;

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

  iRetCode := TH260_StartMeas (iDevIdx[0], iTacq);
  if iRetCode <> TH260_ERROR_NONE
  then begin
    writeln ('TH260_StartMeas error ', iRetCode:3, '. Aborted.');
    ex (iRetCode);
  end;
  writeln ('Measuring for ', iTacq, ' milliseconds...');

  iProgress := 0;
  write (#8#8#8#8#8#8#8#8#8#8#8#8, iProgress:12);

  repeat

    iRetCode := TH260_GetFlags (iDevIdx[0], iFlags);
    if iRetCode <> TH260_ERROR_NONE
    then begin
      writeln ('TH260_GetFlags error ', iRetCode:3, '. Aborted.');
      ex (iRetCode);
    end;
    bFiFoFull := (iFlags and FLAG_FIFOFULL) > 0;

    if bFiFoFull
    then
      writeln ('  FiFo Overrun!')
    else begin

      iRetCode := TH260_ReadfiFo (iDevIdx[0], lwBuffer[0], TTREADMAX, iRecords); // may return less!
      if iRetCode <> TH260_ERROR_NONE
      then begin
        writeln ('TH260_ReadfiFo error ', iRetCode:3, '. Aborted.');
        ex (iRetCode);
      end;

      if (iRecords > 0)
      then begin
        blockwrite (outf, lwBuffer[0], iRecords, iWritten);
        if iRecords <> iWritten
        then begin
          writeln;
          writeln ('file write error');
          bFileError := true;
        end;

        iProgress := iProgress + iWritten;
        write (#8#8#8#8#8#8#8#8#8#8#8#8, iProgress:12);
      end
      else begin
        iRetCode := TH260_CTCStatus (iDevIdx[0], iCTCStatus);
        if iRetCode <> TH260_ERROR_NONE
        then begin
          writeln;
          writeln ('TH260_CTCStatus error ', iRetCode:3, '. Aborted.');
          ex (iRetCode);
        end;
        bTimeOut := (iCTCStatus <> 0);
        if bTimeOut
        then begin
          writeln;
          writeln('Done');
        end;
      end;
    end;

  until  bFiFoFull or bTimeOut or bFileError;

  writeln;

  iRetCode := TH260_StopMeas (iDevIdx[0]);
  if iRetCode <> TH260_ERROR_NONE
  then begin
    writeln ('TH260_StopMeas error ', iRetCode:3, '. Aborted.');
    ex (iRetCode);
  end;

  TH260_CloseAllDevices;

  ex (TH260_ERROR_NONE);
end.

