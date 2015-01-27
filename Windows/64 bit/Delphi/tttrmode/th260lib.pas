Unit TH260Lib;
{                                                                     }
{ Functions exported by the TimeHarp 260 programming library TH260Lib }
{                                                                     }
{ Ver. 1.1      September 2013                                        }
{                                                                     }

interface

const
  {$IFDEF WIN64}
    TH260_LIB_NAME = 'TH260Lib64.DLL';
  {$ELSE}
    TH260_LIB_NAME = 'TH260Lib.DLL';
  {$ENDIF}

  LIB_VERSION    =      '1.1';

  MAXDEVNUM      =          4;   // max num of devices
  HHMAXINPCHAN   =          2;   // max num of input channels

  MAXBINSTEPS    =         22;
  MAXHISTLEN     =      32768;   // max number of histogram bins
  MAXLENCODE     =          5;   // max length code

  TIMINGMODE_HIRES   =      0;   // used by TH260_SetTimingMode
  TIMINGMODE_LORES   =      1;   // used by TH260_SetTimingMode

  TTREADMAX      =     131072;   // 128K event records can be read in one chunk
  TTREADMIN      =        128;   // 128  event records = minimum buffer size that must be provided

  MODE_HIST      =          0;
  MODE_T2        =          2;
  MODE_T3        =          3;

  FLAG_OVERFLOW  =      $0001;   // histo mode only
  FLAG_FIFOFULL  =      $0002;
  FLAG_SYNC_LOST =      $0004;
  FLAG_SYSERROR  =      $0010;   // hardware error, must contact support
  FLAG_SOFTERROR =      $0020;   // software error, must contact support


  SYNCDIVMIN     =          1;
  SYNCDIVMAX     =          8;

  EDGE_RISING    =          1;   // marker edges and TH260 Nano trigger edges
  EDGE_FALLING   =          0;   // marker edges and TH260 Nano trigger edges

  TRGLVLMIN	 =      -1200;   // mV  TH260 Nano only
  TRGLVLMAX	 =       1200;   // mV  TH260 Nano only

  CFDZCMIN       =        -40;   // mV  TH260 Pico only
  CFDZCMAX       =          0;   // mV  TH260 Pico only
  DISCRMIN       =      -1200;   // mV  TH260 Pico only
  DISCRMAX       =          0;   // mV  TH260 Pico only

  CHANOFFSMIN    =     -99999;   // ps
  CHANOFFSMAX    =      99999;   // ps

  OFFSETMIN      =          0;   // ns
  OFFSETMAX      =  100000000;   // ns
  ACQTMIN        =          1;   // ms
  ACQTMAX        =  360000000;   // ms  (100*60*60*1000ms = 100h)

  STOPCNTMIN     =          1;
  STOPCNTMAX     = 4294967295;   // 32 bit is mem max

  MEASCTRL_SINGLESHOT_CTC        = 0;  //default
  MEASCTRL_C1_GATE               = 1;
  MEASCTRL_C1_START_CTC_STOP     = 2;
  MEASCTRL_C1_START_C2_STOP      = 3;



var
  pcLibVersion   : pAnsiChar;
  strLibVersion  : array [0.. 7] of AnsiChar;
  pcErrText      : pAnsiChar;
  strErrText     : array [0..40] of AnsiChar;
  pcHWSerNr      : pAnsiChar;
  strHWSerNr     : array [0.. 7] of AnsiChar;
  pcHWModel      : pAnsiChar;
  strHWModel     : array [0..15] of AnsiChar;
  pcHWPartNo     : pAnsiChar;
  strHWPartNo    : array [0.. 8] of AnsiChar;
  pcHWVersion    : pAnsiChar;
  strHWVersion   : array [0..15] of AnsiChar;
  pcWtext        : pAnsiChar;
  strWtext       : array [0.. 16384] of AnsiChar;

  iDevIdx        : array [0..MAXDEVNUM-1] of LongInt;


function  TH260_GetLibraryVersion     (vers : pAnsiChar) : LongInt;
  stdcall; external TH260_LIB_NAME;
function  TH260_GetErrorString        (errstring : pAnsiChar; errcode : LongInt) : LongInt;
  stdcall; external TH260_LIB_NAME;

function  TH260_OpenDevice            (devidx : LongInt; serial : pAnsiChar) : LongInt;
  stdcall; external TH260_LIB_NAME;
