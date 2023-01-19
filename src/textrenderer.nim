import sdl2
import pixie
import std/math

var window = createWindow("aphelion 2", 100, 100, 1280, 700, SDL_WINDOW_SHOWN)

var event = sdl2.defaultEvent
var render = createRenderer(window, -1, Renderer_Software)

var running = true


let fontImage = readImage("3dfx8x14.png")
let fontWidth = readImageDimensions("3dfx8x14.png").width
let fontHeight = readImageDimensions("3dfx8x14.png").height

let displayarray: string = "Hello world!"

proc drawpixel(x,y: int) =
    render.drawPoint((x.cint()*2)-1,(y.cint()*2)-1)
    render.drawPoint((x.cint()*2)-1,y.cint()*2)
    render.drawPoint(x.cint()*2,(y.cint()*2)-1)
    render.drawPoint(x.cint()*2,y.cint()*2)

while running:

    while pollEvent(event):
        if event.kind == QuitEvent:
            running = false
            break
    
    render.present()
    render.setDrawColor(0,0,0,255)
    render.clear()



    var currentRow = 0
    var currentCol = 0

    
    for ch in displayarray:
        case ch
            of '\n':
                currentCol = 0
                currentRow += 1
            of '\0':
                currentCol = 0
                currentRow += 1
            else:
                for relativeX in 0..<8:
                    for relativeY in 0..<14:
                        let pcolor = fontImage[((int(ch) mod 16)*9)+1+relativeX, int(floor(int(ch)/16)*15)+relativeY]
                        render.setDrawColor(pcolor.r, pcolor.b, pcolor.g, pcolor.a)
                        drawpixel((currentCol*8)+relativeX, (currentRow*14)+relativeY)
                currentCol += 1
        if currentCol == 80: # line wrapping
            currentCol = 0
            currentRow += 1




    render.setDrawColor(255,255,255,255)

# (((character mod 16)*9)+1, int(floor(character/16)*15)) is the expression for the starting point of a character in the font image
    
