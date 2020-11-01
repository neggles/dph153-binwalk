#!/usr/bin/tclsh

proc uhex2dec32 {hexvalue} {
   regsub -all {[^0-9a-f\.\-]} $hexvalue {} newtemp
   set hexvalue [string trim $newtemp]
   set hexvalue [string range $hexvalue [expr [string length $hexvalue]- 8] [expr [string length $hexvalue] - 1]]
   return  [format "%#u" [expr "0x$hexvalue"]] } 
   
###############################################

if { [llength $argv] < 3 } {
  puts "usage: $argv0 <host> <ebNo> <blerResultsFile>"
  exit
}

set userId 0
set host [lindex $argv 0]

if { [llength $argv] > 3 } {
 set userId [lindex $argv 3]
}

set ebNo [lindex $argv 1]
set blerResultsFile [lindex $argv 2]

exec $::env(PICO_DIR_PC82X8)/Toplevel/PC82x8/verif/performanceTests/blerFlush.tcl $host $userId

set blerLength -1
set blerFunction -1
set loop 1

while {$loop} {
  puts "loop"
  set bler [exec $::env(PICO_DIR_PC82X8)/Toplevel/PC82x8/setup/NodeBLayer0/blerReport.tcl $host $userId]
  set blerLength [llength $bler]
  puts "bler $blerLength Response $bler"
  set index 4
  puts "$bler $blerLength"
  while { $index < [expr $blerLength - 2] } { 
     set tmp [lindex $bler $index]
     set userTag [expr 0x00080100 + $userId]
     if {$tmp == $userTag} {set loop 0; break; }
     incr index
    }    
}

set Fp [open $blerResultsFile a+]
#puts $bler
incr index
set nbBlocks [lindex $bler $index]
incr index
set nbBlocksErrors [lindex $bler $index]
set nbBlocksDec [uhex2dec32 $nbBlocks]
set nbBlocksErrorsDec [uhex2dec32 $nbBlocksErrors]
puts "EbNo=$ebNo , AggregateBlocks=$nbBlocksDec , AggregateBlocksErrors=$nbBlocksErrorsDec"
puts $Fp "$ebNo $nbBlocksDec $nbBlocksErrorsDec"

close $Fp
