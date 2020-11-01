###############################################################################
# DTCS package for PC82x8
###############################################################################

package provide PC82x8DTCS 1.0 

namespace eval ::PC82x8DTCS {

# Socket routines

namespace export \
  DTCSConnect \
  DTCSDisconnect \
  DTCSSendMessage \
  DTCSReceiveMessage

variable DTCSPortNumber
set DTCSPortNumber 10000

proc popWord { msgBytes val } {

  upvar $msgBytes myList

  set word [lindex 0 $myList]
  set myList [lrange $myList 1 end]
  return $val
}

proc bitUnpack { val high low } {
  set numBits [expr ($high - $low + 1)]
  set mask [expr 0xFFFFFFFF >> (32-$numBits)]
  return [expr ($val>>$low) & $mask]
}

proc DTCSConnect { host } {

  variable DTCSPortNumber
  set fd [socket $host $DTCSPortNumber]
  fconfigure $fd -blocking 0 -translation binary \
                 -encoding binary -buffering none

  return $fd
}

proc DTCSDisconnect { fd } {

  close $fd

}

proc DTCSSendMessage { fd msg } {

  set msgLen [llength $msg]

  # Format as little-endian binary 32-bit integers and send
  puts -nonewline $fd [binary format I$msgLen $msg]
}

proc DTCSReceiveMessage { fd } {

  set str [read $fd]
  set strLen [string length $str]
  set msg ""

  # Binary scan received message into 32-bit integer list
  for { set i 0 } { $i < $strLen } { } {
    binary scan $str I k
    lappend msg $k
    incr i +4
    set str [string range $str 4 end]
  }

  return $msg
}

# Messaging routines
namespace export \
  DTCSMessage_DL_SCHED_SETUP_REQ \
  DTCSMessage_DL_SCHED_DELETE_REQ \
  DTCSMessage_DL_SCHED_START_REQ \
  DTCSMessage_DL_SCHED_STOP_REQ \
  DTCSMessage_UL_SCHED_SETUP_REQ \
  DTCSMessage_UL_SCHED_DELETE_REQ \
  DTCSMessage_UL_SCHED_START_REQ \
  DTCSMessage_UL_SCHED_STOP_REQ \
  DTCSMessage_DIAG_SETUP_REQ \
  DTCSMessage_DIAG_DELETE_REQ \
  DTCSMessage_DIAG_START_REQ \
  DTCSMessage_DIAG_STOP_REQ \
  DTCSMessage_SWIF_CONFIG_REQ \
  DTCSMessage_DL_SCHED_SETUP_RESP \
  DTCSMessage_DL_SCHED_DELETE_RESP \
  DTCSMessage_DL_SCHED_START_RESP \
  DTCSMessage_DL_SCHED_STOP_RESP \
  DTCSMessage_UL_SCHED_SETUP_RESP \
  DTCSMessage_UL_SCHED_DELETE_RESP \
  DTCSMessage_UL_SCHED_START_RESP \
  DTCSMessage_UL_SCHED_STOP_RESP \
  DTCSMessage_DIAG_SETUP_RESP \
  DTCSMessage_DIAG_DELETE_RESP \
  DTCSMessage_DIAG_START_RESP \
  DTCSMessage_DIAG_STOP_RESP \
  DTCSMessage_DIAG_IND \
  DTCSMessage_SWIF_CONFIG_RESP

#  The following variables fix the type values
variable DTCSMessageTypes
set   DTCSMessageTypes(DL_SCHED_SETUP_REQ)        0x0000
set   DTCSMessageTypes(DL_SCHED_SETUP_RESP)       0x0001
set   DTCSMessageTypes(DL_SCHED_DELETE_REQ)       0x0002
set   DTCSMessageTypes(DL_SCHED_DELETE_RESP)      0x0003
set   DTCSMessageTypes(DL_SCHED_START_REQ)        0x0004
set   DTCSMessageTypes(DL_SCHED_START_RESP)       0x0005
set   DTCSMessageTypes(DL_SCHED_STOP_REQ)         0x0006
set   DTCSMessageTypes(DL_SCHED_STOP_RESP)        0x0007

set   DTCSMessageTypes(UL_SCHED_SETUP_REQ)        0x0100
set   DTCSMessageTypes(UL_SCHED_SETUP_RESP)       0x0101
set   DTCSMessageTypes(UL_SCHED_DELETE_REQ)       0x0102
set   DTCSMessageTypes(UL_SCHED_DELETE_RESP)      0x0103
set   DTCSMessageTypes(UL_SCHED_START_REQ)        0x0104
set   DTCSMessageTypes(UL_SCHED_START_RESP)       0x0105
set   DTCSMessageTypes(UL_SCHED_STOP_REQ)         0x0106
set   DTCSMessageTypes(UL_SCHED_STOP_RESP)        0x0107

set   DTCSMessageTypes(DIAG_SETUP_REQ)            0x0200
set   DTCSMessageTypes(DIAG_SETUP_RESP)           0x0201
set   DTCSMessageTypes(DIAG_DELETE_REQ)           0x0202
set   DTCSMessageTypes(DIAG_DELETE_RESP)          0x0203
set   DTCSMessageTypes(DIAG_START_REQ)            0x0204
set   DTCSMessageTypes(DIAG_START_RESP)           0x0205
set   DTCSMessageTypes(DIAG_STOP_REQ)             0x0206
set   DTCSMessageTypes(DIAG_STOP_RESP)            0x0207
set   DTCSMessageTypes(DIAG_RESERVED)             0x0208
set   DTCSMessageTypes(DIAG_IND)                  0x0209

set   DTCSMessageTypes(SWIF_CONFIG_REQ)           0x0300
set   DTCSMessageTypes(SWIF_CONFIG_RESP)          0x0301

proc DTCSMessage { msgId communicationsContext msgBytes } {

  set msg $msgBytes

  # Insert communicationsContext field
  set msg "$communicationsContext $msg"

  # Overall message length (excludes first header word)
  set msgLen [expr [llength $msg] * 4]

  # Insert msgId and msgLen fields
  set msg "[expr ($msgLen & 0xFFFF) | \
                 ($msgId & 0xFFFF) << 16 ] $msg"

  return $msg
}

proc DTCSMessageResp { msgId context errorCode timeStamp msgBytes } {

  set msg "$msgBytes"

  set msg "$timeStamp $msg"
  set msg "[expr ($errorCode & 0xFFFF)] $msg"
  set msg "$context $msg"
  set msgLen [expr [llength $msg] * 4]

  set msg "[expr ($msgLen & 0xFFFF) | \
                 ($msgId & 0xFFFF) << 16] $msg"

  return $msg
}

proc DecodeDTCSMessage { msgBytes } {
}

proc DTCSMessage_DL_SCHED_SETUP_REQ { context \
                                      schedulingInstance \
                                      portNumber \
                                      repetition \
                                      frameOffset \
                                      dataGenSeed \
                                      dataGenLen \
				                              msgBytes } {

  variable DTCSMessageTypes
  set msg ""

  lappend msg [ expr ($schedulingInstance & 0xFF) | \
                     ($portNumber & 0xFF) << 8 | \
 		                 ($repetition & 0xFF) << 16 | \
                     ($frameOffset & 0xFF) << 24]

  lappend msg [ expr ($dataGenSeed & 0x1FF) | \
                     ($dataGenLen & 0x7FFFFF) << 9]

  set msgLen [ expr ([llength $msgBytes] * 4)]
  lappend msg [ expr $msgLen << 16]
  set msg [concat $msg $msgBytes]

  return [DTCSMessage $DTCSMessageTypes(DL_SCHED_SETUP_REQ) $context $msg]
}

proc DecodeDTCSMessage_DL_SCHED_SETUP_REQ { msgBytes decodedArray } {

  upvar $decodedArray decoded

  set root $decoded(root)

  set val [popWord msgBytes]
  set decoded($root.schedulingInstance) [bitUnpack $val 7 0]
  set decoded($root.portNumber) [bitUnpack $val 15 8]
  set decoded($root.repetition) [bitUnpack $val 24 16]

  set val [popWord msgBytes]
  set decoded($root.dataGenSeed) [bitUnpack $val 8 0]
  set decoded($root.dataGenLen)  [bitUnpack $val 31 9]
}

proc DTCSMessage_DL_SCHED_DELETE_REQ { context schedulingInstance } {

  variable DTCSMessageTypes
  set msg ""

  lappend msg [ expr ($schedulingInstance & 0xFF) ]

  return [DTCSMessage $DTCSMessageTypes(DL_SCHED_DELETE_REQ) $context $msg]
}

proc DTCSMessage_DL_SCHED_START_REQ { context  } {

  variable DTCSMessageTypes
  set msg ""

  return [DTCSMessage $DTCSMessageTypes(DL_SCHED_START_REQ) $context $msg]
}

proc DTCSMessage_DL_SCHED_STOP_REQ { context  } {

  variable DTCSMessageTypes
  set msg ""

  return [DTCSMessage $DTCSMessageTypes(DL_SCHED_STOP_REQ) $context $msg]
}

proc DTCSMessage_UL_SCHED_SETUP_REQ { context \
                                      schedulingInstance \
                                      portNumber \
                                      repetition \
                                      frameOffset \
                                      trigger \
                                      transportChannelId \
				                              msgBytes } {

  variable DTCSMessageTypes
  set msg ""

  lappend msg [ expr ($schedulingInstance & 0xFF) | \
                     ($portNumber & 0xFF) << 8 | \
 		     ($repetition & 0xFF) << 16 | \
 		     ($frameOffset & 0xFF) << 24]

  set msgLen [ expr ([llength $msgBytes] * 4)]

  lappend msg [ expr ($trigger & 0xFF) | \
                     ($transportChannelId & 0xFF) << 8 | \
                     ($msgLen & 0xFFFF) << 16]
  set msg [concat $msg $msgBytes]

  return [DTCSMessage $DTCSMessageTypes(UL_SCHED_SETUP_REQ) $context $msg]
}

proc DTCSMessage_UL_SCHED_DELETE_REQ { context schedulingInstance } {

  variable DTCSMessageTypes
  set msg ""

  lappend msg [ expr ($schedulingInstance & 0xFF) ]

  return [DTCSMessage $DTCSMessageTypes(UL_SCHED_DELETE_REQ) $context $msg]
}

proc DTCSMessage_UL_SCHED_START_REQ { context  } {

  variable DTCSMessageTypes
  set msg ""

  return [DTCSMessage $DTCSMessageTypes(UL_SCHED_START_REQ) $context $msg]
}

proc DTCSMessage_UL_SCHED_STOP_REQ { context  } {

  variable DTCSMessageTypes
  set msg ""

  return [DTCSMessage $DTCSMessageTypes(UL_SCHED_STOP_REQ) $context $msg]
}

proc DTCSMessage_DIAG_SETUP_REQ { context \
                                  diagInstance \
                                  diagTag \
                                  reportingPeriod } {
  variable DTCSMessageTypes
  set msg ""

  lappend msg [ expr ($diagInstance & 0xFFFF) | \
                     ($diagTag & 0xFF) << 16 | \
 		     ($reportingPeriod & 0xFF) << 24 ]

  return [DTCSMessage $DTCSMessageTypes(DIAG_SETUP_REQ) $context $msg]
}

proc DTCSMessage_DIAG_DELETE_REQ { context diagInstance diagTag } {

  variable DTCSMessageTypes
  set msg ""

  lappend msg [ expr ($diagInstance & 0xFFFF) | \
		     ($diagTag & 0xFF) << 16]

  return [DTCSMessage $DTCSMessageTypes(DIAG_DELETE_REQ) $context $msg]
}

proc DTCSMessage_DIAG_START_REQ { context  } {

  variable DTCSMessageTypes
  set msg ""

  return [DTCSMessage $DTCSMessageTypes(DIAG_START_REQ) $context $msg]
}

proc DTCSMessage_DIAG_STOP_REQ { context  } {

  variable DTCSMessageTypes
  set msg ""

  return [DTCSMessage $DTCSMessageTypes(DIAG_STOP_REQ) $context $msg]
}

proc DTCSMessage_SWIF_CONFIG_REQ { context \
                                   interfaceId \
                                   switchMode } {
  variable DTCSMessageTypes
  set msg ""

  lappend msg [ expr ($interfaceId & 0xFF) | \
                     ($switchMode & 0xFF) << 8]

  return [DTCSMessage $DTCSMessageTypes(SWIF_CONFIG_REQ) $context $msg]
}

proc DTCSMessage_DL_SCHED_SETUP_RESP { context errorCode timeStamp } {

  variable DTCSMessageTypes
  return [DTCSMessageResp $DTCSMessageTypes(DL_SCHED_SETUP_RESP) \
                          $context $errorCode $timeStamp ""]

}

proc DTCSMessage_DL_SCHED_DELETE_RESP { context errorCode timeStamp } {

  variable DTCSMessageTypes
  return [DTCSMessageResp $DTCSMessageTypes(DL_SCHED_DELETE_RESP) \
                          $context $errorCode $timeStamp ""]

}

proc DTCSMessage_DL_SCHED_START_RESP { context errorCode timeStamp } {

  variable DTCSMessageTypes
  return [DTCSMessageResp $DTCSMessageTypes(DL_SCHED_START_RESP) \
                          $context $errorCode $timeStamp ""]

}

proc DTCSMessage_DL_SCHED_STOP_RESP { context errorCode timeStamp } {

  variable DTCSMessageTypes
  return [DTCSMessageResp $DTCSMessageTypes(DL_SCHED_STOP_RESP) \
                          $context $errorCode $timeStamp ""]

}


proc DTCSMessage_UL_SCHED_SETUP_RESP { context errorCode timeStamp } {

  variable DTCSMessageTypes
  return [DTCSMessageResp $DTCSMessageTypes(UL_SCHED_SETUP_RESP) \
                          $context $errorCode $timeStamp ""]

}

proc DTCSMessage_UL_SCHED_DELETE_RESP { context errorCode timeStamp } {

  variable DTCSMessageTypes
  return [DTCSMessageResp $DTCSMessageTypes(UL_SCHED_DELETE_RESP) \
                          $context $errorCode $timeStamp ""]

}

proc DTCSMessage_UL_SCHED_START_RESP { context errorCode timeStamp } {

  variable DTCSMessageTypes
  return [DTCSMessageResp $DTCSMessageTypes(UL_SCHED_START_RESP) \
                          $context $errorCode $timeStamp ""]

}

proc DTCSMessage_UL_SCHED_STOP_RESP { context errorCode timeStamp } {

  variable DTCSMessageTypes
  return [DTCSMessageResp $DTCSMessageTypes(UL_SCHED_STOP_RESP) \
                          $context $errorCode $timeStamp ""]

}


proc DTCSMessage_DIAG_SETUP_RESP { context errorCode timeStamp } {

  variable DTCSMessageTypes
  return [DTCSMessageResp $DTCSMessageTypes(DIAG_SETUP_RESP) \
                          $context $errorCode $timeStamp ""]

}

proc DTCSMessage_DIAG_DELETE_RESP { context errorCode timeStamp } {

  variable DTCSMessageTypes
  return [DTCSMessageResp $DTCSMessageTypes(DIAG_DELETE_RESP) \
                          $context $errorCode $timeStamp ""]

}

proc DTCSMessage_DIAG_START_RESP { context errorCode timeStamp } {

  variable DTCSMessageTypes
  return [DTCSMessageResp $DTCSMessageTypes(DIAG_START_RESP) \
                          $context $errorCode $timeStamp ""]

}

proc DTCSMessage_DIAG_STOP_RESP { context errorCode timeStamp } {

  variable DTCSMessageTypes
  return [DTCSMessageResp $DTCSMessageTypes(DIAG_STOP_RESP) \
                          $context $errorCode $timeStamp ""]

}

proc DTCSMessage_DIAG_IND { context errorCode timeStamp msgBytes } {

  variable DTCSMessageTypes
  return [DTCSMessageResp $DTCSMessageTypes(DIAG_IND) \
                          $context $errorCode $timeStamp $msgBytes]

}

proc DTCSMessage_SWIF_CONFIG_RESP { context errorCode timeStamp } {

  variable DTCSMessageTypes
  return [DTCSMessageResp $DTCSMessageTypes(SWIF_CONFIG_RESP) \
                          $context $errorCode $timeStamp ""]

}

} ; # end of namespace
