local util = exports

function util.split(str, splitter, pattern)
	local found = true
	local last = 0
	local parts = {}

	-- print(str)

	while found do
		local match = {str:find(splitter, last, not pattern)}

		-- print(table.concat(match, ', '))

		if #match > 0 then
			parts[#parts + 1] = str:sub(last, match[1] - 1)
			last = match[1] + 1
		else
			found = false
		end
	end

	parts[#parts + 1] = str:sub(last)

	-- print(textutils.serialize(parts))

	return parts
end

function util.normPath(path)
	if path == nil then
		error('path must not be nil', 2)
	end

	local root = path:sub(1, 1) == '/'

	path = util.split(path, '/')
	newPath = {}

	for _, part in ipairs(path) do
		if part == '..' then
			newPath[#newPath] = nil
		elseif #part > 0 and part ~= '.' then
			newPath[#newPath + 1] = part
		end
	end

	-- print(textutils.serialize(newPath))
	-- print(table.concat(newPath, '/'))

	path = table.concat(newPath, '/')

	if root then
		path = '/' .. path:gsub('^/', '')
	end

	-- print(path)

	return path
end

function util.slice(t, from, to)
	local res = {}

	for i = from, to do
		res[#res + 1] = t[i]
	end

	return res
end

-- TODO: Internalize this
util.joinPath = fs.combine
util.basename = fs.getName