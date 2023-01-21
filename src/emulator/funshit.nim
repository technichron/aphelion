
# this is just fun shit made with "interface.nim". not intended for use in the final emulator.


import sdl2
import pixie
import std/math

let horizontalMargin = 5 # pixels
let verticalMargin = 5   # pixels
let columns = 80
let rows = 25
let charHeight = 14 # pixels
let charWidth = 8   # pixels
let charScale = 2
let controlCharsActive = false

var window = createWindow("aphelion 2.1 terminal", 100, 100, cint((charWidth*charScale*columns)+(horizontalMargin*2)), cint((charHeight*charScale*rows)+(verticalMargin*2)), SDL_WINDOW_SHOWN) # 80x25 character display

var event = sdl2.defaultEvent
var render = createRenderer(window, -1, Renderer_Software)

var cursorRow = 0
var cursorCol = 0

let fontImage = readImage("src/assets/3dfx8x14.png")

proc drawpixel(x,y: int) =
    # render.drawPoint(cint((x)+horizontalMargin),cint((y)+verticalMargin))

    for xs in 1..charScale:
        for ys in 1..charScale:
            render.drawPoint(cint((x * charScale) - (xs-1) + horizontalMargin ),cint((y * charScale) - (ys-1) + verticalMargin ))

    # render.drawPoint(cint((x*)-1+horizontalMargin),cint((y*2)-1+verticalMargin))
    # render.drawPoint(cint((x*2)+horizontalMargin),cint((y*2)-1+verticalMargin))
    # render.drawPoint(cint((x*2)+horizontalMargin),cint((y*2)+verticalMargin))
    # render.drawPoint(cint((x*2)-1+horizontalMargin),cint((y*2)+verticalMargin))
    #echo x, ", ", y

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
                        render.setDrawColor(pcolor.r, pcolor.b, pcolor.g, pcolor.a)
                        drawpixel((cursorCol*charWidth)+relativeX, (cursorRow*charHeight)+relativeY)
            of char(0x03):
                render.setDrawColor(0,0,0,255)
                render.clear()
            of char(0x04):
                render.setDrawColor(0,0,0,255)
                render.clear()
                cursorCol = 0
                cursorRow = 0
            else:
                for relativeX in 0..<charWidth:
                    for relativeY in 0..<charHeight:
                        let pcolor = fontImage[((int(ch) mod 16)*(charWidth+1))+1+relativeX, int(floor(int(ch)/16).int()*(charHeight+1))+relativeY]
                        render.setDrawColor(pcolor.r, pcolor.b, pcolor.g, pcolor.a)
                        drawpixel((cursorCol*charWidth)+relativeX, (cursorRow*charHeight)+relativeY)
                cursorCol += 1
    else:
        for relativeX in 0..<charWidth:
            for relativeY in 0..<charHeight:
                let pcolor = fontImage[((int(ch) mod 16)*(charWidth+1))+1+relativeX, int(floor(int(ch)/16).int()*(charHeight+1))+relativeY]
                render.setDrawColor(pcolor.r, pcolor.g, pcolor.b, pcolor.a)
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

proc rand(x: float): uint8 = uint8( (pow(x, math.sqrt(x)) mod x) mod 256 )


var running = true
var i = 1500000.0
#i = 0.0
while running:

    while pollEvent(event):
        if event.kind == QuitEvent:
            running = false
            break
    
    # render.setDrawColor(0,0,0,255)
    # render.clear()


    i += 1
    characterIn(char(rand(i*0.001)))


    # i += 1
    # if rand(i*0.000003) mod 2 == 0:
    #     characterIn(0xDB.char())
    #     #characterIn(rand(i*0.00031).char())
    # else:
    #     characterIn(0x00.char())

    if int(i) mod (columns*rows) == 0:
        render.present()


# (((character mod 16)*9)+1, int(floor(character/16)*15)) is the expression for the starting point of a character in the font image
    
