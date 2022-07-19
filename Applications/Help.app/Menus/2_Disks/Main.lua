
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

	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.disksinfo1))
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.disksinfo2))
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.disksinfo3))
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.disksinfo4))
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.disksinfo5))
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.disksinfo6))
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.disksinfo7))
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.disksinfo8))
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.disksinfo9))
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.disksinfo10))

end

--------------------------------------------------------------------------------

return module

