local GUI = require("GUI")

--------------------------------------------------------------------------------

local workspace = GUI.workspace()
local window3 = workspace:addChild(GUI.titledWindow(50, 22, 60, 20, "Titled window example", true))
-- Attach an single cell layout to it
local layout = window3:addChild(GUI.layout(1, 2, window3.width, window3.height - 1, 1, 1))
-- Add some stuff to layout
layout:addChild(GUI.text(15, 5, 0x000000, "Are you sure you want to:"))
layout:addChild(GUI.text(18, 7, 0x000000, "Shut down the computer?"))
layout:addChild(GUI.text(18, 9, 0x000000, "Restart the computer?"))
layout:addChild(GUI.text(18, 11, 0x000000, "Close all programs and log out from user?"))
layout:addChild(GUI.text(15, 13, 0x000000, "Current mode set:"))
layout:addChild(GUI.text(33, 13, 0x000000, "None"))
--------------------------------------------------------------------------------

workspace:draw()
workspace:start()