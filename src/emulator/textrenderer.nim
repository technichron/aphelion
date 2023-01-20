import sdl2
import pixie
import std/math

let horizontalMargin = 0
let verticalMargin = 0

var window = createWindow("aphelion 2", 100, 100, cint(1280+(horizontalMargin*2)), cint(700+(verticalMargin*2)), SDL_WINDOW_SHOWN)

var event = sdl2.defaultEvent
var render = createRenderer(window, -1, Renderer_Software)

var running = true


let fontImage = readImage("src/assets/3dfx8x14.png")

var displayarray: string = "big"

proc drawpixel(x,y: int) =
    render.drawPoint(cint((x*2)-1+horizontalMargin),cint((y*2)-1+verticalMargin))
    render.drawPoint(cint((x*2)+horizontalMargin),cint((y*2)-1+verticalMargin))
    render.drawPoint(cint((x*2)+horizontalMargin),cint((y*2)+verticalMargin))
    render.drawPoint(cint((x*2)-1+horizontalMargin),cint((y*2)+verticalMargin))

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
            of '\b':
                if currentCol == 0:
                    currentCol = 80
                    currentRow -= 1
                currentCol -= 1

                for relativeX in 0..<8:
                    for relativeY in 0..<14:
                        let pcolor = fontImage[1+relativeX, 0+relativeY]
                        render.setDrawColor(pcolor.r, pcolor.b, pcolor.g, pcolor.a)
                        drawpixel((currentCol*8)+relativeX, (currentRow*14)+relativeY)
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
        if currentRow == 25: # row reset
            currentCol = 0
            currentRow = 0
        if currentCol < 0: # negative reset
            currentCol = 0
        if currentRow < 0: # negative reset
            currentRow = 0




    render.setDrawColor(255,255,255,255)


# (((character mod 16)*9)+1, int(floor(character/16)*15)) is the expression for the starting point of a character in the font image
    
