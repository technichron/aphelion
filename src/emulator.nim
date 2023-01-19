
# ╔═══════════════════════╗
# ║ APHELION EMULATOR 2.0 ║ by technichron
# ╚═══════════════════════╝

import std/strutils, std/sequtils, std/bitops, std/os

var MemorySpace: array[0x10000, uint8]

var Registers: array[30, uint8]
#     0b00000  A  general
#     0b00001  B  general
#     0b00010  C  general
#     0b00011  D  general
#     0b00100  E  general
#     0b00101  F  flags                               00[carry][borrow][greater][equal][less][zero]
#     0b00110  G  general
#     0b01000  IL general - low  byte of I
#     0b11000  IH general - high byte of I
#     0b01001  JL general - low  byte of J
#     0b11001  JH general - high byte of J
#     0b01010  KL general - low  byte of K
#     0b11010  KH general - high byte of K
#     0b01011  PL program counter - low  byte of P
#     0b11011  PH program counter - high byte of P
#     0b01100  SL stack pointer - low  byte of S
#     0b11100  SH stack pointer - high byte of S
#     0b01101  RL return pointer - low  byte of R
#     0b11101  RH return pointer - high byte of R

proc loadAMG(memarray: var array[0x10000, uint8], path: string) =
    let amg = readFile(path)
    if amg.len() == 0x10000:
        for index in 0..0xffff:
            memarray[index] = uint8(amg[index])
        echo "image loaded"
    else:
        echo ".amg is improper length: expected 65536 bytes, got ", len(amg), " bytes"

proc getInstructionArgtype(opcode: int): string =
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

proc getInstructionLength(opcode: int): int =
    case getInstructionArgtype(opcode)
        of "NA":
            return 1
        of "RE":
            return 2
        of "RR":
            return 2
        of "BY":
            return 2
        of "RB":
            return 3
        of "DO":
            return 3
        of "RD":
            return 4
        of "BD":
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
    if address >= 0x9000 and address <= 0xfffe: # check if it is in RAM or RESERVED
        MemorySpace[address] = value
    elif address == 0xffff:
        charOut(value)

proc getRegister(code: int): uint8 =
    return Registers[code]

proc setRegister(code: int, value: uint8) =
    Registers[code] = value

proc getDoubleRegister(code: int): uint16 =
    return uint16(Registers[code+16]*256 + Registers[code])

proc setDoubleRegister(code: int, value: uint16) =
    Registers[code] = uint8(value.bitsliced(0..7))
    Registers[code+16] = uint8(value.bitsliced(8..15))