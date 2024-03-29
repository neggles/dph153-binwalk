#!/usr/bin/tclsh

package require PC82x8DTCS
package require PC82x8Layer0
package require PC82x8RfIf

namespace import ::PC82x8DTCS::*
namespace import ::PC82x8Layer0::*
namespace import ::PC82x8RfIf::*

# Read command line arguments and extract number of users required
set numUsers 8

if { $argc > 2} {
  set numUsers [lindex $argv 2]
  
  if { ($numUsers <= 0) || ($numUsers > 8) } {
     set numUsers 8
  }
}

puts "Setting up Test model 1 for $numUsers users ..."

###############################################################################
# Open test vector files
###############################################################################

# Input/reference files
set dlCfgReqIn    ""
set trch20ms      ""
set trch10ms      ""
set physCh        ""
set dlCommonIn    ""
set pich10ms      ""

###############################################################################
# Utility functions
###############################################################################

proc writeMsg { fd msg } {

  upvar $fd l
  set l [concat $l "$msg"]

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

proc scaleByDb { dB maxGain } {
  return [expr int(0.5 + pow(10.0,($dB/20.0)) * $maxGain/4)]
}

###############################################################################
# Vector generation / parameters
###############################################################################

# Individual channels
set Armsmax     8191 ; # 2^14-1 (allowing for 12dB back-off from full-scale)
set cpichGain   [scaleByDb -10 $Armsmax]

# Summation gains
set unityGain   [expr pow(2,17)]
set outputGain  [expr int(0.5 + $unityGain)]
set cmnGain     [expr int(0.5 + $unityGain)]
set dchGain     [expr int(0.5 + $unityGain)]
set hsScchGain  [expr int(0.5 + $unityGain)]
set hsDschGain  [expr int(0.5 + $unityGain/(sqrt(20)))]

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

# Enable P-SCH (not scrambled so apply sqrt(2) scaling factor)
set pschGain [expr int(0.5 + ([scaleByDb -13 $Armsmax]*sqrt(2)))]
writeMsg dlCommonIn [Layer0Message_DL_PSCH_SETUP $pschGain 0]

# Enable S-SCH (not scrambled so apply sqrt(2) scaling factor)
set sschGain [expr int(0.5 + ([scaleByDb -13 $Armsmax]*sqrt(2)))]
writeMsg dlCommonIn [Layer0Message_DL_SSC_SLOT_SETUP $sscSlots]
writeMsg dlCommonIn [Layer0Message_DL_SSCH_SETUP $sschGain 0]

# Enable P-CPICH
writeMsg dlCommonIn [Layer0Message_DL_PCPICH_SETUP $cpichGain 0]

# Setup PICH
set pichGain  [scaleByDb -18 $Armsmax]
set numPi     18
set sfnOffset 120
set diversity 0
set ovsf      16
writeMsg dlCommonIn [Layer0Message_DL_PICH_SETUP $pichGain $numPi $sfnOffset $diversity $ovsf]

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

#set trchByteList    [genTrchBytes $trBlkSz]
set trchByteList    ""

writeMsg trch20ms [Layer0Message_DL_TTI_CTRL $trchId $tti $codingType $crcType $rmType \
                                    $cfn $trBlkSz $numCodeBlk $numFillerBits \
                                    $codeBlkSz $deltaN $dtxBits1stLevel \
                                    $pBitList $eIniList $ePlusList \
	                            $eMinusList $numTrBlk $trchByteList]

####################################################################
# Transmit P-CCPCH frame control
####################################################################
if { $argc < 2 } {     
  puts "usage: $argv0 <hostname> <pc302Test (1==yes) default == 0>"
  exit
}

set pc302Build 0
if {[llength $argv] >= 2} {
  set pc302Build [lindex $argv 1]
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
# Transmit PCH TTI data
####################################################################

set trchId       3
set tti          $::PC82x8Layer0::TTIEnum(10MS)
set codingType   $::PC82x8Layer0::CodingTypeEnum(CODING_CONV_1_2)
set crcType      $::PC82x8Layer0::CRCTypeEnum(CRC_16BIT)
set rmType       $::PC82x8Layer0::RMTypeEnum(CRC_CONV_PUNCTURE)
set cfn          0
set trBlkSz      126
set numCodeBlk      1
set numFillerBits   0
set codeBlkSz       142
set numTrBlk        1

# Ratematching/DTX
set deltaN          0
set dtxBits1stLevel 0
set pBitList        [list 0 0]
set eIniList        [list 1 0 0]
set ePlusList       [list 0 0 0]
set eMinusList      [list 0 0 0]

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
set tfciPres        0
set bypass2ndLevel  0
set chipOffset      0
set physChanSz      300
set dtxSize         0
set dschSwitch      0
set dtxSwitch       0
set tfciField1      0
set slotFormatMode  0
set slotFormatIdx   0
set chanType        $::PC82x8Layer0::DlFrameChanTypeEnum(SCCPCH)
set lastFrameFlag   0
set cfn             0
set multiCodeInd    1
set compModeStruct  0
set firstSlotTg     0
set lastSlotTg      0
set ovsf            3
set scramCodeSel    0
set trchIdList      [list $trchId]
set ttiList         [list $::PC82x8Layer0::TTIEnum(10MS)]

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
# Transmit PIs to PICH (only first 18 are sent)
####################################################################

set pagingIndicators [list 1 0 1 1 0 0 0 1 0 1 1 0 0 0 1 0 1 0 \
                           0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 \
                           0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 \
                           0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 \
                           0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 \
                           0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 \
                           0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 \
 			   0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
writeMsg pich10ms [Layer0Message_DL_PI_BITMAP_SEND $pagingIndicators]

####################################################################
# Set P-CCPCH gain
####################################################################

set pccpchGain [scaleByDb -10 $Armsmax]
writeMsg dlCfgReqIn [Layer0Message_DL_PCCPCH_GAIN_SETUP $pccpchGain]

####################################################################
# Set SCCPCH gain and PO
####################################################################

set sccpchGain [scaleByDb -18 $Armsmax]
writeMsg dlCfgReqIn [Layer0Message_DL_SCCPCH_GAIN_SETUP $sccpchGain]

set po1 0 ; # 0dB
set po3 0 ; # 0dB
writeMsg dlCfgReqIn [Layer0Message_DL_SCCPCH_PO_SETUP $po1 $po3]

####################################################################
# Transmit DPCHs (refer to TS25.141 Test Model 1)
####################################################################

set dpchOvfsList        [list 2 11 38 55 78 85 113 119]
set dpchChipOffsetList  [list 86 134 112 23 30 18 128 143]

# TM1 gains
set dpchGainList        [list -7 -16 -11 -11 -10 -12 -8 -12]

# Number of DPDCHs
set numDpch $numUsers

for { set i 0 } { $i < $numDpch } { incr i } {

set trchId       [lindex $dpchOvfsList $i]
set tti          $::PC82x8Layer0::TTIEnum(10MS)
set codingType   $::PC82x8Layer0::CodingTypeEnum(CODING_CONV_1_2)
set crcType      $::PC82x8Layer0::CRCTypeEnum(CRC_16BIT)
set rmType       $::PC82x8Layer0::RMTypeEnum(CRC_CONV_PUNCTURE)
set cfn          0
set trBlkSz      276
set numCodeBlk      1
set numFillerBits   0
set codeBlkSz       292
set numTrBlk        1

# Ratematching/DTX
set deltaN          0
set dtxBits1stLevel 0
set pBitList        [list 0 0]
set eIniList        [list 1 0 0]
set ePlusList       [list 0 0 0]
set eMinusList      [list 0 0 0]

set trchByteList    ""
writeMsg trch10ms [Layer0Message_DL_TTI_CTRL $trchId $tti $codingType $crcType $rmType \
                                    $cfn $trBlkSz $numCodeBlk $numFillerBits \
                                    $codeBlkSz $deltaN $dtxBits1stLevel \
                                    $pBitList $eIniList $ePlusList \
	                            $eMinusList $numTrBlk $trchByteList]

####################################################################
# Transmit DPCH frame control
####################################################################

set physChanId      $i
set tfciPres        0
set bypass2ndLevel  0
set chipOffset      [lindex $dpchChipOffsetList $i]
set physChanSz      600
set dtxSize         0
set dschSwitch      0
set dtxSwitch       0
set tfciField1      0
set slotFormatMode  0
set slotFormatIdx   8
set chanType        $::PC82x8Layer0::DlFrameChanTypeEnum(DPCH)
set lastFrameFlag   0
set cfn             0

if { $pc302Build == 1} {
  set tfciPres        1
  set dtxSwitch     1
}

set multiCodeInd    [expr !$tfciPres]
set compModeStruct  0
set firstSlotTg     0
set lastSlotTg      0
set ovsf            $trchId
set scramCodeSel    0
set trchIdList      [list $trchId]
set ttiList         [list $::PC82x8Layer0::TTIEnum(10MS)]

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

set dpchGain [scaleByDb [lindex $dpchGainList $i] $Armsmax]
writeMsg dlCfgReqIn [Layer0Message_DL_DPCH_GAIN_SETUP $physChanId $dpchGain]

set po1 0 ; # 0dB
set po2 0 ; # 0dB
set po3 0 ; # 0dB
writeMsg dlCfgReqIn [Layer0Message_DL_DPCH_PO_SETUP $physChanId $po1 $po2 $po3]

}

####################################################################
# Power measurements
####################################################################

set dlPwrCalc     "" ;	# Downlink config bus messages

set log2Period 0; # 10ms
writeMsg dlPwrCalc [Layer0Message_DL_MEAN_POWER_READ $log2Period]
writeMsg dlPwrCalc [Layer0Message_DL_PEAK_POWER_READ]
writeMsg dlPwrCalc [Layer0Message_DL_PEAK_POWER_RESET]

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
for { set i 0 } { $i < 8 } { incr i } {
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
DiscardDTCSResponse $fd

# PICH
incr schedulingInstance +1
set portNumber         0x03
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
                                  $pich10ms]
DiscardDTCSResponse $fd

# Start scheduler
DTCSSendMessage $fd [DTCSMessage_DL_SCHED_START_REQ $context]
DiscardDTCSResponse $fd

# Disconnect from server
DTCSDisconnect $fd
