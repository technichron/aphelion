import std/sequtils
import def

proc getTokenTypes(a: seq[Token]): seq[TokenType] =
    for entry in a:
        result.add entry.t

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
    
    block checkArguments: # checks instruction and directive arguments
        
        var tokenPointer = 0

        while tokenPointer < assm.len:
            if assm[tokenPointer].t != Instruction: 
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
                        error("Error", $arguments.getTokenTypes & " are not valid args for \'nop\'")
                of "mov":
                    if arguments.getTokenTypes notin movArgTypes:
                        error("Error", $arguments.getTokenTypes & " are not valid args for \'mov\'")
                of "add":
                    if arguments.getTokenTypes notin funcArgTypes:
                        error("Error", $arguments.getTokenTypes & " are not valid args for \'add\'")
                of "adc":
                    if arguments.getTokenTypes notin funcArgTypes:
                        error("Error", $arguments.getTokenTypes & " are not valid args for \'adc\'")
                of "sub":
                    if arguments.getTokenTypes notin funcArgTypes:
                        error("Error", $arguments.getTokenTypes & " are not valid args for \'sub\'")
                of "sbb":
                    if arguments.getTokenTypes notin funcArgTypes:
                        error("Error", $arguments.getTokenTypes & " are not valid args for \'sbb\'")
                of "jif":
                    if arguments.getTokenTypes notin jmpcallArgTypes:
                        error("Error", $arguments.getTokenTypes & " are not valid args for \'jif\'")
                of "cif":
                    if arguments.getTokenTypes notin jmpcallArgTypes:
                        error("Error", $arguments.getTokenTypes & " are not valid args for \'cif\'")
                of "ret":
                    if arguments.len != 0:
                        error("Error", $arguments.getTokenTypes & " are not valid args for \'ret\'")
                of "push":
                    if arguments.getTokenTypes notin pushArgTypes:
                        error("Error", $arguments.getTokenTypes & " are not valid args for \'push\'")
                of "pop":
                    if arguments.getTokenTypes notin regdregArgTypes:
                        error("Error", $arguments.getTokenTypes & " are not valid args for \'pop\'")
                of "and":
                    if arguments.getTokenTypes notin funcArgTypes:
                        error("Error", $arguments.getTokenTypes & " are not valid args for \'and\'")
                of "or":
                    if arguments.getTokenTypes notin funcArgTypes:
                        error("Error", $arguments.getTokenTypes & " are not valid args for \'or\'")
                of "not":
                    if arguments.getTokenTypes notin regdregArgTypes:
                        error("Error", $arguments.getTokenTypes & " are not valid args for \'not\'")
                of "cmp":
                    if arguments.getTokenTypes notin funcArgTypes:
                        error("Error", $arguments.getTokenTypes & " are not valid args for \'cmp\'")
                of "scmp":
                    if arguments.getTokenTypes notin funcArgTypes:
                        error("Error", $arguments.getTokenTypes & " are not valid args for \'scmp\'")
                of "shl":
                    if arguments.getTokenTypes notin shiftArgTypes:
                        error("Error", $arguments.getTokenTypes & " are not valid args for \'shl\'")
                of "asr":
                    if arguments.getTokenTypes notin shiftArgTypes:
                        error("Error", $arguments.getTokenTypes & " are not valid args for \'asr\'")
                of "lsr":
                    if arguments.getTokenTypes notin shiftArgTypes:
                        error("Error", $arguments.getTokenTypes & " are not valid args for \'lsr\'")
                of "hcf":
                    if arguments.len != 0:
                        error("Error", $arguments.getTokenTypes & " are not valid args for \'hcf\'")
                else:
                    # echo assm[tokenPointer].val
                    # echo getTokenTypes(arguments)
                    error("Error", "unrecognized instruction: " & assm[tokenPointer].val)
                    discard
            tokenPointer += arguments.len + 1

    return assm