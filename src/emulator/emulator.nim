
# ╔═══════════════════════╗
# ║ APHELION EMULATOR 2.0 ║
# ╚═══════════════════════╝

import std/strutils, std/bitops, std/os, std/math, pixie, sdl2

const Flags  = 0b00101          # flags                               00[carry][borrow][greater][equal][less][zero]

const StackPointer = 0b01100    # stack pointer   * initialized to the top of ram, 0xFFF0
const ReturnPointer = 0b01101   # return pointer
const ProgramCounter = 0b01011  # program coutner

const FlagCARRY   = 0b00100000
const FlagBORROW  = 0b00010000
const FlagGREATER = 0b00001000
const FlagEQUAL   = 0b00000100
const FlagLESS    = 0b00000010
const FlagZERO    = 0b00000001

var MemorySpace: array[0x10000, uint8]
var Registers: array[30, uint8]
var BIB: array[5, uint8]        # binary instruction buffer - for reading bytes straight from the file
var IB: array[3, int]           # (clean) instruction buffer - [opcode, arg1, arg2]


const horizontalMargin = 5 # pixels
const verticalMargin = 5   # pixels
const columns = 80
const rows = 25
const charHeight = 14 # pixels
const charWidth = 8   # pixels
const charScale = 2
const controlCharsActive = true

var window = createWindow("aphelion 2.0 terminal", 100, 100, cint((charWidth*charScale*columns)+(horizontalMargin*2)), cint((charHeight*charScale*rows)+(verticalMargin*2)), SDL_WINDOW_SHOWN) # 80x25 character display
let icon = loadBMP("src/assets/icon.bmp")
window.setIcon(icon)

var event = sdl2.defaultEvent
var render = createRenderer(window, -1, Renderer_Software)

var cursorRow = 0
var cursorCol = 0

let fontImage = readImage("src/assets/3dfx8x14.png")

proc drawPixel(x,y: int) =
    for xs in 1..charScale:
        for ys in 1..charScale:
            render.drawPoint(cint((x * charScale) - (xs-1) + horizontalMargin ), cint((y * charScale) - (ys-1) + verticalMargin ))

proc displayCharacter(ch: char) =
    if controlCharsActive:
        case ch
            of '\0': discard
            of '\n':
                cursorCol = 0
                cursorRow += 1
            of '\b':
                if cursorCol == 0:
                    cursorCol = columns
                    cursorRow -= 1
                cursorCol -= 1

                for relativeX in 0..<charWidth:
                    for relativeY in 0..<charHeight:
                        let pcolor = fontImage[1+relativeX, 0+relativeY]
                        render.setDrawColor(pcolor.r, pcolor.b, pcolor.g, pcolor.a)
                        drawPixel((cursorCol*charWidth)+relativeX, (cursorRow*charHeight)+relativeY)
            of char(0x0B):      # clear screen
                render.setDrawColor(0,0,0,255)
                render.clear()
            of char(0x0C):      #reset cursor
                cursorCol = 0
                cursorRow = 0
            of char(0x0D):      # clear screen and reset cursor
                render.setDrawColor(0,0,0,255)
                render.clear()
                cursorCol = 0
                cursorRow = 0
            of char(0x0E):      # decrement cursor
                cursorCol -= 1
            of char(0x0F):      # increment cursor
                cursorCol += 1
            else:
                for relativeX in 0..<charWidth:
                    for relativeY in 0..<charHeight:
                        let pcolor = fontImage[((ch.int mod 16)*(charWidth+1))+1+relativeX, int((ch.int/16).floor.int*(charHeight+1))+relativeY]
                        render.setDrawColor(pcolor.r, pcolor.b, pcolor.g, pcolor.a)
                        drawPixel((cursorCol*charWidth)+relativeX, (cursorRow*charHeight)+relativeY)
                cursorCol += 1
    else:
        for relativeX in 0..<charWidth:
            for relativeY in 0..<charHeight:
                let pcolor = fontImage[((int(ch) mod 16)*(charWidth+1))+1+relativeX, int((ch.int/16).floor.int*(charHeight+1))+relativeY]
                render.setDrawColor(pcolor.r, pcolor.g, pcolor.b, pcolor.a)
                drawPixel((cursorCol*charWidth)+relativeX, (cursorRow*charHeight)+relativeY)
        cursorCol += 1
    if cursorCol == columns: # line wrapping
        cursorCol = 0
        cursorRow += 1
    if cursorRow == rows: # row reset
        cursorCol = 0
        cursorRow = 0
    if cursorCol < 0: # negative reset
        cursorCol = 0
    if cursorRow < 0: # negative reset
        cursorRow = 0
    render.present()

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

