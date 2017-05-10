
/************************************************************************

  C# demo access to TimeHarp 260 Hardware via TH260LIB v 3.1.
  The program performs a measurement based on hardcoded settings.
  The resulting histogram is stored in an ASCII output file.

  Michael Wahl, PicoQuant GmbH, March 2017

  Note: This is a console application (i.e. run in Windows cmd box)

  Note: At the API level channel numbers are indexed 0..N-1 
		where N is the number of channels the device has.

  
  Tested with the following compilers:

  - MS Visual C# 2010 (Win 32/64 bit)
  - Mono 3.2.3 (Win 32/64 bit)

************************************************************************/


using System; 				//for Console
using System.Text; 			//for StringBuilder 
using System.IO;			//for File
using System.Runtime.InteropServices;	//for DllImport




class HistoMode 
{

	//the following constants are taken from TH260Lib.defin

	const int MAXDEVNUM = 4;
	const int TH260_ERROR_DEVICE_OPEN_FAIL = -1;
	const int MODE_HIST = 0;
	const int MAXLENCODE = 5;
	const int MAXINPCHAN = 2;
	const int MAXHISTLEN = 32768;
	const int FLAG_OVERFLOW = 0x0001;


#if x64
	const string TH260Lib = "th260lib64"; 
#else
	const string TH260Lib = "th260lib"; 
#endif


	const string TargetLibVersion ="3.1"; //this is what this program was written for


	[DllImport(TH260Lib)]
	extern static int TH260_GetLibraryVersion(StringBuilder vers);

	[DllImport(TH260Lib)]
	extern static int TH260_GetErrorString(StringBuilder errstring, int errcode);

	[DllImport(TH260Lib)]
	extern static int TH260_OpenDevice(int devidx, StringBuilder serial); 

	[DllImport(TH260Lib)]
	extern static int TH260_Initialize(int devidx, int mode);

	[DllImport(TH260Lib)]
	extern static int TH260_GetHardwareInfo(int devidx, StringBuilder model, StringBuilder partno, StringBuilder version); 

	[DllImport(TH260Lib)]
	extern static int TH260_GetNumOfInputChannels(int devidx, ref int nchannels);

	[DllImport(TH260Lib)]
	extern static int TH260_SetSyncDiv(int devidx, int div);

	[DllImport(TH260Lib)] //TimeHarp 260 P only
	extern static int TH260_SetSyncCFD(int devidx, int level, int zerox);

	[DllImport(TH260Lib)] //TimeHarp 260 N only
	extern static int TH260_SetSyncEdgeTrg(int devidx, int level, int edge);

	[DllImport(TH260Lib)]
	extern static int TH260_SetSyncChannelOffset(int devidx, int value);

	[DllImport(TH260Lib)] //TimeHarp 260 P only
	extern static int TH260_SetInputCFD(int devidx, int channel, int level, int zerox);

	[DllImport(TH260Lib)] //TimeHarp 260 N only
	extern static int TH260_SetInputEdgeTrg(int devidx, int channel, int level, int edge);

	[DllImport(TH260Lib)]
	extern static int TH260_SetInputChannelOffset(int devidx, int channel, int value);

	[DllImport(TH260Lib)]
	extern static int TH260_SetInputChannelEnable(int devidx, int channel, int enable);

	[DllImport(TH260Lib)] //TimeHarp 260 P only
	extern static int TH260_SetInputDeadTime(int devidx, int channel, int tdcode);

	[DllImport(TH260Lib)]
	extern static int TH260_SetBinning(int devidx, int binning);

	[DllImport(TH260Lib)]
	extern static int TH260_SetOffset(int devidx, int offset);

	[DllImport(TH260Lib)]
	extern static int TH260_SetHistoLen(int devidx, int lencode, ref int actuallen); 

	[DllImport(TH260Lib)]
	extern static int TH260_GetResolution(int devidx, ref double resolution); 

	[DllImport(TH260Lib)]
	extern static int TH260_GetSyncRate(int devidx, ref int syncrate);

