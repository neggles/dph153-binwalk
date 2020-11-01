#!/usr/bin/tclsh

package require PC82x8DTCS
package require PC82x8Layer0
package require PC82x8RfIf

namespace import ::PC82x8DTCS::*
namespace import ::PC82x8Layer0::*
namespace import ::PC82x8RfIf::*

###############################################################################
# Open test vector files
###############################################################################

# Input/reference files
set dlCfgReqIn    ""
set dlCommonIn    ""
set trch10ms      ""
set trch20ms      ""
set trch40ms      ""
set physCh        ""

###############################################################################
# Utility functions
###############################################################################

proc writeFile { fd msg } {
  foreach i $msg { puts $fd [format %08x $i] }
}

proc writeMsg { fd msg } {

  upvar $fd l
  set l [concat $l "$msg"]

}

proc dumpMsg { msg } {
  foreach i $msg {
    puts [format %08x $i]
  }
}

proc DiscardDTCSResponse { fd } {
  set msgLen 0
  while { $msgLen == 0 } {
    set msg [DTCSReceiveMessage $fd]
    set msgLen [llength $msg]
  }
}

proc genTrchBytes { numBits } {

  set bytes ""

  set numBytes [expr (($numBits)>>3)]
  for { set i 1 } { $i <= $numBytes } { incr i} {
    lappend bytes $i
  }

  return $bytes
}

###############################################################################
# Vector generation / parameters
###############################################################################

# Individual channels
set maxGain     8191 ; # 2^13-1
set pichRef     729  ; # maxGain-15dB

# Summation gains
set unityGain   131072
set outputGain  $unityGain
set cmnGain     $unityGain
set dchGain     $unityGain
set hsScchGain  0
set hsDschGain  0

# Scrambling code group 0 as 'N-1'
set sscSlots    [list 0 0 1 7 8 9 14 7 9 15 1 6 14 6 15]

# Configure gain stage
writeMsg dlCommonIn [Layer0Message_DL_DCH_GAIN_SETUP $dchGain ]
writeMsg dlCommonIn [Layer0Message_DL_COMMON_GAIN_SETUP $cmnGain ]
writeMsg dlCommonIn [Layer0Message_DL_HSSCCH_GAIN_SETUP $hsScchGain ]
writeMsg dlCommonIn [Layer0Message_DL_HSDSCH_GAIN_SETUP $hsDschGain ]
writeMsg dlCommonIn [Layer0Message_DL_OUTPUT_GAIN_SETUP $outputGain ]

# Configure scrambling code generators
set xfsr        1 ;       # Scrambling code 0 (Group 0)
writeMsg dlCommonIn [Layer0Message_DL_SCRAM_CODE_SETUP $xfsr \
                      $::PC82x8Layer0::DlScramCodeGenEnum(DCH0) ]
writeMsg dlCommonIn [Layer0Message_DL_SCRAM_CODE_SETUP $xfsr \
                      $::PC82x8Layer0::DlScramCodeGenEnum(DCH1) ]
writeMsg dlCommonIn [Layer0Message_DL_SCRAM_CODE_SETUP $xfsr \
                      $::PC82x8Layer0::DlScramCodeGenEnum(DCH2) ]
writeMsg dlCommonIn [Layer0Message_DL_SCRAM_CODE_SETUP $xfsr \
                      $::PC82x8Layer0::DlScramCodeGenEnum(DCH3) ]
writeMsg dlCommonIn [Layer0Message_DL_SCRAM_CODE_SETUP $xfsr \
                      $::PC82x8Layer0::DlScramCodeGenEnum(HSDPA0) ]
writeMsg dlCommonIn [Layer0Message_DL_SCRAM_CODE_SETUP $xfsr \
                      $::PC82x8Layer0::DlScramCodeGenEnum(HSDPA1) ]
writeMsg dlCommonIn [Layer0Message_DL_SCRAM_CODE_SETUP $xfsr \
                      $::PC82x8Layer0::DlScramCodeGenEnum(COMMON0) ]
writeMsg dlCommonIn [Layer0Message_DL_SCRAM_CODE_SETUP $xfsr \
                      $::PC82x8Layer0::DlScramCodeGenEnum(COMMON1) ]

