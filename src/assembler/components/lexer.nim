import std/strutils, std/re
import def

# fuck regex

proc lex*(a: string): seq[Token] =
    let b = a.multiReplace(("\n", " \n "),("#", " # "))
    for t in tokenize(b, seps = (Whitespace + {','} - {'\n'})):
        if t.isSep: continue

        var currentToken = Token(val: t.token, t: Literal) # literal until proven otherwise

        if currentToken.val.match(re"\n"): # yes i know its a bunch of elifs and its bad dont @ me
            currentToken.t = NewLine
        elif currentToken.val.match(re"(@)\w+"):
            currentToken.t = Directive
        elif currentToken.val.match(re"^[rR][a-fA-F]$"):
            currentToken.t = Register
        elif currentToken.val.match(re"^[rR][gijkpsrxyGIJKPSRXY][hlHL]$"):
            currentToken.t = Register
        elif currentToken.val.match(re"^[rR][gijkpsrxyGIJKPSRXY]$"):
            currentToken.t = DoubleRegister
        elif currentToken.val.match(re"\$[rR][gijkpsrxyGIJKPSRXY]"):
            currentToken.t = AddressDoubleRegister
        elif currentToken.val.match(re"[0-9]+"):
            currentToken.t = Literal
        elif currentToken.val.match(re"\$[0-9]+"):
            currentToken.t = AddressLiteral
        elif currentToken.val.match(re"\$[a-zA-Z_.][a-zA-Z0-9_.]*"):
            currentToken.t = AddressLiteral
        elif currentToken.val.match(re"[a-zA-Z_.][a-zA-Z0-9_.]*:"):
            currentToken.t = Label
        elif currentToken.val.match(re"^(nop|mov|add|adc|sub|sbb|jif|cif|ret|push|pop|and|or|not|cmp|scmp|shl|asl|lsl|asr|lsr|hcf)$"):
            currentToken.t = InstructionToken
        elif currentToken.val.match(re"^(u8|i8|u16|i16|char|string|file)$"):
            currentToken.t = Datatype
        elif currentToken.val.match(re"^#"):
            currentToken.t = Comment
    
        try:    # weeds out duplicate newlines
            if currentToken.t == NewLine and result[result.high].t == NewLine:
                continue
        except: discard

        result.add currentToken