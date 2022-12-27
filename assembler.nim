import std/strutils, std/sequtils

# APHELION assembler

proc levelOneFlatten(f: string): seq[string] =

    var file = splitLines(f)    # deliniate

    #result = $char(fromHex[uint]("61"))

    for i in file.low()..file.high():                               # strip leading and trailing whitespace
        file[i] = strip(file[i])

    for i in file.low()..file.high():                               # remove comments
        if file[i][0] == '#': file[i] = ""
    
    for i in file.low()..file.high():
        file[i] = file[i].split("#")[0]
    
    for i in file.low()..file.high():                               # strip leading and trailing whitespace again
        file[i] = strip(file[i])
    
    var defineList: seq[array[2, string]]                       # sequence of definition statements to replace
    for i in file.low()..file.high():                               # in the format of ["name","value"]
        let line = file[i].split()
        if line[0] == "@define":
            defineList.add([line[1].replace(",", ""), line[2]])
            file[i] = ""
    
    for i in file.low()..file.high():
        for definition in defineList:
            file[i] = file[i].replaceWord(definition[0], definition[1])

    file = file.filterIt(it.len != 0)
    
    result = file

proc getDataType(value: string): string =
    return value[0..1]

proc levelOneBinaryConversion(input: seq[string]): string =

    for line in input:
        case line.split()[0]
        of "nop", "NOP":
            result.add("00000000")

        of "set", "SET":
            result.add("0001")
            echo line.split()[2]

        else: discard
        result.add(" ")


proc main() = 

    let raw = readFile("sample.asm")

    let flattened = levelOneFlatten(raw)

    let binaryFile = levelOneBinaryConversion(flattened)

    writeFile("binary.bin", binaryFile)
    






main()