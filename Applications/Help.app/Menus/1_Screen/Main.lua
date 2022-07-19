
local GUI = require("GUI")
local paths = require("Paths")
local system = require("System")
local filesystem = require("Filesystem")

local module = {}

local workspace, window, localization = table.unpack({...})
local userSettings = system.getUserSettings()

local user = system.getUser()
--------------------------------------------------------------------------------

module.name = localization.screen
module.margin = 1
module.onTouch = function()

	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.screeninfo1))
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.screeninfo2))
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.screeninfo3))
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.screeninfo4))
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.screeninfo5))
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.screeninfo6))
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.screeninfo7))
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.screeninfo8))
      window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.Tier1))
      window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.Tier2))
      window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.Tier3))

end

--------------------------------------------------------------------------------

return module

