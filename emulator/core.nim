# APHELION EMULATOR 1.0
# BY TECHNICHRON

import std/bitops

# ----------------------------------- setup ---------------------------------- #

var Memory: array[65536, uint8] # 64k

var ProgramCounter:uint16 = 0
var CurrentInstructionBuffer: array[3, uint8]

var Registers: array[8, uint8]
# A - 0b000 - general
# B - 0b001 - general
# C - 0b010 - general
# D - 0b011 - general
# E - 0b100 - general
# L - 0b101 - general / 16bit low register
# H - 0b110 - general / 16bit high register
# F - 0b111 - flags: 000CBELZ - CARRY, BORROW, EQUAL, LESS, ZERO

var running = true

proc binConcat(h,l: uint8): uint16 = uint16(h*256 + l)

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

proc setFlag(name: string, value: bool = true) =
    case name
    of "carry","CARRY":
        Registers[0b111].setBits(4)
    of "borrow","BORROW":
        Registers[0b111].setBits(3)
    of "equal","EQUAL":
        Registers[0b111].setBits(2)
    of "less","LESS":
        Registers[0b111].setBits(1)
    of "zero","ZERO":
        Registers[0b111].setBits(0)
    else:
        discard

proc getFlag(name: string):bool =
    case name
    of "carry","CARRY":
        result = Registers[0b111].testBit(4)
    of "borrow","BORROW":
        result = Registers[0b111].testBit(3)
    of "equal","EQUAL":
        result = Registers[0b111].testBit(2)
    of "less","LESS":
        result = Registers[0b111].testBit(1)
    of "zero","ZERO":
        result = Registers[0b111].testBit(0)
    else:
        discard

proc read(address: uint16): uint8 =
    result = Memory[address]
    if address == 0xFFF1:
        result = uint8(ProgramCounter.bitsliced(0..7))
    if address == 0xFFF2:
        result = uint8(ProgramCounter.bitsliced(8..15))

proc write(address: uint16, data: uint8) =
    if address.getMemoryRegion() == "RAM":
        Memory[address] = data
    if address.getMemoryRegion() == "CHAR OUT":
        stdout.write(char(data))

proc exit() =
    running = false

# -------------------------- loading rom into memory ------------------------- #

let rom = readFile("T:/vscode/aphelion/assembler/output.bin")
if rom.len() <= 0x9000:
    echo "rom length: ", rom.len(), " bytes"
    echo "loading rom..."
    for index in rom.low()..rom.high():
        Memory[index] = uint8(rom[index])
else:
    echo "error: rom is length ", rom.len(), "b, expected <= ", 0x9000, "b"
    running = false



echo "initializing execution."
echo ""

var actingRegisterOne: uint8
var actingRegisterTwo: uint8

let debug = false

while running:

# ----------------------------------- fetch ---------------------------------- #

    CurrentInstructionBuffer[0] = read(ProgramCounter) # read initial byte at instruction counter

    for i in 0..<getInstructionLength(CurrentInstructionBuffer[0]):
        CurrentInstructionBuffer[i] = read(ProgramCounter+uint16(i))    # load instruction buffer with current  instruction
    
    ProgramCounter += uint16(getInstructionLength(CurrentInstructionBuffer[0]))    # increment program counter to location of next instruction

