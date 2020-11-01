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
set ulCecSetup    "" ;	# Static CEC setup

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

if { [llength $argv] != 1 } {
  puts "usage: $argv0 <hostname>"
  exit
}

####################################################################
# CEC delete DCH demod
####################################################################

set chanId                0
set demodAvail            0
set ulCecSetup [Layer0Message_UL_CEC_DCH_DEMOD_DELETE $chanId $demodAvail]

####################################################################
# Connect to DTCS
####################################################################

set host [lindex $argv 0]
set fd [DTCSConnect $host]

# CEC SETUP
set context            0
set schedulingInstance 8
set portNumber         0x51
set repetition         0
set frameOffset        0
set trigger            1; # 1=>TFCI
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

# Disconnect from server
DTCSDisconnect $fd
