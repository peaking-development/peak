--[=====[Rack by CoderPuppy]=====]
-- Device Manager

local utils = require('./utils')

function exports.new(id, dtype, api)
	local device = {
		id = id,
		api = api,
		type = dtype
	}

	return device
end

function exports.wrap(id)
	return exports.new(id, peripheral.getType(id), peripheral.wrap(id))
end

function exports.isDevice(dev)
	return type(dev)      == 'table'
	   and type(dev.id)   == 'string'
	   and type(dev.api)  == 'table'
	   and type(dev.type) == 'string'
end

setmetatable(exports, { __call = function(t, opts, queue)
	local devices = {
		table = {}
	}

	function devices.register(dev)
		if type(dev) ~= 'table' then error('Attempt to register non-table device: ' .. id, 2) end

		if type(devices.table[dev.id]) ~= 'table' then
			devices.table[dev.id] = dev
			queue('devices:register', dev)
		else
			error('Attempt to reregister a device: ' .. dev.id, 2)
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

			if not utils.filterProp(arg, 'id', dev.id) then return false end
			if not utils.filterProp(arg, 'type', dev.type) then return false end
		end

		return true
	end

	function devices.first(...)
		for k, dev in pairs(devices.table) do
			if devices.filter(dev, ...) then
				return dev
			end
		end
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

	function devices.detect()
		local names = peripheral.getNames()

		for i = 1, #names do
			devices.register(exports.wrap(names[i]))
		end
	end

	function devices.newDeviceHandler(ev, side)
		if ev == 'peripheral' then
			devices.register(exports.wrap(side))
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
end })