function  TH260_CloseDevice           (devidx : LongInt) : LongInt;
  stdcall; external TH260_LIB_NAME;
function  TH260_Initialize            (devidx : LongInt; mode : LongInt) : LongInt;
  stdcall; external TH260_LIB_NAME;

// all functions below can only be used after HH_Initialize

function  TH260_GetHardwareInfo       (devidx : LongInt; model : pAnsiChar; partno : pAnsiChar; version : pAnsiChar) : LongInt;
  stdcall; external TH260_LIB_NAME;
function  TH260_GetSerialNumber       (devidx : LongInt; serial : pAnsiChar) : LongInt;
  stdcall; external TH260_LIB_NAME;
function  TH260_GetBaseResolution     (devidx : LongInt; var resolution : Double; var binsteps : LongInt) : LongInt;
  stdcall; external TH260_LIB_NAME;

function  TH260_GetNumOfInputChannels (devidx : LongInt; var nchannels : LongInt) : LongInt;
  stdcall; external TH260_LIB_NAME;

function  TH260_SetTimingMode         (devidx : LongInt; mode : LongInt) : LongInt; // TH 260 Pico only
   stdcall; external TH260_LIB_NAME;

function  TH260_SetSyncDiv            (devidx : LongInt; syncdiv : LongInt) : LongInt;
  stdcall; external TH260_LIB_NAME;
function  TH260_SetSyncCFD            (devidx : LongInt; level : LongInt; zerocross : LongInt) : LongInt; // TH 260 Pico only
  stdcall; external TH260_LIB_NAME;
function  TH260_SetSyncEdgeTrg        (devidx : LongInt; level : LongInt; edge : LongInt) : LongInt; // TH 260 Nano only
  stdcall; external TH260_LIB_NAME;
function  TH260_SetSyncChannelOffset  (devidx : LongInt; value : LongInt) : LongInt;
  stdcall; external TH260_LIB_NAME;

function  TH260_SetInputCFD           (devidx : LongInt; channel : LongInt; level : LongInt; zerocross : LongInt) : LongInt; // TH 260 Pico only
  stdcall; external TH260_LIB_NAME;
function  TH260_SetInputEdgeTrg       (devidx : LongInt; channel : LongInt; level : LongInt; edge : LongInt) : LongInt; // TH 260 Nano only
  stdcall; external TH260_LIB_NAME;
function  TH260_SetInputChannelOffset (devidx : LongInt; channel : LongInt; value : LongInt) : LongInt;
  stdcall; external TH260_LIB_NAME;
function  TH260_SetInputChannelEnable (devidx : LongInt; channel : LongInt; enable : LongInt) : LongInt;
  stdcall; external TH260_LIB_NAME;

function  TH260_SetStopOverflow       (devidx : LongInt; stop_ovfl : LongInt; stopcount : LongWord) : LongInt;
  stdcall; external TH260_LIB_NAME;
function  TH260_SetBinning            (devidx : LongInt; binning : LongInt) : LongInt;
  stdcall; external TH260_LIB_NAME;
function  TH260_SetOffset             (devidx : LongInt; offset : LongInt) : LongInt;
  stdcall; external TH260_LIB_NAME;
function  TH260_SetHistoLen           (devidx : LongInt; lencode : LongInt; var actuallen : LongInt) : LongInt;
  stdcall; external TH260_LIB_NAME;
function  TH260_SetTriggerOutput      (devidx : LongInt; period : LongInt) : LongInt;
  stdcall; external TH260_LIB_NAME;
function  TH260_SetMeasControl        (devidx: LongInt; control: LongInt; startedge: LongInt; stopedge: Longint) : LongInt;
  stdcall; external TH260_LIB_NAME;


function  TH260_ClearHistMem          (devidx : LongInt) : LongInt;
  stdcall; external TH260_LIB_NAME;
function  TH260_StartMeas             (devidx : LongInt; tacq : LongInt) : LongInt;
  stdcall; external TH260_LIB_NAME;
function  TH260_StopMeas              (devidx : LongInt) : LongInt;
  stdcall; external TH260_LIB_NAME;
function  TH260_CTCStatus             (devidx : LongInt; var ctcstatus : LongInt) : LongInt;
  stdcall; external TH260_LIB_NAME;

