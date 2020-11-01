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
set ulSymCtrl     "" ;	# Rel6 Sym Control
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


###############################################################################
# Uplink symbol rate control
###############################################################################
set numPhysCh               2

set userId                  0
set isNewData               1
set is2MsTti                1
set numPhysChEnum           [expr ($numPhysCh - 1)]
set numCMTimeslotGaps       0
set actualSfEnum            1
set numCodeBlocks           1
set numBitsPerCodeBlock     2730
set numCodeBlockFillerBits  0
set numBitsInTrBlock        2706
set rvIndex                 0 ; # Assume no IR


# TRCH control (frame i)
set ulSymCtrl [Layer0Message_UL_SYM_REL6_CTRL $userId \
				              $isNewData $is2MsTti \
                                              $numPhysChEnum $numCMTimeslotGaps \
                                              $actualSfEnum $numCodeBlocks \
                                              $numBitsPerCodeBlock $numCodeBlockFillerBits \
                                              $numBitsInTrBlock $rvIndex ]


###############################################################################
# CEC setup
###############################################################################

set chanId                $userId
set dpcchSlotFmt          1
set eTti                  [expr (1 - $is2MsTti)]
# JGB set chanSelect            0x6
set chanSelect            0xe
set cfn                   0
set tDelay                1024
set scramCodeX            0x1000000
set scramCodeY            0x1ffffff
set srchThreshold         $threshold
set nCqiTxRep             0
# JGB set cqiFbCycle            12
set cqiFbCycle            1
set compModePattern       0x7fff
# JGB set hsDpcchSymbOffset     0
# JGB set hsDpcchSubframeOffset 0
# JGB from setup_HsDpcch_AckNack_And_UlRMC12_2kbps.tcl
set hsDpcchSymbOffset     0;
set hsDpcchSubframeOffset [expr ((38400 - $tDelay) / 256) / 30]
#puts "hsDpcchSubframeOffset: $hsDpcchSubframeOffset"

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

set chanId          0
set sfIdx           3  ; # 3 = SF 1 i.e. no TFCI
set cfn             0
set compModePattern 0x7fff

set ulCecTfci [Layer0Message_UL_CEC_DCH_TFCI \
              $chanId $sfIdx \
              $compModePattern]

###############################################################################
# UL HS_DPCCH CONTROL
###############################################################################
#set controlUlDpcch 256;  # 0x0100
#set controlUlDpcch 768;  # 0x0300
set controlUlDpcch 0  
set uldpcchctrl   "";   # Same control to be sent every 10ms JGB????

writeMsg uldpcchctrl $controlUlDpcch

set ulCfgBus(0)     "" ;	# Downlink config bus messages

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
for { set i 0 } { $i < 10 } { incr i } {
  DTCSSendMessage $fd [DTCSMessage_UL_SCHED_DELETE_REQ $context $i]
  DiscardDTCSResponse $fd
}


#####
#####
#####
#####
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
#####
#####
#####
#####



# ulRel6SymCtrl
set portNumber         0x53
set repetition         1  ; # Rep 1 is 2ms for Rel6 Sym Ctrl
set frameOffset        4
set trigger            3; # 3=>E TFCI
set transportChannelId 0

DTCSSendMessage $fd [DTCSMessage_UL_SCHED_SETUP_REQ $context \
                                  $schedulingInstance \
                                  $portNumber \
                                  $repetition \
			          [expr $frameOffset + $i] \
                                  $trigger \
                                  $transportChannelId \
                                  $ulSymCtrl]
DiscardDTCSResponse $fd
incr schedulingInstance


# CEC SETUP
set portNumber         0x51
set repetition         0
set frameOffset        0
set trigger            0; # 1=>BFN
set transportChannelId 0

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
set transportChannelId 0

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

#####
#####
#####
#####
#####
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
#####
#####
#####
#####

# TrCH BER/BLER reporting
set portNumber         0x43;		# Uplink symbol rate data 2ms E
set repetition         100;		# Reporting period
set frameOffset        0;		# Not used
set trigger            1;               # 1=>TFCI
set physicalChannelId  0;
set transportChannelId 0;

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

# HSDPCCH Ack/Nack reporting
# copied from ...Ack_Nack...12.2
set portNumber         0x33;   # DTCS_PORT_UL_HS_ACK
set repetition         100;      # Reporting period
set frameOffset        0;        # Not used
set trigger            0;       # 0=>BFN
set physicalChannelId  0;
set transportChannelId 0;

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

DTCSSendMessage $fd [DTCSMessage_DL_SCHED_START_REQ $context]
DiscardDTCSResponse $fd

# Disconnect from server
DTCSDisconnect $fd
