
# ╔════════════════════════╗
# ║ APHELION ASSEMBLER 2.0 ║ by technichron
# ╚════════════════════════╝

import std/strutils, std/sequtils, std/terminal, std/tables, std/os, std/parseopt, std/bitops
from std/unicode import graphemeLen

const 
    codepage = {"\\0":0x00,"☺":0x01,"☻":0x02,"♥":0x03,"♦":0x04,"♣":0x05,"♠":0x06,"•":0x07,"\\b":0x08,"○":0x09,"\\n":0x0A,"\\c":0x0B,"\\r":0x0C,"♪":0x0D,"\\i":0x0E,"\\d":0x0F,
                  "►":0x10,"◄":0x11,"↕":0x12,"‼":0x13,"¶":0x14,"§":0x15,"▬":0x16,"↨":0x17,"↑":0x18,"↓":0x19,"→":0x1A,"←":0x1B,"∟":0x1C,"↔":0x1D,"▲":0x1E,"▼":0x1F,
                  " ":0x20,"!":0x21,"\\\"":0x22,"#":0x23,"$":0x24,"%":0x25,"&":0x26,"\\\'":0x27,"(":0x28,")":0x29,"*":0x2A,"+":0x2B,",":0x2C,"-":0x2D,".":0x2E,"/":0x2F,
                  "0":0x30,"1":0x31,"2":0x32,"3":0x33,"4":0x34,"5":0x35,"6":0x36,"7":0x37,"8":0x38,"9":0x39,":":0x3A,";":0x3B,"<":0x3C,"=":0x3D,">":0x3E,"?":0x3F,
                  "@":0x40,"A":0x41,"B":0x42,"C":0x43,"D":0x44,"E":0x45,"F":0x46,"G":0x47,"H":0x48,"I":0x49,"J":0x4A,"K":0x4B,"L":0x4C,"M":0x4D,"N":0x4E,"O":0x4F,
                  "P":0x50,"Q":0x51,"R":0x52,"S":0x53,"T":0x54,"U":0x55,"V":0x56,"W":0x57,"X":0x58,"Y":0x59,"Z":0x5A,"[":0x5B,"\\\\":0x5C,"]":0x5D,"^":0x5E,"_":0x5F,
                  "`":0x60,"a":0x61,"b":0x62,"c":0x63,"d":0x64,"e":0x65,"f":0x66,"g":0x67,"h":0x68,"i":0x69,"j":0x6A,"k":0x6B,"l":0x6C,"m":0x6D,"n":0x6E,"o":0x6F,
                  "p":0x70,"q":0x71,"r":0x72,"s":0x73,"t":0x74,"u":0x75,"v":0x76,"w":0x77,"x":0x78,"y":0x79,"z":0x7A,"{":0x7B,"|":0x7C,"}":0x7D,"~":0x7E,"⌂":0x7F,
                  "Ç":0x80,"ü":0x81,"é":0x82,"â":0x83,"ä":0x84,"à":0x85,"å":0x86,"ç":0x87,"ê":0x88,"ë":0x89,"è":0x8A,"ï":0x8B,"î":0x8C,"ì":0x8D,"Ä":0x8E,"Å":0x8F,
                  "É":0x90,"§":0x91,"Æ":0x92,"ô":0x93,"ö":0x94,"ò":0x95,"û":0x96,"ù":0x97,"ÿ":0x98,"Ö":0x99,"Ü":0x9A,"¢":0x9B,"£":0x9C,"¥":0x9D,"₧":0x9E,"ƒ":0x9F,
                  "á":0xA0,"í":0xA1,"ó":0xA2,"ú":0xA3,"ñ":0xA4,"Ñ":0xA5,"ª":0xA6,"º":0xA7,"¿":0xA8,"⌐":0xA9,"¬":0xAA,"½":0xAB,"¼":0xAC,"¡":0xAD,"«":0xAE,"»":0xAF,
                  "░":0xB0,"▒":0xB1,"▓":0xB2,"│":0xB3,"┤":0xB4,"╡":0xB5,"╢":0xB6,"╖":0xB7,"╕":0xB8,"╣":0xB9,"║":0xBA,"╗":0xBB,"╝":0xBC,"╜":0xBD,"╛":0xBE,"┐":0xBF,
                  "└":0xC0,"┴":0xC1,"┬":0xC2,"├":0xC3,"─":0xC4,"┼":0xC5,"╞":0xC6,"╟":0xC7,"╚":0xC8,"╔":0xC9,"╩":0xCA,"╦":0xCB,"╠":0xCC,"═":0xCD,"╬":0xCE,"╧":0xCF,
                  "╨":0xD0,"╤":0xD1,"╥":0xD2,"╙":0xD3,"╘":0xD4,"╒":0xD5,"╓":0xD6,"╫":0xD7,"╪":0xD8,"┘":0xD9,"┌":0xDA,"█":0xDB,"▄":0xDC,"▌":0xDD,"▐":0xDE,"▀":0xDF,
                  "α":0xE0,"ß":0xE1,"Γ":0xE2,"π":0xE3,"Σ":0xE4,"σ":0xE5,"µ":0xE6,"τ":0xE7,"Φ":0xE8,"Θ":0xE9,"Ω":0xEA,"δ":0xEB,"∞":0xEC,"φ":0xED,"ε":0xEE,"∩":0xEF,
                  "≡":0xF0,"±":0xF1,"≥":0xF2,"≤":0xF3,"⌠":0xF4,"⌡":0xF5,"÷":0xF6,"≈":0xF7,"°":0xF8,"∙":0xF9,"·":0xFA,"√":0xFB,"ⁿ":0xFC,"²":0xFD,"■":0xFE,"\\a":0xFF}.toTable()

    ByteRegisterNames = "ra rb rc rd re rf rgl rgh ril rih rjl rjh rkl rkh rpl rph rsl rsh rrl rrh rxl rxh ryl ryh "
    DoubleRegisterNames = "rg ri rj rk rp rs rx ry "
    RegisterCodes = {"ra": 0x00,"rb": 0x01,"rc": 0x02,"rd": 0x03,"re": 0x04,"rf": 0x05,"rgl": 0x06,"rgh": 0x16,"ril": 0x08,"rih": 0x18,"rjl": 0x09,"rjh": 0x19,"rkl": 0x0a,"rkh": 0x1a
                        ,"rpl": 0x0b,"rph": 0x1b,"rsl": 0x0c,"rsh": 0x1c,"rrl": 0x0d,"rrh": 0x1d,"rxl": 0x0e,"rxh": 0x1e,"ryl": 0x0f,"ryh": 0x1f
,"rg": 0x06,"ri": 0x08,"rj": 0x09,"rk": 0x0a,"rp": 0x0b,"rs": 0x0c,"rr": 0x0d,"rx": 0x0e,"ry": 0x0f}.toTable()

