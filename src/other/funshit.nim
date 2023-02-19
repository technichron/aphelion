
# this is just fun shit made with "displaywindow.nim". not intended for use in the final emulator.


import sdl2
import pixie
import std/math

const horizontalMargin = 1 # pixels
const verticalMargin = 1   # pixels
const columns = 80
const rows = 25
const charHeight = 14 # pixels
const charWidth = 8   # pixels
const charScale = 1
const controlCharsActive = false
const invert = false

var window = createWindow("h", 100, 100, cint((charWidth*charScale*columns)+(horizontalMargin*2)), cint((charHeight*charScale*rows)+(verticalMargin*2)), SDL_WINDOW_SHOWN) # 80x25 character display

var event = sdl2.defaultEvent
var render = createRenderer(window, -1, Renderer_Software)

var cursorRow = 0
var cursorCol = 0

let fontImage = readImage("src/assets/font.png")

proc setcolor(color: ColorRGBX) =
    if invert:
        render.setDrawColor(255-color.r, 255-color.g, 255-color.b, 255-color.a)
    else:
        render.setDrawColor(color.r, color.g, color.b, color.a)

proc setcolor(r,g,b,a: uint8) =
    if invert:
        render.setDrawColor(255-r, 255-g, 255-b, 255-a)
    else:
        render.setDrawColor(r, g, b, a)

proc drawpixel(x,y: int) =
    for xs in 1..charScale:
        for ys in 1..charScale:
            render.drawPoint(((x * charScale) - (xs-1) + horizontalMargin ).cint,((y * charScale) - (ys-1) + verticalMargin ).cint)

proc characterIn(ch: char) =
    if controlCharsActive:
        case ch
            of '\n':
                cursorCol = 0
                cursorRow += 1
            of '\b':
                if cursorCol == 0:
                    cursorCol = columns
                    cursorRow -= 1
                cursorCol -= 1

                for relativeX in 0..<charWidth:
                    for relativeY in 0..<charHeight:
                        let pcolor = fontImage[1+relativeX, 0+relativeY]
                        setcolor(pcolor)
                        drawpixel((cursorCol*charWidth)+relativeX, (cursorRow*charHeight)+relativeY)
            of char(0x03):
                setcolor(0,0,0,255)
                render.clear()
            of char(0x04):
                setcolor(0,0,0,255)
                render.clear()
                cursorCol = 0
                cursorRow = 0
            else:
                for relativeX in 0..<charWidth:
                    for relativeY in 0..<charHeight:
                        let pcolor = fontImage[((ch.int mod 16)*(charWidth+1))+1+relativeX, int((ch.int/16).floor.int*(charHeight+1))+relativeY]
                        setcolor(pcolor)
                        drawpixel((cursorCol*charWidth)+relativeX, (cursorRow*charHeight)+relativeY)
                cursorCol += 1
    else:
        for relativeX in 0..<charWidth:
            for relativeY in 0..<charHeight:
                let pcolor = fontImage[((int(ch) mod 16)*(charWidth+1))+1+relativeX, int((ch.int/16).floor.int*(charHeight+1))+relativeY]
                setcolor(pcolor)
                drawpixel((cursorCol*charWidth)+relativeX, (cursorRow*charHeight)+relativeY)
        cursorCol += 1
    if cursorCol == columns: # line wrapping
        cursorCol = 0
        cursorRow += 1
    if cursorRow == rows: # row reset
        cursorCol = 0
        cursorRow = 0
    if cursorCol < 0: # negative reset
        cursorCol = 0
    if cursorRow < 0: # negative reset
        cursorRow = 0
    #echo "char: \'", ch, "\'"

proc rand(x: float): uint8 = ((pow(x, math.sqrt(x)) mod x) mod 150).uint8


var running = true
var i = 1500000.0
# i = 0.0
i = 4300000.0
while running:

    while pollEvent(event):
        if event.kind == QuitEvent:
            running = false
            break
    
    # render.setDrawColor(0,0,0,255)
    # render.clear()




    # i += 1
    # characterIn(char(rand(i*0.001)))




    i += 1
    if rand(i*0.000003) mod 2 == 0:
        #characterIn(0xDB.char())
        characterIn((rand(i*0.000004)+50).char())
    else:
        characterIn(0x00.char())




    if int(i) mod (columns*rows) == 0:
        render.present()


# (((character mod 16)*9)+1, int(floor(character/16)*15)) is the expression for the starting point of a character in the font image
    
