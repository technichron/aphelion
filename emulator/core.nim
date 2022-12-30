# APHELION EMULATOR 1.0
# BY TECHNICHRON

import std/strutils, std/sequtils, std/bitops

# ----------------------------------- setup ---------------------------------- #

var Memory: array[65536, uint8]

var ProgramCounter:uint16 = 0
var CurrentInstructionBuffer: array[3, uint8]

var Registers: array[8, uint8]
# A - 0b000 - general
# B - 0b001 - general
# C - 0b010 - general
# D - 0b011 - general
# E - 0b100 - general
# L - 0b101 - general / low index register
# H - 0b110 - general / high index register
# F - 0b111 - flags: 000, carry, borrow, equal, less, zero

var running = true

proc binConcat(a,b: uint8): uint16 = uint16(a*256 + b)

proc getHL(): uint16 = binConcat(Registers[0b110], Registers[0b101])

proc getMemoryRegion(address: uint16): string =
    if address == 0xFFFF:
        result = "CHAR OUT"
    elif address >= 0xFFF3:
        result = "UNUSED"
    elif address >= 0xFFF1:
        result = "PROGRAM COUNTER"
    elif address >= 0x9000:
        result = "RAM"
    elif address >= 0:
        result = "ROM"

proc getInstructionLength(instruction: uint8): int =
    case instruction.bitsliced(3..7)    # instruction.bitsliced(3..7) = opcode

    #NOP, LW R, SW R, JMP R, JNZ R, NOT, HALT
    of 0b00000, 0b00100, 0b00110, 0b10000, 0b10010, 0b11000, 0b11111:
        result = 1
    
    #SET R, SET I, ADD R, ADD I, ADC R, ADC I, SUB R, SUB I, SBB R, SBB I, AND R, AND I, OR R, OR I, CMP R, CMP I
    of 0b00010, 0b00011, 0b01000, 0b01001, 0b01010, 0b01011, 0b01100, 0b01101, 0b01110, 0b01111, 0b10100, 0b10101, 0b10110, 0b10111, 0b11010, 0b11011:
        result = 2
    
    #LW I, SW I, JMP I, JNZ I
    of 0b00101, 0b00111, 0b10001, 0b10011:
        result = 3
    else:
        result = 0

proc read(address: uint16): uint8 =
    result = Memory[address]

proc write(address: uint16, data: uint8) =
    if address.getMemoryRegion() == "RAM":
        Memory[address] = data
    if address.getMemoryRegion() == "CHAR OUT":
        stdout.write(char(data))

proc exit() =
    running = false

# -------------------------- loading rom into memory ------------------------- #

let rom = readFile("assembler/output.bin")
if rom.len() <= 0x9000:
    echo "rom length: ", rom.len(), " bytes"
    echo "loading rom..."
    for index in rom.low()..rom.high():
        Memory[index] = uint8(rom[index])
else:
    echo "error: rom is length ", rom.len(), "b, expected <= ", 0x9000, "b"
    running = false







var actingRegisterOne: uint8
var actingRegisterTwo: uint8

while running:

# ----------------------------------- fetch ---------------------------------- #

    CurrentInstructionBuffer[0] = read(ProgramCounter) # read initial byte at instruction counter

    for i in 0..<getInstructionLength(CurrentInstructionBuffer[0]):
        CurrentInstructionBuffer[i] = read(ProgramCounter+uint16(i))    # load instruction buffer with current  instruction

# ---------------------------------- execute --------------------------------- #
    echo "=========================="
    echo "address: ", ProgramCounter

    case CurrentInstructionBuffer[0].bitsliced(3..7)
    of 0b00000:
        echo "NOP"
        discard

    of 0b00010:
        echo "SET REGISTER"

        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)
        actingRegisterTwo = CurrentInstructionBuffer[1].bitsliced(0..2)

        Registers[actingRegisterOne] = Registers[actingRegisterTwo]

    of 0b00011:
        echo "SET IMMEDIATE"

        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)

        Registers[actingRegisterOne] = CurrentInstructionBuffer[1]

    of 0b00100:
        echo "LW REGISTER"

        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)

        Registers[actingRegisterOne] = read(getHL())

    of 0b00101:
        echo "LW IMMEDIATE"

    of 0b00110:
        echo "SW REGISTER"

    of 0b00111:
        echo "SW IMMEDIATE"

    of 0b01000:
        echo "ADD REGISTER"

    of 0b01001:
        echo "ADD IMMEDIATE"

    of 0b01010:
        echo "ADC REGISTER"

    of 0b01011:
        echo "ADC IMMEDIATE"
    
    of 0b01100:
        echo "SUB REGISTER"

    of 0b01101:
        echo "SUB IMMEDIATE"

    of 0b01110:
        echo "SBB REGISTER"

    of 0b01111:
        echo "SBB IMMEDIATE"

    of 0b10000:
        echo "JMP REGISTER"

    of 0b10001:
        echo "JMP IMMEDIATE"

    of 0b10010:
        echo "JNZ REGISTER"

    of 0b10011:
        echo "JNZ IMMEDIATE"

    of 0b10100:
        echo "AND REGISTER"

    of 0b10101:
        echo "AND IMMEDIATE"

    of 0b10110:
        echo "OR REGISTER"

    of 0b10111:
        echo "OR IMMEDIATE"

    of 0b11000:
        echo "NOT REGISTER"

    of 0b11010:
        echo "CMP REGISTER"

    of 0b11011:
        echo "CMP IMMEDIATE"

    of 0b11111:
        echo "HALT"
        exit()
    else:
        echo "INVALID INSTRUCTION, EXITING"
        exit()
    

    ProgramCounter += uint16(getInstructionLength(CurrentInstructionBuffer[0]))    # increment program counter to location of next instruction