var 
    ITable: seq[array[4, string]] # [label, opcode, arg1, arg2]
    TextTable: seq[array[4, string]]
    RODataTable: seq[array[4, string]]
    DataTable: seq[array[4, string]]
    SymbolTable: Table[string, int]
    Path: string
    AphelionImage: string

proc `$`(s: seq[array[4, string]]): string =
    for element in s:
        result.add $element
        result.add "\n"

proc prettyS(s: seq[array[4, string]]): string =
    for element in s:
        result.add element[0]
        result.add "\t"
        if element[0] == "": result.add "\t │ "
        else: result.add " ╪ "
        result.add element[1]
        result.add "\t"
        result.add element[2]
        result.add "\t"
        result.add element[3]
        result.add "\n"

proc prettyS(s: Table[string, int]): string =
    for symbol, address in s.pairs:
        result.add symbol
        result.add "\t"
        result.add " ╪ $"
        result.add toHex(address,4)
        result.add "\n"

proc error(errortype, message: string) =
    styledEcho styleDim, fgRed, errortype, ":", fgDefault, styleDim, " ", message
    quit(0)

proc getInstructionFormat(opcode: string): string =
    case opcode
        of "00", "1d", "3f":
            return "NA"
        of "1e", "1f", "22", "23", "2c", "2d":
            return "RE"
        of "02", "03", "09", "0b", "0d", "0f", "11", "13", "15", "17", "24", "26", "28", "2a", "2e", "30", "32", "34", "3d":
            return "RR"
        of "20":
            return "BY"
        of "04", "0a", "0e", "12", "16", "25", "29", "2f", "33", "36", "37", "38", "39", "3a", "3b", "19", "1a":
            return "RB"
        of "21":
            return "DO"
        of "01", "06", "07", "0c", "10", "14", "18", "27", "2b", "31", "35", "3c":
            return "RD"
        of "05", "1b", "1c":
            return "BD"
        of "08":
            return "DD"
        else:
            return "INVALID"

