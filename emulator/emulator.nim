# APHELION EMULATOR 1.0
# BY TECHNICHRON

import std/bitops, std/os, std/strutils

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

var debug: bool
var debugMessage: string
var clock: float

proc getRegisterName(code: uint8): string =
    case code
    of 0b000: result = "A"
    of 0b001: result = "B"
    of 0b010: result = "C"
    of 0b011: result = "D"
    of 0b100: result = "E"
    of 0b101: result = "L"
    of 0b110: result = "H"
    of 0b111: result = "F"
    else: result = "INVALID"

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

    #NOP, LOAD R, SAVE R, JMP R, JNZ R, NOT, HALT
    of 0b00000, 0b00100, 0b00110, 0b10000, 0b10010, 0b11000, 0b11111:
        result = 1
    
    #SET R, SET I, ADD R, ADD I, ADC R, ADC I, SUB R, SUB I, SBB R, SBB I, AND R, AND I, OR R, OR I, CMP R, CMP I
    of 0b00010, 0b00011, 0b01000, 0b01001, 0b01010, 0b01011, 0b01100, 0b01101, 0b01110, 0b01111, 0b10100, 0b10101, 0b10110, 0b10111, 0b11010, 0b11011:
        result = 2
    
    #LOAD I, SAVE I, JMP I, JNZ I
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
        if debug:
            echo "!! CHAR OUT: ", $char(data)
        else:
            stdout.write(char(data))

proc exit() =
    running = false

debug = false
clock = 600 #hz - at >1000, runs at full speed




let sleepInterval = int((1/clock)*1000)

# -------------------------- loading rom into memory ------------------------- #

let rom = readFile("code/output.bin")
if rom.len() <= 0x9000:
    echo "rom length: ", rom.len(), " bytes"
    echo "loading rom..."
    for index in rom.low()..rom.high():
        Memory[index] = uint8(rom[index])
else:
    echo "error: rom is length ", rom.len(), "b, expected <= ", 0x9000, "b"
    running = false



echo "executing..."
echo ""

var actingRegisterOne: uint8
var actingRegisterTwo: uint8


proc Cycle() =

# ----------------------------------- fetch ---------------------------------- #

    CurrentInstructionBuffer[0] = read(ProgramCounter) # read initial byte at instruction counter

    for i in 0..<getInstructionLength(CurrentInstructionBuffer[0]):
        CurrentInstructionBuffer[i] = read(ProgramCounter+uint16(i))    # load instruction buffer with current  instruction
    
    ProgramCounter += uint16(getInstructionLength(CurrentInstructionBuffer[0]))    # increment program counter to location of next instruction

