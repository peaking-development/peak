--[=====[Peak Kernel by CoderPuppy]=====]

local processes = require('peak-tasks/processes')
local threads   = require('peak-tasks/threads')
local utils     = require('peak-utils')
local users     = require('peak-users')
local racks     = require('peak-racks')

local function peak()
	--[===[Process Manager]===]
	local process = processes.newBase(nil, 1, 'kernel')
	local namespace = processes.kernelNamespace(process)

	local self = threads.newBase(process)
	self.alive = true
	self.paused = false

	process:registerQueue(utils.curry(self.emit, self))
	namespace:registerQueue(utils.curry(self.emit, self))

	self.namespace = namespace
	self.thread    = self

	-- Begin actual kernel section

	self.modules = {}
	self.debug   = false

	function self:checkKernelCall(func)
		local user = users.current()

		if user ~= nil and user.id ~= 0 then error(func .. ' can only be called from the kernel', 3) end
	end

	do
		local oldEmit = self.emit

		function self:emit(...)
			self:checkKernelCall('kernel.emit')

			return oldEmit(self, ...)
		end
	end

	--[===[Interupts]===]
	function self:registerInterupt(ev, handler)
		self:checkKernelCall('kernel.registerInterupt')

		self:on('interupt:' .. ev, handler)
	end

	function self:run(iters)
		self:checkKernelCall('kernel.run')

		if type(iters) ~= 'number' then iters = 1 end

		for i = 1, iters do
			if #self.eventQueue == 0 then break end
			local ev = table.remove(self.eventQueue)
			if #ev == 0 then error('sthap it!', 2) end -- TODO: This is very descriptive
			self:emit('interupt:' .. ev[1], unpack(ev))
		end

		self.scheduler:run(iters)

		return true
	end

	--[===[Modules]===]
	function self:loadModule(module)
		-- This should change
		if users.current().id ~= 0 then error('kernel.loadModule can only be called from the kernel', 2) end

		if type(module) ~= 'table' then error('Attempt to load non-table as module', 2) end

		if type(self.modules[module.name]) ~= 'table' then
			self.modules[module.name] = module
			module:load(self)
		else
			error('Module already loaded: ' .. module.name, 2)
		end
	end

	function self:unloadModule(module)
		-- This should change
		if users.current().id ~= 0 then error('kernel.registerInterupt can only be called from the kernel', 2) end

		if type(module) == 'table' then module = module.name end

		self.modules[module]:unload(self)
		self.modules[module] = nil
	end

	--[===[Rack]===]
	self.rack = racks({})
	self.rack:registerQueue(utils.curry(self.emit, self))

	self.rack:detect()

	self:registerInterupt('peripheral', utils.curry(self.rack.newDeviceHandler, self.rack))
	self:registerInterupt('peripheral_detach', utils.curry(self.rack.oldDeviceHandler, self.rack))

	--[===[Scheduler]===]
	self.scheduler = threads.scheduler()
	self:registerQueue(utils.curry(self.scheduler.queue, self.scheduler))

	-- Process and Scheduler Interop
	do
		local function listenProcess(pid, process)
			process:on('newThread', self.scheduler.add)

			for i = 1, #process.threads do
				kernel.scheduler:add(process.threads[i])
			end
		end

		local function listenNamespace(ns)
			ns:on('new', listenProcess)

			local processes = ns:list()

			for i = 1, #processes do
				listenProcess(unpack(processes[i]))
			end
		end

		listenNamespace(namespace)
	end

	return self
end

module.exports = setmetatable({
	threads = threads
}, {
	__call = function(t, ...) return peak(...) end
})