proc getInstructionLength(opcode: string): int =
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

proc dealWithMacros(f: string): string =

    var file = f

    while file.find("@macro") != -1:

        var macroText = file[file.find("@macro")..(file.find("@endmacro")+8)]
        file = file.replace(file[file.find("@macro")..(file.find("@endmacro")+8)], "")

        let macroName = macroText.splitWhitespace()[1]
        let numOfArgs = macroText.splitLines()[0].splitWhitespace().len - 2
        var argSeq: seq[string]

        for x in 1..numOfArgs:
            argSeq.add macroText.splitLines()[0].splitWhitespace()[x+1]

        while file.find("\n" & macroName) != -1 or file.find(" " & macroName) != -1:
            var lineToReplace = ""
            var argsToReplace: seq[string]
            for line in file.splitLines:
                if line.find(macroName) == -1: continue
                lineToReplace = line
                break

            if lineToReplace.splitWhitespace().len - 1 != numOfArgs:
                error("Invalid Argument","incorrect number of arguments for \"" & macroName & "\"")

            for x in 1..numOfArgs:
                argsToReplace.add lineToReplace.splitWhitespace()[x]

            var replacementText = macroText.multiReplace((macroText.splitLines()[0]&"\n",""),("@endmacro",""))
            
            for arg in 0..numOfArgs-1:
                replacementText = replacementText.replace(argSeq[arg], argsToReplace[arg])
            
            file = file.replace(lineToReplace, replacementText)
    file = file.clean
    return file

proc decify(file: string): string = # turns all integer types and characters into decimal values for easier parsing later
    var lines = file.splitLines()
    for x in 0..1: # iteration times
        for l in 0..lines.high():
            lines[l] = lines[l].strip
            lines[l].add(" ")
            if find(lines[l], '\'') != -1:
                let character =  lines[l][find(lines[l], '\'')..rfind(lines[l], '\'', find(lines[l], '\'')+1)]
                try: lines[l] = lines[l].replace(character, $codepage[character[1..(character.len-2)]])
                except:
                    error("Invalid Argument", "[" & $l & "] invalid char: " & character)

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
                    str = lines[l][find(lines[l], '\"')..rfind(lines[l], '\"', find(lines[l], '\"')+1)]
                    lines[l] = lines[l].replace(str, str.replace(" ", "\\_").strip(chars = {'\'', '\"'})) #\_ is escape code for space
                except:
                    str = lines[l][find(lines[l], '\"')..rfind(lines[l], Whitespace, find(lines[l], '\"')+1)]
                    error("Invalid Argument", "[" & $l & "] invalid string: " & str)
            if lines[l].split[0].endsWith(':') and lines[l].split.len > 1:
                var line = lines[l].split
                line[0].add "\n"
                lines[l] = line.join(" ")
    
    for l in 0..lines.high:
        result.add lines[l]
        if l < lines.high: result.add "\n"

proc handleImports(f: string): string =
    result = f
    for line in f.splitLines():
        if line == "": continue
        if line.splitWhitespace()[0] != "@import": continue
        result = result.replace(line, readFile(addFileExt(line.splitWhitespace()[1],"aphel")))

proc populate(assemblyfile: string) =
    
    ITable.add ["","","",""]
    
    var l = 0
    for currentLine in assemblyfile.splitLines:
        inc l
        if currentLine.endsWith(':'):
            ITable[ITable.high][0] = currentLine[0..currentLine.high-1]
        else:
            if currentLine.split.len <= 3:
                for i in 1..currentLine.split.len:
                    ITable[ITable.high][i] = currentLine.split[i-1]
            else:
                error("Invalid Instruction", "[" & $l & "] invalid argument number : " & currentLine)
            if l != assemblyfile.splitLines.len: ITable.add ["","","",""]
    
    for i in 0..<ITable.len:
        if ITable[i][1] == "string": ITable[i][2] = ITable[i][2].replace("\\_", " ")
                
