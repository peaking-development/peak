--[=====[Rack by CoderPuppy]=====]
-- Device Manager

module.exports = function(opts, queue)
	local devices = {
		table = {}
	}

	function devices.register(id, dtype, dev)
		if type(dev) ~= 'table' then error('Attempt to register non-table device: ' .. id, 2) end

		if type(devices.table[id]) ~= 'table' then
			devices.table[id] = {
				type = dtype,
				api = dev
			}
			queue('devices:register', id, dtype, dev)
		else
			error('Attempt to reregister a device: ' .. id, 2)
		end
	end

	function devices.unregister(id)
		queue('devices:unregister', id)
		devices.table[id] = nil
	end

	function devices.filter(dev, ...)
		local args = {...}

		for i = 1, #args do
			local arg = args[i]

			if arg:sub(1, 5) == 'type:' then
				if dev.type ~= arg:sub(6) then return false end
			elseif arg:sub(1, 5) == 'type|' then
				if dev.type == arg:sub(6) then return false end
			-- TODO: Add more filters here
			end
		end


		return true
	end

	function devices.first(...)
		for k, dev in pairs(devices.table) do
			if devices.filter(dev, ...) then
				return dev
			end
		end

		-- How should this be handled
		error('No device of type: ' .. dtype .. ' registered with device manager', 2)
	end

	function devices.all(...)
		local all = {}

		for k, dev in pairs(devices.table) do
			if devices.filter(dev, ...) then
				all[#all + 1] = dev
			end
		end

		return all
	end

	function devices.newDeviceHandler(ev, side)
		if ev == 'peripheral' then
			devices.register(side, peripheral.wrap(side))
		end
	end

	function devices.oldDeviceHandler(ev, side)
		if ev == 'peripheral_detach' then
			devices.unregister(side)
		end
	end

	-- I don't really know how i should implement this
	function devices.newWiredModemHandler(ev, id, dev)

	end

	return devices
end