local Reg = require 'common/reg'
local util = require 'common/util'
local lon = require 'common/lon'
local Promise = require 'common/promise'
local processes = require 'common/id-reg' ()

local function get(pid)
	if not processes[pid] then error('Non-existent process: ' .. tostring(pid)) end
	return processes[pid]
end

local function addPromise(proc, prom)
	if not Promise.is(prom) then
		print(prom)
		error('not a promise')
	end
	return proc.promises.register(prom)
end

local function releasePromise(proc, pid)
	local prom = proc.promises[pid]
	if not prom then error('Non-existent promise: ' .. tostring(pid)) end
	proc.promises.release(pid)
	if prom.timer then
		peak.timers.release(prom.timer)
	end
end

local tick

local function wait(proc, prom)
	if proc.waiting then
		error('already waiting')
	end
	proc.waiting = prom
	prom(function(...)
		peak.queue[#peak.queue + 1] = function()
			tick(proc, prom)
		end
	end)
end

function tick(proc, prom)
	local args = proc.waiting.res
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
					local prom = Promise.firstResolved(table.unpack(proms))
					wait(proc, prom)
					break
				elseif name == 'release' then
					releasePromise(proc, res[1])
					args = {}
				elseif name == 'continue' then
					wait(proc, Promise.resolved(true, table.unpack(res)))
					break
				else
					-- print(tostring(proc.id) .. ' calling ' .. tostring(name) .. '(' .. table.concat(util.map(res, lon.to), ', ') .. ')')
					local prom = (peak.syscalls[name] or
						error('Unknown syscall ' .. tostring(name) .. ' (called by ' .. tostring(proc.id) .. ')')
					)(proc, table.unpack(res))
					args = {select(1, addPromise(proc, prom))}
				end
			else
				error('Unhandled coroutine status: ' .. tostring(status))
			end
		else
			-- TODO: handle this
			error(res[1])
		end
	end
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

	local proc = {
		status = 'running';

		coroutine = coroutine.create(opts.code);

		promises = Reg();

		-- FS
		jail = {};
		root = {};
		working_dir = {};
		handles = Reg();
	}
	pid = processes.register(proc, pid)
	proc.id = pid

	wait(proc, Promise.resolved(true, table.unpack(opts.args)))

	return proc
end

return {
	get = get;
	addPromise = addPromise;
	releasePromise = releasePromise;
	wait = wait;
	spawn = spawn;
	tick = tick;
}