proc generalChecks() =
    block globalChecks:
        var globalcount = 0
        for entry in TextTable:
            if entry[1] != "@global":
                continue
            inc globalcount
        if globalcount < 1:
            error("Assembler Error", "no entry point found: use \"@global\" to define an entry point.")
        if globalcount > 1:
            error("Assembler Error", "multiple entry points found")
    
proc breakoutITable() =
    var mode = ""
    for entry in ITable:
        if entry[1] == "@segment":
            case entry[2]:
            of "text", "rodata", "data":
                mode = entry[2]
                continue
            else:
                error("Assembler Error", "invalid segment type: " & entry[2])
        case mode
        of "text":
            TextTable.add entry
        of "rodata":
            RODataTable.add entry
        of "data":
            DataTable.add entry
    
    # echo TextTable
    # echo RODataTable
    # echo DataTable

proc argType(arg: string): string =
    if arg == "":
        return "none"
    elif arg[0] == '$':
        result.add "address"
        if arg[1..<arg.len].toLower & " " in ByteRegisterNames:
            result.add "_reg"
        if arg[1..<arg.len].toLower & " " in DoubleRegisterNames:
            result.add "_dreg"
    elif arg.toLower & " " in ByteRegisterNames:
        return "reg"
    elif arg.toLower & " " in DoubleRegisterNames:
        return "dreg"
    else:
        try:
            let x = parseInt(arg)
            return "int"
        except ValueError:
            return "int" # label

proc argTypes(line: array[4, string]): string =
    return argType(line[2]) & " " & argType(line[3])

