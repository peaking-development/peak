--[=====[Peak Kernel by CoderPuppy]=====]

local processes = require('peak-tasks/processes')
local threads   = require('peak-tasks/threads')
local utils     = require('peak-utils')
local users     = require('peak-users')
local racks     = require('peak-racks')

local function peak()
	local self = {}

	self.process   = processes.newBase(nil, 1, 'kernel')
	self.namespace = processes.kernelNamespace(self.process)
	self.thread    = threads.newBase(self.process)

	-- Begin actual kernel section

	self.modules = {}
	self.debug   = false

	do
		local oldEmit = self.emit

		function self:emit(...)
			self:checkKernelCall('kernel.emit')

			return oldEmit(self, ...)
		end
	end

	--[===[Interupts]===]
	self.thread.alive = true
	self.thread.paused = false

	function self.thread.run(threadSelf, iters)
		if type(iters) ~= 'number' then iters = 1 end

		for i = 1, iters do
			if #self.thread.eventQueue == 0 then break end
			local ev = table.remove(self.thread.eventQueue)
			-- self.rack:emit('interupt', unpack(ev))
			-- self.rack:emit('interupt:' .. ev[1], unpack(ev))
		end

		self.scheduler:run(iters)

		return true
	end

	--[===[Modules]===]
	function self:loadModule(module)
		if type(module) ~= 'table' then error('Attempt to load non-table as module', 2) end

		if type(self.modules[module.name]) ~= 'table' then
			self.modules[module.name] = module
			module:load(self)
		else
			error('Module already loaded: ' .. module.name, 2)
		end
	end

	function self:unloadModule(module)
		if type(module) == 'table' then module = module.name end

		self.modules[module]:unload(self)
		self.modules[module] = nil
	end

	--[===[Rack]===]
	-- self.rack = racks({})
	-- self.rack:detect()

	--[===[Scheduler]===]
	self.scheduler = threads.scheduler()

	-- Process and Scheduler Interop
	do
		local function listenProcess(pid, process)
			if process == self.process then return false end

			process:on('newThread', utils.curry(self.scheduler.add, self.scheduler))

			for i = 1, #process.threads do
				self.scheduler:add(process.threads[i])
			end
		end

		local function listenNamespace(ns)
			ns:on('new', listenProcess)
			
			local processes = ns:list()

			for i = 1, #processes do
				listenProcess(unpack(processes[i]))
			end
		end

		listenNamespace(self.namespace)
	end

	return self
end

module.exports = setmetatable({
	threads = threads
}, {
	__call = function(t, ...) return peak(...) end
})