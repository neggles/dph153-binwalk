###############################################################################
# Radio interface for PC82x8
###############################################################################

package provide PC82x8RfIf 1.0

namespace eval ::PC82x8RfIf {

#  The following variables fix the type values
variable CmdEnum
set   CmdEnum(RIC_SET)   "ricSet"
set   CmdEnum(TX_GAIN)   "TXGain"
set   CmdEnum(RX_GAIN)   "RXGain"
set   CmdEnum(TX_FREQ)   "TXFreq"
set   CmdEnum(RX_FREQ)   "RXFreq"
set   CmdEnum(OCTAL_DAC) "OctalDAC"
set   CmdEnum(ADDR)      "Add"
set   CmdEnum(SYNTH)     "ClkSynth"
set   CmdEnum(PA_ON)     "PAOn"

variable RfIfPortNumber
set RfIfPortNumber 8080

namespace export \
  RFConnect \
  RFDisconnect \
  RFConfigAll \
  RFConfigPort \
  RFConfigSingle

proc RFConnect { host } {

  variable RfIfPortNumber
  return [socket $host $RfIfPortNumber]
}

proc RFDisconnect { fd } {
  close $fd
}

proc RFConfigPort { fd portNum txGain rxGain txFreq rxFreq octalDacList } {

  variable CmdEnum

  # Set RIC address
  puts $fd "$CmdEnum(ADDR)=$portNum"

  # Open RIC channel
  puts $fd "$CmdEnum(RIC_SET)=$portNum,6,1"

  # Set TX Gain
  puts $fd "$CmdEnum(TX_GAIN)=$txGain"

  # Set RX Gain
  puts $fd "$CmdEnum(RX_GAIN)=$rxGain"

  # Set TX Frequency
  puts $fd "$CmdEnum(TX_FREQ)=$txFreq"

  # Set RX Frequency
  puts $fd "$CmdEnum(RX_FREQ)=$rxFreq"

  # Set Octal DAC
  set c 1
  foreach i $octalDacList {
    puts $fd "$CmdEnum(OCTAL_DAC)=$i,$c"
    incr c +1
  }

  # Enable synth and turn on PA
  puts $fd "$CmdEnum(SYNTH)"
  puts $fd "$CmdEnum(PA_ON)=1"

  # Close RIC channel
  puts $fd "$CmdEnum(RIC_SET)=$portNum,0,0"
  puts $fd "$CmdEnum(RIC_SET)=$portNum,4,1"
  puts $fd "$CmdEnum(RIC_SET)=$portNum,6,0"
}

proc RFConfigAll { fd txGain rxGain txFreq rxFreq octalDacList } {
  return [RFConfigPort $fd 7 $txGain $rxGain $txFreq $rxFreq $octalDacList]
}

proc RFConfigSingle { fd rfPort txGain rxGain txFreq rxFreq octalDacList } {
  return [RFConfigPort $fd $rfPort $txGain $rxGain $txFreq $rxFreq \
                       $octalDacList]
}


} ; # end of namespace
