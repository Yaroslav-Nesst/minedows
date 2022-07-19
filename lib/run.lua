local image = require("Image")
local GUI = require("GUI")
local system = require("System")

local workspace, run, menu = system.addWindow(GUI.titledWindow(50, 22, 60, 12, "Run", true))
run:addChild(GUI.text(15, 3, 0x000000, "Type name of a program, and"))
run:addChild(GUI.text(15, 4, 0x000000, "Minedows will open it for you"))
run:addChild(GUI.text(4, 9, 0x000000, "Open:"))
run:addChild(GUI.image(4, 3, image.load("/Icons/run.pic")))

local rued = run:addChild(GUI.input(15, 9, 30, 1, 0xc4c4c4, 0x555555, 0x999999, 0xC4C4C4, 0x2D2D2D))
rued.onInputFinished = function()
  patx = rued.text
end

local okay = run:addChild(GUI.button(40, 11, 5, 1, 0xFFFFFF, 0x555555, 0xC4C4C4, 0xFFFFFF, "Run"))
okay.animated = false
okay.onTouch = function()
  system.execute(patx)

if rued == nil and patx == nil then
  GUI.alert("File is nil or not found!")
end

end

