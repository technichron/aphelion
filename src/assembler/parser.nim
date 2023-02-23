import std/sequtils
import def

proc parse*(a: seq[Token]): seq[Token] = # remove comments and make sure everything is grammatically correct
    
    var assm = a

    while true: # clean comments

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

    return assm