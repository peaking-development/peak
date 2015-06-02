local util = {}

function util.concat(...)
	local res = {}
	for i = 1, select('#', ...) do
		for _, v in ipairs(select(i, ...)) do
			res[#res + 1] = v
		end
	end
	return res
end

function util.map(tbl, fn)
	local res = {}
	for i, v in ipairs(tbl) do
		res[i] = fn(v, i, tbl)
	end
	return res
end

function util.filter(tbl, fn)
	local res = {}
	for _, v in ipairs(tbl) do
		if fn(v, i, tbl) then
			res[#res + 1] = v
		end
	end
	return res
end

function util.map_kvs(tbl, fn)
	local res = {}
	for k, v in pairs(tbl) do
		local nk, nv = fn(k, v, tbl)
		res[nk] = nv
	end
	return res
end

function util.filter_kvs(tbl, fn)
	local res = {}
	for k, v in pairs(tbl) do
		if fn(k, v, tbl) then
			res[k] = v
		end
	end
	return res
end

function util.kvs(tbl)
	local res = {}
	for k, v in pairs(tbl) do
		res[#res + 1] = {k, v}
	end
	return res
end

return util
