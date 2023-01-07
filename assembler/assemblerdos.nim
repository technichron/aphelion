
# APHELION ASSEMBLER 2.0
# BY TECHNICHRON

import std/strutils, std/sequtils

proc takeCMDLineArguments() =

proc encodeArguments(f: string): string =
    for c in f.low()..f.high():
        if f[c] == '\'' and f[c+2] == '\'':
            echo f[c+1]

proc cleanse(f: string): string =

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
    
    for i in file.low()..file.high():
        result.add(file[i])
        result.add("\n")


proc main():

    takeCMDLineArguments() # determines parameters from command line arguments

    encodeArguments()

    cleanse() # removes comments

    expandCompoundInstructions() # expand compound instructions from templates

    resolveDefAndMacros() #

    resolveJumps()

    convertToBinary()