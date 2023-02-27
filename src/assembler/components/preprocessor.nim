import std/strutils
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
                if find(lines[l], '\"') != -1:
                    var str = ""
                    try:
                        str = lines[l][find(lines[l], '\"')..rfind(lines[l], '\"', find(lines[l], '\"')+1)]
                        lines[l] = lines[l].replace(str, str.replace(" ", "\\x20"))
                    except:
                        str = lines[l][find(lines[l], '\"')..rfind(lines[l], Whitespace, find(lines[l], '\"')+1)]
                        error("Invalid Argument", "[" & $(l+1) & "] invalid string: " & str)
                if lines[l].split[0].endsWith(':') and lines[l].split.len > 1:
                    var line = lines[l].split
                    line[0].add "\n"
                    lines[l] = line.join(" ")
        result = ""
        for l in 0..lines.high:
            result.add lines[l] & "\n"