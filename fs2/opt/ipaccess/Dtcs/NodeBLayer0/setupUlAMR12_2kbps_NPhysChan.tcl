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

if { [llength $argv] != 2 } {
  puts "usage: $argv0 <hostname> <srchThreshold>"
  exit
}

set host          [lindex $argv 0]
set threshold     [lindex $argv 1]

###############################################################################
# Open test vector files
###############################################################################

# Input/reference files
set ulSymCtrl(0)  "" ;	# 10ms (frame 0) physCh 0
set ulSymCtrl(1)  "" ;	# 20ms (frame 1) physCh 0
set ulSymCtrl(2)  "" ;	# 30ms (frame 2) physCh 0
set ulSymCtrl(3)  "" ;	# 40ms (frame 3) physCh 0
set ulSymCtrl(4)  "" ;	# 10ms (frame 0) physCh 1
set ulSymCtrl(5)  "" ;	# 20ms (frame 1) physCh 1
set ulSymCtrl(6)  "" ;	# 30ms (frame 2) physCh 1
set ulSymCtrl(7)  "" ;	# 40ms (frame 3) physCh 1
set ulSymCtrl(8)  "" ;	# 10ms (frame 0) physCh 2
set ulSymCtrl(9)  "" ;	# 20ms (frame 1) physCh 2
set ulSymCtrl(10)  "" ;	# 30ms (frame 2) physCh 2
set ulSymCtrl(11)  "" ;	# 40ms (frame 3) physCh 2
set ulSymCtrl(12)  "" ;	# 10ms (frame 0) physCh 3
set ulSymCtrl(13)  "" ;	# 20ms (frame 1) physCh 3
set ulSymCtrl(14)  "" ;	# 30ms (frame 2) physCh 3
set ulSymCtrl(15)  "" ;	# 40ms (frame 3) physCh 3

set ulCecSetup(0)    "" ;	# Static CEC setup (PhysCh 0)
set ulCecSetup(1)    "" ;	# Static CEC setup (PhysCh 1)
set ulCecSetup(2)    "" ;	# Static CEC setup (PhysCh 2)
set ulCecSetup(3)    "" ;	# Static CEC setup (PhysCh 3)

set ulCecTfci(0)     "" ;	# Dynamic CEC TFCI commands (PhysCh 0)
set ulCecTfci(1)     "" ;	# Dynamic CEC TFCI commands (PhysCh 1)
set ulCecTfci(2)     "" ;	# Dynamic CEC TFCI commands (PhysCh 2)
set ulCecTfci(3)     "" ;	# Dynamic CEC TFCI commands (PhysCh 3)

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
###############################################################################
## TOTAL NUM CHANNELS
set totalNumPhysicalChannels 1

puts "Start 12.2kbps test with $totalNumPhysicalChannels physical channels"

