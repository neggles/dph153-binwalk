#!/usr/bin/tclsh

package require Tcl 8.4
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
set dlCfgReqIn    ""
set trch20ms      ""
set physCh        ""
set dlCommonIn    ""

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

proc scaleByDb { dB maxGain } {
  return [expr int(0.5 + pow(10.0,($dB/20.0)) * $maxGain/4)]
}

###############################################################################
# Vector generation / parameters
###############################################################################

# Individual channels
set Armsmax     8191 ; # 2^14-1 (allowing for 12dB back-off from full-scale)
set cpichGain   [scaleByDb -10 $Armsmax]

# Summation gains
set unityGain   [expr pow(2,17)]
set outputGain  [expr int(0.5 + $unityGain)]
set cmnGain     [expr int(0.5 + $unityGain)]
set dchGain     [expr int(0.5 + $unityGain)]
set hsScchGain  [expr int(0.5 + $unityGain)]
set hsDschGain  [expr int(0.5 + $unityGain/(sqrt(20)))]

# Scrambling code group 0 as 'N-1'
set sscSlots    [list 0 0 1 7 8 9 14 7 9 15 1 6 14 6 15]

# Configure gain stage
writeMsg dlCommonIn [Layer0Message_DL_DCH_GAIN_SETUP $dchGain ]
writeMsg dlCommonIn [Layer0Message_DL_COMMON_GAIN_SETUP $cmnGain ]
writeMsg dlCommonIn [Layer0Message_DL_HSSCCH_GAIN_SETUP $hsScchGain ]
writeMsg dlCommonIn [Layer0Message_DL_HSDSCH_GAIN_SETUP $hsDschGain ]
writeMsg dlCommonIn [Layer0Message_DL_OUTPUT_GAIN_SETUP $outputGain ]

# Configure scrambling code generators
set xfsr        1 ;       # Scrambling code 0 (Group 0)
writeMsg dlCommonIn [Layer0Message_DL_SCRAM_CODE_SETUP $xfsr \
                      $::PC82x8Layer0::DlScramCodeGenEnum(DCH0) ]
writeMsg dlCommonIn [Layer0Message_DL_SCRAM_CODE_SETUP $xfsr \
                      $::PC82x8Layer0::DlScramCodeGenEnum(DCH1) ]
writeMsg dlCommonIn [Layer0Message_DL_SCRAM_CODE_SETUP $xfsr \
                      $::PC82x8Layer0::DlScramCodeGenEnum(DCH2) ]
writeMsg dlCommonIn [Layer0Message_DL_SCRAM_CODE_SETUP $xfsr \
                      $::PC82x8Layer0::DlScramCodeGenEnum(DCH3) ]
writeMsg dlCommonIn [Layer0Message_DL_SCRAM_CODE_SETUP $xfsr \
                      $::PC82x8Layer0::DlScramCodeGenEnum(HSDPA0) ]
writeMsg dlCommonIn [Layer0Message_DL_SCRAM_CODE_SETUP $xfsr \
                      $::PC82x8Layer0::DlScramCodeGenEnum(HSDPA1) ]
writeMsg dlCommonIn [Layer0Message_DL_SCRAM_CODE_SETUP $xfsr \
                      $::PC82x8Layer0::DlScramCodeGenEnum(COMMON0) ]
writeMsg dlCommonIn [Layer0Message_DL_SCRAM_CODE_SETUP $xfsr \
                      $::PC82x8Layer0::DlScramCodeGenEnum(COMMON1) ]

# Enable P-CPICH
writeMsg dlCommonIn [Layer0Message_DL_PCPICH_SETUP $cpichGain 0]

####################################################################
# Power measurements
####################################################################

set dlPwrCalc     "" ;	# Downlink config bus messages

set log2Period 2; # 40ms
writeMsg dlPwrCalc [Layer0Message_DL_MEAN_POWER_READ $log2Period]
writeMsg dlPwrCalc [Layer0Message_DL_PEAK_POWER_READ]

####################################################################
# Connect to DTCS
####################################################################

if { [llength $argv] != 1 } {
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

# dlCommonIn
set schedulingInstance 0
set portNumber         0x03
set repetition         0
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
                                  $dlCommonIn]
DiscardDTCSResponse $fd

# dlCfgReqIn
incr schedulingInstance +1
set portNumber         0x20
set repetition         0
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
                                  $dlCfgReqIn]
DiscardDTCSResponse $fd

# dlPwrCalc
incr schedulingInstance +1
set portNumber         0x20
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
                                  $dlPwrCalc]
DiscardDTCSResponse $fd

# Start scheduler
DTCSSendMessage $fd [DTCSMessage_DL_SCHED_START_REQ $context]
DiscardDTCSResponse $fd

# Disconnect from server
DTCSDisconnect $fd
