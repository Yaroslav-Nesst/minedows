
local GUI = require("GUI")
local paths = require("Paths")
local system = require("System")
local filesystem = require("Filesystem")

local module = {}

local workspace, window, localization = table.unpack({...})
local userSettings = system.getUserSettings()

local user = system.getUser()
--------------------------------------------------------------------------------

module.name = localization.disks
module.margin = 1
module.onTouch = function()

	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.networkinfo1))
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.networkinfo2))
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.networkinfo3))
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.networkinfo4))
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.networkinfo5))
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.networkinfo6))
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.networkinfo7))
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.networkinfo8))
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.networkinfo9))
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.networkinfo10))

end

--------------------------------------------------------------------------------

return module

