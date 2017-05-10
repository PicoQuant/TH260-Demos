TH260Lib Programming Library for TimeHarp 260 
Version 3.1.0.1
PicoQuant GmbH - March 2017



Introduction

The TimeHarp 260 PCIe board is a Time Correlated Single Photon Counting 
System for applications such as time resolved fluorescence measurement. 

The system requires at least a dual core computer with at least 1 GB 
of memory and 1.5 GHz CPU clock (2 GHz and 2 GB recommended). 
The TimeHarp software is suitable for Windows 7, 8, and 10. 

The programming library is a DLL with demos for various programming 
languages. Please refer to the manual (PDF) for instructions.

Note that you must purchase the TimeHarp 260 DLL option for this
software to work. This is a one time fee, version upgrades are free.


What's new in version 3.1.0.1

- Supports new hardware models manufactured after February 2017
- Fixes a buffer alignment issue causing freezes on some recent 
  PC mainboard models
- Fixes an issue with hardware debug information retrieval
- Improves data throughput in histogramming mode
- The API and data structures remain unchanged in functionaity
- For best throughput observe new buffer alignment recommendation


What was new in version 3.0.0.1

- Fixes an issue where unfortunate calling sequences could lead to
  the loss of status information retrieved via TH260_GetFlags 
- Some documentation improvements


What was new in version 3.0

- Supports the latest hardware improvement of the TimeHarp 260 N - 
  now running at 250 ps resolution (owners of older models with 
  1 ns resolution can request a quote for a hardware upgrade to 250 ps) 
- Officially supports Windows 10 
- Fixes some minor bugs 
- API and data formats remain unchanged


What was new in version 2.0

- A new library routine SetInputDeadTime for suppression of some detector 
  artefacts. (Note that this works only for TimeHarp 260 P purchased after 
  April 2015. Old boards can be updated but must be returned to PicoQuant 
  for this purpose.)
- A bugfix in the shutdown code called upon unloading the library
- Some small demo code improvements
- A new device driver with improved error handling and automated 
  installation. The driver must meet new code signing requirements imposed 
  by Microsoft. Consequently Windows versions prior to 7 are no longer 
  supported. If you must use an older Windows version you can still use the 
  driver of the TimeHarp 260 release version 1.1. 
- Some documentation fixes


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
The TH260Lib package can be distributed on CD/DVD or via download.
The setup distribution file is setup.exe.
If you received the package via download it will be packed in a 
zip-file. Unzip that file and place the distribution setup file in a 
temporary disk folder. Start the installation by running setup.exe and
follow the installer wizard.

The setup program will install the programming library including driver,
manual, and programming demos. Note that the demos create output files 
and must have write access in the folder where you run them. This may not 
be the case in the default installation folder. If need be, please adjust 
the acces permissions or copy the demos to a more suitable folder.

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
www http://www.picoquant.com
