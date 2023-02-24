# ╔════════════════════════╗
# ║ APHELION ASSEMBLER 3.0 ║ by technichron
# ╚════════════════════════╝
# targeting aphelion 2 (.aphel)

import std/strutils, std/sequtils, std/terminal, std/tables, std/os, std/parseopt, std/bitops
from std/unicode import graphemeLen
import def, lexer, parser

var 
    Path: string

proc error(errortype, message: string) =
    styledEcho styleDim, fgRed, errortype, ":", fgDefault, styleDim, " ", message
    quit(0)

proc loadArgs() = 
    var p = initOptParser(commandLineParams().join(" "))
    while true:
        p.next()
        case p.kind
            of cmdEnd:
                break
            of cmdArgument:
                Path = p.key
            else: 
                discard

# proc cleanAndCondense(a: var string) =
#     while a.contains("'"):

proc decify(file: string): string = # sanitizes literals
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
                    lines[l] = lines[l].replace(str, str.replace(" ", "\\x20").strip(chars = {'\'', '\"'}))
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

# ------------------------------------------------------------------------- #

loadArgs()
var assemblyText = readFile(Path)
assemblyText = assemblyText.decify()
var assm = assemblyText.lex()
assm = assm.parse()
writeFile(Path.changeFileExt("txt"), $assm)
