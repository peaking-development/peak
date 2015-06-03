local Promise = require 'common/promise'
local util = require 'common/util'
local sync = require 'common/promise-sync'
local wait = sync.wait
local FS = require 'common/fs'

return {
	fork = function(proc, fn, env)
		local new_proc = peak.processes.spawn {
			code = fn;
			src = proc.src;
			args = {};
			parent = proc;
			env = env;
		}
		return Promise.resolved(true, new_proc.id)
	end;

	exec = function(proc, path, args)
		return ret(sync(function()
			local h = wait(peak.fs(path, 'open', {
				type = 'file';
				execute = true;
			}))
			local code = wait(h.read(math.huge))
			local fn, err = load(code, FS.serialize_path(path), 't', _G)
			if not fn then
				error(err)
			end
			wait(h.close())
			peak.processes.exec(proc, path, args, fn)
		end))
	end;

	listenv = function(proc)
		return Promise.resolved(true, util.keys(proc.env))
	end;

	getenv = function(proc, name)
		return Promise.resolved(true, proc.env[name])
	end;

	setenv = function(proc, name, val)
		proc.env[name] = val
		return Promise.resolved(true)
	end;

	wait_exit = function(proc, pid)
		local wproc = peak.processes.get(pid)
		if wproc.parent == proc then
			wproc.waited_on = true
		end
		return peak.processes.wait_exit(wproc)
	end;
}