	[DllImport(TH260Lib)]
	extern static int TH260_GetCountRate(int devidx, int channel, ref int cntrate);

	[DllImport(TH260Lib)]
	extern static int TH260_GetWarnings(int devidx, ref int warnings);

	[DllImport(TH260Lib)]
	extern static int TH260_GetWarningsText(int devidx, StringBuilder warningstext, int warnings);

	[DllImport(TH260Lib)]
	extern static int TH260_SetStopOverflow(int devidx, int stop_ovfl, uint stopcount);

	[DllImport(TH260Lib)]
	extern static int TH260_ClearHistMem(int devidx);

	[DllImport(TH260Lib)]
	extern static int TH260_StartMeas(int devidx, int tacq);

	[DllImport(TH260Lib)]
	extern static int TH260_StopMeas(int devidx);

	[DllImport(TH260Lib)]
	extern static int TH260_CTCStatus(int devidx, ref int ctcstatus);

	[DllImport(TH260Lib)]
	extern static int TH260_GetHistogram(int devidx, uint[] chcount, int channel, int clear);

	[DllImport(TH260Lib)]
	extern static int TH260_GetFlags(int devidx, ref int flags); 
	
	[DllImport(TH260Lib)]
	extern static int TH260_CloseDevice(int devidx);



	static void Main() 
	{

		int i,j;
		int retcode;
		string cmd = "";
		int[] dev= new int[MAXDEVNUM];
		int found = 0;
		int NumChannels = 0;

		StringBuilder LibVer = new StringBuilder (8);
		StringBuilder Serial = new StringBuilder (8);
		StringBuilder Errstr = new StringBuilder (40);
		StringBuilder Model  = new StringBuilder (16);
		StringBuilder Partno = new StringBuilder (8);
        StringBuilder Version = new StringBuilder(16);
		StringBuilder Wtext  = new StringBuilder (16384);

		int HistLen = 0; 	//you can change this, observe limits
		int Binning = 0; 	//you can change this, observe limits
		int Offset = 0;  	//you can change this, observe limits
		int Tacq = 1000; 	//Measurement time in millisec, you can change this, observe limits

		int SyncDivider = 8;		//you can change this, observe limits

        //TimeHarp 260 P only
		int SyncCFDZeroCross=-10;	//you can change this, observe limits
		int SyncCFDLevel=-50;		//you can change this, observe limits
		int InputCFDZeroCross=-10;	//you can change this, observe limits
		int InputCFDLevel=-50;		//you can change this, observe limits

        //TimeHarp 260 N only
        int SyncTrigEdge = 0;	    //you can change this, observe limits
        int SyncTrigLevel = -50;	//you can change this, observe limits
        int InputTrigEdge = 0;	    //you can change this, observe limits
        int InputTrigLevel = -50;	//you can change this, observe limits

		double Resolution = 0;

		int Syncrate = 0;
		int Countrate = 0;
		int ctcstatus = 0;
		int flags = 0;
		int warnings = 0;

        uint[][] counts = new uint[MAXINPCHAN][];
        for (i = 0; i < MAXINPCHAN; i++)		
		 counts[i] = new uint[MAXHISTLEN];

		StreamWriter SW = null;


		Console.WriteLine ("TimeHarp 260     TH260Lib Demo Application    M. Wahl, PicoQuant GmbH, 2017");
		Console.WriteLine ("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");


		retcode = TH260_GetLibraryVersion(LibVer);
		if(retcode<0)
		{
			TH260_GetErrorString(Errstr, retcode);
			Console.WriteLine("TH260_GetLibraryVersion error {0}. Aborted.",Errstr);
        		goto ex;
 		}
		Console.WriteLine("TH260Lib Version is " + LibVer);

		if(LibVer.ToString() != TargetLibVersion)
		{
			Console.WriteLine("This program requires TH260Lib v." + TargetLibVersion);
        		goto ex;
 		}

		try
		{
			SW = File.CreateText("histomode.out");
		}
		catch ( Exception )
       		{
			Console.WriteLine("Error creating file");
			goto ex;
		}

		Console.WriteLine("Searching for TimeHarp 260 devices...");
		Console.WriteLine("Devidx     Status");


		for(i=0;i<MAXDEVNUM;i++)
 		{
			retcode = TH260_OpenDevice(i, Serial);  
			if(retcode==0) //Grab any TimeHarp we can open
			{
				Console.WriteLine("  {0}        S/N {1}", i, Serial);
				dev[found]=i; //keep index to devices we want to use
				found++;
			}
			else
			{

				if(retcode==TH260_ERROR_DEVICE_OPEN_FAIL)
					Console.WriteLine("  {0}        no device", i);
				else 
				{
					TH260_GetErrorString(Errstr, retcode);
					Console.WriteLine("  {0}        S/N {1}", i, Errstr);
				}
			}
		}

		//In this demo we will use the first device we find, i.e. dev[0].
		//You can also use multiple devices in parallel.
		//You can also check for specific serial numbers, so that you always know 
		//which physical device you are talking to.

		if(found<1)
		{
			Console.WriteLine("No device available.");
			goto ex; 
 		}


		Console.WriteLine("Using device {0}",dev[0]);
		Console.WriteLine("Initializing the device...");

		retcode = TH260_Initialize(dev[0],MODE_HIST);  //Histo mode
		if(retcode<0)
		{
			TH260_GetErrorString(Errstr, retcode);
			Console.WriteLine("TH260_Initialize error {0}. Aborted.",Errstr);
        		goto ex;
 		}

		retcode = TH260_GetHardwareInfo(dev[0],Model,Partno,Version); //this is only for information
		if(retcode<0)
		{
			TH260_GetErrorString(Errstr, retcode);
			Console.WriteLine("TH260_GetHardwareInfo error {0}. Aborted.",Errstr);
			goto ex;
		}
		else
            Console.WriteLine("Found Model {0} Part no {1} Version {2}", Model, Partno, Version);


		retcode = TH260_GetNumOfInputChannels(dev[0], ref NumChannels); 
		if(retcode<0)
		{
			TH260_GetErrorString(Errstr, retcode);
			Console.WriteLine("TH260_GetNumOfInputChannels error {0}. Aborted.",Errstr);
       			goto ex;
		}
		else
			Console.WriteLine("Device has {0} input channels.",NumChannels);


		retcode = TH260_SetSyncDiv(dev[0],SyncDivider);
		if(retcode<0)
		{
			TH260_GetErrorString(Errstr, retcode);
			Console.WriteLine("TH260_SetSyncDiv Error {0}. Aborted.",Errstr);
			goto ex;
		}

        
        if (Model.ToString() == "TimeHarp 260 P")
        {
            retcode = TH260_SetSyncCFD(dev[0], SyncCFDLevel, SyncCFDZeroCross);
            if (retcode < 0)
            {
                TH260_GetErrorString(Errstr, retcode);
                Console.WriteLine("TH260_SetSyncCFD Error {0}. Aborted.", Errstr);
                goto ex;
            }
            for (i = 0; i < NumChannels; i++) // we use the same input settings for all channels
            {
                retcode = TH260_SetInputCFD(dev[0], i, InputCFDLevel, InputCFDZeroCross);
                if (retcode < 0)
                {
                    TH260_GetErrorString(Errstr, retcode);
                    Console.WriteLine("TH260_SetInputCFD Error {0}. Aborted.", Errstr);
                    goto ex;
                }
            }
        }
        else if (Model.ToString() == "TimeHarp 260 N")
        {
            retcode = TH260_SetSyncEdgeTrg(dev[0], SyncTrigLevel, SyncTrigEdge);
            if (retcode < 0)
            {
                TH260_GetErrorString(Errstr, retcode);
                Console.WriteLine("TH260_SetSyncEdgeTrg Error {0}. Aborted.", Errstr);
                goto ex;
            }
            for (i = 0; i < NumChannels; i++) // we use the same input settings for all channels
            {
                retcode = TH260_SetInputEdgeTrg(dev[0], i, InputTrigLevel, InputTrigEdge);
                if (retcode < 0)
                {
                    TH260_GetErrorString(Errstr, retcode);
                    Console.WriteLine("TH260_SetInputEdgeTrg Error {0}. Aborted.", Errstr);
                    goto ex;
                }
            }
        }
        else
        {
            Console.WriteLine("Unknown hardware model: {0}. Aborted.", Model);
            goto ex;
        }
        
		retcode = TH260_SetSyncChannelOffset(dev[0],0);
		if(retcode<0)
		{
			TH260_GetErrorString(Errstr, retcode);
			Console.WriteLine("TH260_SetSyncChannelOffset Error {0}. Aborted.",Errstr);
			goto ex;
		}

		for(i=0;i<NumChannels;i++) // we use the same input settings for all channels
		{
			retcode = TH260_SetInputChannelOffset(dev[0],i,0);
			if(retcode<0)
			{
				TH260_GetErrorString(Errstr, retcode);
				Console.WriteLine("TH260_SetInputChannelOffset Error {0}. Aborted.",Errstr);
				goto ex;
			}
			retcode = TH260_SetInputChannelEnable(dev[0], i, 1);
			if(retcode<0)
			{
				TH260_GetErrorString(Errstr, retcode);
				Console.WriteLine("TH260_SetInputChannelEnable Error {0}. Aborted.",Errstr);
				goto ex;
			}
		}

		retcode = TH260_SetHistoLen(dev[0], MAXLENCODE, ref HistLen);
		if(retcode<0)
		{
			TH260_GetErrorString(Errstr, retcode);
			Console.WriteLine("TH260_SetHistoLen Error {0}. Aborted.",Errstr);
			goto ex;
		}
		Console.WriteLine("Histogram length is {0}",HistLen);


		retcode = TH260_SetBinning(dev[0],Binning);
		if(retcode<0)
		{
			TH260_GetErrorString(Errstr, retcode);
			Console.WriteLine("TH260_SetBinning Error {0}. Aborted.",Errstr);
			goto ex;
		}

		retcode = TH260_SetOffset(dev[0],Offset);
		if(retcode<0)
		{
			TH260_GetErrorString(Errstr, retcode);
			Console.WriteLine("TH260_SetOffset Error {0}. Aborted.",Errstr);
			goto ex;
		}

		retcode = TH260_GetResolution(dev[0], ref Resolution);
		if(retcode<0)
		{
			TH260_GetErrorString(Errstr, retcode);
			Console.WriteLine("TH260_GetResolution Error {0}. Aborted.",Errstr);
			goto ex;
		}

		Console.WriteLine("Resolution is {0} ps", Resolution);


        // After Init allow 150 ms for valid  count rate readings
        // Subsequently you get new values after every 100ms
		System.Threading.Thread.Sleep( 150 );

		retcode = TH260_GetSyncRate(dev[0], ref Syncrate);
		if(retcode<0)
		{
			TH260_GetErrorString(Errstr, retcode);
			Console.WriteLine("TH260_GetSyncRate Error {0}. Aborted.",Errstr);
			goto ex;
		}
		Console.WriteLine("Syncrate = {0}/s", Syncrate);

		for(i=0;i<NumChannels;i++) // for all channels
		{
	 		retcode = TH260_GetCountRate(dev[0],i, ref Countrate);
			if(retcode<0)
			{
				TH260_GetErrorString(Errstr, retcode);
				Console.WriteLine("TH260_GetCountRate Error {0}. Aborted.",Errstr);
				goto ex;
			}
			Console.WriteLine("Countrate[{0}] = {1}/s", i, Countrate);
		}

		Console.WriteLine();

		//After getting the count rates you can check for warnings
		retcode = TH260_GetWarnings(dev[0], ref warnings);
		if(retcode<0)
		{
			TH260_GetErrorString(Errstr, retcode);
			Console.WriteLine("TH260_GetWarnings Error {0}. Aborted.",Errstr);
			goto ex;
		}
		if(warnings!=0)
		{
			TH260_GetWarningsText(dev[0],Wtext, warnings);
			Console.WriteLine("{0}",Wtext);
		}


		retcode = TH260_SetStopOverflow(dev[0],0,10000); //for example only
		if(retcode<0)
		{
			TH260_GetErrorString(Errstr, retcode);
			Console.WriteLine("TH260_SetStopOverflow Error {0}. Aborted.",Errstr);
			goto ex;
		}

		while(cmd!="q")
		{ 
			TH260_ClearHistMem(dev[0]);            
			if(retcode<0)
			{
				TH260_GetErrorString(Errstr, retcode);
				Console.WriteLine("TH260_ClearHistMem Error {0}. Aborted.",Errstr);
				goto ex;
			}

			Console.WriteLine("press RETURN to start measurement");
			Console.ReadLine();

			retcode = TH260_GetSyncRate(dev[0], ref Syncrate);
			if(retcode<0)
			{
				TH260_GetErrorString(Errstr, retcode);
				Console.WriteLine("TH260_ClearHistMem Error {0}. Aborted.",Errstr);
				goto ex;
			}
			Console.WriteLine("Syncrate = {0}/s", Syncrate);

			for(i=0;i<NumChannels;i++) // for all channels
			{
	      			retcode = TH260_GetCountRate(dev[0],i, ref Countrate);
				if(retcode<0)
				{
					TH260_GetErrorString(Errstr, retcode);
					Console.WriteLine("TH260_GetCountRate Error {0}. Aborted.",Errstr);
					goto ex;
				}
				Console.WriteLine("Countrate[{0}] = {1}/s", i, Countrate);
			}

			retcode = TH260_StartMeas(dev[0],Tacq); 
			if(retcode<0)
			{
				TH260_GetErrorString(Errstr, retcode);
				Console.WriteLine("TH260_StartMeas Error {0}. Aborted.",Errstr);
				goto ex;
			}
         
			Console.WriteLine("Measuring for {0} milliseconds...",Tacq);


			ctcstatus=0;
			while(ctcstatus==0) //wait until measurement is completed
			{
		  		retcode = TH260_CTCStatus(dev[0], ref ctcstatus);
				if(retcode<0)
				{
					TH260_GetErrorString(Errstr, retcode);
					Console.WriteLine("TH260_CTCStatus Error {0}. Aborted.",Errstr);
					goto ex;
				}
			}

			retcode = TH260_StopMeas(dev[0]); 
			if(retcode<0)
			{
				TH260_GetErrorString(Errstr, retcode);
				Console.WriteLine("TH260_StopMeas Error {0}. Aborted.",Errstr);
				goto ex;
			}


			Console.WriteLine();
			for(i=0;i<NumChannels;i++) // for all channels
			{
        			retcode = TH260_GetHistogram(dev[0],counts[i],i,0);
				if(retcode<0)
				{
					TH260_GetErrorString(Errstr, retcode);
					Console.WriteLine("TH260_GetHistogram Error {0}. Aborted.",Errstr);
					goto ex;
				}

		 		double Integralcount = 0;
		  		for(j=0;j<HistLen;j++)
					Integralcount+=counts[i][j];
        
				Console.WriteLine("  Integralcount[{0}] = {1}",i,Integralcount);
			}

			Console.WriteLine();

        		retcode = TH260_GetFlags(dev[0], ref flags);
			if(retcode<0)
			{
				TH260_GetErrorString(Errstr, retcode);
				Console.WriteLine("TH260_GetFlags Error {0}. Aborted.",Errstr);
				goto ex;
			}
        
        		if( (flags&FLAG_OVERFLOW) != 0) 
				Console.WriteLine("  Overflow.");


			Console.WriteLine("Enter c to continue or q to quit and save the count data.");
        		cmd = Console.ReadLine();		

		}//while

		for(j=0;j<HistLen;j++)
		{
			for(i=0;i<NumChannels;i++)
			SW.Write("{0,5} ",counts[i][j]);
			SW.WriteLine();
 		}

		SW.Close();

	ex:

		for(i=0;i<MAXDEVNUM;i++) //no harm to close all
		{
			TH260_CloseDevice(i);
		}

		Console.WriteLine("press RETURN to exit");
		Console.ReadLine();

	}

}



