
# ╔════════════════════════╗
# ║ APHELION ASSEMBLER 2.0 ║ by technichron
# ╚════════════════════════╝

import std/strutils, std/sequtils, std/terminal, std/tables, std/os, std/parseopt, consts

var IList: seq[array[4, string]] # [label, opcode, arg1, arg2]
var 
    TextList: seq[array[4, string]]
    RODataList: seq[array[4, string]]
    DataList: seq[array[4, string]]
var SymbolTable: seq[array[2, string]]
var Path: string

proc `$`(s: seq[array[4, string]]): string =
    for element in s:
        result.add $element
        result.add "\n"

proc error(errortype, message: string) =
    styledEcho styleDim, fgRed, errortype, ":", fgDefault, styleDim, " ", message
    quit(0)

proc loadCMDLineArguments() = 
    var p = initOptParser(commandLineParams().join(" "))
    while true:
        p.next()
        case p.kind
            of cmdEnd:
                break
            # of cmdLongOption:
            #     if p.key == "show-instructions":
            #         EchoIns = true
            of cmdArgument:
                Path = p.key
            else: discard

proc clean(file: string): string = # does exactly what it sounds like it does: clean comments and remove commas
    var lines = file.splitLines()


    for l in 0..lines.high():
        lines[l] = lines[l].strip
        if lines[l] != "":
            if lines[l][0] == '#':
                lines[l] = ""
            else:
                lines[l] = lines[l].split('#')[0]
                lines[l] = lines[l].strip()
        lines[l] = lines[l].replace(",")
    
    lines = lines.filterIt(it.len() != 0)

    for l in 0..lines.high:
        result.add lines[l]
        if l < lines.high: result.add "\n" 

proc decify(file: string): string = # turns all integer types and characters into decimal values for easier parsing later
    var lines = file.splitLines(true)

    for l in 0..lines.high():
        lines[l] = lines[l].strip
        lines[l].add(" ")
        if find(lines[l], '\'') != -1:
            let character =  lines[l][find(lines[l], '\'')..find(lines[l], '\'', find(lines[l], '\'')+1)]
            try: lines[l] = lines[l].replace(character, $codepage[character[1..(character.len-2)]])
            except:
                error("Invalid Argument", "[" & $l & "] invalid char length: " & character)

        if find(lines[l], "0x") != -1:
            let num = lines[l][find(lines[l], "0x")..find(lines[l], Whitespace, find(lines[l], "0x")+1)].strip(chars = ({','}+Whitespace))
            try: lines[l] = lines[l].replace(num, $fromHex[uint](num))
            except:
                error("Invalid Argument", "[" & $l & "] invalid hexadecimal integer: " & num)

        if find(lines[l], "0b") != -1:
            let num = lines[l][find(lines[l], "0b")..find(lines[l], Whitespace, find(lines[l], "0b")+1)].strip(chars = ({','}+Whitespace))
            try: lines[l] = lines[l].replace(num, $fromBin[uint](num))
            except:
                echo num
                error("Invalid Argument", "[" & $l & "] invalid binary integer: " & num)
        
        if find(lines[l], "0o") != -1:
            let num = lines[l][find(lines[l], "0o")..find(lines[l], Whitespace, find(lines[l], "0o")+1)].strip(chars = ({','}+Whitespace))
            try: lines[l] = lines[l].replace(num, $fromOct[uint](num))
            except:
                echo num
                error("Invalid Argument", "[" & $l & "] invalid octal integer: " & num)
        if find(lines[l], '\"') != -1:
            var str = ""
            try:
                str = lines[l][find(lines[l], '\"')..find(lines[l], '\"', find(lines[l], '\"')+1)]
                lines[l] = lines[l].replace(str, str.replace(" ", "\\_").strip(chars = {'\'', '\"'})) #\_ is escape code for space
            except:
                str = lines[l][find(lines[l], '\"')..find(lines[l], Whitespace, find(lines[l], '\"')+1)]
                error("Invalid Argument", "[" & $l & "] invalid string: " & str)
        if lines[l].split[0].endsWith(':') and lines[l].split.len > 1:
            var line = lines[l].split
            line[0].add "\n"
            lines[l] = line.join(" ")
    
    for l in 0..lines.high:
        result.add lines[l]
        if l < lines.high: result.add "\n"

proc populate(assemblyfile: string) =
    
    IList.add ["","","",""]
    
    var l = 0
    for currentLine in assemblyfile.splitLines:
        inc l
        if currentLine.endsWith(':'):
            IList[IList.high][0] = currentLine[0..currentLine.high-1]
        else:
            if currentLine.split.len <= 3:
                for i in 1..currentLine.split.len:
                    IList[IList.high][i] = currentLine.split[i-1]
            else:
                error("Invalid Instruction", "[" & $l & "] invalid argument number : " & currentLine)
            if l != assemblyfile.splitLines.len: IList.add ["","","",""]
        