proc nameToOpcodeAndSuch() =
    for i in 0..<TextTable.len:
        case TextTable[i][1]:
        of "@global":
            TextTable[i][1] = "06"
            TextTable[i][3] = "rP"

        of "nop":
            if argTypes(TextTable[i]) != "none none":
                error("Invalid Arguments", "\"" & argTypes(TextTable[i]) & "\" are not valid arguments for \"nop\"")
            TextTable[i][1] = "00"
        
        of "mov":
            case argTypes(TextTable[i])
            of "reg int":           TextTable[i][1] = "01"
            of "reg reg":           TextTable[i][1] = "02"
            of "dreg dreg":         TextTable[i][1] = "03"
            of "int reg":           TextTable[i][1] = "04"
            of "int int":           TextTable[i][1] = "05"
            of "int dreg":          TextTable[i][1] = "06"
            of "address reg":       TextTable[i][1] = "07"
            of "address int":       TextTable[i][1] = "08"
            of "address_dreg int":  TextTable[i][1] = "3c"
            of "address_dreg reg":  TextTable[i][1] = "3d"
            else: error("Invalid Arguments", "\"" & argTypes(TextTable[i]) & "\" are not valid arguments for \"mov\"")

        of "add":
            case argTypes(TextTable[i])
            of "reg reg":   TextTable[i][1] = "09"
            of "reg int":   TextTable[i][1] = "0a"
            of "dreg dreg": TextTable[i][1] = "0b"
            of "dreg int":  TextTable[i][1] = "0c"
            else: error("Invalid Arguments", "\"" & argTypes(TextTable[i]) & "\" are not valid arguments for \"add\"")
        
        of "adc":
            case argTypes(TextTable[i])
            of "reg reg":   TextTable[i][1] = "0d"
            of "reg int":   TextTable[i][1] = "0e"
            of "dreg dreg": TextTable[i][1] = "0f"
            of "dreg int":  TextTable[i][1] = "10"
            else: error("Invalid Arguments", "\"" & argTypes(TextTable[i]) & "\" are not valid arguments for \"adc\"")

        of "sub":
            case argTypes(TextTable[i])
            of "reg reg":   TextTable[i][1] = "11"
            of "reg int":   TextTable[i][1] = "12"
            of "dreg dreg": TextTable[i][1] = "13"
            of "dreg int":  TextTable[i][1] = "14"
            else: error("Invalid Arguments", "\"" & argTypes(TextTable[i]) & "\" are not valid arguments for \"sub\"")
        
        of "sbb":
            case argTypes(TextTable[i])
            of "reg reg":   TextTable[i][1] = "15"
            of "reg int":   TextTable[i][1] = "16"
            of "dreg dreg": TextTable[i][1] = "17"
            of "dreg int":  TextTable[i][1] = "18"
            else: error("Invalid Arguments", "\"" & argTypes(TextTable[i]) & "\" are not valid arguments for \"sbb\"")
        
        of "jif":
            case argTypes(TextTable[i])
            of "int int":   TextTable[i][1] = "1b"
            of "int dreg":  TextTable[i][1] = "19"
            else: error("Invalid Arguments", "\"" & argTypes(TextTable[i]) & "\" are not valid arguments for \"jif\"")
        
        of "cif":
            case argTypes(TextTable[i])
            of "int int":   TextTable[i][1] = "1c"
            of "int dreg":  TextTable[i][1] = "1a"
            else: error("Invalid Arguments", "\"" & argTypes(TextTable[i]) & "\" are not valid arguments for \"cif\"")

        of "ret":
            if argTypes(TextTable[i]) != "none none":
                error("Invalid Arguments", "\"" & argTypes(TextTable[i]) & "\" are not valid arguments for \"ret\"")
            TextTable[i][1] = "1D"
        
        of "push":
            case argTypes(TextTable[i])
            of "reg none":  TextTable[i][1] = "1e"
            of "dreg none": TextTable[i][1] = "1f"
            of "int none":
                if parseInt(TextTable[i][2]) > 0xff or parseInt(TextTable[i][2]) < -0x80:
                    TextTable[i][1] = "21"
                else:
                    TextTable[i][1] = "20"
            else: error("Invalid Arguments", "\"" & argTypes(TextTable[i]) & "\" are not valid arguments for \"push\"")

        of "pop":
            case argTypes(TextTable[i])
            of "reg none":  TextTable[i][1] = "22"
            of "dreg none": TextTable[i][1] = "23"
            else: error("Invalid Arguments", "\"" & argTypes(TextTable[i]) & "\" are not valid arguments for \"pop\"")

        of "and":
            case argTypes(TextTable[i])
            of "reg reg":   TextTable[i][1] = "24"
            of "reg int":   TextTable[i][1] = "25"
            of "dreg dreg": TextTable[i][1] = "26"
            of "dreg int":  TextTable[i][1] = "27"
            else: error("Invalid Arguments", "\"" & argTypes(TextTable[i]) & "\" are not valid arguments for \"and\"")
        
        of "or":
            case argTypes(TextTable[i])
            of "reg reg":   TextTable[i][1] = "28"
            of "reg int":   TextTable[i][1] = "29"
            of "dreg dreg": TextTable[i][1] = "2a"
            of "dreg int":  TextTable[i][1] = "2b"
            else: error("Invalid Arguments", "\"" & argTypes(TextTable[i]) & "\" are not valid arguments for \"or\"")

        of "not":
            case argTypes(TextTable[i])
            of "reg none":  TextTable[i][1] = "2c"
            of "dreg none": TextTable[i][1] = "2d"

        of "cmp":
            case argTypes(TextTable[i])
            of "reg reg":   TextTable[i][1] = "2e"
            of "reg int":   TextTable[i][1] = "2f"
            of "dreg dreg": TextTable[i][1] = "30"
            of "dreg int":  TextTable[i][1] = "31"
            else: error("Invalid Arguments", "\"" & argTypes(TextTable[i]) & "\" are not valid arguments for \"cmp\"")
        
        of "scmp":
            case argTypes(TextTable[i])
            of "reg reg":   TextTable[i][1] = "32"
            of "reg int":   TextTable[i][1] = "33"
            of "dreg dreg": TextTable[i][1] = "34"
            of "dreg int":  TextTable[i][1] = "35"
            else: error("Invalid Arguments", "\"" & argTypes(TextTable[i]) & "\" are not valid arguments for \"scmp\"")
        
        of "shl", "asl", "lsl":
            case argTypes(TextTable[i])
            of "reg int":   TextTable[i][1] = "36"
            of "dreg int":  TextTable[i][1] = "37"
            else: error("Invalid Arguments", "\"" & argTypes(TextTable[i]) & "\" are not valid arguments for \"shl\"")
        
        of "asr":
            case argTypes(TextTable[i])
            of "reg int":   TextTable[i][1] = "38"
            of "dreg int":  TextTable[i][1] = "39"
            else: error("Invalid Arguments", "\"" & argTypes(TextTable[i]) & "\" are not valid arguments for \"asr\"")
        
        of "lsr":
            case argTypes(TextTable[i])
            of "reg int":   TextTable[i][1] = "3a"
            of "dreg int":  TextTable[i][1] = "3b"
            else: error("Invalid Arguments", "\"" & argTypes(TextTable[i]) & "\" are not valid arguments for \"lsr\"")
        
        of "hcf":
            if argTypes(TextTable[i]) != "none none":
                error("Invalid Arguments", "\"" & argTypes(TextTable[i]) & "\" are not valid arguments for \"hcf\"")
            TextTable[i][1] = "3f"

        else:
            error("Invalid Instruction", "\"" & TextTable[i][1] & "\" is not a valid instruction")

    for i in 0..<TextTable.len:
        case TextTable[i][1]
        of "04", "06", "07", "19", "1a":
            swap(TextTable[i][2],TextTable[i][3])
        
        try:
            TextTable[i][2] = $RegisterCodes[TextTable[i][2].toLower.strip(chars = {'$'})]
        except: discard
        try:
            TextTable[i][3] = $RegisterCodes[TextTable[i][3].toLower.strip(chars = {'$'})]
        except: discard

