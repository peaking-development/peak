local Handle = exports

function Handle.new(...)
	local self = setmetatable({}, Handle.mt)
	self:init(...)
	return self
end

Handle.proto = {
	init = function(self, fs, user, path, mode)
		self.fs = fs
		self.user = user
		self.path = path
		self.mode = mode

		self._handle = self.fs:_open(user, path, mode)
	end;

	read = function(self, length)
		if type(length) ~= 'number' and length ~= '*l' and length ~= '*a' then
			length = '*a'
		end

		return self.fs:_read(self._handle, length)
	end;

	write = function(self, content)
		if type(content) == 'string' then
			return self, select(2, self.fs:_write(self._handle, content))
		end
	end;

	close = function(self)
		return self, select(2, self.fs:_close(self._handle))
	end;
}

Handle.mt = {
	__index = Handle.proto
}