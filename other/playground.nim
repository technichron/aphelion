
# proc parseChar(byteChar: char): uint8 =
#     result = uint8(byteChar)

import std/strutils, std/sequtils

let raw = readFile("assembler/output.bin")

for b in raw:
    echo toBin(int(b),8)