for { set physicalChannelNumber 0 } { $physicalChannelNumber < $totalNumPhysicalChannels} { incr physicalChannelNumber } {

###############################################################################
# Uplink symbol rate control
###############################################################################

set trchId_base_address [expr $physicalChannelNumber*16]
for { set i 0 } { $i < 4 } { incr i } {

set physChanId        $physicalChannelNumber
set resetFlag         0
set cfn               [expr 4+4*$physicalChannelNumber]
#set cctrchSize        600
set spreadFactorEnum  4
set compModeGapCount  0x0
set numTrch 4

# Physical channel setup
writeMsg ulSymCtrl([expr $i + 4*$physChanId]) [Layer0Message_UL_PHYSCH_CTRL $physChanId \
                                                 $resetFlag \
                                                 [expr $cfn + $i] \
                                                 $spreadFactorEnum \
                                                 $compModeGapCount \
                                                 $numTrch-1 ]

# TrCHId #0
set trchReset($trchId_base_address)     [expr ($i%2)==0 ? 1 : 0]
set ttiLog2($trchId_base_address)       $::PC82x9Layer0::TTIEnum(20MS)
set codingType($trchId_base_address)    $::PC82x9Layer0::CodingTypeEnum(CODING_CONV_1_3)
set crcType($trchId_base_address)       $::PC82x9Layer0::CRCTypeEnum(CRC_12BIT)
set rmType($trchId_base_address)        $::PC82x9Layer0::RMTypeEnum(CRC_REPETITION1)
set trchXiSize($trchId_base_address)    152
set radioEqBits($trchId_base_address)   1
set numCodeBlk($trchId_base_address)    1
set numFillerBits($trchId_base_address) 0
set codeBlkSize($trchId_base_address)   93
set numTrBlk($trchId_base_address)      1
set trBlkSz($trchId_base_address)       81
set eIniList($trchId_base_address,0)    [list 1   0 0]
set ePlusList($trchId_base_address,0)   [list 304 0 0]
set eMinusList($trchId_base_address,0)  [list 64  0 0]

set eIniList($trchId_base_address,1)    [list 129 0 0]
set ePlusList($trchId_base_address,1)   [list 304 0 0]
set eMinusList($trchId_base_address,1)  [list 64  0 0]

set eIniList($trchId_base_address,2)    [list 1   0 0]
set ePlusList($trchId_base_address,2)   [list 304 0 0]
set eMinusList($trchId_base_address,2)  [list 64  0 0]
					              
set eIniList($trchId_base_address,3)    [list 129 0 0]
set ePlusList($trchId_base_address,3)   [list 304 0 0]
set eMinusList($trchId_base_address,3)  [list 64  0 0]

# TrCHId #1
set trchReset([expr $trchId_base_address + 1])     [expr $i==0 ? 1 : 0]
set ttiLog2([expr $trchId_base_address + 1])       $::PC82x9Layer0::TTIEnum(20MS)
set codingType([expr $trchId_base_address + 1])    $::PC82x9Layer0::CodingTypeEnum(CODING_CONV_1_3)
set crcType([expr $trchId_base_address + 1])       $::PC82x9Layer0::CRCTypeEnum(CRC_NONE)
set rmType([expr $trchId_base_address + 1])        $::PC82x9Layer0::RMTypeEnum(CRC_REPETITION1)
set trchXiSize([expr $trchId_base_address + 1])    167
set radioEqBits([expr $trchId_base_address + 1])   1
set numCodeBlk([expr $trchId_base_address + 1])    1
set numFillerBits([expr $trchId_base_address + 1]) 0
set codeBlkSize([expr $trchId_base_address + 1])   103
set numTrBlk([expr $trchId_base_address + 1])      1
set trBlkSz([expr $trchId_base_address + 1])       103
set eIniList([expr $trchId_base_address + 1],0)    [list 1   0 0]
set ePlusList([expr $trchId_base_address + 1],0)   [list 334 0 0]
set eMinusList([expr $trchId_base_address + 1],0)  [list 52  0 0]

set eIniList([expr $trchId_base_address + 1],1)    [list 157 0 0]
set ePlusList([expr $trchId_base_address + 1],1)   [list 334 0 0]
set eMinusList([expr $trchId_base_address + 1],1)  [list 52  0 0]

set eIniList([expr $trchId_base_address + 1],2)    [list 1   0 0]
set ePlusList([expr $trchId_base_address + 1],2)   [list 334 0 0]
set eMinusList([expr $trchId_base_address + 1],2)  [list 52  0 0]
						                 
set eIniList([expr $trchId_base_address + 1],3)    [list 157 0 0]
set ePlusList([expr $trchId_base_address + 1],3)   [list 334 0 0]
set eMinusList([expr $trchId_base_address + 1],3)  [list 52  0 0]

# TrCHId #2
set trchReset([expr $trchId_base_address + 2])     [expr ($i%2)==0 ? 1 : 0]
set ttiLog2([expr $trchId_base_address + 2])       $::PC82x9Layer0::TTIEnum(20MS)
set codingType([expr $trchId_base_address + 2])    $::PC82x9Layer0::CodingTypeEnum(CODING_CONV_1_2)
set crcType([expr $trchId_base_address + 2])       $::PC82x9Layer0::CRCTypeEnum(CRC_NONE)
set rmType([expr $trchId_base_address + 2])        $::PC82x9Layer0::RMTypeEnum(CRC_REPETITION1)
set trchXiSize([expr $trchId_base_address + 2])    68
set radioEqBits([expr $trchId_base_address + 2])   0
set numCodeBlk([expr $trchId_base_address + 2])    1
set numFillerBits([expr $trchId_base_address + 2]) 0
set codeBlkSize([expr $trchId_base_address + 2])   60
set numTrBlk([expr $trchId_base_address + 2])      1
set trBlkSz([expr $trchId_base_address + 2])       60
set eIniList([expr $trchId_base_address + 2],0)    [list 1   0 0]
set ePlusList([expr $trchId_base_address + 2],0)   [list 136 0 0]
set eMinusList([expr $trchId_base_address + 2],0)  [list 58  0 0]

set eIniList([expr $trchId_base_address + 2],1)    [list 59  0 0]
set ePlusList([expr $trchId_base_address + 2],1)   [list 136 0 0]
set eMinusList([expr $trchId_base_address + 2],1)  [list 58  0 0]

set eIniList([expr $trchId_base_address + 2],2)    [list 1   0 0]
set ePlusList([expr $trchId_base_address + 2],2)   [list 136 0 0]
set eMinusList([expr $trchId_base_address + 2],2)  [list 58  0 0]
						                 
set eIniList([expr $trchId_base_address + 2],3)    [list 59  0 0]
set ePlusList([expr $trchId_base_address + 2],3)   [list 136 0 0]
set eMinusList([expr $trchId_base_address + 2],3)  [list 58  0 0]

# TrCHId #3
set trchReset([expr $trchId_base_address + 3])     [expr $i==0 ? 1 : 0]
set ttiLog2([expr $trchId_base_address + 3])       $::PC82x9Layer0::TTIEnum(40MS)
set codingType([expr $trchId_base_address + 3])    $::PC82x9Layer0::CodingTypeEnum(CODING_CONV_1_3)
set crcType([expr $trchId_base_address + 3])       $::PC82x9Layer0::CRCTypeEnum(CRC_16BIT)
set rmType([expr $trchId_base_address + 3])        $::PC82x9Layer0::RMTypeEnum(CRC_CONV_PUNCTURE)
set trchXiSize([expr $trchId_base_address + 3])    129
set radioEqBits([expr $trchId_base_address + 3])   0
set numCodeBlk([expr $trchId_base_address + 3])    1
set numFillerBits([expr $trchId_base_address + 3]) 0
set codeBlkSize([expr $trchId_base_address + 3])   164
set numTrBlk([expr $trchId_base_address + 3])      1
set trBlkSz([expr $trchId_base_address + 3])       148
set eIniList([expr $trchId_base_address + 3],0)    [list 1   0 0]
set ePlusList([expr $trchId_base_address + 3],0)   [list 258 0 0]
set eMinusList([expr $trchId_base_address + 3],0)  [list 6   0 0]

set eIniList([expr $trchId_base_address + 3],1)    [list 127 0 0]
set ePlusList([expr $trchId_base_address + 3],1)   [list 258 0 0]
set eMinusList([expr $trchId_base_address + 3],1)  [list 6   0 0]

set eIniList([expr $trchId_base_address + 3],2)    [list 193 0 0]
set ePlusList([expr $trchId_base_address + 3],2)   [list 258 0 0]
set eMinusList([expr $trchId_base_address + 3],2)  [list 6   0 0]

set eIniList([expr $trchId_base_address + 3],3)    [list 61  0 0]
set ePlusList([expr $trchId_base_address + 3],3)   [list 258 0 0]
set eMinusList([expr $trchId_base_address + 3],3)  [list 6   0 0]

for { set trchId $trchId_base_address } { $trchId < [expr $trchId_base_address + $numTrch] } { incr trchId } {

# TRCH control (frame i)
writeMsg ulSymCtrl([expr $i + 4*$physChanId]) [Layer0Message_UL_TRCH_CTRL $trchId $trchReset($trchId) \
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

set chanId                $physChanId
set dpcchSlotFmt          0
set eTti                  0
set chanSelect            0x1
set cfn                   0; #[expr 4*$physicalChannelNumber]
set tDelay                1024
set scramCodeX            0x1000000
set scramCodeY            0x1ffffff
set srchThreshold         $threshold
set nCqiTxRep             0
set cqiFbCycle            12
set compModePattern       0x7fff
set hsDpcchSymbOffset     0
set hsDpcchSubframeOffset 0

writeMsg ulCecSetup($chanId) [Layer0Message_UL_CEC_DCH_DEMOD_SETUP \
                            $chanId $dpcchSlotFmt \
            	            $eTti $chanSelect $cfn $tDelay \
                            $scramCodeX $scramCodeY \
                            $srchThreshold $nCqiTxRep $cqiFbCycle \
                            $compModePattern $hsDpcchSymbOffset \
            		    $hsDpcchSubframeOffset]

###############################################################################
# CEC TFCI setup
###############################################################################

set chanId          $physChanId
set sfIdx           0
set compModePattern 0x7fff

writeMsg ulCecTfci($chanId) [Layer0Message_UL_CEC_DCH_TFCI \
                            $chanId $sfIdx \
                            $compModePattern]


}

###############################################################################
# RUN SCRIPT
###############################################################################
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
for { set i 0 } { $i < 35 } { incr i } {
  DTCSSendMessage $fd [DTCSMessage_UL_SCHED_DELETE_REQ $context $i]
  DiscardDTCSResponse $fd
}


#########################################################
# FIRST PHYSICAL CHANNEL
#########################################################

for { set physicalChannelNumber 0 } { $physicalChannelNumber < $totalNumPhysicalChannels} { incr physicalChannelNumber } {

# ulSymCtrl
set portNumber         0x50
set repetition         4
set frameOffset        [expr 4+4*$physicalChannelNumber]
set trigger            1; # 1=>TFCI
set physicalChannelId  $physicalChannelNumber

for { set i 0 } { $i < 4 } { incr i } {

DTCSSendMessage $fd [DTCSMessage_UL_SCHED_SETUP_REQ $context \
                                  $schedulingInstance \
                                  $portNumber \
                                  $repetition \
                                  [expr $frameOffset + $i] \
                                  $trigger \
                                  $physicalChannelId \
                                  $ulSymCtrl([expr $i + 4*$physicalChannelId])]
                                  
                                  
DiscardDTCSResponse $fd
incr schedulingInstance

}

# CEC SETUP
set portNumber         0x51
set repetition         0
set frameOffset        [expr 4*$physicalChannelNumber]
set trigger            0; # 1=>BFN
set physicalChannelId  $physicalChannelNumber

DTCSSendMessage $fd [DTCSMessage_UL_SCHED_SETUP_REQ $context \
                                  $schedulingInstance \
                                  $portNumber \
                                  $repetition \
                                  $frameOffset \
                                  $trigger \
                                  $physicalChannelId \
                                  $ulCecSetup($physicalChannelId)]
DiscardDTCSResponse $fd
incr schedulingInstance

# CEC TFCI (10ms)
set portNumber         0x51
set repetition         1
set frameOffset        [expr 4+4*$physicalChannelNumber]
set trigger            1; # 1=>TFCI
set physicalChannelId  $physicalChannelNumber

DTCSSendMessage $fd [DTCSMessage_UL_SCHED_SETUP_REQ $context \
                                  $schedulingInstance \
                                  $portNumber \
                                  $repetition \
                                  $frameOffset \
                                  $trigger \
                                  $physicalChannelId \
                                  $ulCecTfci($physicalChannelId)]
DiscardDTCSResponse $fd
incr schedulingInstance

# TrCH BER/BLER reporting
set portNumber         0x40;   # Uplink symbol rate data
set repetition         100;    # Reporting period
set frameOffset        0;      # Not used
set trigger            1;      # 1=>TFCI
set physicalChannelId  $physicalChannelNumber;
set transportChannelId [expr $physicalChannelNumber*16];

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

# TrCH BER/BLER reporting ch 1
set portNumber         0x40;   # Uplink symbol rate data
set repetition         100;    # Reporting period
set frameOffset        0;      # Not used
set trigger            1;      # 1=>TFCI
set physicalChannelId  $physicalChannelNumber;
set transportChannelId [expr $physicalChannelNumber*16 + 1];

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

}


#########################################################


# Start scheduler
DTCSSendMessage $fd [DTCSMessage_UL_SCHED_START_REQ $context]
DiscardDTCSResponse $fd

# Disconnect from server
DTCSDisconnect $fd
