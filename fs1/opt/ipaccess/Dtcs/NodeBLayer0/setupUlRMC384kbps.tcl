#!/usr/bin/tclsh

package require PC82x8DTCS
package require PC82x9Layer0
package require PC82x8RfIf

namespace import ::PC82x8DTCS::*
namespace import ::PC82x9Layer0::*
namespace import ::PC82x8RfIf::*

###############################################################################
# Args
###############################################################################

if { [llength $argv] < 2 } {
  puts "usage: $argv0 <hostname> <srchThreshold> <user ID (0~7)>"
  exit
} elseif { [llength $argv] == 2 } {
  puts "Using default userId = 0"
  set userId 0 
} else {
  set userId  [lindex $argv 2]
}

set host          [lindex $argv 0]
set threshold     [lindex $argv 1]

###############################################################################
# Open test vector files
###############################################################################

# Input/reference files
set ulSymCtrl(0)  "" ;	# 10ms (frame 0)
set ulSymCtrl(1)  "" ;	# 20ms (frame 1)
set ulSymCtrl(2)  "" ;	# 30ms (frame 2)
set ulSymCtrl(3)  "" ;	# 40ms (frame 3)
set ulCecSetup    "" ;	# Static CEC setup
set ulCecTfci     "" ;	# Dynamic CEC TFCI commands

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

###############################################################################
# Uplink symbol rate control
###############################################################################

for { set i 0 } { $i < 4 } { incr i } {

set physChanId        $userId
set resetFlag         0
set cfn               4
#set cctrchSize       9600
set spreadFactorEnum  0
set compModeGapCount  0x0
set numTrch 2

# Physical channel setup
writeMsg ulSymCtrl($i) [Layer0Message_UL_PHYSCH_CTRL $physChanId \
                                                 $resetFlag \
                                                 [expr $cfn + $i] \
                                                 $spreadFactorEnum \
                                                 $compModeGapCount \
                                                 $numTrch-1 ]

# TrCHId #0
set trchReset(0)     [expr $i==0 ? 1 : 0]
set ttiLog2(0)       $::PC82x9Layer0::TTIEnum(40MS)
set codingType(0)    $::PC82x9Layer0::CodingTypeEnum(CODING_TURBO_1_3)
set crcType(0)       $::PC82x9Layer0::CRCTypeEnum(CRC_16BIT)
set rmType(0)        $::PC82x9Layer0::RMTypeEnum(CRC_TURBO_PUNCTURE)
set trchXiSize(0)    11580
set radioEqBits(0)   0
set numCodeBlk(0)    4
set numFillerBits(0) 0
set codeBlkSize(0)   3856
set numTrBlk(0)      4
set trBlkSz(0)       3840
set eIniList(0,0)    [list 1    252  1027]
set ePlusList(0,0)   [list 0    7720 3860]
set eMinusList(0,0)  [list 0    2056 1027]
set eIniList(0,1)    [list 3860 1    3860]
set ePlusList(0,1)   [list 3860 0    7720]
set eMinusList(0,1)  [list 1027 0    2056]
set eIniList(0,2)    [list 3860 2054 1]
set ePlusList(0,2)   [list 7720 3860 0]
set eMinusList(0,2)  [list 2056 1027 0]
set eIniList(0,3)    [list 1    5916 3860]
set ePlusList(0,3)   [list 0    7720 3860]
set eMinusList(0,3)  [list 0    2056 1027]

# TrCHId #1
set trchReset(1)     [expr $i==0 ? 1 : 0]
set ttiLog2(1)       $::PC82x9Layer0::TTIEnum(40MS)
set codingType(1)    $::PC82x9Layer0::CodingTypeEnum(CODING_CONV_1_3)
set crcType(1)       $::PC82x9Layer0::CRCTypeEnum(CRC_12BIT)
set rmType(1)        $::PC82x9Layer0::RMTypeEnum(CRC_CONV_PUNCTURE)
set trchXiSize(1)    90
set radioEqBits(1)   0
set numCodeBlk(1)    1
set numFillerBits(1) 0
set codeBlkSize(1)   112
set numTrBlk(1)      1
set trBlkSz(1)       100
set eIniList(1,0)    [list 1   0 0]
set ePlusList(1,0)   [list 180 0 0]
set eMinusList(1,0)  [list 30  0 0]
set eIniList(1,1)    [list 31  0 0]
set ePlusList(1,1)   [list 180 0 0]
set eMinusList(1,1)  [list 30  0 0]
set eIniList(1,2)    [list 121 0 0]
set ePlusList(1,2)   [list 180 0 0]
set eMinusList(1,2)  [list 30  0 0]
set eIniList(1,3)    [list 61  0 0]
set ePlusList(1,3)   [list 180 0 0]
set eMinusList(1,3)  [list 30  0 0]

for { set trchId 0 } { $trchId < $numTrch } { incr trchId } {

# TRCH control (frame i)
set localTrChId [expr $trchId + $userId]
writeMsg ulSymCtrl($i) [Layer0Message_UL_TRCH_CTRL $localTrChId $trchReset($trchId) \
                                               $ttiLog2($trchId) \
                                               $codingType($trchId) \
                                               $crcType($trchId) \
                                               $rmType($trchId) \
                                               $trchXiSize($trchId) \
                                               $radioEqBits($trchId) \
                                               $eIniList($trchId,$i) \
                                               $ePlusList($trchId,$i) \
                                               $eMinusList($trchId,$i) \
                                               $numCodeBlk($trchId) \
                                               $numFillerBits($trchId) \
                                               $codeBlkSize($trchId) \
                                               $numTrBlk($trchId) \
	  	                               $trBlkSz($trchId) ]
}

}

