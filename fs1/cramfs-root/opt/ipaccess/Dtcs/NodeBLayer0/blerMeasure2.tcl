#!/usr/bin/tclsh

proc uhex2dec32 {hexvalue} {
   regsub -all {[^0-9a-f\.\-]} $hexvalue {} newtemp
   set hexvalue [string trim $newtemp]
   set hexvalue [string range $hexvalue [expr [string length $hexvalue]- 8] [expr [string length $hexvalue] - 1]]
   return  [format "%#u" [expr "0x$hexvalue"]] } 
   
###############################################

if { [llength $argv] != 1 } {
  puts "usage: $argv0 <host> "
  exit
}

set host [lindex $argv 0]

exec $::env(PICO_DIR_PC82X8)/Toplevel/PC82x8/verif/performanceTests/blerFlush.tcl $host

set blerLength -1
set blerFunction -1
set loop 1

while {$loop} {
  set bler [exec $::env(PICO_DIR_PC82X8)/Toplevel/PC82x8/setup/NodeBLayer0/blerReport.tcl $host]
  set blerLength [llength $bler]
  set index 4
  while { $index < [expr $blerLength - 2] } { 
     set tmp [lindex $bler $index]
     if {$tmp == "0x00080100"} {set loop 0; break; }
     incr index
    }    
}

incr index
set nbBlocks [lindex $bler $index]
incr index
set nbBlocksErrors    [lindex $bler $index]
set nbBlocksDec       [uhex2dec32 $nbBlocks]
set nbBlocksErrorsDec [uhex2dec32 $nbBlocksErrors]
puts "$nbBlocksDec $nbBlocksErrorsDec"

