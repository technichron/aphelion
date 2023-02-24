import std/sequtils
import def

proc parse*(a: seq[Token]): seq[Token] = # remove comments and make sure everything is grammatically correct
    
    var assm = a

    block cleanComments:
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
    
    block checkArguments:
        
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
                else:
                    echo assm[tokenPointer].val
                    echo arguments
                    tokenPointer += arguments.len + 2

    return assm