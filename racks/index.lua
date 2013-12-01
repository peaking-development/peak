--[=====[Rack by CoderPuppy]=====]
-- Device Manager

local utils = require('peak-utils')

-- racks.new(id, dtype)
-- Creates a new device
-- You need to implement callMethod and listMethods or wrap
function exports.new(id, dtype)
	local self = {
		id             = id,
		type           = dtype,
		connectionType = 'virtual'
	}

	function self:callMethod(name, ...) return self:wrap()[name](...) end
	function self:listMethods()
		local methods = {}

		for k in pairs(self:wrap()) do
			methods[#methods + 1] = k
		end

		return methods
	end

	function self:wrap()
		local wrapped = {}

		local methods = self:listMethods()
		for i = 1, #methods do
			local method = methods[i]
			wrapped[method] = function(...)
				self:callMethod(method, ...)
			end
		end

		return wrapped
	end

	return self
end

function exports.wrap(id)
	local self = exports.new(id, peripheral.getType(id))

	self.connectionType = 'hardware'

	function self:callMethod(name, ...) return peripheral.callMethod(id, name, ...) end
	function self:listMethods() return peripheral.listMethods(id) end

	return self
end

function exports.isDevice(dev)
	return type(dev)      == 'table'
	   and type(dev.id)   == 'string'
	   and type(dev.type) == 'string'
end

setmetatable(exports, { __call = function(t, opts, queue)
	local self = utils.eventEmitter({
		table = {}
	})

	function self:register(dev)
		if type(dev) ~= 'table' then error('Attempt to register non-table device: ' .. id, 2) end

		if type(self.table[dev.id]) ~= 'table' then
			self.table[dev.id] = dev
			self:emit('register', dev)
		else
			error('Attempt to reregister a device: ' .. dev.id, 2)
		end
	end

	function self:unregister(id)
		queue('rack:unregister', id)
		self.table[id] = nil
	end

	function self:filter(dev, ...)
		local args = {...}

		for i = 1, #args do
			local arg = args[i]

			if not utils.filterProp(arg, 'id', dev.id) then return false end
			if not utils.filterProp(arg, 'type', dev.type) then return false end
		end

		return true
	end

	function self:first(...)
		for k, dev in pairs(self.table) do
			if self.filter(dev, ...) then
				return dev
			end
		end
	end

	function self:all(...)
		local all = {}

		for k, dev in pairs(self.table) do
			if self.filter(dev, ...) then
				all[#all + 1] = dev
			end
		end

		return all
	end

	function self:detect()
		local names = peripheral.getNames()

		for i = 1, #names do
			self:register(exports.wrap(names[i]))
		end
	end

	function self:newDeviceHandler(ev, side)
		if ev == 'peripheral' then
			self:register(exports.wrap(side))
		end
	end

	function self:oldDeviceHandler(ev, side)
		if ev == 'peripheral_detach' then
			self:unregister(side)
		end
	end

	-- I don't know how i should implement this
	function self:newWiredModemHandler(ev, id, dev)

	end

	return self
end })