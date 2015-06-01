local Path = require 'common/path'
local Promise = require 'common/promise'
local util = require 'common/util'
local E = require 'common/error'

local function expand_path(proc, path, n)
	n = type(n) == 'number' and n or math.huge
	local path = path
	if n > 0 then
		path = Path.reduce(util.concat(proc.working_dir, path))
		n = n - 1
	end
	if n > 0 then
		path = util.concat(proc.root, path)
		n = n - 1
	end
	if n > 0 then
		path = util.concat(proc.jail, path)
		n = n - 1
	end
	return path
end

local syscalls = {
	jail = function(proc, path)
		-- TODO: check if it's a folder
		proc.jail = expand_path(proc, path, 3)
		proc.root = {}
		proc.working_dir = {}
		return Promise.resolved(true)
	end;

	chroot = function(proc, path)
		-- TODO: check if it's a folder
		proc.root = expand_path(proc, path, 2)
		proc.working_dir = {}
		return Promise.resolved(true)
	end;

	unchroot = function(proc)
		proc.working_dir = {proc.root[#proc.root], table.unpack(proc.working_dir)}
		proc.root = {table.unpack(proc.root, 1, #proc.root - 1)}
		return Promise.resolved(true)
	end;

	chdir = function(proc, path)
		proc.working_dir = expand_path(proc, path, 1)
		return proc.working_dir
	end;

	open = function(proc, path, opts)
		return Promise(
			peak.fs(expand_path(proc, path), 'open', opts),
			Promise.map(proc.handles.register)
		)
	end;

	close = function(proc, fd)
		if proc.handles[fd] then
			local handle = proc.handles[fd]
			return Promise(
				handle.close(),
				Promise.map(function()
					proc.handles[fd] = nil
				end)
			)
		else
			return Promise.resolved(false, E.invalid_fd, fd)
		end
	end;


	stat = function(proc, path)
		return peak.fs(expand_path(proc, path), 'stat')
	end;
}

for _, name in ipairs({'read', 'write', 'seek', 'list', 'call', 'provide', 'unprovide', 'respond'}) do
	syscalls[name] = function(proc, fd, ...)
		local handle = proc.handles[fd]
		if handle then
			if handle[name] then
				return handle[name](...)
			else
				return Promise.resolved(false, E.invalid_call, name, fd)
			end
		else
			return Promise.resolved(false, E.invalid_fd, fd)
		end
	end
end

return syscalls
