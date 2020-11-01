--
-- picoifapp: Lua based scripting language for picoIf.
--
-- URLs: http://www.picochip.com/
-- Copyright (C) 2009, picoChip Designs Ltd
-- Contact: support@picochip.com
-- Author: Jamie Iles
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <http://www.gnu.org/licenses/>.
--

-----------------------------------------------------------------------------
-- The naming convention used here is that those in the picoif
-- namespace use camel caps e.g. picoif.configRead and, if present,
-- the wrapper that is the interactive version uses underscores
-- i.e. config_read. There won't be a full set of interactive wrappers
-- as they are unnecessary in some cases e.g. picoif.dumpSystem only
-- dumps to a file, it would not be sensible to provide a version
-- which dumps the information to stdout.
-- Where applicable all wrappers should do checks for nil parameter values.
-----------------------------------------------------------------------------

onlineHelp = {}

-- Return the hex representation of a 16 bit integer.
--
-- @v The value to get the zero-padded hex representation of.
function toHex16( v )
    return string.format( "%04x", v )
end

-- Print a hexdump of a table of values to stdout in the form:
-- address: val val val...
-- address + 16: val val val...
--
-- @values The table of values to print. This table must be indexed in the
-- range 1--numValues with no holes.
-- @startAddress The address of the first word to be printed.
function hexDump( values, startAddress )
    count = #values

    local i = 1
    local j = 0

    while ( i + j ) <= count
    do
        io.write( string.format( "0x%04x: ", startAddress + ( i - 1 ) ) )
        while ( i + j ) <= count and j < 8
        do
            io.write( toHex16( values[ i + j ] ) .. " " )
            j = j + 1
        end
        io.write( "\n" )

        if ( i + j ) > count then
            break
        end
        j = 0
        i = i + 8
    end
end

-----------------------------------------------------------------------------
-- Perform a configuration read. The values read are written to stdout.
--
-- @devNum The logical device number to read from.
-- @caeid The CAEID of the AE to read from.
-- @address The address from within the AE to begin reading from.
-- @count The number of 16-bit words to read.
function config_read( devNum,
                      caeid,
                      address,
                      count )
    if devNum == nil or caeid == nil or address == nil or count == nil
    then
        help( config_read )
        return
    end
    vals = picoif.configRead( devNum, caeid, address, count )
    hexDump( vals, address )
end

onlineHelp[ config_read ] = [[
Read a series of 16-bit words from the configuration bus and write the results
to stdout.

  config_read( devNum, caeid, address, count )

    @devNum: The logical device number of the picoArray to read from.
    @caeid: The CAEID of the AE.
    @address: The address inside the AE to begin writing to.
    @count: The number of words to read.

EXAMPLE:
  picoifapp> config_read( 0, 0x48, 0x0030, 1 )
  0x0030: 0010
]]

onlineHelp[ picoif.configRead ] = [[
Read a series of 16-bit words from the configuration bus into a Lua table.

  picoif.configRead( devNum, caeid, address, count )

    @devNum: The logical device number of the picoArray to read from.
    @caeid: The CAEID of the AE.
    @address: The address inside the AE to begin writing to.
    @count: The number of words to read.
    @return: Returns a Lua table of values read from the config bus indexed
             1->count.

EXAMPLE:
  picoifapp> vals = config_read( 0, 0x48, 0x0030, 1 )
  picoifapp> for k,v in ipairs( vals ) do print( v ) end
  16
]]

-----------------------------------------------------------------------------
-- Perform a configuration write.
--
-- @devNum The logical device number to write to.
-- @caeid The CAEID of the AE to write to.
-- @address The address from within the AE to begin writing to.
-- @count A table of 16-bit integers to write into the AE.
function config_write( devNum,
                       caeid,
                       address,
                       values )
    if devNum == nil or caeid == nil or address == nil or values == nil
    then
        help( config_write )
        return
    end
    -- Check that all of the values are within the range 0--0xFFFF. All values
    -- must be 16-bit integers.
    for k, v in ipairs( values )
    do
        if v > 0xFFFF then
            error( string.format( "values[%i] out of range (%04x)\n",
                                  k, v ) )
        end
    end

    picoif.configWrite( devNum, caeid, address, values )
end

onlineHelp[ config_write ] = [[
Write a series of 16-bit words to the configuration bus.

  config_write( devNum, caeid, address, values )

    @devNum: The logical device number of the picoArray to write to.
    @caeid: The CAEID of the AE.
    @address: The address inside the AE to begin writing to.
    @values: A Lua table of values to write.

EXAMPLE:
  picoifapp> config_write( 0, 0x2418, 0xA060, { 0 } )
]]

