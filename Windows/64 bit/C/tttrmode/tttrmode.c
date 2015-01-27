/************************************************************************

  Demo access to TimeHarp 260 Hardware via TH260LIB.DLL v 1.1
  The program performs a measurement based on hardcoded settings.
  The resulting event data is stored in a binary output file.

  Michael Wahl, PicoQuant GmbH, September 2013

  Note: This is a console application (i.e. run in Windows cmd box)

  Note: At the API level the input channel numbers are indexed 0..N-1 
		where N is the number of input channels the device has.

  Note: This demo writes only raw event data to the output file.
		It does not write a file header as regular .ht* files have it. 


  Tested with the following compilers:

  - MinGW 2.0.0-3 (free compiler for Win 32 bit)
  - MS Visual C++ 6.0 (Win 32 bit)
  - MS Visual Studio 2010 (Win 64 bit)
  - Borland C++ 5.3 (Win 32 bit)

************************************************************************/


#ifdef _WIN32
#include <windows.h>
#include <dos.h>
#include <conio.h>
#else
#include <unistd.h>
#define Sleep(msec) usleep(msec*1000)
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "th260defin.h"
#include "th260lib.h"
#include "errorcodes.h"


unsigned int buffer[TTREADMAX]; 


int main(int argc, char* argv[])
{

 int dev[MAXDEVNUM]; 
 int found=0;
 FILE *fpout;   
 int retcode;
 int ctcstatus;
 char LIB_Version[8];
 char HW_Model[16];
 char HW_Partno[8];
 char HW_Serial[8];
 char HW_Version[16];
 char Errorstring[40];
 int NumChannels;
 int Mode=MODE_T2; //set T2 or T3 here, observe suitable Sync divider and Range!
 int Binning=0; //you can change this, meaningful only in T3 mode
 int Offset=0;  //you can change this, meaningful only in T3 mode
 int Tacq=1000; //Measurement time in millisec, you can change this
 int SyncDivider = 1; //you can change this, observe Mode! READ MANUAL!

 //These settings will apply for TimeHarp 260 P boards
 int SyncCFDZeroCross=-10; //you can change this
 int SyncCFDLevel=-50; //you can change this
 int InputCFDZeroCross=-10; //you can change this
 int InputCFDLevel=-50; //you can change this

 //These settings will apply for TimeHarp 260 N boards
 int SyncTiggerEdge=0; //you can change this
 int SyncTriggerLevel=-50; //you can change this
 int InputTriggerEdge=0; //you can change this
 int InputTriggerLevel=-50; //you can change this

 double Resolution; 
 int Syncrate;
 int Countrate;
 int i;
 int flags;
 int warnings;
 char warningstext[16384]; //must have 16384 bytest text buffer
 int nRecords;
 unsigned int Progress;


 printf("\nTimeHarp 260 HHLib.DLL Demo Application    M. Wahl, PicoQuant GmbH, 2013");
 printf("\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
 TH260_GetLibraryVersion(LIB_Version);
 printf("\nLibrary version is %s\n",LIB_Version);
 if(strncmp(LIB_Version,LIB_VERSION,sizeof(LIB_VERSION))!=0)
         printf("\nWarning: The application was built for version %s.",LIB_VERSION);

 if((fpout=fopen("tttrmode.out","wb"))==NULL)
 {
        printf("\ncannot open output file\n"); 
        goto ex;
 }


 printf("\nSearching for TimeHarp 260 devices...");
 printf("\nDevidx     Status");


 for(i=0;i<MAXDEVNUM;i++)
 {
	retcode = TH260_OpenDevice(i, HW_Serial); 
	if(retcode==0) //Grab any HydraHarp we can open
	{
		printf("\n  %1d        S/N %s", i, HW_Serial);
		dev[found]=i; //keep index to devices we want to use
		found++;
	}
	else
	{
		if(retcode==TH260_ERROR_DEVICE_OPEN_FAIL)
			printf("\n  %1d        no device", i);
		else 
		{
			TH260_GetErrorString(Errorstring, retcode);
			printf("\n  %1d        %s", i,Errorstring);
		}
	}
 }

 //In this demo we will use the first device we find, i.e. dev[0].
 //You can also use multiple devices in parallel.
 //You can also check for specific serial numbers, so that you always know 
 //which physical device you are talking to.

 if(found<1)
 {
	printf("\nNo device available.");
	goto ex; 
 }
 printf("\nUsing device #%1d",dev[0]);
 printf("\nInitializing the device...");


 retcode = TH260_Initialize(dev[0],Mode);
 if(retcode<0)
 {
        TH260_GetErrorString(Errorstring, retcode);
        printf("\nTH260_Initialize error %d (%s). Aborted.\n",retcode,Errorstring);
        goto ex;
 }

 retcode = TH260_GetHardwareInfo(dev[0],HW_Model,HW_Partno,HW_Version); 
 if(retcode<0)
 {
        TH260_GetErrorString(Errorstring, retcode);
        printf("\nTH260_GetHardwareInfo error %d (%s). Aborted.\n",retcode,Errorstring);
        goto ex;
 }
 else
	printf("\nFound Model %s Part no %s Version %s",HW_Model, HW_Partno, HW_Version);


 retcode = TH260_GetNumOfInputChannels(dev[0],&NumChannels); 
 if(retcode<0)
 {
        TH260_GetErrorString(Errorstring, retcode);
        printf("\nTH260_GetNumOfInputChannels error %d (%s). Aborted.\n",retcode,Errorstring);
        goto ex;
 }
 else
	printf("\nDevice has %i input channels.",NumChannels);



 printf("\n\nUsing the following settings:\n");

 printf("Mode              : %ld\n",Mode);
 printf("Binning           : %ld\n",Binning);
 printf("Offset            : %ld\n",Offset);
 printf("AcquisitionTime   : %ld\n",Tacq);
 printf("SyncDivider       : %ld\n",SyncDivider);

 if(strcmp(HW_Model,"TimeHarp 260 P")==0)
 {
	 printf("SyncCFDZeroCross  : %ld\n",SyncCFDZeroCross);
	 printf("SyncCFDLevel      : %ld\n",SyncCFDLevel);
	 printf("InputCFDZeroCross : %ld\n",InputCFDZeroCross);
	 printf("InputCFDLevel     : %ld\n",InputCFDLevel);
 }
 else if(strcmp(HW_Model,"TimeHarp 260 N")==0)
 {
	 printf("SyncTiggerEdge    : %ld\n",SyncTiggerEdge);
	 printf("SyncTriggerLevel  : %ld\n",SyncTriggerLevel);
	 printf("InputTriggerEdge  : %ld\n",InputTriggerEdge);
	 printf("InputTriggerLevel : %ld\n",InputTriggerLevel);
 }
 else
 {
      printf("\nUnknown hardware model %s. Aborted.\n",HW_Model);
      goto ex;
 }


 retcode = TH260_SetSyncDiv(dev[0],SyncDivider);
 if(retcode<0)
 {
        TH260_GetErrorString(Errorstring, retcode);
        printf("\nPH_SetSyncDiv error %d (%s). Aborted.\n",retcode,Errorstring);
        goto ex;
 }

 if(strcmp(HW_Model,"TimeHarp 260 P")==0)  //Picosecond resolving board
 {
	 retcode=TH260_SetSyncCFD(dev[0],SyncCFDLevel,SyncCFDZeroCross);
	 if(retcode<0)
	 {
			TH260_GetErrorString(Errorstring, retcode);
			printf("\nTH260_SetSyncCFD error %d (%s). Aborted.\n",retcode,Errorstring);
			goto ex;
	 }

	 for(i=0;i<NumChannels;i++) // we use the same input settings for all channels
	 {
		 retcode=TH260_SetInputCFD(dev[0],i,InputCFDLevel,InputCFDZeroCross);
		 if(retcode<0)
		 {
				TH260_GetErrorString(Errorstring, retcode);
				printf("\nTH260_SetInputCFD error %d (%s). Aborted.\n",retcode,Errorstring);
				goto ex;
		 }
	 }
 }

 if(strcmp(HW_Model,"TimeHarp 260 N")==0)  //Nanosecond resolving board
 {
	 retcode=TH260_SetSyncEdgeTrg(dev[0],SyncTriggerLevel,SyncTiggerEdge);
	 if(retcode<0)
	 {
			TH260_GetErrorString(Errorstring, retcode);
			printf("\nTH260_SetSyncEdgeTrg error %d (%s). Aborted.\n",retcode,Errorstring);
			goto ex;
	 }

	 for(i=0;i<NumChannels;i++) // we use the same input settings for all channels
	 {
		 retcode=TH260_SetInputEdgeTrg(dev[0],i,InputTriggerLevel,InputTriggerEdge);
		 if(retcode<0)
		 {
				TH260_GetErrorString(Errorstring, retcode);
				printf("\nTH260_SetInputEdgeTrg error %d (%s). Aborted.\n",retcode,Errorstring);
				goto ex;
		 }
	 }
 }

 retcode = TH260_SetSyncChannelOffset(dev[0],0);
 if(retcode<0)
 {
        TH260_GetErrorString(Errorstring, retcode);
        printf("\nTH260_SetSyncChannelOffset error %d (%s). Aborted.\n",retcode,Errorstring);
        goto ex;
 }

 for(i=0;i<NumChannels;i++) // we use the same input offset for all channels
 {
	 retcode = TH260_SetInputChannelOffset(dev[0],i,0);
	 if(retcode<0)
	 {
			TH260_GetErrorString(Errorstring, retcode);
			printf("\nTH260_SetInputChannelOffset error %d (%s). Aborted.\n",retcode,Errorstring);
			goto ex;
	 }
 }

 retcode = TH260_SetBinning(dev[0],Binning);
 if(retcode<0)
 {
        TH260_GetErrorString(Errorstring, retcode);
        printf("\nTH260_SetBinning error %d (%s). Aborted.\n",retcode,Errorstring);
        goto ex;
 }

 retcode = TH260_SetOffset(dev[0],Offset);
 if(retcode<0)
 {
        TH260_GetErrorString(Errorstring, retcode);
        printf("\nTH260_SetOffset error %d (%s). Aborted.\n",retcode,Errorstring);
        goto ex;
 }
 
 retcode = TH260_GetResolution(dev[0], &Resolution);
 if(retcode<0)
 {
        TH260_GetErrorString(Errorstring, retcode);
        printf("\nTH260_GetResolution error %d (%s). Aborted.\n",retcode,Errorstring);
        goto ex;
 }

 printf("\nResolution is %1.0lfps\n", Resolution);


 printf("\nMeasuring input rates...\n");

 // After Init allow 150 ms for valid  count rate readings
 // Subsequently you get new values after every 100ms
 Sleep(150);

 retcode = TH260_GetSyncRate(dev[0], &Syncrate);
 if(retcode<0)
 {
        TH260_GetErrorString(Errorstring, retcode);
        printf("\nTH260_GetSyncRate error%d (%s). Aborted.\n",retcode,Errorstring);
        goto ex;
 }
 printf("\nSyncrate=%1d/s", Syncrate);


 for(i=0;i<NumChannels;i++) // for all channels
 {
	 retcode = TH260_GetCountRate(dev[0],i,&Countrate);
	 if(retcode<0)
	 {
			TH260_GetErrorString(Errorstring, retcode);
			printf("\nTH260_GetCountRate error %d (%s). Aborted.\n",retcode,Errorstring);
			goto ex;
	 }
	printf("\nCountrate[%1d]=%1d/s", i, Countrate);
 }

 printf("\n");

 //after getting the count rates you can check for warnings
 retcode = TH260_GetWarnings(dev[0],&warnings);
 if(retcode<0)
 {
        TH260_GetErrorString(Errorstring, retcode);
	printf("\nTH260_GetWarnings error %d (%s). Aborted.\n",retcode,Errorstring);
	goto ex;
 }
 if(warnings)
 {
	 TH260_GetWarningsText(dev[0],warningstext, warnings);
	 printf("\n\n%s",warningstext);
 }


 printf("\nStarting data collection...\n");

 Progress = 0;
 printf("\nProgress:%12u",Progress);

 retcode = TH260_StartMeas(dev[0],Tacq); 
 if(retcode<0)
 {
         TH260_GetErrorString(Errorstring, retcode);
         printf("\nTH260_StartMeas error %d (%s). Aborted.\n",retcode,Errorstring);
         goto ex;
 }

 while(1)
 { 
        retcode = TH260_GetFlags(dev[0], &flags);
        if(retcode<0)
        {
		TH260_GetErrorString(Errorstring, retcode);
                printf("\nTH260_GetFlags error %d (%s). Aborted.\n",retcode,Errorstring);
                goto ex;
        }
        
		if (flags&FLAG_FIFOFULL) 
		{
			printf("\nFiFo Overrun!\n"); 
			goto stoptttr;
		}
		
		retcode = TH260_ReadFiFo(dev[0],buffer,TTREADMAX,&nRecords);	//may return less!  
		if(retcode<0) 
		{ 
			TH260_GetErrorString(Errorstring, retcode);
			printf("\nTH260_ReadFiFo error %d (%s). Aborted.\n",retcode,Errorstring);
			goto stoptttr; 
		}  

		if(nRecords) 
		{
			if(fwrite(buffer,4,nRecords,fpout)!=(unsigned)nRecords)
			{
				printf("\nfile write error\n");
				goto stoptttr;
			}               
				Progress += nRecords;
				printf("\b\b\b\b\b\b\b\b\b\b\b\b%12u",Progress);
		}
		else
		{
			retcode = TH260_CTCStatus(dev[0], &ctcstatus);
			if(retcode<0)
			{
		TH260_GetErrorString(Errorstring, retcode);
                printf("\nTH260_CTCStatus error %d (%s). Aborted.\n",retcode,Errorstring);
                goto ex;
			}
			if (ctcstatus) 
			{ 
				printf("\nDone\n"); 
				goto stoptttr; 
			}  
		}

		//within this loop you can also read the count rates if needed.
 }
  
stoptttr:

 retcode = TH260_StopMeas(dev[0]);
 if(retcode<0)
 {
      TH260_GetErrorString(Errorstring, retcode);
      printf("\nTH260_StopMeas error %d (%s). Aborted.\n",retcode,Errorstring);
      goto ex;
 }         
  
ex:

 for(i=0;i<MAXDEVNUM;i++) //no harm to close all
 {
	TH260_CloseDevice(i);
 }
 if(fpout) fclose(fpout);
 printf("\npress RETURN to exit");
 getchar();

 return 0;
}


