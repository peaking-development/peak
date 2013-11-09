--[=====[Peak Kernel by CoderPuppy]=====]

local deviceManager = require('peak-rack')
local processes     = require('peak-tasks/processes')
local threads       = require('peak-tasks/threads')
local utils         = require('peak-utils')
local users         = require('peak-users')

local function peak()
	--[===[Process Manager]===]
	local process = processes.newBase(nil, 1, 'kernel')
	local namespace = processes.kernelNamespace(process)

	local kernel = threads.newBase(process)
	kernel.alive = true
	kernel.paused = false

	process.registerQueue(kernel.emit)
	namespace.registerQueue(kernel.emit)

	kernel.namespace = namespace
	kernel.thread    = kernel

	-- Begin actual kernel section

	kernel.modules = {}
	kernel.debug   = false

	utils.eventEmitter(kernel)

	function kernel.checkKernelCall(func)
		local user = users.current()

		if user ~= nil and user.id ~= 0 then error(func .. ' can only be called from the kernel', 3) end
	end

	do
		local oldEmit = kernel.emit

		function kernel.emit(...)
			kernel.checkKernelCall('kernel.emit')

			return oldEmit(...)
		end
	end

	--[===[Interupts]===]
	function kernel.registerInterupt(ev, handler)
		kernel.checkKernelCall('kernel.registerInterupt')

		kernel.on('interupt:' .. ev, handler)

		-- if type(handler) ~= 'function' then error('Attempt to register non-function as interupt handler', 2) end

		-- local interupts = kernel.interupts[ev]
		-- if interupts == nil then
		-- 	kernel.interupts[ev] = {handler}
		-- 	return 1
		-- elseif type(interupts) == 'table' then
		-- 	interupts[#interupts + 1] = handler
		-- 	return #interupts
		-- elseif type(interupts) == 'function' then
		-- 	kernel.interupts[ev] = {interupts, handler}
		-- 	return 2
		-- else
		-- 	print('what is going on here? ', type(interupts))
		-- 	print('someone messed with the interupt table')
		-- end
	end

	function kernel.run(iters)
		kernel.checkKernelCall('kernel.run')

		if type(iters) ~= 'number' then iters = 1 end

		for i = 1, iters do
			if #kernel.eventQueue == 0 then break end
			local ev = table.remove(kernel.eventQueue)
			if #ev == 0 then error('sthap it!', 2) end -- TODO: This is very descriptive
			kernel.emit('interupt:' .. ev[1], unpack(ev))
		end

		kernel.scheduler.run(iters)

		return true

		-- if type(kernel.interupts[ev]) == 'function' then
		-- 	kernel.interupts[ev](ev, ...)
		-- elseif type(kernel.interupts[ev]) == 'table' then
		-- 	local interupts = kernel.interupts[ev]
		-- 	for i = 1, #interupts do
		-- 		interupts[i](ev, ...)
		-- 	end
		-- elseif kernel.debug then
		-- 	print('Unhandled interupt: ' .. ev)
		-- end

		-- kernel.scheduler.interupt(ev, ...)
	end

	--[===[Modules]===]
	function kernel.loadModule(module)
		-- This should change
		if users.current().id ~= 0 then error('kernel.loadModule can only be called from the kernel', 2) end

		if type(module) ~= 'table' then error('Attempt to load non-table as module', 2) end

		if type(kernel.modules[module.name]) ~= 'table' then
			kernel.modules[module.name] = module
			module.load(kernel)
		else
			error('Module already loaded: ' .. module.name, 2)
		end
	end

	function kernel.unloadModule(module)
		-- This should change
		if users.current().id ~= 0 then error('kernel.registerInterupt can only be called from the kernel', 2) end

		if type(module) == 'table' then module = module.name end

		kernel.modules[module].unload(kernel)
		kernel.modules[module] = nil
	end

	--[===[Device Manager]===]
	kernel.devices = deviceManager({}, kernel.emit)

	kernel.devices.detect()

	kernel.registerInterupt('peripheral', kernel.devices.newDeviceHandler)
	kernel.registerInterupt('peripheral_detach', kernel.devices.oldDeviceHandler)

	--[===[Scheduler]===]
	kernel.scheduler = threads.scheduler()
	kernel.registerQueue(kernel.scheduler.queue)

	-- Process and Scheduler Interop
	do
		local function listenProcess(pid, process)
			process.on('newThread', kernel.scheduler.add)

			for i = 1, #process.threads do
				kernel.scheduler.add(process.threads[i])
			end
		end

		local function listenNamespace(ns)
			ns.on('new', listenProcess)
			-- ns.on('newChild', listenNamespace)

			local processes = ns.list()

			for i = 1, #processes do
				listenProcess(unpack(processes[i]))
			end
		end

		listenNamespace(namespace)
	end

	return kernel
end

module.exports = setmetatable({
	threads = threads
}, {
	__call = function(t, ...) return peak(...) end
})