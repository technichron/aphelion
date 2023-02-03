
# ╔════════════════════════╗
# ║ APHELION ASSEMBLER 2.0 ║ by technichron
# ╚════════════════════════╝

import std/strutils, std/sequtils, std/terminal, std/tables, codepage

var IList: seq[array[4, string]] # [label, opcode, arg1, arg2]

var SymbolTable: seq[array[2, string]]

proc `$`(s: seq[array[4, string]]): string =
    for element in s:
        result.add $element
        result.add "\n"

proc error(errortype, message: string) =
    styledEcho styleDim, fgRed, errortype, ":", fgDefault, styleDim, " ", message
    quit(0)

proc clean(file: string): string = # does exactly what it sounds like it does: clean comments and remove commas
    var lines = file.splitLines()


    for l in 0..lines.high():
        lines[l] = lines[l].strip()
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
        lines[l].add(" ")
        if find(lines[l], '\'') != -1:
            let character =  lines[l][find(lines[l], '\'')..find(lines[l], '\'', find(lines[l], '\'')+1)]
            try:
                lines[l] = lines[l].replace(character, $codepage[character[1..(character.len-2)]])
            except:
                error("Invalid Argument", "[" & $l & "] invalid char length: " & character)

        if find(lines[l], "0x") != -1:
            let num = lines[l][find(lines[l], "0x")..find(lines[l], Whitespace, find(lines[l], "0x")+1)].strip(chars = ({','}+Whitespace))
            try:
                lines[l] = lines[l].replace(num, $fromHex[uint](num))
            except:
                error("Invalid Argument", "[" & $l & "] invalid hexadecimal integer: " & num)

        if find(lines[l], "0b") != -1:
            let num = lines[l][find(lines[l], "0b")..find(lines[l], Whitespace, find(lines[l], "0b")+1)].strip(chars = ({','}+Whitespace))
            try:
                lines[l] = lines[l].replace(num, $fromBin[uint](num))
            except:
                echo num
                error("Invalid Argument", "[" & $l & "] invalid binary integer: " & num)
        
        if find(lines[l], "0o") != -1:
            let num = lines[l][find(lines[l], "0o")..find(lines[l], Whitespace, find(lines[l], "0o")+1)].strip(chars = ({','}+Whitespace))
            try:
                lines[l] = lines[l].replace(num, $fromOct[uint](num))
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
    
    for l in 0..lines.high:
        result.add lines[l]
        if l < lines.high: result.add "\n"


proc populate(il: var seq[array[4, string]], assemblyfile: string, symtable: var seq[array[2, string]]) =
    
    IList.add ["","","",""]
    
    var l = 0
    for currentLine in assemblyfile.splitLines:
        l += 1
        if currentLine.endsWith(':'):
            IList[IList.high][0] = currentLine[0..currentLine.high-1]
        else:
            case currentLine.split.len
            of 1:
                IList[IList.high][1] = currentLine.split[0]
            of 2:
                IList[IList.high][1] = currentLine.split[0]
                IList[IList.high][2] = currentLine.split[1]
            of 3:
                IList[IList.high][1] = currentLine.split[0]
                IList[IList.high][2] = currentLine.split[1]
                IList[IList.high][3] = currentLine.split[2]
            else:
                error("Invalid Instruction", "[" & $l & "] invalid argument length : " & currentLine)
            if l != assemblyfile.splitLines.len: IList.add ["","","",""]
    
    echo IList
            


        


# ------------------------------------------------------------------------- #


var aphelFile = readFile("./aphel/helloworldalt.aphel")
aphelFile = aphelFile.decify()
aphelFile = aphelFile.clean()
IList.populate(aphelFile, SymbolTable)
writeFile("./src/assembler/bruh.txt", aphelFile)