function  TH260_GetFeatures           (devidx : LongInt; var features : LongWord) : LongInt;
  stdcall; external TH260_LIB_NAME;
function  TH260_GetHistogram          (devidx : LongInt; var chcount : LongWord; channel : LongInt; clear : LongInt) : LongInt;
  stdcall; external TH260_LIB_NAME;
function  TH260_GetResolution         (devidx : LongInt; var resolution : Double) : LongInt;
  stdcall; external TH260_LIB_NAME;
function  TH260_GetSyncRate           (devidx : LongInt; var syncrate : LongInt) : LongInt;
  stdcall; external TH260_LIB_NAME;
function  TH260_GetCountRate          (devidx : LongInt; channel : LongInt; var cntrate : LongInt) : LongInt;
  stdcall; external TH260_LIB_NAME;
function  TH260_GetFlags              (devidx : LongInt; var flags : LongInt) : LongInt;
  stdcall; external TH260_LIB_NAME;
function  TH260_GetElapsedMeasTime    (devidx : LongInt; var elapsed : Double) : LongInt;
  stdcall; external TH260_LIB_NAME;
function  TH260_GetWarnings           (devidx : LongInt; var warnings : LongInt) : LongInt;
  stdcall; external TH260_LIB_NAME;
function  TH260_GetWarningsText       (devidx : LongInt; model : pAnsiChar; warnings : LongInt) : LongInt;
  stdcall; external TH260_LIB_NAME;

// for time tagging modes

function  TH260_SetMarkerEdges        (devidx : LongInt; me1 : LongInt; me2 : LongInt; me3 : LongInt; me4 : LongInt) : LongInt;
  stdcall; external TH260_LIB_NAME;
function  TH260_SetMarkerEnable       (devidx : LongInt; en1 : LongInt; en2 : LongInt; en3 : LongInt; en4 : LongInt) : LongInt;
  stdcall; external TH260_LIB_NAME;
 function  TH260_SetMarkerHoldoff     (devidx : LongInt; holdoff : LongInt) : LongInt;
  stdcall; external TH260_LIB_NAME;
function  TH260_ReadFiFo              (devidx : LongInt; var buffer : LongWord; count : LongInt; var nactual : LongInt) : LongInt;
  stdcall; external TH260_LIB_NAME;

procedure TH260_CloseAllDevices;

