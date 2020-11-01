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

set userId 0

if { [llength $argv] < 2 } {
  puts "usage: $argv0 <hostname> <srchThreshold> (<userId>)"
  exit
}

set host          [lindex $argv 0]
set threshold     [lindex $argv 1]

if { [llength $argv] > 2 } {
  set userId        [lindex $argv 2]
}

###############################################################################
# Open test vector files
###############################################################################

# Input/reference files
set ulSymCtrl(0)  "" ;	# 10ms (frame 0) physCh 0
set ulSymCtrl(1)  "" ;	# 20ms (frame 1) physCh 0
set ulSymCtrl(2)  "" ;	# 30ms (frame 2) physCh 0
set ulSymCtrl(3)  "" ;	# 40ms (frame 3) physCh 0


set ulCecSetup(0)    "" ;	# Static CEC setup (PhysCh 0)
set ulCecSetup(1)    "" ;	# Static CEC setup (PhysCh 1)
set ulCecSetup(2)    "" ;	# Static CEC setup (PhysCh 2)
set ulCecSetup(3)    "" ;	# Static CEC setup (PhysCh 3)

set ulCecTfci(0)     "" ;	# Dynamic CEC TFCI commands (PhysCh 0)
set ulCecTfci(1)     "" ;	# Dynamic CEC TFCI commands (PhysCh 1)
set ulCecTfci(2)     "" ;	# Dynamic CEC TFCI commands (PhysCh 2)
set ulCecTfci(3)     "" ;	# Dynamic CEC TFCI commands (PhysCh 3)

set uldpcchctrl   "";   # Same control to be sent every 10ms

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

proc DumpDTCSResponse { fd } {
  set msgLen 0
  set retryCount 100000

  while { $msgLen == 0 && $retryCount != 0 } {

    set msg [DTCSReceiveMessage $fd]
    set msgLen [llength $msg]

    if { $msgLen > 0 } {
      foreach i $msg { puts "0x[format %08x $i]" }
      set retryCount 100000
    } else {
      incr retryCount -1
    }
  }
}

