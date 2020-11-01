###############################################################################
# Various Utils for NWL control
###############################################################################

package provide NWL_CTRL_UTILS 1.0

namespace eval ::NWL_CTRL_UTILS {

namespace export \
  ReceiveDaisyChainResponse \
  NWLPeakAnalysis \
  NWLFrequencyCorrection \
  find_maximum

#  DTCSDisconnect \
#  DTCSSendMessage \
#  DTCSReceiveMessage \
#  DumpDTCSResponse

proc ReceiveDaisyChainResponse { fd } {

set msgComplete 0
set msgArray    ""
set msgLen      0

while { ($msgComplete == 0) } {

                # Receive a response
                set msg [DumpDTCSResponse $fd]

                # Append the current response to a buffer
                for {set i 0} {$i < [llength $msg]} {incr i 1} {				
                        lappend msgArray [format "0x%08x" [lindex $msg $i]]
#			puts [format "0x%08x" [lindex $msg $i]]
                }

                # check if the header contains 0x0209xxxx
                for {set i 0} {$i < [llength $msgArray]} {incr i 1} {

                        if { [expr [lindex $msgArray $i] & 0xFFFF0000] == 0x02090000 } {
                                set     payLoadLen      [expr [lindex $msgArray $i] & 0x0000FFFF]
                                set     msgLen          [expr ([expr ($payLoadLen >> 2)] + 5)]
                        }
                }

                if { $msgLen == [llength $msgArray] } {
                        set     msgComplete     1
                }
}

set response	""
for {set i 0} {$i < [llength $msgArray]} {incr i 1} {
	if { ([lindex $msgArray $i] == 0x00047000) || ([lindex $msgArray $i] == 0x00041000) } {
		set response [concat $response [lindex $msgArray [expr $i+1]]]
	}
}

return $response

}

# procedure for analyzing Psch output
proc NWLPeakAnalysis { psch_op } {

set counter             0
set num_peaks           0
set MAX_NUM_PEAKS       25
set peaks               ""
set pwrs 		""
set fr_errors           ""
set x			""
upvar psch_op psch_output

while { $counter < [llength $psch_output] } {

	if { ([lindex $psch_output $counter] == 0x00083900) & ([lindex $psch_output [expr ($counter+1)]] != 0x00083900) & ([lindex $psch_output [expr ($counter+2)]] != 0xFFFF0000) } {

                set num_peaks [expr ($num_peaks + 1)]

                lappend peaks 		[expr ( [lindex $psch_output [expr ($counter+1)]] >> 16   )]

		lappend pwrs  		[expr ( [lindex $psch_output [expr ($counter+1)]] & 0xFFFF)]

                set     cfo             [expr ( [lindex $psch_output [expr ($counter+2)]] & 0xFFFF)]

		# Convert to signed numbers
 		if { $cfo > 32767 } {
                        set     cfo     [expr ($cfo - 65536)]
                }

		# Convert to Hz
		set cfo [expr (100 * $cfo)]

                lappend fr_errors	$cfo

        }

        set counter [expr ($counter + 1)]

}

set x [concat $pwrs $peaks $fr_errors]

return $x

}


# procedure for correcting carrier frequency error
proc NWLFrequencyCorrection { host_addr error } {

set fr_error       10000
set MAX_FREQ_ERROR 2000
set fr_adj         $error

set op [exec ./BbfeFreqComp.tcl $host_addr [expr ( $fr_adj & 0x0000FFFF)]]

# Continue until frequency offset compensation loop converges
while { abs($fr_error) > $MAX_FREQ_ERROR } {
        # Flush out the Psch buffer
	set psch_op [exec ./PschDetectSetup.tcl $host_addr]
	set psch_op [exec ./PschDetectSetup.tcl $host_addr]

	set x [NWLPeakAnalysis $psch_op]
	set len [llength $x]
	set len [expr $len / 3]

	if { $len == 0 } {
		puts "No Peaks found by Psch. Exiting ...."
		exit
	}

	set idx [find_maximum $x]

	# Now try to close the frequency offset compensation loop
	# Find the freq error corresponding to the strongest peak
	set fr_error [lindex $x [expr ($idx + [expr ($len * 2)])]]

	set fr_error [expr (1 * $fr_error)]

	set fr_adj [expr ($fr_error + $fr_adj)]

	puts [format "residual frequency error = %d Hz ...\n" $fr_error]

	if { abs($fr_adj) > $MAX_FREQ_ERROR } { 
	        set op [exec ./BbfeFreqComp.tcl $host_addr $fr_adj]

		puts "Applying frequency adjustment\n"
	}
} 

puts "Exiting Carrier Frequency Offset Removal Loop ...\n"

return $fr_adj

}

# procedure for finding the maximum value index.
# returns the index of the maximum value in an input array

proc find_maximum { input } {

set max_value 	0
set max_val_idx	0
set counter	0
set array_len   [llength $input]
set array_len   [expr ($array_len / 3)]

while { $counter < $array_len } {

	if { [lindex $input $counter] > $max_value} {
		set max_value 	[lindex $input $counter]
		set max_val_idx	$counter
	}
	set counter [expr ($counter + 1)]
}

return $max_val_idx
}


}