# Enable P-SCH
set pschGain $pichRef
writeMsg dlCommonIn [Layer0Message_DL_PSCH_SETUP $pschGain 0]

# Enable S-SCH
set sschGain $pichRef
writeMsg dlCommonIn [Layer0Message_DL_SSC_SLOT_SETUP $sscSlots]
writeMsg dlCommonIn [Layer0Message_DL_SSCH_SETUP $sschGain 0]

# Enable P-CPICH
writeMsg dlCommonIn [Layer0Message_DL_PCPICH_SETUP $pichRef 0]

####################################################################
# Transmit BCH TTI data (20ms)
####################################################################

set trchId       1
set tti          $::PC82x8Layer0::TTIEnum(20MS)
set codingType   $::PC82x8Layer0::CodingTypeEnum(CODING_CONV_1_2)
set crcType      $::PC82x8Layer0::CRCTypeEnum(CRC_16BIT)
set rmType       $::PC82x8Layer0::RMTypeEnum(CRC_CONV_PUNCTURE)
set cfn          8
set trBlkSz      246
set numCodeBlk      1
set numFillerBits   0
set codeBlkSz       262
set numTrBlk        1

# Ratematching/DTX
set deltaN          0
set dtxBits1stLevel 0
set pBitList        [list 0 0]
set eIniList        [list 1 0 0]
set ePlusList       [list 0 0 0]
set eMinusList      [list 0 0 0]

set trchByteList    ""

writeMsg trch20ms [Layer0Message_DL_TTI_CTRL $trchId $tti $codingType $crcType $rmType \
                                    $cfn $trBlkSz $numCodeBlk $numFillerBits \
                                    $codeBlkSz $deltaN $dtxBits1stLevel \
                                    $pBitList $eIniList $ePlusList \
	                            $eMinusList $numTrBlk $trchByteList]

####################################################################
# Transmit P-CCPCH frame control
####################################################################
if { ([llength $argv] != 1) && 
     ([llength $argv] != 2)} {
  puts "usage: $argv0 <hostname> <pc302Test (1==yes) default == 0>"
  exit
}

set pc302Build 0
if {[llength $argv] == 2} {
  set pc302Build [lindex $argv end]
}

set physChanId      32
set tfciPres        0
set bypass2ndLevel  0
set chipOffset      0
set physChanSz      270
set dtxSize         0
set dschSwitch      0
set dtxSwitch       0
set tfciField1      0
set slotFormatMode  0
set slotFormatIdx   0
set chanType        $::PC82x8Layer0::DlFrameChanTypeEnum(PCCPCH)
set lastFrameFlag   0
set cfn             8
set multiCodeInd    1
set compModeStruct  0
set firstSlotTg     0
set lastSlotTg      0
set ovsf            1
set scramCodeSel    0
set trchIdList      [list $trchId]
set ttiList         [list $::PC82x8Layer0::TTIEnum(20MS)]

if { $pc302Build == 1} {
  set tfciPres        1
  set dtxSwitch     1
}

writeMsg physCh [Layer0Message_DL_FRAME_CTRL $physChanId \
                                $tfciPres $bypass2ndLevel $chipOffset \
                                $physChanSz $dtxSize $dschSwitch $dtxSwitch \
                                $tfciField1 $slotFormatMode $slotFormatIdx \
                                $chanType $lastFrameFlag $cfn $multiCodeInd \
                                $compModeStruct $firstSlotTg $lastSlotTg \
              		   $ovsf $scramCodeSel $trchIdList $ttiList]

####################################################################
# Set P-CCPCH gain
####################################################################

set pccpchGain $pichRef>>1;		# -6dB of CPICH
writeMsg dlCfgReqIn [Layer0Message_DL_PCCPCH_GAIN_SETUP $pccpchGain]

####################################################################
# Transmit PCH TTI data
####################################################################

