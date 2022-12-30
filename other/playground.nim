
# proc parseChar(byteChar: char): uint8 =
#     result = uint8(byteChar)

import std/strutils, std/sequtils, std/bitops

# let raw = readFile("assembler/output.bin")
var x: uint8 = 0b01000000
var y: uint8 = 0b11110111
var z: uint16 = 0b0100000011110111

# stdout.write(char(uint8(72)))
# stdout.write(char(uint8(72)))


echo x*256 + y
echo z