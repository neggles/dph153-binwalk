#!/usr/bin/tclsh

package require PC82x8RfIf

namespace import ::PC82x8RfIf::*

set fd [RFConnect hdp27]
# RFConfigAll { fd txGain rxGain txFreq rxFreq octalDacList }
RFConfigAll $fd 73 86 2140000000 1950000000 [list 153 128 102 121]
RFDisconnect $fd
