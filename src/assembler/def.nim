import std/strutils

type
    tokentype* = enum
        Directive, Label, Instruction, Literal, Register, AddressLiteral, AddressRegister, Datatype, NewLine, Comment
type
    Token* = object
        t*: tokenType
        val*: string

proc `$`*(a: seq[Token]): string =
    var max: int
    for t in a:
        if t.val.len > max: max = t.val.len
    for t in a:
        result.add align(t.val.replace("\n", ""), max) & " ╪ " & $t.t & "\n"
    # for t in a:
    #     result.add t.val & " "