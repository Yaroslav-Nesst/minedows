
local GUI = require("GUI")
local paths = require("Paths")
local system = require("System")
local filesystem = require("Filesystem")

local module = {}

local workspace, window, localization = table.unpack({...})
local userSettings = system.getUserSettings()

local user = system.getUser()
--------------------------------------------------------------------------------

module.name = localization.home
module.margin = 1
module.onTouch = function()

	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.hello))
      window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, user))
      window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.homeinfo1))
      window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.homeinfo2))

end

--------------------------------------------------------------------------------

return module