set trchId       6
set tti          $::PC82x8Layer0::TTIEnum(10MS)
set codingType   $::PC82x8Layer0::CodingTypeEnum(CODING_CONV_1_2)
set crcType      $::PC82x8Layer0::CRCTypeEnum(CRC_16BIT)
set rmType       $::PC82x8Layer0::RMTypeEnum(CRC_REPETITION0)
set cfn          0
set trBlkSz      240
set numCodeBlk      1
set numFillerBits   0
set codeBlkSz       256
set numTrBlk        1

# Ratematching/DTX
set deltaN          97
set dtxBits1stLevel 0
set pBitList        [list 0 0]
set eIniList        [list 1    1 1]
set ePlusList       [list 1056 0 0]
set eMinusList      [list 194  0 0]

set trchByteList    ""

writeMsg trch10ms [Layer0Message_DL_TTI_CTRL $trchId $tti $codingType $crcType $rmType \
                                    $cfn $trBlkSz $numCodeBlk $numFillerBits \
                                    $codeBlkSz $deltaN $dtxBits1stLevel \
                                    $pBitList $eIniList $ePlusList \
	                            $eMinusList $numTrBlk $trchByteList]

####################################################################
# Transmit FACH TTI data
####################################################################

set trchId       7
set tti          $::PC82x8Layer0::TTIEnum(10MS)
set codingType   $::PC82x8Layer0::CodingTypeEnum(CODING_CONV_1_2)
set crcType      $::PC82x8Layer0::CRCTypeEnum(CRC_16BIT)
set rmType       $::PC82x8Layer0::RMTypeEnum(CRC_REPETITION0)
set cfn          0
set trBlkSz      168
set numCodeBlk      1
set numFillerBits   0
set codeBlkSz       184
set numTrBlk        1

# Ratematching/DTX
set deltaN          71
set dtxBits1stLevel 0
set pBitList        [list 0 0]
set eIniList        [list 1    1 1]
set ePlusList       [list 768  0 0]
set eMinusList      [list 142  0 0]

set trchByteList    ""
writeMsg trch10ms [Layer0Message_DL_TTI_CTRL $trchId $tti $codingType $crcType $rmType \
                                    $cfn $trBlkSz $numCodeBlk $numFillerBits \
                                    $codeBlkSz $deltaN $dtxBits1stLevel \
                                    $pBitList $eIniList $ePlusList \
	                            $eMinusList $numTrBlk $trchByteList]

####################################################################
# Transmit SCCPCH frame control
####################################################################

set physChanId      33
set tfciPres        1
set bypass2ndLevel  0
set chipOffset      0
set physChanSz      1080
set dtxSize         0
set dschSwitch      0
set dtxSwitch       0
set tfciField1      0
set slotFormatMode  0
set slotFormatIdx   8
set chanType        $::PC82x8Layer0::DlFrameChanTypeEnum(SCCPCH)
set lastFrameFlag   0
set cfn             0
set multiCodeInd    0
set compModeStruct  0
set firstSlotTg     0
set lastSlotTg      0
set ovsf            63
set scramCodeSel    0
set trchIdList      [list 6 7]
set ttiList         [list $::PC82x8Layer0::TTIEnum(10MS) \
                          $::PC82x8Layer0::TTIEnum(10MS)]

writeMsg physCh [Layer0Message_DL_FRAME_CTRL $physChanId \
                                $tfciPres $bypass2ndLevel $chipOffset \
                                $physChanSz $dtxSize $dschSwitch $dtxSwitch \
                                $tfciField1 $slotFormatMode $slotFormatIdx \
                                $chanType $lastFrameFlag $cfn $multiCodeInd \
                                $compModeStruct $firstSlotTg $lastSlotTg \
               		   $ovsf $scramCodeSel $trchIdList $ttiList]

####################################################################
# Set SCCPCH gain and PO
####################################################################

set sccpchGain $pichRef>>1;		# -6dB of CPICH
writeMsg dlCfgReqIn [Layer0Message_DL_SCCPCH_GAIN_SETUP $sccpchGain]

set po1 12 ; # +3dB
set po3 12 ; # +3dB
writeMsg dlCfgReqIn [Layer0Message_DL_SCCPCH_PO_SETUP $po1 $po3]