# ---------------------------------- execute --------------------------------- #
    if debug: echo "=========================="
    if debug: echo "address: ", ProgramCounter - uint16(getInstructionLength(CurrentInstructionBuffer[0]))

    case CurrentInstructionBuffer[0].bitsliced(3..7)
    of 0b00000:
        if debug: echo "NOP"
        discard

    of 0b00010:
        if debug: echo "SET REGISTER"

        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)
        actingRegisterTwo = CurrentInstructionBuffer[1].bitsliced(0..2)

        Registers[actingRegisterOne] = Registers[actingRegisterTwo]

    of 0b00011:
        if debug: echo "SET IMMEDIATE"

        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)

        Registers[actingRegisterOne] = CurrentInstructionBuffer[1]

    of 0b00100:
        if debug: echo "LW REGISTER"

        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)

        Registers[actingRegisterOne] = read(getHL())

    of 0b00101:
        if debug: echo "LW IMMEDIATE"

        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)

        Registers[actingRegisterOne] = read(binConcat(CurrentInstructionBuffer[1], CurrentInstructionBuffer[2]))


    of 0b00110:
        if debug: echo "SW REGISTER"

        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)

        write(getHL(), Registers[actingRegisterOne])

    of 0b00111:
        if debug: echo "SW IMMEDIATE"

        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)

        write(binConcat(CurrentInstructionBuffer[1], CurrentInstructionBuffer[2]), Registers[actingRegisterOne])

    of 0b01000:
        if debug: echo "ADD REGISTER"

        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)
        actingRegisterTwo = CurrentInstructionBuffer[1].bitsliced(0..2)

        let sum = Registers[actingRegisterOne] + Registers[actingRegisterTwo]
        Registers[actingRegisterOne] = sum

        # detect CARRY and set flag
        if  (sum < Registers[actingRegisterOne]) or (sum < Registers[actingRegisterTwo]):
            setFlag("CARRY")

    of 0b01001:
        if debug: echo "ADD IMMEDIATE"

        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)

        let sum = Registers[actingRegisterOne] + CurrentInstructionBuffer[1]
        Registers[actingRegisterOne] = sum

        # detect CARRY and set flag
        if  (sum < Registers[actingRegisterOne]) or (sum < CurrentInstructionBuffer[1]):
            setFlag("CARRY")

    of 0b01010:
        if debug: echo "ADC REGISTER"

        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)
        actingRegisterTwo = CurrentInstructionBuffer[1].bitsliced(0..2)

        let sum = Registers[actingRegisterOne] + Registers[actingRegisterTwo] + uint8(getFlag("CARRY"))
        Registers[actingRegisterOne] = sum

        # detect CARRY and set flag
        if  (sum < Registers[actingRegisterOne]) or (sum < Registers[actingRegisterTwo]):
            setFlag("CARRY")

    of 0b01011:
        if debug: echo "ADC IMMEDIATE"

        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)

        let sum = Registers[actingRegisterOne] + CurrentInstructionBuffer[1] + uint8(getFlag("CARRY"))
        Registers[actingRegisterOne] = sum

        # detect CARRY and set flag
        if  (sum < Registers[actingRegisterOne]) or (sum < CurrentInstructionBuffer[1]):
            setFlag("CARRY")
    
    of 0b01100:
        if debug: echo "SUB REGISTER"

        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)
        actingRegisterTwo = CurrentInstructionBuffer[1].bitsliced(0..2)

        let diff = Registers[actingRegisterOne] - Registers[actingRegisterTwo]
        Registers[actingRegisterOne] = diff

        if  (diff > Registers[actingRegisterOne]) or (diff > Registers[actingRegisterTwo]):
            setFlag("BORROW")

    of 0b01101:
        if debug: echo "SUB IMMEDIATE"

        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)

        let diff = Registers[actingRegisterOne] - CurrentInstructionBuffer[1]
        Registers[actingRegisterOne] = diff

        if  (diff > Registers[actingRegisterOne]) or (diff > CurrentInstructionBuffer[1]):
            setFlag("BORROW")

    of 0b01110:
        if debug: echo "SBB REGISTER"

        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)
        actingRegisterTwo = CurrentInstructionBuffer[1].bitsliced(0..2)

        let diff = Registers[actingRegisterOne] - Registers[actingRegisterTwo] - uint8(getFlag("BORROW"))
        Registers[actingRegisterOne] = diff

        if  (diff > Registers[actingRegisterOne]) or (diff > Registers[actingRegisterTwo]):
            setFlag("BORROW")

    of 0b01111:
        if debug: echo "SBB IMMEDIATE"

        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)

        let diff = Registers[actingRegisterOne] - CurrentInstructionBuffer[1] - uint8(getFlag("BORROW"))
        Registers[actingRegisterOne] = diff

        if  (diff > Registers[actingRegisterOne]) or (diff > CurrentInstructionBuffer[1]):
            setFlag("BORROW")

    of 0b10000:
        if debug: echo "JMP REGISTER"

        ProgramCounter = getHL()

    of 0b10001:
        if debug: echo "JMP IMMEDIATE"

        ProgramCounter = binConcat(CurrentInstructionBuffer[1], CurrentInstructionBuffer[2])

    of 0b10010:
        if debug: echo "JNZ REGISTER"

        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)

        if Registers[actingRegisterOne] != 0:
            ProgramCounter = getHL()

    of 0b10011:
        if debug: echo "JNZ IMMEDIATE"

        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)

        if Registers[actingRegisterOne] != 0:
            ProgramCounter = binConcat(CurrentInstructionBuffer[1], CurrentInstructionBuffer[2])

    of 0b10100:
        if debug: echo "AND REGISTER"

        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)
        actingRegisterTwo = CurrentInstructionBuffer[1].bitsliced(0..2)

        Registers[actingRegisterOne] = bitand(Registers[actingRegisterOne], Registers[actingRegisterTwo])

    of 0b10101:
        if debug: echo "AND IMMEDIATE"

        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)
        
        Registers[actingRegisterOne] = bitand(Registers[actingRegisterOne], CurrentInstructionBuffer[1])

    of 0b10110:
        if debug: echo "OR REGISTER"

        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)
        actingRegisterTwo = CurrentInstructionBuffer[1].bitsliced(0..2)

        Registers[actingRegisterOne] = bitor(Registers[actingRegisterOne], Registers[actingRegisterTwo])

    of 0b10111:
        if debug: echo "OR IMMEDIATE"

        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)
        
        Registers[actingRegisterOne] = bitor(Registers[actingRegisterOne], CurrentInstructionBuffer[1])

    of 0b11000:
        if debug: echo "NOT REGISTER"

        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)

        Registers[actingRegisterOne] = bitnot(Registers[actingRegisterOne])

    of 0b11010:
        if debug: echo "CMP REGISTER"

        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)
        actingRegisterTwo = CurrentInstructionBuffer[1].bitsliced(0..2)

        if Registers[actingRegisterOne] == Registers[actingRegisterTwo]:
            setFlag("EQUAL")
        
        if Registers[actingRegisterOne] < Registers[actingRegisterTwo]:
            setFlag("LESS")
        
        if Registers[actingRegisterOne] == 0:
            setFlag("ZERO")

    of 0b11011:
        if debug: echo "CMP IMMEDIATE"

        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)

        if Registers[actingRegisterOne] == CurrentInstructionBuffer[1]:
            setFlag("EQUAL")
        
        if Registers[actingRegisterOne] < CurrentInstructionBuffer[1]:
            setFlag("LESS")
        
        if Registers[actingRegisterOne] == 0:
            setFlag("ZERO")

    of 0b11111:
        if debug: echo "HALT"
        exit()
    else:
        if debug: echo "INVALID INSTRUCTION, EXITING"
        exit()