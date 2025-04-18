local strMain, strChangeLbl, strKD, strFS, colorsTitle, colorsBG, colorsText, colorsSelectBG, colorsSelectText, componentProxy, componentList, pullSignal, uptime, tableInsert, mathMax, mathMin, mathHuge, mathFloor, statusline = "OrangeCat Loader", "Change label", "key_down", "filesystem", 0xFF6347, 0x000000, 0xD2691E, 0x433218, 0xA26A42, component.proxy, component.list, computer.pullSignal, computer.uptime, table.insert, math.max, math.min, math.huge, math.floor,0

local eeprom, gpu, internetAddress = componentProxy(componentList("eeprom")()), componentProxy(componentList("gpu")()), componentList("internet")()

gpu.bind(componentList("screen")(), true)

local shutdown, gpuSet, gpuSetBackground, gpuSetForeground, gpuFill, eepromSetData, eepromGetData, screenWidth, screenHeight = computer.shutdown, gpu.set, gpu.setBackground, gpu.setForeground, gpu.fill, eeprom.setData, eeprom.getData, gpu.getResolution()

local OSList, rectangle, centrizedText, consoleText, menuElement =
	{
		{
			"/init.lua",
			function()
			end
		},
		{
			"/OS.lua",
			function()
				computer.getBootAddress, computer.setBootAddress = eepromGetData, eepromSetData
			end
		}
	},
	function(x, y, width, height, color)
		gpuSetBackground(color)
		gpuFill(x, y, width, height, " ")
	end,
	function(y, foreground, text)
		local x = mathFloor(screenWidth / 2 - #text / 2)
		gpuSetForeground(foreground)
		gpuSet(x, y, text)
	end,
	function(text)
		if statusline > screenHeight then
			statusline = 1
			gpuSetBackground(0x000000)
			gpuFill(1, 1, screenWidth/2, screenHeight, " ")
		end
		statusline = statusline + 1
		gpuSetForeground(0xFFFFFF)
		gpuSet(1, statusline, text)
	end,
	function(text, callback, breakLoop)
		return {
			s = text,
			c = callback,
			b = breakLoop
		}
	end

local function title(y, titleText)
	y = 48
	rectangle(screenWidth/2-25, 1, screenWidth, screenHeight, colorsBG)
--	rectangle(mathFloor(screenWidth/2-10), mathFloor(screenHeight/2-10), 20, 20, colorsBG)
	centrizedText(y, colorsTitle, titleText)

	return y - 25
end

local function status(titleText, statusText, needWait, cons)
	local lines = {}
	local y = title(#lines, titleText)
	if cons then
		consoleText(statusText)
	else
		for line in statusText:gmatch("[^\r\n]+") do
			lines[#lines + 1] = line:gsub("\t", "  ")
		end
		for i = 1, #lines do
			centrizedText(y, colorsText, lines[i])
			y = y + 1
		end
	end

	if needWait then
		repeat
			needWait = pullSignal()
		until needWait == strKD or needWait == "touch"
	end
end

local function executeString(...)
	local result, reason = load(...)
	if result then
		result, reason = xpcall(result, debug.traceback)
		if result then
			return
		end
	end

	status(strMain, reason, false,true)
end

local boot, menuBack, menu, input =
	function(proxy)
		for i = 1, #OSList do
			if proxy.exists(OSList[i][1]) then
				status(strMain, "Booting from " .. (proxy.getLabel() or proxy.address),false,true)

				-- Updating current EEPROM boot address if it's differs from given proxy address
				if eepromGetData() ~= proxy.address then
					eepromSetData(proxy.address)
				end

				-- Running OS pre-boot function
				OSList[i][2]()

				-- Reading boot file
				local handle, data, chunk, success, reason = proxy.open(OSList[i][1], "rb"), ""
				repeat
					chunk = proxy.read(handle, mathHuge)
					data = data .. (chunk or "")
				until not chunk

				proxy.close(handle)

				-- Running boot file
				executeString(data, "=" .. OSList[i][1])

				return 1
			end
		end
	end,
	function(f)
		return menuElement("Exit recovery", f, 1)
	end,
	function(titleText, elements)
		local selectedElement, maxLength = 1, 0
		for i = 1, #elements do
			maxLength = math.max(maxLength, #elements[i].s)
		end

		while 1 do
			local y, x, eventData = title(#elements + 2, titleText)
			
			for i = 1, #elements do
				x = mathFloor(screenWidth / 2 - #elements[i].s / 2)
				
				if i == selectedElement then
					rectangle(mathFloor(screenWidth / 2 - maxLength / 2) - 2, y, maxLength + 4, 1, colorsSelectBG)
					gpuSetForeground(colorsSelectText)
					gpuSet(x, y, elements[i].s)
					gpuSetBackground(colorsBG)
				else
					gpuSetForeground(colorsText)
					gpuSet(x, y, elements[i].s)
				end
				
				y = y + 1
			end

			eventData = {pullSignal()}
			if eventData[1] == strKD then
				if eventData[4] == 200 and selectedElement > 1 then
					selectedElement = selectedElement - 1
				elseif eventData[4] == 208 and selectedElement < #elements then
					selectedElement = selectedElement + 1
				elseif eventData[4] == 28 then
					if elements[selectedElement].c then
						elements[selectedElement].c()
					end

					if elements[selectedElement].b then
						return
					end
				end
			end
		end
	end,
	function(y, prefix)
		local text, state, eblo, eventData, char = "", true
		while 1 do
			eblo = prefix .. text
			gpuFill(1, y, screenWidth, 1, " ")
			-- rectangle(mathFloor(screenWidth/2-10), 1, 20, screenHeight, colorsBG)
			gpuSetForeground(colorsText)
			gpuSet(mathFloor(screenWidth / 2 - #eblo / 2), y, eblo .. (state and "█" or ""))

			eventData = {pullSignal(0.5)}
			if eventData[1] == strKD then
				if eventData[4] == 28 then
					return text
				elseif eventData[4] == 14 then
					text = text:sub(1, -2)
				else
					char = unicode.char(eventData[3])
					if char:match("^[%w%d%p%s]+") then
						text = text .. char
					end
				end

				state = true
			elseif eventData[1] == "clipboard" then
				text = text .. eventData[3]
			elseif not eventData[1] then
				state = not state
			end
		end
	end

status(strMain, "Press ALT to enter recovery!",false,true)

local deadline, eventData = uptime() + 1
while uptime() < deadline do
	eventData = {pullSignal(deadline - uptime())}
	if eventData[1] == strKD and eventData[4] == 56 then
		local utilities = {
			menuElement("Partitions", function()
				local restrict, filesystems, filesystemOptions =
					function(text, limit)
						if #text < limit then
							text = text .. string.rep(" ", limit - #text)
						else
							text = text:sub(1, limit)
						end

						return text .. "  "
					end,
					{menuBack()}

				local function updateFilesystems()
					for i = 2, #filesystems do
						table.remove(filesystems, 1)
					end

					for address in componentList(strFS) do
						local proxy = componentProxy(address)
						local label, isReadOnly, filesystemOptions =
							proxy.getLabel() or "noname",
							proxy.isReadOnly(),
							{
								menuElement("Set as bootable", function()
									eepromSetData(address)
									updateFilesystems()
								end, 1)
							}

						if not isReadOnly then
							tableInsert(filesystemOptions, menuElement(strChangeLbl, function()
								proxy.setLabel(input(title(2, strChangeLbl), "Enter new name: "))
								updateFilesystems()
							end, 1))

							tableInsert(filesystemOptions, menuElement("Format", function()
								status(strMain, "Formatting " .. address,false,true)
								
								for _, file in ipairs(proxy.list("/")) do
									proxy.remove(file)
								end

								updateFilesystems()
							end, 1))
						end

						tableInsert(filesystemOptions, menuBack())

						tableInsert(filesystems, 1,
							menuElement(
								(address == eepromGetData() and "> " or "  ") ..
								restrict(label, 12) ..
								restrict(proxy.spaceTotal() > 1048576 and "HDD" or proxy.spaceTotal() > 65536 and "FDD" or "SYS", 3) ..
								restrict(isReadOnly and "R" or "R/W", 3) ..
								restrict(string.format("%.1f", proxy.spaceUsed() / proxy.spaceTotal() * 100) .. "%", 6) ..
								address:sub(1, 7) .. "…",
								function()
									menu(label .. " (" .. address .. ")", filesystemOptions)
								end
							)
						)
					end
				end

				updateFilesystems()
				menu("Select partition", filesystems)
			end),
			
			menuElement("Shutdown", function()
				shutdown()
			end),

			menuBack()
		}

		if internetAddress then	
			tableInsert(utilities, 2, menuElement("System recovery", function()
				local handle, data, result, reason = componentProxy(internetAddress).request("https://raw.githubusercontent.com/Yaroslav-Nesst/minedows/master/Installer/Main.lua"), ""

				if handle then
					status(strMain, "Running recovery script...",false,true)

					while 1 do
						result, reason = handle.read(mathHuge)	
						
						if result then
							data = data .. result
						else
							handle.close()
							
							if reason then
								status(strMain, reason, true,true)
							else
								executeString(data, "=string")
							end

							break
						end
					end
				else
					status(strMain, "Invalid URL-adress", true,true)
				end
			end))
		end

		menu(strMain, utilities)
	end
end

local proxy = componentProxy(eepromGetData())
if not (proxy and boot(proxy)) then
	for address in componentList(strFS) do
		proxy = componentProxy(address)

		if boot(proxy) then
			break
		else
			proxy = nil
		end
	end

	if not proxy then
		status(strMain, "No os/init.lua found.", true,true)
	end
end

shutdown()
