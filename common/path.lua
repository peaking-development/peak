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

return Path
