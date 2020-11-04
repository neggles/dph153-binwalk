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
set numPhysCh               1

set userId                  0
set isNewData               1
set is2MsTti                0
set numPhysChEnum           [expr ($numPhysCh - 1)]
set numCMTimeslotGaps       0
set actualSfEnum            1
set numCodeBlocks           1
set numBitsPerCodeBlock     5100
set numCodeBlockFillerBits  0
set numBitsInTrBlock        5076
set rvIndex                 0 ;# Assume no IR 0


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
set chanSelect            0x2
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

set chanId          0
set sfIdx           3;  # 3 = SF 1 i.e. no TFCI
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

# ulRel6SymCtrl
set portNumber         0x53
set repetition         5 ; # Rep 5 is every 10ms for Rel6 Sym Ctrl
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

# Start scheduler
DTCSSendMessage $fd [DTCSMessage_UL_SCHED_START_REQ $context]
DiscardDTCSResponse $fd

# Disconnect from server
DTCSDisconnect $fd