###############################################################################
# CEC setup
###############################################################################

set chanId                $userId
set dpcchSlotFmt          0
set eTti                  0
set chanSelect            0x1
set cfn                   0
set tDelay                1024
set scramCodeX            0x1000000
set scramCodeY            0x1ffffff
set srchThreshold         $threshold
set nCqiTxRep             0
set cqiFbCycle            12
set compModePattern       0x7fff
set hsDpcchSymbOffset     0
set hsDpcchSubframeOffset 0

set ulCecSetup [Layer0Message_UL_CEC_DCH_DEMOD_SETUP \
                            $chanId $dpcchSlotFmt \
            	            $eTti $chanSelect $cfn $tDelay \
                            $scramCodeX $scramCodeY \
                            $srchThreshold $nCqiTxRep $cqiFbCycle \
                            $compModePattern $hsDpcchSymbOffset \
            		    $hsDpcchSubframeOffset]

###############################################################################
# CEC TFCI setup
###############################################################################

set chanId          $userId
set sfIdx           0
set cfn             0
set compModePattern 0x7fff

set ulCecTfci [Layer0Message_UL_CEC_DCH_TFCI \
              $chanId $sfIdx \
              $compModePattern]

####################################################################
# Connect to DTCS
####################################################################

set fd [DTCSConnect $host]

# DTCSMessage_SWIF_CONFIG_REQ { context
#                               interfaceId
#                               switchMode }
set schedulingInstance 0
set context     0
set interfaceId 0xd ; # Switch UL/DL schedulers to DTCS mastered
set switchMode  1
DTCSSendMessage $fd [DTCSMessage_SWIF_CONFIG_REQ $context \
                                                 $interfaceId $switchMode]
# No response message

# Stop scheduler
DTCSSendMessage $fd [DTCSMessage_UL_SCHED_STOP_REQ $context]
DiscardDTCSResponse $fd

# Delete existing scheduler instances
for { set i 0 } { $i < 10 } { incr i } {
  DTCSSendMessage $fd [DTCSMessage_UL_SCHED_DELETE_REQ $context $i]
  DiscardDTCSResponse $fd
}

# ulSymCtrl
set portNumber         0x50
set repetition         4
set frameOffset        4
set trigger            1; # 1=>TFCI
set transportChannelId $userId

for { set i 0 } { $i < 4 } { incr i } {

DTCSSendMessage $fd [DTCSMessage_UL_SCHED_SETUP_REQ $context \
                                  $schedulingInstance \
                                  $portNumber \
                                  $repetition \
			          [expr $frameOffset + $i] \
                                  $trigger \
                                  $transportChannelId \
                                  $ulSymCtrl($i)]
DiscardDTCSResponse $fd
incr schedulingInstance

}

# CEC SETUP
set portNumber         0x51
set repetition         0
set frameOffset        0
set trigger            0; # 1=>BFN
set transportChannelId $userId

DTCSSendMessage $fd [DTCSMessage_UL_SCHED_SETUP_REQ $context \
                                  $schedulingInstance \
                                  $portNumber \
                                  $repetition \
                                  $frameOffset \
                                  $trigger \
                                  $transportChannelId \
                                  $ulCecSetup]
DiscardDTCSResponse $fd
incr schedulingInstance

# CEC TFCI (10ms)
set portNumber         0x51
set repetition         1
set frameOffset        4
set trigger            1; # 1=>TFCI
set transportChannelId $userId

DTCSSendMessage $fd [DTCSMessage_UL_SCHED_SETUP_REQ $context \
                                  $schedulingInstance \
                                  $portNumber \
                                  $repetition \
                                  $frameOffset \
                                  $trigger \
                                  $transportChannelId \
                                  $ulCecTfci]
DiscardDTCSResponse $fd
incr schedulingInstance

# TrCH BER/BLER reporting
set portNumber         0x40;		# Uplink symbol rate data
set repetition         100;		# Reporting period
set frameOffset        0;		# Not used
set trigger            1;               # 1=>TFCI
set physicalChannelId  $userId;
set transportChannelId $userId;

DTCSSendMessage $fd [DTCSMessage_UL_SCHED_SETUP_REQ $context \
                                  $schedulingInstance \
                                  $portNumber \
                                  $repetition \
                                  $frameOffset \
                                  $trigger \
                                  $physicalChannelId \
                                  $transportChannelId]
DiscardDTCSResponse $fd
incr schedulingInstance

# Start scheduler
DTCSSendMessage $fd [DTCSMessage_UL_SCHED_START_REQ $context]
DiscardDTCSResponse $fd

# Disconnect from server
DTCSDisconnect $fd
