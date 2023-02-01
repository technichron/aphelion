
# ╔════════════════════════╗
# ║ APHELION ASSEMBLER 2.0 ║ by technichron
# ╚════════════════════════╝

import std/strutils, std/sequtils, std/terminal, std/tables, codepage

# var IL: seq[array[4, string]] # [label, opcode, arg1, arg2]

#var SymbolTable: seq[array[2,string]]

proc error(errortype, message: string) =
    styledEcho styleDim, fgRed, errortype, ":", fgDefault, styleDim, " ", message
    quit(0)

proc cleanComments(file: string): string =
    var lines = file.splitLines()


    for l in 0..lines.high():
        lines[l] = lines[l].strip()
        if lines[l] != "":
            if lines[l][0] == '#':
                lines[l] = ""
            else:
                lines[l] = lines[l].split('#')[0]
                lines[l] = lines[l].strip()
    
    lines = lines.filterIt(it.len() != 0)

    for l in 0..lines.high():
        result.add lines[l] & "\n"

proc decify(file: string): string = #turns all integer types and characters into decimal values
    var lines = file.splitLines()

    for l in 0..lines.high():
        if find(lines[l], '\'') != -1:
            let character =  lines[l][find(lines[l], '\'')..find(lines[l], '\'', find(lines[l], '\'')+1)]
            case character.len()
                of 2:
                    error("Invalid Argument", "[" & $l & "] empty char:" & lines[l])
                else:
                    try:
                        lines[l] = lines[l].replace(character, $codepage[character[1..(character.len-2)]])
                    except:
                        error("Invalid Argument", "[" & $l & "] char length != 1: " & lines[l])
    
    for l in 0..lines.high():
        if find(lines[l], "0x") != -1:
            #echo lines[l][find(lines[l], "0x")]
            discard

    
    for l in 0..lines.high():
        result.add lines[l] & "\n"

# ------------------------------------------------------------------------- #


# eraseScreen()
# setCursorPos(0, 0)

var aphelFile = readFile("./aphel/helloworldalt.aphel")
aphelFile = aphelFile.decify()
aphelFile = aphelFile.cleanComments()
writeFile("./src/assembler/bruh.txt", aphelFile)