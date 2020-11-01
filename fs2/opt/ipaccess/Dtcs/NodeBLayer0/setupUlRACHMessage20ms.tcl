#!/usr/bin/tclsh

package require PC8209DTCS
package require PC82x9Layer0
package require PC82x8RfIf

namespace import ::PC8209DTCS::*
namespace import ::PC82x9Layer0::*
namespace import ::PC82x8RfIf::*

###############################################################################
# Args
###############################################################################

#  phyChId = 4 for PC302, 8 for PC312
set phyChId 4
if { [llength $argv] < 2 } {
  puts "usage: $argv0 <hostname> <prachThreshold> (<phyChId>)"
  exit
} elseif { [llength $argv] == 2 } {
  puts "Using default PhyChId = $phyChId"
} else {
  set phyChId  [lindex $argv 2]
  puts "Using  PhyChId = $phyChId"
}


set host [lindex $argv 0]
set prachThreshold [lindex $argv 1]

###############################################################################
# Open test vector files
###############################################################################

# Input/reference files
set ulSymCtrl(0)  "" ;	# 10ms (frame 0)
set ulSymCtrl(1)  "" ;	# 20ms (frame 1)
set ulSymCtrl(2)  "" ;	# 30ms (frame 2)
set ulSymCtrl(3)  "" ;	# 40ms (frame 3)
set ulPrachSetup  "" ;	# PRACH CEC setup
set ulCecTfci     "" ;	# Dynamic CEC TFCI commands

###############################################################################
# Utility functions
###############################################################################

proc logFile { msg } {

  upvar $msg k

  set fd [open "$msg.dat" w]
  foreach i $k {
    puts $fd [format %08x $i]
  }
  close $fd
}

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

for { set i 0 } { $i < 2 } { incr i } {


set physChanId      $phyChId;
set resetFlag       0
set cfn             0
#set cctrchSize      300
set spreadFactorEnum  5
set compModeGapCount  0x0
set numTrch 1

# Physical channel setup
writeMsg ulSymCtrl($i) [Layer0Message_UL_PHYSCH_CTRL $physChanId \
                                                 $resetFlag \
                                                 [expr $cfn + $i] \
                                                 $spreadFactorEnum \
                                                 $compModeGapCount \
                                                 $numTrch-1 ]


# TrCHId #0
set trchReset(0)     [expr $i==0 ? 1 : 0]
set ttiLog2(0)       $::PC82x9Layer0::TTIEnum(20MS)
set codingType(0)    $::PC82x9Layer0::CodingTypeEnum(CODING_CONV_1_2)
set crcType(0)       $::PC82x9Layer0::CRCTypeEnum(CRC_16BIT)
set rmType(0)        $::PC82x9Layer0::RMTypeEnum(CRC_REPETITION1)
set trchXiSize(0)    192
set radioEqBits(0)   0
set numCodeBlk(0)    1
set numFillerBits(0) 0
set codeBlkSize(0)   184
set numTrBlk(0)      1
set trBlkSz(0)       168
set eIniList(0,0)    [list 1   0 0]
set ePlusList(0,0)   [list 384 0 0]
set eMinusList(0,0)  [list 216 0 0]
set eIniList(0,1)    [list 1   0 0]
set ePlusList(0,1)   [list 384 0 0]
set eMinusList(0,1)  [list 216 0 0]

for { set trchId 0 } { $trchId < $numTrch } { incr trchId } {

set trchIdAct [expr $trchId + 64]

# TRCH control (frame i)
writeMsg ulSymCtrl($i) [Layer0Message_UL_TRCH_CTRL $trchIdAct $trchReset($trchId) \
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
	  	                               $trBlkSz($trchId)]
}

}

###############################################################################
# PRACH detector setup
###############################################################################

set aichDelay      0
set sigA           0;			# Detect signature 0
set threshold      $prachThreshold;    # Detection threshold (MS bits)
set scramCodeX     0x000000
set patternA       0x0;	                # Hadamard code = 0
set rachTti        $::PC82x9Layer0::TTIEnum(20MS);  # Tti = 20ms

writeMsg ulPrachSetup [Layer0Message_UL_CEC_PRACH_SETUP \
                     $aichDelay $sigA \
		     $rachTti $threshold $scramCodeX $patternA]

###############################################################################
# RACH demodulator setup
###############################################################################

#Removed from PC82x9

###############################################################################
# CEC TFCI setup
###############################################################################


set chanId          $phyChId;
set sfIdx           0;   # SLot format can't be changed.
set compModePattern 0x7fff;

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

# ulSymCtrl (20ms only)
set portNumber         0x50
set repetition         2;		# 20ms
set frameOffset      0;		# CFN = 0 (first TFCI)
set trigger            4;               # 4=>TFCI RACH
set transportChannelId $phyChId; 	# 4 for 302, 8 for 312


for { set i 0 } { $i < 2 } { incr i } {

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

# CEC TFCI (10ms)
set portNumber         0x51
set repetition         1;		# Every 10ms
set frameOffset        0;		# CFN=0 (first TFCI)
set trigger            4;               # 4=>TFCI RACH
set transportChannelId $phyChId;        # 4 for 302, 8 for 312

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

# CEC SETUP
set portNumber         0x51
set repetition         0;		# Send once
set frameOffset        0;		# Await for CFN mod 256
set trigger            0;               # 0=>BFN
set transportChannelId 0;		# Not used

DTCSSendMessage $fd [DTCSMessage_UL_SCHED_SETUP_REQ $context \
                                  $schedulingInstance \
                                  $portNumber \
                                  $repetition \
                                  $frameOffset \
                                  $trigger \
                                  $transportChannelId \
                                  $ulPrachSetup]
DiscardDTCSResponse $fd
incr schedulingInstance

# TrCH BER/BLER reporting
set portNumber         0x40;		# Uplink symbol rate data
set repetition         100;		# 100 frame period
set frameOffset        0;		# Not used
set trigger            4;               # 1=>BFN
set physicalChannelId  $phyChId;        #  4 for 302, 8 for 312
set transportChannelId 64;		# TrCHID=4

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
