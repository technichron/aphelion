import std/strutils

# APHELION assembler

proc level1pass(f: string): string =

    var file = splitLines(f)    # deliniate

    #result = $char(fromHex[uint]("61"))

    for i in file.low()..file.high():                               # strip leading and trailing whitespace
        file[i] = strip(file[i])

    var delSeq: seq[int]
    for i in file.low()..file.high():                               # remove comments
        if file[i][0] == '#': delSeq.add(i)
    for i in delSeq:
        file.delete(i)
    
    for i in file.low()..file.high():
        file[i] = file[i].split("#")[0]
    
    for i in file.low()..file.high():                               # strip leading and trailing whitespace
        file[i] = strip(file[i])
    
    for i in file.low()..file.high():
        if file[i]

    

    var instructionSequence = 


proc main() = 
    #L1 ASM pass
    let assemblyFile = readFile("sample.asm")

    let binaryFile = level1pass(assemblyFile)
    writeFile("binary.bin", binaryFile)
    






main()