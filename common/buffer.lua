local Promise = require 'common/promise'

return function(h, data, write)
	local buffer
	local pos = 1
	local function read(len)
		local res = buffer:sub(pos, pos + len - 1)
		pos = pos + len
		if pos > #buffer + 1 then pos = #buffer + 1 end
		return res
	end
	function h.read(len)
		buffer = data()
		local res
		if len == math.huge then
			res = buffer:sub(pos)
			pos = #buffer
		elseif len == 'line' then
			local index = buffer:find('[\n\r]', pos)
			local m = buffer:match('[\n\r]*', pos)
			res = read(index - pos)
			read(#m)
		elseif type(len) == 'number' and len > 0 then
			res = read(len)
		else
			res = read(10)
		end
		buffer = nil
		return Promise.resolved(true, res)
	end
	function h.seek(whence, offset)
		if whence == 'set' then
			pos = offset + 1
		elseif whence == 'cur' then
			pos = pos + offset
		else
			return ret(Promise.resolved(false, 'invalid whence: ' .. tostring(whence)))
		end
		if pos > #data() + 1 then
			return ret(Promise.resolved(false, E.badpos, pos, #data() + 1))
		end
		return Promise.resolved(true, pos - 1)
	end
	function h.close()
		return Promise.resolved(true)
	end

	if write then
		function h.write(_data)
			buffer = data()
			buffer = buffer:sub(1, pos - 1) .. _data .. buffer:sub(pos + #_data)
			data(buffer)
			buffer = nil
			return Promise.resolved(true)
		end

		function h.flush()
			return Promise.resolved(true)
		end
	end

	return h
end
