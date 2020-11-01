#!/usr/bin/tclsh

package require PC82x8RfIf

namespace import ::PC82x8RfIf::*

set fd [RFConnect dvk24]
# RFConfigAll { fd rfPort txGain rxGain txFreq rxFreq octalDacList }
RFConfigPort $fd 2 73 67 2140000000 1950000000 [list 150 129 101 128]
RFConfigPort $fd 1 81 64 2140000000 1950000000 [list 149 128 103 128]
RFDisconnect $fd
