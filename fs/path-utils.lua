local pathUtils = exports

local utils = require('peak-utils')

function pathUtils.normPath(path)
	if path == nil then
		error('path must not be nil', 2)
	end

	local root = path:sub(1, 1) == '/'

	path = utils.split(path, '/')
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

-- TODO: Internalize this
pathUtils.joinPath = fs.combine
pathUtils.basename = fs.getName