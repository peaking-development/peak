local Reg = require 'common/reg'
local util = require 'common/util'
local lon = require 'common/lon'
local xtend = require 'common/xtend'
local Promise = require 'common/promise'
local processes = require 'common/id-reg' ()

local function get(pid)
	if not processes[pid] then error('Non-existent process: ' .. tostring(pid)) end
	return processes[pid]
end

local function add_promise(proc, prom)
	if not Promise.is(prom) then
		print(prom)
		error('not a promise')
	end
	return proc.promises.register(prom)
end

local function try_collect(proc)
	if proc.status ~= 'finished' then return end
	if not (proc.waited_on or (proc.parent and proc.parent.status == 'finished')) then
		return
	end
	for child in pairs(proc.children) do
		try_collect(child)
	end
	if not util.empty(proc.children) then return end
	processes.release(proc.id)
	if proc.parent then
		proc.parent.children[proc] = nil
		try_collect(proc.parent)
	end
end

local function wait_exit(proc)
	try_collect(proc)
	return proc.done_prom
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

local function exec(proc, src, args, code)
	proc.coroutine = coroutine.create(code)
	proc.src = src
	proc.args = args
	proc.status = 'running'
	proc.result = nil
	wait(proc, Promise.resolved(true, table.unpack(args, 1, args.n or #args)))
end

function tick(proc, prom)
	local args = proc.waiting.res
	proc.waiting = nil
	local co = proc.coroutine
	while true do
		if proc.coroutine ~= co then
			break
		end
		local res = table.pack(coroutine.resume(proc.coroutine, table.unpack(args, 1, args.n or #args)))
		local status = coroutine.status(proc.coroutine)
		local ok = res[1]
		res = table.pack(table.unpack(res, 2, res.n))
		if status == 'dead' then
			if proc.status ~= 'finished' then
				proc.status = 'finished'
				proc.result = res
				proc.done_resolve(ok, table.unpack(res, 1, res.n))
				try_collect(proc)
			end
			break
		else
			if ok then
				if status == 'suspended' then
					local name = res[1]
					res = table.pack(table.unpack(res, 2, res.n))
					if name == 'wait' then
						local proms = {}
						for _, prom in ipairs(res) do
							proms[#proms + 1] = proc.promises[prom]
						end
						local prom = Promise.first_resolved(table.unpack(proms))
						wait(proc, prom)
						break
					elseif name == 'continue' then
						wait(proc, Promise.resolved(true, table.unpack(res)))
						break
					else
						-- print(tostring(proc.id) .. ' calling ' .. tostring(name) .. '(' .. table.concat(util.map(res, lon.to), ', ') .. ')')
						local prom = (peak.syscalls[name] or
							error('Unknown syscall ' .. tostring(name) .. ' (called by ' .. tostring(proc.id) .. ')')
						)(proc, table.unpack(res))
						args = {select(1, add_promise(proc, prom))}
					end
				else
					error('Unhandled coroutine status: ' .. tostring(status))
				end
			end
		end
	end
end

local function spawn(opts)
	opts = type(opts) == 'table' and xtend(opts) or {}
	opts.src = opts.src or 'kernel'
	opts.args = type(opts.arg) == 'table' and opts.args or {}
	opts.env = type(opts.env) == 'table' and opts.env or nil
	if type(opts.code) ~= 'function' then error('No code passed') end

	local proc = {
		status = 'running';

		promises = Reg();
		env = xtend(opts.env or (opts.parent and opts.parent.env) or {});

		children = {};

		-- FS
		jail = {};
		root = {};
		working_dir = {};
		handles = Reg();
	}
	proc.done_prom, proc.done_resolve = Promise.pending()
	if opts.parent and processes[opts.parent.id] == opts.parent then
		proc.parent = opts.parent
		proc.parent.children[proc] = true
	end
	proc.id = processes.register(proc)

	exec(proc, opts.src, opts.args, opts.code)

	return proc
end

return {
	get = get;
	add_promise = add_promise;
	spawn = spawn;
	tick = tick;
	wait_exit = wait_exit;
	exec = exec;
}
