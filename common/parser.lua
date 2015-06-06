local function num(v)
	return v .. ';'
end
local function var(v)
	v = tostring(v)
	return num(#v) .. v
end

local function parser(get_chunk)
	if type(get_chunk) == 'string' then
		local data = get_chunk
		local got = false
		function get_chunk()
			if not got then
				got = true
				return data
			end
		end
	end
	local buffer = ''
	local done = false
	local function expand_buffer(len)
		if len then
			if #buffer >= len then return true end
			if done then return false end
			while not done and #buffer < len do
				local chunk = get_chunk(len - #buffer)
				if chunk == nil then
					done = true
				else
					buffer = buffer .. chunk
				end
			end
			return #buffer >= len
		else
			if done then return false end
			local chunk = get_chunk()
			if chunk == nil then
				done = true
			else
				buffer = buffer .. chunk
			end
			return not done
		end
	end
	local function read(len)
		if type(len) == 'number' then
			if not expand_buffer(len) then error('Not enough data for: ' .. len) end
			local ret = buffer:sub(1, len)
			buffer = buffer:sub(len + 1)
			return ret
		elseif len == 'num' or len == 'number' then
			while not buffer:match('^[0-9]+;') do
				if not expand_buffer() then
					error('Not enough data for num /[0-9]+;/')
				end
			end
			local n = buffer:match('^([0-9]+);')
			buffer = buffer:sub(#n + 2)
			n = tonumber(n)
			return n
		elseif len == 'all' then
			expand_buffer(math.huge)
			return buffer
		elseif len == 'sub' then
			local len = read('num')
			local left = len
			return parser(function(len)
				len = len or math.huge
				len = math.min(len, left)
				left = left - len
				if len > 0 then
					return read(len)
				end
			end)
		else
			return read(read('num'))
		end
	end
	return setmetatable({
		done = function()
			return #buffer == 0 and (done or not expand_buffer())
		end;
	}, { __call = function(self, len) return read(len) end; })
end

return setmetatable({
	var = var;
	num = num;
}, { __call = function(self, get_chunk) return parser(get_chunk) end; })
