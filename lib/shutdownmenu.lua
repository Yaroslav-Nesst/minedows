--shitdown menu
local GUI = require("GUI")
local System = require("System")
local computer = require("computer")
local image = require("Image")

local workspace = GUI.workspace()

workspace:addChild(GUI.panel(50, 19, 60, 11, 0x262626))
local shutdownb = workspace:addChild(GUI.button(53, 21, 13, 8, 0xC4C4C4, 0x555555, 0x880000, 0xC4C4C4, "Shutdown"))
workspace:addChild(GUI.image(53, 22, image.load("/Icons/shutdown.pic")))
shutdownb.onTouch = function()
	computer.shutdown()
end

local actionButtonsRegular = workspace:addChild(GUI.actionButtons(50, 20, false))

actionButtonsRegular.close.onTouch = function()
	-- Do something when "close" button was touched
	workspace:stop()
end

workspace:draw()
workspace:start()