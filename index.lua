--[=====[Peak Kernel by CoderPuppy]=====]

local deviceManager = require('./devices')
local threads = require('./threads')

local function peak(_)
	local kernel = {
		interupts = {},
		syscalls = {},
		modules = {},
		debug = false
	}
	
	--[===[Syscalls]===]
	function kernel.registerSyscall(name, handler)
		if type(kernal.syscalls[name]) == 'function' then
			error('Attempt to reregister syscall: ' .. name, 2)
		else
			kernel.syscalls[name] = handler
		end
	end

	function kernel.syscall(name, ...)
		if type(kernel.syscalls[name]) == 'function' then
			return kernel.syscalls[name](...)
		else
			error('Attempt to call non-existent syscall: ' .. name, 2)
		end
	end

	--[===[Interupts]===]
	function kernel.registerInterupt(ev, handler)
		local interupts = kernel.interupts[ev]
		if interupts == nil then
			kernel.interupts[ev] = {handler}
			return 1
		elseif type(interupts) == 'table' then
			interupts[#interupts + 1] = handler
			return #interupts
		elseif type(interupts) == 'function' then
			kernel.interupts[ev] = {interupts, handler}
			return 2
		else
			print('what is going on here? ', type(interupts))
			print('someone messed with the interupt table')
		end
	end

	function kernel.interupt(ev, ...)
		if type(kernel.interupts[ev]) == 'function' then
			kernel.interupts[ev](ev, ...)
		elseif type(kernel.interupts[ev]) == 'table' then
			local interupts = kernel.interupts[ev]
			for i = 1, #interupts do
				interupts[i](ev, ...)
			end
		elseif kernel.debug then
			print('Unhandled interupt: ' .. ev)
		end
	end

	--[===[Modules]===]
	function kernel.loadModule(module)
		if type(kernel.modules[module.name]) ~= 'table' then
			kernel.modules[module.name] = module
			module.load(kernel)
		else
			error('Module already loaded: ' .. module.name, 2)
		end
	end

	function kernel.unloadModule(module)
		if type(module) == 'table' then module = module.name end

		kernel.modules[module].unload(kernel)
		kernel.modules[module] = nil
	end

	--[===[Device Manager]===]
	kernel.devices = deviceManager({}, kernel.interupt)

	kernel.registerInterupt('peripheral', kernel.devices.newDeviceHandler)
	kernel.registerInterupt('peripheral_detach', kernel.devices.oldDeviceHandler)

	return kernel
end

module.exports = setmetatable({
	threads = threads
}, {
	__call = function(t, ...) return peak(...) end
})