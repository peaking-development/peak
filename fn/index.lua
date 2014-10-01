local function morefun(fn)
	return setmetatable({}, { __call = fn })
end

local function reerror(err, level)
	error(err:gsub('^pcall: ', ''), level == 0 and 0 or level + 1)
end

local function reerrorCall(level, fn, ...)
	local ok, rtn = pcall(fn, ...)

	if not ok then
		reerror(rtn, level == 0 and 0 or level + 1)
	end

	return rtn
end

local fn = morefun(function(fn, v, ...)
	local ops = {...}
	for _, op in ipairs(ops) do
		v = reerrorCall(2, op, v)
	end
	return v
end)
fn.morefun = morefun
fn.reerror = reerror
fn.reerrorCall = reerrorCall
return fn