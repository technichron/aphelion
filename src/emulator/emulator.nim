
# ╔═══════════════════════╗
# ║ APHELION EMULATOR 2.0 ║
# ╚═══════════════════════╝

import std/strutils, std/sequtils, std/bitops, std/os

const RegA  = 0b00000   # general
const RegB  = 0b00001   # general
const RegC  = 0b00010   # general
const RegD  = 0b00011   # general
const RegE  = 0b00100   # general
const RegF  = 0b00101   # flags                               00[carry][borrow][greater][equal][less][zero]
const RegG  = 0b00110   # general   UNSAFE                  * reccomended for use w/ macro unpacking
const RegIL = 0b01000   # general - low  byte of I
const RegIH = 0b11000   # general - high byte of I
const RegJL = 0b01001   # general - low  byte of J
const RegJH = 0b11001   # general - high byte of J
const RegKL = 0b01010   # general - low  byte of K
const RegKH = 0b11010   # general - high byte of K
const RegPL = 0b01011   # program counter - low  byte of P
const RegPH = 0b11011   # program counter - high byte of P
const RegSL = 0b01100   # stack pointer - low  byte of S
const RegSH = 0b11100   # stack pointer - high byte of S
const RegRL = 0b01101   # return pointer - low  byte of R
const RegRH = 0b11101   # return pointer - high byte of R

const DRegI = 0b01000   # general
const DRegJ = 0b01001   # general
const DRegK = 0b01010   # general
const DRegP = 0b01011   # program counter
const DRegS = 0b01100   # stack pointer   * initialized to the top of ram, 0xFFF0
const DRegR = 0b01101   # return pointer
const ProgramCounter = 0b01011 # alias for DregP

const FlagCARRY   = 0b00100000
const FlagBORROW  = 0b00010000
const FlagGREATER = 0b00001000
const FlagEQUAL   = 0b00000100
const FlagLESS    = 0b00000010
const FlagZERO    = 0b00000001

var MemorySpace: array[0x10000, uint8]
var Registers: array[30, uint8]
var BIB: array[5, uint8] # binary instruction buffer - for reading bytes straight from the file
var IB: array[3, uint16] # (clean) instruction buffer - [opcode, arg1, arg2]

proc loadAMG(memarray: var array[0x10000, uint8], path: string) =
    let amg = readFile(path)
    if amg.len() == 0x10000:
        for index in 0..0xffff:
            memarray[index] = uint8(amg[index])
        echo "\"", path, "\"", " loaded successfully"
    else:
        echo "\"", path, "\"", ": expected 65536 bytes, got ", len(amg), " bytes"

proc getInstructionFormat(opcode: uint8): string =
    case opcode
        of 0x00, 0x1d, 0x3f:
            return "NA"
        of 0x1e, 0x1f, 0x22, 0x23, 0x2c, 0x2d:
            return "RE"
        of 0x02, 0x03, 0x09, 0x0b, 0x0d, 0x0f, 0x11, 0x13, 0x15, 0x17, 0x24, 0x26, 0x28, 0x2a, 0x2e, 0x30, 0x32, 0x34, 0x3d:
            return "RR"
        of 0x20:
            return "BY"
        of 0x04, 0x0a, 0x0e, 0x12, 0x16, 0x25, 0x29, 0x2f, 0x33, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b, 0x19, 0x1a:
            return "RB"
        of 0x21:
            return "DO"
        of 0x01, 0x06, 0x07, 0x0c, 0x10, 0x14, 0x18, 0x27, 0x2b, 0x31, 0x35, 0x3c:
            return "RD"
        of 0x05, 0x1b, 0x1c:
            return "BD"
        of 0x08:
            return "DD"
        else:
            return "INVALID"

proc getInstructionLength(opcode: uint8): int =
    case getInstructionFormat(opcode)
        of "NA":
            return 1
        of "RE", "RR", "BY":
            return 2
        of "RB", "DO":
            return 3
        of "RD", "BD":
            return 4
        of "DD":
            return 5

proc charOut(value: uint8) = # add w/ window support
    discard

proc charIn(): uint8 = 0x00  # add w/ window support

proc read(address: uint16): uint8 =
    if address == 0xffff:
        return charIn()
    else:
        return MemorySpace[address]

proc write(address: uint16, value: uint8) =
    if address >= 0x9000 and address <= 0xfffe: # check if in RAM or RESERVED
        MemorySpace[address] = value
    elif address == 0xffff:
        charOut(value)

proc readRegister(code: int): uint8 =
    return Registers[code]

proc writeRegister(code: int, value: uint8) =
    Registers[code] = value

proc readDoubleRegister(code: int): uint16 =
    return uint16(Registers[code+16]*256 + Registers[code])

proc writeDoubleRegister(code: int, value: uint16) =
    Registers[code] = uint8(value.bitsliced(0..7))
    Registers[code+16] = uint8(value.bitsliced(8..15))

proc readFlag(code: uint8): bool = bitand(code, Registers[RegF]).bool

proc writeFlag(code: uint8, value: bool) = 
    if value:
        Registers[RegF].setBit(fastLog2(code))
    else:
        Registers[RegF] = bitand(Registers[RegF], bitnot(code))

# ----------------------------- time to run shit ----------------------------- #

MemorySpace.loadAMG("amgs/empty.amg")

var running = true
while running:

    BIB[0] = read(readDoubleRegister(ProgramCounter))
    let opcode = BIB[0].bitsliced(2..7)
    for byt in 1..<opcode.getInstructionLength():
        BIB[byt] = read(readDoubleRegister(ProgramCounter)+byt.uint16)
    
    # parse instructions
    IB[0] = opcode
    case opcode.getInstructionFormat()
        of "NA":
            discard
        of "RE":
            IB[1] = BIB[1].bitsliced(3..7)
        of "RR":
            IB[1] = ((BIB[0]*256)+BIB[1]).bitsliced(5..9).uint16
            IB[1] = ((BIB[0]*256)+BIB[1]).bitsliced(5..9).uint16
        of "BY":
            IB[1] = BIB[1].uint16
        of "RB":
            IB[1] = BIB[1].bitsliced(3..7).uint16
            IB[2] = BIB[2].uint16
        of "DO":
            IB[1] = ((BIB[2]*256)+BIB[1]).uint16
        of "RD":
            IB[1] = BIB[1].bitsliced(3..7).uint16
            IB[2] = ((BIB[3]*256)+BIB[2]).uint16
        of "BD":
            IB[1] = BIB[1]
            IB[2] = ((BIB[3]*256)+BIB[2]).uint16
        of "DD":
            IB[1] = ((BIB[2]*256)+BIB[1]).uint16
            IB[2] = ((BIB[4]*256)+BIB[3]).uint16
        
    running = false