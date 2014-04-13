local util = require('./util')
local FS   = require('./fs')

local MountFS = exports

function MountFS.new(...)
	local self = setmetatable({}, MountFS.mt)
	self:init(...)
	return self
end

MountFS.proto = {
	init = function(self)
		self.mounts = {}

		FS(self)
	end;

	mount = function(self, mountPoint, mountFS)
		mountPoint = util.normPath(mountPoint)
		self.mounts[mountPoint] = mountFS
	end;

	_findFS = function(self, path)
		local origPath = path
		local oldPath

		while #path > 0 and path ~= oldPath do
			-- print(':', path)

			if self.mounts[path] then
				return self.mounts[path], origPath:sub(#path + 1)
			end

			oldPath = path
			path = util.normPath(path .. '/..')
		end
	end;

	_checkPermission = function(self, user, path, op)
		local fs, path = self:_findFS(path)

		if fs then
			return fs:checkPermission(user, path, op)
		else
			return false, 'nomountpoint'
		end
	end;

	_open = function(self, user, path, mode)
		local fs, path = self:_findFS(path)

		if fs then
			local handle, reason = fs:open(user, path, mode)

			if handle == nil then
				return nil, reason
			else
				return handle
			end
		else
			return nil, 'nomountpoint'
		end
	end;

	_read = function(self, handle, length)
		return handle:read(length)
	end;

	_write = function(self, handle, content)
		return handle:write(content)
	end;

	_seek = function(self, handle, offset)
		return handle:seak(offset)
	end;

	_close = function(self, handle)
		return handle:close()
	end;

	_stat = function(self, user, path)
		local fs, path = self:_findFS(path)

		if fs then
			return fs:stat(user, path)
		else
			return nil, 'nomountpoint'
		end
	end;
}

MountFS.mt = {
	__index = MountFS.proto
}