proc aphLen(s: string): int = # gets length of string using the aphelion codepage
    var pos = 0
    var acc = 0
    while pos < s.len:
        try:
            let v = codepage[$s[pos..<(pos+s.graphemeLen(pos))]]
            pos += s.graphemeLen(pos)
        except:
            try:
                let v = codepage[$s[pos..(pos+1)]]
                pos += 2
            except:
                error("Invalid Argument", "\'" & $s[pos..<(pos+s.graphemeLen(pos))] & "\' is not encodable - see the codepage for all encodable characters")
        inc acc
    return acc

proc resolveLabels() = 
    ITable = concat(TextTable, RODataTable)

    var bytePointer = 0

    for instruction in ITable:
        if instruction[0] != "":
            SymbolTable[instruction[0]] = bytePointer
        case instruction[1]
        of "uint8", "sint8", "char":
            bytePointer += 1
        of "uint16", "sint16":
            bytePointer += 2
        of "string":
            bytePointer += aphLen(instruction[2])
        of "file":
            bytePointer += readFile(instruction[2]).len
        else:
            bytePointer += getInstructionLength(instruction[1])
        if bytePointer > 0x8fff:
            error("Compilation Error", "text / rodata exceeds ROM space")
    
    bytePointer = 0x9000

    for instruction in DataTable:
        if instruction[0] != "":
            SymbolTable[instruction[0]] = bytePointer
        case instruction[1]
        of "uint8", "sint8", "char":
            bytePointer += 1
        of "uint16", "sint16":
            bytePointer += 2
        of "string":
            bytePointer += aphLen(instruction[2])
        of "file":
            bytePointer += readFile(instruction[2]).len
        if bytePointer > 0xffff:
            error("Compilation Error", "data exceeds RAM space")
        
    for i in 0..<TextTable.len:
        for k in SymbolTable.keys:
            if TextTable[i][2] == k: TextTable[i][2] = $SymbolTable[k]
            if TextTable[i][3] == k: TextTable[i][3] = $SymbolTable[k]

proc addByte(v: SomeInteger) =
    AphelionImage.add (v.uint8.char)

