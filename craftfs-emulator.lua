local util = require('./util')

local CraftFSEmulator = exports

function CraftFSEmulator.new(...)
	local self = setmetatable({}, CraftFSEmulator.mt)
	self:init(...)
	return self
end

CraftFSEmulator.proto = {
	init = function(self, fs, user)
		self.fs = fs
		self.user = user
		self.craftFS = {
			getFreeSpace = function()
				return 'unknown'
			end;

			getName = function(path)
				return util.basename(path)
			end;

			combine = function(a, b)
				return util.joinPath(a, b)
			end;

			open = function(path, mode)
				local h = {}
				local handle = self.fs:open(user, path, mode)

				if mode == 'r' then
					function h.readLine()
						return handle:read('*l')
					end

					function h.readAll()
						return handle:read('*a')
					end
				end

				function h.close()
					handle:close()
				end

				return h
			end;

			exists = function(path)
				return self.fs:stat(self.user, path) ~= nil
			end;

			isDir = function(path)
				local stat = self.fs:stat(self.user, path)
				return stat ~= nil and stat.type == 'directory'
			end;
		}
	end;
}

CraftFSEmulator.mt = {
	__index = CraftFSEmulator.proto
}