proc FlushDTCSResponse { fd } {

  set msgLen 0
  set retryCount 100000

  while { $retryCount != 0 } {

    set msg [DTCSReceiveMessage $fd]
    set msgLen [llength $msg]

    if { $msgLen > 0 } {
      set retryCount 100000
    } else {
      incr retryCount -1
    }
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



###############################################################################
# Uplink symbol rate control
###############################################################################

set trchId_base_address 0
for { set i 0 } { $i < 4 } { incr i } {

set physChanId      $userId
set resetFlag       0
set cfn             4
#set cctrchSize      600
set spreadFactorEnum  4
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
set trchReset($trchId_base_address)     [expr ($i%2)==0 ? 1 : 0]
set ttiLog2($trchId_base_address)       $::PC82x9Layer0::TTIEnum(20MS)
set codingType($trchId_base_address)    $::PC82x9Layer0::CodingTypeEnum(CODING_CONV_1_3)
set crcType($trchId_base_address)       $::PC82x9Layer0::CRCTypeEnum(CRC_16BIT)
set rmType($trchId_base_address)        $::PC82x9Layer0::RMTypeEnum(CRC_REPETITION1)
set trchXiSize($trchId_base_address)    402
set radioEqBits($trchId_base_address)   0
set numCodeBlk($trchId_base_address)    1
set numFillerBits($trchId_base_address) 0
set codeBlkSize($trchId_base_address)   260
set numTrBlk($trchId_base_address)      1
set trBlkSz($trchId_base_address)       244
set eIniList($trchId_base_address,0)    [list 1   0 0]
set ePlusList($trchId_base_address,0)   [list 804 0 0]
set eMinusList($trchId_base_address,0)  [list 176 0 0]
set eIniList($trchId_base_address,1)    [list 353 0 0]
set ePlusList($trchId_base_address,1)   [list 804 0 0]
set eMinusList($trchId_base_address,1)  [list 176 0 0]
set eIniList($trchId_base_address,2)    [list 1   0 0]
set ePlusList($trchId_base_address,2)   [list 804 0 0]
set eMinusList($trchId_base_address,2)  [list 176 0 0]
set eIniList($trchId_base_address,3)    [list 353 0 0]
set ePlusList($trchId_base_address,3)   [list 804 0 0]
set eMinusList($trchId_base_address,3)  [list 176 0 0]

# TrCHId #1
set trchReset([expr $trchId_base_address + 1])     [expr $i==0 ? 1 : 0]
set ttiLog2([expr $trchId_base_address + 1])       $::PC82x9Layer0::TTIEnum(40MS)
set codingType([expr $trchId_base_address + 1])    $::PC82x9Layer0::CodingTypeEnum(CODING_CONV_1_3)
set crcType([expr $trchId_base_address + 1])       $::PC82x9Layer0::CRCTypeEnum(CRC_12BIT)
set rmType([expr $trchId_base_address + 1])        $::PC82x9Layer0::RMTypeEnum(CRC_REPETITION1)
set trchXiSize([expr $trchId_base_address + 1])    90
set radioEqBits([expr $trchId_base_address + 1])   0
set numCodeBlk([expr $trchId_base_address + 1])    1
set numFillerBits([expr $trchId_base_address + 1]) 0
set codeBlkSize([expr $trchId_base_address + 1])   112
set numTrBlk([expr $trchId_base_address + 1])      1
set trBlkSz([expr $trchId_base_address + 1])       100
set eIniList([expr $trchId_base_address + 1],0)    [list 1   0 0]
set ePlusList([expr $trchId_base_address + 1],0)   [list 180 0 0]
set eMinusList([expr $trchId_base_address + 1],0)  [list 40  0 0]
set eIniList([expr $trchId_base_address + 1],1)    [list 81  0 0]
set ePlusList([expr $trchId_base_address + 1],1)   [list 180 0 0]
set eMinusList([expr $trchId_base_address + 1],1)  [list 40  0 0]
set eIniList([expr $trchId_base_address + 1],2)    [list 41  0 0]
set ePlusList([expr $trchId_base_address + 1],2)   [list 180 0 0]
set eMinusList([expr $trchId_base_address + 1],2)  [list 40  0 0]
set eIniList([expr $trchId_base_address + 1],3)    [list 121 0 0]
set ePlusList([expr $trchId_base_address + 1],3)   [list 180 0 0]
set eMinusList([expr $trchId_base_address + 1],3)  [list 40  0 0]

for { set trchId $trchId_base_address } { $trchId < [expr $trchId_base_address + $numTrch] } { incr trchId } {

# TRCH control (frame i)
set localTrChId [expr $userId + $trchId]
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
                                               $trBlkSz($trchId)]
}



###############################################################################
# CEC setup
###############################################################################

set chanId                $physChanId
set dpcchSlotFmt          0
set eTti                  0
set chanSelect            0x9
set cfn                   4
set tDelay                1024
set scramCodeX            0x1000000
set scramCodeY            0x1ffffff
set srchThreshold         $threshold
set nCqiTxRep             0; #0;  #3;
set cqiFbCycle            1; #1;  #4;
set compModePattern       0x7fff
set hsDpcchSymbOffset     0;   #1
set hsDpcchSubframeOffset [expr ((38400 - $tDelay) / 256) / 30]

writeMsg ulCecSetup(0) [Layer0Message_UL_CEC_DCH_DEMOD_SETUP \
                            $chanId $dpcchSlotFmt \
            	            $eTti $chanSelect $cfn $tDelay \
                            $scramCodeX $scramCodeY \
                            $srchThreshold $nCqiTxRep $cqiFbCycle  \
                            $compModePattern $hsDpcchSymbOffset \
            		    $hsDpcchSubframeOffset]

###############################################################################
# CEC TFCI setup
###############################################################################

set chanId          $physChanId
set sfIdx           0
set compModePattern 0x7fff

writeMsg ulCecTfci(0) [Layer0Message_UL_CEC_DCH_TFCI \
                            $chanId $sfIdx \
                            $compModePattern]


}


###############################################################################
# UL HS_DPCCH CONTROL
###############################################################################
#set controlUlDpcch 256;  # 0x0100
#set controlUlDpcch 768;  # 0x0300
set controlUlDpcch $userId;  # 0x0000

writeMsg uldpcchctrl $controlUlDpcch

####################################################################
# Setup CEC diagnostic message
####################################################################

set ulCfgBus(0)     "" ;	# Downlink config bus messages
set ulCfgBus(1)     "" ;	# Downlink config bus messages
set ulCfgBus(2)     "" ;	# Downlink config bus messages

set antenna      0
writeMsg ulCfgBus(0) [Layer0Message_UL_GET_POWER_ESTIMATE $antenna]
writeMsg ulCfgBus(0) [Layer0Message_UL_GET_IQ_OFFSET $antenna]
writeMsg ulCfgBus(0) [Layer0Message_UL_GET_CLOSED_LOOP_GAIN $antenna]

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
set interfaceId 0xf ; # Switch UL/DL schedulers to DTCS mastered
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

# ulCfgBus
set portNumber         0x21
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
                                  $ulCfgBus(0)]
