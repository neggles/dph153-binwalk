###############################################################################
# Layer0 package for PC82x9
###############################################################################

package provide PC82x9Layer0 1.0

namespace eval ::PC82x9Layer0 {

proc popWord { msgBytes val } {

  upvar $msgBytes myList
  upvar $val v

  set v [lindex $myList 0]
  set myList [lrange $myList 1 end]
}

proc bitPack { dst src high low } {
  set numBits [expr ($high - $low + 1)]
  set mask [expr 0xFFFFFFFF >> (32-$numBits)]
  return [expr $dst | (($src & $mask) << $low)]
}

proc bitUnpack { val high low } {
  set numBits [expr ($high - $low + 1)]
  set mask [expr 0xFFFFFFFF >> (32-$numBits)]
  return [expr ($val>>$low) & $mask]
}

proc PrintDecodeArray {printPayload arrayName {fid stdout} } {
  upvar $arrayName arr
  set sortedIndex [lsort [array names arr]]
  foreach indexName $sortedIndex {
    if {$indexName != "root"} {
      if {$printPayload==0} {
        if {[regexp "\.payload$" $indexName match]==0} {
	    puts $fid "$indexName -> 0x[format %x $arr($indexName)]"
        }
      } else {
	  puts $fid "$indexName -> 0x[format %x $arr($indexName)]"
      }
    }
  }
}

proc PushIndex {decodedArray item} {
  upvar $decodedArray decoded

  if [info exists decoded(root)] {
     set decoded(root) "$decoded(root).$item"
  } else {
     set decoded(root) ".$item"
  }
}

proc PopIndex {decodedArray} {
  upvar $decodedArray decoded

  regexp {(.*)\.(.*)} $decoded(root) match root leaf
  set decoded(root) $root
}

###############################################################################
# dlCommonParamsIn
###############################################################################

namespace export \
  Layer0Message_DL_PCPICH_SETUP \
  Layer0Message_DL_SCPICH_SETUP \
  Layer0Message_DL_PSCH_SETUP \
  Layer0Message_DL_SSCH_SETUP \
  Layer0Message_DL_SSC_SLOT_SETUP \
  Layer0Message_DL_AICH_SETUP \
  Layer0Message_DL_PICH_SETUP \
  Layer0Message_DL_PI_BITMAP_SEND \
  Layer0Message_DL_SCRAM_CODE_SETUP \
  Layer0Message_DL_DCH_GAIN_SETUP \
  Layer0Message_DL_COMMON_GAIN_SETUP \
  Layer0Message_DL_HSSCCH_GAIN_SETUP \
  Layer0Message_DL_HSDSCH_GAIN_SETUP \
  Layer0Message_DL_OUTPUT_GAIN_SETUP \
  PrintDecodeArray

variable DlCommonParamCmd
set   DlCommonParamCmd(PICH_SETUP0)         0x00
set   DlCommonParamCmd(PICH_SETUP1)         0x01
set   DlCommonParamCmd(PI_BITMAP15_0)       0x02
set   DlCommonParamCmd(PI_BITMAP31_16)      0x03
set   DlCommonParamCmd(PI_BITMAP47_32)      0x04
set   DlCommonParamCmd(PI_BITMAP63_48)      0x05
set   DlCommonParamCmd(PI_BITMAP79_64)      0x06
set   DlCommonParamCmd(PI_BITMAP95_80)      0x07
set   DlCommonParamCmd(PI_BITMAP111_96)     0x08
set   DlCommonParamCmd(PI_BITMAP127_112)    0x09
set   DlCommonParamCmd(PI_BITMAP143_128)    0x0A
set   DlCommonParamCmd(CLIPPING_THRESHOLD)  0x0B
set   DlCommonParamCmd(SPARE1)              0x0C
set   DlCommonParamCmd(SPARE2)              0x0D
set   DlCommonParamCmd(SPARE3)              0x0E
set   DlCommonParamCmd(SPARE4)              0x0F

set   DlCommonParamCmd(PCPICH_SETUP)        0x01
set   DlCommonParamCmd(SCPICH_SETUP)        0x02
set   DlCommonParamCmd(PSCH_SETUP)          0x03
set   DlCommonParamCmd(SSCH_SETUP)          0x04
set   DlCommonParamCmd(SSC_SLOT3_0)         0x05
set   DlCommonParamCmd(SSC_SLOT7_5)         0x06
set   DlCommonParamCmd(SSC_SLOT11_8)        0x07
set   DlCommonParamCmd(SSC_SLOT14_12)       0x08
set   DlCommonParamCmd(SCRAM_GEN_SETUP)     0x09
set   DlCommonParamCmd(DCH_GAIN)            0x0A
set   DlCommonParamCmd(COMMON_GAIN)         0x0B
set   DlCommonParamCmd(HSSCCH_GAIN)         0x0C
set   DlCommonParamCmd(HSDSCH_GAIN)         0x0D
set   DlCommonParamCmd(OUTPUT_GAIN)         0x0E
set   DlCommonParamCmd(AICH_SETUP)          0x0F

proc Layer0Message_DL_PCPICH_SETUP { gain diversity } {

  variable DlCommonParamCmd

  set val [bitPack 0 $gain 15 0]
  set val [bitPack $val $diversity 25 25]
  set val [bitPack $val $DlCommonParamCmd(PCPICH_SETUP) 31 28]

  return $val
}

proc DecodeLayer0Message_DL_PCPICH_SETUP { msgBytes decodedArray } {
}

proc Layer0Message_DL_SCPICH_SETUP { gain ovsf codeSel diversity } {

  variable DlCommonParamCmd

  set val [bitPack 0 $gain 15 0]
  set val [bitPack $val $ovsf 23 16]
  set val [bitPack $val $codeSel 24 24]
  set val [bitPack $val $diversity 25 25]
  set val [bitPack $val $DlCommonParamCmd(SCPICH_SETUP) 31 28]

  return $val
}

proc Layer0Message_DL_PSCH_SETUP { gain tstdSel } {

  variable DlCommonParamCmd

  set val [bitPack 0 $gain 15 0]
  set val [bitPack $val $tstdSel 26 26]
  set val [bitPack $val $DlCommonParamCmd(PSCH_SETUP) 31 28]

  return $val
}

proc Layer0Message_DL_SSCH_SETUP { gain tstdSel } {

  variable DlCommonParamCmd

  set val [bitPack 0 $gain 15 0]
  set val [bitPack $val $tstdSel 26 26]
  set val [bitPack $val $DlCommonParamCmd(SSCH_SETUP) 31 28]

  return $val
}

proc Layer0Message_DL_SSC_SLOT_SETUP { sscList } {

  variable DlCommonParamCmd
  set cmd $DlCommonParamCmd(SSC_SLOT3_0)
  set msg ""

  set idx 0
  for { set i 0 } { $i < 3 } { incr i } {

    set val [bitPack 0    [lindex $sscList [expr $idx+0]] 3 0]
    set val [bitPack $val [lindex $sscList [expr $idx+1]] 7 4]
    set val [bitPack $val [lindex $sscList [expr $idx+2]] 11 8]
    set val [bitPack $val [lindex $sscList [expr $idx+3]] 15 12]
    set val [bitPack $val $cmd 31 28]
    lappend msg $val

    set cmd [expr $cmd + 1]
    set idx [expr $idx + 4]
  }

  set val [bitPack 0    [lindex $sscList [expr $idx+0]] 3 0]
  set val [bitPack $val [lindex $sscList [expr $idx+1]] 7 4]
  set val [bitPack $val [lindex $sscList [expr $idx+2]] 11 8]
  set val [bitPack $val $cmd 31 28]
  lappend msg $val

  return $msg
}

proc Layer0Message_DL_AICH_SETUP { gain ovsf diversity } {

  variable DlCommonParamCmd

  set val [bitPack 0 $gain 15 0]
  set val [bitPack $val $ovsf 23 16]
  set val [bitPack $val $diversity 25 25]
  set val [bitPack $val $DlCommonParamCmd(AICH_SETUP) 31 28]

  return $val
}

proc Layer0Message_DL_PICH_SETUP { gain numPi sfnOffset diversity ovsf } {

  variable DlCommonParamCmd
  set msg ""

  set val [bitPack 0 $gain 15 0]
  set val [bitPack $val $numPi 23 16]
  set val [bitPack $val $DlCommonParamCmd(PICH_SETUP0) 31 24]
  lappend msg $val

  set val [bitPack 0 $sfnOffset 7 0]
  set val [bitPack $val $diversity 8 8]
  set val [bitPack $val $ovsf 23 16]
  set val [bitPack $val $DlCommonParamCmd(PICH_SETUP1) 31 24]
  lappend msg $val

  return $msg
}

proc Layer0Message_DL_PI_BITMAP_SEND { piBitmapList } {

  variable DlCommonParamCmd
  set cmd $DlCommonParamCmd(PI_BITMAP15_0)
  set msg ""

  set bitmap 0
  for { set i 0 } { $i < 144 } { incr i } {

    if { [expr $i % 16] } {
      # Subsequent PIs in bitmap
      set bitmap [expr $bitmap | [lindex $piBitmapList $i] << ($i % 16)]
    } else {
      # First PI of bitmap resets
      set bitmap [expr [lindex $piBitmapList $i] << ($i % 16)]
    }

    # Last PI of bitmap?
    if { [expr $i % 16] == 15 } {
      set val [bitPack 0 $bitmap 15 0]
      set val [bitPack $val $cmd 31 24]
      lappend msg $val
      incr cmd +1
    }
  }

  # Pack last bitmap into message
  set val [bitPack 0 $bitmap 15 0]
  set val [bitPack $val $cmd 31 24]
  lappend msg $val

  return $msg
}

proc Layer0Message_DL_SCRAM_CODE_SETUP { xfsr codeId } {

  variable DlCommonParamCmd

  set val [bitPack 0 $xfsr 17 0]
  set val [bitPack $val $codeId 27 24]
  set val [bitPack $val $DlCommonParamCmd(SCRAM_GEN_SETUP) 31 28]

  return $val
}

proc Layer0Message_DL_DCH_GAIN_SETUP { gain } {

  variable DlCommonParamCmd

  set val [bitPack 0 $gain 27 0]
  set val [bitPack $val $DlCommonParamCmd(DCH_GAIN) 31 28]

  return $val
}

proc Layer0Message_DL_COMMON_GAIN_SETUP { gain } {

  variable DlCommonParamCmd

  set val [bitPack 0 $gain 27 0]
  set val [bitPack $val $DlCommonParamCmd(COMMON_GAIN) 31 28]

  return $val
}

proc Layer0Message_DL_HSSCCH_GAIN_SETUP { gain } {

  variable DlCommonParamCmd

  set val [bitPack 0 $gain 27 0]
  set val [bitPack $val $DlCommonParamCmd(HSSCCH_GAIN) 31 28]

  return $val
}

proc Layer0Message_DL_HSDSCH_GAIN_SETUP { gain } {

  variable DlCommonParamCmd

  set val [bitPack 0 $gain 27 0]
  set val [bitPack $val $DlCommonParamCmd(HSDSCH_GAIN) 31 28]

  return $val
}

proc Layer0Message_DL_OUTPUT_GAIN_SETUP { gain } {

  variable DlCommonParamCmd

  set val [bitPack 0 $gain 27 0]
  set val [bitPack $val $DlCommonParamCmd(OUTPUT_GAIN) 31 28]

  return $val
}

###############################################################################
# dlFrameParamsIn
###############################################################################

variable DlFrameChanTypeEnum
set   DlFrameChanTypeEnum(DPCH)          0x00
set   DlFrameChanTypeEnum(DSCH)          0x01
set   DlFrameChanTypeEnum(PCCPCH)        0x02
set   DlFrameChanTypeEnum(SCCPCH)        0x03

variable SlotFormatModeEnum
set   SlotFormatModeEnum(NORMAL)         0x00
set   SlotFormatModeEnum(A)              0x01
set   SlotFormatModeEnum(B)              0x02

variable CompModeStructEnum
set   CompModeStructEnum(NO_TPC)             0x00
set   CompModeStructEnum(TPC_FIRST_TIMESLOT) 0x01

variable TTIEnum
set   TTIEnum(10MS)             0x00
set   TTIEnum(20MS)             0x01
set   TTIEnum(40MS)             0x02
set   TTIEnum(80MS)             0x03

variable DlScramCodeGenEnum
set DlScramCodeGenEnum(DCH0)        0x00
set DlScramCodeGenEnum(DCH1)        0x01
set DlScramCodeGenEnum(DCH2)        0x02
set DlScramCodeGenEnum(DCH3)        0x03
set DlScramCodeGenEnum(HSDPA0)      0x04
set DlScramCodeGenEnum(HSDPA1)      0x05
set DlScramCodeGenEnum(COMMON0)     0x06
set DlScramCodeGenEnum(COMMON1)     0x07

namespace export \
  DecodeLayer0Message_DL_FRAME_CTRL \
  Layer0Message_DL_FRAME_CTRL \
  DlFrameChanTypeEnum \
  SlotFormatModeEnum \
  CompModeStructEnum \
  TTIEnum

proc Layer0Message_DL_FRAME_CTRL { physChanId \
                                   tfciPres bypass2ndLevel chipOffset \
                                   physChanSz dtxSize dschSwitch dtxSwitch \
                                   tfciField1 slotFormatMode slotFormatIdx \
                                   chanType lastFrameFlag cfn multiCodeInd \
                                   compModeStruct firstSlotTg lastSlotTg \
                                   ovsf scramCodeSel trchIdList ttiList  } {
  variable DlCommonParamCmd
  set numPhysChan 1
  set numTrch [llength $trchIdList]
  set msg ""

  # General parameters
  set val [bitPack 0 $physChanId 5 0]
  set val [bitPack $val $numPhysChan 9 6]
  set val [bitPack $val $numTrch 15 10]
  set val [bitPack $val $tfciPres 16 16]
  set val [bitPack $val $bypass2ndLevel 17 17]
  set val [bitPack $val $chipOffset 31 24]
  lappend msg $val

  # Physical channe size
  set val [bitPack 0 $physChanSz 15 0]
  set val [bitPack $val $dtxSize 31 16]
  lappend msg $val

  # TFCI (if present)
  if { $tfciPres } {

    set val [bitPack 0 $dschSwitch 1 0]
    set val [bitPack $val $dtxSwitch 3 2]
    set val [bitPack $val $tfciField1 13 4]
    lappend msg $val
  }

  # Slot format
  set val [bitPack 0 $slotFormatMode 1 0]
  set val [bitPack $val $slotFormatIdx 6 2]
  set val [bitPack $val $chanType 11 8]
  set val [bitPack $val $lastFrameFlag 12 12]
  set val [bitPack $val $cfn 23 16]
  set val [bitPack $val $multiCodeInd 31 31]
  lappend msg $val
  
  # Compressed mode
  set val [bitPack 0 $compModeStruct 0 0]
  set val [bitPack $val $firstSlotTg 11 8]
  set val [bitPack $val $lastSlotTg 15 12]
  lappend msg $val

  # Code information
  set val [bitPack 0 $ovsf 8 0]
  set val [bitPack $val $scramCodeSel 15 14]
  lappend msg $val

  # TrCH information
  for { set i 0 } { $i < $numTrch } { incr i } {

    # Check for odd/even index
    if { [expr $i & 1] == 0  } {
      # Reset on even index
      set val [bitPack 0 [lindex $trchIdList $i] 10 0]
      set val [bitPack $val [lindex $ttiList $i] 15 14]
    } else {
      # Append with odd index
      set val [bitPack $val [lindex $trchIdList $i] 26 16]
      set val [bitPack $val [lindex $ttiList $i] 31 30]
      lappend msg $val
    }
  }

  # Odd number of TrCHs?
  if { [expr $numTrch & 1] } {
    # Append last TrCH
    lappend msg $val
  }

  return $msg
}


proc DecodeLayer0Message_DL_FRAME_CTRL { msgBytes decodedArray } {

  upvar $decodedArray decoded
  upvar $msgBytes msg
  set val ""

  set i 0
  while {[llength $msg] != 0 } {

    PushIndex decoded "PHYSCH\[$i\]"
    set root $decoded(root)

    popWord msg val
    set decoded($root.physChanId)     [bitUnpack $val 5 0]
    set decoded($root.numPhysChan)    [bitUnpack $val 9 6]
    set decoded($root.numTrch)        [bitUnpack $val 15 10]
    set decoded($root.tfciPres)       [bitUnpack $val 16 16]
    set decoded($root.bypass2ndLevel) [bitUnpack $val 17 17]
    set decoded($root.chipOffset)     [bitUnpack $val 31 24]

    popWord msg val
    set decoded($root.physChanSz)     [bitUnpack $val 15 0]
    set decoded($root.dtxSize)        [bitUnpack $val 31 16]

    if { $decoded($root.tfciPres) } {
      popWord msg val
      set decoded($root.dschSwitch)     [bitUnpack $val 1 0]
      set decoded($root.dtxSwitch)      [bitUnpack $val 3 2]
      set decoded($root.tfciField1)     [bitUnpack $val 13 4]
    }

    popWord msg val
    set decoded($root.slotFormatMode)   [bitUnpack $val 1 0]
    set decoded($root.slotFormatIdx)    [bitUnpack $val 6 2]
    set decoded($root.chanType)         [bitUnpack $val 11 8]
    set decoded($root.lastFrameFlag)    [bitUnpack $val 12 12]
    set decoded($root.cfn)              [bitUnpack $val 23 16]
    set decoded($root.multiCodeInd)     [bitUnpack $val 31 31]

    popWord msg val
    set decoded($root.compModeStruct)  [bitUnpack $val 0 0]
    set decoded($root.firstSlotTg)     [bitUnpack $val 11 8]
    set decoded($root.lastSlotTg)      [bitUnpack $val 15 12]

    popWord msg val
    set decoded($root.ovsf)            [bitUnpack $val 8 0]
    set decoded($root.scramCodeSel)    [bitUnpack $val 15 14]

    set numTrch $decoded($root.numTrch)
    for { set k 0 } { $k < $numTrch } { incr k } {

      PushIndex decoded "TRCH\[$k\]"
      set root $decoded(root)

      if { [expr $k & 1] == 0 } {
        popWord msg val
        set decoded($root.trchId)       [bitUnpack $val 10 0]
        set decoded($root.ttiLog2)      [bitUnpack $val 15 14]
      } else {
        set decoded($root.trchId)       [bitUnpack $val 26 16]
        set decoded($root.ttiLog2)      [bitUnpack $val 31 30]
      }

      PopIndex decoded
    }

    PopIndex decoded
    incr i
  }
}

###############################################################################
# dlTtiParamsData
###############################################################################

variable CodingTypeEnum
set   CodingTypeEnum(CODING_NONE)         0x00
set   CodingTypeEnum(CODING_CONV_1_2)     0x01
set   CodingTypeEnum(CODING_CONV_1_3)     0x02
set   CodingTypeEnum(CODING_TURBO_1_3)    0x03

variable CRCTypeEnum
set   CRCTypeEnum(CRC_NONE)         0x00
set   CRCTypeEnum(CRC_8BIT)         0x01
set   CRCTypeEnum(CRC_12BIT)        0x02
set   CRCTypeEnum(CRC_16BIT)        0x03
set   CRCTypeEnum(CRC_24BIT)        0x04

variable RMTypeEnum
set   RMTypeEnum(CRC_REPETITION0)    0x00
set   RMTypeEnum(CRC_REPETITION1)    0x01
set   RMTypeEnum(CRC_CONV_PUNCTURE)  0x02
set   RMTypeEnum(CRC_TURBO_PUNCTURE) 0x03

namespace export \
  DecodeLayer0Message_DL_TTI_CTRL \
  Layer0Message_DL_TTI_CTRL \
  CodingTypeEnum \
  CRCTypeEnum \
  RMTypeEnum \
  Layer0Message_DL_HSDSCH_PARAMS \
  Layer0Message_DL_HSSCCH_PARAMS

proc Layer0Message_DL_TTI_CTRL { trchId tti codingType crcType rmType cfn \
                                 trBlkSz numCodeBlk numFillerBits codeBlkSz \
                                 deltaN dtxBits1stLevel pBitList eIniList \
                                 ePlusList eMinusList numTrBlk trchByteList } {

  set msg ""

  # TrCH parameters
  set val [bitPack 0 $trchId 10 0]
  set val [bitPack $val $tti 13 12]
  set val [bitPack $val $codingType 15 14]
  set val [bitPack $val $crcType 18 16]
  set val [bitPack $val $rmType 20 19]
  set val [bitPack $val $cfn 31 24]
  lappend msg $val

  # TrBlk parameters
  set val [bitPack 0 $numTrBlk 15 0]
  set val [bitPack $val $trBlkSz 31 16]
  lappend msg $val

  # Coding parameters
  set val [bitPack 0 $numCodeBlk 7 0]
  set val [bitPack $val $numFillerBits 15 8]
  set val [bitPack $val $codeBlkSz 31 16]
  lappend msg $val
  
  # Ratematching parameters
  set val [bitPack 0 $deltaN 31 0]
  lappend msg $val

  # DTX parameters
  set val [bitPack 0 $dtxBits1stLevel 31 0]
  lappend msg $val

  # P-bit parameters
  for { set i 0 } { $i < [llength $pBitList] } { incr i } {

    # Even P-bit parameter
    if { ($i & 1) == 0 } {
      # Reset value
      set val [bitPack 0 [lindex $pBitList $i] 15 0]
    } else {
      # Append value
      set val [bitPack $val [lindex $pBitList $i] 15 0]
      lappend msg $val
    }    
  }

  # Check for odd number of P-bits (10ms)
  if { [llength $pBitList] & 1 } {
    lappend msg $val
  }

  # Handle E-params
  for { set i 0 } { $i < 3 } { incr i } {
    set val [bitPack 0 [lindex $eIniList $i] 17 0]
    lappend msg $val
    set val [bitPack 0 [lindex $ePlusList $i] 17 0]
    lappend msg $val
    set val [bitPack 0 [lindex $eMinusList $i] 17 0]
    lappend msg $val
  }

  if { [llength $trchByteList] > 0 } {

    set trBlkSzRnd [expr ((($trBlkSz+7)>>3)<<3)]

    # Send TrBlk data (bytes are assumed to be MSB first)
    set bytePos 0
    set bitPos 32
    for { set i 0 } { $i < $numTrBlk } { incr i } {

      for { set j 0 } { $j < $trBlkSzRnd } { incr j +8 } {

        if { [expr ($bitPos % 32)] == 0 } {
 	  set val [bitPack 0 [lindex $trchByteList $bytePos] \
		     [expr $bitPos-1] [expr $bitPos-8]]
        } else {
	  set val [bitPack $val [lindex $trchByteList $bytePos] \
		     [expr $bitPos-1] [expr $bitPos-8]]
	}

        incr bitPos -8
        incr bytePos

        if { [expr ($bitPos % 32)] == 0 } {
          set bitPos 32
          lappend msg $val
        }
    }

    # Handle non 32-bit aligned last trBlk
    if { [expr ($bitPos % 32)] != 0 } {
      lappend msg $val
    }
  }
}

  return $msg
}

proc DecodeLayer0Message_DL_TTI_CTRL { msgBytes decodedArray } {

  upvar $decodedArray decoded
  upvar $msgBytes msg
  set val ""

  set i 0
  while {[llength $msg] != 0 } {

    PushIndex decoded "TRCH\[$i\]"
    set root $decoded(root)

    popWord msg val
    set decoded($root.trchId)          [bitUnpack $val 10 0]
    set decoded($root.ttiLog2)         [bitUnpack $val 13 12]
    set decoded($root.codingType)      [bitUnpack $val 15 14]
    set decoded($root.crcType)         [bitUnpack $val 18 16]
    set decoded($root.rmType)          [bitUnpack $val 20 19]
    set decoded($root.cfn)             [bitUnpack $val 31 24]

    popWord msg val
    set decoded($root.numTrBlk)        [bitUnpack $val 15 0]
    set decoded($root.trBlkSz)         [bitUnpack $val 31 16]

    popWord msg val
    set decoded($root.numCodeBlk)      [bitUnpack $val 7 0]
    set decoded($root.numFillerBits)   [bitUnpack $val 15 8]
    set decoded($root.codeBlkSz)       [bitUnpack $val 31 16]

    popWord msg val
    set decoded($root.deltaN)          [bitUnpack $val 31 0]

    popWord msg val
    set decoded($root.dtxBits1stLevel) [bitUnpack $val 31 0]

    for { set k 0 } { $k < [expr (1<<$decoded($root.ttiLog2))] } { incr k } {
      if { [expr ($k & 1) == 0] } {
        popWord msg val
	set decode($root.pBit\[$k\])   [bitUnpack $val 15 0]
      } else {
        set decode($root.pBit\[$k\])   [bitUnpack $val 31 16]
      }
    }

    for { set k 0 } { $k < 3 } { incr k } {
      popWord msg val
      set decoded($root.eIni\[$k\]) [bitUnpack $val 17 0]
      popWord msg val
      set decoded($root.ePlus\[$k\]) [bitUnpack $val 17 0]
      popWord msg val
      set decoded($root.eMinus\[$k\]) [bitUnpack $val 17 0]
    }

    # Calculates number of bytes/words
    set trBlkSzRnd [expr ((($decoded($root.trBlkSz)+7)>>3)<<3)]
    set numBits [expr $trBlkSzRnd * $decoded($root.numTrBlk)]
    set trBlkWords [expr ((($numBits+31)>>5))]
    for { set k 0 } { $k < $trBlkWords } { incr k } {
      if { [llength $msg] > 0 } {
        popWord msg val
	set decoded($root.dataBits\[$k\]) [bitUnpack $val 31 0]
      } else {
        puts "Missing TRCH data"
        break
      }
    }

    PopIndex decoded
    incr i
  }
}

###############################################################################
# dlHsDschParamsIn
# No Subframe field as it is updated and appended on the fly by DtcsDlScheduler
###############################################################################

proc Layer0Message_DL_HSDSCH_PARAMS { trBlkSz numCodeBlk numFillerBits \
                                      codeBlkSz Nir \
                                      nttiDiv3 \
                                      ndataRateMatch rv_s rv_r rv_rmax \
                                      numPhysChan physChanOffset modSel constVers lastUser \
                                      numSystematicBits ovsf scrCodeSel \
                                      sttdSel gain \
                                      pn9Seed} {
  set msg ""

  # control for CRC
  set val [bitPack 0 $trBlkSz 31 0]               
  lappend msg $val
 
  # control for Turbo
  set val [bitPack 0 $numCodeBlk 7 0]             
  set val [bitPack $val $numFillerBits 15 8]      
  set val [bitPack $val $codeBlkSz 31 16]         
  lappend msg $val
 
  # control for RateMatch
  set val [bitPack 0 $Nir 31 0]                   
  lappend msg $val
 
  set val [bitPack 0 $nttiDiv3 31 0]                     
  lappend msg $val
 
  set val [bitPack 0 $ndataRateMatch 15 0]       
  set val [bitPack $val $rv_s 16 16]              
  set val [bitPack $val $rv_r 27 24]              
  set val [bitPack $val $rv_rmax 31 28]           
  lappend msg $val
 
  # control for interleaver
  set val [bitPack 0 $numPhysChan 3 0]            
  set val [bitPack $val $physChanOffset 7 4]                   
  set val [bitPack $val $modSel 8 8]              
  set val [bitPack $val $constVers 10 9]                  
  set val [bitPack $val $lastUser 11 11]          
  set val [bitPack $val $numSystematicBits 31 16]
  lappend msg $val
 
  set val [bitPack 0 $ovsf 3 0]                  
  set val [bitPack $val $scrCodeSel 4 4]         
  set val [bitPack $val $sttdSel 11 11]
  set val [bitPack $val $gain 31 16]   
  lappend msg $val
  
  # Data PN9 generator seed
  set val [bitPack 0 $pn9Seed 31 0]                   
  lappend msg $val
  
  return $msg
}

###############################################################################
# dlHsScchParamsIn
# No Subframe field as it is updated and appended on the fly by DtcsDlScheduler
# Subframe last user flag also appended on the fly
###############################################################################

proc Layer0Message_DL_HSSCCH_PARAMS { ovsf scrCodeSel sttdSel lastUserFlag gain\
                                      ueId chanOffset \
                                      pn9Seed} {
  
  set msg ""
  
  set val [bitPack 0 $ovsf 6 0]           
  set val [bitPack $val $scrCodeSel 7 7]  
  set val [bitPack $val $sttdSel 11 11]
  set val [bitPack $val $lastUserFlag 12 12]
  set val [bitPack $val $gain 31 16]   
  lappend msg $val
    
  set val [bitPack 0 $ueId 15 0]          
  set val [bitPack $val $chanOffset 19 16]
  lappend msg $val
  
  # Data PN9 generator seed
  set val [bitPack 0 $pn9Seed 31 0]                   
  lappend msg $val
  
  return $msg                                      
}

###############################################################################
# DlPwrCtrlMgr
###############################################################################

variable DlPwrCtrlAddrEnum
set   DlPwrCtrlAddrEnum(PCCPCH_GAIN)   0x04
set   DlPwrCtrlAddrEnum(SCCPCH_GAIN)   0x05
set   DlPwrCtrlAddrEnum(SCCPCH_PO)     0x06
set   DlPwrCtrlAddrEnum(TPC_FRAMES)    0x09
set   DlPwrCtrlAddrEnum(TPC_PATTERN0)  0x0A
set   DlPwrCtrlAddrEnum(TPC_PATTERN1)  0x0B
set   DlPwrCtrlAddrEnum(TPC_PATTERN2)  0x0C
set   DlPwrCtrlAddrEnum(TPC_PATTERN3)  0x0D
set   DlPwrCtrlAddrEnum(PHYS_CHAN_ID)  0x20
set   DlPwrCtrlAddrEnum(DPCH_GAIN)     0x21
set   DlPwrCtrlAddrEnum(DPCH_PO)       0x22
set   DlPwrCtrlAddrEnum(DPCH_PBAL)     0x23

namespace export \
  Layer0Message_DL_PCCPCH_GAIN_SETUP \
  Layer0Message_DL_SCCPCH_GAIN_SETUP \
  Layer0Message_DL_SCCPCH_PO_SETUP \
  Layer0Message_DL_DPCH_GAIN_SETUP \
  Layer0Message_DL_DPCH_PO_SETUP \
  Layer0Message_DL_DPCH_TPC_PATTERN\
  Layer0Message_DL_EAGCH_CONFIG\
  Layer0Message_DL_EAGCH_REQUEST\
  Layer0Message_DL_ERGCHEHICH_CONFIG_CODE_GAIN \
  Layer0Message_DL_ERGCHEHICH_CONFIG_SIG_HOP \
  Layer0Message_DL_ERGCHEHICH_REQUEST 

variable CfgBusAddr
set   CfgBusAddr(DL_PWR_CTRL)      0x04

proc Layer0Message_DL_PCCPCH_GAIN_SETUP { gain } {  

  variable DlPwrCtrlAddrEnum
  variable CfgBusAddr
  set rdNotWr 0

  set val [bitPack 0 $gain 11 0]
  set val [bitPack $val $DlPwrCtrlAddrEnum(PCCPCH_GAIN) 22 16]
  set val [bitPack $val $rdNotWr 23 23]
  set val [bitPack $val $CfgBusAddr(DL_PWR_CTRL) 31 24]

  return $val
}






proc Layer0Message_DL_ERGCHEHICH_CONFIG_CODE_GAIN { OVSFCode ScramCode IQGain } {

   set msg ""

   set val  [bitPack 0 $OVSFCode 7 0]
   set val  [bitPack $val $ScramCode 9 8]
   set val  [bitPack $val 0 22 16]
   lappend msg $val

   set val  [bitPack 0 $IQGain 11 0]
   set val  [bitPack $val 1 22 16]
   lappend msg $val

   return $msg
}

proc Layer0Message_DL_ERGCHEHICH_CONFIG_SIG_HOP { N index } {
   set paramAddr [expr 2 + $index]
   set val  [bitPack 0 $N 5 0]
   set val  [bitPack $val $paramAddr 22 16]
   return $val
}


proc Layer0Message_DL_ERGCHEHICH_REQUEST { SigCmd0 SigCmd1 SigCmd2 SigCmd3 SigCmd4 SigCmd5 SigCmd6 SigCmd7 } {
   set val  [bitPack 0 $SigCmd0 1 0]
   set val  [bitPack $val $SigCmd1 3 2]
   set val  [bitPack $val $SigCmd2 5 4]
   set val  [bitPack $val $SigCmd3 7 6]
   set val  [bitPack $val $SigCmd4 9 8]
   set val  [bitPack $val $SigCmd5 11 10]
   set val  [bitPack $val $SigCmd6 13 12]
   set val  [bitPack $val $SigCmd7 15 14]   
}

proc Layer0Message_DL_EAGCH_CONFIG { Config ScramCode ovsfCode EAgchGain  } {  
  set val [bitPack 0 $Config 3 0]
  set val [bitPack $val $ScramCode 4 4]
  set val [bitPack $val $ovsfCode 15 8]
  set val [bitPack $val $EAgchGain 27 16]
  return $val
}

proc Layer0Message_DL_EAGCH_REQUEST { EAgchConfig TTi Xagv Xags ERNTI  } {  
  set val [bitPack 0 $EAgchConfig 3 0]
  set val [bitPack $val $TTi 6 4]
  set val [bitPack $val $Xagv 12 8]
  set val [bitPack $val $Xags 13 13]
  set val [bitPack $val $ERNTI 31 16]
  return $val
}









proc Layer0Message_DL_SCCPCH_GAIN_SETUP { gain } {  
  variable DlPwrCtrlAddrEnum
  variable CfgBusAddr
  set rdNotWr 0
  set val [bitPack 0 $gain 11 0]
  set val [bitPack $val $DlPwrCtrlAddrEnum(SCCPCH_GAIN) 22 16]
  set val [bitPack $val $rdNotWr 23 23]
  set val [bitPack $val $CfgBusAddr(DL_PWR_CTRL) 31 24]
  return $val
}

proc Layer0Message_DL_SCCPCH_PO_SETUP { po1 po3 } {  

  variable DlPwrCtrlAddrEnum
  variable CfgBusAddr
  set rdNotWr 0

  set val [bitPack 0 $po1 4 0]
  set val [bitPack $val $po3 14 10]
  set val [bitPack $val $DlPwrCtrlAddrEnum(SCCPCH_PO) 22 16]
  set val [bitPack $val $rdNotWr 23 23]
  set val [bitPack $val $CfgBusAddr(DL_PWR_CTRL) 31 24]

  return $val
}

proc Layer0Message_DL_DPCH_GAIN_SETUP { physChanId gain } {  

  variable DlPwrCtrlAddrEnum
  variable CfgBusAddr
  set rdNotWr 0
  set msg ""

  set val [bitPack 0 $physChanId 5 0]
  set val [bitPack $val $DlPwrCtrlAddrEnum(PHYS_CHAN_ID) 22 16]
  set val [bitPack $val $rdNotWr 23 23]
  set val [bitPack $val $CfgBusAddr(DL_PWR_CTRL) 31 24]
  lappend msg $val

  set val [bitPack 0 $gain 11 0]
  set val [bitPack $val $DlPwrCtrlAddrEnum(DPCH_GAIN) 22 16]
  set val [bitPack $val $rdNotWr 23 23]
  set val [bitPack $val $CfgBusAddr(DL_PWR_CTRL) 31 24]
  lappend msg $val

  return $msg
}

proc Layer0Message_DL_DPCH_PO_SETUP { physChanId po1 po2 po3 } {  

  variable DlPwrCtrlAddrEnum
  variable CfgBusAddr
  set rdNotWr 0
  set msg ""

  set val [bitPack 0 $physChanId 5 0]
  set val [bitPack $val $DlPwrCtrlAddrEnum(PHYS_CHAN_ID) 22 16]
  set val [bitPack $val $rdNotWr 23 23]
  set val [bitPack $val $CfgBusAddr(DL_PWR_CTRL) 31 24]
  lappend msg $val

  set val [bitPack 0 $po1 4 0]
  set val [bitPack $val $po2 9 5]
  set val [bitPack $val $po3 14 10]
  set val [bitPack $val $DlPwrCtrlAddrEnum(DPCH_PO) 22 16]
  set val [bitPack $val $rdNotWr 23 23]
  set val [bitPack $val $CfgBusAddr(DL_PWR_CTRL) 31 24]
  lappend msg $val

  return $msg
}

proc Layer0Message_DL_DPCH_TPC_PATTERN { physChanId numFrames tpc4Frames } {
    
  variable DlPwrCtrlAddrEnum
  variable CfgBusAddr
  set rdNotWr 0
  set msg ""

  set val [bitPack 0 $physChanId 5 0]
  set val [bitPack $val 0x2 9 8]
  set val [bitPack $val $DlPwrCtrlAddrEnum(PHYS_CHAN_ID) 22 16]
  set val [bitPack $val $rdNotWr 23 23]
  set val [bitPack $val $CfgBusAddr(DL_PWR_CTRL) 31 24]
  lappend msg $val

  set val [bitPack 0 [lindex $tpc4Frames 0] 14 0]
  set val [bitPack $val $DlPwrCtrlAddrEnum(TPC_PATTERN0) 22 16]
  set val [bitPack $val $rdNotWr 23 23]
  set val [bitPack $val $CfgBusAddr(DL_PWR_CTRL) 31 24]
  lappend msg $val

  set val [bitPack 0 [lindex $tpc4Frames 1] 14 0]
  set val [bitPack $val $DlPwrCtrlAddrEnum(TPC_PATTERN1) 22 16]
  set val [bitPack $val $rdNotWr 23 23]
  set val [bitPack $val $CfgBusAddr(DL_PWR_CTRL) 31 24]
  lappend msg $val

  set val [bitPack 0 [lindex $tpc4Frames 2] 14 0]
  set val [bitPack $val $DlPwrCtrlAddrEnum(TPC_PATTERN2) 22 16]
  set val [bitPack $val $rdNotWr 23 23]
  set val [bitPack $val $CfgBusAddr(DL_PWR_CTRL) 31 24]
  lappend msg $val

  set val [bitPack 0 [lindex $tpc4Frames 3] 14 0]
  set val [bitPack $val $DlPwrCtrlAddrEnum(TPC_PATTERN3) 22 16]
  set val [bitPack $val $rdNotWr 23 23]
  set val [bitPack $val $CfgBusAddr(DL_PWR_CTRL) 31 24]
  lappend msg $val

  set val [bitPack 0 $numFrames 15 0]
  set val [bitPack $val $DlPwrCtrlAddrEnum(TPC_FRAMES) 22 16]
  set val [bitPack $val $rdNotWr 23 23]
  set val [bitPack $val $CfgBusAddr(DL_PWR_CTRL) 31 24]
  lappend msg $val

  return $msg
}

###############################################################################
# DlPwrCalc
###############################################################################

set   CfgBusAddr(DL_PWR_CALC)      0x01

variable DlPwrCalcAddrEnum
set DlPwrCalcAddrEnum(MEAN_POWER0)   0x00
set DlPwrCalcAddrEnum(MEAN_POWER1)   0x01
set DlPwrCalcAddrEnum(PEAK_POWER0)   0x02
set DlPwrCalcAddrEnum(PEAK_POWER1)   0x03
set DlPwrCalcAddrEnum(POWER_PERIOD)  0x04

namespace export \
  Layer0Message_DL_MEAN_POWER_READ \
  Layer0Message_DL_PEAK_POWER_RESET \
  Layer0Message_DL_PEAK_POWER_READ

proc Layer0Message_DL_MEAN_POWER_READ { log2Period } {

  variable DlPwrCalcAddrEnum
  variable CfgBusAddr
  set msg ""

  set rdNotWr 1
  set val [bitPack 0 0 15 0]
  set val [bitPack $val $DlPwrCalcAddrEnum(MEAN_POWER0) 22 16]
  set val [bitPack $val $rdNotWr 23 23]
  set val [bitPack $val $CfgBusAddr(DL_PWR_CALC) 31 24]
  lappend msg $val

#  set val [bitPack 0 0 15 0]
#  set val [bitPack $val $DlPwrCalcAddrEnum(MEAN_POWER1) 22 16]
#  set val [bitPack $val $rdNotWr 23 23]
#  set val [bitPack $val $CfgBusAddr(DL_PWR_CALC) 31 24]
#  lappend msg $val

  set rdNotWr 0
  set val [bitPack 0 $log2Period 1 0]
  set val [bitPack $val $DlPwrCalcAddrEnum(POWER_PERIOD) 22 16]
  set val [bitPack $val $rdNotWr 23 23]
  set val [bitPack $val $CfgBusAddr(DL_PWR_CALC) 31 24]
  lappend msg $val

  return $msg
}

proc Layer0Message_DL_PEAK_POWER_RESET { } {

  variable DlPwrCalcAddrEnum
  variable CfgBusAddr
  set rdNotWr 0
  set msg ""

  set val [bitPack 0 0 15 0]
  set val [bitPack $val $DlPwrCalcAddrEnum(PEAK_POWER0) 22 16]
  set val [bitPack $val $rdNotWr 23 23]
  set val [bitPack $val $CfgBusAddr(DL_PWR_CALC) 31 24]
  lappend msg $val

  return $msg
}

proc Layer0Message_DL_PEAK_POWER_READ { } {

  variable DlPwrCalcAddrEnum
  variable CfgBusAddr
  set rdNotWr 1
  set msg ""

  set val [bitPack 0 0 15 0]
  set val [bitPack $val $DlPwrCalcAddrEnum(PEAK_POWER0) 22 16]
  set val [bitPack $val $rdNotWr 23 23]
  set val [bitPack $val $CfgBusAddr(DL_PWR_CALC) 31 24]
  lappend msg $val

#  set val [bitPack 0 0 15 0]
#  set val [bitPack $val $DlPwrCalcAddrEnum(PEAK_POWER1) 22 16]
#  set val [bitPack $val $rdNotWr 23 23]
#  set val [bitPack $val $CfgBusAddr(DL_PWR_CALC) 31 24]
#  lappend msg $val

  return $msg
}

###############################################################################
# DlSync
###############################################################################

set   CfgBusAddr(DL_SYNC)          0x00

variable DlSyncAddrEnum
set DlSyncAddrEnum(T_CELL)         0x00

namespace export \
  Layer0Message_DL_T_CELL_ADJUST

proc Layer0Message_DL_T_CELL_ADJUST { tCell } {

  variable DlSyncAddrEnum
  variable CfgBusAddr
  set rdNotWr 0
  set msg ""

  set val [bitPack 0 $tCell 15 0]
  set val [bitPack $val $DlSyncAddrEnum(T_CELL) 22 16]
  set val [bitPack $val $rdNotWr 23 23]
  set val [bitPack $val $CfgBusAddr(DL_SYNC) 31 24]
  lappend msg $val

  return $msg
}

###############################################################################
# Uplink
###############################################################################


###############################################################################
# UlSymbolRate
###############################################################################

namespace export \
  Layer0Message_UL_PHYSCH_CTRL \
  Layer0Message_UL_TRCH_CTRL \
  Layer0Message_UL_SYM_REL6_CTRL \
  Layer0Message_UL_SYM_REL6_PC302_CTRL \
  DecodeLayer0Message_UL_SYM_CTRL \
  DecodeLayer0Message_UL_SYM_DATA \
  DecodeLayer0Message_UL_SYM_REL6_CTRL

variable UlSymbolRateCmdEnum
set UlSymbolRateCmdEnum(PHYS_CHAN)   0x00
set UlSymbolRateCmdEnum(CCTRCH_TRCH) 0x01

proc Layer0Message_UL_PHYSCH_CTRL { physChanId resetFlag \
				    cfn actualSfRel99Enum \
                                    numCMTimeslotGaps numTrchEnum } {

  variable UlSymbolRateCmdEnum

  set val [bitPack 0 $physChanId 5 0]
  set val [bitPack $val $resetFlag 7 7]
  set val [bitPack $val $cfn 15 8]
  set val [bitPack $val $actualSfRel99Enum 18 16]
  set val [bitPack $val $numCMTimeslotGaps 21 19]
  set val [bitPack $val $numTrchEnum 25 22]

  return $val
}

proc Layer0Message_UL_TRCH_CTRL { trchId trchReset ttiLog2 codingType crcType \
                                  rmType trchXiSize radioEqBits eIniList \
                                  ePlusList eMinusList numCodeBlk \
                                  numFillerBits codeBlkSize numTrBlk \
                                  trBlkSize } {

  variable UlSymbolRateCmdEnum
  set msg ""

  set val [bitPack 0 $trchId 8 0]
  set val [bitPack $val $trchReset 11 11]
  set val [bitPack $val $ttiLog2 13 12]
  set val [bitPack $val $codingType 15 14]
  set val [bitPack $val $crcType 18 16]
  set val [bitPack $val $rmType 20 19]
  
  lappend msg $val

  set val [bitPack 0 $trchXiSize 15 0]
  set val [bitPack $val $radioEqBits 23 16]
  set val [bitPack $val (($rmType)>>1) 24 24]  
  lappend msg $val

  # Handle E-params
  for { set i 0 } { $i < 3 } { incr i } {
    set val [bitPack 0 [lindex $eIniList $i] 17 0]
    lappend msg $val
    set val [bitPack 0 [lindex $ePlusList $i] 17 0]
    lappend msg $val
    set val [bitPack 0 [lindex $eMinusList $i] 17 0]
    lappend msg $val
  }

  # Coding parameters
  set val [bitPack 0 $numCodeBlk 7 0]
  set val [bitPack $val $numFillerBits 15 8]
  set val [bitPack $val $codeBlkSize 31 16]
  lappend msg $val 

  # Transport parameters
  set val [bitPack 0 $numTrBlk 15 0]
  set val [bitPack $val $trBlkSize 31 16]
  lappend msg $val

  return $msg
}

proc Layer0Message_UL_SYM_REL6_CTRL { userId \
				    isNewData is2MsTti numPhysChEnum \
                                    numCMTimeslotGaps actualSfEnum \
                                    numCodeBlocks \
                                    numBitsPerCodeBlock numCodeBlockFillerBits \
                                    numBitsInTrBlock rvIndex } {
  set msg ""

  set val [bitPack 0 $userId 15 11]
  set val [bitPack $val $isNewData 19 19]
  set val [bitPack $val $is2MsTti 20 20]
  set val [bitPack $val $numPhysChEnum 22 21]
  set val [bitPack $val $numCMTimeslotGaps 25 23]
  set val [bitPack $val $actualSfEnum 28 26]
  set val [bitPack $val $numCodeBlocks 31 29]

  lappend msg $val 

  set val [bitPack 0 $numBitsPerCodeBlock 12 0]
  set val [bitPack $val $numCodeBlockFillerBits 14 13]
  set val [bitPack $val $numBitsInTrBlock 29 15]
  set val [bitPack $val $rvIndex 31 30]

  lappend msg $val 

  return $msg
}


proc Layer0Message_UL_SYM_REL6_PC302_CTRL { userId \
				              isNewDataMode is2MsTti \
                                              firstStageSfEnum actualSfEnum \
                                              numCMTimeslotGaps rvIndex\
                                              numBitsPerCodeBlock numCodeBlockFillerBits \
                                              numCodeBlocks  } {
  set msg ""

  set val [bitPack 0 $userId 15 11]
  set val [bitPack $val $isNewDataMode 19 19]
  set val [bitPack $val $is2MsTti 20 20]
  set val [bitPack $val $firstStageSfEnum 22 21]
  set val [bitPack $val $actualSfEnum  26 23]
  set val [bitPack $val $numCMTimeslotGaps 29 27]
  set val [bitPack $val $rvIndex 31 30]

  lappend msg $val 

  set val [bitPack 0 $numBitsPerCodeBlock 15 0]
  set val [bitPack $val $numCodeBlockFillerBits 23 16]
  set val [bitPack $val $numCodeBlocks 31 24]

  lappend msg $val 

  return $msg
}




proc DecodeLayer0Message_UL_SYM_CTRL { msgBytes decodedArray } {

  upvar $decodedArray decoded
  upvar $msgBytes msg
  set val ""

  set i 0
  while {[llength $msg] != 0 } {

    popWord msg val

    if { $i > 0 } {
      PopIndex decoded
    }
    PushIndex decoded "FRAME\[$i\]"
    PushIndex decoded "PHYSCH"
    DecodeLayer0Message_UL_PHYSCH_CTRL $val msg decoded
    PopIndex decoded
    incr i

  }
}

proc DecodeLayer0Message_UL_PHYSCH_CTRL { firstWord msgBytes decodedArray } {

  upvar $decodedArray decoded
  upvar $msgBytes msg
  set val ""

  set root $decoded(root)

  set decoded($root.physChanId) [bitUnpack $firstWord 5 0]
  set decoded($root.resetFlag) [bitUnpack $firstWord 7 7]
  set decoded($root.cfn) [bitUnpack $firstWord 15 8]
  set decoded($root.actualSfRel99Enum) [bitUnpack $firstWord 18 16]
  set decoded($root.numCMTimeslotGaps) [bitUnpack $firstWord 21 19]
  set decoded($root.numTrchEnum) [bitUnpack $firstWord 25 22]
}

proc DecodeLayer0Message_UL_TRCH_CTRL { msgBytes decodedArray } {

  upvar $decodedArray decoded
  upvar $msgBytes msg
  set val ""

  set root $decoded(root)

  popWord msg val
  set decoded($root.trchId) [bitUnpack $val 8 0]
  set decoded($root.trchReset) [bitUnpack $val 11 11]
  set decoded($root.ttiLog2) [bitUnpack $val 13 12]
  set decoded($root.codingType) [bitUnpack $val 15 14]
  set decoded($root.crcType) [bitUnpack $val 18 16]
  set decoded($root.rmType) [bitUnpack $val 20 19]

  popWord msg val
  set decoded($root.trchXiSize) [bitUnpack $val 15 0]
  set decoded($root.radioEqBits) [bitUnpack $val 31 16]

  for { set i 0 } { $i < 3 } { incr i } {
    popWord msg val
    set decoded($root.eIni\[$i\]) [bitUnpack $val 17 0]
    popWord msg val
    set decoded($root.ePlus\[$i\]) [bitUnpack $val 17 0]
    popWord msg val
    set decoded($root.eMinus\[$i\]) [bitUnpack $val 17 0]
  }

  popWord msg val
  set decoded($root.numCodeBlk) [bitUnpack $val 7 0]
  set decoded($root.numFillerBits) [bitUnpack $val 15 8]
  set decoded($root.codeBlkSz) [bitUnpack $val 31 16]

  popWord msg val
  set decoded($root.numTrBlk) [bitUnpack $val 15 0]
  set decoded($root.trBlkSz) [bitUnpack $val 31 16]
}


proc DecodeLayer0Message_UL_SYM_DATA { msgBytes decodedArray } {

  upvar $decodedArray decoded
  upvar $msgBytes msg
  set val ""

  set i 0
  while {[llength $msg] != 0 } {

    PushIndex decoded "TRCH\[$i\]"

    set root $decoded(root)

    popWord msg val
    set decoded($root.trchId)          [bitUnpack $val 8 0]
    set decoded($root.passThroughFlag) [bitUnpack $val 10 9]
    set decoded($root.trchReset)       [bitUnpack $val 11 11]
    set decoded($root.ttiLog2)         [bitUnpack $val 13 12]
    set decoded($root.codingType)      [bitUnpack $val 15 14]
    set decoded($root.crcType)         [bitUnpack $val 18 16]
    set decoded($root.rmType)          [bitUnpack $val 20 19]
    set decoded($root.cfn)             [bitUnpack $val 31 24]

    popWord msg val
    set decoded($root.numTrBlk) [bitUnpack $val 15 0]
    set decoded($root.trBlkSize) [bitUnpack $val 31 16]

    set numData [expr (((($decoded($root.trBlkSize)+7)>>3) * \
			   $decoded($root.numTrBlk))+3)>>2]

    for { set j 0 } { $j < $numData } { incr j } {

      popWord msg val
      set decoded($root.dataBits\[$j\]) [bitUnpack $val 31 0]

    }

    popWord msg val
    set decoded($root.berNumBits) [bitUnpack $val 31 0]

    popWord msg val
    set decoded($root.berBitsInError) [bitUnpack $val 31 0]

    set numTrBlk [expr $decoded($root.numTrBlk)==0?1:$decoded($root.numTrBlk)]
    set numCrc [expr ($decoded($root.numTrBlk)+31)>>5]

    for { set j 0 } { $j < $numCrc } { incr j } {

      popWord msg val
      set decoded($root.crcFlags\[$j\]) [bitUnpack $val 31 0]

    }

    PopIndex decoded
    incr i
  }
}
proc DecodeLayer0Message_UL_SYM_REL6_CTRL { msgBytes decodedArray } {

  upvar $decodedArray decoded
  upvar $msgBytes msg
  set val ""

  set root $decoded(root)

  popWord msg val
  set decoded($root.userId)     [bitUnpack $val 15 11]
  set decoded($root.isNewData)  [bitUnpack $val 19 19]
  set decoded($root.is2MsTti)    [bitUnpack $val 20 20]
  set decoded($root.numPhysChEnum) [bitUnpack $val 22 21]
  set decoded($root.numCMTimeslotGaps)    [bitUnpack $val 25 23]
  set decoded($root.actualSfEnum)     [bitUnpack $val 28 26]
  set decoded($root.numCodeBlocks)     [bitUnpack $val 31 29]

  popWord msg val
  set decoded($root.numBitsPerCodeBlock) [bitUnpack $val 12 0]
  set decoded($root.numCodeBlockFillerBits) [bitUnpack $val 14 13]
  set decoded($root.numBitsInTrBlock) [bitUnpack $val 29 15]
  set decoded($root.rvIndex) [bitUnpack $val 31 30]

  upvar $decodedArray decoded
}


namespace export \
  Layer0Message_UL_TRCH_DATA \
  Layer0Message_UL_TFCI_IND \
  Layer0Message_UL_RACH_IND \
  Layer0Message_UL_ACK_IND \
  Layer0Message_UL_CQI_IND \
  DecodeLayer0Message_UL_TFCI_IND \
  DecodeLayer0Message_UL_RACH_IND

proc Layer0Message_UL_TRCH_DATA { trchId numTrBlk trBlkSz } {

  set msg ""

  # Information
  lappend msg [ expr ($trchId & 0xFF) ]

  # Params
  lappend msg [ expr ($numTrBlk & 0xFFFF) | \
                     ($trBlkSz & 0xFFFF) << 16]

  # Ensure BER and CRC is output for no TrBlk case
  if { $numTrBlk == 0 } {
    set numTrBlk 1
    set trBlkSz  0
  }

  ############################################################################
  # Data: Round-up transport block size to nearest byte boundary and
  # concatenate eachtransport block together
  ############################################################################

  for { set i 0 } \
      { $i < [expr ($numTrBlk * (($trBlkSz + 7) >> 3) + 3) >> 2] } { incr i } {
    lappend msg $i
  }

  # 32 CRCIs per transfer
  for { set i 0 } {$i < [expr ($numTrBlk + 31) >> 5]} { incr i } {
    lappend msg 0
  }

  # One BER per transport block
  for { set i 0 } { $i < $numTrBlk } { incr i } {
    lappend msg $trBlkSz
    lappend msg 0
  }

  return $msg
}

proc Layer0Message_UL_TFCI_IND { userId cfn tfciVal nGap nFirst } {

  set msg ""

  lappend msg [expr ($userId & 0xFFFF) | \
                    ($cfn & 0xFFFF)<<16]

  lappend msg [expr ($tfciVal & 0xFFFF) | \
                    ($nGap & 0xFF)<<16 | \
                    ($nFirst & 0xFF)<<24]

  return $msg
}

proc DecodeLayer0Message_UL_TFCI_IND { msgBytes decodedArray } {

  upvar $decodedArray decoded
  upvar $msgBytes msg
  set val ""
  set i 0

  while { [llength $msg] != 0 } {

    PushIndex decoded "TFCI\[$i\]"
    set root $decoded(root)

    popWord msg val
    set decoded($root.chanId) [bitUnpack $val 15 0]
    set decoded($root.cfn) [bitUnpack $val 31 16]

    popWord msg val
    set decoded($root.tfciVal) [bitUnpack $val 15 0]
    set decoded($root.nGap) [bitUnpack $val 23 16]
    set decoded($root.nFirst) [bitUnpack $val 31 24]

    PopIndex decoded
    incr i
  }
}

proc Layer0Message_UL_RACH_IND { ackNack rachDemodAvail tauDpch sfn \
                                 scramCodeX signature sigSelect msgTti \
				 freqOffset fingerPosList } {

  variable CECIndicationTypes
  set msg ""

  lappend msg $CECIndicationTypes(PRACH_IND)
  lappend msg [expr ($ackNack & 1) | \
                    ($rachDemodAvail & 1) << 1 | \
                    ($tauDpch & 0xFF) << 8 | \
                    ($sfn & 0xFF) << 16]
  lappend msg $scramCodeX
  lappend msg $signature

  set fingerMask 0
  set len [llength $fingerPosList]
  if { $len > 8 } { set len 8 }
  for { set i 0 } { $i < $len } { incr i } {
    set fingerMask [expr (1 << $i)]
  }

  lappend msg [expr ($sigSelect & 1) | \
                    ($msgTti & 1) << 1 | \
                    ($fingerMask & 0xFF) << 8 | \
                    ($freqOffset & 0xFFFF) << 16]

  set fingerOffset 0
  for { set i 0 } { $i < 4 } { incr i } {
    if { $len > $i } {
      set fingerOffset [expr $fingerOffset | \
                             ([lindex $fingerPosList $i] & 0xFF) << 8*$i]
    }
  }

  lappend msg $fingerOffset

  set fingerOffset 0
  for { set i 4 } { $i < 8 } { incr i } {
    if { $len > $i } {
      set fingerOffset [expr $fingerOffset | \
                             ([lindex $fingerPosList $i] & 0xFF) << (8*($i-4))]
    }
  }

  lappend msg $fingerOffset

  return $msg
}

proc DecodeLayer0Message_UL_RACH_IND { msgBytes decodedArray } {

  upvar $decodedArray decoded
  upvar $msgBytes msg
  set val ""

  set i 0

  while { [llength $msg] != 0 } {

  PushIndex decoded "RACH_IND\[$i\]"
  set root $decoded(root)

  popWord msg val
  set decoded($root.msgType) [bitUnpack $val 7 0]
  set decoded($root.cecInst) [bitUnpack $val 13 8]
  set decoded($root.demodAvail) [bitUnpack $val 21 16]

  popWord msg val
  set decoded($root.ackNack) [bitUnpack $val 0 0]
  set decoded($root.sfn) [bitUnpack $val 15 8]
  set decoded($root.tauDelay) [bitUnpack $val 31 16]

  popWord msg val
  set decoded($root.signatureIdx) [bitUnpack $val 3 0]
  set decoded($root.fingerMask) [bitUnpack $val 15 8]
  set decoded($root.freqOffset) [bitUnpack $val 26 16]

  popWord msg val
  set decoded($root.finger0) [bitUnpack $val 7 0]
  set decoded($root.finger1) [bitUnpack $val 15 8]
  set decoded($root.finger2) [bitUnpack $val 23 16]
  set decoded($root.finger3) [bitUnpack $val 31 24]

  popWord msg val
  set decoded($root.finger4) [bitUnpack $val 7 0]
  set decoded($root.finger5) [bitUnpack $val 15 8]
  set decoded($root.finger6) [bitUnpack $val 23 16]
  set decoded($root.finger7) [bitUnpack $val 31 24]

  PopIndex decoded
  incr i
  }
}

proc Layer0Message_UL_ACK_IND {} {}
proc Layer0Message_UL_CQI_IND {} {}

###############################################################################
# UlHsCec
###############################################################################

namespace export \
  Layer0Message_UL_CEC_FINGER_SIGNAL_POWER_IND \
  Layer0Message_UL_CEC_FINGER_NOISE_POWER_IND \
  Layer0Message_UL_CEC_SEARCHER_PATH_IND \
  Layer0Message_UL_CEC_SEARCHER_MAGNITUDE_IND

variable CECIndicationTypes
set   CECIndicationTypes(PRACH_IND)        0x00

set   CfgBusAddr(UL_AGC)           0x80
set   CfgBusAddr(UL_HS_CEC)        0x84
set   CfgBusAddr(UL_2NDLEVEL)      0x88

variable UlAgcAddrEnum
set UlAgcAddrEnum(GAIN_MODE)        0x00
set UlAgcAddrEnum(OPEN_LOOP_GAIN)   0x04
set UlAgcAddrEnum(CLOSED_LOOP_GAIN) 0x06
set UlAgcAddrEnum(PWR_EST_LO)       0x08
set UlAgcAddrEnum(PWR_EST_HI)       0x0A
set UlAgcAddrEnum(I_OFFSET)         0x0C
set UlAgcAddrEnum(Q_OFFSET)         0x0E

namespace export \
  Layer0Message_UL_SET_AGC_MODE \
  Layer0Message_UL_SET_AGC_GAIN \
  Layer0Message_UL_GET_POWER_ESTIMATE \
  Layer0Message_UL_GET_CLOSED_LOOP_GAIN \
  Layer0Message_UL_GET_OPEN_LOOP_GAIN \
  Layer0Message_UL_GET_IQ_OFFSET

proc Layer0Message_UL_SET_AGC_MODE { mode inst } {

  variable UlAgcAddrEnum
  variable CfgBusAddr
  set msg ""

  set wrNotRd 1
  set val [bitPack 0 $mode 15 15]
  set val [bitPack $val $UlAgcAddrEnum(GAIN_MODE) 22 16]
  set val [bitPack $val $wrNotRd 23 23]
  set val [bitPack $val [expr $CfgBusAddr(UL_AGC) | $inst] 31 24]
  lappend msg $val

  return $msg
}

proc Layer0Message_UL_SET_AGC_GAIN { gain inst } {

  variable UlAgcAddrEnum
  variable CfgBusAddr
  set msg ""

  set wrNotRd 1
  set val [bitPack 0 $gain 15 0]
  set val [bitPack $val $UlAgcAddrEnum(OPEN_LOOP_GAIN) 22 16]
  set val [bitPack $val $wrNotRd 23 23]
  set val [bitPack $val [expr $CfgBusAddr(UL_AGC) | $inst] 31 24]
  lappend msg $val

  return $msg
}

proc Layer0Message_UL_GET_CLOSED_LOOP_GAIN { inst } {

  variable UlAgcAddrEnum
  variable CfgBusAddr
  set msg ""

  set wrNotRd 0
  set val [bitPack 0 $UlAgcAddrEnum(CLOSED_LOOP_GAIN) 22 16]
  set val [bitPack $val $wrNotRd 23 23]
  set val [bitPack $val [expr $CfgBusAddr(UL_AGC) | $inst] 31 24]
  lappend msg $val

  return $msg
}

proc Layer0Message_UL_GET_OPEN_LOOP_GAIN { inst } {

  variable UlAgcAddrEnum
  variable CfgBusAddr
  set msg ""

  set wrNotRd 0
  set val [bitPack 0 $UlAgcAddrEnum(OPEN_LOOP_GAIN) 22 16]
  set val [bitPack $val $wrNotRd 23 23]
  set val [bitPack $val [expr $CfgBusAddr(UL_AGC) | $inst] 31 24]
  lappend msg $val

  return $msg
}

proc Layer0Message_UL_GET_POWER_ESTIMATE { inst } {

  variable UlAgcAddrEnum
  variable CfgBusAddr
  set msg ""

  set wrNotRd 0
  set val [bitPack 0 $UlAgcAddrEnum(PWR_EST_LO) 22 16]
  set val [bitPack $val $wrNotRd 23 23]
  set val [bitPack $val [expr $CfgBusAddr(UL_AGC) | $inst] 31 24]
  lappend msg $val

  set val [bitPack 0 $UlAgcAddrEnum(PWR_EST_HI) 22 16]
  set val [bitPack $val $wrNotRd 23 23]
  set val [bitPack $val [expr $CfgBusAddr(UL_AGC) | $inst] 31 24]
  lappend msg $val

  return $msg
}

proc Layer0Message_UL_GET_IQ_OFFSET { inst } {

  variable UlAgcAddrEnum
  variable CfgBusAddr
  set msg ""

  set wrNotRd 0
  set val [bitPack 0 $UlAgcAddrEnum(I_OFFSET) 22 16]
  set val [bitPack $val $wrNotRd 23 23]
  set val [bitPack $val [expr $CfgBusAddr(UL_AGC) | $inst] 31 24]
  lappend msg $val

  set val [bitPack 0 $UlAgcAddrEnum(Q_OFFSET) 22 16]
  set val [bitPack $val $wrNotRd 23 23]
  set val [bitPack $val [expr $CfgBusAddr(UL_AGC) | $inst] 31 24]
  lappend msg $val

  return $msg
}

# CEC diagnostics addresses
variable CecDiagAddr
set CecDiagAddr(UL_CEC_FINGER_SIGNAL_POWER)  64
set CecDiagAddr(UL_CEC_FINGER_NOISE_POWER)   72
set CecDiagAddr(UL_CEC_SEARCHER_PATH)        80
set CecDiagAddr(UL_CEC_SEARCHER_MAGNITUDE)   88

proc Layer0Message_UL_CEC_FINGER_SIGNAL_POWER_IND { cecInst finger sig } {

  variable CfgBusAddr
  variable CecDiagAddr
  set msg ""
  set rdNotWr 1

  lappend msg [expr ($sig & 0xFFFF)|\
                    ($finger | $CecDiagAddr(UL_CEC_FINGER_SIGNAL_POWER))<<16|\
                    ($rdNotWr & 1)<<23|\
                    ($CfgBusAddr(UL_HS_CEC) | $cecInst)<<24]

  return $msg                    
}

proc Layer0Message_UL_CEC_FINGER_NOISE_POWER_IND { cecInst finger noise } {

  variable CfgBusAddr
  variable CecDiagAddr
  set msg ""
  set rdNotWr 1

  lappend msg [expr ($noise & 0xFFFF)|\
                    ($finger | $CecDiagAddr(UL_CEC_FINGER_NOISE_POWER))<<16|\
                    ($rdNotWr & 1)<<23|\
                    ($CfgBusAddr(UL_HS_CEC) | $cecInst)<<24]

  return $msg

}

proc Layer0Message_UL_CEC_SEARCHER_PATH_IND { cecInst path offset } {

  variable CfgBusAddr
  variable CecDiagAddr
  set msg ""
  set rdNotWr 1

  lappend msg [expr ($offset & 0xFFFF)|\
                    ($path | $CecDiagAddr(UL_CEC_SEARCHER_PATH))<<16|\
                    ($rdNotWr & 1)<<23|\
                    ($CfgBusAddr(UL_HS_CEC) | $cecInst)<<24]

  return $msg

}

proc Layer0Message_UL_CEC_SEARCHER_MAGNITUDE_IND { cecInst path mag } {

  variable CfgBusAddr
  variable CecDiagAddr
  set msg ""
  set rdNotWr 1

  lappend msg [expr ($mag & 0xFFFF)|\
                    ($path | $CecDiagAddr(UL_CEC_SEARCH_MAGNITUDE))<<16|\
                    ($rdNotWr & 1)<<23|\
                    ($CfgBusAddr(UL_HS_CEC) | $cecInst)<<24]

  return $msg

}

namespace export \
  Layer0Message_UL_CEC_PRACH_SETUP \
  Layer0Message_UL_CEC_PRACH_DELETE \
  Layer0Message_UL_CEC_DCH_DEMOD_SETUP \
  Layer0Message_UL_CEC_DCH_DEMOD_SETUP_302 \
  Layer0Message_UL_CEC_DCH_TFCI \
  Layer0Message_UL_CEC_DCH_TFCI_SIR \
  Layer0Message_UL_CEC_DCH_DEMOD_DELETE \
  Layer0Message_UL_CEC_DIAG_SETUP \
  Layer0Message_UL_CEC_SIR_SETUP \
  DecodeLayer0Message_UL_CEC \
  CecDiagTypeEnum

variable CecCmdEnum
set CecCmdEnum(PRACH_SETUP)   0x00
set CecCmdEnum(PRACH_DELETE)  0x01
set CecCmdEnum(DCH_SETUP)     0x02
set CecCmdEnum(DCH_TFCI)      0x03
set CecCmdEnum(DCH_DELETE)    0x04
set CecCmdEnum(SIR_SETUP)     0x05

variable AichDelayEnum
set AichDelayEnum(AICH_DELAY_3SLOT) 0x00
set AichDelayEnum(AICH_DELAY_4SLOT) 0x01

variable CecDiagTypeEnum
set CecDiagTypeEnum(FINGER_SIGNAL_POWER0) 0x40
set CecDiagTypeEnum(FINGER_SIGNAL_POWER1) 0x41
set CecDiagTypeEnum(FINGER_SIGNAL_POWER2) 0x42
set CecDiagTypeEnum(FINGER_SIGNAL_POWER3) 0x43
set CecDiagTypeEnum(FINGER_SIGNAL_POWER4) 0x44
set CecDiagTypeEnum(FINGER_SIGNAL_POWER5) 0x45
set CecDiagTypeEnum(FINGER_SIGNAL_POWER6) 0x46
set CecDiagTypeEnum(FINGER_SIGNAL_POWER7) 0x47
set CecDiagTypeEnum(FINGER_NOISE_POWER0)  0x48
set CecDiagTypeEnum(FINGER_NOISE_POWER1)  0x49
set CecDiagTypeEnum(FINGER_NOISE_POWER2)  0x4A
set CecDiagTypeEnum(FINGER_NOISE_POWER3)  0x4B
set CecDiagTypeEnum(FINGER_NOISE_POWER4)  0x4C
set CecDiagTypeEnum(FINGER_NOISE_POWER5)  0x4D
set CecDiagTypeEnum(FINGER_NOISE_POWER6)  0x4E
set CecDiagTypeEnum(FINGER_NOISE_POWER7)  0x4F
set CecDiagTypeEnum(SEARCHER_PATH_INFO)   0x50

proc DecodeLayer0Message_UL_CEC { msgBytes decodedArray {messageCount 0} } {

  upvar $decodedArray decoded
  upvar $msgBytes msg
  variable CecCmdEnum
  set val ""

  while {[llength $msg] !=0 } {

    PushIndex decoded "Layer0Message_UL_CEC\[$messageCount\]"
    set root $decoded(root)

    popWord msg val
    set decoded($root.msgType) [bitUnpack $val 7 0]
    set decoded($root.cecInst) [bitUnpack $val 13 8]

    switch $decoded($root.msgType) \
      [expr $CecCmdEnum(PRACH_SETUP)] { \
        PushIndex decoded "PRACH_SETUP"; \
        DecodeLayer0Message_UL_CEC_PRACH_SETUP msg decoded; \
        PopIndex decoded; \
      } \
      [expr $CecCmdEnum(PRACH_DELETE)] { \
        PushIndex decoded "PRACH_DELETE"; \
        DecodeLayer0Message_UL_CEC_PRACH_DELETE msg decoded; \
        PopIndex decoded; \
      } \
      [expr $CecCmdEnum(DCH_SETUP)] { \
        PushIndex decoded "DCH_SETUP"; \
        DecodeLayer0Message_UL_CEC_DCH_DEMOD_SETUP msg decoded; \
        PopIndex decoded; \
      } \
      [expr $CecCmdEnum(DCH_TFCI)] { \
        PushIndex decoded "DCH_TFCI"; \
        DecodeLayer0Message_UL_CEC_DCH_TFCI_SIR msg decoded; \
        PopIndex decoded; \
      }

    PopIndex decoded 
    incr messageCount
  }
}

proc Layer0Message_UL_CEC_PRACH_SETUP { aichDelay \
                                        sigA rachTti threshold scramCodeX \
                                        patternA } {
  variable CecCmdEnum
  set msg ""

  set val [bitPack 0 $CecCmdEnum(PRACH_SETUP) 7 0]
  lappend msg $val

  set val [bitPack 0 $aichDelay 0 0]
  set val [bitPack $val $sigA 7 4]
  set val [bitPack $val $rachTti 8 8]
  set val [bitPack $val $threshold 31 16]
  lappend msg $val

  set val [bitPack 0 $scramCodeX 23 0]
  lappend msg $val

  set val [bitPack 0 $patternA 15 0]
  lappend msg $val

  return $msg
}

proc DecodeLayer0Message_UL_CEC_PRACH_SETUP { msgBytes decodedArray } {

  upvar $decodedArray decoded
  upvar $msgBytes msg
  set val ""

  set root $decoded(root)

  popWord msg val
  set decoded($root.aichDelay) [bitUnpack $val 0 0]
  set decoded($root.sigA) [bitUnpack $val 7 4]
  set decoded($root.rachTti) [bitUnpack $val 8 8]
  set decoded($root.threshold) [bitUnpack $val 31 16]

  popWord msg val
  set decoded($root.scramCodeX) [bitUnpack $val 23 0]

  popWord msg val
  set decoded($root.patternA) [bitUnpack $val 15 0]
}

proc Layer0Message_UL_CEC_PRACH_DELETE {  } {

  variable CecCmdEnum

  set val [bitPack 0 $CecCmdEnum(PRACH_DELETE) 7 0]

  return $val
}

proc DecodeLayer0Message_UL_CEC_PRACH_DELETE { msgBytes decodedArray } {

  upvar $decodedArray decoded
  upvar $msgBytes msg
  set val ""

  set root $decoded(root)
}

variable CecChanTypeEnum
set CecChanTypeEnum(RACH) 0x00
set CecChanTypeEnum(DCH)  0x01



proc Layer0Message_UL_CEC_DCH_DEMOD_SETUP_302 { \
          chanId dpcchSlotFmt \
	  eTti chanSelect cfnOffset tDelay scramCodeX scramCodeY \
          srchThreshold nCqiTxRep cqiFbCycle \
	  compModePattern hsDpcchSymbOffset hsDpcchSubframeOffset } {

  variable CecChanTypeEnum
  variable CecCmdEnum
  set msg ""

set tempChanSelHiNib 0
if {[format "%#x" $chanSelect] > 15} {
set tempChanSelHiNib 1
set chanSelect [expr [format "%#x" $chanSelect] - 16]
}
  
  set val [bitPack 0 $CecCmdEnum(DCH_SETUP) 7 0]
  set val [bitPack $val $chanId 13 8]
  lappend msg $val

  set val [bitPack 0 $dpcchSlotFmt 2 0]
  set val [bitPack $val $eTti 3 3]
  set val [bitPack $val $chanSelect 7 4]
  set val [bitPack $val $cfnOffset 15 8]
  set val [bitPack $val $tDelay 31 16]
  lappend msg $val

  set val [bitPack 0 $scramCodeX 24 0]
  set val [bitPack $val $tempChanSelHiNib 25 25]
  lappend msg $val
  
  set val [bitPack 0 $scramCodeY 24 0]
  lappend msg $val

  set val [bitPack 0 $srchThreshold 15 0]
  set val [bitPack $val $nCqiTxRep 17 16]
  set val [bitPack $val $cqiFbCycle 31 24]
  lappend msg $val

  set val [bitPack 0 $compModePattern 14 0]
  set val [bitPack $val $hsDpcchSymbOffset 23 16]
  set val [bitPack $val $hsDpcchSubframeOffset 29 24]
  lappend msg $val

  return $msg
}

proc Layer0Message_UL_CEC_DCH_DEMOD_SETUP { \
          chanId dpcchSlotFmt \
	  eTti chanSelect cfnOffset tDelay scramCodeX scramCodeY \
          srchThreshold nCqiTxRep cqiFbCycle \
	  compModePattern hsDpcchSymbOffset hsDpcchSubframeOffset } {

  variable CecChanTypeEnum
  variable CecCmdEnum
  set msg ""

  set val [bitPack 0 $CecCmdEnum(DCH_SETUP) 7 0]
  set val [bitPack $val $chanId 13 8]
  lappend msg $val

  set val [bitPack 0 $dpcchSlotFmt 2 0]
  set val [bitPack $val $eTti 3 3]
  set val [bitPack $val $chanSelect 7 4]
  set val [bitPack $val $cfnOffset 15 8]
  set val [bitPack $val $tDelay 31 16]
  lappend msg $val

  set val [bitPack 0 $scramCodeX 24 0]
  lappend msg $val

  set val [bitPack 0 $scramCodeY 24 0]
  lappend msg $val

  set val [bitPack 0 $srchThreshold 15 0]
  set val [bitPack $val $nCqiTxRep 17 16]
  set val [bitPack $val $cqiFbCycle 31 24]
  lappend msg $val

  set val [bitPack 0 $compModePattern 14 0]
  set val [bitPack $val $hsDpcchSymbOffset 23 16]
  set val [bitPack $val $hsDpcchSubframeOffset 29 24]
  lappend msg $val

  return $msg
}


proc DecodeLayer0Message_UL_CEC_DCH_DEMOD_SETUP { msgBytes decodedArray } {

  upvar $decodedArray decoded
  upvar $msgBytes msg
  set val ""

  set root $decoded(root)

  popWord msg val
  set decoded($root.dpcchSlotFormat) [bitUnpack $val 2 0]
  set decoded($root.eTti) [bitUnpack $val 3 3]
  set decoded($root.chanSelect) [bitUnpack $val 7 4]
  set decoded($root.cfnOffset) [bitUnpack $val 15 8]
  set decoded($root.tDelay) [bitUnpack $val 31 16]

  popWord msg val
  set decoded($root.scramCodeX) [bitUnpack $val 24 0]

  popWord msg val
  set decoded($root.scramCodeY) [bitUnpack $val 24 0]

  popWord msg val
  set decoded($root.srchTreshold) [bitUnpack $val 15 0]
  set decoded($root.nCqiTxReq) [bitUnpack $val 17 16]
  set decoded($root.cqiFbCycle) [bitUnpack $val 31 24]

  popWord msg val
  set decoded($root.compModePattern) [bitUnpack $val 14 0]
  set decoded($root.hsDpcchSymbOffset) [bitUnpack $val 23 16]
  set decoded($root.hsDpcchSubframeOffset) [bitUnpack $val 29 24]
  
}


proc Layer0Message_UL_CEC_DCH_TFCI { \
                  chanId sfIdx \
                  compModePattern  } {

  return [Layer0Message_UL_CEC_DCH_TFCI_SIR $chanId \
          $sfIdx $compModePattern 0]

}

proc Layer0Message_UL_CEC_DCH_TFCI_SIR { \
                  chanId sfIdx \
                  compModePattern sirTarget } {

  variable CecCmdEnum
  set msg ""

  set val [bitPack 0 $CecCmdEnum(DCH_TFCI) 7 0]
  set val [bitPack $val $chanId 13 8]
  lappend msg $val

  set val [bitPack 0 $sfIdx 3 0]
  set val [bitPack $val $compModePattern 30 16]
  lappend msg $val

  set val [bitPack 0 $sirTarget 15 0]
  lappend msg $val

  return $msg
}

proc DecodeLayer0Message_UL_CEC_DCH_TFCI_SIR { msgBytes decodedArray } {

  upvar $decodedArray decoded
  upvar $msgBytes msg
  set val ""

  set root $decoded(root)

  popWord msg val
  set decoded($root.sfIdx) [bitUnpack $val 3 0]
  set decoded($root.cfn) [bitUnpack $val 15 8]
  set decoded($root.compModePattern) [bitUnpack $val 30 16]

  popWord msg val
  set decoded($root.sirTarget) [bitUnpack $val 15 0]
}

proc Layer0Message_UL_CEC_SIR_SETUP { chanId totalNoisePower \
                                      sirTarget } {

  variable CecCmdEnum
  set msg ""

  set val [bitPack 0 $CecCmdEnum(SIR_SETUP) 7 0]
  set val [bitPack $val $chanId 13 8]
  lappend msg $val

  set val [bitPack 0 $totalNoisePower 15 0]
  set val [bitPack $val $sirTarget 31 16]
  lappend msg $val

  return $msg
}

proc Layer0Message_UL_CEC_DCH_DEMOD_DELETE { \
                  chanId } {

  variable CecCmdEnum
  set msg ""

  set val [bitPack 0 $CecCmdEnum(DCH_DELETE) 7 0]
  set val [bitPack $val $chanId 13 8]

  return $val
}

proc Layer0Message_UL_CEC_DIAG_SETUP { chanId diagEnable diagType } {

  variable CfgBusAddr
  set rdNotWr 0;			# Write command

  # CEC instance ID can be calculated from chanId
  set cecInst [expr $chanId>>3]

  set val [bitPack 0 $diagEnable 0 0]
  set val [bitPack $val [expr $chanId % 8] 3 1]
  set val [bitPack $val $diagType 22 16]
  set val [bitPack $val $rdNotWr 23 23]
  set val [bitPack $val $cecInst 25 24]
  set val [bitPack $val $CfgBusAddr(UL_HS_CEC) 31 24]

  return $val
}

} ; # end of namespace