proc constructImage() = 
    for instruction in TextTable:

        let opcode = fromHex[int](instruction[1])
        var arg1 = 0
        var arg2 = 0
        if instruction[2] != "":
            arg1 = parseInt(instruction[2].strip(chars = {'$'}))
        if instruction[3] != "":
            arg2 = parseInt(instruction[3].strip(chars = {'$'}))

        case getInstructionFormat(instruction[1])
        of "NA":
            addByte(opcode*4)
        of "RE":
            addByte(opcode*4)
            addByte(arg1*8)
        of "RR":
            addByte(opcode*4 + (arg1/8).int)
            addByte(arg1*32 + arg2)
        of "BY":
            addByte(opcode*4)
            addByte(arg1)
        of "RB":
            addByte(opcode*4)
            addByte(arg1*8)
            addByte(arg2)
        of "DO":
            addByte(opcode*4)
            addByte(arg1)
            addByte((arg1/256).int)
        of "RD":
            addByte(opcode*4)
            addByte(arg1*8)
            addByte(arg2)
            addByte((arg2/256).int)
        of "BD":
            addByte(opcode*4)
            addByte(arg1)
            addByte(arg2)
            addByte((arg2/256).int)
        of "DD":
            addByte(opcode*4)
            addByte(arg1)
            addByte((arg1/256).int)
            addByte(arg2)
            addByte((arg2/256).int)
    
    for data in RODataTable:
        case data[1]
        of "uint8":
            addByte(parseUInt(data[2]))
        of "sint8":
            addByte(parseInt(data[2]))
        of "char":
            addByte(parseUInt(data[2]))
        of "uint16":
            addByte(parseUInt(data[2]))
            addByte(parseUInt(data[2]).bitsliced(8..15))
        of "sint16":
            addByte(parseInt(data[2]).bitsliced(0..7))
            addByte(parseInt(data[2]).bitsliced(8..15))
        of "string":
            var pos = 0
            var s = data[2]
            while pos < s.len:
                try:
                    addByte(codepage[$s[pos..<(pos+s.graphemeLen(pos))]])
                    pos += s.graphemeLen(pos)
                except:
                    try:
                        addByte(codepage[$s[pos..(pos+1)]])
                        pos += 2
                    except:
                        error("Invalid Argument", "\'" & $s[pos..<(pos+s.graphemeLen(pos))] & "\' is not encodable - see the codepage for all encodable characters")
        of "file":
            var file = readFile(data[2])
            for c in file:
                addByte(c.uint8)
        else:
            error("Invalid Datatype", "\"" & data[1] & "\" is not a valid datatype")
    
    while AphelionImage.len < 0x9000:
        addByte(0)
    
    for data in DataTable:
        case data[1]
        of "uint8":
            addByte(parseUInt(data[2]))
        of "sint8":
            addByte(parseInt(data[2]))
        of "char":
            addByte(parseUInt(data[2]))
        of "uint16":
            addByte(parseUInt(data[2]))
            addByte(parseUInt(data[2]).bitsliced(8..15))
        of "sint16":
            addByte(parseInt(data[2]).bitsliced(0..7))
            addByte(parseInt(data[2]).bitsliced(8..15))
        of "string":
            var pos = 0
            var s = data[2]
            while pos < s.len:
                try:
                    addByte(codepage[$s[pos..<(pos+s.graphemeLen(pos))]])
                    pos += s.graphemeLen(pos)
                except:
                    try:
                        addByte(codepage[$s[pos..(pos+1)]])
                        pos += 2
                    except:
                        error("Invalid Argument", "\'" & $s[pos..<(pos+s.graphemeLen(pos))] & "\' is not encodable - see the codepage for all encodable characters")
        of "file":
            var file = readFile(data[2])
            for c in file:
                addByte(c.uint8)
        else:
            error("Invalid Datatype", "\"" & data[1] & "\" is not a valid type")
    
    while AphelionImage.len <= 0xFFFF:
        addByte(0)

# ----------------------------- time to run shit ----------------------------- #

proc main() = 
    loadCMDLineArguments()
    var aphelFile = readFile(Path)
    aphelFile = aphelfile.handleImports()
    aphelFile = aphelFile.decify()
    aphelFile = aphelFile.clean()
    aphelFile = aphelFile.dealWithMacros()
    populate(aphelFile)
    breakoutITable()
    generalChecks()
    nameToOpcodeAndSuch()
    resolveLabels()
    constructImage()
    #writeFile(Path.changeFileExt("txt"), prettyS(TextTable) & "\n" & prettyS(RODataTable) & "\n" & prettyS(DataTable))
    writeFile(Path.changeFileExt("amg"), AphelionImage)

main()