#DumpDTCSResponse $fd
DiscardDTCSResponse $fd
incr schedulingInstance


#########################################################
# FIRST PHYSICAL CHANNEL
#########################################################


# ulSymCtrl
set portNumber         0x50
set repetition         4
set frameOffset        0
set trigger            1; # 1=>TFCI
set physicalChannelId  $userId

for { set i 0 } { $i < 4 } { incr i } {

DTCSSendMessage $fd [DTCSMessage_UL_SCHED_SETUP_REQ $context \
                                  $schedulingInstance \
                                  $portNumber \
                                  $repetition \
			                            [expr $frameOffset + $i] \
                                  $trigger \
                                  $physicalChannelId \
                                  $ulSymCtrl($i)]
                                  
                                  
DiscardDTCSResponse $fd
incr schedulingInstance

}

# CEC SETUP
set portNumber         0x51
set repetition         0
set frameOffset        0
set trigger            0; # 0=>BFN
set physicalChannelId  $userId

DTCSSendMessage $fd [DTCSMessage_UL_SCHED_SETUP_REQ $context \
                                  $schedulingInstance \
                                  $portNumber \
                                  $repetition \
                                  $frameOffset \
                                  $trigger \
                                  $physicalChannelId \
                                  $ulCecSetup(0)]
DiscardDTCSResponse $fd
incr schedulingInstance

# CEC TFCI (10ms)
set portNumber         0x51
set repetition         1
set frameOffset        0
set trigger            1; # 1=>TFCI
set physicalChannelId  $userId

DTCSSendMessage $fd [DTCSMessage_UL_SCHED_SETUP_REQ $context \
                                  $schedulingInstance \
                                  $portNumber \
                                  $repetition \
                                  $frameOffset \
                                  $trigger \
                                  $physicalChannelId \
                                  $ulCecTfci(0)]
DiscardDTCSResponse $fd
incr schedulingInstance

# Ul HS-DPCCH control
set portNumber         0x13
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
                                  $uldpcchctrl]
DiscardDTCSResponse $fd
incr schedulingInstance

# TrCH BER/BLER reporting
set portNumber         0x40;   # Uplink symbol rate data
set repetition         100;    # Reporting period
set frameOffset        0;      # Not used
set trigger            1;      # 1=>TFCI
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

# TrCH BER/BLER reporting ch 1
#set portNumber         0x40;   # Uplink symbol rate data
#set repetition         100;    # Reporting period
#set frameOffset        0;      # Not used
#set trigger            1;      # 1=>TFCI
#set physicalChannelId  $physicalChannelNumber;
#set transportChannelId [expr $physicalChannelNumber*16 + 1];
#
#DTCSSendMessage $fd [DTCSMessage_UL_SCHED_SETUP_REQ $context \
#                                  $schedulingInstance \
#                                  $portNumber \
#                                  $repetition \
#                                  $frameOffset \
#                                  $trigger \
#                                  $physicalChannelId \
#                                  $transportChannelId]
#DiscardDTCSResponse $fd
#incr schedulingInstance

# HSDPCCH Ack/Nack reporting
set portNumber         0x33;   # DTCS_PORT_UL_HS_ACK
set repetition         100;      # Reporting period
set frameOffset        0;        # Not used
set trigger            0;       # 0=>BFN
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



#########################################################


# Start scheduler
DTCSSendMessage $fd [DTCSMessage_UL_SCHED_START_REQ $context]
DiscardDTCSResponse $fd

DTCSSendMessage $fd [DTCSMessage_DL_SCHED_START_REQ $context]
DiscardDTCSResponse $fd

# Disconnect from server
DTCSDisconnect $fd
