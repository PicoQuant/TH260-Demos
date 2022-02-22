
**currently un-maintained  Please contact support@picoquant.com for up-to-date versions and information**


# Demo Code for TH260Lib Programming Library for TimeHarp 260


This is demo source code for controlling the TimeHarp 260 TCSPC card

http://www.picoquant.com/products/category/tcspc-and-time-tagging-modules/timeharp-260-tcspc-and-mcs-board-with-pcie-interface

Latest Version of the DLL and TH260 Software is available for here: https://www.picoquant.com/dl_software/TimeHarp260/TimeHarp260_SW_and_DLL_V3_1_0_3.zip

Please also refer to the manual: https://www.picoquant.com/dl_manuals/TimeHarp260_DLL_manual_v3.1.0.2.pdf or the manual for Linux: https://www.picoquant.com/dl_manuals/TimeHarp260_DLL_manual_Linux_v3.1.0.2.pdf

If you are looking for working with ```*.ptu``` and ```*.phu``` files created by PicoQuant software demo code is available here: https://github.com/PicoQuant/PicoQuant-Time-Tagged-File-Format-Demos

Version 3.1.0.3
PicoQuant GmbH - 2018

## Disclaimer

PicoQuant GmbH disclaims all warranties with regard to this software and associated documentation including all implied warranties of merchantability and fitness. In no case shall PicoQuant GmbH be liable for any direct, indirect or consequential damages or any material or immaterial damages whatsoever resulting from loss of data, time or profits arising from use or performance of this software.

## Introduction

The TimeHarp 260 PCIe board is a Time Correlated Single Photon Counting System for applications such as time resolved fluorescence measurement.

The system requires at least a dual core computer with at least 1 GB of memory and 1.5 GHz CPU clock (2 GHz and 2 GB recommended). The TimeHarp software is suitable for Windows 7, 8, and 10.

The programming library is a DLL with demos for various programming languages. Please refer to the manual (PDF) for instructions.

Note that you must purchase the TimeHarp 260 DLL option for this software to work. This is a one time fee, version upgrades are free.

## What's new in Version 3.1.0.3

- Fixes an issue with sporadic timeout errors upon hardware initialization
- Fixes an issue where errors occurred when Windows was set to 1 or 2 ms
  timer resolution
- Provides a new driver to support Windows 10 with "secure boot" enabled
- The file format remains unchanged

## What's new in version 3.1.0.2
- Fixes an issue with stopping measurements on some PCs
- Fixes an issue with unresponsive user interface on some PCs in histogramming mode
- Improves histogramming throughput while reducing CPU load
- The file format remains unchanged

## What's new in version 3.1.0.1
- Supports new hardware models manufactured after February 2017
- Fixes a buffer alignment issue causing freezes on some recent
  PC mainboard models
- Fixes an issue with hardware debug information retrieval
- Improves data throughput in histogramming mode
- The API and data structures remain unchanged in functionaity
- For best throughput observe new buffer alignment recommendation


## What's new in Version 3.0.0.1

- Fixes a bug that could lead to the loss of status information
- Fixes an issue where clipboard data was truncated at long time spans
- Provides some documentation improvements
- The file format remains unchanged

## What's new in Version 3.0

- Supports the latest hardware improvement of the TimeHarp 260 N -
  now running at 250 ps resolution (owners of older models with
  1 ns resolution can request a quote for a hardware upgrade to 250 ps)
- Officially supports Windows 10
- Fixes some minor bugs
- The file format remains unchanged

## What's New in Version 2.0

- Some minor bugfixes
- A new file format. The idea is to place individual header data items not
  in a strict file position and order but to tag the items by name, so that
  future additions do not harm existing software.
- A new device driver in order to meet new driver signing requirements imposed
  by Microsoft. The new driver can now be conveniently installed by setup exe.
  Note that Windows versions prior to 7 are no longer supported. If you must
  use an older Windows version you can still use the driver of the TimeHarp
  260 release version 1.1.
- Supports a new hardware feature to change the dead time of the input
  channels for suppression of some detector artefacts. Note that this works
  only for TimeHarp 260 P purchased after April 2015. Old boards can be
  updated but must be returned to PicoQuant for a hardware modification.

## Trademark Disclaimer

HydraHarp, PicoHarp, TimeHarp and NanoHarp are registered trademarks of PicoQuant GmbH. Other products and corporate names appearing in the product manuals or in the online documentation may or may not be registered trademarks or copyrights of their respective owners. They are used only for identification or explanation and to the owners benefit, without intent to infringe.


## Contact and Support
http://support.picoquant.com
