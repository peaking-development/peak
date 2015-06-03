local Path = {}

function Path.reduce(path)
	local res = {}
	for _, part in ipairs(path) do
		if part == '..' then
			res[#res] = nil
		elseif part == '.' then
		else
			res[#res + 1] = part
		end
	end
	return res
end

function Path.serialize(path)
	local out = {}
	for i, v in ipairs(path) do
		out[i] = v:gsub('\\', '\\\\'):gsub('/', '\\/')
	end
	return table.concat(out, '/')
end

local function unescape(str)
	return str:gsub('\\\\', '\\'):gsub('\\/', '/')
end

function Path.unserialize(path)
	local pat = '(\\*)/'
	local out = {}
	local pre, tmp
	local last_index = 0
	while not (pre and #pre % 2 == 0) do
		pre = path:match(pat)
		local index = path:find(pat)
		last_index = index + #pre + 1
		tmp = path:sub(0, index - 1)
	end
	-- print(last_index, tmp)
	for pre in path:gmatch(pat) do
		-- print('pre', #pre % 2, pre)
		-- print('past', path:sub(0, last_index))
		local index = path:find(pat, last_index + 1)
		if #pre % 2 == 0 then
			-- print('adding\\\\', ('\\'):rep(#pre / 2))
			tmp = tmp .. ('\\'):rep(#pre / 2)
			-- print('splitting', tmp, last_index)
			out[#out + 1] = tmp
			tmp = ''
		else
			tmp = tmp .. ('\\'):rep((#pre - 1) / 2) .. '/'
			-- print('adding\\', pre .. '/', tmp)
		end
		-- print('sub', last_index, index, index and path:sub(last_index, index - 1) or path:sub(last_index))
		-- print('adding', (index and path:sub(last_index + 1, index - 1) or path:sub(last_index + 1)), tmp)
		tmp = tmp .. unescape(index and path:sub(last_index + 1, index - 1) or path:sub(last_index + 1))
		if index then
			last_index = index + #pre
		end
	end
	out[#out + 1] = tmp
	return out
end

return Path
