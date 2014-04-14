local Handle = require('./handle')
local pathUtils   = require('./path-utils')

--[[
interface FS
	function _open(user: String, path: String, mode: String): handle
	function _read(handle, length: Number): String
	function _write(handle, content: String)
	function _seek(handle, offset: Number)
	function _close(handle)

	function _checkPermission(user: String, path: String, op: String): Boolean
	function _stat(user: String, path: String): @Nilable {
		type: String ('file' | 'directory')
	}
end
]]

function checkOp(self, user, path, op)
	local ok, reason = self:checkPermission(user, path, op)
	if ok then
		local stat, reason = self:stat(user, path)

		if path == '*l' then
			error('DO NOT CHECK FOR *l', 2)
		end

		if stat == nil or type(stat) ~= 'table' then
			return false, 'noexist'
		elseif stat.type ~= 'file' then
			return false, 'notfile'
		else
			return true
		end
	else
		return false, reason
	end
end

local function FS(t)
	if type(t) ~= 'table' then
		error('Not a table', 2)
	end

	if type(t._open) ~= 'function' then
		error('No method named _open', 2)
	end

	if type(t._read) ~= 'function' then
		error('No method named _read', 2)
	end

	if type(t._write) ~= 'function' then
		error('No method named _write', 2)
	end

	if type(t._seek) ~= 'function' then
		error('No method named _seek', 2)
	end

	if type(t._close) ~= 'function' then
		error('No method named _close', 2)
	end

	if type(t._checkPermission) ~= 'function' then
		error('No method named _checkPermission', 2)
	end

	if type(t._stat) ~= 'function' then
		error('No method named _stat', 2)
	end

	function t:checkPermission(user, path, op)
		path = pathUtils.normPath(path)

		if user == nil then
			return true
		else
			return self:_checkPermission(user, path, op)
		end
	end

	function t:open(user, path, mode)
		local ok, reason = checkOp(self, user, path, mode)

		if ok then
			return Handle.new(self, user, path, mode)
		else
			return nil, reason
		end
	end

	function t:write(handle, content)
		-- if type(offset) ~= 'number' or offset < -1 then
		-- 	offset = 0
		-- end

		-- path = pathUtils.normPath(path)

		-- local ok, reason = checkOp(self, user, path, 'w')
		-- if ok then
		-- 	return self:_write(user, path, content, offset)
		-- else
		-- 	return nil, reason
		-- end

		if handle == nil then
			return nil, 'notopen'
		end

		return handle:write(content)
	end

	function t:read(handle, length)
		-- if type(offset) ~= 'number' or offset < 0 then
		-- 	offset = 0
		-- end

		-- path = pathUtils.normPath(path)

		-- local ok, reason = checkOp(self, user, path, 'r')
		-- if ok then
		-- 	return self:_read(user, path, length, offset)
		-- else
		-- 	return nil, reason
		-- end

		if handle == nil then
			return nil, 'notopen'
		end

		return handle:read(length)
	end

	function t:stat(user, path)
		return self:_stat(user, path)
	end
end

module.exports = FS