proc generalChecks() =
    block globalChecks:
        var globalcount = 0
        for entry in TextList:
            if entry[1] != "@global":
                continue
            inc globalcount
        if globalcount < 1:
            error("Assembler Error", "no entry point found: use \"@global\" to define an entry point.")
        if globalcount > 1:
            error("Assembler Error", "multiple entry points found")
    
proc breakoutIList() =
    var mode = ""
    for entry in IList:
        if entry[1] == "@segment":
            case entry[2]:
            of "text", "rodata", "data":
                mode = entry[2]
                continue
            else:
                error("Assembler Error", "invalid segment type: " & entry[2])
        case mode
        of "text":
            TextList.add entry
        of "rodata":
            RODataList.add entry
        of "data":
            DataList.add entry
    
    # echo TextList
    # echo RODataList
    # echo DataList

proc argType(arg: string): string =
    if arg == "":
        return "none"
    elif arg[0] == '$':
        result.add "address"
        if arg[1..<arg.len] in ByteRegisterNames:
            result.add "_reg"
        if arg[1..<arg.len] in DoubleRegisterNames:
            result.add "_dreg"
    elif arg.toLower in ByteRegisterNames:
        return "reg"
    elif arg.toLower in DoubleRegisterNames:
        return "dreg"
    else:
        try:
            let x = parseInt(arg)
            return "int"
        except ValueError:
            return "address"

proc argTypes(line: array[4, string]): string =
    return argType(line[2]) & " " & argType(line[3])

