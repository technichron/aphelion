# aphelion assembler

proc level1pass(file: string): string =
    # deliniate
    echo ""


proc main() = 
    #L1 ASM pass
    let assemblyFile = readFile("sample.asm")

    let binaryFile = level1pass(assemblyFile)
    writeFile("binary.bin", binaryFile)
    






main()