proc charOut(value: uint8) =
    displayCharacter(value.char)

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

proc readFlag(code: uint8): bool = bitand(code, Registers[Flags]).bool

proc writeFlag(code: uint8, value: bool) = 
    if value:
        Registers[Flags].setBit(fastLog2(code))
    else:
        Registers[Flags] = bitand(Registers[Flags], bitnot(code))

# ----------------------------- time to run shit ----------------------------- #

MemorySpace.loadAMG("amgs/aphelion2test.amg")

var running = true
while running:

    while pollEvent(event):
        if event.kind == QuitEvent:
            running = false
            break
        if event.kind == KeyDown:
            echo "key press"
            echo event.key.keysym.sym
            break
    
    render.present

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
            writeDoubleRegister(IB[2].uint16, IB[1])
        of 0x07:    # mov $imm16, reg             0x07 0b000111 RD
            writeRegister(read(IB[2]), IB[1])
        of 0x08:    # mov $imm16, $imm16          0x08 0b001000 DD
            write(read(IB[1]), IB[2])
        of 0x3c:    # mov $dreg, $imm16           0x3C 0b001000 RD
            write(read(readDoubleRegister(IB[1])), IB[2])
        of 0x3d:    # mov $dreg, dreg             0x3D 0b001000 RR
            writeDoubleRegister(read(readDoubleRegister(IB[1])), IB[2])

        # add (op1), (op2)            (op1) = (op1) + (op2)

        of 0x09:    # add reg, reg                0x09 0b001001 RR
            let sum = readRegister(IB[1])+readRegister(IB[2])
            writeFlag(FlagCARRY, readRegister(IB[1]) > sum or readRegister(IB[2]) > sum)
            writeRegister(sum, IB[1])
        of 0x0a:    # add reg, imm8               0x0A 0b001010 RB
            let sum = readRegister(IB[1])+IB[2].uint8
            writeFlag(FlagCARRY, readRegister(IB[1]) > sum or IB[2].uint8 > sum)
            writeRegister(sum, IB[1])
        of 0x0b:    # add dreg, dreg              0x0B 0b001011 RR
            let sum = readDoubleRegister(IB[1])+readDoubleRegister(IB[2])
            writeFlag(FlagCARRY, readDoubleRegister(IB[1]) > sum or readDoubleRegister(IB[2]) > sum)
            writeDoubleRegister(sum, IB[1])
        of 0x0c:    # add dreg, imm16             0x0C 0b001100 RD
            let sum = readDoubleRegister(IB[1])+IB[2].uint16
            writeFlag(FlagCARRY, readDoubleRegister(IB[1]) > sum or IB[2].uint16 > sum)
            writeDoubleRegister(sum, IB[1])

        # adc (op1), (op2)            (op1) = (op1) + (op2) + CARRY
    
        of 0x0d:    # adc reg, reg                0x0D 0b001101 RR
            let sum = readRegister(IB[1])+readRegister(IB[2])+readFlag(FlagCARRY).uint8
            writeFlag(FlagCARRY, readRegister(IB[1]) > sum or readRegister(IB[2]) > sum or readFlag(FlagCARRY).uint8 > sum)
            writeRegister(sum, IB[1])
        of 0x0e:    # adc reg, imm8               0x0E 0b001110 RB
            let sum = readRegister(IB[1])+IB[2].uint8+readFlag(FlagCARRY).uint8
            writeFlag(FlagCARRY, readRegister(IB[1]) > sum or IB[2].uint8 > sum or readFlag(FlagCARRY).uint8 > sum)
            writeRegister(sum, IB[1])
        of 0x0f:    # adc dreg, dreg              0x0F 0b001111 RR
            let sum = readDoubleRegister(IB[1])+readDoubleRegister(IB[2])+readFlag(FlagCARRY).uint16
            writeFlag(FlagCARRY, readDoubleRegister(IB[1]) > sum or readDoubleRegister(IB[2]) > sum or readFlag(FlagCARRY).uint16 > sum)
            writeDoubleRegister(sum, IB[1])
        of 0x10:    # adc dreg, imm16             0x10 0b010000 RD
            let sum = readDoubleRegister(IB[1])+IB[2].uint16+readFlag(FlagCARRY).uint16
            writeFlag(FlagCARRY, readDoubleRegister(IB[1]) > sum or IB[2].uint16 > sum or readFlag(FlagCARRY).uint16 > sum)
            writeDoubleRegister(sum, IB[1])

        
        # sub (op1), (op2)            (op1) = (op1) - (op2)

        of 0x11:    # sub reg, reg                0x11 0b010001 RR
            let dif = readRegister(IB[1])-readRegister(IB[2])
            writeFlag(FlagBORROW, readRegister(IB[1]) < dif or readRegister(IB[2]) < dif)
            writeRegister(dif, IB[1])
        of 0x12:    # sub reg, imm8               0x12 0b010010 RB
            let dif = readRegister(IB[1])-IB[2].uint8
            writeFlag(FlagBORROW, readRegister(IB[1]) < dif or IB[2].uint8 < dif)
            writeRegister(dif, IB[1])
        of 0x13:    # sub dreg, dreg              0x13 0b010011 RR
            let dif = readDoubleRegister(IB[1])-readDoubleRegister(IB[2])
            writeFlag(FlagBORROW, readDoubleRegister(IB[1]) < dif or readDoubleRegister(IB[2]) < dif)
            writeDoubleRegister(dif, IB[1])
        of 0x14:    # sub dreg, imm16             0x14 0b010100 RD
            let dif = readDoubleRegister(IB[1])-IB[2].uint16
            writeFlag(FlagBORROW, readDoubleRegister(IB[1]) < dif or IB[2].uint16 < dif)
            writeDoubleRegister(dif, IB[1])
        
        # sbb (op1), (op2)            (op1) = (op1) - (op2) - BORROW
    
        of 0x15:    # sbb reg, reg                0x15 0b010101 RR
            let dif = readRegister(IB[1])-readRegister(IB[2])-readFlag(FlagBORROW).uint8
            writeFlag(FlagBORROW, readRegister(IB[1]) < dif or (readRegister(IB[2])+readFlag(FlagBORROW).uint8) < dif)
            writeRegister(dif, IB[1])
        of 0x16:    # sbb reg, imm8               0x16 0b010110 RB
            let dif = readRegister(IB[1])-IB[2].uint8-readFlag(FlagBORROW).uint8
            writeFlag(FlagBORROW, readRegister(IB[1]) < dif or (IB[2].uint8+readFlag(FlagBORROW).uint8) < dif)
            writeRegister(dif, IB[1])
        of 0x17:    # sbb dreg, dreg              0x17 0b010111 RR
            let dif = readDoubleRegister(IB[1])-readDoubleRegister(IB[2])-readFlag(FlagBORROW).uint8
            writeFlag(FlagBORROW, readDoubleRegister(IB[1]) < dif or (readDoubleRegister(IB[2])+readFlag(FlagBORROW).uint8) < dif)
            writeDoubleRegister(dif, IB[1])
        of 0x18:    # sbb dreg, imm16             0x18 0b011000 RD
            let dif = readDoubleRegister(IB[1])-IB[2].uint16-readFlag(FlagBORROW).uint16
            writeFlag(FlagBORROW, readDoubleRegister(IB[1]) < dif or (IB[2].uint16+readFlag(FlagBORROW).uint16) < dif)
            writeDoubleRegister(dif, IB[1])
        
        # jif (flags), (loc)          set program counter to (loc) if F & (flags) == (flags)

        of 0x1b:    # jif imm8, label/$imm16      0x1B 0b011011 BD
            if bitand(IB[1].uint8, readRegister(Flags)) == IB[1].uint8: writeDoubleRegister(IB[2].uint16, ProgramCounter)
        of 0x19:    # jif imm8, $dreg             0x19 0b011001 RB
            if bitand(IB[2].uint8, readRegister(Flags)) == IB[2].uint8: writeDoubleRegister(readRegister(IB[1]), ProgramCounter)
        
        # cif (flags), (loc)          set program counter to (loc) and set R to address of the following instruction if F & (flags) == (flags)

        of 0x1c:    # cif imm8, label/$imm16      0x1C 0b011100 BD
            if bitand(IB[1].uint8, readRegister(Flags)) == IB[1].uint8:
                writeDoubleRegister(readDoubleRegister(ProgramCounter), ReturnPointer)
                writeDoubleRegister(IB[2].uint16, ProgramCounter)
        of 0x1a:    # cif imm8, $dreg             0x1A 0b011010 RB
            if bitand(IB[2].uint8, readRegister(Flags)) == IB[2].uint8:
                writeDoubleRegister(readDoubleRegister(ProgramCounter), ReturnPointer)
                writeDoubleRegister(readRegister(IB[1]), ProgramCounter)
        
        # ret                         set program counter to R\
        
        of 0x1d:    # ret                         0x1D 0b011101 NA
            writeDoubleRegister(readDoubleRegister(ReturnPointer), ProgramCounter)
        
        # push (value)                push (value) onto stack         * stack pointer decrements, most significant byte of int16 pushed first

        of 0x1e:    # push reg                    0x1E 0b011110 RE
            writeDoubleRegister(readDoubleRegister(StackPointer)-1, StackPointer)
            write(readRegister(IB[1]), readDoubleRegister(StackPointer))
        of 0x1f:    # push dreg                   0x1F 0b011111 RE
            writeDoubleRegister(readDoubleRegister(StackPointer)-2, StackPointer)
            write(readRegister(IB[1]+0b10000), readDoubleRegister(StackPointer)+1)
            write(readRegister(IB[1]), readDoubleRegister(StackPointer))
        of 0x20:    # push imm8                   0x20 0b100000 BY
            writeDoubleRegister(readDoubleRegister(StackPointer)-1, StackPointer)
            write(IB[1].uint8, readDoubleRegister(StackPointer))
        of 0x21:    # push imm16                  0x21 0b100001 DO
            writeDoubleRegister(readDoubleRegister(StackPointer)-2, StackPointer)
            write(IB[1].bitsliced(8..15).uint8, readDoubleRegister(StackPointer)+1)
            write(IB[1].bitsliced(0..7).uint8, readDoubleRegister(StackPointer))
        
        # pop (dest)                  pop value from stack to (dest)  * stack pointer increments

        of 0x22:    # pop reg                     0x22 0b100010 RE
            writeRegister(read(readDoubleRegister(StackPointer)), IB[1])
            writeDoubleRegister(readDoubleRegister(StackPointer)+1, StackPointer)
        of 0x23:    # pop dreg                    0x23 0b100011 RE
            writeDoubleRegister((read(readDoubleRegister(StackPointer)-1)*256+read(readDoubleRegister(StackPointer))).uint16, IB[1])
            writeDoubleRegister(readDoubleRegister(StackPointer)+2, StackPointer)
        
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
            writeFlag(FlagGREATER, readRegister(IB[1]) > readRegister(IB[2]))
            writeFlag(FlagLESS, readRegister(IB[1]) < readRegister(IB[2]))
            writeFlag(FlagEQUAL, readRegister(IB[1]) == readRegister(IB[2]))
            writeFLag(FlagZERO, readRegister(IB[1]) == 0)
        of 0x2f:    # cmp reg, imm8               0x2F 0b101111 RB
            writeFlag(FlagGREATER, readRegister(IB[1]) > IB[2].uint8)
            writeFlag(FlagLESS, readRegister(IB[1]) < IB[2].uint8)
            writeFlag(FlagEQUAL, readRegister(IB[1]) == IB[2].uint8)
            writeFLag(FlagZERO, readRegister(IB[1]) == 0)
        of 0x30:    # cmp dreg, dreg              0x30 0b110000 RR
            writeFlag(FlagGREATER, readDoubleRegister(IB[1]) > readDoubleRegister(IB[2]))
            writeFlag(FlagLESS, readDoubleRegister(IB[1]) < readDoubleRegister(IB[2]))
            writeFlag(FlagEQUAL, readDoubleRegister(IB[1]) == readDoubleRegister(IB[2]))
            writeFLag(FlagZERO, readDoubleRegister(IB[1]) == 0)
        of 0x31:    # cmp dreg, imm16             0x31 0b110001 RD
            writeFlag(FlagGREATER, readDoubleRegister(IB[1]) > IB[2].uint16)
            writeFlag(FlagLESS, readDoubleRegister(IB[1]) < IB[2].uint16)
            writeFlag(FlagEQUAL, readDoubleRegister(IB[1]) == IB[2].uint16)
            writeFLag(FlagZERO, readDoubleRegister(IB[1]) == 0)
        
        # scmp (op1), (op2)           compare (op1) and (op2) as two's complement signed integers, set relevant flags

        of 0x32:    # scmp reg, reg               0x32 0b110010 RR
            let op1 = readRegister(IB[1]).int.toBin(8).fromBin[:int8]()
            let op2 = readRegister(IB[2]).int.toBin(8).fromBin[:int8]()
            writeFlag(FlagGREATER, op1 > op2)
            writeFlag(FlagLESS, op1 < op2)
            writeFlag(FlagEQUAL, op1 == op2)
            writeFLag(FlagZERO, op1 == 0)
        of 0x33:    # scmp reg, imm8              0x33 0b110011 RB
            let op1 = readRegister(IB[1]).int.toBin(8).fromBin[:int8]()
            let op2 = IB[2].toBin(8).fromBin[:int8]()
            writeFlag(FlagGREATER, op1 > op2)
            writeFlag(FlagLESS, op1 < op2)
            writeFlag(FlagEQUAL, op1 == op2)
            writeFLag(FlagZERO, op1 == 0)
        of 0x34:    # scmp dreg, dreg             0x34 0b110100 RR
            let op1 = readDoubleRegister(IB[1]).int.toBin(16).fromBin[:int16]()
            let op2 = readDoubleRegister(IB[2]).int.toBin(16).fromBin[:int16]()
            writeFlag(FlagGREATER, op1 > op2)
            writeFlag(FlagLESS, op1 < op2)
            writeFlag(FlagEQUAL, op1 == op2)
            writeFLag(FlagZERO, op1 == 0)
        of 0x35:    # scmp dreg, imm16            0x35 0b110101 RD
            let op1 = readDoubleRegister(IB[1]).int.toBin(16).fromBin[:int16]()
            let op2 = IB[2].toBin(16).fromBin[:int16]()
            writeFlag(FlagGREATER, op1 > op2)
            writeFlag(FlagLESS, op1 < op2)
            writeFlag(FlagEQUAL, op1 == op2)
            writeFLag(FlagZERO, op1 == 0)
        
        # shl (op), (amount)          logical/arithmetic bit shift left (amount) bits     * can also be called with 'asl' and 'lsl'

        of 0x36:    # shl reg, imm8               0x36 0b110110 RB
            writeRegister((readRegister(IB[1]).int*pow(2.0,IB[2].float).int).uint8, IB[1])
        of 0x37:    # shl dreg, imm8              0x37 0b110111 RB
            writeDoubleRegister((readDoubleRegister(IB[1]).int*pow(2.0,IB[2].float).int).uint16, IB[1])
        
        # asr (op), (amount)          arithmetic bit shift (op) right (amount) bits

        of 0x38:    # asr reg, imm8               0x38 0b111000 RB
            writeRegister(bitor(floor(readRegister(IB[1]).float/pow(2.0,IB[2].float)).int, bitand(0x80, readRegister(IB[1]).int)).uint8, IB[1])
        of 0x39:    # asr dreg, imm8              0x39 0b111001 RB
            writeDoubleRegister(bitor(floor(readRegister(IB[1]).float/pow(2.0,IB[2].float)).int, bitand(0x8000, readDoubleRegister(IB[1]).int)).uint16, IB[1])

        # lsr (op), (amount)          logical bit shift (op) right (amount) bits

        of 0x3A:    # lsr reg, imm8               0x3A 0b111010 RB
            writeRegister((readRegister(IB[1]).float/(2^IB[2]).float).uint8, IB[1])
        of 0x3B:    # lsr dreg, imm8              0x3B 0b111011 RB
            writeDoubleRegister((readDoubleRegister(IB[1]).float/(2^IB[2]).float).uint16, IB[1])
        
        # hcf                         halt and catch fire

        of 0x3F:    # hcf                         0x3F 0b111111 NA
            running = false

        else:
            echo "invalid opcode at $", $(readDoubleRegister(ProgramCounter)-getInstructionLength(opcode).uint16)
            running = false