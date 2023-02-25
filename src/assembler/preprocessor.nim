import std/strutils, std/tables
import def

proc preprocess*(file: string): string =

    result = file

    block removeInitialNewlines:
        result.removePrefix({'\n', '\r'})

    block sanitizeLiterals:  # sanitizes literals
        var lines = result.splitLines()
        for x in 0..1: # iteration times
            for l in 0..lines.high():
                lines[l] = lines[l].strip
                lines[l].add(" ")
                if find(lines[l], '\'') != -1:
                    let character =  lines[l][find(lines[l], '\'')..rfind(lines[l], '\'', find(lines[l], '\'')+1)]
                    try: 
                        lines[l] = lines[l].replace(character, $codepage[character[1..(character.len-2)]])
                    except:
                        error("Invalid Argument", "[" & $l & "] invalid char: " & character)

                if find(lines[l], "0x") != -1:
                    let num = lines[l][find(lines[l], "0x")..find(lines[l], Whitespace, find(lines[l], "0x")+1)].strip(chars = ({','}+Whitespace))
                    try: 
                        lines[l] = lines[l].replace(num, $fromHex[uint](num))
                    except:
                        error("Invalid Argument", "[" & $l & "] invalid hexadecimal integer: " & num)

                if find(lines[l], "0b") != -1:
                    let num = lines[l][find(lines[l], "0b")..find(lines[l], Whitespace, find(lines[l], "0b")+1)].strip(chars = ({','}+Whitespace))
                    try: 
                        lines[l] = lines[l].replace(num, $fromBin[uint](num))
                    except:
                        echo num
                        error("Invalid Argument", "[" & $l & "] invalid binary integer: " & num)
                
                if find(lines[l], "0o") != -1:
                    let num = lines[l][find(lines[l], "0o")..find(lines[l], Whitespace, find(lines[l], "0o")+1)].strip(chars = ({','}+Whitespace))
                    try: 
                        lines[l] = lines[l].replace(num, $fromOct[uint](num))
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

        result = ""
        for l in 0..lines.high:
            result.add lines[l] & "\n"