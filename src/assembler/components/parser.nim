import std/sequtils, std/tables, std/re, std/strutils
import def

proc parse*(a: seq[Token]): seq[Token] =
    
    var assm = a
    
    block cleanComments: # remove comments
        while true:

            var cStart = 0
            var cEnd = 0
            var cFound = false

            for i in 0..assm.high:
                if assm[i].t == Comment:
                    cStart = i
                    cFound = true
                    break
            for i in cStart..assm.high:
                if assm[i].t == NewLine:
                    cEnd = i-1
                    break

            if not cFound: break
            assm.delete(cStart..cEnd)
            

    block checkInstructionArguments: # check instruction arguments
        
        var tokenPointer = 0

        while tokenPointer < assm.len:
            if assm[tokenPointer].t != InstructionToken: 
                inc tokenPointer
                continue

            var arguments = block:
                var a: seq[Token]
                var i = 1
                while assm[tokenPointer+i].t != NewLine:
                    a.add assm[tokenPointer+i]
                    inc i
                a

            case assm[tokenPointer].val:
            of "nop":
                if arguments.len != 0:
                    error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- " & $arguments.getTokenTypes & " are not valid args for \'nop\'")
            of "mov":
                if arguments.getTokenTypes notin movArgTypes:
                    error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- " & $arguments.getTokenTypes & " are not valid args for \'mov\'")
            of "add":
                if arguments.getTokenTypes notin funcArgTypes:
                    error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- " & $arguments.getTokenTypes & " are not valid args for \'add\'")
            of "adc":
                if arguments.getTokenTypes notin funcArgTypes:
                    error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- " & $arguments.getTokenTypes & " are not valid args for \'adc\'")
            of "sub":
                if arguments.getTokenTypes notin funcArgTypes:
                    error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- " & $arguments.getTokenTypes & " are not valid args for \'sub\'")
            of "sbb":
                if arguments.getTokenTypes notin funcArgTypes:
                    error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- " & $arguments.getTokenTypes & " are not valid args for \'sbb\'")
            of "jif":
                if arguments.getTokenTypes notin jmpcallArgTypes:
                    error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- " & $arguments.getTokenTypes & " are not valid args for \'jif\'")
            of "cif":
                if arguments.getTokenTypes notin jmpcallArgTypes:
                    error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- " & $arguments.getTokenTypes & " are not valid args for \'cif\'")
            of "ret":
                if arguments.len != 0:
                    error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- " & $arguments.getTokenTypes & " are not valid args for \'ret\'")
            of "push":
                if arguments.getTokenTypes notin pushArgTypes:
                    error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- " & $arguments.getTokenTypes & " are not valid args for \'push\'")
            of "pop":
                if arguments.getTokenTypes notin regdregArgTypes:
                    error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- " & $arguments.getTokenTypes & " are not valid args for \'pop\'")
            of "and":
                if arguments.getTokenTypes notin funcArgTypes:
                    error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- " & $arguments.getTokenTypes & " are not valid args for \'and\'")
            of "or":
                if arguments.getTokenTypes notin funcArgTypes:
                    error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- " & $arguments.getTokenTypes & " are not valid args for \'or\'")
            of "not":
                if arguments.getTokenTypes notin regdregArgTypes:
                    error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- " & $arguments.getTokenTypes & " are not valid args for \'not\'")
            of "cmp":
                if arguments.getTokenTypes notin funcArgTypes:
                    error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- " & $arguments.getTokenTypes & " are not valid args for \'cmp\'")
            of "scmp":
                if arguments.getTokenTypes notin funcArgTypes:
                    error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- " & $arguments.getTokenTypes & " are not valid args for \'scmp\'")
            of "shl":
                if arguments.getTokenTypes notin shiftArgTypes:
                    error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- " & $arguments.getTokenTypes & " are not valid args for \'shl\'")
            of "asr":
                if arguments.getTokenTypes notin shiftArgTypes:
                    error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- " & $arguments.getTokenTypes & " are not valid args for \'asr\'")
            of "lsr":
                if arguments.getTokenTypes notin shiftArgTypes:
                    error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- " & $arguments.getTokenTypes & " are not valid args for \'lsr\'")
            of "hcf":
                if arguments.len != 0:
                    error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- " & $arguments.getTokenTypes & " are not valid args for \'hcf\'")
            else:
                # echo assm[tokenPointer].val
                # echo getTokenTypes(arguments)
                error("Error", "unrecognized instruction: " & assm[tokenPointer].val)
            tokenPointer += arguments.len + 1

    block checkDirectiveArguments: # check directive arguments

        var tokenPointer = 0

        while tokenPointer < assm.len:
            if assm[tokenPointer].t != Directive: 
                inc tokenPointer
                continue

            var arguments = block:
                var a: seq[Token]
                var i = 1
                while assm[tokenPointer+i].t != NewLine:
                    a.add assm[tokenPointer+i]
                    inc i
                a

            case assm[tokenPointer].val
            of "@segment":
                if arguments.len != 1:
                    error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- " & $arguments.getTokenTypes & " are not valid args for \'@segment\'")
                if arguments[0].val notin ["text", "data"]:
                    error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- \'" & arguments[0].val & "\' is not a valid argument for \'@segment\'")
            of "@define":
                if arguments.len != 2:
                    error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- " & $arguments.getTokenTypes & " are not valid args for \'@define\'")
            of "@import":
                if arguments.len != 2:
                    error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- " & $arguments.getTokenTypes & " are not valid args for \'@import\'")
            of "@global":
                if arguments.len != 1:
                    error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- " & $arguments.getTokenTypes & " are not valid args for \'@global\'")
            of "@org":
                if arguments.len != 1:
                    error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- " & $arguments.getTokenTypes & " are not valid args for \'@org\'")
            else:
                error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- \'" & assm[tokenPointer].val & "\' is not a recognized directive")
            tokenPointer += arguments.len + 1

    block checkDataTypeArgs:
        var tokenPointer = 0

        while tokenPointer < assm.len:
            if assm[tokenPointer].t != DatatypeToken: 
                inc tokenPointer
                continue

            var arguments = block:
                var a: seq[Token]
                var i = 1
                while assm[tokenPointer+i].t != NewLine:
                    a.add assm[tokenPointer+i]
                    inc i
                a
            
            if arguments.len != 1:
                    error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- " & $arguments.getTokenTypes & " are not valid datatype arguments")
            if arguments[0].t != Literal:
                error("Error", $assm[tokenPointer..tokenPointer+arguments.len] & "- \'" & arguments[0].val & "\' is of type " & $arguments.getTokenTypes & ", (Literal) required")

            
            tokenPointer += arguments.len + 1

    block checkOneGlobal:
        if count(assm.getTokenValues, "@global") != 1:
            error("Error", $count(assm.getTokenValues, "@global") & " \'@global\' directives found")

    #return assm

    block translateLiterals:

        var tokenPointer = 0

        while tokenPointer < assm.len:
            if assm[tokenPointer].t != Literal: 
                inc tokenPointer
                continue

            if assm[tokenPointer].val.match(re"('.*')"):
                let character = assm[tokenPointer].val
                try: 
                    assm[tokenPointer].val = $(codepage[character[1..character.high-1]])
                except:
                    error("Error", " invalid char: " & character)
            
            if assm[tokenPointer].val.match(re"0[xX][0-9a-fA-F]*"):
                let num = assm[tokenPointer].val
                try: 
                    assm[tokenPointer].val = $fromHex[int](num[2..num.high])
                except:
                    error("Error", " invalid hexadecimal integer: " & num)

            if assm[tokenPointer].val.match(re"0[oO][0-8]*"):
                let num = assm[tokenPointer].val
                try: 
                    assm[tokenPointer].val = $fromOct[int](num[2..num.high])
                except:
                    error("Error", " invalid octal integer: " & num)
            
            if assm[tokenPointer].val.match(re"0[bB][0-1]*"):
                let num = assm[tokenPointer].val
                try: 
                    assm[tokenPointer].val = $fromBin[int](num[2..num.high])
                except:
                    error("Error", " invalid binary integer: " & num)


            inc tokenPointer


    return assm