####################################################################
# Transmit AMR RAB #1
####################################################################

set trchId       2
set tti          $::PC82x8Layer0::TTIEnum(20MS)
set codingType   $::PC82x8Layer0::CodingTypeEnum(CODING_CONV_1_3)
set crcType      $::PC82x8Layer0::CRCTypeEnum(CRC_12BIT)
set rmType       $::PC82x8Layer0::RMTypeEnum(CRC_REPETITION0)
set cfn          0
set trBlkSz      81
set numCodeBlk      1
set numFillerBits   0
set codeBlkSz       93
set numTrBlk        1

# Ratematching/DTX
set deltaN          5
set dtxBits1stLevel 0
set pBitList        [list 0 0]
set eIniList        [list 1   1 1]
set ePlusList       [list 606 0 0]
set eMinusList      [list 10  0 0]

set trchByteList    ""
writeMsg trch20ms [Layer0Message_DL_TTI_CTRL $trchId $tti $codingType $crcType $rmType \
                                    $cfn $trBlkSz $numCodeBlk $numFillerBits \
                                    $codeBlkSz $deltaN $dtxBits1stLevel \
                                    $pBitList $eIniList $ePlusList \
	                            $eMinusList $numTrBlk $trchByteList]

####################################################################
# Transmit AMR RAB #2
####################################################################

set trchId       3
set tti          $::PC82x8Layer0::TTIEnum(20MS)
set codingType   $::PC82x8Layer0::CodingTypeEnum(CODING_CONV_1_3)
set crcType      $::PC82x8Layer0::CRCTypeEnum(CRC_NONE)
set rmType       $::PC82x8Layer0::RMTypeEnum(CRC_CONV_PUNCTURE)
set cfn          0
set trBlkSz      103
set numCodeBlk      1
set numFillerBits   0
set codeBlkSz       103
set numTrBlk        1

# Ratematching/DTX
set deltaN          -9
set dtxBits1stLevel 0
set pBitList        [list 0 0]
set eIniList        [list 1   1 1]
set ePlusList       [list 666 0 0]
set eMinusList      [list 18  0 0]

set trchByteList    ""
writeMsg trch20ms [Layer0Message_DL_TTI_CTRL $trchId $tti $codingType $crcType $rmType \
                                    $cfn $trBlkSz $numCodeBlk $numFillerBits \
                                    $codeBlkSz $deltaN $dtxBits1stLevel \
                                    $pBitList $eIniList $ePlusList \
	                            $eMinusList $numTrBlk $trchByteList]

####################################################################
# Transmit AMR RAB #3
####################################################################

set trchId       4
set tti          $::PC82x8Layer0::TTIEnum(20MS)
set codingType   $::PC82x8Layer0::CodingTypeEnum(CODING_CONV_1_2)
set crcType      $::PC82x8Layer0::CRCTypeEnum(CRC_NONE)
set rmType       $::PC82x8Layer0::RMTypeEnum(CRC_REPETITION0)
set cfn          0
set trBlkSz      60
set numCodeBlk      1
set numFillerBits   0
set codeBlkSz       60
set numTrBlk        1

# Ratematching/DTX
set deltaN          26
set dtxBits1stLevel 0
set pBitList        [list 0 0]
set eIniList        [list 1   1 1]
set ePlusList       [list 272 0 0]
set eMinusList      [list 52  0 0]

set trchByteList    ""
writeMsg trch20ms [Layer0Message_DL_TTI_CTRL $trchId $tti $codingType $crcType $rmType \
                                    $cfn $trBlkSz $numCodeBlk $numFillerBits \
                                    $codeBlkSz $deltaN $dtxBits1stLevel \
                                    $pBitList $eIniList $ePlusList \
	                            $eMinusList $numTrBlk $trchByteList]

####################################################################
# Transmit AMR SRB
####################################################################

set trchId       5
set tti          $::PC82x8Layer0::TTIEnum(40MS)
set codingType   $::PC82x8Layer0::CodingTypeEnum(CODING_CONV_1_3)
set crcType      $::PC82x8Layer0::CRCTypeEnum(CRC_16BIT)
set rmType       $::PC82x8Layer0::RMTypeEnum(CRC_CONV_PUNCTURE)
set cfn          0
set trBlkSz      148
set numCodeBlk      1
set numFillerBits   0
set codeBlkSz       164
set numTrBlk        1