proc nameToOpcodeAndSuch() =
    for i in 0..<TextList.len:
        case TextList[i][1]:
        of "@global":
            TextList[i][1] = "0x06"
            TextList[i][3] = "rP"

        of "nop":
            if argTypes(TextList[i]) != "none none":
                error("Invalid Arguments", "\"" & argTypes(TextList[i]) & "\" are not valid arguments for \"nop\"")
            TextList[i][1] = "0x00"
        
        of "mov":
            case argTypes(TextList[i])
            of "reg address":           TextList[i][1] = "0x01"
            of "reg reg":               TextList[i][1] = "0x02"
            of "dreg dreg":             TextList[i][1] = "0x03"
            of "reg int":               TextList[i][1] = "0x04"
            of "int address":           TextList[i][1] = "0x05"
            of "dreg int":              TextList[i][1] = "0x06"
            of "address reg":           TextList[i][1] = "0x07"
            of "address address":       TextList[i][1] = "0x08"
            of "address_dreg address":  TextList[i][1] = "0x3c"
            of "address_dreg dreg":     TextList[i][1] = "0x3d"
            else: error("Invalid Arguments", "\"" & argTypes(TextList[i]) & "\" are not valid arguments for \"mov\"")

        of "add":
            case argTypes(TextList[i])
            of "reg reg":   TextList[i][1] = "0x09"
            of "reg int":   TextList[i][1] = "0x0a"
            of "dreg dreg": TextList[i][1] = "0x0b"
            of "dreg int":  TextList[i][1] = "0x0c"
            else: error("Invalid Arguments", "\"" & argTypes(TextList[i]) & "\" are not valid arguments for \"add\"")
        
        of "adc":
            case argTypes(TextList[i])
            of "reg reg":   TextList[i][1] = "0x0d"
            of "reg int":   TextList[i][1] = "0x0e"
            of "dreg dreg": TextList[i][1] = "0x0f"
            of "dreg int":  TextList[i][1] = "0x10"
            else: error("Invalid Arguments", "\"" & argTypes(TextList[i]) & "\" are not valid arguments for \"adc\"")

        of "sub":
            case argTypes(TextList[i])
            of "reg reg":   TextList[i][1] = "0x11"
            of "reg int":   TextList[i][1] = "0x12"
            of "dreg dreg": TextList[i][1] = "0x13"
            of "dreg int":  TextList[i][1] = "0x14"
            else: error("Invalid Arguments", "\"" & argTypes(TextList[i]) & "\" are not valid arguments for \"sub\"")
        
        of "sbb":
            case argTypes(TextList[i])
            of "reg reg":   TextList[i][1] = "0x15"
            of "reg int":   TextList[i][1] = "0x16"
            of "dreg dreg": TextList[i][1] = "0x17"
            of "dreg int":  TextList[i][1] = "0x18"
            else: error("Invalid Arguments", "\"" & argTypes(TextList[i]) & "\" are not valid arguments for \"sbb\"")
        
        of "jif":
            case argTypes(TextList[i])
            of "int address":   TextList[i][1] = "0x1b"
            of "reg int":       TextList[i][1] = "0x19"
            else: error("Invalid Arguments", "\"" & argTypes(TextList[i]) & "\" are not valid arguments for \"jif\"")
        
        of "cif":
            case argTypes(TextList[i])
            of "int address":   TextList[i][1] = "0x1c"
            of "reg int":       TextList[i][1] = "0x1a"
            else: error("Invalid Arguments", "\"" & argTypes(TextList[i]) & "\" are not valid arguments for \"cif\"")

        of "ret":
            if argTypes(TextList[i]) != "none none":
                error("Invalid Arguments", "\"" & argTypes(TextList[i]) & "\" are not valid arguments for \"ret\"")
            TextList[i][1] = "0x1D"
        
        of "push":
            case argTypes(TextList[i])
            of "reg none":  TextList[i][1] = "0x1e"
            of "dreg none": TextList[i][1] = "0x1f"
            of "int none":
                if parseInt(TextList[i][2]) > 0xff or parseInt(TextList[i][2]) < -0x80:
                    TextList[i][1] = "0x21"
                else:
                    TextList[i][1] = "0x20"
            else: error("Invalid Arguments", "\"" & argTypes(TextList[i]) & "\" are not valid arguments for \"push\"")

        of "pop":
            case argTypes(TextList[i])
            of "reg none":  TextList[i][1] = "0x22"
            of "dreg none": TextList[i][1] = "0x23"
            else: error("Invalid Arguments", "\"" & argTypes(TextList[i]) & "\" are not valid arguments for \"pop\"")

        of "and":
            case argTypes(TextList[i])
            of "reg reg":   TextList[i][1] = "0x24"
            of "reg int":   TextList[i][1] = "0x25"
            of "dreg dreg": TextList[i][1] = "0x26"
            of "dreg int":  TextList[i][1] = "0x27"
            else: error("Invalid Arguments", "\"" & argTypes(TextList[i]) & "\" are not valid arguments for \"and\"")
        
        of "or":
            case argTypes(TextList[i])
            of "reg reg":   TextList[i][1] = "0x28"
            of "reg int":   TextList[i][1] = "0x29"
            of "dreg dreg": TextList[i][1] = "0x2a"
            of "dreg int":  TextList[i][1] = "0x2b"
            else: error("Invalid Arguments", "\"" & argTypes(TextList[i]) & "\" are not valid arguments for \"or\"")

        of "not":
            case argTypes(TextList[i])
            of "reg none":  TextList[i][1] = "0x2c"
            of "dreg none": TextList[i][1] = "0x2d"

        of "cmp":
            case argTypes(TextList[i])
            of "reg reg":   TextList[i][1] = "0x2e"
            of "reg int":   TextList[i][1] = "0x2f"
            of "dreg dreg": TextList[i][1] = "0x30"
            of "dreg int":  TextList[i][1] = "0x31"
            else: error("Invalid Arguments", "\"" & argTypes(TextList[i]) & "\" are not valid arguments for \"cmp\"")
        
        of "scmp":
            case argTypes(TextList[i])
            of "reg reg":   TextList[i][1] = "0x32"
            of "reg int":   TextList[i][1] = "0x33"
            of "dreg dreg": TextList[i][1] = "0x34"
            of "dreg int":  TextList[i][1] = "0x35"
            else: error("Invalid Arguments", "\"" & argTypes(TextList[i]) & "\" are not valid arguments for \"scmp\"")
        
        of "shl":
            case argTypes(TextList[i])
            of "reg int":   TextList[i][1] = "0x36"
            of "dreg int":  TextList[i][1] = "0x37"
            else: error("Invalid Arguments", "\"" & argTypes(TextList[i]) & "\" are not valid arguments for \"shl\"")
        
        of "asr":
            case argTypes(TextList[i])
            of "reg int":   TextList[i][1] = "0x38"
            of "dreg int":  TextList[i][1] = "0x39"
            else: error("Invalid Arguments", "\"" & argTypes(TextList[i]) & "\" are not valid arguments for \"asr\"")
        
        of "lsr":
            case argTypes(TextList[i])
            of "reg int":   TextList[i][1] = "0x3A"
            of "dreg int":  TextList[i][1] = "0x3B"
            else: error("Invalid Arguments", "\"" & argTypes(TextList[i]) & "\" are not valid arguments for \"lsr\"")
        
        of "hcf":
            if argTypes(TextList[i]) != "none none":
                error("Invalid Arguments", "\"" & argTypes(TextList[i]) & "\" are not valid arguments for \"hcf\"")
            TextList[i][1] = "0x3F"

        else:
            # TextList[i][2] = argType(TextList[i][2])
            # TextList[i][3] = argType(TextList[i][3])
            error("Invalid Instruction", "\"" & TextList[i][1] & "\" is not a valid instruction")
            
proc alignIrregularArguments() =
    for i in 0..<TextList.len:
        case TextList[i][1]:
        of "0x04", "0x06", "0x07":
            # let temp = TextList[i][2]
            # TextList[i][2] = TextList[i][3]
            # TextList[i][3] = temp
            swap(TextList[i][2],TextList[i][3])
        else: discard

proc resolveLabels() = 
    IList = concat(TextList, RODataList)


# ------------------------------------------------------------------------- #


loadCMDLineArguments()
var aphelFile = readFile(Path)
aphelFile = aphelFile.decify()
aphelFile = aphelFile.clean()
populate(aphelFile)
breakoutIList()
generalChecks()
nameToOpcodeAndSuch()
alignIrregularArguments()
resolveLabels()
writeFile(Path.changeFileExt("txt"), $IList)