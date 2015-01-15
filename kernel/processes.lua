local processes = {}
local lastPID = peak.config.startID

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
		peak.timers.release(prom.timer)
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
		lastPID = peak.config.startID;
	}
	processes[pid] = proc

	wait(proc, Promise.resolved(true, table.unpack(opts.args)))

	return proc
end

local function run()
	local oldReady = ready
	ready = {}
	for pid in pairs(oldReady) do
		if type(pid) == 'number' then
			local proc = get(pid)
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
						elseif name == 'continue' then
							wait(proc, Promise.resolved(true, table.unpack(res)))
						else
							local prom = (peak.syscalls[name] or
								error('Unknown syscall ' .. tostring(name) .. ' for ' .. tostring(proc.id))
							)(proc, table.unpack(res))
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
	end
end

local function anyReady()
	return ready.any
end

return {
	get = get;
	addPromise = addPromise;
	releasePromise = releasePromise;
	wait = wait;
	spawn = spawn;
	run = run;
	anyReady = anyReady;
}