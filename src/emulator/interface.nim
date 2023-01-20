import sdl2
import pixie
import std/math

const horizontalMargin = 5 # pixels
const verticalMargin = 5   # pixels
const columns = 80
const rows = 25
const charHeight = 14 # pixels
const charWidth = 8   # pixels
const charScale = 1

var window = createWindow("aphelion 2.1 terminal", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, cint((charWidth*charScale*columns)+(horizontalMargin*2)), cint((charHeight*charScale*rows)+(verticalMargin*2)), SDL_WINDOW_SHOWN) # 80x25 character display

var event = sdl2.defaultEvent
var render = createRenderer(window, -1, Renderer_Software)

var cursorRow = 0
var cursorCol = 0

let fontImage = readImage("src/assets/3dfx8x14.png")

proc drawpixel(x,y: int) =
    render.drawPoint(cint((x*2)-1+horizontalMargin),cint((y*2)-1+verticalMargin))
    render.drawPoint(cint((x*2)+horizontalMargin),cint((y*2)-1+verticalMargin))
    render.drawPoint(cint((x*2)+horizontalMargin),cint((y*2)+verticalMargin))
    render.drawPoint(cint((x*2)-1+horizontalMargin),cint((y*2)+verticalMargin))

proc characterIn(ch: char) =
    case ch
        of '\n':
            cursorCol = 0
            cursorRow += 1
        of '\b':
            if cursorCol == 0:
                cursorCol = 80
                cursorRow -= 1
            cursorCol -= 1

            for relativeX in 0..<8:
                for relativeY in 0..<14:
                    let pcolor = fontImage[1+relativeX, 0+relativeY]
                    render.setDrawColor(pcolor.r, pcolor.b, pcolor.g, pcolor.a)
                    drawpixel((cursorCol*8)+relativeX, (cursorRow*14)+relativeY)
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
                    let pcolor = fontImage[((int(ch) mod 16)*(9))+1+relativeX, int(floor(int(ch)/16)*(15))+relativeY]
                    render.setDrawColor(pcolor.r, pcolor.b, pcolor.g, pcolor.a)
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

proc rand(x: float): uint8 = uint8( (pow(x, math.sqrt(x)) mod x) mod 255 )


var running = true
var i = 300000.0
while running:

    while pollEvent(event):
        if event.kind == QuitEvent:
            running = false
            break
    
    # render.setDrawColor(0,0,0,255)
    # render.clear()


    i += 1

    characterIn(char(rand(i*0.00002)))

    # if rand(i*0.00002) mod 2 == 0:
    #     characterIn(0xDB.char())
    # else:
    #     characterIn(0x00.char())
    # if i mod (columns*rows) == 0:
    #     render.present()


# (((character mod 16)*9)+1, int(floor(character/16)*15)) is the expression for the starting point of a character in the font image
    
