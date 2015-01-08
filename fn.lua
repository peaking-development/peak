local function morefun(fn)
	return setmetatable({}, { __call = fn })
end

local function reerrorMsg(err, msg)
	err = err:gsub('^pcall: ', '')
	if msg then
		return msg .. ' - ' .. err
	else
		return err
	end
end

local function reerror(err, level, msg)
	error(reerrorMsg(err, msg), level == 0 and 0 or level + 1)
end

local function reerrorCall(level, msg, fn, ...)
	if type(level) ~= 'number' then error('fn.reerrorCall: level must be a number', 2) end
	if type(fn) ~= 'function' then error('fn.reerrorCall: function must be a function', 2) end

	local res = {pcall(fn, ...)}
	local ok = table.remove(res, 1)

	if not ok then
		reerror(res[1], level == 0 and 0 or level + 1, msg)
	end

	return unpack(res)
end

local fn = morefun(function(fn, v, ...)
	local ops = {...}
	v = {v}
	for i, op in ipairs(ops) do
		if type(op) ~= 'function' then print(op) end
		v = {reerrorCall(2, 'fn: Error at ' .. tostring(i), op, unpack(v))}
	end
	return unpack(v)
end)
fn.more = morefun
fn.reerror = reerror
fn.reerrorMsg = reerrorMsg
fn.reerrorCall = reerrorCall
fn.combine = function(...)
	local ops = {...}
	return function(...)
		local v = {...}
		for _, op in ipairs(ops) do
			if type(op) ~= 'function' then print(op) end
			v = {reerrorCall(1, 'fn.combine: Error at ' .. tostring(i), op, unpack(v))}
		end
		return unpack(v)
	end
end
return fn