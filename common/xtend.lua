return function(...)
	local res = {}
	for i = 1, select('#', ...) do
		if type(select(i, ...)) == 'table' then
			for k, v in pairs(select(i, ...)) do
				res[k] = v
			end
		end
	end
	return res
end
