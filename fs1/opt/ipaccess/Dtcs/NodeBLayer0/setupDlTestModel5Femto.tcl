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
set trch20ms      ""
set trch10ms      ""
set physCh        ""
set dlCommonIn    ""
set pich10ms      ""
set hsDschCtrl    ""
set hsScchCtrl    ""

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
set cpichGain   [scaleByDb -11 $Armsmax]

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
set pschGain [expr int(0.5 + ([scaleByDb -14 $Armsmax]*sqrt(2)))]
writeMsg dlCommonIn [Layer0Message_DL_PSCH_SETUP $pschGain 0]

# Enable S-SCH (not scrambled so apply sqrt(2) scaling factor)
set sschGain [expr int(0.5 + ([scaleByDb -14 $Armsmax]*sqrt(2)))]
writeMsg dlCommonIn [Layer0Message_DL_SSC_SLOT_SETUP $sscSlots]
writeMsg dlCommonIn [Layer0Message_DL_SSCH_SETUP $sschGain 0]

# Enable P-CPICH
writeMsg dlCommonIn [Layer0Message_DL_PCPICH_SETUP $cpichGain 0]

# Setup PICH
set pichGain  [scaleByDb -19 $Armsmax]
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

set pccpchGain [scaleByDb -11 $Armsmax]
writeMsg dlCfgReqIn [Layer0Message_DL_PCCPCH_GAIN_SETUP $pccpchGain]

####################################################################
# Set S-CCPCH gain and PO
####################################################################

set sccpchGain [scaleByDb -19 $Armsmax]
writeMsg dlCfgReqIn [Layer0Message_DL_SCCPCH_GAIN_SETUP $sccpchGain]

set po1 0 ; # 0dB
set po3 0 ; # 0dB
writeMsg dlCfgReqIn [Layer0Message_DL_SCCPCH_PO_SETUP $po1 $po3]

####################################################################
# Transmit DPCHs (refer to TS25.141 Test Model 5)
####################################################################

set dpchOvfsList        [list 15 23 68 76 82 90]
set dpchChipOffsetList  [list 86 134 52 45 143 112]
set dpchGainList        [list -17 -15 -15 -18 -16 -17]
set numDpch 6;

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
# Transmit HS-SCCH control
####################################################################

set numberChannels 2; # Number of HS-SCCH channels to set-up
set hsScchOvfsList    [list 9 29]
set hsScchGainsList   [list -15 -21]

for { set i 0 } { $i < $numberChannels } { incr i } {

set ovsf            [lindex $hsScchOvfsList $i]
set scrCodeSel      0;
set sttdSel         0;
set lastUserFlag    [expr $i==($numberChannels-1) ? 1 : 0]
set gain            [scaleByDb [lindex $hsScchGainsList $i] $Armsmax]
set ueId            $i;
set chanOffset      [expr $i + 1];
set constVers       0;
set pn9Seed         [expr $ovsf * 23 * 4 + 3]; # 23*OVSF, followed by two ones

writeMsg hsScchCtrl [Layer0Message_DL_HSSCCH_PARAMS $ovsf $scrCodeSel \
                                      $sttdSel $lastUserFlag $gain\
                                      $ueId $chanOffset \
                                      $pn9Seed]

}

####################################################################
# Transmit HS-DSCH control
####################################################################
# Number of HS-DSCH channels to set-up
set numberUsers 2;          # 1 or 2
set numberCodesPerUser 1;   # 1, 2 or 4 

set hsdschOvfsList            [list 4 12]
set hsdschPhysChanOfstList    [list 0 8]

for { set i 0 } { $i < $numberUsers } { incr i } {

set trBlkSz           1838;
set numCodeBlk        1;
set numFillerBits     0;
set codeBlkSz         1862;
set Nir               28800;
set nttiDiv3          1866;
set ndataRateMatch    1920; # 7680 [bits/subframe/4 codes] = 9600 [bits/frame/code]
set rv_s              1;
set rv_r              0;
set rv_rmax           1;
set numPhysChan       $numberCodesPerUser;
set physChanOffset    [lindex $hsdschPhysChanOfstList $i]
set modSel            1;
set constVers         0;
set lastUser          [expr $i==($numberUsers-1) ? 1 : 0];
set numSystematicBits 1866;
set ovsf              [lindex $hsdschOvfsList $i]
set scrCodeSel        0;
set sttdSel           0;
set gain              [scaleByDb -5 $Armsmax]
set pn9Seed           [expr $ovsf * 23];

writeMsg hsDschCtrl [Layer0Message_DL_HSDSCH_PARAMS $trBlkSz \
                     $numCodeBlk $numFillerBits $codeBlkSz \
                     $Nir \
                     $nttiDiv3 \
                     $ndataRateMatch $rv_s $rv_r $rv_rmax \
                     $numPhysChan $physChanOffset $modSel $constVers $lastUser \
                     $numSystematicBits \
                     $ovsf $scrCodeSel $sttdSel $gain \
                     $pn9Seed]

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
set interfaceId 0xf
set switchMode  1
DTCSSendMessage $fd [DTCSMessage_SWIF_CONFIG_REQ $context \
                                                 $interfaceId $switchMode]
# No response message

# Stop scheduler
DTCSSendMessage $fd [DTCSMessage_DL_SCHED_STOP_REQ $context]
DiscardDTCSResponse $fd

# Delete existing scheduler instances
for { set i 0 } { $i < 9 } { incr i } {
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

# dl Hs-scch
incr schedulingInstance +1
set portNumber         0x12; # DTCS_PORT_DL_HSSCCH_CONTROL
set repetition         1;    # every sub-frame
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
                                $hsScchCtrl]
DiscardDTCSResponse $fd

# dl Hs-dsch
incr schedulingInstance +1
set portNumber         0x10; # DTCS_PORT_DL_HSDPSCH_CONTROL
set repetition         1;    # every sub-frame
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
                                $hsDschCtrl]
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
