
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
const ProgramCounter = 0b01011 # alias for DRegP

const FlagCARRY   = 0b00100000
const FlagBORROW  = 0b00010000
const FlagGREATER = 0b00001000
const FlagEQUAL   = 0b00000100
const FlagLESS    = 0b00000010
const FlagZERO    = 0b00000001

var MemorySpace: array[0x10000, uint8]
var Registers: array[30, uint8]
var BIB: array[5, uint8] # binary instruction buffer - for reading bytes straight from the file
var IB: array[3, int] # (clean) instruction buffer - [opcode, arg1, arg2]

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

proc read(address: SomeInteger): uint8 =
    if address == 0xffff:
        return charIn()
    else:
        return MemorySpace[address]

proc write(value: uint8, address: SomeInteger) =
    if address >= 0x9000 and address <= 0xfffe: # check if in RAM or RESERVED
        MemorySpace[address] = value
    elif address == 0xffff:
        charOut(value)

proc readRegister(code: int): uint8 =
    return Registers[code]

proc writeRegister(value: uint8, code: int) =
    Registers[code] = value

proc readDoubleRegister(code: int): uint16 =
    return uint16(Registers[code+16]*256 + Registers[code])

proc writeDoubleRegister(value: uint16, code:int) =
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
    
    # parse instruction and organize instruction buffer
    IB[0] = opcode.int
    case opcode.getInstructionFormat()
        of "NA":
            discard
        of "RE":
            IB[1] = BIB[1].bitsliced(3..7).int
        of "RR":
            IB[1] = ((BIB[0]*256)+BIB[1]).bitsliced(5..9).int
            IB[2] = ((BIB[0]*256)+BIB[1]).bitsliced(0..4).int
        of "BY":
            IB[1] = BIB[1].int
        of "RB":
            IB[1] = BIB[1].bitsliced(3..7).int
            IB[2] = BIB[2].int
        of "DO":
            IB[1] = ((BIB[2]*256)+BIB[1]).int
        of "RD":
            IB[1] = BIB[1].bitsliced(3..7).int
            IB[2] = ((BIB[3]*256)+BIB[2]).int
        of "BD":
            IB[1] = BIB[1].int
            IB[2] = ((BIB[3]*256)+BIB[2]).int
        of "DD":
            IB[1] = ((BIB[2]*256)+BIB[1]).int
            IB[2] = ((BIB[4]*256)+BIB[3]).int
    
    writeDoubleRegister(readDoubleRegister(ProgramCounter)+getInstructionLength(opcode).uint16, ProgramCounter)

    case IB[0]

        of 0x00:    # nop                         0x00 0b000000 NA
            discard

        # mov (src), (dest)           copy data from (src) to (dest)

        of 0x01:    # mov reg, $imm16             0x01 0b000001 RD
            write(readRegister(IB[1]), IB[2])
        of 0x02:    # mov reg, reg                0x02 0b000010 RR
            writeRegister(readRegister(IB[1]), IB[2])
        of 0x03:    # mov dreg, dreg              0x03 0b000011 RR
            writeDoubleRegister(readDoubleRegister(IB[1]), IB[2])
        of 0x04:    # mov imm8, reg               0x04 0b000100 RB
            writeRegister(IB[1].uint8, IB[2])
        of 0x05:    # mov imm8, $imm16            0x05 0b000101 BD
            write(IB[1].uint8, IB[2])
        of 0x06:    # mov imm16, dreg             0x06 0b000110 RD
            writeDoubleRegister(IB[1].uint16, IB[2])
        of 0x07:    # mov $imm16, reg             0x07 0b000111 RD
            writeRegister(read(IB[1]), IB[2])
        of 0x08:    # mov $imm16, $imm16          0x08 0b001000 DD
            write(read(IB[1]), IB[2])
        of 0x3c:    # mov $dreg, $imm16           0x3C 0b001000 RD
            write(read(readDoubleRegister(IB[1])), IB[2])
        of 0x3d:    # mov $dreg, dreg             0x3D 0b001000 RR
            writeDoubleRegister(read(readDoubleRegister(IB[1])), IB[2])

        # add (op1), (op2)            (op1) = (op1) + (op2)

        of 0x09:    # add reg, reg                0x09 0b001001 RR
            writeFlag(FlagCARRY, readRegister(IB[1]) > (readRegister(IB[1]) + readRegister(IB[2])) or readRegister(IB[2]) > (readRegister(IB[1]) + readRegister(IB[2])))
            writeRegister(readRegister(IB[1])+readRegister(IB[2]), IB[1])
        of 0x0a:    # add reg, imm8               0x0A 0b001010 RB
            writeFlag(FlagCARRY, readRegister(IB[1]) > (readRegister(IB[1])+IB[2].uint8) or IB[2].uint8 > (readRegister(IB[1])+IB[2].uint8))
            writeRegister(readRegister(IB[1])+IB[2].uint8, IB[1])
        of 0x0b:    # add dreg, dreg              0x0B 0b001011 RR
            writeFlag(FlagCARRY, readDoubleRegister(IB[1]) > (readDoubleRegister(IB[1]) + readDoubleRegister(IB[2])) or readDoubleRegister(IB[2]) > (readDoubleRegister(IB[1]) + readDoubleRegister(IB[2])))
            writeDoubleRegister(readDoubleRegister(IB[1])+readDoubleRegister(IB[2]), IB[1])
        of 0x0c:    # add dreg, imm16             0x0C 0b001100 RD
            writeFlag(FlagCARRY, readDoubleRegister(IB[1]) > (readDoubleRegister(IB[1])+IB[2].uint16) or IB[2].uint16 > (readDoubleRegister(IB[1])+IB[2].uint16))
            writeDoubleRegister(readDoubleRegister(IB[1])+IB[2].uint16, IB[1])

        # adc (op1), (op2)            (op1) = (op1) + (op2) + CARRY
    
        of 0x0d:    # adc reg, reg                0x0D 0b001101 RR
            writeRegister(readRegister(IB[1])+readRegister(IB[2])+readFlag(FlagCARRY).uint8, IB[1])
        of 0x0e:    # adc reg, imm8               0x0E 0b001110 RB
            writeRegister(readRegister(IB[1])+IB[2].uint8+readFlag(FlagCARRY).uint8, IB[1])
        of 0x0f:    # adc dreg, dreg              0x0F 0b001111 RR
            writeDoubleRegister(readDoubleRegister(IB[1])+readDoubleRegister(IB[2])+readFlag(FlagCARRY).uint8, IB[1])
        of 0x10:    # adc dreg, imm16             0x10 0b010000 RD
            writeDoubleRegister(readDoubleRegister(IB[1])+IB[2].uint16+readFlag(FlagCARRY).uint16, IB[1])
        
        # sub (op1), (op2)            (op1) = (op1) - (op2)

        of 0x11:    # sub reg, reg                0x11 0b010001 RR
            writeRegister(readRegister(IB[1])-readRegister(IB[2]), IB[1])
        of 0x12:    # sub reg, imm8               0x12 0b010010 RB
            writeRegister(readRegister(IB[1])-IB[2].uint8, IB[1])
        of 0x13:    # sub dreg, dreg              0x13 0b010011 RR
            writeDoubleRegister(readDoubleRegister(IB[1])-readDoubleRegister(IB[2]), IB[1])
        of 0x14:    # sub dreg, imm16             0x14 0b010100 RD
            writeDoubleRegister(readDoubleRegister(IB[1])-IB[2].uint16, IB[1])
        
        # sbb (op1), (op2)            (op1) = (op1) - (op2) - BORROW
    
        of 0x15:    # sbb reg, reg                0x15 0b010101 RR
            writeRegister(readRegister(IB[1])-readRegister(IB[2])-readFlag(FlagBORROW).uint8, IB[1])
        of 0x16:    # sbb reg, imm8               0x16 0b010110 RB
            writeRegister(readRegister(IB[1])-IB[2].uint8-readFlag(FlagBORROW).uint8, IB[1])
        of 0x17:    # sbb dreg, dreg              0x17 0b010111 RR
            writeDoubleRegister(readDoubleRegister(IB[1])-readDoubleRegister(IB[2])-readFlag(FlagBORROW).uint8, IB[1])
        of 0x18:    # sbb dreg, imm16             0x18 0b011000 RD
            writeDoubleRegister(readDoubleRegister(IB[1])-IB[2].uint16-readFlag(FlagBORROW).uint16, IB[1])
        
        # jif (flags), (loc)          set program counter to (loc) if F & (flags) == (flags)

        of 0x1b:    # jif imm8, label/$imm16      0x1B 0b011011 BD
            if bitand(IB[1].uint8, readRegister(RegF)) == IB[1].uint8: writeDoubleRegister(IB[2].uint16, ProgramCounter)
        of 0x19:    # jif imm8, $dreg             0x19 0b011001 RB
            if bitand(IB[2].uint8, readRegister(RegF)) == IB[2].uint8: writeDoubleRegister(readRegister(IB[1]), ProgramCounter)
        
        # cif (flags), (loc)          set program counter to (loc) and set R to address of the following instruction if F & (flags) == (flags)

        of 0x1c:    # cif imm8, label/$imm16      0x1C 0b011100 BD
            if bitand(IB[1].uint8, readRegister(RegF)) == IB[1].uint8:
                writeDoubleRegister(readDoubleRegister(ProgramCounter), DRegR)
                writeDoubleRegister(IB[2].uint16, ProgramCounter)
        of 0x1a:    # cif imm8, $dreg             0x1A 0b011010 RB
            if bitand(IB[2].uint8, readRegister(RegF)) == IB[2].uint8:
                writeDoubleRegister(readDoubleRegister(ProgramCounter), DRegR)
                writeDoubleRegister(readRegister(IB[1]), ProgramCounter)
        
        # ret                         set program counter to R\
        
        of 0x1d:    # ret                         0x1D 0b011101 NA
            writeDoubleRegister(readDoubleRegister(DRegR), ProgramCounter)
        
        # push (value)                push (value) onto stack         * stack pointer decrements, most significant byte of int16 pushed first

        of 0x1e:    # push reg                    0x1E 0b011110 RE
            writeDoubleRegister(readDoubleRegister(DRegS)-1, DRegS)
            write(readRegister(IB[1]), readDoubleRegister(DRegS))
        of 0x1f:    # push dreg                   0x1F 0b011111 RE
            writeDoubleRegister(readDoubleRegister(DRegS)-2, DRegS)
            write(readDoubleRegister(IB[1]).uint8+0b10000, readDoubleRegister(DRegS)+1)
            write(readRegister(IB[1]), readDoubleRegister(DRegS))
        of 0x20:    # push imm8                   0x20 0b100000 BY
            writeDoubleRegister(readDoubleRegister(DRegS)-1, DRegS)
            write(IB[1].uint8, readDoubleRegister(DRegS))
        of 0x21:    # push imm16                  0x21 0b100001 DO
            writeDoubleRegister(readDoubleRegister(DRegS)-2, DRegS)
            write(IB[1].bitsliced(8..15).uint8, readDoubleRegister(DRegS)+1)
            write(IB[1].bitsliced(0..7).uint8, readDoubleRegister(DRegS))
        
        # pop (dest)                  pop value from stack to (dest)  * stack pointer increments

        of 0x22:    # pop reg                     0x22 0b100010 RE
            writeRegister(read(readDoubleRegister(DregS)), IB[1])
            writeDoubleRegister(readDoubleRegister(DRegS)+1, DRegS)
        of 0x23:    # pop dreg                    0x23 0b100011 RE
            writeDoubleRegister((read(readDoubleRegister(DregS)-1)*256+read(readDoubleRegister(DregS))).uint16, IB[1])
            writeDoubleRegister(readDoubleRegister(DRegS)+2, DRegS)
        
        # and (op1), (op2)            (op1) = (op1) & (op2)

        of 0x24:    # and reg, reg                0x24 0b100100 RR
            writeRegister(bitand(readRegister(IB[1]),readRegister(IB[2])), IB[1])
        of 0x25:    # and reg, imm8               0x25 0b100101 RB
            writeRegister(bitand(readRegister(IB[1]),IB[2].uint8), IB[1])
        of 0x26:    # and dreg, dreg              0x26 0b100110 RR
            writeDoubleRegister(bitand(readDoubleRegister(IB[1]),readDoubleRegister(IB[2])), IB[1])
        of 0x27:    # and dreg, imm16             0x27 0b100111 RD
            writeDoubleRegister(bitand(readDoubleRegister(IB[1]),IB[2].uint16), IB[1])
        
        # or (op1), (op2)             (op1) = (op1) | (op2)

        of 0x28:    # or reg, reg                 0x28 0b101000 RR
            writeRegister(bitor(readRegister(IB[1]),readRegister(IB[2])), IB[1])
        of 0x29:    # or reg, imm8                0x29 0b101001 RB
            writeRegister(bitor(readRegister(IB[1]),IB[2].uint8), IB[1])
        of 0x2a:    # or dreg, dreg               0x2A 0b101010 RR
            writeDoubleRegister(bitor(readDoubleRegister(IB[1]),readDoubleRegister(IB[2])), IB[1])
        of 0x2b:    # or dreg, imm16              0x2B 0b101011 RD
            writeDoubleRegister(bitor(readDoubleRegister(IB[1]),IB[2].uint16), IB[1])
        
        # not (op)                    (op) = ! (op)

        of 0x2c:    # not reg                     0x2C 0b101100 RE
            writeRegister(bitnot(readRegister(IB[1])), IB[1])
        of 0x2d:    # not dreg                    0x2D 0b101101 RE
            writeDoubleRegister(bitnot(readDoubleRegister(IB[1])), IB[1])
        
        # cmp (op1), (op2)            compare (op1) and (op2), set relevant flags

        of 0x2e:    # cmp reg, reg                0x2E 0b101110 RR
            writeFlag(FlagGREATER, IB[1].uint8 > readRegister(IB[2]))
            writeFlag(FlagLESS, IB[1].uint8 < readRegister(IB[2]))
            writeFlag(FlagEQUAL, IB[1].uint8 == readRegister(IB[2]))

        else:
            echo "invalid opcode at $", $(readDoubleRegister(ProgramCounter)-getInstructionLength(opcode).uint16)
            running = false
        