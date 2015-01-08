local Promise = require 'promise'

local kernel = {}

local processes = {}
local lastPID = 0
local maxPID = math.pow(2, 32)

local timers = {}
local ready = {}

local syscalls = {

}

local function get(pid)
	if not processes[pid] then error('Non-existent process: ' .. tostring(pid)) end
	return processes[pid]
end

local function wait(proc, prom)
	proc.waiting = prom
	prom(function(...)
		ready[proc.id] = true
	end)
end

local function spawn(opts)
	opts = type(opts) == 'table' and opts or {}
	do
		local new = {}
		for k, v in pairs(opts) do
			new[k] = v
		end
		opts = new
	end
	opts.args = type(opts.arg) == 'table' and opts.args or {}
	if type(opts.code) ~= 'function' then error('No code passed') end
	local pid = type(opts.pid) == 'number' and opts.pid or lastPID
	while processes[pid] do
		if pid >= maxPID then
			pid = 0
		else
			pid = pid + 1
		end
	end
	if pid == lastPID then
		lastPID = lastPID + 1
	end
	local proc = {
		id = pid;
		coroutine = coroutine.create(opts.code);
	}
	processes[pid] = proc

	wait(proc, Promise.resolved(table.unpack(opts.args)))

	return proc
end

-- Only call this when you know it's ready
local function run(proc)
	local args = {proc.waiting.ok, table.unpack(proc.waiting.res)}
	while true do
		local res = {coroutine.resume(proc.coroutine, table.unpack(args))}
		local status = coroutine.status(proc.coroutine)
		local ok = table.remove(res, 1)
		if ok then
			if status == 'dead' then
				proc.result = res
				break
			elseif status == 'suspended' then
				local name = table.remove(res, 1)
				if name == 'wait' then
					wait(proc, Promise.first(table.unpack(res)))
					break
				else
					args = {(syscalls[name] or error('Unknown syscall: ' .. tostring(name)))(proc, table.unpack(res))}
				end
			else
				error('Unhandled coroutine status: ' .. tostring(status))
			end
		else
			print(require('serialization').serialize(res))
		end
	end
end

kernel.status = 'ready'

function kernel.boot(path)
	if kernel.status ~= 'ready' then error('Invalid status for kernel.boot: ' .. kernel.status) end
	kernel.status = 'on'
	spawn {
		code = function()
			print('hi')
			return 1
		end
	}
end

function kernel.tick()
	print('peak - tick')
	for pid in pairs(ready) do
		run(get(pid))
		ready[pid] = nil
	end
	ready = {}
	return 1
end

return kernel