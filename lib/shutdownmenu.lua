local GUI = require("GUI")

--------------------------------------------------------------------------------

local workspace = GUI.workspace()
workspace:addChild(GUI.panel(1, 1, workspace.width, workspace.height, 0x2D2D2D))

-- Add a panel that symbolizes the system window, the size of which we will change
local panel = workspace:addChild(GUI.panel(3, 2, 30, 10, 0xE1E1E1))
-- Add a resizer, by default located in the right part of the window. Make the width of the resizer at least 3 to handle the drag/drop events in both directions
local resizer = workspace:addChild(GUI.resizer(panel.localX + panel.width - 2, panel.localY + math.floor(panel.height / 2 - 2), 3, 4, 0xAAAAAA, 0x0))

-- This function will be called during the "drag" event, when the user moves over the resizer
resizer.onResize = function(dragWidth, dragHeight)
	panel.width = panel.width + dragWidth
	resizer.localX = resizer.localX + dragWidth

	workspace:draw()
end

-- This function will be called on "drop" event
resizer.onResizeFinished = function()
	GUI.alert("Resize finished!")
end

--------------------------------------------------------------------------------

workspace:draw()
workspace:start()