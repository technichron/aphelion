
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
            return "label"

proc argTypes(line: array[4, string]): string =
    return argType(line[2]) & " " & argType(line[3])

proc nameToOpcodeAndSuch() =
    IList = concat(TextList)
    for i in 0..<TextList.len:
        case TextList[i][1]:
        of "@global":
            TextList[i][1] = "0x06"
            TextList[i][3] = "0x0b"

        of "nop":
            if argTypes(TextList[i]) != "none none":
                error("Invalid Arguments", "\"" & $argTypes(TextList[i]) & "\" are not valid arguments for \'nop\'")
            TextList[i][1] = "0x00"
        
        of "mov":
            case argTypes(TextList[i])
            of "reg address":
                TextList[i][1] = "0x01"
            of "reg reg":
                TextList[i][1] = "0x02"
            of "dreg dreg":
                TextList[i][1] = "0x03"
            of "int reg":
                TextList[i][1] = "0x04"
            of "int address":
                TextList[i][1] = "0x05"
            of "int dreg":
                TextList[i][1] = "0x06"
            of "address reg":
                TextList[i][1] = "0x07"
            of "address address":
                TextList[i][1] = "0x08"

        else:
            # TextList[i][2] = argType(TextList[i][2])
            # TextList[i][3] = argType(TextList[i][3])
            discard
            



# ------------------------------------------------------------------------- #


loadCMDLineArguments()
var aphelFile = readFile(Path)
aphelFile = aphelFile.decify()
aphelFile = aphelFile.clean()
populate(aphelFile)
breakoutIList()
generalChecks()
nameToOpcodeAndSuch()
writeFile(Path.changeFileExt("txt"), $TextList)
echo GC_getStatistics()