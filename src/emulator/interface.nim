import sdl2
import pixie
import std/math

const horizontalMargin = 5 # pixels
const verticalMargin = 5   # pixels
const columns = 80
const rows = 25
const charHeight = 14 # pixels
const charWidth = 8   # pixels
const charScale = 2
const controlCharsActive = true

var window = createWindow("aphelion 2.0 terminal", 100, 100, cint((charWidth*charScale*columns)+(horizontalMargin*2)), cint((charHeight*charScale*rows)+(verticalMargin*2)), SDL_WINDOW_SHOWN) # 80x25 character display
let icon = loadBMP("src/assets/icon.bmp")
window.setIcon(icon)

var event = sdl2.defaultEvent
var render = createRenderer(window, -1, Renderer_Software)

var cursorRow = 0
var cursorCol = 0

let fontImage = readImage("src/assets/3dfx8x14.png")



proc drawpixel(x,y: int) =
    for xs in 1..charScale:
        for ys in 1..charScale:
            render.drawPoint(cint((x * charScale) - (xs-1) + horizontalMargin ),cint((y * charScale) - (ys-1) + verticalMargin ))

proc characterIn(ch: char) =
    if controlCharsActive:
        case ch
            of '\0': discard
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
            of char(0x0B):      # clear screen
                render.setDrawColor(0,0,0,255)
                render.clear()
            of char(0x0C):      #reset cursor
                cursorCol = 0
                cursorRow = 0
            of char(0x0D):      # clear screen and reset cursor
                render.setDrawColor(0,0,0,255)
                render.clear()
                cursorCol = 0
                cursorRow = 0
            of char(0x0E):      # decrement cursor
                cursorCol -= 1
            of char(0x0F):      # increment cursor
                cursorCol += 1
            else:
                for relativeX in 0..<charWidth:
                    for relativeY in 0..<charHeight:
                        let pcolor = fontImage[((ch.int mod 16)*(charWidth+1))+1+relativeX, int((ch.int/16).floor.int*(charHeight+1))+relativeY]
                        render.setDrawColor(pcolor.r, pcolor.b, pcolor.g, pcolor.a)
                        drawpixel((cursorCol*charWidth)+relativeX, (cursorRow*charHeight)+relativeY)
                cursorCol += 1
    else:
        for relativeX in 0..<charWidth:
            for relativeY in 0..<charHeight:
                let pcolor = fontImage[((int(ch) mod 16)*(charWidth+1))+1+relativeX, int((ch.int/16).floor.int*(charHeight+1))+relativeY]
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
    render.present()

var running = true
while running:

    while pollEvent(event):
        if event.kind == QuitEvent:
            running = false
            break
        if event.kind == KeyDown:
            echo "key press"
            echo event.key.keysym.sym
            break