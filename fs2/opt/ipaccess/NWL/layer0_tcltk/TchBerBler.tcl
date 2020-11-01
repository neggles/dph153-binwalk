#!/usr/bin/tclsh

# NWL_DTCS package contains calls to various DTCS functions. Present in NWL_DTCS.tcl
package require NWL_DTCS
namespace import ::NWL_DTCS::*

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

proc DisplayDTCSResponse { fd } {
  set msgLen 0
  while { $msgLen == 0 } {
    set msg [DTCSReceiveMessage $fd]
    set msgLen [llength $msg]
  }
  puts $msg
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


proc FileDTCSResponse { fd  fp} {
  set msgLen 0
  while { $msgLen == 0 } {
    set msg [DTCSReceiveMessage $fd]
    set msgLen [llength $msg]
  }

  set outerHeader [lrange $msg 0 3]

  set payloadLen [lindex $outerHeader 0]

  set payloadLen [expr (($payloadLen & 0xFFFF)>>2)] 

  set msgId [lindex $outerHeader 0]

  set msgId [expr ($msgId>>16)]


  puts ""

  puts -nonewline "msgId = "

  puts -nonewline [format "%#x" $msgId]

  puts ""

  puts -nonewline "payload length = "

  puts -nonewline $payloadLen

  puts ""


#   set msg "[expr ($errorCode & 0xFFFF)] $msg"
#   set msg "[expr ($msgLen & 0xFFFF) | ($msgId & 0xFFFF) << 16] $msg"

  set innerHeader [lrange $msg 4 5]

  set diagInstance [lindex $innerHeader 0]
  set diagInstance 5

  set diagInstance [expr ($diagInstance & 0xFFFF)]

  puts -nonewline "diagInstance = "

  puts -nonewline [format "%#x" $diagInstance] 

  puts ""


  set diagTag [lindex $innerHeader 0]
  set diagTag 5

  set diagTag [expr ($diagTag)]

  puts -nonewline "diagTag = "

  puts -nonewline [format "%#x" $diagTag] 

  puts ""


  set bodyLength [lindex $innerHeader 0]

  set bodyLength [expr ($bodyLength >> 24)]  

  puts -nonewline "bodyLength = "

  puts -nonewline [format "%#x" $bodyLength] 

  puts ""


  set body [lrange $msg 6 $msgLen]

  foreach i $outerHeader { puts "0x[format %08x $i]" }

  foreach i $innerHeader { puts "0x[format %08x $i]" }

  foreach i $body { puts $fp "0x[format %08x $i]" }

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

set diagType PC82x8Layer0::NwlDiagTypeEnum(HS_DIAG)



####################################################################
# Connect to DTCS
####################################################################

if { [llength $argv] == 0 } {
  puts "usage: $argv0 <hostname>"
  exit
}

set host [lindex $argv 0]
set fd [DTCSConnect $host]
####################################################################
# Configure the switch for DTCS control
####################################################################
#DTCSMessage_SWIF_CONFIG_REQ {  context
#                               interfaceId
#                               switchMode }

set delay 0

set context     0
set interfaceId 0x8
set switchMode  1

DTCSSendMessage $fd [DTCSMessage_SWIF_CONFIG_REQ $context \
                                                 $interfaceId $switchMode] 
#DumpDTCSResponse $fd

###################################################################
# Kill all existing diag tasks
###################################################################
# Stop scheduler

DTCSSendMessage $fd [DTCSMessage_DLRX_DIAG_STOP_REQ $context]

DumpDTCSResponse $fd

###################################################################
# Set-up a task in the diagnostic block to receive all responses 
###################################################################
# Setup new scheduler instances
#set diagInstance       0
#set diagTag            [lindex $argv 1]	
#set reportingPeriod    40	

# Stop scheduler
DTCSSendMessage $fd [DTCSMessage_DLRX_SCHED_STOP_REQ $context]
DiscardDTCSResponse $fd

# Delete existing scheduler instances
for { set i 0 } { $i < 10 } { incr i } {
  DTCSSendMessage $fd [DTCSMessage_DLRX_SCHED_DELETE_REQ $context $i]
  DiscardDTCSResponse $fd
}

set schedulingInstance 0

# TrCH BER/BLER reporting
set portNumber         0x00;     # Downlink viterbi symbol rate data 
set repetition         100;	     # Reporting period
set frameOffset        0;	     # Not used 
set trigger            0 ;       # 1=>TFCI <?? need to understand this> 
set transportChannelId 3;        #  
set msgBytes 0    

DTCSSendMessage $fd [DTCSMessage_DLRX_SCHED_SETUP_REQ $context \
                                  $schedulingInstance \
                                  $portNumber \
                                  $repetition \
                                  $frameOffset \
                                  $trigger \
                                  $transportChannelId \
                                  $msgBytes  ]
DiscardDTCSResponse $fd
incr schedulingInstance

# Start scheduler
DTCSSendMessage $fd [DTCSMessage_DLRX_SCHED_START_REQ $context]
DiscardDTCSResponse $fd

# Disconnect from server
DTCSDisconnect $fd



























