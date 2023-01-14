
# APHELION EMULATOR 2.0
# BY TECHNICHRON

import std/strutils, std/sequtils

var MemorySpace: array[0x10000, uint8]

proc loadAMG(memarray: var array[0x10000, uint8], path: string) =
    let amg = readFile(path)
    if amg.len() == 0x10000:
        for index in 0..0xFFFF:
            memarray[index] = uint8(amg[index])
        echo "image loaded"
    else:
        echo "image file is improper length: 65536 bytes expected, got ", len(amg), " bytes"