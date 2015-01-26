TH260Lib Programming Library for TimeHarp 260 
Version 1.1
PicoQuant GmbH - September 2013



Introduction

The TimeHarp 260 PCIe board is a Time Correlated Single Photon Counting 
System for applications such as time resolved fluorescence measurement. 

The system requires a dual core computer with at least 1 GB 
of memory and 1.5 GHz CPU clock (2 GHz and 2 GB recommended). 
The TimeHarp software is suitable for Windows XP, Vista, 7 and 8. 

Note that the setup program does not install any hardware drivers.
This must be performed by standard Windows mechanisms. 

The programming library is a DLL with demos for various programming 
languages. Please refer to the manual (PDF) for instructions.

Note that you must purchase the TimeHarp 260 DLL option for this
software to work.


What's new in this version

The new version 1.1 of TH260Lib provides the following new features:
- Compression of overflow records in TTTR mode
- A new library routine GetHardwareDebugInfo
- A new library routine GetSyncPeriod
- A new library routine SetMarkerHoldoffTime replacing SetMarkerHoldoff
- A bugfix for SetSyncCFD and SetInputCFD
- Some small demo code improvements
- A bugfix of the LabVIEW demos
- Some documentation fixes

The changes are also marked in red in manual section 7.2 listing the 
individual library routines. See the notes there for synopsis.


Disclaimer

PicoQuant GmbH disclaims all warranties with regard to this software 
and associated documentation including all implied warranties of 
merchantability and fitness. In no case shall PicoQuant GmbH be 
liable for any direct, indirect or consequential damages or any material 
or immaterial damages whatsoever resulting from loss of data, time 
or profits arising from use or performance of this software.


License and Copyright Notice

With the TimeHarp 260 DLL option you have purchased a license to use 
the TH260Lib software. You have not purchased the software itself. 
The software is protected by copyright and intellectual property laws. 
You may not distribute the software to third parties or reverse engineer, 
decompile or disassemble the software or part thereof. You may use and 
modify demo code to create your own software. Original or modified demo 
code may be re-distributed, provided that the original disclaimer and 
copyright notes are not removed from it. Copyright of the manual and 
on-line documentation belongs to PicoQuant GmbH. No parts of it may be 
reproduced, translated or transferred to third parties without written 
permission of PicoQuant GmbH.


Trademark Disclaimer

HydraHarp, PicoHarp, TimeHarp and NanoHarp are registered trademarks 
of PicoQuant GmbH. Other products and corporate names appearing in the 
product manuals or in the online documentation may or may not be registered 
trademarks or copyrights of their respective owners. They are used only 
for identification or explanation and to the owner’s benefit, without 
intent to infringe.


Installation 

Before installation, make sure to backup any work you kept in previous
installation directories and uninstall any older versions of TH260Lib.
The TH260Lib package can be distributed on CD, via download or via email.
The setup distribution file is setup.exe.
If you received the package via download or email, it may be packed in a 
zip-file. Unzip that file and place the distribution setup file in a 
temporary disk folder. Start the installation by running setup.exe and
follow the installer wizard.

The setup program will install the programming library including manual, 
and programming demos. Note that the demos create output files and must 
have write access in the folder where you run them. This may not be the 
case in the default installation folder. If need be, please adjust the 
acces permissions or copy the demos to a suitable folder.

Before uninstalling the TH260Lib package, please backup your measurement 
data and custom programs.
From the start menu select:  PicoQuant - TimeHarp 260 - TH260Lib  vx.x  
>  uninstall.
Alternatively you can use the Control Panel Wizard 'Add/Remove Programs'
(in some Windows versions this Wizard is called 'Software')


Contact and Support

PicoQuant GmbH
Rudower Chaussee 29
12489 Berlin, Germany
Phone +49 30 6392 6929
Fax   +49 30 6392 6561
email info@picoquant.com