# ---------------------------------- execute --------------------------------- #
    if debug: 
        debugMessage.add("executing ")
        debugMessage.add(toHex(ProgramCounter - uint16(getInstructionLength(CurrentInstructionBuffer[0]))))
        debugMessage.add(" - ")

    case CurrentInstructionBuffer[0].bitsliced(3..7)
    of 0b00000:
        if debug: debugmessage.add("NOP")

    of 0b00010:

        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)
        actingRegisterTwo = CurrentInstructionBuffer[1].bitsliced(0..2)

        Registers[actingRegisterOne] = Registers[actingRegisterTwo]

        if debug:
            debugmessage.add("SET ")
            debugmessage.add(getRegisterName(actingRegisterOne))
            debugmessage.add(" ")
            debugmessage.add(getRegisterName(actingRegisterOne))

    of 0b00011:
        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)

        Registers[actingRegisterOne] = CurrentInstructionBuffer[1]

        if debug: 
            debugmessage.add("SET ")
            debugmessage.add(getRegisterName(actingRegisterOne))
            debugmessage.add(" ")
            debugmessage.add(toHex(CurrentInstructionBuffer[1]))

    of 0b00100:
        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)

        Registers[actingRegisterOne] = read(getHL())

        if debug:
            debugmessage.add("LOAD ")
            debugmessage.add(getRegisterName(actingRegisterOne))
            debugmessage.add(" HL")

    of 0b00101:
        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)

        Registers[actingRegisterOne] = read(binConcat(CurrentInstructionBuffer[1], CurrentInstructionBuffer[2]))

        if debug:
            debugmessage.add("LOAD ")
            debugmessage.add(getRegisterName(actingRegisterOne))
            debugmessage.add(" ")
            debugmessage.add(toHex(binConcat(CurrentInstructionBuffer[1], CurrentInstructionBuffer[2])))

    of 0b00110:

        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)

        write(getHL(), Registers[actingRegisterOne])

        if debug:
            debugmessage.add("SAVE ")
            debugmessage.add(getRegisterName(actingRegisterOne))
            debugmessage.add(" HL")

    of 0b00111:
        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)

        write(binConcat(CurrentInstructionBuffer[1], CurrentInstructionBuffer[2]), Registers[actingRegisterOne])

        if debug:
            debugmessage.add("SAVE ")
            debugmessage.add(getRegisterName(actingRegisterOne))
            debugmessage.add(" ")
            debugmessage.add(toHex(binConcat(CurrentInstructionBuffer[1], CurrentInstructionBuffer[2])))

    of 0b01000:
        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)
        actingRegisterTwo = CurrentInstructionBuffer[1].bitsliced(0..2)

        let sum = Registers[actingRegisterOne] + Registers[actingRegisterTwo]
        Registers[actingRegisterOne] = sum

        # detect CARRY and set flag
        if  (sum < Registers[actingRegisterOne]) or (sum < Registers[actingRegisterTwo]):
            setFlag("CARRY")
        
        if debug:
            debugmessage.add("ADD ")
            debugmessage.add(getRegisterName(actingRegisterOne))
            debugmessage.add(" ")
            debugmessage.add(getRegisterName(actingRegisterTwo))

    of 0b01001:
        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)

        let sum = Registers[actingRegisterOne] + CurrentInstructionBuffer[1]
        Registers[actingRegisterOne] = sum

        # detect CARRY and set flag
        if  (sum < Registers[actingRegisterOne]) or (sum < CurrentInstructionBuffer[1]):
            setFlag("CARRY")
        
        if debug:
            debugmessage.add("ADD ")
            debugmessage.add(getRegisterName(actingRegisterOne))
            debugmessage.add(" ")
            debugmessage.add(toHex(CurrentInstructionBuffer[1]))

    of 0b01010:
        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)
        actingRegisterTwo = CurrentInstructionBuffer[1].bitsliced(0..2)

        let sum = Registers[actingRegisterOne] + Registers[actingRegisterTwo] + uint8(getFlag("CARRY"))
        Registers[actingRegisterOne] = sum

        # detect CARRY and set flag
        if  (sum < Registers[actingRegisterOne]) or (sum < Registers[actingRegisterTwo]):
            setFlag("CARRY")
        
        if debug:
            debugmessage.add("ADC ")
            debugmessage.add(getRegisterName(actingRegisterOne))
            debugmessage.add(" ")
            debugmessage.add(getRegisterName(actingRegisterTwo))

    of 0b01011:
        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)

        let sum = Registers[actingRegisterOne] + CurrentInstructionBuffer[1] + uint8(getFlag("CARRY"))
        Registers[actingRegisterOne] = sum

        # detect CARRY and set flag
        if  (sum < Registers[actingRegisterOne]) or (sum < CurrentInstructionBuffer[1]):
            setFlag("CARRY")
        
        if debug:
            debugmessage.add("ADC ")
            debugmessage.add(getRegisterName(actingRegisterOne))
            debugmessage.add(" ")
            debugmessage.add(toHex(CurrentInstructionBuffer[1]))
    
    of 0b01100:
        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)
        actingRegisterTwo = CurrentInstructionBuffer[1].bitsliced(0..2)

        let diff = Registers[actingRegisterOne] - Registers[actingRegisterTwo]
        Registers[actingRegisterOne] = diff

        if  (diff > Registers[actingRegisterOne]) or (diff > Registers[actingRegisterTwo]):
            setFlag("BORROW")
        
        if debug:
            debugmessage.add("SUB ")
            debugmessage.add(getRegisterName(actingRegisterOne))
            debugmessage.add(" ")
            debugmessage.add(getRegisterName(actingRegisterTwo))

    of 0b01101:
        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)

        let diff = Registers[actingRegisterOne] - CurrentInstructionBuffer[1]
        Registers[actingRegisterOne] = diff

        if  (diff > Registers[actingRegisterOne]) or (diff > CurrentInstructionBuffer[1]):
            setFlag("BORROW")
        
        if debug:
            debugmessage.add("SUB ")
            debugmessage.add(getRegisterName(actingRegisterOne))
            debugmessage.add(" ")
            debugmessage.add(toHex(CurrentInstructionBuffer[1]))

    of 0b01110:
        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)
        actingRegisterTwo = CurrentInstructionBuffer[1].bitsliced(0..2)

        let diff = Registers[actingRegisterOne] - Registers[actingRegisterTwo] - uint8(getFlag("BORROW"))
        Registers[actingRegisterOne] = diff

        if  (diff > Registers[actingRegisterOne]) or (diff > Registers[actingRegisterTwo]):
            setFlag("BORROW")
        
        if debug:
            debugmessage.add("SBB ")
            debugmessage.add(getRegisterName(actingRegisterOne))
            debugmessage.add(" ")
            debugmessage.add(getRegisterName(actingRegisterTwo))

    of 0b01111:
        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)

        let diff = Registers[actingRegisterOne] - CurrentInstructionBuffer[1] - uint8(getFlag("BORROW"))
        Registers[actingRegisterOne] = diff

        if  (diff > Registers[actingRegisterOne]) or (diff > CurrentInstructionBuffer[1]):
            setFlag("BORROW")
        
        if debug:
            debugmessage.add("SBB ")
            debugmessage.add(getRegisterName(actingRegisterOne))
            debugmessage.add(" ")
            debugmessage.add(toHex(CurrentInstructionBuffer[1]))

    of 0b10000:
        ProgramCounter = getHL()

        if debug:
            debugmessage.add("JMP HL")

    of 0b10001:
        ProgramCounter = binConcat(CurrentInstructionBuffer[1], CurrentInstructionBuffer[2])

        if debug:
            debugmessage.add("JMP ")
            debugmessage.add(toHex(binConcat(CurrentInstructionBuffer[1], CurrentInstructionBuffer[2])))

    of 0b10010:
        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)

        if Registers[actingRegisterOne] != 0:
            ProgramCounter = getHL()
        
        if debug:
            debugmessage.add("JNZ ")
            debugMessage.add(getRegisterName(actingRegisterOne))
            debugmessage.add(" HL")

    of 0b10011:
        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)

        if Registers[actingRegisterOne] != 0:
            ProgramCounter = binConcat(CurrentInstructionBuffer[1], CurrentInstructionBuffer[2])
        else:
            setFlag("ZERO")
        
        if debug:
            debugmessage.add("JNZ ")
            debugMessage.add(getRegisterName(actingRegisterOne))
            debugmessage.add(" ")
            debugmessage.add(toHex(binConcat(CurrentInstructionBuffer[1], CurrentInstructionBuffer[2])))

    of 0b10100:
        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)
        actingRegisterTwo = CurrentInstructionBuffer[1].bitsliced(0..2)

        Registers[actingRegisterOne] = bitand(Registers[actingRegisterOne], Registers[actingRegisterTwo])

        if debug:
            debugmessage.add("AND ")
            debugmessage.add(getRegisterName(actingRegisterOne))
            debugmessage.add(" ")
            debugmessage.add(getRegisterName(actingRegisterTwo))

    of 0b10101:
        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)
        
        Registers[actingRegisterOne] = bitand(Registers[actingRegisterOne], CurrentInstructionBuffer[1])

        if debug:
            debugmessage.add("AND ")
            debugmessage.add(getRegisterName(actingRegisterOne))
            debugmessage.add(" ")
            debugmessage.add(toHex(CurrentInstructionBuffer[1]))

    of 0b10110:
        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)
        actingRegisterTwo = CurrentInstructionBuffer[1].bitsliced(0..2)

        Registers[actingRegisterOne] = bitor(Registers[actingRegisterOne], Registers[actingRegisterTwo])

        if debug:
            debugmessage.add("OR ")
            debugmessage.add(getRegisterName(actingRegisterOne))
            debugmessage.add(" ")
            debugmessage.add(getRegisterName(actingRegisterTwo))

    of 0b10111:
        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)
        
        Registers[actingRegisterOne] = bitor(Registers[actingRegisterOne], CurrentInstructionBuffer[1])

        if debug:
            debugmessage.add("OR ")
            debugmessage.add(getRegisterName(actingRegisterOne))
            debugmessage.add(" ")
            debugmessage.add(toHex(CurrentInstructionBuffer[1]))

    of 0b11000:
        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)

        Registers[actingRegisterOne] = bitnot(Registers[actingRegisterOne])

        if debug:
            debugmessage.add("NOT ")
            debugmessage.add(getRegisterName(actingRegisterOne))

    of 0b11010:
        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)
        actingRegisterTwo = CurrentInstructionBuffer[1].bitsliced(0..2)

        if Registers[actingRegisterOne] == Registers[actingRegisterTwo]:
            setFlag("EQUAL")
        
        if Registers[actingRegisterOne] < Registers[actingRegisterTwo]:
            setFlag("LESS")
        
        if Registers[actingRegisterOne] == 0:
            setFlag("ZERO")
        
        if debug:
            debugmessage.add("CMP ")
            debugmessage.add(getRegisterName(actingRegisterOne))
            debugmessage.add(" ")
            debugmessage.add(getRegisterName(actingRegisterTwo))

    of 0b11011:
        actingRegisterOne = CurrentInstructionBuffer[0].bitsliced(0..2)

        if Registers[actingRegisterOne] == CurrentInstructionBuffer[1]:
            setFlag("EQUAL")
        
        if Registers[actingRegisterOne] < CurrentInstructionBuffer[1]:
            setFlag("LESS")
        
        if Registers[actingRegisterOne] == 0:
            setFlag("ZERO")
        
        if debug:
            debugmessage.add("CMP ")
            debugmessage.add(getRegisterName(actingRegisterOne))
            debugmessage.add(" ")
            debugmessage.add(toHex(CurrentInstructionBuffer[1]))
    
    of 0b11111:
        if debug: debugmessage.add("HALT")
        exit()
    else:
        if debug: debugmessage.add("INVALID INSTRUCTION, EXITING")
        exit()

    if debug: echo debugMessage
    debugMessage = ""

while running:
    Cycle()
    sleep(sleepInterval)