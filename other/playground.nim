
# proc parseChar(byteChar: char): uint8 =
#     result = uint8(byteChar)

import std/strutils, std/sequtils, std/bitops

# let raw = readFile("assembler/output.bin")
var x = 0b00100111

# stdout.write(char(uint8(72)))
# stdout.write(char(uint8(72)))

echo toBin(x, 8)
echo toBin(x.bitsliced(3..7), 5)