const

  TH260_ERROR_NONE                      =           0;

  TH260_ERROR_DEVICE_OPEN_FAIL          =          -1;
  TH260_ERROR_DEVICE_BUSY               =          -2;
  TH260_ERROR_DEVICE_HEVENT_FAIL        =          -3;
  TH260_ERROR_DEVICE_CALLBSET_FAIL      =          -4;
  TH260_ERROR_DEVICE_BARMAP_FAIL        =          -5;
  TH260_ERROR_DEVICE_CLOSE_FAIL         =          -6;
  TH260_ERROR_DEVICE_RESET_FAIL         =          -7;
  TH260_ERROR_DEVICE_GETVERSION_FAIL    =          -8;
  TH260_ERROR_DEVICE_VERSION_MISMATCH   =          -9;
  TH260_ERROR_DEVICE_NOT_OPEN           =         -10;
  TH260_ERROR_DEVICE_LOCKED             =         -11;
  TH260_ERROR_DEVICE_DRIVERVER_MISMATCH	=	 -12;

  TH260_ERROR_INSTANCE_RUNNING          =         -16;
  TH260_ERROR_INVALID_ARGUMENT          =         -17;
  TH260_ERROR_INVALID_MODE              =         -18;
  TH260_ERROR_INVALID_OPTION            =         -19;
  TH260_ERROR_INVALID_MEMORY            =         -20;
  TH260_ERROR_INVALID_RDATA             =         -21;

  TH260_ERROR_NOT_INITIALIZED           =         -22;
  TH260_ERROR_NOT_CALIBRATED            =         -23;
  TH260_ERROR_DMA_FAIL                  =         -24;
  TH260_ERROR_XTDEVICE_FAIL             =         -25;
  TH260_ERROR_FPGACONF_FAIL             =         -26;
  TH260_ERROR_IFCONF_FAIL               =         -27;
  TH260_ERROR_FIFORESET_FAIL            =         -28;
  TH260_ERROR_THREADSTATE_FAIL          =         -29;
  TH260_ERROR_THREADLOCK_FAIL           =         -30;

  TH260_ERROR_USB_GETDRIVERVER_FAIL     =         -32;
  TH260_ERROR_USB_DRIVERVER_MISMATCH    =         -33;
  TH260_ERROR_USB_GETIFINFO_FAIL        =         -34;
  TH260_ERROR_USB_HISPEED_FAIL          =         -35;
  TH260_ERROR_USB_VCMD_FAIL             =         -36;
  TH260_ERROR_USB_BULKRD_FAIL           =         -37;

  TH260_ERROR_LANEUP_TIMEOUT            =         -40;
  TH260_ERROR_DONEALL_TIMEOUT           =         -41;
  TH260_ERROR_MB_ACK_TIMEOUT            =         -42;
  TH260_ERROR_MACTIVE_TIMEOUT           =         -43;
  TH260_ERROR_MEMCLEAR_FAIL             =         -44;
  TH260_ERROR_MEMTEST_FAIL              =         -45;
  TH260_ERROR_CALIB_FAIL                =         -46;
  TH260_ERROR_REFSEL_FAIL               =         -47;
  TH260_ERROR_STATUS_FAIL               =         -48;
  TH260_ERROR_MODNUM_FAIL               =         -49;
  TH260_ERROR_DIGMUX_FAIL               =         -50;
  TH260_ERROR_MODMUX_FAIL               =         -51;
  TH260_ERROR_MODFWPCB_MISMATCH         =         -52;
  TH260_ERROR_MODFWVER_MISMATCH         =         -53;
  TH260_ERROR_MODPROPERTY_MISMATCH      =         -54;
  TH260_ERROR_INVALID_MAGIC             =         -55;
  TH260_ERROR_INVALID_LENGTH            =         -56;

  TH260_ERROR_EEPROM_F01                =         -64;
  TH260_ERROR_EEPROM_F02                =         -65;
  TH260_ERROR_EEPROM_F03                =         -66;
  TH260_ERROR_EEPROM_F04                =         -67;
  TH260_ERROR_EEPROM_F05                =         -68;
  TH260_ERROR_EEPROM_F06                =         -69;
  TH260_ERROR_EEPROM_F07                =         -70;
  TH260_ERROR_EEPROM_F08                =         -71;
  TH260_ERROR_EEPROM_F09                =         -72;
  TH260_ERROR_EEPROM_F10                =         -73;
  TH260_ERROR_EEPROM_F11                =         -74;

  TH260_ERROR_UNSUPPORTED_FUNCTION	=	  -80;

  TH260_ERROR_UKNOWN                    =         -99;


//The following are bitmasks for return values from HH_GetWarnings

  WARNING_SYNC_RATE_ZERO            = $0001;
  WARNING_SYNC_RATE_TOO_LOW         = $0002;
  WARNING_SYNC_RATE_TOO_HIGH        = $0004;

  WARNING_INPT_RATE_ZERO            = $0010;
  WARNING_INPT_RATE_TOO_HIGH        = $0040;

  WARNING_INPT_RATE_RATIO           = $0100;
  WARNING_DIVIDER_GREATER_ONE       = $0200;
  WARNING_TIME_SPAN_TOO_SMALL       = $0400;
  WARNING_OFFSET_UNNECESSARY        = $0800;
  WARNING_DIVIDER_TOO_SMALL	    = $1000;
  WARNING_COUNTS_DROPPED	    = $2000;


implementation

  procedure TH260_CloseAllDevices;
  var
    iDev : integer;
  begin
    for iDev := 0 to MAXDEVNUM-1 // no harm closing all
    do TH260_CloseDevice (iDev);
  end;

initialization
  pcLibVersion := pAnsiChar(@strLibVersion[0]);
  pcErrText    := pAnsiChar(@strErrText[0]);
  pcHWSerNr    := pAnsiChar(@strHWSerNr[0]);
  pcHWModel    := pAnsiChar(@strHWModel[0]);
  pcHWPartNo   := pAnsiChar(@strHWPartNo[0]);
  pcHWVersion  := pAnsiChar(@strHWVersion[0]);
  pcWtext      := pAnsiChar(@strWtext[0]);
finalization
  TH260_CloseAllDevices;
end.
