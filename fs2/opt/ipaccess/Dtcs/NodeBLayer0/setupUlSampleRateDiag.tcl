#!/usr/bin/tclsh

package require PC82x8DTCS
package require PC82x8Layer0

namespace import ::PC82x8DTCS::*
namespace import ::PC82x8Layer0::*

####################################################################
# Utilities
####################################################################

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

####################################################################
# Connect to DTCS
####################################################################

if { [llength $argv] == 0 } {
  puts "usage: $argv0 <hostname>"
  exit
}

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

# ulCfgBus
set schedulingInstance 0
set portNumber         0x21
set repetition         10
set dataGenSeed        0
set dataGenLen         0
DTCSSendMessage $fd [DTCSMessage_DL_SCHED_SETUP_REQ $context \
                                  $schedulingInstance \
                                  $portNumber \
                                  $repetition \
                                  0 \
                                  $dataGenSeed \
                                  $dataGenLen \
                                  $ulCfgBus(0)]
DumpDTCSResponse $fd
incr schedulingInstance

# Start scheduler
DTCSSendMessage $fd [DTCSMessage_DL_SCHED_START_REQ $context]
DumpDTCSResponse $fd

# Disconnect from server
DTCSDisconnect $fd
