import std/strutils, std/tables, std/terminal

const codepage* = {"\\0":0x00,"☺":0x01,"☻":0x02,"♥":0x03,"♦":0x04,"♣":0x05,"♠":0x06,"•":0x07,"\\b":0x08,"○":0x09,"\\n":0x0A,"\\c":0x0B,"\\r":0x0C,"♪":0x0D,"\\i":0x0E,"\\d":0x0F,
                  "►":0x10,"◄":0x11,"↕":0x12,"‼":0x13,"¶":0x14,"§":0x15,"▬":0x16,"↨":0x17,"↑":0x18,"↓":0x19,"→":0x1A,"←":0x1B,"∟":0x1C,"↔":0x1D,"▲":0x1E,"▼":0x1F,
                  " ":0x20,"!":0x21,"\\\"":0x22,"#":0x23,"$":0x24,"%":0x25,"&":0x26,"\\\'":0x27,"(":0x28,")":0x29,"*":0x2A,"+":0x2B,",":0x2C,"-":0x2D,".":0x2E,"/":0x2F,
                  "0":0x30,"1":0x31,"2":0x32,"3":0x33,"4":0x34,"5":0x35,"6":0x36,"7":0x37,"8":0x38,"9":0x39,":":0x3A,";":0x3B,"<":0x3C,"=":0x3D,">":0x3E,"?":0x3F,
                  "@":0x40,"A":0x41,"B":0x42,"C":0x43,"D":0x44,"E":0x45,"F":0x46,"G":0x47,"H":0x48,"I":0x49,"J":0x4A,"K":0x4B,"L":0x4C,"M":0x4D,"N":0x4E,"O":0x4F,
                  "P":0x50,"Q":0x51,"R":0x52,"S":0x53,"T":0x54,"U":0x55,"V":0x56,"W":0x57,"X":0x58,"Y":0x59,"Z":0x5A,"[":0x5B,"\\\\":0x5C,"]":0x5D,"^":0x5E,"_":0x5F,
                  "`":0x60,"a":0x61,"b":0x62,"c":0x63,"d":0x64,"e":0x65,"f":0x66,"g":0x67,"h":0x68,"i":0x69,"j":0x6A,"k":0x6B,"l":0x6C,"m":0x6D,"n":0x6E,"o":0x6F,
                  "p":0x70,"q":0x71,"r":0x72,"s":0x73,"t":0x74,"u":0x75,"v":0x76,"w":0x77,"x":0x78,"y":0x79,"z":0x7A,"{":0x7B,"|":0x7C,"}":0x7D,"~":0x7E,"⌂":0x7F,
                  "Ç":0x80,"ü":0x81,"é":0x82,"â":0x83,"ä":0x84,"à":0x85,"å":0x86,"ç":0x87,"ê":0x88,"ë":0x89,"è":0x8A,"ï":0x8B,"î":0x8C,"ì":0x8D,"Ä":0x8E,"Å":0x8F,
                  "É":0x90,"§":0x91,"Æ":0x92,"ô":0x93,"ö":0x94,"ò":0x95,"û":0x96,"ù":0x97,"ÿ":0x98,"Ö":0x99,"Ü":0x9A,"¢":0x9B,"£":0x9C,"¥":0x9D,"₧":0x9E,"ƒ":0x9F,
                  "á":0xA0,"í":0xA1,"ó":0xA2,"ú":0xA3,"ñ":0xA4,"Ñ":0xA5,"ª":0xA6,"º":0xA7,"¿":0xA8,"⌐":0xA9,"¬":0xAA,"½":0xAB,"¼":0xAC,"¡":0xAD,"«":0xAE,"»":0xAF,
                  "░":0xB0,"▒":0xB1,"▓":0xB2,"│":0xB3,"┤":0xB4,"╡":0xB5,"╢":0xB6,"╖":0xB7,"╕":0xB8,"╣":0xB9,"║":0xBA,"╗":0xBB,"╝":0xBC,"╜":0xBD,"╛":0xBE,"┐":0xBF,
                  "└":0xC0,"┴":0xC1,"┬":0xC2,"├":0xC3,"─":0xC4,"┼":0xC5,"╞":0xC6,"╟":0xC7,"╚":0xC8,"╔":0xC9,"╩":0xCA,"╦":0xCB,"╠":0xCC,"═":0xCD,"╬":0xCE,"╧":0xCF,
                  "╨":0xD0,"╤":0xD1,"╥":0xD2,"╙":0xD3,"╘":0xD4,"╒":0xD5,"╓":0xD6,"╫":0xD7,"╪":0xD8,"┘":0xD9,"┌":0xDA,"█":0xDB,"▄":0xDC,"▌":0xDD,"▐":0xDE,"▀":0xDF,
                  "α":0xE0,"ß":0xE1,"Γ":0xE2,"π":0xE3,"Σ":0xE4,"σ":0xE5,"µ":0xE6,"τ":0xE7,"Φ":0xE8,"Θ":0xE9,"Ω":0xEA,"δ":0xEB,"∞":0xEC,"φ":0xED,"ε":0xEE,"∩":0xEF,
                  "≡":0xF0,"±":0xF1,"≥":0xF2,"≤":0xF3,"⌠":0xF4,"⌡":0xF5,"÷":0xF6,"≈":0xF7,"°":0xF8,"∙":0xF9,"·":0xFA,"√":0xFB,"ⁿ":0xFC,"²":0xFD,"■":0xFE,"\\a":0xFF}.toTable()

