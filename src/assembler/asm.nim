# ╔════════════════════════╗
# ║ APHELION ASSEMBLER 3.0 ║ by technichron
# ╚════════════════════════╝
# targeting aphelion 2 (.aphel)

import std/strutils, std/os, std/parseopt
import components/def, components/preprocessor, components/lexer, components/parser

var LoadPath: string
var StorePath: string

proc loadArgs() = 
    var p = initOptParser(commandLineParams().join(" "))
    while true:
        p.next()
        case p.kind
            of cmdEnd:
                break
            of cmdArgument:
                if LoadPath == "":
                    LoadPath = p.key
                else:
                    StorePath = p.key
            else: 
                discard

# ------------------------------------------------------------------------- #

loadArgs()

if LoadPath == "": error("Error", "no assembly path specified")

var assmTxt = readFile(LoadPath).preprocess
var assm = assmTxt.lex
assm = assm.parse

if StorePath != "":
    writeFile(StorePath, pretty(assm))
else:
    writeFile(LoadPath.changeFileExt("txt"), pretty(assm))
# if StorePath != "":
#     writeFile(StorePath, $assm)
# else:
#     writeFile(LoadPath.changeFileExt("txt"), $assm)