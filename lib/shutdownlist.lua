local image = require("Image")
local GUI = require("GUI")
local system = require("System")

------------------------------------------------------------------------------------------



shutdownf = 0
rebootf = 0
logoutf = 0
chosen  = ("◉")
notchosen  = ("○")
modeset = "None"

blanka = ("○")

local workspace, shutdown, menu = system.addWindow(GUI.titledWindow(50, 22, 60, 15, "Shut Down Minedows", true))

local layout = shutdown:addChild(GUI.layout(1, 2, shutdown.width, shutdown.height - 1, 1, 1))
shutdown:addChild(GUI.text(15, 5, 0x000000, "Are you sure you want to:"))
shutdown:addChild(GUI.text(18, 7, 0x000000, "Shut down the computer?"))
shutdown:addChild(GUI.text(18, 9, 0x000000, "Restart the computer?"))
shutdown:addChild(GUI.text(18, 11, 0x000000, "Close all programs and log out from user?"))
shutdown:addChild(GUI.text(15, 13, 0x000000, "Current mode set:"))
shutdown:addChild(GUI.text(33, 13, 0x000000, "None"))
shutdown:addChild(GUI.image(2, 5, image.load("/Icons/pc.pic")))


local shutdownb = shutdown:addChild(GUI.button(15, 7, 1, 1, 0xFFFFFF, 0x555555, 0xC4C4C4, 0xFFFFFF, blanka))
shutdownb.animated = false
shutdownb.onTouch = function()
    shutdown:addChild(GUI.text(33, 13, 0x000000, "        "))
    shutdown:addChild(GUI.text(33, 13, 0x000000, "Shutdown"))
    modeset = "Shutdown"
    workspace:draw()
end

local rebootb = shutdown:addChild(GUI.button(15, 9, 1, 1, 0xFFFFFF, 0x555555, 0xC4C4C4, 0xFFFFFF, blanka))
rebootb.animated = false
rebootb.onTouch = function()
    shutdown:addChild(GUI.text(33, 13, 0x000000, "        "))
    shutdown:addChild(GUI.text(33, 13, 0x000000, "Reboot"))
    modeset = "Reboot"
    workspace:draw()
end

local logoutb = shutdown:addChild(GUI.button(15, 11, 1, 1, 0xFFFFFF, 0x555555, 0xC4C4C4, 0xFFFFFF, blanka))
logoutb.animated = false
logoutb.onTouch = function()
    shutdown:addChild(GUI.text(33, 13, 0x000000, "        "))
    shutdown:addChild(GUI.text(33, 13, 0x000000, "Logout"))
    workspace:draw()
    modeset = "Logout"
end

local okay = shutdown:addChild(GUI.button(44, 13, 5, 1, 0xFFFFFF, 0x555555, 0xC4C4C4, 0xFFFFFF, "OK"))
okay.animated = false
okay.onTouch = function()
  if modeset == "Shutdown" then
  	computer.shutdown()
  elseif modeset == "Reboot" then
	computer.shutdown(true)
    elseif modeset == "Logout" then
	system.authorize()
  end

end

------------------------------------------------------------------------------------------



workspace:draw()
workspace:start()
