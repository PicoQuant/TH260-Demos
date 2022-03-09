/************************************************************************

  Demo for running multiple TimeHarp 260 in TTTR mode via TH260LIB v.3.2
  The program performs a measurement based on hardcoded settings.
  The resulting event data is stored in multiple binary output files.

  Michael Wahl, PicoQuant GmbH, February 2020

  Note: This is a console application

  Note: At the API level the input channel numbers are indexed 0..N-1 
        where N is the number of input channels the device has.

  Note: This demo writes only raw event data to the output file.
        It does not write a file header as regular .PTU files have it. 


  Tested with the following compilers:

  - MinGW 2.0.0-3 (free compiler for Win 32 bit)
  - MS Visual C++ 6.0 (Win 32 bit)
  - MS Visual Studio 2010 (Win 32/64 bit)
  - Borland C++ 5.3 (Win 32 bit)
  - gcc 4.8.1 (Linux 32/64 bit)  

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


#define NCARDS 2  //this specifies how many cards we want to use in parallel


unsigned int buffer[NCARDS][TTREADMAX]; 


int main(int argc, char* argv[])
{

 int dev[MAXDEVNUM]; 
 int found=0;
 FILE *fpout[NCARDS];   
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
 int Tacq=10000; //Measurement time in millisec, you can change this
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
 int i,j,n;
 int flags;
 int warnings;
 char warningstext[16384]; //must have 16384 bytest text buffer
 int nRecords;
 unsigned int Progress;
 char filename[40];
 int done[NCARDS];
 int alldone;

 printf("\nTimeHarp 260 TH260Lib.DLL Demo Application   M. Wahl, PicoQuant GmbH, 2020");
 printf("\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

 TH260_GetLibraryVersion(LIB_Version);
 printf("\nLibrary version is %s\n",LIB_Version);
 if(strncmp(LIB_Version,LIB_VERSION,sizeof(LIB_VERSION))!=0)
         printf("\nWarning: The application was built for version %s.",LIB_VERSION);

 for(n=0;n<NCARDS;n++)
 {
	 sprintf(filename,"tttrmode_%1d.out",n);
	 if((fpout[n]=fopen(filename,"wb"))==NULL)
	 {
			printf("\ncannot open output file %s\n",filename); 
			goto ex;
	 }
 }

 printf("\nSearching for TimeHarp 260 devices...");
 printf("\nDevidx     Serial     Status");


 for(i=0;i<MAXDEVNUM;i++)
 {
	retcode = TH260_OpenDevice(i, HW_Serial); 
	if(retcode==0) //Grab any device we can open
	{
		printf("\n  %1d        %7s    open ok", i, HW_Serial);
		dev[found]=i; //keep index to devices we want to use
		found++;
	}
	else
	{
		if(retcode==TH260_ERROR_DEVICE_OPEN_FAIL)
			printf("\n  %1d        %7s    no device", i, HW_Serial);
		else 
		{
			TH260_GetErrorString(Errorstring, retcode);
			printf("\n  %1d        %7s    %s", i, HW_Serial, Errorstring);
		}
	}
 }

 //In this demo we will use the first NCARDS devices we find.
 //You can also check for specific serial numbers, so that you always know 
 //which physical device you are talking to.

 if(found<NCARDS)
 {
	printf("\nNot enough devices available.");
	goto ex; 
 }

 for(n=0;n<NCARDS;n++)
	printf("\nUsing device #%1d",dev[n]);

 for(n=0;n<NCARDS;n++)
 {
	 printf("\nInitializing device #%1d",dev[n]);

	 retcode = TH260_Initialize(dev[n],Mode);
	 if(retcode<0)
	 {
			TH260_GetErrorString(Errorstring, retcode);
			printf("\nTH260_Initialize error %d (%s). Aborted.\n",retcode,Errorstring);
			goto ex;
	 }

	 retcode = TH260_GetHardwareInfo(dev[n],HW_Model,HW_Partno,HW_Version); 
	 if(retcode<0)
	 {
			TH260_GetErrorString(Errorstring, retcode);
			printf("\nTH260_GetHardwareInfo error %d (%s). Aborted.\n",retcode,Errorstring);
			goto ex;
	 }
	 else
		printf("\nFound Model %s Part no %s Version %s",HW_Model, HW_Partno, HW_Version);


	 retcode = TH260_GetNumOfInputChannels(dev[n],&NumChannels); 
	 if(retcode<0)
	 {
			TH260_GetErrorString(Errorstring, retcode);
			printf("\nTH260_GetNumOfInputChannels error %d (%s). Aborted.\n",retcode,Errorstring);
			goto ex;
	 }
	 else
		printf("\nDevice has %i input channels.",NumChannels);

	 retcode = TH260_SetSyncDiv(dev[n],SyncDivider);
	 if(retcode<0)
	 {
			TH260_GetErrorString(Errorstring, retcode);
			printf("\nPH_SetSyncDiv error %d (%s). Aborted.\n",retcode,Errorstring);
			goto ex;
	 }

	 if(strcmp(HW_Model,"TimeHarp 260 P")==0)  //Picosecond resolving board
	 {
		 retcode=TH260_SetSyncCFD(dev[n],SyncCFDLevel,SyncCFDZeroCross);
		 if(retcode<0)
		 {
				TH260_GetErrorString(Errorstring, retcode);
				printf("\nTH260_SetSyncCFD error %d (%s). Aborted.\n",retcode,Errorstring);
				goto ex;
		 }

		 for(i=0;i<NumChannels;i++) // we use the same input settings for all channels
		 {
			 retcode=TH260_SetInputCFD(dev[n],i,InputCFDLevel,InputCFDZeroCross);
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
		 retcode=TH260_SetSyncEdgeTrg(dev[n],SyncTriggerLevel,SyncTiggerEdge);
		 if(retcode<0)
		 {
				TH260_GetErrorString(Errorstring, retcode);
				printf("\nTH260_SetSyncEdgeTrg error %d (%s). Aborted.\n",retcode,Errorstring);
				goto ex;
		 }

		 for(i=0;i<NumChannels;i++) // we use the same input settings for all channels
		 {
			 retcode=TH260_SetInputEdgeTrg(dev[n],i,InputTriggerLevel,InputTriggerEdge);
			 if(retcode<0)
			 {
					TH260_GetErrorString(Errorstring, retcode);
					printf("\nTH260_SetInputEdgeTrg error %d (%s). Aborted.\n",retcode,Errorstring);
					goto ex;
			 }
		 }
	 }

	 retcode = TH260_SetSyncChannelOffset(dev[n],0);
	 if(retcode<0)
	 {
			TH260_GetErrorString(Errorstring, retcode);
			printf("\nTH260_SetSyncChannelOffset error %d (%s). Aborted.\n",retcode,Errorstring);
			goto ex;
	 }

	 for(i=0;i<NumChannels;i++) // we use the same input offset for all channels
	 {
		 retcode = TH260_SetInputChannelOffset(dev[n],i,0);
		 if(retcode<0)
		 {
				TH260_GetErrorString(Errorstring, retcode);
				printf("\nTH260_SetInputChannelOffset error %d (%s). Aborted.\n",retcode,Errorstring);
				goto ex;
		 }
	 }

	 retcode = TH260_SetBinning(dev[n],Binning);
	 if(retcode<0)
	 {
			TH260_GetErrorString(Errorstring, retcode);
			printf("\nTH260_SetBinning error %d (%s). Aborted.\n",retcode,Errorstring);
			goto ex;
	 }

	 retcode = TH260_SetOffset(dev[n],Offset);
	 if(retcode<0)
	 {
			TH260_GetErrorString(Errorstring, retcode);
			printf("\nTH260_SetOffset error %d (%s). Aborted.\n",retcode,Errorstring);
			goto ex;
	 }
 
	 retcode = TH260_GetResolution(dev[n], &Resolution);
	 if(retcode<0)
	 {
			TH260_GetErrorString(Errorstring, retcode);
			printf("\nTH260_GetResolution error %d (%s). Aborted.\n",retcode,Errorstring);
			goto ex;
	 }
 }


 printf("\nMeasuring input rates...\n");

 // After Init allow 150 ms for valid  count rate readings
 // Subsequently you get new values after every 100ms
 Sleep(150);

 for(n=0;n<NCARDS;n++)
 {
	 retcode = TH260_GetSyncRate(dev[n], &Syncrate);
	 if(retcode<0)
	 {
			TH260_GetErrorString(Errorstring, retcode);
			printf("\nTH260_GetSyncRate error%d (%s). Aborted.\n",retcode,Errorstring);
			goto ex;
	 }
	 printf("\nSyncrate[%1d]=%1d/s", n, Syncrate);


	 for(i=0;i<NumChannels;i++) // for all channels
	 {
		 retcode = TH260_GetCountRate(dev[n],i,&Countrate);
		 if(retcode<0)
		 {
				TH260_GetErrorString(Errorstring, retcode);
				printf("\nTH260_GetCountRate error %d (%s). Aborted.\n",retcode,Errorstring);
				goto ex;
		 }
		printf("\nCountrate[%1d][%1d]=%1d/s", n, i, Countrate);
	 }
 }

 printf("\n");

 //after getting the count rates you can check for warnings
 for(n=0;n<NCARDS;n++)
 {
	 retcode = TH260_GetWarnings(dev[n],&warnings);
	 if(retcode<0)
	 {
			TH260_GetErrorString(Errorstring, retcode);
		printf("\nTH260_GetWarnings error %d (%s). Aborted.\n",retcode,Errorstring);
		goto ex;
	 }
	 if(warnings)
	 {
		 TH260_GetWarningsText(dev[n],warningstext, warnings);
		 printf("\n\nDevice %1d:",n);
		 printf("\n%s",warningstext);
	 }
 }

 printf("\npress RETURN to start");
 getchar();
 
 printf("\nStarting data collection...\n");

 Progress = 0;
 printf("\nProgress:%12u",Progress);

 for(n=0;n<NCARDS;n++)
 {
	 retcode = TH260_StartMeas(dev[n],Tacq); 
	 if(retcode<0)
	 {
			 TH260_GetErrorString(Errorstring, retcode);
			 printf("\nTH260_StartMeas error %d (%s). Aborted.\n",retcode,Errorstring);
			 goto ex;
	 }
	 done[n]=0;
 }

 while(1)
 { 
	for(n=0;n<NCARDS;n++) //this basic demo uses a loop, for efficiency this should be done in parallel
	{
        retcode = TH260_GetFlags(dev[n], &flags);
        if(retcode<0)
        {
			TH260_GetErrorString(Errorstring, retcode);
            printf("\nTH260_GetFlags error %d (%s). Aborted.\n",retcode,Errorstring);
            goto ex;
        }
        
		if (flags&FLAG_FIFOFULL) 
		{
			printf("\nDevice %1d: FiFo Overrun!\n",n); 
			goto stoptttr;
		}
		
		retcode = TH260_ReadFiFo(dev[n],buffer[n],TTREADMAX,&nRecords);	//may return less!  
		if(retcode<0) 
		{ 
			TH260_GetErrorString(Errorstring, retcode);
			printf("\nTH260_ReadFiFo error %d (%s). Aborted.\n",retcode,Errorstring);
			goto stoptttr; 
		}  

		if(nRecords) 
		{
			if(fwrite(buffer[n],4,nRecords,fpout[n])!=(unsigned)nRecords)
			{
				printf("\nfile write error\n");
				goto stoptttr;
			}               
				Progress += nRecords;
				if(n==NCARDS-1)
				{
					printf("\b\b\b\b\b\b\b\b\b\b\b\b%12u",Progress);
					fflush(stdout);
				}
		}
		else
		{
			retcode = TH260_CTCStatus(dev[n], &ctcstatus);
			if(retcode<0)
			{
				TH260_GetErrorString(Errorstring, retcode);
                printf("\nTH260_CTCStatus error %d (%s). Aborted.\n",retcode,Errorstring);
                goto ex;
			}
			if (ctcstatus) 
			{ 
				done[n]=1;
				alldone = 0;
				for(j=0;j<NCARDS;j++)
					alldone += done[j];
				if(alldone == NCARDS)
				{
					printf("\nDone\n"); 
					goto stoptttr; 
				}
			}  
		}
	}
	//within this loop you can also read the count rates if needed but consider the time this costs
 }
  
stoptttr:

 for(n=0;n<NCARDS;n++)
 {
	 retcode = TH260_StopMeas(dev[n]);
	 if(retcode<0)
	 {
		  TH260_GetErrorString(Errorstring, retcode);
		  printf("\nTH260_StopMeas error %d (%s). Aborted.\n",retcode,Errorstring);
		  goto ex;
	 }         
 }

ex:

 for(i=0;i<MAXDEVNUM;i++) //no harm to close all
 {
	TH260_CloseDevice(i);
 }

 for(n=0;n<NCARDS;n++)
	if(fpout[n]) fclose(fpout[n]);

 printf("\npress RETURN to exit");
 getchar();

 return 0;
}


