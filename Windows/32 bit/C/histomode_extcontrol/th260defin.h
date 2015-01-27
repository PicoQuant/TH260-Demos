
/* 
	TH260Lib programming library for TimeHarp 260
	
	Ver. 1.1      PicoQuant GmbH, September 2013
*/


#define LIB_VERSION "1.1"	

#define MAXSTRLEN_LIBVER       8 // max string length of *version in TH260_GetLibraryVersion
#define MAXSTRLEN_ERRSTR      40 // max string length of *errstring in TH260_GetErrorString
#define MAXSTRLEN_SERIAL       8 // max string length of *serial in TH260_OpenDevice and TH260_GetSerialNumber
#define MAXSTRLEN_MODEL       16 // max string length of *model in TH260_GetHardwareInfo
#define MAXSTRLEN_PART         8 // max string length of *partno in TH260_GetHardwareInfo
#define MAXSTRLEN_VERSION     16 // max string length of *version in TH260_GetHardwareInfo
#define MAXSTRLEN_WRNTXT   16384 // max string length of *text in TH260_GetWarningsText

#define HWIDENT_PICO    "TimeHarp 260 P" //as returned by TH260_GetHardwareInfo
#define HWIDENT_NANO    "TimeHarp 260 N" //as returned by TH260_GetHardwareInfo

#define MAXDEVNUM	 4	    // max number of devices
 
#define MAXINPCHAN   2	    // max number of detector input channels

#define MAXBINSTEPS	22	    // get actual number via TH260_GetBaseResolution() !

#define MAXHISTLEN  32768	// max number of histogram bins
#define MAXLENCODE  5		// max length code histo mode

#define TTREADMAX   131072  // 128K event records can be read in one chunk
#define TTREADMIN   128     // 128 records = minimum buffer size that must be provided

#define MODE_HIST	0
#define MODE_T2		2
#define MODE_T3		3

#define MEASCTRL_SINGLESHOT_CTC 0 //default
#define MEASCTRL_C1_GATE		1
#define MEASCTRL_C1_START_CTC_STOP	2
#define MEASCTRL_C1_START_C2_STOP	3

#define EDGE_RISING   1
#define EDGE_FALLING  0

#define TIMINGMODE_HIRES  0		//used by TH260_SetTimingMode
#define TIMINGMODE_LORES  1		//used by TH260_SetTimingMode

#define FEATURE_DLL       0x0001
#define FEATURE_TTTR      0x0002
#define FEATURE_MARKERS   0x0004 
#define FEATURE_LOWRES    0x0008 
#define FEATURE_TRIGOUT   0x0010

#define FLAG_OVERFLOW     0x0001  //histo mode only
#define FLAG_FIFOFULL     0x0002  
#define FLAG_SYNC_LOST    0x0004  
#define FLAG_SYSERROR     0x0010  //hardware error, must contact support
#define FLAG_SOFTERROR    0x0020  //software error, must contact support

#define SYNCDIVMIN		1
#define SYNCDIVMAX		8

#define TRGLVLMIN	-1200		//mV  TH260 Nano only
#define TRGLVLMAX	 1200		//mV  TH260 Nano only 

#define CFDLVLMIN	-1200		//mV  TH260 Pico only
#define CFDLVLMAX		0		//mV  TH260 Pico only
#define CFDZCMIN	  -40		//mV  TH260 Pico only
#define CFDZCMAX		0		//mV  TH260 Pico only 

#define CHANOFFSMIN -99999		//ps
#define CHANOFFSMAX  99999		//ps

#define OFFSETMIN	0			//ns
#define OFFSETMAX	100000000	//ns 
#define ACQTMIN		1			//ms
#define ACQTMAX		360000000	//ms  (100*60*60*1000ms = 100h)

#define STOPCNTMIN  1
#define STOPCNTMAX  4294967295  //32 bit is mem max

#define TRIGOUTMIN  0			//0=off
#define TRIGOUTMAX  16777215	//in units of 100ns

#define HOLDOFFMIN  0			//ns
#define HOLDOFFMAX  25500		//ns

//The following are bitmasks for return values from GetWarnings()

#define WARNING_SYNC_RATE_ZERO				0x0001
#define WARNING_SYNC_RATE_VERY_LOW			0x0002
#define WARNING_SYNC_RATE_TOO_HIGH			0x0004
#define WARNING_INPT_RATE_ZERO				0x0010
#define WARNING_INPT_RATE_TOO_HIGH			0x0040
#define WARNING_INPT_RATE_RATIO				0x0100
#define WARNING_DIVIDER_GREATER_ONE			0x0200
#define WARNING_TIME_SPAN_TOO_SMALL			0x0400
#define WARNING_OFFSET_UNNECESSARY			0x0800
#define WARNING_DIVIDER_TOO_SMALL			0x1000
#define WARNING_COUNTS_DROPPED				0x2000
