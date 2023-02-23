import std/strutils, std/re
import def

proc lex*(a: string): seq[Token] =
    let b = a.multiReplace(("\n", " \n "),("#", " # "))
    for t in tokenize(b, seps = (Whitespace + {','} - {'\n'})):
        if t.isSep: continue

        var currentToken = Token(val: t.token, t: Literal) # literal by default

        if currentToken.val.match(re"\n"):
            currentToken.t = NewLine
        elif currentToken.val.match(re"(@)\w+"):
            currentToken.t = Directive
        elif currentToken.val.match(re"^[rR][a-zA-Z][hlHL]?$"):
            currentToken.t = Register
        elif currentToken.val.match(re"\$[rR][a-zA-Z][hlHL]?"):
            currentToken.t = AddressRegister
        elif currentToken.val.match(re"[0-9]+"):
            currentToken.t = Literal
        elif currentToken.val.match(re"\$[0-9]+"):
            currentToken.t = AddressLiteral
        elif currentToken.val.match(re"\$[a-zA-Z_.][a-zA-Z0-9_.]*"):
            currentToken.t = AddressLiteral
        elif currentToken.val.match(re"[a-zA-Z_.][a-zA-Z0-9_.]*:"):
            currentToken.t = Label
        elif currentToken.val.match(re"^(nop|mov|add|adc|sub|sbb|jif|cif|ret|push|pop|and|or|not|cmp|scmp|shl|asl|lsl|asr|lsr|hcf)$"):
            currentToken.t = Instruction
        elif currentToken.val.match(re"^(u8|i8|u16|i16|char|string|file)$"):
            currentToken.t = Datatype
        elif currentToken.val.match(re"^#"):
            currentToken.t = Comment
    
        result.add currentToken