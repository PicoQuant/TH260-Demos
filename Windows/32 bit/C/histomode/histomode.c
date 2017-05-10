/************************************************************************

  Demo access to TimeHarp 260 Hardware via TH260LIB v 3.1
  The program performs a measurement based on hardcoded settings.
  The resulting histogram is stored in an ASCII output file.

  Michael Wahl, PicoQuant GmbH, March 2017

  Note: This is a console application (i.e. run in Windows cmd box)

  Note: At the API level channel numbers are indexed 0..N-1 
		where N is the number of channels the device has.

  
  Tested with the following compilers:

  - MinGW 2.0.0-3 (free compiler for Win 32 bit)
  - MS Visual C++ 6.0 (Win 32 bit)
  - MS Visual Studio 2010 (Win 64 bit)
  - Borland C++ 5.3 (Win 32 bit)

************************************************************************/

#include <windows.h>
#include <dos.h>
#include <stdio.h>
#include <conio.h>
#include <stdlib.h>
#include <string.h>

#include "th260defin.h"
#include "th260lib.h"
#include "errorcodes.h"


unsigned int counts[MAXINPCHAN][MAXHISTLEN];


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
 char HW_Version[16];
 char HW_Serial[8];
 char Errorstring[40];
 int NumChannels;
 int HistLen;
 int Binning=0; //you can change this
 int Offset=0; 
 int Tacq=1000; //Measurement time in millisec, you can change this
 int SyncDivider = 1; //you can change this
 
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
 double Integralcount; 
 int i,j;
 int flags;
 int warnings;
 char warningstext[16384]; //must have 16384 bytest text buffer
 char cmd=0;


 printf("\nTimeHarp 260 TH260Lib Demo Application    M. Wahl, PicoQuant GmbH, 2017");
 printf("\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
 TH260_GetLibraryVersion(LIB_Version);
 printf("\nLibrary version is %s",LIB_Version);
 if(strncmp(LIB_Version,LIB_VERSION,sizeof(LIB_VERSION))!=0)
         printf("\nWarning: The application was built for version %s.",LIB_VERSION);

 if((fpout=fopen("histomode.out","w"))==NULL)
 {
        printf("\ncannot open output file\n"); 
        goto ex;
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

 fprintf(fpout,"Binning           : %ld\n",Binning);
 fprintf(fpout,"Offset            : %ld\n",Offset);
 fprintf(fpout,"AcquisitionTime   : %ld\n",Tacq);
 fprintf(fpout,"SyncDivider       : %ld\n",SyncDivider);

 printf("\nInitializing the device...");

 retcode = TH260_Initialize(dev[0],MODE_HIST);  //Histo mode with internal clock
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


 if(strcmp(HW_Model,"TimeHarp 260 P")==0)
 {
	 fprintf(fpout,"SyncCFDZeroCross  : %ld\n",SyncCFDZeroCross);
	 fprintf(fpout,"SyncCFDLevel      : %ld\n",SyncCFDLevel);
	 fprintf(fpout,"InputCFDZeroCross : %ld\n",InputCFDZeroCross);
	 fprintf(fpout,"InputCFDLevel     : %ld\n",InputCFDLevel);
 }
 else if(strcmp(HW_Model,"TimeHarp 260 N")==0)
 {
	 fprintf(fpout,"SyncTiggerEdge    : %ld\n",SyncTiggerEdge);
	 fprintf(fpout,"SyncTriggerLevel  : %ld\n",SyncTriggerLevel);
	 fprintf(fpout,"InputTriggerEdge  : %ld\n",InputTriggerEdge);
	 fprintf(fpout,"InputTriggerLevel : %ld\n",InputTriggerLevel);
 }
 else
 {
      printf("\nUnknown hardware model %s. Aborted.\n",HW_Model);
      goto ex;
 }


 retcode = TH260_GetNumOfInputChannels(dev[0],&NumChannels); 
 if(retcode<0)
 {
        TH260_GetErrorString(Errorstring, retcode);
        printf("\nTH260_GetNumOfInputChannels error %d (%s). Aborted.\n",retcode,Errorstring);
        goto ex;
 }
 else
	printf("\nDevice has %i input channels.",NumChannels);


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

 retcode = TH260_SetHistoLen(dev[0], MAXLENCODE, &HistLen);
 if(retcode<0)
 {
        TH260_GetErrorString(Errorstring, retcode);
        printf("\nTH260_SetHistoLen error %d (%s). Aborted.\n",retcode,Errorstring);
        goto ex;
 }
 printf("\nHistogram length is %d",HistLen);

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



 // After Init allow 150 ms for valid  count rate readings
 // Subsequently you get new values after every 100ms
 Sleep(150);


 retcode = TH260_GetSyncRate(dev[0], &Syncrate);
 if(retcode<0)
 {
        TH260_GetErrorString(Errorstring, retcode);
        printf("\nTH260_GetSyncRate error %d (%s). Aborted.\n",retcode,Errorstring);
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
	 

 retcode = TH260_SetStopOverflow(dev[0],0,10000); //for example only
 if(retcode<0)
 {
        TH260_GetErrorString(Errorstring, retcode);
        printf("\nTH260_SetStopOverflow error %d (%s). Aborted.\n",retcode,Errorstring);
        goto ex;
 }

 while(cmd!='q')
 { 

        TH260_ClearHistMem(dev[0]);            
        if(retcode<0)
		{
          TH260_GetErrorString(Errorstring, retcode);
          printf("\nTH260_ClearHistMem error %d (%s). Aborted.\n",retcode,Errorstring);
          goto ex;
		}

        printf("\npress RETURN to start measurement");
        getchar();

        retcode = TH260_GetSyncRate(dev[0], &Syncrate);
        if(retcode<0)
		{
          TH260_GetErrorString(Errorstring, retcode);
          printf("\nTH260_GetSyncRate error %d (%s). Aborted.\n",retcode,Errorstring);
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

		//here you could check for warnings again
        
        retcode = TH260_StartMeas(dev[0],Tacq); 
        if(retcode<0)
        {
                TH260_GetErrorString(Errorstring, retcode);
                printf("\nTH260_StartMeas error %d (%s). Aborted.\n",retcode,Errorstring);
                goto ex;
        }
         
        printf("\n\nMeasuring for %1d milliseconds...",Tacq);
        
		ctcstatus=0;
		while(ctcstatus==0)
		{
		  retcode = TH260_CTCStatus(dev[0], &ctcstatus);
          if(retcode<0)
		  {
                TH260_GetErrorString(Errorstring, retcode);
                printf("\nTH260_CTCStatus error %d (%s). Aborted.\n",retcode,Errorstring);
                goto ex;
		  }
		}
         		
        retcode = TH260_StopMeas(dev[0]);
        if(retcode<0)
        {
                TH260_GetErrorString(Errorstring, retcode);
                printf("\nTH260_StopMeas error %d (%s). Aborted.\n",retcode,Errorstring);
                goto ex;
        }
        
		printf("\n");
		for(i=0;i<NumChannels;i++) // for all channels
		{
          retcode = TH260_GetHistogram(dev[0],counts[i],i,0);
          if(retcode<0)
		  {
                TH260_GetErrorString(Errorstring, retcode);
                printf("\nTH260_GetHistogram error %d (%s). Aborted.\n",retcode,Errorstring);
                goto ex;
		  }

		  Integralcount = 0;
		  for(j=0;j<HistLen;j++)
			Integralcount+=counts[i][j];
        
          printf("\n  Integralcount[%1d]=%1.0lf",i,Integralcount);

		}
		printf("\n");

        retcode = TH260_GetFlags(dev[0], &flags);
        if(retcode<0)
        {
                TH260_GetErrorString(Errorstring, retcode);
                printf("\nTH260_GetFlags error %d (%s). Aborted.\n",retcode,Errorstring);
                goto ex;
        }
        
        if(flags&FLAG_OVERFLOW) printf("\n  Overflow.");

        printf("\nEnter c to continue or q to quit and save the count data.");
        cmd=getchar();
		getchar();
 }
 
 for(j=0;j<HistLen;j++)
 {
	for(i=0;i<NumChannels;i++)
         fprintf(fpout,"%5d ",counts[i][j]);
	fprintf(fpout,"\n");
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


