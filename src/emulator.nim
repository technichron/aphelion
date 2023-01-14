
# APHELION EMULATOR 2.0
# BY TECHNICHRON

import std/strutils, std/sequtils

var MemorySpace: array[0x10000, uint8]

var Registers: array[19, uint8]
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
        for index in 0..0xFFFF:
            memarray[index] = uint8(amg[index])
        echo "image loaded"
    else:
        echo "image file is improper length: 65536 bytes expected, got ", len(amg), " bytes"

