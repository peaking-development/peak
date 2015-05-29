return function(getChunk)
	local buffer = ''
	local done = false
	local function expandBuffer(len)
		if #buffer >= len then return true end
		if done then error('No more data') end
		while not done and #buffer < len do
			local chunk = getChunk(len - #buffer)
			if chunk == nil then
				done = true
			else
				buffer = buffer .. chunk
			end
		end
		return #buffer >= len
	end
	return function(len)
		if type(len) == 'number' then
			if not expandBuffer(len) then error('Not enough data') end
			local ret = buffer:sub(1, len)
			buffer = buffer:sub(len + 1)
			return ret
		elseif len == 'all' then
			expandBuffer(math.huge)
			return buffer
		else
			while not buffer:match('^[0-9]+:') do
				if not expandBuffer(#buffer + 1) then
					error('Not enough data')
				end
			end
			local len = buffer:match('^([0-9]+):')
			buffer = buffer:sub(#len + 2)
			len = tonumber(len)
			if not expandBuffer(len) then
				error('Not enough data')
			end
			local ret = buffer:sub(1, len)
			buffer = buffer:sub(len + 1)
			return ret
		end
	end
end
