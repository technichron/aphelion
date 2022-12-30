# APHELION ASSEMBLER 1.0
# BY TECHNICHRON

import std/strutils, std/sequtils

const PunctuationChars = {'!'..'/', ':'..'@', '['..'`', '{'..'~'}

# proc seqStringToString(s: seq[string]): string =
#     for i in s.low()..s.high():
#         result.add(s[i])
#         result.add("\n")

proc getDataType(value: string): string =
    case value[0]
    of '0': #number
        result = $value[1] # x - hex, b - binary, d - decimal, o - octal
    of 'a','A','b','B','c','C','d','D','z','Z','l','L','h','H','f','F':
        result = "register"
    else:
        result = "error"

proc getRegisterCode(value: string): string =
    case value:
    of "a", "A":
        result = "000"
    of "b", "B":
        result = "001"
    of "c", "C":
        result = "010"
    of "d", "D":
        result = "011"
    of "e", "E":
        result = "100"
    of "l", "L":
        result = "101"
    of "h", "H":
        result = "110"
    of "f", "F":
        result = "111"
    else: discard

proc numToBin(num: string, len: int): string =
    var decimal: int
    case getDataType(num)
    of "x":
        decimal = fromHex[int](num)
    of "b":
        decimal = fromBin[int](num)
    of "d":
        decimal = parseInt(num[2..len(num)-1])
    of "o":
        decimal = fromOct[int](num)

    if len == 8:
        result = toBin(decimal, 8)
    if len == 16:
        result = insertSep(toBin(decimal, 16), ' ', 8)

proc levelOneFlatten(f: string): seq[string] =

    var file = splitLines(f)    # deliniate

    #result = $char(fromHex[uint]("61"))

    file = file.filterIt(it.len != 0)

    for i in file.low()..file.high():                               # strip leading and trailing whitespace
        file[i] = strip(file[i])

    for i in file.low()..file.high():                               # remove comments
        if file[i][0] == '#': file[i] = ""
    
    for i in file.low()..file.high():
        file[i] = file[i].split("#")[0]
    
    for i in file.low()..file.high():                               # strip leading and trailing whitespace again
        file[i] = strip(file[i])
    
    echo "cleansed..."
    
    var defineList: seq[array[2, string]]                       # sequence of definition statements to replace
    for i in file.low()..file.high():                               # in the format of ["name","value"]
        let line = file[i].split()
        if line[0] == "@define":
            defineList.add([line[1].replace(","), line[2]])
            file[i] = ""
    
    for i in file.low()..file.high():
        for definition in defineList:
            file[i] = file[i].replaceWord(definition[0], definition[1])
    
    echo "definitions resolved..."

    for i in file.low()..file.high():
        file[i] = file[i].replace(",")

    file = file.filterIt(it.len != 0)                                   # filter out zero-length entries

    var hasMainLabel = false
    for i in file.low()..file.high():
        if file[i] == "main:":
            hasMainLabel = true

    if hasMainLabel:
        file = concat(@["jmp main"], file)
    
    if file[file.high()] != "halt" and file[file.high()] != "HALT":
        file = concat(file, @["halt"])




    result = file

