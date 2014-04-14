local pathUtils = require('./path-utils')
local FS   = require('./fs')

local PathFS = exports

function PathFS.new(...)
	local self = setmetatable({}, PathFS.mt)
	self:init(...)
	return self
end

PathFS.proto = {
	init = function(self, fs, path)
		self.fs   = fs
		self.path = path .. ''

		FS(self)
	end;

	_getPath = function(self, origPath)
		return "/" .. pathUtils.joinPath(self.path, origPath:gsub("^/", "") .. '')
	end;

	_checkPermission = function(self, user, path, op)
		return self.fs:checkPermission(user, self:_getPath(path), op)
	end;

	_open = function(self, user, path, mode)
		return self.fs:open(user, self:_getPath(path), mode)
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
		return self.fs:stat(user, self:_getPath(path))
	end;
}

PathFS.mt = {
	__index = PathFS.proto
}