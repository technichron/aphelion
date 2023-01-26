import bitops, displaywindow

const Flags* = 0b00101          # flags                               00[carry][borrow][greater][equal][less][zero]

const StackPointer* = 0b01100    # stack pointer   * initialized to the top of ram, 0xFFF0
const ReturnPointer* = 0b01101   # return pointer
const ProgramCounter* = 0b01011  # program counter

const FlagCARRY*   = 0b00100000
const FlagBORROW*  = 0b00010000
const FlagGREATER* = 0b00001000
const FlagEQUAL*   = 0b00000100
const FlagLESS*    = 0b00000010
const FlagZERO*    = 0b00000001

var MemorySpace*: array[0x10000, uint8]
var Registers*: array[30, uint8]
var BIB*: array[5, uint8]        # binary instruction buffer - for reading bytes straight from the file
var IB*: array[3, int]           # (clean) instruction buffer - [opcode, arg1, arg2]

proc loadAMG*(memarray: var array[0x10000, uint8], path: string) =
    let amg = readFile(path)
    if amg.len() == 0x10000:
        for index in 0..0xffff:
            memarray[index] = uint8(amg[index])
        echo "\"", path, "\"", " loaded successfully"
    else:
        echo "\"", path, "\"", ": expected 65536 bytes, got ", len(amg), " bytes"

proc getInstructionFormat*(opcode: uint8): string =
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

proc getInstructionLength*(opcode: uint8): int =
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

proc read*(address: SomeInteger): uint8 =
    if address == 0xffff:
        return charIn()
    else:
        return MemorySpace[address]

proc write*(value: uint8, address: SomeInteger) =
    if address >= 0x9000 and address <= 0xfffe: # check if in RAM or RESERVED
        MemorySpace[address] = value
    elif address == 0xffff:
        charOut(value)

proc readRegister*(code: int): uint8 =
    return Registers[code]

proc writeRegister*(value: uint8, code: int) =
    Registers[code] = value

proc readDoubleRegister*(code: int): uint16 =
    return uint16(Registers[code+16]*256 + Registers[code])

proc writeDoubleRegister*(value: uint16, code:int) =
    Registers[code] = uint8(value.bitsliced(0..7))
    Registers[code+16] = uint8(value.bitsliced(8..15))

proc readFlag*(code: uint8): bool = bitand(code, Registers[Flags]).bool

proc writeFlag*(code: uint8, value: bool) = 
    if value:
        Registers[Flags].setBit(fastLog2(code))
    else:
        Registers[Flags] = bitand(Registers[Flags], bitnot(code))