type
    TokenType* = enum
        Directive, Label, InstructionToken, Literal, Register, DoubleRegister, AddressDoubleRegister, AddressLiteral, DatatypeToken, NewLine, Comment

    Token* = object
        t*: TokenType
        val*: string
    
    InstructionFormat* = enum
        NA, RE, RR, BY, RB, DO, RD, BD, DD

    Instruction* = object
        label*: string
        opcode*: uint8
        arg1*: Token
        arg2*: Token
        format*: InstructionFormat
    
    Datatype* = enum
        str, u8, u16, i8, i16, file

    Data* = object
        label*: string
        datatype*: Datatype

proc `$`*(a: seq[Token]): string =
    for t in a:
        result.add t.val
        if t.t != NewLine: result.add " "

proc `$`*(a: seq[TokenType]): string =
    result.add "("
    for t in 0..a.high:
        result.add $a[t]
        if t != a.high: result.add ", "
    result.add ")"

proc pretty*(a: seq[Token]): string =
    var max: int
    for t in a:
        if t.val.len > max: max = t.val.len
    for t in a:
        result.add align(t.val.replace("\n", ""), max) & " │ " & $t.t & "\n"

proc getTokenTypes*(a: seq[Token]): seq[TokenType] =
    for entry in a:
        result.add entry.t

proc getTokenValues*(a: seq[Token]): seq[string] =
    for entry in a:
        result.add entry.val

proc error*(errortype, message: string) =
    styledEcho styleDim, fgRed, errortype, ":", fgDefault, styleDim, " ", message
    quit(0)


const movArgTypes* = [@[Register, Literal],
                      @[Register, Register], 
                      @[DoubleRegister, DoubleRegister],
                      @[Literal, Register],
                      @[Literal, Literal],
                      @[Literal, DoubleRegister],
                      @[AddressLiteral, Register],
                      @[AddressLiteral, Literal],
                      @[AddressDoubleRegister, Literal],
                      @[AddressDoubleRegister, Register],
                      @[Register, AddressDoubleRegister]]

const funcArgTypes* = [@[Register, Register],
                       @[Register, Literal],
                       @[DoubleRegister, DoubleRegister],
                       @[DoubleRegister, Literal]]

const jmpcallArgTypes* = [@[Literal, Literal],
                          @[Literal, DoubleRegister]]

const pushArgTypes* = [@[Register],
                       @[DoubleRegister],
                       @[Literal]]

const regdregArgTypes* = [@[Register],
                          @[DoubleRegister]]

const shiftArgTypes* = [@[Register, Literal],
                        @[DoubleRegister, Literal]]