proc levelOneBinaryConversion(input: seq[string]): string =

    for line in input:

        result.add(" ")

        case line.split()[0]
        of "nop", "NOP":                                                                    # nop
            result.add("00000000")

        of "set", "SET":                                                                    # set
            result.add("0001")

            case getDataType(line.split()[2])
            of "x", "b","d", "o":
                result.add("1")
                result.add(getRegisterCode(line.split()[1]))
                result.add(" ")
                result.add(numToBin(line.split()[2], 8))

            else:
                result.add("0")
                result.add(getRegisterCode(line.split()[1]))
                result.add(" 00000")
                result.add(getRegisterCode(line.split()[2]))
        
        of "lw", "LW":                                                                        # lw
            result.add("0010")

            case getDataType(line.split()[2])
            of "x", "b","d", "o":
                result.add("1")
                result.add(getRegisterCode(line.split()[1]))
                result.add(" ")
                result.add(numToBin(line.split()[2], 16))
            
            else:
                result.add("0")
                result.add(getRegisterCode(line.split()[1]))
        
        of "sw", "SW":                                                                        # sw
            result.add("0011")

            case getDataType(line.split()[2])
            of "x", "b","d", "o":
                result.add("1")
                result.add(getRegisterCode(line.split()[1]))
                result.add(" ")
                result.add(numToBin(line.split()[2], 16))
            
            else:
                result.add("0")
                result.add(getRegisterCode(line.split()[1]))
            
        of "add", "ADD":                                                                        # add
            result.add("0100")

            case getDataType(line.split()[2])
            of "x", "b","d", "o":
                result.add("1")
                result.add(getRegisterCode(line.split()[1]))
                result.add(" ")
                result.add(numToBin(line.split()[2], 8))

            else:
                result.add("0")
                result.add(getRegisterCode(line.split()[1]))
                result.add(" 00000")
                result.add(getRegisterCode(line.split()[2]))
            
        of "adc", "ADC":                                                                        # adc
            result.add("0101")

            case getDataType(line.split()[2])
            of "x", "b","d", "o":
                result.add("1")
                result.add(getRegisterCode(line.split()[1]))
                result.add(" ")
                result.add(numToBin(line.split()[2], 8))

            else:
                result.add("0")
                result.add(getRegisterCode(line.split()[1]))
                result.add(" 00000")
                result.add(getRegisterCode(line.split()[2]))

        of "sub", "SUB":                                                                        # sub
            result.add("0110")

            case getDataType(line.split()[2])
            of "x", "b","d", "o":
                result.add("1")
                result.add(getRegisterCode(line.split()[1]))
                result.add(" ")
                result.add(numToBin(line.split()[2], 8))

            else:
                result.add("0")
                result.add(getRegisterCode(line.split()[1]))
                result.add(" 00000")
                result.add(getRegisterCode(line.split()[2]))

        of "sbb", "SBB":                                                                        # sbb
            result.add("0111")

            case getDataType(line.split()[2])
            of "x", "b","d", "o":
                result.add("1")
                result.add(getRegisterCode(line.split()[1]))
                result.add(" ")
                result.add(numToBin(line.split()[2], 8))

            else:
                result.add("0")
                result.add(getRegisterCode(line.split()[1]))
                result.add(" 00000")
                result.add(getRegisterCode(line.split()[2]))

        of "and", "AND":                                                                        # and
            result.add("1010")

            case getDataType(line.split()[2])
            of "x", "b","d", "o":
                result.add("1")
                result.add(getRegisterCode(line.split()[1]))
                result.add(" ")
                result.add(numToBin(line.split()[2], 8))

            else:
                result.add("0")
                result.add(getRegisterCode(line.split()[1]))
                result.add(" 00000")
                result.add(getRegisterCode(line.split()[2]))

        of "or", "OR":                                                                            # or
            result.add("1011")

            case getDataType(line.split()[2])
            of "x", "b","d", "o":
                result.add("1")
                result.add(getRegisterCode(line.split()[1]))
                result.add(" ")
                result.add(numToBin(line.split()[2], 8))

            else:
                result.add("0")
                result.add(getRegisterCode(line.split()[1]))
                result.add(" 00000")
                result.add(getRegisterCode(line.split()[2]))

        of "not", "NOT":                                                                        # not
            result.add("11000")
            result.add(getRegisterCode(line.split()[1]))

        of "cmp", "CMP":                                                                        # cmp
            result.add("1101")

            case getDataType(line.split()[2])
            of "x", "b","d", "o":
                result.add("1")
                result.add(getRegisterCode(line.split()[1]))
                result.add(" ")
                result.add(numToBin(line.split()[2], 8))

            else:
                result.add("0")
                result.add(getRegisterCode(line.split()[1]))
                result.add(" 00000")
                result.add(getRegisterCode(line.split()[2]))

        of "jmp", "JMP":                                                                        # jmp
            result.add("1000")

            case line.split()[1]
            of "hl", "HL":
                result.add("0000")
            else:
                result.add("1000 ")
                result.add(line.split()[1])

        of "jnz", "JNZ":                                                                        # jnz
            result.add("1001")

            case line.split()[1]
            of "hl", "HL":
                result.add("0")
                result.add(getRegisterCode(line.split()[1]))
            else:
                result.add("1")
                result.add(getRegisterCode(line.split()[1]))
                result.add(line.split()[1])
        
        of "halt", "HALT":
            result.add("11111111")

        else:
            result.add(line)
    
    result.delete(0..0)

    echo "instructions converted..."

    # ----------------------- jmp / jnz reference processor ---------------------- #

    var byteList = result.split(' ')
    var tempByteList = byteList

    var alias = ""
    var byteNumber = 0

    var offset = 1
    for i in byteList.low()..byteList.high(): # ADD EMPTY STRING AFTER JUMP REFERENCES - CHECK IF STRING ONLY CONTAINS LETTERS
        if not (contains(byteList[i], Digits) or contains(byteList[i], PunctuationChars)):
            tempByteList.insert(" ", i+offset)
            offset += 1
    
    byteList = tempByteList

    while true:

        alias = ""
        byteNumber = 0

        for line in byteList:
            if line[line.high()] == ':':
                alias = line[0..<line.high()]
                break
            byteNumber += 1
        
        if byteNumber == len(byteList): break

        for l in byteList.low()..byteList.high():
            if byteList[l] == alias:
                byteList[l] = insertSep(toBin(byteNumber, 16), ' ', 8)
    
        byteList.delete(byteNumber)

    
    echo "jumps resolved..."
    
    result = ""
    for b in byteList:
        if isEmptyOrWhitespace(b):
            continue
        result.add(b)
        result.add(" ")

proc txtToBin(inText: string): string =
    for b in inText.split(' '):
        if isEmptyOrWhitespace(b) == false:
            result.add($char(fromBin[uint8](b)))


proc main() = 

    let raw = readFile("assembler/sample.asm")

    let flattened = levelOneFlatten(raw)

    let binaryTextFile = levelOneBinaryConversion(flattened)
    let binaryFile = txtToBin(binaryTextFile)

    # writeFile("flattened.txt", seqStringToString(flattened))
    writeFile("assembler/output.txt", binaryTextFile)
    writeFile("assembler/output.bin", binaryFile)

    echo "done!"
    
main()