onlineHelp[ picoif.configWrite ] = [[
Write a series of 16-bit words to the configuration bus from a Lua table.

  picoif.configWrite( devNum, caeid, address, values )

    @devNum: The logical device number of the picoArray to write to.
    @caeid: The CAEID of the AE.
    @address: The address inside the AE to begin writing to.
    @values: A Lua table of values to write.

EXAMPLE:
  picoifapp> config_write( 0, 0x2428, 0x0000, { 0x0000, 0x0001 } )
]]

-----------------------------------------------------------------------------
-- Read a general purpose register (GPR) in a picoArray and print the value to
-- stdout.
--
-- @devNum The logical device number of the picoArray to read the
-- register from.
-- @registerNum The name of the register to read (taken from the
-- picoifGPRId_t enumeration for the device type.
function register_read( devNum,
                        registerNum )
    if devNum == nil or registerNum == nil
    then
        help( register_read )
        return
    end
    val = picoif.registerRead( devNum, registerNum )
    io.write( registerNum .. ": " .. string.format( "%08x\n", val ) )
end

onlineHelp[ register_read ] = [[
Read the value of a general purpose register (GPR) in a picoArray. The value
of the register is printed to stdout.

  register_read( devNum, registerNum )

    @devNum: The logical device number of the picoArray to read from.
    @registerNum: The name of the register to read from. This should be taken
                  from the picoifGPRId_t enum in libpicoif.

EXAMPLE:
  picoifapp> register_read( 0, "PC202_GPR_PROCIF_0" )
  PC202_GPR_PROCIF_0: 00000000
]]

onlineHelp[ picoif.registerRead ] = [[
Read the value of a general purpose register (GPR) in a picoArray.

  picoif.registerRead( devNum, registerNum )

    @devNum: The logical device number of the picoArray to read from.
    @registerNum: The name of the register to read from. This should be taken
                  from the picoifGPRId_t enum in libpicoif.
    @return Returns the value of the register.

EXAMPLE:
  picoifapp> v = picoif.registerRead( 0, "PC202_GPR_PROCIF_0" )
  picoifapp> print( v )
  32
]]

-----------------------------------------------------------------------------
-- Write a general purpose register (GPR) in a picoArray.
--
-- @devNum The logical device number of the picoArray to write the
-- register to.
-- @registerNum The name of the register to write (taken from the
-- picoifGPRId_t enumeration for the device type.
-- @value The value to write into the register.
function register_write( devNum,
                         registerNum,
                         value )
    if devNum == nil or registerNum == nil or value == nil
    then
        help( register_write )
        return
    end
    picoif.registerWrite( devNum, registerNum, value )
end

onlineHelp[ register_write ] = [[
Write a general purpose register (GPR) in a picoArray.

  register_write( devNum, registerNum, value )

    @devNum: The logical device number of the picoArray to write to.
    @registerNum: The name of the register to write to. This should be taken
                  from the picoifGPRId_t enum in libpicoif.
    @value: The value to write to the register.

EXAMPLE:
  picoifapp> register_write( 0, "PC202_GPR_AHB2PICO_1", 0xdeadbeef )
]]

onlineHelp[ picoif.registerWrite ] = [[
Write the value of a general purpose register (GPR) in a picoArray.

  picoif.registerWrite( devNum, registerNum, value )

    @devNum: The logical device number of the picoArray to write to.
    @registerNum: The name of the register to write. This should be taken
                  from the picoifGPRId_t enum in libpicoif.

EXAMPLE:
  picoifapp> picoif.registerWrite( 0, "PC202_GPR_PROCIF_0", 0x12345678 )
]]

-----------------------------------------------------------------------------
-- Reset all of the picoArray devices in the system.
function reset()
    picoif.resetAll()
end

onlineHelp[ reset ] = [[
Reset all of the picoArray devices.

  reset()

EXAMPLE:
  picoifapp> reset()
]]

onlineHelp[ picoif.resetAll ] = [[
Reset all of the picoArray devices.

  picoif.resetAll()

EXAMPLE:
  picoifapp> picoif.resetAll()
]]

-----------------------------------------------------------------------------
-- Start all of the picoArray devices running.
function start()
    picoif.startAll()
end

onlineHelp[ start ] = [[
Start all of the picoArray devices.

  start()

EXAMPLE:
  picoifapp> start()
]]

onlineHelp[ picoif.startAll ] = [[
Start all of the picoArray devices running.

  picoif.startAll()

EXAMPLE:
  picoifapp> picoif.startAll()
]]

-----------------------------------------------------------------------------
-- Stop all of the picoArray devices running.
function stop()
    picoif.stopAll()
end

onlineHelp[ stop ] = [[
Stop all of the picoArray devices.

  stop()

EXAMPLE:
  picoifapp> stop()
]]

onlineHelp[ picoif.stopAll ] = [[
Stop all of the picoArray devices running.

  picoif.stopAll()

EXAMPLE:
  picoifapp> picoif.stopAll()
]]

-----------------------------------------------------------------------------
-- Get the number of devices in the picoArray system and print the result to
-- stdout.
function num_devices()
    print( picoif.numDevices() )
end

onlineHelp[ num_devices ] = [[
Get the number of picoArray devices in the system and print the result to
stdout.

  num_devices()

EXAMPLE:
  picoifapp> num_devices()
  1
]]

onlineHelp[ picoif.numDevices ] = [[
Get the number of picoArray devices in the system.

  picoif.numDevices()

    @return Returns the number of devices in the system.

EXAMPLE:
  picoifapp> nd = picoif.numDevices()
  picoifapp> print( nd )
  1
]]

-----------------------------------------------------------------------------
-- Generate a corefile for the system and write it to a file.
--
-- No interactive wrapper.
--
onlineHelp[ picoif.dumpSystem ] = [[
Generate a corefile for the picoArray system and write it to a file.

  picoif.dumpSystem( fileName )

    @fileName: The name of the file to create.

EXAMPLE:
  picoifapp> picoif.dumpSystem( "corefile.pd" )
]]

-----------------------------------------------------------------------------
-- Dump the specified part of a memory and write it to a file if specified.
--
-- No interactive wrapper.
--
onlineHelp[ picoif.memoryRead ] = [[
Read a region of the memory beginning at the starting address and write
to the file if specified.

  picoif.memoryRead( devNum, address, count, memType, fileName )

    @devNum: The logical device number of the picoArray to read from.
    @address: The starting location for the read.
    @count The number of 16-bit words to read.
    @memType The type of memory to read (taken from the
             picoifMemoryTypeId_t enumeration).
    @fileName The filename to write the memory to (an optional
              parameter which defaults to stdout)

EXAMPLE:
  picoifapp> picoif.memoryRead( 0, 0x10000000, 16, "PICO_MEM_SDRAM" )
]]

-----------------------------------------------------------------------------
-- Write the specified part of a memory with the data provided.
--
-- No interactive wrapper.
--
onlineHelp[ picoif.memoryWrite ] = [[
Write a region of the memory beginning at the starting address.

  picoif.memoryWrite( devNum, address, memType, data )

    @devNum: The logical device number of the picoArray to read from.
    @address: The starting location for the read.
    @memType: The type of memory to read (taken from the
              picoifMemoryTypeId_t enumeration).
    @data: The data to be written. A Lua table.

EXAMPLE:
  picoifapp> picoif.memoryWrite( 0, 0x10000000, "PICO_MEM_SDRAM", {0, 1} )
]]

-----------------------------------------------------------------------------
-- Load a picoArray with a specified loadfile.
--
-- No interactive wrapper.
--
onlineHelp[ picoif.loadFile ] = [[
Load a picoArray with a specified loadfile.

  picoif.loadFile( devNum, loadFileName )

    @devNum: The logical device number of the picoArray to load.
    @loadFileName: The name of the loadfile.

EXAMPLE:
  picoifapp> picoif.loadFile( 0, "loadfile.pa" )
]]

-----------------------------------------------------------------------------
-- Load a picoArray with a specified binary loadfile.
--
-- No interactive wrapper.
--
onlineHelp[ picoif.loadBinaryFile ] = [[
Load a specified device with a binary picoArray loadfile.

  picoif.loadBinaryFile( devNum, loadFileName )

    @devNum: The logical device number of the picoArray to load
    @loadFileName: The loadfile to use

EXAMPLE:
  picoifapp> picoif.loadBinaryFile( 0, "/root/loadfile.pico" )
]]

-----------------------------------------------------------------------------
-- Exit picoifapp
function exit()
    os.exit();
end

onlineHelp[ exit ] = [[
Exit picoifapp and return to the shell.

EXAMPLE:
  picoifapp> exit()
]]

-----------------------------------------------------------------------------
function help( func )
    -- The onlineHelp table is indexed using functions.
    if type( func ) == "function" then
        h = onlineHelp[ func ]
        if h ~= nil then
            print( h )
            return
        end
    end

    -- When nothing is found, simply provide an alphabetical list
    -- of those functions which have online help.
    print("Use help(<command>) to get help on one of the following:")
    names = {}
    for k, v in pairs( onlineHelp ) do
        table.insert( names, findFunctionName(k) )
    end
    table.sort( names )
    for k, v in ipairs(names) do
        print( "  ", v )
    end
end

-- Turn a function reference into a name. Search the global namespace
-- and the picoif namespace.
function findFunctionName ( func )
    for k, v in pairs(_G) do
        if v == func then
            return k
        end
    end
    for k, v in pairs(picoif) do
        if v == func then
            return "picoif."..k
        end
    end
    return "Function not found"
end