# Ratematching/DTX
set deltaN          -64
set dtxBits1stLevel 0
set pBitList        [list 0 0 0 0]
set eIniList        [list 1    1 1]
set ePlusList       [list 1032 0 0]
set eMinusList      [list 128  0 0]

set trchByteList    ""
writeMsg trch40ms [Layer0Message_DL_TTI_CTRL $trchId $tti $codingType $crcType $rmType \
                                    $cfn $trBlkSz $numCodeBlk $numFillerBits \
                                    $codeBlkSz $deltaN $dtxBits1stLevel \
                                    $pBitList $eIniList $ePlusList \
	                            $eMinusList $numTrBlk $trchByteList]

####################################################################
# Transmit AMR frame control
####################################################################

set physChanId      0
set tfciPres        0
set bypass2ndLevel  0
set chipOffset      0
set physChanSz      510
set dtxSize         0
set dschSwitch      0
set dtxSwitch       0
set tfciField1      0
set slotFormatMode  0
set slotFormatIdx   8
set chanType        $::PC82x8Layer0::DlFrameChanTypeEnum(DPCH)
set lastFrameFlag   0
set cfn             0
set multiCodeInd    1
set compModeStruct  0
set firstSlotTg     0
set lastSlotTg      0
set ovsf            2
set scramCodeSel    0
set trchIdList      [list 2 3 4 5]
set ttiList         [list $::PC82x8Layer0::TTIEnum(20MS) \
                          $::PC82x8Layer0::TTIEnum(20MS) \
                          $::PC82x8Layer0::TTIEnum(20MS) \
                          $::PC82x8Layer0::TTIEnum(40MS)]
if { $pc302Build == 1} {
  set tfciPres        1
  set dtxSwitch     1
}
writeMsg physCh [Layer0Message_DL_FRAME_CTRL $physChanId \
                               $tfciPres $bypass2ndLevel $chipOffset \
                               $physChanSz $dtxSize $dschSwitch $dtxSwitch \
                               $tfciField1 $slotFormatMode $slotFormatIdx \
                               $chanType $lastFrameFlag $cfn $multiCodeInd \
                               $compModeStruct $firstSlotTg $lastSlotTg \
               		   $ovsf $scramCodeSel $trchIdList $ttiList]

####################################################################
# Set DPCH gain and PO
####################################################################

set dpchGain $pichRef>>1;		# -6dB of CPICH
writeMsg dlCfgReqIn [Layer0Message_DL_DPCH_GAIN_SETUP $physChanId $dpchGain]

set po1 0; # 0dB
set po2 0; # 0dB
set po3 0; # 0dB
writeMsg dlCfgReqIn [Layer0Message_DL_DPCH_PO_SETUP $physChanId $po1 $po2 $po3]

####################################################################
# Power measurements
####################################################################

set dlPwrCalc     "" ;	# Downlink config bus messages

set log2Period 2; # 40ms
writeMsg dlPwrCalc [Layer0Message_DL_MEAN_POWER_READ $log2Period]
writeMsg dlPwrCalc [Layer0Message_DL_PEAK_POWER_READ]

####################################################################
# Connect to DTCS
####################################################################

set host [lindex $argv 0]
set fd [DTCSConnect $host]

# DTCSMessage_SWIF_CONFIG_REQ { context
#                               interfaceId
#                               switchMode }
set context     0
set interfaceId 0xd
set switchMode  1
DTCSSendMessage $fd [DTCSMessage_SWIF_CONFIG_REQ $context \
                                                 $interfaceId $switchMode]
# No response message

# Stop scheduler
DTCSSendMessage $fd [DTCSMessage_DL_SCHED_STOP_REQ $context]
DiscardDTCSResponse $fd

# Delete existing scheduler instances
for { set i 0 } { $i < 10 } { incr i } {
  DTCSSendMessage $fd [DTCSMessage_DL_SCHED_DELETE_REQ $context $i]
  DiscardDTCSResponse $fd
}

