namespace eval ::vexpect {}

proc vexpect::timedout {} {
append vexpect::ret "Timed out looking for [lindex $vexpect::script $vexpect::scrindex]\n"
set vexpect::exit 1
}

proc vexpect::check {t} {
append vexpect::ret $t
if {$vexpect::scrindex < 0} return
set vexpect::bufferred "$vexpect::bufferred$t"
if [regexp [lindex $vexpect::script $vexpect::scrindex] $vexpect::bufferred] {
after cancel $vexpect::afid
incr vexpect::scrindex
vexpect::send [lindex $vexpect::script $vexpect::scrindex]
set vexpect::bufferred ""
incr vexpect::scrindex
if {[lindex $vexpect::script $vexpect::scrindex] == "interact"} {
set vexpect::scrindex -1
} else {
set vexpect::afid [after $vexpect::timeout vexpect::timedout]
}
}
}
proc vexpect::cr {} {
global vexpect::f vexpect::started vexpect::debug vexpect::exit
set t [read $vexpect::f]
if [eof $vexpect::f] {set vexpect::exit 1}
if {$started} {
vexpect::check $t
} else {
binary scan $t c* a
if {$debug} {
puts "Deciphering: $a"
}
set idx 0
while {$idx < [llength $a]} {
if {[lindex $a $idx] == -1} {
if {$debug} {
puts "got -1"
}
incr idx
switch -- [lindex $a $idx] {
-2 - 
-3 - 
-4 - 
-5 {
set ope [lindex $a $idx]
if {$debug} {
puts " got $ope"
}
incr idx
set opt [lindex $a $idx]
if {$debug} {
puts " for $opt"
}
if {$ope == -3} {
if {$debug} {
puts "Vexpect::Send reject at index $idx"
}
puts -nonewline $vexpect::f [binary format ccc -1 -4 $opt]
flush $vexpect::f
}
}
-6 - 
-7 - 
-8 - 
-9 - 
-10 - 
-11 - 
-12 -
-13 - 
-14 - 
-15 - 
-16 {
if {$debug} {
puts " got [lindex $a $idx]"
}
}
}
incr idx
} else {
if {$debug} {
puts "Starting with $idx = [lindex $a $idx]"
}
set t [binary format c* [lrange $a $idx end]]
vexpect::check $t
set vexpect::started 1
break
}
}
}
}
proc vexpect::send {text} {
if [catch { puts -nonewline $vexpect::f $text; flush $vexpect::f}] {
set vexpect::exit 1
}
return 1
}
proc vexpect {host scr} {
set vexpect::script $scr
set vexpect::started 0
set vexpect::debug 0
set vexpect::bufferred ""
set vexpect::scrindex 0
set vexpect::timeout 30000
set vexpect::ret ""
set port 23
if {[llength $host] == 2} {
set port [lindex $host 1]
}
set vexpect::f [socket [lindex $host 0] $port]
fconfigure $vexpect::f -blocking false -buffering line -translation binary
fileevent $vexpect::f readable { vexpect::cr }
set vexpect::afid [after $vexpect::timeout vexpect::timedout]
set vexpect::exit 0
vwait vexpect::exit
catch {close $vexpect::f}
return $::vexpect::ret
}
proc bgerror {message} {
global errorInfo errorCode
puts stderr "$message\n$errorInfo\n$errorCode"
}
set mtu 1492
if { $argc > 0 } {
	set mtu [lindex $argv 0]
}
set script [list "gin:" "guest\r\n" "word:" "1qaz@WSX\r\n" "$" "a=`cs_client get wan/0/mtu`\r\n" "$" "test \"$mtu\" = \"\$a\" || ( cs_client set wan/0/mtu $mtu ; cs_client commit ; ipc_client 192.168.157.185 reset )\r\n" "$" "exit\r\n"]
set response [vexpect [list 192.168.157.185 23] $script]
puts got=$response
