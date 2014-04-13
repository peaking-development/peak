local FS = require('./fs')

local CraftFS = exports

function CraftFS.new(...)
	local self = setmetatable({}, CraftFS.mt)
	self:init(...)
	return self
end

CraftFS.proto = {
	init = function(self, craftFS)
		self.craftFS = craftFS
		FS(self)
	end;

	_checkPermission = function(self, user, path, op)
		if op == 'r' then
			return true
		elseif op == 'w' then
			error("huh", 2)
			if self.craftFS.isReadOnly(path) then
				return false, 'readonly'
			else
				return true
			end
		elseif op == 's' then
			return true
		else
			return false
		end
	end;

	_open = function(self, user, path, mode)
		return {
			file = self.craftFS.open(path, mode);
			offset = 0;
			content = "";
		}
	end;

	_read = function(self, handle, length)
		local remaining = handle.content:sub(handle.offset)

		if length == '*l' then
			while remaining:find('\n', 1, true) == nil do
				local data = handle.file.readLine()
				if #data == 0 then
					break
				end
				handle.content = handle.content .. data .. '\n'
				remaining = handle.content:sub(handle.offset)
				print(remaining, ', ', handle.content, ', ', handle.offset)
			end

			local nl = remaining:find('\n', 1, true)

			if nl then
				return remaining:sub(1, nl - 1)
			else
				return remaining
			end
		elseif length == '*a' then
			return remaining .. handle.file.readAll()
		elseif type(length) == 'number' then
			while #remaining < length do
				handle.content = handle.content .. handle.file.readLine()
				remaining = handle.content:sub(handle.offset)
			end

			return remaining:sub(1, length)
		end
	end;

	_write = function(self, handle, content)
		
	end;

	_seek = function(self, handle, offset)

	end;

	_close = function(self, handle)
		handle.file.close()
	end;

	_stat = function(self, user, path)
		if not self.craftFS.exists(path) then
			return nil
		end

		local stat = {}
		if self.craftFS.isDir(path) then
			stat.type = 'directory'
		else
			stat.type = 'file'
		end
		return stat
	end;
}

CraftFS.mt = {
	__index = CraftFS.proto
}