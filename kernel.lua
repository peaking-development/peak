local Promise = require 'promise'

local maxID = math.pow(2, 32)
local startID = 0

local kernel = {}
local syscalls

-- Timers
local timers = {}
local lastTID = startID
local time

local function setTimer(time)
	local tid = lastTID
	do
		local looped = false
		while timers[tid] do
			if tid >= maxID then
				if looped then
					error('No available timer id')
				else
					tid = startID
					looped = true
				end
			else
				tid = tid + 1
			end
		end
		if tid == lastTID then
			lastTID = lastTID + 1
		end
	end

	local timer = {
		id = tid;
		time = time;
		refs = 0;
	}
	timer.promise, timer.resolve = Promise.pending()
	timer.promise.timer = timer
	timers[tid] = timer
	return timer
end

local function getTimer(tid)
	if not timers[tid] then error('Non-existent timer: ' .. tostring(tid)) end
	return timers[tid]
end

local function grabTimer(timer)
	timer.refs = timer.refs + 1
end

local function releaseTimer(timer)
	timers.refs = timer.refs - 1
	if timer.refs <= 0 then
		timers[timer.id] = nil
	end
end

-- Processes
local processes = {}
local lastPID = startID

local ready = {}

local function get(pid)
	if not processes[pid] then error('Non-existent process: ' .. tostring(pid)) end
	return processes[pid]
end

local function addPromise(proc, prom)
	local pid = proc.lastPID
	while proc.promises[pid] do
		if pid == maxID then
			if looped then
				error('No available promise id')
			else
				pid = startID
				looped = true
			end
		else
			pid = pid + 1
		end
	end
	if pid == proc.lastPID then
		proc.lastPID = proc.lastPID + 1
	end

	proc.promises[pid] = prom

	return pid
end

local function releasePromise(proc, pid)
	local prom = proc.promises[pid]
	if not prom then error('Non-existent promise: ' .. tostring(pid)) end
	proc.promises[pid] = nil
	if prom.timer then
		releaseTimer(prom.timer)
	end
end

local function wait(proc, prom)
	proc.waiting = prom
	prom(function(...)
		ready[proc.id] = true
		ready.any = true
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
	do
		local looped = false
		while processes[pid] do
			if pid >= maxID then
				if looped then
					error('No available process id')
				else
					pid = startID
					looped = true
				end
			else
				pid = pid + 1
			end
		end
		if pid == lastPID then
			lastPID = lastPID + 1
		end
	end

	local proc = {
		id = pid;
		status = 'running';

		coroutine = coroutine.create(opts.code);

		promises = {};
		lastPID = startID;
	}
	processes[pid] = proc

	wait(proc, Promise.resolved(true, table.unpack(opts.args)))

	return proc
end

-- Only call this when you know it's ready
local function run(proc)
	local args = {proc.waiting.ok, table.unpack(proc.waiting.res)}
	proc.waiting = nil
	while true do
		local res = {coroutine.resume(proc.coroutine, table.unpack(args))}
		local status = coroutine.status(proc.coroutine)
		local ok = table.remove(res, 1)
		if ok then
			if status == 'dead' then
				proc.status = 'finished'
				proc.result = res
				break
			elseif status == 'suspended' then
				local name = table.remove(res, 1)
				if name == 'wait' then
					local proms = {}
					for _, prom in ipairs(res) do
						proms[#proms + 1] = proc.promises[prom]
					end
					local prom = Promise.first(table.unpack(proms))
					wait(proc, prom)
					break
				elseif name == 'release' then
					releasePromise(proc, res[1])
					args = {}
				else
					local prom = (syscalls[name] or error('Unknown syscall: ' .. tostring(name)))(proc, table.unpack(res))
					args = {select(1, addPromise(proc, prom))}
				end
			else
				error('Unhandled coroutine status: ' .. tostring(status))
			end
		else
			error(res[1])
		end
	end
end

syscalls = {
	time = function(proc)
		return Promise.resolved(true, time)
	end;

	timer = function(proc, time)
		local timer = setTimer(time)
		grabTimer(timer)
		return timer.promise
	end;
}

kernel.status = 'ready'

function kernel.boot(path)
	if kernel.status ~= 'ready' then error('Invalid status for kernel.boot: ' .. kernel.status) end
	kernel.status = 'on'
	spawn {
		code = function()
			local function sleep(time)
				local ok, _, cur = coroutine.yield('wait', coroutine.yield('time'))
				if ok then
					coroutine.yield('wait', coroutine.yield('timer', cur + time))
				else
					error(_)
				end
			end
			print('sleeping')
			-- sleep(1)
			-- print('more sleeping')
			-- sleep(1)
			sleep(2)
			print('hi')
		end
	}
end

function kernel.tick(t)
	time = t
	for tid, timer in pairs(timers) do
		if time >= timer.time then
			timer.resolve(true, time)
			timers[tid] = nil
		end
	end

	local oldReady = ready
	ready = {}
	for pid in pairs(oldReady) do
		if type(pid) == 'number' then
			run(get(pid))
		end
	end

	local nextTime = math.huge
	for tid, timer in pairs(timers) do
		if time < timer.time then
			nextTime = math.min(nextTime, timer.time)
		end
	end

	if processes[0].status == 'finished' then
		kernel.status = 'off'
	end

	if ready.any then
		return 0
	else
		return nextTime - time
	end
end

return kernel