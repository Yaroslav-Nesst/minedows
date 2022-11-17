local GUI = require("GUI")

--------------------------------------------------------------------------------

local workspace = GUI.workspace()
local window3 = workspace:addChild(GUI.titledWindow(50, 22, 60, 20, "Titled window example", true))
-- Attach an single cell layout to it
local layout = window3:addChild(GUI.layout(1, 2, window3.width, window3.height - 1, 1, 1))
-- Add some stuff to layout
layout:addChild(GUI.button(1, 1, 36, 3, 0xB4B4B4, 0xFFFFFF, 0x969696, 0xB4B4B4, "Press me"))
layout:addChild(GUI.button(1, 1, 36, 3, 0xB4B4B4, 0xFFFFFF, 0x969696, 0xB4B4B4, "And me"))
--------------------------------------------------------------------------------

workspace:draw()
workspace:start()