# Setup new scheduler instances

# dlCommonIn
set schedulingInstance 0
set portNumber         0x03
set repetition         0
set frameOffset        0
set dataGenSeed        0
set dataGenLen         0
DTCSSendMessage $fd [DTCSMessage_DL_SCHED_SETUP_REQ $context \
                                  $schedulingInstance \
                                  $portNumber \
                                  $repetition \
                                  $frameOffset \
                                  $dataGenSeed \
                                  $dataGenLen \
                                  $dlCommonIn]
DiscardDTCSResponse $fd

# dlCfgReqIn
incr schedulingInstance +1
set portNumber         0x20
set repetition         0
set frameOffset        0
set dataGenSeed        0
set dataGenLen         0
DTCSSendMessage $fd [DTCSMessage_DL_SCHED_SETUP_REQ $context \
                                  $schedulingInstance \
                                  $portNumber \
                                  $repetition \
                                  $frameOffset \
                                  $dataGenSeed \
                                  $dataGenLen \
                                  $dlCfgReqIn]
DiscardDTCSResponse $fd

# dlPwrCalc
incr schedulingInstance +1
set portNumber         0x20
set repetition         10
set frameOffset        0
set dataGenSeed        0
set dataGenLen         0
DTCSSendMessage $fd [DTCSMessage_DL_SCHED_SETUP_REQ $context \
                                  $schedulingInstance \
                                  $portNumber \
                                  $repetition \
                                  $frameOffset \
                                  $dataGenSeed \
                                  $dataGenLen \
                                  $dlPwrCalc]
DiscardDTCSResponse $fd

# 10ms TTI
incr schedulingInstance +1
set portNumber         0x00
set repetition         1
set frameOffset        0
set dataGenSeed        1
set dataGenLen         0
DTCSSendMessage $fd [DTCSMessage_DL_SCHED_SETUP_REQ $context \
                                  $schedulingInstance \
                                  $portNumber \
                                  $repetition \
                                  $frameOffset \
                                  $dataGenSeed \
                                  $dataGenLen \
                                  $trch10ms]
DiscardDTCSResponse $fd

# 20ms TTI
incr schedulingInstance +1
set portNumber         0x00
set repetition         2
set frameOffset        0
set dataGenSeed        1
set dataGenLen         0
DTCSSendMessage $fd [DTCSMessage_DL_SCHED_SETUP_REQ $context \
                                  $schedulingInstance \
                                  $portNumber \
                                  $repetition \
                                  $frameOffset \
                                  $dataGenSeed \
                                  $dataGenLen \
                                  $trch20ms]
writeFile [open "trch20ms.dat" w] $trch20ms
DiscardDTCSResponse $fd

# 40ms TTI
incr schedulingInstance +1
set portNumber         0x00
set repetition         4
set frameOffset        0
set dataGenSeed        1
set dataGenLen         0
DTCSSendMessage $fd [DTCSMessage_DL_SCHED_SETUP_REQ $context \
                                  $schedulingInstance \
                                  $portNumber \
                                  $repetition \
                                  $frameOffset \
                                  $dataGenSeed \
                                  $dataGenLen \
                                  $trch40ms]
writeFile [open "trch40ms.dat" w] $trch40ms
DiscardDTCSResponse $fd

# All physical channels
incr schedulingInstance +1
set portNumber         0x02
set repetition         1
set frameOffset        0
set dataGenSeed        0
set dataGenLen         0
DTCSSendMessage $fd [DTCSMessage_DL_SCHED_SETUP_REQ $context \
                                  $schedulingInstance \
                                  $portNumber \
                                  $repetition \
                                  $frameOffset \
                                  $dataGenSeed \
                                  $dataGenLen \
                                  $physCh]
writeFile [open "physCh.dat" w] $physCh
DiscardDTCSResponse $fd

# Start scheduler
DTCSSendMessage $fd [DTCSMessage_DL_SCHED_START_REQ $context]
DiscardDTCSResponse $fd

# Disconnect from server
DTCSDisconnect $fd
