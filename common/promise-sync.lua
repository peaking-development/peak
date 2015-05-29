local Promise = require 'common/promise'
local lon = require 'common/lon'

local function sync(co, ...)
	if type(co) ~= 'thread' then
		return Promise.flatMap(function(...)
			return sync(coroutine.create(co), ...)
		end)
	end

	local promise, resolve = Promise.pending()

	local function run(...)
		local res = {coroutine.resume(co, ...)}
		local ok = table.remove(res, 1)
		if ok then
			if coroutine.status(co) == 'dead' then
				resolve(true, table.unpack(res))
			else
				res[1](function(ok, ...)
					run(ok, ...)
				end)
			end
		else
			resolve(false, type(res[1]) == 'table' and table.unpack(res[1]) or res[1])
		end
	end
	run(...)

	return promise
end

local function wait(prom)
	if not Promise.is(prom) then
		print(debug.traceback())
	end
	local res = {coroutine.yield(prom)}
	if res[1] then
		return table.unpack(res, 2)
	else
		error({table.unpack(res, 2)})
	end
end

return setmetatable({
	wait = wait;
}, { __call = function(self, ...) return sync(...) end; })
