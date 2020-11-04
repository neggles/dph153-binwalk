#!/usr/bin/tclsh

if { [llength $argv] < 1 } {
  puts "usage: $argv0 <host>"
  exit
}

set host [lindex $argv 0]
set userId 0
if { [llength $argv] > 1 } {
  set userId [lindex $argv 1]
}

set count 0
set bler -1

while {($bler!="") && ($count<2)} {

  set bler [exec $::env(PICO_DIR_PC82X8)/Toplevel/PC82x9/setup/NodeBLayer0/blerReport_Rach.tcl $host $userId]
  puts "bler flush $bler"
  after 10
  incr count
}

