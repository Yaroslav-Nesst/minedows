-- Checking for required components
local function getComponentAddress(name)
	return component.list(name)() or error("Required " .. name .. " component is missing")
end

local function getComponentProxy(name)
	return component.proxy(getComponentAddress(name))
end

local EEPROMProxy, internetProxy, GPUProxy = 
	getComponentProxy("eeprom"),
	getComponentProxy("internet"),
	getComponentProxy("gpu")

-- Binding GPU to screen in case it's not done yet
GPUProxy.bind(getComponentAddress("screen"))
local screenWidth, screenHeight = GPUProxy.getResolution()

local repositoryURL = "https://raw.githubusercontent.com/Yaroslav-Nesst/minedows/master/"
local installerURL = "Installer/"
local EFIURL = "EFI/Minified.lua"

local installerPath = "/Temp/"
local installerPicturesPath = installerPath .. "Installer/Pictures/"
local OSPath = "/"

local temporaryFilesystemProxy, selectedFilesystemProxy

--------------------------------------------------------------------------------

-- Working with components directly before system libraries are downloaded & initialized
local function centrize(width)
	return math.floor(screenWidth / 2 - width / 2)
end

local function centrizedText(y, color, text)
	GPUProxy.fill(1, y, screenWidth, 1, " ")
	GPUProxy.setForeground(color)
	GPUProxy.set(centrize(#text), y, text)
end
-- GPUProxy.setForeground(0xFFFFFF)
-- GPUProxy.set(1, 1, "Booting Minedows")
local statusline = 0
local function status1(text, needWait)
	if statusline > screenHeight then
		statusline = 1
		GPUProxy.setBackground(0x000000)
		GPUProxy.fill(1, 1, screenWidth/2, screenHeight, " ")
	end
	statusline = statusline + 1
	GPUProxy.setForeground(0xFFFFFF)
	GPUProxy.set(1, statusline, text)
	if needWait then
		repeat
			needWait = computer.pullSignal()
		until needWait == "key_down" or needWait == "touch"
	end
end

local function title()
	local y = math.floor(screenHeight / 2 - 1)
	centrizedText(y, 0xFF6347, "Minedows")

	return y + 2
end

local function status(text, needWait)
	centrizedText(title(), 0xFF6347, text)

	if needWait then
		repeat
			needWait = computer.pullSignal()
		until needWait == "key_down" or needWait == "touch"
	end
end

local function progress(value)
	local width = 26
	local x, y, part = centrize(width), title(), math.ceil(width * value)
	
	GPUProxy.setForeground(0x878787)
	GPUProxy.set(x, y, string.rep("─", part))
	GPUProxy.setForeground(0xC3C3C3)
	GPUProxy.set(x + part, y, string.rep("─", width - part))
end

local function filesystemPath(path)
	return path:match("^(.+%/).") or ""
end

local function filesystemName(path)
	return path:match("%/?([^%/]+%/?)$")
end

local function filesystemHideExtension(path)
	return path:match("(.+)%..+") or path
end

local function rawRequest(url, chunkHandler)
	local internetHandle, reason = internetProxy.request(repositoryURL .. url:gsub("([^%w%-%_%.%~])", function(char)
		return string.format("%%%02X", string.byte(char))
	end))

	if internetHandle then
		local chunk, reason
		while true do
			chunk, reason = internetHandle.read(math.huge)	
			
			if chunk then
				chunkHandler(chunk)
			else
				if reason then
					error("Internet request failed: " .. tostring(reason))
				end

				break
			end
		end

		internetHandle.close()
	else
		error("Connection failed: " .. url)
	end
end

local function request(url)
	local data = ""
	
	rawRequest(url, function(chunk)
		data = data .. chunk
	end)

	return data
end

local function download(url, path)
	selectedFilesystemProxy.makeDirectory(filesystemPath(path))

	local fileHandle, reason = selectedFilesystemProxy.open(path, "wb")
	if fileHandle then	
		rawRequest(url, function(chunk)
			selectedFilesystemProxy.write(fileHandle, chunk)
		end)

		selectedFilesystemProxy.close(fileHandle)
	else
		error("File opening failed: " .. tostring(reason))
	end
end

local function deserialize(text)
	local result, reason = load("return " .. text, "=string")
	if result then
		return result()
	else
		error(reason)
	end
end

-- Clearing screen
GPUProxy.setBackground(0x000000)
GPUProxy.fill(1, 1, screenWidth, screenHeight, " ")

status1("Booting kernel", false)

status1("Searching for appropriate temporary fs", false)
-- Searching for appropriate temporary filesystem for storing libraries, images, etc
for address in component.list("filesystem") do
	local proxy = component.proxy(address)
	status1("fs "..proxy.spaceTotal(), false)
	if proxy.spaceTotal() >= 2 * 1024 * 1024 then
		temporaryFilesystemProxy, selectedFilesystemProxy = proxy, proxy
		break
	end
end


-- If there's no suitable HDDs found - then meow
if not temporaryFilesystemProxy then
	status1("No drives found!", true)
	return
end

status1("Getting file list", false)
-- First, we need a big ass file list with localizations, applications, wallpapers
progress(0)
local files = deserialize(request(installerURL .. "Files.cfg"))
local doDownload = true

-- After that we could download required libraries for installer from it

if doDownload then
	for i = 1, #files.installerFiles do
		status1("Downloading" .. files.installerFiles[i], false)
		progress(i / #files.installerFiles)
 		download(files.installerFiles[i], installerPath .. files.installerFiles[i])
		status1("Done" .. files.installerFiles[i], false)
	end
else
	status1("doDownload is false, skipping...", false)
 
end

status1("Initializing package system for system libraries", false)
-- Initializing simple package system for loading system libraries
package = {loading = {}, loaded = {}}

function require(module)
	if package.loaded[module] then
		return package.loaded[module]
	elseif package.loading[module] then
		error("already loading " .. module .. ": " .. debug.traceback())
	else
		package.loading[module] = true

		local handle, reason = temporaryFilesystemProxy.open(installerPath .. "lib/" .. module .. ".lua", "rb")
		if handle then
			local data, chunk = ""
			repeat
				chunk = temporaryFilesystemProxy.read(handle, math.huge)
				data = data .. (chunk or "")
			until not chunk

			temporaryFilesystemProxy.close(handle)
			
			local result, reason = load(data, "=" .. module)
			if result then
				package.loaded[module] = result() or true
			else
				error(reason)
			end
		else
			error("File opening failed: " .. tostring(reason))
		end

		package.loading[module] = nil

		return package.loaded[module]
	end
end

-- Initializing system libraries
status1("Initializing system libraries", false)
status1("Initializing filesystem.lua", false)
local filesystem = require("Filesystem")
filesystem.setProxy(temporaryFilesystemProxy)

status1("Initializing bit32.lua", false)
bit32 = bit32 or require("Bit32")
status1("Initializing image.lua", false)
local image = require("Image")
status1("Initializing text.lua", false)
local text = require("Text")
status1("Initializing number.lua", false)
local number = require("Number")

status1("Initializing screen.lua", false)
local screen = require("Screen")
status1("Initializing GPUProxy", false)
screen.setGPUProxy(GPUProxy)

status1("Initializing filesystem.lua", false)
local GUI = require("GUI")
status1("Initializing system.lua", false)
local system = require("System")
status1("Initializing paths.lua", false)
local paths = require("Paths")
status1("All done, starting graphical environment...", false)





--------------------------------------------------------------------------------





-- Creating main UI workspace
local workspace = GUI.workspace()
workspace:addChild(GUI.panel(1, 1, workspace.width, workspace.height, 0x180052))
workspace:addChild(GUI.text(3, 2, 0xFFFFFF, "ver-0.14"))


-- Main installer window
-- local window = workspace:addChild(GUI.window(1, 1, 80, 24))
-- mainw = window:addChild(GUI.panel(1, 1, window.width, window.height, 0x180052))
local window = workspace:addChild(GUI.titledWindow(1, 1, 80, 24, "Minedows Setup", true))
local mainw = window:addChild(GUI.container(1, 1, window.width, window.height))
--local mainw = window:addChild(GUI.innerwindow(1, 1, window.width, window.height, 0x180052))
window.localX, window.localY = math.ceil(workspace.width / 2 - window.width / 2), math.ceil(workspace.height / 2 - window.height / 2)

window.actionButtons.close.onTouch = function()
	computer.shutdown(true)
end

local function runWindow()
	local run = workspace:addChild(GUI.titledWindow(1, 1, 60, 12, "Run", true))
	run:addChild(GUI.text(15, 3, 0x000000, "Type name of a program, and"))
	run:addChild(GUI.text(15, 4, 0x000000, "Minedows will open it for you"))
	run:addChild(GUI.text(4, 9, 0x000000, "Open:"))
	run:addChild(GUI.image(4, 3, image.load("/Temp/Installer/Pictures/Pc.pic")))

	run.actionButtons.close.onTouch = function()
		run:remove()
		workspace:draw()
	end

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
end

local runButton = workspace:addChild(GUI.button(4, 4, 6, 1, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, "Run"))
runButton.onTouch = function()
	runWindow()
end

-- Main vertical layout
local layout = window:addChild(GUI.layout(1, 1, window.width, window.height - 2, 1, 1))

-- local stageButtonsLayout = window:addChild(GUI.layout(1, window.height - 2, window.width, 3, 1, 1))
-- stageButtonsLayout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
-- stageButtonsLayout:setSpacing(1, 1, 3)

local function loadImage(name)
	return image.load(installerPicturesPath .. name .. ".pic")
end

local function newInput(...)
	return GUI.input(1, 1, 26, 1, 0xF0F0F0, 0x787878, 0xC3C3C3, 0xF0F0F0, 0x878787, "", ...)
end

local function newSwitchAndLabel(width, color, text, state)
	return GUI.switchAndLabel(1, 1, width, 6, color, 0xD2D2D2, 0xF0F0F0, 0xA5A5A5, text .. ":", state)
end

local function addTitle(color, text)
	return mainw:addChild(GUI.text(1, 1, color, text))
end

local function addImage(before, after, name)
	if before > 0 then
		layout:addChild(GUI.object(1, 1, 1, before))
	end

	local picture = layout:addChild(GUI.image(1, 1, loadImage(name)))
	picture.height = picture.height + after

	return picture
end

local function addImage1(x, y, before, after, name)
	if before > 0 then
		mainw:addChild(GUI.object(1, 1, 1, before))
	end

	local picture = mainw:addChild(GUI.image(x, y, loadImage(name)))
	picture.height = picture.height + after

	return picture
end

--local function addStageButton(text)
--	local button = stageButtonsLayout:addChild(GUI.adaptiveFramedButton(1, 1, 2, 1, 0xC3C3C3, 0x878787, 0xA5A5A5, 0x696969, text))
--
-- local button = stageButtonsLayout:addChild(GUI.adaptiveRoundedButton(1, 1, 2, 0, 0xC3C3C3, 0x878787, 0xA5A5A5, 0x696969, text))
--	button.colors.disabled.background = 0xD2D2D2
--	button.colors.disabled.text = 0xB4B4B4
--
--	return button
--end

-- local prevButton = addStageButton("Back")
-- local nextButton = addStageButton("Next")
local prevButton = window:addChild(GUI.adaptiveFramedButton(window.width - 18, window.height - 2, 2, 1, 0xC3C3C3, 0x878787, 0xA5A5A5, 0x696969, "Back"))
prevButton.colors.disabled.background = 0xD2D2D2
prevButton.colors.disabled.text = 0xB4B4B4

local nextButton = window:addChild(GUI.adaptiveFramedButton(window.width - 8, window.height - 2, 2, 1, 0xC3C3C3, 0x878787, 0xA5A5A5, 0x696969, "Next"))
nextButton.colors.disabled.background = 0xD2D2D2
nextButton.colors.disabled.text = 0xB4B4B4

local localization
local stage = 1
local stages = {}

local usernameInput = newInput("")
local passwordInput = newInput("", false, "•")
local passwordSubmitInput = newInput("", false, "•")
local usernamePasswordText = GUI.text(1, 1, 0xCC0040, "")
local passwordSwitchAndLabel = newSwitchAndLabel(26, 0x66DB80, "", false)

local wallpapersSwitchAndLabel = newSwitchAndLabel(30, 0xFF4980, "", true)
local screensaversSwitchAndLabel = newSwitchAndLabel(30, 0xFFB600, "", true)
local applicationsSwitchAndLabel = newSwitchAndLabel(30, 0x33DB80, "", true)
local localizationsSwitchAndLabel = newSwitchAndLabel(30, 0x33B6FF, "", true)

local acceptSwitchAndLabel = newSwitchAndLabel(30, 0x9949FF, "", false)

local localizationStart = GUI.text(1, 2, 0xCC0040, "Language to install:")

local function addStage(onTouch)
	table.insert(stages, function()
		mainw:removeChildren()
		layout:removeChildren()
		onTouch()
		workspace:draw()
	end)
end

local function loadStage()
	if stage < 1 then
		stage = 1
	elseif stage > #stages then
		stage = #stages
	end

	stages[stage]()
end

local function checkUserInputs()
	local nameEmpty = #usernameInput.text == 0
	local nameVaild = usernameInput.text:match("^%w[%w%s_]+$")
	local passValid = passwordSwitchAndLabel.switch.state or #passwordInput.text == 0 or #passwordSubmitInput.text == 0 or passwordInput.text == passwordSubmitInput.text

	if (nameEmpty or nameVaild) and passValid then
		usernamePasswordText.hidden = true
		nextButton.disabled = nameEmpty or not nameVaild or not passValid
	else
		usernamePasswordText.hidden = false
		nextButton.disabled = true

		if nameVaild then
			usernamePasswordText.text = localization.passwordsArentEqual
		else
			usernamePasswordText.text = localization.usernameInvalid
		end
	end
end

local function checkLicense()
	nextButton.disabled = not acceptSwitchAndLabel.switch.state
end

prevButton.onTouch = function()
	stage = stage - 1
	loadStage()
end

nextButton.onTouch = function()
	stage = stage + 1
	loadStage()
end

acceptSwitchAndLabel.switch.onStateChanged = function()
	checkLicense()
	workspace:draw()
end

passwordSwitchAndLabel.switch.onStateChanged = function()
	passwordInput.hidden = passwordSwitchAndLabel.switch.state
	passwordSubmitInput.hidden = passwordSwitchAndLabel.switch.state
	checkUserInputs()

	workspace:draw()
end

usernameInput.onInputFinished = function()
	checkUserInputs()
	workspace:draw()
end

passwordInput.onInputFinished = usernameInput.onInputFinished
passwordSubmitInput.onInputFinished = usernameInput.onInputFinished

-- Localization selection stage
addStage(function()
	prevButton.disabled = true
	local localizationComboBox = GUI.comboBox(40, 14, 22, 1, 0xF0F0F0, 0x969696, 0xD2D2D2, 0xB4B4B4)
	for i = 1, #files.localizations do
		localizationComboBox:addItem(filesystemHideExtension(filesystemName(files.localizations[i]))).onTouch = function()
		-- Obtaining localization table
		localization = deserialize(request(installerURL .. files.localizations[i]))

		-- Filling widgets with selected localization data
		usernameInput.placeholderText = localization.username
		passwordInput.placeholderText = localization.password
		passwordSubmitInput.placeholderText = localization.submitPassword
		passwordSwitchAndLabel.label.text = localization.withoutPassword
		wallpapersSwitchAndLabel.label.text = localization.wallpapers
		screensaversSwitchAndLabel.label.text = localization.screensavers
		applicationsSwitchAndLabel.label.text = localization.applications
		localizationsSwitchAndLabel.label.text = localization.languages
		acceptSwitchAndLabel.label.text = localization.accept
		end
	end

	addImage1(16, 5, 0, 0, "Logo")

	mainw:addChild(localizationComboBox)
	mainw:addChild(GUI.text(20, 14, 0xCC0040, "Language to install:"))

	workspace:draw()
	localizationComboBox:getItem(1).onTouch()
end)

-- Filesystem selection stage
addStage(function()
	prevButton.disabled = false
	nextButton.disabled = false

	mainw:addChild(GUI.object(5, 5, 1, 1))
	addTitle(0x696969, localization.select)
	
	local diskLayout = mainw:addChild(GUI.layout(1, 2, layout.width, 11, 1, 1))
	diskLayout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
	diskLayout:setSpacing(1, 1, 0)

	local HDDImage = loadImage("HDD")

	local function select(proxy)
		selectedFilesystemProxy = proxy

		for i = 1, #diskLayout.children do
			diskLayout.children[i].children[1].hidden = diskLayout.children[i].proxy ~= selectedFilesystemProxy
		end
	end

	local function updateDisks()
		local function diskEventHandler(workspace, disk, e1)
			if e1 == "touch" then
				select(disk.proxy)
				workspace:draw()
			end
		end

		local function addDisk(proxy, picture, disabled)
			local disk = diskLayout:addChild(GUI.container(1, 1, 14, diskLayout.height))
			local formatContainer = disk:addChild(GUI.container(1, 1, disk.width, disk.height))
			formatContainer:addChild(GUI.panel(1, 1, formatContainer.width, formatContainer.height, 0xD2D2D2))
			formatContainer:addChild(GUI.button(1, formatContainer.height, formatContainer.width, 1, 0xCC4940, 0xE1E1E1, 0x990000, 0xE1E1E1, localization.erase)).onTouch = function()
				local list, path = proxy.list("/")
				for i = 1, #list do
					path = "/" .. list[i]

					if proxy.address ~= temporaryFilesystemProxy.address or path ~= installerPath then
						proxy.remove(path)
					end
				end

				updateDisks()
			end

			if disabled then
				picture = image.blend(picture, 0xFFFFFF, 0.4)
				disk.disabled = true
			end

			disk:addChild(GUI.image(4, 2, picture))
			disk:addChild(GUI.label(2, 7, disk.width - 2, 1, disabled and 0x969696 or 0x696969, text.limit(proxy.getLabel() or proxy.address, disk.width - 2))):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
			disk:addChild(GUI.progressBar(2, 8, disk.width - 2, disabled and 0xCCDBFF or 0x66B6FF, disabled and 0xD2D2D2 or 0xC3C3C3, disabled and 0xC3C3C3 or 0xA5A5A5, math.floor(proxy.spaceUsed() / proxy.spaceTotal() * 100), true, true, "", "% " .. localization.used))

			disk.eventHandler = diskEventHandler
			disk.proxy = proxy
		end

		diskLayout:removeChildren()
		
		for address in component.list("filesystem") do
			local proxy = component.proxy(address)
			if proxy.spaceTotal() >= 1 * 1024 * 1024 then
				addDisk(
					proxy,
					proxy.spaceTotal() < 1 * 1024 * 1024 and floppyImage or HDDImage,
					proxy.isReadOnly() or proxy.spaceTotal() < 2 * 1024 * 1024
				)
			end
		end

		select(selectedFilesystemProxy)
	end
	
	updateDisks()
end)

-- User profile setup stage
addStage(function()
	checkUserInputs()

	addImage(0, 0, "User")
	addTitle(0x696969, localization.setup)

	layout:addChild(usernameInput)
	layout:addChild(passwordInput)
	layout:addChild(passwordSubmitInput)
	layout:addChild(usernamePasswordText)
	layout:addChild(passwordSwitchAndLabel)
end)

-- Downloads customization stage
addStage(function()
	nextButton.disabled = false

	addImage(0, 0, "Settings")
	addTitle(0x696969, localization.customize)

	layout:addChild(wallpapersSwitchAndLabel)
	layout:addChild(screensaversSwitchAndLabel)
	layout:addChild(applicationsSwitchAndLabel)
	layout:addChild(localizationsSwitchAndLabel)
end)

-- License acception stage
addStage(function()
	checkLicense()

	local lines = text.wrap({request("LICENSE")}, layout.width - 2)
	local textBox = layout:addChild(GUI.textBox(1, 1, layout.width, layout.height - 3, 0xF0F0F0, 0x696969, lines, 1, 1, 1))

	layout:addChild(acceptSwitchAndLabel)
end)

-- Downloading stage
addStage(function()
	stageButtonsLayout:removeChildren()
	
	-- Creating user profile
	mainw:removeChildren()
	addImage(1, 1, "User")
	addTitle(0x969696, localization.creating)
	workspace:draw()

	-- Renaming if possible
	if not selectedFilesystemProxy.getLabel() then
		selectedFilesystemProxy.setLabel("Minedows System")
	end

	local function switchProxy(runnable)
		filesystem.setProxy(selectedFilesystemProxy)
		runnable()
		filesystem.setProxy(temporaryFilesystemProxy)
	end

	-- Creating system paths
	local userSettings, userPaths
	switchProxy(function()
		paths.create(paths.system)
		userSettings, userPaths = system.createUser(
			usernameInput.text,
			localizationComboBox:getItem(localizationComboBox.selectedItem).text,
			not passwordSwitchAndLabel.switch.state and passwordInput.text,
			wallpapersSwitchAndLabel.switch.state,
			screensaversSwitchAndLabel.switch.state
		)
	end)

	-- Flashing EEPROM
	layout:removeChildren()
	addImage(1, 1, "EEPROM")
	addTitle(0x969696, localization.flashing)
	workspace:draw()
	
	EEPROMProxy.set(request(EFIURL))
	EEPROMProxy.setLabel("OrangeCat EFI")
	EEPROMProxy.setData(selectedFilesystemProxy.address)

	-- Downloading files
	layout:removeChildren()
	addImage(3, 2, "Downloading")

	local container = layout:addChild(GUI.container(1, 1, layout.width - 20, 2))
	local progressBar = container:addChild(GUI.progressBar(1, 1, container.width, 0x66B6FF, 0xD2D2D2, 0xA5A5A5, 0, true, false))
	local cyka = container:addChild(GUI.label(1, 2, container.width, 1, 0x969696, "")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)

	-- Creating final filelist of things to download
	local downloadList = {}

	local function getData(item)
		if type(item) == "table" then
			return item.path, item.id, item.version, item.shortcut
		else
			return item
		end
	end

	local function addToList(state, key)
		if state then
			local selectedLocalization, path, localizationName = localizationComboBox:getItem(localizationComboBox.selectedItem).text
			
			for i = 1, #files[key] do
				path = getData(files[key][i])

				if filesystem.extension(path) == ".lang" then
					localizationName = filesystem.hideExtension(filesystem.name(path))

					if
						-- If ALL loacalizations need to be downloaded
						localizationsSwitchAndLabel.switch.state or
						-- If it's required localization file
						localizationName == selectedLocalization or
						-- Downloading English "just in case" for non-english localizations
						selectedLocalization ~= "English" and localizationName == "English"
					then
						table.insert(downloadList, files[key][i])
					end
				else
					table.insert(downloadList, files[key][i])
				end
			end
		end
	end

	addToList(true, "required")
	addToList(true, "localizations")
	addToList(applicationsSwitchAndLabel.switch.state, "optional")
	addToList(wallpapersSwitchAndLabel.switch.state, "wallpapers")
	addToList(screensaversSwitchAndLabel.switch.state, "screensavers")

	-- Downloading files from created list
	local versions, path, id, version, shortcut = {}
	for i = 1, #downloadList do
		path, id, version, shortcut = getData(downloadList[i])

		cyka.text = text.limit(localization.installing .. " \"" .. path .. "\"", container.width, "center")
		workspace:draw()

		-- Download file
		download(path, OSPath .. path)

		-- Adding system versions data
		if id then
			versions[id] = {
				path = OSPath .. path,
				version = version or 1,
			}
		end

		-- Create shortcut if possible
		if shortcut then
			switchProxy(function()
				system.createShortcut(
					userPaths.desktop .. filesystem.hideExtension(filesystem.name(filesystem.path(path))),
					OSPath .. filesystem.path(path)
				)
			end)
		end

		progressBar.value = math.floor(i / #downloadList * 100)
		workspace:draw()
	end

	-- Saving system versions
	switchProxy(function()
		filesystem.writeTable(paths.system.versions, versions, true)
	end)

	-- Done info
	layout:removeChildren()
	addImage(1, 1, "Done")
	addTitle(0x969696, localization.installed)
	addStageButton(localization.reboot).onTouch = function()
		computer.shutdown(true)
	end
	workspace:draw()

	-- Removing temporary installer directory
	temporaryFilesystemProxy.remove(installerPath)
end)

--------------------------------------------------------------------------------

loadStage()
workspace:start()
