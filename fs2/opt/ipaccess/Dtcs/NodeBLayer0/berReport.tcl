#!/usr/bin/tclsh

package require PC82x8DTCS
package require PC82x8Layer0

namespace import ::PC82x8DTCS::*
namespace import ::PC82x8Layer0::*

####################################################################
# Utilities
####################################################################

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
# Connect to DTCS
####################################################################

if { [llength $argv] == 0 } {
  puts "usage: $argv0 <hostname>"
  exit
}

set host [lindex $argv 0]
set fd [DTCSConnect $host]

# Stop diagnostics
set context           0
DTCSSendMessage $fd [DTCSMessage_DIAG_STOP_REQ $context]

# Discard response
DiscardDTCSResponse $fd

# Setup BLER diagnostic
set diagInstance      0;		# TrCH-ID
set diagTag           0;		# BER
set reportingPeriod   100;	# 100ms

# Send message
DTCSSendMessage $fd [DTCSMessage_DIAG_SETUP_REQ $context \
 $diagInstance \
 $diagTag \
 $reportingPeriod]

# Discard response
DiscardDTCSResponse $fd

# Start diagnostics
DTCSSendMessage $fd [DTCSMessage_DIAG_START_REQ $context]

# Discard response
DiscardDTCSResponse $fd

DumpDTCSResponse $fd

# Stop diagnostics
set context           0
DTCSSendMessage $fd [DTCSMessage_DIAG_STOP_REQ $context]

# Discard response
DiscardDTCSResponse $fd

# Send message
DTCSSendMessage $fd [DTCSMessage_DIAG_DELETE_REQ $context \
 $diagInstance \
 $diagTag]

# Discard response
DiscardDTCSResponse $fd

# Disconnect from server
DTCSDisconnect $fd
